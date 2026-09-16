#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
permit_source="${workspace_dir}/npc/rv64/vsrc/control/OooSerializedMemTerminalPermit.v"
drain_source="${workspace_dir}/npc/rv64/vsrc/control/OooPendingDrainResolveGate.v"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 RESULT_DIR" >&2
  exit 2
fi

result_dir="$(realpath -m "$1")"
mkdir -p -- "${result_dir}"
release_ivflags="-g2012 -Wall -I${workspace_dir}/npc/rv64/vsrc -I${workspace_dir}/npc/rv64/vsrc/include -I${testbench_dir}/common"
permit_sha_before="$(sha256sum "${permit_source}" | awk '{print $1}')"
drain_sha_before="$(sha256sum "${drain_source}" | awk '{print $1}')"

run_variant() {
  local variant="$1"
  local expected="$2"
  local variant_dir="${result_dir}/${variant}"
  local work_dir="${variant_dir}/work.$$"
  local test_result="${variant_dir}/test-result"
  local driver_log="${variant_dir}/driver.log"
  local result_file="${variant_dir}/result.txt"
  local mutation_diff="${variant_dir}/${variant}.diff"
  local test_log="${test_result}/logs/tb_ooo_serialized_mem_terminal_permit.log"
  local compile_artifact="${work_dir}/build/tb_ooo_serialized_mem_terminal_permit.vvp"

  mkdir -p -- "${variant_dir}" "${work_dir}"
  case "${test_result}" in
    "${variant_dir}"/test-result)
      [[ ! -e "${test_result}" ]] || rm -r -- "${test_result}"
      ;;
    *)
      echo "[V16A-SERIALIZED-PERMIT-MUTATION][CLEANUP-REFUSED] ${test_result}" >&2
      return 1
      ;;
  esac

  local mutated_permit="${work_dir}/OooSerializedMemTerminalPermit.v"
  local mutated_drain="${work_dir}/OooPendingDrainResolveGate.v"
  cp -- "${permit_source}" "${mutated_permit}"
  cp -- "${drain_source}" "${mutated_drain}"

  case "${variant}" in
    drop-owner-match)
      local anchor='  wire owner_matches_w = owner_i == permit_owner_q;'
      [[ "$(grep -Fc "${anchor}" "${mutated_permit}" || true)" == 1 ]] || return 1
      perl -0pi -e \
        's/  wire owner_matches_w = owner_i == permit_owner_q;/  wire owner_matches_w = 1\x27b1; \/\/ V16A_MUTATION_DROP_OWNER_MATCH/' \
        "${mutated_permit}"
      diff -u --label production/OooSerializedMemTerminalPermit.v \
        --label mutation/OooSerializedMemTerminalPermit.v \
        "${permit_source}" "${mutated_permit}" >"${mutation_diff}" || true
      ;;
    drop-cancel-priority)
      local anchor='    end else if (cancel_i || consume_i || !stop_pending_i ||'
      [[ "$(grep -Fc "${anchor}" "${mutated_permit}" || true)" == 1 ]] || return 1
      perl -0pi -e \
        's/    end else if \(cancel_i \|\| consume_i \|\| !stop_pending_i \|\|/    end else if (consume_i || !stop_pending_i || \/\* V16A_MUTATION_DROP_CANCEL *\//' \
        "${mutated_permit}"
      diff -u --label production/OooSerializedMemTerminalPermit.v \
        --label mutation/OooSerializedMemTerminalPermit.v \
        "${permit_source}" "${mutated_permit}" >"${mutation_diff}" || true
      ;;
    drop-cancel-cycle-block)
      local anchor='      !cancel_i && permit_valid_q && stop_pending_i && owner_exact_one_w &&'
      [[ "$(grep -Fc "${anchor}" "${mutated_permit}" || true)" == 1 ]] || return 1
      perl -0pi -e \
        's/      !cancel_i && permit_valid_q && stop_pending_i && owner_exact_one_w &&/      permit_valid_q && stop_pending_i && owner_exact_one_w && \/\* V16B_MUTATION_DROP_CANCEL_CYCLE_BLOCK *\//' \
        "${mutated_permit}"
      diff -u --label production/OooSerializedMemTerminalPermit.v \
        --label mutation/OooSerializedMemTerminalPermit.v \
        "${permit_source}" "${mutated_permit}" >"${mutation_diff}" || true
      ;;
    drop-fence-current-idle)
      local anchor='      !pending_system_fence_i || mem_idle_i;'
      [[ "$(grep -Fc "${anchor}" "${mutated_drain}" || true)" == 1 ]] || return 1
      perl -0pi -e \
        's/      !pending_system_fence_i \|\| mem_idle_i;/      1\x27b1; \/\/ V16A_MUTATION_DROP_FENCE_IDLE/' \
        "${mutated_drain}"
      diff -u --label production/OooPendingDrainResolveGate.v \
        --label mutation/OooPendingDrainResolveGate.v \
        "${drain_source}" "${mutated_drain}" >"${mutation_diff}" || true
      ;;
    drop-raw-backend-drain)
      local anchor='      stop_pending_i && backend_drained_o && pending_control_ready_i &&'
      [[ "$(grep -Fc "${anchor}" "${mutated_drain}" || true)" == 1 ]] || return 1
      perl -0pi -e \
        's/      stop_pending_i && backend_drained_o && pending_control_ready_i &&/      stop_pending_i && pending_control_ready_i && \/\* V16A_MUTATION_DROP_RAW_DRAIN *\//' \
        "${mutated_drain}"
      diff -u --label production/OooPendingDrainResolveGate.v \
        --label mutation/OooPendingDrainResolveGate.v \
        "${drain_source}" "${mutated_drain}" >"${mutation_diff}" || true
      ;;
    *)
      echo "unknown variant: ${variant}" >&2
      return 1
      ;;
  esac

  set +e
  make -C "${testbench_dir}" v16a-serialized-mem-terminal-permit-focused \
    "RTL_OOO_SERIALIZED_MEM_TERMINAL_PERMIT=${mutated_permit}" \
    "RTL_OOO_PENDING_DRAIN_RESOLVE_GATE=${mutated_drain}" \
    "RESULT_DIR=${test_result}" \
    "BUILD_DIR=${work_dir}/build" \
    "IVFLAGS=${release_ivflags}" >"${driver_log}" 2>&1
  local make_rc=$?
  set -e

  local compile_success=0
  local mutation_detected=0
  [[ -s "${compile_artifact}" ]] && compile_success=1
  if [[ ${make_rc} -ne 0 && -f "${test_log}" ]] &&
     grep -Fq "${expected}" "${test_log}" &&
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

  case "${work_dir}" in
    "${variant_dir}"/work.*)
      rm -r -- "${work_dir}"
      ;;
    *)
      echo "[V16A-SERIALIZED-PERMIT-MUTATION][CLEANUP-REFUSED] ${work_dir}" >&2
      return 1
      ;;
  esac
  [[ "${result}" == PASS ]]
}

run_variant \
  drop-owner-match \
  '[CHECK-FAIL] V16A owner B cannot consume owner A permit'
run_variant \
  drop-cancel-priority \
  '[CHECK-FAIL] V16A cancel drop cannot resurrect held permit'
run_variant \
  drop-cancel-cycle-block \
  '[CHECK-FAIL] V16A held cancel suppresses ready immediately'
run_variant \
  drop-fence-current-idle \
  '[CHECK-FAIL] V16A FENCE current mem_idle blocks completion'
run_variant \
  drop-raw-backend-drain \
  '[CHECK-FAIL] V16A raw drain recheck blocks completion'

permit_sha_after="$(sha256sum "${permit_source}" | awk '{print $1}')"
drain_sha_after="$(sha256sum "${drain_source}" | awk '{print $1}')"
result=FAIL
if [[ "${permit_sha_before}" == "${permit_sha_after}" &&
      "${drain_sha_before}" == "${drain_sha_after}" ]]; then
  result=PASS
fi
printf '%s\n' \
  "RESULT=${result}" \
  'MUTATION_COUNT=5' \
  'COMPILE_SUCCESS_COUNT=5' \
  'DETECTED_COUNT=5' \
  'CONFIG=OOO_ASSERT_OFF' \
  "PERMIT_SHA_BEFORE=${permit_sha_before}" \
  "PERMIT_SHA_AFTER=${permit_sha_after}" \
  "DRAIN_SHA_BEFORE=${drain_sha_before}" \
  "DRAIN_SHA_AFTER=${drain_sha_after}" >"${result_dir}/result.txt"
cat "${result_dir}/result.txt"
[[ "${result}" == PASS ]]
