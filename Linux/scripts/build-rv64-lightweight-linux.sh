#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
linux_home=$(cd -- "${script_dir}/.." && pwd)
repo_root=$(cd -- "${linux_home}/.." && pwd)
linux_root=${LINUX_ROOT:-"${linux_home}/env/src/linux"}
opensbi_root=${OPENSBI_ROOT:-"${linux_home}/env/src/opensbi"}
cross_compile=${CROSS_COMPILE:-riscv64-linux-gnu-}
jobs=${JOBS:-2}
output_dir=
work_dir=

usage() {
  cat <<'EOF'
usage: Linux/scripts/build-rv64-lightweight-linux.sh \
  --output-dir PATH --work-dir PATH [--jobs N]

Builds one minimal Linux 6.6 Image, libc-free PID1/initramfs, one effective
DTB shared by OpenSBI and Linux, and fw_jump.  Both directories must be new.
The caller owns cleanup and promotion of the final artifact set.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      output_dir=${2:?--output-dir requires a path}
      shift 2
      ;;
    --work-dir)
      work_dir=${2:?--work-dir requires a path}
      shift 2
      ;;
    --jobs)
      jobs=${2:?--jobs requires a value}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[RV64-L3-BUILD][FAIL] unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "${output_dir}" && -n "${work_dir}" ]]
[[ "${jobs}" =~ ^[0-9]+$ ]] && (( jobs > 0 && jobs <= 64 ))
for command_name in cmp cpio dtc find git grep make readelf sha256sum sort xargs; do
  command -v "${command_name}" >/dev/null
done
for command_name in \
  "${cross_compile}gcc" "${cross_compile}objdump" "${cross_compile}readelf"; do
  command -v "${command_name}" >/dev/null
done
for input in \
  "${linux_root}/Makefile" \
  "${linux_root}/tools/include/nolibc/nolibc.h" \
  "${opensbi_root}/Makefile" \
  "${linux_home}/lightweight/rv64-l3-kernel.config" \
  "${linux_home}/lightweight/rv64-l3-init.c" \
  "${linux_home}/platform/common-rv64.yml" \
  "${linux_home}/platform/npc-rv64.yml" \
  "${linux_home}/platform/gen_dts.py" \
  "${script_dir}/check-rv64-lightweight-linux-config.sh"; do
  [[ -f "${input}" && ! -L "${input}" ]]
done
[[ ! -e "${output_dir}" && ! -L "${output_dir}" ]]
[[ ! -e "${work_dir}" && ! -L "${work_dir}" ]]
mkdir -p -- "${output_dir}" "${work_dir}"
output_dir=$(realpath -- "${output_dir}")
work_dir=$(realpath -- "${work_dir}")

kernel_build="${work_dir}/linux-build"
uapi_output="${work_dir}/linux-uapi"
opensbi_build="${work_dir}/opensbi-build"
initramfs_root="${work_dir}/initramfs-root"
effective_dts="${work_dir}/rv64-l3-effective.dts"

mkdir -p -- "${kernel_build}" "${uapi_output}"
make -s -C "${linux_root}" O="${kernel_build}" ARCH=riscv \
  CROSS_COMPILE="${cross_compile}" headers_install \
  INSTALL_HDR_PATH="${uapi_output}"
test -s "${uapi_output}/include/asm/unistd.h"

"${cross_compile}gcc" \
  -Os -std=gnu11 -Wall -Wextra -Werror \
  -fno-ident -fno-builtin -fno-pic -fno-pie -fno-stack-protector \
  -fno-asynchronous-unwind-tables -fno-unwind-tables \
  -march=rv64imac_zicsr_zifencei -mabi=lp64 \
  -nostdlib -nostartfiles -static -no-pie \
  -Wl,--build-id=none \
  -I"${uapi_output}/include" \
  -I"${linux_root}/tools/include/nolibc" \
  -include "${linux_root}/tools/include/nolibc/nolibc.h" \
  "${linux_home}/lightweight/rv64-l3-init.c" -lgcc \
  -o "${output_dir}/init"

"${cross_compile}readelf" -hW "${output_dir}/init" \
  >"${output_dir}/init-readelf-header.txt"
"${cross_compile}readelf" -lW "${output_dir}/init" \
  >"${output_dir}/init-readelf-program.txt"
"${cross_compile}readelf" -dW "${output_dir}/init" \
  >"${output_dir}/init-readelf-dynamic.txt"
"${cross_compile}objdump" -dr "${output_dir}/init" \
  >"${output_dir}/init-objdump.txt"
grep -Eq 'Type:[[:space:]]+EXEC' "${output_dir}/init-readelf-header.txt"
if grep -Fq 'INTERP' "${output_dir}/init-readelf-program.txt"; then
  printf '%s\n' '[RV64-L3-BUILD][FAIL] PID1 contains PT_INTERP' >&2
  exit 1
fi
grep -Fq 'There is no dynamic section' "${output_dir}/init-readelf-dynamic.txt"
grep -Eq '[[:space:]]amoadd\.d[[:space:]]' "${output_dir}/init-objdump.txt"
grep -Eq '[[:space:]]lr\.d[[:space:]]' "${output_dir}/init-objdump.txt"
grep -Eq '[[:space:]]sc\.d[[:space:]]' "${output_dir}/init-objdump.txt"

mkdir -p -- \
  "${initramfs_root}/dev" "${initramfs_root}/proc" \
  "${initramfs_root}/sys" "${initramfs_root}/tmp"
cp -- "${output_dir}/init" "${initramfs_root}/init"
chmod 0755 "${initramfs_root}/init"
find "${initramfs_root}" -exec touch -h -d '@0' -- {} +
(
  cd "${initramfs_root}"
  LC_ALL=C find . -print0 | LC_ALL=C sort -z | \
    cpio --null --create --format=newc --owner=0:0 --reproducible \
      >"${output_dir}/initramfs.cpio"
)

KCONFIG_ALLCONFIG="${linux_home}/lightweight/rv64-l3-kernel.config" \
  make -s -C "${linux_root}" O="${kernel_build}" ARCH=riscv \
    CROSS_COMPILE="${cross_compile}" allnoconfig
make -s -C "${linux_root}" O="${kernel_build}" ARCH=riscv \
  CROSS_COMPILE="${cross_compile}" olddefconfig
bash "${script_dir}/check-rv64-lightweight-linux-config.sh" \
  "${kernel_build}/.config"
make -s -C "${linux_root}" O="${kernel_build}" ARCH=riscv \
  CROSS_COMPILE="${cross_compile}" -j"${jobs}" Image
cp -- "${kernel_build}/arch/riscv/boot/Image" "${output_dir}/Image"
cp -- "${kernel_build}/.config" "${output_dir}/linux.config"

python3 -B "${linux_home}/platform/gen_dts.py" \
  --config "${linux_home}/platform/npc-rv64.yml" \
  --mode initramfs --reset-syscon \
  --initrd-image "${output_dir}/initramfs.cpio" \
  --memory-size 0x08000000 \
  --bootargs-override \
    'console=ttyS0,115200n8 earlycon=sbi loglevel=6 rdinit=/init panic=-1' \
  --output "${effective_dts}"
dtc -q -I dts -O dtb -o "${output_dir}/guest.dtb" "${effective_dts}"
cp -- "${output_dir}/guest.dtb" "${output_dir}/opensbi-platform.dtb"
cp -- "${effective_dts}" "${output_dir}/guest.dts"
cp -- "${effective_dts}" "${output_dir}/opensbi-platform.dts"
cmp -s "${output_dir}/guest.dtb" "${output_dir}/opensbi-platform.dtb"
grep -Fq 'rdinit=/init' "${effective_dts}"
grep -Fq 'linux,initrd-start' "${effective_dts}"
grep -Fq 'linux,initrd-end' "${effective_dts}"
[[ $(grep -Fc 'compatible = "syscon-poweroff"' "${effective_dts}") -eq 1 ]]

make -s -C "${opensbi_root}" O="${opensbi_build}" PLATFORM=generic \
  CROSS_COMPILE="${cross_compile}" \
  FW_FDT_PATH="${output_dir}/opensbi-platform.dtb" \
  FW_JUMP_ADDR=0x80400000 FW_JUMP_FDT_ADDR=0x82300000 \
  -j"${jobs}"
cp -- "${opensbi_build}/platform/generic/firmware/fw_jump.bin" \
  "${output_dir}/fw_jump.bin"

linux_version=$(make -s -C "${linux_root}" kernelversion)
linux_tree_stat_sha=$(find "${linux_root}" -type f \
  -printf '%P\t%s\t%T@\n' | LC_ALL=C sort | sha256sum | awk '{print $1}')
linux_tree_content_sha=$(find "${linux_root}" -type f -print0 | \
  LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')
opensbi_commit=$(git -C "${opensbi_root}" rev-parse HEAD 2>/dev/null || printf unknown)
opensbi_diff_sha=$(git -C "${opensbi_root}" diff --no-ext-diff --binary HEAD | sha256sum | awk '{print $1}')
{
  printf '%s\n' 'schema=npc-rv64-l3-lightweight-linux-artifact-binding-v1'
  printf 'linux_version=%s\n' "${linux_version}"
  printf 'linux_tree_stat_sha256=%s\n' "${linux_tree_stat_sha}"
  printf 'linux_tree_content_sha256=%s\n' "${linux_tree_content_sha}"
  printf 'opensbi_commit=%s\n' "${opensbi_commit}"
  printf 'opensbi_diff_sha256=%s\n' "${opensbi_diff_sha}"
  printf 'cross_gcc_sha256=%s\n' "$(sha256sum "$(command -v "${cross_compile}gcc")" | awk '{print $1}')"
  printf 'kernel_input_config_sha256=%s\n' "$(sha256sum "${linux_home}/lightweight/rv64-l3-kernel.config" | awk '{print $1}')"
  printf 'pid1_build_script_sha256=%s\n' "$(sha256sum "${linux_home}/scripts/build-rv64-lightweight-linux.sh" | awk '{print $1}')"
  printf 'config_checker_sha256=%s\n' "$(sha256sum "${linux_home}/scripts/check-rv64-lightweight-linux-config.sh" | awk '{print $1}')"
  printf 'gen_dts_sha256=%s\n' "$(sha256sum "${linux_home}/platform/gen_dts.py" | awk '{print $1}')"
  printf 'common_platform_sha256=%s\n' "$(sha256sum "${linux_home}/platform/common-rv64.yml" | awk '{print $1}')"
  printf 'npc_platform_sha256=%s\n' "$(sha256sum "${linux_home}/platform/npc-rv64.yml" | awk '{print $1}')"
  printf 'kernel_effective_config_sha256=%s\n' "$(sha256sum "${output_dir}/linux.config" | awk '{print $1}')"
  printf 'pid1_source_sha256=%s\n' "$(sha256sum "${linux_home}/lightweight/rv64-l3-init.c" | awk '{print $1}')"
  printf 'pid1_sha256=%s\n' "$(sha256sum "${output_dir}/init" | awk '{print $1}')"
  printf 'initramfs_sha256=%s\n' "$(sha256sum "${output_dir}/initramfs.cpio" | awk '{print $1}')"
  printf 'linux_image_sha256=%s\n' "$(sha256sum "${output_dir}/Image" | awk '{print $1}')"
  printf 'guest_dtb_sha256=%s\n' "$(sha256sum "${output_dir}/guest.dtb" | awk '{print $1}')"
  printf 'opensbi_platform_dtb_sha256=%s\n' "$(sha256sum "${output_dir}/opensbi-platform.dtb" | awk '{print $1}')"
  printf 'effective_dtb_sha256=%s\n' "$(sha256sum "${output_dir}/guest.dtb" | awk '{print $1}')"
  printf 'opensbi_fw_sha256=%s\n' "$(sha256sum "${output_dir}/fw_jump.bin" | awk '{print $1}')"
  printf '%s\n' 'linux_load_addr=0x80400000'
  printf '%s\n' 'linux_guest_dtb_addr=0x82300000'
  printf '%s\n' 'initramfs_addr=0x84000000'
  printf '%s\n' 'memory_size=0x08000000'
  printf '%s\n' 'effective_dtb_shared=1'
  printf '%s\n' 'effective_dtb_rdinit=1'
  printf '%s\n' 'effective_dtb_initrd=1'
  printf '%s\n' 'linux_syscon_poweroff_driver=0'
  printf '%s\n' 'linux_guest_dtb_syscon=1'
  printf '%s\n' 'opensbi_platform_dtb_syscon=1'
  printf '%s\n' 'opensbi_fw_jump_fdt_addr=0x82300000'
} >"${output_dir}/artifact-binding.txt"

printf '[RV64-L3-BUILD][PASS] output=%s image_bytes=%s initramfs_bytes=%s\n' \
  "${output_dir}" "$(stat -c '%s' "${output_dir}/Image")" \
  "$(stat -c '%s' "${output_dir}/initramfs.cpio")"
