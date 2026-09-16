#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${testbench_dir}/../../.." && pwd)"
tier=fast
evidence_dir_arg=
result_root=
result_ready=0
result_manifest_sha=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)
      [[ $# -ge 2 && ($2 == "fast" || $2 == "link") ]] || {
        echo "usage: $0 [--tier fast|link] [--evidence-dir TASK_RUN_SUBDIR]" >&2
        exit 2
      }
      tier=$2
      shift 2
      ;;
    --evidence-dir)
      [[ $# -ge 2 && -n $2 ]] || {
        echo "usage: $0 [--tier fast|link] [--evidence-dir TASK_RUN_SUBDIR]" >&2
        exit 2
      }
      evidence_dir_arg=$2
      shift 2
      ;;
    *)
      echo "usage: $0 [--tier fast|link] [--evidence-dir TASK_RUN_SUBDIR]" >&2
      exit 2
      ;;
  esac
done

runtime_base="${repo_root}/.github/runtime-artifacts/v14r-memory-request-hold"
mkdir -p "${runtime_base}"
runtime_dir="$(mktemp -d "${runtime_base}/${tier}.XXXXXX")"
cleanup_runtime() {
  local command_rc=$?
  local cleanup_rc=0
  local resolved
  local result_tmp
  resolved="$(realpath -m -- "${runtime_dir}")" || cleanup_rc=1
  if [[ ${cleanup_rc} -eq 0 ]]; then
    case "${resolved}" in
      "${runtime_base}/"*) rm -rf -- "${resolved}" || cleanup_rc=1 ;;
      *) cleanup_rc=1 ;;
    esac
  fi
  if [[ ${cleanup_rc} -eq 0 ]]; then
    echo "[V14R-HOLD-CLEANUP][PASS]"
  else
    echo "[V14R-HOLD-CLEANUP][FAIL] path=${runtime_dir}" >&2
  fi
  if [[ -n "${evidence_dir_arg}" && -n "${result_root}" &&
        -d "${result_root}" ]]; then
    result_tmp="${result_root}/.result.txt.tmp.$$"
    if [[ ${command_rc} -eq 0 && ${cleanup_rc} -eq 0 &&
          ${result_ready} -eq 1 ]]; then
      if ! printf '%s\n' \
          'RESULT=PASS' \
          "TIER=${tier}" \
          'HOLDER_FF=29' \
          'PAYLOAD_SHADOW_BITS=217' \
          'MUTATION_TOTAL=6' \
          "MANIFEST_SHA256=${result_manifest_sha}" \
          'MANIFEST_FILES=9' \
          'BUILD_RETAINED=0' \
          'CLEANUP=PASS' \
          'PPA=UNQUALIFIED' >"${result_tmp}" ||
         ! mv -f -- "${result_tmp}" "${result_root}/result.txt"; then
        rm -f -- "${result_tmp}"
        cleanup_rc=1
        echo "[V14R-HOLD-RESULT][FAIL] retained result commit failed" >&2
      else
        echo "[V14R-HOLD-RESULT][PASS] artifact=${result_root}/result.txt"
      fi
    fi
  fi
  if [[ ${command_rc} -ne 0 ]]; then
    exit "${command_rc}"
  fi
  exit "${cleanup_rc}"
}
trap cleanup_runtime EXIT

result_root="${runtime_dir}"
if [[ -n "${evidence_dir_arg}" ]]; then
  evidence_dir="$(realpath -m -- "${evidence_dir_arg}")"
  case "${evidence_dir}" in
    "${repo_root}/.github/task-runs/"*) ;;
    *)
      echo "[V14R-HOLD-EVIDENCE][FAIL] retained evidence must be below .github/task-runs: ${evidence_dir}" >&2
      exit 2
      ;;
  esac
  if [[ -d "${evidence_dir}" && -n "$(find "${evidence_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "[V14R-HOLD-EVIDENCE][FAIL] retained evidence directory is not empty: ${evidence_dir}" >&2
    exit 2
  fi
  mkdir -p "${evidence_dir}"
  result_root="${evidence_dir}"
fi

run_make_target() {
  local name=$1
  local target=$2
  local result_dir="${result_root}/${name}"
  local log="${result_root}/${name}.driver.log"
  if ! make -C "${testbench_dir}" "${target}" \
      "RESULT_DIR=${result_dir}" \
      "BUILD_DIR=${runtime_dir}/build/${name}" >"${log}" 2>&1; then
    echo "[V14R-HOLD-STEP][FAIL] step=${name}" >&2
    tail -n 80 "${log}" >&2
    return 1
  fi
  echo "[V14R-HOLD-STEP][PASS] step=${name}"
}

production_manifest() {
  sha256sum \
    "${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v" \
    "${repo_root}/npc/rv64/vsrc/memory/OooStoreQueue.v" \
    "${repo_root}/npc/rv64/vsrc/writeback/OooRob.v" \
    "${repo_root}/npc/rv64/testbench/tests/tb_ooo_int_backend.sv" \
    "${repo_root}/npc/rv64/testbench/tests/tb_ooo_store_queue.sv" \
    "${repo_root}/npc/rv64/testbench/Makefile" \
    "${repo_root}/npc/rv64/design/specs/ooo-memory-request-admission-hold.md" \
    "${script_dir}/run_v14r_memory_request_hold_mutation.sh" \
    "${script_dir}/check_v14r_memory_request_hold.sh"
}

production_manifest >"${result_root}/production-before.sha256"
run_make_target store-queue \
  "${result_root}/store-queue/logs/tb_ooo_store_queue.log"
grep -Fq '[PASS] tb_ooo_store_queue' \
  "${result_root}/store-queue/logs/tb_ooo_store_queue.log"
run_make_target focused v14r-memory-request-hold-focused
grep -Fq \
  '[V14R-MEMORY-REQUEST-HOLD] holder_ff=29 payload_bits=217 banks=2 late_priority=2 exact_fire=4 exact_source=4 independent_bank=1 late_sq_block=1 nonflush_cancel=1 sq_launch_lease=1 amo_launch_lease=1 capacity_isolation=2 cancel_ready_race=1 PASS' \
  "${result_root}/focused/logs/tb_ooo_int_backend_v14r_memory_request_hold.log"
run_make_target single-bank v14r-single-bank-probe-order-focused
grep -Fq \
  '[V14R-SINGLE-BANK-PROBE-ORDER] older_probe=1 younger_store_block=1 valid_lease=0 mutation_anchor=2 PASS' \
  "${result_root}/single-bank/logs/tb_ooo_int_backend_v14r_single_bank_probe_order.log"

"${script_dir}/run_v14r_memory_request_hold_mutation.sh" \
  "${result_root}/mutation" >"${result_root}/mutation.driver.log"
grep -Fq 'RESULT=PASS' "${result_root}/mutation/result.txt"
grep -Fq 'VARIANT_TOTAL=6' "${result_root}/mutation/result.txt"
grep -Fq 'VARIANT_PASS_COUNT=6' "${result_root}/mutation/result.txt"
grep -Fq 'COMPILE_SUCCESS=1' "${result_root}/mutation/result.txt"
grep -Fq 'MUTATION_DETECTED=1' "${result_root}/mutation/result.txt"
echo "[V14R-HOLD-STEP][PASS] step=mutation-matrix variants=6"

if [[ "${tier}" == "link" ]]; then
  run_make_target dual-memory v8s-dual-memory-core-focused
  link_result="${result_root}/linked-regressions"
  link_build="${runtime_dir}/build/linked-regressions"
  link_log="${result_root}/linked-regressions.driver.log"
  default_log="${link_result}/logs/tb_ooo_int_backend.log"
  retry_log="${link_result}/logs/tb_ooo_int_backend_v11l_memory_retry_holder.log"
  reservation_log="${link_result}/logs/tb_ooo_int_backend_v11m_memory_reservation_holder.log"
  if ! make -C "${testbench_dir}" \
      "${default_log}" "${retry_log}" "${reservation_log}" \
      "RESULT_DIR=${link_result}" "BUILD_DIR=${link_build}" \
      >"${link_log}" 2>&1; then
    echo "[V14R-HOLD-STEP][FAIL] step=linked-regressions" >&2
    tail -n 80 "${link_log}" >&2
    exit 1
  fi
  grep -Fq '[PASS] tb_ooo_int_backend' "${default_log}"
  grep -Fq '[PASS] tb_ooo_int_backend_v11l_memory_retry_holder' \
    "${retry_log}"
  grep -Fq '[PASS] tb_ooo_int_backend_v11m_memory_reservation_holder' \
    "${reservation_log}"
  echo "[V14R-HOLD-STEP][PASS] step=linked-regressions cases=4"
fi

production_manifest >"${result_root}/production-after.sha256"
if ! cmp -s "${result_root}/production-before.sha256" \
              "${result_root}/production-after.sha256"; then
  echo "[V14R-HOLD-IDENTITY][FAIL] production inputs drifted" >&2
  diff -u "${result_root}/production-before.sha256" \
          "${result_root}/production-after.sha256" >&2 || true
  exit 1
fi

manifest_sha="$(sha256sum "${result_root}/production-after.sha256" | awk '{print $1}')"
result_manifest_sha="${manifest_sha}"
echo "[V14R-HOLD-IDENTITY][PASS] manifest_sha256=${manifest_sha} files=9"
if [[ -n "${evidence_dir_arg}" ]]; then
  echo "[V14R-HOLD-EVIDENCE][PASS] retained=${result_root} build_retained=0"
fi
echo "[V14R-HOLD-CHECK][PASS] tier=${tier} holder_ff=29 payload_shadow_bits=217 mutation=6 ppa=UNQUALIFIED"
result_ready=1
