# NPC RV64 Core Regression With Official riscv-tests

## Goal

完善 `npc/rv64` 核本身的轻量验证闭环，不跑 Linux/rootfs 重门；接入较完整的官方 core-level 测试集，并修复测试暴露的 RTL/仿真模型缺口。

## Changes

- Added `scripts/npc-rv64-core-regress.sh` and `make -C npc/rv64 core-regress`.
- Added NPC runtime `--tohost=ADDR` watcher for official `riscv-tests`.
- Pulled official `riscv-tests` into ignored runtime artifacts:
  `.github/runtime-artifacts/npc-rv64-core-tests/src/riscv-tests/`.
- Fixed Zbb word variants: `clzw/ctzw/cpopw/rolw/roriw/rorw`.
- Changed RV64 ordinary load/store path to byte-addressed 64-bit windows:
  exact effective address, lane0 `wdata/wstrb`, no normal misaligned trap.
- Kept AMO/LR/SC misaligned exceptions.
- Relaxed DPI data PMEM read/write alignment to support exact byte addresses.
- Fixed D-cache store-hit + invalidate-all behavior so same exact-address entries stay valid after store commit.
- Updated LSU, MemoryStage, OoO backend, and mem AXI bridge module tests to the new data-side contract.

## Validation

- `make -C npc/rv64 -j2`: PASS.
- `scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui`: PASS.
- `make -C npc/rv64/testbench run`: PASS, 52/52.
- `make -C npc/rv64 core-regress`: PASS.

Final evidence:

- Core regression run dir: `npc/rv64/perf/results/core-regress/20260626-160919/`.
- `status.txt`: module testbench PASS, Verilator lint PASS, NPC build PASS, AM cpu-tests PASS, official `riscv-tests-count INFO 111 tests attempted`.
- Official suites covered by default: `rv64ui rv64um rv64uc rv64uzba rv64uzbb rv64uzbc rv64uzbs`.

## Boundary

This is a core-level signoff baseline for the current RTL and simulator. It does not claim full Linux/rootfs boot completion, full industrial CPU sign-off, formal proof, riscv-arch-test closure, privilege torture coverage, or physical implementation sign-off.
