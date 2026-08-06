#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a"
status_path="$task_root/layered-system-v3.status"
driver_log="$task_root/evidence/layered-system-v3.driver.log"
stage=init
finalized=0

mkdir -p -- "$task_root/evidence"
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

stage=task-layered-create
python3 -B npc/rv64/eval/ppa/tools/layered_system_signoff.py create \
  --l0-module-dir "$task_root/evidence/l0-current-final-v3" \
  --l1-replay-dir .github/task-runs/2026-08-05-rv64-v15f-full-core-coremark-checker-replay-v2 \
  --l2-result-dir .github/task-runs/2026-08-05-rv64-v15e-l2-mini-system-all-a11/mini-system \
  --l3-result-dir .github/task-runs/2026-08-05-rv64-v15e-l3-lightweight-linux-all-a6/lightweight-linux \
  --output "$task_root/evidence/layered-system-signoff-final-v3.json"

stage=task-layered-verify
python3 -B npc/rv64/eval/ppa/tools/layered_system_signoff.py verify \
  --receipt "$task_root/evidence/layered-system-signoff-final-v3.json"

stage=canonical-layered-create
python3 -B npc/rv64/eval/ppa/tools/layered_system_signoff.py create \
  --l0-module-dir "$task_root/evidence/l0-current-final-v3" \
  --l1-replay-dir .github/task-runs/2026-08-05-rv64-v15f-full-core-coremark-checker-replay-v2 \
  --l2-result-dir .github/task-runs/2026-08-05-rv64-v15e-l2-mini-system-all-a11/mini-system \
  --l3-result-dir .github/task-runs/2026-08-05-rv64-v15e-l3-lightweight-linux-all-a6/lightweight-linux \
  --output npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json

stage=canonical-layered-verify
python3 -B npc/rv64/eval/ppa/tools/layered_system_signoff.py verify \
  --receipt npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json

stage=task-system-capture
python3 -B npc/rv64/eval/ppa/tools/system_recertification_current.py capture \
  --output "$task_root/evidence/system-recertification-final-v3.json"

stage=task-system-verify
python3 -B npc/rv64/eval/ppa/tools/system_recertification_current.py verify \
  --input "$task_root/evidence/system-recertification-final-v3.json"

stage=canonical-system-capture
python3 -B npc/rv64/eval/ppa/tools/system_recertification_current.py capture \
  --output npc/rv64/eval/ppa/evidence/system-recertification-current.json

stage=canonical-system-verify
python3 -B npc/rv64/eval/ppa/tools/system_recertification_current.py verify \
  --input npc/rv64/eval/ppa/evidence/system-recertification-current.json

printf '%s\n' \
  'PASS stage=complete L0=113/113 L1=177+61 L2=all L3=all Ubuntu=NOT_RUN assertions=0' \
  >"$status_path"
finalized=1
trap - EXIT
