# 本地 RV64 CPU RTL/验证子任务 `hist-qh-stop-hold-final-review-v1`

- RV64 RTL/证据对象：独立复核本地 RV64 queue-head CSR 从 owner birth 到 C0/C1/C2 的 stop state 与 owner-to-busy 双合同，验证八个 compile-success RTL 配置是否足以拒绝 historical-pre-T3U younger lane1 CSR overlap，并判断 HIST-SER-QH-STOP-HOLD-DROP 是否只应提升到 bounded VD3。
- 流水线配置：任务类型 `read-only-review`；执行模式 `workspace-files`（默认只读探索；仅按声明路径与命令读取）
- 结论首行：`RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<testbench/仿真/综合/STA 结果>｜范围=<PASS/GAP/inconclusive>`

## 合同证据绑定

- 合同 JSON 路径：`.github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/subagent-contracts/hist-qh-stop-hold-final-review-v1.json`
- 合同 JSON SHA-256：`f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`
- 上述 SHA-256 只绑定该 JSON 契约文件；不绑定设计 spec、`contract.md`、RTL、测试或其它上下文文件。

## 本地 RTL 输入、动作与产物

RTL/spec/TB/evidence 输入路径：
- npc/rv64/vsrc/control/OooStopPendingSequencer.v
- npc/rv64/vsrc/frontend/OooFrontendRunGate.v
- npc/rv64/vsrc/frontend/OooFrontend.v
- npc/rv64/vsrc/control/OooControlPlane.v
- npc/rv64/vsrc/control/OooPendingDrainResolveGate.v
- npc/rv64/testbench/Makefile
- npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv
- npc/rv64/design/specs/ooo-stop-pending-sequencer.md
- npc/rv64/design/arch/serialize-at-retire-phase1.md
- npc/rv64/design/arch/historical-defect-backfill-ledger.json
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop
- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/task-report.md
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/hypothesis.md
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/subagent-contracts/hist-qh-stop-hold-final-review-v1.json

RTL/证据输出路径：
- 无（只读）

工程命令：
- command=rg; mode=read-only
- command=sed; mode=read-only
- command=sha256sum; mode=read-only

工程命令用途（固定枚举）：
- rg: purpose=search-allowed-paths; label=只读检索允许路径
- sed: purpose=view-selected-lines; label=只读查看指定文本行
- sha256sum: purpose=hash-declared-artifact; label=计算已声明产物哈希

`read-only` 节点只运行不落盘的源码与日志查询；`sed -i`、重定向和其它写型选项不属于该节点命令集合。

工程输入仅来自上列工作区路径；工程输出仅进入上列 RTL/证据输出路径。

## RV64 RTL 必读材料

- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/task-report.md
- .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/hypothesis.md
- npc/rv64/design/specs/ooo-stop-pending-sequencer.md
- npc/rv64/design/arch/historical-defect-backfill-ledger.json

## RV64 微架构复核边界

- 报告 `unknowns`、显式假设、RTL/TB 反例、替代微架构解释、置信度及其本地证据基础。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不设置固定发现数量上限；不得截断仍影响 RTL 结论的 blocker、反例或覆盖洞。
- 缺少必要上下游 RTL/spec/TB 时返回 `scope_extension_request`，列出所需路径、命令和对应流水线原因。
- 可以提出合同未预设的微架构解释或设计方案，但不执行合同未列出的工程动作，也不扩大结论范围。

## RV64 RTL 交付

- 本地 RV64 RTL 交付：逐拍复核 owner birth、stop state、RunGate orphan/busy/can_run、真实 lane1 capture 与 C0/C1/C2 raw 计数，指出任何假绿或遗漏 root。
- 本地 RV64 RTL 交付：核对 current、drop-stop-hold、drop-RunGate-owner、historical-pre-T3U 四种语义的 source transform、compile receipt、assertion on/off oracle 和 replay identity。
- 本地 RV64 RTL 交付：给出 VD3 PASS、GAP 或 inconclusive 结论；若 PASS，明确不扩展到 VD4、formal、full-system、architecture-stable 或 PPA；若发现反例，提供具体 RTL/TB/evidence 路径与 scope_extension_request。

## RV64 RTL 判定条件

- 本地 RV64 RTL 判定：不得把 hold-only bounded survival 解释为 production hold 可删除或 PPA 等价。
- 本地 RV64 RTL 判定：negative case 必须 compile-success，并由既有 assertion 或逐拍 raw product-topology observation 拒绝，而不是编译失败或事件去重。
- 本地 RV64 RTL 判定：必须审查 historical-pre-T3U 与历史源码两处缺失项的对应关系、ordinary drain root 为零的因果纠偏以及 ledger VD3 定义。

## 最终技术回复

- 第一行严格使用上方“对象｜周期/配置｜TB/EDA 观测｜范围”格式。
- 若本地 RV64 RTL 证据 JSON 的字段在定向 Python 单测中得到非预期返回结果，写明 CPU 证据对象、具体 schema 字段、工作区相对路径、测试名和返回码。
- 该叙述顺序不删除反例、未知项、替代假设、原始日志 marker、真实文件名或 `scope_extension_request`。
- 保留真实 RTL 文件、module、signal、TB、日志 marker 与 schema 字段名称。
- 仅在主节点交付当前 WSL 工程命令执行权后运行上列命令；命令结束后停止工程进程并归还执行权。
