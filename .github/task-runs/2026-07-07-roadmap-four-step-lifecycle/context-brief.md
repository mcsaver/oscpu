# Context Brief: roadmap four-step lifecycle

- 用户指出此前列出的下一步里有部分已经完成，要求执行 1/2/3/4，并注意相关文档生命周期。
- 已读取通用规范、doc-lifecycle 指令、project-status、known-issues 和相关模块 memory；本任务按“先复核真实状态，再改剩余缺口，再更新长期留档”的顺序执行。
- `python3 scripts/github_index_db.py brief roadmap kconfig difftest csr serialize --profile difftest`：建议 profile 为 `difftest`，并召回 difftest contract、agent 规范和相关 memory 入口；说明该任务必须带 difftest 证据。
- `python3 scripts/github_index_db.py brief roadmap kconfig difftest csr serialize --profile npc-dev`：建议 profile 为 `npc-dev`，并召回 NPC profile 入口；说明触碰 `npc/rv64` 设计文档和 RV64 构建边界需要 NPC 证据。
- `python3 scripts/github_index_db.py brief roadmap kconfig difftest csr serialize --profile agent-system`：建议 profile 为 `agent-system`，并召回 task-run/evidence/guard、WSL single-flight 与 `scripts/README.md` 相关规则。
- 人工复核结论：NEMU CSR/priv 正确性、NPC↔NEMU full-state difftest、Svnapot NPC/NEMU 对齐已由前序工程闭合；真实未闭合点是 `tool/kconfig` 与 `tool/fixdep` 自身仍反向 include `$(NEMU_HOME)/scripts/build.mk`。
- 生命周期边界：本任务关闭的是 ROADMAP 四步护栏链，不代表 B7 `OOO_CSR_QUEUE_HEAD` 默认翻 1；B7 仍需 full Linux boot、`-v-`/full-state difftest 和 glue TB CsrFile stub。
