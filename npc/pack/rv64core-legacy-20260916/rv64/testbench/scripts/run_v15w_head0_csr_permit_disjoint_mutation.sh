#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
sequencer_source="${workspace_dir}/npc/rv64/vsrc/control/OooPendingSystemSequencer.v"
cancel_gate_source="${workspace_dir}/npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v"

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
      echo "[V15W-HEAD0-CSR-PERMIT-DISJOINT-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      ;;
  esac
}
trap cleanup EXIT

release_ivflags="-g2012 -Wall -I${workspace_dir}/npc/rv64/vsrc -I${workspace_dir}/npc/rv64/vsrc/include -I${testbench_dir}/common"
sequencer_sha_before="$(sha256sum "${sequencer_source}" | awk '{print $1}')"
cancel_gate_sha_before="$(sha256sum "${cancel_gate_source}" | awk '{print $1}')"
aggregate_pass=1

run_variant() {
  local variant=$1
  local mutated_sequencer="${work_dir}/${variant}-OooPendingSystemSequencer.v"
  local mutated_cancel_gate="${work_dir}/${variant}-OooPendingSystemAdmissionCancelGate.v"
  local variant_result="${result_dir}/${variant}"
  local driver_log="${variant_result}/driver.log"
  local mutation_diff="${variant_result}/mutation.diff"
  local result_file="${variant_result}/result.txt"
  local test_result="${variant_result}/test-result"
  local test_log compile_artifact expected_failure anchor anchor_count make_rc
  local compile_success=0 mutation_detected=0

  mkdir -p -- "${variant_result}"
  cp -- "${sequencer_source}" "${mutated_sequencer}"
  cp -- "${cancel_gate_source}" "${mutated_cancel_gate}"

  case "${variant}" in
    drop-inflight-arm-blocker)
      anchor='      !clear_dispatched_i && !head0_csr_inflight_i && valid_q &&'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_sequencer}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/      !clear_dispatched_i && !head0_csr_inflight_i && valid_q &&/      !clear_dispatched_i && valid_q && \/\* V15W_MUTATION_DROP_INFLIGHT_ARM *\//' \
        "${mutated_sequencer}"
      test_log="${test_result}/logs/tb_ooo_pending_system_sequencer.log"
      compile_artifact="${work_dir}/${variant}-build/tb_ooo_pending_system_sequencer.vvp"
      expected_failure='FAIL head0 inflight blocks permit arm actual=1 expected=0'
      ;;
    drop-inflight-held-clear)
      anchor='                 (head0_csr_inflight_i && dispatch_permit_q) ||'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_sequencer}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/                 \(head0_csr_inflight_i && dispatch_permit_q\) \|\|/                 \/\* V15W_MUTATION_DROP_INFLIGHT_HELD_CLEAR *\//' \
        "${mutated_sequencer}"
      test_log="${test_result}/logs/tb_ooo_pending_system_sequencer.log"
      compile_artifact="${work_dir}/${variant}-build/tb_ooo_pending_system_sequencer.vvp"
      expected_failure='inflight clears held permit actual=1 expected=0'
      ;;
    readd-head0-commit-dispatch-cancel)
      anchor='      rst_i || core_local_flush_i || feedback_free_dispatch_cancel_w;'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_cancel_gate}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/      rst_i \|\| core_local_flush_i \|\| feedback_free_dispatch_cancel_w;/      rst_i || core_local_flush_i || feedback_free_dispatch_cancel_w ||\n      head0_csr_commit_i; \/\* V15W_MUTATION_READD_HEAD0_CANCEL *\//' \
        "${mutated_cancel_gate}"
      test_log="${test_result}/logs/tb_ooo_pending_system_admission_cancel_gate.log"
      compile_artifact="${work_dir}/${variant}-build/tb_ooo_pending_system_admission_cancel_gate.vvp"
      expected_failure='FAIL head0 CSR death clears holder outside dispatch cancel'
      ;;
    drop-head0-commit-admission-clear)
      anchor='      head0_csr_commit_i;'
      anchor_count="$(grep -Fc "${anchor}" "${mutated_cancel_gate}" || true)"
      [[ "${anchor_count}" == 1 ]] || {
        printf 'RESULT=FAIL\nSTAGE=mutation-anchor\nANCHOR_COUNT=%s\n' \
          "${anchor_count}" >"${result_file}"
        return 1
      }
      perl -0pi -e \
        's/      head0_csr_commit_i;/      1\x27b0; \/\* V15W_MUTATION_DROP_HEAD0_CLEAR *\//' \
        "${mutated_cancel_gate}"
      test_log="${test_result}/logs/tb_ooo_pending_system_admission_cancel_gate.log"
      compile_artifact="${work_dir}/${variant}-build/tb_ooo_pending_system_admission_cancel_gate.vvp"
      expected_failure='FAIL head0 CSR death clears holder outside dispatch cancel'
      ;;
    *)
      printf 'RESULT=FAIL\nSTAGE=unknown-variant\n' >"${result_file}"
      return 1
      ;;
  esac

  {
    diff -u --label production/OooPendingSystemSequencer.v \
      --label mutation/OooPendingSystemSequencer.v \
      "${sequencer_source}" "${mutated_sequencer}" || true
    diff -u --label production/OooPendingSystemAdmissionCancelGate.v \
      --label mutation/OooPendingSystemAdmissionCancelGate.v \
      "${cancel_gate_source}" "${mutated_cancel_gate}" || true
  } >"${mutation_diff}"

  set +e
  make -C "${testbench_dir}" v15w-head0-csr-permit-disjoint-focused \
    "RTL_OOO_PENDING_SYSTEM_SEQUENCER=${mutated_sequencer}" \
    "RTL_OOO_PENDING_SYSTEM_ADMISSION_CANCEL_GATE=${mutated_cancel_gate}" \
    "RESULT_DIR=${test_result}" \
    "BUILD_DIR=${work_dir}/${variant}-build" \
    "IVFLAGS=${release_ivflags}" >"${driver_log}" 2>&1
  make_rc=$?
  set -e

  if [[ -s "${compile_artifact}" ]]; then
    compile_success=1
  fi
  if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
     grep -Fq "${expected_failure}" "${test_log}" &&
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
  drop-inflight-arm-blocker \
  drop-inflight-held-clear \
  readd-head0-commit-dispatch-cancel \
  drop-head0-commit-admission-clear; do
  if ! run_variant "${variant}"; then
    aggregate_pass=0
  fi
done

sequencer_sha_after="$(sha256sum "${sequencer_source}" | awk '{print $1}')"
cancel_gate_sha_after="$(sha256sum "${cancel_gate_source}" | awk '{print $1}')"
result=FAIL
if [[ ${aggregate_pass} -eq 1 &&
      "${sequencer_sha_before}" == "${sequencer_sha_after}" &&
      "${cancel_gate_sha_before}" == "${cancel_gate_sha_after}" ]]; then
  result=PASS
fi
printf '%s\n' \
  "RESULT=${result}" \
  'MUTATION_COUNT=4' \
  'CONFIG=OOO_ASSERT_OFF' \
  "SEQUENCER_SHA_BEFORE=${sequencer_sha_before}" \
  "SEQUENCER_SHA_AFTER=${sequencer_sha_after}" \
  "CANCEL_GATE_SHA_BEFORE=${cancel_gate_sha_before}" \
  "CANCEL_GATE_SHA_AFTER=${cancel_gate_sha_after}" \
  >"${result_dir}/result.txt"
cat "${result_dir}/result.txt"
[[ "${result}" == PASS ]]
