#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-24-rv64-v9s-serialize-default"
run_label="${V9S_ROOTFS_RUN_LABEL:-rootfs-csr-qh-on-current-systemd-strict}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
simulator="${repo_root}/npc/rv64/build-csrqh/NpcSimTop"
rootfs_template="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict.ext4"
rootfs_cpio="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict-rootfs.cpio"
rootfs_runtime_dir="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict/${run_label}"
rootfs_run_image="${rootfs_runtime_dir}/rootfs.ext4"
expected_design_sha="c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d"
host_timeout_seconds="${V9S_ROOTFS_HOST_TIMEOUT_SECONDS:-36000}"
commit_gap_limit_cycles="${V9S_ROOTFS_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V9S_ROOTFS_PROGRESS_INTERVAL:-5000000}"
config_restored=0
rootfs_template_sha=""
rootfs_cpio_sha=""
status_helper="${repo_root}/scripts/task-run-status.sh"

mkdir -p "${result_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

restore_npc_config() {
  local restore_rc=0

  if [[ "${config_restored}" -eq 0 ]]; then
    set +e
    make -C "${repo_root}/npc/rv64" default_defconfig \
      >"${result_dir}/config-restore.log" 2>&1
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
  local restore_rc=0
  local rootfs_artifact_rc=0
  local final_rc

  trap - EXIT HUP INT TERM
  set +e
  restore_npc_config
  restore_rc=$?
  {
    printf 'rootfs_template_pre_sha256=%s\n' \
      "${rootfs_template_sha:-UNAVAILABLE}"
    if [[ -s "${rootfs_template}" ]]; then
      rootfs_template_post_sha="$(sha256sum "${rootfs_template}" | awk '{print $1}')"
      printf 'rootfs_template_post_sha256=%s\n' "${rootfs_template_post_sha}"
      if [[ -n "${rootfs_template_sha}" &&
            "${rootfs_template_post_sha}" != "${rootfs_template_sha}" ]]; then
        rootfs_artifact_rc=1
      fi
    else
      printf '%s\n' "rootfs_template_post_sha256=MISSING"
      rootfs_artifact_rc=1
    fi
    printf 'rootfs_cpio_pre_sha256=%s\n' "${rootfs_cpio_sha:-UNAVAILABLE}"
    if [[ -s "${rootfs_cpio}" ]]; then
      rootfs_cpio_post_sha="$(sha256sum "${rootfs_cpio}" | awk '{print $1}')"
      printf 'rootfs_cpio_post_sha256=%s\n' "${rootfs_cpio_post_sha}"
      if [[ -n "${rootfs_cpio_sha}" &&
            "${rootfs_cpio_post_sha}" != "${rootfs_cpio_sha}" ]]; then
        rootfs_artifact_rc=1
      fi
    else
      printf '%s\n' "rootfs_cpio_post_sha256=MISSING"
      rootfs_artifact_rc=1
    fi
  } >"${result_dir}/rootfs-template-post.txt"
  if [[ "${restore_rc}" -ne 0 ]]; then
    cleanup_rc="${restore_rc}"
  elif [[ "${rootfs_artifact_rc}" -ne 0 ]]; then
    cleanup_rc="${rootfs_artifact_rc}"
  fi
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

task_run_status_stage "rootfs-template-rebuild"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  ubuntu-rootfs-systemd-strict-image \
  >"${result_dir}/rootfs-build.log" 2>&1
test -s "${rootfs_template}"
test -s "${rootfs_cpio}"
rootfs_template_sha="$(sha256sum "${rootfs_template}" | awk '{print $1}')"
rootfs_cpio_sha="$(sha256sum "${rootfs_cpio}" | awk '{print $1}')"
{
  printf '%s\n' "rootfs_rebuild_mode=fresh-current-inputs"
  printf '%s\n' "rootfs_binary_hash_policy=per-run-attestation"
  printf 'rootfs_template_sha256=%s\n' "${rootfs_template_sha}"
  printf 'rootfs_cpio_sha256=%s\n' "${rootfs_cpio_sha}"
  sha256sum \
    "${repo_root}/Linux/Makefile" \
    "${repo_root}/Linux/scripts/build-ubuntu-rootfs.sh" \
    "${repo_root}/Linux/scripts/build-ubuntu-systemd-overlay.sh" \
    "${repo_root}/Linux/scripts/check-ubuntu-rootfs.sh" \
    "${repo_root}/Linux/scripts/npc-systemd-strict-check.sh"
} >"${result_dir}/rootfs-build-binding.txt"

task_run_status_stage "rootfs-static-check"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  check-ubuntu-rootfs-systemd-strict \
  >"${result_dir}/rootfs-check.log" 2>&1

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
  >"${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

task_run_status_stage "evidence-binding-pre"
[[ ! -e "${rootfs_run_image}" ]]
mkdir -p "${rootfs_runtime_dir}"
{
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf '%s\n' "NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict"
  printf '%s\n' "uart_rx_bytes=0"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf 'rootfs_template=%s\n' "${rootfs_template}"
  printf 'rootfs_run_image=%s\n' "${rootfs_run_image}"
  printf 'rootfs_template_sha256_pre=%s\n' "${rootfs_template_sha}"
  printf 'rootfs_cpio_sha256=%s\n' "${rootfs_cpio_sha}"
  sha256sum \
    "${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image" \
    "${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin" \
    "${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb"
} >"${result_dir}/binding.txt"

task_run_status_stage "systemd-strict-guest"
NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL="${progress_interval}" \
NPC_USER_PROGRESS_LIMIT=256 \
NPC_SYSTEMD_HOST_TIMEOUT="${host_timeout_seconds}" \
NPC_SYSTEMD_ROOTFS_WORK_IMAGE="${rootfs_run_image}" \
NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256="${rootfs_template_sha}" \
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  BOOT=ubuntu-rootfs \
  NPC_OOO_CSR_QUEUE_HEAD=1 \
  NPC_OOO_TERMINAL_HOLDER_ASSERT=1 \
  NPC_FAST_SIM=1 \
  VERILATOR='verilator -Wno-fatal' \
  NPC_SYSTEMD_CHECK_LOG_DIR="${result_dir}/guest" \
  NPC_SYSTEMD_PROGRESS="${progress_interval}" \
  check-npc-systemd-guest-systemd-strict \
  >"${result_dir}/driver.log" 2>&1

task_run_status_stage "strict-marker-check"
grep -F "[npc-systemd-check] PASS strict guest + natural poweroff (mode=systemd-strict)" \
  "${result_dir}/driver.log"
grep -F "loaded bytes=0 file_bytes=0 text_bytes=0" \
  "${result_dir}/guest/console.log"
if grep -aEq 'uart-rx\][[:space:]]+pop=' "${result_dir}/guest/console.log"; then
  printf '%s\n' "[V9S-ROOTFS-CSR-QH-SYSTEMD-STRICT] unexpected UART RX byte" >&2
  exit 1
fi
grep -F "rootfs_template_sha256_pre=${rootfs_template_sha}" \
  "${result_dir}/guest/rootfs-binding.txt"
grep -F "rootfs_run_image_sha256_pre=${rootfs_template_sha}" \
  "${result_dir}/guest/rootfs-binding.txt"

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

{
  sha256sum "${rootfs_template}" "${rootfs_run_image}"
} >"${result_dir}/rootfs-post-binding.txt"

printf '%s\n' \
  "[V9S-ROOTFS-CSR-QH-SYSTEMD-STRICT] current design strict rootfs + natural poweroff PASS"
task_run_status_stage "evidence-verified"
task_run_status_mark_evidence_complete
