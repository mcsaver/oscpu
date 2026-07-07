# Profile Resolve

- `npc-dev`: 触碰 `npc/rv64/design/arch/ROADMAP.md`、`serialize-at-retire.md` 和 NPC difftest 注释；需要 RV64 build 与 contract 证据。
- `nemu-dev`: 触碰 `nemu/src/isa/riscv64/difftest/dut.c` 注释，并复核 NEMU 仍作为 CSR/priv/FPR reference；需要 NEMU build 证据。
- `difftest`: 任务核心是把 CSR/FPR full-state difftest 的当前事实写回 ROADMAP 与 serialize 文档；需要说明比较范围与剩余掩码边界。
- `agent-system`: 触碰 `scripts/README.md`，并按 doc-lifecycle/task-run/strict guard 规则生成证据包。

本轮未运行完整 `scripts/agent-e2e.sh --profile <profile>`，采用 bounded 手工证据：工具自构建、NEMU build、NPC RV64 build、`check-contract`、scoped `git diff --check` 与最终 strict guard。原因是本任务真实代码改动集中在工作区工具构建模板和文档生命周期，不改 RTL/NEMU 语义。
