#!/usr/bin/env bash
set -euo pipefail

RELEASE=${UBUNTU_RELEASE:-jammy}
VERSION=${UBUNTU_BASE_VERSION:-22.04.5}
ARCH=${UBUNTU_ARCH:-riscv64}
MIRROR=${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}
BASE_URL=${UBUNTU_BASE_URL:-https://cdimages.ubuntu.com/ubuntu-base/releases/22.04/release}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
WORK=${UBUNTU_ROOTFS_WORK:-"$ENV_ROOT/images/ubuntu2204"}
ROOTFS=${UBUNTU_ROOTFS_DIR:-"$WORK/rootfs"}
IMAGE=${UBUNTU_ROOTFS_IMAGE:-"$WORK/ubuntu-22.04-riscv64.ext4"}
CPIO=${UBUNTU_ROOTFS_CPIO_IMAGE:-"$WORK/ubuntu-22.04-riscv64-rootfs.cpio"}
IMAGE_SIZE=${UBUNTU_ROOTFS_IMAGE_SIZE:-2G}
FILENAME="ubuntu-base-$VERSION-base-$ARCH.tar.gz"
TARBALL=${UBUNTU_BASE_TARBALL:-"$ENV_ROOT/downloads/$FILENAME"}
SHA_FILE=${UBUNTU_BASE_SHA_FILE:-"$ENV_ROOT/downloads/SHA256SUMS"}

mkdir -p "$WORK" "$(dirname "$TARBALL")"

can_sudo() {
  [ "$(id -u)" -eq 0 ] || sudo -n true >/dev/null 2>&1
}

download_ubuntu_base() {
  if [ ! -f "$TARBALL" ]; then
    echo "[ubuntu-rootfs] download: $BASE_URL/$FILENAME"
    curl -fL "$BASE_URL/$FILENAME" -o "$TARBALL"
  fi
  if [ ! -f "$SHA_FILE" ]; then
    echo "[ubuntu-rootfs] download: $BASE_URL/SHA256SUMS"
    curl -fL "$BASE_URL/SHA256SUMS" -o "$SHA_FILE"
  fi
  grep " \\*$FILENAME\$" "$SHA_FILE" > "$WORK/$FILENAME.sha256"
  (cd "$ENV_ROOT/downloads" && sha256sum -c "$WORK/$FILENAME.sha256")
}

write_guest_config() {
  local dir=$1
  cat > "$dir/etc/fstab" <<'EOF'
/dev/vda / ext4 defaults 0 1
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
EOF

  cat > "$dir/etc/hostname" <<'EOF'
ysyx-ubuntu2204
EOF

  cat > "$dir/init" <<'INIT'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mkdir -p /proc /sys /run /tmp
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true

echo "[ysyx-rootfs] Ubuntu 22.04 rootfs reached"
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
uname -a 2>/dev/null || true
echo "[ysyx-rootfs] probing /bin/sh -c"
/bin/sh -c 'echo "[ysyx-rootfs-sh] /bin/sh -c marker"; exit 0'
sh_probe_rc=$?
echo "[ysyx-rootfs] /bin/sh -c exit=$sh_probe_rc"
echo "[ysyx-rootfs] launching /bin/sh"

exec /bin/sh -i </dev/console >/dev/console 2>&1
INIT
  chmod 0755 "$dir/init"
}

build_with_sudo_debootstrap() {
  local sudo_cmd=()
  if [ "$(id -u)" -ne 0 ]; then
    sudo_cmd=(sudo)
  fi

  if [ ! -d "$ROOTFS/debootstrap" ] && [ ! -x "$ROOTFS/bin/sh" ]; then
    "${sudo_cmd[@]}" debootstrap --arch="$ARCH" --foreign --variant=minbase "$RELEASE" "$ROOTFS" "$MIRROR"
  fi

  if [ ! -x "$ROOTFS/usr/bin/qemu-riscv64-static" ]; then
    "${sudo_cmd[@]}" cp /usr/bin/qemu-riscv64-static "$ROOTFS/usr/bin/"
  fi

  "${sudo_cmd[@]}" chroot "$ROOTFS" /debootstrap/debootstrap --second-stage
  "${sudo_cmd[@]}" bash -c "$(declare -f write_guest_config); write_guest_config '$ROOTFS'"
  "${sudo_cmd[@]}" truncate -s "$IMAGE_SIZE" "$IMAGE"
  "${sudo_cmd[@]}" mkfs.ext4 -F -d "$ROOTFS" "$IMAGE"
  "${sudo_cmd[@]}" chown "$(id -u):$(id -g)" "$IMAGE"
}

build_with_fakeroot_ubuntu_base() {
  command -v fakeroot >/dev/null || {
    echo "[ubuntu-rootfs] missing fakeroot and sudo is unavailable" >&2
    exit 1
  }
  command -v mkfs.ext4 >/dev/null || {
    echo "[ubuntu-rootfs] missing mkfs.ext4" >&2
    exit 1
  }
  download_ubuntu_base

  local helper="$WORK/.build-rootfs-fakeroot.sh"
  cat > "$helper" <<'FAKEROOT'
set -euo pipefail
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"
tar -xpf "$TARBALL" -C "$ROOTFS" \
  --delay-directory-restore \
  --exclude='./dev/*' \
  --exclude='dev/*'
mkdir -p "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" "$ROOTFS/tmp" "$ROOTFS/etc"
chmod 1777 "$ROOTFS/tmp"

cat > "$ROOTFS/etc/fstab" <<'EOF'
/dev/vda / ext4 defaults 0 1
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
EOF

cat > "$ROOTFS/etc/hostname" <<'EOF'
ysyx-ubuntu2204
EOF

cat > "$ROOTFS/init" <<'INIT'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mkdir -p /proc /sys /run /tmp
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true

echo "[ysyx-rootfs] Ubuntu 22.04 rootfs reached"
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
uname -a 2>/dev/null || true
echo "[ysyx-rootfs] probing /bin/sh -c"
/bin/sh -c 'echo "[ysyx-rootfs-sh] /bin/sh -c marker"; exit 0'
sh_probe_rc=$?
echo "[ysyx-rootfs] /bin/sh -c exit=$sh_probe_rc"
echo "[ysyx-rootfs] launching /bin/sh"

exec /bin/sh -i </dev/console >/dev/console 2>&1
INIT
chmod 0755 "$ROOTFS/init"

truncate -s "$IMAGE_SIZE" "$IMAGE"
mkfs.ext4 -F -d "$ROOTFS" "$IMAGE"
(cd "$ROOTFS" && find . -print0 | sort -z | cpio --quiet --null -o --format=newc > "$CPIO")
FAKEROOT

  ROOTFS="$ROOTFS" TARBALL="$TARBALL" IMAGE="$IMAGE" CPIO="$CPIO" IMAGE_SIZE="$IMAGE_SIZE" \
    fakeroot -- bash "$helper"
}

if can_sudo && command -v debootstrap >/dev/null && command -v qemu-riscv64-static >/dev/null; then
  echo "[ubuntu-rootfs] build via debootstrap"
  build_with_sudo_debootstrap
else
  echo "[ubuntu-rootfs] build via Ubuntu Base + fakeroot"
  build_with_fakeroot_ubuntu_base
fi

echo "[ubuntu-rootfs] generated: $IMAGE"
echo "[ubuntu-rootfs] generated rootfs cpio: $CPIO"
echo "[ubuntu-rootfs] 注意：启动该 rootfs 还需要 RTL/仿真侧 virtio-mmio block、host block backend 与 IRQ2 路径。"
