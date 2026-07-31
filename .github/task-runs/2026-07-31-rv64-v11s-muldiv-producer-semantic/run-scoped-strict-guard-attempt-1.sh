#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
e2e_run=.github/task-runs/2026-07-31-OooMulDivUnit-producer-lifecycle-revtag-v11s
status_path="${run_root}/scoped-strict-guard-attempt-1.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${run_root}/scoped-strict-guard-attempt-1.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"
scripts/agent-e2e.sh --guard --guard-mode strict \
  --paths-file "${run_root}/guard-paths.txt" \
  --evidence-dir "${e2e_run}" \
  >"${run_root}/scoped-strict-guard-attempt-1.stdout.log" \
  2>"${run_root}/scoped-strict-guard-attempt-1.stderr.log"
