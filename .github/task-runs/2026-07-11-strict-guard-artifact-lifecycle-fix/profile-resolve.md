# Profile Resolve

- `source`: live-or-stored profile catalog
- `strict_guard_required_profiles`: 2
- `agent-system`: 9 nodes；fresh run `2026-07-11-strict-guard-runtime-artifact-boundary`
- `npc-dev`: 5 nodes；fresh run `2026-07-11-strict-guard-artifact-fix-npc-dev`
- `selection_reason`: 本轮同时触碰 agent-system 文档/DB 生命周期与 `npc/rv64` 文档；两类 evidence 都必须晚于对应变更。

两个 profile 均先通过 `--validate-profile`，再以 `--stop-on-fail` 生成 completed task-run。
