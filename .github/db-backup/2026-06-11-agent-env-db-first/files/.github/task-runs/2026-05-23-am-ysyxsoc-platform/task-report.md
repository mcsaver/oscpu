# Task Report

## 基本信息

- `task_id`: `2026-05-23-am-ysyxsoc-platform`
- `task_slug`: `am-ysyxsoc-platform`
- `graph_template`: `am-device-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23 19:22`
- `updated_at`: `2026-05-23 19:43`

## 任务目标

- `source_request`: 用户希望在 AM 中新增 ysyxSoC 平台，未来继续使用 AM 平台无关环境开发，而不用从 AM 迁移到裸 ysyxSoC/NPC 专用接口。
- `goal`: 新增 `riscv32-ysyxsoc`，按 ysyxSoC 地址图提供 TRM/IOE 基础平台，并让 AM run 默认进入 `npc/sim BACKEND=soc`。
- `scope`: `abstract-machine` 平台脚本与 RISC-V ysyxSoC 平台代码；验证覆盖 `am-kernels` cpu-tests 与 am-tests 构建；不修改 ysyxSoC 生成物或 NPC RTL。

## 选图说明

- `selected_template`: `am-device-loop`
- `why_this_graph`: 任务核心是新增 AM 平台并对齐设备配置、运行入口和基础测试。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、Copilot、memory、ysyxSoC spec、NPC/AM 平台代码 | 确认 ysyxSoC UART/PSRAM/CLINT-like timer 可作为默认 AM 平台基础，VGA/PS2/GPIO 暂为空壳 | 已读文件清单见会话记录 |
| implement | Codex | completed | `riscv32-npc`、`platform/npc.mk`、ysyxSoC 地址图 | 新增 `riscv32-ysyxsoc` 脚本和 `am/src/riscv/ysyxsoc/` 平台实现 | 新文件位于 `abstract-machine/scripts/` 与 `abstract-machine/am/src/riscv/ysyxsoc/` |
| verify | Codex | completed | 新平台代码、NPC SoC 后端、NEMU SoC reference | 构建并运行 smoke/full 回归 | `difftest-ref` PASS；cpu-tests 38/38 PASS；am-tests image PASS；diff check PASS |
| record | Codex | completed | 验证结果和设计边界 | 更新 memory 与 task-runs | 本目录与 `.github/memory/*` |

## 关键产物

- `artifacts`: `abstract-machine/scripts/riscv32-ysyxsoc.mk`、`abstract-machine/scripts/platform/ysyxsoc.mk`、`abstract-machine/am/src/riscv/ysyxsoc/*`、`am-kernels/tests/cpu-tests/tests/char-test.c`
- `logs_or_traces`: 终端验证输出；未保留长日志文件
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/abstract-machine.md`、`.github/memory/modules/am-kernels.md`、`.github/memory/modules/ysyx-soc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: ysyxSoC 真实 VGA/PS2/GPIO 外设仍是空壳，AM 平台默认不暴露这些设备。
- `risk_assessment`: timer 当前依赖 NPC SoC/NEMU reference 中的 CLINT-like `mtime`；若未来严格运行在未提供 CLINT 的 ysyxSoCFull/板级环境，需要补板级 timer 或调整 AM timer 实现。

## 补充验证

- [2026-05-23 21:26] 按用户截图要求将 ysyxSoC TRM 从 PSRAM 入口切到 MROM 入口，并补齐 SRAM 栈/堆和 NPC SoC MROM/SRAM 后端。关键证据：`char-test-riscv32-ysyxsoc.elf` entry `0x20000000`；反汇编 `_start` 首条为 `0x20000000: 00000413 li s0,0`；`_stack_pointer/_heap_start=0x0f001000`，`_heap_end=0x0f002000`；`readelf -S` 仅有 `.text@0x20000000` 与 `.rodata@0x20000238` 两个 alloc 段。
- 验证结果：`make -C am-kernels/tests/cpu-tests ARCH=riscv32-ysyxsoc ALL=char-test run YSYXSOC_RUN_ARGS="--no-diff --no-progress -m 0"` PASS；NPC 日志显示 MROM `[0x20000000,0x20000fff]`、SRAM `[0x0f000000,0x0f001fff]`，镜像 size `1364`，最终 `HIT GOOD TRAP at pc = 0x2000009e`。
- 直连 SoC smoke：`soc-main.cpp` 的 `mrom_read()` 改为返回最小 `li a0,0; ebreak`；`make -C npc/soc soc` 与 `./npc/soc/build/ysyxSoCFull` PASS。
- 实现注意：`ioe.c` 的 ysyxSoC handler LUT 已改为只读表，`timer.c` 不再写 `boot_time` 全局，避免 MROM-only 镜像下的运行期全局写。
- [2026-05-23 19:43] 按用户要求新增 `char-test` 验证 UART 字符输出。`riscv32-ysyxsoc` 下测试会先通过 `putch()` 输出固定字符序列，再通过 `AM_UART_TX` 输出 `char-test: AM_UART_TX path -> ysyxSoC UART OK`，并检查 `AM_UART_CONFIG.present` 与无输入 `AM_UART_RX == -1`。
- 验证结果：`ALL=char-test ARCH=riscv32-ysyxsoc` 在 `--no-diff` 与 `--diff=default` 下均 PASS；新增测试并入自动发现后，`ARCH=riscv32-ysyxsoc` 全量 cpu-tests 在 `--diff=default --no-progress -m 0` 下 39/39 PASS；`ALL=char-test ARCH=riscv32-npc` PASS。
- 实现注意：`char-test` 只覆盖串口路径，因此不需要调用完整 `ioe_init()`。

## 下一步建议

1. 补真实 ysyxSoC VGA/PS2/GPIO 后，打开或替换 `YSYXSOC_HAS_GPU/YSYXSOC_HAS_INPUT` 对应平台路径。
2. 若要在 `ysyxSoCFull` 顶层直接加载 AM 镜像，需要给 SoC Verilator 入口补镜像加载、flash/mrom DPI 和退出观测。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 否
- `reason`: 现有 `am-device-loop` 已覆盖。

## 收尾结论

- `final_result`: `riscv32-ysyxsoc` 平台完成，可通过 AM 构建并默认运行到 NPC SoC 后端。
- `evidence_summary`: `make -C npc/sim BACKEND=soc difftest-ref` PASS；`ARCH=riscv32-ysyxsoc` cpu-tests 初始 38/38 PASS，新增 `char-test` 后全量 39/39 PASS；`char-test` 在 ysyxSoC no-diff/diff-on 与 npc no-diff 下 PASS；`am-tests` image PASS；`git diff --check` PASS。
- `notes`: GPU/input 默认关闭是有意边界，不是遗漏。
