#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/driver/run-current-fresh-a1.sh"
driver_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/driver"
generated="${driver_dir}/run-ppa-owner-any-live-e7da-a1.generated.sh"
parent_summary="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/ppa-candidate-f784-a1/summary.json"
focused_status="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/owner-any-live-validation-v1.status"
focused_commands="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/owner-any-live-validation-v1/command-status.txt"
mutation_result="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/owner-any-live-validation-v1/mutation/result.txt"
expected_template_sha=b8526a181a532102fcaf6499b708c03278cb1558b9d8db4a00b68505b8656a5f
expected_parent_summary_sha=a1537bc81e4a6d3a96b1c2ff81d87f3c9b7b4faa7c20f434d883562536b3f9e0
expected_focused_status_sha=c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431
expected_focused_commands_sha=a4c37fe22cc5548caa2d086d5745d0fc1094d99e172588cae4a0cb8aa7614c5d
expected_mutation_result_sha=0816afde09e01dc0901d3f021af80c5cb6307a7b92f054e165bfbcb93d518a68
expected_design_id=sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308

require_frozen_file() {
  local path=$1
  local expected_sha=$2
  local label=$3
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || {
    printf '%s\n' "[V15S-PPA-PREPARE][FAIL] ${label} missing, empty, or symlinked" >&2
    return 2
  }
  [[ "$(sha256sum "${path}" | awk '{print $1}')" == "${expected_sha}" ]] || {
    printf '%s\n' "[V15S-PPA-PREPARE][FAIL] ${label} hash drift" >&2
    return 2
  }
}

require_frozen_file "${template}" "${expected_template_sha}" template
require_frozen_file "${parent_summary}" "${expected_parent_summary_sha}" parent-summary
require_frozen_file "${focused_status}" "${expected_focused_status_sha}" focused-status
require_frozen_file "${focused_commands}" "${expected_focused_commands_sha}" focused-command-status
require_frozen_file "${mutation_result}" "${expected_mutation_result_sha}" mutation-result

[[ "$(<"${focused_status}")" == PASS ]] || {
  printf '%s\n' '[V15S-PPA-PREPARE][FAIL] focused status is not PASS' >&2
  exit 2
}
grep -Fqx 'command_rc=0' "${focused_commands}" || {
  printf '%s\n' '[V15S-PPA-PREPARE][FAIL] focused command receipt is not complete' >&2
  exit 2
}
grep -Fqx 'RESULT=PASS' "${mutation_result}" || {
  printf '%s\n' '[V15S-PPA-PREPARE][FAIL] mutation receipt is not PASS' >&2
  exit 2
}

observed_design_id="$(python3 -B -c \
  'from pathlib import Path; from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding; print("sha256:" + rtl_binding(Path.cwd())[0])')"
[[ "${observed_design_id}" == "${expected_design_id}" ]] || {
  printf '%s\n' \
    "[V15S-PPA-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

[[ ! -e "${generated}" ]] || {
  printf '%s\n' "[V15S-PPA-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}
sed \
  -e 's/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/2026-08-07-rv64-v15s-f784-named-timing-path-a1/g' \
  -e 's/current-fresh-a1/ppa-owner-any-live-e7da-a1/g' \
  -e 's/v15q-current-reference-ppa-337-a1/v15s-owner-any-live-e7da-a1/g' \
  -e 's/v15q-current-reference-ppa/v15s-owner-any-live/g' \
  "${template}" >"${generated}"
chmod 0755 "${generated}"

printf '%s\n' \
  "[V15S-PPA-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15S-PPA-PREPARE] parent_summary=${parent_summary}" \
  "[V15S-PPA-PREPARE] driver=${generated}"
exec "${generated}"
