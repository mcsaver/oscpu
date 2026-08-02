# V13Q verification result

- goal work classification: `verification`
- lightweight agent-flow execution profile: `development`
- production RTL change: none
- final verification verdict: `PASS_WITH_DECLARED_GAPS`
- promotion verdict: `NO_CHANGE / NOT_ELIGIBLE_PPA_PENDING`

## Positive directed evidence

Command:

```text
make -C npc/rv64/testbench RESULT_DIR=<V13Q>/evidence/backend-error-backpressure v13q-store-b-error-backpressure-focused
```

Result: `rc=0`, `[RESULT] PASS`.

Fail-closed focused receipt:
`evidence/backend-error-backpressure/result.json` records `make_rc=0`, stable
critical-source binding and the exact log digest.  The corresponding manifest
includes the wrapper, dual-memory arbiter, SQ and ROB rather than binding only
the bridge/backend pair.

- SLVERR direct: cause 7, original VA `0x0000000040000900`, exactly one
  terminal lifecycle, quiet window PASS.
- DECERR direct: cause 7, original VA `0x0000000040000940`, exactly one
  terminal lifecycle, quiet window PASS.
- SLVERR fallback: one real dual-WB occupancy edge, B handshake while backend
  is blocked, `S_RESP` capture, cause 7, original VA
  `0x0000000040000980`, exactly one terminal lifecycle, quiet window PASS.
- aggregate marker:
  `[V13Q-BACKEND-B-ERROR-BP] slverr_direct=1 decerr_direct=1 slverr_fallback=1 cause7=3 original_tval=3 exact_terminal=3 quiet=9 PASS`.
- log SHA-256:
  `ca173e37f6da81f871b25587577276ab84a048de3b2e75a58561a77e09a7c4a0`.

## Negative RTL sensitivity

Driver:
`driver/run-v13q-backend-error-bp-mutations.sh`.
Each variant is compiled by overriding only `RTL_OOO_INT_BACKEND`; the live
production file is never rewritten and temporary RTL/VVP files are removed.

| Variant | Expected runtime rejection | Result |
| --- | --- | --- |
| `drain-cause-load-fault` | formal WB cause is 5 rather than 7 | PASS: mutation rejected, fail-closed DUT result |
| `drain-tval-uses-pa` | formal WB/commit expose `0x8000_09xx` rather than original `0x4000_09xx` VA | PASS: mutation rejected, fail-closed DUT result |
| `ignore-formal-wb-credit` | response/WB/SQ terminal/MIQ pop occur while both WB slots are full | PASS: mutation rejected, fail-closed DUT result |

All per-variant result JSON files bind live source SHA
`49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`,
record `make_rc=2`, `runtime_marker_detected=true`,
`mutation_detected=true`.  `evidence/mutation-suite-result.json` is removed at
rerun start and atomically installed with suite-level PASS only after all three
new receipts exist.  Each per-variant stale receipt and runtime log is likewise
removed before reconstruction.  Positive and mutation receipt staging resides
under the same evidence filesystem as the final paths; rerun cleanup left no
hidden staging directory or focused VVP.

## Regression evidence

- V13P focused bridge/backend contract: `rc=0`; direct OKAY/SLVERR/DECERR,
  fallback, killed-drop and real-backend fusion markers remain PASS.
- V8X backend bridge recovery: `rc=0`;
  `[V8X-BACKEND-BRIDGE-RECOVERY] A=0 B=1 ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS`.
- V8X log SHA-256:
  `8e38435baefe645f6530ab40ecea1231c6975f5b4b0c764aef097485ff1fe94a`.

## Evidence boundary

This result closes real-backend SLVERR/DECERR direct behavior, one-cycle
formal-WB backpressure fallback, original-VA preservation, C0 barrier and
exactly-once lifecycle sensitivity.  It does not claim multi-cycle fallback,
asymmetric SQ credit, delayed retirement, system workload, synthesis, STA,
power, area or PPA promotion.

## Cleanup

After evidence indexing, four focused VVPs were absent/removed, including the
V13Q target and the V13P/V8X regressions.  The three retained regression VVPs
accounted for 31,784,044 rebuildable bytes.  Runtime logs, result JSON,
critical-source binding, reviewer contracts and evidence index are retained.
