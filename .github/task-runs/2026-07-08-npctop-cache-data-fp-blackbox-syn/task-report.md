# Task Report: NpcTop Cache/Data/FP Blackbox Synthesis Probe

Date: 2026-07-08

## Goal

Probe whether `NpcTop` can progress further through Yosys synthesis when the already-known large cache/FP boundaries are treated as macros:

- `OooFetchPacketCache`
- `OooDataWordCache`
- `OooFpArithGate`

This run intentionally did not boot Ubuntu/rootfs. It is part of correctness/synthesis preparation before OS bring-up.

## Result

Status: partial progress, no final netlist.

The run passed the previous `OooDataWordCache` expansion point and reached real standard-cell ABC. It terminated at `119.26`, when Yosys began real-library ABC extraction for `OooBranchDirectionPredictor`.

No `NpcTop.netlist.v` was produced.

## Evidence

Primary log:

- `evidence/NpcTop-cache-data-fp-blackbox-full.log`

Key markers:

- `evidence/key-markers.md`

Representative facts:

- Lines 615-617 show all three blackbox boundaries were applied.
- Line 183314 and line 3970117 show Yosys `check` reported 0 problems at the recorded check points.
- Line 3673948 shows generic ABC handled `OooBranchDirectionPredictor` at `140384 gates / 167328 wires`.
- Lines 4544032-4548006 show real-library ABC progressed through `OooFpPhysRegFile`, `OooIntIssueQueue`, `OooPhysRegFile`, `OooArchRegFile`, and `OooIntBackend`.
- Line 4548662 shows termination occurred when entering real-library ABC for `OooBranchDirectionPredictor`.
- Lines 4548663-4548664 show `make` termination before `NpcTop.netlist.v`.

## Verification

- `git diff --check` PASS, recorded in `evidence/git-diff-check.log`.
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug npctop-cache-data-fp-blackbox-syn --stop-on-fail` PASS, supplemental run `.github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn-2/`.
- `scripts/agent-e2e.sh --profile npc-dev --task-slug npctop-cache-data-fp-blackbox-syn --stop-on-fail` PASS, supplemental run `.github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn-3/`.
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS.

## Engineering Reading

The data cache blackbox is effective as a synthesis boundary: the flow no longer dies at `OooDataWordCache`.

The next synthesis bottleneck is not a cache expansion problem. It is now real-library ABC/runtime pressure, with `OooBranchDirectionPredictor` as the current terminal point for this run. Several state-heavy non-cache modules also showed material mapping cost: physical/architectural register files, issue queue, ROB, and backend integration.

`STA_SYNTH_PUBLIC_AUTONAME=0` did not prevent large rename/autoname-style log growth in this flow. The flow also spent significant time in post-ABC cleanup and name propagation. A follow-up should separate fast machine-oriented netlist generation from human-readable naming.

## Correctness Boundary

This is only a synthesis-boundary result. It does not prove cache/FP/predictor behavior.

For any later macro replacement or timing rewrite, `npc/rv64/vsrc/debug/` and `npc/rv64/vsrc/common/` should be treated as part of the semantic audit surface:

- `common/` carries shared ISA/spec facts, encodings, architectural constants, and interface conventions.
- `debug/` carries checker/observable hooks that can audit whether RTL behavior still matches spec-level intent.
- Timing or macro changes should add or reuse local invariants here before being trusted by larger random or OS-level tests.

## Next Step

Before trying Ubuntu/rootfs, run a faster synthesis follow-up:

1. Keep the three macro boundaries.
2. Add `OooBranchDirectionPredictor` as an exploratory blackbox, or split its tables into a memory macro while preserving update/predict semantics.
3. Disable or reduce public/autoname-style netlist naming for probe runs.
4. Pair any predictor/regfile/issue-queue macro split with `debug/common` invariants and focused unit/random tests.
