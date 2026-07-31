# V11I implementer review

## RV64 RTL object and root-cause result

- Object: `OooIntBackend` terminal ingress lane0/lane6,
  `OooMemOwnerTerminalCollector` pending/dequeue,
  `OooMemOwnerTracker` edge-old token table and `OooLoadQueue.terminal_seen_q`.
- H1 is confirmed for current production RTL: accepted terminal sources end their old
  holder lifetime; the previous GAP was the absence of a complete 32-token reuse
  observation.
- H3 remains excluded: tracker allocation cannot reuse a same-edge death token and LQ
  reads edge-old token→ProducerId at dequeue/free.
- H2 is a real local consequence only when source one-shot is violated: the old
  `{LOAD,token0,epoch0}` tuple is accepted after token0 binds a different full PID,
  frees that new tracker owner and sets the new LQ entry's `terminal_seen_q`.

## Implementation

- Production RTL was not changed.
- `tb_ooo_int_backend.sv` now drives 32 sequential
  request→MIQ→response-lane0 LOAD transactions, releases each owner, wraps token0,
  then holds a different full PID in a new reservation.
- The compile-success generated RTL copy saves the first lane0 response tuple and
  replays it only after token0 is rebound to the new PID.
- `run_v11i_terminal_lifecycle.py` runs production and stale-tuple copies with
  assertions on/off, freezes tool/source/raw-log hashes, and refuses non-empty result
  directories unless explicitly overridden.
- `v11i_terminal_lifecycle_evidence.py` independently recomputes current design
  identity, raw hashes and marker counts. Its six mutation tests reject altered
  production RC, log hash, mutation receipts, runner source binding and scope.
- The module Makefile now includes the verification-only tracker semantic checker;
  this repairs the layered testbench filelist without changing synthesis sources.

## Cycle evidence

Current selected evidence is `evidence/terminal-lifecycle-attempt-9/summary.json`:

| configuration | compile | simulation | exact observation |
| --- | ---: | ---: | --- |
| production + `OOO_ASSERT` | 0 | 0 | one token-wrap PASS, one TB PASS, no V11I FAIL or holder marker |
| production release | 0 | 0 | same stimulus and exact PASS counts |
| stale lane0 tuple + `OOO_ASSERT` | 0 | 1 | one activation and one `[V9Y-HOLDER-TERMINAL-NEXT]` |
| stale lane0 tuple release | 0 | 1 | one activation and one `[V11I-LATE-TUPLE-ABA][FAIL]`; raw Q confirms new tracker free and new PID terminal-seen |

- design-id: `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`
- old PID / new PID / token: `00 / 40 / 0`
- runner inputs and canonical RTL pre/post: identical
- independent validation receipt: `evidence/terminal-lifecycle-attempt-9/validation-receipt.json`
- layered regression: `evidence/layered-regression-attempt-2/summary.json`, 7/7 PASS

## Claim boundary

- This closes only the local LOAD terminal source→collector→tracker→LQ lifecycle
  through one complete tracker-token wrap.
- It does not authorize raw-event deduplication, event swallowing, assertion
  weakening, whole-architecture GREEN, synthesis/STA/power or PPA promotion.
- V11I itself changes no production core or elaborated RTL and launches no system
  workload. The earlier V11H `OooLoadQueue` semantic change still means a new full
  current-design system run is required before system-level promotion.
- A3 remains original `FAIL rc=1`, classified separately as completed system
  transaction plus old-oracle false positive with independent checker replay PASS.

Implementer disposition: **READY_FOR_INDEPENDENT_REVIEW**.
