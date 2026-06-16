# Task Report: DB Materialize Live First

- `run_id`: 2026-06-15-db-materialize-live-first
- `profile`: agent-system
- `status`: completed
- `final_result`: pass
- `summary`: 用户希望把数据库内容全部解压回原文件，并只让数据库保存固定格式 memory/log。本轮已将所有 stored documents 物化回原路径，并把非 memory/log 文档解除 DB ownership。

## Result

- `materialize`: 2349 documents materialized, 102 non-retained stored documents pruned.
- `retained_db`: DB 仅保留 `.github/memory/**` 与 `.github/task-runs/**` 日志/报告类 stored documents。
- `live_first`: agent、instruction、e2e profile/module、contract、说明文档和 skill 均回到 live 文件。
- `api`: `profiles`、`resolve-profile`、`brief` 已支持 live-or-stored fallback。
- `archive_policy`: `archive-markdown` 默认保留 live Markdown，`update-stored` 默认同步写回原文件。

## Verification

- `py_compile`: PASS
- `bash -n`: PASS
- `json parse`: PASS
- `audit-db-first`: PASS, candidates=2247, stored=2247, materialized=2247, shims=0
- `audit-markdown-coverage --fail-on-live-evidence`: PASS, active_md=2311, db_owned=2247, shims=0
- `schema-audit`: PASS
- `policy-audit`: PASS, agents=18 live indexed agents
- `report-audit`: PASS
- `artifact-audit`: PASS
- `delivery-audit`: PASS
- `branch-health-audit`: PASS
- `trace-audit`: PASS
- `skill-audit`: PASS
- `profiles` / `resolve-profile` / `brief`: PASS, source=live-or-stored

## Boundary

Full `rebuild` exceeded the current interactive budget twice after large task-run materialization. The leftover rebuild process was stopped; current DB health was verified through `stat`, targeted refresh, retained audits, and key live-or-stored query commands.
