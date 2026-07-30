#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
runner="${run_dir}/run-current-design-evidence-replay.sh"
tmp_dir="$(mktemp -d)"

cleanup() {
  local rc=$?
  rm -rf -- "${tmp_dir}"
  exit "${rc}"
}
trap cleanup EXIT

for test_point in pre-init active-stage; do
  for signal_case in HUP:129 INT:130 TERM:143; do
    signal_name="${signal_case%%:*}"
    expected_rc="${signal_case##*:}"
    case_dir="${tmp_dir}/${test_point}-${signal_name}"
    task_status="${case_dir}/task-run.status"
    replay_status="${case_dir}/replay.status"
    driver_log="${case_dir}/driver.log"
    evidence_dir="${case_dir}/stage-logs"
    stdout_log="${case_dir}/stdout.log"
    expected_stage="status-test-${test_point}"

    mkdir -p "${case_dir}"
    printf '%s\n' 'PASS' > "${task_status}"
    printf '%s\n' \
      'state=PASS' \
      'stage=stale-complete' \
      'detail=stale-pass-must-be-overwritten' > "${replay_status}"

    set +e
    V10C_ATTEMPT=91 \
    V10C_START_STAGE=closed-evidence-currentness \
    V10C_TASK_STATUS_PATH_OVERRIDE="${task_status}" \
    V10C_REPLAY_STATUS_PATH_OVERRIDE="${replay_status}" \
    V10C_DRIVER_LOG_OVERRIDE="${driver_log}" \
    V10C_EVIDENCE_DIR_OVERRIDE="${evidence_dir}" \
    V10C_STATUS_TEST_POINT="${test_point}" \
    V10C_STATUS_TEST_SIGNAL="${signal_name}" \
      bash "${runner}" > "${stdout_log}" 2>&1
    actual_rc=$?
    set -e

    [[ "${actual_rc}" -eq "${expected_rc}" ]]
    grep -Fx \
      "FAIL rc=${expected_rc} stage=${expected_stage} evidence_complete=0 cleanup_rc=0 signal=${signal_name}" \
      "${task_status}" >/dev/null
    grep -Fx 'state=FAIL' "${replay_status}" >/dev/null
    grep -Fx "stage=${expected_stage}" "${replay_status}" >/dev/null
    grep -Fx \
      "detail=rc=${expected_rc};evidence_complete=0;cleanup_rc=0;signal=${signal_name}" \
      "${replay_status}" >/dev/null
    grep -F \
      "[V10C-STATUS-SELFTEST][SIGNAL] point=${test_point} signal=${signal_name}" \
      "${stdout_log}" >/dev/null
    if grep -F '[V10C-REPLAY][PASS]' "${stdout_log}" >/dev/null; then
      printf '[V10C-STATUS-TEST][FAIL] signal case published PASS point=%s signal=%s\n' \
        "${test_point}" "${signal_name}" >&2
      exit 1
    fi
  done
done

printf '%s\n' \
  '[V10C-STATUS-TEST][PASS] stale PASS overwritten for pre-init/active-stage HUP/INT/TERM'
