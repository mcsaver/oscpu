#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/db-audits.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${status_path}"
}
trap finish EXIT

python3 scripts/github_index_db.py audit-db-first \
  >"${run_root}/audit-db-first.log" 2>&1
python3 scripts/github_index_db.py audit-markdown-coverage \
  --fail-on-live-evidence \
  >"${run_root}/audit-markdown-coverage.log" 2>&1
python3 scripts/github_index_db.py artifact-audit \
  >"${run_root}/artifact-audit-global.log" 2>&1

printf '%s\n' '[V11R-DB-AUDITS][PASS]'
