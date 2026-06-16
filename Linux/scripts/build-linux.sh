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
PLATFORM=${LINUX_PLATFORM:-shared}
BUILD_DIR=${LINUX_BUILD_DIR:-"$ENV_ROOT/platforms/$PLATFORM/build/linux"}
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

LINUX_PATCH="$LINUX_HOME/patches/linux-skip-riscv-unaligned-benchmark.patch"
if [ -f "$LINUX_PATCH" ] &&
   ! grep -q "NPC bring-up: skip the early unaligned-access benchmark" \
     "$ROOT/arch/riscv/kernel/cpufeature.c"; then
  (cd "$ROOT" && patch -p1 < "$LINUX_PATCH")
fi

mkdir -p "$BUILD_DIR"
CONFIG_TOOL="$ROOT/scripts/config"
kconfig() {
  "$CONFIG_TOOL" --file "$BUILD_DIR/.config" "$@"
}

# Linux 源码和下载缓存共享；.config、对象文件和 Image 按平台写入 O= 目录，
# 使 riscv64-nemu 与 riscv64-npc 可以并行构建而不覆盖彼此产物。
make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" defconfig

# NPC 当前是单 hart bring-up；裁掉 PCI/USB/模块/调试面，避免仿真把大量周期
# 花在通用发行版探测路径上。systemd rootfs 仍需要 AF_UNIX、netlink 和 notify socket；
# NEMU rootfs 额外打开最小 virtio-net，用于枚举接口，不代表已有 host 转发后端。
kconfig --disable CONFIG_SMP
kconfig --set-val CONFIG_NR_CPUS 1
kconfig --disable CONFIG_MODULES
kconfig --enable CONFIG_NET
kconfig --enable CONFIG_UNIX
kconfig --enable CONFIG_PACKET
kconfig --enable CONFIG_NETLINK_DIAG
kconfig --enable CONFIG_INET
# systemd 需要本地 socket/netlink，但不需要 IPsec；关掉 XFRM/ESP 可以避免
# CRYPTO_GENIV -> DRBG -> jitterentropy 在慢速 NEMU 上消耗十几秒 guest time。
kconfig --disable CONFIG_XFRM
kconfig --disable CONFIG_XFRM_ALGO
kconfig --disable CONFIG_XFRM_AH
kconfig --disable CONFIG_XFRM_ESP
kconfig --disable CONFIG_XFRM_IPCOMP
kconfig --disable CONFIG_INET_AH
kconfig --disable CONFIG_INET_ESP
kconfig --disable CONFIG_INET_IPCOMP
kconfig --disable CONFIG_AUDIT
kconfig --disable CONFIG_AUDITSYSCALL
# systemd/journald 的单位沙箱会探测 cgroup-BPF firewalling；打开最小内核
# BPF syscall 与 cgroup-BPF，避免完整 Ubuntu 用户态把该能力报告为缺失。
kconfig --enable CONFIG_BPF_SYSCALL
kconfig --enable CONFIG_CGROUP_BPF
kconfig --disable CONFIG_IKCONFIG
kconfig --disable CONFIG_IKCONFIG_PROC
kconfig --disable CONFIG_IO_URING
kconfig --disable CONFIG_PERF_EVENTS
kconfig --disable CONFIG_CGROUP_PERF
kconfig --disable CONFIG_ARCH_MICROCHIP_POLARFIRE
kconfig --disable CONFIG_SOC_MICROCHIP_POLARFIRE
kconfig --disable CONFIG_ARCH_RENESAS
kconfig --disable CONFIG_ARCH_SIFIVE
kconfig --disable CONFIG_SOC_SIFIVE
kconfig --disable CONFIG_ARCH_STARFIVE
kconfig --disable CONFIG_SOC_STARFIVE
kconfig --disable CONFIG_ARCH_SUNXI
kconfig --disable CONFIG_ARCH_THEAD
kconfig --disable CONFIG_EFI
kconfig --disable CONFIG_EFI_STUB
kconfig --disable CONFIG_EFI_PARTITION
kconfig --disable CONFIG_EFIVAR_FS
kconfig --disable CONFIG_IPV6
kconfig --disable CONFIG_XFRM_USER
kconfig --disable CONFIG_NETFILTER
kconfig --disable CONFIG_IP_VS
kconfig --disable CONFIG_BRIDGE
kconfig --disable CONFIG_VLAN_8021Q
kconfig --disable CONFIG_NET_SCHED
kconfig --disable CONFIG_NET_CLS
kconfig --disable CONFIG_NET_ACT
kconfig --enable CONFIG_NETDEVICES
kconfig --enable CONFIG_VIRTIO_NET
# 只保留 virtio-net 这条 Linux-visible 设备路径；其它虚拟/以太网
# 厂商驱动会增加 probe 面和构建体积，当前 NEMU 没有对应 MMIO 设备。
kconfig --disable CONFIG_DUMMY
kconfig --disable CONFIG_MACVLAN
kconfig --disable CONFIG_IPVLAN
kconfig --disable CONFIG_VXLAN
kconfig --disable CONFIG_VETH
kconfig --disable CONFIG_NET_FAILOVER
kconfig --disable CONFIG_FAILOVER
kconfig --disable CONFIG_ETHERNET
kconfig --disable CONFIG_NET_VENDOR_CADENCE
kconfig --disable CONFIG_NET_VENDOR_STMICRO
kconfig --disable CONFIG_MACB
kconfig --disable CONFIG_STMMAC_ETH
kconfig --disable CONFIG_PHYLIB
kconfig --disable CONFIG_MII
kconfig --disable CONFIG_WIRELESS
kconfig --disable CONFIG_CFG80211
kconfig --disable CONFIG_MAC80211
kconfig --disable CONFIG_PCI
kconfig --disable CONFIG_USB_SUPPORT
kconfig --disable CONFIG_SOUND
kconfig --disable CONFIG_MEDIA_SUPPORT
kconfig --disable CONFIG_DRM
kconfig --disable CONFIG_FB
kconfig --disable CONFIG_MMC
kconfig --disable CONFIG_COMMON_CLK
kconfig --disable CONFIG_I2C
kconfig --disable CONFIG_SPI
kconfig --disable CONFIG_PINCTRL
kconfig --disable CONFIG_GPIOLIB
kconfig --disable CONFIG_POWER_SUPPLY
kconfig --disable CONFIG_HWMON
kconfig --disable CONFIG_THERMAL
kconfig --disable CONFIG_REGULATOR
# NEMU rootfs DTB 暴露 google,goldfish-rtc；打开 RTC class/driver，
# 让 Ubuntu 用户态拥有 wall-clock 设备，而不是只依赖 CLINT mtime。
kconfig --enable CONFIG_RTC_CLASS
kconfig --enable CONFIG_RTC_DRV_GOLDFISH
kconfig --disable CONFIG_RPMSG
kconfig --disable CONFIG_EXTCON
kconfig --disable CONFIG_RESET_CONTROLLER
kconfig --disable CONFIG_GENERIC_PHY
kconfig --disable CONFIG_RISCV_PMU
# Ubuntu 的 e2scrub/systemd 维护任务会通过 loop-control 清理在线 ext4 快照；
# 这是发行版用户态的正常路径，不能为了提速关掉。
kconfig --enable CONFIG_BLK_DEV_LOOP
kconfig --disable CONFIG_VIRTIO_CONSOLE
kconfig --disable CONFIG_VIRTIO_BALLOON
kconfig --disable CONFIG_SERIAL_SH_SCI
kconfig --disable CONFIG_VT
kconfig --disable CONFIG_ACPI
kconfig --disable CONFIG_PNP
kconfig --disable CONFIG_INPUT
kconfig --disable CONFIG_KVM
kconfig --disable CONFIG_IOMMU_SUPPORT
kconfig --disable CONFIG_SCSI
kconfig --disable CONFIG_ATA
kconfig --disable CONFIG_MD
kconfig --disable CONFIG_BLK_DEV_DM
kconfig --disable CONFIG_BTRFS_FS
# systemd 会用 autofs 管理部分 automount 条件；直接内建 autofs，避免
# 无模块内核下查找 autofs4 alias 时返回 ENOSYS 噪声。
kconfig --enable CONFIG_AUTOFS_FS
kconfig --disable CONFIG_OVERLAY_FS
kconfig --disable CONFIG_ISO9660_FS
kconfig --disable CONFIG_FAT_FS
kconfig --disable CONFIG_NETWORK_FILESYSTEMS
kconfig --disable CONFIG_NFS_FS
kconfig --disable CONFIG_NFS_V4
kconfig --disable CONFIG_SUNRPC
kconfig --disable CONFIG_NET_9P
kconfig --disable CONFIG_9P_FS
kconfig --disable CONFIG_RAID6_PQ
kconfig --disable CONFIG_RAID6_PQ_BENCHMARK
kconfig --disable CONFIG_XOR_BLOCKS
kconfig --disable CONFIG_HUGETLBFS
kconfig --disable CONFIG_HUGETLB_PAGE
kconfig --disable CONFIG_DEBUG_VM
kconfig --disable CONFIG_DEBUG_VM_IRQSOFF
kconfig --disable CONFIG_DEBUG_VM_PGFLAGS
kconfig --disable CONFIG_DEBUG_VM_PGTABLE
kconfig --disable CONFIG_DEBUG_KERNEL
kconfig --disable CONFIG_DEBUG_PLIST
kconfig --disable CONFIG_DEBUG_FS
kconfig --disable CONFIG_DEBUG_INFO
kconfig --disable CONFIG_FTRACE
kconfig --disable CONFIG_TRACING
kconfig --disable CONFIG_PROFILING
kconfig --disable CONFIG_KALLSYMS
kconfig --disable CONFIG_KALLSYMS_ALL
kconfig --disable CONFIG_MQ_IOSCHED_KYBER
kconfig --disable CONFIG_IOSCHED_BFQ
kconfig --disable CONFIG_INIT_STACK_ALL_PATTERN
kconfig --disable CONFIG_INIT_STACK_ALL_ZERO
kconfig --enable CONFIG_INIT_STACK_NONE
kconfig --disable CONFIG_LOCKUP_DETECTOR
kconfig --disable CONFIG_SOFTLOCKUP_DETECTOR
kconfig --disable CONFIG_WQ_WATCHDOG
kconfig --disable CONFIG_WATCHDOG
# 单 hart RTL 仿真里先走最朴素的周期 tick，避开 SBI cpuidle/NO_HZ idle
# 在 OpenSBI trap handler 中反复空转，影响 initramfs bring-up 的可观测性。
kconfig --disable CONFIG_CPU_IDLE
kconfig --disable CONFIG_RISCV_SBI_CPUIDLE
kconfig --disable CONFIG_NO_HZ_IDLE
kconfig --enable CONFIG_HZ_PERIODIC
kconfig --disable CONFIG_CRYPTO_DRBG_MENU
kconfig --disable CONFIG_CRYPTO_DRBG
kconfig --disable CONFIG_CRYPTO_JITTERENTROPY
kconfig --disable CONFIG_CRYPTO_SHA3
kconfig --disable CONFIG_CRYPTO_DEV_VIRTIO
kconfig --disable CONFIG_CRYPTO_HW
kconfig --disable CONFIG_CRYPTO_GCM
kconfig --disable CONFIG_CRYPTO_GENIV
kconfig --disable CONFIG_CRYPTO_SEQIV
kconfig --disable CONFIG_CRYPTO_ECHAINIV
kconfig --disable CONFIG_CRYPTO_AUTHENC
kconfig --disable CONFIG_CRYPTO_USER_API
kconfig --disable CONFIG_CRYPTO_USER_API_HASH
kconfig --disable CONFIG_CRYPTO_USER_API_SKCIPHER
kconfig --disable CONFIG_CRYPTO_USER_API_RNG
kconfig --disable CONFIG_CRYPTO_USER_API_AEAD
# NEMU rootfs DTB 现在提供 virtio-rng；打开最小 hwrng/virtio_rng，
# 让 systemd/ssh/apt 后续能走真实设备熵源，而不是只吃 bootloader rng-seed。
kconfig --enable CONFIG_HW_RANDOM
kconfig --enable CONFIG_HW_RANDOM_VIRTIO
kconfig --disable CONFIG_SECURITY_SELINUX
kconfig --disable CONFIG_SECURITY_APPARMOR

kconfig --enable CONFIG_SERIAL_8250
kconfig --enable CONFIG_SERIAL_8250_CONSOLE
kconfig --enable CONFIG_SERIAL_8250_DW
kconfig --enable CONFIG_SERIAL_OF_PLATFORM
kconfig --enable CONFIG_SERIAL_EARLYCON
# v6.6 的 SBI early console/HVC 依赖 legacy v0.1 console 配置；
# OpenSBI v1.8 仍提供该 legacy console，打开后 earlycon=sbi 才会真正生效。
kconfig --enable CONFIG_RISCV_SBI_V01
kconfig --enable CONFIG_SERIAL_EARLYCON_RISCV_SBI
kconfig --enable CONFIG_HVC_RISCV_SBI
kconfig --enable CONFIG_PRINTK
kconfig --enable CONFIG_EARLY_PRINTK
kconfig --enable CONFIG_BLK_DEV_INITRD
kconfig --enable CONFIG_DEVTMPFS
kconfig --enable CONFIG_DEVTMPFS_MOUNT
kconfig --enable CONFIG_PROC_FS
kconfig --enable CONFIG_SYSFS
kconfig --enable CONFIG_TMPFS
kconfig --enable CONFIG_VIRTIO
kconfig --enable CONFIG_VIRTIO_MMIO
kconfig --enable CONFIG_VIRTIO_BLK
kconfig --enable CONFIG_EXT4_FS

make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" Image

echo "[linux] platform: $PLATFORM"
echo "[linux] build dir: $BUILD_DIR"
echo "[linux] Image: $BUILD_DIR/arch/riscv/boot/Image"
