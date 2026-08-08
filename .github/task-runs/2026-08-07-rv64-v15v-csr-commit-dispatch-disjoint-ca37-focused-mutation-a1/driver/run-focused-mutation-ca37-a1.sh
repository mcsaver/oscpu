#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_rel=.github/task-runs/2026-08-07-rv64-v15v-csr-commit-dispatch-disjoint-ca37-focused-mutation-a1
run_dir=${repo_root}/${run_rel}
evidence_dir=${run_dir}/evidence
status_path=${run_dir}/focused-mutation.status
testbench_dir=${repo_root}/npc/rv64/testbench
identity_checker=${repo_root}/npc/rv64/eval/ppa/tools/mini_system_run.py
expected_design_id=sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f
runtime_dir=
runtime_bytes=0
command_rc=1
cleanup_rc=1

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}"
task_run_status_init "${status_path}"

cleanup_runtime() {
  local resolved

  [[ -n "${runtime_dir}" ]] || {
    cleanup_rc=0
    return 0
  }
  resolved="$(realpath -m -- "${runtime_dir}")"
  case "${resolved}" in
    /tmp/rv64-v15v-focused-mutation.*)
      if [[ -d "${resolved}" ]]; then
        runtime_bytes="$(du -sb -- "${resolved}" | awk '{print $1}')"
        rm -r -- "${resolved}"
      fi
      [[ ! -e "${resolved}" ]]
      cleanup_rc=$?
      ;;
    *)
      printf '%s\n' "cleanup_refused=${resolved}" \
        >"${evidence_dir}/runtime-cleanup.txt"
      cleanup_rc=2
      return 2
      ;;
  esac
  printf 'runtime_deleted=%s\nruntime_bytes_deleted=%s\nruntime_path=%s\n' \
    "$([[ ${cleanup_rc} -eq 0 ]] && printf PASS || printf FAIL)" \
    "${runtime_bytes}" "${resolved}" >"${evidence_dir}/runtime-cleanup.txt"
  return "${cleanup_rc}"
}

finish() {
  local shell_rc=$?
  local final_rc

  trap - EXIT
  if [[ "${TASK_RUN_STATUS_SIGNAL}" != none ]]; then
    command_rc=${shell_rc}
  elif [[ ${command_rc} -ne 0 && ${shell_rc} -ne 0 ]]; then
    command_rc=${shell_rc}
  fi
  if [[ -n "${runtime_dir}" && -e "${runtime_dir}" ]]; then
    cleanup_runtime || true
  fi
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

task_run_status_stage rtl-identity-before
python3 -B "${identity_checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${evidence_dir}/rtl-identity-before.json" \
  >"${evidence_dir}/rtl-identity-before.log"
readarray -t rtl_identity < <(python3 -B - "${evidence_dir}/rtl-identity-before.json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data["rtl_design_id"])
print(data["production_rtl_file_count"])
PY
)
design_id=${rtl_identity[0]}
rtl_file_count=${rtl_identity[1]}
[[ "${design_id}" == "${expected_design_id}" ]]
[[ "${rtl_file_count}" == 146 ]]

task_run_status_stage runtime-create
runtime_dir="$(mktemp -d /tmp/rv64-v15v-focused-mutation.XXXXXX)"
focused_result=${evidence_dir}/focused
mutation_result=${evidence_dir}/mutation

task_run_status_stage focused-assert-on
set +e
make -C "${testbench_dir}" v15v-csr-commit-dispatch-disjoint-focused \
  "RESULT_DIR=${focused_result}" \
  "BUILD_DIR=${runtime_dir}/focused-build" \
  "RTL_EVIDENCE_SHA=${design_id#sha256:}" \
  >"${evidence_dir}/focused-driver.log" 2>&1
focused_rc=$?
set -e
printf 'focused_rc=%s\nconfig=OOO_ASSERT_ON\n' "${focused_rc}" \
  >"${evidence_dir}/command-status.txt"
focused_log=${focused_result}/logs/tb_ooo_pending_system_admission_cancel_gate.log
[[ ${focused_rc} -eq 0 && -s "${focused_log}" ]]
grep -Fq '[V15V-CSR-COMMIT-DISPATCH-DISJOINT] clear=1 cancel=0 head0-cancel=1 PASS' \
  "${focused_log}"
grep -Fq '[RESULT] PASS' "${focused_log}"

task_run_status_stage mutation-assert-off
set +e
make -C "${testbench_dir}" v15v-csr-commit-dispatch-disjoint-mutation \
  "RESULT_DIR=${mutation_result}" \
  >"${evidence_dir}/mutation-driver.log" 2>&1
mutation_rc=$?
set -e
printf 'mutation_rc=%s\nconfig=OOO_ASSERT_OFF\n' "${mutation_rc}" \
  >>"${evidence_dir}/command-status.txt"
mutation_root=${mutation_result}/v15v-csr-commit-dispatch-disjoint-mutation
mutation_record=${mutation_root}/result.txt
[[ ${mutation_rc} -eq 0 && -s "${mutation_record}" ]]
grep -Fqx 'RESULT=PASS' "${mutation_record}"
grep -Fqx 'MUTATION_COUNT=2' "${mutation_record}"
for variant in readd-commit-to-dispatch-cancel drop-commit-from-admission-clear; do
  variant_record=${mutation_root}/${variant}/result.txt
  [[ -s "${variant_record}" ]]
  grep -Fqx 'RESULT=PASS' "${variant_record}"
  grep -Fqx 'COMPILE_SUCCESS=1' "${variant_record}"
  grep -Fqx 'MUTATION_DETECTED=1' "${variant_record}"
  grep -Fqx 'EXPECTED_TEST_FAILURE=1' "${variant_record}"
done

task_run_status_stage rtl-identity-after
python3 -B "${identity_checker}" rtl-identity --repo-root "${repo_root}" \
  --output "${evidence_dir}/rtl-identity-after.json" \
  >"${evidence_dir}/rtl-identity-after.log"
cmp -s "${evidence_dir}/rtl-identity-before.json" \
  "${evidence_dir}/rtl-identity-after.json"

task_run_status_stage summary
printf '%s\n' \
  'result=PASS' \
  "rtl_design_id=${design_id}" \
  "production_rtl_file_count=${rtl_file_count}" \
  'focused_config=OOO_ASSERT_ON' \
  'focused_test=tb_ooo_pending_system_admission_cancel_gate' \
  'focused_result=PASS' \
  'focused_marker=[V15V-CSR-COMMIT-DISPATCH-DISJOINT]' \
  'mutation_count=2' \
  'mutation_config=OOO_ASSERT_OFF' \
  'mutation_compile_success=2/2' \
  'mutation_detected=2/2' \
  'production_identity_stable=PASS' \
  >"${evidence_dir}/summary.txt"

task_run_status_stage cleanup
cleanup_runtime
[[ ${cleanup_rc} -eq 0 ]]

task_run_status_stage evidence-seal
find "${evidence_dir}" -type f \
  ! -name evidence-files.sha256 \
  ! -name evidence-files.verify.log \
  -print0 | LC_ALL=C sort -z | xargs -0 sha256sum \
  >"${evidence_dir}/evidence-files.sha256"
sha256sum -c "${evidence_dir}/evidence-files.sha256" \
  >"${evidence_dir}/evidence-files.verify.log"
task_run_status_mark_evidence_complete
command_rc=0
