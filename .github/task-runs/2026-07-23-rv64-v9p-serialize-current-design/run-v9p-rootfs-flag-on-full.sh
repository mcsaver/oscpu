#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_dir="${task_run_dir}/rootfs-flag-on-full"
status_path="${task_run_dir}/rootfs-flag-on-full.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
expected_design_sha="9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
host_timeout_seconds="${V9P_ROOTFS_HOST_TIMEOUT_SECONDS:-21600}"
commit_gap_limit_cycles="${V9P_ROOTFS_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V9P_ROOTFS_PROGRESS_INTERVAL:-5000000}"
config_restored=0

mkdir -p "${result_dir}"
printf '%s\n' "RUNNING" > "${status_path}"
restore_npc_config() {
  if [[ "${config_restored}" -eq 0 ]]; then
    make -C "${repo_root}/npc/rv64" default_defconfig \
      > "${result_dir}/config-restore.log" 2>&1
    config_restored=1
  fi
}

finish() {
  local rc=$?
  set +e
  restore_npc_config
  if [[ "${rc}" -eq 0 ]]; then
    printf '%s\n' "PASS" > "${status_path}"
  else
    printf 'FAIL rc=%s\n' "${rc}" > "${status_path}"
  fi
  exit "${rc}"
}
trap finish EXIT

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

# NPC_FAST_SIM only selects the optimized host C++ compiler/flags for the same
# generated RTL model. Build once with the repository-default fast host tuple
# and the validated non-fatal Verilator warning policy, then freeze that exact
# executable for the strict guest run.
rm -f "${simulator}"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  sim \
  > "${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL="${progress_interval}" \
NPC_USER_PROGRESS_LIMIT=256 \
NPC_SYSTEMD_HOST_TIMEOUT="${host_timeout_seconds}" \
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  NPC_SYSTEMD_CHECK_LOG_DIR="${result_dir}/guest" \
  NPC_SYSTEMD_PROGRESS="${progress_interval}" \
  check-npc-systemd-guest-full \
  > "${result_dir}/driver.log" 2>&1

grep -F "[npc-systemd-check] PASS strict guest + natural poweroff" \
  "${result_dir}/driver.log"

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

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  sha256sum \
    "${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
    "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
    "${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb" \
    "${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"
} > "${result_dir}/binding.txt"

printf '%s\n' \
  "[V9P-ROOTFS-FLAG-ON] OOO_CSR_QUEUE_HEAD=1 strict guest + natural poweroff PASS"
