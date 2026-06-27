# NPC RV64 Privileged Core Regression

## Goal

在不直接跑 Linux/rootfs 重门的前提下，继续完善 `npc/rv64` 核本身：把官方 `riscv-tests` 从默认用户态/扩展小测推进到 `rv64mi/rv64si` privileged smoke，并修复暴露出的 RTL/CSR/Sv39 缺口。

## Changes

- Extended `scripts/npc-rv64-core-regress.sh` with `--riscv-privileged`, `--riscv-filter REGEX`, and PID-suffixed run directories.
- Added minimal privileged CSR model coverage: debug trigger no-op CSRs, `pmpcfg0/pmpaddr0`, `misa` WARL no-op writes, and writable `mstatus.TVM/TW/TSR`.
- Fixed FP/System illegal arbitration in `OooAluFetchCore`: recognized FP instructions no longer get trapped by the integer decoder illegal bit while FS is enabled; FS-off FP still traps.
- Fixed buffered data memory drain in `OooIntBackend` to preserve exact effective addresses.
- Added Sv39 leaf PTE A/D checks in data and fetch bridges.
- Added focused regressions for `fmv.w.x`, Sv39 A=0 load/fetch page fault, and D=0 store page fault.

## Validation

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-sv39-ad-fault/module-testbench run`: PASS, 53/53.
- `make -C npc/rv64 lint`: PASS.
- `make -C npc/rv64 -j2`: PASS.
- `scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64mi`: PASS, 17/17.
- `scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64si`: PASS, 7/7.
- `scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-privileged`: PASS, 135 tests attempted.
- `scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --no-riscv-tests`: PASS, AM cpu-tests.

## Boundary

This is a core-level RTL/simulator regression milestone. It does not claim Linux/rootfs completion, exhaustive riscv-arch-test closure, formal verification, physical signoff, or full industrial CPU sign-off.
