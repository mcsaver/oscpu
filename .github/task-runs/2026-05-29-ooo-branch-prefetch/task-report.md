# OoO branch stop prefetch

## Context

- Goal: reduce branch stop-pending bubbles after same-cycle redirect fetch.
- Baseline before this increment: AM `cpu-tests/add` on `NPC_OOO_ALU_EXPERIMENT=1` reached GOOD TRAP with `cycles=1150 commits=839 CPI=1.371`.
- VCD profile showed about 145 branch resolves and about 289 cycles in branch stop-pending, with the front end idle while waiting for branch operands/issue.

## Plan

1. Add a non-speculative branch prefetch mode: while a dispatched branch is pending, fetch a statically predicted path into the fetch FIFO but keep dispatch blocked.
2. Use a conservative static predictor: backward branches predict taken, forward branches predict not taken.
3. On branch resolve, keep the prefetched FIFO/outstanding request only when the predicted PC matches the resolved next PC; otherwise discard it and redirect to the resolved target.
4. Validate focused fetch-core branch tests, full module tests, and AM `add` CPI.

## Result

- Reverted; not kept in RTL.
- The idea reduced apparent branch bubbles but broke precise control-flow ownership. Without a real branch checkpoint/rollback mechanism, preserving prefetched younger-path state during unresolved branch stop-pending is unsafe.
- No `branch_prefetch`/prediction-state implementation remains in `OooAluFetchCore` or its focused testbench.

## Evidence

- Failed experiment: `/tmp/ysyx-ooo-branch-prefetch-add.log` printed GOOD TRAP but only `cycles=103`, `commits=69`, `CPI=1.493`; correct AM `add` should retire 839 instructions on the experimental path, so this was an early wrong-path exit.
- Failed partial fix: `/tmp/ysyx-ooo-branch-prefetch-fix-tb/logs/tb_ooo_alu_fetch_core.log` -> `[CHECK-FAIL] not-taken branch commits fallthrough got=0x00000009 expected=0x00000007`.
- Revert/final focused fetch-core: `/tmp/ysyx-ooo-branch-prefetch-revert-tb/logs/tb_ooo_alu_fetch_core.log` -> `[RESULT] PASS`.
- Revert/final module regression: `/tmp/ysyx-ooo-same-cycle-final-module/summary.txt` -> `total: 38`, `passed: 38`, `failed: 0`.
- Revert/final experimental AM `cpu-tests/add`: `/tmp/ysyx-ooo-same-cycle-final-add.log` -> GOOD TRAP, `cycles=1150`, `commits=839`, `CPI=1.371`.
