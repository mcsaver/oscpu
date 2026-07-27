#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_dir="${task_run_dir}/linux-debug-ports"
status_path="${task_run_dir}/linux-debug-ports.status"
diag_config="${task_run_dir}/configs/rv64-linux-debug-ports-defconfig"
canonical_config="${repo_root}/Linux/configs/rv64_linux_defconfig"
build_dir="${repo_root}/npc/rv64/build-csrqh-debugports"
simulator="${build_dir}/NpcSimTop"
config_restored=0

mkdir -p "${result_dir}"
printf '%s\n' "RUNNING" > "${status_path}"

restore_linux_config() {
  if [[ "${config_restored}" -eq 0 ]]; then
    make -C "${repo_root}/Linux" \
      ARCH=riscv64-npc \
      LINUX_CONFIG="${canonical_config}" \
      FORCE_CONFIG=1 \
      linux-defconfig \
      > "${result_dir}/config-restore.log" 2>&1
    config_restored=1
  fi
}

finish() {
  local rc=$?
  set +e
  restore_linux_config
  if [[ "${rc}" -eq 0 ]]; then
    printf '%s\n' "PASS" > "${status_path}"
  else
    printf 'FAIL rc=%s\n' "${rc}" > "${status_path}"
  fi
  exit "${rc}"
}
trap finish EXIT

make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  LINUX_CONFIG="${diag_config}" \
  FORCE_CONFIG=1 \
  linux-defconfig \
  > "${result_dir}/config-apply.log" 2>&1

rm -f "${simulator}"
make -C "${repo_root}/npc/rv64" \
  BUILD_DIR="${build_dir}" \
  OOO_CSR_QUEUE_HEAD=1 \
  CXX=/usr/bin/clang++ \
  LINK=/usr/bin/clang++ \
  VERILATOR='verilator -Wno-fatal' \
  VERILATOR_OPT_FAST='-O3 -march=native' \
  VERILATOR_OPT_GLOBAL='-O3 -march=native' \
  > "${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha="$(sha256sum "${simulator}" | awk '{print $1}')"

restore_linux_config

design_sha="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"

set +e
timeout 7200s "${simulator}" \
  -b \
  --progress=25000000 \
  --no-diff \
  --max=300000000 \
  --log="${result_dir}/npc.log" \
  -i "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
  --load=0x80200000:"${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
  --load=0x82200000:"${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb" \
  --block="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4" \
  > "${result_dir}/console.log" 2>&1
sim_rc=$?
set -e

[[ "${sim_rc}" -ne 0 ]]
grep -F "ooo flags=" "${result_dir}/npc.log"
grep -F "recent debug cycles before stop:" "${result_dir}/npc.log"

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha}"
  printf 'simulator_sha256=%s\n' "${simulator_sha}"
  printf 'OOO_CSR_QUEUE_HEAD=1\n'
  printf 'CONFIG_NPC_DEBUG_PORTS=y\n'
  printf 'CONFIG_NPC_SIM_STATS=n\n'
  printf 'max_cycles=300000000\n'
  printf 'sim_rc=%s\n' "${sim_rc}"
} > "${result_dir}/binding.txt"

printf '%s\n' \
  "[V9P-LINUX-DEBUG-PORTS] 300M-cycle owner/bus snapshot captured PASS"
