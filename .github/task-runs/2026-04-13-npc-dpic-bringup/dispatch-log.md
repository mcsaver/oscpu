# Dispatch Log

## 基本信息

- `task_id`: `2026-04-13-npc-dpic-bringup`
- `task_slug`: `npc-dpic-bringup`
- `graph_template`: `am-device-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-04-13 02:00] `survey-npc-interface` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `用户要求给已完成的 RV32I core 加一层 DPI 外部环境，并能加载 AM 编译出来的镜像运行`
- `depends_on`: `study-first recall`
- `inputs`: `NpcCore.v`、study 笔记、npc/single/Makefile、csrc/main.cpp`
- `action`: `读取项目记忆、NPC 学习资料和当前核心接口，确认最小平台层的落点`
- `outputs`: `确定采用 core 外 DPI 平台层，沿 IFU/LSU 握手口接 pmem/mmio`
- `evidence`: `已确认 core 已有 IFU/LSU 请求-响应口和 exit/trap 观测口`
- `handoff_to`: `dpic-wrapper`
- `next_step`: `实现 NpcSimTop.sv 与 C++ harness`
- `notes`: `同时确认应优先对齐 NEMU/AM 现有地址约定，而不是另起一套平台 ABI`

### [2026-04-13 02:20] `dpic-wrapper` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `核心边界已明确`
- `depends_on`: `survey-npc-interface`
- `inputs`: `npc/single/vsrc/*.v`、`npc/single/csrc/main.cpp`、NEMU 地址图
- `action`: 新增 `NpcSimTop.sv`、重写 `csrc/main.cpp`、补齐 `npc/single/Makefile`
- `outputs`: 可构建的 Verilator + DPI 最小仿真平台
- `evidence`: `make -C npc/single lint && make` 通过
- `handoff_to`: `am-platform-align`
- `next_step`: `把 abstract-machine 的 npc 平台对齐到同一套退出和 MMIO 约定`
- `notes`: `总线被实现为一拍请求、一拍返回，避免组合路径重复调用宿主侧带副作用函数`

### [2026-04-13 02:40] `am-platform-align` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `仅有 NPC 仿真器还不够，需要让 AM 镜像可以直接面向这套平台生成并运行`
- `depends_on`: `dpic-wrapper`
- `inputs`: `abstract-machine/scripts/platform/npc.mk`、`am/src/riscv/npc/*.c`、`scripts/riscv32-nemu.mk`、NEMU 平台约定
- `action`: 新增 `riscv32-npc.mk`，并把 `putch/halt/timer/run` 等最小平台路径对齐到 NPC DPI 平台
- `outputs`: AM 侧可直接生成并运行 `riscv32-npc` 镜像
- `evidence`: `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/kernels/hello ARCH=riscv32-npc image` 通过
- `handoff_to`: `hello-smoke`
- `next_step`: `执行 hello 冒烟，确认串口输出和正常退出`
- `notes`: `中途修正了 platform/npc.mk 的 Makefile recipe 缩进错误`

### [2026-04-13 03:00] `hello-smoke` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `NPC 和 AM 两侧最小平台实现已落盘`
- `depends_on`: `am-platform-align`
- `inputs`: `hello-riscv32-npc.bin`、`npc/single/build/NpcSimTop`
- `action`: 直接运行镜像，并验证 AM 侧 `make run` 入口
- `outputs`: `最小闭环通过`
- `evidence`: `hello` 成功打印 `Hello, AbstractMachine!`，并以 `ebreak/code=0` 退出；AM 侧 `make ARCH=riscv32-npc run` 也通过
- `handoff_to`: `record-memory`
- `next_step`: `更新 task-run 与项目记忆`
- `notes`: 当前验证已经覆盖 pmem 取指、串口输出、return 0 -> halt -> ebreak 退出三条关键路径

### [2026-04-13 18:40] `nemu-architecture-survey` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `用户明确要求停止“一个 main.cpp 包打天下”的实现方式，转而参考 AM/NEMU 的架构做更完整的仿真器分层`
- `depends_on`: `hello-smoke`
- `inputs`: `nemu/src/monitor/monitor.c`、`nemu/src/cpu/cpu-exec.c`、`nemu/src/memory/paddr.c`、`nemu/src/device/*`、`abstract-machine/am/src/platform/nemu/ioe/input.c`、`abstract-machine/am/include/amdev.h`
- `action`: `回读 NEMU 的 monitor/cpu-exec/paddr/device/io-map 分层和 AM/NEMU 输入 ABI，重新梳理 NPC csrc 的职责边界`
- `outputs`: `确认 NPC 仿真器应按 monitor -> cpu-exec -> paddr -> device/map 分层，并继续复用 NEMU/AM 地址图与键盘 ABI`
- `evidence`: `已定位 NEMU 的 monitor、cpu-exec、paddr、device/map、serial/timer/keyboard 实现，以及 AM/NEMU 输入拆包逻辑`
- `handoff_to`: `simulator-refactor`
- `next_step`: `按新的分层边界拆分 npc/single/csrc`
- `notes`: `该节点的核心结论是：平台逻辑应继续放在 core 外层，但软件仿真器自身不能再维持为单文件结构`

### [2026-04-13 19:10] `simulator-refactor` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `NEMU 风格的职责边界已明确`
- `depends_on`: `nemu-architecture-survey`
- `inputs`: `npc/single/csrc/main.cpp`、NEMU 分层模型、当前 DPI 平台约束
- `action`: `把原先单体 main.cpp 拆分为 monitor、memory/paddr、device/map、device、cpu-exec、dpi、utils，并把 main.cpp 收缩为启动入口`
- `outputs`: `分层后的 NPC C++ 仿真器与瘦身后的 main.cpp`
- `evidence`: `make -C npc/single -j4` 通过；`main.cpp` 的静态错误面已清零
- `handoff_to`: `am-input-align`
- `next_step`: `把 AM 的 NPC 输入路径和运行参数桥接补齐到新仿真器结构上`
- `notes`: `这里保留了 “NpcSimTop.sv 做一拍请求/一拍返回，C++ 侧做平台与设备” 的大边界，只是把 C++ 宿主从单文件升级为多层实现`

### [2026-04-13 19:40] `am-input-align` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `仿真器已完成分层，但 AM 的 NPC 输入仍是空读 stub，运行脚本也无法透传更多仿真参数`
- `depends_on`: `simulator-refactor`
- `inputs`: `abstract-machine/am/src/riscv/npc/input.c`、`abstract-machine/scripts/platform/npc.mk`、`amdev.h`、NEMU/AM 键盘 ABI`
- `action`: `实现 NPC 平台的键盘事件拆包，并给 platform/npc.mk 增加 NPC_RUN_ARGS 透传；中途修复了 Makefile recipe 的 tab 缩进问题`
- `outputs`: `AM 侧可直接消费 NPC 键盘事件，且能从 make run 透传 trace/max-cycles/stdin-kbd`
- `evidence`: `hello` 在透传 trace 参数后继续通过；`input.c` 已按 KEYDOWN_MASK + keycode 读取 KBD_ADDR`
- `handoff_to`: `kbd-regression`
- `next_step`: `做端到端 keyboard 回归，确认事件链路真的打通`
- `notes`: `这一步的重点不是“再补一个 stub”，而是让 AM 的 NPC 平台和 NEMU 平台尽量对齐到同一套输入 ABI`

### [2026-04-13 20:20] `kbd-regression` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `NPC 输入链路与运行参数透传已落盘，需要实际证明 AM 程序能收到键盘事件`
- `depends_on`: `am-input-align`
- `inputs`: `am-kernels/tests/am-tests`、`mainargs=k`、`--stdin-kbd --max-cycles 200000`
- `action`: `用 scripted stdin 模式向 NPC 注入按键，并运行 AM 的 readkey test 观察 guest 侧输出`
- `outputs`: `键盘事件端到端验证通过`
- `evidence`: `printf 'a' | ...` 运行后，终端打印 `Try to press any key...`、`A DOWN`、`A UP`；随后因 keyboard_test 无限轮询而按预期 timeout`
- `handoff_to`: `record-memory`
- `next_step`: `清理静态错误面并更新 memory/task-run`
- `notes`: `这里的 timeout 不是功能失败，而是测试程序本身的设计；关键证据是 guest 已经实际收到事件`

### [2026-04-13 20:35] `record-memory` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `核心重构与回归验证均已完成，需要把稳定结论写回项目记忆`
- `depends_on`: `kbd-regression`
- `inputs`: `make -C npc/single -j4` 构建结果、静态诊断结果、hello/keyboard 回归证据、memory 协议
- `action`: `补齐 project-status、模块笔记、设计决策和 task-run 摘要，并顺手清掉入口文件的编辑器假红线`
- `outputs`: `稳定记忆与 task-run 已和代码现状对齐`
- `evidence`: `main.cpp` 当前无静态报错；`.github/memory/*` 与本 task 的 report/log 已更新
- `handoff_to`: `none`
- `next_step`: `等待下一轮在现有分层上继续补设备、CSR 或 difftest`
- `notes`: `至此，本任务已经从“最小能跑 hello”升级到“结构化、可继续扩展的 NPC 仿真器 bring-up 基线”`
