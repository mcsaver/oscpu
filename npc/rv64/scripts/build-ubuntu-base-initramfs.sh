#!/usr/bin/env bash
set -euo pipefail

VERSION=${UBUNTU_BASE_VERSION:-22.04.5}
ARCH=${UBUNTU_ARCH:-riscv64}
BASE_URL=${UBUNTU_BASE_URL:-https://cdimages.ubuntu.com/ubuntu-base/releases/22.04/release}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
WORK=${UBUNTU_ROOTFS_WORK:-"$ENV_ROOT/images/ubuntu2204"}
ROOTFS=${UBUNTU_BASE_ROOTFS_DIR:-"$WORK/ubuntu-base-rootfs"}
TARBALL=${UBUNTU_BASE_TARBALL:-"$ENV_ROOT/downloads/ubuntu-base-$VERSION-base-$ARCH.tar.gz"}
SHA_FILE=${UBUNTU_BASE_SHA_FILE:-"$ENV_ROOT/downloads/SHA256SUMS"}
STAMP=${UBUNTU_BASE_STAMP:-"$ROOTFS/.ysyx-ubuntu-base-$VERSION-$ARCH"}
INITRAMFS_PROFILE=${UBUNTU_INITRAMFS_PROFILE:-probe}
if [ -n "${UBUNTU_INITRD_IMAGE:-}" ]; then
  CPIO=$UBUNTU_INITRD_IMAGE
else
  CPIO="$WORK/ubuntu-22.04-riscv64-$INITRAMFS_PROFILE.cpio"
fi
INIT_MODE=${UBUNTU_INIT_MODE:-syscall}
INIT_SRC=${UBUNTU_INIT_SRC:-"$RV64_DIR/tools/ysyx-ubuntu-init.c"}
INIT_BIN=${UBUNTU_INIT_BIN:-"$WORK/ysyx-ubuntu-init"}
LOCAL_LINUX_PREFIX="$ENV_ROOT/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-"
if [ -x "${LOCAL_LINUX_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_LINUX_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
CC=${CC:-"${CROSS_COMPILE}gcc"}

FILENAME="ubuntu-base-$VERSION-base-$ARCH.tar.gz"

mkdir -p "$WORK"
mkdir -p "$(dirname "$TARBALL")"

if [ ! -f "$TARBALL" ]; then
  echo "[ubuntu-base] download: $BASE_URL/$FILENAME"
  curl -fL "$BASE_URL/$FILENAME" -o "$TARBALL"
fi

if [ ! -f "$SHA_FILE" ]; then
  echo "[ubuntu-base] download: $BASE_URL/SHA256SUMS"
  curl -fL "$BASE_URL/SHA256SUMS" -o "$SHA_FILE"
fi

grep " \\*$FILENAME\$" "$SHA_FILE" > "$WORK/$FILENAME.sha256"
(cd "$ENV_ROOT/downloads" && sha256sum -c "$WORK/$FILENAME.sha256")

if [ ! -f "$STAMP" ]; then
  rm -rf "$ROOTFS"
  mkdir -p "$ROOTFS"
  # Ubuntu Base 带有 /dev 设备节点；普通用户无法 mknod，所以这里跳过 /dev，
  # 由 /init 在 guest 内挂载 devtmpfs，避免把 sudo 作为 initramfs 构建前置。
  tar -xzf "$TARBALL" -C "$ROOTFS" \
    --no-same-owner \
    --delay-directory-restore \
    --exclude='./dev/*' \
    --exclude='dev/*'
  mkdir -p "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" "$ROOTFS/tmp"
  chmod 1777 "$ROOTFS/tmp"
  touch "$STAMP"
fi

build_syscall_init() {
  echo "[ubuntu-base] build rv64imac syscall init: $INIT_BIN"
  "$CC" -Os -ffreestanding -fno-builtin -fno-pic -fno-pie \
    -fno-stack-protector -nostdlib -nostartfiles -static -no-pie \
    -march=rv64imac_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
    -Wl,--no-relax -Wl,--build-id=none -Wl,-e,_start \
    -o "$INIT_BIN" "$INIT_SRC"
}

if [ "$INIT_MODE" = "syscall" ]; then
  build_syscall_init
elif [ "$INIT_MODE" = "shell" ]; then
  cat > "$ROOTFS/init" <<'INIT'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mkdir -p /proc /sys /run /tmp
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true

echo "[ysyx-init] Ubuntu 22.04 initramfs reached"
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
uname -a 2>/dev/null || true
echo "[ysyx-init] probing /bin/sh -c"
/bin/sh -c 'echo "[ysyx-sh] /bin/sh -c marker"; exit 0'
sh_probe_rc=$?
echo "[ysyx-init] /bin/sh -c exit=$sh_probe_rc"
echo "[ysyx-init] launching /bin/sh"

exec /bin/sh -i </dev/console >/dev/console 2>&1
INIT
else
  echo "[ubuntu-base] unsupported UBUNTU_INIT_MODE=$INIT_MODE" >&2
  exit 1
fi

cat > "$ROOTFS/etc/fstab" <<'EOF'
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
EOF

cat > "$ROOTFS/etc/hostname" <<'EOF'
ysyx-ubuntu2204
EOF

case "$INITRAMFS_PROFILE" in
  probe)
    PROBE_ROOT="$WORK/ubuntu-base-probe-rootfs"
    rm -rf "$PROBE_ROOT"
    mkdir -p "$PROBE_ROOT/dev" "$PROBE_ROOT/proc" "$PROBE_ROOT/sys" \
      "$PROBE_ROOT/run" "$PROBE_ROOT/tmp" "$PROBE_ROOT/etc"
    chmod 1777 "$PROBE_ROOT/tmp"
    cp "$INIT_BIN" "$PROBE_ROOT/init"
    cp "$ROOTFS/etc/os-release" "$PROBE_ROOT/etc/os-release"
    chmod 0755 "$PROBE_ROOT/init"
    (cd "$PROBE_ROOT" && find . -print0 | sort -z | cpio --quiet --null -o --format=newc > "$CPIO")
    ;;
  full)
    if [ "$INIT_MODE" = "syscall" ]; then
      cp "$INIT_BIN" "$ROOTFS/init"
    fi
    chmod 0755 "$ROOTFS/init"
    (cd "$ROOTFS" && find . -print0 | sort -z | cpio --quiet --null -o --format=newc > "$CPIO")
    ;;
  *)
    echo "[ubuntu-base] unsupported UBUNTU_INITRAMFS_PROFILE=$INITRAMFS_PROFILE" >&2
    exit 1
    ;;
esac

echo "[ubuntu-base] rootfs: $ROOTFS"
echo "[ubuntu-base] profile: $INITRAMFS_PROFILE"
echo "[ubuntu-base] initramfs: $CPIO"
echo "[ubuntu-base] next: make -C npc/rv64/tools smoke-ubuntu-initramfs"
