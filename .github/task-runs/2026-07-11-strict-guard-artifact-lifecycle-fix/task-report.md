# Task Report

- `task_id`: 2026-07-11-strict-guard-artifact-lifecycle-fix
- `task_slug`: strict-guard-artifact-lifecycle-fix
- `profile`: manual-corrective
- `validation_profiles`: agent-system, npc-dev
- `status`: completed
- `method`: systematic-debugging + TDD red/green
- `scope`: evidence lifecycle only
- `rtl_behavior_change`: false

## Result

- 旧 run 的三份 raw evidence 已建立 DB/index-only 记录；legacy/manual run 未伪造 e2e manifest。
- 超限 `topo40.rpt` 仅从 Git index 解除跟踪；本地文件仍在且命中 ignore，SHA-256 未变。
- 全局及 fresh-run artifact audit、fresh-run trace audit、DB lifecycle audits 均 PASS。
- fresh `agent-system` 9/9 与 `npc-dev` 5/5 completed；strict guard required profiles 2/2 PASS。
- 没有修改阈值、ignore 合同、旧失败报告或 DUT RTL 行为。

## Evidence boundary

本报告是手工 corrective maintenance 摘要，不作为 profile evidence。strict guard 使用的真实
profile task-runs 分别是 `2026-07-11-strict-guard-runtime-artifact-boundary` 与
`2026-07-11-strict-guard-artifact-fix-npc-dev`。
