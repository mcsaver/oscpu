RV64 RTL 结论｜对象=`OooSerializedMemTerminalPermit.ready_o/permit_valid_q/permit_owner_q`、`OooPendingDrainResolveGate.drain_complete_o` 与 f72e/93c8 本地证据｜周期/配置=held-permit capture→consume/cancel、OOO_ASSERT focused TB、OOO_ASSERT_OFF mutation、exact-5ns mapped STA｜TB/EDA 观测=focused TB 与 4/4 mutation PASS、CPI 零回退、目标 terminal→drain→frontend Top40 路径族移出；93c8 仍 40/40 违例｜范围=GAP

## Independent decision

`retain_for_reconciliation`。93c8 不回滚，但不具备 Architecture/Pareto promotion 资格；A1b 的工具与证据状态 PASS 不代表 timing hard gate PASS。

- f72e→93c8：CoreMark CPI `1.653109654836→1.653109654836`，Dhrystone CPI `2.294461647059→2.294461647059`。
- WNS `-13.382589340→-11.550187111 ns`，改善 `+1.832402229 ns`；TNS `-315554.09375→-285529.625 ns`，改善 `+30024.46875 ns`。
- logic-area proxy `2181706.52→2181781.84`，增加 `75.32`；known standard cells `929223→929252`，增加 29。
- f72e 的 40/40 terminal→`drain_complete`→fetch/redirect 路径在 93c8 Top40 中消失；93c8 仍有 4 条 terminal→permit capture FF 路径和 1 条 CSR 路径，不能扩写为 terminal logic 全部移出。
- A1 外层因旧 endpoint regex 保持 FAIL；独立 inventory recheck PASS。A1b 外层 PASS 且与 A1 mapped 数值一致，但 `target_met=false`。A2 为 `SIGTERM rc=143 evidence_complete=0`，不得计为候选失败或机械重跑。

## Preserved invariants and counterexample

局部 RTL 与定向 marker 支持 exact-one owner、A→B mismatch、cancel/consume clear priority、raw backend drain、FENCE current `mem_idle`、CSR current scalar 与 C0/C1 exactly-once。

审查构造出未闭合组合：held permit、owner match、stop/raw-drain/control-ready 为 1，同时 `cancel_i=1`。93c8 的 `ready_o` 不读 cancel，因而 clear 沿前仍可能令 `ready_o/drain_complete_o=1`。原 arm-cancel TB 只检查沿后清除，ROB-head trap 用例则从未 arm 的 permit 开始；两者都不能证明 held-permit+cancel 同周期安全。若下游没有完整优先级屏蔽，这是功能缺陷。

## Evidence and scope

- focused/mutation：`.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/evidence/rtl-focused`。
- CPI：`.github/task-runs/2026-08-08-rv64-v16a-owner-permit-cpi-93c8-a1/evidence/owner-timing-current-candidate-ab/result.json`。
- mapped candidate：`.github/task-runs/2026-08-08-rv64-v16a-owner-permit-ppa-93c8-a1b/evidence/traceable-93c8-a1b/summary.json`。
- live selector：`.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/evidence/selector-live-93c8.json`，为 `STATE_CONFLICT/STATE_RECONCILIATION`。

`scope_extension_request`：读取下游 dispatch/trap/exit mux，并新增 held-permit 与 flush/system-clear/trap-clear/exit-clear 碰撞 TB；同时保持 raw drain/control-ready 为 1，观察 drain、owner clear 与架构 side effect exactly-once。

置信度：局部 capture/hold/clear、CPI 与 mapped 数值高；93c8 cancel-cycle 系统安全性中低。合同内只读命令已结束，无工程进程遗留，WSL shell ownership 已归还。
