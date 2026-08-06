#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
rtl_source="${workspace_dir}/npc/rv64/vsrc/execute/OooIntBackend.v"

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
      rm -rf -- "${work_dir}"
      ;;
    *)
      echo "[V14R-MUTATION][CLEANUP-REFUSED] unexpected work path ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

production_sha_before="$(sha256sum "${rtl_source}" | awk '{print $1}')"
result_file="${result_dir}/result.txt"
variant_pass_count=0
variant_total=6
overall_result=PASS

apply_mutation() {
  local name=$1
  local mutated_rtl=$2
  local anchor_count=0
  local expected_count=0
  case "${name}" in
    holder-bypass)
      perl -0pi -e '
        s/wire \[5:0\] mem_req_effective_sel_w = mem_req_hold_valid_q \?\n      \(mem_req_hold_active_w \? mem_req_hold_sel_q : 6\x27b0\) :\n      live_mem_req_sel_w;/wire [5:0] mem_req_effective_sel_w = live_mem_req_sel_w;/g;
        s/wire \[2:0\] mem1_req_effective_sel_w = mem1_req_hold_valid_q \?\n      \(mem1_req_hold_active_w \? mem1_req_hold_sel_q : 3\x27b0\) :\n      live_mem1_req_sel_w;/wire [2:0] mem1_req_effective_sel_w = live_mem1_req_sel_w;/g;
      ' "${mutated_rtl}"
      anchor_count=$((
        $(grep -Fc 'wire [5:0] mem_req_effective_sel_w = live_mem_req_sel_w;' "${mutated_rtl}" || true) +
        $(grep -Fc 'wire [2:0] mem1_req_effective_sel_w = live_mem1_req_sel_w;' "${mutated_rtl}" || true)
      ))
      expected_count=2
      ;;
    cancel-fallback)
      perl -0pi -e '
        s/wire \[5:0\] mem_req_effective_sel_w = mem_req_hold_valid_q \?\n      \(mem_req_hold_active_w \? mem_req_hold_sel_q : 6\x27b0\) :\n      live_mem_req_sel_w;/wire [5:0] mem_req_effective_sel_w = mem_req_hold_valid_q ?\n      (mem_req_hold_active_w ? mem_req_hold_sel_q : live_mem_req_sel_w) :\n      live_mem_req_sel_w;/g;
        s/wire \[2:0\] mem1_req_effective_sel_w = mem1_req_hold_valid_q \?\n      \(mem1_req_hold_active_w \? mem1_req_hold_sel_q : 3\x27b0\) :\n      live_mem1_req_sel_w;/wire [2:0] mem1_req_effective_sel_w = mem1_req_hold_valid_q ?\n      (mem1_req_hold_active_w ? mem1_req_hold_sel_q : live_mem1_req_sel_w) :\n      live_mem1_req_sel_w;/g;
      ' "${mutated_rtl}"
      anchor_count=$((
        $(grep -Fc '(mem_req_hold_active_w ? mem_req_hold_sel_q : live_mem_req_sel_w)' "${mutated_rtl}" || true) +
        $(grep -Fc '(mem1_req_hold_active_w ? mem1_req_hold_sel_q : live_mem1_req_sel_w)' "${mutated_rtl}" || true)
      ))
      expected_count=2
      ;;
    consume-miq-live-split)
      perl -0pi -e '
        s/\(grant_issue0_w && mem_req_ready_i\) \|\|\n      \(grant_mem1_issue0_w && mem1_req_ready_i\)/(live_grant_issue0_w && mem_req_ready_i) ||\n      (live_grant_mem1_issue0_w && mem1_req_ready_i)/g;
        s/\(grant_issue1_w && mem_req_ready_i\) \|\|\n      \(grant_mem1_issue1_w && mem1_req_ready_i\)/(live_grant_issue1_w && mem_req_ready_i) ||\n      (live_grant_mem1_issue1_w && mem1_req_ready_i)/g;
        s/wire push_issue0_w = grant_issue0_w/wire push_issue0_w = live_grant_issue0_w/g;
        s/wire push_issue1_w = grant_issue1_w/wire push_issue1_w = live_grant_issue1_w/g;
        s/wire push_mem1_issue0_w = grant_mem1_issue0_w/wire push_mem1_issue0_w = live_grant_mem1_issue0_w/g;
        s/wire push_mem1_issue1_w = grant_mem1_issue1_w/wire push_mem1_issue1_w = live_grant_mem1_issue1_w/g;
      ' "${mutated_rtl}"
      anchor_count=$((
        $(grep -Fc '(live_grant_issue0_w && mem_req_ready_i)' "${mutated_rtl}" || true) +
        $(grep -Fc '(live_grant_mem1_issue0_w && mem1_req_ready_i)' "${mutated_rtl}" || true) +
        $(grep -Fc '(live_grant_issue1_w && mem_req_ready_i)' "${mutated_rtl}" || true) +
        $(grep -Fc '(live_grant_mem1_issue1_w && mem1_req_ready_i)' "${mutated_rtl}" || true) +
        $(grep -Fc 'wire push_issue0_w = live_grant_issue0_w' "${mutated_rtl}" || true) +
        $(grep -Fc 'wire push_issue1_w = live_grant_issue1_w' "${mutated_rtl}" || true) +
        $(grep -Fc 'wire push_mem1_issue0_w = live_grant_mem1_issue0_w' "${mutated_rtl}" || true) +
        $(grep -Fc 'wire push_mem1_issue1_w = live_grant_mem1_issue1_w' "${mutated_rtl}" || true)
      ))
      expected_count=8
      ;;
    single-bank-probe-order)
      perl -0pi -e '
        s/       !\(sq_mode_w && issue0_is_plain_store_w &&\n         issue0_miq_probe_block_r\)\);/       1\x27b1); \/\* V14R_MUTATION_SINGLE_BANK_PROBE_ORDER_BYPASS0 \*\//g;
        s/       !\(sq_mode_w && issue1_is_plain_store_w &&\n         issue1_miq_probe_block_r\)\);/       1\x27b1); \/\* V14R_MUTATION_SINGLE_BANK_PROBE_ORDER_BYPASS1 \*\//g;
      ' "${mutated_rtl}"
      anchor_count="$(grep -Fc 'V14R_MUTATION_SINGLE_BANK_PROBE_ORDER_BYPASS' "${mutated_rtl}" || true)"
      expected_count=2
      ;;
    sq-held-launch-residency)
      perl -0pi -e '
        s/sq_drain_source_resident_w && !drain_inflight_q &&/sq_drain_valid_w \&\& !drain_inflight_q \&\& \/\* V14R_MUTATION_SQ_HELD_USES_LIVE_VALID *\//g;
      ' "${mutated_rtl}"
      anchor_count="$(grep -Fc 'V14R_MUTATION_SQ_HELD_USES_LIVE_VALID' "${mutated_rtl}" || true)"
      expected_count=1
      ;;
    amo-held-launch-authorization)
      perl -0pi -e '
        s/wire mem_amo_fire_authorized_w = mem_amo_launch_authorized_w \|\|\n      \(mem_req_hold_active_w &&\n       mem_req_hold_sel_q\[MEM_REQ_SEL_AMO\] && mem_amo_owner_lease_w\);/wire mem_amo_fire_authorized_w = mem_amo_launch_authorized_w; \/\* V14R_MUTATION_AMO_HELD_USES_LIVE_AUTH *\//g;
      ' "${mutated_rtl}"
      anchor_count="$(grep -Fc 'V14R_MUTATION_AMO_HELD_USES_LIVE_AUTH' "${mutated_rtl}" || true)"
      expected_count=1
      ;;
    *)
      return 2
      ;;
  esac
  [[ "${anchor_count}" == "${expected_count}" ]]
}

run_variant() {
  local name=$1
  local make_target=$2
  local test_stem=$3
  local variant_dir="${result_dir}/${name}"
  local variant_work="${work_dir}/${name}"
  local mutated_rtl="${variant_work}/OooIntBackend.v"
  local mutation_result_dir="${variant_dir}/mutation"
  local mutation_build_dir="${variant_work}/build"
  local driver_log="${variant_dir}/driver.log"
  local variant_result="${variant_dir}/result.txt"
  local mutation_diff="${variant_dir}/${name}.diff"
  local test_log="${mutation_result_dir}/logs/${test_stem}.log"
  local compile_success=0
  local mutation_detected=0
  local make_rc=0
  local production_sha_after_variant
  local result=FAIL
  local expected_marker

  case "${name}" in
    holder-bypass)
      expected_marker='[V14R-H2-BANK0-PAYLOAD-HOLD]'
      ;;
    cancel-fallback)
      expected_marker='[V14R-H4-BANK0-CANCEL-BUBBLE]'
      ;;
    consume-miq-live-split)
      expected_marker='[CHECK-FAIL] V14R bank0 exact reservation consumes'
      ;;
    single-bank-probe-order)
      expected_marker='[CHECK-FAIL] V14R younger probe has zero VALID'
      ;;
    sq-held-launch-residency)
      expected_marker='[V14R-H4-BANK0-SOURCE-LOSS]'
      ;;
    amo-held-launch-authorization)
      expected_marker='[V8G-AMO-LAUNCH-AUTH]'
      ;;
    *)
      return 2
      ;;
  esac

  mkdir -p "${variant_dir}" "${variant_work}"
  cp -- "${rtl_source}" "${mutated_rtl}"
  if ! apply_mutation "${name}" "${mutated_rtl}"; then
    printf '%s\n' 'RESULT=FAIL' "MUTATION=${name}" \
      'STAGE=mutation-anchor' >"${variant_result}"
    return 1
  fi
  diff -u --label production/OooIntBackend.v \
    --label "mutation/${name}/OooIntBackend.v" \
    "${rtl_source}" "${mutated_rtl}" >"${mutation_diff}" || true

  set +e
  make -C "${testbench_dir}" "${make_target}" \
    "RTL_OOO_INT_BACKEND=${mutated_rtl}" \
    "RESULT_DIR=${mutation_result_dir}" \
    "BUILD_DIR=${mutation_build_dir}" >"${driver_log}" 2>&1
  make_rc=$?
  set -e

  production_sha_after_variant="$(sha256sum "${rtl_source}" | awk '{print $1}')"
  if [[ -s "${mutation_build_dir}/${test_stem}.vvp" ]]; then
    compile_success=1
  fi
  if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
     grep -Fq "${expected_marker}" "${test_log}" &&
     grep -Fq '[RESULT] FAIL' "${test_log}"; then
    mutation_detected=1
  fi
  if [[ ${compile_success} -eq 1 && ${mutation_detected} -eq 1 &&
        "${production_sha_before}" == "${production_sha_after_variant}" ]]; then
    result=PASS
  fi
  printf '%s\n' \
    "RESULT=${result}" \
    "MUTATION=${name}" \
    "EXPECTED_MARKER=${expected_marker}" \
    "COMPILE_SUCCESS=${compile_success}" \
    "MUTATION_DETECTED=${mutation_detected}" \
    'EXPECTED_TEST_FAILURE=1' \
    "MAKE_RC=${make_rc}" \
    "PRODUCTION_SHA_BEFORE=${production_sha_before}" \
    "PRODUCTION_SHA_AFTER=${production_sha_after_variant}" \
    "TEST_LOG=${test_log}" \
    "MUTATION_DIFF=${mutation_diff}" >"${variant_result}"
  sed -n '1,20p' "${variant_result}"
  [[ "${result}" == "PASS" ]]
}

if run_variant holder-bypass v14r-memory-request-hold-focused \
    tb_ooo_int_backend_v14r_memory_request_hold; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi
if run_variant cancel-fallback v14r-memory-request-hold-focused \
    tb_ooo_int_backend_v14r_memory_request_hold; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi
if run_variant consume-miq-live-split v14r-memory-request-hold-focused \
    tb_ooo_int_backend_v14r_memory_request_hold; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi
if run_variant single-bank-probe-order \
    v14r-single-bank-probe-order-focused \
    tb_ooo_int_backend_v14r_single_bank_probe_order; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi
if run_variant sq-held-launch-residency \
    v14r-memory-request-hold-focused \
    tb_ooo_int_backend_v14r_memory_request_hold; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi
if run_variant amo-held-launch-authorization \
    v14r-memory-request-hold-focused \
    tb_ooo_int_backend_v14r_memory_request_hold; then
  variant_pass_count=$((variant_pass_count + 1))
else
  overall_result=FAIL
fi

production_sha_after="$(sha256sum "${rtl_source}" | awk '{print $1}')"
if [[ "${production_sha_before}" != "${production_sha_after}" ]]; then
  overall_result=FAIL
fi
aggregate_complete=0
if [[ "${variant_pass_count}" == "${variant_total}" ]]; then
  aggregate_complete=1
fi
printf '%s\n' \
  "RESULT=${overall_result}" \
  "VARIANT_TOTAL=${variant_total}" \
  "VARIANT_PASS_COUNT=${variant_pass_count}" \
  "COMPILE_SUCCESS=${aggregate_complete}" \
  "MUTATION_DETECTED=${aggregate_complete}" \
  "PRODUCTION_SHA_BEFORE=${production_sha_before}" \
  "PRODUCTION_SHA_AFTER=${production_sha_after}" >"${result_file}"
sed -n '1,20p' "${result_file}"
[[ "${overall_result}" == "PASS" &&
   "${variant_pass_count}" == "${variant_total}" ]]
