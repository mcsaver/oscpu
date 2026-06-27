# NPC RV64 RV64G FP/AMO Core Regression

## 背景

用户要求先完善 `npc/rv64` 核本身，不直接运行完整 Linux/rootfs 重门。本轮目标是继续使用轻量 core-level gate 与官方 `riscv-tests` 暴露真实 RTL 缺口，并把修复与证据沉淀下来。

## Root Cause 与修复

- `rv64ua-p-lrsc` 卡在 barrier：AMO word writeback 在 `OooIntBackend` 内使用 8B aligned address，和当前 LSU/AXI-DPI 的 exact byte address + lane0 `wstrb` 契约不一致。修复为 AMO write phase 使用 `mem_eff_addr_q`，并在 `tb_ooo_int_backend` 增加 8B 内非 0 word offset 的 `amoadd.w` 回归。
- `rv64uf` 多项失败：官方 FP 测试会用 `fsflags a1, x0` 检查 exception flags；此前 FP arithmetic flags 只停在局部逻辑，没有 OR 入 `fflags` CSR。`CsrFile` 新增 FP fflags commit port，`OooAluFetchCore` 在 pending FP stop/drain 精确提交时携带 fflags。
- `rv64uf-p-fcvt_w` 失败：RV64 下 `FCVT.W/WU.{S,D}` 写 GPR 的 32-bit 结果需要 sign-extend 到 XLEN；已修正单/双精度 to-int helper。
- `rv64ud-p-move` 失败：`FSGNJ.S` 在 FLEN=64 时需要对未 NaN-boxed 单精度源视为 canonical qNaN；已在 sign-injection helper 中补齐。
- `rv64ud` arithmetic fflags 失败：double add/sub/mul/div/sqrt 结果路径没有生成对应 exception flags；已补 double arithmetic fflags helper 并接入 pending FP commit。

## 修改范围

- `npc/rv64/vsrc/execute/OooIntBackend.v`
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`
- `npc/rv64/vsrc/core/CsrFile.v`
- `npc/rv64/vsrc/frontend/OooAluFetchCore.v`
- `npc/rv64/testbench/tests/tb_csr_file.sv`
- `npc/rv64/vsrc/legacy/NpcCore.v`

## 验证证据

- Focused module regression: `tb_csr_file/tb_ooo_alu_fetch_core/tb_ooo_int_backend` PASS.
- `make -C npc/rv64 lint` PASS.
- `make -C npc/rv64 -j2` PASS.
- Local light gate: `npc/rv64/perf/results/core-regress-local-gates-after-fp/20260626-175213-349221/`, module-testbench/lint/build/AM cpu-tests PASS.
- Official `rv64ua`: `npc/rv64/perf/results/core-regress-rv64ua-fixed/20260626-172324-312613/`, 19/19 PASS.
- Official `rv64uf`: `npc/rv64/perf/results/core-regress-rv64uf-fixed/20260626-174530-325064/`, 11/11 PASS.
- Official `rv64ud`: `npc/rv64/perf/results/core-regress-rv64ud-fixed/20260626-175031-329931/`, 12/12 PASS.
- Official RV64G subset: `npc/rv64/perf/results/core-regress-rv64g-official-fixed/20260626-175055-331711/`, `rv64ui/rv64um/rv64ua/rv64uf/rv64ud`, 109 tests attempted, all PASS.
- Official expanded subset after FP fix: `npc/rv64/perf/results/core-regress-official-expanded-after-fp/20260626-175641-354868/`, `rv64ui/rv64um/rv64ua/rv64uf/rv64ud/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs`, 153 tests attempted, all PASS.
- Privileged smoke after FP changes: `npc/rv64/perf/results/core-regress-privileged-after-fp/20260626-175154-345944/`, `rv64mi/rv64si`, 24 tests attempted, all PASS.

## 边界

本轮没有运行完整 Linux/rootfs。该结果是 core RTL 轻量签核切片，不代表完整工业级 CPU signoff；仍缺 riscv-arch-test 全矩阵、随机/差分/形式验证、长稳、PPA/timing/CDC/reset、综合与物理实现签核。
