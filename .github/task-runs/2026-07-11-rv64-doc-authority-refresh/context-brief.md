# Context Brief

- `task`: 将 RV64 OoO 代码优先审计结论落实为 current docs 与 history archive
- `scope`: `npc/rv64` 文档入口、架构快照、六份关键 active spec、审计结果、DB memory
- `code_snapshot`: `cab1814b0622e53e1e62f2b0fc17ed6873c72ba2`
- `source_audit`: `audit-results/2026-07-11-rv64-ooo-blind/`
- `old_task_run`: `.github/task-runs/2026-07-11-rv64-ooo-code-first-architecture-audit/`（immutable）
- `new_current_authority`: `npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md`
- `archived_snapshot`: `npc/rv64/design/arch/history/rtl-ground-truth-2026-07-03.md`
- `no_rtl_behavior_change`: true

## Evidence correction

- 177 个官方 riscv-tests：逐项 PASS。
- AM cpu-tests：原始日志 58/59；`fp-difftest-probe` FAIL。
- module testbench：摘要写 86/86，但至少三份原始日志 FAIL 后仍被输出为 PASS。
- 当前 `.config` 未开启 Difftest；OpenSTA 数字不是布局布线后签核。

## Dirty-tree boundary

- 开工前已有 `.github/db-backup/task-runs/manifest.json` 与 `build/linux-logs/npc-linux.log` 修改。
- 开工前已有旧审计 task-run 与 `audit-results/` 未跟踪内容。
- 本任务不回退或覆盖上述无关/既有内容；只在审计结果中新增勘误并修正文档解释。

## DB recall

- `command`: `python3 scripts/github_index_db.py brief "rv64 ooo 文档 归档 current authority contract" --profile npc-dev --max-tokens 1200`
- `source`: live-or-stored
- `profile`: npc-dev
- `token_estimate`: 887 / 1200
- `profile_suggestion`: npc-dev（score 10，匹配 contract / rv64）
