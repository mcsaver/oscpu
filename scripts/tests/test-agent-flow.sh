#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runner="${repo_root}/scripts/agent-flow.sh"
test_root=$(mktemp -d)

cleanup() {
  local rc=$?
  case "${test_root}" in
    /tmp/*) rm -rf -- "${test_root}" ;;
    *) printf '[agent-flow-test] refuse cleanup outside /tmp: %s\n' "${test_root}" >&2 ;;
  esac
  exit "${rc}"
}
trap cleanup EXIT

export AGENT_FLOW_STATE_ROOT="${test_root}/state"
export AGENT_FLOW_BIN_DIR="${test_root}/bin"

"${runner}" begin --task review-ok --class review
"${runner}" finish --task review-ok >"${test_root}/review.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/review.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/review.summary"

"${runner}" begin --task review-gate --class review
set +e
"${runner}" record --task review-gate --gate maintain-release \
  >"${test_root}/review-gate.out" 2>&1
review_gate_rc=$?
set -e
[[ "${review_gate_rc}" -eq 2 ]]
"${runner}" finish --task review-gate >"${test_root}/review-gate.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/review-gate.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/review-gate.summary"

"${runner}" begin --task analysis-gate --class analysis
set +e
"${runner}" record --task analysis-gate --gate flow-observation-smoke \
  >"${test_root}/analysis-gate.out" 2>&1
analysis_gate_rc=$?
set -e
[[ "${analysis_gate_rc}" -eq 2 ]]
"${runner}" finish --task analysis-gate >"${test_root}/analysis-gate.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/analysis-gate.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/analysis-gate.summary"

"${runner}" begin --task review-write --class review
"${runner}" record --task review-write --path npc/rv64/vsrc/example.sv
set +e
"${runner}" finish --task review-write >"${test_root}/review-write.summary"
review_write_rc=$?
set -e
[[ "${review_write_rc}" -eq 1 ]]
grep -Fqx 'RESULT=BLOCKED' "${test_root}/review-write.summary"

"${runner}" begin --task development-evidence --class development --archive none
"${runner}" record --task development-evidence --path npc/rv64/vsrc/example.sv
set +e
"${runner}" finish --task development-evidence >"${test_root}/development-missing.summary"
development_missing_rc=$?
set -e
[[ "${development_missing_rc}" -eq 1 ]]
grep -Fq 'require one PASS evidence' "${test_root}/development-missing.summary"
"${runner}" evidence --task development-evidence --name rtl-focused-test --status PASS
"${runner}" decision --task development-evidence --kind decision \
  --text 'focused RTL evidence closes the modified transaction path'
"${runner}" finish --task development-evidence >"${test_root}/development.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/development.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/development.summary"
grep -Fq $'\tdecision\tfocused RTL evidence closes the modified transaction path\t-' \
  "${AGENT_FLOW_STATE_ROOT}/development-evidence/decisions.tsv"

"${runner}" begin --task environment-plan --class environment --archive none \
  --initial-work-seconds 10
"${runner}" record --task environment-plan \
  --path scripts/agent-flow.c \
  --path scripts/agent-e2e.sh \
  --path .github/ai-env/contracts/agent-env-policy.json
"${runner}" status --task environment-plan >"${test_root}/environment-generation-2.summary"
grep -Fqx 'GENERATION=2' "${test_root}/environment-generation-2.summary"
"${runner}" record --task environment-plan --path scripts/agent-flow.c
"${runner}" status --task environment-plan >"${test_root}/environment-generation-3.summary"
grep -Fqx 'GENERATION=3' "${test_root}/environment-generation-3.summary"
"${runner}" finish --task environment-plan --plan >"${test_root}/environment-plan.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/environment-plan.summary"
grep -Fqx 'GATE_COUNT=3' "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_0=flow-self-test' \
  "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_1=profile-bindings' \
  "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_2=policy-audit' \
  "${test_root}/environment-plan.summary"

"${runner}" begin --task environment-advisory-target --class environment --archive none \
  --overhead-target 1
"${runner}" record --task environment-advisory-target --gate flow-observation-smoke
"${runner}" finish --task environment-advisory-target --candidate \
  >"${test_root}/environment-advisory-target-candidate.summary"
grep -Fqx 'RESULT=CANDIDATE_PASS' \
  "${test_root}/environment-advisory-target-candidate.summary"
grep -Fqx 'OVERHEAD_TARGET_PERCENT=1' \
  "${test_root}/environment-advisory-target-candidate.summary"
"${runner}" finish --task environment-advisory-target \
  >"${test_root}/environment-advisory-target-final.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/environment-advisory-target-final.summary"
grep -Fq ':reused' "${test_root}/environment-advisory-target-final.summary"

"${runner}" begin --task candidate-invalidated --class environment --archive none
"${runner}" record --task candidate-invalidated --gate flow-observation-smoke
"${runner}" finish --task candidate-invalidated --candidate \
  >"${test_root}/candidate-invalidated-candidate.summary"
grep -Fqx 'RESULT=CANDIDATE_PASS' \
  "${test_root}/candidate-invalidated-candidate.summary"
"${runner}" record --task candidate-invalidated --gate flow-observation-smoke
"${runner}" finish --task candidate-invalidated \
  >"${test_root}/candidate-invalidated-final.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/candidate-invalidated-final.summary"
grep -Fqx 'GENERATION=3' "${test_root}/candidate-invalidated-final.summary"
if grep -Fq ':reused' "${test_root}/candidate-invalidated-final.summary"; then
  printf '%s\n' '[agent-flow-test] stale candidate gate result was reused' >&2
  exit 1
fi

"${runner}" begin --task invalid-path --class development --archive none
set +e
"${runner}" record --task invalid-path --path ../outside >"${test_root}/invalid-path.out" 2>&1
invalid_path_rc=$?
set -e
[[ "${invalid_path_rc}" -eq 2 ]]

test_repo="${test_root}/repo"
mkdir -p "${test_repo}"
binary="${AGENT_FLOW_BIN_DIR}/agent-flow"
"${binary}" --repo "${test_repo}" begin --task compact-archive \
  --class development --archive compact
"${binary}" --repo "${test_repo}" record --task compact-archive --path src/core.c
"${binary}" --repo "${test_repo}" evidence --task compact-archive \
  --name focused-test --status PASS
"${binary}" --repo "${test_repo}" decision --task compact-archive \
  --kind hypothesis --text 'the focused test exercises the modified data path'
"${binary}" --repo "${test_repo}" finish --task compact-archive \
  >"${test_root}/compact.summary"
compact_run=$(sed -n 's/^TASK_RUN=//p' "${test_root}/compact.summary")
[[ -f "${test_repo}/${compact_run}/agent-flow-result.md" ]]
[[ -f "${test_repo}/${compact_run}/agent-flow-changed-directories.tsv" ]]
[[ -f "${test_repo}/${compact_run}/agent-flow-decision-trace.tsv" ]]
grep -Fq 'private token-by-token reasoning' \
  "${test_repo}/${compact_run}/agent-flow-result.md"

printf '%s\n' \
  '[agent-flow-test] PASS review/analysis zero gates, class mismatch, development evidence, decision trace, compact task-run, gate pointers, repeated-path and candidate invalidation, advisory overhead target, and path confinement'
