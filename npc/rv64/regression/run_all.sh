#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
JOBS=${JOBS:-$(nproc)}

echo "[L0] build rv64 linux profile"
make -C "$RV64_DIR" rv64_linux_defconfig
make -C "$RV64_DIR" -j"$JOBS"

echo "[L1] DTB smoke"
make -C "$RV64_DIR/tools" smoke-dtb

echo "[L2] OpenSBI mini smoke"
make -C "$RV64_DIR/tools" smoke-opensbi

echo "[L3] OpenSBI runtime SBI smoke"
make -C "$RV64_DIR/tools" smoke-opensbi-sbi

echo "[L4] Linux initramfs smoke"
make -C "$RV64_DIR/tools" smoke-linux-initramfs

if [ "${RUN_UBUNTU_SMOKE:-0}" = "1" ]; then
  echo "[L5] Ubuntu 22.04 initramfs smoke"
  make -C "$RV64_DIR" ubuntu-base-initramfs
  make -C "$RV64_DIR/tools" smoke-ubuntu-initramfs
fi
