# OooPendingSystemSequencer Spec

## 1. Requirements

- `OooPendingSystemSequencer` owns the pending SYSTEM/CSR/IRQ register state
  that was previously stored directly in `OooAluFetchCore`, plus the
  cancellable pre-ROB CSR dispatch permit bound to that same holder.
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
- `dispatch_eligible_i` is the parent's exact drain observation.  It may arm
  `dispatch_permit_o` only for a held, undispatched CSR with no ProducerId
  lease and no registered queue-head CSR owner.  The registered permit holds
  across backend-ready stalls.
- `dispatch_cancel_i`, holder clear, orphan recovery, dispatch fire, exact
  producer death, backend reset, or `head0_csr_inflight_i` while the permit is
  held clears the permit.  Cancellation has priority over arming, including on
  the same edge.  `head0_csr_inflight_i` also blocks arm while the permit is
  empty; the arm and held-clear terms are independently mutation-visible.
- `dispatch_fire_i` is legal only with a live, uncancelled permit and a held
  CSR.  It consumes the permit, sets `dispatched_o`, births the exact
  `ProducerId` lease, and leaves kind/payload stable.
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
  exact-drain observation registers `dispatch_permit_o` without changing the
  payload state.
- `HELD_PERMITTED`: the held CSR has `dispatch_permit_o == 1`.  Cancellation
  returns it to `HELD`; accepted `dispatch_fire_i` consumes the permit and
  moves to `CSR_DISPATCHED`.
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
3. `Cpermit`: for CSR only, the exact `Cdrain` eligibility is sampled into the
   cancellable permit. Non-CSR side effects keep their established direct
   drain-complete timing.
4. `Cresolve`: the permitted CSR is admitted to the ROB and receives its exact
   ProducerId lease.
5. `Ccommit`: only the exact CSR ROB-head ProducerId/PC match can perform the
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
- `dispatch_permit_o` implies `valid_o && csr_o && !dispatched_o &&
  !producer_valid_o && !head0_csr_inflight_i` at the parent transaction
  boundary.
- `dispatch_fire_i` implies a live permit and no current cancellation.

## 5. Datapath Constraints

- One register bank stores valid, dispatched, canonical kind, PC, instruction,
  architectural next PC, CSR read data, and IRQ cause.
- `fence_o` is the only pending-holder source for the parent's stronger
  ordinary-FENCE `mem_idle` drain term; the parent must not reconstruct this
  type from a second raw-instruction decoder.
- `mem_owner_terminalized` gates non-CSR drain completion and the raw CSR
  eligibility sampled by `dispatch_permit_o`. It admits a
  collector-pending-only token but rejects every active holder without a
  verified same-edge terminal transfer. The actual CSR dispatch mux consumes
  the permit, not the scalar terminal signal.
- No combinational feedback is introduced into dispatch ready/valid. Dispatch
  readiness remains generated by the parent from registered outputs. In
  particular, the memory-owner terminal cone cannot propagate through CSR
  payload selection, backend readiness, frontend action, or fetch flow.
- Queue-head CSR ordering uses the existing registered
  `head0_csr_inflight_q` to block permit arm/hold.  The queue-head commit event
  remains an exact holder/admission clear and serial-flush witness, but does
  not feed the pre-ROB dispatch-cancel mux.
- Widths use `define.v`: `XLEN`, `INST_W`, and `TRAP_CAUSE_W`.

## 6. V15U Qualification Record

The qualified production identity is
`sha256:e34bcf47cf2e69976190cff4a13cf21b4f8f3e18495858b3256e9d5205bec6ce`
over 146 production RTL files. The focused task-run
`.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-focused-mutation-a1`
observes permit arm/hold/cancel/re-arm/fire and the production-like
memory-terminal-to-CSR-dispatch integration with `OOO_ASSERT` enabled. Its
assertion-disabled compile-success variant removes cancel priority and is
rejected at the lane1 same-edge cancellation observation. The before/after RTL
identities match and the temporary compile tree is deleted after evidence
sealing.

The current full-core task-run
`.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1`
passes 113/113 module tests, 177/177 official tests, 61/61 AM tests, DiffTest
with zero mismatches, CoreMark and Dhrystone. The same identity passes the full
L2 mini-system run at 6,098,497 commits / 9,882,568 cycles and the full L3
lightweight-Linux run at 24,460,280 commits / 57,129,353 cycles. Both runs have
zero RTL assertion failures, stable input hashes, exactly one natural syscon
poweroff and exactly one `GOOD TRAP`; L3 additionally observes exactly one
kernel `Power down`. Ubuntu 22.04/systemd was not run and is not claimed.

The same-configuration 5 ns mapped comparison against
`sha256:102e2f600d396b63f41172597c43011da1b3c8b28947f88e14f0cf4d8f37e90d`
improves WNS from -17.413881302 ns to -13.794656754 ns, TNS from
-464687.6875 ns to -399965.46875 ns, logic-area proxy by -110.88, and cell
count by -146; sequential area changes by +12.32 and fixed-toggle relative-only
power is unchanged at 0.136 W. The 5 ns target remains unmet. V15U is therefore
retained only as an engineering candidate with functional L0-L3 evidence, not
as timing or release signoff.

## 7. V15V/V15W Exact-Death / Pre-ROB Cancel Split

`pending_system_csr_commit` belongs to `CSR_DISPATCHED`: its authorization
requires `dispatched_o && producer_valid_o` plus exact ProducerId/PC match.
`dispatch_permit_o` belongs to `HELD_PERMITTED` and implies
`!dispatched_o && !producer_valid_o`. V15V therefore removes the exact pending
commit from the combinational pre-ROB `dispatch_cancel_i` cone while retaining
it as `producer_death_i` and full holder/admission clear. V15W applies the same
phase split to queue-head CSR commit: the existing registered
`head0_csr_inflight_q` blocks pending-CSR permit arm and clears a held permit;
the exact commit still clears the younger lane1 pending owner but no longer
feeds pre-ROB dispatch cancel.

The standalone admission-cancel TB must observe exact pending commit as
`clear=1,cancel=0` and head0 commit as `clear=1,cancel=0`. The sequencer TB must
observe inflight arm block, held-permit clear, continued re-arm block, and
release/re-arm. Existing V15V negative variants continue to reject reconnecting
exact pending commit to dispatch cancel or deleting it from full holder clear.
V15W adds four independent `OOO_ASSERT=0` compile-success variants: delete the
inflight arm blocker, delete held-permit clear, reconnect head0 commit to
dispatch cancel, and delete head0 commit from admission clear. The parent
assertions require `head0_csr_commit -> head0_csr_inflight`,
`head0_csr_inflight -> !system_csr_dispatch_permit`, and head0 commit disjoint
from pending CSR dispatch valid/fire.

## 8. V15X ROB-head trap / pre-ROB cancel split

`csr_trap_mem_valid` is the architectural commit consequence of the canonical
C0 `TRAP` pregrant. `OooCoreTopGlue` asserts their bidirectional equivalence,
and ROB-I14 closes both dispatch-ready lanes for every C0 control pregrant.
The trap remains a full `pending_system_clear` witness, which blocks permit arm
and clears a held pre-ROB payload/permit on the clock edge. It therefore does
not also feed the late combinational `dispatch_cancel_i` path.

The admission-cancel TB must observe the trap as `clear=1,cancel=0`. The
sequencer TB must show that holder clear consumes a held permit and payload
with cancel low, then permits a clean recapture/re-arm. The parent assertion
requires trap to be disjoint from pending CSR permit, valid, and fire; the
existing C0 equivalence and ROB dispatch-closure assertions remain enabled.
