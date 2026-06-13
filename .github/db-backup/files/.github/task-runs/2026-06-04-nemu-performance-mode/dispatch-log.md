# 2026-06-04 NEMU performance mode dispatch log

## 目标

- 把 RV64 Linux 长跑中刷屏的 CSR/MMU/trap 诊断变成可关闭选项。
- 把结束时 BPU/cache/host 执行统计变成可关闭选项。
- 增加统一 `performance` 开关，让 Linux NEMU 默认关闭 trace 和调试统计，提高长跑速度并减少 console 噪声。

## 调用链

- 热路径统计：
  - `cpu-exec.c::exec_once()` 每条指令调用 `bpu_commit()`，由 `CONFIG_BPU` 控制。
  - `cpu-exec.c::statistic()` 结束时打印 host time、guest instruction、simulation frequency，并调用 cache/BPU 统计。
  - `cache.c` 在 I/D cache 访问、miss 和 writeback 时维护 counter。
- 调试日志：
  - `inst.c::csr_write()` 对 `stvec/satp` 写入做 budget Log。
  - `system/mmu.c::sv39_fail()` 对 page walk fail 做 budget Log。
  - `system/intr.c::isa_raise_intr_with_tval()` 对非 ECALL trap 做 budget Log。

## 修改记录

- `CONFIG_PERFORMANCE`
  - 一键关闭 trace、difftest、watchpoint、BPU、runtime check、ASAN、mem random 和 RISC-V debug logs。
- `CONFIG_STATISTIC`
  - 控制 `statistic()` 的所有输出。
  - 关闭时仍保留 cache flush。
- `CONFIG_RISCV_DEBUG_LOG`
  - 控制截图中的 `CSR write`、`Sv39 translate failed`、`RISC-V trap exception`。
- `CONFIG_CACHE_STATISTIC`
  - 控制 cache counter 维护和打印。
  - 不控制 cache 模型本身。
- `riscv64-linux_defconfig`
  - 打开 `CONFIG_PERFORMANCE=y`，作为 Ubuntu rootfs 长跑默认配置。

## 验证记录

- 性能配置构建：
  - `make -C nemu NEMU_HOME=$PWD/nemu riscv64-linux_defconfig`
  - `make -C nemu NEMU_HOME=$PWD/nemu -j4`
  - PASS。
- 调试配置构建：
  - 从 `riscv64-linux_defconfig` 临时删除 `CONFIG_PERFORMANCE` 到 `/tmp/riscv64-linux-debug_defconfig`。
  - `conf --defconfig=/tmp/riscv64-linux-debug_defconfig Kconfig && conf --syncconfig Kconfig`
  - `make -C nemu NEMU_HOME=$PWD/nemu -j4`
  - PASS。
- 切回性能配置：
  - `make -C nemu NEMU_HOME=$PWD/nemu riscv64-linux_defconfig && make -C nemu NEMU_HOME=$PWD/nemu -j4`
  - PASS。
- Linux 入口 smoke：
  - `make -C Linux ARCH=riscv64-nemu MAX_CYCLES=1000000 LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-performance-smoke-final run`
  - PASS，按预算停在 `STOP after requested budget`。
- 噪声检查：
  - `rg` 检查 `console.log` 中无 `CSR write`、`Sv39 translate failed`、`RISC-V trap exception`、`bpu branch`、`bpu target`、`host time spent`、`total guest instructions`、`simulation frequency`。

## 额外发现

- 直接尝试 `riscv64-npc_defconfig` 时，构建失败在既有 `riscv64/inst.c` unused-variable：A/F/D 关闭后 `lr_reservation_*` 与 `exec_rvf_load()` 局部变量未使用。该配置问题不由本轮引入，且不影响 `riscv64-linux_defconfig` 的性能/调试模式。
