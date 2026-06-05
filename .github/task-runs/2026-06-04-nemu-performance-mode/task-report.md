# 2026-06-04 NEMU performance mode task report

## 结论

NEMU 已新增统一性能模式：`CONFIG_PERFORMANCE=y` 会从配置层关闭 trace、difftest、watchpoint、透明 BPU 统计模型、运行时检查、ASAN、随机内存初始化，以及 RV64 Linux bring-up 的 CSR/MMU/trap 诊断日志。`riscv64-linux_defconfig` 默认打开该模式，因此 `make -C Linux ARCH=riscv64-nemu run` 使用的是安静的 Linux 长跑配置。

## 修改点

- `nemu/Kconfig`
  - 新增 `CONFIG_PERFORMANCE`。
  - 新增 `CONFIG_STATISTIC`，控制结束时 host time、guest instruction、simulation frequency 与下游统计打印。
  - 新增 `CONFIG_RISCV_DEBUG_LOG`，控制 CSR write、Sv39 page fault 和 trap exception 诊断日志。
  - `TRACE/DIFFTEST/WATCHPOINT/RT_CHECK/CC_ASAN` 等调试开关依赖 `!PERFORMANCE`。
- `nemu/src/cpu/Kconfig`
  - `CONFIG_BPU` 依赖 `!PERFORMANCE`，性能模式下不再维护透明分支预测统计模型。
- `nemu/src/memory/Kconfig`
  - 新增 `CONFIG_CACHE_STATISTIC`，控制 cache counter 维护和打印。
  - `CONFIG_MEM_RANDOM` 依赖 `!PERFORMANCE`。
- `nemu/src/cpu/cpu-exec.c`
  - `CONFIG_STATISTIC=n` 时不打印统计；若 cache 模型开启，仍执行必要 `cache_flush_all()`。
- `nemu/src/memory/cache.c`
  - cache access/hit/miss/writeback counter 改由 `CONFIG_CACHE_STATISTIC` 控制。
  - 关闭统计时不打印 cache counter，但 DCache flush 语义保持。
- `nemu/src/isa/{riscv32,riscv64}`
  - CSR write、Sv39 fail 和 trap exception 诊断挂到 `CONFIG_RISCV_DEBUG_LOG`。
- `nemu/configs/riscv64-linux_defconfig`
  - 默认 `CONFIG_PERFORMANCE=y`。

## 验证

- `make -C nemu NEMU_HOME=$PWD/nemu riscv64-linux_defconfig && make -C nemu NEMU_HOME=$PWD/nemu -j4` PASS。
- 去掉 `CONFIG_PERFORMANCE` 的临时 `/tmp/riscv64-linux-debug_defconfig` 构建 PASS，说明调试模式下新增的日志宏也能编译。
- `make -C Linux ARCH=riscv64-nemu MAX_CYCLES=1000000 LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-performance-smoke-final run` PASS。
- 关键词检查无命中：`CSR write`、`Sv39 translate failed`、`RISC-V trap exception`、`bpu branch`、`bpu target`、`host time spent`、`total guest instructions`、`simulation frequency`。
- `git diff --check` PASS。

## 边界

- 性能模式仍保留启动阶段的基本加载说明，例如镜像路径、MMIO map 和 block image；这些不是每条指令热路径 trace，也不是 debug counter。
- `riscv64-npc_defconfig` 临时构建仍会因既有 RV64 A/F/D 关闭时 `inst.c` unused-variable 问题失败；该问题早于本轮开关，不影响 `riscv64-linux_defconfig` 性能/调试两套模式。
