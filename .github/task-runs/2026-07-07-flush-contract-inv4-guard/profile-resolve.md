# Profile Resolve

- `npc-dev`: 本轮真实语义改动触碰 `npc/rv64/vsrc/**`、`npc/rv64/eval/contract-assert-baseline.txt`、`npc/rv64/design/**`；需要 `check-contract`、RV64 build 和 focused TB 证据。
- `agent-system`: 当前工作树仍有 `.github/**` 与 `scripts/**` 既有脏文件，strict guard 会要求 agent-system 证据；本任务同时更新 memory/task-run，故纳入 guard 覆盖。
- `difftest` / `nemu-dev`: 当前工作树仍有前序 difftest/NEMU dirty paths，strict guard 会在最终收尾按整棵 dirty worktree 要求它们；本轮未改 NEMU/difftest 语义，相关覆盖沿用当前 task-run 的“无新增语义改动 + guard 通过”记录，不把本切片说成 difftest/NEMU 功能交付。

本轮未运行完整 `scripts/agent-e2e.sh --profile <profile>`；采用 bounded 证据：in-RTL assertion ratchet、Verilator build、focused module TB、doc lifecycle 校正和 strict guard。
