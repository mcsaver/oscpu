# Task Report: OooFpArithGate Launch/Out TB

## Objective

Close the immediate correctness gap in `OooFpArithGate` by adding focused coverage for the B-FP
`launch_valid_i -> out_valid_o` self-pipeline interface before continuing Ubuntu/rootfs work.

## Implementer Summary

- Kept the legacy `start_i/done_o` arithmetic examples in `tb_ooo_fp_arith_gate`.
- Connected the B-FP launch/out metadata ports in the focused TB.
- Added a three-cycle back-to-back launch sequence for addsub, mul, and fma.
- Checked stage5 consecutive `out_valid_o` results for ROB index, physical destination, value, and fflags.
- Added a younger-than-kill case where in-flight metadata must be cleared so no killed result asserts `out_valid_o`.
- Updated `ooo-fp-arith-gate.md` so the launch/out basic coverage gap is closed and the remaining gaps are explicit.

## Debug/Common Method Rule

`npc/rv64/vsrc/debug` and `npc/rv64/vsrc/common` are also a semantic audit layer for the RTL/spec contract,
not just helper/debug directories. For future cross-module semantic changes, especially redirect, facts,
kill/ROB age, AD-update, or similar invariant-bearing logic, check or extend common facts and debug checkers
before claiming a timing or synthesis optimization preserves semantics.

Current audit entry points include `common/OooSlotFacts.v`, `common/OooRedirectMuxFacts.vh`,
`common/OooRedirectSeqFacts.vh`, `debug/OooRedirectMuxChecker.sv`, `debug/OooRedirectSeqChecker.sv`,
`debug/OooRedirectMergeChecker.sv`, and `debug/OooAdUpdateChecker.sv`.

This task is a single-module FP arithmetic TB slice, so the direct audit vehicle is the focused TB plus the
current `OooFpArithGate` spec. The debug/common rule is recorded here to keep the next synthesis iterations honest.

## Verification

- PASS: `make -C npc/rv64/testbench run TESTS=tb_ooo_fp_arith_gate RESULT_DIR=../perf/results/20260708-fp-arith-launch-out/module-testbench`
- PASS: `make -C npc/rv64 lint`
- PASS: `make -C npc/rv64 check-rtl-style`
- PASS: `make -C npc/rv64 check-contract`
- PASS: `git diff --check`
- PASS: `scripts/agent-e2e.sh --profile npc-dev --task-slug fp-arith-launch-out-tb --stop-on-fail`
- PASS: `scripts/agent-e2e.sh --guard --guard-mode strict`

## Reviewer Notes

- This does not close full B-FP validation. Remaining correctness gaps are flush clear-chain coverage, illegal
  `launch_kind_i`, and randomized mixed single/double precision back-to-back streams.
- This does not prove `OooFpArithGate` full stdcell synthesis is closed. The known Yosys blocker remains full
  stdcell mapping/gate extraction cost, so the next synthesis loop should split addsub/mul/fma or FMA subpaths.
- No Ubuntu/rootfs boot was started in this task.
