#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
evidence="${run_dir}/evidence/vectored-run-1"
status_path="${run_dir}/vectored-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
mutation_runner="${repo_root}/npc/rv64/testbench/scripts/run_csr_vectored_trap_mutations.py"
tb_dir="${repo_root}/npc/rv64/testbench"
temp_dir="$(mktemp -d "${repo_root}/.tmp-v14e-vectored.XXXXXXXX")"
finalized=0
cleaned=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14E-VECTORED-TRAP][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_temp() {
  if [[ "${cleaned}" -eq 1 ]]; then
    return
  fi
  case "${temp_dir}" in
    "${repo_root}"/.tmp-v14e-vectored.*) rm -rf -- "${temp_dir}" || cleanup_rc=$? ;;
    *) printf '%s\n' "[V14E-VECTORED-TRAP][FAIL] unsafe temp path ${temp_dir}" >&2; cleanup_rc=1 ;;
  esac
  cleaned=1
}

finalize_on_exit() {
  local command_rc=$?
  cleanup_temp
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

cd "${repo_root}"
task_run_status_stage "source-binding-pre"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-before.json"
design_id="$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1]))["design_id"].removeprefix("sha256:"))' "${evidence}/source-before.json")"

task_run_status_stage "positive-focused"
mkdir -p "${evidence}/positive/logs"
make -B -C "${tb_dir}" \
  BUILD_DIR="${temp_dir}/positive-build" \
  RESULT_DIR="${temp_dir}/positive-result" \
  RTL_EVIDENCE_SHA="${design_id}" \
  "${temp_dir}/positive-result/logs/tb_csr_file.log" \
  "${temp_dir}/positive-result/logs/tb_csr_file_vectored_trap.log" \
  "${temp_dir}/positive-result/logs/tb_ooo_priv_system.log" \
  > "${evidence}/positive.driver.log" 2>&1
for test_name in tb_csr_file tb_csr_file_vectored_trap tb_ooo_priv_system; do
  test -s "${temp_dir}/positive-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/positive-result/logs/${test_name}.log" \
    --output "${evidence}/positive/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "compile-success-mutations"
python3 -B "${mutation_runner}" --repo-root "${repo_root}" \
  --result-dir "${temp_dir}/mutations" \
  > "${evidence}/mutations.driver.log" 2>&1
mkdir -p "${evidence}/mutations/logs"
for mutation_id in \
  direct_only_target \
  vector_sync_exception \
  force_machine_tvec \
  reserved_mode_passthrough \
  exception_over_memory_priority \
  vector_offset_plus_four \
  drop_nondelegated_supervisor_irq; do
  test -s "${temp_dir}/mutations/${mutation_id}/build/tb_csr_file_vectored_trap.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/mutations/${mutation_id}/run/logs/tb_csr_file_vectored_trap.log" \
    --output "${evidence}/mutations/logs/${mutation_id}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "source-binding-post"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-after.json"
cmp "${evidence}/source-before.json" "${evidence}/source-after.json"

task_run_status_stage "summary-audit"
python3 -B "${run_dir}/build-vectored-summary.py" \
  --evidence "${evidence}" \
  --raw-mutation-manifest "${temp_dir}/mutations/mutation-evidence.json" \
  --mutation-output "${evidence}/mutations/summary.json" \
  --output "${evidence}/summary.json" \
  > "${evidence}/summary.driver.log" 2>&1
command_rc=$?
if [[ "${command_rc}" -ne 0 ]]; then
  tail -n 80 "${evidence}/summary.driver.log" >&2 || true
fi

cleanup_temp
task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
