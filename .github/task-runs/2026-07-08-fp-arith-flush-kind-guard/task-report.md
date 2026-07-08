# Task Report: OooFpArithGate Flush/Kind Guard

## Objective

Continue correctness verification before synthesis/OS work by closing the next small but important
`OooFpArithGate` B-FP self-pipeline gaps: flush clearing, deterministic mixed precision alignment,
and illegal launch kind defense.

## Implementer Summary

- Added a focused TB case where a launched FMA is flushed while in flight; later pipeline activity must not assert `out_valid_o`.
- Added a deterministic mixed precision back-to-back launch sequence: `FADD.S`, `FMUL.D`, `FMADD.S`.
- Added an `OOO_ASSERT` in `OooFpArithGate` that reports illegal `launch_kind_i=3` when `launch_valid_i` is asserted.
- Ratcheted `npc/rv64/eval/contract-assert-baseline.txt` from 11 to 12.
- Updated `ooo-fp-arith-gate.md`, project status, and NPC module memory so completed gaps are not left in active task lists.

## Verification

- PASS: `make -C npc/rv64/testbench run TESTS=tb_ooo_fp_arith_gate RESULT_DIR=../perf/results/20260708-fp-arith-flush-kind-guard/module-testbench`
- PASS: `make -C npc/rv64 lint`
- PASS: `make -C npc/rv64 check-rtl-style`
- PASS: `make -C npc/rv64 check-contract`
- PASS: `git diff --check`
- PASS: `scripts/agent-e2e.sh --profile npc-dev --task-slug fp-arith-flush-kind-guard --stop-on-fail`
- PASS: `scripts/agent-e2e.sh --guard --guard-mode strict`
- PASS: `make -C npc/rv64 syn STA_DESIGN=OooFpArithGate STA_CLK_FREQ_MHZ=100 STA_SYNTH_STOP_AFTER_COARSE=1 STA_RTL_FILES=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v`

## Reviewer Notes

- This is still deterministic coverage, not randomized FP pressure.
- The new assertion is simulation/contract only; it does not change synthesis behavior because `OOO_ASSERT` is not used in synthesis.
- This does not close `OooFpArithGate` full stdcell synthesis. The next synthesis step should still split addsub/mul/fma or FMA subpaths for OOC mapping.
- No Ubuntu/rootfs boot was started in this task.
