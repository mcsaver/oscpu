#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11d-memory-tracker-cursor-semantic-coverage"
canonical_evidence="${task_run_dir}/evidence/cursor-attempt-2"
output_log="${task_run_dir}/evidence/final-identity.log"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
temporary_binding="$(mktemp /tmp/v11d-final-rtl.XXXXXX.json)"

cleanup() {
  rm -f -- "${temporary_binding}"
}
trap cleanup EXIT

exec > >(tee "${output_log}") 2>&1
cd "${repo_root}"

python3 "${snapshot_tool}" --snapshot-out "${temporary_binding}"
cmp "${temporary_binding}" "${canonical_evidence}/rtl-source-binding.post.json"
sha256sum -c "${canonical_evidence}/sources.post.sha256"

tracker_hash="$(sha256sum npc/rv64/vsrc/memory/OooMemOwnerTracker.v | awk '{print $1}')"
expected_tracker_hash="fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8"
if [[ "${tracker_hash}" != "${expected_tracker_hash}" ]]; then
  echo "[V11D-FINAL-IDENTITY][FAIL] tracker_sha256=${tracker_hash}"
  exit 1
fi

python3 -m json.tool "${task_run_dir}/round-state.json" >/dev/null
bash -n \
  "${task_run_dir}/run-memory-tracker-cursor-focused.sh" \
  "${task_run_dir}/run-arch-stable-observation.sh" \
  "${task_run_dir}/run-guards.sh" \
  "${task_run_dir}/verify-final-identity.sh"

git diff --check -- \
  npc/rv64/testbench/Makefile \
  npc/rv64/eval/ppa/tools/arch_stable_freeze.py \
  npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  .github/memory/project-status.md \
  .github/memory/modules/npc.md

echo "[V11D-FINAL-IDENTITY][PASS] design_id=sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375 tracker_sha256=${tracker_hash}"
