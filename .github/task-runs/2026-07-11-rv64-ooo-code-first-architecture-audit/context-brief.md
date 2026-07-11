# Context Brief

- `task`: RV64 OoO 代码优先架构审计与 Markdown 后验对照
- `scope`: `npc/rv64` core/frontend/backend/memory/control/bus + current docs + regression/STA
- `code_snapshot`: `cab1814b0622e53e1e62f2b0fc17ed6873c72ba2`
- `method`: phase-1 code blind -> frozen baseline -> directed tests -> phase-2 docs comparison -> reviewer downgrade
- `primary_output`: `audit-results/2026-07-11-rv64-ooo-blind/05_FINAL_ARCHITECTURE_ASSESSMENT.txt`
- `comparison_output`: `audit-results/2026-07-11-rv64-ooo-blind/04_DOCUMENT_COMPARISON.txt`
- `no_rtl_change`: true
- `current_config_difftest`: disabled
- `existing_regression`: module 86/86; riscv-tests 177; AM PASS
- `current_sta`: WNS about -5.35ns; frontend/IFU next-PC path; non-signoff model

## Reviewer boundaries

- 非法 FP 最终 ROB 后果尚无整核波形。
- MIQ flush+pop 默认可达是高置信整链推断；MIQ full+pop 在当前默认整核不可达。
- 普通 FENCE 可观察差异需 RVWMO/多 observer litmus。
- 设备读取时机/lane 副作用需 bridge+xbar+device 联测。
- dated snapshot/task-run 不按 current spec 评价。
