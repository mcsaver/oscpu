# V9X SERIALIZE-G1 recovery × lane × holder-phase contract

## RTL object

- Local RV64 OoO dispatch/control/front-end path only.
- Primary modules:
  - `OooPendingDispatchArbiter`
  - `OooPendingSystemSequencer`
  - `OooStopPendingSequencer`
  - `OooFrontendRunGate`
- Primary transactions:
  - lane0/lane1 serialized-system dispatch
  - queue-head CSR dispatch and exact `ProducerId` lease
  - older branch/JALR, trap and core-local recovery
  - pending-system holder capture/clear and stop owner birth/clear

## Hard constraints

1. Older recovery wins over a younger same-edge serialized-system request before ROB ownership.
2. Once a queue-head CSR holder owns an exact `ProducerId`, unrelated recovery must not clear that lease; only matching death/commit or architectural reset may clear it.
3. `stop_pending_q` may be born only with a real serialization owner or an explicitly contracted queue-head CSR inflight owner.
4. Lane0/lane1 priority and `rob_walk_mode_i` behavior must agree between pending-holder capture and stop-owner birth.
5. Do not add terminal-event deduplication and do not weaken any RTL assertion.
6. Preserve current dual-issue behavior and the queue-head CSR first-cycle dispatch block.

## Required result

- Freeze the cycle-accurate recovery × lane × phase truth table.
- Identify every mismatch between the actual pending-holder capture event and stop-owner birth.
- Convert at least one real mismatch into a directed negative regression before the RTL correction.
- Apply the smallest single-source RTL correction supported by the contract.
- Run focused, layered and architecture-gate verification; record exact commands, return codes and markers.

## Promotion boundary

This slice may close only the recovery/owner-birth sub-contract. `SERIALIZE-G1`, arch-stable and PPA promotion remain open until memory-owner terminal evidence and all remaining architecture blockers are independently closed.
