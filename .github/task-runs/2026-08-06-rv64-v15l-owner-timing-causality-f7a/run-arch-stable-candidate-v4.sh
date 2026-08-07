#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a"
status_path="$task_root/arch-stable-candidate-v4.status"
driver_log="$task_root/evidence/arch-stable-candidate-v4.driver.log"
stage=build
finalized=0

printf '%s\n' 'RUNNING stage=build' >"$status_path"
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
export PATH=/home/lyg/tools/OpenSTA/build:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin

python3 -B npc/rv64/eval/ppa/tools/arch_stable_current_candidate.py \
  --output-dir "$task_root/evidence/arch-stable-candidate-f7a-v4" \
  --architecture-evidence .github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence/architecture-current-final.json \
  --architecture-result .github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence/architecture-current-verification-final.json \
  --functional-aggregate .github/task-runs/2026-08-05-rv64-v15f-full-core-coremark-checker-replay-v2/evidence/functional/functional-aggregate.json \
  --claim ARCH_STABLE

printf '%s\n' \
  'PASS stage=complete schema=v2 claim=ARCH_STABLE ppa=UNQUALIFIED promotion_eligible=false' \
  >"$status_path"
finalized=1
trap - EXIT
