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

# Task classes describe work; none of them creates a task-run by default.
classes=(review analysis docs development verification environment longrun cleanup release)
class_index=0
for task_class in "${classes[@]}"; do
  task="archive-default-${class_index}"
  "${runner}" begin --task "${task}" --class "${task_class}"
  "${runner}" status --task "${task}" >"${test_root}/${task}.summary"
  grep -Fqx 'ARCHIVE_MODE=none' "${test_root}/${task}.summary"
  class_index=$((class_index + 1))
done

# A normal local change closes its optional record without claiming engineering PASS.
"${runner}" begin --task development-no-gate --class development
"${runner}" record --task development-no-gate --path src/example.c
"${runner}" finish --task development-no-gate >"${test_root}/development-no-gate.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' "${test_root}/development-no-gate.summary"
grep -Fqx 'ENGINEERING_RESULT=NOT_EVALUATED' "${test_root}/development-no-gate.summary"
grep -Fqx 'GATE_SELECTION=NOT_REQUESTED' "${test_root}/development-no-gate.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/development-no-gate.summary"
if grep -Fq 'all selected gates passed' "${test_root}/development-no-gate.summary"; then
  printf '%s\n' '[agent-flow-test] zero-gate finish produced an empty-set PASS' >&2
  exit 1
fi
"${runner}" finish --task development-no-gate \
  >"${test_root}/development-no-gate-again.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' \
  "${test_root}/development-no-gate-again.summary"
set +e
"${runner}" record --task development-no-gate --path src/after-finish.c \
  >"${test_root}/development-after-finish.out" 2>&1
after_finish_rc=$?
set -e
[[ "${after_finish_rc}" -eq 2 ]]

# Paths are records only: even former environment/RV64 mappings select no gate.
"${runner}" begin --task paths-are-advisory --class development
"${runner}" record --task paths-are-advisory \
  --path .github/ai-env/contracts/agent-env-policy.json \
  --path scripts/agent-flow.c \
  --path npc/rv64/eval/ppa/tools/arch_stable_freeze.py
"${runner}" finish --task paths-are-advisory --plan \
  >"${test_root}/paths-are-advisory.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/paths-are-advisory.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/paths-are-advisory.summary"

# Explicit checks remain available and their scope is visible in the summary.
"${runner}" begin --task explicit-gate-pass --class environment
"${runner}" record --task explicit-gate-pass --gate flow-observation-smoke
"${runner}" finish --task explicit-gate-pass >"${test_root}/explicit-gate-pass.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/explicit-gate-pass.summary"
grep -Fqx 'ENGINEERING_RESULT=SCOPED_PASS' "${test_root}/explicit-gate-pass.summary"
grep -Fqx 'GATE_SELECTION=EXPLICIT' "${test_root}/explicit-gate-pass.summary"
grep -Fq 'GATE_0=flow-observation-smoke:PASS:' "${test_root}/explicit-gate-pass.summary"

# A selected gate failure propagates; recording cannot turn it green.
fake_repo="${test_root}/empty-repo"
mkdir -p "${fake_repo}"
binary="${AGENT_FLOW_BIN_DIR}/agent-flow"
"${binary}" --repo "${fake_repo}" begin --task explicit-gate-fail --class environment
"${binary}" --repo "${fake_repo}" record --task explicit-gate-fail \
  --gate flow-observation-smoke
set +e
"${binary}" --repo "${fake_repo}" finish --task explicit-gate-fail \
  >"${test_root}/explicit-gate-fail.summary"
explicit_gate_fail_rc=$?
set -e
[[ "${explicit_gate_fail_rc}" -eq 1 ]]
grep -Fqx 'RESULT=BLOCKED' "${test_root}/explicit-gate-fail.summary"
grep -Fq 'GATE_0=flow-observation-smoke:FAIL:' "${test_root}/explicit-gate-fail.summary"

# Link checks subsume explicitly selected fast checks; paths do not participate.
"${runner}" begin --task explicit-dependency-normalization --class development
"${runner}" record --task explicit-dependency-normalization \
  --path npc/rv64/vsrc/execute/OooIntBackend.v \
  --gate rv64-memory-request-hold-fast \
  --gate rv64-memory-request-hold-link
"${runner}" finish --task explicit-dependency-normalization --plan \
  >"${test_root}/explicit-dependency-normalization.summary"
grep -Fqx 'GATE_COUNT=1' "${test_root}/explicit-dependency-normalization.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-memory-request-hold-link' \
  "${test_root}/explicit-dependency-normalization.summary"

# Task classes are descriptive; paths and explicit checks do not create a permission epoch.
for task_class in review analysis; do
  task="descriptive-${task_class}"
  "${runner}" begin --task "${task}" --class "${task_class}"
  "${runner}" record --task "${task}" --path src/review-followup.c
  "${runner}" finish --task "${task}" >"${test_root}/${task}.summary"
  grep -Fqx 'RESULT=FINISHED_NO_GATES' "${test_root}/${task}.summary"
done

# Verification describes a validation-oriented task; it is not a write permission class.
"${runner}" begin --task verification-with-path --class verification
"${runner}" record --task verification-with-path --path src/verification-fix.c
"${runner}" finish --task verification-with-path \
  >"${test_root}/verification-with-path.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' \
  "${test_root}/verification-with-path.summary"

"${runner}" begin --task review-explicit-gate --class review
"${runner}" record --task review-explicit-gate --gate flow-observation-smoke \
  >"${test_root}/review-explicit-gate.out" 2>&1
"${runner}" finish --task review-explicit-gate \
  >"${test_root}/review-explicit-gate.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/review-explicit-gate.summary"

# A long runtime label alone does not opt into persistence or terminal receipts.
"${runner}" begin --task longrun-nonpersistent --class longrun
"${runner}" finish --task longrun-nonpersistent \
  >"${test_root}/longrun-nonpersistent.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' \
  "${test_root}/longrun-nonpersistent.summary"

# Explicit durable longruns and destructive cleanup keep their real fail-closed criteria.
durable_repo="${test_root}/durable-repo"
mkdir -p "${durable_repo}"
"${binary}" --repo "${durable_repo}" begin --task longrun-missing-terminal \
  --class longrun --archive durable
set +e
"${binary}" --repo "${durable_repo}" finish --task longrun-missing-terminal \
  >"${test_root}/longrun-missing-terminal.summary"
longrun_missing_rc=$?
set -e
[[ "${longrun_missing_rc}" -eq 1 ]]
grep -Fq 'durable longrun requires task-run-status PASS evidence' \
  "${test_root}/longrun-missing-terminal.summary"

"${binary}" --repo "${durable_repo}" begin --task longrun-complete \
  --class longrun --archive durable
"${binary}" --repo "${durable_repo}" evidence --task longrun-complete \
  --name task-run-status --status PASS
"${binary}" --repo "${durable_repo}" finish --task longrun-complete \
  >"${test_root}/longrun-complete.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' "${test_root}/longrun-complete.summary"

"${runner}" begin --task cleanup-missing-preview --class cleanup
"${runner}" evidence --task cleanup-missing-preview --name cleanup-result --status PASS
set +e
"${runner}" finish --task cleanup-missing-preview \
  >"${test_root}/cleanup-missing-preview.summary"
cleanup_missing_rc=$?
set -e
[[ "${cleanup_missing_rc}" -eq 1 ]]
grep -Fq 'cleanup requires cleanup-preview and cleanup-result PASS evidence' \
  "${test_root}/cleanup-missing-preview.summary"

"${runner}" begin --task cleanup-complete --class cleanup
"${runner}" evidence --task cleanup-complete --name cleanup-preview --status PASS
"${runner}" evidence --task cleanup-complete --name cleanup-result --status PASS
"${runner}" finish --task cleanup-complete >"${test_root}/cleanup-complete.summary"
grep -Fqx 'RESULT=FINISHED_NO_GATES' "${test_root}/cleanup-complete.summary"

# Candidate means scoped checks passed; an empty candidate is rejected.
"${runner}" begin --task empty-candidate --class environment
set +e
"${runner}" finish --task empty-candidate --candidate \
  >"${test_root}/empty-candidate.summary"
empty_candidate_rc=$?
set -e
[[ "${empty_candidate_rc}" -eq 1 ]]
grep -Fq 'candidate requires at least one explicitly selected gate' \
  "${test_root}/empty-candidate.summary"

"${runner}" begin --task checked-candidate --class environment
"${runner}" record --task checked-candidate --gate flow-observation-smoke
"${runner}" finish --task checked-candidate --candidate \
  >"${test_root}/checked-candidate.summary"
grep -Fqx 'RESULT=CANDIDATE_PASS' "${test_root}/checked-candidate.summary"
"${runner}" finish --task checked-candidate >"${test_root}/checked-final.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/checked-final.summary"
grep -Fq ':reused' "${test_root}/checked-final.summary"

# Explicit persistence still works, but a zero-gate archive is not labeled PASS.
archive_repo="${test_root}/archive-repo"
mkdir -p "${archive_repo}"
"${binary}" --repo "${archive_repo}" begin --task compact-record \
  --class development --archive compact
"${binary}" --repo "${archive_repo}" record --task compact-record --path src/core.c
"${binary}" --repo "${archive_repo}" decision --task compact-record \
  --kind hypothesis --text 'the targeted test should exercise the modified path'
"${binary}" --repo "${archive_repo}" finish --task compact-record \
  >"${test_root}/compact-record.summary"
compact_run=$(sed -n 's/^TASK_RUN=//p' "${test_root}/compact-record.summary")
[[ -f "${archive_repo}/${compact_run}/agent-flow-result.md" ]]
grep -Fq '`status`: FINISHED_NO_GATES' \
  "${archive_repo}/${compact_run}/agent-flow-result.md"
grep -Fq '`engineering_result`: NOT_EVALUATED' \
  "${archive_repo}/${compact_run}/agent-flow-result.md"

# CLI input validation remains strict without becoming a workflow permission layer.
"${runner}" begin --task invalid-inputs --class development
set +e
"${runner}" record --task invalid-inputs --path ../outside \
  >"${test_root}/invalid-path.out" 2>&1
invalid_path_rc=$?
"${runner}" record --task invalid-inputs --gate no-such-gate \
  >"${test_root}/invalid-gate.out" 2>&1
invalid_gate_rc=$?
set -e
[[ "${invalid_path_rc}" -eq 2 ]]
[[ "${invalid_gate_rc}" -eq 2 ]]

printf '%s\n' \
  '[agent-flow-test] PASS explicit-only gates, zero-gate non-PASS completion, opt-in archives, user-scoped read-only consistency, durable-longrun and cleanup fail-closed criteria, candidate scope, dependency normalization, failure propagation, and path confinement'
