# OoO Pending Lane1 Return Dead-State Cleanup

## Stage 1 - Requirements

- Remove the legacy `pending_lane1_ret_*` dispatch path from
  `OooAluFetchCore`.
- The path is no longer produced by any current RTL assignment: lane1 return
  fallthrough retirement is owned by `OooSyntheticLane1RetSequencer`, and direct
  lane1 return RAS pop remains a direct event.
- Keep the external behavior unchanged:
  - normal frontend dispatch is no longer blocked by a permanently-zero pending
    lane1 return flag;
  - dispatch0 payload mux no longer contains unreachable pending lane1 return
    entries;
- `OooRasUpdateGate` drops its legacy pending lane1-ret input port because no
  current producer can drive it.
- Out of scope: changing synthetic lane1 return commit behavior, RAS stack
  priority, branch/RAS/BTB prediction rules, pending branch/jump/mem/system
  owner sequencing, CSR/trap side effects, retire count, or commit mux rules.

## Stage 2a - Protocol Rules

- There is no valid/ready transaction for the removed path after this cleanup.
- The old `pending_lane1_ret_dispatch_valid` was equivalent to a register that
  reset to zero and was never set; therefore all consumers observed an idle
  protocol permanently.
- Direct branch0-lane1-return handling still uses:
  - direct capture into `OooSyntheticLane1RetSequencer` for synthetic retire;
  - direct RAS update inputs for the same-cycle direct return event.
- The RAS gate input list now contains only real pop sources: direct ret0,
  direct ret1, pending jump return, and direct branch0 lane1 return.

## Stage 2b - State Machine

The removed legacy state machine was effectively:

| State | Meaning | Producer | Consumer | Transition |
| --- | --- | --- | --- | --- |
| `IDLE` | No pending lane1 return dispatch replay | reset only | all consumers | stays `IDLE` |

There is no reachable `PENDING` state in the current RTL. This cleanup deletes
that one-state dead machine and its unreachable dispatch mux arms.

## Stage 2c - Invariants

- `pending_lane1_ret` must not exist as a register in `OooAluFetchCore` after
  this cleanup.
- No dispatch valid, dispatch payload mux, stop/run gate, or testbench monitor
  may consume `pending_lane1_ret_*`.
- The parent must not contain assignments to `pending_lane1_ret_*`.
- `OooRasUpdateGate` must not expose a pending lane1-ret input port until a
  future spec introduces a real replay producer.
- Synthetic lane1 return commit remains the only lane1-return delayed retire
  state owner.

## Stage 2d - Datapath Constraints

- Remove four parent registers:
  - `pending_lane1_ret_q`
  - `pending_lane1_ret_pc_q`
  - `pending_lane1_ret_next_pc_q`
  - `pending_lane1_ret_inst_q`
- Remove their reset/clear assignments and the `pending_lane1_ret_fire` clear
  block.
- Remove the unreachable dispatch0 valid and payload mux branches.
- Remove the permanent block from normal `dispatch_valid_w`.
- Update the focused fetch-core monitor to observe the direct lane1 return event
  only; the old pending fire monitor was observing an unreachable wire.

## Stage 3 - RTL Mapping

- `OooAluFetchCore.v` deletes the dead registers and unreachable mux arms.
- `OooRasUpdateGate` and `tb_ooo_ras_update_gate` drop the legacy pending
  lane1-ret pop source from their interface/coverage matrix.
- `tb_ooo_alu_fetch_core.sv` no longer references the removed internal wire.
- Verification must include a static scan proving no `pending_lane1_ret`
  identifier remains in frontend RTL or affected focused testbenches.
