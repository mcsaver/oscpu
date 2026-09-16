# OoO Control Commit Sequencer

> ⚠️ **状态（2026-07-03 RTL 重读）**：FP GPR pseudo-commit 臂已随 pending-FP 拆除物理删除（RTL 注释自证，FP 经 ROB 真 commit），`core_serial_flush_o` 与 rd_en/rd_data/write 元数据恒 0（每拍清零、无置位路径）；jump no-link 与 undispatched-branch 两臂因 pending_jump/pending_branch 通道判死而不可达——活路径仅剩 drain 出口的 SYSTEM 合成 commit（mret/sret/wfi/sfence/CSR-illegal 兜底）；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述（FP 相关句已按现行 RTL 修正）。

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
- `rst` clears all output state (the module has no `flush_i` port). During
  normal cycles, valid metadata is a one-cycle pulse; PC/inst/next-PC payload
  registers retain their last value when invalid, matching the old parent block.
- Out of scope: changing ROB commit arbitration, CSR/trap commit order, pending
  owner lifetime, FPR storage, or architectural register-file policy.

## Stage 2a - Protocol Rules

- The module is a fixed-latency synchronous state owner with no ready/valid
  backpressure.
- `pending_jump_nolink_commit_i` emits a one-cycle control commit for a resolved
  no-link JAL/JALR when the parent has already accepted the commit boundary.
- `drain_complete_i` allows one drained pending owner to become a pseudo commit:
  MRET/SRET, non-trapping system control, or undispatched branch fallback. The
  former FP GPR writeback/observation arm has been physically removed (FP now
  commits through the ROB). ECALL, IRQ, architectural trap, pending jump, and
  pending memory do not emit a pseudo commit here.
- Jump no-link commit has priority over drain commit if both are asserted by a
  malformed caller; this follows the old parent `if/else` control order.

## Stage 2b - State Machine

| State | Encoding | Meaning | Exit |
| --- | --- | --- | --- |
| `IDLE` | `valid=0, serial_flush=0` | No pseudo commit is visible this cycle. | Jump no-link or eligible drained owner enters `PULSE_COMMIT`. |
| `PULSE_COMMIT` | `valid=1` | One pseudo commit is visible on commit0 for exactly one cycle. | Next cycle returns to `IDLE` unless a new event arrives. |

（历史 `PULSE_FLUSH` 状态属于已删除的 FP GPR 臂；`serial_flush_q` 寄存器保留但无置位路径。）

## Stage 2c - Invariants

- `ctrl_commit_valid_o` is a pulse: without a new event it clears in the next
  cycle. A stuck valid would duplicate retirement.
- `core_serial_flush_o` is constant 0 in the current RTL: its only setter (the
  FP GPR commit arm) has been removed; the output port is retained for wiring.
- ECALL, IRQ, pending architectural trap, misaligned pending branch, pending
  jump, and pending memory never produce `ctrl_commit_valid_o`; their
  architectural side effects remain owned by trap/CSR or redirect logic.
- When `ctrl_commit_valid_o` is high, commit1 must be suppressed by the parent
  mux. This module only supplies the commit0 payload; it never drives commit1.
- `ctrl_commit_write_o`/`ctrl_commit_rd_en_o`/`ctrl_commit_rd_data_o` are
  constant 0 in the current RTL: pseudo commits never write registers (the FP
  GPR arm that set them has been removed).
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
- （历史 Drained FP payload mux 已随 FP GPR 臂物理删除。）
- All muxes are registered at the clock edge. The module adds no new
  combinational path from CSR/trap/pending events into ROB commit outputs.
