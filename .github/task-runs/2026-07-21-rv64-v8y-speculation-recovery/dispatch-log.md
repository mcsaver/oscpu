# V8Y OOO-4 子任务派发记录

## contract-review-v1

- 工程对象：本地 RV64 Verilog/SystemVerilog OoO 核的分支解析、流水线恢复、AXI 读事务排空与证据门。
- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/subagent-contracts/v8y-speculation-recovery-contract-review-v1.json`
- 合同 JSON SHA-256：`0ea2cc8e0297d9e2d5ac0672853fcda0e7a7e5316adeba50ab6407192f8e18a4`
- 哈希作用域：仅绑定上述 JSON 文件，不绑定 RTL、设计规范、testbench 或证据产物。
- canonical 管线：`create -> validate -> render` 全部 PASS。
- 执行模式：`self-contained-no-tools`；只消费合同内冻结材料，不运行 shell、不写文件。
- 当前状态：已派发并返回 `GAP`；完整结构化结论固化在 `contract-review-result.json`。
- 关键反例：补跨 ROB 环回、逐 full-ProducerId complete/retire ledger、逐指标 compile-success RTL 验证变异，以及同一 suite/design 绑定。
- 处理：V8Y 已扩展为 linear 0/1/2 与 wrap 14/15/0；focused binary 同时运行 V8D/V8X；变异矩阵扩成 9 项；正在生成专用 OOO-4 evidence record。

## final-review-v1（历史冻结材料复核）

- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/subagent-contracts/v8y-speculation-recovery-final-review-v1.json`
- 合同 JSON SHA-256：`196852bedfe5c2de1e044ec292a099d1ec6648347d803e4371d14c850e8c3201`
- canonical 管线：`create -> validate -> render` 全部 PASS；渲染边界逐字派发。
- 执行模式：`self-contained-no-tools`；不运行 WSL shell、不读取仓库、不写文件。
- 结果：限定材料 `PASS`，保存于 `final-review-v1-result.json`；它关闭了最老分支选择、ROB 环回、严格年轻流水事务清除、完成/退休一次性与已握手 AXI 事务排空反例。
- 证据状态：这是 suite `v8y-ooo4-20260721T071657Z-1714237` 的历史复核。随后 canonical runner 修正证据生命周期并产生新的最终 suite，因此 v1 只保留为审计历史，不作为最终 OOO-4 发布绑定。

## final-review-v2（最终冻结材料复核）

- 工程对象：本地 RV64 双发射 OoO Verilog/SystemVerilog 核的控制流推测、分支错误预测恢复、完成/退休授权、memory bridge 排空与架构证据生命周期。
- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/subagent-contracts/v8y-speculation-recovery-final-review-v2.json`
- 合同 JSON SHA-256：`53fefcc58f5072b34aee9eb836326592fad8db54b5d1bad8901f2541d7fdee85`
- 哈希作用域：仅绑定上述 JSON 文件，不绑定 RTL、设计规范、testbench 或证据产物。
- canonical 管线：`create -> validate -> render` 全部 PASS；渲染边界逐字派发。
- 执行模式：`self-contained-no-tools`；不运行 WSL shell、不读取仓库、不写文件。
- 最终绑定：design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`，suite `v8y-ooo4-20260721T072758Z-1732951`，source `27/fa41ce6b...743a41`，provenance `52/e25ce5fb...9812`。
- 结果：`PASS`，保存于 `final-review-v2-result.json`；未发现未闭合反例，且两项生命周期修正均判定不削弱 OOO-4 技术证据。
- 声明边界：`OOO-4=GREEN`；`DI-1/DI-2/overall=RED`；`PPA=UNQUALIFIED`；`promotion_eligible=false`；不是仓库级独立源码/日志/哈希重算。
