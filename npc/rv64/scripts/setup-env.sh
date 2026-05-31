#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
PY_VENV=${NPC_RV64_PYTHON_VENV:-"$ENV_ROOT/tools/python"}
INSTALL_HOST_PACKAGES=${NPC_RV64_INSTALL_HOST_PACKAGES:-0}

mkdir -p \
  "$ENV_ROOT/src" \
  "$ENV_ROOT/build" \
  "$ENV_ROOT/downloads" \
  "$ENV_ROOT/images/initramfs" \
  "$ENV_ROOT/images/ubuntu2204" \
  "$ENV_ROOT/logs" \
  "$ENV_ROOT/tools" \
  "$ENV_ROOT/tmp"

PACKAGES=(
  build-essential git make cmake ninja-build curl wget ca-certificates
  device-tree-compiler u-boot-tools flex bison libssl-dev libelf-dev bc
  cpio rsync file python3 python3-pip python3-venv
  verilator gdb-multiarch
  gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
  gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf
  debootstrap qemu-user-static e2fsprogs
)

HOST_COMMANDS=(
  git make curl wget tar cpio file python3
  dtc fdtget verilator
  riscv64-linux-gnu-gcc riscv64-linux-gnu-objcopy
)

if [ "$INSTALL_HOST_PACKAGES" = "1" ]; then
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "[setup-env] 当前脚本只支持 Debian/Ubuntu 系宿主安装 apt 依赖。" >&2
    exit 1
  fi
  SUDO=()
  if [ "$(id -u)" -ne 0 ]; then
    SUDO=(sudo)
  fi
  echo "[setup-env] 安装宿主基础依赖；外部源码、下载包和镜像仍放在 $ENV_ROOT"
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y "${PACKAGES[@]}"
else
  missing=()
  for cmd in "${HOST_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [ "${#missing[@]}" -ne 0 ]; then
    echo "[setup-env] 缺少宿主基础命令：${missing[*]}" >&2
    echo "[setup-env] 如需自动安装 apt 依赖，请显式执行：NPC_RV64_INSTALL_HOST_PACKAGES=1 $0" >&2
    exit 1
  fi
fi

if [ ! -x "$PY_VENV/bin/python3" ]; then
  python3 -m venv "$PY_VENV"
fi

PIP_CACHE_DIR="$ENV_ROOT/downloads/pip-cache" "$PY_VENV/bin/python3" -m pip install --upgrade pip
PIP_CACHE_DIR="$ENV_ROOT/downloads/pip-cache" "$PY_VENV/bin/python3" -m pip install pyyaml

if ! "$PY_VENV/bin/python3" - <<'PY' >/dev/null 2>&1
import yaml
PY
then
  echo "[setup-env] 本地 Python venv 中 PyYAML 校验失败：$PY_VENV" >&2
  exit 1
fi

echo "[setup-env] 环境根目录：$ENV_ROOT"
echo "[setup-env] 本地 Python：$PY_VENV/bin/python3"
echo "[setup-env] 下一步可执行：make -C npc/rv64 initramfs linux opensbi ubuntu-base-initramfs"
