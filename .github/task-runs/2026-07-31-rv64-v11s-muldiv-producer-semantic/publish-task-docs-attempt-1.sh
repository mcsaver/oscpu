#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
work_root="${run_root}/task-doc-publish-work-attempt-1"
verify_root="${run_root}/task-doc-publish-verify-attempt-1"
status_path="${run_root}/task-doc-publish-attempt-1.status"
docs=(
  contract.md
  implementation-result.md
  test-disposition.md
  final-review-result.md
  completion-definition.md
  task-report.md
  dispatch-log.md
  evidence-map.md
)

if [[ -e "${work_root}" || -e "${verify_root}" ]]; then
  printf 'refusing to overwrite task document publication work roots\n' >&2
  exit 73
fi

mkdir -p "${work_root}" "${verify_root}"
printf 'RUNNING\n' >"${status_path}"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${run_root}/task-doc-publish-attempt-1.rc"
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

for doc in "${docs[@]}"; do
  cp --reflink=auto "${run_root}/${doc}" "${work_root}/${doc}"
done

for doc in "${docs[@]}"; do
  log_stem=${doc%.md}
  python3 scripts/github_index_db.py update-stored \
    "${run_root}/${doc}" \
    --from-file "${work_root}/${doc}" \
    --refresh-shim \
    >"${run_root}/task-doc-publish-attempt-1.${log_stem}.stdout.log" \
    2>"${run_root}/task-doc-publish-attempt-1.${log_stem}.stderr.log"
  python3 scripts/github_index_db.py materialize \
    --path "${run_root}/${doc}" \
    --output-root "${verify_root}" \
    >"${run_root}/task-doc-publish-attempt-1.${log_stem}.verify.stdout.log" \
    2>"${run_root}/task-doc-publish-attempt-1.${log_stem}.verify.stderr.log"
  cmp \
    "${work_root}/${doc}" \
    "${verify_root}/${run_root}/${doc}"
done

python3 scripts/github_index_db.py snapshot-stored --yes \
  >"${run_root}/task-doc-publish-attempt-1.snapshot.stdout.log" \
  2>"${run_root}/task-doc-publish-attempt-1.snapshot.stderr.log"

printf '%s\n' '[V11S-TASK-DOC-PUBLISH][PASS]'
