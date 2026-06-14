# Operations

## Daily Check

```bash
scripts/agent-maintain.sh --mode check
```

## Before Delivery

```bash
python3 scripts/github_index_db.py delivery-audit
scripts/package-ai-dev-env.sh
python3 scripts/github_index_db.py delivery-audit
scripts/agent-e2e.sh --profile agent-system --task-slug commercial-delivery-smoke
```

## Memory Update Rule

- 新的长期事实写入 `.github/memory/project-status.md` 和相关 module memory。
- DB-backed 文档必须通过 `update-stored --refresh-shim` 写回。
- 跨层任务必须生成 `.github/task-runs/<run_id>/` 证据包。

## Archive Rule

- 旧手工产物进入 `.github/archive/legacy-ai-dev-env-2026-06-13/`。
- `.github/task-runs` 不硬搬；用 DB/API 查询历史 run。
- 大体积运行态 payload 进入 `.github/runtime-artifacts` 或外部 object store。
