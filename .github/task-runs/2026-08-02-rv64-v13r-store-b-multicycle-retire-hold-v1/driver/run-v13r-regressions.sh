#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1"
result_root="${task_root}/evidence/regressions"
binding_path="${task_root}/evidence/v13r-focused/critical-source-binding.sha256"
result_json="${result_root}/result.json"
v13q_log="${result_root}/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log"
v13p_bridge_log="${result_root}/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log"
v13p_backend_log="${result_root}/logs/tb_ooo_int_backend_v13p_store_b_fusion.log"
v8x_log="${result_root}/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log"
vvps=(
  "${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13q_store_b_error_backpressure.vvp"
  "${repo_root}/npc/rv64/testbench/build/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.vvp"
  "${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13p_store_b_fusion.vvp"
  "${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v8x_backend_bridge_recovery.vvp"
)

mkdir -p "${result_root}/logs"
tmp_root="$(mktemp -d "${result_root}/.regression-run.XXXXXX")"

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${vvps[@]}"
}
trap cleanup EXIT

if [[ ! -f "${binding_path}" ]]; then
  printf '%s\n' '[V13R-REGRESSION][FAIL] focused source binding missing' >&2
  exit 11
fi
(
  cd "${repo_root}"
  sha256sum -c --quiet "${binding_path}"
)
binding_sha="$(sha256sum "${binding_path}" | awk '{print $1}')"

rm -f -- "${result_json}" "${v13q_log}" "${v13p_bridge_log}" \
  "${v13p_backend_log}" "${v8x_log}" "${vvps[@]}"

set +e
make -C "${repo_root}/npc/rv64/testbench" \
  "RESULT_DIR=${result_root}" \
  v13q-store-b-error-backpressure-focused \
  v13p-store-b-fusion-focused \
  v8x-backend-bridge-recovery
make_rc=$?
set -e

if [[ "${make_rc}" != "0" ]]; then
  printf '[V13R-REGRESSION][FAIL] make rc=%s\n' "${make_rc}" >&2
  exit 21
fi
(
  cd "${repo_root}"
  sha256sum -c --quiet "${binding_path}"
)

if ! grep -Fq '[V13Q-BACKEND-B-ERROR-BP] slverr_direct=1 decerr_direct=1 slverr_fallback=1 cause7=3 original_tval=3 exact_terminal=3 quiet=9 PASS' "${v13q_log}" || \
   ! grep -Fq '[PASS] tb_ooo_int_backend_v13q_store_b_error_backpressure' "${v13q_log}" || \
   ! grep -Fq '[RESULT] PASS' "${v13q_log}"; then
  printf '%s\n' '[V13R-REGRESSION][FAIL] V13Q marker set incomplete' >&2
  exit 22
fi
if ! grep -Fq '[V13P-B-FUSION-CONTRACT][PASS] direct=3 fallback=1 killed-drop=1' "${v13p_bridge_log}" || \
   ! grep -Fq '[PASS] tb_ooo_mem_axi_bridge_v13p_store_b_fusion' "${v13p_bridge_log}" || \
   ! grep -Fq '[RESULT] PASS' "${v13p_bridge_log}"; then
  printf '%s\n' '[V13R-REGRESSION][FAIL] V13P bridge marker set incomplete' >&2
  exit 23
fi
if ! grep -Fq '[V13P-BACKEND-B-FUSION] probe=1 aw=1 w=1 b=1 wb=1 sq_terminal=1 collector=0 registered_commit=1 sq_release=1 quiet=3 PASS' "${v13p_backend_log}" || \
   ! grep -Fq '[PASS] tb_ooo_int_backend_v13p_store_b_fusion' "${v13p_backend_log}" || \
   ! grep -Fq '[RESULT] PASS' "${v13p_backend_log}"; then
  printf '%s\n' '[V13R-REGRESSION][FAIL] V13P backend marker set incomplete' >&2
  exit 24
fi
if ! grep -Fq '[V8X-BACKEND-BRIDGE-RECOVERY] A=0 B=1 ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS' "${v8x_log}" || \
   ! grep -Fq '[PASS] tb_ooo_int_backend_v8x_backend_bridge_recovery' "${v8x_log}" || \
   ! grep -Fq '[RESULT] PASS' "${v8x_log}"; then
  printf '%s\n' '[V13R-REGRESSION][FAIL] V8X marker set incomplete' >&2
  exit 25
fi

v13q_sha="$(sha256sum "${v13q_log}" | awk '{print $1}')"
v13p_bridge_sha="$(sha256sum "${v13p_bridge_log}" | awk '{print $1}')"
v13p_backend_sha="$(sha256sum "${v13p_backend_log}" | awk '{print $1}')"
v8x_sha="$(sha256sum "${v8x_log}" | awk '{print $1}')"
printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "suite": "v13r-affected-neighborhood-regressions",' \
  "  \"make_rc\": ${make_rc}," \
  "  \"critical_source_binding_sha256\": \"${binding_sha}\"," \
  '  "tests": {' \
  '    "v13q_store_b_error_backpressure": {' \
  '      "status": "PASS",' \
  "      \"log_sha256\": \"${v13q_sha}\"" \
  '    },' \
  '    "v13p_mem_axi_bridge_store_b_fusion": {' \
  '      "status": "PASS",' \
  "      \"log_sha256\": \"${v13p_bridge_sha}\"" \
  '    },' \
  '    "v13p_backend_store_b_fusion": {' \
  '      "status": "PASS",' \
  "      \"log_sha256\": \"${v13p_backend_sha}\"" \
  '    },' \
  '    "v8x_backend_bridge_recovery": {' \
  '      "status": "PASS",' \
  "      \"log_sha256\": \"${v8x_sha}\"" \
  '    }' \
  '  },' \
  '  "source_binding_stable_pre_post": true,' \
  '  "status": "PASS"' \
  '}' > "${tmp_root}/result.json"
mv -- "${tmp_root}/result.json" "${result_json}"

printf '%s\n' '[V13R-REGRESSION][PASS] V13Q=1 V13P-bridge=1 V13P-backend=1 V8X=1 binding=stable'
