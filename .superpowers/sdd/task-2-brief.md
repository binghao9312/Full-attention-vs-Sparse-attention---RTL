### Task 2: 繪製 Overview 與 Pair Streamer/Feature Memory SVG 圖
編寫對應的分頁 SVG 圖像，實作點擊 Overview 元件會跳轉至對應頁籤的互動邏輯。

**Files:**
- Modify: `sparse_attention_architecture.html`

**Interfaces:**
- Consumes: Task 1 的基本網頁框架與 `switchTab(tabId)` 函數。
- Produces: Overview、Pair Streamer 與 Feature Memory 三個頁籤的完整 SVG 繪圖。

- [ ] **Step 1: 實作 Overview SVG 圖與連結綁定**
  
  在 `sparse_attention_architecture.html` 中實作 `renderContent(tabId)` 函數，當 `tabId === 'overview'` 時，生成頂層架構的 SVG 並置於 `#canvas-area`。
  
  該 SVG 需包含：
  - `chip_top` 的外框（最外層虛線框，顏色為淡灰白）。
  - 控制暫存器區塊：`Bus & Regs Controller`（亮黃色 `#fbbf24`）。
  - `sparse_attention_core` 內部的大方框，包含：
    - `qk_pair_streamer`（翡翠綠 `#10b981`）
    - `qkv_feature_mem`（翡翠綠 `#10b981`）
    - `qk_dot_accumulator`（霓虹藍 `#3b82f6`）
    - `sparse_softmax_sv`（桃紅色 `#ec4899`）
    - `stats_counter`（黃綠色 `#84cc16`）
  - 右側：`Result FIFO`（藍灰色）。
  - 箭頭連接線標明關鍵訊號（`q_idx`, `k_idx`, `q_feature_vector`, `k_feature_vector`, `attention_score`, `context_value`）。
  - 每個子模組的 SVG `<g class="module-box" onclick="switchTab('tab_id')">`，點擊能正確調用 `switchTab`。
  
  在 `<style>` 中加入懸停與發光樣式：
  ```css
  .module-box { cursor: pointer; transition: all 0.3s ease; }
  .module-box:hover rect { filter: drop-shadow(0 0 8px var(--glow-color, #3b82f6)); transform: translateY(-2px); }
  .signal-line { stroke: rgba(255, 255, 255, 0.25); stroke-width: 2; fill: none; }
  .signal-line:hover { stroke: #3b82f6; stroke-width: 3; filter: drop-shadow(0 0 5px #3b82f6); }
  ```

- [ ] **Step 2: 實作 QK Pair Streamer SVG 細節圖**
  
  當 `tabId === 'pair_streamer'` 時，渲染 Pair Streamer 內部細節 SVG：
  - 左側：`pattern_controller`。
  - 右側：4 組 Line Buffer 區塊：
    - `Block LB` (WINDOW_SIZE=4 組)
    - `Global Row LB` (WINDOW_SIZE=4 組)
    - `Butterfly LB` (IDX_WIDTH=8 組)
    - `Global LB` (1 組)
  - 底部：`MUX` 多路選擇器。
  - 連接線：`k_idx` 輸出至 Line Buffers，`selected_dout` 從 MUX 輸出為 `buffer_dout`。

- [ ] **Step 3: 實作 QKV Feature Memory SVG 細節圖**
  
  當 `tabId === 'feature_mem'` 時，渲染 Feature Memory 內部細節 SVG：
  - 包含 `q_mem`, `k_mem`, `v_mem` 三個獨立 SRAM 方塊。
  - 寫入路徑（含 `qkv_we`, `qkv_sel`, `qkv_token_idx`, `qkv_feature_idx`, `qkv_data_in`）。
  - 讀取路徑（含 `q_read_idx`, `k_read_idx`, `v_read_idx` 分別定址並行輸出 `FEATURE_DIM` 維度的特徵向量）。

- [ ] **Step 4: 手動檢查功能**
  
  驗證：
  1. 點擊 Overview 中的模組方框能跳轉至對應頁籤。
  2. 頁籤切換時 SVG 能平滑重新渲染且排版美觀、不重疊。
