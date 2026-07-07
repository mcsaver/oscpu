# Profile Resolve

- `npc-dev`: 触碰 `npc/rv64/vsrc/**`、`npc/rv64/testbench/**` 与 `npc/rv64/design/specs/**`，需要 RTL style/lint/build/focused TB/contract 证据。
- `nemu-dev`: 触碰 `nemu/src/isa/riscv64/**` 注释与构建边界，需要 NEMU build 证据。
- `difftest`: 任务目标是 NPC 与 NEMU 的 Svnapot 行为对齐，必须给出 full-state difftest 证据。

本任务未运行完整自动 `scripts/agent-e2e.sh --profile <profile>`，采用手动 bounded profile 证据：focused RTL TB + lint/build/contract + NEMU build + `rv64ssvnapot-p-napot` full-state difftest。原因是变更范围集中在 Sv39 PTE.N/Svnapot 语义，完整 profile 成本高且本任务已有目标测试闭环。
