# OooTrapExitOutputSequencer Spec

## Owner

`OooTrapExitOutputSequencer` owns the final user-visible sticky
`trap_valid_o`, trap payload, `exit_valid_o`, exit payload, and `halted_o`
state for the control plane (`control/OooControlPlane`, historically
`OooAluFetchCore`).

It does not own pending architectural trap/exit capture, CSR trap entry, PC
redirect/recovery, ROB retirement, backend drain qualification, or simulation
exit-code selection.

## State

- `trap_valid_o`: a terminal trap has been reported.
- `trap_cause_o`, `trap_pc_o`, `trap_tval_o`: terminal trap payload.
- `exit_valid_o`: a simulation exit has been reported.
- `exit_is_ecall_o`, `exit_is_ebreak_o`: simulation exit classification.
- `halted_o`: terminal state has been reached through either trap or exit.

All state is cleared by reset. Outside reset the outputs are sticky until
another terminal event overwrites the corresponding payload.

## Inputs And Priority

On a non-reset clock edge:

1. `trap_i` sets `halted_o`, asserts `trap_valid_o`, and captures the trap
   payload.
2. `exit_i` sets `halted_o`, asserts `exit_valid_o`, and captures the exit
   payload.

Trap and exit captures are independent. If the parent asserts both in the same
cycle, both valid bits are set deterministically. Normal parent policy should
still present one final architectural outcome at a precise boundary.

## Parent Event Contract

`OooControlPlane`(经 `OooTrapExitEventMux`)remains responsible for forming
the terminal event inputs. The event mux must preserve the old sequential
assignment priority(注:其中依赖 pending branch/jump 的臂在当前配置下输入恒
0,已证死,见 `ooo-trap-exit-event-mux.md` 状态注记):

1. pending branch commit misaligned target,
2. tracked branch match misaligned target,
3. untracked branch resolve misaligned target,
4. pending jump misaligned target,
5. drain-reached undispatched branch misaligned target,
6. drain-reached generic pending trap payload,
7. branch-spec restore misaligned target if no later event overrides it.

The drain-reached events are only valid when the old `OooAluFetchCore` drain
`else if` branch would have been reached after earlier branch/jump/memory/system
resolve cases. This keeps final trap/exit timing identical while moving only
the sticky output registers into `control/`.
