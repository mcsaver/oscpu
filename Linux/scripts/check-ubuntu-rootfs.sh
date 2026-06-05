#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
IMAGE=${UBUNTU_ROOTFS_IMAGE:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
REQUIRE_SYSTEMD=${UBUNTU_ROOTFS_REQUIRE_SYSTEMD:-0}
DEBUGFS=${DEBUGFS:-debugfs}

if [ ! -f "$IMAGE" ]; then
  echo "[ubuntu-rootfs-check] missing rootfs image: $IMAGE" >&2
  exit 1
fi

if ! command -v "$DEBUGFS" >/dev/null; then
  echo "[ubuntu-rootfs-check] missing debugfs; install e2fsprogs first" >&2
  exit 1
fi

debugfs_stat() {
  local path=$1
  "$DEBUGFS" -R "stat $path" "$IMAGE" 2>&1 || true
}

rootfs_has() {
  local path=$1
  local out
  out=$(debugfs_stat "$path")
  grep -q "Inode:" <<<"$out" && ! grep -qi "File not found" <<<"$out"
}

print_required() {
  local path=$1
  local label=$2
  if rootfs_has "$path"; then
    echo "[ubuntu-rootfs-check] OK      $label: $path"
  else
    echo "[ubuntu-rootfs-check] MISSING $label: $path" >&2
    return 1
  fi
}

echo "[ubuntu-rootfs-check] image: $IMAGE"

missing=0
print_required /init "stage1 init" || missing=1
print_required /bin/sh "Ubuntu shell" || missing=1
print_required /etc/os-release "Ubuntu identity" || missing=1

if rootfs_has /etc/os-release; then
  "$DEBUGFS" -R "cat /etc/os-release" "$IMAGE" 2>/dev/null |
    grep -E '^(PRETTY_NAME|VERSION_ID)=' || true
fi

systemd_bin=
for candidate in /lib/systemd/systemd /usr/lib/systemd/systemd /sbin/init /usr/sbin/init; do
  if rootfs_has "$candidate"; then
    systemd_bin=$candidate
    break
  fi
done

systemd_missing=0
if [ -n "$systemd_bin" ]; then
  echo "[ubuntu-rootfs-check] OK      systemd candidate: $systemd_bin"
else
  echo "[ubuntu-rootfs-check] MISSING systemd candidate"
  echo "[ubuntu-rootfs-check] 当前镜像只能作为 Ubuntu Base shell/rootfs gate，不能声明完整 systemd Ubuntu。"
  echo "[ubuntu-rootfs-check] 需要 systemd gate 时，请用具备 sudo + debootstrap + qemu-riscv64-static 的环境重建，"
  echo "[ubuntu-rootfs-check] 或设置 UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 让脚本在无法生成 systemd rootfs 时直接失败。"
  if [ "$REQUIRE_SYSTEMD" = "1" ]; then
    systemd_missing=1
  fi
fi

if [ "$REQUIRE_SYSTEMD" = "1" ] && [ -n "$systemd_bin" ]; then
  # 严格 gate 不只看 PID1 二进制，还检查 systemd/udev/dbus 的关键用户态组件是否在镜像内。
  systemd_target_ok=0
  for path in /lib/systemd/system/basic.target /usr/lib/systemd/system/basic.target; do
    if rootfs_has "$path"; then
      echo "[ubuntu-rootfs-check] OK      systemd basic.target: $path"
      systemd_target_ok=1
      break
    fi
  done
  if [ "$systemd_target_ok" -ne 1 ]; then
    echo "[ubuntu-rootfs-check] MISSING systemd basic.target"
    systemd_missing=1
  fi

  udev_ok=0
  for path in /lib/systemd/systemd-udevd /usr/lib/systemd/systemd-udevd; do
    if rootfs_has "$path"; then
      echo "[ubuntu-rootfs-check] OK      udev daemon: $path"
      udev_ok=1
      break
    fi
  done
  if [ "$udev_ok" -ne 1 ]; then
    echo "[ubuntu-rootfs-check] MISSING udev daemon"
    systemd_missing=1
  fi

  if rootfs_has /usr/bin/dbus-daemon; then
    echo "[ubuntu-rootfs-check] OK      dbus daemon: /usr/bin/dbus-daemon"
  else
    echo "[ubuntu-rootfs-check] MISSING dbus daemon: /usr/bin/dbus-daemon"
    systemd_missing=1
  fi

  if rootfs_has /bin/login; then
    echo "[ubuntu-rootfs-check] OK      agetty login path: /bin/login"
  else
    echo "[ubuntu-rootfs-check] MISSING agetty login path: /bin/login"
    systemd_missing=1
  fi

  if rootfs_has /bin/bash; then
    echo "[ubuntu-rootfs-check] OK      root login shell: /bin/bash"
  else
    echo "[ubuntu-rootfs-check] MISSING root login shell: /bin/bash"
    systemd_missing=1
  fi

  if rootfs_has /lib/ld-linux-riscv64-lp64d.so.1; then
    echo "[ubuntu-rootfs-check] OK      lp64d dynamic linker: /lib/ld-linux-riscv64-lp64d.so.1"
  else
    echo "[ubuntu-rootfs-check] MISSING lp64d dynamic linker: /lib/ld-linux-riscv64-lp64d.so.1"
    systemd_missing=1
  fi

  if rootfs_has /lib/riscv64-linux-gnu/security; then
    echo "[ubuntu-rootfs-check] OK      PAM module path: /lib/riscv64-linux-gnu/security"
  else
    echo "[ubuntu-rootfs-check] MISSING PAM module path: /lib/riscv64-linux-gnu/security"
    systemd_missing=1
  fi

  if rootfs_has /sbin/e2scrub_all; then
    echo "[ubuntu-rootfs-check] OK      e2scrub service entrypoint: /sbin/e2scrub_all"
  else
    echo "[ubuntu-rootfs-check] MISSING e2scrub service entrypoint: /sbin/e2scrub_all"
    systemd_missing=1
  fi

  if rootfs_has /etc/systemd/system/serial-getty@hvc0.service; then
    echo "[ubuntu-rootfs-check] OK      unavailable hvc0 getty masked: /etc/systemd/system/serial-getty@hvc0.service"
  else
    echo "[ubuntu-rootfs-check] MISSING unavailable hvc0 getty mask"
    systemd_missing=1
  fi
fi

if [ "$systemd_missing" -ne 0 ]; then
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[ubuntu-rootfs-check] rootfs readiness check passed"
