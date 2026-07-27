# V9Y pre-fix independent RTL review

## Verdict

`GAP`

Object: `OooMemOwnerTerminalCollector` twelve ingress lanes,
`OooIntBackend` holder/tracker state, and
`OooPendingDrainResolveGate`.

Cycle convention: edge-old holder state, current-edge terminal transfer, then
edge-new holder/pending/live state.

The pre-fix non-FENCE drain gate did not distinguish an active memory owner
from a token already transferred to the terminal collector. CSR had the same
gap at `system_csr_dispatch_valid_o`; ordinary `FENCE` already used full
`mem_idle_i`.

## Exact terminal map

| Lane | Terminal source | Bound holder death |
| ---: | --- | --- |
| 0 | bank0 response | MIQ0/bridge0 response owner; legacy `mem_pending_q` final response |
| 1 | bank1 response | MIQ1/bridge1 response owner |
| 2 | bridge0 active drop | bridge0 active owner and any still-resident MIQ0 entry |
| 3 | bridge0 station drop | bridge0 station owner |
| 4 | bridge1 active drop | bridge1 active owner and any still-resident MIQ1 entry |
| 5 | bridge1 station drop | bridge1 station owner |
| 6 | reservation0 terminal | non-STORE reservation0 local completion/cancel |
| 7 | reservation1 terminal | non-STORE reservation1 local completion/cancel |
| 8 | legacy buffer terminal | non-STORE buffer cancel |
| 9 | AMO interphase cancel | unsent AMO write-phase `mem_pending_q` cancel |
| 10 | retry0 terminal | LOAD retry0 cancel |
| 11 | retry1 terminal | LOAD retry1 cancel |

STORE uses the separate exact `sq_owner_release_effective_mask_w` tracker
release path. Request fire and retry repush are holder handoffs, not terminal
events.

## Required phase distinction

| Phase | Active holder | Current ingress | Collector pending | Tracker live | Non-FENCE resolve |
| --- | ---: | ---: | ---: | ---: | ---: |
| unterminated owner | 1 | 0 | 0 | 1 | no |
| same-edge exact terminal transfer | 1 | 1 | 0 | 1 | yes, only if edge-new holder dies |
| collector-pending-only | 0 | 0 | 1 | 1 | yes |
| full idle | 0 | 0 | 0 | 0 | yes |
| ingress without holder death | 1 | 1 | 0 | 1 | no; fail-loud |
| holder death without ingress/release | 0 | 0 | 0 | 1 | no; fail-loud |

The reviewer recommended a single exact predicate generated in
`OooIntBackend` from reservation, MIQ, bridge active/station, buffer,
`mem_pending_q`, retry, SQ, collector-pending, tracker-live, current handoff,
same-edge birth, exact ingress, and exact STORE release masks. It must gate
both non-CSR drain completion and CSR Cresolve. Replacing it with full
`mem_idle_i` would be safe but unnecessarily wait for collector dequeue and
tracker free.

Duplicate terminal, pending duplicate, tuple mismatch, and same-edge
re-enqueue checks must remain fail-loud. This review did not cover pending
architectural trap, full seven-kind exactly-once retirement, Linux flag-on,
architecture-stable, synthesis, STA, power, or PPA.

Contract SHA-256:
`a22d03f2e49621db916e620ba0002f1341b4ab8cb7c7e6a6ccb844b254c80fa9`.
The reviewer modified no file and returned WSL command ownership.
