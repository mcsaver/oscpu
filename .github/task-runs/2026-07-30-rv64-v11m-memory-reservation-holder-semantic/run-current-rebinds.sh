#!/usr/bin/env bash
set -uo pipefail

run_root=".github/task-runs/2026-07-30-rv64-v11m-memory-reservation-holder-semantic"
evidence_root="${run_root}/evidence"
bundle_status="${run_root}/current-rebinds.status"

run_stage() {
  local stage="$1"
  local runner="$2"
  local result_dir="$3"
  local driver_log="${result_dir}.driver.log"
  local driver_status="${result_dir}.status"

  printf 'RUNNING stage=%s\n' "${stage}" > "${bundle_status}"
  python3 "${runner}" --result-dir "${result_dir}" \
    > "${driver_log}" 2>&1
  local rc=$?
  printf '%s\n' "${rc}" > "${driver_status}"
  if [[ "${rc}" -ne 0 ]]; then
    printf 'FAIL stage=%s rc=%s\n' "${stage}" "${rc}" > "${bundle_status}"
    return "${rc}"
  fi
  printf 'PASS stage=%s rc=0\n' "${stage}" > "${bundle_status}"
}

run_stage \
  "v11j-bridge-holder" \
  "npc/rv64/testbench/scripts/run_v11j_bridge_holder_semantic.py" \
  "${evidence_root}/v11j-bridge-rebind-current-a3" || exit $?

run_stage \
  "v11k-miq-holder" \
  "npc/rv64/testbench/scripts/run_v11k_miq_holder_semantic.py" \
  "${evidence_root}/v11k-miq-rebind-current-a1" || exit $?

run_stage \
  "v11l-memory-retry-holder" \
  "npc/rv64/testbench/scripts/run_v11l_memory_retry_holder_semantic.py" \
  "${evidence_root}/v11l-memory-retry-rebind-current-a1" || exit $?

printf 'PASS stages=3 rc=0\n' > "${bundle_status}"
