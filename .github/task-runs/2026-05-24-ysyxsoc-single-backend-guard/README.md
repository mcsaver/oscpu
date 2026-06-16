# 2026-05-24 ysyxsoc Single Backend Guard

## 背景

用户将开发环境切回 `npc/sim` single 后端后，继续运行 `ARCH=riscv32-ysyxsoc ALL=char-test run`，但旧脚本在 `platform/ysyxsoc.mk` 中硬编码 `BACKEND=soc`，导致 single 环境仍进入 `npc/soc`，日志出现 MROM/SRAM 地址并触发 SoC difftest reference 加载。

## 变更

- `abstract-machine/scripts/riscv32-ysyxsoc.mk` 读取 `npc/sim/include/config/auto.conf` 和显式后端变量。
- single 后端时复用 `platform/npc.mk`，并用 `-U__PLATFORM_YSYXSOC -D__PLATFORM_NPC` 让测试按 legacy NPC 平台分支编译。
- 只有 `YSYXSOC_BACKEND=soc`、`NPC_SIM_BACKEND=soc` 或 `NPC_PLATFORM=soc` 时才 include `platform/ysyxsoc.mk` 并使用 MROM/SRAM 地址图。
- 本地生成配置恢复为 single 开发状态：`npc/sim` 为 single，`npc/soc` 为 default no-diff，`npc/single` 为 perf no-diff。

## 验证

- `make -C npc/sim switch BACKEND=single`
- `make -C npc/sim BACKEND=soc backend-default_defconfig`
- `make -C npc/sim BACKEND=single backend-perf_defconfig`
- `make -C npc/sim BACKEND=single -j4`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=char-test run`

结果：用户原命令 PASS。日志 `char-test-single.log` 显示进入 `npc/single`，物理内存为 `[0x80000000, 0x87ffffff]`，`Difftest: OFF`，GOOD TRAP at `0x8000004c`。
