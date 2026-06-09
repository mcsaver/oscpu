#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
DEFAULT_KERNEL_CONFIG="$ENV_ROOT/src/linux/.config"
config_path=${LINUX_KERNEL_CONFIG:-${LINUX_CONFIG:-$DEFAULT_KERNEL_CONFIG}}

if [[ -z "$config_path" || ! -f "$config_path" ]]; then
  echo "missing Linux kernel .config: ${config_path:-<unset>}" >&2
  exit 1
fi

require_config_enabled() {
  local opt="$1"
  if ! grep -qx "${opt}=y" "$config_path"; then
    echo "required ${opt}=y in $config_path" >&2
    exit 1
  fi
  echo "[linux-kernel-config] PASS ${opt}=y"
}

require_config_disabled() {
  local opt="$1"
  if grep -qx "${opt}=y" "$config_path"; then
    echo "required ${opt} disabled in $config_path" >&2
    exit 1
  fi
  echo "[linux-kernel-config] PASS ${opt}=disabled"
}

# 这些能力直接对应 Ubuntu/systemd 启动日志里已修过的噪声：
# autofs 必须内建，否则无模块内核会在查 autofs4 alias 时返回 ENOSYS；
# cgroup-BPF/BPF syscall 用来让 systemd 的 IPAddressDeny/Allow 探测不再报缺失。
require_config_disabled CONFIG_MODULES
require_config_enabled CONFIG_AUTOFS_FS
require_config_enabled CONFIG_BPF
require_config_enabled CONFIG_BPF_SYSCALL
require_config_enabled CONFIG_CGROUPS
require_config_enabled CONFIG_CGROUP_BPF
require_config_enabled CONFIG_SECCOMP
require_config_enabled CONFIG_SECCOMP_FILTER

echo "__NEMU_KERNEL_CONFIG__:ok"
