# Dispatch Log

## 2026-05-23

### `study-context`

- 读取 AGENTS、Copilot instructions、project/module memory、NPC study notes，确认本轮属于跨模块 difftest/reference 任务。
- 梳理 NPC SoC 地址图：CLINT、SRAM、UART、SPI、GPIO、PS2、MROM、VGA、Flash、PSRAM/PMEM、SDRAM 与 legacy MMIO 的当前关系。

### `nemu-soc-model`

- 在 NEMU RISC-V Kconfig 新增 `CONFIG_SOC_SIM`，默认关闭，依赖 RV32 system 模式。
- 新增 `memory/soc.{h,c}`，用 paddr 层模型覆盖 ysyxSoC 最小功能窗口；UART 支持 THR 写字符和 LSR ready，Flash 暂按 sparse 空镜像处理。
- 修改 `paddr.c`，在 PMEM 与 RISC-V CLINT 特例后接入 SoC 模型，并对 SoC MMIO 访问触发 difftest skip。
- 修改 `difftest_memcpy()`，允许 reference loader 同步 SoC SRAM/MROM/VGA/SDRAM 等非主 PMEM 窗口。

### `capstone-crash-fix`

- 首次跑 `NPC_SIM_BACKEND=soc --diff=default` 时，`npc/soc` 已打开 difftest 后出现 Segmentation fault。
- 用 `gdb -batch -ex run -ex bt` 定位到 NEMU shared object 中 `disassemble()` 空函数指针调用；根因是 Capstone 使用相对路径 `tools/capstone/...`，从 NPC cwd 启动时找不到库。
- 修改 `disasm.c`：优先用 `NEMU_HOME` 定位 Capstone，失败时退化为 `.word` 原始编码输出。
- 单个 `dummy-riscv32-npc.bin --diff=default --no-progress -m 0` 复验 GOOD TRAP。

### `verify`

- `make -C npc/sim BACKEND=soc difftest-ref` PASS，`riscv32-nemu-interpreter-so` 已重新链接 SoC 模型和 disasm 修复。
- NEMU SoC UART smoke：自定义镜像写 `0x1000_0000`，输出 `S` 并 `HIT GOOD TRAP`。
- `riscv32-nemu` cpu-tests 用 `NEMUFLAGS=-b` 跑 38/38 PASS。
- `riscv32-npc` cpu-tests 用 `NPC_SIM_BACKEND=soc NPC_RUN_ARGS="--diff=default --no-progress -m 0"` 跑 38/38 PASS。
- `git diff --check` PASS。

### `record`

- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/nemu.md`、`difftest.md`、`npc.md`。
- 新增本 task-run 的 `task-report.md` 与 `dispatch-log.md`。
