# 任务报告

## 基本信息

- `task_id`: `rv64core-interactive-datasheet-20260728`
- `task_slug`: `rv64core-interactive-datasheet`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex /root`
- `started_at`: `2026-07-28`
- `updated_at`: `2026-07-28`

## 任务目标

- `source_request`: 在现有 RV64 Core 学习讲义基础上交付可离线打开的交互式 HTML；按实例层次逐级钻取，并借鉴 ADI 等半导体 datasheet 的信息结构。
- `goal`: 把当前 `NpcTop/NpcCoreTop` elaboration 层次、模块定义、事务拓扑、端口、源码图册和 WaveDrom 汇入一个可搜索、可深链接的单文件文档。
- `scope`: `npc/rv64/vsrc/**` 只读；新增或修改 `docs/rv64core/study/{index.html,README.md,tools/**}`；同步本 task-run 与 NPC/project memory。

## 选图说明

- `selected_template`: `custom: recall -> IA review -> data extraction -> single-file build -> static audit -> adversarial review -> record`
- `why_this_graph`: 用户要求同时解决层次钻取、跨模块 transaction、150 个源码文件、37 个时序图、离线交付和 datasheet 排版，单一文档生成节点不能给出足够证据。
- `dynamic_nodes_added`: `hierarchy-model`、`transaction-model`、`offline-bundle`、`interactive-static-audit`、`HTML-adversarial-review`
- `why_dynamic_nodes_were_needed`: 必须机械区分 file/module/instance 身份，并阻止外部资源、错 lane 跳转和无关时序图假绑定。

## 节点概览

| 节点 ID | 负责 Agent | 状态 | 输入 | 输出 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `recall-and-IA` | `/root` + 两名 advisor | `completed` | 现有讲义、参考图、当前 XML 层次、ADI datasheet 结构 | 三栏 IA、固定模块数据页、实例树/事务图分离合同 | advisor verdict |
| `hierarchy-model` | `/root` | `completed` | 当前 `NpcTop` XML、150 文件 atlas | 136 module、195 instance、双根 scope 与反向索引 | generator PASS |
| `transaction-model` | `/root` | `completed` | 讲义中的 RTL 事实与 WaveDrom | 8 条 transaction、51 个主阶段、1 条 sidePath、208 个数据字段、37 个 timing binding | payload audit PASS |
| `offline-bundle` | `/root` | `completed` | CSS、JavaScript、WaveDrom 3.6.2 runtime/skin/license | `docs/rv64core/study/index.html` 单文件 | 1054123 bytes、external resources=0 |
| `interactive-static-audit` | `/root` | `completed` | 最新 HTML 与 payload | 层次互反、route marker、离线资源、身份与计数检查 | `audit_interactive_datasheet.py` PASS |
| `adversarial-review` | `/root/html_visual_adversarial_review` | `completed` | 生成器、JS、CSS、审计器和最新 HTML | 首轮 4 个 P1 + 3 个 P2；修正后 0 P0/P1 | reviewer recheck PASS |
| `record` | `/root` | `completed-with-waiver` | 交付与静态证据 | README、task-run、stored memory、bounded recall、strict guard | scoped PASS；全工作树见豁免 |

## 关键产物

- `primary_artifact`: `docs/rv64core/study/index.html`
- `generator`: `docs/rv64core/study/tools/build_interactive_datasheet.py`
- `runtime_source`: `docs/rv64core/study/tools/interactive_datasheet.js`
- `stylesheet_source`: `docs/rv64core/study/tools/interactive_datasheet.css`
- `auditor`: `docs/rv64core/study/tools/audit_interactive_datasheet.py`
- `entrypoint`: `docs/rv64core/study/README.md`
- `production_rtl_changes`: `none`

## 实现者证据

- 生成器：`files=150`、`modules=136`、`instances=195`、`transactions=8`、
  `wavedrom=37`、`bytes=1054123`、`PASS`。
- 交互审计：上述计数一致，并验证 `transaction_phases=51`、
  `transaction_side_paths=1`、`transaction_data_fields=208`、
  `self_check_answer_slots=975`、`sequential_targets=1218`、
  `external_resources=0`、`PASS`。
- 讲义审计：`markdown_files=14`、`atlas_rows=150`、`covered_vsrc_files=150`、`wavedrom_blocks=37`、`PASS`。
- JavaScript：Node `vm.Script` 对 88940-byte 源文件解析成功。
- Python：生成、交互审计、讲义覆盖和 inventory 四个工具 `py_compile` 返回 0。

## 审查者闭环

首轮对抗审查发现：

1. transaction phase 按 module 类型猜具体实例，双 memory lane 可能跳错；
2. 接口筛选跨 route 残留；
3. 无 timing binding 的模块借用全局第一张图；
4. 长 transaction/hierarchy 图打印时可能越出 A4；
5. 无 JavaScript 加载提示、部分 ARIA 和 route 焦点仍可加强。

修正后：

- transaction 卡声明为 `MODULE-DEFINITION FLOW`，点击进入源码数据页和完整实例反向索引，不再猜 lane；
- route 切换复位接口筛选，不存在的 group 自动回退 `all`；
- 无绑定时显示 `NO MODULE-SPECIFIC TIMING`，不冒充本模块证据；
- print CSS 将层次和 transaction 改为单列文档流；
- 删除无 JS 加载残留，补齐 tab/tabpanel、tree leaf 和页面标题焦点。

审查者复读最新产物后给出：4 个原 P1 全部关闭，未发现新 P0/P1，静态范围 PASS。

## 用户截图缺陷修复跟进

用户随后给出两项真实视觉反例：

1. WaveDrom 保持电平被连续写成显式 `0`/`1`，浏览器把每段重新起笔，形成并不存在于
   事务语义中的窄尖峰；
2. transaction phase 使用固定宽单行、`min-width: max-content` 和独立箭头标签，
   导致普通窗口横向滚动，文字与相邻卡片重叠。

本轮从源头修复：

- 新增 `normalize_wavedrom_levels.py`，将 9 章、71 个受影响的 `"wave"` 字段规范为
  WaveDrom 保持符号 `.`；字符数和周期位置不变；
- `audit_vsrc_coverage.py` 检查 Markdown 源，生成器再对 payload 防御性规范化，
  `audit_interactive_datasheet.py` 对最终 HTML payload 复查，形成三层防回归闭环；
- transaction DOM 改为有序列表，交接边界和 handoff 文本收进本 phase 卡片；CSS 改为
  `auto-fit/minmax` 响应式网格，删除固定宽单行、独立箭头与绝对定位标签；
- README 增加 WaveDrom 规范化检查与 `--write` 修复入口。

跟进验证：

- formatter check：`files=0 fields=0`、PASS；
- study audit：150/150、37 WaveDrom、PASS；
- interactive build/audit：150 files、136 modules、195 instances、8 transactions、
  37 WaveDrom、981166 bytes、external resources=0、PASS；
- Python 5 个工具 `py_compile` 返回 0；JavaScript 65355 bytes 由 `vm.Script`
  解析成功；
- 独立审查者逐项复核 formatter、嵌套 signal、生成器兜底、最终 payload、语义 DOM、
  屏幕/打印 CSS 和 CSS/JS 内嵌一致性，结论为 0 P0/P1/P2、静态 PASS。

## Rev. B 学习增强与三张截图闭环

用户继续要求补齐 Self-check 答案，并针对 Features 出界、ADD/DIV 案例含混和横向事务图
难以承载数据流给出三张截图。本轮修改仍只发生在 `docs/rv64core/study/**`：

- 每个 elaborated module instance 的 5 道 Self-check 都改为原生
  `<details>/<summary>` 可展开答案，共 `195 × 5 = 975` 个答案槽；答案绑定父实例、
  端口握手对、状态 owner、kill/drain 与 completion/commit 区别，并给出源码证据入口；
- 生成器从非阻塞赋值机械提取 `1218` 个去重状态名。边沿识别同时覆盖
  `always @(posedge ...)` 和 `always_ff @(posedge ...)`；已复核
  `AxiDpiSlave=1/11`、`AxiVirtioBlk=2/16`
  （`posedgeBlocks/sequentialTargets`），不再把有功能状态的仿真模块误判为组合模块；
- Features 由 CSS columns 改为 container-adaptive grid，`lead-grid` 使用
  `auto-fit/minmax(min(100%,360px),1fr)`，callout/feature 长路径与 CamelCase 可断行；
- ADD/DIV 案例明确程序序为 `DIV(older) → ADD(younger)`：ADD 可先 formal-WB，
  但 `commit0` 必须是 older DIV，`commit1` 只有同一顺序窗口才可携带 younger ADD；
- transaction 改为全宽自上而下阅读，每个主阶段显示 Data In、State Update、
  Data Out、Guard。最终 8 条 transaction 共 51 个主阶段；Store 额外有一条卡内
  owner-lifetime sidePath，因此共有 208 个显式数据字段。

独立审查首先发现两项 P1 和一项静态 P2：

1. `always_ff` 未计入 posedge，导致有 `sequentialTargets` 的模块出现错误答案；
2. Store 的初版纵向图漏掉 arbiter B 返回 bridge 的阶段；
3. 固定两栏 `lead-grid` 在 sidebar 后的 981 px 临界区仍可能被挤压。

修正后，审查者又用 RTL 端口找到 Store 数据身份反例：collector 实际只携带
`{kind, token, epoch}`，不能与 `ProducerId/error/fault` 主完成链混画。最终模型把
phase 7 的 `OooIntBackend` 画成明确分叉：

- 主完成链：bridge response + MIQ/live table exact match，按 token 恢复
  `ProducerId/ROB`，生成 formal memory WB 与 SQ terminal，再进入 `OooRob`；
- owner-lifetime 分支：只把 `{kind, token, epoch}` 送入
  `OooMemOwnerTerminalCollector`，dequeue 后由 tracker 回收 owner；明确不携带
  exception payload，也不向 ROB 供数。

同一审查者回归最终 `1054123`-byte HTML 后确认该 P1 关闭；内嵌 CSS/JS 与 tools
源逐字一致，51 phases、1 sidePath、208 fields、975 answers、0 external resources
均由交互审计复查，最终静态范围为 0 P0/P1/P2。

## 当前阻塞点

- `blockers`: 无。
- `risk_assessment`: 已尝试使用 Codex 内置浏览器打开本地单文件，但 `file://` URL 被
  浏览器安全策略拒绝；没有绕过该限制。因此真实 320/375 px 截图、触控和打印预览仍为
  GAP。交互结构、响应式布局合同、波形编码和离线合同有静态证据；动态 RTL TB、综合、
  STA 与 PPA 也不在本文档修复范围。
- `guard_waiver`: 全工作树 strict guard 已再次实际运行，因共享脏工作树 764 个 changed
  paths 中存在本任务未触碰的 agent-system、Linux 和 NPC 开发文件，要求
  `agent-system/rv64-linux/npc-dev` 新 profile evidence。本任务没有修改这些范围，
  不以文档请求扩权运行三套耗时回归；相同 guard 对 docs、task-run 与两份 memory
  共 4 个实际交付 path root 执行 strict scoped 检查为 `required_profiles=0`、PASS。
  该豁免已同步 project/NPC memory。

## 收尾结论

- `final_result`: `completed-with-browser-policy-and-full-worktree-guard-gap`
- `evidence_summary`: generator、交互审计、150/150 讲义审计、JavaScript/Python 语法、
  双轮实现者/审查者复核、stored memory 发布、bounded non-history recall 和 scoped
  strict guard 全部 PASS；全工作树 guard 的三个外部 profile 触发已显式豁免。
- `notes`: ADI 仅作为信息架构参考，没有复制商标或专有版式；WaveDrom 3.6.2 MIT license 已内嵌在单文件 third-party notice 中。
