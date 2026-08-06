#!/usr/bin/env bash

set -uo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${script_dir}/../../../../.." && pwd)
tier=fast

if [[ $# -eq 2 && $1 == "--tier" && ($2 == "fast" || $2 == "link") ]]; then
  tier=$2
elif [[ $# -ne 0 ]]; then
  printf '%s\n' "usage: $0 [--tier fast|link]" >&2
  exit 2
fi

contract="${script_dir}/owner-timing-contract-v1.json"
profile="${script_dir}/owner-timing-validation-profile-v1.json"
baseline="${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json"
probe="${script_dir}/NpcOooOwnerTimingProbe.sv"
collector="${script_dir}/owner_timing_collector.cpp"
extension="${script_dir}/owner-timing.mk"
workload_runner="${repo_root}/npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh"
workload_tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
workload_test="${repo_root}/npc/rv64/eval/ppa/tests/test_owner_timing_workload_ab.py"
runtime_base="${repo_root}/.github/runtime-artifacts/owner-timing"
mkdir -p "${runtime_base}" || exit 1
runtime_dir=$(mktemp -d "${runtime_base}/${tier}.XXXXXX") || exit 1

cleanup_runtime() {
  local command_rc=$?
  local cleanup_rc=0
  local resolved

  resolved=$(realpath -m -- "${runtime_dir}") || cleanup_rc=1
  if [[ "${cleanup_rc}" -eq 0 ]]; then
    case "${resolved}" in
      "${runtime_base}/"*) rm -rf -- "${resolved}" || cleanup_rc=1 ;;
      *) cleanup_rc=1 ;;
    esac
  fi
  if [[ "${cleanup_rc}" -eq 0 ]]; then
    printf '%s\n' "[OWNER-TIMING-CLEANUP][PASS]"
  else
    printf '%s\n' "[OWNER-TIMING-CLEANUP][FAIL] path=${runtime_dir}" >&2
  fi
  if [[ "${command_rc}" -ne 0 ]]; then
    exit "${command_rc}"
  fi
  exit "${cleanup_rc}"
}
trap cleanup_runtime EXIT

run_step() {
  local step=$1
  shift
  local log="${runtime_dir}/${step}.log"
  local rc=0

  "$@" >"${log}" 2>&1 || rc=$?
  if [[ "${rc}" -ne 0 ]]; then
    printf '[OWNER-TIMING-STEP][FAIL] step=%s rc=%s\n' "${step}" "${rc}" >&2
    tail -n 80 "${log}" >&2
    return "${rc}"
  fi
  if [[ "${step}" == "cpp-unit" ]]; then
    if ! grep -Fq '[OWNER-TIMING-UNIT][PASS]' "${log}"; then
      printf '%s\n' '[OWNER-TIMING-STEP][FAIL] step=cpp-unit missing-pass-marker' >&2
      tail -n 80 "${log}" >&2
      return 1
    fi
  fi
  printf '[OWNER-TIMING-STEP][PASS] step=%s\n' "${step}"
  if [[ "${step}" == "cpp-unit" ]]; then
    grep -F '[OWNER-TIMING-UNIT][PASS]' "${log}"
  fi
  return 0
}

validate_contract() {
  jq -e '
    .schema == "npc-rv64-owner-timing-contract-v1" and
    .bridge_sample_bits.station_cancel == [38, 38] and
    .bridge_sample_bits.active_drop == [39, 39] and
    .bridge_sample_bits.response_fire == [40, 40] and
    .state_encoding.illegal == [13, 14, 15] and
    (.stages | index("sq_query")) != null and
    .authorization.optimization_candidate_authorized == false and
    .authorization.ppa == "UNQUALIFIED"
  ' "${contract}"
}

validate_profile() {
  jq -e --arg tier "${tier}" '
    .schema == "npc-rv64-owner-timing-validation-profile-v1" and
    .task_class == "diagnostic" and
    .required_configuration.CONFIG_NPC_OOO_STATS == "y" and
    .required_configuration.production_filelist_modified == false and
    .required_configuration.production_top_modified == false and
    (.tiers[$tier].steps | type) == "array" and
    .authorization.optimization_candidate_authorized == false and
    .authorization.ppa == "UNQUALIFIED"
  ' "${profile}"
}

validate_baseline_binding() {
  local design_id
  design_id=$(jq -er '.binding.design_id' "${profile}") || return
  jq -e --arg design_id "${design_id}" '
    .schema == "npc-rv64-performance-baseline-current-v2" and
    .design_id == $design_id
  ' "${baseline}"
}

validate_source_abi() {
  local expected
  for expected in \
    'bridge0_sample_w[38] = bridge0_station_cancel_i;' \
    'bridge0_sample_w[39] = bridge0_active_drop_i;' \
    'bridge0_sample_w[40] = bridge0_response_fire_i;' \
    'bridge1_sample_w[38] = bridge1_station_cancel_i;' \
    'bridge1_sample_w[39] = bridge1_active_drop_i;' \
    'bridge1_sample_w[40] = bridge1_response_fire_i;' \
    'sample.station_cancel = field(value, 38, 1) != 0;' \
    'sample.active_drop = field(value, 39, 1) != 0;' \
    'sample.response_fire = field(value, 40, 1) != 0;'
  do
    grep -Fq "${expected}" "${probe}" "${collector}" || return 1
  done
}

validate_config_fail_closed() {
  local log="${runtime_dir}/config-negative-inner.log"
  if make -s -C "${repo_root}/npc/rv64" -f Makefile \
      -f eval/ppa/instrumentation/owner-timing.mk lint \
      CONFIG_NPC_OOO_STATS=n >"${log}" 2>&1; then
    return 1
  fi
  grep -Fq 'owner-timing.mk requires CONFIG_NPC_OOO_STATS=y' "${log}"
}

validate_script_syntax() {
  bash -n "${script_dir}/check-owner-timing.sh" \
    "${repo_root}/npc/rv64/eval/ppa/run-owner-timing-diagnostics.sh" \
    "${repo_root}/npc/rv64/eval/ppa/replay-owner-timing-link.sh" \
    "${workload_runner}" &&
    python3 -B "${workload_tool}" --help >/dev/null
}

production_identity() {
  find "${repo_root}/npc/rv64/vsrc" -type f \
    \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o \
       -name '*.svh' -o -name '*.mk' \) -print0 |
    sort -z | xargs -0 sha256sum
  sha256sum "${repo_root}/npc/rv64/include/generated/autoconf.h" \
            "${repo_root}/npc/rv64/include/config/auto.conf"
}

run_step contract validate_contract || exit $?
run_step profile validate_profile || exit $?
run_step baseline-binding validate_baseline_binding || exit $?
run_step source-abi validate_source_abi || exit $?
run_step config-negative validate_config_fail_closed || exit $?
run_step script-syntax validate_script_syntax || exit $?
run_step workload-consumer-unit python3 -B "${workload_test}" || exit $?
production_identity >"${runtime_dir}/production-before.sha256" || exit 1

run_step cpp-compile \
  g++ -std=c++17 -O2 -Wall -Wextra -Werror \
  -DNPC_OWNER_TIMING_UNIT_TEST "${collector}" \
  -o "${runtime_dir}/owner-timing-unit" || exit $?
run_step cpp-unit "${runtime_dir}/owner-timing-unit" || exit $?
run_step sv-lint \
  make -s -C "${repo_root}/npc/rv64" -f Makefile \
  -f eval/ppa/instrumentation/owner-timing.mk lint \
  CONFIG_NPC_OOO_STATS=y || exit $?

if [[ "${tier}" == "link" ]]; then
  run_step full-dpi-link \
    make -s -C "${repo_root}/npc/rv64" -f Makefile \
    -f eval/ppa/instrumentation/owner-timing.mk \
    CONFIG_NPC_OOO_STATS=y BUILD_DIR="${runtime_dir}/build" || exit $?
  sha256sum "${runtime_dir}/build/NpcSimTop" |
    sed 's#  .*#  diagnostic-simulator#'
fi

production_identity >"${runtime_dir}/production-after.sha256" || exit 1
if ! cmp -s "${runtime_dir}/production-before.sha256" \
             "${runtime_dir}/production-after.sha256"; then
  printf '%s\n' '[OWNER-TIMING-IDENTITY][FAIL] production observation inputs drifted' >&2
  diff -u "${runtime_dir}/production-before.sha256" \
          "${runtime_dir}/production-after.sha256" >&2 || true
  exit 1
fi

printf '%s\n' '[OWNER-TIMING-IDENTITY][PASS] production-observation-inputs-stable=1'
printf '[OWNER-TIMING-PRODUCTION-MANIFEST] sha256=%s files=%s\n' \
  "$(sha256sum "${runtime_dir}/production-after.sha256" | cut -d ' ' -f 1)" \
  "$(wc -l <"${runtime_dir}/production-after.sha256" | tr -d ' ')"
sha256sum "${contract}" "${profile}" "${probe}" "${collector}" "${extension}" |
  sed "s#${repo_root}/##"
printf '[OWNER-TIMING-TOOL] %s\n' "$(g++ --version | sed -n '1p')"
printf '[OWNER-TIMING-TOOL] %s\n' "$(verilator --version)"
printf '[OWNER-TIMING-CHECK][PASS] tier=%s unit_cases=12 workload_cases=14 candidate_authorized=0 ppa=UNQUALIFIED\n' "${tier}"
