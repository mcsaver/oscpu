# RV64 V14C P0 transitive-cone current rebind

## 结论

- 对象：current design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`，146 个 production RTL 文件；本轮 production RTL 零改动。
- 范围：P0 九门 task-local `CURRENT_DYNAMIC_PASS`，不依赖冻结 replay；独立 reviewer=`APPROVED_CURRENT_SCOPE`。
- 正向：shared module aggregate 113/113、V14C dynamic suite 18/18、IFU current module logs 5/5。
- 负向：P0 121 条观测 = 118 次 compile-success RTL mutation 执行 + 3 次 oracle probe；4 组跨 gate 观测共享相同 `(source, variant_sha256)`，故唯一 P0 RTL 变体为 114。
- 邻接证据：MIQ-FLUSH-G1 的 3 条 mutation 属于 P1，已从 P0 排除，只作为下一轮 partial evidence。
- Icarus warning：2368 次、45 个唯一行型全部命中 `PmpChecker.v`/`AxiCrossbar.v` 的精确行号与数组名；正向 assertion failure=0。

## 历史状态

- `current-bind-1.status=PASS` 原样保留，但因 driver 丢失 normalize 阶段返回码而不接受为交付。
- `current-bind-checker-replay-1.status=FAIL` 与 `p0-replay-elimination-1.status=FAIL` 原样保留。
- `p0-final-1.status=PASS` 原样保留，但其 P0=124 归属被 supersede：其中 3 条实际为 MIQ-FLUSH-G1 P1，且该口径没有区分观测与唯一 RTL 变体。
- 权威 task-local 收据为 `evidence/p0-final-2/receipt.json`；`historical_status_rewritten=false`。

## Fail-closed 边界

- Section13：P0 current=9/9；P1 stale=7；historical backfill 非 current；producer/holder semantic=GAP；functional aggregate 非 current；freeze empty groups=12。
- `architecture_gate_state=RED`、`arch_stable=false`、`ppa_state=BLOCKED_BY_ARCHITECTURE`、`promotion_eligible=false`。
- 本轮不提供完整 architecture freeze、综合、STA、power、area 或 PPA promotion 结论。

## 证据指针

- 逐项反例清单：`evidence/counterexample-inventory-1/inventory.json`
- 最终 P0 收据：`evidence/p0-final-2/receipt.json`
- Section13：`evidence/section13-current-3/section13-current-audit.json`
- 独立审查：`subagent-contracts/v14c-p0-current-review-v3.json`、`reviewer-result-v3.md`
- 最终审计：`evidence/final-audit-1/audit.json`、`final-audit-1.status=PASS`
- 稳定事实已写入 stored memory；`memory-staging`、Python bytecode 与可再生编译产物均未保留。

## 下一主线

执行 P1 direct active-cone current rebind：`CONTROL-EVENT-G1`、`MIQ-FLUSH-G1`、`STORE-BRESP-G1`。MIQ 的 3 条当前负向观测可复用，但仍须补当前正向、完整 receipt、assertion-clean terminal marker 与 source pre/post identity。
