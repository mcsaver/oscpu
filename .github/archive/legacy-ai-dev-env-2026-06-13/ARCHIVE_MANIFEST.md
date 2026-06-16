# Legacy AI Dev Environment Archive

- `created_at`: 2026-06-13
- `reason`: 将旧手工交付包和手工 e2e 调试产物从 active workspace 移出，保留为可追溯备份。
- `active_replacement`: `deliverables/ai-dev-env-commercial-v1/`

## Moved Roots

| old path | archived path | reason |
| --- | --- | --- |
| `outputs/` | external artifact，见 `POINTERS.md` | 2026-05-28 手工便携包、PPT、runtime probe 等旧交付草稿，不能继续作为新版 active deliverable。 |
| `.github/e2e/_manual/` | external artifact，见 `POINTERS.md` | 手工 e2e 调试日志和 dry-run 产物，不属于标准 task-run/DB-backed evidence 链路。 |

## Retention Notes

- `.github/task-runs/` 未移动：这些目录属于 DB-backed evidence surface，移动会破坏 `runs/evidence/audit-db-first` 的路径契约。
- 新版本只通过 `run-manifest.json`、`evidence-index.md` 和 `evidence_assets` 索引回查历史 task-run。
- Git 中只保留 `ARCHIVE_MANIFEST.md`、`CHECKSUMS.txt`、`POINTERS.md`；旧实体 payload 进入 `dist/archive/`、release artifact 或对象存储。
- 需要恢复旧手工包时，从外部 artifact 复制对应子树；不要把它重新作为 active `outputs/` 发布面。
