# RV64 CPU 微架构 RTL 子任务 `v8x-backend-bridge-recovery-final-review`

- 工程领域：本地 RV64 CPU 微架构 Verilog/SystemVerilog 设计、验证或 PPA
- 本地作用域：输入、工程动作和产物仅覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据；不使用非工作区来源
- 措辞剖面：`rv64-hardware-professional`；自然语言按流水线、事务、时序、缓存一致性和验证语义解释，真实 RTL 标识符保持不变
- 术语限定：多义术语首次出现时同时说明 module/signal/transaction 对象、pipeline/privilege/memory 层级、path/cycle/config 作用域和工程目的
- 任务类型：`read-only-review`
- 执行模式：`workspace-files`（默认只读探索；仅按声明路径与命令读取）
- 目标：工作对象为本地 RV64 Verilog/SystemVerilog 处理器工程；独立复核真实 OooIntBackend MIQ 与 OooDualMemBridgeWrapper active A/station B 的分支错误预测恢复联合轨迹、两项 compile-success RTL 验证变异、相邻回归、哈希绑定和裁决边界，并主动寻找未覆盖反例或假绿。

## 合同证据绑定

- 合同 JSON 路径：`.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-final-review.json`
- 合同 JSON SHA-256：`01e17e1466e2c7dc024c7d21a82d364043e917f1f49fdd49730d493d50461149`
- 上述 SHA-256 只绑定该 JSON 契约文件；不绑定设计 spec、`contract.md`、RTL、测试或其它上下文文件。
- 本提示是该 JSON 通过校验后的渲染结果。需要复核哈希时只核对上述路径；不得把该哈希与同名设计合同混用。

## 派发资格

- 新任务使用 canonical `create → validate → render` 管线；本渲染只会在 JSON 校验通过后产生，并须原样作为工程范围与上下文边界。
- 若 JSON 校验失败，或派发提示手工改写了 RTL 输入、工程命令、输出路径或状态边界，则该轮复核输出只能记为 `candidate-only`，不能进入下游硬证据。
- `scope_extension_request` 只触发新的 versioned contract；新 JSON 必须重新校验、重新渲染并绑定新的 SHA-256，旧合同范围不会被口头追加。

## RTL 输入与工程动作

RTL/spec/TB/evidence 输入路径：
- npc/rv64/vsrc/execute/OooIntBackend.v
- npc/rv64/vsrc/memory/OooMemAxiBridge.v
- npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v
- npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v
- npc/rv64/testbench/tests/tb_ooo_int_backend.sv
- npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh
- npc/rv64/testbench/Makefile
- npc/rv64/Makefile
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery
- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/SPEC.md
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/subagent-contracts/v8x-backend-bridge-recovery-final-review.json

RTL/证据输出路径：
- 无（只读）

工程命令：
- command=rg; mode=read-only
- command=sed; mode=read-only
- command=git diff; mode=read-only
- command=sha256sum; mode=read-only

Canonical 工程命令用途（固定枚举，不接受任务自定义文本，也不增加未列出的参数或命令变体）：
- rg: purpose=search-allowed-paths; label=只读检索允许路径
- sed: purpose=view-selected-lines; label=只读查看指定文本行
- git diff: purpose=inspect-scoped-diff; label=只读查看限定差异
- sha256sum: purpose=hash-declared-artifact; label=计算已声明产物哈希

`read-only` 节点只运行不落盘的源码与日志查询；`sed -i`、重定向和其它写型选项不属于该节点命令集合。

工程输入仅来自上列工作区路径；工程输出仅进入上列 RTL/证据输出路径。

## 最小上下文

- .github/AGENTS.md
- .github/instructions/rtl-agent-task-contract.instructions.md
- .github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/SPEC.md

## 推理自由与不确定性出口

- 可以并应当报告 `unknowns`、显式假设、反例、替代假设、置信度及其证据基础；这些内容不会被视为任务失败。
- 信息不足时允许给出 `inconclusive`，不得为了满足预期而强制给出 PASS。
- 不得设置固定发现数量上限；按严重度排序可以，但不得截断仍影响结论的 blocker、反例或覆盖洞。
- 发现输入集合遗漏必要上下游时，返回 `scope_extension_request`，说明所需路径/命令及原因；该请求本身不改变当前节点范围，须由主 agent 生成新版契约。
- 子 agent 可以提出合同未预设的替代解释或设计方案，只要不执行合同未列出的工程动作、不越级扩大结论。

## 交付物

- 逐项给出真实连接、A/B immutable identity、active/station建立、单拍branch mispredict且wrapper flush=0、A迟到R drain、A/B两组exact drop+MIQ pop+collector ingress、B pre-AXI终止、零WB/commit/cache-fill/second-AR、final conservation、6-cycle guard、2/2 compile-success RTL变异、5/5回归、contract/hash/provenance的PASS或GAP；每个GAP给出具体路径/行号/最小反例；明确unknowns、scope_extension_request、confidence_and_basis。

## 成功条件

- 只有当实际源码和日志共同证明V8W所列真实backend+bridge active/station双owner联合动态轨迹已闭合、两项变异均编译成功并因预期语义witness被拒绝、相邻回归不退化、证据哈希一致且生产RTL未被本切片修改时才可PASS；不得把该结果外推为OOO-4/DI-5/OOO-3/overall GREEN或PPA promotion。

## 协作约束

- 保留真实 RTL 标识符和信号语义；遇到歧义时直接补充流水线、事务、时序或验证上下文，不改变技术含义。
- 若需增加 RTL 文件、证据输出路径或验证命令，先返回主 agent 生成新版契约。
- Windows/Codex 经 WSL 访问本工作区时，工程 shell 为 single-flight：主 agent 可以把唯一 shell ownership 交给一个契约授权的子 agent；该节点执行期间主 agent 与其它子 agent 不得并发启动工程命令。
- 本节点只执行合同中逐项声明的工程命令；仅当主 agent 将当前 WSL shell ownership 交给本节点时执行，否则只完成已有 RTL 上下文的推理。
