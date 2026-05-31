#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
LOCAL_LINUX_PREFIX="$ENV_ROOT/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-"
if [ -x "${LOCAL_LINUX_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_LINUX_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi

BUSYBOX_VERSION=${BUSYBOX_VERSION:-1.36.1}
BUSYBOX_ROOT=${BUSYBOX_ROOT:-"$ENV_ROOT/src/busybox-$BUSYBOX_VERSION"}
BUSYBOX_BIN=${BUSYBOX_BIN:-$BUSYBOX_ROOT/busybox}
BUSYBOX_TARBALL=${BUSYBOX_TARBALL:-"$ENV_ROOT/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"}
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
JOBS=${JOBS:-$(nproc)}
WORK=${INITRAMFS_WORK:-"$ENV_ROOT/images/initramfs"}
ROOTFS=${INITRAMFS_ROOTFS:-"$WORK/rootfs"}
OUT=${INITRAMFS_OUT:-"$WORK/rootfs.cpio"}
TMP_ROOT=${NPC_RV64_TMPDIR:-"$ENV_ROOT/tmp"}

build_busybox() {
  if [ ! -d "$BUSYBOX_ROOT" ]; then
    mkdir -p "$(dirname "$BUSYBOX_ROOT")"
    mkdir -p "$(dirname "$BUSYBOX_TARBALL")"
    if [ ! -f "$BUSYBOX_TARBALL" ]; then
      curl -fL "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2" -o "$BUSYBOX_TARBALL"
    fi
    tar -xjf "$BUSYBOX_TARBALL" -C "$(dirname "$BUSYBOX_ROOT")"
  fi
  local min_config
  mkdir -p "$TMP_ROOT"
  min_config=$(mktemp "$TMP_ROOT/busybox-config.XXXXXX")
  cat > "$min_config" <<'EOF'
CONFIG_STATIC=y
CONFIG_BUSYBOX=y
CONFIG_FEATURE_INSTALLER=y
CONFIG_ASH=y
CONFIG_SH_IS_ASH=y
CONFIG_ASH_ECHO=y
CONFIG_ASH_PRINTF=y
CONFIG_ASH_TEST=y
CONFIG_ASH_ALIAS=y
CONFIG_ASH_EXPAND_PRMT=y
CONFIG_CAT=y
CONFIG_LS=y
CONFIG_MOUNT=y
CONFIG_ECHO=y
CONFIG_DMESG=y
CONFIG_UNAME=y
CONFIG_PS=y
CONFIG_PWD=y
CONFIG_MKDIR=y
CONFIG_MKNOD=y
CONFIG_SLEEP=y
CONFIG_TRUE=y
CONFIG_FALSE=y
CONFIG_PRINTF=y
CONFIG_TEST=y
CONFIG_FEATURE_SH_MATH=y
EOF
  make -C "$BUSYBOX_ROOT" distclean
  KCONFIG_ALLCONFIG="$min_config" make -C "$BUSYBOX_ROOT" allnoconfig
  rm -f "$min_config"
  sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' "$BUSYBOX_ROOT/.config"
  sed -i 's/^# CONFIG_STATIC_LIBGCC is not set/CONFIG_STATIC_LIBGCC=y/' "$BUSYBOX_ROOT/.config"
  make -C "$BUSYBOX_ROOT" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" busybox
}

if [ ! -x "$BUSYBOX_BIN" ]; then
  echo "[initramfs] 未找到 BUSYBOX_BIN=$BUSYBOX_BIN，开始构建静态 BusyBox"
  build_busybox
fi

if ! file "$BUSYBOX_BIN" | grep -qi "statically linked"; then
  echo "[initramfs] 警告：$BUSYBOX_BIN 不是静态链接，目标机可能缺动态链接器/库。" >&2
fi

rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp}
install -m 0755 "$BUSYBOX_BIN" "$ROOTFS/bin/busybox"

for app in sh ls cat mount echo dmesg uname ps pwd mkdir mknod sleep; do
  ln -sf /bin/busybox "$ROOTFS/bin/$app"
done

cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo "YSYX RV64 Linux initramfs booted"
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"

cd "$ROOTFS"
find . -print0 | sort -z | cpio --quiet --null -o --format=newc > "$OUT"
echo "[initramfs] generated: $OUT"
