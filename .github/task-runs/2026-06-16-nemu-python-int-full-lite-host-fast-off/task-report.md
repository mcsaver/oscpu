# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-host-fast-off
- `task_slug`: nemu-python-int-full-lite-host-fast-off
- `graph_template`: `hardware-aware-software-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- `source_request`: 继续推进 NEMU full Ubuntu 22.04，使用重型 staged focused gate 对 PyLong blocker 做 fast-path A/B。
- `goal`: 在 `NEMU_VADDR_HOST_FAST=0` 下运行 full-lite staged PyLong gate，观察是否复现 [76]。
- `scope`: NEMU-only full rootfs；不切 NPC，不从备份取答案。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| host-fast-off-staged-run | Codex | PASS | full rootfs, `NEMU_VADDR_HOST_FAST=0`, `full-lite`, loops=5, 120B max inst | 6 stage all rc=0，done rc=0 | `python-int-preflight-summary.tsv` |

## 关键产物

- `artifacts`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-host-fast-off/`
- `logs_or_traces`: `evidence/nemu-python-int-preflight/`
- `linked_memory_updates`: `.github/memory/known-issues.md`, `.github/memory/modules/nemu.md`

## 当前阻塞点

- `blockers`: PyLong transient root cause 仍未定位。
- `missing_dependencies`: 需要更具体的 root-cause slice 或更多 staged samples。
- `risk_assessment`: host-fast-off PASS 不排除 host-fast path；只说明该单次 full-lite staged sample 未复现。

## 下一步建议

1. 将 transient failure 聚焦到 Python argv/argparse/loop small-int corruption 路径。
2. 增加 systemctl-lite/custom stage 或重复采样统计复现概率。

## 收尾结论

- `final_result`: PASS.
- `evidence_summary`: summary 显示 `runtime.vaddr_host_fast=0`、`stage_count=6`、所有 `stage_rc.*=0`、boot 199s、total 479s。
- `notes`: 该 run 是 slow-path A/B 证据，不代表 issue [76] 已关闭。

