#!/usr/bin/env bash
set -euo pipefail

RELEASE=${UBUNTU_RELEASE:-jammy}
ARCH=${UBUNTU_ARCH:-riscv64}
MIRROR=${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
WORK=${UBUNTU_ROOTFS_WORK:-"$ENV_ROOT/images/ubuntu2204"}
ROOTFS=${UBUNTU_ROOTFS_DIR:-"$WORK/rootfs"}
APT_ROOT=${UBUNTU_SYSTEMD_OVERLAY_APT_ROOT:-"$WORK/apt-systemd-overlay"}
APT_TRUSTED=${UBUNTU_SYSTEMD_OVERLAY_APT_TRUSTED:-1}
APT_COMPONENTS=${UBUNTU_SYSTEMD_OVERLAY_COMPONENTS:-"main universe"}
APT_NO_RECOMMENDS=${UBUNTU_SYSTEMD_OVERLAY_NO_RECOMMENDS:-1}
OVERLAY_PACKAGES=${UBUNTU_SYSTEMD_OVERLAY_PACKAGES:-"systemd systemd-sysv udev dbus procps iproute2 kmod util-linux login passwd adduser"}

if [ ! -d "$ROOTFS" ] || [ ! -f "$ROOTFS/etc/os-release" ]; then
  echo "[ubuntu-systemd-overlay] missing extracted Ubuntu rootfs: $ROOTFS" >&2
  echo "[ubuntu-systemd-overlay] run this after Ubuntu Base extraction or via build-ubuntu-rootfs.sh" >&2
  exit 1
fi

for tool in apt-get dpkg-deb; do
  if ! command -v "$tool" >/dev/null; then
    echo "[ubuntu-systemd-overlay] missing tool: $tool" >&2
    exit 1
  fi
done

mkdir -p "$APT_ROOT/etc/apt" "$APT_ROOT/state/lists/partial" \
  "$APT_ROOT/cache/archives/partial"

trusted_opt=
if [ "$APT_TRUSTED" = "1" ]; then
  trusted_opt="[trusted=yes] "
fi

cat > "$APT_ROOT/etc/apt/sources.list" <<EOF
deb ${trusted_opt}${MIRROR} ${RELEASE} ${APT_COMPONENTS}
deb ${trusted_opt}${MIRROR} ${RELEASE}-updates ${APT_COMPONENTS}
deb ${trusted_opt}${MIRROR} ${RELEASE}-security ${APT_COMPONENTS}
EOF

STATUS_FILE="$ROOTFS/var/lib/dpkg/status"
if [ ! -f "$STATUS_FILE" ]; then
  STATUS_FILE="$APT_ROOT/status"
  : > "$STATUS_FILE"
fi

apt_opts=(
  -o "APT::Architecture=$ARCH"
  -o "APT::Architectures::=$ARCH"
  -o "Dir::Etc::sourcelist=$APT_ROOT/etc/apt/sources.list"
  -o "Dir::Etc::sourceparts=-"
  -o "Dir::Etc::main=-"
  -o "Dir::State=$APT_ROOT/state"
  -o "Dir::State::status=$STATUS_FILE"
  -o "Dir::Cache=$APT_ROOT/cache"
  -o "Debug::NoLocking=1"
)

echo "[ubuntu-systemd-overlay] apt update for $RELEASE/$ARCH"
apt-get "${apt_opts[@]}" update

install_opts=(--yes --download-only)
if [ "$APT_NO_RECOMMENDS" = "1" ]; then
  install_opts+=(--no-install-recommends)
fi

echo "[ubuntu-systemd-overlay] download packages: $OVERLAY_PACKAGES"
# shellcheck disable=SC2086
apt-get "${apt_opts[@]}" "${install_opts[@]}" install $OVERLAY_PACKAGES

shopt -s nullglob
debs=("$APT_ROOT/cache/archives"/*.deb)
if [ "${#debs[@]}" -eq 0 ]; then
  echo "[ubuntu-systemd-overlay] apt produced no .deb packages" >&2
  exit 1
fi

echo "[ubuntu-systemd-overlay] unpack ${#debs[@]} packages into $ROOTFS"
for deb in "${debs[@]}"; do
  dpkg-deb -x "$deb" "$ROOTFS"
done

mkdir -p "$ROOTFS/etc/apt" "$ROOTFS/etc/systemd/system" \
  "$ROOTFS/var/lib/systemd" "$ROOTFS/run" "$ROOTFS/run/lock"
cp "$APT_ROOT/etc/apt/sources.list" "$ROOTFS/etc/apt/sources.list"

# systemd 在首次启动时可以填充空 machine-id；显式放一个文件比缺文件更接近真实 rootfs。
if [ ! -e "$ROOTFS/etc/machine-id" ]; then
  : > "$ROOTFS/etc/machine-id"
fi

if [ ! -e "$ROOTFS/sbin/init" ]; then
  mkdir -p "$ROOTFS/sbin"
  if [ -x "$ROOTFS/lib/systemd/systemd" ]; then
    ln -s ../lib/systemd/systemd "$ROOTFS/sbin/init"
  elif [ -x "$ROOTFS/usr/lib/systemd/systemd" ]; then
    ln -s ../usr/lib/systemd/systemd "$ROOTFS/sbin/init"
  fi
fi

# Ubuntu Base 的 chrootless 解包可能留下 /usr/lib 下的动态链接器，
# 但 RISC-V lp64d ELF interpreter 固定请求 /lib/ld-linux-riscv64-lp64d.so.1。
mkdir -p "$ROOTFS/lib"
if [ ! -e "$ROOTFS/lib/ld-linux-riscv64-lp64d.so.1" ] && \
   [ -e "$ROOTFS/usr/lib/ld-linux-riscv64-lp64d.so.1" ]; then
  ln -s ../usr/lib/ld-linux-riscv64-lp64d.so.1 \
    "$ROOTFS/lib/ld-linux-riscv64-lp64d.so.1"
fi

echo "[ubuntu-systemd-overlay] overlay complete"
