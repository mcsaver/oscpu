#!/usr/bin/env bash

set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1"
evidence="${run_dir}/evidence/p1-direct-1"
section13="${run_dir}/evidence/section13-current-1"
status_path="${run_dir}/p1-direct-1.status"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
finalized=0

if [[ -e "${evidence}" || -e "${section13}" || -e "${status_path}" ]]; then
  printf '%s\n' '[V14D-P1-DIRECT-FINAL][FAIL] output already exists' >&2
  exit 2
fi
if [[ "$(<"${run_dir}/control-run-3.status")" != 'PASS' || \
  "$(<"${run_dir}/store-run-3.status")" != 'PASS' ]]; then
  printf '%s\n' '[V14D-P1-DIRECT-FINAL][FAIL] gate status drift' >&2
  exit 2
fi
mkdir -p "${evidence}" "${section13}"
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
task_run_status_stage "source-binding"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-before.sha256"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-before.json"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${evidence}/source-after.json"
cmp "${evidence}/source-before.json" "${evidence}/source-after.json"
sha256sum \
  npc/rv64/eval/ppa/evidence/architecture-current.json \
  npc/rv64/design/arch/architecture-debt-ledger.json \
  npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  > "${evidence}/canonical-after.sha256"
cmp "${evidence}/canonical-before.sha256" "${evidence}/canonical-after.sha256"

task_run_status_stage "p1-direct-receipt"
python3 -B "${run_dir}/build-p1-direct-receipt.py" \
  --evidence "${evidence}" --output "${evidence}/receipt.json" \
  > "${evidence}/receipt.driver.log" 2>&1

task_run_status_stage "section13-current-audit"
python3 -B "${run_dir}/build-section13-current-audit.py" \
  --output "${section13}/section13-current-audit.json" \
  --matrix "${section13}/blocker-matrix.txt" \
  > "${section13}/section13.driver.log" 2>&1

if find "${run_dir}" -type f \( -name '*.vvp' -o -name '*.o' -o -name '*.pyc' \) -print -quit | grep -q .; then
  printf '%s\n' '[V14D-P1-DIRECT-FINAL][FAIL] transient compiled product retained' >&2
  exit 3
fi
task_run_status_stage "evidence-complete"
if [[ -s "${evidence}/receipt.json" && \
  -s "${section13}/section13-current-audit.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize 0 0
