### Task 4: 撰寫全模組繁體中文文字架構說明
為每一個分頁提供深入剖析的 RTL 解說文本。

**Files:**
- Modify: `sparse_attention_architecture.html`

**Interfaces:**
- Consumes: 所有分頁的 HTML/SVG 結構及 Task 2, 3 中已完成的基礎文字說明。
- Produces: 最終完美整合的 HTML 互動網頁，右側 `#info-area` 文字說明具備高度專業性與完整度。

- [ ] **Step 1: 驗證各分頁之繁體中文解說文本**
  
  檢查 `sparse_attention_architecture.html` 中所有分頁的 `infoArea.innerHTML`：
  - **Overview**: 需完整列出暫存器地址（`ADDR_CONTROL=0x00`, `ADDR_SEQ_LEN=0x01`, `ADDR_STATUS=0x05` 等），以及 `advance_ready` 握手機制。
  - **Pair Streamer**: 需詳細列出四種模式（Sliding Window, Dilated, Sliding Global, Butterfly）的定址特色。
  - **Feature Memory**: 需詳細描述並行雙埠特徵讀出機制。
  - **Dot Accumulator**: 需詳細描述 Stage 0 & 1 的 Pipeline 切分與 `advance_ready` 之阻塞傳播。
  - **Softmax & Context**: 需詳述指數 LUT（查表 delta 計算）、累加 Weighted Sum，以及 bit-serial Division 逐位除法。
  - **Stats & Result FIFO**: 需詳述 `pair_count`、`cycle_count`（依據 `pair_valid` 累加）及 FIFO 的 Push/Pop/Ready 握手。

- [ ] **Step 2: 進行微調與代碼清理**
  
  檢查網頁中是否有任何殘留的預留文字 (Placeholder) 或英文未翻譯部分，並將其全部中文化或精確專業化。

- [ ] **Step 3: 驗證整體網頁在瀏覽器中開啟之流暢度與功能**
  
  手動點擊所有分頁，確認排版完美，中文字體清晰易讀。
