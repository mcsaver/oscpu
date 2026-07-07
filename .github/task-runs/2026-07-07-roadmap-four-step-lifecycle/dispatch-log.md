# Dispatch Log

- 复核 ROADMAP 的 2026-07-06 “四步”待办，发现其中 NEMU CSR/priv、CSR+priv+FPR full-state difftest、Svnapot 对齐已由历史工程完成。
- 复核 `tool/` 后发现剩余真实代码缺口：`tool/kconfig/Makefile` 与 `tool/fixdep/Makefile` 仍 include `$(NEMU_HOME)/scripts/build.mk`；在空 `NEMU_HOME` 下 `make -C tool/kconfig` 会失败。
- 新增 `scripts/build.mk` 作为工作区级通用工具构建模板，并把 `tool/kconfig`、`tool/fixdep` 切到 `$(YSYX_HOME)/scripts/build.mk`。
- 同步更新 `scripts/README.md`，说明 `scripts/build.mk` 是工作区工具模板，不承载 NEMU 专有构建语义。
- 更新 `npc/rv64/design/arch/ROADMAP.md`，把四步护栏链标为完成，并把下一步切到 B7 flag-ON 前置验证。
- 更新 `npc/rv64/design/arch/serialize-at-retire.md`，移除“CSR difftest 盲区”过期叙述，保留 Linux smoke 与 `-v-`/full-state difftest 风险边界。
- 更新 NPC/NEMU difftest 注释，使 CSR snapshot/比较列表描述和当前 `kCsrCmpList` 事实一致。
- 更新 project-status、npc/nemu/difftest memory，并生成本 task-run 证据包。
