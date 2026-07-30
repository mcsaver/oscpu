#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage"
output_log="${task_run_dir}/evidence/commit-gate.log"

exec > >(tee "${output_log}") 2>&1
cd "${repo_root}"

tracked_modified=0
untracked_files=0
staged_entries=0
while IFS= read -r status_line; do
  xy="${status_line:0:2}"
  if [[ "${xy}" == "??" ]]; then
    untracked_files=$((untracked_files + 1))
  else
    tracked_modified=$((tracked_modified + 1))
    if [[ "${xy:0:1}" != " " ]]; then
      staged_entries=$((staged_entries + 1))
    fi
  fi
done < <(git status --porcelain=v1 --untracked-files=all)

branch="$(git branch --show-current)"
head_sha="$(git rev-parse HEAD)"

printf '[V11E-COMMIT-GATE] branch=%s head=%s tracked_modified=%d untracked_files=%d staged_entries=%d\n' \
  "${branch}" \
  "${head_sha}" \
  "${tracked_modified}" \
  "${untracked_files}" \
  "${staged_entries}"

if [[ "${staged_entries}" -gt 0 ]]; then
  echo "[V11E-COMMIT-GATE] preexisting_staged_paths:"
  git diff --cached --name-only
fi

echo "[V11E-COMMIT-GATE] GAP mixed-origin-worktree; no stage or commit authorized"
