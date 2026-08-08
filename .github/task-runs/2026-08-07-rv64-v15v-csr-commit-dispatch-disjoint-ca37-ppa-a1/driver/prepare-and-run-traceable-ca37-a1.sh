#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_id=2026-08-07-rv64-v15v-csr-commit-dispatch-disjoint-ca37-ppa-a1
template="${repo_root}/.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/driver/run-traceable-e34b-a1.generated.sh"
driver_dir="${repo_root}/.github/task-runs/${run_id}/driver"
generated="${driver_dir}/run-traceable-ca37-a1.generated.sh"
candidate_reference="${repo_root}/.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/traceable-e34b-a1/summary.json"
path_analysis="${repo_root}/.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/ppa-delta-and-path-cluster-v1.json"
expected_template_sha=22881a6e1289864f704baa74fa0c2196d9f2f8e9b161e38fccbe15c8ff9f7d76
expected_candidate_reference_sha=66d86fa78fe98b7521fb2282be2140d6666a35a171505069fb597c7b1851b5cc
expected_path_analysis_sha=d19d2ef198f3716adfb099a380329146ed34d85aca0a6bfb2d078cc84c963cb5
expected_design_id=sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f

require_frozen_file() {
  local path=$1
  local expected_sha=$2
  local label=$3
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || {
    printf '%s\n' "[V15V-CA37-TRACE-PREPARE][FAIL] ${label} missing, empty, or symlinked" >&2
    return 2
  }
  [[ "$(sha256sum "${path}" | awk '{print $1}')" == "${expected_sha}" ]] || {
    printf '%s\n' "[V15V-CA37-TRACE-PREPARE][FAIL] ${label} hash drift" >&2
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
    "[V15V-CA37-TRACE-PREPARE][FAIL] design-id expected=${expected_design_id} observed=${observed_design_id}" >&2
  exit 2
}

mkdir -p -- "${driver_dir}"
[[ ! -e "${generated}" ]] || {
  printf '%s\n' \
    "[V15V-CA37-TRACE-PREPARE][FAIL] generated driver already exists: ${generated}" >&2
  exit 2
}

sed \
  -e 's|.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/traceable-102e-a1/summary.json|__V15V_CANDIDATE_REFERENCE__|g' \
  -e 's|.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/ppa-delta-and-path-cluster-v1.json|__V15V_PATH_ANALYSIS__|g' \
  -e 's|2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1|2026-08-07-rv64-v15v-csr-commit-dispatch-disjoint-ca37-ppa-a1|g' \
  -e 's|traceable-e34b-a1|traceable-ca37-a1|g' \
  -e 's|v15u-csr-dispatch-permit-e34b-ppa-a1|v15v-csr-commit-dispatch-disjoint-ca37-ppa-a1|g' \
  -e 's|__V15V_CANDIDATE_REFERENCE__|.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/traceable-e34b-a1/summary.json|g' \
  -e 's|__V15V_PATH_ANALYSIS__|.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/ppa-delta-and-path-cluster-v1.json|g' \
  -e 's|\[v15u-e34b-timing-trace\]|[v15v-ca37-timing-trace]|g' \
  "${template}" >"${generated}"

chmod 0755 "${generated}"

printf '%s\n' \
  "[V15V-CA37-TRACE-PREPARE][PASS] design_id=${observed_design_id}" \
  "[V15V-CA37-TRACE-PREPARE] driver=${generated}"
exec "${generated}"
