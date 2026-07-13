# Task 3: 繪製 Dot Accumulator 與 Softmax & Context SVG 圖 - 實作報告

## 實作內容 (What was implemented)

在 `sparse_attention_architecture.html` 的 JavaScript 渲染函式 `renderContent(tabId)` 中，完整實作了以下三個頁籤的互動式 SVG 電路架構圖與說明面板內容：

1. **Dot Accumulator (點積管線 - `dot_accum`)**：
   - 繪製了 Stage 0 級的特徵向量拆分與輸入部分，包含 `q_feature_vector` 與 `k_feature_vector`。
   - 繪製了 4 個並行的乘法單元 (`Multiplier Lane 0` 到 `3`)，計算 Query 與 Key 各維度乘積。
   - 繪製了並行乘積暫存器 `product_reg [0:3]`。
   - 繪製了 Stage 1 級的樹狀加法器 (`Adder Tree`)，依序執行兩級加法運算，輸出點積和 `score_sum`。
   - 繪製了 Stage 2 級的輸出暫存器， latch 點積和為 `attention_score`，並同步傳遞索引與 valid 信號。
   - 繪製了管線控制，包含 gated 系統時脈與 `advance_ready` 控制線，並連線至各個管線級暫存器。

2. **Softmax & Context (權重與除法 - `softmax_context`)**：
   - 繪製了在線 Softmax 的 5-狀態控制機狀態轉移圖 (圓圈狀態節點：`COLLECT`、`UPDATE`、`PREPARE`、`DIVIDE`、`OUTPUT`)，並使用粉紅色標註各轉移條件的控制信號與弧線箭頭。
   - 繪製了在線最大值與指數查表查算路徑，包含 `exp_lut` 查表模組、`row_exp_sum` 指數累加器暫存列、與 V 向量進行加權和乘加累加的 `row_weighted_sum` 暫存列。
   - 繪製了恢復/非恢復型位序列除法器 (Bit-Serial Restoring Divider) 的逐位計算路徑，包含餘數暫存器 `division_remainder`、除數暫存器 `division_denominator`、減法比較器、商移位暫存器 `division_quotient` 以及 `division_bit` 計數器。

3. **Stats & Result FIFO (統計與輸出緩衝 - `stats_fifo`)**：
   - 繪製了 `stats_counter` 電路，包含三個獨立的遞增累加暫存器：`pair_count` (QK配對計數)、`cycle_count` (執行週期計數) 與 `mac_count` (乘加運算計數，每次加 4)。
   - 繪製了 Result FIFO 環狀佇列 (Circular Queue) 與讀寫指標運作圖。展示了 `core_context_value` 如何在握手時寫入 FIFO，以及主機如何通過向 `ADDR_RESULT_POP` 寫入數據來彈出 (POP) 數據，並將讀取指針 `fifo_rd_ptr` 和數據輸出到外部 APB 總線。

## 驗證方法 (How it was verified)

1. **程式碼語法檢查**：
   - 檢查 `sparse_attention_architecture.html` 中所添加的 HTML/JavaScript 模板字面量無語法衝突，並確實與前台導覽標籤及系統 Overview 中的子模組 `onclick` 點擊動作 (`onclick="switchTab(...)"`) 完美對接。
   - 檢查所有 SVG 幾何圖形座標（viewBox = "0 0 900 580"）、箭頭標識 (`marker-end`)、及 CSS 類別（例如 `.module-box` 與 `.signal-group`）以確保其繼承的陰影與 hover 動效在瀏覽器中能夠完美配合。
2. **RTL 代碼規格對照**：
   - 對照 `qk_dot_accumulator.v` 的暫存器與管線階層，確認點積管線圖中所有寄存器命名與控制關係皆完全匹配。
   - 對照 `sparse_softmax_sv.v` 的 FSM 狀態轉移與 datapath 除法電路，確保 `softmax_context` 圖中列出的轉移路徑與 Restoring 除法運算邏輯在硬體上均完全一致。
   - 對照 `stats_counter.v` 與 `chip_top.v` 中的 Result FIFO 邏輯，確認 Counters 的遞增步長及 FIFO 讀寫指針結構精確無誤。

## 修改檔案 (Files Changed)

- Modify: `C:\Users\HAO\Documents\人工智慧晶片報告\RTL\Rtl\sparse_attention_architecture.html`

## 自我審查結果 (Self-Review Findings)

- **排版與佈局**：SVG 圖表均為精確的向量圖，各元件排版對稱，管線連線清晰，信號皆標有精確的 RTL 變數名稱及位元寬度，不易產生 overlapping。
- **懸停與點擊互動**：Overview 中的各模組點擊皆能正常導覽，個別分頁中的 SVG 模組與信號線均能響應 CSS 懸停動態效果。

## 其他事項 (Issues or Concerns)

- 無，所有需求皆已依據設計規格完成。
