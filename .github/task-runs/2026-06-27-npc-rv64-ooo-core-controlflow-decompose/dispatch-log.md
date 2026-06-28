# 派发日志

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 模块 (`module`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | --------------- | ----------------- |
| recall | codex | repo rules | completed | AGENTS/copilot/memory/npc RTL workflow | 明确继续解耦、记录和验证约束 | task-report.md |
| rtl-derive | codex | npc/rv64 RTL | completed | core glue 剩余组合公式 | 需求/协议/状态机/不变量/数据通路摘要 | task-report.md |
| implement | codex | frontend/control/writeback/core | completed | `OooCoreTopGlue.v` direct/control/writeback 规则 | 新增 owner modules 并接线 | source diff |
| focused-verify | codex | npc/rv64/testbench | completed | focused tests | 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-core-controlflow-decompose/focused/` |
| full-verify | codex | npc/rv64/testbench/lint/build | completed | 默认 testbench、lint、build | 103/103 PASS；lint PASS；build PASS | `npc/rv64/perf/results/20260627-ooo-core-controlflow-decompose/all/` |
| record | codex | docs/memory/task-run | completed | README/spec/memory | README/spec/memory/task-run 更新 | task-report.md |
