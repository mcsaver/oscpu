# Dispatch Log

## 基本信息

- `task_id`: `2026-05-23-am-ysyxsoc-platform`
- `task_slug`: `am-ysyxsoc-platform`
- `graph_template`: `am-device-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-23 19:22] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求在 AM 中新增 ysyxSoC 平台
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、ysyxSoC CPU spec、AM/NPC/NEMU/ysyxSoC 源码
- `action`: 梳理现有 `riscv32-npc`、`platform/npc.mk`、ysyxSoC 地址图和 NEMU SOC_SIM 模型
- `outputs`: 确认新平台应使用 UART `0x1000_0000`、PSRAM `0x8000_0000`、CLINT-like `mtime`，GPU/input 默认关闭
- `evidence`: 源码与 memory 读取结果
- `handoff_to`: implement
- `next_step`: 新增平台脚本和 IOE/TRM 实现
- `notes`: 不修改 ysyxSoC 生成物和 NPC RTL

### [2026-05-23 19:22] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: recall 完成
- `depends_on`: recall
- `inputs`: AM 平台脚本、RISC-V NPC 平台实现、ysyxSoC 地址图
- `action`: 新增 `riscv32-ysyxsoc.mk`、`platform/ysyxsoc.mk` 和 `am/src/riscv/ysyxsoc/` 平台文件
- `outputs`: ysyxSoC AM 平台可构建，run 入口默认进入 `npc/sim BACKEND=soc`
- `evidence`: `add-riscv32-ysyxsoc` 首次裸跑 GOOD TRAP
- `handoff_to`: verify
- `next_step`: 构建 reference 并跑 difftest/full 回归
- `notes`: unsupported disk config 保留 `present=false`，但 `blksz=512` 避免上层 devscan 0 除法

### [2026-05-23 19:22] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: implement 完成
- `depends_on`: implement
- `inputs`: 新 AM 平台、NPC SoC 后端、NEMU SoC reference
- `action`: 运行 smoke、difftest reference、全量 cpu-tests 和 am-tests image 构建
- `outputs`: 验证通过
- `evidence`: `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C npc/sim BACKEND=soc difftest-ref` PASS；`ARCH=riscv32-ysyxsoc` cpu-tests 38/38 PASS；`make -C am-kernels/tests/am-tests ARCH=riscv32-ysyxsoc image` PASS；`git diff --check -- abstract-machine` PASS
- `handoff_to`: record
- `next_step`: 更新 memory 与任务记录
- `notes`: 首次不带 `NEMU_HOME` 的 difftest-ref 失败是环境变量空值覆盖默认路径，显式路径后通过

### [2026-05-23 19:22] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: verify 完成
- `depends_on`: verify
- `inputs`: 验证结果、改动清单
- `action`: 更新 project-status、abstract-machine/am-kernels/ysyx-soc 模块记忆与本 task-run
- `outputs`: 记录完成
- `evidence`: `.github/memory/*` 与 `.github/task-runs/2026-05-23-am-ysyxsoc-platform/`
- `handoff_to`: none
- `next_step`: 交付用户
- `notes`: 无

### [2026-05-23 19:43] `verify` - `evidence_supplement`

- `owner_agent`: Codex
- `trigger`: 用户要求新增 `char-test` 测试 UART 模块
- `depends_on`: completed platform
- `inputs`: `am-kernels/tests/cpu-tests`、`riscv32-ysyxsoc` AM 平台、NPC SoC 后端、NEMU SoC reference
- `action`: 新增 `am-kernels/tests/cpu-tests/tests/char-test.c`，覆盖 `putch()` 输出路径和 ysyxSoC `AM_UART_CONFIG/AM_UART_TX/AM_UART_RX` 路径
- `outputs`: UART 字符输出 smoke 并入 cpu-tests 自动发现列表
- `evidence`: `ALL=char-test ARCH=riscv32-ysyxsoc` 在 `--no-diff` 与 `--diff=default` 下 PASS，终端显示 `putch path` 和 `AM_UART_TX path` 两行；`ARCH=riscv32-ysyxsoc` 全量 cpu-tests 39/39 PASS；`ALL=char-test ARCH=riscv32-npc` PASS
- `handoff_to`: record
- `next_step`: 更新 memory
- `notes`: `char-test` 只覆盖串口路径，因此不调用完整 `ioe_init()`

### [2026-05-23 21:26] `implement` - `scope_update`

- `owner_agent`: Codex
- `trigger`: 用户要求完成 ysyxSoC TRM 截图中的 MROM/SRAM 运行环境
- `depends_on`: completed platform
- `inputs`: AM ysyxSoC 平台、NPC SoC 地址图、ysyxSoC MROM/SRAM 规格
- `action`: 新增 `linker-ysyxsoc.ld`，把 AM `_start` 链接到 MROM `0x20000000`，栈/堆放到 SRAM；NPC SoC reset PC 改为 MROM，并把 MROM/SRAM slave 接入 DPI 内存模型
- `outputs`: AM 镜像从 MROM 取第一条 TRM 指令，SRAM 承载 stack/heap，MROM store 在仿真侧报错
- `evidence`: ELF entry `0x20000000`，`_start` 首条 `li s0,0`，`_stack_pointer/_heap_start=0x0f001000`
- `handoff_to`: verify
- `next_step`: 运行 `char-test`
- `notes`: ysyxSoC IOE LUT/timer 去除了运行期全局写

### [2026-05-23 21:26] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: implement scope_update 完成
- `depends_on`: implement
- `inputs`: MROM/SRAM 版 AM 镜像与 NPC SoC 后端
- `action`: 运行 `char-test` 并检查 ELF header、section、symbol 和反汇编
- `outputs`: 验证通过
- `evidence`: `make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=char-test run YSYXSOC_RUN_ARGS="--no-diff --no-progress -m 0"` PASS；日志显示 MROM/SRAM backing store 与 `HIT GOOD TRAP at pc = 0x2000009e`
- `handoff_to`: record
- `next_step`: 更新 memory
- `notes`: 本轮未复跑全量 cpu-tests 或 diff-on 回归
