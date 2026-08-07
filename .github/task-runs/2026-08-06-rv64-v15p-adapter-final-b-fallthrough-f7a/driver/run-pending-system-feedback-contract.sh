#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
task_run="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
evidence_root="${task_run}/evidence/pending-system-feedback-contract/final-v2"
runtime_base="${repo_root}/.github/runtime-artifacts/v15p-pending-system-feedback"
source_rtl="${repo_root}/npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v"
test_name=tb_ooo_pending_system_admission_cancel_gate

[[ ! -e "${evidence_root}" ]] || {
  printf 'refusing to overwrite %s\n' "${evidence_root}" >&2
  exit 2
}
mkdir -p -- "${runtime_base}" "${evidence_root}"
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX")

cleanup() {
  local resolved
  resolved=$(realpath -m -- "${runtime_dir}")
  case "${resolved}" in
    "${runtime_base}"/run.*) rm -rf -- "${resolved}" ;;
    *) printf 'refusing unsafe cleanup: %s\n' "${resolved}" >&2; return 1 ;;
  esac
}
trap cleanup EXIT HUP INT TERM

positive_result="${evidence_root}/positive"
mutation_result="${evidence_root}/mutation"
mutant_rtl="${runtime_dir}/OooPendingSystemAdmissionCancelGate.full-clear-feedback.v"

make -C "${repo_root}/npc/rv64/testbench" \
  TESTS="${test_name}" \
  BUILD_DIR="${runtime_dir}/positive-build" \
  RESULT_DIR="${positive_result}" run \
  >"${evidence_root}/positive-console.log" 2>&1
grep -Fq '[V15P-PENDING-CSR-FEEDBACK-FREE] PASS' \
  "${positive_result}/logs/${test_name}.log"
grep -Fq '[RESULT] PASS' "${positive_result}/logs/${test_name}.log"

[[ $(grep -Fc 'rst_i || core_local_flush_i || feedback_free_dispatch_clear_w;' \
       "${source_rtl}") -eq 1 ]]
sed 's/rst_i || core_local_flush_i || feedback_free_dispatch_clear_w;/rst_i || core_local_flush_i || system_csr_admission_clear_o;/' \
  "${source_rtl}" >"${mutant_rtl}"
[[ $(grep -Fc 'rst_i || core_local_flush_i || system_csr_admission_clear_o;' \
       "${mutant_rtl}") -eq 1 ]]

set +e
make -C "${repo_root}/npc/rv64/testbench" \
  TESTS="${test_name}" \
  BUILD_DIR="${runtime_dir}/mutation-build" \
  RESULT_DIR="${mutation_result}" \
  RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE="${mutant_rtl}" run \
  >"${evidence_root}/mutation-console.log" 2>&1
mutation_rc=$?
set -e
[[ ${mutation_rc} -ne 0 ]]
grep -Fq 'FAIL branch commit terminal is observation only' \
  "${mutation_result}/logs/${test_name}.log"
grep -Fq '[RESULT] FAIL' "${mutation_result}/logs/${test_name}.log"

sha256sum "${source_rtl}" \
  "${repo_root}/npc/rv64/testbench/tests/${test_name}.sv" \
  >"${evidence_root}/inputs.sha256"
{
  printf 'STATUS=PASS\n'
  printf 'POSITIVE_TEST=%s\n' "${test_name}"
  printf 'POSITIVE_MARKER=[V15P-PENDING-CSR-FEEDBACK-FREE] PASS\n'
  printf 'MUTATION=full_observed_clear_reconnected_to_dispatch_cancel\n'
  printf 'MUTATION_COMPILE=PASS\n'
  printf 'MUTATION_ORACLE=REJECTED\n'
  printf 'MUTATION_RC=%s\n' "${mutation_rc}"
  printf 'RUNTIME_CLEANUP=PASS_ON_EXIT\n'
} >"${evidence_root}/result.txt"

printf '[V15P-PENDING-SYSTEM-FEEDBACK-CONTRACT] PASS\n'
