#!/usr/bin/env bash
set -euo pipefail

require_perf="${NEMU_PERFORMANCE_REQUIRED:-1}"
config_path="${NEMU_CONFIG:-}"
autoconf_path="${NEMU_AUTOCONF:-}"
policy_header_path="${NEMU_POLICY_HEADER:-}"
device_address_path="${NEMU_DEVICE_ADDRESS_HEADER:-}"

if [[ -z "$policy_header_path" ]]; then
  policy_header_path="$(dirname "$config_path")/include/nemu-config.h"
fi
if [[ ! -f "$policy_header_path" ]]; then
  echo "missing NEMU fixed-policy header: $policy_header_path" >&2
  exit 1
fi

if [[ -z "$device_address_path" ]]; then
  device_address_path="$(dirname "$config_path")/include/device/device_address.h"
fi
if [[ ! -f "$device_address_path" ]]; then
  echo "missing NEMU device-address header: $device_address_path" >&2
  exit 1
fi

require_header_value() {
  local header="$1"
  local opt="$2"
  local value="$3"
  local pattern="^[[:space:]]*#[[:space:]]*define[[:space:]]+${opt}[[:space:]]+${value}([[:space:]]|$)"
  if ! grep -Eq "$pattern" "$header"; then
    echo "required #define ${opt} ${value} in $header" >&2
    exit 1
  fi
}

# 这些是已从 Kconfig 退出的 NEMU 固定策略/平台 ABI，即使使用
# Linux debug defconfig 放开性能守门，也不应该跳过它们。
require_header_value "$policy_header_path" NEMU_ENGINE_NAME '"interpreter"'
require_header_value "$policy_header_path" NEMU_SYSTEM_MODE 1
require_header_value "$policy_header_path" NEMU_RV64_DECODE_CACHE 1
require_header_value "$policy_header_path" NEMU_RV64_DECODE_CACHE_ENTRIES 32768
require_header_value "$device_address_path" DEV_SERIAL_MMIO 0x10000000
require_header_value "$device_address_path" DEV_DISK_MMIO 0x10001000
require_header_value "$device_address_path" DEV_VIRTIO_RNG_MMIO 0x10002000
require_header_value "$device_address_path" DEV_GOLDFISH_RTC_MMIO 0x10003000
require_header_value "$device_address_path" DEV_VIRTIO_NET_MMIO 0x10004000
require_header_value "$device_address_path" DEV_SYSCON_RESET_MMIO 0x00100000
echo "__NEMU_FIXED_POLICY__:ok"

if [[ "$require_perf" != "1" ]]; then
  echo "__NEMU_PERFORMANCE_CONFIG__:skipped"
  exit 0
fi

if [[ -z "$config_path" || ! -f "$config_path" ]]; then
  echo "missing NEMU .config: ${config_path:-<unset>}" >&2
  exit 1
fi

if [[ -z "$autoconf_path" || ! -f "$autoconf_path" ]]; then
  echo "missing NEMU autoconf.h: ${autoconf_path:-<unset>}" >&2
  exit 1
fi

require_config_enabled() {
  local opt="$1"
  if ! grep -qx "${opt}=y" "$config_path"; then
    echo "required ${opt}=y in $config_path" >&2
    exit 1
  fi
}

reject_config_enabled() {
  local opt="$1"
  if grep -qx "${opt}=y" "$config_path"; then
    echo "performance gate rejects ${opt}=y in $config_path" >&2
    exit 1
  fi
}

require_autoconf_define() {
  local opt="$1"
  if ! grep -qx "#define ${opt} 1" "$autoconf_path"; then
    echo "required #define ${opt} 1 in $autoconf_path" >&2
    exit 1
  fi
}

require_config_value() {
  local opt="$1"
  local value="$2"
  if ! grep -qx "${opt}=${value}" "$config_path"; then
    echo "required ${opt}=${value} in $config_path" >&2
    exit 1
  fi
}

require_autoconf_value() {
  local opt="$1"
  local value="$2"
  if ! grep -qx "#define ${opt} ${value}" "$autoconf_path"; then
    echo "required #define ${opt} ${value} in $autoconf_path" >&2
    exit 1
  fi
}

reject_autoconf_define() {
  local opt="$1"
  if grep -qx "#define ${opt} 1" "$autoconf_path"; then
    echo "performance gate rejects #define ${opt} 1 in $autoconf_path" >&2
    exit 1
  fi
}

require_config_enabled CONFIG_PERFORMANCE
require_autoconf_define CONFIG_PERFORMANCE
require_config_enabled CONFIG_RISCV_CLINT_HOST_TIME
require_autoconf_define CONFIG_RISCV_CLINT_HOST_TIME
require_config_enabled CONFIG_INTERPRETER_BASIC_BLOCK
require_autoconf_define CONFIG_INTERPRETER_BASIC_BLOCK
require_config_value CONFIG_INTERPRETER_TB_MAX_INST 256
require_autoconf_value CONFIG_INTERPRETER_TB_MAX_INST 256
require_config_enabled CONFIG_INTERPRETER_WIDE_IFETCH
require_autoconf_define CONFIG_INTERPRETER_WIDE_IFETCH
require_config_enabled CONFIG_INTERPRETER_IFETCH_PAGE_CACHE
require_autoconf_define CONFIG_INTERPRETER_IFETCH_PAGE_CACHE
require_config_enabled CONFIG_INTERPRETER_INTR_FAST_FLAG
require_autoconf_define CONFIG_INTERPRETER_INTR_FAST_FLAG
require_config_value CONFIG_DEVICE_UPDATE_CHECK_INTERVAL 512
require_autoconf_value CONFIG_DEVICE_UPDATE_CHECK_INTERVAL 512
require_config_enabled CONFIG_HAS_SERIAL
require_autoconf_define CONFIG_HAS_SERIAL
require_config_value CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL 4
require_autoconf_value CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL 4
require_config_enabled CONFIG_HAS_DISK
require_autoconf_define CONFIG_HAS_DISK
require_config_enabled CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
require_autoconf_define CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
require_config_enabled CONFIG_HAS_VIRTIO_RNG
require_autoconf_define CONFIG_HAS_VIRTIO_RNG
require_config_enabled CONFIG_HAS_GOLDFISH_RTC
require_autoconf_define CONFIG_HAS_GOLDFISH_RTC
require_config_enabled CONFIG_HAS_VIRTIO_NET
require_autoconf_define CONFIG_HAS_VIRTIO_NET
require_config_enabled CONFIG_HAS_SYSCON_RESET
require_autoconf_define CONFIG_HAS_SYSCON_RESET
require_config_value CONFIG_MSIZE 0x40000000
require_autoconf_value CONFIG_MSIZE 0x40000000

debug_opts=(
  CONFIG_TRACE
  CONFIG_MTRACE
  CONFIG_ITRACE
  CONFIG_DTRACE
  CONFIG_ETRACE
  CONFIG_FTRACE
  CONFIG_DIFFTEST
  CONFIG_WATCHPOINT
  CONFIG_BPU
  CONFIG_STATISTIC
  CONFIG_CACHE_STATISTIC
  CONFIG_RT_CHECK
  CONFIG_CC_ASAN
  CONFIG_MEM_RANDOM
  CONFIG_RISCV_DEBUG_LOG
  CONFIG_RISCV_PROGRESS_DEBUG_LOG
  CONFIG_RISCV_IRQ_DEBUG_LOG
  CONFIG_RISCV_SYSCALL_DEBUG_LOG
)

legacy_device_opts=(
  CONFIG_DEVICE_MAP_LEGACY
  CONFIG_HAS_TIMER
  CONFIG_HAS_KEYBOARD
  CONFIG_HAS_VGA
  CONFIG_HAS_AUDIO
)

for opt in "${debug_opts[@]}"; do
  reject_config_enabled "$opt"
  reject_autoconf_define "$opt"
done

for opt in "${legacy_device_opts[@]}"; do
  reject_config_enabled "$opt"
  reject_autoconf_define "$opt"
done

echo "__NEMU_PERFORMANCE_CONFIG__:ok"
