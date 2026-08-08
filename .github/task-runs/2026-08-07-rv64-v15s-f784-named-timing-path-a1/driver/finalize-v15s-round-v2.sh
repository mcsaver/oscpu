#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
full_core_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1"
evidence_dir="${run_dir}/evidence/round-finalization-v2"
status_path="${run_dir}/round-finalization-v2.status"
expected_design_id='sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308'
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

task_run_status_stage evidence-check
if grep -Fxq PASS "${run_dir}/round-finalization-v1.status" &&
   jq -e --arg design "${expected_design_id}" '
     .status == "PASS" and .candidate_design_id == $design and
     .decision == "RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE" and
     .named_trace_original == "FAIL_PRESERVED" and
     .named_trace_checker_replay == "PASS" and
     .focused == "PASS" and .l0_l1 == "PASS" and
     .timing_5ns_hard_gate == "GAP" and
     .independent_review == "PASS"
   ' "${run_dir}/evidence/round-finalization-v1/result.json" >/dev/null &&
   grep -Fxq PASS "${run_dir}/post-candidate-current-verify-replay-v2.status" &&
   grep -Fq '[FULL-CORE-FUNCTIONAL-VERIFY][PASS]' \
     "${run_dir}/evidence/post-candidate-current-verify-replay-v2/verify.log" &&
   grep -Fq "design_id=${expected_design_id}" \
     "${run_dir}/evidence/post-candidate-current-verify-replay-v2/result.txt" &&
   grep -Fq 'classification=EXACT_ORIGINAL_NON_LOGIN_LAUNCH_CONTEXT' \
     "${run_dir}/evidence/post-candidate-current-verify-replay-v2/result.txt" &&
   grep -Fq 'rtl_design_drift=NO' \
     "${run_dir}/evidence/post-candidate-current-verify-replay-v2/result.txt" &&
   grep -Fq '[FULL-CORE-FUNCTIONAL-VERIFY][FAIL] functional frozen inputs differ from live execution inputs' \
     "${run_dir}/evidence/round-finalization-v1/post-candidate-current-verify.log" &&
   grep -Fq '[FULL-CORE-FUNCTIONAL-VERIFY][FAIL] functional frozen inputs differ from live execution inputs' \
     "${run_dir}/evidence/round-finalization-v1/post-candidate-current-verify-replay-v1.log" &&
   jq -e '
     .status == "DRIFT" and .difference_count == 1 and
     .differences[0].group == "toolchain" and
     .differences[0].key == "riscv64-unknown-elf-gcc" and
     .differences[0].frozen == null and
     .differences[0].live.path ==
       "/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-gcc"
   ' "${run_dir}/evidence/post-candidate-current-verify-replay-v2/login-context-input-diff.json" >/dev/null &&
   jq -e --arg design "${expected_design_id}" '
     .status == "PASS" and .design_id == $design and
     .decision == "RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE" and
     .timing.hard_gate == "GAP"
   ' "${run_dir}/evidence/independent-review-v4/result.json" >/dev/null &&
   grep -Fxq PASS "${full_core_dir}/full-core-current.status" &&
   grep -Fq '[task-run-status-test] PASS' \
     "${run_dir}/evidence/round-finalization-v1/task-run-status-test.log"; then
  command_rc=0
fi

task_run_status_stage binding-receipt
sha256sum \
  "${run_dir}/round-finalization-v1.status" \
  "${run_dir}/evidence/round-finalization-v1/result.json" \
  "${run_dir}/evidence/round-finalization-v1/post-candidate-current-verify.log" \
  "${run_dir}/evidence/round-finalization-v1/post-candidate-current-verify-replay-v1.log" \
  "${run_dir}/evidence/round-finalization-v1/task-run-status-test.log" \
  "${run_dir}/post-candidate-current-verify-replay-v2.status" \
  "${run_dir}/evidence/post-candidate-current-verify-replay-v2/launch-context.txt" \
  "${run_dir}/evidence/post-candidate-current-verify-replay-v2/verify.log" \
  "${run_dir}/evidence/post-candidate-current-verify-replay-v2/result.txt" \
  "${run_dir}/evidence/post-candidate-current-verify-replay-v2/login-context-input-diff.json" \
  "${run_dir}/evidence/independent-review-v4/result.json" \
  "${full_core_dir}/evidence/functional/run-result.json" \
  "${run_dir}/task-report.md" \
  "${run_dir}/dispatch-log.md" >"${evidence_dir}/bindings.sha256" || command_rc=1

if [[ "${command_rc}" -eq 0 ]]; then
  printf '%s\n' \
    '{' \
    '  "schema": "npc-rv64-v15s-round-finalization-v2",' \
    '  "status": "PASS",' \
    '  "candidate_design_id": "sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308",' \
    '  "decision": "RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE",' \
    '  "technical_review": "PASS",' \
    '  "post_candidate_current_verify": "PASS",' \
    '  "post_candidate_launch_context": "EXACT_ORIGINAL_NON_LOGIN_LAUNCH_CONTEXT",' \
    '  "login_shell_input_mismatch": "FAIL_PRESERVED_AND_CLASSIFIED",' \
    '  "rtl_design_drift": false,' \
    '  "timing_5ns_hard_gate": "GAP",' \
    '  "ubuntu": "NOT_RUN_USER_EXPLICIT_ONLY"' \
    '}' >"${evidence_dir}/result.json" || command_rc=1
fi

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 ]] && jq -e '.status == "PASS"' \
    "${evidence_dir}/result.json" >/dev/null; then
  task_run_status_mark_evidence_complete
fi

finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
exit "${command_rc}"
