#!/usr/bin/env bash

# task-run 状态必须由显式证据完成位授权；仅凭 EXIT 时的返回码不能写 PASS。
# 本文件供长时间 RV64 仿真、综合和系统回放 runner source，不主动安装 EXIT trap，
# 以便调用者先执行自身的配置恢复或其它清理动作。

TASK_RUN_STATUS_PATH=""
TASK_RUN_STATUS_STAGE="not-started"
TASK_RUN_STATUS_SIGNAL="none"
TASK_RUN_STATUS_EVIDENCE_COMPLETE=0

_task_run_status_write() {
  local status_line="${1:?status line is required}"
  local status_tmp

  [[ -n "${TASK_RUN_STATUS_PATH}" ]] || {
    printf '%s\n' "[task-run-status] status path is not initialized" >&2
    return 2
  }

  status_tmp="${TASK_RUN_STATUS_PATH}.tmp.$$"
  printf '%s\n' "${status_line}" >"${status_tmp}" || return
  mv -f -- "${status_tmp}" "${TASK_RUN_STATUS_PATH}"
}

task_run_status_init() {
  local status_path="${1:?status path is required}"

  TASK_RUN_STATUS_PATH="${status_path}"
  TASK_RUN_STATUS_STAGE="initialized"
  TASK_RUN_STATUS_SIGNAL="none"
  TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
  _task_run_status_write "RUNNING"
}

task_run_status_stage() {
  local stage="${1:?stage is required}"

  if [[ ! "${stage}" =~ ^[A-Za-z0-9._:-]+$ ]]; then
    printf '%s\n' "[task-run-status] invalid stage: ${stage}" >&2
    return 2
  fi
  TASK_RUN_STATUS_STAGE="${stage}"
}

task_run_status_mark_evidence_complete() {
  TASK_RUN_STATUS_EVIDENCE_COMPLETE=1
}

task_run_status_note_signal() {
  local signal_name="${1:?signal name is required}"
  local signal_rc="${2:?signal return code is required}"

  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  exit "${signal_rc}"
}

task_run_status_install_signal_traps() {
  trap 'task_run_status_note_signal HUP 129' HUP
  trap 'task_run_status_note_signal INT 130' INT
  trap 'task_run_status_note_signal TERM 143' TERM
}

task_run_status_finalize() {
  local command_rc="${1:?command return code is required}"
  local cleanup_rc="${2:-0}"
  local final_rc="${command_rc}"
  local status_line

  if [[ ! "${command_rc}" =~ ^[0-9]+$ ]] ||
     [[ ! "${cleanup_rc}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "[task-run-status] return codes must be non-negative integers" >&2
    return 2
  fi

  if [[ "${TASK_RUN_STATUS_EVIDENCE_COMPLETE}" -eq 1 &&
        "${command_rc}" -eq 0 &&
        "${cleanup_rc}" -eq 0 &&
        "${TASK_RUN_STATUS_SIGNAL}" == "none" ]]; then
    _task_run_status_write "PASS"
    return 0
  fi

  if [[ "${final_rc}" -eq 0 ]]; then
    if [[ "${cleanup_rc}" -ne 0 ]]; then
      final_rc="${cleanup_rc}"
    else
      final_rc=1
    fi
  fi

  status_line="FAIL rc=${final_rc} stage=${TASK_RUN_STATUS_STAGE}"
  status_line+=" evidence_complete=${TASK_RUN_STATUS_EVIDENCE_COMPLETE}"
  status_line+=" cleanup_rc=${cleanup_rc}"
  if [[ "${TASK_RUN_STATUS_SIGNAL}" != "none" ]]; then
    status_line+=" signal=${TASK_RUN_STATUS_SIGNAL}"
  fi
  _task_run_status_write "${status_line}" || return 1
  return "${final_rc}"
}
