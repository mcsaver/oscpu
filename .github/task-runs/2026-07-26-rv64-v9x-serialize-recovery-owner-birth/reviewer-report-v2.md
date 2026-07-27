# V9X post-implementation review v2

RV64 RTL 结论｜对象=serialization owner birth/live/lease、queue-head CSR owner、C0/C1 recovery｜周期/配置=edge-old→edge-new、`rob_walk_mode` 0/1、默认 `OOO_CSR_QUEUE_HEAD=0` 与待证 flag-on｜TB/EDA 观测=5 个负向 assertion 命中、7 个 focused PASS、111/111、全功能聚合 PASS、hard gates 9/9 GREEN｜范围=GAP

## Contract binding

- Contract: `reviewer-contract-v2.json`
- SHA-256: `f0e59a75a8687d45813e790d59d1822ab64292494c095f2170bc133d4dd6ef9c`
- The reviewed RTL hashes belong to architecture design cohort
  `sha256:69fe9222e3aa7e92a18bca9a61c93680323193f37b7d0d8f5ee6d7ee3b935c7a`.
- The review was read-only and ran no simulation, synthesis, or STA.

## Findings

1. `pre-ROB trap/exit × C1 core_local_flush` is not closed at the RTL
   boundary. `OooPendingSystemSequencer` consumes the C1 reset, while
   `OooPendingTrapExitSequencer` is reset only by `rst || flush_i`.
   `OooStopPendingSequencer` clears stop on C1. A live or same-edge captured
   trap/exit can therefore remain while stop clears. Production reachability
   still depends on the C0/C1 apply path outside the v2 contract.
2. The pre-ROB CSR transition into an exact lease lacks a same-edge proof.
   `OooStopPendingSequencer` observes edge-old
   `pending_system_producer_valid_i`; if
   `system_csr_dispatch_fire_i && drain_complete_i` is reachable, the drain
   branch can clear stop while `OooPendingSystemSequencer` creates the lease.
3. Queue-head CSR owner birth is reconstructed from
   `core_dispatch0_fire_w` plus FIFO-head facts instead of directly consuming
   `OooFrontend.head0_csr_dispatch_fire_w`. The merged dispatch fire also
   carries pending-system injection, so exact equivalence requires the
   frontend backend-dispatch mux path.
4. V9X evidence lacks the existing
   `tb_ooo_core_top_glue_v9o_csr_qh` flag-on target. The 111 default tests do
   not include this focused configuration.
5. The task report and completion definition remain pending, and the older
   focused directory contains a stale pre-fix FAIL. Those records cannot be
   presented as a completed task-run until the final evidence paths are
   distinguished explicitly.

## Same-edge truth table

| Owner phase / collision | Holder edge-new | `stop_pending` edge-new | Result |
| --- | --- | --- | --- |
| lane0/lane1 pending SYSTEM capture × accepted older recovery | capture rejected | no birth | PASS |
| trap/exit capture × matching squash clear | capture rejected; payload zero | no birth | PASS |
| ordinary clear × legal trap/exit replacement | replacement accepted | birth | PASS |
| exact pending CSR lease × ordinary recovery | lease holds | hold one | PASS |
| exact pending CSR lease × exact commit/C1 | lease clears | clears | PASS |
| queue-head CSR visible, backend not ready | no inflight | no birth | unit PASS; flag-on GAP |
| queue-head CSR fire × older branch/JALR kill | birth rejected | no birth | static PASS |
| queue-head CSR inflight × older branch/JALR kill | inflight clears | clears same edge | static PASS |
| queue-head CSR inflight × C1 | inflight clears | clears same edge | static PASS |
| pre-ROB trap/exit × C1 | holder lacks direct C1 reset | stop clears | GAP |
| pending CSR dispatch × drain-complete | lease becomes live | edge-old drain may clear | GAP |
| merged backend fire × visible queue-head CSR | real frontend fire not yet proven | reconstructed birth may assert | GAP |

## Evidence boundaries

- The two pre-fix recovery RED cases and exit squash RED have matching green
  tests.
- All five V9X assertion markers produced ERROR+FATAL under intentional
  invalid-state injection:
  `[V9X-STOP-BIRTH-WITNESS]`, `[V9X-STOP-LEASE-HOLD]`,
  `[V9X-STOP-QCSR-HOLD]`, `[V9X-STOP-OWNER-LIVE]`, and
  `[V9X-EXIT-SQUASH-COLLISION]`.
- Seven focused testbenches pass.
- `module-current-v2` is 111/111.
- The full functional aggregate is 111/111, 177/177, 59/59, zero DiffTest
  mismatches, CoreMark CRC `0xfcaf`, and Dhrystone 10000.
- The canonical architecture aggregate is 9/9 GREEN.
- These results do not prove the queue-head flag-on configuration,
  memory-owner terminal behavior, seven-kind serialized-transaction
  exactly-once behavior, arch-stable closure, or PPA qualification.

## Scope extension request

- Add `OooPendingDrainResolveGate.v` and its testbench to determine the
  reachability of `system_csr_dispatch_fire_w && drain_complete_w`.
- Add `OooFrontendBackendDispatchMux.v` and its testbench to prove merged
  `core_dispatch0_fire_w` equivalence to the real queue-head fire or replace
  the reconstructed birth with a direct accepted event.
- Add `OooPendingDispatchArbiter.v`, `OooCoreSliceControlGate.v`, and
  `OooControlEventApplySequencer.v` to determine C0/C1 reachability for the
  trap/exit holder.
- Run `tb_ooo_core_top_glue_v9o_csr_qh` with its flag-on configuration and
  preserve its V9O/V9P markers, command, return code, and design identity in
  the V9X task-run.

The reviewer returned WSL shell ownership to the root node and made no
workspace changes.
