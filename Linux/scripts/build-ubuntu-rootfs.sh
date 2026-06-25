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
ROOTFS_NPC_CONSOLE_SHELL=${UBUNTU_ROOTFS_NPC_CONSOLE_SHELL:-0}
ROOTFS_NPC_TTY_READER=${UBUNTU_ROOTFS_NPC_TTY_READER:-0}
ROOTFS_NPC_TTY_READER_MODE=${UBUNTU_ROOTFS_NPC_TTY_READER_MODE:-line}
ROOTFS_NPC_LOGIN_MARKER=${UBUNTU_ROOTFS_NPC_LOGIN_MARKER:-0}
ROOTFS_NPC_LOGIN_TRACE=${UBUNTU_ROOTFS_NPC_LOGIN_TRACE:-0}
ROOTFS_NPC_GENERATOR_TRACE=${UBUNTU_ROOTFS_NPC_GENERATOR_TRACE:-0}
ROOTFS_NPC_GENERATOR_SKIP=${UBUNTU_ROOTFS_NPC_GENERATOR_SKIP:-}
ROOTFS_NPC_GENERATOR_SKIP_MODE=${UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE:-shell}
ROOTFS_NPC_GENERATOR_REAL_MODE=${UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE:-exec}
ROOTFS_NEMU_LOGIN_MARKER=${UBUNTU_ROOTFS_NEMU_LOGIN_MARKER:-0}
ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE=${UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE:-0}
ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=${UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS:-$ROOTFS_NPC_CONSOLE_SHELL}
FILENAME="ubuntu-base-$VERSION-base-$ARCH.tar.gz"
TARBALL=${UBUNTU_BASE_TARBALL:-"$ENV_ROOT/downloads/$FILENAME"}
SHA_FILE=${UBUNTU_BASE_SHA_FILE:-"$ENV_ROOT/downloads/SHA256SUMS"}
ROOTFS_INIT_SRC=${UBUNTU_ROOTFS_INIT_SRC:-"$LINUX_HOME/tools/ysyx-rootfs-init.c"}
ROOTFS_INIT_BIN=${UBUNTU_ROOTFS_INIT_BIN:-"$WORK/ysyx-rootfs-init"}
ROOTFS_STATIC_INIT=${UBUNTU_ROOTFS_STATIC_INIT:-1}
ROOTFS_PROBE_SRC=${UBUNTU_ROOTFS_PROBE_SRC:-"$LINUX_HOME/tools/ysyx-ubuntu-init.c"}
ROOTFS_PROBE_BIN=${UBUNTU_ROOTFS_PROBE_BIN:-"$WORK/ysyx-rootfs-probe"}
ROOTFS_PROBE_ENABLE=${UBUNTU_ROOTFS_PROBE:-0}
ROOTFS_NPC_TTY_PROBE_SRC=${UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC:-"$LINUX_HOME/tools/ysyx-npc-tty-probe.c"}
ROOTFS_NPC_TTY_PROBE_BIN=${UBUNTU_ROOTFS_NPC_TTY_PROBE_BIN:-"$WORK/ysyx-npc-tty-probe"}
ROOTFS_NPC_GENERATOR_SKIP_SRC=${UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC:-"$LINUX_HOME/tools/ysyx-npc-generator-skip.c"}
ROOTFS_NPC_GENERATOR_SKIP_BIN=${UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_BIN:-"$WORK/ysyx-npc-generator-skip"}
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

npc_tty_probe_mode_required() {
  case "$ROOTFS_NPC_TTY_READER_MODE" in
    c-probe|tty-probe) return 0 ;;
    *) return 1 ;;
  esac
}

build_npc_tty_probe() {
  if ! npc_tty_probe_mode_required; then
    return
  fi
  if [ ! -f "$ROOTFS_NPC_TTY_PROBE_SRC" ]; then
    echo "[ubuntu-rootfs] missing NPC tty probe source: $ROOTFS_NPC_TTY_PROBE_SRC" >&2
    exit 1
  fi
  if ! command -v "$CC" >/dev/null; then
    echo "[ubuntu-rootfs] missing compiler for NPC tty probe: $CC" >&2
    exit 1
  fi
  echo "[ubuntu-rootfs] build NPC tty probe: $ROOTFS_NPC_TTY_PROBE_BIN"
  "$CC" -O2 -Wall -Wextra -static -march=rv64gc -mabi=lp64d \
    -o "$ROOTFS_NPC_TTY_PROBE_BIN" "$ROOTFS_NPC_TTY_PROBE_SRC"
}

npc_generator_static_skip_required() {
  [ "$ROOTFS_NPC_GENERATOR_TRACE" = "1" ] &&
    [ "$ROOTFS_NPC_GENERATOR_SKIP_MODE" = "static" ]
}

build_npc_generator_skip_wrapper() {
  if ! npc_generator_static_skip_required; then
    return
  fi
  if [ ! -f "$ROOTFS_NPC_GENERATOR_SKIP_SRC" ]; then
    echo "[ubuntu-rootfs] missing NPC generator skip source: $ROOTFS_NPC_GENERATOR_SKIP_SRC" >&2
    exit 1
  fi
  if ! command -v "$CC" >/dev/null; then
    echo "[ubuntu-rootfs] missing compiler for NPC generator skip wrapper: $CC" >&2
    exit 1
  fi
  echo "[ubuntu-rootfs] build NPC static generator skip wrapper: $ROOTFS_NPC_GENERATOR_SKIP_BIN"
  "$CC" -Os -ffreestanding -fno-builtin -fno-pic -fno-pie \
    -fno-stack-protector -nostdlib -nostartfiles -static -no-pie \
    -march=rv64imac_zicsr_zifencei -mabi=lp64 -mcmodel=medany \
    -Wl,--no-relax -Wl,--build-id=none -Wl,-e,_start \
    -o "$ROOTFS_NPC_GENERATOR_SKIP_BIN" "$ROOTFS_NPC_GENERATOR_SKIP_SRC"
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
  cat > "$dir/etc/machine-id" <<'EOF'
9f5e2a4d8c7b4a13a6d2e9f001122334
EOF
  mkdir -p "$dir/var/lib/dbus"
  ln -sfn /etc/machine-id "$dir/var/lib/dbus/machine-id"

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

if [ -x /usr/local/sbin/ysyx-npc-console-shell ]; then
  echo "[ysyx-rootfs] starting NPC console shell hook"
  if command -v setsid >/dev/null 2>&1; then
    (setsid -c /usr/local/sbin/ysyx-npc-console-shell || \
      setsid /usr/local/sbin/ysyx-npc-console-shell || \
      /usr/local/sbin/ysyx-npc-console-shell) </dev/console >/dev/console 2>&1 &
  else
    /usr/local/sbin/ysyx-npc-console-shell </dev/console >/dev/console 2>&1 &
  fi
fi

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

install_npc_login_trace_wrapper() {
  local dir=$1
  if [ "${ROOTFS_NPC_LOGIN_TRACE:-0}" != "1" ]; then
    return
  fi

  mkdir -p "$dir/usr/local/sbin"
  cat > "$dir/usr/local/sbin/ysyx-npc-login-trace" <<\EOF
#!/bin/sh
echo "__NPC_LOGIN_TRACE_BEGIN__ argc=$# argv=$*" >/dev/console
echo "__NPC_LOGIN_TRACE_TTY__:$(tty 2>/dev/null || echo unknown)" >/dev/console
echo "__NPC_LOGIN_TRACE_LOGIN_BIN__:$(command -v login 2>/dev/null || echo /bin/login)" >/dev/console
if command -v strace >/dev/null 2>&1; then
  rm -f /run/ysyx-npc-login-strace.*
  strace -ff -qq -s 128 -o /run/ysyx-npc-login-strace /bin/login "$@"
  rc=$?
  echo "__NPC_LOGIN_TRACE_LOGIN_RC__:$rc" >/dev/console
  for f in /run/ysyx-npc-login-strace*; do
    [ -f "$f" ] || continue
    echo "__NPC_LOGIN_TRACE_FILE__:$f" >/dev/console
    tail -n 40 "$f" >/dev/console 2>&1 || true
  done
  exit "$rc"
fi
/bin/login "$@"
rc=$?
echo "__NPC_LOGIN_TRACE_LOGIN_RC__:$rc" >/dev/console
exit "$rc"
EOF
  chmod 0755 "$dir/usr/local/sbin/ysyx-npc-login-trace"
}

install_npc_generator_trace() {
  local dir=$1
  if [ "${ROOTFS_NPC_GENERATOR_TRACE:-0}" != "1" ]; then
    return
  fi

  local gen_dir gen gen_name real_bucket real_root real_gen real_gen_guest skip_list skip_mode has_wrapper
  local stale stale_name stale_real
  skip_list=${ROOTFS_NPC_GENERATOR_SKIP:-}
  skip_mode=${ROOTFS_NPC_GENERATOR_SKIP_MODE:-shell}
  if [ "$skip_mode" = "static" ]; then
    if [ ! -f "${ROOTFS_NPC_GENERATOR_SKIP_BIN:-}" ]; then
      echo "[ubuntu-rootfs] missing NPC static generator skip wrapper: ${ROOTFS_NPC_GENERATOR_SKIP_BIN:-unset}" >&2
      exit 1
    fi
    mkdir -p "$dir/usr/local/sbin" "$dir/etc"
    cp "$ROOTFS_NPC_GENERATOR_SKIP_BIN" "$dir/usr/local/sbin/ysyx-npc-generator-skip"
    chmod 0755 "$dir/usr/local/sbin/ysyx-npc-generator-skip"
    printf '%s\n' "$skip_list" > "$dir/etc/ysyx-npc-generator-skip-list"
    printf '%s\n' "${ROOTFS_NPC_GENERATOR_REAL_MODE:-exec}" > "$dir/etc/ysyx-npc-generator-real-mode"
  fi
  for gen_dir in "$dir/lib/systemd/system-generators" "$dir/usr/lib/systemd/system-generators"; do
    [ -d "$gen_dir" ] || continue
    case "$gen_dir" in
      "$dir/lib/systemd/system-generators") real_bucket=lib ;;
      "$dir/usr/lib/systemd/system-generators") real_bucket=usr-lib ;;
      *) real_bucket=other ;;
    esac
    real_root="$dir/usr/local/lib/ysyx-npc-system-generators/$real_bucket"
    mkdir -p "$real_root"
    for stale in "$gen_dir"/*.ysyx-real; do
      [ -f "$stale" ] || continue
      stale_name=$(basename "$stale" .ysyx-real)
      stale_real="$real_root/$stale_name"
      if [ ! -e "$stale_real" ]; then
        mv "$stale" "$stale_real"
      else
        rm -f "$stale"
      fi
      chmod 0755 "$stale_real" 2>/dev/null || true
    done
    for gen in "$gen_dir"/*; do
      [ -f "$gen" ] || continue
      [ -x "$gen" ] || continue
      case "$gen" in
        *.ysyx-real) continue ;;
      esac
      gen_name=$(basename "$gen")
      real_gen="$real_root/$gen_name"
      real_gen_guest="/usr/local/lib/ysyx-npc-system-generators/$real_bucket/$gen_name"
      has_wrapper=0
      if grep -aq '__NPC_GENERATOR_BEGIN__' "$gen" 2>/dev/null; then
        has_wrapper=1
      fi
      if [ "$has_wrapper" = "1" ] && [ ! -e "$real_gen" ]; then
        continue
      fi
      if [ "$has_wrapper" != "1" ] && [ ! -e "$real_gen" ]; then
        mv "$gen" "$real_gen"
      fi
      if [ "$skip_mode" = "static" ]; then
        cp "$dir/usr/local/sbin/ysyx-npc-generator-skip" "$gen"
        chmod 0755 "$gen"
      else
        cat > "$gen" <<EOF
#!/bin/sh
name="$gen_name"
skip_list="$skip_list"
echo "__NPC_GENERATOR_BEGIN__:\$name argc=\$# argv=\$*" >/dev/console
case " \$skip_list " in
  *" all "*|*" \$name "*)
    echo "__NPC_GENERATOR_SKIP__:\$name match=space-list" >/dev/console
    echo "__NPC_GENERATOR_END__:\$name rc=0 skipped=1" >/dev/console
    exit 0
    ;;
esac
case ",\$skip_list," in
  *,all,*|*,\$name,*)
    echo "__NPC_GENERATOR_SKIP__:\$name match=comma-list" >/dev/console
    echo "__NPC_GENERATOR_END__:\$name rc=0 skipped=1" >/dev/console
    exit 0
    ;;
esac
"$real_gen_guest" "\$@"
rc=\$?
echo "__NPC_GENERATOR_END__:\$name rc=\$rc" >/dev/console
exit "\$rc"
EOF
        chmod 0755 "$gen"
      fi
    done
  done
}

install_serial_autologin() {
  local dir=$1
  if [ "$ROOTFS_SERIAL_AUTOLOGIN" != "1" ]; then
    return
  fi

  for tty in $ROOTFS_SERIAL_AUTOLOGIN_TTYS; do
    local dropin_dir="$dir/etc/systemd/system/serial-getty@${tty}.service.d"
    mkdir -p "$dropin_dir"
    local serial_after="systemd-logind.service systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target rc-local.service"
    local serial_wants="systemd-logind.service"
    if [ "${ROOTFS_NPC_LOGIN_MARKER:-0}" = "1" ]; then
      serial_after="getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service"
      serial_wants=""
    fi
    local login_program_args=""
    if [ "${ROOTFS_NPC_LOGIN_MARKER:-0}" = "1" ] && [ "${ROOTFS_NPC_LOGIN_TRACE:-0}" = "1" ]; then
      install_npc_login_trace_wrapper "$dir"
      login_program_args="--login-program /usr/local/sbin/ysyx-npc-login-trace"
    fi
    cat > "$dropin_dir/autologin.conf" <<EOF
[Unit]
# NPC 的 16550 串口已经作为 kernel console 可用；当前设备模型不会稳定地产生
# dev-ttyS0.device，因此 login gate 不能依赖 systemd device unit。
BindsTo=
Wants=
Wants=${serial_wants}
After=
After=${serial_after}

[Service]
# NEMU/Linux bring-up 需要自动化验证长期 console session；这里只覆盖串口 getty，
# PID1、PAM session、/dev/pts 和真实 Ubuntu 用户态仍然走 systemd 路线。
ExecStart=
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} ${login_program_args} --keep-baud 115200,57600,38400,9600 %I \$TERM
EOF
    if [ "${ROOTFS_NPC_LOGIN_MARKER:-0}" = "1" ]; then
      cat > "$dir/etc/systemd/system/serial-getty@${tty}.service" <<EOF
[Unit]
Description=Serial Getty on %I for NPC login gate
Documentation=man:agetty(8) man:systemd-getty-generator(8)
DefaultDependencies=no
After=getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service
Before=systemd-udev-trigger.service sysinit.target getty.target
IgnoreOnIsolate=yes
Conflicts=rescue.service
Before=rescue.service

[Service]
# Keep the login/PAM path real while avoiding template device and late boot waits on NPC.
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} ${login_program_args} --keep-baud 115200,57600,38400,9600 %I \$TERM
Type=simple
Restart=always
UtmpIdentifier=%I
IgnoreSIGPIPE=no
SendSIGHUP=yes

[Install]
WantedBy=sysinit.target getty.target
EOF
      mkdir -p "$dir/etc/systemd/system/getty.target.wants" "$dir/etc/systemd/system/sysinit.target.wants"
      ln -sfn "../serial-getty@${tty}.service" "$dir/etc/systemd/system/getty.target.wants/serial-getty@${tty}.service"
      ln -sfn "../serial-getty@${tty}.service" "$dir/etc/systemd/system/sysinit.target.wants/serial-getty@${tty}.service"
    fi
  done
}

install_serial_masks() {
  local dir=$1
  for tty in $ROOTFS_SERIAL_MASK_TTYS; do
    mkdir -p "$dir/etc/systemd/system"
    ln -sfn /dev/null "$dir/etc/systemd/system/serial-getty@${tty}.service"
  done
}

install_npc_login_marker() {
  local dir=$1
  if [ "$ROOTFS_NPC_LOGIN_MARKER" != "1" ]; then
    return
  fi

  mkdir -p "$dir/root"
  cat > "$dir/root/.bash_profile" <<'EOF'
# Marker-only profile for NPC serial-getty login/session gates.
if [ "${YSYX_NPC_LOGIN_MARKER_EMITTED:-0}" != "1" ]; then
  export YSYX_NPC_LOGIN_MARKER_EMITTED=1
  echo __NPC_LOGIN_CHECK_BEGIN__
  check_fail=0
  pass() { echo "__NPC_LOGIN_CHECK_PASS__:$1"; }
  fail() { echo "__NPC_LOGIN_CHECK_FAIL__:$1"; check_fail=1; }

  uid="$(id -u 2>/dev/null || echo unknown)"
  tty_path="$(tty 2>/dev/null || echo unknown)"
  pid1_comm=unknown
  [ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
  loginuid=unknown
  [ -r /proc/self/loginuid ] && loginuid="$(cat /proc/self/loginuid 2>/dev/null || echo unknown)"

  echo "__NPC_LOGIN_UID__:$uid"
  echo "__NPC_LOGIN_TTY__:$tty_path"
  echo "__NPC_LOGIN_PID1__:$pid1_comm"
  echo "__NPC_LOGIN_LOGINUID__:$loginuid"

  [ "$uid" = "0" ] && pass root-login || fail root-login
  [ "$tty_path" = "/dev/ttyS0" ] && pass ttyS0-login || fail ttyS0-login
  [ "$pid1_comm" = "systemd" ] && pass pid1-systemd || fail pid1-systemd
  [ -d /run/systemd/system ] && pass systemd-runtime || fail systemd-runtime
  [ -x /bin/login ] && pass login-binary || fail login-binary
  [ -d /lib/riscv64-linux-gnu/security ] && pass pam-module-path || fail pam-module-path

  echo "__NPC_LOGIN_CHECK_DONE__ rc=$check_fail"
fi

[ -r /root/.profile ] && . /root/.profile
EOF
  : > "$dir/root/.hushlogin"
  chmod 0644 "$dir/root/.bash_profile"
  chmod 0644 "$dir/root/.hushlogin"
}

install_npc_login_profile() {
  local dir=$1
  if [ "$ROOTFS_NPC_LOGIN_MARKER" != "1" ]; then
    return
  fi

  if [ -f "$dir/etc/profile" ] && [ ! -f "$dir/etc/profile.ysyx-original" ]; then
    cp -a "$dir/etc/profile" "$dir/etc/profile.ysyx-original"
  fi
  cat > "$dir/etc/profile" <<\EOF
# NPC_LOGIN_MARKER_MINIMAL_ETC_PROFILE
# Keep login-shell startup deterministic on NPC; /root/.bash_profile owns the marker checks.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
if [ -z "${TERM:-}" ]; then
  TERM=vt102
fi
export TERM
EOF
  chmod 0644 "$dir/etc/profile"
}

trim_npc_login_pam() {
  local dir=$1
  if [ "$ROOTFS_NPC_LOGIN_MARKER" != "1" ]; then
    return
  fi

  local pam_login="$dir/etc/pam.d/login"
  if [ ! -f "$pam_login" ]; then
    return
  fi

  # NPC 目前的 full-login gate 只需要真实 agetty/login/PAM/bash 链路。
  # Ubuntu login 的失败延迟/公告/邮箱/lastlog 非核心路径会在 NPC 上触发 glibc
  # longjmp 检查，导致 shell marker 前退出；在专用镜像里禁用它们。
  sed -i \
    -e 's/^\([[:space:]]*auth[[:space:]]\+optional[[:space:]]\+pam_faildelay\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
    -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_motd\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
    -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_lastlog\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
    -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_mail\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
    "$pam_login"
}

install_nemu_login_marker() {
  local dir=$1
  if [ "$ROOTFS_NEMU_LOGIN_MARKER" != "1" ]; then
    return
  fi

  mkdir -p "$dir/root"
  # NEMU 使用 /root/.profile 追加串口登录 marker，避免和 NPC 专用 .bash_profile 互相覆盖。
  if ! grep -q '__NEMU_LOGIN_CHECK_BEGIN__' "$dir/root/.profile" 2>/dev/null; then
    cat >> "$dir/root/.profile" <<'EOF'

# Marker-only profile for NEMU serial-getty login/session gates.
if [ "${YSYX_NEMU_LOGIN_MARKER_EMITTED:-0}" != "1" ]; then
  export YSYX_NEMU_LOGIN_MARKER_EMITTED=1
  echo __NEMU_LOGIN_CHECK_BEGIN__
  check_fail=0
  pass() { echo "__NEMU_LOGIN_CHECK_PASS__:$1"; }
  fail() { echo "__NEMU_LOGIN_CHECK_FAIL__:$1"; check_fail=1; }

  uid="$(id -u 2>/dev/null || echo unknown)"
  tty_path="$(tty 2>/dev/null || echo unknown)"
  pid1_comm=unknown
  [ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
  loginuid=unknown
  [ -r /proc/self/loginuid ] && loginuid="$(cat /proc/self/loginuid 2>/dev/null || echo unknown)"

  echo "__NEMU_LOGIN_UID__:$uid"
  echo "__NEMU_LOGIN_TTY__:$tty_path"
  echo "__NEMU_LOGIN_PID1__:$pid1_comm"
  echo "__NEMU_LOGIN_LOGINUID__:$loginuid"

  [ "$uid" = "0" ] && pass root-login || fail root-login
  [ "$tty_path" = "/dev/ttyS0" ] && pass ttyS0-login || fail ttyS0-login
  [ "$pid1_comm" = "systemd" ] && pass pid1-systemd || fail pid1-systemd
  [ -d /run/systemd/system ] && pass systemd-runtime || fail systemd-runtime
  [ -x /bin/login ] && pass login-binary || fail login-binary
  [ -d /lib/riscv64-linux-gnu/security ] && pass pam-module-path || fail pam-module-path

  echo "__NEMU_LOGIN_CHECK_DONE__ rc=$check_fail"
fi
EOF
  fi
  chmod 0644 "$dir/root/.profile"
}

install_npc_login_boot_profile() {
  local dir=$1
  if [ "$ROOTFS_NPC_LOGIN_MARKER" != "1" ]; then
    return
  fi

  mkdir -p "$dir/etc/systemd/system"
  ln -sfn /lib/systemd/system/multi-user.target "$dir/etc/systemd/system/default.target"

  for unit in \
    plymouth-read-write.service \
    plymouth-start.service \
    plymouth-quit.service \
    plymouth-quit-wait.service; do
    ln -sfn /dev/null "$dir/etc/systemd/system/$unit"
  done
}

preseed_systemd_update_done() {
  local dir=$1
  if [ "${ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE:-0}" != "1" ]; then
    return
  fi
  if ! command -v systemd-sysusers >/dev/null 2>&1; then
    echo "[ubuntu-rootfs] missing host systemd-sysusers for NPC update preseed" >&2
    exit 1
  fi

  echo "[ubuntu-rootfs] preseed systemd sysusers/update-done stamps"
  systemd-sysusers --root="$dir"
  mkdir -p "$dir/etc" "$dir/var"
  touch "$dir/etc/.updated" "$dir/var/.updated"
}

install_nemu_systemd_masks() {
  local dir=$1
  mkdir -p "$dir/etc/systemd/system"
  # e2scrub 的工具本体保留在 full rootfs 中，但在线 ext4 scrub/reap 是宿主维护任务；
  # 在慢速 NEMU guest 中它会阻塞 multi-user.target，不能作为 Ubuntu bring-up 前置。
  ln -sfn /dev/null "$dir/etc/systemd/system/e2scrub_reap.service"
  ln -sfn /dev/null "$dir/etc/systemd/system/e2scrub_all.timer"
}

install_npc_console_shell() {
  local dir=$1
  if [ "$ROOTFS_NPC_CONSOLE_SHELL" != "1" ]; then
    return
  fi

  mkdir -p "$dir/usr/local/sbin" "$dir/etc/systemd/system/sysinit.target.wants"
  case "$ROOTFS_NPC_TTY_READER_MODE" in
    c-probe|tty-probe)
      if [ ! -f "${ROOTFS_NPC_TTY_PROBE_BIN:-}" ]; then
        echo "[ubuntu-rootfs] missing built NPC tty probe: ${ROOTFS_NPC_TTY_PROBE_BIN:-unset}" >&2
        exit 1
      fi
      cp "$ROOTFS_NPC_TTY_PROBE_BIN" "$dir/usr/local/sbin/ysyx-npc-tty-probe"
      chmod 0755 "$dir/usr/local/sbin/ysyx-npc-tty-probe"
      ;;
  esac

  cat > "$dir/usr/local/sbin/ysyx-npc-console-shell" <<'EOF'
#!/bin/sh
export HOME=/root
export USER=root
export LOGNAME=root
export SHELL=/bin/bash
export TERM="${TERM:-vt100}"
export PS1='root@ysyx-ubuntu2204:~# '
cd /root 2>/dev/null || cd /
echo __NPC_CONSOLE_SHELL_READY__
exec /bin/bash --noprofile --norc -i
EOF
  chmod 0755 "$dir/usr/local/sbin/ysyx-npc-console-shell"

  cat > "$dir/usr/local/sbin/ysyx-npc-systemd-autocheck" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo __NPC_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NPC_CHECK_PASS__:$1"; }
fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; }

uname_arch="$(uname -m 2>/dev/null || true)"
echo "__NPC_CHECK_UNAME__:$uname_arch"
[ "$uname_arch" = "riscv64" ] && pass uname-riscv64 || fail uname-riscv64

os_name=0
os_version=0
if [ -r /etc/os-release ]; then
  while IFS= read -r line; do
    case "$line" in
      'NAME="Ubuntu"'|'NAME=Ubuntu') os_name=1 ;;
      'VERSION_ID="22.04"'|'VERSION_ID=22.04') os_version=1 ;;
    esac
  done </etc/os-release
fi
if [ "$os_name" = 1 ] && [ "$os_version" = 1 ]; then
  pass os-release-ubuntu-2204
else
  cat /etc/os-release 2>/dev/null || true
  fail os-release-ubuntu-2204
fi

[ "$(id -u 2>/dev/null)" = "0" ] && pass root-context || fail root-context
[ -x /bin/sh ] && pass bin-sh || fail bin-sh
[ -x /bin/bash ] && pass bin-bash || fail bin-bash

pid1_comm=
[ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
if [ "$pid1_comm" = "systemd" ] && [ -d /run/systemd/system ]; then
  systemd_state=pid1-systemd
else
  systemd_state="pid1-${pid1_comm:-unknown}"
fi
echo "__NPC_CHECK_SYSTEMD_STATE__:$systemd_state"
case "$systemd_state" in
  pid1-systemd|running|degraded|starting|initializing) pass systemd-state ;;
  *) fail systemd-state ;;
esac

echo "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=$check_fail"
EOF
  chmod 0755 "$dir/usr/local/sbin/ysyx-npc-systemd-autocheck"

  cat > "$dir/usr/local/sbin/ysyx-npc-tty-reader" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
export TERM="${TERM:-vt100}"

reader_mode=${YSYX_NPC_TTY_READER_MODE:-line}
echo "__NPC_TTY_READER_MODE__:$reader_mode"
tty_name=$(tty 2>/dev/null || true)
echo "__NPC_TTY_READER_STDIN__:${tty_name:-unknown}"
reader_input=${YSYX_NPC_TTY_READER_INPUT:-$tty_name}
case "$reader_input" in
  /dev/*) ;;
  *) reader_input=/dev/ttyS0 ;;
esac
echo "__NPC_TTY_READER_INPUT__:$reader_input"
if command -v stty >/dev/null 2>&1; then
  stty -a 2>/dev/null | sed 's/^/__NPC_TTY_READER_STTY_BEFORE__:/' || true
fi

print_proc_marker() {
  proc_label=$1
  proc_pid=$2
  proc_stat=$(cat "/proc/$proc_pid/stat" 2>/dev/null || true)
  if [ -n "$proc_stat" ]; then
    proc_after=${proc_stat#*) }
    proc_fd0=$(readlink "/proc/$proc_pid/fd/0" 2>/dev/null || true)
    [ -n "$proc_fd0" ] || proc_fd0=unknown
    set -- $proc_after
    echo "__NPC_TTY_READER_PROC__:$proc_label:pid=$proc_pid state=${1:-?} pgrp=${3:-?} session=${4:-?} tty_nr=${5:-?} tpgid=${6:-?} fd0=$proc_fd0"
  else
    echo "__NPC_TTY_READER_PROC__:$proc_label:pid=$proc_pid missing"
  fi
}

run_line_reader() {
  stty -echo 2>/dev/null || true
  echo __NPC_TTY_READER_READY__
  if IFS= read -r line; then
    printf '__NPC_TTY_READER_LINE__:%s\n' "$line"
    if [ "$line" = "__NPC_TTY_READER_PING__" ]; then
      echo "__NPC_TTY_READER_DONE__ rc=0"
    else
      echo "__NPC_TTY_READER_DONE__ rc=1"
    fi
  else
    echo "__NPC_TTY_READER_DONE__ rc=2"
  fi
}

run_raw_bytes_reader() {
  tmp=/run/ysyx-npc-tty-reader.raw
  err=/run/ysyx-npc-tty-reader.dd.err
  rm -f "$tmp" "$err"
  # 这一模式只取消输入 canonical/echo，保留输出侧行规程，便于继续观察 console marker。
  # time=2 让“无字节进入用户态”在当前 NPC cycle budget 内可见，而不是继续卡到 max-cycle。
  stty -icanon -echo min 0 time 2 2>/dev/null || true
  print_proc_marker shell $$
  if command -v stty >/dev/null 2>&1; then
    stty -a 2>/dev/null | sed 's/^/__NPC_TTY_READER_STTY_RAW__:/' || true
  fi
  echo __NPC_TTY_READER_READY__
  dd_rc=0
  dd_watchdog=0
  case "$reader_mode" in raw-proc|raw-proc-fast) dd_watchdog=1 ;; esac
  if [ "$dd_watchdog" = "1" ]; then
    dd if="$reader_input" bs=1 count=24 of="$tmp" 2>"$err" &
    dd_pid=$!
    echo "__NPC_TTY_READER_DD_PID__:$dd_pid"
    dd_sample=0
    dd_limit=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SAMPLES:-8}
    dd_sleep=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SLEEP:-0.2}
    if [ "$reader_mode" = "raw-proc-fast" ]; then
      dd_limit=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SAMPLES:-64}
      dd_sleep=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SLEEP:-0}
    fi
    while kill -0 "$dd_pid" 2>/dev/null; do
      print_proc_marker dd "$dd_pid"
      dd_sample=$((dd_sample + 1))
      [ "$dd_sample" -ge "$dd_limit" ] && break
      if [ "$dd_sleep" != "0" ]; then
        sleep "$dd_sleep" 2>/dev/null || sleep 1
      fi
    done
    if kill -0 "$dd_pid" 2>/dev/null; then
      echo "__NPC_TTY_READER_DD_TIMEOUT__:samples=$dd_sample"
      kill "$dd_pid" 2>/dev/null || true
      wait "$dd_pid" 2>/dev/null || true
      dd_rc=124
    else
      wait "$dd_pid"
      dd_rc=$?
    fi
  else
    dd if="$reader_input" bs=1 count=24 of="$tmp" 2>"$err"
    dd_rc=$?
  fi
  if [ "$dd_rc" = 0 ]; then
    set -- $(wc -c <"$tmp" 2>/dev/null || echo 0)
    bytes=${1:-0}
    hex=
    if command -v od >/dev/null 2>&1; then
      for byte in $(od -An -tx1 -v "$tmp" 2>/dev/null); do
        hex="${hex}${hex:+ }$byte"
      done
    fi
    payload=$(cat "$tmp" 2>/dev/null || true)
    echo "__NPC_TTY_READER_BYTES__:$bytes"
    echo "__NPC_TTY_READER_HEX__:$hex"
    printf '__NPC_TTY_READER_LINE__:%s\n' "$payload"
    if [ "$payload" = "__NPC_TTY_READER_PING__" ]; then
      echo "__NPC_TTY_READER_DONE__ rc=0"
    else
      echo "__NPC_TTY_READER_DONE__ rc=3"
    fi
  else
    echo "__NPC_TTY_READER_DD_RC__:$dd_rc"
    sed 's/^/__NPC_TTY_READER_DD_ERR__:/' "$err" 2>/dev/null || true
    if [ "$dd_rc" = 124 ]; then
      echo "__NPC_TTY_READER_DONE__ rc=4"
    else
      echo "__NPC_TTY_READER_DONE__ rc=2"
    fi
  fi
}

run_c_probe_reader() {
  if [ ! -x /usr/local/sbin/ysyx-npc-tty-probe ]; then
    echo "__NPC_TTY_READER_C_PROBE_MISSING__"
    echo "__NPC_TTY_READER_DONE__ rc=5"
    return
  fi
  print_proc_marker shell $$
  /usr/local/sbin/ysyx-npc-tty-probe "$reader_input"
}

case "$reader_mode" in
  c-probe|tty-probe) run_c_probe_reader ;;
  raw|raw-bytes|raw-proc|raw-proc-fast) run_raw_bytes_reader ;;
  *) run_line_reader ;;
esac
EOF
  chmod 0755 "$dir/usr/local/sbin/ysyx-npc-tty-reader"

  cat > "$dir/usr/local/sbin/ysyx-npc-systemd-wrapper" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo "[ysyx-npc-systemd-wrapper] begin"

systemd_bin=
for candidate in /lib/systemd/systemd /usr/lib/systemd/systemd /sbin/init /usr/sbin/init; do
  if [ -x "$candidate" ]; then
    systemd_bin="$candidate"
    break
  fi
done

echo __NPC_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NPC_CHECK_PASS__:$1"; }
fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; }

os_name=0
os_version=0
if [ -r /etc/os-release ]; then
  while IFS= read -r line; do
    case "$line" in
      'NAME="Ubuntu"'|'NAME=Ubuntu') os_name=1 ;;
      'VERSION_ID="22.04"'|'VERSION_ID=22.04') os_version=1 ;;
    esac
  done </etc/os-release
fi
[ "$os_name" = 1 ] && [ "$os_version" = 1 ] && pass os-release-ubuntu-2204 || fail os-release-ubuntu-2204
[ -x /bin/sh ] && pass bin-sh || fail bin-sh
[ -x /bin/bash ] && pass bin-bash || fail bin-bash
[ -n "$systemd_bin" ] && pass systemd-binary || fail systemd-binary
[ -x /usr/local/sbin/ysyx-npc-systemd-autocheck ] && pass systemd-autocheck-script || fail systemd-autocheck-script
echo "__NPC_CHECK_SYSTEMD_STATE__:wrapper-pre-systemd"
pass systemd-wrapper-preflight
echo "__NPC_SYSTEMD_CHECK_DONE__ rc=$check_fail"

if [ -n "$systemd_bin" ]; then
  echo "[ysyx-npc-systemd-wrapper] console prompt marker"
  printf 'root@ysyx-ubuntu2204:~# '
  echo "[ysyx-npc-systemd-wrapper] exec systemd: $systemd_bin"
  exec "$systemd_bin"
fi

echo "[ysyx-npc-systemd-wrapper] no systemd binary found; fallback shell"
exec /bin/sh -i </dev/console >/dev/console 2>&1
EOF
  chmod 0755 "$dir/usr/local/sbin/ysyx-npc-systemd-wrapper"

  cat > "$dir/etc/systemd/system/ysyx-npc-systemd-autocheck.service" <<'EOF'
[Unit]
Description=YSYX NPC systemd guest autocheck
DefaultDependencies=no
After=ysyx-npc-console-shell.service ysyx-npc-tty-reader.service
Before=systemd-journald.service systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/usr/local/sbin/ysyx-npc-systemd-autocheck

[Service]
Type=oneshot
StandardInput=null
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=/usr/local/sbin/ysyx-npc-systemd-autocheck
TimeoutStartSec=0

[Install]
WantedBy=sysinit.target
EOF
  ln -sfn ../ysyx-npc-systemd-autocheck.service "$dir/etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-autocheck.service"

  cat > "$dir/etc/systemd/system/ysyx-npc-tty-reader.service" <<'EOF'
[Unit]
Description=YSYX NPC ttyS0 input reader diagnostic
DefaultDependencies=no
Before=ysyx-npc-systemd-autocheck.service systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/dev/ttyS0
ConditionPathExists=/usr/local/sbin/ysyx-npc-tty-reader

[Service]
Type=oneshot
Environment=TERM=vt100
Environment=YSYX_NPC_TTY_READER_MODE=__NPC_TTY_READER_MODE__
WorkingDirectory=/root
StandardInput=tty-force
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=/usr/local/sbin/ysyx-npc-tty-reader
Restart=no
TimeoutStartSec=0

[Install]
WantedBy=sysinit.target
EOF
  sed -i "s/__NPC_TTY_READER_MODE__/$ROOTFS_NPC_TTY_READER_MODE/g" "$dir/etc/systemd/system/ysyx-npc-tty-reader.service"

  cat > "$dir/etc/systemd/system/ysyx-npc-console-shell.service" <<'EOF'
[Unit]
Description=YSYX NPC automated root console shell
DefaultDependencies=no
Before=systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/dev/ttyS0

[Service]
Type=simple
Environment=TERM=vt100
WorkingDirectory=/root
StandardInput=tty-force
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=-/usr/local/sbin/ysyx-npc-console-shell
Restart=always
RestartSec=0

[Install]
WantedBy=sysinit.target
EOF
  if [ "$ROOTFS_NPC_TTY_READER" = "1" ]; then
    rm -f "$dir/etc/systemd/system/sysinit.target.wants/ysyx-npc-console-shell.service"
    ln -sfn ../ysyx-npc-tty-reader.service "$dir/etc/systemd/system/sysinit.target.wants/ysyx-npc-tty-reader.service"
  else
    rm -f "$dir/etc/systemd/system/sysinit.target.wants/ysyx-npc-tty-reader.service"
    ln -sfn ../ysyx-npc-console-shell.service "$dir/etc/systemd/system/sysinit.target.wants/ysyx-npc-console-shell.service"
  fi

  if [ "$ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS" = "1" ]; then
    mkdir -p "$dir/usr/local/share/ysyx-disabled-system-generators" "$dir/lib/systemd/system-generators"
    for generator in "$dir"/lib/systemd/system-generators/*; do
      [ -e "$generator" ] || continue
      mv "$generator" "$dir/usr/local/share/ysyx-disabled-system-generators/"
    done
  fi
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
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_login_trace_wrapper); $(declare -f install_serial_autologin); ROOTFS_SERIAL_AUTOLOGIN='$ROOTFS_SERIAL_AUTOLOGIN' ROOTFS_SERIAL_AUTOLOGIN_USER='$ROOTFS_SERIAL_AUTOLOGIN_USER' ROOTFS_SERIAL_AUTOLOGIN_TTYS='$ROOTFS_SERIAL_AUTOLOGIN_TTYS' ROOTFS_NPC_LOGIN_MARKER='$ROOTFS_NPC_LOGIN_MARKER' ROOTFS_NPC_LOGIN_TRACE='$ROOTFS_NPC_LOGIN_TRACE' install_serial_autologin '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_serial_masks); ROOTFS_SERIAL_MASK_TTYS='$ROOTFS_SERIAL_MASK_TTYS' install_serial_masks '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_login_marker); ROOTFS_NPC_LOGIN_MARKER='$ROOTFS_NPC_LOGIN_MARKER' install_npc_login_marker '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f trim_npc_login_pam); ROOTFS_NPC_LOGIN_MARKER='$ROOTFS_NPC_LOGIN_MARKER' trim_npc_login_pam '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_login_profile); ROOTFS_NPC_LOGIN_MARKER='$ROOTFS_NPC_LOGIN_MARKER' install_npc_login_profile '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_nemu_login_marker); ROOTFS_NEMU_LOGIN_MARKER='$ROOTFS_NEMU_LOGIN_MARKER' install_nemu_login_marker '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_login_boot_profile); ROOTFS_NPC_LOGIN_MARKER='$ROOTFS_NPC_LOGIN_MARKER' install_npc_login_boot_profile '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_nemu_systemd_masks); install_nemu_systemd_masks '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_console_shell); ROOTFS_NPC_CONSOLE_SHELL='$ROOTFS_NPC_CONSOLE_SHELL' ROOTFS_NPC_TTY_READER='$ROOTFS_NPC_TTY_READER' ROOTFS_NPC_TTY_READER_MODE='$ROOTFS_NPC_TTY_READER_MODE' ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS='$ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS' install_npc_console_shell '$ROOTFS'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_full_runtime_defaults); install_full_runtime_defaults '$ROOTFS' '$ROOTFS_FLAVOR'"
  "${sudo_cmd[@]}" bash -c "$(declare -f install_npc_generator_trace); ROOTFS_NPC_GENERATOR_TRACE='$ROOTFS_NPC_GENERATOR_TRACE' ROOTFS_NPC_GENERATOR_SKIP='$ROOTFS_NPC_GENERATOR_SKIP' ROOTFS_NPC_GENERATOR_SKIP_MODE='$ROOTFS_NPC_GENERATOR_SKIP_MODE' ROOTFS_NPC_GENERATOR_REAL_MODE='$ROOTFS_NPC_GENERATOR_REAL_MODE' ROOTFS_NPC_GENERATOR_SKIP_BIN='$ROOTFS_NPC_GENERATOR_SKIP_BIN' install_npc_generator_trace '$ROOTFS'"
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
  "${sudo_cmd[@]}" bash -c "$(declare -f preseed_systemd_update_done); ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE='$ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE' preseed_systemd_update_done '$ROOTFS'"
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
cat > "$ROOTFS/etc/machine-id" <<'EOF'
9f5e2a4d8c7b4a13a6d2e9f001122334
EOF
mkdir -p "$ROOTFS/var/lib/dbus"
ln -sfn /etc/machine-id "$ROOTFS/var/lib/dbus/machine-id"

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

if [ -x /usr/local/sbin/ysyx-npc-console-shell ]; then
  echo "[ysyx-rootfs] starting NPC console shell hook"
  if command -v setsid >/dev/null 2>&1; then
    (setsid -c /usr/local/sbin/ysyx-npc-console-shell || \
      setsid /usr/local/sbin/ysyx-npc-console-shell || \
      /usr/local/sbin/ysyx-npc-console-shell) </dev/console >/dev/console 2>&1 &
  else
    /usr/local/sbin/ysyx-npc-console-shell </dev/console >/dev/console 2>&1 &
  fi
fi

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
if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ] && [ "$ROOTFS_NPC_LOGIN_TRACE" = "1" ]; then
  mkdir -p "$ROOTFS/usr/local/sbin"
  cat > "$ROOTFS/usr/local/sbin/ysyx-npc-login-trace" <<\EOF
#!/bin/sh
echo "__NPC_LOGIN_TRACE_BEGIN__ argc=$# argv=$*" >/dev/console
echo "__NPC_LOGIN_TRACE_TTY__:$(tty 2>/dev/null || echo unknown)" >/dev/console
echo "__NPC_LOGIN_TRACE_LOGIN_BIN__:$(command -v login 2>/dev/null || echo /bin/login)" >/dev/console
if command -v strace >/dev/null 2>&1; then
  rm -f /run/ysyx-npc-login-strace.*
  strace -ff -qq -s 128 -o /run/ysyx-npc-login-strace /bin/login "$@"
  rc=$?
  echo "__NPC_LOGIN_TRACE_LOGIN_RC__:$rc" >/dev/console
  for f in /run/ysyx-npc-login-strace*; do
    [ -f "$f" ] || continue
    echo "__NPC_LOGIN_TRACE_FILE__:$f" >/dev/console
    tail -n 40 "$f" >/dev/console 2>&1 || true
  done
  exit "$rc"
fi
/bin/login "$@"
rc=$?
echo "__NPC_LOGIN_TRACE_LOGIN_RC__:$rc" >/dev/console
exit "$rc"
EOF
  chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-login-trace"
fi
if [ "$ROOTFS_SERIAL_AUTOLOGIN" = "1" ]; then
  for tty in $ROOTFS_SERIAL_AUTOLOGIN_TTYS; do
    dropin_dir="$ROOTFS/etc/systemd/system/serial-getty@${tty}.service.d"
    mkdir -p "$dropin_dir"
    serial_after="systemd-logind.service systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target rc-local.service"
    serial_wants="systemd-logind.service"
    if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ]; then
      serial_after="getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service"
      serial_wants=""
    fi
    login_program_args=""
    if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ] && [ "$ROOTFS_NPC_LOGIN_TRACE" = "1" ]; then
      login_program_args="--login-program /usr/local/sbin/ysyx-npc-login-trace"
    fi
    cat > "$dropin_dir/autologin.conf" <<EOF
[Unit]
# NPC 的 16550 串口已经作为 kernel console 可用；当前设备模型不会稳定地产生
# dev-ttyS0.device，因此 login gate 不能依赖 systemd device unit。
BindsTo=
Wants=
Wants=${serial_wants}
After=
After=${serial_after}

[Service]
# NEMU/Linux bring-up 需要自动化验证长期 console session；这里只覆盖串口 getty，
# PID1、PAM session、/dev/pts 和真实 Ubuntu 用户态仍然走 systemd 路线。
ExecStart=
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} ${login_program_args} --keep-baud 115200,57600,38400,9600 %I \$TERM
EOF
    if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ]; then
      cat > "$ROOTFS/etc/systemd/system/serial-getty@${tty}.service" <<EOF
[Unit]
Description=Serial Getty on %I for NPC login gate
Documentation=man:agetty(8) man:systemd-getty-generator(8)
DefaultDependencies=no
After=getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service
Before=systemd-udev-trigger.service sysinit.target getty.target
IgnoreOnIsolate=yes
Conflicts=rescue.service
Before=rescue.service

[Service]
# Keep the login/PAM path real while avoiding template device and late boot waits on NPC.
ExecStart=-/sbin/agetty --autologin ${ROOTFS_SERIAL_AUTOLOGIN_USER} ${login_program_args} --keep-baud 115200,57600,38400,9600 %I \$TERM
Type=simple
Restart=always
UtmpIdentifier=%I
IgnoreSIGPIPE=no
SendSIGHUP=yes

[Install]
WantedBy=sysinit.target getty.target
EOF
      mkdir -p "$ROOTFS/etc/systemd/system/getty.target.wants" "$ROOTFS/etc/systemd/system/sysinit.target.wants"
      ln -sfn "../serial-getty@${tty}.service" "$ROOTFS/etc/systemd/system/getty.target.wants/serial-getty@${tty}.service"
      ln -sfn "../serial-getty@${tty}.service" "$ROOTFS/etc/systemd/system/sysinit.target.wants/serial-getty@${tty}.service"
    fi
  done
fi
for tty in $ROOTFS_SERIAL_MASK_TTYS; do
  mkdir -p "$ROOTFS/etc/systemd/system"
  ln -sfn /dev/null "$ROOTFS/etc/systemd/system/serial-getty@${tty}.service"
done
if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ]; then
  mkdir -p "$ROOTFS/root"
  cat > "$ROOTFS/root/.bash_profile" <<'EOF'
# Marker-only profile for NPC serial-getty login/session gates.
if [ "${YSYX_NPC_LOGIN_MARKER_EMITTED:-0}" != "1" ]; then
  export YSYX_NPC_LOGIN_MARKER_EMITTED=1
  echo __NPC_LOGIN_CHECK_BEGIN__
  check_fail=0
  pass() { echo "__NPC_LOGIN_CHECK_PASS__:$1"; }
  fail() { echo "__NPC_LOGIN_CHECK_FAIL__:$1"; check_fail=1; }

  uid="$(id -u 2>/dev/null || echo unknown)"
  tty_path="$(tty 2>/dev/null || echo unknown)"
  pid1_comm=unknown
  [ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
  loginuid=unknown
  [ -r /proc/self/loginuid ] && loginuid="$(cat /proc/self/loginuid 2>/dev/null || echo unknown)"

  echo "__NPC_LOGIN_UID__:$uid"
  echo "__NPC_LOGIN_TTY__:$tty_path"
  echo "__NPC_LOGIN_PID1__:$pid1_comm"
  echo "__NPC_LOGIN_LOGINUID__:$loginuid"

  [ "$uid" = "0" ] && pass root-login || fail root-login
  [ "$tty_path" = "/dev/ttyS0" ] && pass ttyS0-login || fail ttyS0-login
  [ "$pid1_comm" = "systemd" ] && pass pid1-systemd || fail pid1-systemd
  [ -d /run/systemd/system ] && pass systemd-runtime || fail systemd-runtime
  [ -x /bin/login ] && pass login-binary || fail login-binary
  [ -d /lib/riscv64-linux-gnu/security ] && pass pam-module-path || fail pam-module-path

  echo "__NPC_LOGIN_CHECK_DONE__ rc=$check_fail"
fi

[ -r /root/.profile ] && . /root/.profile
EOF
  : > "$ROOTFS/root/.hushlogin"
  chmod 0644 "$ROOTFS/root/.bash_profile"
  chmod 0644 "$ROOTFS/root/.hushlogin"
  if [ -f "$ROOTFS/etc/profile" ] && [ ! -f "$ROOTFS/etc/profile.ysyx-original" ]; then
    cp -a "$ROOTFS/etc/profile" "$ROOTFS/etc/profile.ysyx-original"
  fi
  cat > "$ROOTFS/etc/profile" <<\EOF
# NPC_LOGIN_MARKER_MINIMAL_ETC_PROFILE
# Keep login-shell startup deterministic on NPC; /root/.bash_profile owns the marker checks.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
if [ -z "${TERM:-}" ]; then
  TERM=vt102
fi
export TERM
EOF
  chmod 0644 "$ROOTFS/etc/profile"
  if [ -f "$ROOTFS/etc/pam.d/login" ]; then
    sed -i \
      -e 's/^\([[:space:]]*auth[[:space:]]\+optional[[:space:]]\+pam_faildelay\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
      -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_motd\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
      -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_lastlog\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
      -e 's/^\([[:space:]]*session[[:space:]]\+optional[[:space:]]\+pam_mail\.so.*\)$/# NPC_LOGIN_MARKER_DISABLED \1/' \
      "$ROOTFS/etc/pam.d/login"
  fi
fi
if [ "$ROOTFS_NEMU_LOGIN_MARKER" = "1" ]; then
  mkdir -p "$ROOTFS/root"
  # NEMU marker 追加到 .profile；NPC .bash_profile 会在末尾 source 它，二者保持隔离。
  if ! grep -q '__NEMU_LOGIN_CHECK_BEGIN__' "$ROOTFS/root/.profile" 2>/dev/null; then
    cat >> "$ROOTFS/root/.profile" <<'EOF'

# Marker-only profile for NEMU serial-getty login/session gates.
if [ "${YSYX_NEMU_LOGIN_MARKER_EMITTED:-0}" != "1" ]; then
  export YSYX_NEMU_LOGIN_MARKER_EMITTED=1
  echo __NEMU_LOGIN_CHECK_BEGIN__
  check_fail=0
  pass() { echo "__NEMU_LOGIN_CHECK_PASS__:$1"; }
  fail() { echo "__NEMU_LOGIN_CHECK_FAIL__:$1"; check_fail=1; }

  uid="$(id -u 2>/dev/null || echo unknown)"
  tty_path="$(tty 2>/dev/null || echo unknown)"
  pid1_comm=unknown
  [ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
  loginuid=unknown
  [ -r /proc/self/loginuid ] && loginuid="$(cat /proc/self/loginuid 2>/dev/null || echo unknown)"

  echo "__NEMU_LOGIN_UID__:$uid"
  echo "__NEMU_LOGIN_TTY__:$tty_path"
  echo "__NEMU_LOGIN_PID1__:$pid1_comm"
  echo "__NEMU_LOGIN_LOGINUID__:$loginuid"

  [ "$uid" = "0" ] && pass root-login || fail root-login
  [ "$tty_path" = "/dev/ttyS0" ] && pass ttyS0-login || fail ttyS0-login
  [ "$pid1_comm" = "systemd" ] && pass pid1-systemd || fail pid1-systemd
  [ -d /run/systemd/system ] && pass systemd-runtime || fail systemd-runtime
  [ -x /bin/login ] && pass login-binary || fail login-binary
  [ -d /lib/riscv64-linux-gnu/security ] && pass pam-module-path || fail pam-module-path

  echo "__NEMU_LOGIN_CHECK_DONE__ rc=$check_fail"
fi
EOF
  fi
  chmod 0644 "$ROOTFS/root/.profile"
fi
if [ "$ROOTFS_NPC_LOGIN_MARKER" = "1" ]; then
  mkdir -p "$ROOTFS/etc/systemd/system"
  ln -sfn /lib/systemd/system/multi-user.target "$ROOTFS/etc/systemd/system/default.target"
  for unit in \
    plymouth-read-write.service \
    plymouth-start.service \
    plymouth-quit.service \
    plymouth-quit-wait.service; do
    ln -sfn /dev/null "$ROOTFS/etc/systemd/system/$unit"
  done
fi
mkdir -p "$ROOTFS/etc/systemd/system"
# full rootfs 保留 e2fsprogs/e2scrub 工具，但禁用会阻塞 NEMU boot 的在线 scrub 维护任务。
ln -sfn /dev/null "$ROOTFS/etc/systemd/system/e2scrub_reap.service"
ln -sfn /dev/null "$ROOTFS/etc/systemd/system/e2scrub_all.timer"
if [ "$ROOTFS_NPC_CONSOLE_SHELL" = "1" ]; then
  mkdir -p "$ROOTFS/usr/local/sbin" "$ROOTFS/etc/systemd/system/sysinit.target.wants"
  case "$ROOTFS_NPC_TTY_READER_MODE" in
    c-probe|tty-probe)
      if [ ! -f "${ROOTFS_NPC_TTY_PROBE_BIN:-}" ]; then
        echo "[ubuntu-rootfs] missing built NPC tty probe: ${ROOTFS_NPC_TTY_PROBE_BIN:-unset}" >&2
        exit 1
      fi
      cp "$ROOTFS_NPC_TTY_PROBE_BIN" "$ROOTFS/usr/local/sbin/ysyx-npc-tty-probe"
      chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-tty-probe"
      ;;
  esac

  cat > "$ROOTFS/usr/local/sbin/ysyx-npc-console-shell" <<'EOF'
#!/bin/sh
export HOME=/root
export USER=root
export LOGNAME=root
export SHELL=/bin/bash
export TERM="${TERM:-vt100}"
export PS1='root@ysyx-ubuntu2204:~# '
cd /root 2>/dev/null || cd /
echo __NPC_CONSOLE_SHELL_READY__
exec /bin/bash --noprofile --norc -i
EOF
  chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-console-shell"
  cat > "$ROOTFS/usr/local/sbin/ysyx-npc-systemd-autocheck" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo __NPC_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NPC_CHECK_PASS__:$1"; }
fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; }

uname_arch="$(uname -m 2>/dev/null || true)"
echo "__NPC_CHECK_UNAME__:$uname_arch"
[ "$uname_arch" = "riscv64" ] && pass uname-riscv64 || fail uname-riscv64

os_name=0
os_version=0
if [ -r /etc/os-release ]; then
  while IFS= read -r line; do
    case "$line" in
      'NAME="Ubuntu"'|'NAME=Ubuntu') os_name=1 ;;
      'VERSION_ID="22.04"'|'VERSION_ID=22.04') os_version=1 ;;
    esac
  done </etc/os-release
fi
if [ "$os_name" = 1 ] && [ "$os_version" = 1 ]; then
  pass os-release-ubuntu-2204
else
  cat /etc/os-release 2>/dev/null || true
  fail os-release-ubuntu-2204
fi

[ "$(id -u 2>/dev/null)" = "0" ] && pass root-context || fail root-context
[ -x /bin/sh ] && pass bin-sh || fail bin-sh
[ -x /bin/bash ] && pass bin-bash || fail bin-bash

pid1_comm=
[ -r /proc/1/comm ] && IFS= read -r pid1_comm </proc/1/comm || true
if [ "$pid1_comm" = "systemd" ] && [ -d /run/systemd/system ]; then
  systemd_state=pid1-systemd
else
  systemd_state="pid1-${pid1_comm:-unknown}"
fi
echo "__NPC_CHECK_SYSTEMD_STATE__:$systemd_state"
case "$systemd_state" in
  pid1-systemd|running|degraded|starting|initializing) pass systemd-state ;;
  *) fail systemd-state ;;
esac

echo "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=$check_fail"
EOF
  chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-systemd-autocheck"
  cat > "$ROOTFS/usr/local/sbin/ysyx-npc-tty-reader" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
export TERM="${TERM:-vt100}"

reader_mode=${YSYX_NPC_TTY_READER_MODE:-line}
echo "__NPC_TTY_READER_MODE__:$reader_mode"
tty_name=$(tty 2>/dev/null || true)
echo "__NPC_TTY_READER_STDIN__:${tty_name:-unknown}"
reader_input=${YSYX_NPC_TTY_READER_INPUT:-$tty_name}
case "$reader_input" in
  /dev/*) ;;
  *) reader_input=/dev/ttyS0 ;;
esac
echo "__NPC_TTY_READER_INPUT__:$reader_input"
if command -v stty >/dev/null 2>&1; then
  stty -a 2>/dev/null | sed 's/^/__NPC_TTY_READER_STTY_BEFORE__:/' || true
fi

print_proc_marker() {
  proc_label=$1
  proc_pid=$2
  proc_stat=$(cat "/proc/$proc_pid/stat" 2>/dev/null || true)
  if [ -n "$proc_stat" ]; then
    proc_after=${proc_stat#*) }
    proc_fd0=$(readlink "/proc/$proc_pid/fd/0" 2>/dev/null || true)
    [ -n "$proc_fd0" ] || proc_fd0=unknown
    set -- $proc_after
    echo "__NPC_TTY_READER_PROC__:$proc_label:pid=$proc_pid state=${1:-?} pgrp=${3:-?} session=${4:-?} tty_nr=${5:-?} tpgid=${6:-?} fd0=$proc_fd0"
  else
    echo "__NPC_TTY_READER_PROC__:$proc_label:pid=$proc_pid missing"
  fi
}

run_line_reader() {
  stty -echo 2>/dev/null || true
  echo __NPC_TTY_READER_READY__
  if IFS= read -r line; then
    printf '__NPC_TTY_READER_LINE__:%s\n' "$line"
    if [ "$line" = "__NPC_TTY_READER_PING__" ]; then
      echo "__NPC_TTY_READER_DONE__ rc=0"
    else
      echo "__NPC_TTY_READER_DONE__ rc=1"
    fi
  else
    echo "__NPC_TTY_READER_DONE__ rc=2"
  fi
}

run_raw_bytes_reader() {
  tmp=/run/ysyx-npc-tty-reader.raw
  err=/run/ysyx-npc-tty-reader.dd.err
  rm -f "$tmp" "$err"
  # 这一模式只取消输入 canonical/echo，保留输出侧行规程，便于继续观察 console marker。
  # time=2 让“无字节进入用户态”在当前 NPC cycle budget 内可见，而不是继续卡到 max-cycle。
  stty -icanon -echo min 0 time 2 2>/dev/null || true
  print_proc_marker shell $$
  if command -v stty >/dev/null 2>&1; then
    stty -a 2>/dev/null | sed 's/^/__NPC_TTY_READER_STTY_RAW__:/' || true
  fi
  echo __NPC_TTY_READER_READY__
  dd_rc=0
  dd_watchdog=0
  case "$reader_mode" in raw-proc|raw-proc-fast) dd_watchdog=1 ;; esac
  if [ "$dd_watchdog" = "1" ]; then
    dd if="$reader_input" bs=1 count=24 of="$tmp" 2>"$err" &
    dd_pid=$!
    echo "__NPC_TTY_READER_DD_PID__:$dd_pid"
    dd_sample=0
    dd_limit=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SAMPLES:-8}
    dd_sleep=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SLEEP:-0.2}
    if [ "$reader_mode" = "raw-proc-fast" ]; then
      dd_limit=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SAMPLES:-64}
      dd_sleep=${YSYX_NPC_TTY_READER_DD_WATCHDOG_SLEEP:-0}
    fi
    while kill -0 "$dd_pid" 2>/dev/null; do
      print_proc_marker dd "$dd_pid"
      dd_sample=$((dd_sample + 1))
      [ "$dd_sample" -ge "$dd_limit" ] && break
      if [ "$dd_sleep" != "0" ]; then
        sleep "$dd_sleep" 2>/dev/null || sleep 1
      fi
    done
    if kill -0 "$dd_pid" 2>/dev/null; then
      echo "__NPC_TTY_READER_DD_TIMEOUT__:samples=$dd_sample"
      kill "$dd_pid" 2>/dev/null || true
      wait "$dd_pid" 2>/dev/null || true
      dd_rc=124
    else
      wait "$dd_pid"
      dd_rc=$?
    fi
  else
    dd if="$reader_input" bs=1 count=24 of="$tmp" 2>"$err"
    dd_rc=$?
  fi
  if [ "$dd_rc" = 0 ]; then
    set -- $(wc -c <"$tmp" 2>/dev/null || echo 0)
    bytes=${1:-0}
    hex=
    if command -v od >/dev/null 2>&1; then
      for byte in $(od -An -tx1 -v "$tmp" 2>/dev/null); do
        hex="${hex}${hex:+ }$byte"
      done
    fi
    payload=$(cat "$tmp" 2>/dev/null || true)
    echo "__NPC_TTY_READER_BYTES__:$bytes"
    echo "__NPC_TTY_READER_HEX__:$hex"
    printf '__NPC_TTY_READER_LINE__:%s\n' "$payload"
    if [ "$payload" = "__NPC_TTY_READER_PING__" ]; then
      echo "__NPC_TTY_READER_DONE__ rc=0"
    else
      echo "__NPC_TTY_READER_DONE__ rc=3"
    fi
  else
    echo "__NPC_TTY_READER_DD_RC__:$dd_rc"
    sed 's/^/__NPC_TTY_READER_DD_ERR__:/' "$err" 2>/dev/null || true
    if [ "$dd_rc" = 124 ]; then
      echo "__NPC_TTY_READER_DONE__ rc=4"
    else
      echo "__NPC_TTY_READER_DONE__ rc=2"
    fi
  fi
}

run_c_probe_reader() {
  if [ ! -x /usr/local/sbin/ysyx-npc-tty-probe ]; then
    echo "__NPC_TTY_READER_C_PROBE_MISSING__"
    echo "__NPC_TTY_READER_DONE__ rc=5"
    return
  fi
  print_proc_marker shell $$
  /usr/local/sbin/ysyx-npc-tty-probe "$reader_input"
}

case "$reader_mode" in
  c-probe|tty-probe) run_c_probe_reader ;;
  raw|raw-bytes|raw-proc|raw-proc-fast) run_raw_bytes_reader ;;
  *) run_line_reader ;;
esac
EOF
  chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-tty-reader"
  cat > "$ROOTFS/usr/local/sbin/ysyx-npc-systemd-wrapper" <<'EOF'
#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

echo "[ysyx-npc-systemd-wrapper] begin"

systemd_bin=
for candidate in /lib/systemd/systemd /usr/lib/systemd/systemd /sbin/init /usr/sbin/init; do
  if [ -x "$candidate" ]; then
    systemd_bin="$candidate"
    break
  fi
done

echo __NPC_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NPC_CHECK_PASS__:$1"; }
fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; }

os_name=0
os_version=0
if [ -r /etc/os-release ]; then
  while IFS= read -r line; do
    case "$line" in
      'NAME="Ubuntu"'|'NAME=Ubuntu') os_name=1 ;;
      'VERSION_ID="22.04"'|'VERSION_ID=22.04') os_version=1 ;;
    esac
  done </etc/os-release
fi
[ "$os_name" = 1 ] && [ "$os_version" = 1 ] && pass os-release-ubuntu-2204 || fail os-release-ubuntu-2204
[ -x /bin/sh ] && pass bin-sh || fail bin-sh
[ -x /bin/bash ] && pass bin-bash || fail bin-bash
[ -n "$systemd_bin" ] && pass systemd-binary || fail systemd-binary
[ -x /usr/local/sbin/ysyx-npc-systemd-autocheck ] && pass systemd-autocheck-script || fail systemd-autocheck-script
echo "__NPC_CHECK_SYSTEMD_STATE__:wrapper-pre-systemd"
pass systemd-wrapper-preflight
echo "__NPC_SYSTEMD_CHECK_DONE__ rc=$check_fail"

if [ -n "$systemd_bin" ]; then
  echo "[ysyx-npc-systemd-wrapper] console prompt marker"
  printf 'root@ysyx-ubuntu2204:~# '
  echo "[ysyx-npc-systemd-wrapper] exec systemd: $systemd_bin"
  exec "$systemd_bin"
fi

echo "[ysyx-npc-systemd-wrapper] no systemd binary found; fallback shell"
exec /bin/sh -i </dev/console >/dev/console 2>&1
EOF
  chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-systemd-wrapper"
  cat > "$ROOTFS/etc/systemd/system/ysyx-npc-systemd-autocheck.service" <<'EOF'
[Unit]
Description=YSYX NPC systemd guest autocheck
DefaultDependencies=no
After=ysyx-npc-console-shell.service ysyx-npc-tty-reader.service
Before=systemd-journald.service systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/usr/local/sbin/ysyx-npc-systemd-autocheck

[Service]
Type=oneshot
StandardInput=null
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=/usr/local/sbin/ysyx-npc-systemd-autocheck
TimeoutStartSec=0

[Install]
WantedBy=sysinit.target
EOF
  ln -sfn ../ysyx-npc-systemd-autocheck.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-autocheck.service"
  cat > "$ROOTFS/etc/systemd/system/ysyx-npc-tty-reader.service" <<'EOF'
[Unit]
Description=YSYX NPC ttyS0 input reader diagnostic
DefaultDependencies=no
Before=ysyx-npc-systemd-autocheck.service systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/dev/ttyS0
ConditionPathExists=/usr/local/sbin/ysyx-npc-tty-reader

[Service]
Type=oneshot
Environment=TERM=vt100
Environment=YSYX_NPC_TTY_READER_MODE=__NPC_TTY_READER_MODE__
WorkingDirectory=/root
StandardInput=tty-force
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=/usr/local/sbin/ysyx-npc-tty-reader
Restart=no
TimeoutStartSec=0

[Install]
WantedBy=sysinit.target
EOF
  sed -i "s/__NPC_TTY_READER_MODE__/$ROOTFS_NPC_TTY_READER_MODE/g" "$ROOTFS/etc/systemd/system/ysyx-npc-tty-reader.service"
  cat > "$ROOTFS/etc/systemd/system/ysyx-npc-console-shell.service" <<'EOF'
[Unit]
Description=YSYX NPC automated root console shell
DefaultDependencies=no
Before=systemd-sysusers.service systemd-udev-trigger.service systemd-modules-load.service sysinit.target
ConditionPathExists=/dev/ttyS0

[Service]
Type=simple
Environment=TERM=vt100
WorkingDirectory=/root
StandardInput=tty-force
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
ExecStart=-/usr/local/sbin/ysyx-npc-console-shell
Restart=always
RestartSec=0

[Install]
WantedBy=sysinit.target
EOF
  if [ "$ROOTFS_NPC_TTY_READER" = "1" ]; then
    rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/ysyx-npc-console-shell.service"
    ln -sfn ../ysyx-npc-tty-reader.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/ysyx-npc-tty-reader.service"
  else
    rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/ysyx-npc-tty-reader.service"
    ln -sfn ../ysyx-npc-console-shell.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/ysyx-npc-console-shell.service"
  fi

  if [ "$ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS" = "1" ]; then
    mkdir -p "$ROOTFS/usr/local/share/ysyx-disabled-system-generators" "$ROOTFS/lib/systemd/system-generators"
    for generator in "$ROOTFS"/lib/systemd/system-generators/*; do
      [ -e "$generator" ] || continue
      mv "$generator" "$ROOTFS/usr/local/share/ysyx-disabled-system-generators/"
    done
  fi
fi
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

if [ "$ROOTFS_NPC_GENERATOR_TRACE" = "1" ]; then
  skip_list=${ROOTFS_NPC_GENERATOR_SKIP:-}
  skip_mode=${ROOTFS_NPC_GENERATOR_SKIP_MODE:-shell}
  if [ "$skip_mode" = "static" ]; then
    if [ ! -f "${ROOTFS_NPC_GENERATOR_SKIP_BIN:-}" ]; then
      echo "[ubuntu-rootfs] missing NPC static generator skip wrapper: ${ROOTFS_NPC_GENERATOR_SKIP_BIN:-unset}" >&2
      exit 1
    fi
    mkdir -p "$ROOTFS/usr/local/sbin" "$ROOTFS/etc"
    cp "$ROOTFS_NPC_GENERATOR_SKIP_BIN" "$ROOTFS/usr/local/sbin/ysyx-npc-generator-skip"
    chmod 0755 "$ROOTFS/usr/local/sbin/ysyx-npc-generator-skip"
    printf '%s\n' "$skip_list" > "$ROOTFS/etc/ysyx-npc-generator-skip-list"
    printf '%s\n' "${ROOTFS_NPC_GENERATOR_REAL_MODE:-exec}" > "$ROOTFS/etc/ysyx-npc-generator-real-mode"
  fi
  for gen_dir in "$ROOTFS/lib/systemd/system-generators" "$ROOTFS/usr/lib/systemd/system-generators"; do
    [ -d "$gen_dir" ] || continue
    case "$gen_dir" in
      "$ROOTFS/lib/systemd/system-generators") real_bucket=lib ;;
      "$ROOTFS/usr/lib/systemd/system-generators") real_bucket=usr-lib ;;
      *) real_bucket=other ;;
    esac
    real_root="$ROOTFS/usr/local/lib/ysyx-npc-system-generators/$real_bucket"
    mkdir -p "$real_root"
    for stale in "$gen_dir"/*.ysyx-real; do
      [ -f "$stale" ] || continue
      stale_name=$(basename "$stale" .ysyx-real)
      stale_real="$real_root/$stale_name"
      if [ ! -e "$stale_real" ]; then
        mv "$stale" "$stale_real"
      else
        rm -f "$stale"
      fi
      chmod 0755 "$stale_real" 2>/dev/null || true
    done
    for gen in "$gen_dir"/*; do
      [ -f "$gen" ] || continue
      [ -x "$gen" ] || continue
      case "$gen" in
        *.ysyx-real) continue ;;
      esac
      gen_name=$(basename "$gen")
      real_gen="$real_root/$gen_name"
      real_gen_guest="/usr/local/lib/ysyx-npc-system-generators/$real_bucket/$gen_name"
      has_wrapper=0
      if grep -aq '__NPC_GENERATOR_BEGIN__' "$gen" 2>/dev/null; then
        has_wrapper=1
      fi
      if [ "$has_wrapper" = "1" ] && [ ! -e "$real_gen" ]; then
        continue
      fi
      if [ "$has_wrapper" != "1" ] && [ ! -e "$real_gen" ]; then
        mv "$gen" "$real_gen"
      fi
      if [ "$skip_mode" = "static" ]; then
        cp "$ROOTFS/usr/local/sbin/ysyx-npc-generator-skip" "$gen"
        chmod 0755 "$gen"
      else
        cat > "$gen" <<EOF
#!/bin/sh
name="$gen_name"
skip_list="$skip_list"
echo "__NPC_GENERATOR_BEGIN__:\$name argc=\$# argv=\$*" >/dev/console
case " \$skip_list " in
  *" all "*|*" \$name "*)
    echo "__NPC_GENERATOR_SKIP__:\$name match=space-list" >/dev/console
    echo "__NPC_GENERATOR_END__:\$name rc=0 skipped=1" >/dev/console
    exit 0
    ;;
esac
case ",\$skip_list," in
  *,all,*|*,\$name,*)
    echo "__NPC_GENERATOR_SKIP__:\$name match=comma-list" >/dev/console
    echo "__NPC_GENERATOR_END__:\$name rc=0 skipped=1" >/dev/console
    exit 0
    ;;
esac
"$real_gen_guest" "\$@"
rc=\$?
echo "__NPC_GENERATOR_END__:\$name rc=\$rc" >/dev/console
exit "\$rc"
EOF
        chmod 0755 "$gen"
      fi
    done
  done
fi

if [ "$ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE" = "1" ]; then
  if ! command -v systemd-sysusers >/dev/null 2>&1; then
    echo "[ubuntu-rootfs] missing host systemd-sysusers for NPC update preseed" >&2
    exit 1
  fi
  echo "[ubuntu-rootfs] preseed systemd sysusers/update-done stamps"
  systemd-sysusers --root="$ROOTFS"
  mkdir -p "$ROOTFS/etc" "$ROOTFS/var"
  touch "$ROOTFS/etc/.updated" "$ROOTFS/var/.updated"
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
    ROOTFS_NPC_CONSOLE_SHELL="$ROOTFS_NPC_CONSOLE_SHELL" \
    ROOTFS_NPC_TTY_READER="$ROOTFS_NPC_TTY_READER" \
    ROOTFS_NPC_TTY_READER_MODE="$ROOTFS_NPC_TTY_READER_MODE" \
    ROOTFS_NPC_TTY_PROBE_BIN="$ROOTFS_NPC_TTY_PROBE_BIN" \
    ROOTFS_NPC_LOGIN_MARKER="$ROOTFS_NPC_LOGIN_MARKER" \
    ROOTFS_NPC_LOGIN_TRACE="$ROOTFS_NPC_LOGIN_TRACE" \
    ROOTFS_NPC_GENERATOR_TRACE="$ROOTFS_NPC_GENERATOR_TRACE" \
    ROOTFS_NPC_GENERATOR_SKIP="$ROOTFS_NPC_GENERATOR_SKIP" \
    ROOTFS_NPC_GENERATOR_SKIP_MODE="$ROOTFS_NPC_GENERATOR_SKIP_MODE" \
    ROOTFS_NPC_GENERATOR_REAL_MODE="$ROOTFS_NPC_GENERATOR_REAL_MODE" \
    ROOTFS_NPC_GENERATOR_SKIP_BIN="$ROOTFS_NPC_GENERATOR_SKIP_BIN" \
    ROOTFS_NEMU_LOGIN_MARKER="$ROOTFS_NEMU_LOGIN_MARKER" \
    ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE="$ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE" \
    ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS="$ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS" \
    ROOTFS_SYSTEMD_OVERLAY_SCRIPT="$ROOTFS_SYSTEMD_OVERLAY_SCRIPT" \
    fakeroot -- bash "$helper"
}

build_rootfs_static_init
build_rootfs_probe
build_npc_tty_probe
build_npc_generator_skip_wrapper

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
    UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL="$ROOTFS_NPC_CONSOLE_SHELL" \
    UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER="$ROOTFS_NPC_TTY_READER" \
    UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER="$ROOTFS_NPC_LOGIN_MARKER" \
    UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_TRACE="$ROOTFS_NPC_LOGIN_TRACE" \
    UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE="$ROOTFS_NPC_GENERATOR_TRACE" \
    UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP="$ROOTFS_NPC_GENERATOR_SKIP" \
    UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE="$ROOTFS_NPC_GENERATOR_SKIP_MODE" \
    UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE="$ROOTFS_NPC_GENERATOR_REAL_MODE" \
    UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER="$ROOTFS_NEMU_LOGIN_MARKER" \
    UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE="$ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE" \
    bash "$SCRIPT_DIR/check-ubuntu-rootfs.sh"
fi
echo "[ubuntu-rootfs] 注意：启动该 rootfs 还需要 RTL/仿真侧 virtio-mmio block、host block backend 与 IRQ2 路径。"
