#!/usr/bin/env bash
set -u -o pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
status_path="${run_root}/index-evidence.status"

printf 'RUNNING\n' >"${status_path}"
python3 scripts/github_index_db.py index-evidence \
  "${run_root}" \
  --write-index \
  --yes \
  >"${run_root}/index-evidence.stdout.log" \
  2>"${run_root}/index-evidence.stderr.log"
rc=$?
if [[ ${rc} -eq 0 ]]; then
  printf 'PASS rc=0\n' >"${status_path}"
else
  printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
fi
exit "${rc}"
