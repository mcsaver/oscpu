#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
run_rel=.github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill
run_dir=${repo_root}/${run_rel}
exact_root=${run_dir}/evidence/v9p-exact-source/sources
base_tb=${run_dir}/evidence/v9p-exact-source/testbench/npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv
derived_tb=${run_dir}/evidence/v9p-bridge-counterexample/derived/tb_ooo_mem_axi_bridge.sv
exact_bridge=${exact_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v
result_root=${run_dir}/evidence/v9p-bridge-counterexample
build_root=${repo_root}/.github/runtime-artifacts/v15g-v9p-bridge-backfill
test_name=tb_ooo_mem_axi_bridge_v9r_sq_retry_c0

case $(realpath -m "${build_root}") in
  "${repo_root}/.github/runtime-artifacts/"*) ;;
  *) exit 2 ;;
esac
[[ ! -L ${result_root} ]]
[[ -f ${base_tb} && ! -L ${base_tb} ]]
[[ -f ${derived_tb} && ! -L ${derived_tb} ]]
[[ -f ${exact_bridge} && ! -L ${exact_bridge} ]]
mkdir -p "${result_root}" "${build_root}"

cleanup() {
  rm -rf -- "${build_root}"
}
trap cleanup EXIT

exact_deps=(
  "${exact_root}/npc/rv64/vsrc/memory/PmpChecker.v"
  "${exact_root}/npc/rv64/vsrc/memory/OooTypedPmaChecker.v"
  "${exact_root}/npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v"
  "${exact_root}/npc/rv64/vsrc/memory/OooPmaChecker.v"
  "${exact_root}/npc/rv64/vsrc/memory/OooPostTranslateMemoryClass.v"
  "${exact_root}/npc/rv64/vsrc/cache/OooDataWordCache.v"
  "${exact_root}/npc/rv64/vsrc/sram/Sram4096x113.v"
  "${exact_root}/npc/rv64/vsrc/memory/OooSv39Tlb.v"
)
current_deps=(
  "${repo_root}/npc/rv64/vsrc/memory/PmpChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooTypedPmaChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooPmaChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooPostTranslateMemoryClass.v"
  "${repo_root}/npc/rv64/vsrc/cache/OooDataWordCache.v"
  "${repo_root}/npc/rv64/vsrc/sram/Sram4096x113.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooSv39Tlb.v"
)
for path in "${exact_deps[@]}" "${current_deps[@]}"; do
  [[ -f ${path} && ! -L ${path} ]]
done

run_make_case() {
  local case_name=$1
  local tb=$2
  local bridge=$3
  local expected=$4
  shift 4
  local deps=("$@")
  local result_dir=${result_root}/${case_name}
  local build_dir=${build_root}/${case_name}
  local log=${result_dir}/logs/${test_name}.log
  local source_list="${tb}"
  local path
  for path in "${deps[@]}"; do
    source_list+=" ${path}"
  done
  source_list+=" ${bridge}"

  mkdir -p "${result_dir}" "${build_dir}"
  local return_code=125
  if [[ ! -e ${log} ]]; then
    set +e
    make -C "${repo_root}/npc/rv64/testbench" -j1 \
      BUILD_DIR="${build_dir}" RESULT_DIR="${result_dir}" \
      "TB_SRCS_${test_name}=${source_list}" "${log}" \
      >"${build_dir}/make.log" 2>&1
    return_code=$?
    set -e
  fi
  [[ -f ${log} && ! -L ${log} ]]
  if [[ ${expected} == PASS ]]; then
    [[ ${return_code} == 125 || ${return_code} == 0 ]]
    [[ $(grep -Fc '[RESULT] PASS' "${log}") == 1 ]]
  else
    [[ ${return_code} == 125 || ${return_code} != 0 ]]
    [[ $(grep -Fc '[RESULT] FAIL status=1' "${log}") == 1 ]]
  fi
}

run_make_case v9p-original-negative "${base_tb}" "${exact_bridge}" FAIL \
  "${exact_deps[@]}"
v9p_negative_log=${result_root}/v9p-original-negative/logs/${test_name}.log
[[ $(grep -Fc '[CHECK-FAIL] V9R bridge C0 forbids retry fire got=1 expected=0' \
      "${v9p_negative_log}") == 1 ]]
[[ $(grep -Fc '[CHECK-FAIL] V9R bridge repeated C0 forbids retry fire got=1 expected=0' \
      "${v9p_negative_log}") == 1 ]]

run_make_case v9p-c0-c1 "${derived_tb}" "${exact_bridge}" PASS \
  "${exact_deps[@]}"
v9p_cycle_log=${result_root}/v9p-c0-c1/logs/${test_name}.log
[[ $(grep -Fc '[V15G-V9P-C0-C1-HANDOFF][PASS] bank0_lanes=2,10' \
      "${v9p_cycle_log}") == 1 ]]

run_make_case current-control "${base_tb}" \
  "${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v" PASS \
  "${current_deps[@]}"
current_log=${result_root}/current-control/logs/${test_name}.log
[[ $(grep -Fc '[CHECK-FAIL]' "${current_log}") == 0 ]]

summary_tmp=${build_root}/summary.json
v9p_negative_sha=$(sha256sum -- "${v9p_negative_log}" | awk '{print $1}')
v9p_cycle_sha=$(sha256sum -- "${v9p_cycle_log}" | awk '{print $1}')
current_sha=$(sha256sum -- "${current_log}" | awk '{print $1}')
exact_bridge_sha=$(sha256sum -- "${exact_bridge}" | awk '{print $1}')
current_bridge_sha=$(sha256sum -- \
  "${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v" | awk '{print $1}')
jq -n \
  --arg schema npc-rv64-v9p-bridge-counterexample-v1 \
  --arg exact_bridge_path "${run_rel}/evidence/v9p-exact-source/sources/npc/rv64/vsrc/memory/OooMemAxiBridge.v" \
  --arg exact_bridge_sha256 "${exact_bridge_sha}" \
  --arg current_bridge_path npc/rv64/vsrc/memory/OooMemAxiBridge.v \
  --arg current_bridge_sha256 "${current_bridge_sha}" \
  --arg negative_path "${run_rel}/evidence/v9p-bridge-counterexample/v9p-original-negative/logs/${test_name}.log" \
  --arg negative_sha256 "${v9p_negative_sha}" \
  --arg cycle_path "${run_rel}/evidence/v9p-bridge-counterexample/v9p-c0-c1/logs/${test_name}.log" \
  --arg cycle_sha256 "${v9p_cycle_sha}" \
  --arg current_path "${run_rel}/evidence/v9p-bridge-counterexample/current-control/logs/${test_name}.log" \
  --arg current_sha256 "${current_sha}" \
  '{
    schema: $schema,
    status: "PASS",
    v9p_rtl: {
      bridge: {path: $exact_bridge_path, sha256: $exact_bridge_sha256},
      dependency_binding: "V9P exact source-manifest hashes",
      focused_negative: {
        result: "REJECTED",
        observed: "C0 retry fire remained high while the bridge barrier retained S_SQ_QUERY",
        log: {path: $negative_path, sha256: $negative_sha256}
      },
      c0_c1_counterexample: {
        result: "PASS",
        observed: "C0 retry capture plus bridge hold; C1 drop0 with the same token",
        bank0_collector_lanes: [2, 10],
        log: {path: $cycle_path, sha256: $cycle_sha256}
      }
    },
    current_rtl: {
      bridge: {path: $current_bridge_path, sha256: $current_bridge_sha256},
      focused_control: {
        result: "PASS",
        observed: "C0 suppresses retry fire and preserves the bridge owner",
        log: {path: $current_path, sha256: $current_sha256}
      }
    },
    cleanup: {compiled_images_retained: 0}
  }' >"${summary_tmp}"
summary=${result_root}/summary.json
if [[ -e ${summary} ]]; then
  cmp -s -- "${summary_tmp}" "${summary}"
else
  mv -- "${summary_tmp}" "${summary}"
fi

printf '[RV64-V9P-BRIDGE-COUNTEREXAMPLE][PASS] v9p=C0-retry+C0-hold+C1-drop0 current=C0-hold compiled-images=0\n'
