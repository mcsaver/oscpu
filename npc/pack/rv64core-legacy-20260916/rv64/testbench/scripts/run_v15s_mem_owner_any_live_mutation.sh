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
mkdir -p -- "${result_dir}"
work_dir="${result_dir}/work.$$"
mkdir -p -- "${work_dir}"

cleanup() {
  case "${work_dir}" in
    "${result_dir}"/work.*)
      [[ ! -e "${work_dir}" ]] || rm -r -- "${work_dir}"
      ;;
    *)
      echo "[V15S-MEM-OWNER-ANY-LIVE-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

mutated_rtl="${work_dir}/OooIntBackend.v"
mutation_result_dir="${result_dir}/mutation"
driver_log="${result_dir}/driver.log"
result_file="${result_dir}/result.txt"
mutation_diff="${result_dir}/constantize-owner-any-live.diff"
test_log="${mutation_result_dir}/logs/tb_ooo_int_backend_hist_ser_qh_younger_store.log"
production_sha_before="$(sha256sum "${rtl_source}" | awk '{print $1}')"

cp -- "${rtl_source}" "${mutated_rtl}"
anchor='  wire v15s_mem_owner_any_live_w = |mem_owner_live_mask_w;'
anchor_count="$(grep -Fc "${anchor}" "${mutated_rtl}" || true)"
if [[ "${anchor_count}" != 1 ]]; then
  printf '%s\n' 'RESULT=FAIL' 'STAGE=mutation-anchor' \
    "ANCHOR_COUNT=${anchor_count}" >"${result_file}"
  exit 1
fi
perl -0pi -e \
  's/  wire v15s_mem_owner_any_live_w = \|mem_owner_live_mask_w;/  wire v15s_mem_owner_any_live_w = 1\x27b0; \/\* V15S_MUTATION_CONSTANTIZE_ANY_LIVE \*\//' \
  "${mutated_rtl}"
if [[ "$(grep -Fc 'V15S_MUTATION_CONSTANTIZE_ANY_LIVE' "${mutated_rtl}" || true)" != 1 ]]; then
  printf '%s\n' 'RESULT=FAIL' 'STAGE=mutation-apply' >"${result_file}"
  exit 1
fi
diff -u --label production/OooIntBackend.v \
  --label mutation/OooIntBackend.v \
  "${rtl_source}" "${mutated_rtl}" >"${mutation_diff}" || true

release_ivflags="-g2012 -Wall -I${workspace_dir}/npc/rv64/vsrc -I${workspace_dir}/npc/rv64/vsrc/include -I${testbench_dir}/common"
set +e
make -C "${testbench_dir}" v15s-mem-owner-any-live-focused \
  "RTL_OOO_INT_BACKEND=${mutated_rtl}" \
  "RESULT_DIR=${mutation_result_dir}" \
  "BUILD_DIR=${work_dir}/build" \
  "IVFLAGS=${release_ivflags}" >"${driver_log}" 2>&1
make_rc=$?
set -e

compile_success=0
mutation_detected=0
if [[ -s "${work_dir}/build/tb_ooo_int_backend_hist_ser_qh_younger_store.vvp" ]]; then
  compile_success=1
fi
if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
   grep -Fq '[CHECK-FAIL] HIST-QH current owner guard keeps mem_idle low got=1 expected=0' "${test_log}" &&
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
  'MUTATION=constantize-v15s-mem-owner-any-live' \
  'CONFIG=OOO_ASSERT_OFF' \
  "COMPILE_SUCCESS=${compile_success}" \
  "MUTATION_DETECTED=${mutation_detected}" \
  'EXPECTED_TEST_FAILURE=1' \
  "MAKE_RC=${make_rc}" \
  "PRODUCTION_SHA_BEFORE=${production_sha_before}" \
  "PRODUCTION_SHA_AFTER=${production_sha_after}" \
  "TEST_LOG=${test_log}" \
  "MUTATION_DIFF=${mutation_diff}" >"${result_file}"
cat "${result_file}"
[[ "${result}" == PASS ]]
