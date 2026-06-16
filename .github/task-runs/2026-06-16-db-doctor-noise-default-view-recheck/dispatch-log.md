# Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`。
- 读取 `.github/memory/modules/agent-system.md`、`.github/instructions/agent-e2e-workflow.instructions.md`、`.github/e2e/README.md`、`.github/e2e/modules/github-index.md`。

## PLAN

- 复核默认 `doctor`/`audit-db-first` 是否仍显示历史 drift。
- 检查 `scripts/dev_memory` 与 `github-index` e2e 合同是否已固定显式诊断开关。
- 刷新 live-first 规则文档索引，消除 verbose 里的索引缓存 stale。
- 同步 memory、stored DB 与 snapshot。

## VERIFY

- `python3 scripts/github_index_db.py doctor --fail-on-drift`：PASS，`blocking_drift=0`。
- `python3 scripts/github_index_db.py doctor --fail-on-drift --show-nonblocking-drift`：PASS，刷新索引后 `nonblocking_drift=0`。
- `python3 scripts/github_index_db.py audit-db-first`：PASS。
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`：PASS。
- `python3 -m py_compile scripts/dev_memory/maintenance.py scripts/dev_memory/cli.py scripts/dev_memory/core.py scripts/github_index_db.py`：PASS。
- `bash -n scripts/e2e/modules/github_index.sh scripts/agent-e2e.sh`：PASS。
- `scripts/agent-e2e.sh --list-profiles`：PASS，包含 `github-index`。
- `scripts/agent-e2e.sh --validate-profile --profile github-index`：PASS。
- `git diff --check -- scripts/dev_memory/maintenance.py scripts/dev_memory/cli.py scripts/e2e/modules/github_index.sh .github/e2e/modules/github-index.md .github/memory/project-status.md .github/memory/modules/agent-system.md`：PASS。

## RECORD

- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/agent-system.md`。
- 执行 `update-stored` 同步两份 memory。
- 执行 `snapshot-stored --backup-dir .github/db-backup/stored-snapshot --yes`。
