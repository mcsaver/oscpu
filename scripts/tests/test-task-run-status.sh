#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
status_helper="${repo_root}/scripts/task-run-status.sh"
tmp_dir="$(mktemp -d)"

cleanup() {
  local rc=$?
  rm -rf -- "${tmp_dir}"
  exit "${rc}"
}
trap cleanup EXIT

source "${status_helper}"

expect_status() {
  local status_path="${1:?status path is required}"
  local pattern="${2:?status pattern is required}"

  if ! grep -Eq "${pattern}" "${status_path}"; then
    printf '%s\n' "[task-run-status-test] unexpected status in ${status_path}" >&2
    sed -n '1,4p' "${status_path}" >&2
    return 1
  fi
}

success_status="${tmp_dir}/success.status"
task_run_status_init "${success_status}"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
expect_status "${success_status}" '^PASS$'

incomplete_status="${tmp_dir}/incomplete.status"
task_run_status_init "${incomplete_status}"
task_run_status_stage "systemd-guest"
set +e
task_run_status_finalize 0 0
incomplete_rc=$?
set -e
[[ "${incomplete_rc}" -eq 1 ]]
expect_status \
  "${incomplete_status}" \
  '^FAIL rc=1 stage=systemd-guest evidence_complete=0 cleanup_rc=0$'

command_fail_status="${tmp_dir}/command-fail.status"
task_run_status_init "${command_fail_status}"
task_run_status_stage "rtl-simulation"
set +e
task_run_status_finalize 7 0
command_fail_rc=$?
set -e
[[ "${command_fail_rc}" -eq 7 ]]
expect_status \
  "${command_fail_status}" \
  '^FAIL rc=7 stage=rtl-simulation evidence_complete=0 cleanup_rc=0$'

cleanup_fail_status="${tmp_dir}/cleanup-fail.status"
task_run_status_init "${cleanup_fail_status}"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
set +e
task_run_status_finalize 0 9
cleanup_fail_rc=$?
set -e
[[ "${cleanup_fail_rc}" -eq 9 ]]
expect_status \
  "${cleanup_fail_status}" \
  '^FAIL rc=9 stage=evidence-verified evidence_complete=1 cleanup_rc=9$'

pass_write_fail_status="${tmp_dir}/pass-write-fail.status"
task_run_status_init "${pass_write_fail_status}"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
_task_run_status_write() {
  local status_line="${1:?status line is required}"

  if [[ "${status_line}" == "PASS" ]]; then
    return 73
  fi
  printf '%s\n' "${status_line}" >"${TASK_RUN_STATUS_PATH}"
}
set +e
task_run_status_finalize 0 0
pass_write_fail_rc=$?
set -e
[[ "${pass_write_fail_rc}" -eq 73 ]]
expect_status \
  "${pass_write_fail_status}" \
  '^FAIL rc=73 stage=evidence-verified evidence_complete=1 cleanup_rc=0 status_write_rc=73$'
unset -f _task_run_status_write
source "${status_helper}"

for signal_case in HUP:129 INT:130 TERM:143; do
  signal_name="${signal_case%%:*}"
  signal_rc="${signal_case##*:}"
  signal_status="${tmp_dir}/${signal_name,,}.status"
  set +e
  (
    set -euo pipefail
    source "${status_helper}"

    finish_signal_case() {
      local command_rc=$?
      local final_rc

      trap - EXIT HUP INT TERM
      set +e
      task_run_status_finalize "${command_rc}" 0
      final_rc=$?
      exit "${final_rc}"
    }

    task_run_status_init "${signal_status}"
    task_run_status_stage "systemd-guest"
    trap finish_signal_case EXIT
    task_run_status_install_signal_traps
    kill -s "${signal_name}" "${BASHPID}"
    task_run_status_mark_evidence_complete
  )
  actual_signal_rc=$?
  set -e
  [[ "${actual_signal_rc}" -eq "${signal_rc}" ]]
  expect_status \
    "${signal_status}" \
    "^FAIL rc=${signal_rc} stage=systemd-guest evidence_complete=0 cleanup_rc=0 signal=${signal_name}$"
done

printf '%s\n' \
  "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM"
