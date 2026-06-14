# OoO same-cycle redirect fetch

## Context

- Goal: reduce fixed front-end bubbles after known control-flow redirects in the experimental OoO ALU path.
- Baseline before this increment: AM `cpu-tests/add` on `NPC_OOO_ALU_EXPERIMENT=1` reached GOOD TRAP with `cycles=1379 commits=839 CPI=1.644`.

## Plan

1. Let direct JAL and RAS-return redirects issue the target fetch in the same cycle as the front-end flush when the previous outstanding request is absent or being dropped.
2. Let already-dispatched branch resolves issue the resolved target fetch in the same cycle as stop-pending cleanup under the same one-outstanding constraint.
3. Preserve correctness by clearing stale fetch FIFO contents while carrying the newly-fired redirect request as the next outstanding request.
4. Add focused fetch-core observability for same-cycle redirect requests and rerun module/experiment regressions.

## Result

- Implemented and kept.
- `OooAluFetchCore` can issue a new fetch request in the same cycle as a known redirect for direct JAL, RAS-return, and backend branch resolve, while still clearing stale FIFO contents.
- Redirect flush/resolve state now preserves the newly fired redirect request as the outstanding request, instead of clearing all outstanding state unconditionally.
- Focused tests now observe same-cycle direct and branch redirect fetches.

## Evidence

- Focused fetch-core: `/tmp/ysyx-ooo-same-cycle-redirect-tb/logs/tb_ooo_alu_fetch_core.log` -> `[RESULT] PASS`.
- Final focused fetch-core after reverting the later unsafe branch-prefetch experiment: `/tmp/ysyx-ooo-branch-prefetch-revert-tb/logs/tb_ooo_alu_fetch_core.log` -> `[RESULT] PASS`.
- Final full module regression: `/tmp/ysyx-ooo-same-cycle-final-module/summary.txt` -> `total: 38`, `passed: 38`, `failed: 0`.
- Final experimental AM `cpu-tests/add`: `/tmp/ysyx-ooo-same-cycle-final-add.log` -> GOOD TRAP, `cycles=1150`, `commits=839`, `CPI=1.371`.
- Default non-experimental AM `cpu-tests/add`: `/tmp/ysyx-default-after-same-cycle-add.log` -> GOOD TRAP, `cycles=1509`, `commits=838`, `CPI=1.801`.
