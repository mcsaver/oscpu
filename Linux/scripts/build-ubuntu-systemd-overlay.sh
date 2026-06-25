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
ROOTFS_FLAVOR=${UBUNTU_ROOTFS_FLAVOR:-systemd-minimal}
ROOTFS_FLAVOR_SCRIPT=${UBUNTU_ROOTFS_FLAVOR_SCRIPT:-"$SCRIPT_DIR/ubuntu-rootfs-flavors.sh"}
source "$ROOTFS_FLAVOR_SCRIPT"
ROOTFS_FLAVOR=$(ubuntu_rootfs_flavor_normalize "$ROOTFS_FLAVOR")
APT_TRUSTED=${UBUNTU_SYSTEMD_OVERLAY_APT_TRUSTED:-1}
APT_COMPONENTS=${UBUNTU_SYSTEMD_OVERLAY_COMPONENTS:-"main universe"}
APT_NO_RECOMMENDS=${UBUNTU_SYSTEMD_OVERLAY_NO_RECOMMENDS:-$(ubuntu_rootfs_flavor_no_recommends "$ROOTFS_FLAVOR")}
OVERLAY_PACKAGES=${UBUNTU_SYSTEMD_OVERLAY_PACKAGES:-$(ubuntu_rootfs_flavor_packages "$ROOTFS_FLAVOR")}

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
mkdir -p "$(dirname "$STATUS_FILE")"
if [ ! -f "$STATUS_FILE" ]; then
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

echo "[ubuntu-systemd-overlay] flavor: $ROOTFS_FLAVOR"
echo "[ubuntu-systemd-overlay] no-recommends: $APT_NO_RECOMMENDS"
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

dpkg_status_mark_installed() {
  local deb=$1
  local status_file=$2
  local package control_tmp status_tmp

  package=$(dpkg-deb -f "$deb" Package)
  control_tmp=$(mktemp)
  status_tmp=$(mktemp)

  # chrootless dpkg-deb -x 只解包文件，不会更新 dpkg 数据库；这里把 control
  # 段标记为已安装，让 guest 内 dpkg-query/apt-cache 能看到真实 full 用户态。
  dpkg-deb -f "$deb" | awk '
    /^Package: / {
      print
      print "Status: install ok installed"
      inserted = 1
      next
    }
    /^Status: / { next }
    { print }
    END { if (!inserted) exit 1 }
  ' > "$control_tmp"

  awk -v pkg="$package" '
    BEGIN { RS = ""; ORS = "\n\n" }
    {
      found = 0
      n = split($0, lines, "\n")
      for (i = 1; i <= n; i++) {
        if (lines[i] == "Package: " pkg) {
          found = 1
        }
      }
      if (!found) print
    }
  ' "$status_file" > "$status_tmp"
  cat "$control_tmp" >> "$status_tmp"
  printf '\n' >> "$status_tmp"
  mv "$status_tmp" "$status_file"
  rm -f "$control_tmp"
}

dpkg_info_install_records() {
  local deb=$1
  local info_dir=$2
  local package multi_arch info_package control_dir control_file control_name

  package=$(dpkg-deb -f "$deb" Package)
  multi_arch=$(dpkg-deb -f "$deb" Multi-Arch 2>/dev/null || true)
  info_package=$package
  if [ "$multi_arch" = "same" ]; then
    info_package="$package:$ARCH"
  fi

  mkdir -p "$info_dir"
  # dpkg --audit 会要求每个 installed package 都有 .list；chrootless 解包
  # 必须补齐这层 info 数据库，不能只让文件系统里“看起来有文件”。
  dpkg-deb -c "$deb" | awk '
    {
      path = $6
      if (path == "") next

      # dpkg 的 .list 文件不能把根目录写成单独的 "/"；dpkg-query
      # 会把它解析成空文件名并中止，必须按 Debian 格式写成 "/."。
      if (path == "." || path == "./") {
        print "/."
        next
      }

      sub(/^\.\//, "/", path)
      if (path != "/" && path ~ /\/$/) sub(/\/$/, "", path)
      if (path == "/") path = "/."
      if (path == "") next
      print path
    }
  ' > "$info_dir/$info_package.list"

  control_dir=$(mktemp -d)
  dpkg-deb -e "$deb" "$control_dir"
  for control_file in "$control_dir"/*; do
    [ -f "$control_file" ] || continue
    control_name=$(basename "$control_file")
    [ "$control_name" = "control" ] && continue
    cp "$control_file" "$info_dir/$info_package.$control_name"
  done
  rm -rf "$control_dir"
}

echo "[ubuntu-systemd-overlay] refresh dpkg status for unpacked packages"
DPKG_INFO_DIR="$ROOTFS/var/lib/dpkg/info"
for deb in "${debs[@]}"; do
  dpkg_status_mark_installed "$deb" "$STATUS_FILE"
  dpkg_info_install_records "$deb" "$DPKG_INFO_DIR"
done

mkdir -p "$ROOTFS/etc/apt" "$ROOTFS/etc/systemd/system" \
  "$ROOTFS/var/lib/systemd" "$ROOTFS/run" "$ROOTFS/run/lock"
cp "$APT_ROOT/etc/apt/sources.list" "$ROOTFS/etc/apt/sources.list"

# systemd 在首次启动时可以填充空 machine-id；显式放一个文件比缺文件更接近真实 rootfs。
if [ ! -e "$ROOTFS/etc/machine-id" ]; then
  : > "$ROOTFS/etc/machine-id"
fi

# full flavor 仍保留 e2fsprogs/e2scrub 工具，但在线 ext4 scrub/reap 属于维护任务；
# 在慢速 NEMU guest 中它会阻塞 multi-user.target，影响 focused gate 的启动判定。
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

# chrootless dpkg-deb 解包不会执行 usrmerge/maintainer scripts；full flavor 中
# PAM 模块可能分散在 /lib 与 /usr/lib，login 只搜 /lib 下的 multiarch security 目录。
pam_lib_dir="$ROOTFS/lib/riscv64-linux-gnu/security"
pam_usr_dir="$ROOTFS/usr/lib/riscv64-linux-gnu/security"
if [ -d "$pam_usr_dir" ]; then
  mkdir -p "$pam_lib_dir"
  for module in "$pam_usr_dir"/pam_*.so; do
    [ -e "$module" ] || continue
    module_name=$(basename "$module")
    if [ ! -e "$pam_lib_dir/$module_name" ]; then
      ln -s "../../../usr/lib/riscv64-linux-gnu/security/$module_name" \
        "$pam_lib_dir/$module_name"
    fi
  done
fi

if [ "$ROOTFS_FLAVOR" = "full" ] &&
   [ -e "$pam_lib_dir/pam_systemd.so" ] &&
   [ -f "$ROOTFS/etc/pam.d/common-session" ] &&
   ! grep -Eq '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_systemd\.so([[:space:]]|$)' \
      "$ROOTFS/etc/pam.d/common-session"; then
  # chrootless 解包不会运行 libpam-systemd 的 pam-auth-update；手工补齐后，
  # serial-getty/login 才会为当前 ttyS0 root 登录创建 logind session。
  printf '\nsession optional pam_systemd.so\n' >> "$ROOTFS/etc/pam.d/common-session"
fi

echo "[ubuntu-systemd-overlay] overlay complete"
