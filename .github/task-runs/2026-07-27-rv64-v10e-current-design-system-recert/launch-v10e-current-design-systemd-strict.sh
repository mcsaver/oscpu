#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
runner="${task_run_dir}/run-v10e-current-design-systemd-strict.sh"
selftest="${task_run_dir}/test-runner-contract.py"
run_label="${V10E_RECERT_RUN_LABEL:-rootfs-5f9dd068-systemd-strict-6b-a4}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
status_helper="${repo_root}/scripts/task-run-status.sh"
validate_only="${V10E_RECERT_LAUNCH_VALIDATE_ONLY:-0}"

case "${run_label}" in
  *[!A-Za-z0-9._-]*|"")
    printf '%s\n' "[V10E-RECERT-LAUNCH] invalid run label: ${run_label}" >&2
    exit 2
    ;;
esac

command -v flock >/dev/null
command -v setsid >/dev/null
test -x "${runner}"
test -x "${selftest}"
test -f "${status_helper}"
[[ "${validate_only}" == "0" || "${validate_only}" == "1" ]]
mkdir -p "$(dirname -- "${lock_path}")"

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

if [[ -e "${status_path}" || -e "${result_dir}" ]]; then
  printf '%s\n' \
    "[V10E-RECERT-LAUNCH] result label already exists: ${run_label}" >&2
  exit 2
fi

if [[ "${validate_only}" == "1" ]]; then
  python3 "${selftest}"
  if ! flock -n "${lock_path}" true; then
    printf '%s\n' \
      "[V10E-RECERT-LAUNCH] another RV64 engineering run owns ${lock_path}" >&2
    exit 3
  fi
  printf '%s\n' \
    "[V10E-RECERT-LAUNCH] validation PASS label=${run_label}"
  exit 0
fi

mkdir -p "${result_dir}"
set +e
python3 "${selftest}" >"${result_dir}/prelaunch-contract.log" 2>&1
selftest_rc=$?
set -e
if [[ "${selftest_rc}" -ne 0 ]]; then
  set +e
  publish_launcher_failure "${selftest_rc}" "launcher-selftest"
  publish_rc=$?
  set -e
  printf '%s\n' \
    "[V10E-RECERT-LAUNCH] pre-launch contract failed rc=${publish_rc}" >&2
  exit "${publish_rc}"
fi
{
  printf 'run_label=%s\n' "${run_label}"
  printf 'runner=%s\n' "${runner}"
  printf 'lock_path=%s\n' "${lock_path}"
  printf '%s\n' "prelaunch_contract=PASS"
  printf '%s\n' "session_mode=setsid-no-tty"
  printf '%s\n' "stdin=/dev/null"
  printf 'max_cycles=%s\n' "${V10E_RECERT_MAX_CYCLES:-6000000000}"
  printf 'host_timeout_seconds=%s\n' \
    "${V10E_RECERT_HOST_TIMEOUT_SECONDS:-100000}"
  printf 'commit_gap_limit_cycles=%s\n' \
    "${V10E_RECERT_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
} >"${result_dir}/launch-binding.txt"
date -Ins >"${result_dir}/launched-at.txt"

nohup setsid env \
  V10E_RECERT_RUN_LABEL="${run_label}" \
  V10E_RECERT_MAX_CYCLES="${V10E_RECERT_MAX_CYCLES:-6000000000}" \
  V10E_RECERT_HOST_TIMEOUT_SECONDS="${V10E_RECERT_HOST_TIMEOUT_SECONDS:-100000}" \
  V10E_RECERT_COMMIT_GAP_LIMIT_CYCLES="${V10E_RECERT_COMMIT_GAP_LIMIT_CYCLES:-1000000}" \
  V10E_RECERT_PROGRESS_INTERVAL="${V10E_RECERT_PROGRESS_INTERVAL:-5000000}" \
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
    kill -TERM -- "-${launcher_pid}" 2>/dev/null ||
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
    if [[ "${launcher_rc}" -eq 0 ]]; then
      launcher_rc=4
    fi
  fi
  set +e
  publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"
  publish_rc=$?
  set -e
  printf '%s\n' \
    "[V10E-RECERT-LAUNCH] runner did not publish status; " \
    "recorded FAIL rc=${publish_rc}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit "${publish_rc}"
fi

status_text="$(sed -n '1p' "${status_path}")"
if [[ "${status_text}" != "RUNNING" ]]; then
  printf '%s\n' \
    "[V10E-RECERT-LAUNCH] unexpected initial status: ${status_text}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit 5
fi

printf '%s\n' \
  "[V10E-RECERT-LAUNCH] RUNNING label=${run_label} launcher_pid=${launcher_pid}"
