# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-wide-ifetch-off-diag-rerun
- `task_slug`: nemu-python-int-full-lite-wide-ifetch-off-diag-rerun
- `graph_template`: `hardware-aware-software-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- `source_request`: 继续推进 NEMU full Ubuntu 22.04，修环境 bug 而不是绕过问题。
- `goal`: 在 probe 增强 loops 参数诊断后，重跑同一 `wide-ifetch-off` staged gate。
- `scope`: NEMU-only full rootfs；不切 NPC，不从备份取答案。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| add-loop-arg-diagnostics | Codex | PASS | `Linux/tools/nemu-python-int-preflight.py` | `ARGS_LOOPS_TYPE/REPR/BIT_LENGTH/PLUS_ONE` marker | git diff |
| wide-ifetch-off-diag-rerun | Codex | PASS | full rootfs, `NEMU_INTERPRETER_WIDE_IFETCH=0`, `full-lite`, loops=5, 80B max inst | 6 stage all rc=0，done rc=0 | `python-int-preflight-summary.tsv` |

## 关键产物

- `artifacts`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off-diag-rerun/`
- `logs_or_traces`: `evidence/nemu-python-int-preflight/`
- `linked_memory_updates`: `.github/memory/known-issues.md`, `.github/memory/modules/nemu.md`

## 当前阻塞点

- `blockers`: PyLong transient 仍不稳定；该重跑未复现。
- `missing_dependencies`: 需要继续用 staged gate 扩大样本，或转向更具体的 ifetch/host-fast/memory corruption 根因切片。
- `risk_assessment`: 一次 PASS 不能否定前一次 transient failure。

## 下一步建议

1. 对 host-fast-off 运行同规格 staged gate。
2. 若继续出现 transient，优先收集 `ARGS_LOOPS_*` marker。

## 收尾结论

- `final_result`: PASS.
- `evidence_summary`: summary 显示 `runtime.wide_ifetch=0`、`stage_count=6`、所有 `stage_rc.*=0`、boot 135s、total 294s；console 中每个 stage 的 `ARGS_LOOPS_REPR=5`、`ARGS_LOOPS_PLUS_ONE=6` 正常。
- `notes`: 证明 wide-ifetch-off 下 failure 是 transient，不是每次必现。

