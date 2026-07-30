# 派发日志

## 基本信息

- `task_id`: `rv64core-interactive-datasheet-20260728`
- `task_slug`: `rv64core-interactive-datasheet`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-07-28] `information-architecture-review` - `completed-gap`

- `owner_agent`: `/root/html_datasheet_ia_review`
- `trigger`: 用户要求层次钻取和 ADI datasheet 风格。
- `inputs`: 用户参考图、现有讲义交付范围。
- `access_boundary`: `no production RTL write`
- `action`: 设计顶栏、三栏导航、实例树、transaction 图、模块固定章节、deep-link、离线、移动端、打印和无 JS 验收合同。
- `evidence`: 明确要求 `instance_name : ModuleType`，并分离实例层次与 transaction 数据流。
- `handoff_to`: `/root`
- `notes`: 仅给 IA/验收建议，实际源码绑定由主节点完成。

### [2026-07-28] `interactive-implementation` - `completed`

- `owner_agent`: `/root`
- `depends_on`: `information-architecture-review`
- `inputs`: 当前讲义、150 文件 atlas、NpcTop XML、37 个 WaveDrom。
- `access_boundary`: `write docs/task-run only`
- `action`: 实现 CSS、JavaScript、Python generator/auditor；嵌入 WaveDrom runtime、skin、license 与全部 payload，生成单文件 HTML。
- `outputs`: `docs/rv64core/study/index.html` 及四个工具源文件。
- `evidence`: generator `150/136/195/8/37`、980947 bytes、PASS；external resources=0。
- `handoff_to`: `adversarial-review`
- `notes`: 没有修改 `npc/rv64/vsrc/**`。

### [2026-07-28] `adversarial-review-round-1` - `completed-gap`

- `owner_agent`: `/root/html_visual_adversarial_review`
- `depends_on`: `interactive-implementation`
- `inputs`: `index.html`、JS、CSS、generator、auditor。
- `access_boundary`: `read-only; no browser; no production RTL`
- `action`: 对抗检查 lane identity、filter state、timing provenance、print overflow、noscript 和 ARIA/focus。
- `outputs`: 0 P0、4 P1、3 P2。
- `evidence`: P1 分别绑定 transaction 实例猜测、筛选泄漏、无关 timing 回退和 A4 越界。
- `handoff_to`: `/root`
- `notes`: WSL shell ownership 已归还。

### [2026-07-28] `adversarial-fixes` - `completed`

- `owner_agent`: `/root`
- `depends_on`: `adversarial-review-round-1`
- `inputs`: reviewer findings。
- `access_boundary`: `write docs/task-run only`
- `action`: transaction 改模块定义级入口；route-local filter；删除 timing fallback；print 单列；修正 noscript、ARIA 与 route focus；强化 forbidden-marker 审计。
- `outputs`: 修订后的源文件和 `index.html`。
- `evidence`: generator、interactive audit、150/150 study audit、Python compile 与 JavaScript syntax 全部 PASS。
- `handoff_to`: `adversarial-review-round-2`

### [2026-07-28] `adversarial-review-round-2` - `completed`

- `owner_agent`: `/root/html_visual_adversarial_review`
- `depends_on`: `adversarial-fixes`
- `inputs`: 修订后 JS/CSS/auditor/index。
- `access_boundary`: `read-only; no browser; no production RTL`
- `action`: 定点复读原 4 个 P1 及相关 P2。
- `outputs`: 4 个 P1 全部关闭；0 个新 P0/P1。
- `evidence`: module-definition flow、route reset、no timing fallback、print grid、noscript 与 focus markers 均绑定真实行号。
- `handoff_to`: `/root`
- `notes`: 真实浏览器视觉/触控/打印预览仍为动态 GAP；WSL shell ownership已归还。

### [2026-07-28] `record-and-final-gates` - `completed-with-waiver`

- `owner_agent`: `/root`
- `depends_on`: `adversarial-review-round-2`
- `inputs`: 最终 HTML、审计结果、task-run。
- `access_boundary`: `write docs/task-run/memory only`
- `action`: 发布 project/NPC stored memory；首次定向 `RV64 Core 交互式 Datasheet`
  brief 因缺少独立 focus match fail-closed，随后以稳定 focus `本地 RV64 RTL 合同`
  获得 `ok=true/recall_status=complete`；移除临时 Python cache；运行全工作树与 scoped
  strict guard。
- `evidence`: 最终 stored update 为 project 48351 bytes/23 chunks、NPC 46263 bytes/57 chunks；
  bounded recall 2637/3200 tokens、PASS；全工作树 guard 因 711 个共享 dirty paths
  缺 `agent-system/rv64-linux/npc-dev` evidence 而 FAIL，10 个实际交付路径 scoped
  strict guard 为 `required_profiles=0`、PASS。
- `waiver`: 三个 profile 的触发文件均不属于本 HTML 任务的写入范围；不运行越权的
  agent/Linux/RTL 回归。豁免已同步 task report、project memory 与 NPC memory。
- `handoff_to`: 用户。

### [2026-07-28] `screenshot-defect-root-cause-and-fix` - `completed`

- `owner_agent`: `/root`
- `trigger`: 用户截图显示 WaveDrom 伪尖峰和 transaction 卡片横向溢出/标签重叠。
- `inputs`: 37 个 WaveDrom、transaction renderer、屏幕/打印 CSS、两层 HTML 审计器。
- `access_boundary`: `write docs/task-run/memory only; no production RTL`
- `action`: 规范化 9 章 71 个 wave 字段；新增 formatter；在 Markdown audit、generator
  和 payload audit 建立防回归闭环；transaction 改为语义有序列表与响应式网格。
- `outputs`: 修订后的 9 个讲义章节、5 个工具/样式源、README 和 981166-byte
  `index.html`。
- `evidence`: formatter 0 pending；study audit 150/150 + 37；interactive build/audit
  150/136/195/8/37、external resources=0；Python/JavaScript 语法 PASS。
- `handoff_to`: `screenshot-fix-adversarial-review`

### [2026-07-28] `screenshot-fix-browser-check` - `completed-gap`

- `owner_agent`: `/root`
- `depends_on`: `screenshot-defect-root-cause-and-fix`
- `access_boundary`: `Codex in-app browser; local file only`
- `action`: 尝试打开 `file://wsl$/Ubuntu/.../docs/rv64core/study/index.html`。
- `evidence`: 浏览器明确以 URL 安全策略拒绝本地 `file://`；未绕过、未切换其他浏览器
  表面，改用结构化布局和生成物审计。
- `gap`: 未取得真实 320/375 px、打印预览或触控截图。
- `handoff_to`: `screenshot-fix-adversarial-review`

### [2026-07-28] `screenshot-fix-adversarial-review` - `completed`

- `owner_agent`: `/root/html_visual_adversarial_review`
- `depends_on`: `screenshot-defect-root-cause-and-fix`
- `inputs`: formatter、两层审计、generator、JS/CSS 与最新单文件 HTML。
- `access_boundary`: `read-only; no production RTL; no browser-policy bypass`
- `action`: 定点寻找波形语义变化、嵌套 signal 漏检、生成物不同步、窄屏/打印溢出、
  键盘/读屏顺序和旧箭头回归。
- `outputs`: 0 P0、0 P1、0 P2；静态 PASS。
- `evidence`: 37 WaveDrom 无重复显式电平；8 transaction 无 `flow-arrow`、
  `min-width:max-content` 或绝对定位标签；CSS/JS 与生成页一致。
- `handoff_to`: `/root`
- `notes`: WSL shell ownership 已归还；动态浏览器视觉仍为 GAP。

### [2026-07-28] `screenshot-fix-record-and-guard` - `completed-with-waiver`

- `owner_agent`: `/root`
- `depends_on`: `screenshot-fix-adversarial-review`
- `inputs`: 最新 HTML、审计结果、review verdict、task-run 与 DB-backed memory。
- `access_boundary`: `write docs/task-run/memory only`
- `action`: 发布 project/NPC stored memory；运行 bounded npc non-history recall；再次运行
  全工作树与实际交付 path roots 的 strict guard。
- `evidence`: stored memory 已可召回新 981166-byte/hash、71 个 wave 字段和响应式
  transaction 合同；brief 为 2637/3200 tokens、`ok=true`；全工作树为
  `changed_paths=736/required_profiles=3`、FAIL，4 个实际交付 path roots 为
  `required_profiles=0`、PASS。
- `waiver`: `agent-system/rv64-linux/npc-dev` 均由共享工作树中本任务未触碰的路径触发；
  不把 HTML 视觉修复扩权为三套外部回归，也不把外部状态判为 PASS。
- `handoff_to`: 用户。

### [2026-07-28] `rev-b-self-check-and-dataflow` - `completed`

- `owner_agent`: `/root`
- `trigger`: 用户要求补齐 Self-check 答案，并修复 Features 出界、解释 ADD/DIV、
  将 transaction 改为纵向且补齐数据流。
- `inputs`: 195 个 elaborated instances、136 个 module definition、150 个 vsrc、
  8 条 transaction、37 个 WaveDrom 和用户三张视觉反例。
- `access_boundary`: `write docs/task-run/memory only; no production RTL`
- `action`: 生成 975 个可展开答案；提取 1218 个 sequential target；修复
  always/always_ff 识别；澄清 older DIV/younger ADD；把 transaction 改为纵向
  4-field 数据卡；修复 Features/lead-grid/callout 自适应换行。
- `outputs`: Rev. B generator/runtime/CSS/auditor、更新后的章节/README 和单文件 HTML。
- `evidence`: build 150/136/195/8/37、1054123 bytes；audit 51 phases、
  1 sidePath、208 fields、975 answers、1218 state targets、0 external resources；
  study/formatter/Python/JavaScript 全部 PASS。
- `handoff_to`: `rev-b-adversarial-review`

### [2026-07-28] `rev-b-adversarial-review` - `completed`

- `owner_agent`: `/root/html_visual_adversarial_review`
- `depends_on`: `rev-b-self-check-and-dataflow`
- `access_boundary`: `read-only; no production RTL; no browser-policy bypass`
- `action`: 检查 always_ff 状态结论、Store AW/W/B 全链、窄容器 CSS、ADD/DIV
  程序序语义、Self-check 原生交互与生成物一致性。
- `outputs`: 首轮 2 P1 + 1 P2；修复后进一步发现 Store owner tuple 与
  completion payload 混画 P1；最终回归 0 P0/P1/P2。
- `evidence`: `AxiDpiSlave=1/11`、`AxiVirtioBlk=2/16`；
  Store 主链为 bridge response → backend PID restore/formal WB → ROB，
  卡内 sidePath 只传 `{kind,token,epoch}` 到 collector；最终 audit PASS。
- `handoff_to`: `/root`
- `notes`: CSS/JS 与 index 内嵌逐字一致；动态 `file://` 浏览器视觉仍为 GAP；
  WSL shell ownership 已归还。

### [2026-07-28] `rev-b-record-and-guard` - `completed-with-waiver`

- `owner_agent`: `/root`
- `depends_on`: `rev-b-adversarial-review`
- `access_boundary`: `write docs/task-run/memory only`
- `action`: 更新 task-run；发布 project/NPC DB-backed memory；运行 bounded
  `npc` non-history brief；移除 Python cache；执行 full/scoped strict guard。
- `evidence`: stored memory 为 project 50591 bytes/24 chunks、NPC 47880 bytes/57
  chunks；brief 为 2637/3200 tokens、`ok=true`；full guard 为
  `changed_paths=764/required_profiles=3`、FAIL；4 个实际交付 path roots 为
  `changed_paths=4/required_profiles=0`、PASS。
- `waiver`: full guard 的 `agent-system/rv64-linux/npc-dev` 均由共享工作树中本任务
  未触碰的路径触发；不把本地 HTML 学习文档扩权成外部 Linux/RTL 回归，也不把其状态
  判为 PASS。
- `handoff_to`: 用户。
