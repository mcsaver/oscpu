# Task Report

## 基本信息

- `task_id`: `2026-04-22-nemu-kconfig-batch-mode`
- `task_slug`: `nemu-kconfig-batch-mode`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-04-22 14:21:00 +0800`
- `updated_at`: `2026-04-22 14:33:44 +0800`

## 任务目标

- `source_request`: `把这个批处理模式放到Kconfig中实现可配置化`
- `goal`: `把 NEMU 批处理模式改成 Kconfig 可持久化的默认行为，同时保留命令行 -b/--batch 作为按次开启入口`
- `scope`: `nemu/Kconfig`、`nemu/src/monitor/sdb/sdb.c`，以及对应 memory/task-run 记录`

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: `本任务仍然是参考平台 NEMU 的启动闭环修补，但这次把默认行为从命令行扩展到 Kconfig -> config macro -> sdb 启动状态`
- `dynamic_nodes_added`: `none`
- `why_dynamic_nodes_were_needed`: `none`

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `trace-kconfig-path` | `codex` | `completed` | `nemu/Kconfig`、`sdb.c`、`config.mk` | Kconfig 接线点与语义选择 | 确认应新增 `CONFIG_BATCH_MODE`，并仅控制 batch 的默认值 |
| `patch-kconfig-default` | `codex` | `completed` | `nemu/Kconfig`、`sdb.c` | `CONFIG_BATCH_MODE` 与默认批处理状态初始化 | `Kconfig` 新增配置项，`sdb.c` 用 `MUXDEF(CONFIG_BATCH_MODE, true, false)` 初始化 `is_batch_mode` |
| `verify-default-and-cli` | `codex` | `completed` | 默认 `.config`、native NEMU | 默认关闭与显式 `-b` 验证结果 | 默认 `.config` 为 `# CONFIG_BATCH_MODE is not set`；`make -C nemu ISA=riscv32 run ARGS=-b` 直接 `HIT GOOD TRAP` |
| `verify-kconfig-enabled` | `codex` | `completed` | 临时测试配置 | `CONFIG_BATCH_MODE=y` 时的自动批处理行为 | 临时 `syncconfig` 后 `.config` / `autoconf.h` 出现 `CONFIG_BATCH_MODE=y`；不传 `-b` 的 `make -C nemu ISA=riscv32 run ARGS=` 直接 `HIT GOOD TRAP` |
| `restore-config` | `codex` | `completed` | 原始 `.config` 备份 | 恢复后的工作区配置状态 | 恢复并重新 `syncconfig` 后，当前 `nemu/.config` 回到 `# CONFIG_BATCH_MODE is not set` |

## 关键产物

- `artifacts`: `nemu/Kconfig`、`nemu/src/monitor/sdb/sdb.c`
- `logs_or_traces`: `默认关闭、命令行开启、Kconfig 开启三类启动路径的终端输出`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`

## 当前阻塞点

- `blockers`: `none`
- `missing_dependencies`: `none`
- `risk_assessment`: `本次把 batch 模式提升为可配置默认值，但没有改变 -b 的显式开启语义；剩余注意点是恢复 .config 时需要显式 syncconfig，否则 autoconf.h 可能暂时滞后`

## 下一步建议

1. 若后续还要把 monitor 行为继续配置化，可考虑把启动后自动执行的第一条命令也抽成 Kconfig 或脚本入口，而不只限于 batch 模式。
2. 可补一个脚本化 smoke test，固定验证 `CONFIG_BATCH_MODE=y` 时 `run` 目标不会停在 `(nemu)`。

## 模板升级候选

- `repeated_dynamic_subgraph`: `none`
- `should_promote_to_static_template`: `no`
- `reason`: `现有参考闭环模板足以覆盖这类启动配置任务`

## 收尾结论

- `final_result`: `NEMU 批处理模式已支持 Kconfig 配置默认值，且命令行 -b/--batch 兼容保留`
- `evidence_summary`: `默认关闭、显式命令行开启、临时 Kconfig 开启三条路径均已验证，且测试后已恢复原始配置`
- `notes`: `make 过程里的 .git/index.lock 只读告警来自仓库自带 git 记录辅助逻辑，不影响验证结果`
