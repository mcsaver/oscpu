#!/usr/bin/env bash
set -euo pipefail

RELEASE=${UBUNTU_RELEASE:-jammy}
ARCH=${UBUNTU_ARCH:-riscv64}
MIRROR=${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
WORK=${UBUNTU_ROOTFS_WORK:-"$ENV_ROOT/images/ubuntu2204"}
ROOTFS=${UBUNTU_ROOTFS_DIR:-"$WORK/rootfs"}
IMAGE=${UBUNTU_ROOTFS_IMAGE:-"$WORK/ubuntu-22.04-riscv64.ext4"}
CPIO=${UBUNTU_INITRD_IMAGE:-"$WORK/ubuntu-22.04-riscv64.cpio"}
IMAGE_SIZE=${UBUNTU_ROOTFS_IMAGE_SIZE:-2G}

if [ "$(id -u)" -ne 0 ]; then
  SUDO=(sudo)
else
  SUDO=()
fi

mkdir -p "$WORK"

if [ ! -d "$ROOTFS/debootstrap" ] && [ ! -x "$ROOTFS/bin/sh" ]; then
  "${SUDO[@]}" debootstrap --arch="$ARCH" --foreign --variant=minbase "$RELEASE" "$ROOTFS" "$MIRROR"
fi

if [ ! -x "$ROOTFS/usr/bin/qemu-riscv64-static" ]; then
  "${SUDO[@]}" cp /usr/bin/qemu-riscv64-static "$ROOTFS/usr/bin/"
fi

"${SUDO[@]}" chroot "$ROOTFS" /debootstrap/debootstrap --second-stage

cat <<'EOF' | "${SUDO[@]}" tee "$ROOTFS/etc/fstab" >/dev/null
/dev/vda / ext4 defaults 0 1
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
EOF

cat <<'EOF' | "${SUDO[@]}" tee "$ROOTFS/etc/hostname" >/dev/null
ysyx-ubuntu2204
EOF

truncate -s "$IMAGE_SIZE" "$IMAGE"
"${SUDO[@]}" mkfs.ext4 -F -d "$ROOTFS" "$IMAGE"
"${SUDO[@]}" chown "$(id -u):$(id -g)" "$IMAGE"

(cd "$ROOTFS" && "${SUDO[@]}" find . -print0 | sort -z | "${SUDO[@]}" cpio --null -ov --format=newc > "$CPIO")
"${SUDO[@]}" chown "$(id -u):$(id -g)" "$CPIO"

echo "[ubuntu-rootfs] generated: $IMAGE"
echo "[ubuntu-rootfs] generated initramfs: $CPIO"
echo "[ubuntu-rootfs] 注意：启动该 rootfs 还需要 RTL 侧 virtio-mmio block、多源 PLIC、UART RX，并最终补 F/D 用户态兼容。"
