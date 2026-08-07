#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
evidence_dir="${run_dir}/evidence/owner-any-live-validation-v1"
status_path="${run_dir}/owner-any-live-validation-v1.status"
runtime_base="${repo_root}/.github/runtime-artifacts/v15s-owner-any-live-validation-v1"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
testbench_dir="${repo_root}/npc/rv64/testbench"
mutation_runner="${testbench_dir}/scripts/run_v15s_mem_owner_any_live_mutation.sh"
rtl_source="${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v"
focused_test=tb_ooo_int_backend_hist_ser_qh_younger_store

runtime_dir=
cleanup_rc=0
assert_off_rc=1
assert_on_rc=1
mutation_rc=1
manifest_rc=1
command_rc=1
deleted_bytes=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${run_dir}/evidence" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[V15S-OWNER-ANY-LIVE] RV64 engineering lane is occupied' >&2
  exit 3
fi
if ! mkdir -- "${evidence_dir}"; then
  printf '%s\n' "[V15S-OWNER-ANY-LIVE] evidence directory already exists: ${evidence_dir}" >&2
  exit 2
fi
runtime_dir="$(mktemp -d "${runtime_base}/run.XXXXXX")" || exit 1
task_run_status_init "${status_path}" || exit 1

cleanup_runtime() {
  local resolved
  [[ -n "${runtime_dir}" && -e "${runtime_dir}" ]] || return 0
  resolved="$(realpath -m -- "${runtime_dir}")" || return 1
  case "${resolved}" in
    "${runtime_base}"/run.*) rm -r -- "${resolved}" ;;
    *)
      printf '%s\n' "[V15S-OWNER-ANY-LIVE] refusing cleanup target: ${resolved}" >&2
      return 2
      ;;
  esac
}

finalize_on_exit() {
  local exit_rc=$?
  cleanup_runtime || cleanup_rc=$?
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${exit_rc}" "${cleanup_rc}" || true
  fi
}

signal_exit() {
  local signal_name=$1
  local signal_rc=$2
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  exit "${signal_rc}"
}

trap 'signal_exit HUP 129' HUP
trap 'signal_exit INT 130' INT
trap 'signal_exit TERM 143' TERM
trap finalize_on_exit EXIT

write_input_manifest() {
  sha256sum \
    "${rtl_source}" \
    "${repo_root}/npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md" \
    "${testbench_dir}/tests/tb_ooo_int_backend.sv" \
    "${testbench_dir}/Makefile" \
    "${mutation_runner}" \
    "$0"
}

release_ivflags="-g2012 -Wall -I${repo_root}/npc/rv64/vsrc -I${repo_root}/npc/rv64/vsrc/include -I${testbench_dir}/common"
assert_flags="-DOOO_CSR_QUEUE_HEAD=1 -DHIST_SER_QH_YOUNGER_STORE_FOCUSED -DOOO_ASSERT"

task_run_status_stage preflight
manifest_rc=0
for input in "${rtl_source}" "${mutation_runner}" "$0"; do
  [[ -f "${input}" && ! -L "${input}" && -s "${input}" ]] || manifest_rc=1
done
for command_name in awk bash cmp du flock grep make realpath rm sha256sum timeout; do
  command -v "${command_name}" >/dev/null || manifest_rc=1
done
if [[ "${manifest_rc}" -eq 0 ]]; then
  write_input_manifest >"${evidence_dir}/inputs-before.sha256" || manifest_rc=1
fi

if [[ "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage focused-assert-off
  assert_off_rc=0
  /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    make -C "${testbench_dir}" v15s-mem-owner-any-live-focused \
      "RESULT_DIR=${evidence_dir}/assert-off" \
      "BUILD_DIR=${runtime_dir}/assert-off-build" \
      "IVFLAGS=${release_ivflags}" \
      >"${evidence_dir}/assert-off.driver.log" 2>&1 || assert_off_rc=$?
fi

if [[ "${assert_off_rc}" -eq 0 ]]; then
  task_run_status_stage focused-assert-on
  assert_on_rc=0
  /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    make -C "${testbench_dir}" v15s-mem-owner-any-live-focused \
      "RESULT_DIR=${evidence_dir}/assert-on" \
      "BUILD_DIR=${runtime_dir}/assert-on-build" \
      "IVFLAGS=${release_ivflags}" \
      "TB_IVFLAGS_${focused_test}=${assert_flags}" \
      >"${evidence_dir}/assert-on.driver.log" 2>&1 || assert_on_rc=$?
fi

if [[ "${assert_on_rc}" -eq 0 ]]; then
  task_run_status_stage compile-success-mutation
  mutation_rc=0
  /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    bash "${mutation_runner}" "${evidence_dir}/mutation" \
      >"${evidence_dir}/mutation.driver.log" 2>&1 || mutation_rc=$?
fi

task_run_status_stage evidence-check
assert_off_log="${evidence_dir}/assert-off/logs/${focused_test}.log"
assert_on_log="${evidence_dir}/assert-on/logs/${focused_test}.log"
if [[ "${assert_off_rc}" -eq 0 ]]; then
  grep -Fq '[HIST-SER-QH-YOUNGER-STORE][CURRENT-OWNER-GUARD-PASS]' \
    "${assert_off_log}" || assert_off_rc=1
  grep -Fq '[RESULT] PASS' "${assert_off_log}" || assert_off_rc=1
fi
if [[ "${assert_on_rc}" -eq 0 ]]; then
  grep -Fq '[HIST-SER-QH-YOUNGER-STORE][CURRENT-OWNER-GUARD-PASS]' \
    "${assert_on_log}" || assert_on_rc=1
  grep -Fq '[RESULT] PASS' "${assert_on_log}" || assert_on_rc=1
  if grep -Fq '[V15S-MEM-OWNER-ANY-LIVE]' "${assert_on_log}"; then
    assert_on_rc=1
  fi
fi
if [[ "${mutation_rc}" -eq 0 ]]; then
  grep -Fq 'RESULT=PASS' "${evidence_dir}/mutation/result.txt" || mutation_rc=1
  grep -Fq 'COMPILE_SUCCESS=1' "${evidence_dir}/mutation/result.txt" || mutation_rc=1
  grep -Fq 'MUTATION_DETECTED=1' "${evidence_dir}/mutation/result.txt" || mutation_rc=1
fi

task_run_status_stage runtime-cleanup
if [[ -e "${runtime_dir}" ]]; then
  deleted_bytes="$(du -sb "${runtime_dir}" | awk '{print $1}')"
fi
cleanup_runtime || cleanup_rc=$?
[[ ! -e "${runtime_dir}" ]] || cleanup_rc=1
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
printf '%s\n' \
  'runtime_deleted=PASS' \
  "runtime_bytes_deleted=${deleted_bytes}" \
  'compiled_vvp_retained=NO' >"${evidence_dir}/cleanup.txt"

task_run_status_stage input-manifest-after
write_input_manifest >"${evidence_dir}/inputs-after.sha256" || manifest_rc=1
if [[ "${manifest_rc}" -eq 0 ]] && ! cmp -s \
    "${evidence_dir}/inputs-before.sha256" \
    "${evidence_dir}/inputs-after.sha256"; then
  manifest_rc=1
fi

if [[ "${manifest_rc}" -eq 0 && "${assert_off_rc}" -eq 0 &&
      "${assert_on_rc}" -eq 0 && "${mutation_rc}" -eq 0 &&
      "${cleanup_rc}" -eq 0 && "${deleted_bytes}" -gt 0 ]]; then
  command_rc=0
fi
printf '%s\n' \
  "manifest_rc=${manifest_rc}" \
  "assert_off_rc=${assert_off_rc}" \
  "assert_on_rc=${assert_on_rc}" \
  "mutation_rc=${mutation_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "runtime_bytes_deleted=${deleted_bytes}" \
  "command_rc=${command_rc}" >"${evidence_dir}/command-status.txt"

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
exit "${command_rc}"
