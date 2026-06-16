# Task Report

## 基本信息

- `task_id`: `2026-04-14-npc-trace-experience`
- `task_slug`: `npc-trace-experience`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `GitHub Copilot`
- `started_at`: `2026-04-14`
- `updated_at`: `2026-04-14`

## 任务目标

- `source_request`: `用户在接近 NEMU 的 NPC monitor/Kconfig/SDB 壳落地后，继续选择“补齐 itrace、mtrace、dtrace 的完整使用体验和回归验证”。`
- `goal`: `把 npc/single 现有零散的 itrace/mtrace/dtrace 日志点升级为真正可用的运行时 trace 体验，并补齐 CLI、monitor、README 和长期记忆。`
- `scope`: `Kconfig 默认项、monitor 参数解析、trace 运行时状态层、cpu-exec/paddr/map/dpi/NpcSimTop 的 trace 链路、README、memory、回归验证。`

## 选图说明

- `selected_template`: `regression-debug-loop`
- `why_this_graph`: `这轮工作本质上是对已存在 trace 钩子做“梳理链路 -> 提升运行时可用性 -> 回归验证 -> 修边角 bug -> 文档收口”的调试闭环，和 regression-debug-loop 最贴近。`
- `dynamic_nodes_added`: `trace-path-survey`, `runtime-trace-refactor`, `batch-regression`, `monitor-regression`, `literal-cond-fix`, `record-docs`
- `why_dynamic_nodes_were_needed`: `现有代码里虽然已有 trace 日志点，但缺运行时控制，且 mtrace 把 ifetch 与数据访存混在一起；在第一次回归后还额外暴露了默认 "true" 条件字面量误报，需要插入一轮局部修复与重跑。`

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `trace-path-survey` | `GitHub Copilot` | `completed` | `Kconfig`、`README`、`monitor.cpp`、`cpu-exec.cpp`、`paddr.cpp`、`map.cpp`、`dpi.cpp`、`NpcSimTop.sv` | 现有 trace 链路清单与缺口 | 确认三类 trace 只有编译期开关，且 mtrace 混入 ifetch |
| `runtime-trace-refactor` | `GitHub Copilot` | `completed` | 现有 trace 日志点与 monitor/SDB 框架 | 运行时 trace 状态层、CLI 开关、monitor 命令、ifetch/LSU 拆分 | `trace.cpp/trace.h` 与 `monitor/sdb/paddr/map/dpi/NpcSimTop` 已接通 |
| `batch-regression` | `GitHub Copilot` | `completed` | 新版 `NpcSimTop`、`hello-riscv32-npc.bin` | batch 下 `itrace/mtrace/dtrace` 回归结果 | `--itrace --itrace-cond '$pc == 0x80000000'` 和 `--mtrace --dtrace` 均跑通 hello |
| `monitor-regression` | `GitHub Copilot` | `completed` | `(npc)` monitor、`info t`、`trace ...` | monitor 动态 trace 控制回归结果 | `info t` / `trace itrace on` / `trace cond ...` / `si 2` 已生效 |
| `literal-cond-fix` | `GitHub Copilot` | `completed` | monitor/batch 回归日志中的 warning | `true/false` 字面条件兼容修复 | 修复后 `trace cond true` 与默认 `CONFIG_NPC_ITRACE_COND="true"` 不再误报 |
| `record-docs` | `GitHub Copilot` | `completed` | 回归命令、日志、memory 协议 | README、memory、task-run 收尾 | 本 task-report、dispatch-log、README、memory 已同步 |

## 关键产物

- `artifacts`: `npc/single/Kconfig`、`npc/single/configs/default_defconfig`、`npc/single/README.md`、`npc/single/csrc/include/utils.h`、`npc/single/csrc/include/memory/paddr.h`、`npc/single/csrc/include/device/map.h`、`npc/single/csrc/include/monitor/trace.h`、`npc/single/csrc/cpu/cpu-exec.cpp`、`npc/single/csrc/memory/paddr.cpp`、`npc/single/csrc/device/map.cpp`、`npc/single/csrc/dpi.cpp`、`npc/single/csrc/monitor/monitor.cpp`、`npc/single/csrc/monitor/sdb.cpp`、`npc/single/csrc/monitor/trace.cpp`、`npc/single/vsrc/NpcSimTop.sv`
- `logs_or_traces`: `make -C npc/single default_defconfig && make -C npc/single all -j4` 通过；`./npc/single/build/NpcSimTop ... -b --itrace --itrace-cond '$pc == 0x80000000' --log npc/single/build/itrace-test.log --max-cycles 200000` 输出首条提交 itrace 并正常退出；`./npc/single/build/NpcSimTop ... -b --mtrace --dtrace --log npc/single/build/mtrace-dtrace-test.log --max-cycles 200000` 输出数据访存与 serial dtrace 并正常退出；`printf 'info t\ntrace itrace on\ntrace cond true\ninfo t\nsi 2\nq\n' | ./npc/single/build/NpcSimTop ... --log npc/single/build/monitor-trace-test.log --max-cycles 200000` 验证 monitor 动态 trace 与 `true` 字面条件生效且不再报警。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: `无硬阻塞；当前三类 trace 已可通过 CLI 和 monitor 在运行时控制。`
- `missing_dependencies`: `仍未接更完整的 difftest/反汇编展示/更细粒度的设备 trace 分类。`
- `risk_assessment`: `当前 itrace 记录的是提交边界和写回结果，够用但还不是完整反汇编视图；mtrace/dtrace 已能满足 bring-up 和设备定位，但日志量仍取决于 guest 程序真实访问密度。`

## 下一步建议

1. 在现有 `itrace` 基础上补反汇编文本和更细的条件过滤，进一步贴近 NEMU 的指令视图。
2. 如果后续接 difftest，可直接复用当前 `cpu-exec` 的提交边界，把 trace 与对拍证据放在同一观察点。

## 模板升级候选

- `repeated_dynamic_subgraph`: `survey trace path -> add runtime control -> batch/monitor regression -> fix corner bug -> record docs`
- `should_promote_to_static_template`: `yes`
- `reason`: `后续无论是补 difftest、补反汇编、还是扩设备 trace，都会复用这条“已有调试钩子体验化 + 回归 + 文档收口”的子流程。`

## 收尾结论

- `final_result`: `npc/single` 的 `itrace/mtrace/dtrace` 已从“编译期开关 + 零散日志点”升级为“运行时可控 + monitor/CLI 可用 + 文档可查”的 trace 子系统，其中 mtrace 已显式排除 ifetch，只记录真实数据 load/store。`
- `evidence_summary`: 构建链闭合；batch `itrace`、batch `mtrace+dtrace`、monitor `info t/trace` 三条路径均实测通过；默认 `CONFIG_NPC_ITRACE_COND="true"` 与 monitor `trace cond true` 不再触发错误 warning。
- `notes`: 这轮工作的关键不是多加几个 `Log()`，而是把 trace 的“build 能力、运行时状态、用户入口、日志边界”一次理顺，避免后续继续把调试体验卡在编译期宏和噪音日志上。