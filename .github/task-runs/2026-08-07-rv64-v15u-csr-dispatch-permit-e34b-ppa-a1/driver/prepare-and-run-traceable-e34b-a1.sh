#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_id=2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/driver/run-traceable-102e-a1.generated.sh"
driver_dir="${repo_root}/.github/task-runs/${run_id}/driver"
generated="${driver_dir}/run-traceable-e34b-a1.generated.sh"
candidate_reference="${repo_root}/.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/traceable-102e-a1/summary.json"
path_analysis="${repo_root}/.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/ppa-delta-and-path-cluster-v1.json"
expected_template_sha=74caa2baab3b0485fdbf2ed6a34c2ae5b2fdd4cb1d1ec3ff8b4e1b9b5172c990
expected_candidate_reference_sha=b413fc63647f9c06da322b6ed823dcd1b6a88644117f999d7da7af0dfac17dc3
expected_path_analysis_sha=907ec6913c0a063dbf84a311272cd03dd413825a59c5412edcd5dbc83d1bdf61
expected_design_id=sha256:e34bcf47cf2e69976190cff4a13cf21b4f8f3e18495858b3256e9d5205bec6ce

require_frozen_file() {
  local path=$1
  local expected_sha=$2
  local label=$3
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || {
    printf '%s\n' "[V15U-E34B-TRACE-PREPARE][FAIL] ${label} missing, empty, or symlinked" >&2
    return 2
  }
  [[ "$(sha256sum "${path}" | awk '{print $1}')" == "${expected_sha}" ]] || {
    printf '%s\n' "[V15U-E34B-TRACE-PREPARE][FAIL] ${label} hash drift" >&2
    return 2
  }
}

require_frozen_file "${template}" "${expected_template_sha}" template
require_frozen_file "${candidate_reference}" \
  "${expected_candidate_reference_sha}" candidate-reference
require_frozen_file "${path_analysis}" "${expected_path_analysis_sha}" \
  path-analysis

observed_design_id="$(python3 -B -c \
  'from pathlib import Path; from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding; print("sha256:" + rtl_binding(Path.cwd())[0])')"
[[ "${observed_design_id}" == "${expected_design_id}" ]] || {
  printf '%s\n' \
    "[V15U-E34B-TRACE-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

mkdir -p -- "${driver_dir}"
[[ ! -e "${generated}" ]] || {
  printf '%s\n' \
    "[V15U-E34B-TRACE-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}

sed \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/ppa-owner-any-live-e7da-a1/summary.json|__V15U_CANDIDATE_REFERENCE__|g' \
  -e 's|\.github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1/evidence/e7da-top40-cluster-and-hypothesis-v1.json|__V15U_PATH_ANALYSIS__|g' \
  -e 's|2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1|2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1|g' \
  -e 's|traceable-102e-a1|traceable-e34b-a1|g' \
  -e 's|v15t-dbranch-head-facts-102e-ppa-a1|v15u-csr-dispatch-permit-e34b-ppa-a1|g' \
  -e 's|__V15U_CANDIDATE_REFERENCE__|.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/traceable-102e-a1/summary.json|g' \
  -e 's|__V15U_PATH_ANALYSIS__|.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/ppa-delta-and-path-cluster-v1.json|g' \
  -e 's|\[v15t-102e-timing-trace\]|[v15u-e34b-timing-trace]|g' \
  "${template}" >"${generated}"

chmod 0755 "${generated}"

printf '%s\n' \
  "[V15U-E34B-TRACE-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15U-E34B-TRACE-PREPARE] driver=${generated}"
exec "${generated}"
