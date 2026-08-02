#!/usr/bin/env bash

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1"
test_evidence="${run_dir}/evidence/store-run-1"
v13r_replay="${run_dir}/evidence/store-v13r-checker-replay-1/replay.json"
warning_replay_dir="${run_dir}/evidence/store-warning-checker-replay-1"
evidence="${run_dir}/evidence/store-run-3"
status_path="${run_dir}/store-run-3.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
finalized=0

if [[ -e "${evidence}" || -e "${status_path}" || -e "${warning_replay_dir}" ]]; then
  printf '%s\n' '[V14D-STORE-BRESP-3][FAIL] output already exists' >&2
  exit 2
fi
if [[ "$(<"${run_dir}/store-run-1.status")" != \
  'FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0' || \
  "$(<"${run_dir}/store-run-2.status")" != \
  'FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0' ]]; then
  printf '%s\n' '[V14D-STORE-BRESP-3][FAIL] historical attempt status drift' >&2
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
cmp "${test_evidence}/source-before.json" "${evidence}/source-before.json"
cmp "${test_evidence}/canonical-before.sha256" "${evidence}/canonical-before.sha256"

task_run_status_stage "warning-checker-replay"
python3 -B "${run_dir}/build-store-warning-checker-replay.py" \
  --test-evidence "${test_evidence}" \
  --attempt-status "${run_dir}/store-run-2.status" \
  --attempt-summary-log "${run_dir}/evidence/store-run-2/summary.driver.log" \
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
python3 -B "${run_dir}/build-store-summary.py" \
  --evidence "${evidence}" \
  --test-evidence "${test_evidence}" \
  --v13r-replay "${v13r_replay}" \
  --warning-replay "${warning_replay_dir}/replay.json" \
  --output "${evidence}/summary.json" \
  > "${evidence}/summary.driver.log" 2>&1

if find "${run_dir}" -type f \( -name '*.vvp' -o -name '*.o' -o -name '*.pyc' \) -print -quit | grep -q .; then
  printf '%s\n' '[V14D-STORE-BRESP-3][FAIL] transient compiled product retained' >&2
  exit 3
fi
task_run_status_stage "evidence-complete"
if [[ -s "${evidence}/summary.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize 0 0
