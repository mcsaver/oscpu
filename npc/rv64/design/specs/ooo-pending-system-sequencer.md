# OooPendingSystemSequencer Spec

## 1. Requirements

- `OooPendingSystemSequencer` owns only the pending SYSTEM/CSR/IRQ register state
  that was previously stored directly in `OooAluFetchCore`.
- The module records exactly one serialized control entry.  Its canonical kind
  is one of `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`; the public
  Boolean type outputs are derived from that single registered kind and are not
  independent state.
- `SFENCE_FAMILY` covers accepted `SFENCE.VMA`, `SINVAL.VMA`,
  `SFENCE.W.INVAL`, and `SFENCE.INVAL.IR` encodings.  `FENCE` means ordinary
  `OPCODE_MISC_MEM/FUNCT3_FENCE`; it remains distinct from `FENCE.I`.
- The parent remains responsible for CSR side effects, trap/return target
  selection, pending owner arbitration, backend drain policy, fetch redirect, and
  precise recovery.
- The module is synchronous to `clk` and resets with `rst`; there is no separate
  flush input because the parent folds reset/flush into `rst`.

## 2. Protocol Rules

- Outputs are registered and may be consumed combinationally by the parent.
- A live post-dispatch CSR lease has highest lifecycle priority: only
  `producer_death_i` (exact CSR commit) or the parent-provided synchronous
  backend reset may clear it.  Ordinary clear, refresh, dispatch, and recapture
  inputs cannot overwrite that owner.
- Outside a live CSR lease, `clear_i` clears `valid/dispatched/kind`. Payload
  registers are intentionally left unchanged outside reset; every consumer
  must qualify them with `valid_o` and the canonical kind.
- Capture priority is `IRQ > lane0 SYSTEM > lane1 SYSTEM`. All capture sources
  require the holder to be empty and force `dispatched_o = 0`.  A held entry is
  never overwritten by a later capture.
- Each selected non-IRQ capture must classify to exactly one canonical kind.
  Ordinary FENCE is recognized from the captured instruction; every other kind
  comes from its dedicated capture bit.  A missing or overlapping
  classification is an interface violation and must fail loud under
  `OOO_ASSERT`.
- `dispatch_fire_i` is legal only for a held CSR.  It sets `dispatched_o`,
  births the exact `ProducerId` lease, and leaves kind/payload stable.
- `clear_dispatched_i` clears only `dispatched_o` and has lower priority than
  a valid CSR dispatch birth.  It cannot clear a live post-dispatch lease.
- `refresh_rdata_i` has the lowest priority and rewrites only `csr_rdata_o`
  (drain-complete re-latch, added with the FP domain-A migration: the rdata
  captured at dispatch time is stale when the CSR shares the window with
  in-flight fflags-producing FP instructions; the parent asserts it at
  `backend_drained && stop_pending && pending CSR && !dispatched`).

## 3. State Machine

- `IDLE`: `valid_o == 0`, kind is `NONE`, and there is no ProducerId lease.
  A selected capture moves to `HELD`.
- `HELD`: `valid_o == 1 && dispatched_o == 0`; kind and payload remain stable
  while the backend drains.  A non-CSR terminal clear returns to `IDLE`.  A CSR
  `dispatch_fire_i` moves to `CSR_DISPATCHED`.
- `CSR_DISPATCHED`: `valid_o == 1 && dispatched_o == 1 &&
  producer_valid_o == 1 && kind == CSR`.  The exact ProducerId and payload
  remain stable until `producer_death_i` or backend-global reset returns the
  holder to `IDLE`.

The parent timing contract is:

1. `Ccap`: arbiter capture and `stop_pending` set occur on the same edge.
2. `Cdrain`: no younger dispatch is admitted; the parent proves ROB/IQ/synthetic
   owners empty, `mem_retire_quiet`, and the V9Y
   [`mem_owner_terminalized`](./ooo-serialize-memory-owner-terminal.md)
   boundary. Ordinary FENCE additionally requires complete `mem_idle`.
3. `Cresolve`: non-CSR side effect/redirect/clear occurs, or a CSR is admitted
   to the ROB and receives its exact ProducerId lease.
4. `Ccommit`: only the exact CSR ROB-head ProducerId/PC match can perform the
   CSR write, redirect, and lease death.

`OooStopPendingSequencer` consumes the accepted holder-birth and registered
lease facts defined by
[`ooo-serialize-owner-birth.md`](./ooo-serialize-owner-birth.md). It must not
repeat raw lane/type classification. At the CSR `Cresolve` edge,
`system_csr_dispatch_fire_w` implies `pending_replay_wait_w`, so
`drain_complete_w` is combinationally false; the new exact lease and the
stop drain-clear arm cannot occur on the same edge.

Flush/recovery ownership:

| phase | branch/JALR or trap recovery | required result |
| --- | --- | --- |
| pre-ROB `HELD` | parent clear/reset | pending kind and valid clear; no side effect |
| post-dispatch CSR | same `core_local_flush` as ROB | holder and exact lease die together |
| ordinary drain completion | parent terminal clear | one side effect/redirect, then invalid |

## 4. Invariants

- Reset clears all state and payload.
- `clear_i` cannot create a valid pending entry.
- `valid_o` is equivalent to `kind != NONE`; a valid entry exposes exactly one
  of `csr/ecall/mret/wfi/sfence/fencei/fence/irq`.
- Any accepted capture writes a complete payload and clears `dispatched_o`.
- A non-empty holder rejects recapture; kind and payload remain stable until an
  authorized clear/death edge.
- IRQ capture always records `inst_o == 0`, `next_pc_o == pc_o`,
  `csr_rdata_o == 0`, and `irq_o == 1`.
- Non-IRQ captures always clear `irq_o` and `irq_cause_o`.
- `dispatch_fire_i` never changes `valid_o`, kind, PC, instruction, next PC,
  CSR rdata, or IRQ cause.
- `producer_valid_o` implies `valid_o && csr_o && dispatched_o`.

## 5. Datapath Constraints

- One register bank stores valid, dispatched, canonical kind, PC, instruction,
  architectural next PC, CSR read data, and IRQ cause.
- `fence_o` is the only pending-holder source for the parent's stronger
  ordinary-FENCE `mem_idle` drain term; the parent must not reconstruct this
  type from a second raw-instruction decoder.
- `mem_owner_terminalized` gates both non-CSR drain completion and CSR
  dispatch. It admits a collector-pending-only token but rejects every active
  holder without a verified same-edge terminal transfer.
- No combinational feedback is introduced into dispatch ready/valid. Dispatch
  readiness remains generated by the parent from registered outputs.
- Widths use `define.v`: `XLEN`, `INST_W`, and `TRAP_CAUSE_W`.
