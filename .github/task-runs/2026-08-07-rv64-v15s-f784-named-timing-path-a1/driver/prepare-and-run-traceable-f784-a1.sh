#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_id=2026-08-07-rv64-v15s-f784-named-timing-path-a1
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-trace-337-a1/driver/run-traceable-names-a1.sh"
driver_dir="${repo_root}/.github/task-runs/${run_id}/driver"
generated="${driver_dir}/run-traceable-f784-a1.generated.sh"
candidate_summary="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/ppa-candidate-f784-a1/summary.json"
review_receipt="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/post-candidate-review-final.md"
expected_template_sha=9d98f740a4b839a4d47bc9e8b8aeabe2a73e4f816afeab6c18caf46c6e41bbd7
expected_candidate_summary_sha=a1537bc81e4a6d3a96b1c2ff81d87f3c9b7b4faa7c20f434d883562536b3f9e0
expected_review_receipt_sha=69238f801e7480e2201a9f4e0d8e5910e80300495ab267a4d9bbaa96d9111e09
expected_design_id=sha256:f784b60a858e4c947316b67e9d16f1c0715f8328b1424eb5ae9b3a377566cef3

require_frozen_file() {
  local path=$1
  local expected_sha=$2
  local label=$3
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || {
    printf '%s\n' "[V15S-TRACE-PREPARE][FAIL] ${label} missing, empty, or symlinked" >&2
    return 2
  }
  [[ "$(sha256sum "${path}" | awk '{print $1}')" == "${expected_sha}" ]] || {
    printf '%s\n' "[V15S-TRACE-PREPARE][FAIL] ${label} hash drift" >&2
    return 2
  }
}

require_frozen_file "${template}" "${expected_template_sha}" template
require_frozen_file "${candidate_summary}" "${expected_candidate_summary_sha}" candidate-summary
require_frozen_file "${review_receipt}" "${expected_review_receipt_sha}" review-receipt

observed_design_id="$(python3 -B -c \
  'from pathlib import Path; from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding; print("sha256:" + rtl_binding(Path.cwd())[0])')"
[[ "${observed_design_id}" == "${expected_design_id}" ]] || {
  printf '%s\n' \
    "[V15S-TRACE-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

mkdir -p -- "${driver_dir}"
[[ ! -e "${generated}" ]] || {
  printf '%s\n' "[V15S-TRACE-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}

sed \
  -e 's|2026-08-07-rv64-v15r-current-timing-trace-337-a1|2026-08-07-rv64-v15s-f784-named-timing-path-a1|g' \
  -e 's|traceable-names-a1|traceable-f784-a1|g' \
  -e 's|v15r-current-timing-trace-337-a1|v15s-f784-named-timing-path-a1|g' \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/evidence/current-reference-ppa-337-a1.json|.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/ppa-candidate-f784-a1/summary.json|g' \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/current-timing-path-analysis-337-a1.json|.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/post-candidate-review-final.md|g' \
  -e 's|\[v15r-timing-trace\]|[v15s-f784-timing-trace]|g' \
  "${template}" >"${generated}"
chmod 0755 "${generated}"

printf '%s\n' \
  "[V15S-TRACE-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15S-TRACE-PREPARE] driver=${generated}"
exec "${generated}"
