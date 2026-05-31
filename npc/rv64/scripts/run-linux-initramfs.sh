#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
LOG_DIR=${LOG_DIR:-"$ENV_ROOT/logs/linux-initramfs/$(date +%Y%m%d-%H%M%S)"}
JOBS=${JOBS:-$(nproc)}

mkdir -p "$LOG_DIR"

make -C "$RV64_DIR" rv64_linux_defconfig
make -C "$RV64_DIR" -j"$JOBS"
make -C "$RV64_DIR/tools" smoke-linux-initramfs LOG_DIR="$LOG_DIR" 2>&1 | tee "$LOG_DIR/linux-initramfs.log"
status=${PIPESTATUS[0]}

"$SCRIPT_DIR/collect-linux-log.sh" "$LOG_DIR/linux-initramfs.log" "$LOG_DIR"
exit "$status"
