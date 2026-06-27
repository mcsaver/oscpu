# Evidence Index

## Regression Runs

- Local light gate: `npc/rv64/perf/results/core-regress-local-gates-after-fp/20260626-175213-349221/`
- Official RV64G subset: `npc/rv64/perf/results/core-regress-rv64g-official-fixed/20260626-175055-331711/`
- Official expanded subset after FP fix: `npc/rv64/perf/results/core-regress-official-expanded-after-fp/20260626-175641-354868/`
- Privileged smoke: `npc/rv64/perf/results/core-regress-privileged-after-fp/20260626-175154-345944/`
- AMO/LRSC focused official suite: `npc/rv64/perf/results/core-regress-rv64ua-fixed/20260626-172324-312613/`
- Single precision FP official suite: `npc/rv64/perf/results/core-regress-rv64uf-fixed/20260626-174530-325064/`
- Double precision FP official suite: `npc/rv64/perf/results/core-regress-rv64ud-fixed/20260626-175031-329931/`

## Key Commands

```sh
make -C npc/rv64/testbench TESTS="tb_csr_file tb_ooo_alu_fetch_core tb_ooo_int_backend" RESULT_DIR=../perf/results/20260626-fp-fflags/module-testbench run
make -C npc/rv64 lint
make -C npc/rv64 -j2
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ua --log-base npc/rv64/perf/results/core-regress-rv64ua-fixed
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64uf --log-base npc/rv64/perf/results/core-regress-rv64uf-fixed
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ud --log-base npc/rv64/perf/results/core-regress-rv64ud-fixed
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64ua,rv64uf,rv64ud --log-base npc/rv64/perf/results/core-regress-rv64g-official-fixed
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64ua,rv64uf,rv64ud,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs --log-base npc/rv64/perf/results/core-regress-official-expanded-after-fp
./scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64mi,rv64si --log-base npc/rv64/perf/results/core-regress-privileged-after-fp
./scripts/npc-rv64-core-regress.sh --no-riscv-tests --log-base npc/rv64/perf/results/core-regress-local-gates-after-fp
```

## Expected Summary

- RV64G official subset: 109 attempted, all PASS.
- Expanded official subset: 153 attempted, all PASS.
- Privileged smoke: 24 attempted, all PASS.
- Local light gate: module-testbench, verilator-lint, npc-build, am-cpu-tests all PASS.

## Non-Coverage

- No full Linux/rootfs run in this slice.
- No riscv-arch-test full matrix.
- No formal signoff.
- No PPA/timing/CDC/reset or physical implementation signoff.
