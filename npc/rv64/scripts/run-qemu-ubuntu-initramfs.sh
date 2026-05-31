#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}

QEMU_BIN=${QEMU_BIN:-"$ENV_ROOT/tools/qemu/bin/qemu-system-riscv64"}
LINUX_IMAGE=${LINUX_IMAGE:-"$ENV_ROOT/src/linux/arch/riscv/boot/Image"}
UBUNTU_INITRD_IMAGE=${UBUNTU_INITRD_IMAGE:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64-probe.cpio"}
QEMU_MEMORY=${QEMU_MEMORY:-128M}
QEMU_TIMEOUT=${QEMU_TIMEOUT:-60s}
LOG_DIR=${LOG_DIR:-"$ENV_ROOT/logs/qemu"}
LOG_FILE=${LOG_FILE:-"$LOG_DIR/ubuntu-initramfs.log"}

if [ ! -x "$QEMU_BIN" ]; then
  echo "[qemu-run] missing local qemu-system-riscv64: $QEMU_BIN" >&2
  echo "[qemu-run] run: make -C $RV64_DIR qemu" >&2
  exit 1
fi
if [ ! -f "$LINUX_IMAGE" ]; then
  echo "[qemu-run] missing Linux Image: $LINUX_IMAGE" >&2
  echo "[qemu-run] run: make -C $RV64_DIR linux" >&2
  exit 1
fi
if [ ! -f "$UBUNTU_INITRD_IMAGE" ]; then
  echo "[qemu-run] missing Ubuntu initramfs: $UBUNTU_INITRD_IMAGE" >&2
  echo "[qemu-run] run: make -C $RV64_DIR ubuntu-base-initramfs" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
set +e
timeout --foreground "$QEMU_TIMEOUT" "$QEMU_BIN" \
  -machine virt \
  -cpu rv64 \
  -m "$QEMU_MEMORY" \
  -smp 1 \
  -nographic \
  -kernel "$LINUX_IMAGE" \
  -initrd "$UBUNTU_INITRD_IMAGE" \
  -append "console=ttyS0 earlycon=sbi loglevel=8 ignore_loglevel rdinit=/init" \
  2>&1 | tee "$LOG_FILE"
qemu_rc=${PIPESTATUS[0]}
set -e

if grep -qa "\[ysyx-init\]" "$LOG_FILE"; then
  echo "[qemu-run] PASS: Ubuntu probe init reached ($LOG_FILE)"
  exit 0
fi

echo "[qemu-run] FAIL: Ubuntu probe init not reached, qemu_rc=$qemu_rc ($LOG_FILE)" >&2
exit 1
