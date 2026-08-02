#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1"
bridge_rtl="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
rob_rtl="${repo_root}/npc/rv64/vsrc/writeback/OooRob.v"
bridge_vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.vvp"
backend_vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.vvp"
suite_result="${task_root}/evidence/mutation-suite-result.json"
binding_path="${task_root}/evidence/v13r-focused/critical-source-binding.sha256"

mkdir -p "${task_root}/evidence"
tmp_root="$(mktemp -d "${task_root}/evidence/.mutation-run.XXXXXX")"
bridge_source_sha="$(sha256sum "${bridge_rtl}" | awk '{print $1}')"
rob_source_sha="$(sha256sum "${rob_rtl}" | awk '{print $1}')"

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${bridge_vvp}" "${backend_vvp}"
}
trap cleanup EXIT

if [[ ! -f "${binding_path}" ]]; then
  printf '%s\n' '[V13R-MUTATION][FAIL] focused source binding missing' >&2
  exit 10
fi
(
  cd "${repo_root}"
  sha256sum -c --quiet "${binding_path}"
)
binding_sha="$(sha256sum "${binding_path}" | awk '{print $1}')"

# Invalidate every prior per-variant receipt/log before the first variant.
# A signal between variants therefore leaves the suite absent and no later
# stale single-variant PASS available for accidental authorization.
rm -f -- "${suite_result}" "${bridge_vvp}" "${backend_vvp}" \
  "${task_root}/evidence/mutation-s-resp-auto-drop/result.json" \
  "${task_root}/evidence/mutation-s-resp-auto-drop/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log" \
  "${task_root}/evidence/mutation-s-resp-auto-drop/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log" \
  "${task_root}/evidence/mutation-decerr-captured-as-okay/result.json" \
  "${task_root}/evidence/mutation-decerr-captured-as-okay/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log" \
  "${task_root}/evidence/mutation-decerr-captured-as-okay/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log" \
  "${task_root}/evidence/mutation-rob-ignores-commit-ready/result.json" \
  "${task_root}/evidence/mutation-rob-ignores-commit-ready/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log" \
  "${task_root}/evidence/mutation-rob-ignores-commit-ready/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log"

run_one() {
  local mutation="$1"
  local expected="$2"
  local expected_log_kind="$3"
  local result_root="${task_root}/evidence/mutation-${mutation}"
  local variant_dir="${tmp_root}/${mutation}"
  local variant_rtl
  local bridge_log="${result_root}/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log"
  local backend_log="${result_root}/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log"
  local expected_log
  local result_json="${result_root}/result.json"
  local result_tmp="${tmp_root}/${mutation}.result.json"
  local make_rc
  local variant_sha
  local log_sha
  local source_name
  local source_rtl
  local source_sha

  mkdir -p "${variant_dir}" "${result_root}/logs"
  rm -f -- "${result_json}" "${bridge_log}" "${backend_log}" \
    "${bridge_vvp}" "${backend_vvp}"

  case "${mutation}" in
    s-resp-auto-drop)
      variant_rtl="${variant_dir}/OooMemAxiBridge.v"
      source_name="OooMemAxiBridge.v"
      source_rtl="${bridge_rtl}"
      source_sha="${bridge_source_sha}"
      if [[ "$(grep -Fc 'if (rsp_ready_w) begin' "${bridge_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13R-MUTATION][FAIL] S_RESP hold anchor is not unique' >&2
        exit 11
      fi
      sed 's/if (rsp_ready_w) begin/if (rsp_ready_w || !rsp_ready_w) begin/' \
        "${bridge_rtl}" > "${variant_rtl}"
      ;;
    decerr-captured-as-okay)
      variant_rtl="${variant_dir}/OooMemAxiBridge.v"
      source_name="OooMemAxiBridge.v"
      source_rtl="${bridge_rtl}"
      source_sha="${bridge_source_sha}"
      if [[ "$(grep -Fc "rsp_error_q <= (lsu_axi_bresp_i != 2'b00);" "${bridge_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13R-MUTATION][FAIL] DECERR capture anchor is not unique' >&2
        exit 12
      fi
      sed "s/rsp_error_q <= (lsu_axi_bresp_i != 2'b00);/rsp_error_q <= (lsu_axi_bresp_i == 2'b10);/" \
        "${bridge_rtl}" > "${variant_rtl}"
      ;;
    rob-ignores-commit-ready)
      variant_rtl="${variant_dir}/OooRob.v"
      source_name="OooRob.v"
      source_rtl="${rob_rtl}"
      source_sha="${rob_source_sha}"
      if [[ "$(grep -Fc 'assign head0_base_ready_w = !recovering_w && commit_ready_i &&' "${rob_rtl}")" != "1" ]]; then
        printf '%s\n' '[V13R-MUTATION][FAIL] commit-ready anchor is not unique' >&2
        exit 13
      fi
      sed "s/!recovering_w && commit_ready_i &&/!recovering_w \\&\\& 1'b1 \\&\\&/" \
        "${rob_rtl}" > "${variant_rtl}"
      ;;
    *)
      printf '[V13R-MUTATION][FAIL] unknown mutation %s\n' "${mutation}" >&2
      exit 14
      ;;
  esac

  if cmp -s "${source_rtl}" "${variant_rtl}"; then
    printf '[V13R-MUTATION][FAIL] mutation %s produced no source delta\n' \
      "${mutation}" >&2
    exit 15
  fi

  set +e
  if [[ "${source_name}" == "OooMemAxiBridge.v" ]]; then
    make -C "${repo_root}/npc/rv64/testbench" \
      "RESULT_DIR=${result_root}" \
      "RTL_OOO_MEM_AXI_BRIDGE=${variant_rtl}" \
      v13r-store-b-multicycle-retire-hold-focused
  else
    make -C "${repo_root}/npc/rv64/testbench" \
      "RESULT_DIR=${result_root}" \
      "RTL_OOO_ROB=${variant_rtl}" \
      v13r-store-b-multicycle-retire-hold-focused
  fi
  make_rc=$?
  set -e
  rm -f -- "${bridge_vvp}" "${backend_vvp}"

  if [[ "${expected_log_kind}" == "bridge" ]]; then
    expected_log="${bridge_log}"
  else
    expected_log="${backend_log}"
  fi
  if [[ "${make_rc}" == "0" ]]; then
    printf '[V13R-MUTATION][FAIL] mutation %s remained green\n' \
      "${mutation}" >&2
    exit 16
  fi
  if [[ ! -f "${expected_log}" ]] || ! grep -Fq "${expected}" "${expected_log}"; then
    printf '[V13R-MUTATION][FAIL] mutation %s missed marker %s\n' \
      "${mutation}" "${expected}" >&2
    exit 17
  fi
  if ! grep -Fq '[RESULT] FAIL' "${expected_log}"; then
    printf '[V13R-MUTATION][FAIL] mutation %s lacks fail-closed result\n' \
      "${mutation}" >&2
    exit 18
  fi

  variant_sha="$(sha256sum "${variant_rtl}" | awk '{print $1}')"
  log_sha="$(sha256sum "${expected_log}" | awk '{print $1}')"
  printf '%s\n' \
    '{' \
    '  "schema_version": 1,' \
    "  \"mutation\": \"${mutation}\"," \
    "  \"source_name\": \"${source_name}\"," \
    "  \"source_sha256\": \"${source_sha}\"," \
    "  \"variant_sha256\": \"${variant_sha}\"," \
    "  \"critical_source_binding_sha256\": \"${binding_sha}\"," \
    "  \"make_rc\": ${make_rc}," \
    "  \"expected_detection\": \"${expected}\"," \
    "  \"expected_log_sha256\": \"${log_sha}\"," \
    '  "compile_and_run_reached_result": true,' \
    '  "runtime_marker_detected": true,' \
    '  "mutation_detected": true,' \
    '  "status": "PASS"' \
    '}' > "${result_tmp}"
  mv -- "${result_tmp}" "${result_json}"
  printf '[V13R-MUTATION][PASS] %s\n' "${mutation}"
}

run_one s-resp-auto-drop \
  '[CHECK-FAIL] V13R DECERR holder remains S_RESP' bridge
run_one decerr-captured-as-okay \
  '[CHECK-FAIL] V13R DECERR holder keeps error' bridge
run_one rob-ignores-commit-ready \
  '[CHECK-FAIL] V13R commit_ready hold blocks target commit' backend

if [[ "$(sha256sum "${bridge_rtl}" | awk '{print $1}')" != "${bridge_source_sha}" ]] || \
   [[ "$(sha256sum "${rob_rtl}" | awk '{print $1}')" != "${rob_source_sha}" ]]; then
  printf '%s\n' '[V13R-MUTATION][FAIL] live production RTL drifted' >&2
  exit 19
fi
(
  cd "${repo_root}"
  sha256sum -c --quiet "${binding_path}"
)

printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "suite": "v13r-store-b-multicycle-retire-hold-mutations",' \
  "  \"bridge_source_sha256\": \"${bridge_source_sha}\"," \
  "  \"rob_source_sha256\": \"${rob_source_sha}\"," \
  "  \"critical_source_binding_sha256\": \"${binding_sha}\"," \
  '  "mutation_count": 3,' \
  '  "mutation_detected_count": 3,' \
  '  "live_production_rtl_stable": true,' \
  '  "status": "PASS"' \
  '}' > "${tmp_root}/mutation-suite-result.json"
mv -- "${tmp_root}/mutation-suite-result.json" "${suite_result}"

printf '%s\n' \
  '[V13R-MUTATION-SUITE][PASS] s_resp_hold=1 decerr_snapshot=1 commit_ready=1'
