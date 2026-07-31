#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/combined-semantic-gate-attempt-1"
status_path="${attempt_root}/runner.status"
stdout_path="${attempt_root}/stdout.log"
stderr_path="${attempt_root}/stderr.log"

mkdir -p "${attempt_root}"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${attempt_root}/runner.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"
make -C npc/rv64 check-producer-holder-semantic-coverage \
  >"${stdout_path}" 2>"${stderr_path}"
