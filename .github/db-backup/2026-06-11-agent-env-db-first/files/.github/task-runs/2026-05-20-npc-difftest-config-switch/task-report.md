# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-difftest-config-switch`
- `task_slug`: `npc-difftest-config-switch`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 用户要求把 NPC difftest 做成可手动关闭的开关，避免不需要时影响性能。
- `goal`: 增加编译期开关，并保留原有 `--diff=default` 运行时启用方式。
- `scope`: `npc/single` Kconfig、Makefile、host difftest/monitor/执行链、README、记忆文档。

## 选图说明

- `selected_template`: `regression-debug-loop`
- `why_this_graph`: 配置改动会影响构建矩阵和 difftest 回归，需要覆盖关闭与打开两条路径。
- `dynamic_nodes_added`: 无。
- `why_dynamic_nodes_were_needed`: 不需要扩图。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、memory、NPC study、源码检索 | 确认 difftest 原先只有运行时 `--diff` | `rg`/源码阅读 |
| implement | codex | completed | Kconfig/Makefile/host CLI/README | 新增 `CONFIG_NPC_DIFFTEST` 两层开关 | 文件 diff |
| verify-off | codex | completed | 本地原配置，difftest 关闭 | 构建、help、裸跑通过 | `make -C npc/single -B -j4`; `--help`; `cpu-tests add` |
| verify-on | codex | completed | 临时 `default_defconfig`，difftest 打开 | 构建、help、difftest add 通过 | `make -C npc/single -B -j4`; `cpu-tests add --diff=default` |
| record | codex | completed | 验证结果 | memory/task-runs 更新 | 本文件与 memory 条目 |

## 关键产物

- `artifacts`: `CONFIG_NPC_DIFFTEST`，`default_defconfig/perf_defconfig` 差异，关闭配置下的 `difftest.h` stub。
- `logs_or_traces`: 终端验证输出。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/difftest.md`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: `default_defconfig` 打开 `CONFIG_NPC_ITRACE=y` 时暴露了既有 `disasm.c` 函数指针链式赋值编译错误，已用最小改动修复。

## 下一步建议

1. 长跑 benchmark 时优先使用 `make -C npc/single perf_defconfig` 或在 `menuconfig` 里关闭 `NPC_DIFFTEST` 后重建。
2. 做功能回归时使用 `default_defconfig` 或手动打开 `NPC_DIFFTEST`，再传 `NPC_RUN_ARGS='--diff=default -m 0'`。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无。
- `should_promote_to_static_template`: 否。
- `reason`: 单次配置切换任务。

## 收尾结论

- `final_result`: NPC difftest 已支持编译期关闭，且保留运行时显式开启。
- `evidence_summary`: 关闭配置构建/裸跑 PASS；打开配置构建/difftest PASS；lint PASS。
- `notes`: 本地 `.config` 已恢复为进入任务前的关闭 difftest 配置，最终二进制也按关闭路径重建。
