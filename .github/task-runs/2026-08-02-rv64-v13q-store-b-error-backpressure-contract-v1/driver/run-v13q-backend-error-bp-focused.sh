#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1"
result_root="${task_root}/evidence/backend-error-backpressure"
log_path="${result_root}/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log"
binding_path="${result_root}/critical-source-binding.sha256"
result_json="${result_root}/result.json"
vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13q_store_b_error_backpressure.vvp"
mkdir -p "${result_root}/logs"
# Stage the manifest and PASS receipt beside the final evidence so mv remains
# a same-filesystem atomic rename.
tmp_root="$(mktemp -d "${result_root}/.focused-run.XXXXXX")"

critical_sources=(
  npc/rv64/vsrc/memory/OooMemAxiBridge.v
  npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v
  npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v
  npc/rv64/vsrc/execute/OooIntBackend.v
  npc/rv64/vsrc/memory/OooStoreQueue.v
  npc/rv64/vsrc/memory/OooMemInflightQueue.v
  npc/rv64/vsrc/memory/OooMemOwnerTracker.v
  npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v
  npc/rv64/vsrc/writeback/OooRob.v
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv
  npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh
  npc/rv64/testbench/Makefile
)

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${vvp}"
}
trap cleanup EXIT

rm -f -- "${result_json}" "${binding_path}" "${log_path}" "${vvp}"

(
  cd "${repo_root}"
  sha256sum "${critical_sources[@]}"
) > "${tmp_root}/pre.sha256"

set +e
make -C "${repo_root}/npc/rv64/testbench" \
  "RESULT_DIR=${result_root}" \
  v13q-store-b-error-backpressure-focused
make_rc=$?
set -e

(
  cd "${repo_root}"
  sha256sum "${critical_sources[@]}"
) > "${tmp_root}/post.sha256"

if [[ "${make_rc}" != "0" ]]; then
  printf '[V13Q-FOCUSED][FAIL] make rc=%s\n' "${make_rc}" >&2
  exit 21
fi
if ! cmp -s "${tmp_root}/pre.sha256" "${tmp_root}/post.sha256"; then
  printf '%s\n' '[V13Q-FOCUSED][FAIL] critical source binding drifted' >&2
  exit 22
fi
if ! grep -Fq '[V13Q-BACKEND-B-ERROR-BP] slverr_direct=1 decerr_direct=1 slverr_fallback=1 cause7=3 original_tval=3 exact_terminal=3 quiet=9 PASS' "${log_path}"; then
  printf '%s\n' '[V13Q-FOCUSED][FAIL] aggregate lifecycle marker missing' >&2
  exit 23
fi
if ! grep -Fq '[PASS] tb_ooo_int_backend_v13q_store_b_error_backpressure' "${log_path}" || \
   ! grep -Fq '[RESULT] PASS' "${log_path}"; then
  printf '%s\n' '[V13Q-FOCUSED][FAIL] terminal PASS markers missing' >&2
  exit 24
fi

mv -- "${tmp_root}/pre.sha256" "${binding_path}"
binding_sha="$(sha256sum "${binding_path}" | awk '{print $1}')"
log_sha="$(sha256sum "${log_path}" | awk '{print $1}')"
printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "test": "v13q-store-b-error-backpressure-focused",' \
  "  \"make_rc\": ${make_rc}," \
  "  \"critical_source_binding_sha256\": \"${binding_sha}\"," \
  "  \"log_sha256\": \"${log_sha}\"," \
  '  "aggregate_marker_detected": true,' \
  '  "terminal_pass_detected": true,' \
  '  "status": "PASS"' \
  '}' > "${tmp_root}/result.json"
mv -- "${tmp_root}/result.json" "${result_json}"

printf '%s\n' '[V13Q-FOCUSED][PASS] source-binding=stable result=PASS'
