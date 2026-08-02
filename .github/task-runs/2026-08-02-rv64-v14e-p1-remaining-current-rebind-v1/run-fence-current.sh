#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
evidence="${run_dir}/evidence/fence-run-1"
status_path="${run_dir}/fence-run-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
mutation_runner="${repo_root}/.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/run-fence-rtl-variants.py"
tb_dir="${repo_root}/npc/rv64/testbench"
temp_dir="$(mktemp -d /tmp/rv64-v14e-fence.XXXXXXXX)"
finalized=0
cleaned=0
cleanup_rc=0

if [[ -e "${evidence}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14E-FENCE][FAIL] output already exists' >&2
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
    /tmp/rv64-v14e-fence.*) rm -rf -- "${temp_dir}" || cleanup_rc=$? ;;
    *) printf '%s\n' "[V14E-FENCE][FAIL] unsafe temp path ${temp_dir}" >&2; cleanup_rc=1 ;;
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
  "${temp_dir}/positive-result/logs/tb_ooo_priv_system.log" \
  "${temp_dir}/positive-result/logs/tb_ooo_pending_drain_resolve_gate.log" \
  > "${evidence}/positive.driver.log" 2>&1
for test_name in tb_ooo_priv_system tb_ooo_pending_drain_resolve_gate; do
  test -s "${temp_dir}/positive-build/${test_name}.vvp"
  python3 -B "${snapshot_tool}" --root "${repo_root}" normalize-log \
    --input "${temp_dir}/positive-result/logs/${test_name}.log" \
    --output "${evidence}/positive/logs/${test_name}.log" \
    --temp-root "${temp_dir}"
done

task_run_status_stage "compile-success-mutations"
python3 -B "${mutation_runner}" --root "${repo_root}" \
  --output "${evidence}/mutations/summary.json" \
  > "${evidence}/mutations.driver.log" 2>&1

task_run_status_stage "source-binding-post"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-after.json"
cmp "${evidence}/source-before.json" "${evidence}/source-after.json"

task_run_status_stage "summary-audit"
python3 -B "${run_dir}/build-fence-summary.py" \
  --evidence "${evidence}" --output "${evidence}/summary.json" \
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
