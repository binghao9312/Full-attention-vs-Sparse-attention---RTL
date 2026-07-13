### Task 3: 繪製 Dot Accumulator 與 Softmax & Context SVG 圖
編寫點積管線與 Softmax 電路的 SVG 圖。

**Files:**
- Modify: `sparse_attention_architecture.html`

**Interfaces:**
- Consumes: Task 2 的 SVG 渲染架構。
- Produces: Dot Accumulator 與 Softmax FSM & Divider 的 SVG 圖與 Stats & Result FIFO 的 SVG 圖實作。

- [ ] **Step 1: 實作 QK Dot Accumulator SVG 圖**
  
  當 `tabId === 'dot_accum'` 時，在 `sparse_attention_architecture.html` 中繪製點積管線細節 SVG：
  - **Stage 0 (乘法單元)**：
    - `q_feature_vector` 與 `k_feature_vector` 的拆分信號輸入。
    - 4 個獨立的乘法器方框（`Multiplier Lane 0` 到 `3`），計算各維度乘積。
    - 乘積結果送到第一級暫存器 `product_reg [0:3]`（以時脈控制）。
  - **Stage 1 (累加與加法單元)**：
    - 繪製樹狀加法器（`Adder Tree`）或串聯加法電路計算 4 個 `product_reg` 的和 `score_sum`。
    - 結果輸出暫存器（將 `score_sum` 暫存輸出為 `attention_score`，並同步傳遞 `score_q_idx` 和 `score_k_idx`）。
  - 管線控制：繪製時脈與 `advance_ready` 控制線路，連接至 Stage 0 與 Stage 1 的暫存器。

- [ ] **Step 2: 實作 Softmax & Context SVG 圖**
  
  當 `tabId === 'softmax_context'` 時，在 `sparse_attention_architecture.html` 中渲染 Softmax 運算與除法器電路細節 SVG：
  - **FSM 狀態圖**：以狀態圓圈繪製 Collect, Update, Prepare, Divide, Output 狀態，並用箭頭標註狀態移轉條件（如 `scores_done`, `division_bit == 0`, `context_ready` 等）。
  - **計算路徑**：
    - 指數估算：`exp_lut` 查表模組，接收輸入差值。
    - 指數累加器與暫存列。
    - 加權和累加器（`row_weighted_sum`），與 V 向量（`v_feature_vector`）相乘並累加。
    - **非恢復型除法器 (Non-restoring Divider)**：繪製逐位（bit-serial）除法電路，包含減法器、左移暫存器、`division_bit` 計數器。

- [ ] **Step 3: 實作 Stats & Result FIFO SVG 圖**
  
  當 `tabId === 'stats_fifo'` 時，渲染統計計數器與結果 FIFO 的 SVG 細節圖：
  - 統計計數器：三個累加暫存器，分別是 `pair_count`、`cycle_count`、`mac_count`。
  - 結果 FIFO：繪製具有讀寫指標（`fifo_rd_ptr`, `fifo_wr_ptr`）的環狀佇列或 FIFO 緩衝區區塊，展示 `core_context_value` 如何寫入，以及外部 Bus 透過 `ADDR_RESULT_POP` 彈出數據。

- [ ] **Step 4: 手動檢查功能**
  
  在瀏覽器中點擊 `Dot Accumulator`、`Softmax & Context`、`Stats & Result FIFO` 分頁按鈕，確認對應的 SVG 電路圖均能正確、美觀地渲染出來，且頁籤切換完全正常。
