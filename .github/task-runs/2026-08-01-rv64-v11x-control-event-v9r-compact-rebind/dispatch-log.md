# V11X reviewer dispatch log

## Review 1: compact evidence and cohort boundary

- Contract: `.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind/subagent-contracts/v11x-control-event-compact-review.json`
- Contract SHA-256: `64e5cd8ca4a70a9219b9fe831acb56c0e1dcd0d433e5e89a8c5cded4fe26e2b2`
- Scope: read-only RV64 RTL/spec/TB/evidence inspection.
- Result: `GAP`.
- Actionable counterexample: the V9R focused set proved empty-holder capture blocking but did not itself bind the already-resident retry holder pause to a compile-success C0 request-gate variant.
- Cohort finding: local evidence is bound to `82febf...`, while `full-core-current.json` remains `04c545...`; therefore generic `closed_binding` must remain `GAP` even when the local semantic validator passes.

The counterexample was mapped to the existing
`tb_ooo_int_backend_v11l_memory_retry_holder` cycle matrix and two new compact
mutations, `backend-bank0-resident-fire-open` and
`backend-bank1-resident-fire-open`. No production RTL was changed.

## Review 2: resident-holder remediation

- Contract: `.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind/subagent-contracts/v11x-control-event-resident-holder-review-v2.json`
- Contract SHA-256: `270fccb1f14b42df252cfd09633b79a33616d2e33ba9850284355255c04721b2`
- Scope: read-only `OooIntBackend` holder/request-fire path and compact V9R evidence.
- Result: scoped `PASS`; full-core `closed_binding` remains `GAP`.
- Observation: for two C0 barrier cycles both retry tuples remain resident and both request-fire/MIQ-push paths remain zero. Each bank-specific request-gate mutation compiles and is rejected at `stage=c0-filled-holder-pause`.
- Remaining boundary: the forced internal C0 source and the natural ROB trap-head C0 source are separately covered; no claim is made for whole-core architecture stability or PPA promotion.
- Scope extension request: none.

Both reviewers explicitly returned Windows-to-WSL shell ownership and left no
engineering process running.
