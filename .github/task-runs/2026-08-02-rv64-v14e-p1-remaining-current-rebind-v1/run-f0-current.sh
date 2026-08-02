#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
evidence="${run_dir}/evidence/f0-run-1"
status_path="${run_dir}/f0-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
module_runner="${repo_root}/npc/rv64/eval/ppa/tools/full_core_current_evidence.py"
functional_runner="${repo_root}/npc/rv64/eval/ppa/tools/full_core_functional_evidence.py"
temp_dir="$(mktemp -d "${repo_root}/.tmp-v14e-f0.XXXXXXXX")"
finalized=0
cleaned=0
command_rc=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14E-F0][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_temp() {
  if [[ "${cleaned}" -eq 1 ]]; then
    return
  fi
  case "${temp_dir}" in
    "${repo_root}"/.tmp-v14e-f0.*) rm -rf -- "${temp_dir}" || cleanup_rc=$? ;;
    *) printf '%s\n' "[V14E-F0][FAIL] unsafe temp path ${temp_dir}" >&2; cleanup_rc=1 ;;
  esac
  cleaned=1
}

cleanup_failed_functional_products() {
  if [[ "${command_rc}" -eq 0 ]]; then
    return
  fi
  case "${evidence}/functional/images" in
    "${run_dir}"/evidence/f0-run-1/functional/images)
      rm -rf -- "${evidence}/functional/images" || cleanup_rc=$?
      ;;
    *) cleanup_rc=1 ;;
  esac
  rm -f -- \
    "${evidence}/functional/frozen/NpcSimTop" \
    "${evidence}/functional/frozen/riscv64-nemu-interpreter-so" || cleanup_rc=$?
}

finalize_on_exit() {
  local exit_rc=$?
  if [[ "${command_rc}" -eq 0 && "${exit_rc}" -ne 0 ]]; then
    command_rc="${exit_rc}"
  fi
  cleanup_temp
  cleanup_failed_functional_products
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
  task_run_status_stage "module-current"
  python3 -B "${module_runner}" module \
    --output-dir "${evidence}/module" --jobs 4 \
    > "${evidence}/module.driver.log" 2>&1 || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "production-rtl-counterexamples"
  python3 -B "${run_dir}/run-f0-rtl-counterexamples.py" \
    --work-dir "${temp_dir}/rtl-counterexamples" \
    --output-dir "${evidence}/rtl-counterexamples" \
    > "${evidence}/rtl-counterexamples.driver.log" 2>&1 || command_rc=$?
fi
cleanup_temp

if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 ]]; then
  task_run_status_stage "full-functional-current"
  python3 -B "${functional_runner}" \
    --module-result "${evidence}/module/result.json" \
    --output-dir "${evidence}/functional" --jobs 4 \
    > "${evidence}/functional.driver.log" 2>&1 || command_rc=$?
fi

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "functional-compaction"
  python3 -B "${run_dir}/compact-f0-functional.py" \
    --functional-dir "${evidence}/functional" \
    > "${evidence}/functional-compaction.log" 2>&1 || command_rc=$?
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
  python3 -B "${run_dir}/build-f0-summary.py" \
    --evidence "${evidence}" --module-dir "${evidence}/module" \
    --functional-dir "${evidence}/functional" \
    --rtl-summary "${evidence}/rtl-counterexamples/summary.json" \
    --source-before "${evidence}/source-before.json" \
    --source-after "${evidence}/source-after.json" \
    --output "${evidence}/summary.json" \
    > "${evidence}/summary.driver.log" 2>&1 || command_rc=$?
fi

task_run_status_stage "artifact-audit"
forbidden="$(find "${evidence}" -type f \( \
  -name '*.bin' -o -name '*.so' -o -name '*.o' -o -name '*.a' -o \
  -name '*.vvp' -o -name '*.pyc' -o -name 'NpcSimTop' \
  \) -print -quit)"
forbidden_dir="$(find "${evidence}" -type d \( \
  -name images -o -name build -o -name obj_dir -o -name generated -o -name __pycache__ \
  \) -print -quit)"
if [[ -n "${forbidden}" || -n "${forbidden_dir}" ]]; then
  printf '%s\n' "[V14E-F0][FAIL] retained=${forbidden:-${forbidden_dir}}" >&2
  command_rc=1
fi
if [[ "${command_rc}" -ne 0 ]]; then
  tail -n 100 "${evidence}/module.driver.log" 2>/dev/null >&2 || true
  tail -n 100 "${evidence}/rtl-counterexamples.driver.log" 2>/dev/null >&2 || true
  tail -n 100 "${evidence}/functional.driver.log" 2>/dev/null >&2 || true
  tail -n 100 "${evidence}/functional-compaction.log" 2>/dev/null >&2 || true
  tail -n 100 "${evidence}/summary.driver.log" 2>/dev/null >&2 || true
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
