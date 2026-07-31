#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
work_root="${run_root}/memory-update-work"
verify_root="${run_root}/memory-update-verify-attempt-1"
status_path="${run_root}/memory-update-attempt-1.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${run_root}/memory-update-attempt-1.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

if [[ -e "${verify_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${verify_root}" >&2
  exit 73
fi

printf 'RUNNING\n' >"${status_path}"
wc -c \
  "${work_root}/.github/memory/modules/npc.md" \
  "${work_root}/.github/memory/project-status.md" \
  >"${run_root}/memory-update-attempt-1.before-publish-bytes.log"

python3 scripts/github_index_db.py update-stored \
  .github/memory/modules/npc.md \
  --from-file "${work_root}/.github/memory/modules/npc.md" \
  --refresh-shim \
  >"${run_root}/memory-update-attempt-1.npc.stdout.log" \
  2>"${run_root}/memory-update-attempt-1.npc.stderr.log"

python3 scripts/github_index_db.py update-stored \
  .github/memory/project-status.md \
  --from-file "${work_root}/.github/memory/project-status.md" \
  --refresh-shim \
  >"${run_root}/memory-update-attempt-1.project.stdout.log" \
  2>"${run_root}/memory-update-attempt-1.project.stderr.log"

python3 scripts/github_index_db.py materialize \
  --path .github/memory/modules/npc.md \
  --output-root "${verify_root}" \
  >"${run_root}/memory-update-attempt-1.verify-npc.stdout.log" \
  2>"${run_root}/memory-update-attempt-1.verify-npc.stderr.log"

python3 scripts/github_index_db.py materialize \
  --path .github/memory/project-status.md \
  --output-root "${verify_root}" \
  >"${run_root}/memory-update-attempt-1.verify-project.stdout.log" \
  2>"${run_root}/memory-update-attempt-1.verify-project.stderr.log"

cmp \
  "${work_root}/.github/memory/modules/npc.md" \
  "${verify_root}/.github/memory/modules/npc.md"
cmp \
  "${work_root}/.github/memory/project-status.md" \
  "${verify_root}/.github/memory/project-status.md"

wc -c \
  "${verify_root}/.github/memory/modules/npc.md" \
  "${verify_root}/.github/memory/project-status.md" \
  >"${run_root}/memory-update-attempt-1.after-publish-bytes.log"

python3 scripts/github_index_db.py snapshot-stored --yes \
  >"${run_root}/memory-update-attempt-1.snapshot.stdout.log" \
  2>"${run_root}/memory-update-attempt-1.snapshot.stderr.log"
