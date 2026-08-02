#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1"
source_rtl="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.vvp"
tmp_root="$(mktemp -d)"

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${vvp}"
}
trap cleanup EXIT

source_sha="$(sha256sum "${source_rtl}" | awk '{print $1}')"

run_one() {
  local mutation="$1"
  local expected="$2"
  local result_root="${task_root}/evidence/mutation-${mutation}"
  local variant_rtl="${tmp_root}/${mutation}/OooMemAxiBridge.v"
  local mutation_log="${result_root}/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log"
  local make_rc

  mkdir -p "$(dirname "${variant_rtl}")" "${result_root}"
  case "${mutation}" in
    duplicate-s-resp)
      if [[ "$(grep -c '^            state_q <= (data_store_b_response_fusion_w && rsp_ready_w) ?$' "${source_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13P-MUTATION][FAIL] duplicate-response anchor is not unique' >&2
        exit 11
      fi
      sed '/^            state_q <= (data_store_b_response_fusion_w && rsp_ready_w) ?$/ {
        N
        c\            state_q <= S_RESP;
      }' "${source_rtl}" > "${variant_rtl}"
      ;;
    drop-fallback-error-snapshot)
      if [[ "$(grep -c '^            rsp_error_q <= (lsu_axi_bresp_i != 2.b00);$' "${source_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13P-MUTATION][FAIL] fallback-error anchor is not unique' >&2
        exit 12
      fi
      sed "s/^            rsp_error_q <= (lsu_axi_bresp_i != 2.b00);$/            rsp_error_q <= 1'b0;/" \
        "${source_rtl}" > "${variant_rtl}"
      ;;
    expose-killed-b)
      if [[ "$(grep -c '^      data_store_b_terminal_w && fsm_normal_w;$' "${source_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13P-MUTATION][FAIL] killed-response anchor is not unique' >&2
        exit 13
      fi
      sed 's/^      data_store_b_terminal_w && fsm_normal_w;$/      data_store_b_terminal_w;/' \
        "${source_rtl}" > "${variant_rtl}"
      ;;
    *)
      printf '[V13P-MUTATION][FAIL] unknown mutation %s\n' "${mutation}" >&2
      exit 14
      ;;
  esac

  if cmp -s "${source_rtl}" "${variant_rtl}"; then
    printf '[V13P-MUTATION][FAIL] mutation %s produced no source delta\n' "${mutation}" >&2
    exit 15
  fi

  rm -f -- "${vvp}"
  set +e
  make -C "${repo_root}/npc/rv64/testbench" \
    "RESULT_DIR=${result_root}" \
    "RTL_OOO_MEM_AXI_BRIDGE=${variant_rtl}" \
    "${mutation_log}"
  make_rc=$?
  set -e
  rm -f -- "${vvp}"

  if [[ "${make_rc}" == "0" ]]; then
    printf '[V13P-MUTATION][FAIL] mutation %s remained green\n' "${mutation}" >&2
    exit 16
  fi
  if ! grep -Fq "${expected}" "${mutation_log}"; then
    printf '[V13P-MUTATION][FAIL] mutation %s missed marker %s\n' \
      "${mutation}" "${expected}" >&2
    exit 17
  fi
  if ! grep -Fq '[RESULT] FAIL' "${mutation_log}"; then
    printf '[V13P-MUTATION][FAIL] mutation %s lacks fail-closed result\n' \
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
    '  "mutation_detected": true,' \
    '  "status": "PASS"' \
    '}' > "${result_root}/result.json"
  printf '[V13P-MUTATION][PASS] %s\n' "${mutation}"
}

run_one duplicate-s-resp '[V13P-B-FUSION-NO-DUP]'
run_one drop-fallback-error-snapshot '[V13P-B-FUSION-FALLBACK]'
run_one expose-killed-b '[CHECK-FAIL] V13P killed B cannot fuse got=1 expected=0'

printf '%s\n' '[V13P-MUTATION-SUITE][PASS] duplicate=1 fallback=1 killed=1'
