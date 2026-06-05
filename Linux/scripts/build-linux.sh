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

# NPC 当前是单 hart bring-up；裁掉 PCI/USB/模块/调试面，避免仿真把大量周期
# 花在通用发行版探测路径上。systemd rootfs 仍需要 AF_UNIX、netlink 和 notify socket，
# 因此保留最小 CONFIG_NET，不等价于启用真实网卡设备。
scripts/config --disable CONFIG_SMP
scripts/config --set-val CONFIG_NR_CPUS 1
scripts/config --disable CONFIG_MODULES
scripts/config --enable CONFIG_NET
scripts/config --enable CONFIG_UNIX
scripts/config --enable CONFIG_PACKET
scripts/config --enable CONFIG_NETLINK_DIAG
scripts/config --enable CONFIG_INET
# systemd 需要本地 socket/netlink，但不需要 IPsec；关掉 XFRM/ESP 可以避免
# CRYPTO_GENIV -> DRBG -> jitterentropy 在慢速 NEMU 上消耗十几秒 guest time。
scripts/config --disable CONFIG_XFRM
scripts/config --disable CONFIG_XFRM_ALGO
scripts/config --disable CONFIG_XFRM_AH
scripts/config --disable CONFIG_XFRM_ESP
scripts/config --disable CONFIG_XFRM_IPCOMP
scripts/config --disable CONFIG_INET_AH
scripts/config --disable CONFIG_INET_ESP
scripts/config --disable CONFIG_INET_IPCOMP
scripts/config --disable CONFIG_AUDIT
scripts/config --disable CONFIG_AUDITSYSCALL
scripts/config --disable CONFIG_BPF_SYSCALL
scripts/config --disable CONFIG_IKCONFIG
scripts/config --disable CONFIG_IKCONFIG_PROC
scripts/config --disable CONFIG_IO_URING
scripts/config --disable CONFIG_PERF_EVENTS
scripts/config --disable CONFIG_CGROUP_PERF
scripts/config --disable CONFIG_ARCH_MICROCHIP_POLARFIRE
scripts/config --disable CONFIG_SOC_MICROCHIP_POLARFIRE
scripts/config --disable CONFIG_ARCH_RENESAS
scripts/config --disable CONFIG_ARCH_SIFIVE
scripts/config --disable CONFIG_SOC_SIFIVE
scripts/config --disable CONFIG_ARCH_STARFIVE
scripts/config --disable CONFIG_SOC_STARFIVE
scripts/config --disable CONFIG_ARCH_SUNXI
scripts/config --disable CONFIG_ARCH_THEAD
scripts/config --disable CONFIG_EFI
scripts/config --disable CONFIG_EFI_STUB
scripts/config --disable CONFIG_EFI_PARTITION
scripts/config --disable CONFIG_EFIVAR_FS
scripts/config --disable CONFIG_IPV6
scripts/config --disable CONFIG_XFRM_USER
scripts/config --disable CONFIG_NETFILTER
scripts/config --disable CONFIG_IP_VS
scripts/config --disable CONFIG_BRIDGE
scripts/config --disable CONFIG_VLAN_8021Q
scripts/config --disable CONFIG_NET_SCHED
scripts/config --disable CONFIG_NET_CLS
scripts/config --disable CONFIG_NET_ACT
scripts/config --disable CONFIG_NETDEVICES
scripts/config --disable CONFIG_WIRELESS
scripts/config --disable CONFIG_CFG80211
scripts/config --disable CONFIG_MAC80211
scripts/config --disable CONFIG_PCI
scripts/config --disable CONFIG_USB_SUPPORT
scripts/config --disable CONFIG_SOUND
scripts/config --disable CONFIG_MEDIA_SUPPORT
scripts/config --disable CONFIG_DRM
scripts/config --disable CONFIG_FB
scripts/config --disable CONFIG_MMC
scripts/config --disable CONFIG_COMMON_CLK
scripts/config --disable CONFIG_I2C
scripts/config --disable CONFIG_SPI
scripts/config --disable CONFIG_PINCTRL
scripts/config --disable CONFIG_GPIOLIB
scripts/config --disable CONFIG_POWER_SUPPLY
scripts/config --disable CONFIG_HWMON
scripts/config --disable CONFIG_THERMAL
scripts/config --disable CONFIG_REGULATOR
scripts/config --disable CONFIG_RTC_CLASS
scripts/config --disable CONFIG_RPMSG
scripts/config --disable CONFIG_EXTCON
scripts/config --disable CONFIG_RESET_CONTROLLER
scripts/config --disable CONFIG_GENERIC_PHY
scripts/config --disable CONFIG_RISCV_PMU
# Ubuntu 的 e2scrub/systemd 维护任务会通过 loop-control 清理在线 ext4 快照；
# 这是发行版用户态的正常路径，不能为了提速关掉。
scripts/config --enable CONFIG_BLK_DEV_LOOP
scripts/config --disable CONFIG_VIRTIO_CONSOLE
scripts/config --disable CONFIG_VIRTIO_BALLOON
scripts/config --disable CONFIG_SERIAL_SH_SCI
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
scripts/config --disable CONFIG_AUTOFS_FS
scripts/config --disable CONFIG_OVERLAY_FS
scripts/config --disable CONFIG_ISO9660_FS
scripts/config --disable CONFIG_FAT_FS
scripts/config --disable CONFIG_NETWORK_FILESYSTEMS
scripts/config --disable CONFIG_NFS_FS
scripts/config --disable CONFIG_NFS_V4
scripts/config --disable CONFIG_SUNRPC
scripts/config --disable CONFIG_NET_9P
scripts/config --disable CONFIG_9P_FS
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
scripts/config --disable CONFIG_DEBUG_PLIST
scripts/config --disable CONFIG_DEBUG_FS
scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_FTRACE
scripts/config --disable CONFIG_TRACING
scripts/config --disable CONFIG_PROFILING
scripts/config --disable CONFIG_KALLSYMS
scripts/config --disable CONFIG_KALLSYMS_ALL
scripts/config --disable CONFIG_MQ_IOSCHED_KYBER
scripts/config --disable CONFIG_IOSCHED_BFQ
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
scripts/config --disable CONFIG_CRYPTO_USER_API
scripts/config --disable CONFIG_CRYPTO_USER_API_HASH
scripts/config --disable CONFIG_CRYPTO_USER_API_SKCIPHER
scripts/config --disable CONFIG_CRYPTO_USER_API_RNG
scripts/config --disable CONFIG_CRYPTO_USER_API_AEAD
scripts/config --disable CONFIG_HW_RANDOM
scripts/config --disable CONFIG_HW_RANDOM_VIRTIO
scripts/config --disable CONFIG_SECURITY_SELINUX
scripts/config --disable CONFIG_SECURITY_APPARMOR

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
