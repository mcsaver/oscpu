#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/selected-tb-rebind.status"

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

python3 npc/rv64/testbench/scripts/run_v11l_memory_retry_holder_semantic.py \
  --result-dir "${run_root}/evidence/v11l-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11m_memory_reservation_holder_semantic.py \
  --result-dir "${run_root}/evidence/v11m-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11n_memory_pending_holder_semantic.py \
  --result-dir "${run_root}/evidence/v11n-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11o_memory_buffer_token_semantic.py \
  --result-dir "${run_root}/evidence/v11o-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11p_checkpoint_irrevocable_write_semantic.py \
  --result-dir "${run_root}/evidence/v11p-rebind-current" --overwrite
python3 npc/rv64/testbench/scripts/run_v11q_int_lane0_packet_semantic.py \
  --result-dir "${run_root}/evidence/v11q-rebind-current" --overwrite
