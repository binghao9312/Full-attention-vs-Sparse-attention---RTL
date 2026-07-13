### Task 1: HTML 骨架與頁籤導覽列
建立基礎 HTML 架構、CSS 樣式變數、頁籤切換邏輯與控制面板。

**Files:**
- Create: `sparse_attention_architecture.html`

**Interfaces:**
- Produces: 包含頁籤切換邏輯的空白 HTML 頁面及基礎響應式佈局。

- [ ] **Step 1: 建立 HTML 骨架與 CSS 樣式**
  
  寫入 `sparse_attention_architecture.html` 的基本骨架與 CSS 暗黑科技風格：
  ```html
  <!DOCTYPE html>
  <html lang="zh-Hant">
  <head>
      <meta charset="UTF-8">
      <title>Sparse Attention RTL 架構分析圖</title>
      <style>
          :root {
              --bg-dark: #0f172a;
              --bg-panel: rgba(30, 41, 59, 0.7);
              --border-color: rgba(255, 255, 255, 0.1);
              --text-main: #f8fafc;
              --text-muted: #94a3b8;
              --color-ctrl: #fbbf24;
              --color-mem: #10b981;
              --color-alu: #3b82f6;
              --color-soft: #ec4899;
          }
          body {
              background-color: var(--bg-dark);
              color: var(--text-main);
              font-family: 'Inter', 'Segoe UI', system-ui, sans-serif;
              margin: 0;
              padding: 20px;
              overflow-x: hidden;
          }
          .dashboard {
              display: grid;
              grid-template-columns: 3fr 2fr;
              gap: 20px;
              height: calc(100vh - 120px);
          }
          /* Tab navigation styles */
          .tabs {
              display: flex;
              gap: 10px;
              margin-bottom: 20px;
              border-bottom: 1px solid var(--border-color);
              padding-bottom: 10px;
          }
          .tab-btn {
              background: none;
              border: none;
              color: var(--text-muted);
              padding: 10px 20px;
              cursor: pointer;
              font-weight: 600;
              transition: all 0.3s ease;
              border-radius: 6px;
          }
          .tab-btn.active {
              background: rgba(59, 130, 246, 0.2);
              color: var(--text-main);
              box-shadow: 0 0 10px rgba(59, 130, 246, 0.3);
          }
          .tab-content {
              display: none;
              animation: fadeIn 0.4s ease;
          }
          .tab-content.active {
              display: block;
          }
          @keyframes fadeIn {
              from { opacity: 0; transform: translateY(10px); }
              to { opacity: 1; transform: translateY(0); }
          }
          /* Layout components */
          .canvas-container {
              background: var(--bg-panel);
              border: 1px solid var(--border-color);
              border-radius: 12px;
              backdrop-filter: blur(8px);
              display: flex;
              justify-content: center;
              align-items: center;
              position: relative;
              overflow: hidden;
          }
          .info-panel {
              background: var(--bg-panel);
              border: 1px solid var(--border-color);
              border-radius: 12px;
              padding: 25px;
              overflow-y: auto;
              backdrop-filter: blur(8px);
          }
          h1 { margin-top: 0; font-size: 24px; color: var(--text-main); }
          p { line-height: 1.6; color: var(--text-muted); }
      </style>
  </head>
  <body>
      <h1>Sparse Attention RTL 電路與架構分析</h1>
      <div class="tabs" id="tab-nav"></div>
      <div class="dashboard">
          <div class="canvas-container" id="canvas-area"></div>
          <div class="info-panel" id="info-area"></div>
      </div>
      <script>
          // JavaScript for switching tabs will go here
      </script>
  </body>
  </html>
  ```

- [ ] **Step 2: 撰寫 Tab 切換機制與 JavaScript 初始化**
  
  在 `<script>` 中加入 Tab 的數據結構與導覽切換邏輯：
  ```javascript
  const tabsConfig = [
      { id: 'overview', name: 'Overview (系統總覽)' },
      { id: 'pair_streamer', name: 'Pair Streamer (索引產生器)' },
      { id: 'feature_mem', name: 'Feature Memory (特徵記憶體)' },
      { id: 'dot_accum', name: 'Dot Accumulator (點積管線)' },
      { id: 'softmax_context', name: 'Softmax & Context (權重與除法)' },
      { id: 'stats_fifo', name: 'Stats & Result FIFO' }
  ];

  function initTabs() {
      const nav = document.getElementById('tab-nav');
      tabsConfig.forEach((tab, index) => {
          const btn = document.createElement('button');
          btn.className = `tab-btn ${index === 0 ? 'active' : ''}`;
          btn.textContent = tab.name;
          btn.onclick = () => switchTab(tab.id);
          btn.dataset.id = tab.id;
          nav.appendChild(btn);
      });
      switchTab('overview');
  }

  function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(btn => {
          btn.classList.toggle('active', btn.dataset.id === tabId);
      });
      renderContent(tabId);
  }
  
  window.onload = initTabs;
  ```

- [ ] **Step 3: 手動檢查基本框架運作**
  
  使用瀏覽器開啟 `sparse_attention_architecture.html`，點擊按鈕，確認 class `active` 切換無誤，且無語法錯誤。
