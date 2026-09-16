#!/usr/bin/env bash
set -euo pipefail

# Focused historical-defect evidence runner; not part of the module TB inventory.

usage() {
  printf 'usage: %s --result-dir .github/task-runs/<run>/evidence/<name>\n' "$0"
}

result_arg=
while (($#)); do
  case "$1" in
    --result-dir)
      (($# >= 2)) || { usage >&2; exit 2; }
      result_arg=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done
[[ -n ${result_arg} ]] || { usage >&2; exit 2; }

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/../../../.." && pwd)
result_root=$(realpath -m -- "${repo_root}/${result_arg}")
case "${result_root}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '[RV64-V9R-CURRENT][FAIL] result-dir must stay below .github/task-runs\n' >&2
    exit 2
    ;;
esac
[[ ! -e ${result_root} && ! -L ${result_root} ]] || {
  printf '[RV64-V9R-CURRENT][FAIL] result-dir must not already exist\n' >&2
  exit 2
}

tb_dir=${repo_root}/npc/rv64/testbench
backend=${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v
bridge=${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v
mutation_tool=${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py
mkdir -p -- "${repo_root}/.github/runtime-artifacts"
build_root=$(mktemp -d "${repo_root}/.github/runtime-artifacts/v9r-current.XXXXXXXX")
cleanup() {
  rm -rf -- "${build_root}"
}
trap cleanup EXIT HUP INT TERM

for input in "${backend}" "${bridge}" "${mutation_tool}"; do
  [[ -f ${input} && ! -L ${input} ]] || {
    printf '[RV64-V9R-CURRENT][FAIL] invalid input=%s\n' "${input}" >&2
    exit 2
  }
done
mkdir -p -- "${result_root}"

rtl_design_sha() {
  python3 -B - "${repo_root}" <<'PY'
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture
print(architecture.rtl_binding(root)[0])
PY
}

artifact_fields() {
  local path=$1
  printf '%s\t%s\t%s\n' \
    "${path#${repo_root}/}" \
    "$(sha256sum -- "${path}" | awk '{print $1}')" \
    "$(stat -c '%s' -- "${path}")"
}

design_sha_before=$(rtl_design_sha)
backend_sha_before=$(sha256sum -- "${backend}" | awk '{print $1}')
bridge_sha_before=$(sha256sum -- "${bridge}" | awk '{print $1}')

baseline_result=${result_root}/baseline
baseline_build=${build_root}/baseline
mkdir -p -- "${baseline_result}" "${baseline_build}"
make -B -C "${tb_dir}" -j1 \
  TESTS='tb_ooo_int_backend_v9r_sq_retry_c0 tb_ooo_mem_axi_bridge_v9r_sq_retry_c0' \
  EXTRA_TESTS= BUILD_DIR="${baseline_build}" RESULT_DIR="${baseline_result}" \
  RTL_EVIDENCE_SHA="${design_sha_before}" run \
  >"${baseline_build}/make.log" 2>&1
backend_baseline_log=${baseline_result}/logs/tb_ooo_int_backend_v9r_sq_retry_c0.log
bridge_baseline_log=${baseline_result}/logs/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log
grep -Fq '[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS' "${backend_baseline_log}"
grep -Fq '[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS' "${backend_baseline_log}"
grep -Fq '[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] state=S_SQ_QUERY held=1 release=1 PASS' "${bridge_baseline_log}"
[[ $(grep -Fc '[RESULT] PASS' "${backend_baseline_log}") == 1 ]]
[[ $(grep -Fc '[RESULT] PASS' "${bridge_baseline_log}") == 1 ]]

variant_tsv=${build_root}/variants.tsv
: >"${variant_tsv}"
run_variant() {
  local case_name=$1
  local source=$2
  local rtl_variable=$3
  local test_name=$4
  local marker=$5
  local variant_dir=${result_root}/${case_name}
  local variant_build=${build_root}/${case_name}
  local mutant=${variant_dir}/$(basename -- "${source}")
  local log=${variant_dir}/logs/${test_name}.log
  mkdir -p -- "${variant_dir}" "${variant_build}"
  python3 -B "${mutation_tool}" --root "${repo_root}" mutate \
    --case "${case_name}" --output "${mutant}"

  set +e
  make -B -C "${tb_dir}" -j1 TESTS="${test_name}" EXTRA_TESTS= \
    "${rtl_variable}=${mutant}" BUILD_DIR="${variant_build}" \
    RESULT_DIR="${variant_dir}" RTL_EVIDENCE_SHA="${design_sha_before}" run \
    >"${variant_build}/make.log" 2>&1
  local return_code=$?
  set -e
  [[ ${return_code} -eq 2 ]]
  local image=${variant_build}/${test_name}.vvp
  [[ -s ${image} ]]
  [[ $(grep -Fc "${marker}" "${log}") == 1 ]]
  grep -Fq '[COMPILE]' "${log}"
  grep -Fq '[RESULT] FAIL' "${log}"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${case_name}" "${return_code}" "${mutant#${repo_root}/}" \
    "$(sha256sum -- "${mutant}" | awk '{print $1}')" \
    "${log#${repo_root}/}" "$(sha256sum -- "${log}" | awk '{print $1}')" \
    "$(sha256sum -- "${image}" | awk '{print $1}')" \
    "$(stat -c '%s' -- "${image}")" >>"${variant_tsv}"
}

run_variant backend-bank0-ready-open "${backend}" RTL_OOO_INT_BACKEND \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  '[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed during full-flush barrier'
run_variant backend-bank1-ready-open "${backend}" RTL_OOO_INT_BACKEND \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  '[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed during full-flush barrier'
run_variant bridge-retry-fire-open "${bridge}" RTL_OOO_MEM_AXI_BRIDGE \
  tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 \
  '[V9R-MEM-SQ-RETRY-C0-HANDOFF] bridge released SQ-query owner during full-flush barrier'

design_sha_after=$(rtl_design_sha)
backend_sha_after=$(sha256sum -- "${backend}" | awk '{print $1}')
bridge_sha_after=$(sha256sum -- "${bridge}" | awk '{print $1}')
[[ ${design_sha_after} == "${design_sha_before}" ]]
[[ ${backend_sha_after} == "${backend_sha_before}" ]]
[[ ${bridge_sha_after} == "${bridge_sha_before}" ]]

variants_json=${build_root}/variants.json
jq -Rn '[inputs | split("\t") | {
  id: .[0], result: "REJECTED_COMPILE_SUCCESS_VARIANT",
  make_return_code: (.[1] | tonumber),
  mutated_rtl: {path: .[2], sha256: .[3]},
  log: {path: .[4], sha256: .[5]},
  compiled_image: {sha256: .[6], size_bytes: (.[7] | tonumber), retained: false}
}]' <"${variant_tsv}" >"${variants_json}"

read -r backend_log_path backend_log_sha backend_log_size < <(artifact_fields "${backend_baseline_log}")
read -r bridge_log_path bridge_log_sha bridge_log_size < <(artifact_fields "${bridge_baseline_log}")
summary_tmp=${build_root}/summary.json
jq -n \
  --arg design_id "sha256:${design_sha_before}" \
  --arg backend_sha256 "${backend_sha_before}" \
  --arg bridge_sha256 "${bridge_sha_before}" \
  --arg backend_log_path "${backend_log_path}" \
  --arg backend_log_sha256 "${backend_log_sha}" \
  --argjson backend_log_size "${backend_log_size}" \
  --arg bridge_log_path "${bridge_log_path}" \
  --arg bridge_log_sha256 "${bridge_log_sha}" \
  --argjson bridge_log_size "${bridge_log_size}" \
  --slurpfile variants "${variants_json}" \
  '{
    schema: "npc-rv64-v9r-sq-retry-c0-current-v1", status: "PASS",
    design_id: $design_id,
    production_sources: {
      backend: {path: "npc/rv64/vsrc/execute/OooIntBackend.v", sha256: $backend_sha256},
      bridge: {path: "npc/rv64/vsrc/memory/OooMemAxiBridge.v", sha256: $bridge_sha256}
    },
    baseline: {
      status: "PASS", backend_banks: 2, forced_barrier_cases: 2,
      natural_trap_head_cases: 1, bridge_query_hold_cases: 1,
      logs: {
        backend: {path: $backend_log_path, sha256: $backend_log_sha256, size_bytes: $backend_log_size},
        bridge: {path: $bridge_log_path, sha256: $bridge_log_sha256, size_bytes: $bridge_log_size}
      }
    },
    compile_success_rtl_variants: $variants[0],
    cleanup: {compiled_images_retained: 0, result_logs_retained: 5, negative_rtl_sources_retained: 3}
  }' >"${summary_tmp}"
mv -f -- "${summary_tmp}" "${result_root}/summary.json"

printf '[RV64-V9R-CURRENT][PASS] design_id=sha256:%s baseline=2/2 variants=3/3 compiled-images=0\n' "${design_sha_before}"
