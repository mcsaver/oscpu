# V9Z local RV64 pending-arch-trap memory-terminal contract

## Scope

This task closes only the `pending_arch_trap_q` consumer of the current
memory-owner terminal predicate.

Current production path:

`OooIntBackend.mem_owner_terminalized_o → OooAluDecodeBackend →`
`OooAluCoreSlice → OooExecuteBackend → OooCoreTopGlue →`
`OooControlPlane.mem_owner_terminalized_i →`
`OooPendingDrainResolveGate.drain_complete_o →`
`OooCsrTrapRequestMux.pending_arch_trap_fire_o`.

The current gate qualifies `drain_complete_o` with
`mem_owner_terminalized_i` only when `pending_system_i` is set.
`pending_arch_trap_i` is therefore an uncovered serialized consumer.

## Required behavior

- A pending architectural trap must not generate
  `pending_arch_trap_fire_o`, CSR execute-trap entry, redirect, or pending
  clear while any older memory token remains in an active MIQ, bridge,
  reservation, buffer, AMO, retry, or SQ holder.
- An exact current-edge accepted terminal transfer may authorize the same
  architectural-trap resolve edge.
- A collector-pending-only token must not add collector dequeue latency.
- `pending_system_i`, CSR dispatch, and ordinary FENCE retain the V9Y
  behavior. Ordinary FENCE continues to require complete `mem_idle_i`.
- Simulation exit is outside this slice unless a concrete shared-gate
  counterexample requires a separate contract.
- Duplicate, wrong-kind/epoch, pending-duplicate, and same-edge re-enqueue
  terminal events remain fail-loud. No deduplication is permitted.

## Pre-fix counterexample

With:

- `stop_pending_i=1`;
- `pending_control_ready_i=1`;
- `backend_drained_o=1`;
- `pending_arch_trap_i=1`;
- `pending_system_i=0`;
- `mem_owner_terminalized_i=0`;

the current `pending_system_mem_terminal_w` evaluates to one, so
`drain_complete_o` can evaluate to one. The downstream mux then asserts
`pending_arch_trap_fire_o` while an older memory owner is still active.

## Minimal implementation boundary

The shared drain gate must require the exact production
`mem_owner_terminalized_i` predicate when either `pending_system_i` or
`pending_arch_trap_i` is the serialized owner. It must not replace this
predicate with full `mem_idle_i`, and it must not add new state or modify the
collector/tracker acceptance algebra.

## Verification obligations

- Preserve a pre-fix RED for active-holder plus pending architectural trap.
- Add positive controls for exact terminalized/pending-only and full-idle
  phases.
- Preserve V9Y non-FENCE, CSR, and ordinary-FENCE cases.
- Bind the gate result through `OooCsrTrapRequestMux` so
  `pending_arch_trap_fire_o` and its cause/PC/tval payload cannot fire early.
- Reject compile-success RTL variants that remove the arch-trap terminal
  term or replace it with full `mem_idle_i`.
- Run focused assertion-enabled and assertion-disabled configurations,
  affected control tests, module aggregate, current-design functional and
  architecture gates.
- Independent reviewer must search for overlap, priority, vacuity,
  assertion-only, and evidence-provenance counterexamples.

## Non-claims

This slice does not close seven-kind serialized exactly-once retirement,
simulation exit, full Linux flag-on, `SERIALIZE-G1`, full-core
architecture-stable, synthesis/STA/power, or PPA promotion.

