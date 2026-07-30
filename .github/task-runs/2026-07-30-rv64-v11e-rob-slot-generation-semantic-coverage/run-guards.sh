#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage"
profile_evidence="${repo_root}/.github/task-runs/2026-07-30-rob-slot-generation-final"
scoped_log="${task_run_dir}/evidence/scoped-strict-guard.log"
full_log="${task_run_dir}/evidence/full-worktree-strict-guard.log"

cd "${repo_root}"

set +e
scripts/agent-e2e.sh \
  --guard \
  --guard-mode strict \
  --paths-file "${task_run_dir}/guard-paths.txt" \
  --evidence-dir "${profile_evidence}" \
  2>&1 | tee "${scoped_log}"
scoped_rc="${PIPESTATUS[0]}"
set -e

if [[ "${scoped_rc}" -ne 0 ]] ||
   ! grep -Fq "[agent-e2e-guard] PASS profile=npc-dev evidence=" \
     "${scoped_log}" ||
   ! grep -Fq "2026-07-30-rob-slot-generation-final" "${scoped_log}"; then
  echo "[V11E-SCOPED-GUARD][FAIL] rc=${scoped_rc}" | tee -a "${scoped_log}"
  exit 1
fi
echo "[V11E-SCOPED-GUARD][PASS] paths=7 profile=npc-dev" |
  tee -a "${scoped_log}"

set +e
scripts/agent-e2e.sh --guard --guard-mode strict 2>&1 | tee "${full_log}"
full_rc="${PIPESTATUS[0]}"
set -e

if [[ "${full_rc}" -ne 1 ]] ||
   ! grep -Fq \
     "[agent-e2e-guard] FAIL missing_evidence profile=rv64-linux reason=Linux/scripts/check-ubuntu-rootfs.sh" \
     "${full_log}" ||
   ! grep -Fq "[agent-e2e-guard] PASS profile=agent-system" "${full_log}" ||
   ! grep -Fq "[agent-e2e-guard] PASS profile=rv64-systemd-contract" "${full_log}" ||
   ! grep -Fq "[agent-e2e-guard] PASS profile=npc-dev" "${full_log}"; then
  echo "[V11E-FULL-GUARD][FAIL] unexpected guard result rc=${full_rc}" |
    tee -a "${full_log}"
  exit 1
fi
echo "[V11E-FULL-GUARD] EXPECTED_GAP profile=rv64-linux scope=shared-worktree" |
  tee -a "${full_log}"
