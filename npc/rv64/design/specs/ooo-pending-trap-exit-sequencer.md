# OooPendingTrapExitSequencer Spec

## Owner

`OooPendingTrapExitSequencer` owns the serialized architectural trap and
simulation-exit pending state used by `OooControlPlane` (successor of the
legacy `OooAluFetchCore` monolith) while the backend drains to a precise
boundary.

It does not own final trap/exit/halt outputs, CSR trap entry, PC redirect, ROB
retirement, or backend drain qualification.

## State

- `pending_exit_o`: a serialized simulation exit is waiting for the drain point.
- `pending_exit_is_ecall_o`, `pending_exit_is_ebreak_o`: exit payload bits.
- `pending_arch_trap_o`: a serialized architectural trap is waiting for the
  drain point.
- `pending_trap_cause_o`, `pending_trap_pc_o`, `pending_trap_tval_o`: trap
  payload captured from fetch/decode/lane1 barrier classification.

Exit and arch-trap valid bits are independent. If both are valid, the parent
control policy must prioritize architectural trap before simulation exit.

## Inputs And Priority

On reset all valid bits and payload are zero.

On a non-reset clock edge:

1. `clear_exit_i` clears exit valid and exit payload bits.
2. `clear_arch_i` clears arch-trap valid. Trap payload is not consumed when
   invalid and may retain its previous value. When the clear comes from a
   wrong-path squash (`clear_arch_squash_i`), the payload (cause/pc/tval) is
   cleared for every cause, so the drain-exit `drain_trap_payload` path cannot
   consume stale speculative residue.
3. `capture_exit_i` writes `pending_exit_o` from `capture_exit_valid_i` and
   writes the exit payload bits.
4. `capture_arch_i` writes `pending_arch_trap_o` from
   `capture_arch_valid_i` and writes trap payload, except when
   `clear_arch_i && clear_arch_squash_i` is asserted on the same edge.  That
   collision means the observed head belongs to the path being squashed, so
   squash owns both validity and payload and capture is discarded.
5. `late_clear_i` has final priority and clears all valid bits and payload.

Normal non-squash clear and a new capture in the same cycle still keep the new
capture, while a committed backend trap late-clear removes stale frontend
pending control state.  The explicit squash/capture exception was added after
R3.2 changed issue timing enough to expose a wrong-path `illegal` capture on
the same edge as JALR recovery; allowing capture to win revived an orphan trap
that later preempted a legal `SFENCE.VMA` drain.

## Integration Contract

The parent must derive capture inputs using the dispatch priority order:

1. interrupt drain boundary,
2. lane0 fetch fault,
3. lane0 decode architectural trap,
4. lane0 simulation exit,
5. lane0 illegal CSR/system trap or legal system boundary,
6. lane1 barrier trap/exit capture 或 scrub；非 trap/exit lane1 owner 也可用
   `capture_*_i=1`、`capture_*_valid_i=0` 清掉 stale valid bit，
7. unsupported instruction trap（mode=1 下该 dispatch-time 捕获与 lane1 的
   INST_ACCESS_FAULT capture 被门控关闭以防 wrong-path spurious trap，
   仅置 stop_pending，真实 trap 依赖 commit 路径）.

（2026-07-03 注：旧列表中的 lane0 FP serialized boundary 已随 FP 迁域 A
拆除；lane0 branch/jump serialized boundary 在 `OOO_ROB_WALK_MODE=1` 下
capture 恒 0，已形式化证死。）

The parent remains responsible for `stop_pending_q`, drain completion, CSR trap
muxing, the pending SYSTEM owner, and final user-visible
`trap_valid_o` / `exit_valid_o` / `halted_o`（branch/jump/memory pending owner
已证死、FP pending owner 已拆除，见 rtl-ground-truth §4）.
