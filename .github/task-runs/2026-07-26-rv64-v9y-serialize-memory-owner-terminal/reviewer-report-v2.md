# V9Y post-implementation independent RTL review

## Verdict

`GAP`

Object: `OooIntBackend.mem_owner_terminalized_o` through
`OooPendingDrainResolveGate`.

Cycle/configuration: edge-old holder, same-edge terminal transfer, edge-new
collector pending/tracker live; both `OOO_ASSERT` enabled and disabled.

The RED, focused GREEN, 3/3 gate mutations, module 111/111, functional
aggregate, and architecture 9/9 evidence are green under design ID
`sha256:a26c1dc25148349b4b4606e9404fe8418125733dc450dfd653cd6926f1ba730a`,
but V9Y cannot close for two reasons.

## Blockers

1. The production predicate was inside the outer `` `ifdef OOO_ASSERT`` block
   in `OooIntBackend.v`. With `OOO_ASSERT` undefined, the only assignment to
   `mem_owner_terminalized_o` was removed and the production control input was
   undriven. Existing focused and module simulations all enabled
   `OOO_ASSERT`, so they did not cover this configuration.

2. Same-edge terminal transfer used the raw
   `mem_terminal_ingress_mask_w`, not collector acceptance-equivalent
   ingress. For a live active token with a wrong kind/epoch or duplicate
   ingress, the raw mask could remove the holder from the unterminalized set
   even though the collector rejected the handoff. An assertion-enabled
   simulation would fail at the edge, but the combinational control predicate
   could already authorize resolve; an assertion-disabled configuration could
   pass silently.

## Confirmed facts

- The static twelve-lane order is correct: response 0/1, bridge active drop
  2/4, bridge station drop 3/5, reservation terminal 6/7, legacy buffer
  cancel 8, AMO interphase cancel 9, and retry cancel 10/11.
- STORE uses the separate exact `sq_owner_release_effective_mask_w` path.
- The scalar reaches `OooPendingDrainResolveGate` without register or semantic
  transformation.
- CSR Cresolve and non-CSR drain both consume the scalar; ordinary `FENCE`
  still additionally requires full `mem_idle_i`.
- Under `OOO_ASSERT=1` and valid ingress, active, same-edge transfer,
  collector-pending-only, full-idle, orphan-live, and pending-without-live
  phase algebra is consistent.

## Required closure evidence

- Move all production predicate declarations and assignments outside
  `OOO_ASSERT`; leave shadow/fail-loud assertions inside.
- Add an explicit macro-off compile/run.
- Bind transfer to collector acceptance-equivalent token/kind/epoch and
  duplicate checks.
- Add invalid-kind/epoch, duplicate-ingress, same-edge re-enqueue, and exact
  SQ-release observations or negative variants.

The review does not close pending architectural trap, seven-kind serialized
exactly-once completion/retirement, `SERIALIZE-G1`, architecture-stable, or
PPA.

Contract SHA-256:
`a71208b4068eaead54cf4b95eb54f6803ebf0104ab889461249b2a821c5d8a12`.
The reviewer modified no file, left no process, and returned WSL command
ownership.
