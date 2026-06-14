# ysyxSoC 模块笔记

## 当前状态

- 2026-05-24: `npc/soc` 中接入 ysyxSoCFull 的 CPU cache 已同步为 2-way set-associative：I/D cache 均为 32B line、64 sets、2 ways，总容量各 4KB，匹配当前 B2/ChipLink 侧 32B block 约束；ICache 仍允许 MROM `0x20000000..0x20000fff` 走 cacheable fill，DCache 仍只覆盖普通 cacheable 内存，不把 UART/MMIO 纳入 cache。验证：`make -C npc/soc soc-lint`、`make -C npc/soc soc`、`make -C npc/soc -j4`、`make -C npc/soc/testbench ... tb_icache/tb_dcache`、`ARCH=riscv32-ysyxsoc ALL=mem-test/char-test` 均 PASS。`npc/soc/testbench run` 全量仍被既有 UART testbench 期望阻塞，和 ysyxSoCFull 程序路径无关。
- 2026-05-24: 复验 B2 交付状态时确认 ChipLink 仍关闭，`ysyxSoC/src/Top.scala` 为 `hasChipLink=false`、`sdramUseAXI=false`，`pgrep` 未发现 ChipLink 或 ysyxSoCFull 残留进程。注意从 Windows/WSL 非交互入口强制重建 ysyxSoC 时，需显式把 `/home/lyg/.local/bin` 加入 PATH，否则会因找不到 mill wrapper 失败；补 PATH 后 `make -C npc/soc soc -B` PASS。
- 2026-05-24: B2 的 ysyxSoCFull Verilator 闭环已完成，ChipLink 配置保持关闭：`ysyxSoC/src/Top.scala` 中 `hasChipLink=false`、`sdramUseAXI=false`，交付前也确认没有宿主 ChipLink 进程。Full SoC 现在可通过 `make -C npc/soc soc-run IMG=... RUN_ARGS=...` 从 MROM 跑 AM 镜像，`mrom_read/flash_read` 有真实 image backing store，CPU commit/ebreak/ecall 可由 DPI 输出 GOOD/BAD TRAP。验证：内建 smoke 在 PC `0x20000004` GOOD TRAP，char-test 串口文本完整输出，mem-test 在 PC `0x200002c6` GOOD TRAP。
- 2026-05-24: ysyxSoCFull 的外设仿真补齐了本轮 B2 所需最小行为。UART APB 侧按 16550 DLAB 和 enable phase 处理寄存器读写，避免初始化 divisor latch 被输出为字符；PSRAM APB wrapper 在 `ifndef SYNTHESIS` 下提供 Verilator behavioral RAM，支持 `pstrb` byte lane 写和 32-bit little-endian 读，保证 NPC DCache dirty writeback/refill 能在 Full SoC 仿真中被观察到。原综合/FPGA 使用的 EF_PSRAM QSPI controller 仍在 `else` 分支。
- 2026-05-24: 当前 AM/NPC/NEMU 闭环已按 ysyxSoC MROM/SRAM 约束跑通 difftest。程序入口和取指仍在 MROM `0x20000000`，但可写 `.data/.bss/heap/stack` 均位于 SRAM `0x0f000000..0x0f001fff`；AM `_start` 负责把 MROM 中的 `.data` load image 复制到 SRAM。NPC 在 difftest 初始化时同步整段 MROM/SRAM 到 NEMU reference，NEMU 只对 MMIO 外设 skip-ref，不跳过 MROM/SRAM。验证：`riscv32-ysyxsoc` cpu-tests 39/39 difftest PASS；`readelf` 抽查 `.data` VMA=`0x0f000000`、LMA=`0x20000160`。
- 2026-05-23: AM/NPC SoC 普通后端已对齐 ysyxSoC “MROM 复位 + SRAM 栈/堆”运行约束。AM 镜像入口为 MROM `0x20000000`，NPC SoC reset PC 同步为 `0x20000000`；MROM 仅承载取指/只读数据，CPU store 会报错，栈/堆符号在 SRAM `0x0f000000..0x0f001fff`。这与 `ysyxSoC/src/SoC.scala` 的 MROM 4KB、SRAM 8KB 地址图一致；当前 `ysyxSoCFull` Verilator smoke 的 `mrom_read()` 只返回最小 `li a0,0; ebreak`，后续若要直接运行完整 AM 镜像，还需要把 MROM DPI 加载真实镜像并补退出观测。
- 2026-05-23: AM 已新增 `riscv32-ysyxsoc` 平台作为 ysyxSoC 地址图的 guest 入口。该平台不修改 `ysyxSoC/src/` 或 `ysyxSoCFull.v`，而是在 `abstract-machine/am/src/riscv/ysyxsoc/` 中按当前 SoC 窗口使用 UART `0x1000_0000`、CLINT-like timer `0x0200_0000`、PSRAM `0x8000_0000`，并默认通过 `npc/sim BACKEND=soc` 运行。由于当前 `ysyxSoC/perip/vga/ps2/gpio` 仍为空壳，AM 平台默认将 GPU/input 标为不可用；后续补真实 VGA/PS2 后，需要同步打开 `YSYXSOC_HAS_GPU/YSYXSOC_HAS_INPUT` 或替换对应平台实现。验证：`riscv32-ysyxsoc` cpu-tests 38/38 SoC difftest PASS。
- 2026-05-23: `ysyxSoC/` 已作为独立 SoC 集成目录进入工作区。当前 CPU 接口规范位于 `ysyxSoC/spec/cpu-interface.md`，要求 CPU 顶层模块名为 `ysyx_8位学号`，端口包含 `clock/reset/io_interrupt`、一路完整 AXI4 master 和一路 AXI4 slave。`ysyxSoC/Makefile` 通过 `mill -i ysyxsoc.runMain ysyx.Elaborate --target-dir build` 生成 `build/ysyxSoCFull.v`，随后做端口名替换和尾部清理。
- 2026-05-23: 已按用户要求移除 `ysyxSoC/` 及其 `rocket-chip` 依赖目录下的 `.git` 元数据，备份位置为 `/tmp/ysyxSoC-git-metadata-backup-2026-05-23/`。`ysyxSoC/` 不再被外层 `.gitignore` 排除，后续可作为普通目录由外层仓库纳入；若执行 `git add .`，仍需注意 `ysyxSoC/.gitignore`、`ysyxSoC/rocket-chip/.gitignore` 会继续排除生成物和上游忽略项。
- 2026-05-23: 当前宿主环境已经配置用户级 Zulu JDK 21 与 `/home/lyg/.local/bin/mill` wrapper；`ysyxSoC/.mill-version` 固定为 Mill 0.12.4。后续 ysyxSoC 任务应优先使用 `mill -i` 或 `make verilog`，避免系统 OpenJDK 8 导致 `readAllBytes()` 等 API 缺失。
- 2026-05-23: `npc/soc` 当前承接 ysyxSoC CPU 集成侧：`ysyx_26010035` wrapper 与 `NpcSoCAxiBridge` 对齐 `cpu-interface.md`，`make -C npc/soc soc` 会纳入 `ysyxSoC/build/ysyxSoCFull.v` 与 perip 源。SoC 地址图还需要同时与 NEMU `CONFIG_SOC_SIM` reference 保持一致，尤其是 SRAM、UART、MROM、VGA、Flash、SDRAM 等窗口。

## 设计笔记

- `ysyxSoC/build/ysyxSoCFull.v` 是生成物，不应优先手写维护；若需要改 SoC 结构，优先改 `ysyxSoC/src/*.scala` 后重新生成。
- CPU RTL 的具体实现与 AXI4 bridge 在 `npc/soc`，SoC agent 主要负责规范、生成链路、外设/地址图与 Chisel 侧连接关系。
- 地址图变更至少要同步检查三侧：ysyxSoC Chisel/生成物、`npc/soc` 仿真顶层/CPU bridge、NEMU `CONFIG_SOC_SIM` reference。

## 踩坑记录

- 系统 `/usr/bin/java` 仍可能是 OpenJDK 8；直接调用不经过 wrapper 的 Mill/Chisel 命令可能失败。先检查 `which mill`、`mill -i --version` 和 `JAVA_HOME`，再归因到工程源码。
