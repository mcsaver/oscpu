# 2026-05-24 NPC SoC MROM/SRAM DiffTest

## 背景

NPC SoC 后端已经从 MROM `0x20000000` 复位，并新增 SRAM `0x0f000000..0x0f001fff`。若 NEMU reference 不建模并同步这两段，DiffTest 会在 MROM 取指/SRAM 数据访问阶段失去逐条比较意义。

## 变更

- NPC difftest 初始化新增 MROM/SRAM region 枚举，使用既有 `difftest_memcpy(..., DIFFTEST_TO_REF)` 同步整段 MROM 与 SRAM，不新增 DiffTest API。
- MROM/SRAM 同步增加门控：`npc/soc` 只有在 `CONFIG_NPC_SOC_DIFFTEST=y` 且 NEMU reference so 的 `soc_sim_in_range()` 确认 MROM/SRAM 属于 SoC 地址空间时才走该路径。
- NEMU `CONFIG_SOC_SIM` 区分可比较存储与 MMIO 副作用：MROM/SRAM/SDRAM 不再 `skip_ref`，UART/占位外设/Flash 仍 skip。
- NEMU reference so 导出 `soc_sim_in_range()`，使 NPC 能在运行时区分 SoC NEMU ref 与普通 NEMU ref。
- 新增 `npc/soc/configs/difftest_defconfig`，保持默认配置精简，同时提供可复现的 SoC difftest 配置。
- `riscv32-ysyxsoc` AM 镜像改为 `.text/.rodata` 在 MROM，`.data/.bss/heap/stack` 在 SRAM；新增 ysyxSoC `_start` 复制 `.data` 并清零 `.bss`。
- NEMU `riscv32-soc_defconfig` 关闭 trace，避免 reference so 在 NPC difftest 中逐条打印 ITRACE。

## 验证

- `make -C npc/sim BACKEND=soc backend-difftest_defconfig`
- `make -C npc/sim BACKEND=soc -j4`
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu riscv32-soc_defconfig`
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C npc/sim BACKEND=soc difftest-ref -j4`
- `rg "CONFIG_NPC_SOC_DIFFTEST" npc/soc/include/generated/autoconf.h`
- `rg "CONFIG_SOC_SIM" nemu/include/generated/autoconf.h`
- `nm -D nemu/build/riscv32-nemu-interpreter-so | rg "soc_sim_in_range"`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc run NPC_RUN_ARGS="--diff=default --no-progress -m 0"`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=dummy run NPC_RUN_ARGS="--diff=default --no-progress -m 0"`
- `riscv64-linux-gnu-readelf -S -l am-kernels/tests/cpu-tests/build/select-sort-riscv32-ysyxsoc.elf`
- `git diff --check`

结果：`riscv32-ysyxsoc` cpu-tests 39/39 PASS。日志保存在 `cpu-tests-ysyxsoc-diff.log`；其中每项启动可见 `sync mrom`、`sync sram` 和 `Difftest: ON`。恢复 SoC reference 后 `ALL=dummy` 单项 PASS，日志保存在 `dummy-after-soc-restore.log`。
