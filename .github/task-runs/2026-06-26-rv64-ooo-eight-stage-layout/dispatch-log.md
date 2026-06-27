# Dispatch Log

- task: refactor RV64 OoO RTL framework by the requested 8 core categories.
- mode: merge OoO implementation into outer `vsrc` directories plus local
  RAS, return-continuation buffer, and branch-target capture buffer
  extractions.
- root RTL: `npc/rv64/vsrc`.
- key filelist: `npc/rv64/vsrc/filelist.mk`.
- focused result dir:
  `npc/rv64/perf/results/20260626-vsrc-merged-layout/module-testbench/`.
- return-cont focused result dir:
  `npc/rv64/perf/results/20260626-return-cont-buffer/module-testbench/`.
- branch-target capture focused result dir:
  `npc/rv64/perf/results/20260626-branch-target-capture-buffer/module-testbench/`.
- default full module testbench status: PASS, 52/52 after RV64 legacy
  cache/core test rebaseline; known issue [100] closed.

## Evidence

- path scan: `npc/rv64/vsrc/ooo` no longer exists and active
  `npc/rv64/vsrc`/`npc/rv64/testbench` has no `vsrc/ooo` or `RTL_OOO_DIR`
  reference after migration.
- stale local RAS state scan: no `ras_count_q`, `ras_stack_q`,
  `ras_push_idx_w`, `ras_top_idx_w`, `RAS_COUNT`, `RAS_DEPTH`, or
  `ras_reset_idx` left in `OooAluFetchCore`.
- stale local return-continuation assignment scan: no direct
  `return_cont_* <=` assignments left in `OooAluFetchCore`.
- stale local branch-target capture assignment scan: no direct
  `branch_target_capture_* <=` assignments left in `OooAluFetchCore`.
- focused tests: 6/6 PASS.
- return-cont focused tests: `tb_ooo_alu_fetch_core` PASS and
  `tb_ooo_int_backend` PASS.
- branch-target capture focused tests: `tb_ooo_alu_fetch_core` PASS and
  `tb_ooo_int_backend` PASS.
- branch-target capture helper standalone test:
  `tb_ooo_branch_target_capture_buffer` PASS.
- stale RV64 XLEN module baselines fixed: `tb_multiplier` PASS and
  `tb_divider` PASS.
- stale legacy cache/core baselines fixed: `tb_icache`, `tb_dcache`,
  `tb_npc_core_smoke`, `tb_npc_core_mcycle`, and `tb_npc_core_interrupt` PASS.
- default aggregate module regression: 52/52 PASS.
- full lint: PASS.
- forced full Verilator build: PASS.
- control-flow smokes: `smoke-jal-link`, `smoke-branch-raw`, and
  `smoke-ras-trap-boundary` GOOD TRAP.
