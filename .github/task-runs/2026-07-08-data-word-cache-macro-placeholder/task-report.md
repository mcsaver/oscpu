# OooDataWordCache macro placeholder report

## Objective

Advance the D-cache macro/OOC work from “semantic checker exists” to an explicit timing/area placeholder contract, without claiming real STA or starting OS bring-up.

## Changes

- Extended `npc/rv64/design/specs/ooo-data-word-cache.md` with `Macro/OOC Contract v0`.
- Updated `npc/rv64/design/specs/yosys-macro-boundary-contracts.md` so the `OooDataWordCache` row records placeholder v0 instead of generic open wording.
- Added `yosys-sta/scripts/check_dcache_macro_contract.py`.
- Extended `.github/e2e/modules/yosys-sta.md` with the D-cache placeholder checker requirement.

## Placeholder Facts

- `req` and `walk` read latency remain `0 cycle`.
- fill/store write visibility is `next cycle`.
- same-cycle fill/store priority is `fill then store`.
- reset only clears valid state.
- default bridge instance capacity is `4096` entries:
  `262144` data bits + `200704` tag bits + `4096` valid bits = `466944` state bits.

## Evidence

- `evidence/check-dcache-macro-contract.log`: new D-cache placeholder checker PASS.
- `evidence/check-macro-contracts.log`: four-blackbox macro-boundary checker PASS.
- `evidence/tb-ooo-data-word-cache.log`: focused D-cache TB remains PASS.
- `evidence/py-compile.log`: checker Python compile smoke PASS.
- `evidence/git-status-scope.log`: scoped paths touched by this slice.
- `scripts/agent-e2e.sh --profile npc-dev --task-slug data-word-cache-macro-placeholder --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-data-word-cache-macro-placeholder-2`.
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug data-word-cache-macro-placeholder --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-data-word-cache-macro-placeholder-3`.
- `scripts/agent-e2e.sh --profile agent-system --task-slug data-word-cache-macro-placeholder --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-data-word-cache-macro-placeholder-4`.
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS.
- `git diff --check`, `python3 scripts/github_index_db.py doctor --fail-on-drift`, and `python3 scripts/github_index_db.py audit-db-first`: PASS.

## Interpretation

This closes the “define D-cache timing/area placeholder or OOC/SRAM contract” task at the documentation/checker level. It does not provide real Liberty/LEF, OOC timing, power, or signoff area. The next D-cache-specific task is to either add a real macro model or produce an OOC timing report and connect it to the top-level STA assumptions.

## Boundary

No production RTL behavior was changed in this slice. No Ubuntu/rootfs boot was started.
