# Task Report

## 基本信息

- `task_id`: `2026-04-13-npc-dpic-bringup`
- `task_slug`: `npc-dpic-bringup`
- `graph_template`: `am-device-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `GitHub Copilot`
- `started_at`: `2026-04-13`
- `updated_at`: `2026-04-13`

## 任务目标

- `source_request`: `在 core 顶层加一层 DPIC 来模拟真实 PC/物理总线，先实现 pmem 和程序正常退出等最小外部环境，并能把 AM 编译出来的二进制装进 NPC 的 pmem 运行；随后用户要求按 AM/NEMU 的架构思路，把 csrc 从单个 main.cpp 重构成更完整、可维护的分层仿真器。`
- `goal`: `为 npc/single 增加最小可运行的 Verilator + DPI 平台层，并继续重构成参考 NEMU 的 monitor/memory/device/cpu-exec 分层仿真器；同时把 abstract-machine 的 NPC 平台对齐到同一套 pmem/mmio/输入/退出约定。`
- `scope`: `NpcSimTop.sv`、`npc/single/csrc` 分层重构、npc/single/Makefile、AM 的 riscv32-npc 脚本、NPC 平台 trm/timer/input、AM->NPC run 入口、keyboard/trace 回归、memory/task-run 记录。`

## 选图说明

- `selected_template`: `am-device-loop`
- `why_this_graph`: `本轮任务本质上是在 AM 程序、平台 MMIO 约定和 NPC 目标仿真器之间补一条最小闭环，最接近 am-device-loop。`
- `dynamic_nodes_added`: `survey-npc-interface`, `dpic-wrapper`, `am-platform-align`, `hello-smoke`, `nemu-architecture-survey`, `simulator-refactor`, `am-input-align`, `kbd-regression`, `record-memory`
- `why_dynamic_nodes_were_needed`: `当前工作区既没有现成的 NPC DPI 平台实现，也没有用户可接受的 NEMU 风格分层仿真器；在最小闭环跑通后，还必须补一轮“参考 NEMU 重新整理 csrc 职责边界 + 接通 AM 输入 ABI + 回归验证”的扩图。`

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `survey-npc-interface` | `GitHub Copilot` | `completed` | `NpcCore.v`、study 笔记、现有 Makefile/csrc | 核心外部握手边界与最小平台约束 | 已确认 IFU/LSU 握手口、exit/trap 观测口可直接承载外层平台 |
| `dpic-wrapper` | `GitHub Copilot` | `completed` | `npc/single/vsrc`、`npc/single/csrc` | `NpcSimTop.sv`、C++ DPI harness、可构建 Makefile | `make -C npc/single lint && make` 通过 |
| `am-platform-align` | `GitHub Copilot` | `completed` | `abstract-machine/scripts/platform/npc.mk`、`am/src/riscv/npc/*.c`、NEMU 地址约定 | `riscv32-npc` 目标、串口/RTC/ebreak 对齐、AM run 入口 | `make -C am-kernels/kernels/hello ARCH=riscv32-npc image` 通过 |
| `hello-smoke` | `GitHub Copilot` | `completed` | `hello-riscv32-npc.bin`、`NpcSimTop` | 串口输出 + ebreak 退出闭环 | `hello` 在 NPC 上打印成功并以 code=0 退出 |
| `nemu-architecture-survey` | `GitHub Copilot` | `completed` | `nemu/src/monitor/monitor.c`、`nemu/src/cpu/cpu-exec.c`、`nemu/src/memory/paddr.c`、`nemu/src/device/*`、AM/NEMU 输入实现 | NPC 仿真器重构边界与输入 ABI 清单 | 已确认应沿 `monitor -> cpu-exec -> paddr -> device/map` 分层，并继续复用 NEMU/AM 地址与键盘 ABI |
| `simulator-refactor` | `GitHub Copilot` | `completed` | 现有 `npc/single/csrc/main.cpp`、NEMU 分层模型 | 拆分后的 `csrc/include`、`cpu/`、`device/`、`memory/`、`monitor/`、`dpi.cpp` 与瘦身后的 `main.cpp` | `make -C npc/single -j4` 通过，`main.cpp` 静态诊断清零 |
| `am-input-align` | `GitHub Copilot` | `completed` | `abstract-machine/am/src/riscv/npc/input.c`、`abstract-machine/scripts/platform/npc.mk`、`amdev.h` | NPC 键盘 ABI 接通、`NPC_RUN_ARGS` 透传 | `hello` 能继续运行，AM 侧可透传 `--trace/--trace-file/--max-cycles/--stdin-kbd` |
| `kbd-regression` | `GitHub Copilot` | `completed` | `am-kernels/tests/am-tests`、refactor 后 NPC | 键盘事件端到端验证 | `printf 'a' | ... mainargs=k NPC_RUN_ARGS='--stdin-kbd --max-cycles 200000'` 观察到 `A DOWN/UP` |
| `record-memory` | `GitHub Copilot` | `completed` | task 证据、memory 协议 | 稳定记忆与 task-run 收尾 | `.github/memory/*` 与当前 task-report / dispatch-log 已同步更新 |

## 关键产物

- `artifacts`: `npc/single/Makefile`、`npc/single/vsrc/NpcSimTop.sv`、`npc/single/csrc/main.cpp`、`npc/single/csrc/dpi.cpp`、`npc/single/csrc/utils.cpp`、`npc/single/csrc/cpu/cpu-exec.cpp`、`npc/single/csrc/device/device.cpp`、`npc/single/csrc/device/map.cpp`、`npc/single/csrc/memory/paddr.cpp`、`npc/single/csrc/monitor/monitor.cpp`、`npc/single/csrc/include/*`、`abstract-machine/scripts/platform/npc.mk`、`abstract-machine/scripts/riscv32-npc.mk`、`abstract-machine/am/src/riscv/npc/npc.h`、`abstract-machine/am/src/riscv/npc/trm.c`、`abstract-machine/am/src/riscv/npc/timer.c`、`abstract-machine/am/src/riscv/npc/input.c`
- `logs_or_traces`: `make -C npc/single lint && make` 通过；`make -C npc/single -j4` 在重构后继续通过；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/kernels/hello ARCH=riscv32-npc image` 通过；`./npc/single/build/NpcSimTop .../hello-riscv32-npc.bin --max-cycles 200000` 打印 `Hello, AbstractMachine!` 并以 `code=0` 退出；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/kernels/hello ARCH=riscv32-npc run NPC_RUN_ARGS='--max-cycles 500000 --trace-file build/hello-test.vcd --trace'` 通过；`printf 'a' | AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C /home/lyg/PA/ysyx-workbench/am-kernels/tests/am-tests ARCH=riscv32-npc run mainargs=k NPC_RUN_ARGS='--stdin-kbd --max-cycles 200000'` 打印 `A DOWN/UP`，随后因测试本身无限轮询而按预期 timeout。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/abstract-machine.md`、`.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: `无硬阻塞；当前分层平台已能跑 hello，并验证 AM 键盘事件链路。`
- `missing_dependencies`: `当前 MMIO 已覆盖 pmem、serial、rtc、keyboard，但尚未接 GPU、mtime/mtimecmp、CSR trap handler、更完整 UART 状态与更真实总线协议。`
- `risk_assessment`: `软件仿真器已经从单文件 harness 升级为分层结构，但底层平台仍是单拍 DPI 总线和最小设备集，适合 bring-up 与 AM 回归，不适合作为最终 SoC 互连模型；普通异常仍停在 core 内部的 trap/halt-only 语义。`

## 下一步建议

1. 在现有 `device/map` 分层上继续补 `mtime/mtimecmp`、更完整的 UART 状态和后续图形设备，让 `am-tests` 的设备项逐步可跑。
2. 给 `NpcCore` 接最小 CSR/trap handler，把普通异常从 halt-only 升级为真正的 `mtvec/mepc/mcause/mtval` 闭环。
3. 在 `cpu-exec` / `NpcSimTop` 之上增加 commit trace 或 difftest 钩子，为后续和 NEMU 做逐指令比对准备接口。

## 模板升级候选

- `repeated_dynamic_subgraph`: `survey-npc-interface -> dpic-wrapper -> am-platform-align -> hello-smoke`
- `should_promote_to_static_template`: `yes`
- `reason`: `后续 NPC bring-up、设备增量接入和 AM 平台迁移大概率会重复这条链路，可以沉淀成独立的 NPC harness/平台闭环模板。`

## 收尾结论

- `final_result`: NPC 现在不仅具备最小外部环境，还已经把软件仿真器升级成参考 NEMU 的分层结构：可把 AM 的 `riscv32-npc` 镜像装进 `pmem`，经 DPI 模拟串口/RTC/键盘等最小设备运行，并通过 `ebreak + a0` 正常退出；AM 键盘事件链路也已实际打通。
- `evidence_summary`: Verilator lint/build 通过；重构后 `make -C npc/single -j4` 继续通过；AM `hello` 镜像构建与运行通过；AM 侧 `NPC_RUN_ARGS` 能直接透传 trace/max-cycles 选项；`readkey test` 在 `riscv32-npc` 上已打印 `A DOWN/UP`，说明 `stdin -> NPC keyboard -> KBD MMIO -> AM input.c -> am-tests` 链路可用。
- `notes`: 当前闭环优先服务 RV32I bring-up 和 AM 程序加载，不追求完整 SoC；但 `main.cpp` 已不再承担平台逻辑，后续扩设备、trace 或 difftest 时应沿 `monitor/memory/device/cpu-exec/dpi` 分层继续演进。
