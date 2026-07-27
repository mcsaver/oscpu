#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_dir="${task_run_dir}/rootfs-commit-gap-diagnostic"
status_path="${task_run_dir}/rootfs-commit-gap-diagnostic.status"
classification_path="${task_run_dir}/rootfs-commit-gap-diagnostic.classification.json"
classifier="${task_run_dir}/classify-v9p-rootfs-commit-gap.py"
diag_config="${task_run_dir}/configs/rv64-linux-debug-ports-defconfig"
canonical_config="${repo_root}/Linux/configs/rv64_linux_defconfig"
build_dir="${repo_root}/npc/rv64/build-v9p-commit-gap"
simulator="${build_dir}/NpcSimTop"
smoke_image="${task_run_dir}/riscv-fullstate-smoke/images/rv64mi-p-csr.bin"
expected_design_sha="9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
commit_gap_limit_cycles=1000000
host_timeout_seconds=7200
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
test -s "${smoke_image}"
simulator_sha="$(sha256sum "${simulator}" | awk '{print $1}')"

restore_linux_config

NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
  "${simulator}" \
  -b \
  --no-progress \
  --no-diff \
  --max-cycles=2000000 \
  --tohost=0x0000000080001000 \
  --log="${result_dir}/smoke-npc.log" \
  "${smoke_image}" \
  > "${result_dir}/smoke-console.log" 2>&1
grep -F "commit-gap] enabled" "${result_dir}/smoke-npc.log"
grep -Eq "TOHOST PASS|HIT GOOD TRAP" "${result_dir}/smoke-npc.log"
if grep -F "commit-gap] expired" "${result_dir}/smoke-npc.log"; then
  printf '%s\n' "[V9P-ROOTFS-COMMIT-GAP][FAIL] enabled watcher stopped a passing RV64 CSR smoke" >&2
  exit 1
fi

set +e
NPC_OOO_WINDOW=0 \
NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL=5000000 \
NPC_USER_PROGRESS_LIMIT=128 \
timeout --signal=INT --kill-after=30s "${host_timeout_seconds}s" \
  "${simulator}" \
  -b \
  --progress=5000000 \
  --no-diff \
  --max=3000000000 \
  --log="${result_dir}/npc.log" \
  -i "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
  --load=0x80200000:"${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
  --load=0x82200000:"${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb" \
  --block="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4" \
  > "${result_dir}/console.log" 2>&1
sim_rc=$?
set -e
printf '%s\n' "${sim_rc}" > "${result_dir}/sim-rc.txt"

case "${sim_rc}" in
  3)
    grep -F "commit-gap] expired" "${result_dir}/npc.log"
    grep -F "recent commits before stop:" "${result_dir}/npc.log"
    grep -F "recent debug cycles before stop:" "${result_dir}/npc.log"
    grep -F "memdiag=" "${result_dir}/npc.log"
    ;;
  124)
    grep -F "commit-gap] enabled" "${result_dir}/npc.log"
    grep -F "[progress]" "${result_dir}/npc.log"
    grep -F "[npc] execution interrupted" "${result_dir}/npc.log"
    if grep -F "commit-gap] expired" "${result_dir}/npc.log"; then
      printf '%s\n' \
        "[V9P-ROOTFS-COMMIT-GAP][FAIL] host-budget outcome contains an expiration marker" \
        >&2
      exit 1
    fi
    ;;
  *)
    printf '%s\n' \
      "[V9P-ROOTFS-COMMIT-GAP][FAIL] unexpected simulator return code ${sim_rc}" \
      >&2
    exit 1
    ;;
esac

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
[[ "${design_sha_post}" == "${design_sha_pre}" ]]

{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha}"
  printf 'OOO_CSR_QUEUE_HEAD=1\n'
  printf 'CONFIG_NPC_DEBUG_PORTS=y\n'
  printf 'CONFIG_NPC_SIM_STATS=n\n'
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'sim_rc=%s\n' "${sim_rc}"
  printf 'rootfs_promotion_eligible=false\n'
} > "${result_dir}/binding.txt"

python3 "${classifier}" \
  --log "${result_dir}/npc.log" \
  --output "${classification_path}" \
  --sim-rc "${sim_rc}" \
  --sim-rc-source "persisted_by_runner" \
  --host-timeout-seconds "${host_timeout_seconds}" \
  --commit-gap-limit-cycles "${commit_gap_limit_cycles}" \
  --rtl-design-id "sha256:${design_sha_pre}" \
  --simulator-sha256 "${simulator_sha}" \
  --harness-status "PASS"

printf '%s\n' \
  "[V9P-ROOTFS-COMMIT-GAP] diagnostic outcome classified PASS; rootfs gate remains unresolved"
