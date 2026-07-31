#!/usr/bin/env bash
set -uo pipefail

run_dir=".github/task-runs/2026-07-30-rv64-v11n-memory-pending-holder-semantic"
status_path="${run_dir}/semantic-gate.status"
log_path="${run_dir}/evidence/semantic-gate.log"

printf 'RUNNING\n' > "${status_path}"
set +e
make -C npc/rv64 check-producer-holder-semantic-coverage \
  > "${log_path}" 2>&1
rc=$?
set -e

if [[ ${rc} -eq 0 ]]; then
  printf 'PASS rc=0\n' > "${status_path}"
else
  printf 'FAIL rc=%d\n' "${rc}" > "${status_path}"
fi
exit "${rc}"
