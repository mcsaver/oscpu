#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-25-rv64-systemd-strict-rootfs"
image="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict.ext4"
cpio="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict-rootfs.cpio"
status_path="${task_run_dir}/status"
reuse_image="${RV64_STRICT_ROOTFS_REUSE_IMAGE:-0}"
status_helper="${repo_root}/scripts/task-run-status.sh"

mkdir -p "${task_run_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

finish() {
  local command_rc=$?
  local final_rc

  trap - EXIT HUP INT TERM
  set +e
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

task_run_status_stage "rootfs-image"
if [[ "${reuse_image}" == "1" ]]; then
  test -s "${image}"
  test -s "${cpio}"
  printf '%s\n' "reused_existing_strict_rootfs=1" >"${task_run_dir}/reuse.log"
else
  make -C "${repo_root}/Linux" \
    ARCH=riscv64-npc \
    ubuntu-rootfs-systemd-strict-image \
    >"${task_run_dir}/build.log" 2>&1
fi

task_run_status_stage "rootfs-static-check"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  check-ubuntu-rootfs-systemd-strict \
  >"${task_run_dir}/check.log" 2>&1

grep -F "NPC strict rootfs unit enabled for sysinit.target" \
  "${task_run_dir}/check.log"
grep -F "NPC strict rootfs unit ordering and ttyS0 output" \
  "${task_run_dir}/check.log"

task_run_status_stage "rootfs-binding"
{
  printf '%s\n' "rootfs_flavor=systemd-minimal"
  printf 'reused_existing_strict_rootfs=%s\n' "${reuse_image}"
  printf '%s\n' "UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=1"
  printf '%s\n' "UBUNTU_ROOTFS_NPC_STRICT_AUTORUN=1"
  sha256sum \
    "${image}" \
    "${cpio}" \
    "${repo_root}/Linux/scripts/npc-systemd-strict-check.sh" \
    "${repo_root}/Linux/scripts/build-ubuntu-rootfs.sh" \
    "${repo_root}/Linux/scripts/check-ubuntu-rootfs.sh" \
    "${repo_root}/Linux/scripts/check-npc-systemd-guest.sh"
} >"${task_run_dir}/binding.txt"

debugfs -R "cat /etc/systemd/system/ysyx-npc-systemd-strict.service" \
  "${image}" >"${task_run_dir}/strict-unit.txt" 2>&1
debugfs -R "stat /etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-strict.service" \
  "${image}" >"${task_run_dir}/strict-unit-enablement.txt" 2>&1

task_run_status_stage "strict-unit-check"
grep -F "ExecStart=/usr/local/sbin/ysyx-npc-systemd-strict-check --poweroff" \
  "${task_run_dir}/strict-unit.txt"
grep -F 'Fast link dest: "../ysyx-npc-systemd-strict.service"' \
  "${task_run_dir}/strict-unit-enablement.txt"

printf '%s\n' "[RV64-STRICT-ROOTFS] build + static image checks PASS"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
