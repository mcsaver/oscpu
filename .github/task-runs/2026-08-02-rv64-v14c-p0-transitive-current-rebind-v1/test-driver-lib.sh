#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
temp_dir=$(mktemp -d /tmp/rv64-v14c-driver-test.XXXXXXXX)

cleanup() {
  local resolved
  resolved=$(realpath -m -- "${temp_dir}") || return 1
  if [[ "${resolved}" != /tmp/rv64-v14c-driver-test.* ]]; then
    printf '%s\n' "refusing unexpected driver-test cleanup: ${resolved}" >&2
    return 2
  fi
  rm -rf -- "${resolved}"
}
trap cleanup EXIT

task_run_status_stage() { :; }
source "${run_dir}/driver-lib.sh"

if v14c_run_logged "negative" "${temp_dir}/negative.log" \
  bash -c 'exit 17'; then
  printf '%s\n' "[V14C-DRIVER-SELF-TEST][FAIL] nonzero stage accepted" >&2
  exit 1
else
  rc=$?
fi
if [[ "${rc}" -ne 17 ]]; then
  printf '%s\n' "[V14C-DRIVER-SELF-TEST][FAIL] rc=${rc} expected=17" >&2
  exit 1
fi
v14c_run_logged "positive" "${temp_dir}/positive.log" \
  bash -c 'printf "%s\n" PASS' || exit $?
printf '%s\n' "[V14C-DRIVER-SELF-TEST][PASS] negative_rc=17 positive_rc=0"
