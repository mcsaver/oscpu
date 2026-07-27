#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-24-rv64-v9s-serialize-default"
run_label="${V9S_ROOTFS_RUN_LABEL:-rootfs-csr-qh-on-current}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d"
host_timeout_seconds="${V9S_ROOTFS_HOST_TIMEOUT_SECONDS:-36000}"
commit_gap_limit_cycles="${V9S_ROOTFS_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V9S_ROOTFS_PROGRESS_INTERVAL:-5000000}"
config_restored=0
status_helper="${repo_root}/scripts/task-run-status.sh"

mkdir -p "${result_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

restore_npc_config() {
  local restore_rc=0

  if [[ "${config_restored}" -eq 0 ]]; then
    set +e
    make -C "${repo_root}/npc/rv64" default_defconfig \
      > "${result_dir}/config-restore.log" 2>&1
    restore_rc=$?
    if [[ "${restore_rc}" -eq 0 ]]; then
      config_restored=1
    fi
    return "${restore_rc}"
  fi
  return 0
}

finish() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc

  trap - EXIT HUP INT TERM
  set +e
  restore_npc_config
  cleanup_rc=$?
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

task_run_status_stage "rtl-binding-pre"
design_sha_pre="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
[[ "${design_sha_pre}" == "${expected_design_sha}" ]]

task_run_status_stage "simulator-build"
rm -f "${simulator}"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_OOO_TERMINAL_HOLDER_ASSERT=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  sim \
  > "${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

task_run_status_stage "evidence-binding-pre"
{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  sha256sum \
    "${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
    "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
    "${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb" \
    "${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"
} > "${result_dir}/binding.txt"

task_run_status_stage "systemd-full-guest"
NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL="${progress_interval}" \
NPC_USER_PROGRESS_LIMIT=256 \
NPC_SYSTEMD_HOST_TIMEOUT="${host_timeout_seconds}" \
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_OOO_TERMINAL_HOLDER_ASSERT=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  NPC_SYSTEMD_CHECK_LOG_DIR="${result_dir}/guest" \
  NPC_SYSTEMD_PROGRESS="${progress_interval}" \
  check-npc-systemd-guest-full \
  > "${result_dir}/driver.log" 2>&1

task_run_status_stage "strict-marker-check"
grep -F "[npc-systemd-check] PASS strict guest + natural poweroff" \
  "${result_dir}/driver.log"

task_run_status_stage "rtl-binding-post"
design_sha_post="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
simulator_sha_post="$(sha256sum "${simulator}" | awk '{print $1}')"
[[ "${design_sha_post}" == "${design_sha_pre}" ]]
[[ "${simulator_sha_post}" == "${simulator_sha_pre}" ]]

printf '%s\n' \
  "[V9S-ROOTFS-CSR-QH-ON] current design strict guest + natural poweroff PASS"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
