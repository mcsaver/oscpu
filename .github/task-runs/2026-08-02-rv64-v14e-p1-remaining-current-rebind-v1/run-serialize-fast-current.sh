#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
evidence="${run_dir}/evidence/serialize-fast-run-1"
status_path="${run_dir}/serialize-fast-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
qh_runner="${repo_root}/npc/rv64/testbench/scripts/run_v12c_serialize_qh_current.py"
system_runner="${repo_root}/npc/rv64/testbench/scripts/run_v12c_serialize_system_current.py"
finalized=0
command_rc=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14E-SERIALIZE-FAST][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize_on_exit() {
  local exit_rc=$?
  if [[ "${command_rc}" -eq 0 && "${exit_rc}" -ne 0 ]]; then
    command_rc="${exit_rc}"
  fi
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

cd "${repo_root}"
task_run_status_stage "source-binding-pre"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-before.json" || command_rc=$?

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "queue-head-current"
  python3 -B "${qh_runner}" --repo-root "${repo_root}" \
    --output-dir "${evidence}/qh" \
    > "${evidence}/qh.driver.log" 2>&1 || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "pending-system-current"
  python3 -B "${system_runner}" --repo-root "${repo_root}" \
    --output-dir "${evidence}/system" \
    > "${evidence}/system.driver.log" 2>&1 || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "source-binding-post"
  python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
    --output "${evidence}/source-after.json" || command_rc=$?
  if [[ "${command_rc}" -eq 0 ]]; then
    cmp "${evidence}/source-before.json" "${evidence}/source-after.json" || command_rc=$?
  fi
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "summary-audit"
  python3 -B "${run_dir}/build-serialize-fast-summary.py" \
    --evidence "${evidence}" --output "${evidence}/summary.json" \
    > "${evidence}/summary.driver.log" 2>&1 || command_rc=$?
fi

task_run_status_stage "artifact-audit"
forbidden="$(find "${evidence}" -type f \( \
  -name '*.vvp' -o -name '*.o' -o -name '*.so' -o -name '*.pyc' -o -name 'NpcSimTop' \
  \) -print -quit)"
forbidden_dir="$(find "${evidence}" -type d \( -name build -o -name generated -o -name __pycache__ \) -print -quit)"
if [[ -n "${forbidden}" || -n "${forbidden_dir}" ]]; then
  printf '%s\n' "[V14E-SERIALIZE-FAST][FAIL] retained=${forbidden:-${forbidden_dir}}" >&2
  command_rc=1
fi
if [[ "${command_rc}" -ne 0 ]]; then
  test ! -e "${evidence}/summary.driver.log" || tail -n 80 "${evidence}/summary.driver.log" >&2 || true
  tail -n 80 "${evidence}/qh.driver.log" 2>/dev/null >&2 || true
  tail -n 80 "${evidence}/system.driver.log" 2>/dev/null >&2 || true
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
