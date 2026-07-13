# Task 2 Report: 繪製 Overview 與 Pair Streamer/Feature Memory SVG 圖

## 實作內容 (What was implemented)

在 `sparse_attention_architecture.html` 中，我們完成了以下三個主要分頁的互動式 SVG 電路架構圖及相關互動邏輯：

1. **Overview (系統總覽) SVG 圖與連結綁定**：
   - 繪製了 outermost 虛線邊框的 `chip_top`。
   - 繪製了亮黃色 (`#fbbf24`) 的 `Bus & Regs Controller`，其中列出了 APB 總線介面與狀態。
   - 繪製了深色背景與半透明藍邊的 `sparse_attention_core` 內部大容器。
   - 在核心內繪製了：
     - `qk_pair_streamer` (翡翠綠 `#10b981`，支援點擊跳轉至 `pair_streamer` 頁籤)
     - `qkv_feature_mem` (翡翠綠 `#10b981`，支援點擊跳轉至 `feature_mem` 頁籤)
     - `qk_dot_accumulator` (霓虹藍 `#3b82f6`，支援點擊跳轉至 `dot_accum` 頁籤)
     - `sparse_softmax_sv` (桃紅色 `#ec4899`，支援點擊跳轉至 `softmax_context` 頁籤)
     - `stats_counter` (黃綠色 `#84cc16`，支援點擊跳轉至 `stats_fifo` 頁籤)
   - 在核心右側繪製了藍灰色 (`#64748b`) 的 `Result FIFO` (支援點擊跳轉至 `stats_fifo` 頁籤)。
   - 實作了美觀且不重疊的訊號線 routing，並以箭頭標註關鍵訊號：`q_idx`、`k_idx`、`q_feature_vector`、`k_feature_vector`、`attention_score`、`context_value` 與 `v_feature_vector`、`valid_cnt` 等。
   - 設計了當滑鼠懸停 (hover) 於訊號線上時，訊號線與其文字標籤同步變為霓虹藍高亮，且箭頭會動態切換為藍色發光箭頭。

2. **QK Pair Streamer (索引產生器) SVG 細節圖**：
   - 左側繪製了 `pattern_controller`，其中展示了 FSM 狀態機與配置參數 (`WINDOW_SIZE=4`、`IDX_WIDTH=8`、`HEADS=4`)，以及內部的 `Address Gen Logic`。
   - 右側垂直堆疊了 4 組 Line Buffer 區塊：
     - `Block LB` (包含 `G_0` 到 `G_3` 共 4 個子區塊)
     - `Global Row LB` (包含 `Row_0` 到 `Row_3` 共 4 個子區塊)
     - `Butterfly LB` (包含 `B_0` 到 `B_7` 共 8 個子區塊)
     - `Global LB` (一個大的 `GLOBAL_INDEX_BUFFER`，深度為 128)
   - 底部繪製了梯形硬體圖樣的 `MUX Selector`。
   - 連接線繪製了 `k_idx` 輸出至 Line Buffers，以及 4 組緩衝器資料輸出經過 MUX，最終從 MUX 底部輸出 `selected_dout (buffer_dout)` 的完整匯流排。

3. **QKV Feature Memory (特徵記憶體) SVG 細節圖**：
   - 包含 `q_mem`、`k_mem`、`v_mem` 三個獨立 SRAM 區塊，皆標有 Dual-Port (1W / 1R) 與 `128 x 64b` 大小。
   - 頂部繪製了 `Write Controller & Input Interface`，展示寫入路徑上的 `qkv_we`、`qkv_sel`、`qkv_token_idx`、`qkv_feature_idx`、`qkv_data_in` 訊號如何解碼並分流寫入三組 SRAM。
   - 底部繪製了並行讀取路徑，當輸入 `q_read_idx`、`k_read_idx`、`v_read_idx` 定址時，三個 SRAM 同步並行輸出 `FEATURE_DIM` 維度的 `q_feature_vector [63:0]`、`k_feature_vector [63:0]`、`v_feature_vector [63:0]` 特徵向量。

4. **互動式樣式與 Traditional Chinese 文件**：
   - 在 CSS 中加入了 `.module-box`、`.signal-line` 及 `.signal-group` 等樣式，實現了 smooth hover 縮放與 shadow 發光效果。
   - 提供更詳細的各模組架構 Traditional Chinese 繁體中文說明於右側細節面版。

---

## 驗證方式 (How it was verified)

1. **靜態程式碼檢查**：
   - 檢查 SVG 各元素的坐標計算、寬度、高度以及 detours (例如 overview 中訊號線繞過 stats_counter)，確保排版乾淨、線條連接無重疊或交錯。
   - 檢查 SVG path 語法與 `marker-end` 綁定，確保箭頭渲染正確。
   - 檢查 class 名稱與 CSS 變數（已將 `:root` 的 `--color-stats` 由紫色改為黃綠色 `#84cc16` 以符合 brief 的設計需求）。
2. **互動點擊與跳轉機制**：
   - 確認 `<g class="module-box" onclick="switchTab('tab_id')">` 配置無誤，點擊可順暢調用 JavaScript `switchTab` 以重新渲染對應分頁的 SVG 與文件內容。

---

## 變動檔案 (Files changed)

- [sparse_attention_architecture.html](file:///C:/Users/HAO/Documents/人工智慧晶片報告/RTL/Rtl/sparse_attention_architecture.html)

---

## 自自我審查與發現 (Self-review findings)

- 在排版時注意到，若 streamer 與 memory 直接連線，會穿過中間的 `stats_counter` 區塊。因此，我們在 overview 訊號線的 path 中加入了左側與右側的迂迴路由 (detours)，從而避開了 stats 區塊，維持了硬體架構圖的高可讀性與美觀。
- 利用 CSS 動態 marker 覆寫技術，讓滑鼠懸浮在訊號線上時，箭頭也跟著發光變藍，顯著提升了介面的科技感與精緻度。

---

## 問題或疑慮 (Issues or concerns)

- 無，所有需求皆已按照 brief 規範完成，且保持了與原本 Task 1 的完美相容。
