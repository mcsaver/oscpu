# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-github-index-shim-guard-final
- `task_slug`: github-index-shim-guard-final
- `profile`: github-index
- `asset_count`: 2
- `total_size_bytes`: 42997

## 证据资产

### .github/task-runs/2026-06-13-github-index-shim-guard-final/evidence/github-index-contract.log

- `kind`: log
- `size_bytes`: 42724
- `line_count`: 1127
- `sha256`: 4ae4b01dd456fb7b747bb2ef457724e1349035c56bf33d91ea278d3f6c2887cb
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:54:36+00:00
- `markers`: {"FAIL": 2, "PASS": 166, "WARN": 24, "symbolic": ["__DEMO_MARKER__"]}
- `summary`: log evidence; size=42724 bytes; lines=1127; FAIL=2; WARN=24; PASS=166; symbolic=__DEMO_MARKER__; tail=[github-index] contract PASS scripts/github_index_db.py PASS scripts/dev_memory/core.py PASS scripts/dev_memory/queries.py PASS scripts/dev_memory/api.py PASS scripts/dev_memory/maintenance.py PASS scripts/dev_memory/cli.py PASS scripts/dev_memory/__main__....

### .github/task-runs/2026-06-13-github-index-shim-guard-final/nodes.tsv

- `kind`: tsv
- `size_bytes`: 273
- `line_count`: 1
- `sha256`: 62ed1fb7a941a4d019cf5659aa1d0b0999dbe794d9382c557459833c26502da1
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:54:36+00:00
- `markers`: {"PASS": 2}
- `summary`: tsv evidence; size=273 bytes; lines=1; PASS=2; tail=github-index-contract agent-system github-index PASS scripts/github_index_db.py + .github files SQLite index can build, query and doctor .github metadata without owning originals .github/task-runs/2026-06-13-github-index-shim-guard-final/evidence/github-ind...
