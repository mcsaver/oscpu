#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
LOG_DIR=${LOG_DIR:-"$ENV_ROOT/logs/linux-initramfs/$(date +%Y%m%d-%H%M%S)"}

mkdir -p "$LOG_DIR"

make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=busybox-initramfs LOG_DIR="$LOG_DIR" run 2>&1 | tee "$LOG_DIR/linux-initramfs.log"
status=${PIPESTATUS[0]}

"$SCRIPT_DIR/collect-linux-log.sh" "$LOG_DIR/linux-initramfs.log" "$LOG_DIR"
exit "$status"
