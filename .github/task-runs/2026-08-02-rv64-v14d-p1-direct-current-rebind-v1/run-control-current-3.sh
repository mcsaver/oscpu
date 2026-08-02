#!/usr/bin/env bash

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1"
v9o_evidence="${run_dir}/evidence/control-run-1"
v9r_evidence="${run_dir}/evidence/control-run-2"
v9o_replay="${run_dir}/evidence/control-checker-replay-1/replay.json"
warning_replay_dir="${run_dir}/evidence/control-warning-checker-replay-1"
evidence="${run_dir}/evidence/control-run-3"
status_path="${run_dir}/control-run-3.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
finalized=0

if [[ -e "${evidence}" || -e "${status_path}" || -e "${warning_replay_dir}" ]]; then
  printf '%s\n' '[V14D-CONTROL-EVENT-3][FAIL] output already exists' >&2
  exit 2
fi
if [[ "$(<"${run_dir}/control-run-1.status")" != \
  'FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0' || \
  "$(<"${run_dir}/control-run-2.status")" != \
  'FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0' ]]; then
  printf '%s\n' '[V14D-CONTROL-EVENT-3][FAIL] historical attempt status drift' >&2
  exit 2
fi

mkdir -p "${evidence}" "${warning_replay_dir}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" 0 || true
  fi
}
trap finalize_on_exit EXIT

cd "${repo_root}"
task_run_status_stage "source-binding-pre"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-before.sha256"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-before.json"
cmp "${v9o_evidence}/source-before.json" "${evidence}/source-before.json"
cmp "${v9r_evidence}/source-before.json" "${evidence}/source-before.json"
cmp "${v9r_evidence}/source-after.json" "${evidence}/source-before.json"
cmp "${v9o_evidence}/canonical-before.sha256" "${evidence}/canonical-before.sha256"
cmp "${v9r_evidence}/canonical-before.sha256" "${evidence}/canonical-before.sha256"
cmp "${v9r_evidence}/canonical-after.sha256" "${evidence}/canonical-before.sha256"

task_run_status_stage "warning-checker-replay"
python3 -B "${run_dir}/build-warning-checker-replay.py" \
  --v9o-evidence "${v9o_evidence}" \
  --v9r-evidence "${v9r_evidence}" \
  --attempt-status "${run_dir}/control-run-2.status" \
  --attempt-summary-log "${v9r_evidence}/summary.driver.log" \
  --output "${warning_replay_dir}/replay.json" \
  > "${warning_replay_dir}/replay.driver.log" 2>&1

task_run_status_stage "source-binding-post"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-after.json"
cmp "${evidence}/source-before.json" "${evidence}/source-after.json"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-after.sha256"
cmp "${evidence}/canonical-before.sha256" "${evidence}/canonical-after.sha256"

task_run_status_stage "summary-audit"
python3 -B "${run_dir}/build-control-summary.py" \
  --evidence "${evidence}" \
  --v9o-evidence "${v9o_evidence}" \
  --v9r-evidence "${v9r_evidence}" \
  --v9o-replay "${v9o_replay}" \
  --warning-replay "${warning_replay_dir}/replay.json" \
  --output "${evidence}/summary.json" \
  > "${evidence}/summary.driver.log" 2>&1

task_run_status_stage "evidence-complete"
if [[ -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize 0 0
