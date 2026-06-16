# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-full-lite-wide-ifetch-off
- `task_slug`: nemu-python-int-full-lite-wide-ifetch-off
- `graph_template`: `hardware-aware-software-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-16
- `updated_at`: 2026-06-16

## 任务目标

- `source_request`: 继续推进 NEMU full Ubuntu 22.04，使用重型 staged focused gate 对 PyLong blocker 做 fast-path A/B。
- `goal`: 在 `NEMU_INTERPRETER_WIDE_IFETCH=0` 下运行 full-lite staged PyLong gate，观察是否复现 [76]。
- `scope`: NEMU-only full rootfs；不切 NPC，不从备份取答案。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| wide-ifetch-off-staged-run | Codex | FAIL-as-signal | full rootfs, `NEMU_INTERPRETER_WIDE_IFETCH=0`, `full-lite`, loops=5, 80B max inst | `runtime-after-journal` stage rc=1，done rc=1 | `evidence/nemu-python-int-preflight/console.log` |

## 关键产物

- `artifacts`: `.github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/`
- `logs_or_traces`: `evidence/nemu-python-int-preflight/console.log`
- `linked_memory_updates`: `.github/memory/known-issues.md`, `.github/memory/modules/nemu.md`

## 当前阻塞点

- `blockers`: PyLong transient 仍未定位根因。
- `missing_dependencies`: 需要带 loops 参数诊断的重跑确认损坏细节。
- `risk_assessment`: 该 run 只证明 staged wide-ifetch-off 场景下复现过一次 transient；不能单独证明 wide-ifetch 关闭是根因。

## 下一步建议

1. 增强 Python probe 对 `args.loops`/`args.loops + 1` 的诊断 marker。
2. 以同场景重跑，确认是否稳定复现。

## 收尾结论

- `final_result`: PyLong transient reproduced once.
- `evidence_summary`: `runtime-after-journal` prewarm rc=0，随后 Python probe 在 `range(1, args.loops + 1)` 抛出 `OverflowError: too many digits in integer`；`after-runtime` stage 又恢复 rc=0。
- `notes`: 该失败是有价值的 transient 复现证据，但不是完整根因闭合。

