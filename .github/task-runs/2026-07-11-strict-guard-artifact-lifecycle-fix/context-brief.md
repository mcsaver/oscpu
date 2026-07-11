# Context Brief

- `task`: 修复 strict guard 的 agent-system evidence 缺口
- `root_cause`: tracked raw evidence 超过 1 MiB；profile 本身未坏
- `offending_path`: `.github/task-runs/2026-07-11-knife-b2-s2s3/evidence/topo40.rpt`
- `size_bytes`: 1650168
- `sha256`: `f2b292686adef90056a7fe0ea7977d6a0085d98a7d5aa9cf0c3b346ffe10d512`
- `source_commit`: `757437e9db207f76ad4675dee8063dce73024383`
- `contract_limit`: 1048576 bytes
- `fix_strategy`: index first, `git rm --cached`, keep ignored raw payload in place
- `non_goals`: 不改 RTL、不改阈值、不删除历史报告内容

## DB recall

- `command`: `python3 scripts/github_index_db.py brief "artifact-audit topo40 evidence archive strict guard" --profile agent-system --max-tokens 1600`
- `source`: live-or-stored
- `profile`: agent-system
- `token_estimate`: 1243 / 1600
