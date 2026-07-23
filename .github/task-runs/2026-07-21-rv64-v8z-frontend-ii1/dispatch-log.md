# V8Z DI-1 子任务派发记录

## contract-review-v1

- 工程对象：本地 RV64 Verilog/SystemVerilog 前端 FPC、request/response outstanding、packet FIFO credit 与 cache-hit initiation interval。
- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/subagent-contracts/v8z-frontend-ii1-contract-review-v1.json`
- 合同 JSON SHA-256：`785ed9bc9a27deb7ab19f9b360b1ab4653ad03587f1dd680c8fba9ed9d3c48b8`
- 哈希作用域：只绑定上述 JSON，不绑定 RTL、设计合同、testbench 或后续证据。
- canonical 管线：`create -> validate -> render` PASS，渲染文本逐字派发。
- 权限：workspace-files 只读复核，仅限合同列出的路径和 canonical `rg`/`sed`；无写路径。
- shell ownership：派发期间唯一 WSL 工程 shell ownership 交给该 reviewer，主 agent 与其它节点不并发运行工程命令。
- 状态：`INCONCLUSIVE`；reviewer 未在限定时间内返回可审计 verdict，主 agent 已终止该节点并撤回 WSL shell ownership。
- 技术裁决：不把超时或部分核对当作 PASS；结果冻结在 `contract-review-v1-result.json`。
- 后续：把主 agent 已核对的真实 RTL source facts 固定为 self-contained no-tools v2 合同，复核组合证据边界；所有反例仍必须由 focused TB、compile-success RTL source mutation 或 fail-closed evidence gate 关闭。

## contract-review-v2

- 工程对象：冻结的本地 RV64 Bridge H1、Frontend outstanding/FIFO credit、64-cycle turnover、source mutation 与同一 design binding 事实。
- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/subagent-contracts/v8z-frontend-ii1-contract-review-v2.json`
- 合同 JSON SHA-256：`0a98207e9827ad6ca5f66777295da067024fe5f70e99e168b6d8d7c0c570b43e`
- 哈希作用域：只绑定上述 JSON，不绑定 RTL、设计合同、testbench 或后续证据。
- canonical 管线：`create -> validate -> render` PASS，渲染文本逐字派发。
- 权限：`self-contained-no-tools`；无 shell、命令、文件读取或写路径，不占用 WSL shell ownership。
- 状态：`GAP`；结果冻结在 `contract-review-v2-result.json`，本节点未使用 WSL shell。
- 可执行反例：完整 frontend backpressure 恢复、64-cycle trailing owner 排空、sink dequeue 独立计数、跨 request/response/enqueue/dequeue PC ledger、sink/PC source mutation、assert/release 与同源哈希实跑证据。
- 落地规则：上述每项必须进入 focused oracle、compile-success mutation 或 evidence parser，关闭前 DI-1 保持 RED。

## final-review-v1

- 工程对象：冻结的本地 RV64 Bridge/Frontend cache-hit initiation interval、真实 sink、backpressure 恢复、tail 守恒、source mutation 与同一 design binding 证据。
- 合同 JSON：`.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/subagent-contracts/v8z-frontend-ii1-final-review-v1.json`
- 合同 JSON SHA-256：`c8aae57c868da65250a8abd59b8c9115fd9de4a87d5f019e303ec81b51dbc58f`
- 哈希作用域：只绑定上述 JSON，不绑定 RTL、设计合同、testbench、最终 verdict 或其它证据。
- canonical 管线：`validate -> render` PASS；该 JSON 先前由 canonical `create` 生成，校验后的渲染文本逐字派发。
- 权限：`self-contained-no-tools`；无 shell、命令、文件读取或写路径，不占用 WSL shell ownership。
- 状态：`PASS`；结果冻结在 `final-review-v1-result.json`，本节点未使用 WSL shell。
- 结论边界：只授权最终 suite/design 绑定内的 DI-1 scoped GREEN；DI-2 与 overall architecture 保持 RED，PPA 保持 UNQUALIFIED，且不构成仓库级独立审计。
- 未独立复算项：合同/proof-source/provenance/gate-log SHA-256、原始波形、mutation patch 与 RTL 源码；这些由 canonical runner 和机器门约束，不并入 reviewer 自身能力声明。
- 证据分层：本审查结果只进入 task-run 审计层，不反向加入已冻结的 DI-1 proof-source/provenance 清单。
