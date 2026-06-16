# Task Report

## 基本信息

- `task_id`: 2026-06-16-nemu-npc-parallel-runtime-policy
- `trace_id`: manual:2026-06-16-nemu-npc-parallel-runtime-policy
- `task_slug`: nemu-npc-parallel-runtime-policy
- `graph_template`: agent-env-refactor
- `profile`: agent-system + nemu-dev + npc-dev
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system
- `started_at`: 2026-06-16 13:55:31 +0800
- `updated_at`: 2026-06-16 13:55:31 +0800

## 任务目标

- `source_request`: NEMU/NPC 并行开发时，经常出现 NEMU 跑着跑着就杀了 NPC 的进程。
- `goal`: 让 NEMU/NPC 日常并行开发不被 active runtime guard 硬拦，同时保留 strict 单场景复现能力。
- `scope`: `scripts/e2e/lib/common.sh`、agent-system runtime guard 合同、相关 e2e 文档与 memory。

## 根因结论

- 仓库内 NEMU guest-check cleanup 只 kill 自己保存的 `nemu_pid`，没有发现按名字 `pkill/killall` NPC 的代码。
- 真实冲突来自此前 active scenario runtime isolation 的 hard fail 语义：NEMU-only dispatch 发现 NPC 长跑即失败，外层 wrapper 或人工清理容易表现成“NEMU 杀 NPC”。

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `root-cause-scan` | `agent-system` | `agent-system` | `PASS` | kill/cleanup 搜索、memory | NEMU cleanup 未按名字杀 NPC；runtime guard hard fail 是体验根因 | evidence/validation-summary.log |
| `policy-implementation` | `agent-system` | `agent-system` | `PASS` | `scripts/e2e/lib/common.sh` | 默认 `warn`，`strict` hard fail，`off` 跳过 | scripts/e2e/lib/common.sh |
| `contract-doc-update` | `agent-system` | `agent-system` | `PASS` | e2e tests/docs | agent-system 合同和文档同步 | evidence/validation-summary.log |
| `validation` | `agent-system` | `agent-system` | `PASS` | fake ps + profile validate | warn/strict/off 返回码符合预期，相关 profile 校验 PASS | evidence/validation-summary.log |
| `real-dispatch-smoke` | `nemu` | `nemu` | `PARTIAL` | `scripts/agent-e2e.sh --profile nemu-dev` | runtime guard PASS policy=warn；后续既有 NEMU slice 合同失败 | .github/task-runs/2026-06-16-2026-06-16-nemu-npc-parallel-runtime-warn/ |

## 当前阻塞点

- `blockers`: 并行 runtime policy 修复无阻塞。
- `residual`: 真实 `nemu-dev` dispatch 后续 blocked 在 `nemu-ubuntu-slice-contract` 的既有 Makefile 字符串合同失败，不属于本轮 runtime policy。

## 收尾结论

- `final_result`: NEMU/NPC 日常并行开发默认不再因 active runtime guard 被硬拦；严格单场景复现实验可显式设置 `AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict`。
- `evidence_summary`: 见 `evidence/validation-summary.log` 与真实 `nemu-dev` task-run。
