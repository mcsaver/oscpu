#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
rtl_source="${workspace_dir}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 RESULT_DIR" >&2
  exit 2
fi

result_dir="$(realpath -m "$1")"
mkdir -p "${result_dir}"
work_dir="${result_dir}/work.$$"
mkdir -p "${work_dir}"

cleanup() {
  case "${work_dir}" in
    "${result_dir}"/work.*)
      rm -r -- "${work_dir}"
      ;;
    *)
      echo "[ADAPTER-INPUT-AW-W-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

mutated_rtl="${work_dir}/OooLsuAxiLaneAdapter.v"
mutation_result_dir="${result_dir}/mutation"
driver_log="${result_dir}/driver.log"
result_file="${result_dir}/result.txt"
mutation_diff="${result_dir}/no-input-aw-w-fallthrough.diff"
test_log="${mutation_result_dir}/logs/tb_ooo_owner_timing_causal_probe.log"
production_sha_before="$(sha256sum "${rtl_source}" | awk '{print $1}')"

cp -- "${rtl_source}" "${mutated_rtl}"
anchor_count="$(grep -Fc 'wire direct_write_offer_w = !rst && idle_w &&' \
  "${mutated_rtl}" || true)"
if [[ "${anchor_count}" != 1 ]]; then
  printf '%s\n' 'RESULT=FAIL' 'STAGE=mutation-anchor' \
    "DIRECT_OFFER_ANCHOR_COUNT=${anchor_count}" >"${result_file}"
  exit 1
fi
perl -0pi -e \
  's/wire direct_write_offer_w = !rst \&\& idle_w \&\&/wire direct_write_offer_w = 1\x27b0 \&\& !rst \&\& idle_w \&\& \/* MUTATION_DISABLE_INPUT_AW_W_FALLTHROUGH *\//g' \
  "${mutated_rtl}"
if [[ "$(grep -Fc 'MUTATION_DISABLE_INPUT_AW_W_FALLTHROUGH' \
        "${mutated_rtl}" || true)" != 1 ]]; then
  printf '%s\n' 'RESULT=FAIL' 'STAGE=mutation-apply' >"${result_file}"
  exit 1
fi
diff -u --label production/OooLsuAxiLaneAdapter.v \
  --label mutation/OooLsuAxiLaneAdapter.v \
  "${rtl_source}" "${mutated_rtl}" >"${mutation_diff}" || true

set +e
make -C "${testbench_dir}" owner-timing-causal-probe-focused \
  "RTL_OOO_LSU_AXI_LANE_ADAPTER=${mutated_rtl}" \
  "RESULT_DIR=${mutation_result_dir}" \
  "BUILD_DIR=${work_dir}/build" >"${driver_log}" 2>&1
make_rc=$?
set -e

compile_success=0
mutation_detected=0
if [[ -s "${work_dir}/build/tb_ooo_owner_timing_causal_probe.vvp" ]]; then
  compile_success=1
fi
if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
   grep -Fq 'b_delay=0 peer=0 store_terminal_cycles=2' "${test_log}" &&
   grep -Fq 'b_delay=2 peer=0 store_terminal_cycles=4' "${test_log}" &&
   grep -Fq 'b_delay=5 peer=0 store_terminal_cycles=7' "${test_log}" &&
   grep -Fq 'b_delay=0 peer=1 store_terminal_cycles=2 peer_admission_cycles=3' "${test_log}" &&
   grep -Fq 'b_delay=2 peer=1 store_terminal_cycles=4 peer_admission_cycles=5' "${test_log}" &&
   grep -Fq 'b_delay=5 peer=1 store_terminal_cycles=7 peer_admission_cycles=8' "${test_log}" &&
   grep -Fq '[OWNER-TIMING-CAUSAL-PROBE][FAIL] adapter write-path fall-through absolute terminal latency mismatch' "${test_log}" &&
   grep -Fq '[RESULT] FAIL' "${test_log}"; then
  mutation_detected=1
fi
production_sha_after="$(sha256sum "${rtl_source}" | awk '{print $1}')"

result=FAIL
if [[ ${compile_success} -eq 1 && ${mutation_detected} -eq 1 &&
      "${production_sha_before}" == "${production_sha_after}" ]]; then
  result=PASS
fi
printf '%s\n' \
  "RESULT=${result}" \
  'MUTATION=no-input-aw-w-fallthrough' \
  "COMPILE_SUCCESS=${compile_success}" \
  "MUTATION_DETECTED=${mutation_detected}" \
  'EXPECTED_TEST_FAILURE=1' \
  'EXPECTED_STORE_TERMINAL=2,4,7' \
  'EXPECTED_PEER_ADMISSION=3,5,8' \
  "MAKE_RC=${make_rc}" \
  "PRODUCTION_SHA_BEFORE=${production_sha_before}" \
  "PRODUCTION_SHA_AFTER=${production_sha_after}" \
  "TEST_LOG=${test_log}" \
  "MUTATION_DIFF=${mutation_diff}" >"${result_file}"
cat "${result_file}"
[[ "${result}" == PASS ]]
