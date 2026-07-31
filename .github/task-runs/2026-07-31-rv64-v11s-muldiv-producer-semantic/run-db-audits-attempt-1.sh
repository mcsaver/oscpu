#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
status_path="${run_root}/db-audits-attempt-1.status"

printf 'RUNNING\n' >"${status_path}"

finish() {
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

python3 scripts/github_index_db.py audit-db-first \
  >"${run_root}/audit-db-first-attempt-1.log" 2>&1
python3 scripts/github_index_db.py audit-markdown-coverage \
  --fail-on-live-evidence \
  >"${run_root}/audit-markdown-coverage-attempt-1.log" 2>&1
python3 scripts/github_index_db.py artifact-audit \
  >"${run_root}/artifact-audit-global-attempt-1.log" 2>&1

printf '%s\n' '[V11S-DB-AUDITS-A1][PASS]'
