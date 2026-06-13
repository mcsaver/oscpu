# Dispatch Log

## 基本信息

- 日期：2026-05-24
- 任务：B2 ysyxSoCFull cache/外设闭环与旧 DCache bug 复查
- 执行者：Codex

### [2026-05-24] `recall` - `completed`

- 读取 AGENTS、Copilot、project-status、known-issues、NPC/AM/ysyxSoC/am-kernels 模块记忆和相关 instructions。
- 明确本轮约束：中文回复、先定位 root cause、跨模块更新 memory 与 task-run。

### [2026-05-24] `implement` - `completed`

- 补 ysyxSoCFull image loading、MROM/Flash DPI backing、commit/exit DPI 和 `soc-run`。
- 修 AM/`npc/soc`/ysyxSoC UART DLAB/APB enable-phase、AM UART 初始化、`npc/soc` LSU/MMIO byte address、`npc/soc` ICache MROM cacheable/RVC offset。
- 扩展 `mem-test` 到 cacheable PSRAM，并补 Full SoC 仿真用 APB PSRAM backing store。
- 按 single/soc 环境隔离要求恢复 `npc/single`，确保 SoC 地址图、MROM cacheable、UART DLAB 和 32B cache line 改动只留在 `npc/soc`。

### [2026-05-24] `verify` - `completed`

- `soc-lint`、`soc`、Full SoC smoke、char-test、mem-test 均通过。
- 普通 NPC SoC `mem-test` 显示 DCache `access=12, hit=9, miss=3, writeback=16`，确认 32B line 下仍覆盖 cache 命中与脏行回写。
- `git diff --name-only -- npc/single` 无输出；`make -C npc/single lint` PASS；single 模块级 testbench 使用临时 build 目录 26/26 PASS，确认 single 未被 SoC 专用改动波及。
- `git diff --check` 通过。

### [2026-05-24] `handoff` - `completed`

- 更新 project-status、NPC/ysyxSoC/AM/am-kernels 模块记忆与本 task-run。
- 确认 `hasChipLink=false`、`sdramUseAXI=false`，未发现 ChipLink 进程。

### [2026-05-24] `reverify` - `completed`

- 重新执行 `make -C npc/soc soc-lint` PASS。
- 从 Windows/WSL 非交互入口执行 `make -C npc/soc soc -B` 时先因 PATH 缺少 `mill` 失败；显式加入 `/home/lyg/.local/bin` 后 PASS。
- 重新执行 ysyxSoCFull 内建 smoke、`char-test-riscv32-ysyxsoc.bin` 和 `mem-test-riscv32-ysyxsoc.bin`，均 GOOD TRAP。
- 重新执行普通 SoC 后端 `ARCH=riscv32-ysyxsoc ALL=char-test/mem-test`，均 PASS；`mem-test` DCache 统计为 `access=12, hit=9, miss=3, writeback=16`。
- 复查 `npc/single`：`git diff --name-only -- npc/single` 无输出，`make -C npc/single lint` PASS，模块 testbench 26/26 PASS。
- `git diff --check` PASS；`Top.scala` 仍为 `hasChipLink=false`、`sdramUseAXI=false`，未发现 ChipLink/ysyxSoCFull 残留进程。

### [2026-05-24] `set-assoc-design` - `completed`

- 新需求：用户要求在 `npc/single` 继续开发核心，将 cache 做成组相联结构，验证成功后应用到 `npc/soc`。
- 设计收敛：I/D cache 均采用 2-way set-associative；`npc/single` 为 64B line、32 sets、2 ways，总容量各 4KB；`npc/soc` 为 32B line、64 sets、2 ways，总容量各 4KB，并保留 SoC ICache MROM cacheable。
- RTL 不变量：命中逐 way 比较 valid/tag；miss victim invalid-first，否则按每 set 1-bit pseudo-LRU；refill 前清 victim valid，整行填完后置 valid/tag；DCache dirty victim 先完整 writeback，flush/fence.i 扫描全部 set/way/word。

### [2026-05-24] `set-assoc-implement` - `completed`

- 修改 `npc/single` 的 `define.v`、`ICache.v`、`DCache.v`，把 direct-mapped metadata/data SRAM 扩展为 packed ways，并补 hit/victim/flush 的 way 选择。
- 更新 `npc/single` I/D cache testbench，增加同 index 不同 tag 两路共存、LRU dirty eviction、flush 多 way 脏行覆盖。
- 在 `npc/single` 验证通过后，同步应用到 `npc/soc`；SoC ICache 继续保留 MROM cacheable 条件，SoC line 参数仍为 32B。

### [2026-05-24] `set-assoc-verify` - `completed`

- `npc/single` cache 专项 testbench PASS，lint PASS，模块 testbench 26/26 PASS，pipe_test PASS，Verilator build PASS。
- `riscv32-npc mem-test` 在 `NPC_SIM_BACKEND=single --no-diff` 下 PASS，统计为 ICache `access=521, hit=510, miss=11`、DCache `access=76, hit=72, miss=4`。
- `npc/soc` lint、soc-lint、`make -C npc/soc -j4`、`make -C npc/soc soc` PASS；SoC I/D cache 专项 testbench PASS。
- `riscv32-ysyxsoc mem-test` PASS，统计为 ICache `access=550, hit=528, miss=22`、DCache `access=12, hit=10, miss=2`；`riscv32-ysyxsoc char-test` PASS，串口输出正常。
- `npc/soc/testbench run` 全量仍被既有 `tb_uart` 状态/tx 期望值阻塞，已记录为非 cache 残留；`git diff --check` PASS。
