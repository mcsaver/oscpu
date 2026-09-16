#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
rtl_source="${workspace_dir}/npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v"

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
      echo "[V15X-TRAP-C0-DISPATCH-CLOSURE-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

mutated_rtl="${work_dir}/OooPendingSystemAdmissionCancelGate.v"
test_result="${result_dir}/test-result"
driver_log="${result_dir}/driver.log"
mutation_diff="${result_dir}/readd-trap-dispatch-cancel.diff"
result_file="${result_dir}/result.txt"
test_log="${test_result}/logs/tb_ooo_pending_system_admission_cancel_gate.log"
compile_artifact="${work_dir}/build/tb_ooo_pending_system_admission_cancel_gate.vvp"
release_ivflags="-g2012 -Wall -I${workspace_dir}/npc/rv64/vsrc -I${workspace_dir}/npc/rv64/vsrc/include -I${testbench_dir}/common"
rtl_sha_before="$(sha256sum "${rtl_source}" | awk '{print $1}')"

cp -- "${rtl_source}" "${mutated_rtl}"
anchor='  wire feedback_free_dispatch_cancel_w ='
anchor_count="$(grep -Fc "${anchor}" "${mutated_rtl}" || true)"
if [[ "${anchor_count}" != 1 ]]; then
  printf '%s\n' \
    'RESULT=FAIL' \
    'STAGE=mutation-anchor' \
    "ANCHOR_COUNT=${anchor_count}" >"${result_file}"
  exit 1
fi

perl -0pi -e \
  's/  wire feedback_free_dispatch_cancel_w =\n/  wire feedback_free_dispatch_cancel_w =\n      csr_trap_mem_valid_i || \/\* V15X_MUTATION_READD_TRAP_CANCEL *\/\n/' \
  "${mutated_rtl}"

diff -u --label production/OooPendingSystemAdmissionCancelGate.v \
  --label mutation/OooPendingSystemAdmissionCancelGate.v \
  "${rtl_source}" "${mutated_rtl}" >"${mutation_diff}" || true

set +e
make -C "${testbench_dir}" v15x-trap-c0-dispatch-closure-focused \
  "RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE=${mutated_rtl}" \
  "RESULT_DIR=${test_result}" \
  "BUILD_DIR=${work_dir}/build" \
  "IVFLAGS=${release_ivflags}" >"${driver_log}" 2>&1
make_rc=$?
set -e

compile_success=0
mutation_detected=0
if [[ -s "${compile_artifact}" ]]; then
  compile_success=1
fi
if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
   grep -Fq 'FAIL memory trap clears holder behind C0 dispatch closure' "${test_log}" &&
   grep -Fq '[RESULT] FAIL' "${test_log}"; then
  mutation_detected=1
fi

rtl_sha_after="$(sha256sum "${rtl_source}" | awk '{print $1}')"
result=FAIL
if [[ ${compile_success} -eq 1 && ${mutation_detected} -eq 1 &&
      "${rtl_sha_before}" == "${rtl_sha_after}" ]]; then
  result=PASS
fi

printf '%s\n' \
  "RESULT=${result}" \
  'MUTATION=readd-trap-dispatch-cancel' \
  'CONFIG=OOO_ASSERT_OFF' \
  "COMPILE_SUCCESS=${compile_success}" \
  "MUTATION_DETECTED=${mutation_detected}" \
  'EXPECTED_TEST_FAILURE=1' \
  "MAKE_RC=${make_rc}" \
  "RTL_SHA_BEFORE=${rtl_sha_before}" \
  "RTL_SHA_AFTER=${rtl_sha_after}" \
  "TEST_LOG=${test_log}" \
  "MUTATION_DIFF=${mutation_diff}" >"${result_file}"
cat "${result_file}"
[[ "${result}" == PASS ]]
