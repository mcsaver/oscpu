# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-vsrc-layout`
- `task_slug`: `npc-vsrc-layout`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22 18:00`
- `updated_at`: `2026-05-22 18:06`

## 任务目标

- `source_request`: 用户希望把 `vsrc` 中过多的模块按商业方案分门别类放到不同目录中，方便管理。
- `goal`: 在不改变 RTL 行为的前提下，将 NPC RTL/仿真源文件按功能域分区，并让构建、testbench、文档与记忆同步使用新结构。
- `scope`: `npc/single/vsrc`、`npc/single/Makefile`、`npc/single/testbench/Makefile`、`npc/single/README.md`、`.github/agents/npc.agent.md`、相关 memory/task-run 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务是源码组织与构建入口重排，不属于参考模型闭环或 bug 调试模板；但涉及大量文件移动和构建/testbench 依赖，需要独立节点记录。
- `dynamic_nodes_added`: `recall`、`map-layout`、`move-files`、`update-build`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 需要先摸清 `NpcCore/NpcSimTop/testbench/STA` 依赖，再执行文件移动并逐层验证路径。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | codex | completed | `.github/AGENTS.md`、`copilot-instructions.md`、memory、NPC study README | 约束摘要：中文、先读记忆、跨文件先查依赖、改后验证和记录 | 已完成必读链读取 |
| `map-layout` | codex | completed | `vsrc` 文件列表、`NpcCore/NpcSimTop` 实例化链、testbench Makefile | 功能域目录映射：include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/sim | `rg --files`、实例化扫描、旧路径引用扫描 |
| `move-files` | codex | completed | 平铺 `npc/single/vsrc/*.{v,sv}` | RTL/仿真源文件移动到功能目录，新增 `vsrc/filelist.mk` | `find npc/single/vsrc -maxdepth 2 -type f` 显示新树 |
| `update-build` | codex | completed | `Makefile`、`testbench/Makefile`、README、NPC agent 文档 | 主构建/testbench 共享 `vsrc/filelist.mk`，补 `vsrc/include` include 路径，文档同步 | `make -n lint` 与 testbench dry-run 展开新路径 |
| `verify` | codex | completed | 新目录和构建清单 | lint/build/testbench/cpu-tests 全通过 | 见“关键产物”验证证据 |
| `record` | codex | completed | 本次改动和验证结果 | 更新 project-status、npc memory、decisions、本 task-run | 本目录与 memory 已更新 |

## 关键产物

- `artifacts`: `npc/single/vsrc/filelist.mk`；`vsrc/include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/sim/`；更新后的 `npc/single/Makefile` 与 `npc/single/testbench/Makefile`
- `logs_or_traces`: `/tmp/npc-vsrc-layout-tests`、`/tmp/npc-vsrc-layout-pipe`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`

## RTL 变更边界

- `需求要点`: 改善源码可维护性和构建清单集中度；不改变 CPU 功能。
- `协议/状态机/不变量`: 本轮没有修改任何模块内部 RTL 语句、端口、握手协议、状态机或数据通路，因此既有协议与不变量沿用移动前版本。
- `数据通路约束`: 仅路径变更；`NpcCore` 对 IF/decode/execute/memory/cache/bus/writeback 的连接关系保持不变。
- `自检结论`: 通过 lint、强制 Verilator build、模块 testbench、pipe_test 和 cpu-tests 证明路径重排没有破坏编译入口和端到端运行。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 综合/STA 未运行；本任务只验证 Verilator 与 Icarus 路径，既有 `oss-cad-suite` 缺失问题仍见 known-issues。
- `risk_assessment`: Git 未暂存时重命名会显示为 delete + untracked 目录；提交时需让 Git 检测 rename，避免误判为删除。

## 下一步建议

1. 后续新增 RTL 文件时只更新 `npc/single/vsrc/filelist.mk`，不要在多个 Makefile 中重复维护路径。
2. 若恢复 `oss-cad-suite`，可再跑 `make -C npc/single syn-check-env` / `syn` 确认 STA filelist 入口。

## 模板升级候选

- `repeated_dynamic_subgraph`: 源码组织/构建入口重排。
- `should_promote_to_static_template`: `false`
- `reason`: 当前是一次性结构整理，尚未形成高频重复图。

## 收尾结论

- `final_result`: NPC `vsrc` 已按功能域分目录管理，构建、testbench、文档和长期记忆同步完成。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single -B -j14` PASS；模块 testbench 22/22 PASS；pipe_test PASS；`cpu-tests` 38/38 PASS。
- `notes`: 本轮不包含 RTL 行为改动。
