# OooPendingTrapExitSequencer Spec

## Owner

`OooPendingTrapExitSequencer` owns the serialized architectural trap and
simulation-exit pending state used by `OooAluFetchCore` while the backend drains
to a precise boundary.

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
   invalid and may retain its previous value.
3. `capture_exit_i` writes `pending_exit_o` from `capture_exit_valid_i` and
   writes the exit payload bits.
4. `capture_arch_i` writes `pending_arch_trap_o` from
   `capture_arch_valid_i` and writes trap payload.
5. `late_clear_i` has final priority and clears all valid bits and payload.

This priority preserves the old `OooAluFetchCore` behavior: normal clear and
new capture in the same cycle keep the capture, while a committed backend trap
late-clear removes stale frontend pending control state.

## Integration Contract

The parent must derive capture inputs using the dispatch priority order:

1. interrupt drain boundary,
2. lane0 fetch fault,
3. lane0 decode architectural trap,
4. lane0 simulation exit,
5. lane0 FP serialized boundary,
6. lane0 illegal CSR/system trap or legal system boundary,
7. lane0 branch/jump serialized boundary,
8. lane1 barrier,
9. unsupported instruction trap.

The parent remains responsible for `stop_pending_q`, drain completion, CSR trap
muxing, branch/jump/memory/FP pending owners, and final user-visible
`trap_valid_o` / `exit_valid_o` / `halted_o`.
