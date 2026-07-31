# V11I independent final review v2

## Disposition

`APPROVED_FOR_CURRENT_SCOPE` / bounded APPROVE / blocker=0.

## RV64 module, cycle and EDA findings

- Object: `OooIntBackend` lane0 terminal →
  `OooMemOwnerTerminalCollector` → `OooMemOwnerTracker` →
  `OooLoadQueue.terminal_seen_q`.
- Configuration: 33 LOADs, tracker token0..31 followed by token0 reuse,
  with `OOO_ASSERT` enabled and disabled.
- Production result: 2/2 PASS. The original lane0 response fires exactly once and
  the MIQ entry pops on the same edge; no production state retains the old tuple.
  After token0 changes from PID `00` to PID `40`, ingress and accept remain quiet
  while the new tracker/LQ owner stays live with `terminal_seen_q=0`.
- Compile-success stale-tuple result: 2/2 expected rejection. The frozen RTL copy
  activates the old tuple at time 656. The assertions-on image rejects it at time
  660 with `[V9Y-HOLDER-TERMINAL-NEXT]`; the assertions-off image rejects it at
  time 665 with `[V11I-LATE-TUPLE-ABA][FAIL]` after direct tracker/LQ raw-Q
  observation. Both variants compile with rc=0 and simulate with the expected rc=1.
- H1 is confirmed for the current production source. H2 is retained only as the
  demonstrated consequence of violating source one-shot. H3 is excluded because
  tracker allocation scans edge-old `live_q` and LQ samples the edge-old
  token-to-ProducerId table on dequeue/free.
- Layered assertions-on regression is 7/7 PASS: collector, tracker, LoadQueue,
  ordinary IntBackend, AXI bridge, dual wrapper and V8X parent recovery.

## Binding and evidence integrity

- Review contract SHA-256:
  `c90a077ac927f8335fdcdeccbf939503f74655cbdea8bca4bb1bca7e8ee59a40`.
- Canonical design-id:
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`.
- Selected summary SHA-256 prefix: `3c4d536f`.
- Compile-success variant SHA-256 prefix: `10e10eed`.
- `sources.pre.sha256` and `sources.post.sha256` are identical, and the validation
  receipt binds the selected summary and raw logs.
- Attempt-1, attempt-2 and layered-attempt-1 remain immutable FAIL evidence; no
  status was rewritten. Production `OooIntBackend.v` contains no V11I mutation
  state. No terminal-event deduplication or assertion weakening was introduced.
- The release oracle obtains PID/token from actual dispatch/allocation transactions
  and makes its failure decision from tracker/LQ raw state, not from a DUT PASS
  signal.

## Claim boundary

This review closes only the current local LOAD terminal one-shot and
collector→tracker→LQ lifecycle across one complete tracker-token wrap. It does not
prove arbitrary illegal raw ingress, global no-live-reuse, whole architecture,
full-system behavior, synthesis, STA, power or PPA.

V11I changes no production RTL and launches no full-system workload. V11H previously
changed production `OooLoadQueue` semantics, so a new current-design full-system run
remains required before system promotion; it is not authorized or started by this
review. A3 remains the immutable original FAIL with completed system transaction and
independent checker-replay PASS.

