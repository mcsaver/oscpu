#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_id=2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15r-current-timing-trace-337-a1/driver/run-traceable-names-a1.sh"
driver_dir="${repo_root}/.github/task-runs/${run_id}/driver"
generated="${driver_dir}/run-traceable-102e-a1.generated.sh"
candidate_reference="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/ppa-owner-any-live-e7da-a1/summary.json"
hypothesis="${repo_root}/.github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1/evidence/e7da-top40-cluster-and-hypothesis-v1.json"
expected_template_sha=9d98f740a4b839a4d47bc9e8b8aeabe2a73e4f816afeab6c18caf46c6e41bbd7
expected_candidate_reference_sha=e3b35b361f1b9340bd622a895e0e65f890f41653d4d3d32c30433b8528698adb
expected_hypothesis_sha=6def0316c58d0f8f9a257304e999ed91f676cdc99b8cc0fcc33664e4f9e8dbbd
expected_design_id=sha256:102e2f600d396b63f41172597c43011da1b3c8b28947f88e14f0cf4d8f37e90d

require_frozen_file() {
  local path=$1
  local expected_sha=$2
  local label=$3
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || {
    printf '%s\n' "[V15T-102E-TRACE-PREPARE][FAIL] ${label} missing, empty, or symlinked" >&2
    return 2
  }
  [[ "$(sha256sum "${path}" | awk '{print $1}')" == "${expected_sha}" ]] || {
    printf '%s\n' "[V15T-102E-TRACE-PREPARE][FAIL] ${label} hash drift" >&2
    return 2
  }
}

require_frozen_file "${template}" "${expected_template_sha}" template
require_frozen_file "${candidate_reference}" "${expected_candidate_reference_sha}" candidate-reference
require_frozen_file "${hypothesis}" "${expected_hypothesis_sha}" hypothesis

observed_design_id="$(python3 -B -c \
  'from pathlib import Path; from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding; print("sha256:" + rtl_binding(Path.cwd())[0])')"
[[ "${observed_design_id}" == "${expected_design_id}" ]] || {
  printf '%s\n' \
    "[V15T-102E-TRACE-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

mkdir -p -- "${driver_dir}"
[[ ! -e "${generated}" ]] || {
  printf '%s\n' "[V15T-102E-TRACE-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}

sed \
  -e 's|2026-08-07-rv64-v15r-current-timing-trace-337-a1|2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1|g' \
  -e 's|traceable-names-a1|traceable-102e-a1|g' \
  -e 's|v15r-current-timing-trace-337-a1|v15t-dbranch-head-facts-102e-ppa-a1|g' \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/evidence/current-reference-ppa-337-a1.json|.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/ppa-owner-any-live-e7da-a1/summary.json|g' \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/evidence/current-timing-path-analysis-337-a1.json|.github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1/evidence/e7da-top40-cluster-and-hypothesis-v1.json|g' \
  -e 's|\[v15r-timing-trace\]|[v15t-102e-timing-trace]|g' \
  "${template}" >"${generated}"

python3 -B - "${generated}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
start_marker = 'if [[ "${parser_rc}" -eq 0 ]]; then\n  task_run_status_stage traceable-name-check\n'
end_marker = '\nif [[ "${trace_rc}" -eq 0 ]]; then\n'
if text.count(start_marker) != 1:
    raise SystemExit("traceability start marker count is not exactly one")
start = text.index(start_marker)
end = text.index(end_marker, start)
new = '''if [[ "${parser_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-name-check
  trace_rc=0
  start_count=$(grep -c '^Startpoint:' "${evidence_dir}/opensta-top40.rpt") || trace_rc=1
  endpoint_count=$(grep -c '^Endpoint:' "${evidence_dir}/opensta-top40.rpt") || trace_rc=1
  public_flat_starts=$(grep -Ec '^Startpoint: u_core_.*_DFF.*_D$' \
    "${evidence_dir}/opensta-top40.rpt") || true
  public_flat_endpoints=$(grep -Ec '^Endpoint: u_core_.*_DFF.*_D$' \
    "${evidence_dir}/opensta-top40.rpt") || true
  opaque_starts=$(grep -Ec '^Startpoint: _[0-9]+_' \
    "${evidence_dir}/opensta-top40.rpt") || true
  opaque_endpoints=$(grep -Ec '^Endpoint: _[0-9]+_' \
    "${evidence_dir}/opensta-top40.rpt") || true
  [[ "${start_count}" -eq 40 && "${endpoint_count}" -eq 40 && \
      "${public_flat_starts}" -eq 40 && "${public_flat_endpoints}" -eq 40 && \
      "${opaque_starts}" -eq 0 && "${opaque_endpoints}" -eq 0 ]] || trace_rc=1
  printf 'status=%s\nstartpoints=%s\nendpoints=%s\npublic_flat_startpoints=%s\npublic_flat_endpoints=%s\nopaque_startpoints=%s\nopaque_endpoints=%s\n' \
    "$([[ "${trace_rc}" -eq 0 ]] && printf PASS || printf FAIL)" \
    "${start_count}" "${endpoint_count}" "${public_flat_starts}" \
    "${public_flat_endpoints}" "${opaque_starts}" "${opaque_endpoints}" \
    >"${evidence_dir}/traceability.txt"
fi
'''
path.write_text(text[:start] + new + text[end:], encoding="utf-8")
PY

chmod 0755 "${generated}"

printf '%s\n' \
  "[V15T-102E-TRACE-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15T-102E-TRACE-PREPARE] driver=${generated}"
exec "${generated}"
