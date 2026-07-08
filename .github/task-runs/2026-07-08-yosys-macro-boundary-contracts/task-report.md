# Yosys macro boundary contracts report

## Objective

Move the four-blackbox `NpcTop` synthesis result from a one-off structural milestone into a maintained macro/OOC contract checklist before attempting STA or OS bring-up.

## Changes

- Added `npc/rv64/design/specs/yosys-macro-boundary-contracts.md`.
- Added `yosys-sta/scripts/check_macro_contracts.py`.
- Indexed the new spec from `npc/rv64/design/specs/README.md`.
- Extended `.github/e2e/modules/yosys-sta.md` so the Yosys-STA contract names the macro-boundary checker.

## Contract coverage

The new spec table covers the four explicit `NpcTop` blackbox boundaries:

- `OooFetchPacketCache`
- `OooDataWordCache`
- `OooFpArithGate`
- `OooBranchDirectionPredictor`

Each row records the RTL owner, current netlist instance, boundary kind, timing/area status, semantic audit status, next task, and evidence. All four rows intentionally keep timing/area open because the current top netlist still reports unknown area for these cells.

## Evidence

- `evidence/check-macro-contracts.log`: checker PASS for spec rows, RTL module declarations, and netlist instances.
- `evidence/py-compile.log`: checker Python syntax/import smoke PASS.
- `evidence/git-status-scope.log`: scoped changed files for this task.
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug yosys-macro-boundary-contracts --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-yosys-macro-boundary-contracts-2`.
- `scripts/agent-e2e.sh --profile agent-system --task-slug yosys-macro-boundary-contracts --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-yosys-macro-boundary-contracts-3`.
- `scripts/agent-e2e.sh --profile npc-dev --task-slug yosys-macro-boundary-contracts --stop-on-fail`: PASS, run `.github/task-runs/2026-07-08-yosys-macro-boundary-contracts-4`.
- `scripts/agent-e2e.sh --guard --guard-mode strict`: PASS after the required `yosys-sta`, `agent-system`, and `npc-dev` evidence was present.
- `git diff --check`, `python3 scripts/github_index_db.py doctor --fail-on-drift`, and `python3 scripts/github_index_db.py audit-db-first`: PASS.

## Interpretation

This does not close STA. It creates a runnable guardrail so the next steps remain explicit:

- timing/area placeholder or real macro/OOC model per boundary;
- semantic audit through `debug/` and `common` facts/checkers or focused TB;
- only then a new `NpcTop` synthesis/STA attempt with macro assumptions listed.

## Boundary

No Ubuntu/rootfs boot was started. No production RTL behavior was changed.
