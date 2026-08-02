#!/usr/bin/env bash

v14c_run_logged() {
  local stage=$1
  local log=$2
  shift 2
  task_run_status_stage "${stage}"
  mkdir -p "$(dirname "${log}")"
  if "$@" >"${log}" 2>&1; then
    printf '[V14C-P0-CURRENT-BIND] stage=%s status=PASS log=%s\n' \
      "${stage}" "${log#${repo_root}/}"
    return 0
  else
    local rc=$?
    printf '[V14C-P0-CURRENT-BIND] stage=%s status=FAIL rc=%s log=%s\n' \
      "${stage}" "${rc}" "${log#${repo_root}/}" >&2
    tail -n 80 "${log}" >&2 || true
    return "${rc}"
  fi
}
