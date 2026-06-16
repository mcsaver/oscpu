# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-single-module-testbench`
- `task_slug`: `npc-single-module-testbench`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 在 `single` 目录下建立 `testbench`，独立测试每个模块正确性，并在 `perf` 中保留结果。
- `goal`: 为 `npc/single/vsrc` 纯 RTL 核心模块建立可复跑的模块级自检入口，产物归档到 `npc/single/perf/results/<timestamp>/module-testbench/`。
- `scope`: 新增 testbench 框架、模块自检用例、结果归档；不修改 RTL 功能逻辑。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 该任务是 RTL 模块级验证基础设施建设，不属于现有 AM/NEMU 参考闭环或 CI 修复模板。
- `dynamic_nodes_added`: `recall`、`testbench-design`、`implement`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 需要先确认模块边界、工具链和 perf 结果约定，再落测试框架。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | codex | completed | AGENTS、copilot 指令、memory、NPC study、Makefile、perf README | 约束摘要与模块清单 | 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/*`、`npc/single/design/study/*` |
| `testbench-design` | codex | completed | `npc/single/vsrc` 模块接口、Icarus/Verilator 可用性 | Icarus 模块级自检方案 | `verilator --version`、`iverilog -V` 可用 |
| `implement` | codex | completed | 纯 RTL 模块清单 | `npc/single/testbench` 框架与 21 个 testbench 入口 | 新增 `testbench/Makefile`、`common/*.svh`、`tests/*.sv` |
| `verify` | codex | completed | testbench 框架 | perf 归档结果与 lint 结果 | `make -C npc/single/testbench run` 21/21 PASS；`make -C npc/single lint` PASS |
| `record` | codex | completed | 验证结果 | task-run 与 memory 更新 | 本文件、`dispatch-log.md`、memory 条目 |

## 关键产物

- `artifacts`: `npc/single/testbench/`
- `logs_or_traces`: `npc/single/perf/results/20260520-114215/module-testbench/summary.txt`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: `NpcSimTop.sv` 是 DPI-C 仿真壳，不作为纯 RTL unit test；它仍由原有 Verilator lint/build 与 AM difftest 闭环覆盖。Icarus 对 `ICache` 内部 memory function 的接口数据存在 X 传播差异，本轮 `tb_icache` 对 fill/hit 额外检查内部 line 数据与接口 valid/error，完整取指数据路径仍以 Verilator/NPC difftest 为准。

## 下一步建议

1. 后续改任一 RTL 子模块时，先跑 `make -C npc/single/testbench run` 做模块级 smoke，再跑原有 difftest。
2. 如果要把 cache 数据接口也纳入 bit-accurate unit test，可为 `ICache/DCache/NpcCore` 增加 Verilator C++ 专用 testbench，绕开 Icarus 对该函数/数组组合的仿真差异。

## 模板升级候选

- `repeated_dynamic_subgraph`: RTL module unit-test infrastructure
- `should_promote_to_static_template`: `false`
- `reason`: 当前是一次性基础设施建设，后续若频繁新增 RTL 模块再考虑固化模板。

## 收尾结论

- `final_result`: 已建立 `npc/single/testbench` 模块级自检框架，并把通过结果归档到 `npc/single/perf/results/20260520-114215/module-testbench/`。
- `evidence_summary`: 21 个 testbench 全部 PASS；原有 `npc/single` Verilator lint PASS。
- `notes`: 本轮未修改 RTL。
