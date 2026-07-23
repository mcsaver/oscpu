# RV64 CPU 微架构 RTL 子任务 `v8x-backend-bridge-recovery-contract-review`

- 工程领域：本地 RV64 CPU 微架构 Verilog/SystemVerilog 设计、验证或 PPA
- 本地作用域：输入、工程动作和产物仅覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据；不使用非工作区来源
- 措辞剖面：`rv64-hardware-professional`；自然语言按流水线、事务、时序、缓存一致性和验证语义解释，真实 RTL 标识符保持不变
- 术语限定：多义术语首次出现时同时说明 module/signal/transaction 对象、pipeline/privilege/memory 层级、path/cycle/config 作用域和工程目的
- 任务类型：`read-only-review`
- 执行模式：`self-contained-no-tools`（冻结材料 RTL 复核；不执行命令或仓库读取）
- 目标：工作对象为本地 RV64 Verilog/SystemVerilog 处理器工程；只依据随附硬件事实审查 backend MIQ 与真实 dual-memory bridge 的选择性分支恢复联合轨迹是否足以关闭 V8W verification gap，并主动寻找假绿反例。

## 合同证据绑定

- 合同 JSON 路径：`.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-contract-review.json`
- 合同 JSON SHA-256：`badace8d8da51a1433a461c33b9fc294700a2e226d6abe3c2b00907c8e19efdc`
- 上述 SHA-256 只绑定该 JSON 契约文件；不绑定设计 spec、`contract.md`、RTL、测试或其它上下文文件。
- 本提示是该 JSON 通过校验后的渲染结果。需要复核哈希时只核对上述路径；不得把该哈希与同名设计合同混用。

## 派发资格

- 新任务使用 canonical `create → validate → render` 管线；本渲染只会在 JSON 校验通过后产生，并须原样作为工程范围与上下文边界。
- 若 JSON 校验失败，或派发提示手工改写了 RTL 输入、工程命令、输出路径或状态边界，则该轮复核输出只能记为 `candidate-only`，不能进入下游硬证据。
- `scope_extension_request` 只触发新的 versioned contract；新 JSON 必须重新校验、重新渲染并绑定新的 SHA-256，旧合同范围不会被口头追加。

## RTL 输入与工程动作

材料来源路径（仅作 provenance；本节点不读取这些仓库文件）：
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/SPEC.md
- npc/rv64/vsrc/execute/OooIntBackend.v
- npc/rv64/vsrc/memory/OooMemAxiBridge.v
- npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v
- npc/rv64/testbench/tests/tb_ooo_int_backend.sv
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-contract-review.json
- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md

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

- 待验证轨迹为同 bank MIQ [A,B] 与 bridge active=A/station=B；A/B 均是 younger ordinary LOAD，older branch 的单拍 mispredict 只使 backend MIQ owner effective-killed，wrapper global flush 保持 0。
- A 已经完成一次 AXI AR handshake并在 READ_DATA 等待 R；B 只驻留 bridge station。A 的迟到 R 必须产生 drop(A) 并精确 pop MIQ head A，禁止 WB、commit、cache fill或第二个 AR。
- A pop 后，station B 必须晋升 active；backend MIQ persistent killed bit此时对 B 成为 exact head authority，bridge 在 pre-AXI 状态产生 drop(B)，backend精确 pop B。
- 最终要求 drop/MIQ-pop/collector-terminal 均精确两次且身份顺序 A 后 B；tracker、collector、MIQ、ROB和两个 bridge归零/idle，A/B无 WB或commit，共享 AXI AR fire 总数仍为1。
- 接口直接连接 backend request、expected、tracker-expected、station-expected、SQ-query、drop、owner-residency和translate信号到 OooDualMemBridgeWrapper；不由 testbench 伪造 bridge ready/response/drop/SQ allow。
- 至少一个 compile-success RTL mutation 必须破坏承重跨模块边并由focused test拒绝；相邻 V8W backend、bridge、wrapper和integration回归仍需通过。
- 本切片只关闭该联合动态覆盖洞；OOO-4、DI-5、OOO-3、overall架构继续RED，PPA为UNQUALIFIED且promotion_eligible=false。

## 推理自由与不确定性出口

- 可以并应当报告 `unknowns`、显式假设、反例、替代假设、置信度及其证据基础；这些内容不会被视为任务失败。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不得设置固定发现数量上限；按严重度排序可以，但不得截断仍影响结论的 blocker、反例或覆盖洞。
- 发现输入集合遗漏必要上下游时，返回 `scope_extension_request`，说明所需路径/命令及原因；该请求本身不改变当前节点范围，须由主 agent 生成新版契约。
- 子 agent 可以提出合同未预设的替代解释或设计方案，只要不执行合同未列出的工程动作、不越级扩大结论。

## 交付物

- 仅输出严格 JSON，字段 verdict(pass或gap)、blockers、false_green_risks、required_observations、required_mutations、recommended_refinements；每项必须落到本地 RV64 RTL 信号或仿真事件。

## 成功条件

- 只有当真实连接、身份顺序、exactly-once terminal、无目标/WB副作用、最终守恒以及compile-success变异敏感性都可独立证伪时 verdict=pass；否则 verdict=gap并给出最小修订。

## 协作约束

- 保留真实 RTL 标识符和信号语义；遇到歧义时直接补充流水线、事务、时序或验证上下文，不改变技术含义。
- 若需增加 RTL 文件、证据输出路径或验证命令，先返回主 agent 生成新版契约。
- Windows/Codex 经 WSL 访问本工作区时，工程 shell 为 single-flight：主 agent 可以把唯一 shell ownership 交给一个契约授权的子 agent；该节点执行期间主 agent 与其它子 agent 不得并发启动工程命令。
- 本任务为冻结材料 RTL 复核：不执行工程命令，也不读取上方材料之外的模块；结论只覆盖这些材料，不能据此宣称完成仓库级 RTL 全量复核。
