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

hup_status="${tmp_dir}/hup.status"
set +e
(
  set -euo pipefail
  source "${status_helper}"

  finish_hup_case() {
    local command_rc=$?
    local final_rc

    trap - EXIT HUP INT TERM
    set +e
    task_run_status_finalize "${command_rc}" 0
    final_rc=$?
    exit "${final_rc}"
  }

  task_run_status_init "${hup_status}"
  task_run_status_stage "systemd-guest"
  trap finish_hup_case EXIT
  task_run_status_install_signal_traps
  kill -HUP "${BASHPID}"
  task_run_status_mark_evidence_complete
)
hup_rc=$?
set -e
[[ "${hup_rc}" -eq 129 ]]
expect_status \
  "${hup_status}" \
  '^FAIL rc=129 stage=systemd-guest evidence_complete=0 cleanup_rc=0 signal=HUP$'

printf '%s\n' \
  "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, and HUP"
