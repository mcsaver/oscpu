#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1"
source_rtl="${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v"
vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13q_store_b_error_backpressure.vvp"
suite_result="${task_root}/evidence/mutation-suite-result.json"
mkdir -p "${task_root}/evidence"
# Keep receipt staging on the same filesystem as its final task-run path so
# the final mv is an atomic rename rather than a cross-filesystem copy.
tmp_root="$(mktemp -d "${task_root}/evidence/.mutation-run.XXXXXX")"

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${vvp}"
}
trap cleanup EXIT

source_sha="$(sha256sum "${source_rtl}" | awk '{print $1}')"
rm -f -- "${suite_result}"

run_one() {
  local mutation="$1"
  local expected="$2"
  local result_root="${task_root}/evidence/mutation-${mutation}"
  local variant_rtl="${tmp_root}/${mutation}/OooIntBackend.v"
  local mutation_log="${result_root}/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log"
  local result_json="${result_root}/result.json"
  local result_tmp="${tmp_root}/${mutation}.result.json"
  local make_rc
  local variant_sha

  mkdir -p "$(dirname "${variant_rtl}")" "$(dirname "${mutation_log}")"
  # A failed or interrupted rerun must not inherit a previous PASS receipt or
  # runtime log.  A new receipt is installed atomically only after the expected
  # checker marker and fail-closed DUT result have both been observed.
  rm -f -- "${result_json}" "${mutation_log}"
  case "${mutation}" in
    drain-cause-load-fault)
      if [[ "$(grep -c '^      miq_drain_wb_fire_w ? `EXC_STORE_ACCESS_FAULT :$' "${source_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13Q-MUTATION][FAIL] drain-cause anchor is not unique' >&2
        exit 11
      fi
      sed 's/^      miq_drain_wb_fire_w ? `EXC_STORE_ACCESS_FAULT :$/      miq_drain_wb_fire_w ? `EXC_LOAD_ACCESS_FAULT :/' \
        "${source_rtl}" > "${variant_rtl}"
      ;;
    drain-tval-uses-pa)
      if [[ "$(grep -c 'miq_drain_wb_fire_w ? sq_drain_vaddr_w' "${source_rtl}")" != "2" ]]; then
        printf '%s\n' '[V13Q-MUTATION][FAIL] drain-tval anchors are not exactly two' >&2
        exit 12
      fi
      sed 's/miq_drain_wb_fire_w ? sq_drain_vaddr_w/miq_drain_wb_fire_w ? miq_head_addr_w/g' \
        "${source_rtl}" > "${variant_rtl}"
      ;;
    ignore-formal-wb-credit)
      if [[ "$(grep -c '^      mem_owner_open_w ? mem_open_all_sink_credit_w :$' "${source_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13Q-MUTATION][FAIL] WB-credit anchor is not unique' >&2
        exit 13
      fi
      sed 's/^      mem_owner_open_w ? mem_open_all_sink_credit_w :$/      mem_owner_open_w ? mem_open_nonwb_sink_credit_w :/' \
        "${source_rtl}" > "${variant_rtl}"
      ;;
    *)
      printf '[V13Q-MUTATION][FAIL] unknown mutation %s\n' "${mutation}" >&2
      exit 14
      ;;
  esac

  if cmp -s "${source_rtl}" "${variant_rtl}"; then
    printf '[V13Q-MUTATION][FAIL] mutation %s produced no source delta\n' \
      "${mutation}" >&2
    exit 15
  fi

  rm -f -- "${vvp}"
  set +e
  make -C "${repo_root}/npc/rv64/testbench" \
    "RESULT_DIR=${result_root}" \
    "RTL_OOO_INT_BACKEND=${variant_rtl}" \
    "${mutation_log}"
  make_rc=$?
  set -e
  rm -f -- "${vvp}"

  if [[ "${make_rc}" == "0" ]]; then
    printf '[V13Q-MUTATION][FAIL] mutation %s remained green\n' \
      "${mutation}" >&2
    exit 16
  fi
  if ! grep -Fq "${expected}" "${mutation_log}"; then
    printf '[V13Q-MUTATION][FAIL] mutation %s missed marker %s\n' \
      "${mutation}" "${expected}" >&2
    exit 17
  fi
  if ! grep -Fq '[RESULT] FAIL' "${mutation_log}"; then
    printf '[V13Q-MUTATION][FAIL] mutation %s lacks fail-closed result\n' \
      "${mutation}" >&2
    exit 18
  fi

  variant_sha="$(sha256sum "${variant_rtl}" | awk '{print $1}')"
  printf '%s\n' \
    '{' \
    '  "schema_version": 1,' \
    "  \"mutation\": \"${mutation}\"," \
    "  \"source_sha256\": \"${source_sha}\"," \
    "  \"variant_sha256\": \"${variant_sha}\"," \
    "  \"make_rc\": ${make_rc}," \
    "  \"expected_detection\": \"${expected}\"," \
    '  "runtime_marker_detected": true,' \
    '  "mutation_detected": true,' \
    '  "status": "PASS"' \
    '}' > "${result_tmp}"
  mv -- "${result_tmp}" "${result_json}"
  printf '[V13Q-MUTATION][PASS] %s\n' "${mutation}"
}

run_one drain-cause-load-fault \
  '[CHECK-FAIL] V13Q formal WB cause is store access fault'
run_one drain-tval-uses-pa \
  '[CHECK-FAIL] V13Q formal WB tval is original VA'
run_one ignore-formal-wb-credit \
  '[CHECK-FAIL] V13Q full WB slots backpressure backend response'

printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "suite": "v13q-backend-error-backpressure-mutations",' \
  "  \"source_sha256\": \"${source_sha}\"," \
  '  "mutation_count": 3,' \
  '  "mutation_detected_count": 3,' \
  '  "status": "PASS"' \
  '}' > "${tmp_root}/mutation-suite-result.json"
mv -- "${tmp_root}/mutation-suite-result.json" "${suite_result}"

printf '%s\n' \
  '[V13Q-MUTATION-SUITE][PASS] cause=1 original-tval=1 wb-credit=1'
