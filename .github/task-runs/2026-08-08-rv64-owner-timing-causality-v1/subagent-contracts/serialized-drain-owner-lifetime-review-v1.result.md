# Serialized drain owner-lifetime independent review

`SERIALIZED-DRAIN-OWNER-LIFETIME-REVIEW GAP`

- design_id: `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`
- contract: `.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/subagent-contracts/serialized-drain-owner-lifetime-review-v1.json`
- contract_sha256: `789a2731fd51d13744080ad8f7ba40f6851306b73870fa3e6128184e09b55799`
- current_timing_status: `GAP_NO_SAFE_SERIALIZED_DRAIN_BOUNDARY`
- reviewed_candidate: `serialized-mem-terminal-readiness-register-v1`
- production_rtl_change_authorized: `false`
- ppa: `UNQUALIFIED`
- promotion_eligible: `false`

## RV64 RTL conclusion

`OooIntBackend.mem_owner_terminalized_o` 在当拍正确区分 active holder、accepted terminal transfer、collector-pending-only、tracker live 与 same-edge reservation birth；`OooMemOwnerTerminalCollector` 的 exact tuple、duplicate、pending/dequeue 和 re-enqueue 规则未发现具体反例。该结论只覆盖当拍 scalar 与 collector accounting。

裸一 bit readiness 不能从原合同证明跨周期仍属于同一个 serialized owner。未闭合的最短反例类为：capture 后新 memory birth、owner A clear 后 owner B handoff、flush 与 arm 同沿、collector token dequeue/free 后复用，以及 stale readiness 绕过 FENCE `mem_idle` 或 trap/exit priority。现有 `tb_ooo_pending_drain_resolve_gate.sv` 只驱动组合 scalar；`tb_ooo_serialized_owner_exactly_once.sv` 把 `backend_drained_q_i` 固定为 1 且手工翻转 terminal scalar，均未连接真实 memory birth/collector。

因此只允许继续分析，不允许把 `serialized-mem-terminal-readiness-register-v1` 直接落到生产 RTL。需要证明 `OooFrontendRunGate.stop_pending_busy_o -> !can_run_o` 阻断新 pending/dispatch birth，`OooBackendDrainTracker` 的 force/update 语义不会制造 surviving owner 的假 drained，所有 serialized owner exact-one，且 clear/handoff 之间存在可观测失效边界；否则候选必须绑定 owner kind/generation 并 clear-dominant。

## Scope extension requested by reviewer

- `npc/rv64/vsrc/frontend/OooFrontend.v`
- `npc/rv64/vsrc/frontend/OooFrontendRunGate.v`
- `npc/rv64/vsrc/control/OooPendingDispatchArbiter.v`
- `npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v`
- `npc/rv64/vsrc/control/OooTrapExitEventMux.v`
- `npc/rv64/vsrc/control/OooCsrTrapRequestMux.v`
- candidate-specific clocked TB connected to the real owner/clear signals

Confidence: current scalar/collector accounting `high`; GAP boundary `high`; a correctly owner-bound registered permit `medium` pending the requested source/TB closure.
