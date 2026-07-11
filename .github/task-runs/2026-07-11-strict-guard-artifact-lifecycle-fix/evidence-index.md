# Evidence Index

## Scope

- `task_id`: 2026-07-11-strict-guard-artifact-lifecycle-fix
- `kind`: manual corrective maintenance
- `rtl_behavior_change`: false
- `contract_limit_bytes`: 1048576

## Root cause

唯一失败资产是历史 raw STA 报告 `topo40.rpt`：1,650,168 bytes、9,074 lines、
SHA-256 `f2b292686adef90056a7fe0ea7977d6a0085d98a7d5aa9cf0c3b346ffe10d512`，
来源 commit `757437e9db207f76ad4675dee8063dce73024383`。其 runtime 路径早已被
`.gitignore` 覆盖，但该提交仍把文件强制纳入 Git，因此触发 source/runtime 边界合同。

## Lifecycle closure

- 旧 run 的三份 raw evidence 已通过 `index-evidence --write-index` 登记；DB readback 为
  `assets=3`、`total_size_bytes=2629949`。
- 派生 `evidence-index.md` 与既有 `task-report.md` 已通过 `archive-markdown` 归档。
- legacy/manual run 没有原始 e2e manifest；本轮未伪造 manifest。
- `git rm --cached` 只解除超限报告的 current source tracking。本地 raw 文件仍存在、
  命中 `.gitignore:101`，解除前后 SHA-256 不变。
- 当前 cached diff 保留了用户已有的架构快照 rename；未 reset 或覆盖。

## RED / GREEN

| Gate | RED | GREEN |
| --- | --- | --- |
| global `artifact-audit` | exit 1；唯一错误为 1,650,168 > 1,048,576 | PASS；`tracked_runtime_files=5666`、`tracked_heavy_files=0` |
| `agent-system` | 旧 run 被同一 artifact audit 阻断 | fresh run completed；9 nodes |
| `npc-dev` | 旧证据早于后续文档修改 | fresh run completed；5 nodes |
| strict guard | exit 1；缺 agent-system completed evidence | PASS；`required_profiles=2`，两项均 PASS |
| fresh run artifact audit | 未执行 | PASS；manifest assets 10、DB assets 11 |
| fresh run trace audit | 未执行 | PASS；trace nodes 9、evidence assets 11 |
| DB lifecycle audits | 未执行 | `audit-db-first` 与 markdown coverage 均 PASS |

## Fresh profile evidence

- `2026-07-11-strict-guard-runtime-artifact-boundary`: profile `agent-system`，status `completed`。
- `2026-07-11-strict-guard-artifact-fix-npc-dev`: profile `npc-dev`，status `completed`。

## Non-fixes intentionally rejected

没有调高 1 MiB 阈值、添加 ignore 豁免、截断/删除/搬移 raw 报告、改写旧失败报告，
也没有把 legacy/manual run 冒充完整 e2e run。
