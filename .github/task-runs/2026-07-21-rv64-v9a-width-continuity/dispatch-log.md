# V9A 子 agent 派发与复核日志

## v1 合同

- JSON：`.github/task-runs/2026-07-21-rv64-v9a-width-continuity/subagent-contracts/v9a-di2-contract-review-v1.json`
- JSON SHA-256：`4ed9723fc261781cb776a40ae63032599af7bab21e2b7e2637de42aa29a79c72`
- validate：PASS
- shell ownership：派发期间交给该只读节点；主 agent 不并发运行 WSL 工程命令。

### canonical render（逐字）

# RV64 CPU 微架构 RTL 子任务 `v9a-di2-contract-review-v1`

- 工程领域：本地 RV64 CPU 微架构 Verilog/SystemVerilog 设计、验证或 PPA
- 本地作用域：输入、工程动作和产物仅覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据；不使用非工作区来源
- 措辞剖面：`rv64-hardware-professional`；自然语言按流水线、事务、时序、缓存一致性和验证语义解释，真实 RTL 标识符保持不变
- 术语限定：多义术语首次出现时同时说明 module/signal/transaction 对象、pipeline/privilege/memory 层级、path/cycle/config 作用域和工程目的
- 任务类型：`read-only-review`
- 执行模式：`workspace-files`（默认只读探索；仅按声明路径与命令读取）
- 目标：独立复核本地 RV64 OoO 核 DI-2 七级双宽连续性合同，确认每个计数点对应真实事务接纳或完成事件，融合边界描述准确，固定 64 周期窗口与 full ProducerId 账本能够拒绝空覆盖、重复、遗漏和串 lane

## 合同证据绑定

- 合同 JSON 路径：`.github/task-runs/2026-07-21-rv64-v9a-width-continuity/subagent-contracts/v9a-di2-contract-review-v1.json`
- 合同 JSON SHA-256：`4ed9723fc261781cb776a40ae63032599af7bab21e2b7e2637de42aa29a79c72`
- 上述 SHA-256 只绑定该 JSON 契约文件；不绑定设计 spec、`contract.md`、RTL、测试或其它上下文文件。
- 本提示是该 JSON 通过校验后的渲染结果。需要复核哈希时只核对上述路径；不得把该哈希与同名设计合同混用。

## 派发资格

- 新任务使用 canonical `create → validate → render` 管线；本渲染只会在 JSON 校验通过后产生，并须原样作为工程范围与上下文边界。
- 若 JSON 校验失败，或派发提示手工改写了 RTL 输入、工程命令、输出路径或状态边界，则该轮复核输出只能记为 `candidate-only`，不能进入下游硬证据。
- `scope_extension_request` 只触发新的 versioned contract；新 JSON 必须重新校验、重新渲染并绑定新的 SHA-256，旧合同范围不会被口头追加。

## RTL 输入与工程动作

RTL/spec/TB/evidence 输入路径：
- .github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md
- .github/task-runs/2026-07-21-rv64-v9a-width-continuity/rtl-derivation.md
- npc/rv64/design/arch/rv64-architecture-ppa-contract.md
- npc/rv64/design/arch/pipeline-stage-boundary.md
- npc/rv64/design/specs/ooo-int-issue-queue.md
- npc/rv64/vsrc/frontend/OooFrontend.v
- npc/rv64/vsrc/decode/OooAluDecodeBackend.v
- npc/rv64/vsrc/execute/OooIntBackend.v
- npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v
- npc/rv64/vsrc/scheduling/OooIntIssueQueue.v
- npc/rv64/vsrc/writeback/OooRob.v
- npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv
- npc/rv64/eval/ppa/tools/architecture_hard_gates.py
- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-21-rv64-v9a-width-continuity/subagent-contracts/v9a-di2-contract-review-v1.json

RTL/证据输出路径：
- 无（只读）

工程命令：
- command=rg; mode=read-only
- command=sed; mode=read-only

Canonical 工程命令用途（固定枚举，不接受任务自定义文本，也不增加未列出的参数或命令变体）：
- rg: purpose=search-allowed-paths; label=只读检索允许路径
- sed: purpose=view-selected-lines; label=只读查看指定文本行

`read-only` 节点只运行不落盘的源码与日志查询；`sed -i`、重定向和其它写型选项不属于该节点命令集合。

工程输入仅来自上列工作区路径；工程输出仅进入上列 RTL/证据输出路径。

## 最小上下文

- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md
- npc/rv64/design/arch/rv64-architecture-ppa-contract.md

## 推理自由与不确定性出口

- 可以并应当报告 `unknowns`、显式假设、反例、替代假设、置信度及其证据基础；这些内容不会被视为任务失败。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不得设置固定发现数量上限；按严重度排序可以，但不得截断仍影响结论的 blocker、反例或覆盖洞。
- 发现输入集合遗漏必要上下游时，返回 `scope_extension_request`，说明所需路径/命令及原因；该请求本身不改变当前节点范围，须由主 agent 生成新版契约。
- 子 agent 可以提出合同未预设的替代解释或设计方案，只要不执行合同未列出的工程动作、不越级扩大结论。

## 交付物

- 按 boundary/event/identity/window/drain 五类给出 PASS 或 GAP，列出可执行 RTL testbench 反例、未知项、替代假设与必要的 scope_extension_request

## 成功条件

- 明确裁决七级事件是否非真空且不重复计数，指出任何错误层级路径、身份守恒缺口、不可观测连接错误或窗口选择漏洞；信息不足时返回 inconclusive 而非强制 PASS

## 协作约束

- 保留真实 RTL 标识符和信号语义；遇到歧义时直接补充流水线、事务、时序或验证上下文，不改变技术含义。
- 若需增加 RTL 文件、证据输出路径或验证命令，先返回主 agent 生成新版契约。
- Windows/Codex 经 WSL 访问本工作区时，工程 shell 为 single-flight：主 agent 可以把唯一 shell ownership 交给一个契约授权的子 agent；该节点执行期间主 agent 与其它子 agent 不得并发启动工程命令。
- 本节点只执行合同中逐项声明的工程命令；仅当主 agent 将当前 WSL shell ownership 交给本节点时执行，否则只完成已有 RTL 上下文的推理。

### v1 返回裁决

- 总体：GAP / inconclusive；合同可作为实现草案，不能成为 DI-2 GREEN。
- shell ownership：已明确释放。
- 采纳的可执行反例：父级 dispatch fire 不能替代 ROB/IQ sink；lane1 immediate 串接 lane0 时 PC/PID/数量仍可能假绿；PID 生命周期结束后可合法复用；固定预热必须有唯一锚点；窗口第 17 拍 stall 不能被滑动规避；窗口后 flush 不能制造假 drain。
- 处置：已把独立 sink、payload scoreboard、active PID lifecycle、首个 fetch fire + 24-cycle 固定预热、cycle trace digest、stall probe 和自然 drain 写入 `contract.md` / `rtl-derivation.md`。
- scope extension：后续复核合同将按实现文件集生成 v2，不口头扩展 v1。

## v2 最终证据审查与纠偏

- JSON：`.github/task-runs/2026-07-21-rv64-v9a-width-continuity/subagent-contracts/v9a-di2-final-evidence-review-v2.json`
- JSON SHA-256：`485e16c42f3acb0cda3dbb5ccfc34e19f3ad4b6bf1669cd9d47335b4f90d27a9`
- validate/render：PASS；只读节点已明确释放 WSL shell ownership。
- 已确认项：固定 64 拍七边界 exact dual、固定窗口 stall probe、full ProducerId generation 生命周期、RenameMap/ROB/IQ sink、自然排空、初版 10/10 compile-success mutation、同 design 九门与 `PPA=UNQUALIFIED` 声明均有证据。
- 审查 blocker 1：EX→WB 只核 valid 和全局生命周期，未把前一拍 capture 的 full ProducerId/完整 payload 与下一拍 down-side逐 lane 对账；同拍旁路或 stage payload/PID 错接可能假绿。
- 审查 blocker 2：八个 adjacent regression 日志已入 provenance，但除主 focused TB 外，其余各自 TB source 未全部进入 exact source inventory。
- 纠偏：新增 EX0/EX1 previous-cycle full-payload ledger 与 `ex1_stage_payload_alias` 变异，mutation 总数升至 11；把其余七个 regression TB 源文件加入 `WIDTH_CONTINUITY_SOURCE_PATHS`。纠偏后必须重建八项 sibling、重新发布 DI-2 并再做只读复核。
