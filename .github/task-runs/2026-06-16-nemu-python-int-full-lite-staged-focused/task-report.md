# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-staged-focused
- `task_slug`: nemu-python-int-full-lite-staged-focused
- `graph_template`: `hardware-aware-software-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- `source_request`: 继续推进 NEMU full Ubuntu 22.04，并让 agent 环境、e2e 环境、记忆系统协同；当前 PyLong blocker 的 focused gate 需要更接近 full hard gate 的 before/runtime 多阶段时序。
- `goal`: 在不减少旧 focused gate 能力的前提下，为 `check-nemu-python-int-preflight` 增加 staged mode，并用真实 full rootfs 重型 run 验证。
- `scope`: NEMU-only；不切 NPC，不从备份取答案。

## 选图说明

- `selected_template`: `hardware-aware-software-loop` + `modular-agent-e2e`
- `why_this_graph`: 该任务修改 Linux/NEMU guest check 脚本和 agent/e2e 合同，属于软件实现硬件/系统语义的 NEMU Ubuntu gate。
- `dynamic_nodes_added`: `python-int-staged-focused-gate`
- `why_dynamic_nodes_were_needed`: issue [76] 的剩余缺口是 focused 3-loop 触发率不足，需要一个更接近 full hard gate 的多阶段 probe。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall-current-state | Codex | PASS | `.github/AGENTS.md`, project memory, issue [76] | 确认 focused gate 下一步应接近 full gate 多阶段时序 | 本报告 |
| implement-staged-gate | Codex | PASS | `Linux/scripts/check-nemu-python-int-preflight.sh`, `Linux/Makefile`, `scripts/e2e/modules/nemu.sh` | `NEMU_PYTHON_INT_STAGE_MODE`, `NEMU_PYTHON_INT_TAGS`, stage summary/e2e contract | git diff |
| validate-contract | Codex | PASS | staged gate source | `bash -n` PASS, `--validate-profile nemu-ubuntu-profile` PASS | 终端输出 |
| python-int-staged-focused-gate | Codex | PASS | full rootfs, full-lite stage mode, 80B max inst, loops=5 | 6 stage x 5 loops 全 rc=0，summary TSV 写入 stage rc | `evidence/nemu-python-int-preflight/console.log`, `python-int-preflight-summary.tsv` |

## 关键产物

- `artifacts`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-staged-focused/`
- `logs_or_traces`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-staged-focused/evidence/nemu-python-int-preflight/`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/nemu.md`, `.github/memory/modules/agent-system.md`, `.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: PyLong transient root cause 仍未定位；本 run 未复现 corruption。
- `missing_dependencies`: 仍需要继续 A/B `wide-ifetch`、`vaddr-host-fast` 或更重 stage/systemctl mode。
- `risk_assessment`: `full-lite` 比旧 focused 更接近 full gate，但仍不是完整 `check-nemu-systemd-guest.sh` 的全部 runtime 行为，不能单独证明 issue [76] 已修。

## 下一步建议

1. 用同一 staged gate 跑 `NEMU_INTERPRETER_WIDE_IFETCH=0` 和 `NEMU_VADDR_HOST_FAST=0` A/B。
2. 若仍全部 PASS，升级到 `systemctl-lite` 或自定义 tags，覆盖 systemctl daemon-reload/root-enable/runtime-start 相关时序。
3. 结合 host perf 基线继续看 `rv_decode_cache_exec`、`vaddr_ifetch_wide`、`exec_rv64c` 和 Sv39 热路径。

## 模板升级候选

- `repeated_dynamic_subgraph`: PyLong full-rootfs staged focused reproducer
- `should_promote_to_static_template`: `yes`
- `reason`: issue [76] 需要反复用同一 stage matrix 做 slow-path A/B。

## 收尾结论

- `final_result`: PASS for staged focused gate, issue [76] still active.
- `evidence_summary`: `python-int-preflight-summary.tsv` 显示 `stage_mode=full-lite`, `stage_count=6`, `loops=5`, `stage_rc.*=0`, `boot_seconds=69`, `total_seconds=181`。console 中 30 条 `__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:<tag>:<i>:0` 全部 PASS。
- `notes`: 这是 NEMU-only full rootfs focused/staged gate，不代表完整 Ubuntu login/full hard gate 或 PyLong 根因完成。
