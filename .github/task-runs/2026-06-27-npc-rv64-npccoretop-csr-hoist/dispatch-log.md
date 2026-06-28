# 派发日志

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 模块 (`module`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | --------------- | ----------------- |
| recall | codex | repo rules | completed | AGENTS/copilot/memory/npc RTL workflow | 明确顶层实例层级与验证约束 | task-report.md |
| rtl-derive | codex | npc/rv64 RTL | completed | `NpcCoreTop`/`OooCoreTopGlue`/`CsrFile` 接口 | 需求/协议/状态机/不变量/数据通路摘要 | task-report.md |
| implement | codex | core/testbench | completed | glue 内部 CSR/FPR 状态实例 | CSR/FPR state owner 上提到 `NpcCoreTop`，testbench 外置 CSR/FPR include | source diff |
| focused-verify | codex | npc/rv64/testbench | completed | focused tests | 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-core-npccoretop-csr-hoist/focused/` |
| full-verify | codex | npc/rv64/testbench/lint/build | completed | 默认 testbench、lint、build | 103/103 PASS；lint PASS；build PASS | `npc/rv64/perf/results/20260627-ooo-core-npccoretop-csr-hoist/all/` |
| record | codex | docs/memory/task-run | completed | README/spec/memory | README/spec/memory/task-run 更新 | task-report.md |
