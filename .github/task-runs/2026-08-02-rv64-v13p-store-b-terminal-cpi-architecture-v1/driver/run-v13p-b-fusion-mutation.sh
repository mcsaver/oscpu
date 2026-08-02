#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1"
result_root="${task_root}/evidence/mutation-disable-direct"
source_rtl="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
tmp_root="$(mktemp -d)"
variant_rtl="${tmp_root}/OooMemAxiBridge.v"
mutation_log="${result_root}/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log"

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${repo_root}/npc/rv64/testbench/build/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.vvp"
}
trap cleanup EXIT

mkdir -p "${result_root}"

if [[ "$(grep -c '^  assign data_store_b_response_fusion_w =$' "${source_rtl}")" != "1" ]]; then
  printf '%s\n' '[V13P-MUTATION][FAIL] direct-fusion assignment anchor is not unique' >&2
  exit 2
fi

sed "/^  assign data_store_b_response_fusion_w =$/ {
  n
  c\\      1'b0;
}" "${source_rtl}" > "${variant_rtl}"

if ! grep -A1 '^  assign data_store_b_response_fusion_w =$' "${variant_rtl}" |
     grep -Fxq "      1'b0;"; then
  printf '%s\n' '[V13P-MUTATION][FAIL] direct-fusion mutation was not applied' >&2
  exit 3
fi

set +e
make -C "${repo_root}/npc/rv64/testbench" \
  "RESULT_DIR=${result_root}" \
  "RTL_OOO_MEM_AXI_BRIDGE=${variant_rtl}" \
  "${mutation_log}"
make_rc=$?
set -e

if [[ "${make_rc}" == "0" ]]; then
  printf '%s\n' '[V13P-MUTATION][FAIL] disabled direct fusion remained green' >&2
  exit 4
fi
if ! grep -Fq '[CHECK-FAIL] B OKAY direct predicate got=0 expected=1' "${mutation_log}"; then
  printf '%s\n' '[V13P-MUTATION][FAIL] cycle-sensitive direct check did not detect mutation' >&2
  exit 5
fi
if ! grep -Fq '[RESULT] FAIL' "${mutation_log}"; then
  printf '%s\n' '[V13P-MUTATION][FAIL] mutation log lacks fail-closed result' >&2
  exit 6
fi

source_sha="$(sha256sum "${source_rtl}" | awk '{print $1}')"
variant_sha="$(sha256sum "${variant_rtl}" | awk '{print $1}')"
printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "mutation": "disable_data_store_b_response_fusion",' \
  "  \"source_sha256\": \"${source_sha}\"," \
  "  \"variant_sha256\": \"${variant_sha}\"," \
  "  \"make_rc\": ${make_rc}," \
  '  "expected_detection": "[CHECK-FAIL] B OKAY direct predicate got=0 expected=1",' \
  '  "mutation_detected": true,' \
  '  "status": "PASS"' \
  '}' > "${result_root}/result.json"

printf '%s\n' '[V13P-MUTATION][PASS] disabled direct fusion was rejected by the B-cycle check'
