#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
linux_home=$(cd -- "${script_dir}/.." && pwd)
opensbi_root=${OPENSBI_ROOT:-"${linux_home}/env/src/opensbi"}
cross_compile=${CROSS_COMPILE:-riscv64-linux-gnu-}
jobs=${JOBS:-4}
output_dir=
work_dir=

usage() {
  cat <<'EOF'
usage: Linux/scripts/build-rv64-mini-system.sh \
  --output-dir PATH --work-dir PATH [--jobs N]

Builds the local RV64 L2 OpenSBI + S/U mini-system payload, effective DTB and
fw_jump artifact set. Both output and work directories must be new.
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
      printf '[RV64-L2-BUILD][FAIL] unknown option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

[[ -n "${output_dir}" && -n "${work_dir}" ]]
[[ "${jobs}" =~ ^[0-9]+$ ]] && (( jobs > 0 && jobs <= 64 ))
for command_name in awk cp dtc git grep make python3 realpath sha256sum stat; do
  command -v "${command_name}" >/dev/null
done
for command_name in "${cross_compile}gcc" "${cross_compile}objcopy" \
  "${cross_compile}objdump" "${cross_compile}readelf"; do
  command -v "${command_name}" >/dev/null
done
for input in \
  "${opensbi_root}/Makefile" \
  "${linux_home}/mini-system/rv64-l2-payload.S" \
  "${linux_home}/mini-system/rv64-l2-payload.ld" \
  "${linux_home}/platform/common-rv64.yml" \
  "${linux_home}/platform/npc-rv64.yml" \
  "${linux_home}/platform/gen_dts.py"; do
  [[ -f "${input}" && ! -L "${input}" ]]
done
[[ ! -e "${output_dir}" && ! -L "${output_dir}" ]]
[[ ! -e "${work_dir}" && ! -L "${work_dir}" ]]
mkdir -p -- "${output_dir}" "${work_dir}"
output_dir=$(realpath -- "${output_dir}")
work_dir=$(realpath -- "${work_dir}")

effective_dts=${work_dir}/rv64-l2-effective.dts
opensbi_build=${work_dir}/opensbi-build

python3 -B "${linux_home}/platform/gen_dts.py" \
  --config "${linux_home}/platform/npc-rv64.yml" \
  --mode kernel --reset-syscon --memory-size 0x08000000 \
  --bootargs-override 'console=ttyS0,115200n8' \
  --output "${effective_dts}"
dtc -q -I dts -O dtb -o "${output_dir}/mini-system.dtb" "${effective_dts}"
cp -- "${effective_dts}" "${output_dir}/mini-system.dts"
[[ $(grep -Fc 'compatible = "syscon-poweroff"' "${effective_dts}") -eq 1 ]]
grep -Fq 'serial@10000000' "${effective_dts}"
grep -Fq 'interrupt-controller@c000000' "${effective_dts}"

"${cross_compile}gcc" -x assembler-with-cpp -nostdlib -nostartfiles \
  -march=rv64ima_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
  -static -no-pie -Wl,--no-relax -Wl,--build-id=none \
  -Wl,-T,"${linux_home}/mini-system/rv64-l2-payload.ld" \
  "${linux_home}/mini-system/rv64-l2-payload.S" \
  -o "${output_dir}/mini-system.elf"
"${cross_compile}objcopy" -O binary "${output_dir}/mini-system.elf" \
  "${output_dir}/mini-system.bin"
"${cross_compile}readelf" -hW "${output_dir}/mini-system.elf" \
  >"${output_dir}/mini-system-readelf.txt"
"${cross_compile}objdump" -dr "${output_dir}/mini-system.elf" \
  >"${output_dir}/mini-system-objdump.txt"
grep -Eq 'Entry point address:[[:space:]]+0x80400000' \
  "${output_dir}/mini-system-readelf.txt"
grep -Eq '[[:space:]]amoadd\.d[[:space:]]' "${output_dir}/mini-system-objdump.txt"
grep -Eq '[[:space:]]lr\.d[[:space:]]' "${output_dir}/mini-system-objdump.txt"
grep -Eq '[[:space:]]sc\.d[[:space:]]' "${output_dir}/mini-system-objdump.txt"
grep -Eq '[[:space:]]sfence\.vma[[:space:]]' "${output_dir}/mini-system-objdump.txt"
grep -Eq '[[:space:]]fence[[:space:]]' "${output_dir}/mini-system-objdump.txt"

make -s -C "${opensbi_root}" O="${opensbi_build}" PLATFORM=generic \
  CROSS_COMPILE="${cross_compile}" \
  FW_FDT_PATH="${output_dir}/mini-system.dtb" \
  FW_JUMP_ADDR=0x80400000 FW_JUMP_FDT_ADDR=0x82300000 \
  -j"${jobs}"
cp -- "${opensbi_build}/platform/generic/firmware/fw_jump.bin" \
  "${output_dir}/fw_jump.bin"

opensbi_commit=$(git -C "${opensbi_root}" rev-parse HEAD 2>/dev/null || printf unknown)
opensbi_diff_sha=$(git -C "${opensbi_root}" diff --no-ext-diff --binary HEAD | \
  sha256sum | awk '{print $1}')
{
  printf '%s\n' 'schema=npc-rv64-l2-mini-system-artifact-binding-v1'
  printf 'opensbi_commit=%s\n' "${opensbi_commit}"
  printf 'opensbi_diff_sha256=%s\n' "${opensbi_diff_sha}"
  printf 'cross_gcc_sha256=%s\n' "$(sha256sum "$(command -v "${cross_compile}gcc")" | awk '{print $1}')"
  printf 'build_script_sha256=%s\n' "$(sha256sum "${linux_home}/scripts/build-rv64-mini-system.sh" | awk '{print $1}')"
  printf 'payload_source_sha256=%s\n' "$(sha256sum "${linux_home}/mini-system/rv64-l2-payload.S" | awk '{print $1}')"
  printf 'linker_script_sha256=%s\n' "$(sha256sum "${linux_home}/mini-system/rv64-l2-payload.ld" | awk '{print $1}')"
  printf 'gen_dts_sha256=%s\n' "$(sha256sum "${linux_home}/platform/gen_dts.py" | awk '{print $1}')"
  printf 'common_platform_sha256=%s\n' "$(sha256sum "${linux_home}/platform/common-rv64.yml" | awk '{print $1}')"
  printf 'npc_platform_sha256=%s\n' "$(sha256sum "${linux_home}/platform/npc-rv64.yml" | awk '{print $1}')"
  printf 'payload_elf_sha256=%s\n' "$(sha256sum "${output_dir}/mini-system.elf" | awk '{print $1}')"
  printf 'payload_bin_sha256=%s\n' "$(sha256sum "${output_dir}/mini-system.bin" | awk '{print $1}')"
  printf 'effective_dtb_sha256=%s\n' "$(sha256sum "${output_dir}/mini-system.dtb" | awk '{print $1}')"
  printf 'opensbi_fw_sha256=%s\n' "$(sha256sum "${output_dir}/fw_jump.bin" | awk '{print $1}')"
  printf '%s\n' 'payload_load_addr=0x80400000'
  printf '%s\n' 'effective_dtb_addr=0x82300000'
  printf '%s\n' 'opensbi_fw_jump_fdt_addr=0x82300000'
  printf '%s\n' 'effective_dtb_syscon=1'
  printf '%s\n' 'case_set=privilege,sv39,timer,interrupt,atomic-mmio,shutdown,all'
} >"${output_dir}/artifact-binding.txt"

printf '[RV64-L2-BUILD][PASS] output=%s payload_bytes=%s fw_bytes=%s\n' \
  "${output_dir}" "$(stat -c '%s' "${output_dir}/mini-system.bin")" \
  "$(stat -c '%s' "${output_dir}/fw_jump.bin")"
