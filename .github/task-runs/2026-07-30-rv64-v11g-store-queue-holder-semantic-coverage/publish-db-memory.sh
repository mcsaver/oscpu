#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_rel=".github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage"

cd "${repo_root}"

documents=(
  "${task_run_rel}/contract.md"
  "${task_run_rel}/rtl-derivation.md"
  "${task_run_rel}/completion-definition.md"
  "${task_run_rel}/dispatch-log.md"
  "${task_run_rel}/pre-review-result.md"
  "${task_run_rel}/implementation-review.md"
  "${task_run_rel}/task-report.md"
  "${task_run_rel}/evidence-index.md"
  "${task_run_rel}/final-reviewer-report.md"
  ".github/memory/project-status.md"
  ".github/memory/modules/npc.md"
)

for document in "${documents[@]}"; do
  python3 scripts/github_index_db.py update-stored \
    "${document}" \
    --from-file "${document}"
done

python3 scripts/github_index_db.py snapshot-stored --yes
python3 scripts/github_index_db.py audit-db-first
python3 scripts/github_index_db.py audit-markdown-coverage
python3 scripts/github_index_db.py runtime-artifact-audit
