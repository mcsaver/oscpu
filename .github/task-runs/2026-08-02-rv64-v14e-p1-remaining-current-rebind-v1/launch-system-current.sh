#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
runner="${task_run_dir}/run-system-current.sh"
summary_builder="${task_run_dir}/build-system-current-summary.py"
run_label="${V14E_SYSTEM_RUN_LABEL:-rootfs-093c2380-systemd-strict-6b-v14e-a2}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
runtime_dir="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict/${run_label}"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
status_helper="${repo_root}/scripts/task-run-status.sh"
expected_design_id="${V14E_SYSTEM_EXPECTED_DESIGN_ID:-sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488}"
expected_file_count="${V14E_SYSTEM_EXPECTED_FILE_COUNT:-146}"
host_timeout_seconds="${V14E_SYSTEM_HOST_TIMEOUT_SECONDS:-100000}"
max_cycles="${V14E_SYSTEM_MAX_CYCLES:-6000000000}"
commit_gap_limit_cycles="${V14E_SYSTEM_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V14E_SYSTEM_PROGRESS_INTERVAL:-5000000}"
validate_only="${V14E_SYSTEM_LAUNCH_VALIDATE_ONLY:-0}"

case "${run_label}" in
  *[!A-Za-z0-9._-]*|"")
    printf '%s\n' "[V14E-SERIALIZE-SYSTEM-LAUNCH] invalid run label: ${run_label}" >&2
    exit 2
    ;;
esac

for command_name in flock setsid nohup bash python3; do
  command -v "${command_name}" >/dev/null
done
test -x "${runner}"
test -s "${summary_builder}"
test -f "${status_helper}"
[[ "${validate_only}" == "0" || "${validate_only}" == "1" ]]
mkdir -p "$(dirname -- "${lock_path}")"

validate_contract() {
  bash -n "${runner}"
  bash -n "${task_run_dir}/launch-system-current.sh"
  bash "${repo_root}/scripts/tests/test-task-run-status.sh"
  python3 -B "${summary_builder}" --self-test
  python3 -B "${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py"
  python3 -B "${repo_root}/Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
  python3 -B "${repo_root}/Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
  python3 -B "${repo_root}/npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"
  [[ "${expected_design_id}" =~ ^sha256:[0-9a-f]{64}$ ]]
  [[ "${expected_file_count}" =~ ^[0-9]+$ ]]
  [[ "${max_cycles}" =~ ^[0-9]+$ ]]
  (( expected_file_count > 0 ))
  (( max_cycles >= 6000000000 ))
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-PRELAUNCH] status=PASS checker_suites=5"
}

publish_launcher_failure() {
  local launcher_rc="${1:?launcher return code is required}"
  local launcher_stage="${2:?launcher stage is required}"
  local finalize_rc=0

  source "${status_helper}"
  task_run_status_init "${status_path}"
  task_run_status_stage "${launcher_stage}"
  set +e
  task_run_status_finalize "${launcher_rc}" 0
  finalize_rc=$?
  set -e
  return "${finalize_rc}"
}

if [[ -e "${status_path}" || -e "${result_dir}" || -e "${runtime_dir}" ]]; then
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] label/runtime already exists: ${run_label}" >&2
  exit 2
fi
if ! flock -n "${lock_path}" true; then
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] another RV64 engineering run owns ${lock_path}" >&2
  exit 3
fi

if [[ "${validate_only}" == "1" ]]; then
  validate_contract
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] validation PASS label=${run_label}"
  exit 0
fi

mkdir -p "${result_dir}"
set +e
validate_contract >"${result_dir}/prelaunch-contract.log" 2>&1
contract_rc=$?
set -e
if [[ "${contract_rc}" -ne 0 ]]; then
  set +e
  publish_launcher_failure "${contract_rc}" "launcher-contract"
  publish_rc=$?
  set -e
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] contract failed rc=${publish_rc}" >&2
  exit "${publish_rc}"
fi

{
  printf '%s\n' "schema=rv64-v14e-system-current-launch-v1"
  printf 'run_label=%s\n' "${run_label}"
  printf 'runner=%s\n' "${runner}"
  printf 'runtime_dir=%s\n' "${runtime_dir}"
  printf 'lock_path=%s\n' "${lock_path}"
  printf 'expected_design_id=%s\n' "${expected_design_id}"
  printf 'expected_file_count=%s\n' "${expected_file_count}"
  printf 'max_cycles=%s\n' "${max_cycles}"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'commit_gap_limit_cycles=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf '%s\n' "session_mode=setsid-no-tty"
  printf '%s\n' "stdin=dev-null"
  printf '%s\n' "prelaunch_contract=PASS"
} >"${result_dir}/launch-binding.txt"
date -Ins >"${result_dir}/launched-at.txt"

nohup setsid env \
  V14E_SYSTEM_RUN_LABEL="${run_label}" \
  V14E_SYSTEM_EXPECTED_DESIGN_ID="${expected_design_id}" \
  V14E_SYSTEM_EXPECTED_FILE_COUNT="${expected_file_count}" \
  V14E_SYSTEM_MAX_CYCLES="${max_cycles}" \
  V14E_SYSTEM_HOST_TIMEOUT_SECONDS="${host_timeout_seconds}" \
  V14E_SYSTEM_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
  V14E_SYSTEM_PROGRESS_INTERVAL="${progress_interval}" \
  flock -n -E 73 "${lock_path}" "${runner}" \
  >"${result_dir}/launcher.log" 2>&1 </dev/null &
launcher_pid=$!
printf '%s\n' "${launcher_pid}" >"${result_dir}/launcher.pid"

for _ in $(seq 1 300); do
  if [[ -s "${status_path}" ]]; then
    break
  fi
  if ! kill -0 "${launcher_pid}" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ ! -s "${status_path}" ]]; then
  launcher_rc=0
  if kill -0 "${launcher_pid}" 2>/dev/null; then
    kill -TERM -- "-${launcher_pid}" 2>/dev/null || \
      kill -TERM "${launcher_pid}" 2>/dev/null || true
    set +e
    wait "${launcher_pid}"
    set -e
    launcher_rc=124
  else
    set +e
    wait "${launcher_pid}"
    launcher_rc=$?
    set -e
    [[ "${launcher_rc}" -ne 0 ]] || launcher_rc=4
  fi
  set +e
  publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"
  publish_rc=$?
  set -e
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] runner did not publish status; FAIL rc=${publish_rc}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit "${publish_rc}"
fi

status_text="$(sed -n '1p' "${status_path}")"
if [[ "${status_text}" != "RUNNING" ]]; then
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM-LAUNCH] initial status is ${status_text}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit 5
fi

printf '%s\n' \
  "[V14E-SERIALIZE-SYSTEM-LAUNCH] RUNNING label=${run_label} launcher_pid=${launcher_pid}"
