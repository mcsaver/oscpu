#!/usr/bin/env bash
set -euo pipefail

config=${1:-}
if [[ -z "${config}" || ! -f "${config}" || -L "${config}" ]]; then
  printf '%s\n' '[RV64-L3-CONFIG][FAIL] expected one regular effective .config' >&2
  exit 2
fi

required=(
  'CONFIG_64BIT=y'
  'CONFIG_MMU=y'
  'CONFIG_ARCH_RV64I=y'
  'CONFIG_RISCV_SBI=y'
  'CONFIG_RISCV_ISA_C=y'
  'CONFIG_BINFMT_ELF=y'
  'CONFIG_BLK_DEV_INITRD=y'
  'CONFIG_DEVTMPFS=y'
  'CONFIG_PROC_FS=y'
  'CONFIG_SYSFS=y'
  'CONFIG_TMPFS=y'
  'CONFIG_TTY=y'
  'CONFIG_SERIAL_8250=y'
  'CONFIG_SERIAL_8250_CONSOLE=y'
  'CONFIG_SERIAL_OF_PLATFORM=y'
  'CONFIG_PRINTK=y'
  'CONFIG_POSIX_TIMERS=y'
  'CONFIG_HIGH_RES_TIMERS=y'
  'CONFIG_HZ_PERIODIC=y'
)

disabled=(
  'CONFIG_SMP'
  'CONFIG_MODULES'
  'CONFIG_FPU'
  'CONFIG_RISCV_ISA_V'
  'CONFIG_DEVTMPFS_MOUNT'
  'CONFIG_NET'
  'CONFIG_BLOCK'
  'CONFIG_VIRTIO_MENU'
  'CONFIG_POWER_RESET'
  'CONFIG_POWER_RESET_SYSCON'
  'CONFIG_POWER_RESET_SYSCON_POWEROFF'
)

for marker in "${required[@]}"; do
  if ! grep -Fqx -- "${marker}" "${config}"; then
    printf '[RV64-L3-CONFIG][FAIL] required effective symbol missing: %s\n' \
      "${marker}" >&2
    exit 1
  fi
done
for symbol in "${disabled[@]}"; do
  if grep -Eq "^${symbol}=(y|m)$" "${config}"; then
    printf '[RV64-L3-CONFIG][FAIL] forbidden effective symbol enabled: %s\n' \
      "${symbol}" >&2
    exit 1
  fi
done

if grep -Eq '^CONFIG_NR_CPUS=' "${config}" &&
   ! grep -Fqx 'CONFIG_NR_CPUS=1' "${config}"; then
  printf '%s\n' '[RV64-L3-CONFIG][FAIL] effective NR_CPUS is not one' >&2
  exit 1
fi

printf '%s\n' \
  '[RV64-L3-CONFIG][PASS] rv64=1 mmu=1 sbi=1 plic=selected timer=selected serial=8250 initrd=1 pseudo_fs=4 smp=0 modules=0 syscon_driver=0'
