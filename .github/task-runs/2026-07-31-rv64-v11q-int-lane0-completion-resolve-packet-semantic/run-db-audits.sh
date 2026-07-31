#!/usr/bin/env bash
set -euo pipefail

run_id="2026-07-31-rv64-v11q-int-lane0-completion-resolve-packet-semantic"
evidence_root=".github/task-runs/${run_id}/evidence"

python3 scripts/github_index_db.py audit-db-first \
  > "${evidence_root}/audit-db-first.log" 2>&1
python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence \
  > "${evidence_root}/audit-markdown-coverage.log" 2>&1
python3 scripts/github_index_db.py artifact-audit \
  > "${evidence_root}/artifact-audit-global.log" 2>&1

printf '%s\n' '[V11Q-DB-AUDITS][PASS]'
