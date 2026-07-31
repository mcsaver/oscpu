(() => {
  "use strict";

  const dataNode = document.getElementById("rv64-data");
  if (!dataNode) {
    return;
  }

  const DATA = JSON.parse(dataNode.textContent);
  const instances = new Map(DATA.instances.map((item) => [item.id, item]));
  const files = new Map(DATA.files.map((item) => [item.path, item]));
  const transactions = new Map(DATA.transactions.map((item) => [item.id, item]));
  const timings = new Map(DATA.timings.map((item) => [item.id, item]));
  const FONT_SCALE_STORAGE_KEY = "rv64core-font-scale-v1";
  const FONT_SCALE_OPTIONS = ["standard", "large", "xlarge"];
  const FONT_SCALE_LABELS = {
    standard: "标准",
    large: "大",
    xlarge: "特大",
  };

  const state = {
    sidebarTab: "hierarchy",
    treeRoot: DATA.coreRoot,
    expanded: new Set(),
    activeTransaction: null,
    activeTiming: null,
    interfaceFilter: "all",
    signalFocus: "",
    searchResults: [],
    searchCursor: -1,
    waveCounter: 0,
    fontScale: "large",
    lastRouteKey: null,
    preserveViewOnce: false,
  };

  const elements = {
    body: document.body,
    sidebarBody: document.getElementById("sidebarBody"),
    main: document.getElementById("mainContent"),
    search: document.getElementById("globalSearch"),
    searchResults: document.getElementById("searchResults"),
    fontScaleButton: document.getElementById("fontScaleButton"),
    toast: document.getElementById("toast"),
    live: document.getElementById("liveStatus"),
  };

  const STATUS_LABELS = {
    Top: "生产实例树",
    Sim: "仿真专用",
    Check: "定向 Checker",
    Catalog: "Catalog-only",
    Header: "Header / Include",
    "Doc/Build": "文档 / 构建",
  };

  const CATEGORY_LABELS = {
    bus: "SoC 总线",
    cache: "缓存",
    common: "事实 ABI",
    control: "控制与恢复",
    core: "集成与架构状态",
    debug: "验证与观测",
    decode: "译码",
    execute: "执行",
    frontend: "取指前端",
    include: "全局定义",
    memory: "访存 / MMU",
    pipeline: "流水构件",
    regread_bypass: "寄存器读取",
    rename_allocate: "重命名与分配",
    scheduling: "调度",
    sim: "仿真集成",
    sram: "SRAM",
    writeback: "完成与退休",
    root: "目录入口",
  };

  const GROUP_LABELS = {
    clock_reset: "时钟 / 复位",
    axi: "AXI",
    fetch: "取指",
    dispatch: "派发 / 发射",
    memory: "访存",
    completion: "完成 / 退休",
    control: "控制 / 恢复",
    privilege: "CSR / 特权 / 中断",
    debug: "调试 / 观测",
    other: "其他",
  };

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function attr(value) {
    return escapeHtml(value);
  }

  function inlineCode(value) {
    return escapeHtml(value).replace(/`([^`]+)`/g, "<code>$1</code>");
  }

  function clampText(value, length = 110) {
    const text = String(value ?? "").replace(/\s+/g, " ").trim();
    return text.length > length ? `${text.slice(0, length - 1)}…` : text;
  }

  function displayInstance(node) {
    if (!node) {
      return "Unknown";
    }
    if (node.instance === node.module) {
      return node.module;
    }
    return `${node.instance} : ${node.module}`;
  }

  function categoryLabel(category) {
    return CATEGORY_LABELS[category] || category || "未分类";
  }

  function statusLabel(status) {
    return STATUS_LABELS[status] || status || "未知";
  }

  function routeHash(kind, id) {
    return `#/${kind}/${encodeURIComponent(id)}`;
  }

  function parseRoute() {
    const raw = window.location.hash.replace(/^#\/?/, "");
    if (!raw) {
      return { kind: "module", id: DATA.coreRoot };
    }
    const slash = raw.indexOf("/");
    if (slash < 0) {
      return { kind: "module", id: DATA.coreRoot };
    }
    const kind = raw.slice(0, slash);
    let id = raw.slice(slash + 1);
    try {
      id = decodeURIComponent(id);
    } catch (_error) {
      return { kind: "module", id: DATA.coreRoot };
    }
    return { kind, id };
  }

  function currentRoute() {
    return parseRoute();
  }

  function navigate(kind, id, options = {}) {
    const next = routeHash(kind, id);
    state.preserveViewOnce = Boolean(options.preserveView);
    closeSearch();
    closeSidebar();
    if (window.location.hash === next) {
      renderRoute();
      return;
    }
    if (options.replace) {
      history.replaceState(null, "", next);
      renderRoute();
    } else {
      window.location.hash = next;
    }
  }

  function ancestorIds(id) {
    const result = [];
    let cursor = instances.get(id);
    while (cursor) {
      result.unshift(cursor.id);
      cursor = cursor.parent ? instances.get(cursor.parent) : null;
    }
    return result;
  }

  function expandAncestors(id) {
    ancestorIds(id).forEach((item) => state.expanded.add(item));
  }

  function firstInstanceForModule(moduleName, contextId = DATA.coreRoot) {
    const moduleInfo = DATA.modules[moduleName];
    if (!moduleInfo || !moduleInfo.instances.length) {
      return null;
    }
    const inContext = moduleInfo.instances
      .filter((id) => id.startsWith(contextId))
      .sort((a, b) => a.length - b.length);
    if (inContext.length) {
      return inContext[0];
    }
    const inCore = moduleInfo.instances
      .filter((id) => id.startsWith(DATA.coreRoot))
      .sort((a, b) => a.length - b.length);
    return inCore[0] || moduleInfo.instances[0];
  }

  function announce(message) {
    elements.live.textContent = "";
    window.setTimeout(() => {
      elements.live.textContent = message;
    }, 10);
  }

  function showToast(message) {
    elements.toast.textContent = message;
    elements.toast.hidden = false;
    window.clearTimeout(showToast.timer);
    showToast.timer = window.setTimeout(() => {
      elements.toast.hidden = true;
    }, 2200);
  }

  function preferredFontScale() {
    try {
      const stored = window.localStorage.getItem(FONT_SCALE_STORAGE_KEY);
      if (FONT_SCALE_OPTIONS.includes(stored)) {
        return stored;
      }
    } catch (_error) {
      // file:// 或隐私模式可能禁用 storage；此时保留 HTML 的默认大字号。
    }
    const initial = elements.body.dataset.fontScale;
    return FONT_SCALE_OPTIONS.includes(initial) ? initial : "large";
  }

  function applyFontScale(scale, options = {}) {
    const next = FONT_SCALE_OPTIONS.includes(scale) ? scale : "large";
    state.fontScale = next;
    elements.body.dataset.fontScale = next;
    if (elements.fontScaleButton) {
      const label = FONT_SCALE_LABELS[next];
      elements.fontScaleButton.textContent = `字号 ${label}`;
      elements.fontScaleButton.setAttribute(
        "aria-label",
        `当前字号：${label}；点击切换字号`,
      );
      elements.fontScaleButton.title = `当前字号：${label}；点击切换`;
    }
    if (options.persist) {
      try {
        window.localStorage.setItem(FONT_SCALE_STORAGE_KEY, next);
      } catch (_error) {
        // 字号已经在当前页面生效，storage 失败不应阻断阅读。
      }
    }
    if (options.notify) {
      showToast(`已切换为${FONT_SCALE_LABELS[next]}字号`);
      announce(`字号已切换为${FONT_SCALE_LABELS[next]}`);
    }
  }

  function cycleFontScale() {
    const currentIndex = FONT_SCALE_OPTIONS.indexOf(state.fontScale);
    const next = FONT_SCALE_OPTIONS[(currentIndex + 1) % FONT_SCALE_OPTIONS.length];
    applyFontScale(next, { persist: true, notify: true });
  }

  function openSidebar() {
    elements.body.classList.add("sidebar-open");
    document.getElementById("menuButton")?.setAttribute("aria-expanded", "true");
    if (window.matchMedia("(max-width: 1100px)").matches) {
      window.setTimeout(() => {
        document.getElementById(`navTab-${state.sidebarTab}`)?.focus();
      }, 0);
    }
  }

  function closeSidebar(restoreFocus = false) {
    elements.body.classList.remove("sidebar-open");
    document.getElementById("menuButton")?.setAttribute("aria-expanded", "false");
    if (restoreFocus) {
      document.getElementById("menuButton")?.focus();
    }
  }

  function closeSearch() {
    elements.searchResults.hidden = true;
    state.searchCursor = -1;
  }

  function navTabs() {
    const tabs = [
      ["hierarchy", "层次"],
      ["transactions", "事务"],
      ["files", "源码"],
    ];
    return `
      <div class="nav-tabs" role="tablist" aria-label="导航视图">
        ${tabs
          .map(
            ([id, label]) => `
              <button
                id="navTab-${id}"
                type="button"
                class="nav-tab"
                role="tab"
                data-sidebar-tab="${id}"
                aria-selected="${state.sidebarTab === id}"
                aria-controls="sidebarBody"
                tabindex="${state.sidebarTab === id ? "0" : "-1"}"
              >${label}</button>
            `,
          )
          .join("")}
      </div>
    `;
  }

  function renderSidebar() {
    const route = currentRoute();
    let body = "";
    if (state.sidebarTab === "hierarchy") {
      if (route.kind === "module" && instances.has(route.id)) {
        state.treeRoot = route.id.startsWith(DATA.coreRoot) ? DATA.coreRoot : DATA.socRoot;
      }
      body = renderHierarchySidebar(route);
    } else if (state.sidebarTab === "transactions") {
      body = renderTransactionSidebar(route);
    } else {
      body = renderFileSidebar(route);
    }

    document.getElementById("navTabs").innerHTML = navTabs();
    elements.sidebarBody.setAttribute("aria-labelledby", `navTab-${state.sidebarTab}`);
    elements.sidebarBody.innerHTML = body;
  }

  function renderHierarchySidebar(route) {
    const root = instances.get(state.treeRoot);
    if (!root) {
      return `<p class="empty-state">实例树不可用。</p>`;
    }
    return `
      <div class="scope-links" aria-label="层次范围">
        <button type="button" class="scope-link" data-tree-scope="${attr(DATA.coreRoot)}">
          Core 根
        </button>
        <button type="button" class="scope-link" data-tree-scope="${attr(DATA.socRoot)}">
          SoC 根
        </button>
      </div>
      <p class="side-section-title">实例名 : 模块类型</p>
      <ul class="tree" role="tree" aria-label="${attr(displayInstance(root))} 实例树">
        ${renderTreeNode(root.id, route.kind === "module" ? route.id : "", 0)}
      </ul>
      <div class="callout callout--note" style="margin:16px 5px 0;color:#dbe8ef;background:rgba(255,255,255,.05);border-color:rgba(255,255,255,.16);border-left-color:#6da4c3">
        <span class="callout-label" style="color:#b9d4e4">Reading rule</span>
        树边表示“例化/包含”，不是数据流方向。数据流请看模块页的 Transaction 章节。
      </div>
    `;
  }

  function renderTreeNode(id, selectedId, depth) {
    const node = instances.get(id);
    if (!node) {
      return "";
    }
    const hasChildren = node.children.length > 0;
    const expanded = state.expanded.has(id);
    const selected = id === selectedId;
    return `
      <li role="treeitem" ${hasChildren ? `aria-expanded="${expanded}"` : ""} data-tree-id="${attr(id)}">
        <div class="tree-row" style="padding-left:${Math.min(depth, 12) * 9}px">
          <button
            type="button"
            class="tree-toggle"
            data-toggle-node="${attr(id)}"
            aria-label="${expanded ? "折叠" : "展开"} ${attr(displayInstance(node))}"
            ${hasChildren ? "" : "disabled"}
          >${hasChildren ? (expanded ? "−" : "+") : "·"}</button>
          <button
            type="button"
            class="tree-label"
            data-nav-module="${attr(id)}"
            aria-current="${selected ? "page" : "false"}"
          >
            <span class="tree-instance">${escapeHtml(node.instance)}</span>
            <span class="tree-module">${escapeHtml(node.module)}</span>
          </button>
        </div>
        ${
          hasChildren && expanded
            ? `<ul role="group" class="tree-group">${node.children
                .map((child) => renderTreeNode(child, selectedId, depth + 1))
                .join("")}</ul>`
            : ""
        }
      </li>
    `;
  }

  function renderTransactionSidebar(route) {
    return `
      <p class="side-section-title">跨模块 Transaction</p>
      <div class="side-list">
        ${DATA.transactions
          .map(
            (tx) => `
              <button
                type="button"
                class="side-item"
                data-nav-transaction="${attr(tx.id)}"
                aria-current="${route.kind === "transaction" && route.id === tx.id ? "page" : "false"}"
              >
                ${escapeHtml(tx.title)}
                <small>${escapeHtml(tx.kind)} · ${tx.phases.length} 个阶段</small>
              </button>
            `,
          )
          .join("")}
      </div>
    `;
  }

  function renderFileSidebar(route) {
    const groups = {};
    DATA.files.forEach((file) => {
      (groups[file.status] ||= []).push(file);
    });
    return `
      <p class="side-section-title">150 个 vsrc 文件</p>
      ${Object.entries(STATUS_LABELS)
        .map(([status, label]) => {
          const group = groups[status] || [];
          return `
            <details class="file-group" ${status === "Top" ? "open" : ""}>
              <summary>${escapeHtml(label)} · ${group.length}</summary>
              ${group
                .map(
                  (file) => `
                    <button
                      type="button"
                      class="file-item"
                      data-nav-file="${attr(file.path)}"
                      aria-current="${route.kind === "file" && route.id === file.path ? "page" : "false"}"
                    >${escapeHtml(file.path.replace("npc/rv64/vsrc/", ""))}</button>
                  `,
                )
                .join("")}
            </details>
          `;
        })
        .join("")}
    `;
  }

  function breadcrumbForInstance(node) {
    const ancestors = ancestorIds(node.id);
    return `
      <nav class="breadcrumb" aria-label="实例路径">
        ${ancestors
          .map((id, index) => {
            const item = instances.get(id);
            const current = index === ancestors.length - 1;
            return `
              ${index ? '<span class="breadcrumb-sep" aria-hidden="true">›</span>' : ""}
              <button
                type="button"
                data-nav-module="${attr(id)}"
                aria-current="${current ? "page" : "false"}"
                ${current ? "disabled" : ""}
              >${escapeHtml(item.module)}</button>
            `;
          })
          .join("")}
      </nav>
    `;
  }

  function genericBreadcrumb(label, parentLabel, parentTab) {
    return `
      <nav class="breadcrumb" aria-label="页面路径">
        <button type="button" data-sidebar-jump="${attr(parentTab)}">${escapeHtml(parentLabel)}</button>
        <span class="breadcrumb-sep" aria-hidden="true">›</span>
        <button type="button" aria-current="page" disabled>${escapeHtml(label)}</button>
      </nav>
    `;
  }

  function documentRibbon(kind) {
    return `
      <div class="document-ribbon">
        <span>RV64CORE-TRM-001 · ${escapeHtml(kind)}</span>
        <span>${escapeHtml(DATA.meta.revision)} · RTL snapshot ${escapeHtml(DATA.meta.snapshotDate)}</span>
      </div>
    `;
  }

  function identityRows(rows) {
    return `
      <table class="identity-table" aria-label="对象身份">
        <tbody>
          ${rows
            .map(
              ([label, value]) => `
                <tr>
                  <th scope="row">${escapeHtml(label)}</th>
                  <td>${inlineCode(value)}</td>
                </tr>
              `,
            )
            .join("")}
        </tbody>
      </table>
    `;
  }

  function section(number, title, body, id = "") {
    return `
      <section class="section" ${id ? `id="${attr(id)}"` : ""}>
        <h2 class="section-title">
          <span class="section-number">${escapeHtml(number)}</span>
          ${escapeHtml(title)}
        </h2>
        ${body}
      </section>
    `;
  }

  function statusBadges(moduleInfo) {
    return `
      <div class="badge-row" aria-label="事实等级">
        <span class="badge badge--fact">RTL FACT</span>
        <span class="badge">${escapeHtml(statusLabel(moduleInfo.status))}</span>
        <span class="badge">${escapeHtml(categoryLabel(moduleInfo.category))}</span>
        <span class="badge badge--gap">DYNAMIC TB / STA: GAP</span>
      </div>
    `;
  }

  function deriveFeatures(moduleInfo, node) {
    const rich = moduleInfo.rich || {};
    if (rich.features?.length) {
      return rich.features;
    }
    const result = [];
    result.push(`${statusLabel(moduleInfo.status)}；定义文件与实例身份分开记录`);
    result.push(`${moduleInfo.ports.length} 个 ANSI 端口，按握手/控制/架构观测分组`);
    if (moduleInfo.posedgeBlocks) {
      result.push(`${moduleInfo.posedgeBlocks} 个显式 posedge 时序块，存在本地状态边界`);
    } else {
      result.push("未检出显式 posedge 时序块；优先按组合 gate/wrapper 阅读");
    }
    if (node.children.length) {
      result.push(`${node.children.length} 个直接子实例，可在框图中继续钻取`);
    } else {
      result.push("叶子实例；继续学习应转向接口、状态与 transaction 终止条件");
    }
    result.push(`${moduleInfo.instances.length} 个当前 NpcTop 实例，不能用模块定义代替实例路径`);
    return result;
  }

  function deriveBoundary(moduleInfo) {
    const rich = moduleInfo.rich || {};
    if (rich.boundary) {
      return rich.boundary;
    }
    if (moduleInfo.posedgeBlocks) {
      return "该模块包含时序状态。必须区分组合输出、上升沿状态更新以及下一周期对下游可见三个相位。";
    }
    return "该模块主要是组合决策或结构装配。它可以改变选择与门控，但 transaction 生命周期通常由父模块或相邻队列持有。";
  }

  function productConfigCallout(moduleName) {
    const relevant = new Set([
      "NpcCoreTop",
      "OooFrontend",
      "OooRob",
      "OooControlPlane",
      "OooCsrAccessRequestMux",
      "OooStopPendingSequencer",
      "OooControlCommitSequencer",
      "OooControlEventApplySequencer",
      "CsrFile",
    ]);
    if (!relevant.has(moduleName) || !DATA.productConfig) {
      return "";
    }
    const config = DATA.productConfig;
    return `
      <div class="callout callout--note">
        <span class="callout-label">CURRENT PRODUCT CONFIGURATION</span>
        <code>OOO_CSR_QUEUE_HEAD=${escapeHtml(config.OOO_CSR_QUEUE_HEAD)}</code>，
        fallback <code>${escapeHtml(config.OOO_CSR_QUEUE_HEAD_FALLBACK)}</code>。
        ${escapeHtml(config.activeCsrPath)}
        <br>
        配置真源：<code>${escapeHtml(config.source)}</code>；
        fallback：<code>${escapeHtml(config.defineFallbackSource)}</code>。
      </div>
    `;
  }

  function moduleQuickFacts(moduleInfo, node) {
    return `
      <div class="quick-facts">
        ${[
          ["实例深度", String(node.depth)],
          ["直接子实例", String(node.children.length)],
          ["模块实例总数", String(moduleInfo.instances.length)],
          ["ANSI 端口", String(moduleInfo.ports.length)],
          ["posedge 块", String(moduleInfo.posedgeBlocks)],
          ["源码身份", statusLabel(moduleInfo.status)],
        ]
          .map(
            ([label, value]) => `
              <div class="quick-fact">
                <span class="quick-fact-label">${escapeHtml(label)}</span>
                <span class="quick-fact-value">${escapeHtml(value)}</span>
              </div>
            `,
          )
          .join("")}
      </div>
    `;
  }

  function diagramNode(node, variant = "") {
    if (!node) {
      return `
        <div class="diagram-node diagram-node--ghost" aria-label="无父实例">
          <span class="diagram-instance">—</span>
          <span class="diagram-module">层次根</span>
        </div>
      `;
    }
    const moduleInfo = DATA.modules[node.module] || {};
    return `
      <button
        type="button"
        class="diagram-node ${variant} category-${attr(moduleInfo.category || "root")}"
        data-nav-module="${attr(node.id)}"
      >
        <span class="diagram-instance">${escapeHtml(node.instance)}</span>
        <span class="diagram-module">${escapeHtml(node.module)}</span>
        <span class="diagram-role">${escapeHtml(clampText(moduleInfo.description, 64))}</span>
      </button>
    `;
  }

  function hierarchyDiagram(node) {
    const parent = node.parent ? instances.get(node.parent) : null;
    const children = node.children.map((id) => instances.get(id)).filter(Boolean);
    return `
      <div class="diagram-legend" aria-label="框图图例">
        <span class="legend-item"><span class="legend-swatch"></span>实例包含关系</span>
        <span class="legend-item"><span class="legend-swatch legend-swatch--transaction"></span>Transaction 数据流另见下节</span>
        <span class="legend-item"><span class="legend-swatch legend-swatch--control"></span>恢复/冲刷控制流另见下节</span>
      </div>
      <div class="hierarchy-diagram">
        <div class="hierarchy-track" role="group" aria-label="${attr(displayInstance(node))} 局部实例层次">
          ${diagramNode(parent, "diagram-node--ghost")}
          <span class="diagram-arrow" aria-hidden="true"></span>
          ${diagramNode(node, "diagram-node--current")}
          <span class="diagram-arrow" aria-hidden="true"></span>
          <div class="child-grid">
            ${
              children.length
                ? children.map((child) => diagramNode(child)).join("")
                : `<div class="callout" style="grid-column:1/-1;margin:0">这是当前实例树中的叶子模块。接口和 transaction 仍可能跨越父级边界。</div>`
            }
          </div>
        </div>
      </div>
      <div class="callout callout--caution">
        <span class="callout-label">CAUTION — 两种拓扑不能混淆</span>
        上图只回答“谁例化谁”。fetch、dispatch、completion、redirect 和 AXI 的方向由下面的
        transaction 图说明；层次树上的父子边不代表 valid/ready 流向。
      </div>
    `;
  }

  function relatedTransactions(moduleName) {
    return DATA.transactions.filter((tx) => tx.modules.includes(moduleName));
  }

  function transactionChips(items, activeId) {
    if (!items.length) {
      return `<p class="callout">当前模块没有绑定到预设学习 transaction；仍可从接口表和父级框图继续追踪。</p>`;
    }
    return `
      <div class="transaction-selector" aria-label="选择 transaction">
        ${items
          .map(
            (tx) => `
              <button
                type="button"
                class="transaction-chip"
                data-module-transaction="${attr(tx.id)}"
                aria-pressed="${tx.id === activeId}"
              >${escapeHtml(tx.shortTitle || tx.title)}</button>
            `,
          )
          .join("")}
      </div>
    `;
  }

  function transactionFlow(tx) {
    const sidePathCount = tx.phases.filter((phase) => phase.sidePath).length;
    return `
      <div class="callout callout--note">
        <span class="callout-label">TOP-TO-BOTTOM MODULE / DATA FLOW</span>
        从上到下依次阅读 transaction。每个阶段同时给出模块职责、进入的数据、状态变化、
        离开的数据和准入条件；阶段之间的向下箭头只表示主路径 payload/identity 的 handoff。
        若卡片内出现“并行分支”，它会独立闭合 owner 生命周期，不应误读为下一阶段的数据源。
        模块名按钮打开源码定义和完整实例清单，再由实例路径选择 lane0、lane1 或其他上下文。
      </div>
      <div class="flow-reading-key" aria-label="事务图阅读图例">
        <span><strong>${tx.phases.length}</strong> 个主路径阶段</span>
        <span><strong>4</strong> 个字段 / 阶段：输入、状态、输出、门控</span>
        <span><strong>${sidePathCount}</strong> 条并行 owner 分支；向下箭头只表示主路径</span>
      </div>
      <div class="transaction-flow-wrap">
        <ol class="transaction-flow" aria-label="${attr(tx.title)} transaction 阶段">
          ${tx.phases
            .map((phase, index) => {
              const moduleInfo = DATA.modules[phase.module];
              const source = moduleInfo?.source || "";
              const sidePath = phase.sidePath;
              const sideModuleInfo = sidePath ? DATA.modules[sidePath.module] : null;
              const sideSource = sideModuleInfo?.source || "";
              const isTerminal = index + 1 === tx.phases.length;
              const previousTransfer =
                index > 0 ? tx.phases[index - 1].transfer : tx.initiator;
              const dataIn = phase.dataIn || previousTransfer || "upstream payload";
              const stateChange = phase.stateChange || phase.event;
              const dataOut =
                phase.dataOut || phase.transfer || (isTerminal ? tx.terminal : "next phase payload");
              const guard = phase.guard || phase.edge || "event boundary";
              return `
                <li class="flow-step">
                  <article class="flow-step-card ${isTerminal ? "is-terminal" : ""}">
                    <header class="flow-step-header">
                      <div>
                        <span class="flow-step-index">PHASE ${String(index + 1).padStart(2, "0")} / ${String(tx.phases.length).padStart(2, "0")} · MODULE</span>
                        ${
                          source
                            ? `
                              <button
                                type="button"
                                class="flow-step-module flow-step-module-link"
                                data-nav-file="${attr(source)}"
                                title="打开模块定义与精确实例清单"
                              >${escapeHtml(phase.module)}</button>
                            `
                            : `<span class="flow-step-module">${escapeHtml(phase.module)}</span>`
                        }
                      </div>
                      <span class="flow-step-edge">
                        <strong>EDGE / LATENCY</strong>
                        ${escapeHtml(phase.edge || "event boundary")}
                      </span>
                    </header>
                    <p class="flow-step-event">${escapeHtml(phase.event)}</p>
                    <dl class="flow-data-grid">
                      <div class="flow-data-cell flow-data-cell--in">
                        <dt>DATA IN / IDENTITY</dt>
                        <dd>${escapeHtml(dataIn)}</dd>
                      </div>
                      <div class="flow-data-cell flow-data-cell--state">
                        <dt>STATE UPDATE / CHECK</dt>
                        <dd>${escapeHtml(stateChange)}</dd>
                      </div>
                      <div class="flow-data-cell flow-data-cell--out">
                        <dt>DATA OUT / PAYLOAD</dt>
                        <dd>${escapeHtml(dataOut)}</dd>
                      </div>
                      <div class="flow-data-cell flow-data-cell--guard">
                        <dt>GUARD / BACKPRESSURE</dt>
                        <dd>${escapeHtml(guard)}</dd>
                      </div>
                    </dl>
                    ${
                      sidePath
                        ? `
                          <aside
                            class="flow-side-path"
                            aria-label="${attr(sidePath.label || "并行数据流")}"
                          >
                            <header class="flow-side-path-header">
                              <span>${escapeHtml(sidePath.label || "PARALLEL BRANCH")}</span>
                              ${
                                sideSource
                                  ? `
                                    <button
                                      type="button"
                                      class="flow-side-path-module flow-step-module-link"
                                      data-nav-file="${attr(sideSource)}"
                                      title="打开并行分支模块定义与精确实例清单"
                                    >${escapeHtml(sidePath.module)}</button>
                                  `
                                  : `<strong class="flow-side-path-module">${escapeHtml(sidePath.module)}</strong>`
                              }
                            </header>
                            <p class="flow-side-path-note">
                              此分支从本阶段分出并独立结束；下方主路径箭头仍使用 DATA OUT / PAYLOAD。
                            </p>
                            <dl class="flow-side-data-grid">
                              <div class="flow-data-cell flow-data-cell--in">
                                <dt>BRANCH DATA IN</dt>
                                <dd>${escapeHtml(sidePath.dataIn)}</dd>
                              </div>
                              <div class="flow-data-cell flow-data-cell--state">
                                <dt>BRANCH STATE UPDATE</dt>
                                <dd>${escapeHtml(sidePath.stateChange)}</dd>
                              </div>
                              <div class="flow-data-cell flow-data-cell--out">
                                <dt>BRANCH DATA OUT</dt>
                                <dd>${escapeHtml(sidePath.dataOut)}</dd>
                              </div>
                              <div class="flow-data-cell flow-data-cell--guard">
                                <dt>BRANCH EXCLUSION / GUARD</dt>
                                <dd>${escapeHtml(sidePath.guard)}</dd>
                              </div>
                            </dl>
                          </aside>
                        `
                        : ""
                    }
                    <footer class="flow-step-transfer">
                      <span>${isTerminal ? "TRANSACTION TERMINAL" : "OUTBOUND HANDOFF PAYLOAD"}</span>
                      <strong>${escapeHtml(dataOut)}</strong>
                    </footer>
                  </article>
                  ${
                    isTerminal
                      ? ""
                      : `
                        <div class="flow-connector" aria-hidden="true">
                          <span>
                            <strong>HANDOFF → ${escapeHtml(tx.phases[index + 1].module)}</strong>
                            <small>${escapeHtml(dataOut)}</small>
                          </span>
                        </div>
                      `
                  }
                </li>
              `;
            })
            .join("")}
        </ol>
      </div>
      <div class="transaction-contract">
        <div class="contract-cell">
          <h4>Owner / Terminal</h4>
          <p><strong>${escapeHtml(tx.owner)}</strong><br>${escapeHtml(tx.terminal)}</p>
        </div>
        <div class="contract-cell">
          <h4>Backpressure</h4>
          <p>${escapeHtml(tx.backpressure)}</p>
        </div>
        <div class="contract-cell">
          <h4>Flush / Architectural effect</h4>
          <p>${escapeHtml(tx.flush)} ${escapeHtml(tx.architecturalEffect)}</p>
        </div>
      </div>
    `;
  }

  function renderTransactionForModule(moduleInfo, node) {
    const related = relatedTransactions(moduleInfo.name);
    if (!related.length) {
      return transactionChips([], "");
    }
    if (!state.activeTransaction || !related.some((tx) => tx.id === state.activeTransaction)) {
      state.activeTransaction = related[0].id;
    }
    const tx = transactions.get(state.activeTransaction);
    return `
      ${transactionChips(related, tx.id)}
      <p class="prose">${escapeHtml(tx.summary)}</p>
      ${transactionFlow(tx)}
      <p style="margin:10px 0 0">
        <button type="button" class="table-action" data-nav-transaction="${attr(tx.id)}">
          打开完整 transaction 数据页
        </button>
      </p>
    `;
  }

  function portLifecycle(port) {
    const group = GROUP_LABELS[port.group] || port.group;
    if (port.direction === "input") {
      return `${group}输入；由父级或上游持有，在对应握手/采样边沿消费。`;
    }
    if (port.direction === "output") {
      return `${group}输出；valid 为 0 时 payload 不形成有效 transaction。`;
    }
    return `${group}双向接口；必须结合模块注释和上层连接判断驱动边界。`;
  }

  function renderPorts(moduleInfo) {
    const groups = Object.entries(moduleInfo.portGroups).filter(([, count]) => count);
    const availableGroups = new Set(groups.map(([group]) => group));
    const filter =
      state.interfaceFilter === "all" || availableGroups.has(state.interfaceFilter)
        ? state.interfaceFilter
        : "all";
    state.interfaceFilter = filter;
    const ports = moduleInfo.ports.filter((port) => filter === "all" || port.group === filter);
    const collapsed = ports.length > 12;
    return `
      <div class="interface-groups" aria-label="接口分组筛选">
        <button type="button" class="interface-filter" data-interface-filter="all" aria-pressed="${filter === "all"}">
          全部 ${moduleInfo.ports.length}
        </button>
        ${groups
          .map(
            ([group, count]) => `
              <button
                type="button"
                class="interface-filter"
                data-interface-filter="${attr(group)}"
                aria-pressed="${filter === group}"
              >${escapeHtml(GROUP_LABELS[group] || group)} ${count}</button>
            `,
          )
          .join("")}
      </div>
      ${
        ports.length
          ? `
            <div class="table-wrap">
              <table class="data-table ${collapsed ? "ports-collapsed" : ""}" id="portTable">
                <thead>
                  <tr>
                    <th>信号</th>
                    <th>方向</th>
                    <th>位宽表达式</th>
                    <th>接口族</th>
                    <th>生命周期阅读提示</th>
                  </tr>
                </thead>
                <tbody>
                  ${ports
                    .map(
                      (port) => `
                        <tr data-port-name="${attr(port.name)}" class="${state.signalFocus === port.name ? "is-highlighted" : ""}">
                          <td><code>${escapeHtml(port.name)}</code></td>
                          <td>${escapeHtml(port.direction)}</td>
                          <td><code>${escapeHtml(port.width || "1 bit")}</code></td>
                          <td>${escapeHtml(GROUP_LABELS[port.group] || port.group)}</td>
                          <td>${escapeHtml(portLifecycle(port))}</td>
                        </tr>
                      `,
                    )
                    .join("")}
                </tbody>
              </table>
            </div>
            ${
              collapsed
                ? `<button type="button" class="table-action" data-toggle-ports aria-expanded="false">展开全部 ${ports.length} 个端口</button>`
                : ""
            }
          `
          : `<p class="callout">这个源文件没有可抽取的 ANSI module 端口，可能是 header、文档或非 ANSI 声明。</p>`
      }
    `;
  }

  function relevantTimings(moduleInfo, transaction = null) {
    let ids = [];
    if (transaction?.timingIds?.length) {
      ids.push(...transaction.timingIds);
    }
    ids.push(...(moduleInfo.timingIds || []));
    return [...new Set(ids)].filter((id) => timings.has(id));
  }

  function timingPanel(timingIds, activeId = null) {
    const available = timingIds.map((id) => timings.get(id)).filter(Boolean);
    if (!available.length) {
      state.activeTiming = null;
      return `
        <div class="callout callout--note">
          <span class="callout-label">NO MODULE-SPECIFIC TIMING</span>
          当前模块没有绑定 WaveDrom 教学图；这里不会借用其他模块的波形。可从关联 transaction
          或第 10 章时序图册继续学习。
        </div>
      `;
    }
    if (!activeId || !available.some((item) => item.id === activeId)) {
      activeId = available[0].id;
    }
    state.activeTiming = activeId;
    const timing = timings.get(activeId);
    const readingGuide = timing.wave?.foot?.text || "";
    return `
      <div class="wave-toolbar">
        <label class="field-label">
          WaveDrom 场景
          <select id="timingSelect">
            ${available
              .map(
                (item) => `
                  <option value="${attr(item.id)}" ${item.id === activeId ? "selected" : ""}>
                    ${escapeHtml(item.title)}
                  </option>
                `,
              )
              .join("")}
          </select>
        </label>
        <button type="button" class="action-button" style="color:var(--navy)" data-open-timing-chapter="${attr(timing.chapterHref)}">
          打开原讲义
        </button>
      </div>
      <div class="wave-host" id="waveHost" aria-label="${attr(timing.title)} WaveDrom"></div>
      ${
        readingGuide
          ? `
            <div class="callout callout--note timing-reading-guide">
              <span class="callout-label">HOW TO READ THIS CASE</span>
              ${escapeHtml(readingGuide)}
            </div>
          `
          : ""
      }
      <div class="signal-links" aria-label="时序信号">
        ${timing.signals
          .map(
            (signal) => `
              <button type="button" class="signal-link" data-signal-search="${attr(signal.name)}">
                ${escapeHtml(signal.name)}
              </button>
            `,
          )
          .join("")}
      </div>
      <h3 class="subsection-title">逐行文本替代</h3>
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr><th>信号</th><th>WaveJSON</th><th>数据标签</th></tr>
          </thead>
          <tbody>
            ${timing.signals
              .map(
                (signal) => `
                  <tr>
                    <td><code>${escapeHtml(signal.name)}</code></td>
                    <td><code>${escapeHtml(signal.wave)}</code></td>
                    <td>${escapeHtml((signal.data || []).join(" · ") || "—")}</td>
                  </tr>
                `,
              )
              .join("")}
          </tbody>
        </table>
      </div>
      <div class="callout">
        <span class="callout-label">EDGE SEMANTICS</span>
        WaveDrom 是当前 RTL 的教学模型。上升沿改变 owner/valid 后，消费者通常从下一周期观察新状态；
        可变延迟、仲裁等待和反压会拉长保持区，不得把示意长度当固定 latency。
      </div>
    `;
  }

  function renderWave(timingId) {
    const timing = timings.get(timingId);
    const host = document.getElementById("waveHost");
    if (!timing || !host) {
      return;
    }
    const index = state.waveCounter++;
    host.innerHTML = `<div id="WaveDrom_Display_${index}"></div>`;
    try {
      if (!window.WaveDrom || !window.WaveSkin) {
        throw new Error("WaveDrom runtime unavailable");
      }
      window.WaveDrom.RenderWaveForm(index, timing.wave, "WaveDrom_Display_", false);
      const svg = host.querySelector("svg");
      if (svg) {
        svg.setAttribute("role", "img");
        svg.setAttribute("aria-label", timing.title);
      }
    } catch (error) {
      host.innerHTML = `
        <p class="wave-fallback">
          WaveDrom 渲染失败：${escapeHtml(error.message)}。下方文本表仍保留完整 WaveJSON。
        </p>
      `;
    }
  }

  function deriveInvariants(moduleInfo) {
    const rich = moduleInfo.rich || {};
    if (rich.invariants?.length) {
      return rich.invariants;
    }
    const result = [
      "实例路径、模块类型与定义文件是三个不同身份；同一模块可以有多个实例。",
      "valid/ready 只有在同一周期同时成立时才发生 transaction handoff。",
    ];
    if (moduleInfo.posedgeBlocks) {
      result.push("时序状态只能在指定边沿更新；组合输入变化不能被描述成状态已经提交。");
    } else {
      result.push("本模块不拥有主要时序状态时，取消、重放与 exactly-once 资格必须回到父 owner 查证。");
    }
    result.push("静态 RTL 事实不自动升级为动态功能、综合、STA 或 PPA PASS。");
    return result;
  }

  function codeSequence(values, limit = 14) {
    const unique = [...new Set((Array.isArray(values) ? values : []).filter(Boolean))];
    if (!unique.length) {
      return "未检出";
    }
    const shown = unique.slice(0, limit);
    const remainder = unique.length - shown.length;
    return `${shown.map((item) => `<code>${escapeHtml(item)}</code>`).join("、")}${
      remainder ? `，另有 ${remainder} 项` : ""
    }`;
  }

  function portNameWithoutDirection(name) {
    return String(name || "").replace(/_(?:io|i|o)$/i, "");
  }

  function deriveHandshakePairs(moduleInfo) {
    const buckets = new Map();
    moduleInfo.ports.forEach((port) => {
      const clean = portNameWithoutDirection(port.name);
      const match = clean.match(/^(.*?)(?:_)?(valid|ready)$/i);
      if (!match || !match[1]) {
        return;
      }
      const stem = match[1].replace(/_+$/, "");
      const role = match[2].toLowerCase();
      if (!buckets.has(stem)) {
        buckets.set(stem, { stem, valid: [], ready: [] });
      }
      buckets.get(stem)[role].push(port);
    });
    return [...buckets.values()]
      .filter((item) => item.valid.length && item.ready.length)
      .sort((left, right) => left.stem.localeCompare(right.stem));
  }

  function deriveRequestResponseFamilies(moduleInfo) {
    const buckets = new Map();
    moduleInfo.ports.forEach((port) => {
      const clean = portNameWithoutDirection(port.name);
      const match = clean.match(
        /^(.*?)(?:_)?(request|response|req|resp|rsp)(?:_(.*))?$/i,
      );
      if (!match) {
        return;
      }
      const prefix = match[1].replace(/_+$/, "") || "default";
      const token = match[2].toLowerCase();
      const role = token === "request" || token === "req" ? "request" : "response";
      if (!buckets.has(prefix)) {
        buckets.set(prefix, { prefix, request: [], response: [] });
      }
      buckets.get(prefix)[role].push(port.name);
    });
    return [...buckets.values()]
      .filter((item) => item.request.length && item.response.length)
      .sort((left, right) => left.prefix.localeCompare(right.prefix));
  }

  function handshakeDirection(pair) {
    const valid = pair.valid[0];
    const ready = pair.ready[0];
    if (valid.direction === "output" && ready.direction === "input") {
      return "本模块向下游发送，必须保持 valid/payload 直到 ready";
    }
    if (valid.direction === "input" && ready.direction === "output") {
      return "本模块接收上游，只有 valid 与 ready 同拍为 1 才消费";
    }
    return "方向不是典型的一入一出，必须按接口表和父级连接复核";
  }

  function renderInterfaceAnswer(moduleInfo) {
    const pairs = deriveHandshakePairs(moduleInfo);
    const families = deriveRequestResponseFamilies(moduleInfo);
    const pairHtml = pairs.length
      ? `
        <p><strong>机械配对结果：</strong>共检出 ${pairs.length} 组同 stem 的 valid/ready。</p>
        <ul class="self-check-answer-list">
          ${pairs
            .map(
              (pair) => `
                <li>
                  <code>${escapeHtml(pair.valid[0].name)}</code> +
                  <code>${escapeHtml(pair.ready[0].name)}</code>：
                  ${escapeHtml(handshakeDirection(pair))}。
                </li>
              `,
            )
            .join("")}
        </ul>
      `
      : `
        <p><strong>机械配对结果：</strong>当前 ${moduleInfo.ports.length} 个 ANSI 端口名中，
        没有检出完整的同 stem valid/ready 对。它可能是组合 leaf、单向采样接口，或握手
        被父模块拆分；不能把任意 <code>*_valid</code> 单独当成 transaction fire。</p>
      `;
    const familyHtml = families.length
      ? `
        <p><strong>request/response 家族：</strong></p>
        <ul class="self-check-answer-list">
          ${families
            .map(
              (family) => `
                <li>
                  <code>${escapeHtml(family.prefix)}</code>：
                  request 侧 ${codeSequence(family.request, 8)}；
                  response 侧 ${codeSequence(family.response, 8)}。
                </li>
              `,
            )
            .join("")}
        </ul>
      `
      : `
        <p><strong>request/response 家族：</strong>端口名中没有同时出现可配对的
        <code>req/request</code> 与 <code>rsp/resp/response</code> 家族。</p>
      `;
    return `${pairHtml}${familyHtml}
      <p>真正的 handoff 条件始终是同一周期的 <code>valid &amp;&amp; ready</code>；
      名字配对只是导航线索，位宽、方向和组合门控以 5.0 接口表及 RTL 为准。</p>`;
  }

  function classifySequentialTargets(targets) {
    const groups = {
      identity: [],
      lifecycle: [],
      payload: [],
      other: [],
    };
    targets.forEach((target) => {
      const name = target.toLowerCase();
      if (
        /(owner|producer|pid|rob|token|epoch|generation|(^|_)gen|tag|(^|_)pc|addr|index|idx|slot|lane|rd_|rs[12])/.test(
          name,
        )
      ) {
        groups.identity.push(target);
      } else if (
        /(valid|ready|busy|state|phase|pending|count|head|tail|done|seen|active|full|empty|flush|kill|credit|ptr|counter)/.test(
          name,
        )
      ) {
        groups.lifecycle.push(target);
      } else if (
        /(data|payload|result|value|inst|insn|imm|mask|strb|cause|tval|fflags|csr|pte)/.test(
          name,
        )
      ) {
        groups.payload.push(target);
      } else {
        groups.other.push(target);
      }
    });
    return groups;
  }

  function renderStateAnswer(moduleInfo, node) {
    const targets = moduleInfo.sequentialTargets || [];
    const boundary = moduleInfo.rich?.boundary || deriveBoundary(moduleInfo);
    if (!moduleInfo.posedgeBlocks && !targets.length) {
      const parent = node.parent ? instances.get(node.parent) : null;
      return `
        <p><strong>直接结论：</strong>当前定义没有检出
        <code>always/always_ff @(posedge ...)</code>，
        因而本文件不拥有主要寄存状态。它的输出由组合输入或子模块输出决定。</p>
        <p>若输出需要跨反压周期保持，责任属于
        ${
          parent
            ? `相邻父实例 <code>${escapeHtml(displayInstance(parent))}</code> 或更下游的寄存/FIFO owner`
            : "消费它的下游寄存器、FIFO 或 transaction owner"
        }，不能因为本模块有 <code>valid</code> 端口就假定 payload 会自行保存。</p>
        <p><strong>模块边界：</strong>${escapeHtml(boundary)}</p>
      `;
    }
    if (!targets.length) {
      const parent = node.parent ? instances.get(node.parent) : null;
      return `
        <p><strong>直接结论：</strong>虽然文件中检出 ${moduleInfo.posedgeBlocks} 个
        <code>posedge</code> 观察块，但没有检出非阻塞赋值左值；因此当前静态证据不支持
        把这些块当作功能状态 owner。常见情况是 <code>OOO_ASSERT</code> 边沿检查。</p>
        <p>本模块可见输出主要来自组合连接或子模块；若需要跨反压保持，责任属于
        ${
          parent
            ? `父实例 <code>${escapeHtml(displayInstance(parent))}</code> 所连接的具体子 owner`
            : "下游寄存器、FIFO 或具体 transaction owner"
        }。若源码通过 task/宏隐藏非阻塞赋值，仍需在 8.0 源文件中人工确认。</p>
        <p><strong>模块边界：</strong>${escapeHtml(boundary)}</p>
      `;
    }
    const groups = classifySequentialTargets(targets);
    const rows = [
      ["身份 / 顺序线索", groups.identity],
      ["生命周期 / 控制线索", groups.lifecycle],
      ["数据 / 异常 payload 线索", groups.payload],
      ["其他寄存状态", groups.other],
    ].filter(([, values]) => values.length);
    return `
      <p><strong>直接结论：</strong>文件中有 ${moduleInfo.posedgeBlocks} 个 posedge 块；
      从非阻塞赋值左值机械提取到 ${targets.length} 个去重状态名。数组只显示 owner 名，
      不展开每个 entry。</p>
      <div class="self-check-state-groups">
        ${rows
          .map(
            ([label, values]) => `
              <p><strong>${escapeHtml(label)}：</strong>${codeSequence(values)}</p>
            `,
          )
          .join("")}
      </div>
      <p><strong>职责解释：</strong>${inlineCode(moduleInfo.rich?.summary || moduleInfo.description)}
      ${escapeHtml(boundary)}</p>
      <p>这些名字是定位线索，不等于完整语义：仍需查看 reset、enable、kill、优先级和
      同拍多写条件，才能回答“每个状态在什么边沿改变”。</p>
    `;
  }

  function renderFlushAnswer(moduleInfo, node, related) {
    const controlPorts = moduleInfo.ports
      .filter((port) => /(flush|kill|squash|cancel|clear|reset)/i.test(port.name))
      .map((port) => port.name);
    const hasAxi = moduleInfo.ports.some((port) => port.group === "axi");
    const transactionRules = related.length
      ? `
        <ul class="self-check-answer-list">
          ${related
            .map(
              (tx) => `
                <li><strong>${escapeHtml(tx.title)}：</strong>${escapeHtml(tx.flush)}
                terminal 是 ${escapeHtml(tx.terminal)}。</li>
              `,
            )
            .join("")}
        </ul>
      `
      : `
        <p>当前模块未绑定预设 transaction，因此不能仅凭端口名字宣称“全部撤回”或
        “全部 drain”。${moduleInfo.posedgeBlocks
          ? "先检查本模块保存的 valid/owner，再沿父级 ready/terminal 连接追踪。"
          : "本模块没有主要寄存状态，已接受事务的生命周期通常由父级或下游 owner 保持。"}</p>
      `;
    return `
      <p><strong>判断原则：</strong>handoff 之前可以通过 ready/valid 门控阻止事务出生；
      handoff 之后只能由真正的状态 owner 根据 kill 资格取消，或继续 drain 到定义好的
      terminal，不能把组合 <code>flush</code> 当成“时间倒流”。</p>
      ${transactionRules}
      <p><strong>本模块的取消线索端口：</strong>${codeSequence(controlPorts)}。</p>
      ${
        hasAxi
          ? `<p><strong>AXI 特例：</strong>AR/AW/W 一旦 <code>valid &amp;&amp; ready</code>
             被外部接受，就不能由 Core flush 撤回；owner 必须继续接收 R/B terminal，
             再决定结果提交、丢弃或只做 drain。</p>`
          : ""
      }
      <p>结构父实例是 ${
        node.parent
          ? `<code>${escapeHtml(displayInstance(instances.get(node.parent)))}</code>`
          : "当前 elaboration 根"
      }；结构父子关系本身不证明谁拥有 kill/drain 状态。</p>
    `;
  }

  function renderVisibilityAnswer(moduleInfo, related) {
    const architecturePorts = moduleInfo.ports
      .filter((port) => /(commit|retire|trap|exit)/i.test(port.name))
      .map((port) => port.name);
    const relatedRules = related.length
      ? `
        <ul class="self-check-answer-list">
          ${related
            .map(
              (tx) => `
                <li><strong>${escapeHtml(tx.title)}：</strong>局部 terminal /
                completion 是 ${escapeHtml(tx.terminal)}；架构效果是
                ${escapeHtml(tx.architecturalEffect)}。</li>
              `,
            )
            .join("")}
        </ul>
      `
      : `
        <p>本模块没有绑定模块专属 transaction。保守答案是：
        <code>done</code>、<code>complete</code>、response 或局部
        <code>valid &amp;&amp; ready</code> 只结束局部 transaction；普通指令仍要等
        ROB 按序 commit，CSR/trap/exit 则要等对应控制提交边界。</p>
      `;
    return `
      <p><strong>核心区别：</strong>completion 表示“结果或 terminal 已经回到 owner”；
      commit/retire 表示“它已经通过程序序、异常和控制门，允许改变体系结构可见状态”。</p>
      ${relatedRules}
      <p><strong>本模块的架构边界命名线索：</strong>${codeSequence(architecturePorts)}。
      即使名字含 <code>commit</code>，仍需同时检查 valid、异常、lane 前缀和 ready 条件。</p>
      ${
        ["bus", "cache", "memory"].includes(moduleInfo.category)
          ? `<p>总线 R/B 或 cache hit 只闭合访存层 transaction，不自动等价为 CPU 指令已退休；
             device 写副作用还必须服从具体外设的 AXI/寄存器合同。</p>`
          : ""
      }
      ${
        ["debug", "sim"].includes(moduleInfo.category)
          ? `<p>Debug/checker/simulation 观测信号不应反向成为架构状态 owner；
             “观察到完成”不能替代生产路径的 commit 证明。</p>`
          : ""
      }
    `;
  }

  function selfCheckItems(moduleInfo, node) {
    const parent = node.parent ? instances.get(node.parent) : null;
    const related = relatedTransactions(moduleInfo.name);
    const transactionOwners = [...new Set(related.map((tx) => tx.owner).filter(Boolean))];
    const boundary = moduleInfo.rich?.boundary || deriveBoundary(moduleInfo);
    const parentAnswer = parent
      ? `
        <p><strong>直接结论：</strong>直接父实例是
        <code>${escapeHtml(displayInstance(parent))}</code>，完整路径为
        <code>${escapeHtml(parent.id)}</code>。</p>
        <p><strong>重要区分：</strong>它首先是结构容器，不必然拥有本模块内部的 FIFO、
        FSM、ROB entry 或 AXI transaction。${escapeHtml(boundary)}</p>
        ${
          transactionOwners.length
            ? `<p><strong>关联 transaction 声明的 owner：</strong>${transactionOwners
                .map((item) => escapeHtml(item))
                .join("；")}。</p>`
            : `<p>当前没有预设 transaction owner 绑定；应从本页 4.0 的上下游连接和
               8.0 源码中的寄存状态继续定位。</p>`
        }
      `
      : `
        <p><strong>直接结论：</strong><code>${escapeHtml(node.id)}</code> 是当前
        elaboration 树的根，没有直接父实例。</p>
        <p>根节点负责提供结构入口；内部 transaction owner 仍由各子模块状态决定。
        ${escapeHtml(boundary)}</p>
      `;
    return [
      {
        question: `沿实例路径 ${node.id}，直接父实例是谁？它是否一定是 transaction owner？`,
        answer: parentAnswer,
        evidence: parent
          ? `实例树 \`${parent.id}\` → \`${node.id}\`；定义文件 \`${moduleInfo.source}\``
          : `实例树根 \`${node.id}\`；定义文件 \`${moduleInfo.source}\``,
      },
      {
        question: `${moduleInfo.name} 的 ${moduleInfo.ports.length} 个端口中，哪些组成 valid/ready 或 request/response 对？`,
        answer: renderInterfaceAnswer(moduleInfo),
        evidence: `5.0 INTERFACES AND SIGNAL GROUPS；\`${moduleInfo.source}\` ANSI 端口`,
      },
      {
        question: (moduleInfo.sequentialTargets || []).length && moduleInfo.posedgeBlocks
          ? `文件中 ${moduleInfo.posedgeBlocks} 个 posedge 块主要保存哪些身份、生命周期和 payload？`
          : (moduleInfo.sequentialTargets || []).length
            ? `从非阻塞赋值提取到的状态名由哪个边沿块保存，主要承担哪些身份、生命周期和 payload？`
          : moduleInfo.posedgeBlocks
            ? `文件中 ${moduleInfo.posedgeBlocks} 个 posedge 观察块是否真的保存功能状态？`
            : "该组合模块的输出由谁锁存？反压时 payload 由哪个相邻 owner 保持？",
        answer: renderStateAnswer(moduleInfo, node),
        evidence: `\`${moduleInfo.source}\` 的 posedge 计数与非阻塞赋值左值；7.0 DESIGN INVARIANTS`,
      },
      {
        question: "flush/kill 到达时，已 handoff 的 transaction 能撤回，还是只能 drain 到 terminal？",
        answer: renderFlushAnswer(moduleInfo, node, related),
        evidence: related.length
          ? `4.0 关联 transaction：${related.map((tx) => tx.title).join("、")}`
          : `\`${moduleInfo.source}\` 控制端口与父级 owner；当前无预设 transaction 绑定`,
      },
      {
        question: "哪个事件只表示完成，哪个事件才让结果对架构可见？",
        answer: renderVisibilityAnswer(moduleInfo, related),
        evidence: related.length
          ? `4.0 transaction terminal / architectural effect；7.0 invariants`
          : `本页接口与源码证据；全局 ROB/control commit 合同`,
      },
    ];
  }

  function renderSelfCheck(moduleInfo, node) {
    const items = selfCheckItems(moduleInfo, node);
    return `
      <div class="self-check-intro">
        <strong>使用方法：</strong>先根据实例树、接口表和时序图自行作答，再点击每题的
        “展开参考答案”。答案绑定当前实例与当前 RTL 静态快照；机械提取线索不会冒充
        testbench、综合或 STA 结论。
      </div>
      <ol class="question-list">
        ${items
          .map(
            (item, index) => `
              <li class="self-check-item">
                <div class="self-check-question">${escapeHtml(item.question)}</div>
                <details class="self-check-answer">
                  <summary>
                    <span>展开参考答案</span>
                    <span class="self-check-answer-tag">ANSWER ${String(index + 1).padStart(2, "0")}</span>
                  </summary>
                  <div class="self-check-answer-body">
                    ${item.answer}
                    <p class="self-check-evidence">
                      <strong>证据入口：</strong>${inlineCode(item.evidence)}
                    </p>
                  </div>
                </details>
              </li>
            `,
          )
          .join("")}
      </ol>
    `;
  }

  function sourceHref(path) {
    return `../../../${path}`;
  }

  function moduleSourceSection(moduleInfo) {
    return `
      <div class="source-card">
        <div>
          <span class="callout-label">DEFINITION FILE · ${escapeHtml(statusLabel(moduleInfo.status))}</span>
          <div class="source-path">${escapeHtml(moduleInfo.source)}</div>
          <p class="source-description">${inlineCode(moduleInfo.description)}</p>
        </div>
        <a class="source-link" href="${attr(sourceHref(moduleInfo.source))}">打开源文件</a>
      </div>
      <p style="margin:10px 0 0">
        <button type="button" class="table-action" data-nav-file="${attr(moduleInfo.source)}">
          打开文件数据页与全部实例反向索引
        </button>
      </p>
    `;
  }

  function revisionSection() {
    return `
      <div class="table-wrap">
        <table class="data-table revision-table">
          <thead><tr><th>Revision</th><th>日期</th><th>内容</th><th>验证边界</th></tr></thead>
          <tbody>
            <tr>
              <td>${escapeHtml(DATA.meta.revision)}</td>
              <td>${escapeHtml(DATA.meta.snapshotDate)}</td>
              <td>建立标准/大/特大三级阅读字号并默认使用大字号；统一放大 transaction 字段、导航、表格、Self-check 与 WaveDrom 标签，同时修复未定义的强调色变量。</td>
              <td>当前源码静态 elaboration、离线资源与可读性结构审计；未执行浏览器截图对比、RTL TB、综合、STA 或 PPA。</td>
            </tr>
            <tr>
              <td>Rev. C</td>
              <td>2026-07-29</td>
              <td>跟随当前产品默认 <code>OOO_CSR_QUEUE_HEAD=1</code>：新增 head0 CSR 队头事务、C0/C1/C2 时序和产品配置证据；层次 XML 改为从当前 filelist 重新生成并做新鲜度门禁。</td>
              <td>当前 NpcTop 静态 elaboration、源码/讲义/离线结构审计；未在本次文档更新中重跑 RTL TB、系统仿真、综合、STA 或 PPA。</td>
            </tr>
            <tr>
              <td>Rev. B</td>
              <td>2026-07-28</td>
              <td>补全 195 个具体实例的 Self-check 参考答案，覆盖父实例、握手对、时序状态、flush/drain 和 completion/commit。</td>
              <td>答案由当前实例树、ANSI 端口、非阻塞赋值左值和已审计 transaction 静态生成；动态验证边界不变。</td>
            </tr>
            <tr>
              <td>Rev. A</td>
              <td>2026-07-28</td>
              <td>从当时的 NpcTop Verilator XML、150 文件 atlas 与 37 个 WaveDrom 生成首版交互式技术参考。</td>
              <td>静态 elaboration / 文档审计；动态 TB、综合、STA、PPA 未在本次执行。</td>
            </tr>
          </tbody>
        </table>
      </div>
    `;
  }

  function footer() {
    return `
      <footer class="document-footer">
        <span>RV64CORE-TRM-001 · ${escapeHtml(DATA.meta.revision)} · 单文件离线交付</span>
        <span>WaveDrom ${escapeHtml(DATA.meta.waveDromVersion)} (MIT) · <button type="button" class="nav-button" style="padding:2px 5px;color:#cae5f5" data-show-license>第三方许可</button></span>
      </footer>
    `;
  }

  function renderModulePage(id) {
    const node = instances.get(id);
    if (!node) {
      return renderNotFound("实例", id);
    }
    const moduleInfo = DATA.modules[node.module];
    if (!moduleInfo) {
      return renderNotFound("模块定义", node.module);
    }
    expandAncestors(id);
    const rich = moduleInfo.rich || {};
    const features = deriveFeatures(moduleInfo, node);
    const timingIds = relevantTimings(moduleInfo);

    const html = `
      <article class="datasheet">
        ${documentRibbon("MODULE DATA SHEET")}
        ${breadcrumbForInstance(node)}
        <header class="datasheet-header">
          <div>
            <p class="part-kicker">${escapeHtml(categoryLabel(moduleInfo.category))} · MODULE DATA SHEET</p>
            <h1 class="part-title">${escapeHtml(moduleInfo.name)}</h1>
            <p class="part-subtitle">${inlineCode(rich.summary || moduleInfo.description)}</p>
            ${statusBadges(moduleInfo)}
          </div>
          ${identityRows([
            ["实例名", node.instance],
            ["模块类型", moduleInfo.name],
            ["实例路径", node.id],
            ["定义文件", moduleInfo.source],
            ["参数化类型", node.rawModule || moduleInfo.name],
          ])}
        </header>
        <div class="datasheet-body">
          ${section(
            "1.0",
            "GENERAL DESCRIPTION",
            `
              <div class="lead-grid">
                <div class="prose">
                  <p>${inlineCode(rich.summary || moduleInfo.description)}</p>
                  <p>${escapeHtml(deriveBoundary(moduleInfo))}</p>
                  <div class="callout callout--note">
                    <span class="callout-label">IDENTITY RULE</span>
                    当前页面描述具体实例 <code>${escapeHtml(node.instance)}</code>；
                    模块类型 <code>${escapeHtml(moduleInfo.name)}</code> 定义于
                    <code>${escapeHtml(moduleInfo.source)}</code>。同类型其他实例可能处在不同 lane 或父级上下文。
                  </div>
                  ${productConfigCallout(moduleInfo.name)}
                </div>
                <div>
                  <h3 class="subsection-title" style="margin-top:0">FEATURES</h3>
                  <ul class="features">
                    ${features.map((item) => `<li>${inlineCode(item)}</li>`).join("")}
                  </ul>
                </div>
              </div>
            `,
            "general-description",
          )}
          ${section("2.0", "QUICK FACTS", moduleQuickFacts(moduleInfo, node), "quick-facts")}
          ${section("3.0", "FUNCTIONAL BLOCK DIAGRAM", hierarchyDiagram(node), "block-diagram")}
          ${section("4.0", "THEORY OF OPERATION / TRANSACTION", renderTransactionForModule(moduleInfo, node), "transaction")}
          ${section(
            "5.0",
            "INTERFACES AND SIGNAL GROUPS",
            `
              <p class="prose">
                接口表来自当前 Verilog ANSI 端口声明。位宽保留宏表达式；“生命周期阅读提示”是教学分类，
                最终握手与边沿必须回到 RTL 连接确认。
              </p>
              ${renderPorts(moduleInfo)}
            `,
            "interfaces",
          )}
          ${section("6.0", "TIMING CHARACTERISTICS", timingPanel(timingIds, state.activeTiming), "timing")}
          ${section(
            "7.0",
            "DESIGN INVARIANTS AND CORNER CASES",
            `
              <ul class="invariant-list">
                ${deriveInvariants(moduleInfo).map((item) => `<li>${inlineCode(item)}</li>`).join("")}
              </ul>
              <div class="callout callout--caution">
                <span class="callout-label">VERIFICATION BOUNDARY</span>
                本页的实例、端口、posedge 数和直接子模块绑定当前源码；跨模块周期链属于静态结构推导。
                未运行本模块的新 TB、综合、STA 或 PPA，因此不能据此宣称动态或物理实现 PASS。
              </div>
            `,
            "invariants",
          )}
          ${section("8.0", "SOURCE EVIDENCE", moduleSourceSection(moduleInfo), "source-evidence")}
          ${section(
            "9.0",
            "SELF-CHECK QUESTIONS / ANSWERS",
            renderSelfCheck(moduleInfo, node),
            "self-check",
          )}
          ${section("10.0", "REVISION HISTORY", revisionSection(), "revision-history")}
        </div>
        ${footer()}
      </article>
    `;

    document.title = `${moduleInfo.name} · RV64 Core Interactive Datasheet`;
    return { html, timingId: state.activeTiming };
  }

  function renderTransactionPage(id) {
    const tx = transactions.get(id);
    if (!tx) {
      return renderNotFound("Transaction", id);
    }
    const primaryModule = DATA.modules[tx.phases[0]?.module] || null;
    const timingIds = [
      ...(tx.timingIds || []),
      ...(primaryModule?.timingIds || []),
    ].filter((item, index, values) => timings.has(item) && values.indexOf(item) === index);
    const participantRows = tx.modules.map((moduleName) => {
      const moduleInfo = DATA.modules[moduleName];
      return `
        <tr>
          <td><code>${escapeHtml(moduleName)}</code></td>
          <td>${escapeHtml(moduleInfo ? categoryLabel(moduleInfo.category) : "跨层状态")}</td>
          <td>${moduleInfo ? String(moduleInfo.instances.length) : "0"}</td>
          <td>${moduleInfo ? `<button type="button" class="table-action" data-nav-file="${attr(moduleInfo.source)}">定义 / 实例清单</button>` : "内嵌状态 / 无独立实例"}</td>
        </tr>
      `;
    });
    const html = `
      <article class="datasheet">
        ${documentRibbon("TRANSACTION DATA SHEET")}
        ${genericBreadcrumb(tx.title, "Transaction Index", "transactions")}
        <header class="datasheet-header">
          <div>
            <p class="part-kicker">${escapeHtml(tx.kind)} · TRANSACTION DATA SHEET</p>
            <h1 class="part-title">${escapeHtml(tx.title)}</h1>
            <p class="part-subtitle">${escapeHtml(tx.summary)}</p>
            <div class="badge-row">
              <span class="badge badge--derive">STRUCTURAL DERIVATION</span>
              <span class="badge badge--gap">DYNAMIC TRACE: GAP</span>
            </div>
          </div>
          ${identityRows([
            ["Transaction ID", tx.id],
            ["Initiator", tx.initiator],
            ["Owner", tx.owner],
            ["Terminal", tx.terminal],
            ["阶段数", String(tx.phases.length)],
          ])}
        </header>
        <div class="datasheet-body">
          ${section(
            "1.0",
            "GENERAL DESCRIPTION",
            `<div class="prose"><p>${escapeHtml(tx.summary)}</p><p><strong>架构可见边界：</strong>${escapeHtml(tx.architecturalEffect)}</p></div>`,
          )}
          ${section("2.0", "TRANSACTION FLOW", transactionFlow(tx))}
          ${section(
            "3.0",
            "CYCLE / HANDOFF TABLE",
            `
              <div class="table-wrap">
                <table class="data-table">
                  <thead><tr><th>阶段</th><th>模块 / Owner</th><th>事件</th><th>边沿或握手</th><th>向下游传递</th></tr></thead>
                  <tbody>
                    ${tx.phases
                      .map(
                        (phase, index) => `
                          <tr>
                            <td>C${index}</td>
                            <td><code>${escapeHtml(phase.module)}</code></td>
                            <td>${escapeHtml(phase.event)}</td>
                            <td>${escapeHtml(phase.edge)}</td>
                            <td>${escapeHtml(phase.transfer || (index + 1 === tx.phases.length ? "terminal" : "handoff"))}</td>
                          </tr>
                        `,
                      )
                      .join("")}
                  </tbody>
                </table>
              </div>
            `,
          )}
          ${section("4.0", "TIMING CHARACTERISTICS", timingPanel(timingIds, state.activeTiming))}
          ${section(
            "5.0",
            "PARTICIPATING MODULES",
            `
              <div class="table-wrap">
                <table class="data-table">
                  <thead><tr><th>模块类型</th><th>职责域</th><th>生产实例数</th><th>定义 / 精确实例入口</th></tr></thead>
                  <tbody>${participantRows.join("")}</tbody>
                </table>
              </div>
            `,
          )}
          ${section(
            "6.0",
            "CORNER CASES",
            `
              <div class="transaction-contract">
                <div class="contract-cell"><h4>Backpressure</h4><p>${escapeHtml(tx.backpressure)}</p></div>
                <div class="contract-cell"><h4>Flush / Kill</h4><p>${escapeHtml(tx.flush)}</p></div>
                <div class="contract-cell"><h4>Terminal</h4><p>${escapeHtml(tx.terminal)}</p></div>
              </div>
              <div class="callout callout--caution">
                <span class="callout-label">STATIC MODEL</span>
                阶段编号用于表达相对先后，不承诺每个相邻阶段固定相差一拍。队列等待、仲裁和 ready 反压可插入任意保持周期。
              </div>
            `,
          )}
          ${section("7.0", "REVISION HISTORY", revisionSection())}
        </div>
        ${footer()}
      </article>
    `;
    document.title = `${tx.title} · RV64 Transaction Datasheet`;
    return { html, timingId: state.activeTiming };
  }

  function renderFilePage(path) {
    const file = files.get(path);
    if (!file) {
      return renderNotFound("源文件", path);
    }
    const moduleInfo = file.module ? DATA.modules[file.module] : null;
    const instanceItems = moduleInfo
      ? moduleInfo.instances
          .map((id) => instances.get(id))
          .filter(Boolean)
          .map(
            (node) => `
              <tr>
                <td><code>${escapeHtml(node.instance)}</code></td>
                <td><code>${escapeHtml(node.id)}</code></td>
                <td><button type="button" class="table-action" data-nav-module="${attr(node.id)}">进入实例</button></td>
              </tr>
            `,
          )
          .join("")
      : "";
    const html = `
      <article class="datasheet">
        ${documentRibbon("SOURCE FILE DATA SHEET")}
        ${genericBreadcrumb(path.replace("npc/rv64/vsrc/", ""), "Source Index", "files")}
        <header class="datasheet-header">
          <div>
            <p class="part-kicker">${escapeHtml(statusLabel(file.status))} · SOURCE FILE</p>
            <h1 class="part-title" style="font-size:clamp(24px,3vw,38px)">${escapeHtml(path.split("/").pop())}</h1>
            <p class="part-subtitle">${inlineCode(file.description)}</p>
            <div class="badge-row">
              <span class="badge badge--fact">ATLAS FACT</span>
              <span class="badge">${escapeHtml(statusLabel(file.status))}</span>
              <span class="badge">${escapeHtml(categoryLabel(file.category))}</span>
            </div>
          </div>
          ${identityRows([
            ["完整路径", file.path],
            ["身份", statusLabel(file.status)],
            ["module 声明", file.module || "无"],
            ["NpcTop 实例数", moduleInfo ? String(moduleInfo.instances.length) : "0"],
            ["posedge 块", moduleInfo ? String(moduleInfo.posedgeBlocks) : "—"],
          ])}
        </header>
        <div class="datasheet-body">
          ${section(
            "1.0",
            "GENERAL DESCRIPTION",
            `
              <div class="prose"><p>${inlineCode(file.description)}</p></div>
              <div class="callout callout--caution">
                <span class="callout-label">FILE ≠ MODULE ≠ INSTANCE</span>
                文件是源码容器；module 是可复用定义；instance 才是 elaboration 后的硬件对象。
                编译在册不等于生产实例树可达，生产可达也不保证所有参数化功能臂都会活动。
              </div>
            `,
          )}
          ${section(
            "2.0",
            "SOURCE ACCESS",
            `
              <div class="source-card">
                <div class="source-path">${escapeHtml(file.path)}</div>
                <a class="source-link" href="${attr(sourceHref(file.path))}">打开源文件</a>
              </div>
            `,
          )}
          ${section(
            "3.0",
            "INSTANCE REVERSE INDEX",
            moduleInfo && moduleInfo.instances.length
              ? `
                <div class="table-wrap">
                  <table class="data-table">
                    <thead><tr><th>实例名</th><th>完整实例路径</th><th>动作</th></tr></thead>
                    <tbody>${instanceItems}</tbody>
                  </table>
                </div>
              `
              : `<p class="callout">当前 NpcTop 生产实例树中没有该文件对应的模块实例。身份为 ${escapeHtml(statusLabel(file.status))}。</p>`,
          )}
          ${
            moduleInfo
              ? section(
                  "4.0",
                  "INTERFACE SUMMARY",
                  `
                    <p>模块 <code>${escapeHtml(moduleInfo.name)}</code> 共抽取 ${moduleInfo.ports.length} 个 ANSI 端口。</p>
                    ${renderPorts(moduleInfo)}
                  `,
                )
              : ""
          }
          ${section("5.0", "REVISION HISTORY", revisionSection())}
        </div>
        ${footer()}
      </article>
    `;
    document.title = `${path.split("/").pop()} · RV64 Source Datasheet`;
    return { html, timingId: null };
  }

  function renderNotFound(kind, id) {
    document.title = `Not Found · RV64 Core Interactive Datasheet`;
    return {
      html: `
        <article class="datasheet">
          ${documentRibbon("ERROR")}
          <div class="empty-state">
            <h1>未找到${escapeHtml(kind)}</h1>
            <p><code>${escapeHtml(id)}</code></p>
            <button type="button" class="table-action" data-nav-module="${attr(DATA.coreRoot)}">返回 NpcCoreTop</button>
          </div>
        </article>
      `,
      timingId: null,
    };
  }

  function renderRoute() {
    const route = currentRoute();
    const routeKey = `${route.kind}:${route.id}`;
    const routeChanged = state.lastRouteKey !== null && state.lastRouteKey !== routeKey;
    if (routeChanged) {
      state.activeTransaction = null;
      state.activeTiming = null;
      if (!state.preserveViewOnce) {
        state.interfaceFilter = "all";
        state.signalFocus = "";
      }
    }
    state.lastRouteKey = routeKey;
    state.preserveViewOnce = false;
    let result;
    if (route.kind === "module") {
      result = renderModulePage(route.id);
      state.sidebarTab = "hierarchy";
    } else if (route.kind === "transaction") {
      result = renderTransactionPage(route.id);
      state.sidebarTab = "transactions";
    } else if (route.kind === "file") {
      result = renderFilePage(route.id);
      state.sidebarTab = "files";
    } else {
      result = renderModulePage(DATA.coreRoot);
    }
    elements.main.innerHTML = result.html;
    renderSidebar();
    window.scrollTo({ top: 0, behavior: "auto" });
    window.requestAnimationFrame(() => {
      if (result.timingId) {
        renderWave(result.timingId);
      }
      if (routeChanged) {
        const pageTitle = elements.main.querySelector("h1");
        if (pageTitle) {
          pageTitle.setAttribute("tabindex", "-1");
          pageTitle.focus({ preventScroll: true });
        }
      }
    });
    announce(document.title);
  }

  function buildSearchIndex() {
    const index = [];
    DATA.instances.forEach((node) => {
      index.push({
        type: "Instance",
        title: displayInstance(node),
        path: node.id,
        haystack: `${node.instance} ${node.module} ${node.id}`,
        kind: "module",
        id: node.id,
      });
    });
    Object.values(DATA.modules).forEach((moduleInfo) => {
      const target = firstInstanceForModule(moduleInfo.name);
      if (target) {
        index.push({
          type: "Module",
          title: moduleInfo.name,
          path: `${moduleInfo.source} · ${moduleInfo.instances.length} instance(s)`,
          haystack: `${moduleInfo.name} ${moduleInfo.source} ${moduleInfo.description}`,
          kind: "module",
          id: target,
        });
        moduleInfo.ports.forEach((port) => {
          index.push({
            type: "Signal",
            title: port.name,
            path: `${moduleInfo.name} · ${GROUP_LABELS[port.group] || port.group}`,
            haystack: `${port.name} ${moduleInfo.name} ${port.group} ${port.direction}`,
            kind: "module",
            id: target,
            signal: port.name,
            interfaceGroup: port.group,
          });
        });
      }
    });
    DATA.transactions.forEach((tx) => {
      index.push({
        type: "Transaction",
        title: tx.title,
        path: `${tx.kind} · ${tx.modules.join(" › ")}`,
        haystack: `${tx.title} ${tx.summary} ${tx.kind} ${tx.modules.join(" ")} ${tx.terminal} ${tx.flush}`,
        kind: "transaction",
        id: tx.id,
      });
    });
    DATA.files.forEach((file) => {
      index.push({
        type: "Source file",
        title: file.path.split("/").pop(),
        path: `${statusLabel(file.status)} · ${file.path}`,
        haystack: `${file.path} ${file.module || ""} ${file.description} ${file.status}`,
        kind: "file",
        id: file.path,
      });
    });
    return index;
  }

  const searchIndex = buildSearchIndex();

  function runSearch(rawQuery) {
    const query = rawQuery.trim().toLocaleLowerCase();
    if (!query) {
      closeSearch();
      return;
    }
    const terms = query.split(/\s+/).filter(Boolean);
    const typeRank = {
      Module: 0,
      Instance: 1,
      Transaction: 2,
      Signal: 3,
      "Source file": 4,
    };
    state.searchResults = searchIndex
      .filter((item) => {
        const haystack = item.haystack.toLocaleLowerCase();
        return terms.every((term) => haystack.includes(term));
      })
      .sort((a, b) => {
        const aStarts = a.title.toLocaleLowerCase().startsWith(query) ? 0 : 1;
        const bStarts = b.title.toLocaleLowerCase().startsWith(query) ? 0 : 1;
        return aStarts - bStarts || (typeRank[a.type] ?? 9) - (typeRank[b.type] ?? 9) || a.title.localeCompare(b.title);
      })
      .slice(0, 48);
    state.searchCursor = state.searchResults.length ? 0 : -1;
    renderSearchResults(query);
  }

  function renderSearchResults(query) {
    elements.searchResults.hidden = false;
    if (!state.searchResults.length) {
      elements.searchResults.innerHTML = `<p class="search-empty">没有匹配“${escapeHtml(query)}”的模块、实例、信号、transaction 或文件。</p>`;
      return;
    }
    elements.searchResults.innerHTML = `
      <p class="search-summary">${state.searchResults.length} 个结果 · Enter 打开 · Esc 关闭</p>
      ${state.searchResults
        .map(
          (item, index) => `
            <button
              type="button"
              class="search-result ${index === state.searchCursor ? "is-active" : ""}"
              data-search-index="${index}"
              role="option"
              aria-selected="${index === state.searchCursor}"
            >
              <span class="search-result-type">${escapeHtml(item.type)}</span>
              <span class="search-result-title">${escapeHtml(item.title)}</span>
              <span class="search-result-path">${escapeHtml(item.path)}</span>
            </button>
          `,
        )
        .join("")}
    `;
  }

  function chooseSearchResult(index) {
    const result = state.searchResults[index];
    if (!result) {
      return;
    }
    state.signalFocus = result.signal || "";
    state.interfaceFilter = result.interfaceGroup || "all";
    elements.search.value = "";
    navigate(result.kind, result.id, { preserveView: true });
  }

  function copyDeepLink() {
    const value = window.location.href;
    const fallback = () => {
      const field = document.createElement("textarea");
      field.value = value;
      field.setAttribute("readonly", "");
      field.style.position = "fixed";
      field.style.opacity = "0";
      document.body.appendChild(field);
      field.select();
      document.execCommand("copy");
      field.remove();
    };
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(value).catch(fallback);
    } else {
      fallback();
    }
    showToast("当前模块深链接已复制");
  }

  function showLicense() {
    const license = document.getElementById("thirdPartyLicense")?.textContent || "License text unavailable.";
    const page = `
      <article class="datasheet">
        ${documentRibbon("THIRD-PARTY NOTICE")}
        ${genericBreadcrumb("WaveDrom License", "Current Page", state.sidebarTab)}
        <div class="datasheet-body">
          ${section(
            "1.0",
            "WAVEDROM LICENSE",
            `<pre class="license-text">${escapeHtml(license)}</pre>`,
          )}
          <p><button type="button" class="table-action" data-history-back>返回</button></p>
        </div>
      </article>
    `;
    elements.main.innerHTML = page;
    window.scrollTo({ top: 0, behavior: "auto" });
  }

  document.addEventListener("click", (event) => {
    const target = event.target instanceof Element ? event.target : null;
    if (!target) {
      return;
    }
    const navModule = target.closest("[data-nav-module]");
    if (navModule) {
      navigate("module", navModule.dataset.navModule);
      return;
    }
    const navTransaction = target.closest("[data-nav-transaction]");
    if (navTransaction) {
      navigate("transaction", navTransaction.dataset.navTransaction);
      return;
    }
    const navFile = target.closest("[data-nav-file]");
    if (navFile) {
      navigate("file", navFile.dataset.navFile);
      return;
    }
    const toggle = target.closest("[data-toggle-node]");
    if (toggle) {
      const id = toggle.dataset.toggleNode;
      if (state.expanded.has(id)) {
        state.expanded.delete(id);
      } else {
        state.expanded.add(id);
      }
      renderSidebar();
      return;
    }
    const scope = target.closest("[data-tree-scope]");
    if (scope) {
      state.treeRoot = scope.dataset.treeScope;
      state.expanded.add(state.treeRoot);
      navigate("module", state.treeRoot);
      return;
    }
    const tab = target.closest("[data-sidebar-tab]");
    if (tab) {
      state.sidebarTab = tab.dataset.sidebarTab;
      renderSidebar();
      return;
    }
    const jump = target.closest("[data-sidebar-jump]");
    if (jump) {
      state.sidebarTab = jump.dataset.sidebarJump;
      renderSidebar();
      openSidebar();
      return;
    }
    const moduleTx = target.closest("[data-module-transaction]");
    if (moduleTx) {
      state.activeTransaction = moduleTx.dataset.moduleTransaction;
      const route = currentRoute();
      if (route.kind === "module") {
        const result = renderModulePage(route.id);
        elements.main.innerHTML = result.html;
        window.requestAnimationFrame(() => renderWave(result.timingId));
      }
      return;
    }
    const interfaceFilter = target.closest("[data-interface-filter]");
    if (interfaceFilter) {
      state.interfaceFilter = interfaceFilter.dataset.interfaceFilter;
      const route = currentRoute();
      const result = route.kind === "module" ? renderModulePage(route.id) : renderFilePage(route.id);
      elements.main.innerHTML = result.html;
      if (result.timingId) {
        window.requestAnimationFrame(() => renderWave(result.timingId));
      }
      return;
    }
    const togglePorts = target.closest("[data-toggle-ports]");
    if (togglePorts) {
      const table = document.getElementById("portTable");
      const collapsed = table?.classList.toggle("ports-collapsed");
      togglePorts.setAttribute("aria-expanded", String(!collapsed));
      togglePorts.textContent = collapsed ? `展开全部端口` : "收起端口表";
      return;
    }
    const searchResult = target.closest("[data-search-index]");
    if (searchResult) {
      chooseSearchResult(Number(searchResult.dataset.searchIndex));
      return;
    }
    const signalSearch = target.closest("[data-signal-search]");
    if (signalSearch) {
      elements.search.value = signalSearch.dataset.signalSearch;
      elements.search.focus();
      runSearch(elements.search.value);
      return;
    }
    const chapter = target.closest("[data-open-timing-chapter]");
    if (chapter) {
      window.location.href = chapter.dataset.openTimingChapter;
      return;
    }
    if (target.closest("[data-copy-link]")) {
      copyDeepLink();
      return;
    }
    if (target.closest("[data-print]")) {
      window.print();
      return;
    }
    if (target.closest("[data-font-scale-control]")) {
      cycleFontScale();
      return;
    }
    if (target.closest("[data-menu-open]")) {
      if (elements.body.classList.contains("sidebar-open")) {
        closeSidebar();
      } else {
        openSidebar();
      }
      return;
    }
    if (target.closest("[data-sidebar-close]")) {
      closeSidebar(true);
      return;
    }
    if (target.closest("[data-show-license]")) {
      showLicense();
      return;
    }
    if (target.closest("[data-history-back]")) {
      renderRoute();
    }
  });

  document.addEventListener("change", (event) => {
    const target = event.target;
    if (target instanceof HTMLSelectElement && target.id === "timingSelect") {
      state.activeTiming = target.value;
      const route = currentRoute();
      let result;
      if (route.kind === "module") {
        result = renderModulePage(route.id);
      } else if (route.kind === "transaction") {
        result = renderTransactionPage(route.id);
      } else {
        return;
      }
      elements.main.innerHTML = result.html;
      window.requestAnimationFrame(() => renderWave(result.timingId));
    }
  });

  elements.search.addEventListener("input", () => runSearch(elements.search.value));
  elements.search.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" && state.searchResults.length) {
      event.preventDefault();
      state.searchCursor = (state.searchCursor + 1) % state.searchResults.length;
      renderSearchResults(elements.search.value.trim());
    } else if (event.key === "ArrowUp" && state.searchResults.length) {
      event.preventDefault();
      state.searchCursor = (state.searchCursor - 1 + state.searchResults.length) % state.searchResults.length;
      renderSearchResults(elements.search.value.trim());
    } else if (event.key === "Enter" && state.searchCursor >= 0) {
      event.preventDefault();
      chooseSearchResult(state.searchCursor);
    } else if (event.key === "Escape") {
      closeSearch();
      elements.search.blur();
    }
  });

  document.addEventListener("keydown", (event) => {
    const target = event.target;
    const typing = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement;
    if (event.key === "/" && !typing) {
      event.preventDefault();
      elements.search.focus();
      return;
    }
    if (event.key === "Escape") {
      const sidebarWasOpen = elements.body.classList.contains("sidebar-open");
      closeSearch();
      closeSidebar(sidebarWasOpen);
      return;
    }
    if (event.altKey && event.key === "ArrowLeft") {
      const route = currentRoute();
      if (route.kind === "module") {
        const node = instances.get(route.id);
        if (node?.parent) {
          event.preventDefault();
          navigate("module", node.parent);
        }
      }
      return;
    }
    const navTab = target instanceof Element ? target.closest(".nav-tab") : null;
    if (navTab && ["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      event.preventDefault();
      const tabs = ["hierarchy", "transactions", "files"];
      const currentIndex = tabs.indexOf(navTab.dataset.sidebarTab);
      let nextIndex = currentIndex;
      if (event.key === "ArrowLeft") {
        nextIndex = (currentIndex - 1 + tabs.length) % tabs.length;
      } else if (event.key === "ArrowRight") {
        nextIndex = (currentIndex + 1) % tabs.length;
      } else if (event.key === "Home") {
        nextIndex = 0;
      } else if (event.key === "End") {
        nextIndex = tabs.length - 1;
      }
      state.sidebarTab = tabs[nextIndex];
      renderSidebar();
      document.getElementById(`navTab-${state.sidebarTab}`)?.focus();
      return;
    }
    const treeLabel = target instanceof Element ? target.closest(".tree-label") : null;
    if (!treeLabel) {
      return;
    }
    const labels = [...document.querySelectorAll(".tree-label")];
    const index = labels.indexOf(treeLabel);
    const id = treeLabel.dataset.navModule;
    const node = instances.get(id);
    if (event.key === "ArrowDown") {
      event.preventDefault();
      labels[Math.min(index + 1, labels.length - 1)]?.focus();
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      labels[Math.max(index - 1, 0)]?.focus();
    } else if (event.key === "ArrowRight" && node?.children.length) {
      event.preventDefault();
      if (!state.expanded.has(id)) {
        state.expanded.add(id);
        renderSidebar();
        document.querySelector(`[data-nav-module="${CSS.escape(id)}"]`)?.focus();
      } else {
        document.querySelector(`[data-nav-module="${CSS.escape(node.children[0])}"]`)?.focus();
      }
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      if (state.expanded.has(id)) {
        state.expanded.delete(id);
        renderSidebar();
        document.querySelector(`[data-nav-module="${CSS.escape(id)}"]`)?.focus();
      } else if (node?.parent) {
        document.querySelector(`[data-nav-module="${CSS.escape(node.parent)}"]`)?.focus();
      }
    } else if (event.key === " " && node?.children.length) {
      event.preventDefault();
      if (state.expanded.has(id)) {
        state.expanded.delete(id);
      } else {
        state.expanded.add(id);
      }
      renderSidebar();
      document.querySelector(`[data-nav-module="${CSS.escape(id)}"]`)?.focus();
    }
  });

  window.addEventListener("hashchange", renderRoute);

  state.expanded.add(DATA.coreRoot);
  expandAncestors(DATA.coreRoot);
  applyFontScale(preferredFontScale());
  if (!window.location.hash) {
    history.replaceState(null, "", routeHash("module", DATA.coreRoot));
  }
  renderRoute();
})();
