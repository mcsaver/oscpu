#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
source_run="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1"
evidence_dir="${run_dir}/evidence/post-candidate-current-verify-replay-v2"
status_path="${run_dir}/post-candidate-current-verify-replay-v2.status"
command_rc=1
cleanup_rc=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -- "${evidence_dir}" || exit 1
task_run_status_init "${status_path}" || exit 1

finalize_on_exit() {
  local exit_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${exit_rc}" "${cleanup_rc}" || true
  fi
}

signal_exit() {
  local signal_name=$1
  local signal_rc=$2
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  exit "${signal_rc}"
}

trap 'signal_exit HUP 129' HUP
trap 'signal_exit INT 130' INT
trap 'signal_exit TERM 143' TERM
trap finalize_on_exit EXIT

task_run_status_stage launch-context
printf '%s\n' \
  'original_execution_launcher=Windows-wsl-direct-non-login-bash' \
  "python=$(/usr/bin/realpath -e /usr/bin/python3)" \
  "path=${PATH}" \
  "optional_unknown_elf_gcc=$(command -v riscv64-unknown-elf-gcc || printf '%s' ABSENT)" \
  >"${evidence_dir}/launch-context.txt"

task_run_status_stage current-design-verify
/usr/bin/python3 -B \
  "${repo_root}/npc/rv64/eval/ppa/tools/full_core_functional_evidence.py" \
  --verify-result \
  "${source_run}/evidence/functional/run-result.json" \
  --require-current-design \
  >"${evidence_dir}/verify.log" 2>&1
command_rc=$?

task_run_status_stage evidence-check
if [[ "${command_rc}" -eq 0 ]] &&
   grep -Fq '[FULL-CORE-FUNCTIONAL-VERIFY][PASS]' \
     "${evidence_dir}/verify.log" &&
   grep -Fq 'design_id=sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308' \
     "${evidence_dir}/verify.log" &&
   grep -Fq 'optional_unknown_elf_gcc=ABSENT' \
     "${evidence_dir}/launch-context.txt"; then
  printf '%s\n' \
    'schema=npc-rv64-post-candidate-current-verify-replay-v2' \
    'status=PASS' \
    'classification=EXACT_ORIGINAL_NON_LOGIN_LAUNCH_CONTEXT' \
    'login_shell_failures_preserved=2' \
    'rtl_design_drift=NO' \
    'toolchain_input_drift=NO' \
    'design_id=sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308' \
    >"${evidence_dir}/result.txt" || command_rc=1
else
  command_rc=1
fi

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
exit "${command_rc}"
