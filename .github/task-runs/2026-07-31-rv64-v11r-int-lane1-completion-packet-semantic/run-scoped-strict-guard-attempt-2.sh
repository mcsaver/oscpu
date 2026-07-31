#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
e2e_run=.github/task-runs/2026-07-31-OooIntBackend-integer-EX1-packet-lane1-V11R
status_path="${run_root}/scoped-strict-guard-attempt-2.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${status_path}"
}
trap finish EXIT

scripts/agent-e2e.sh --guard --guard-mode strict \
  --paths-file "${run_root}/guard-paths.txt" \
  --evidence-dir "${e2e_run}"
