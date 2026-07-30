#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_dir="${repo_root}/.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2"
source_run="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3"
source_status="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3.status"
rootfs="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict/rootfs-c1b531-systemd-strict-6b-a3/rootfs.ext4"
status_path="${task_dir}/a3-checker-replay-v2.status"
evidence_path="${task_dir}/checker-replay-v2-evidence.json"
base_evidence_path="${task_dir}/base-replay-evidence.json"
embedded_checker_path="${task_dir}/a3-embedded-strict-checker.sh"
unit_log="${task_dir}/strict-checker-unit.log"
replay_log="${task_dir}/checker-replay-v2.log"
source_hashes="${task_dir}/source-input-sha256.txt"
status_helper="${repo_root}/scripts/task-run-status.sh"
expected_embedded_sha="83b6a5384bc92a0b6c4977832a5e882c06684de554a8a09e0391a7acff053f9a"

test ! -e "${status_path}"
test ! -e "${evidence_path}"
test ! -e "${base_evidence_path}"
test ! -e "${embedded_checker_path}"
test -f "${rootfs}"
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
  "${source_run}/guest/rootfs-binding.txt" \
  "${source_run}/binding.txt" \
  "${source_run}/post-binding.txt" \
  "${source_run}/systemd-transaction-evidence.json" \
  "${source_run}/rtl-assertion-failures.txt" \
  "${source_run}/terminal-markers.txt" \
  >"${source_hashes}"

task_run_status_stage "strict-checker-unit"
PYTHONDONTWRITEBYTECODE=1 python3 \
  "${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py" \
  >"${unit_log}" 2>&1
grep -Fq "Ran 3 tests" "${unit_log}"
grep -Fq "OK" "${unit_log}"

task_run_status_stage "a3-embedded-checker-replay"
PYTHONDONTWRITEBYTECODE=1 python3 \
  "${task_dir}/replay-a3-checker-v2.py" \
  --out "${evidence_path}" \
  --base-out "${base_evidence_path}" \
  --embedded-out "${embedded_checker_path}" \
  >"${replay_log}" 2>&1
grep -Fq "[V10F-A3-CHECKER-REPLAY-V2]" "${replay_log}"
python3 -m json.tool "${evidence_path}" >/dev/null

task_run_status_stage "embedded-checker-postcheck"
test "$(
  debugfs -R \
    "cat /usr/local/sbin/ysyx-npc-systemd-strict-check" \
    "${rootfs}" 2>/dev/null |
    sha256sum |
    awk '{print $1}'
)" = "${expected_embedded_sha}"
test "$(sha256sum "${embedded_checker_path}" | awk '{print $1}')" = \
  "${expected_embedded_sha}"

task_run_status_stage "source-input-postcheck"
(
  cd "${repo_root}"
  sed "s#${repo_root}/##" "${source_hashes}" |
    sha256sum -c -
)

task_run_status_stage "evidence-complete"
task_run_status_mark_evidence_complete
