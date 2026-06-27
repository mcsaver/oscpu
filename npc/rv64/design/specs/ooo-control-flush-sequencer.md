# OoO Control Flush Sequencer

## Stage 1 - Requirements

- `OooControlFlushSequencer` owns the registered flush state that used to live
  in `OooAluFetchCore`: `core_trap_flush`, `trap_redirect_squash`, and
  `checkpoint_mem_flush`.
- The parent still owns trap/CSR side effects, pending owner clear, branch
  checkpoint generation, fetch PC/outstanding sequencing, memory request
  arbitration, and commit muxing.
- Inputs are already-prioritized predicates from `OooAluFetchCore`. Outputs are
  registered and feed existing run gates, action gates, local flush, memory
  flush, and branch recovery suppression logic.
- `rst || flush_i` from the parent clears all output state. In normal cycles,
  trap flush and checkpoint memory flush are one-cycle registered pulses driven
  by their request predicates; trap redirect squash is a sticky state that holds
  until the backend is drained.
- Out of scope: changing CSR trap ordering, branch predictor/RAS update policy,
  memory checkpoint restore policy, backend drain detection, or commit/retire
  arbitration.

## Stage 2a - Protocol Rules

- The module is a synchronous state owner with no ready/valid backpressure.
- `trap_flush_req_i` produces `core_trap_flush_o` for one cycle on the next
  clock edge. The current parent drives this request from `csr_trap_mem_valid`.
- `checkpoint_restore_i` produces `checkpoint_mem_flush_o` for one cycle on the
  next clock edge. If the restore predicate remains high, the output remains
  high cycle by cycle.
- `priv_predictor_boundary_i` sets `trap_redirect_squash_o`. Once set, it
  remains asserted while `backend_drained_i` is low, blocking stale direct
  branch recovery across privileged/trap predictor boundaries.
- If `priv_predictor_boundary_i` and `backend_drained_i` are both high in the
  same cycle, the set wins and `trap_redirect_squash_o` is asserted for the
  next cycle. A later drained cycle with no new boundary clears it.
- Reset has priority over all requests, matching the old parent
  `if (rst || flush_i) ... else ...` block.

## Stage 2b - State Machine

| State | Encoding | Meaning | Exit |
| --- | --- | --- | --- |
| `IDLE` | `core_trap_flush=0, trap_redirect_squash=0, checkpoint_mem_flush=0` | No registered flush/squash state is visible. | Trap request pulses trap flush; checkpoint restore pulses memory flush; privileged predictor boundary enters `SQUASH_HELD`. |
| `PULSE_TRAP_FLUSH` | `core_trap_flush=1` | Frontend/backend local flush is requested for one cycle after precise trap commit. | Returns to `IDLE` unless a new trap request arrives. |
| `PULSE_CHECKPOINT_MEM_FLUSH` | `checkpoint_mem_flush=1` | Memory side is flushed for one cycle after branch-spec checkpoint restore. | Follows `checkpoint_restore_i` cycle by cycle. |
| `SQUASH_HELD` | `trap_redirect_squash=1` | Stale direct branch recovery is suppressed across a trap/CSR/predictor boundary. | Clears when `backend_drained_i=1` and no new boundary arrives. |

The pulse states can overlap with `SQUASH_HELD`.

## Stage 2c - Invariants

- `core_trap_flush_o` is a registered pulse derived only from
  `trap_flush_req_i`; without a new request it clears in the next cycle.
- `checkpoint_mem_flush_o` is the registered value of `checkpoint_restore_i`.
- `trap_redirect_squash_o` cannot clear while the backend is not drained.
- A same-cycle privileged boundary has priority over drained clear, so squash
  is never lost at a privilege/trap predictor boundary.
- The module never writes FIFO, RAS, BPU, BTB, CSR, ROB, register-file, memory
  payload, or fetch PC state.

## Stage 2d - Datapath Constraints

- Registers: `core_trap_flush_q`, `trap_redirect_squash_q`, and
  `checkpoint_mem_flush_q`.
- Next-state equations:
  - `core_trap_flush_d = trap_flush_req_i`
  - `checkpoint_mem_flush_d = checkpoint_restore_i`
  - `trap_redirect_squash_d =
     (trap_redirect_squash_q && !backend_drained_i) ||
     priv_predictor_boundary_i`
- All outputs are direct register reads. The module adds no new combinational
  path from CSR/trap/checkpoint requests into local flush consumers.
