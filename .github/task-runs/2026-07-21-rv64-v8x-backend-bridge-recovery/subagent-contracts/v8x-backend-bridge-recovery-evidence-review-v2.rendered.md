# RV64 CPU 微架构 RTL 子任务 `v8x-backend-bridge-recovery-evidence-review-v2`

- 工程领域：本地 RV64 CPU 微架构 Verilog/SystemVerilog 设计、验证或 PPA
- 本地作用域：输入、工程动作和产物仅覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据；不使用非工作区来源
- 措辞剖面：`rv64-hardware-professional`；自然语言按流水线、事务、时序、缓存一致性和验证语义解释，真实 RTL 标识符保持不变
- 术语限定：多义术语首次出现时同时说明 module/signal/transaction 对象、pipeline/privilege/memory 层级、path/cycle/config 作用域和工程目的
- 任务类型：`read-only-review`
- 执行模式：`self-contained-no-tools`（冻结材料 RTL 复核；不执行命令或仓库读取）
- 目标：仅依据随附的本地 RV64 Verilog/SystemVerilog 仿真与验证证据，复核 OooIntBackend 到 OooDualMemBridgeWrapper/OooMemAxiBridge 的同 bank 双 LOAD 分支错误预测恢复联合轨迹是否关闭 V8W 指定验证缺口，并主动寻找身份、时序、守恒或变异敏感性假绿；不得外推为总体架构或 PPA 结论。

## 合同证据绑定

- 合同 JSON 路径：`.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-evidence-review-v2.json`
- 合同 JSON SHA-256：`1b1d568b5ac9e2cec6bb7033ee7233ece6d7a6f2206927effcd39303e130678f`
- 上述 SHA-256 只绑定该 JSON 契约文件；不绑定设计 spec、`contract.md`、RTL、测试或其它上下文文件。
- 本提示是该 JSON 通过校验后的渲染结果。需要复核哈希时只核对上述路径；不得把该哈希与同名设计合同混用。

## 派发资格

- 新任务使用 canonical `create → validate → render` 管线；本渲染只会在 JSON 校验通过后产生，并须原样作为工程范围与上下文边界。
- 若 JSON 校验失败，或派发提示手工改写了 RTL 输入、工程命令、输出路径或状态边界，则该轮复核输出只能记为 `candidate-only`，不能进入下游硬证据。
- `scope_extension_request` 只触发新的 versioned contract；新 JSON 必须重新校验、重新渲染并绑定新的 SHA-256，旧合同范围不会被口头追加。

## RTL 输入与工程动作

材料来源路径（仅作 provenance；本节点不读取这些仓库文件）：
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery
- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-evidence-review-v2.json

RTL/证据输出路径：
- 无（只读）

工程命令：
- 无（self-contained no-tools）

Canonical 工程命令用途（固定枚举，不接受任务自定义文本，也不增加未列出的参数或命令变体）：
- 无；子 agent 只消费合同内随附材料

`read-only` 节点只运行不落盘的源码与日志查询；`sed -i`、重定向和其它写型选项不属于该节点命令集合。

工程输入仅来自上列工作区路径；工程输出仅进入上列 RTL/证据输出路径。

## 最小上下文

- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md

## 冻结 RTL 材料

- Focused 正例唯一 marker：A=0 B=1 ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS，随后 test PASS 与 RESULT PASS。
- dispatch 捕获不可变 owner tuple kind/token/epoch/fault_tval；drop、exact MIQ pop、collector lane2 terminal 均逐 owner 比较，不用更新后的 head 单独标识事务。
- 真实 backend 与 wrapper 全端口直连，TB 仅建模 wrapper 唯一 AXI slave；A active、B station 建立前 ARREADY 为低，唯一 shared AR fire 同时核对 owner=A、head=A、station=B。
- older branch commit held；branch_resolve_mispredict 为单拍且 wrapper global flush 全程为零；A/B MIQ effective-killed 状态保持到各自 exact pop。
- A 在 bridge READ_DATA 接收迟到 R，同一采样边只允许 drop(A)、exact pop(A)、collector lane2(A)，逐周期禁止 response、WB、commit、cache fill 与第二次 AR。
- 下一周期 B 从真实 station 晋升；active、tracker expected、station expected、residency、MIQ head 均核对为 B；persistent-killed authority 触发 pre-AXI drop(B)、pop(B)、collector lane2(B)，并禁止 translate、AR、WB、commit、fill。
- ledger 强制 A terminal 先于 B terminal且各恰一次；两个 bridge、tracker、collector、MIQ、ROB 最终 drain idle，随后 6 周期 quiet guard 无新增事件。
- 两项 compile-success RTL 验证变异均 compile_rc=0、sim_rc=1：屏蔽 active recovery 的首个 witness 为 V8X active A exact selective authority；阻断 killed station promotion 的首个 witness 为 V8X station B promotes to active B；生产 RTL SHA 前后一致。
- V8W backend/full bridge/wrapper 与默认 backend/core-top 共 5/5 回归 PASS；check-contract 13 tests、holder census 与 assertion census PASS；aggregate marker 为 baseline=1 mutations=2/2 regressions=5/5 contract=PASS；本轮未修改 production RTL。
- 结论边界固定为仅关闭指定 LOAD 联合动态轨迹；OOO-4、DI-5、OOO-3、overall 仍为 RED，PPA=UNQUALIFIED，promotion_eligible=false。

## 推理自由与不确定性出口

- 可以并应当报告 `unknowns`、显式假设、反例、替代假设、置信度及其证据基础；这些内容不会被视为任务失败。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不得设置固定发现数量上限；按严重度排序可以，但不得截断仍影响结论的 blocker、反例或覆盖洞。
- 发现输入集合遗漏必要上下游时，返回 `scope_extension_request`，说明所需路径/命令及原因；该请求本身不改变当前节点范围，须由主 agent 生成新版契约。
- 子 agent 可以提出合同未预设的替代解释或设计方案，只要不执行合同未列出的工程动作、不越级扩大结论。

## 交付物

- 输出严格 JSON：verdict(pass/gap/inconclusive)、verified_points、blockers、remaining_risks、unknowns、scope_extension_request、confidence_and_basis、conclusion_boundary；每个 blocker 必须指出随附证据中的具体承重缺口和最小补证。

## 成功条件

- 仅当随附证据共同闭合 immutable owner、真实 active/station、单拍选择性恢复、A 迟到 R 无副作用终结、B pre-AXI 精确终结、A 后 B exactly-once ledger、最终守恒、compile-success RTL 变异敏感性和相邻回归时才可 pass；允许 gap 或 inconclusive，且不得提升总体架构/PPA 状态。

## 协作约束

- 保留真实 RTL 标识符和信号语义；遇到歧义时直接补充流水线、事务、时序或验证上下文，不改变技术含义。
- 若需增加 RTL 文件、证据输出路径或验证命令，先返回主 agent 生成新版契约。
- Windows/Codex 经 WSL 访问本工作区时，工程 shell 为 single-flight：主 agent 可以把唯一 shell ownership 交给一个契约授权的子 agent；该节点执行期间主 agent 与其它子 agent 不得并发启动工程命令。
- 本任务为冻结材料 RTL 复核：不执行工程命令，也不读取上方材料之外的模块；结论只覆盖这些材料，不能据此宣称完成仓库级 RTL 全量复核。
