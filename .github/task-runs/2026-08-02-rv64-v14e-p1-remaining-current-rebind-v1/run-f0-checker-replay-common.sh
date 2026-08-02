#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

attempt="${1:-}"
if [[ ! "${attempt}" =~ ^[4-9][0-9]*$ ]]; then
  printf '%s\n' '[V14E-F0-REPLAY][FAIL] attempt must be an integer >= 4' >&2
  exit 2
fi

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
evidence="${run_dir}/evidence/f0-run-${attempt}"
module_dir="${run_dir}/evidence/f0-run-1/module"
source_run="${run_dir}/evidence/f0-run-2"
source_status="${run_dir}/f0-run-2.status"
status_path="${run_dir}/f0-run-${attempt}.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
finalized=0
command_rc=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14E-F0-REPLAY][FAIL] run-${attempt} output already exists" >&2
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
task_run_status_stage "classifier-unit-tests"
python3 -B "${run_dir}/test-f0-diagnostic-classifier.py" \
  > "${evidence}/classifier-tests.log" 2>&1 || command_rc=$?
if [[ "${command_rc}" -eq 0 ]]; then
  python3 -B "${run_dir}/test-f0-warning-path-adapter.py" \
    > "${evidence}/warning-adapter-tests.log" 2>&1 || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "source-binding-pre"
  python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
    --output "${evidence}/source-before.json" || command_rc=$?
fi
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "source-binding-post"
  python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
    --output "${evidence}/source-after.json" || command_rc=$?
  cmp "${evidence}/source-before.json" "${evidence}/source-after.json" || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-replay"
  python3 -B "${run_dir}/build-f0-summary.py" \
    --evidence "${evidence}" --module-dir "${module_dir}" \
    --functional-dir "${source_run}/functional" \
    --rtl-summary "${source_run}/rtl-counterexamples/summary.json" \
    --source-before "${evidence}/source-before.json" \
    --source-after "${evidence}/source-after.json" \
    --evidence-mode CHECKER_REPLAY --replay-source-status "${source_status}" \
    --output "${evidence}/summary.json" \
    > "${evidence}/summary.driver.log" 2>&1 || command_rc=$?
fi

task_run_status_stage "artifact-audit"
forbidden="$(find "${evidence}" -type f \( \
  -name '*.bin' -o -name '*.so' -o -name '*.o' -o -name '*.a' -o \
  -name '*.vvp' -o -name '*.pyc' -o -name 'NpcSimTop' \
  \) -print -quit)"
if [[ -n "${forbidden}" ]]; then
  printf '%s\n' "[V14E-F0-REPLAY][FAIL] retained=${forbidden}" >&2
  command_rc=1
fi
if [[ "${command_rc}" -ne 0 ]]; then
  cat "${evidence}/classifier-tests.log" 2>/dev/null >&2 || true
  cat "${evidence}/warning-adapter-tests.log" 2>/dev/null >&2 || true
  tail -n 120 "${evidence}/summary.driver.log" 2>/dev/null >&2 || true
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
