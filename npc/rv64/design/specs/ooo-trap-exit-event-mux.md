# OooTrapExitEventMux Spec

## Owner

`OooTrapExitEventMux` owns the pure combinational selection of the terminal
trap/exit event presented to `OooTrapExitOutputSequencer`.

It does not own sticky output registers, pending trap/exit state, CSR trap
entry, PC redirect/recovery, ROB retirement, backend drain tracking, or
simulation exit-code selection.

## Inputs

The parent supplies already-decoded facts from branch-spec recovery, pending
branch/jump resolve, drain qualification, pending owner state, and pending
trap/exit payloads.

The mux treats `drain_complete_i` as a candidate. A drain terminal event is
valid only when the old parent `else if` drain branch would have been reached:
no committed CSR trap, no direct frontend flush, `stop_pending_i` is set, and
earlier branch/jump/memory/system resolve cases are not taking priority.

## Priority

Trap payload priority preserves the old sequential assignment order:

1. pending branch commit misaligned target,
2. tracked branch match misaligned target,
3. untracked branch resolve misaligned target,
4. pending jump misaligned target,
5. drain-reached undispatched branch misaligned target,
6. drain-reached generic pending trap payload,
7. branch-spec restore misaligned target when no later event overrides it.

Branch match, untracked branch, and branch-spec trap payloads use the
`core_branch_resolve_*` payload. Pending branch commit and drain branch use the
pending branch payload. Pending jump uses the resolved jump payload. Generic
drain trap uses the pending trap payload and cause.

## Exit Event

`exit_o` is asserted only for a drain-reached pending exit when no architectural
trap, system, undispatched branch, pending jump, pending memory, or pending FP
owner takes priority. Exit payload bits are forwarded from the pending exit
state.

Trap and exit outputs are independent. This intentionally preserves the old
behavior where branch-spec trap assignment could coexist with a later drain
exit assignment in the same cycle.
