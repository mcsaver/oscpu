# Yosys-STA flow versioning report

## Objective

Close the reproducibility gap exposed by the four-blackbox `NpcTop` synthesis run: the successful fast-name Yosys flow depended on files under `/home/lyg/PA/ysyx-workbench/yosys-sta/`, but the top-level repository ignored that directory wholesale.

## Changes

- Narrowed the top-level `.gitignore` rule for `/yosys-sta/`.
- Kept generated/local payloads ignored through `/yosys-sta/*` and the existing nested ignores.
- Explicitly allowlisted reproducible flow files:
  - `yosys-sta/Makefile`
  - `yosys-sta/scripts/common.tcl`
  - `yosys-sta/scripts/default.sdc`
  - `yosys-sta/scripts/pdk/icsprout55.tcl`
  - `yosys-sta/scripts/pdk/nangate45.tcl`
  - `yosys-sta/scripts/sta.tcl`
  - `yosys-sta/scripts/yosys.tcl`
- Added `SYNTH_DFF_AUTONAME ?= 1` and `export SYNTH_DFF_AUTONAME` to `yosys-sta/Makefile`.

## Evidence

- `evidence/git-check-ignore-after.log`: `yosys-sta/Makefile` and tracked Tcl scripts are now matched by allowlist rules, while `yosys-sta/result/foo` remains ignored by the nested result ignore.
- `evidence/yosys-sta-make-dry-run.log`: dry-run still reaches the same `yosys-sta/scripts/yosys.tcl` synthesis entry.
- `evidence/synth-switch-chain.log`: `STA_SYNTH_DFF_AUTONAME` is wired from `npc/rv64/Makefile` to `SYNTH_DFF_AUTONAME`, exported by `yosys-sta/Makefile`, and consumed by `yosys-sta/scripts/yosys.tcl`.
- `evidence/git-status-scope.log`: the scoped worktree now exposes `yosys-sta/` as Git-visible untracked content instead of hiding it under the old broad ignore rule.

## Interpretation

This does not claim a new synthesis result. It makes the already-proven fast-name flow reproducible as a repository-level artifact, so future `NpcTop` macro-boundary synthesis does not rely on a silent local tool-directory mutation.

The next synthesis/timing step remains unchanged: build timing/area/OOC contracts for `OooFetchPacketCache`, `OooDataWordCache`, `OooFpArithGate`, and `OooBranchDirectionPredictor`, with `debug/` and `common/` facts/checkers used as the RTL/spec semantic audit layer.

## Boundary

No Ubuntu/rootfs boot was started. This task only changes Yosys flow versioning and Makefile export plumbing; it does not alter production RTL behavior.
