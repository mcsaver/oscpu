#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
JOBS=${JOBS:-$(nproc)}

echo "[L0] build rv64 linux simulator profile"
make -C "$LINUX_HOME" ARCH=riscv64-npc JOBS="$JOBS" sim

echo "[L1] focused Linux bring-up gates"
make -C "$LINUX_HOME" ARCH=riscv64-npc \
  smoke-jal-link smoke-branch-raw \
  smoke-sret-user smoke-sret-user-pagefault smoke-sret-user-sv39 smoke-sret-restore \
  smoke-ras-trap-boundary smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass \
  smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub \
  smoke-fp-mul smoke-fp-div smoke-fp-sqrt

echo "[L2] DTB and OpenSBI payload gates"
make -C "$LINUX_HOME" ARCH=riscv64-npc smoke-dtb smoke-opensbi-sbi

echo "[L3] Linux busybox initramfs artifacts"
make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=busybox-initramfs prepare

if [ "${RUN_UBUNTU_SMOKE:-0}" = "1" ]; then
  echo "[L4] Ubuntu 22.04 shell initramfs gate"
  make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-shell run
fi
