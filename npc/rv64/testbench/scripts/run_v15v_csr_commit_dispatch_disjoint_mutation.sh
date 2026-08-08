#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
rtl_source=${workspace_dir}/npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v

if [[ $# -ne 1 ]]; then
  echo "usage: $0 RESULT_DIR" >&2
  exit 2
fi

result_dir="$(realpath -m "$1")"
mkdir -p -- "${result_dir}"
work_dir=${result_dir}/work.$$
mkdir -p -- "${work_dir}"

cleanup() {
  case "${work_dir}" in
    "${result_dir}"/work.*)
      [[ ! -e "${work_dir}" ]] || rm -r -- "${work_dir}"
      ;;
    *)
      echo "[V15V-CSR-COMMIT-DISPATCH-DISJOINT-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

release_ivflags="-g2012 -Wall -I${workspace_dir}/npc/rv64/vsrc -I${workspace_dir}/npc/rv64/vsrc/include -I${testbench_dir}/common"
production_sha_before="$(sha256sum "${rtl_source}" | awk '{print $1}')"
aggregate_pass=1

run_variant() {
  local variant=$1
  local mutated_rtl=${work_dir}/${variant}.v
  local variant_result=${result_dir}/${variant}
  local driver_log=${variant_result}/driver.log
  local mutation_diff=${variant_result}/mutation.diff
  local result_file=${variant_result}/result.txt
  local test_log=${variant_result}/test-result/logs/tb_ooo_pending_system_admission_cancel_gate.log
  local anchor anchor_count make_rc compile_success=0 mutation_detected=0

  mkdir -p -- "${variant_result}"
  cp -- "${rtl_source}" "${mutated_rtl}"
  case "${variant}" in
    readd-commit-to-dispatch-cancel)
      anchor='      rst_i || core_local_flush_i || feedback_free_dispatch_cancel_w;'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_rtl}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/      rst_i \|\| core_local_flush_i \|\| feedback_free_dispatch_cancel_w;/      rst_i || core_local_flush_i || feedback_free_dispatch_cancel_w ||\n      pending_system_csr_commit_i; \/\* V15V_MUTATION_READD_COMMIT_CANCEL *\//g' \
        "${mutated_rtl}"
      ;;
    drop-commit-from-admission-clear)
      anchor='      pending_system_csr_commit_i ||'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_rtl}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/      pending_system_csr_commit_i \|\|/      \/\* V15V_MUTATION_DROP_COMMIT_CLEAR *\//g' \
        "${mutated_rtl}"
      ;;
    *)
      printf 'RESULT=FAIL\nSTAGE=unknown-variant\n' >"${result_file}"
      return 1
      ;;
  esac

  diff -u --label production/OooPendingSystemAdmissionCancelGate.v \
    --label mutation/OooPendingSystemAdmissionCancelGate.v \
    "${rtl_source}" "${mutated_rtl}" >"${mutation_diff}" || true

  set +e
  make -C "${testbench_dir}" v15v-csr-commit-dispatch-disjoint-focused \
    "RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE=${mutated_rtl}" \
    "RESULT_DIR=${variant_result}/test-result" \
    "BUILD_DIR=${work_dir}/${variant}-build" \
    "IVFLAGS=${release_ivflags}" >"${driver_log}" 2>&1
  make_rc=$?
  set -e

  if [[ -s "${work_dir}/${variant}-build/tb_ooo_pending_system_admission_cancel_gate.vvp" ]]; then
    compile_success=1
  fi
  if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
     grep -Fq 'FAIL exact pending CSR death clears holder without redispatch cancel' "${test_log}" &&
     grep -Fq '[RESULT] FAIL' "${test_log}"; then
    mutation_detected=1
  fi

  local result=FAIL
  if [[ ${compile_success} -eq 1 && ${mutation_detected} -eq 1 ]]; then
    result=PASS
  fi
  printf '%s\n' \
    "RESULT=${result}" \
    "MUTATION=${variant}" \
    'CONFIG=OOO_ASSERT_OFF' \
    "COMPILE_SUCCESS=${compile_success}" \
    "MUTATION_DETECTED=${mutation_detected}" \
    'EXPECTED_TEST_FAILURE=1' \
    "MAKE_RC=${make_rc}" \
    "TEST_LOG=${test_log}" \
    "MUTATION_DIFF=${mutation_diff}" >"${result_file}"
  [[ "${result}" == PASS ]]
}

for variant in \
  readd-commit-to-dispatch-cancel \
  drop-commit-from-admission-clear; do
  if ! run_variant "${variant}"; then
    aggregate_pass=0
  fi
done

production_sha_after="$(sha256sum "${rtl_source}" | awk '{print $1}')"
result=FAIL
if [[ ${aggregate_pass} -eq 1 &&
      "${production_sha_before}" == "${production_sha_after}" ]]; then
  result=PASS
fi
printf '%s\n' \
  "RESULT=${result}" \
  'MUTATION_COUNT=2' \
  'CONFIG=OOO_ASSERT_OFF' \
  "PRODUCTION_SHA_BEFORE=${production_sha_before}" \
  "PRODUCTION_SHA_AFTER=${production_sha_after}" \
  >"${result_dir}/result.txt"
cat "${result_dir}/result.txt"
[[ "${result}" == PASS ]]
