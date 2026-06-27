# OoO Synthetic Lane1 Return Sequencer

## Stage 1 - Requirements

- `OooSyntheticLane1RetSequencer` owns the registered state used to retire a
  lane1 return instruction when lane0 direct branch handling must serialize the
  pair: `synth_lane1_ret_*` and `synth_lane1_branch_drop_*`.
- The parent still owns normal pending owner capture/clear, branch/RAS/BTB
  decisions, CSR/trap side effects, commit0/commit1 muxing, retire-count
  arithmetic, and backend-drain policy.
- Inputs are single-cycle predicates and payloads already produced by
  `OooAluFetchCore`: synthetic return capture, branch-commit observation,
  synthetic return commit, branch-drop match, SATP clear, and late precise trap
  clear.
- Outputs are registered and feed existing run gating, direct-branch
  suppression, backend-drain detection, commit mux, halted decision, and retire
  count logic.
- `rst || flush_i` clears all output state. In normal cycles, capture and clear
  events are applied with the same late-priority order as the old parent
  always block.
- Out of scope: changing the commit mux, branch append gate, direct branch
  resolve policy, RAS update policy, or trap/CSR side effects. The legacy
  `pending_lane1_ret` dispatch path is removed by the follow-up cleanup spec,
  not by this sequencer itself.

## Stage 2a - Protocol Rules

- The module is a synchronous state owner with no ready/valid backpressure.
- `capture_i` records a lane1 return payload and marks a synthetic return
  pending. `capture_branch_seen_i` records whether the older lane0 branch was
  already appended in the same cycle.
- When capture also needs to drop the older branch from the visible retire
  stream, `capture_branch_drop_i` sets a branch-drop entry with
  `capture_branch_pc_i`.
- `ret_commit_i` clears both the pending synthetic return and any branch-drop
  entry.
- `branch_drop_match_i` clears only the branch-drop entry when the parent has
  observed the older branch but is not committing the synthetic return in the
  same cycle.
- `branch_commit1_i` marks the older branch as seen after it commits from lane1.
- `satp_clear_i` clears the synthetic state at a privileged address-space
  boundary.
- `trap_clear_i` is the late precise-trap boundary and has the highest normal
  cycle priority.

## Stage 2b - State Machine

| State | Encoding | Meaning | Exit |
| --- | --- | --- | --- |
| `IDLE` | `ret_pending=0, drop_pending=0` | No synthetic lane1 return is waiting. | `capture_i` enters `WAIT_BRANCH` or `WAIT_RET`. |
| `WAIT_BRANCH` | `ret_pending=1, branch_seen=0` | Lane1 return payload is recorded, but the older branch has not yet committed. | `branch_commit1_i` enters `WAIT_RET`; `ret_commit_i`, `satp_clear_i`, or `trap_clear_i` returns to `IDLE`. |
| `WAIT_RET` | `ret_pending=1, branch_seen=1` | Synthetic lane1 return can be presented through the commit mux when parent arbitration allows it. | `ret_commit_i`, `satp_clear_i`, or `trap_clear_i` returns to `IDLE`. |
| `DROP_BRANCH` | `drop_pending=1` | Older branch should be suppressed/rewired in the visible retire stream. | `ret_commit_i`, `branch_drop_match_i`, `satp_clear_i`, or `trap_clear_i` clears the drop entry. |

`DROP_BRANCH` can overlap with `WAIT_RET`.

## Stage 2c - Invariants

- `ret_pending_o=0` implies `branch_seen_o=0` and all return payload outputs are
  cleared.
- `branch_drop_pending_o=0` implies `branch_drop_pc_o=0`.
- `ret_commit_i` clears return and drop state in the same cycle unless a later
  capture occurs; this matches the old parent maintenance-before-capture order.
- `branch_drop_match_i` never clears the synthetic return payload by itself.
- `capture_i` writes the return payload atomically: pending, branch-seen,
  branch PC, return PC, next PC, and instruction update on the same edge.
- `trap_clear_i` clears all state even if capture, commit, or SATP clear are
  also asserted by a malformed caller.
- The module never writes CSR, trap, ROB, register-file, FIFO, fetch PC, RAS,
  BPU, BTB, or pending owner state.

## Stage 2d - Datapath Constraints

- Registers: `ret_pending_q`, `ret_branch_seen_q`, `ret_branch_pc_q`,
  `ret_pc_q`, `ret_next_pc_q`, `ret_inst_q`, `branch_drop_pending_q`, and
  `branch_drop_pc_q`.
- Normal next-state order mirrors the old parent nonblocking assignment order:
  1. maintain existing state;
  2. apply `ret_commit_i`, else `branch_drop_match_i`, else `branch_commit1_i`;
  3. apply `capture_i` and optional `capture_branch_drop_i`;
  4. apply `satp_clear_i`;
  5. apply `trap_clear_i`.
- All outputs are direct register reads. The module adds no new combinational
  path from commit mux decisions into visible commit outputs.
