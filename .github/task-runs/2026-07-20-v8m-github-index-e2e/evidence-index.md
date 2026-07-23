# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-v8m-github-index-e2e
- `task_slug`: db-first-stored-memory-audit
- `profile`: github-index
- `asset_count`: 2
- `total_size_bytes`: 80247

## 证据资产

### .github/task-runs/2026-07-20-v8m-github-index-e2e/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T21:48:44+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-20-v8m-github-index-e2e/evidence/github-index-contract.log

- `kind`: log
- `size_bytes`: 80159
- `line_count`: 1857
- `sha256`: 0b646a30481dbc4d6097760764c0fb1aec276689e59b99203864153438ef3052
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-19T21:48:44+00:00
- `markers`: {"FAIL": 2, "PASS": 174, "WARN": 22, "symbolic": ["__BRIEF_CANONICAL_REQUIRED__", "__BRIEF_PROFILE_REQUIRED__", "__DEMO_MARKER__"]}
- `summary`: log evidence; size=80159 bytes; lines=1857; FAIL=2; WARN=22; PASS=174; symbolic=__BRIEF_CANONICAL_REQUIRED__,__BRIEF_PROFILE_REQUIRED__,__DEMO_MARKER__; tail=��复和 memory 中写明豁免理由。 11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确允许路径、读写权限、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务不得使用写型命令、写文件或访问网络、账号、凭据和外部服务。 请直接打开 [`.g...
