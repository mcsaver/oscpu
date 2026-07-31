#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/v11jk-rebind-current.status"

finish() {
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"

python3 npc/rv64/testbench/scripts/run_v11j_bridge_holder_semantic.py \
  --result-dir "${run_root}/evidence/v11j-bridge-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11k_miq_holder_semantic.py \
  --result-dir "${run_root}/evidence/v11k-miq-rebind-current" --overwrite
