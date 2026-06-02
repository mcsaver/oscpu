#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
LOCAL_LINUX_PREFIX="$ENV_ROOT/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-"
if [ -x "${LOCAL_LINUX_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_LINUX_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi

ROOT=${LINUX_ROOT:-"$ENV_ROOT/src/linux"}
REF=${LINUX_REF:-v6.6}
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
JOBS=${JOBS:-$(nproc)}
VERSION=${REF#v}
TARBALL=${LINUX_TARBALL:-"$ENV_ROOT/downloads/linux-$VERSION.tar.xz"}
TARBALL_URL=${LINUX_TARBALL_URL:-https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VERSION.tar.xz}

ensure_clean_default_root() {
  local resolved
  resolved=$(realpath -m "$ROOT")
  case "$resolved" in
    "$(realpath -m "$ENV_ROOT/src/linux")")
      rm -rf "$ROOT"
      ;;
    *)
      echo "[linux] $ROOT 不是 git 仓库且不在默认 $ENV_ROOT/src/linux，拒绝自动删除。" >&2
      exit 1
      ;;
  esac
}

if [ ! -d "$ROOT/.git" ] && [ ! -f "$ROOT/Makefile" ]; then
  if ! git clone --depth=1 --branch "$REF" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git "$ROOT"; then
    echo "[linux] git clone 失败，回退到官方 tarball: $TARBALL_URL"
    ensure_clean_default_root
    mkdir -p "$(dirname "$TARBALL")"
    curl -fL --retry 5 --retry-delay 2 -C - "$TARBALL_URL" -o "$TARBALL"
    mkdir -p "$(dirname "$ROOT")"
    tar -xf "$TARBALL" -C "$(dirname "$ROOT")"
    mv "$(dirname "$ROOT")/linux-$VERSION" "$ROOT"
  fi
fi

if [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
  git -C "$ROOT" checkout -q "$REF"
fi

cd "$ROOT"

LINUX_PATCH="$LINUX_HOME/patches/linux-skip-riscv-unaligned-benchmark.patch"
if [ -f "$LINUX_PATCH" ] &&
   ! grep -q "NPC bring-up: skip the early unaligned-access benchmark" \
     arch/riscv/kernel/cpufeature.c; then
  patch -p1 < "$LINUX_PATCH"
fi

make ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" defconfig

# NPC 当前是单 hart、initramfs 优先 bring-up；裁掉 defconfig 中与启动证明无关的
# 网络/PCI/模块/调试面，避免仿真把大量周期花在通用发行版探测路径上。
scripts/config --disable CONFIG_SMP
scripts/config --set-val CONFIG_NR_CPUS 1
scripts/config --disable CONFIG_MODULES
scripts/config --disable CONFIG_NET
scripts/config --disable CONFIG_PCI
scripts/config --disable CONFIG_USB_SUPPORT
scripts/config --disable CONFIG_SOUND
scripts/config --disable CONFIG_MEDIA_SUPPORT
scripts/config --disable CONFIG_DRM
scripts/config --disable CONFIG_FB
scripts/config --disable CONFIG_VT
scripts/config --disable CONFIG_ACPI
scripts/config --disable CONFIG_PNP
scripts/config --disable CONFIG_INPUT
scripts/config --disable CONFIG_KVM
scripts/config --disable CONFIG_IOMMU_SUPPORT
scripts/config --disable CONFIG_SCSI
scripts/config --disable CONFIG_ATA
scripts/config --disable CONFIG_MD
scripts/config --disable CONFIG_BLK_DEV_DM
scripts/config --disable CONFIG_BTRFS_FS
scripts/config --disable CONFIG_RAID6_PQ
scripts/config --disable CONFIG_RAID6_PQ_BENCHMARK
scripts/config --disable CONFIG_XOR_BLOCKS
scripts/config --disable CONFIG_HUGETLBFS
scripts/config --disable CONFIG_HUGETLB_PAGE
scripts/config --disable CONFIG_DEBUG_VM
scripts/config --disable CONFIG_DEBUG_VM_IRQSOFF
scripts/config --disable CONFIG_DEBUG_VM_PGFLAGS
scripts/config --disable CONFIG_DEBUG_VM_PGTABLE
scripts/config --disable CONFIG_DEBUG_KERNEL
scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_FTRACE
scripts/config --disable CONFIG_TRACING
scripts/config --disable CONFIG_PROFILING
scripts/config --disable CONFIG_KALLSYMS_ALL
scripts/config --disable CONFIG_INIT_STACK_ALL_PATTERN
scripts/config --disable CONFIG_INIT_STACK_ALL_ZERO
scripts/config --enable CONFIG_INIT_STACK_NONE
scripts/config --disable CONFIG_LOCKUP_DETECTOR
scripts/config --disable CONFIG_SOFTLOCKUP_DETECTOR
scripts/config --disable CONFIG_WQ_WATCHDOG
scripts/config --disable CONFIG_WATCHDOG
# 单 hart RTL 仿真里先走最朴素的周期 tick，避开 SBI cpuidle/NO_HZ idle
# 在 OpenSBI trap handler 中反复空转，影响 initramfs bring-up 的可观测性。
scripts/config --disable CONFIG_CPU_IDLE
scripts/config --disable CONFIG_RISCV_SBI_CPUIDLE
scripts/config --disable CONFIG_NO_HZ_IDLE
scripts/config --enable CONFIG_HZ_PERIODIC
scripts/config --disable CONFIG_CRYPTO_DRBG_MENU
scripts/config --disable CONFIG_CRYPTO_DRBG
scripts/config --disable CONFIG_CRYPTO_JITTERENTROPY
scripts/config --disable CONFIG_CRYPTO_SHA3
scripts/config --disable CONFIG_CRYPTO_DEV_VIRTIO
scripts/config --disable CONFIG_CRYPTO_HW
scripts/config --disable CONFIG_CRYPTO_GCM
scripts/config --disable CONFIG_CRYPTO_GENIV
scripts/config --disable CONFIG_CRYPTO_SEQIV
scripts/config --disable CONFIG_CRYPTO_ECHAINIV
scripts/config --disable CONFIG_CRYPTO_AUTHENC
scripts/config --disable CONFIG_HW_RANDOM
scripts/config --disable CONFIG_HW_RANDOM_VIRTIO

scripts/config --enable CONFIG_SERIAL_8250
scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
scripts/config --enable CONFIG_SERIAL_8250_DW
scripts/config --enable CONFIG_SERIAL_OF_PLATFORM
scripts/config --enable CONFIG_SERIAL_EARLYCON
# v6.6 的 SBI early console/HVC 依赖 legacy v0.1 console 配置；
# OpenSBI v1.8 仍提供该 legacy console，打开后 earlycon=sbi 才会真正生效。
scripts/config --enable CONFIG_RISCV_SBI_V01
scripts/config --enable CONFIG_SERIAL_EARLYCON_RISCV_SBI
scripts/config --enable CONFIG_HVC_RISCV_SBI
scripts/config --enable CONFIG_PRINTK
scripts/config --enable CONFIG_EARLY_PRINTK
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_PROC_FS
scripts/config --enable CONFIG_SYSFS
scripts/config --enable CONFIG_TMPFS
scripts/config --enable CONFIG_VIRTIO
scripts/config --enable CONFIG_VIRTIO_MMIO
scripts/config --enable CONFIG_VIRTIO_BLK
scripts/config --enable CONFIG_EXT4_FS

make ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
make ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" Image

echo "[linux] Image: $ROOT/arch/riscv/boot/Image"
