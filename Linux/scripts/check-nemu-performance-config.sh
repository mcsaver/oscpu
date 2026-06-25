#!/usr/bin/env bash
set -euo pipefail

require_perf="${NEMU_PERFORMANCE_REQUIRED:-1}"
config_path="${NEMU_CONFIG:-}"
autoconf_path="${NEMU_AUTOCONF:-}"

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
require_config_enabled CONFIG_INTERPRETER_DECODE_CACHE
require_autoconf_define CONFIG_INTERPRETER_DECODE_CACHE
require_config_enabled CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH
require_autoconf_define CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH
require_config_value CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES 32768
require_autoconf_value CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES 32768
require_config_enabled CONFIG_INTERPRETER_INTR_FAST_FLAG
require_autoconf_define CONFIG_INTERPRETER_INTR_FAST_FLAG
require_config_value CONFIG_DEVICE_UPDATE_CHECK_INTERVAL 512
require_autoconf_value CONFIG_DEVICE_UPDATE_CHECK_INTERVAL 512
require_config_value CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL 4
require_autoconf_value CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL 4
require_config_enabled CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
require_autoconf_define CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG
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

for opt in "${debug_opts[@]}"; do
  reject_config_enabled "$opt"
  reject_autoconf_define "$opt"
done

echo "__NEMU_PERFORMANCE_CONFIG__:ok"
