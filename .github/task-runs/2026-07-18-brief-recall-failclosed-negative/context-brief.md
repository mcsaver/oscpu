# Agent Brief

- `recall_status`: failed
- `profile`: github-index

WARN context brief generation failed; profile dispatch is not green.

## Diagnostic

```text
# Agent Brief

- `ok`: false
- `recall_status`: failed
- `source`: live-or-stored
- `profile`: github-index
- `terms`: github-index brief-recall-failclosed-negative
- `token_estimate`: 0 / 1
- `error`: required paths exceed token budget: .github/AGENTS.md, .github/e2e/profiles/github-index.tsv; no independent primary focus match outside required/core/profile/optional paths: github-index brief-recall-failclosed-negative

## Profile Suggestions
- `github-index` score=22 matched=github-index, requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `contracts` score=1 matched=github-index command=`scripts/agent-e2e.sh --profile contracts`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

## Chunks

```
