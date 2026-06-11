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
ROOTFS_FLAVOR=${UBUNTU_ROOTFS_FLAVOR:-systemd-minimal}
ROOTFS_FLAVOR_SCRIPT=${UBUNTU_ROOTFS_FLAVOR_SCRIPT:-"$SCRIPT_DIR/ubuntu-rootfs-flavors.sh"}
source "$ROOTFS_FLAVOR_SCRIPT"
ROOTFS_FLAVOR=$(ubuntu_rootfs_flavor_normalize "$ROOTFS_FLAVOR")
WORK=${UBUNTU_ROOTFS_WORK:-"$ENV_ROOT/images/ubuntu2204"}
ROOTFS_ARTIFACT_SUFFIX=${UBUNTU_ROOTFS_ARTIFACT_SUFFIX:-$(ubuntu_rootfs_flavor_artifact_suffix "$ROOTFS_FLAVOR")}
ROOTFS=${UBUNTU_ROOTFS_DIR:-"$WORK/rootfs$ROOTFS_ARTIFACT_SUFFIX"}
IMAGE=${UBUNTU_ROOTFS_IMAGE:-"$WORK/ubuntu-22.04-riscv64$ROOTFS_ARTIFACT_SUFFIX.ext4"}
CPIO=${UBUNTU_ROOTFS_CPIO_IMAGE:-"$WORK/ubuntu-22.04-riscv64$ROOTFS_ARTIFACT_SUFFIX-rootfs.cpio"}
IMAGE_SIZE=${UBUNTU_ROOTFS_IMAGE_SIZE:-$(ubuntu_rootfs_flavor_image_size "$ROOTFS_FLAVOR")}
ROOTFS_INCLUDE=${UBUNTU_ROOTFS_INCLUDE:-$(ubuntu_rootfs_flavor_include_csv "$ROOTFS_FLAVOR")}
DEBOOTSTRAP_VARIANT=${UBUNTU_DEBOOTSTRAP_VARIANT:-$(ubuntu_rootfs_flavor_debootstrap_variant "$ROOTFS_FLAVOR")}
ROOTFS_REQUIRE_SYSTEMD=${UBUNTU_ROOTFS_REQUIRE_SYSTEMD:-0}
ROOTFS_SYSTEMD_OVERLAY=${UBUNTU_ROOTFS_SYSTEMD_OVERLAY:-0}
ROOTFS_SYSTEMD_OVERLAY_SCRIPT=${UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT:-"$SCRIPT_DIR/build-ubuntu-systemd-overlay.sh"}
ROOTFS_SERIAL_AUTOLOGIN=${UBUNTU_ROOTFS_SERIAL_AUTOLOGIN:-1}
ROOTFS_SERIAL_AUTOLOGIN_USER=${UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_USER:-root}
ROOTFS_SERIAL_AUTOLOGIN_TTYS=${UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_TTYS:-ttyS0}
ROOTFS_SERIAL_MASK_TTYS=${UBUNTU_ROOTFS_SERIAL_MASK_TTYS:-hvc0}
FILENAME="ubuntu-base-$VERSION-base-$ARCH.tar.gz"
TARBALL=${UBUNTU_BASE_TARBALL:-"$ENV_ROOT/downloads/$FILENAME"}
SHA_FILE=${UBUNTU_BASE_SHA_FILE:-"$ENV_ROOT/downloads/SHA256SUMS"}
ROOTFS_INIT_SRC=${UBUNTU_ROOTFS_INIT_SRC:-"$LINUX_HOME/tools/ysyx-rootfs-init.c"}
ROOTFS_INIT_BIN=${UBUNTU_ROOTFS_INIT_BIN:-"$WORK/ysyx-rootfs-init"}
ROOTFS_STATIC_INIT=${UBUNTU_ROOTFS_STATIC_INIT:-1}
ROOTFS_PROBE_SRC=${UBUNTU_ROOTFS_PROBE_SRC:-"$LINUX_HOME/tools/ysyx-ubuntu-init.c"}
ROOTFS_PROBE_BIN=${UBUNTU_ROOTFS_PROBE_BIN:-"$WORK/ysyx-rootfs-probe"}
ROOTFS_PROBE_ENABLE=${UBUNTU_ROOTFS_PROBE:-0}
LOCAL_LINUX_PREFIX="$ENV_ROOT/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-"
if [ -x "${LOCAL_LINUX_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_LINUX_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
CC=${CC:-"${CROSS_COMPILE}gcc"}

mkdir -p "$WORK" "$(dirname "$TARBALL")"
echo "[ubuntu-rootfs] flavor: $ROOTFS_FLAVOR"
echo "[ubuntu-rootfs] rootfs dir: $ROOTFS"
echo "[ubuntu-rootfs] image: $IMAGE"
echo "[ubuntu-rootfs] cpio: $CPIO"
echo "[ubuntu-rootfs] image size: $IMAGE_SIZE"
echo "[ubuntu-rootfs] include packages: $ROOTFS_INCLUDE"

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

build_rootfs_static_init() {
  if [ "$ROOTFS_STATIC_INIT" != "1" ]; then
    return
  fi
  if [ ! -f "$ROOTFS_INIT_SRC" ]; then
    echo "[ubuntu-rootfs] missing static init source: $ROOTFS_INIT_SRC" >&2
    exit 1
  fi
  if ! command -v "$CC" >/dev/null; then
    echo "[ubuntu-rootfs] missing compiler for static init: $CC" >&2
    exit 1
  fi
  echo "[ubuntu-rootfs] build static rootfs init: $ROOTFS_INIT_BIN"
  "$CC" -Os -ffreestanding -fno-builtin -fno-pic -fno-pie \
    -fno-stack-protector -nostdlib -nostartfiles -static -no-pie \
    -march=rv64imac_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
    -Wl,--no-relax -Wl,--build-id=none -Wl,-e,_start \
    -o "$ROOTFS_INIT_BIN" "$ROOTFS_INIT_SRC"
}

build_rootfs_probe() {
  if [ "$ROOTFS_PROBE_ENABLE" != "1" ]; then
    return
  fi
  if [ ! -f "$ROOTFS_PROBE_SRC" ]; then
    echo "[ubuntu-rootfs] skip syscall probe: missing $ROOTFS_PROBE_SRC"
    return
  fi
  if ! command -v "$CC" >/dev/null; then
    echo "[ubuntu-rootfs] skip syscall probe: missing compiler $CC"
    return
  fi
  echo "[ubuntu-rootfs] build syscall-only rootfs probe: $ROOTFS_PROBE_BIN"
  "$CC" -Os -ffreestanding -fno-builtin -fno-pic -fno-pie \
    -fno-stack-protector -nostdlib -nostartfiles -static -no-pie \
    -march=rv64imac_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
    -Wl,--no-relax -Wl,--build-id=none -Wl,-e,_start \
    -o "$ROOTFS_PROBE_BIN" "$ROOTFS_PROBE_SRC"
}

write_guest_config() {
  local dir=$1
  cat > "$dir/etc/fstab" <<'EOF'
/dev/vda / ext4 defaults 0 1
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
tmpfs /run tmpfs mode=0755,nosuid,nodev 0 0
devpts /dev/pts devpts gid=5,mode=620,ptmxmode=666 0 0
tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev 0 0
cgroup2 /sys/fs/cgroup cgroup2 nsdelegate 0 0
EOF

  cat > "$dir/etc/hostname" <<'EOF'
ysyx-ubuntu2204
EOF

  cat > "$dir/init" <<'INIT'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo "[ysyx-rootfs] stage1 begin"
mkdir -p /proc /sys /run /run/lock /tmp /dev /dev/pts /dev/shm /sys/fs/cgroup
[ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
[ -c /dev/tty ] || mknod -m 666 /dev/tty c 5 0 2>/dev/null || true
echo "[ysyx-rootfs] mount proc"
mount -t proc proc /proc 2>/dev/null || true
if grep -qs " /dev " /proc/mounts 2>/dev/null; then
  echo "[ysyx-rootfs] mounted /dev"
else
  echo "[ysyx-rootfs] mount devtmpfs"
  mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
  [ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
  [ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
  [ -c /dev/tty ] || mknod -m 666 /dev/tty c 5 0 2>/dev/null || true
fi
echo "[ysyx-rootfs] mount sysfs"
mount -t sysfs sysfs /sys 2>/dev/null || true
echo "[ysyx-rootfs] mount run tmpfs"
mount -t tmpfs tmpfs /run -o mode=0755,nosuid,nodev 2>/dev/null || true
echo "[ysyx-rootfs] mount devpts"
mount -t devpts devpts /dev/pts -o gid=5,mode=620,ptmxmode=666 2>/dev/null || true
[ -e /dev/ptmx ] || ln -sf pts/ptmx /dev/ptmx 2>/dev/null || true
echo "[ysyx-rootfs] mount dev shm"
mount -t tmpfs tmpfs /dev/shm -o mode=1777,nosuid,nodev 2>/dev/null || true
echo "[ysyx-rootfs] mount cgroup2"
mount -t cgroup2 cgroup2 /sys/fs/cgroup -o nsdelegate 2>/dev/null || \
  mount -t cgroup2 cgroup2 /sys/fs/cgroup 2>/dev/null || true
chmod 1777 /tmp 2>/dev/null || true
echo "[ysyx-rootfs] stage1 mounts done"

for mount_point in /dev /proc /sys /run /dev/pts /dev/shm /sys/fs/cgroup; do
  if grep -qs " $mount_point " /proc/mounts 2>/dev/null; then
    echo "[ysyx-rootfs] mounted $mount_point"
  else
    echo "[ysyx-rootfs] missing mount $mount_point"
  fi
done

init_mode=auto
if [ -r /proc/cmdline ]; then
  for arg in $(cat /proc/cmdline); do
    case "$arg" in
      ysyx_init=*) init_mode="${arg#ysyx_init=}" ;;
    esac
  done
fi

systemd_bin=
for candidate in /lib/systemd/systemd /usr/lib/systemd/systemd /sbin/init /usr/sbin/init; do
  if [ -x "$candidate" ]; then
    systemd_bin="$candidate"
    break
  fi
done

echo "[ysyx-rootfs] Ubuntu 22.04 rootfs reached"
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
uname -a 2>/dev/null || true

if [ "$init_mode" = systemd ] || { [ "$init_mode" = auto ] && [ -n "$systemd_bin" ]; }; then
  if [ -n "$systemd_bin" ]; then
    echo "[ysyx-rootfs] launching systemd: $systemd_bin"
    exec "$systemd_bin"
  fi
  echo "[ysyx-rootfs] requested systemd but no systemd binary found"
fi

echo "[ysyx-rootfs] probing /bin/sh -c"
/bin/sh -c 'echo "[ysyx-rootfs-sh] /bin/sh -c marker"; exit 0'
sh_probe_rc=$?
echo "[ysyx-rootfs] /bin/sh -c exit=$sh_probe_rc"
echo "[ysyx-rootfs] launching /bin/sh"

exec /bin/sh -i </dev/console >/dev/console 2>&1
INIT
  chmod 0755 "$dir/init"
}

install_serial_autologin() {
  local dir=$1
  if [ "$ROOTFS_SERIAL_AUTOLOGIN" != "1" ]; then
    return
  fi

  for tty in $ROOTFS_SERIAL_AUTOLOGIN_TTYS; do
    local dropin_dir="$dir/etc/systemd/system/serial-getty@${tty}.service.d"
    mkdir -p "$dropin_dir"
    cat > "$dropin_dir/autologin.conf" <<EOF
[Service]
# NEMU/Linux bring-up 需要自动化验证长期 console session；这里只覆盖串口 getty，
# PID1、PAM session、/dev/pts 和真实 Ubuntu 用户态仍然走 systemd 路线。
ExecStart=
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} --keep-baud 115200,57600,38400,9600 %I \$TERM
EOF
  done
}

install_serial_masks() {
  local dir=$1
  for tty in $ROOTFS_SERIAL_MASK_TTYS; do
    mkdir -p "$dir/etc/systemd/system"
    ln -sfn /dev/null "$dir/etc/systemd/system/serial-getty@${tty}.service"
  done
}

install_nemu_systemd_masks() {
  local dir=$1
  mkdir -p "$dir/etc/systemd/system"
  # e2scrub 的工具本体保留在 full rootfs 中，但在线 ext4 scrub/reap 是宿主维护任务；
  # 在慢速 NEMU guest 中它会阻塞 multi-user.target，不能作为 Ubuntu bring-up 前置。
  ln -sfn /dev/null "$dir/etc/systemd/system/e2scrub_reap.service"
  ln -sfn /dev/null "$dir/etc/systemd/system/e2scrub_all.timer"
}

install_full_runtime_defaults() {
  local dir=$1
  local flavor=${2:-systemd-minimal}
  [ "$flavor" = "full" ] || return

  mkdir -p "$dir/etc/ssh" "$dir/etc/systemd/system" "$dir/var/spool/rsyslog"
  if [ ! -f "$dir/etc/ssh/sshd_config" ]; then
    cat > "$dir/etc/ssh/sshd_config" <<'EOF'
Include /etc/ssh/sshd_config.d/*.conf
Port 22
PermitRootLogin prohibit-password
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
  fi

  if ! grep -q '^syslog:' "$dir/etc/group" 2>/dev/null; then
    echo 'syslog:x:101:' >> "$dir/etc/group"
  fi
  if ! grep -q '^syslog:' "$dir/etc/passwd" 2>/dev/null; then
    echo 'syslog:x:101:101::/nonexistent:/usr/sbin/nologin' >> "$dir/etc/passwd"
  fi
  if ! grep -q '^sshd:' "$dir/etc/group" 2>/dev/null; then
    echo 'sshd:x:102:' >> "$dir/etc/group"
  fi
  if ! grep -q '^sshd:' "$dir/etc/passwd" 2>/dev/null; then
    echo 'sshd:x:102:102::/run/sshd:/usr/sbin/nologin' >> "$dir/etc/passwd"
  fi
  if command -v ssh-keygen >/dev/null 2>&1; then
    ssh-keygen -A -f "$dir"
  fi
  chown -h 101:101 "$dir/var/spool/rsyslog" 2>/dev/null || true
  ln -sfn /lib/systemd/system/rsyslog.service "$dir/etc/systemd/system/syslog.service"
}

build_with_sudo_debootstrap() {
  local sudo_cmd=()
  if [ "$(id -u)" -ne 0 ]; then
    sudo_cmd=(sudo)
  fi

  if [ ! -d "$ROOTFS/debootstrap" ] && [ ! -x "$ROOTFS/bin/sh" ]; then
    local debootstrap_args=(--arch="$ARCH" --foreign)
    if [ -n "$DEBOOTSTRAP_VARIANT" ]; then
      debootstrap_args+=(--variant="$DEBOOTSTRAP_VARIANT")
    fi
    debootstrap_args+=(--include="$ROOTFS_INCLUDE" "$RELEASE" "$ROOTFS" "$MIRROR")
    "${sudo_cmd[@]}" debootstrap "${debootstrap_args[@]}"
  fi

  if [ ! -x "$ROOTFS/usr/bin/qemu-riscv64-static" ]; then
    "${sudo_cmd[@]}" cp /usr/bin/qemu-riscv64-static "$ROOTFS/usr/bin/"
  fi

  "${sudo_cmd[@]}" chroot "$ROOTFS" /debootstrap/debootstrap --second-stage
  "${sudo_cmd[@]}" bash -c "$(declare -f write_guest_config); write_guest_config '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_serial_autologin); ROOTFS_SERIAL_AUTOLOGIN='$ROOTFS_SERIAL_AUTOLOGIN' ROOTFS_SERIAL_AUTOLOGIN_USER='$ROOTFS_SERIAL_AUTOLOGIN_USER' ROOTFS_SERIAL_AUTOLOGIN_TTYS='$ROOTFS_SERIAL_AUTOLOGIN_TTYS' install_serial_autologin '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_serial_masks); ROOTFS_SERIAL_MASK_TTYS='$ROOTFS_SERIAL_MASK_TTYS' install_serial_masks '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_nemu_systemd_masks); install_nemu_systemd_masks '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_full_runtime_defaults); install_full_runtime_defaults '$ROOTFS' '$ROOTFS_FLAVOR'"
  "${sudo_cmd[@]}" bash -c '
set -e
rootfs=$1
mkdir -p "$rootfs/bin"
# Ubuntu Base/merged-/usr 场景下 root 的 passwd shell 仍可能是 /bin/bash。
if [ ! -e "$rootfs/bin/bash" ] && [ -e "$rootfs/usr/bin/bash" ]; then
  ln -s ../usr/bin/bash "$rootfs/bin/bash"
fi
if [ ! -e "$rootfs/bin/login" ] && [ -e "$rootfs/usr/bin/login" ]; then
  ln -s ../usr/bin/login "$rootfs/bin/login"
fi
mkdir -p "$rootfs/sbin"
if [ ! -e "$rootfs/sbin/e2scrub_all" ] && [ -e "$rootfs/usr/sbin/e2scrub_all" ]; then
  ln -s ../usr/sbin/e2scrub_all "$rootfs/sbin/e2scrub_all"
fi
if [ ! -e "$rootfs/sbin/e2scrub" ] && [ -e "$rootfs/usr/sbin/e2scrub" ]; then
  ln -s ../usr/sbin/e2scrub "$rootfs/sbin/e2scrub"
fi
mkdir -p "$rootfs/lib/riscv64-linux-gnu"
if [ -d "$rootfs/usr/lib/riscv64-linux-gnu/security" ]; then
  # debootstrap/Ubuntu Base 布局都可能留下双 PAM 模块目录；login 搜 /lib 路径。
  pam_lib_dir="$rootfs/lib/riscv64-linux-gnu/security"
  pam_usr_dir="$rootfs/usr/lib/riscv64-linux-gnu/security"
  mkdir -p "$pam_lib_dir"
  for module in "$pam_usr_dir"/pam_*.so; do
    [ -e "$module" ] || continue
    module_name=$(basename "$module")
    if [ ! -e "$pam_lib_dir/$module_name" ]; then
      ln -s "../../../usr/lib/riscv64-linux-gnu/security/$module_name" "$pam_lib_dir/$module_name"
    fi
  done
fi
' _ "$ROOTFS"
  # 默认用静态 PID1 承担伪文件系统挂载，再按 cmdline 选择 systemd 或 shell。
  if [ "$ROOTFS_STATIC_INIT" = "1" ]; then
    "${sudo_cmd[@]}" cp "$ROOTFS_INIT_BIN" "$ROOTFS/init"
    "${sudo_cmd[@]}" chmod 0755 "$ROOTFS/init"
  fi
  # 可选静态 probe 用来验证 rootfs 上的 kernel exec/PID1 链路，不改变默认 /init。
  if [ "$ROOTFS_PROBE_ENABLE" = "1" ] && [ -f "$ROOTFS_PROBE_BIN" ]; then
    "${sudo_cmd[@]}" cp "$ROOTFS_PROBE_BIN" "$ROOTFS/ysyx-rootfs-probe"
    "${sudo_cmd[@]}" chmod 0755 "$ROOTFS/ysyx-rootfs-probe"
  fi
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
if [ "$ROOTFS_SYSTEMD_OVERLAY" = "1" ]; then
  # 当前无 sudo/debootstrap 时，systemd overlay 至少把 PID1 与核心用户态依赖放进 rootfs，
  # 让后续 NEMU 可以进入真实 systemd gate 调试，而不是停在“镜像内没有 systemd”。
  UBUNTU_ROOTFS_DIR="$ROOTFS" \
    UBUNTU_ROOTFS_FLAVOR="$ROOTFS_FLAVOR" \
    UBUNTU_ROOTFS_FLAVOR_SCRIPT="$ROOTFS_FLAVOR_SCRIPT" \
    UBUNTU_ROOTFS_WORK="$WORK" \
    UBUNTU_SYSTEMD_OVERLAY_APT_ROOT="$WORK/apt-systemd-overlay" \
    bash "$ROOTFS_SYSTEMD_OVERLAY_SCRIPT"
fi
mkdir -p "$ROOTFS/bin"
# Ubuntu Base/overlay 可能只提供 /usr/bin/sh；补 /bin 兼容入口，保证 shebang 和 PID1 fallback 可执行。
if [ ! -e "$ROOTFS/bin/sh" ] && [ -e "$ROOTFS/usr/bin/sh" ]; then
  ln -s ../usr/bin/sh "$ROOTFS/bin/sh"
fi
if [ ! -e "$ROOTFS/bin/dash" ] && [ -e "$ROOTFS/usr/bin/dash" ]; then
  ln -s ../usr/bin/dash "$ROOTFS/bin/dash"
fi
if [ ! -e "$ROOTFS/bin/bash" ] && [ -e "$ROOTFS/usr/bin/bash" ]; then
  ln -s ../usr/bin/bash "$ROOTFS/bin/bash"
fi
if [ ! -e "$ROOTFS/bin/login" ] && [ -e "$ROOTFS/usr/bin/login" ]; then
  ln -s ../usr/bin/login "$ROOTFS/bin/login"
fi
mkdir -p "$ROOTFS/sbin"
if [ ! -e "$ROOTFS/sbin/e2scrub_all" ] && [ -e "$ROOTFS/usr/sbin/e2scrub_all" ]; then
  ln -s ../usr/sbin/e2scrub_all "$ROOTFS/sbin/e2scrub_all"
fi
if [ ! -e "$ROOTFS/sbin/e2scrub" ] && [ -e "$ROOTFS/usr/sbin/e2scrub" ]; then
  ln -s ../usr/sbin/e2scrub "$ROOTFS/sbin/e2scrub"
fi
mkdir -p "$ROOTFS/lib"
mkdir -p "$ROOTFS/lib/riscv64-linux-gnu"
if [ -d "$ROOTFS/usr/lib/riscv64-linux-gnu/security" ]; then
  # full overlay 可能已创建真实 /lib/.../security；补齐缺失模块而不是依赖整目录 symlink。
  pam_lib_dir="$ROOTFS/lib/riscv64-linux-gnu/security"
  pam_usr_dir="$ROOTFS/usr/lib/riscv64-linux-gnu/security"
  mkdir -p "$pam_lib_dir"
  for module in "$pam_usr_dir"/pam_*.so; do
    [ -e "$module" ] || continue
    module_name=$(basename "$module")
    if [ ! -e "$pam_lib_dir/$module_name" ]; then
      ln -s "../../../usr/lib/riscv64-linux-gnu/security/$module_name" "$pam_lib_dir/$module_name"
    fi
  done
fi
# RISC-V Ubuntu 动态 ELF 请求 /lib 下的 lp64d loader；chrootless 解包时需补 merged-/usr 兼容 symlink。
if [ ! -e "$ROOTFS/lib/ld-linux-riscv64-lp64d.so.1" ] && [ -e "$ROOTFS/usr/lib/ld-linux-riscv64-lp64d.so.1" ]; then
  ln -s ../usr/lib/ld-linux-riscv64-lp64d.so.1 "$ROOTFS/lib/ld-linux-riscv64-lp64d.so.1"
fi
if [ "$ROOTFS_PROBE_ENABLE" = "1" ] && [ -f "$ROOTFS_PROBE_BIN" ]; then
  # 可选静态 probe 用来验证 rootfs 上的 kernel exec/PID1 链路，不改变默认 /init。
  cp "$ROOTFS_PROBE_BIN" "$ROOTFS/ysyx-rootfs-probe"
  chmod 0755 "$ROOTFS/ysyx-rootfs-probe"
fi

cat > "$ROOTFS/etc/fstab" <<'EOF'
/dev/vda / ext4 defaults 0 1
devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
tmpfs /run tmpfs mode=0755,nosuid,nodev 0 0
devpts /dev/pts devpts gid=5,mode=620,ptmxmode=666 0 0
tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev 0 0
cgroup2 /sys/fs/cgroup cgroup2 nsdelegate 0 0
EOF

cat > "$ROOTFS/etc/hostname" <<'EOF'
ysyx-ubuntu2204
EOF

cat > "$ROOTFS/init" <<'INIT'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo "[ysyx-rootfs] stage1 begin"
mkdir -p /proc /sys /run /run/lock /tmp /dev /dev/pts /dev/shm /sys/fs/cgroup
[ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
[ -c /dev/tty ] || mknod -m 666 /dev/tty c 5 0 2>/dev/null || true
echo "[ysyx-rootfs] mount proc"
mount -t proc proc /proc 2>/dev/null || true
if grep -qs " /dev " /proc/mounts 2>/dev/null; then
  echo "[ysyx-rootfs] mounted /dev"
else
  echo "[ysyx-rootfs] mount devtmpfs"
  mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
  [ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
  [ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
  [ -c /dev/tty ] || mknod -m 666 /dev/tty c 5 0 2>/dev/null || true
fi
echo "[ysyx-rootfs] mount sysfs"
mount -t sysfs sysfs /sys 2>/dev/null || true
echo "[ysyx-rootfs] mount run tmpfs"
mount -t tmpfs tmpfs /run -o mode=0755,nosuid,nodev 2>/dev/null || true
echo "[ysyx-rootfs] mount devpts"
mount -t devpts devpts /dev/pts -o gid=5,mode=620,ptmxmode=666 2>/dev/null || true
[ -e /dev/ptmx ] || ln -sf pts/ptmx /dev/ptmx 2>/dev/null || true
echo "[ysyx-rootfs] mount dev shm"
mount -t tmpfs tmpfs /dev/shm -o mode=1777,nosuid,nodev 2>/dev/null || true
echo "[ysyx-rootfs] mount cgroup2"
mount -t cgroup2 cgroup2 /sys/fs/cgroup -o nsdelegate 2>/dev/null || \
  mount -t cgroup2 cgroup2 /sys/fs/cgroup 2>/dev/null || true
chmod 1777 /tmp 2>/dev/null || true
echo "[ysyx-rootfs] stage1 mounts done"

for mount_point in /dev /proc /sys /run /dev/pts /dev/shm /sys/fs/cgroup; do
  if grep -qs " $mount_point " /proc/mounts 2>/dev/null; then
    echo "[ysyx-rootfs] mounted $mount_point"
  else
    echo "[ysyx-rootfs] missing mount $mount_point"
  fi
done

init_mode=auto
if [ -r /proc/cmdline ]; then
  for arg in $(cat /proc/cmdline); do
    case "$arg" in
      ysyx_init=*) init_mode="${arg#ysyx_init=}" ;;
    esac
  done
fi

systemd_bin=
for candidate in /lib/systemd/systemd /usr/lib/systemd/systemd /sbin/init /usr/sbin/init; do
  if [ -x "$candidate" ]; then
    systemd_bin="$candidate"
    break
  fi
done

echo "[ysyx-rootfs] Ubuntu 22.04 rootfs reached"
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
uname -a 2>/dev/null || true

if [ "$init_mode" = systemd ] || { [ "$init_mode" = auto ] && [ -n "$systemd_bin" ]; }; then
  if [ -n "$systemd_bin" ]; then
    echo "[ysyx-rootfs] launching systemd: $systemd_bin"
    exec "$systemd_bin"
  fi
  echo "[ysyx-rootfs] requested systemd but no systemd binary found"
fi

echo "[ysyx-rootfs] probing /bin/sh -c"
/bin/sh -c 'echo "[ysyx-rootfs-sh] /bin/sh -c marker"; exit 0'
sh_probe_rc=$?
echo "[ysyx-rootfs] /bin/sh -c exit=$sh_probe_rc"
echo "[ysyx-rootfs] launching /bin/sh"

exec /bin/sh -i </dev/console >/dev/console 2>&1
INIT
chmod 0755 "$ROOTFS/init"
if [ "$ROOTFS_STATIC_INIT" = "1" ]; then
  # 默认用静态 PID1 承担伪文件系统挂载，再按 cmdline 选择 systemd 或 shell。
  cp "$ROOTFS_INIT_BIN" "$ROOTFS/init"
  chmod 0755 "$ROOTFS/init"
fi
if [ "$ROOTFS_SERIAL_AUTOLOGIN" = "1" ]; then
  for tty in $ROOTFS_SERIAL_AUTOLOGIN_TTYS; do
    dropin_dir="$ROOTFS/etc/systemd/system/serial-getty@${tty}.service.d"
    mkdir -p "$dropin_dir"
    cat > "$dropin_dir/autologin.conf" <<EOF
[Service]
# NEMU/Linux bring-up 需要自动化验证长期 console session；这里只覆盖串口 getty，
# PID1、PAM session、/dev/pts 和真实 Ubuntu 用户态仍然走 systemd 路线。
ExecStart=
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} --keep-baud 115200,57600,38400,9600 %I \$TERM
EOF
  done
fi
for tty in $ROOTFS_SERIAL_MASK_TTYS; do
  mkdir -p "$ROOTFS/etc/systemd/system"
  ln -sfn /dev/null "$ROOTFS/etc/systemd/system/serial-getty@${tty}.service"
done
mkdir -p "$ROOTFS/etc/systemd/system"
# full rootfs 保留 e2fsprogs/e2scrub 工具，但禁用会阻塞 NEMU boot 的在线 scrub 维护任务。
ln -sfn /dev/null "$ROOTFS/etc/systemd/system/e2scrub_reap.service"
ln -sfn /dev/null "$ROOTFS/etc/systemd/system/e2scrub_all.timer"
if [ "$ROOTFS_FLAVOR" = "full" ]; then
  mkdir -p "$ROOTFS/etc/ssh" "$ROOTFS/var/spool/rsyslog"
  if [ ! -f "$ROOTFS/etc/ssh/sshd_config" ]; then
    cat > "$ROOTFS/etc/ssh/sshd_config" <<'EOF'
Include /etc/ssh/sshd_config.d/*.conf
Port 22
PermitRootLogin prohibit-password
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
  fi
  if ! grep -q '^syslog:' "$ROOTFS/etc/group" 2>/dev/null; then
    echo 'syslog:x:101:' >> "$ROOTFS/etc/group"
  fi
  if ! grep -q '^syslog:' "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo 'syslog:x:101:101::/nonexistent:/usr/sbin/nologin' >> "$ROOTFS/etc/passwd"
  fi
  if ! grep -q '^sshd:' "$ROOTFS/etc/group" 2>/dev/null; then
    echo 'sshd:x:102:' >> "$ROOTFS/etc/group"
  fi
  if ! grep -q '^sshd:' "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo 'sshd:x:102:102::/run/sshd:/usr/sbin/nologin' >> "$ROOTFS/etc/passwd"
  fi
  if command -v ssh-keygen >/dev/null 2>&1; then
    ssh-keygen -A -f "$ROOTFS"
  fi
  chown -h 101:101 "$ROOTFS/var/spool/rsyslog" 2>/dev/null || true
  ln -sfn /lib/systemd/system/rsyslog.service "$ROOTFS/etc/systemd/system/syslog.service"
fi

truncate -s "$IMAGE_SIZE" "$IMAGE"
mkfs.ext4 -F -d "$ROOTFS" "$IMAGE"
(cd "$ROOTFS" && find . -print0 | sort -z | cpio --quiet --null -o --format=newc > "$CPIO")
FAKEROOT

  ROOTFS="$ROOTFS" WORK="$WORK" TARBALL="$TARBALL" IMAGE="$IMAGE" CPIO="$CPIO" IMAGE_SIZE="$IMAGE_SIZE" \
    ROOTFS_STATIC_INIT="$ROOTFS_STATIC_INIT" ROOTFS_INIT_BIN="$ROOTFS_INIT_BIN" \
    ROOTFS_PROBE_ENABLE="$ROOTFS_PROBE_ENABLE" ROOTFS_PROBE_BIN="$ROOTFS_PROBE_BIN" \
    ROOTFS_SYSTEMD_OVERLAY="$ROOTFS_SYSTEMD_OVERLAY" \
    ROOTFS_FLAVOR="$ROOTFS_FLAVOR" ROOTFS_FLAVOR_SCRIPT="$ROOTFS_FLAVOR_SCRIPT" \
    ROOTFS_SERIAL_AUTOLOGIN="$ROOTFS_SERIAL_AUTOLOGIN" \
    ROOTFS_SERIAL_AUTOLOGIN_USER="$ROOTFS_SERIAL_AUTOLOGIN_USER" \
    ROOTFS_SERIAL_AUTOLOGIN_TTYS="$ROOTFS_SERIAL_AUTOLOGIN_TTYS" \
    ROOTFS_SERIAL_MASK_TTYS="$ROOTFS_SERIAL_MASK_TTYS" \
    ROOTFS_SYSTEMD_OVERLAY_SCRIPT="$ROOTFS_SYSTEMD_OVERLAY_SCRIPT" \
    fakeroot -- bash "$helper"
}

build_rootfs_static_init
build_rootfs_probe

if can_sudo && command -v debootstrap >/dev/null && command -v qemu-riscv64-static >/dev/null; then
  echo "[ubuntu-rootfs] build via debootstrap"
  build_with_sudo_debootstrap
else
  if [ "$ROOTFS_REQUIRE_SYSTEMD" = "1" ] && [ "$ROOTFS_SYSTEMD_OVERLAY" != "1" ]; then
    echo "[ubuntu-rootfs] UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1, but sudo+debootstrap+qemu-riscv64-static is unavailable" >&2
    echo "[ubuntu-rootfs] 当前 Ubuntu Base + fakeroot 路线不会安装 systemd-sysv/udev/dbus，不能作为完整 systemd rootfs。" >&2
    exit 1
  fi
  echo "[ubuntu-rootfs] build via Ubuntu Base + fakeroot"
  if [ "$ROOTFS_SYSTEMD_OVERLAY" = "1" ]; then
    echo "[ubuntu-rootfs] note: enabling apt/dpkg-deb systemd overlay without chroot second-stage"
  else
    echo "[ubuntu-rootfs] note: Ubuntu Base + fakeroot only proves shell/rootfs gate; systemd packages are not installed"
  fi
  build_with_fakeroot_ubuntu_base
fi

echo "[ubuntu-rootfs] generated: $IMAGE"
echo "[ubuntu-rootfs] generated rootfs cpio: $CPIO"
if [ "$ROOTFS_REQUIRE_SYSTEMD" = "1" ] && [ -f "$SCRIPT_DIR/check-ubuntu-rootfs.sh" ]; then
  UBUNTU_ROOTFS_IMAGE="$IMAGE" UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
    bash "$SCRIPT_DIR/check-ubuntu-rootfs.sh"
fi
echo "[ubuntu-rootfs] 注意：启动该 rootfs 还需要 RTL/仿真侧 virtio-mmio block、host block backend 与 IRQ2 路径。"
