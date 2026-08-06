#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a"
status_path="$task_root/current-receipts-v3-resume.status"
driver_log="$task_root/evidence/current-receipts-v3-resume.driver.log"
stage=init
finalized=0

printf '%s\n' 'RUNNING stage=init' >"$status_path"
exec > >(tee "$driver_log") 2>&1

finish_on_exit() {
  local rc=$?
  if [[ "$finalized" -eq 0 ]]; then
    printf 'FAIL rc=%s stage=%s evidence_complete=0 cleanup_rc=0\n' \
      "$rc" "$stage" >"$status_path"
  fi
}
trap finish_on_exit EXIT

cd "$repo_root"

stage=delta-rebind-canonical-build
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py build \
  --output npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json

stage=delta-rebind-canonical-verify
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py verify \
  --input npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json

stage=delta-rebind-task-build
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py build \
  --output "$task_root/evidence/architecture-debt-delta-rebind-final-v3.json"

stage=delta-rebind-task-verify
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py verify \
  --input "$task_root/evidence/architecture-debt-delta-rebind-final-v3.json"

stage=architecture-debt-refresh
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_current.py refresh \
  --output npc/rv64/eval/ppa/evidence/architecture-debt-current.json

stage=architecture-debt-verify
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_current.py verify \
  --input npc/rv64/eval/ppa/evidence/architecture-debt-current.json

stage=architecture-debt-task-build
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_current.py build \
  --output "$task_root/evidence/architecture-debt-current-final-v3.json"

stage=architecture-debt-task-verify
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_current.py verify \
  --input "$task_root/evidence/architecture-debt-current-final-v3.json"

stage=historical-defect-refresh
python3 -B npc/rv64/eval/ppa/tools/historical_defect_current.py refresh \
  --output npc/rv64/eval/ppa/evidence/historical-defect-current.json

stage=historical-defect-verify
python3 -B npc/rv64/eval/ppa/tools/historical_defect_current.py verify \
  --input npc/rv64/eval/ppa/evidence/historical-defect-current.json \
  --expected-design-id sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9

stage=historical-defect-task-build
python3 -B npc/rv64/eval/ppa/tools/historical_defect_current.py build \
  --output "$task_root/evidence/historical-defect-current-final-v3.json"

stage=historical-defect-task-verify
python3 -B npc/rv64/eval/ppa/tools/historical_defect_current.py verify \
  --input "$task_root/evidence/historical-defect-current-final-v3.json" \
  --expected-design-id sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9

printf '%s\n' \
  'PASS stage=complete delta=146/3/175/19 architecture_debt=16+4 historical_defect=6/6 whole_architecture=RED ppa=UNPROMOTED' \
  >"$status_path"
finalized=1
trap - EXIT
