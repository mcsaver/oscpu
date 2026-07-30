#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_dir="${repo_root}/.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay"
source_run="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3"
source_status="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3.status"
status_path="${task_dir}/a3-checker-replay.status"
evidence_path="${task_dir}/checker-replay-evidence.json"
unit_log="${task_dir}/strict-checker-unit.log"
replay_log="${task_dir}/checker-replay.log"
source_hashes="${task_dir}/source-input-sha256.txt"
status_helper="${repo_root}/scripts/task-run-status.sh"

test ! -e "${status_path}"
test ! -e "${evidence_path}"
test -f "${status_helper}"
source "${status_helper}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finish() {
  local command_rc=$?
  local final_rc=0

  trap - EXIT
  set +e
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  set -e
  exit "${final_rc}"
}
trap finish EXIT

task_run_status_stage "freeze-a3-inputs"
sha256sum \
  "${source_status}" \
  "${source_run}/guest/console.log" \
  "${source_run}/guest/npc.log" \
  "${source_run}/binding.txt" \
  "${source_run}/post-binding.txt" \
  "${source_run}/systemd-transaction-evidence.json" \
  "${source_run}/rtl-assertion-failures.txt" \
  "${source_run}/terminal-markers.txt" \
  >"${source_hashes}"

task_run_status_stage "strict-checker-unit"
python3 \
  "${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py" \
  >"${unit_log}" 2>&1
grep -Fq "Ran 3 tests" "${unit_log}"
grep -Fq "OK" "${unit_log}"

task_run_status_stage "a3-checker-replay"
python3 "${task_dir}/replay-a3-checker.py" \
  --out "${evidence_path}" >"${replay_log}" 2>&1
grep -Fq \
  "[V10F-A3-CHECKER-REPLAY]" \
  "${replay_log}"
python3 -m json.tool "${evidence_path}" >/dev/null

task_run_status_stage "source-input-postcheck"
(
  cd "${repo_root}"
  sed "s#${repo_root}/##" "${source_hashes}" |
    sha256sum -c -
)

task_run_status_stage "evidence-complete"
task_run_status_mark_evidence_complete
