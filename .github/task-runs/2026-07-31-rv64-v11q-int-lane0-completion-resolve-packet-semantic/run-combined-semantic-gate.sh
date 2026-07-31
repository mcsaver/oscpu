#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_root="${repo_root}/.github/task-runs/2026-07-31-rv64-v11q-int-lane0-completion-resolve-packet-semantic"
log_path="${run_root}/evidence/combined-semantic-gate.log"
status_path="${run_root}/combined-semantic-gate.status"

printf 'RUNNING\n' >"${status_path}"
cd "${repo_root}" || exit 2

make -C npc/rv64 check-producer-holder-semantic-coverage \
  >"${log_path}" 2>&1
rc=$?

if [[ ${rc} -eq 0 ]]; then
  printf 'PASS rc=0\n' >"${status_path}"
else
  printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
fi
exit "${rc}"
