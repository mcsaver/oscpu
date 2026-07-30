#!/usr/bin/env bash
set -euo pipefail

task_root=".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
review_root="${task_root}/review-v6"
contract="${task_root}/subagent-contracts/v10e_runner_prelaunch_review_v6.json"
label="rootfs-c1b531-systemd-strict-6b-a3"
runtime_root=".github/runtime-artifacts/rv64-systemd-strict/${label}"
status_path="${task_root}/${label}.status"
result_root="${task_root}/${label}"
lock_path=".github/runtime-artifacts/rv64-engineering-single-flight.lock"
expected_head="af027d1bce085bace474b748dcd89113145f8772"
expected_design_id="sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"

branch="$(git branch --show-current)"
head="$(git rev-parse HEAD)"
[[ "${branch}" == "ai" ]]
[[ "${head}" == "${expected_head}" ]]
printf '[V10E-A3-PRELAUNCH] branch=%s head=%s\n' "${branch}" "${head}"

bash -n \
  "${task_root}/run-v10e-current-design-systemd-strict.sh" \
  "${task_root}/launch-v10e-current-design-systemd-strict.sh" \
  ".github/task-runs/2026-07-24-rv64-v9s-serialize-default/launch-v9s-rootfs-csr-qh-systemd-strict.sh" \
  "scripts/task-run-status.sh" \
  "$0"
printf '[V10E-A3-PRELAUNCH] bash-syntax=PASS\n'

bash scripts/tests/test-task-run-status.sh
python3 "${task_root}/test-runner-contract.py"
python3 \
  .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${contract}"
python3 -m json.tool "${task_root}/round-state.json" >/dev/null

(
  cd "${review_root}"
  sha256sum -c sha256sums.txt
)

design_record="$(
  python3 -c \
    'import pathlib, sys; sys.path.insert(0, "npc/rv64/eval/ppa/tools"); import architecture_hard_gates as gates; design_id, sources = gates.rtl_binding(pathlib.Path.cwd()); print("sha256:" + design_id + " " + str(len(sources)))'
)"
read -r live_design_id source_count <<<"${design_record}"
[[ "${live_design_id}" == "${expected_design_id}" ]]
[[ "${source_count}" == "146" ]]
printf \
  '[V10E-A3-PRELAUNCH] rtl_design_id=%s source_count=%s\n' \
  "${live_design_id}" \
  "${source_count}"

set +e
running_statuses="$(
  rg -l '^RUNNING(?: |$)' .github/task-runs -g '*.status'
)"
running_status_rc=$?
set -e
if [[ "${running_status_rc}" -eq 0 ]]; then
  printf \
    '[V10E-A3-PRELAUNCH] unexpected-running-status=%s\n' \
    "${running_statuses}" \
    >&2
  exit 1
fi
[[ "${running_status_rc}" -eq 1 ]]

test ! -e "${status_path}"
test ! -e "${result_root}"
test ! -e "${runtime_root}"

V10E_RECERT_LAUNCH_VALIDATE_ONLY=1 \
V10E_RECERT_RUN_LABEL="${label}" \
  bash "${task_root}/launch-v10e-current-design-systemd-strict.sh"

test ! -e "${status_path}"
test ! -e "${result_root}"
test ! -e "${runtime_root}"

exec 9>"${lock_path}"
flock -n 9
flock -u 9
exec 9>&-

git diff --check

printf \
  '[V10E-A3-PRELAUNCH] result=PASS label=%s target_vacant=1 lock_available=1\n' \
  "${label}"
