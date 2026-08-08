#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
full_core_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1"
evidence_dir="${run_dir}/evidence/round-finalization-v1"
status_path="${run_dir}/round-finalization-v1.status"
expected_design_id='sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308'
expected_parent_id='sha256:f784b60a858e4c947316b67e9d16f1c0715f8328b1424eb5ae9b3a377566cef3'
command_rc=1
cleanup_rc=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}" || exit 1
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
if grep -Fxq 'FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0' \
     "${run_dir}/traceable-f784-a1.status" &&
   jq -e --arg parent "${expected_parent_id}" '
     .status == "PASS" and
     .classification == "EDA_TRANSACTION_COMPLETE_ORIGINAL_TRACE_NAME_ORACLE_FALSE_NEGATIVE" and
     .design.expected_id == $parent and .design.observed_id == $parent and
     .corrected_name_contract.report.status == "PASS" and
     .corrected_name_contract.report.path_count == 40 and
     .corrected_name_contract.report.unique_startpoints == 1 and
     .corrected_name_contract.report.unique_endpoints == 40 and
     .production_manifest_replay.checked_count == 206 and
     .artifact_verification.checked_count == 14 and
     .runtime_cleanup.netlist_retained == false
   ' "${run_dir}/evidence/checker-replay-flat-public-name-v1/result.json" >/dev/null &&
   grep -Fxq PASS "${run_dir}/owner-any-live-validation-v1.status" &&
   grep -Fq 'RESULT=PASS' "${run_dir}/evidence/owner-any-live-validation-v1/mutation/result.txt" &&
   grep -Fq 'COMPILE_SUCCESS=1' "${run_dir}/evidence/owner-any-live-validation-v1/mutation/result.txt" &&
   grep -Fq 'MUTATION_DETECTED=1' "${run_dir}/evidence/owner-any-live-validation-v1/mutation/result.txt" &&
   cmp -s "${run_dir}/evidence/owner-any-live-validation-v1/inputs-before.sha256" \
          "${run_dir}/evidence/owner-any-live-validation-v1/inputs-after.sha256" &&
   grep -Fxq PASS "${run_dir}/ppa-owner-any-live-e7da-a1.status" &&
   jq -e '
     .status == "PASS" and .period_ns == 5.0 and
     .timing.wns_ns == -17.592411041 and
     .timing.tns_ns == -468716.46875 and
     .timing.combinational_loops == 0 and
     .timing.violated_path_count == 40 and
     .timing.target_200mhz_met == false and
     .synthesis.area.total_cells_including_unknown_macros == 929222 and
     .synthesis.area.logic_area_proxy_excluding_unknown_macros == 2181644.08 and
     .netlist.runtime_retention == "DELETE_AFTER_EVIDENCE_CAPTURE" and
     .power.qualification == "RELATIVE_ONLY_FIXED_TOGGLE_0P1"
   ' "${run_dir}/evidence/ppa-owner-any-live-e7da-a1/summary.json" >/dev/null &&
   cmp -s "${run_dir}/evidence/ppa-owner-any-live-e7da-a1/production-manifest-before.sha256" \
          "${run_dir}/evidence/ppa-owner-any-live-e7da-a1/production-manifest-after.sha256" &&
   grep -Fxq PASS "${full_core_dir}/full-core-current.status" &&
   jq -e --arg design "${expected_design_id}" '
     .status == "PASS" and .design_id == $design and .inputs_unchanged == true and
     .counts.module_passed == 113 and .counts.module_required == 113 and
     .counts.official_passed == 177 and .counts.official_required == 177 and
     .counts.am_passed == 61 and .counts.am_required == 61 and
     .counts.difftest_mismatches == 0 and
     .counts.evidence_mutations_compiled == 11 and
     .counts.evidence_mutations_rejected == 11 and
     .retention.compiled_intermediates_retained == 0
   ' "${full_core_dir}/evidence/functional/run-result.json" >/dev/null &&
   jq -e --arg design "${expected_design_id}" '
     .status == "PASS" and .design_id == $design and
     .decision == "RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE" and
     .contract.sha256 == "3cd430bf41d526c352fb3ffde58014681ccc40ea5b132b789163b72052a2c2a9" and
     .equivalence.status == "PASS" and
     .timing.hard_gate == "GAP" and
     .coverage.production_32_token_dynamic == "GAP" and
     .scope_extension_request == "none"
   ' "${run_dir}/evidence/independent-review-v4/result.json" >/dev/null &&
   grep -Fq '[V15S-OWNER-ANY-LIVE-INDEPENDENT-REVIEW][APPROVE_ENGINEERING_CANDIDATE]' \
     "${run_dir}/evidence/independent-review-v4/review.md"; then
  command_rc=0
fi

task_run_status_stage binding-receipt
sha256sum \
  "${run_dir}/traceable-f784-a1.status" \
  "${run_dir}/evidence/checker-replay-flat-public-name-v1/result.json" \
  "${run_dir}/owner-any-live-validation-v1.status" \
  "${run_dir}/evidence/owner-any-live-validation-v1/mutation/result.txt" \
  "${run_dir}/ppa-owner-any-live-e7da-a1.status" \
  "${run_dir}/evidence/ppa-owner-any-live-e7da-a1/summary.json" \
  "${full_core_dir}/full-core-current.status" \
  "${full_core_dir}/evidence/module/result.json" \
  "${full_core_dir}/evidence/functional/run-result.json" \
  "${full_core_dir}/evidence/functional/functional-aggregate-result.json" \
  "${run_dir}/subagent-contracts/v15s-owner-any-live-material-review-v4.json" \
  "${run_dir}/evidence/independent-review-v4/review.md" \
  "${run_dir}/evidence/independent-review-v4/result.json" \
  "${run_dir}/task-report.md" >"${evidence_dir}/bindings.sha256" || command_rc=1

if [[ "${command_rc}" -eq 0 ]]; then
  printf '%s\n' \
    '{' \
    '  "schema": "npc-rv64-v15s-round-finalization-v1",' \
    '  "status": "PASS",' \
    '  "parent_design_id": "sha256:f784b60a858e4c947316b67e9d16f1c0715f8328b1424eb5ae9b3a377566cef3",' \
    '  "candidate_design_id": "sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308",' \
    '  "decision": "RETAIN_REVERSIBLE_ENGINEERING_CANDIDATE",' \
    '  "named_trace_original": "FAIL_PRESERVED",' \
    '  "named_trace_checker_replay": "PASS",' \
    '  "focused": "PASS",' \
    '  "l0_l1": "PASS",' \
    '  "mapped_sta_collection": "PASS",' \
    '  "timing_5ns_hard_gate": "GAP",' \
    '  "independent_review": "PASS",' \
    '  "l2_l3": "NOT_RUN_RISK_GATED",' \
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
