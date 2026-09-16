# OooTrapExitEventMux Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**:pending_branch/pending_jump/pending_mem 三个 owner 已被形式化证死(capture 被 `OOO_ROB_WALK_MODE=1` 门死/lane1 barrier 与 FACT_MEM 结构互斥,输入恒 0),下文优先级 1/2/4/5/7 臂为活文件中的死通道(第 7 臂 branch_spec 链同因 pending_branch 恒 0:`branch_spec_resolve_valid` 要求 `pending_branch_i`);实际活路径仅剩 drain 兜底 trap payload(第 6 臂)、exit,及依赖 issue-resolve misaligned 的 untracked 残臂(第 3 臂);拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

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
drain trap uses the pending trap payload and cause, and fires only when the
pending trap pc is nonzero (mode=1 guard: speculative lane1 residual with
pc==0 must not raise a spurious drain trap).

## Exit Event

`exit_o` is asserted only for a drain-reached pending exit when no architectural
trap, system, undispatched branch, pending jump, or pending memory owner takes
priority (the former pending-FP owner has been removed with the FP domain-A
migration). Exit payload bits are forwarded from the pending exit state.

Trap and exit outputs are independent. This intentionally preserves the old
behavior where branch-spec trap assignment could coexist with a later drain
exit assignment in the same cycle.
