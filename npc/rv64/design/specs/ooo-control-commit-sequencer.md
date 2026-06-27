# OoO Control Commit Sequencer

## Stage 1 - Requirements

- `OooControlCommitSequencer` owns the registered pseudo-commit state used by
  serialized front-end control instructions: `ctrl_commit_valid`, commit0
  payload, and `core_serial_flush`.
- The parent still owns pending owner capture/clear, CSR side effects, trap
  register writes, ROB commit muxing, FPR writes, PC/outstanding sequencing, and
  backend drain policy.
- Inputs are single-cycle event predicates and payloads already produced by
  `OooAluFetchCore`. Outputs are registered and feed the existing commit0 mux,
  retire count, local flush, and front-end run gates.
- `rst || flush_i` clears all output state. During normal cycles, valid/write
  metadata and `core_serial_flush` are one-cycle pulses; PC/inst/next-PC payload
  registers retain their last value when invalid, matching the old parent block.
- Out of scope: changing ROB commit arbitration, CSR/trap commit order, pending
  owner lifetime, FPR storage, or architectural register-file policy.

## Stage 2a - Protocol Rules

- The module is a fixed-latency synchronous state owner with no ready/valid
  backpressure.
- `pending_jump_nolink_commit_i` emits a one-cycle control commit for a resolved
  no-link JAL/JALR when the parent has already accepted the commit boundary.
- `drain_complete_i` allows one drained pending owner to become a pseudo commit:
  MRET/SRET, non-trapping system control, undispatched branch fallback, or FP
  GPR writeback/observation. ECALL, IRQ, architectural trap, pending jump, and
  pending memory do not emit a pseudo commit here.
- Jump no-link commit has priority over drain commit if both are asserted by a
  malformed caller; this follows the old parent `if/else` control order.
- FP GPR pseudo commit also raises `core_serial_flush_o` for one cycle so
  younger backend state is flushed after serializing the GPR-visible FP result.

## Stage 2b - State Machine

| State | Encoding | Meaning | Exit |
| --- | --- | --- | --- |
| `IDLE` | `valid=0, serial_flush=0` | No pseudo commit is visible this cycle. | Jump no-link or eligible drained owner enters `PULSE_COMMIT`; FP GPR commit also pulses serial flush. |
| `PULSE_COMMIT` | `valid=1` | One pseudo commit is visible on commit0 for exactly one cycle. | Next cycle returns to `IDLE` unless a new event arrives. |
| `PULSE_FLUSH` | `serial_flush=1` | FP GPR pseudo commit requests one local serial flush. | Next cycle returns to `IDLE` unless another FP GPR event arrives. |

`PULSE_COMMIT` and `PULSE_FLUSH` can be true together for FP GPR commit.

## Stage 2c - Invariants

- `ctrl_commit_valid_o` is a pulse: without a new event it clears in the next
  cycle. A stuck valid would duplicate retirement.
- `core_serial_flush_o` is a pulse and can only be asserted by an FP GPR commit.
  A stuck flush would block normal front-end/backend progress.
- ECALL, IRQ, pending architectural trap, misaligned pending branch, pending
  jump, and pending memory never produce `ctrl_commit_valid_o`; their
  architectural side effects remain owned by trap/CSR or redirect logic.
- When `ctrl_commit_valid_o` is high, commit1 must be suppressed by the parent
  mux. This module only supplies the commit0 payload; it never drives commit1.
- `ctrl_commit_write_o` is true only for FP GPR commits with a nonzero
  destination register.
- The module never writes CSR, trap, FPR, ROB, FIFO, BPU/RAS/BTB, or fetch PC
  state.

## Stage 2d - Datapath Constraints

- Registers: `valid_q`, `pc_q`, `inst_q`, `next_pc_q`, `rd_en_q`, `rd_addr_q`,
  `rd_data_q`, `write_q`, and `serial_flush_q`.
- Jump no-link payload mux selects pending jump PC/inst/resolved target and
  forces rd/write metadata to zero.
- Drained system payload mux selects pending system PC/inst and either
  `csr_ret_target_i` for MRET/SRET or `pending_system_next_pc_i` for other
  non-trapping system controls.
- Drained branch payload mux selects pending branch PC/inst/next-PC only when
  the branch was not already dispatched and is not misaligned.
- Drained FP payload mux selects pending FP PC/inst/next-PC, destination, and
  result value; it may set rd/write metadata and serial flush.
- All muxes are registered at the clock edge. The module adds no new
  combinational path from CSR/trap/pending events into ROB commit outputs.
