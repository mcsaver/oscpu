# OoO serialized owner-birth contract

## 1. Purpose and scope

This contract closes the `SERIALIZE-G1` recovery/owner-birth sub-slice for the
local RV64 dual-issue OoO core.  It aligns the registered `stop_pending` state
with the owners that are actually accepted by:

- `OooPendingSystemSequencer`;
- `OooPendingTrapExitSequencer`; and
- the queue-head CSR inflight register in `OooFrontend`.

It does not change serialized-operation terminal side effects, memory-owner
quiet rules, redirect arbitration, AXI ownership, or the exact CSR
`ProducerId` match.  It does not close the remaining `SERIALIZE-G1`,
arch-stable, or PPA promotion gaps.

## 2. Interface contract

### 2.1 Ports and ownership

| Signal | Producer | Consumer | Timing | Meaning |
| --- | --- | --- | --- | --- |
| `pending_owner_birth_w` | `OooControlPlane` | `OooStopPendingSequencer` | combinational before `Ccap` edge | At least one pending SYSTEM/trap/exit holder will be valid after this edge. |
| `pending_owner_live_w` | registered holders in `OooControlPlane` | `OooStopPendingSequencer` assertion | registered level | A pending SYSTEM/trap/exit owner currently exists. |
| `head0_csr_dispatch_fire_w` | `OooFrontend` | `OooControlPlane` | combinational before queue-head dispatch edge | The canonical ready-qualified, legal, non-FP queue-head CSR acceptance event. It is shared with the frontend inflight owner and must not be reconstructed from the merged backend fire. |
| `v9x_head0_csr_owner_birth_w` | `OooControlPlane` | `OooStopPendingSequencer` | combinational before queue-head dispatch edge | The canonical frontend fire after same-edge older-control kill, C1 reset and exact commit exclusion. |
| `head0_csr_owner_kill_w` | branch resolve facts | front-end inflight register and stop sequencer | combinational | The exact older branch/JALR recovery that cancels queue-head CSR ownership. |
| `head0_csr_inflight_w` | `OooFrontend` | run gate and stop sequencer | registered level | A queue-head CSR has entered the ROB and not reached commit/recovery death. |
| `pending_system_producer_valid_w` | `OooPendingSystemSequencer` | stop sequencer | registered level | A post-dispatch pending CSR owns an exact `ProducerId` lease. |
| `core_local_flush_w` | `OooCoreSliceControlGate` | pending SYSTEM/trap/exit holder reset and stop sequencer | combinational C1 apply | Backend-global recovery/reset for registered owners. |

No new ready/valid feedback is introduced.  All new birth terms drive only the
D input of `stop_pending_o`; all inputs are already available before the clock
edge.  Registered stop/holder outputs remain the only inputs to `can_run`.

### 2.2 Six boundary classes

| Contract class | Frozen rule |
| --- | --- |
| Data | The change carries no architectural payload; PC, instruction, CSR data and `ProducerId` remain in their existing holders. |
| Control | `stop_pending` birth consumes accepted owner-birth events, not raw lane classification. |
| Backpressure | Queue-head CSR birth requires the same real lane0 dispatch fire that consumes backend ready; a merely visible/not-ready CSR cannot arm stop. |
| Flush/recovery | Pre-ROB clear wins over younger capture; post-dispatch exact CSR lease survives ordinary recovery until exact death or C1 reset; queue-head inflight dies with its exact older-control kill or C1 reset. |
| Exception | Trap/exit owner birth follows the validity and squash priority implemented by `OooPendingTrapExitSequencer`; a rejected wrong-path trap cannot arm stop. |
| Performance | No new combinational path reaches dispatch ready, fetch ready, redirect PC or memory request arbitration.  The added logic is a narrow Boolean cone into one register D input. |

### 2.3 Flush/recovery clear-versus-hold table

| Owner phase | C0 trap/exit | older branch/JALR recovery | C1 `core_local_flush` | exact terminal |
| --- | --- | --- | --- | --- |
| empty / candidate capture | no birth | no birth if the target holder rejects the capture | no birth | not applicable |
| pre-ROB pending SYSTEM/trap/exit | clear holder and stop together | clear holder and stop together | direct holder reset and stop clear on the same edge | drain terminal clears both |
| post-dispatch pending CSR lease | lease and stop hold until C1 | lease and stop hold until C1 | clear lease and stop together | exact CSR commit clears both |
| queue-head CSR birth | birth rejected when the front-end inflight register rejects it | birth rejected | birth rejected | not applicable |
| queue-head CSR inflight | hold through C0 while owner remains | exact older-control kill clears owner and stop together | clear owner and stop together | head0 CSR commit clears both |

The architectural transaction invariants remain unchanged: committed stores
survive all flushes, accepted AXI owners drain to protocol completion, and a
CSR write already made visible at commit is not undone.

### 2.4 Same-edge priority, high to low

1. `rst`, external `flush_i`, or C1 `core_local_flush_i`;
2. exact pending-CSR death or queue-head CSR commit;
3. live exact pending-CSR lease hold;
4. surviving queue-head CSR inflight hold;
5. committed trap and accepted older-control/pre-ROB clear;
6. accepted pending-owner or queue-head CSR birth;
7. normal hold.

An event filtered out by its holder cannot appear at level 6.  A live lease at
level 3 is deliberately different from a pre-ROB holder: ordinary clear is
not its death.

### 2.5 Cycle examples

```text
pre-ROB collision:
  Cn:   older_recovery=1, raw_system=1, accepted_birth=0
  Cn+1: pending_system=0, stop_pending=0

queue-head CSR:
  Cn:   csr_visible=1, backend_ready=0, owner_birth=0
  Cn+1: inflight=0, stop_pending=0
  Cm:   csr_dispatch_fire=1, older_kill=0, owner_birth=1
  Cm+1: inflight=1, stop_pending=1

exact pending CSR:
  Ck:   producer_valid=1, ordinary_recovery=1
  Ck+1: producer_valid=1, stop_pending=1
  Ck+1: core_local_flush=1
  Ck+2: producer_valid=0, stop_pending=0
```

## 3. State and timing model

`OooStopPendingSequencer` remains a one-bit FSM:

| State | Meaning | Entry | Exit |
| --- | --- | --- | --- |
| `RUN` | no serialization stop | accepted owner birth | reset/C1, exact terminal, accepted owner death |
| `STOP` | a registered owner blocks younger dispatch | live holder/lease/inflight | matching owner death or recovery |

The state transition is a single explicit priority chain.  Multiple
independent nonblocking writes to `stop_pending_o` are forbidden.

Owner phases are external registered state, not duplicated inside the stop
sequencer:

- pending SYSTEM `IDLE/HELD/CSR_DISPATCHED`;
- trap/exit invalid/valid;
- queue-head CSR idle/inflight.

## 4. Invariants

- `V9X-INV1`: in the current ROB-walk architecture, a rising
  `stop_pending_o` has a previous-edge accepted pending owner birth or
  queue-head CSR owner birth.
- `V9X-INV2`: `pending_system_producer_valid_w` implies
  `stop_pending_o` until exact death/C1 reset.
- `V9X-INV3`: queue-head CSR inflight implies `stop_pending_o` until exact
  commit/older-control kill/C1 reset.
- `V9X-INV4`: a pending-system capture colliding with its accepted pre-ROB
  clear cannot produce owner birth.
- `V9X-INV5`: `stop_pending_o` must not be used to hide duplicate terminal
  events; terminal exactly-once remains separately asserted and tested.
- `V9X-INV6`: a C1 `core_local_flush_w` edge clears pending SYSTEM,
  trap/exit and queue-head owners together with `stop_pending_o`.
- `V9X-INV7`: merged `core_dispatch0_fire_w=1` with canonical
  `head0_csr_dispatch_fire_w=0` cannot birth a queue-head stop owner.

Encodable invariants are immediate `OOO_ASSERT` checks.  Each new check must
be exercised by an intentional negative module configuration before the
architecture gate is accepted.

## 5. Critical path and topology

- Registers: only the existing one-bit `stop_pending_o`; no new state.
- Combinational blocks:
  - accepted pending-system birth;
  - accepted trap/exit birth;
  - exact queue-head CSR birth/kill;
  - explicit stop next-state priority mux.
- Shared resource: one Boolean owner-birth OR and one next-state mux; no
  arithmetic or payload mux is added.
- Expected longest added path:
  `capture/kill fact -> owner_birth AND/OR -> stop_pending D`.
- The path terminates at a register and does not feed dispatch ready in the
  same cycle.
- There is no FSM helper function and no loop-generated hardware.

## 6. Verification plan

1. RED proof on the old RTL:
   - lane0 SYSTEM + mode1 older-branch recovery;
   - lane1 SYSTEM + recovery.
2. Focused module tests:
   - empty/pre-ROB accepted and rejected birth;
   - queue-head CSR not-ready, accepted, killed-birth and C1 death;
   - exact lease ordinary-clear hold and exact-death clear;
   - lane0/lane1 accepted owner matrix.
3. Flag-on integration:
   - canonical queue-head fire, inflight and stop birth;
   - merged-fire alias with real fire zero;
   - pre-ROB exit holder followed by isolated C1 reset;
   - older branch/JALR recovery and typed C0/C1 terminal markers.
4. Assertion-negative run for ownerless stop and lease/stop divergence.
5. Compile-success RTL variants that remove the C1 holder reset or replace
   canonical queue-head fire with merged fire; both must be rejected.
6. RTL style, lint, `check-contract`, complete module suite.
7. Full functional aggregate and architecture gate; no claim beyond the
   evidence actually produced.

## 7. Risks and rollback

- Queue-head CSR remains default-off; flag-off green runs do not validate its
  dynamic path.  Dedicated flag-on module tests are mandatory.
- Memory-owner terminal proof and seven-kind exactly-once proof are separate
  `SERIALIZE-G1` blockers.
- If an accepted-birth term creates a ready/valid combinational loop, revert
  the consumer wiring and keep the RED evidence; do not mask the loop with a
  delayed duplicate owner.

## 8. Change record

- 2026-07-26 V9X: contract frozen before RTL changes from independent
  recovery × lane × holder-phase review.
- 2026-07-27 V9X post-v3: queue-head birth consumes the canonical frontend
  fire, trap/exit holder consumes C1 reset, and two compile-success variants
  prove the corresponding flag-on oracles are fail-closed.
