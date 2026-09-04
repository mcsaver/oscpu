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

path_is_within_or_equal() {
  local child=$1 parent=$2 child_real parent_real
  child_real=$(realpath -m -- "$child")
  parent_real=$(realpath -m -- "$parent")
  if [[ $parent_real == / ]]; then
    [[ $child_real == /* ]]
  else
    [[ $child_real == "$parent_real" || $child_real == "$parent_real"/* ]]
  fi
}

WORK_REAL=$(realpath -m -- "$WORK")
ROOTFS_REAL=$(realpath -m -- "$ROOTFS")
APT_ROOT_REAL=$(realpath -m -- "$APT_ROOT")
WORK_LEXICAL=$(realpath -ms -- "$WORK")
APT_ROOT_LEXICAL=$(realpath -ms -- "$APT_ROOT")
APT_ARCHIVES="$APT_ROOT/cache/archives"
APT_ARCHIVES_REAL=$(realpath -m -- "$APT_ARCHIVES")
APT_SOURCES_LIST="$APT_ROOT/etc/apt/sources.list"
PARENT_LOCK_HELD=${UBUNTU_SYSTEMD_OVERLAY_PARENT_LOCK_HELD:-0}
PARENT_WORK_LOCK_FD=${UBUNTU_SYSTEMD_OVERLAY_WORK_LOCK_FD:-}
PARENT_ROOTFS_LOCK_FD=${UBUNTU_SYSTEMD_OVERLAY_ROOTFS_LOCK_FD:-}
PARENT_APT_LOCK_FD=${UBUNTU_SYSTEMD_OVERLAY_APT_LOCK_FD:-}
if [[ $PARENT_LOCK_HELD == 1 ]]; then
  OVERLAY_WORK_LOCK=${UBUNTU_SYSTEMD_OVERLAY_WORK_LOCK:-}
  OVERLAY_ROOTFS_LOCK=${UBUNTU_SYSTEMD_OVERLAY_ROOTFS_LOCK:-}
  OVERLAY_APT_LOCK=${UBUNTU_SYSTEMD_OVERLAY_APT_LOCK:-}
else
  # Direct callers cannot override resource identities and thereby opt out of
  # serialization with another invocation targeting the same trees.
  OVERLAY_WORK_LOCK="$WORK_REAL/.build-ubuntu-rootfs.lock"
  OVERLAY_ROOTFS_LOCK="$ROOTFS_REAL.build.lock"
  OVERLAY_APT_LOCK="$APT_ROOT_REAL.build.lock"
fi

# APT_ROOT contains mutable apt state and a destructive archive cleanup.  It
# must remain a dedicated subtree of WORK and must never overlap the extracted
# rootfs that receives package payloads.
if [[ $WORK_REAL == / || $APT_ROOT_REAL == "$WORK_REAL" ]] ||
   ! path_is_within_or_equal "$APT_ROOT_REAL" "$WORK_REAL"; then
  echo "[ubuntu-systemd-overlay] APT_ROOT must be a canonical strict child of WORK: $APT_ROOT / $WORK" >&2
  exit 1
fi
if path_is_within_or_equal "$APT_ROOT_REAL" "$ROOTFS_REAL" ||
   path_is_within_or_equal "$ROOTFS_REAL" "$APT_ROOT_REAL"; then
  echo "[ubuntu-systemd-overlay] APT_ROOT must not overlap ROOTFS: $APT_ROOT / $ROOTFS" >&2
  exit 1
fi
if ! path_is_within_or_equal "$APT_ARCHIVES_REAL" "$APT_ROOT_REAL" ||
   [[ $APT_ARCHIVES_REAL == "$APT_ROOT_REAL" ]]; then
  echo "[ubuntu-systemd-overlay] apt archives escaped APT_ROOT: $APT_ARCHIVES / $APT_ROOT" >&2
  exit 1
fi

APT_MUTABLE_DIRS=(
  "$APT_ROOT"
  "$APT_ROOT/etc"
  "$APT_ROOT/etc/apt"
  "$APT_ROOT/state"
  "$APT_ROOT/state/lists"
  "$APT_ROOT/state/lists/partial"
  "$APT_ROOT/cache"
  "$APT_ARCHIVES"
  "$APT_ARCHIVES/partial"
)

validate_apt_root_chain() {
  local relative component current
  local -a apt_root_components
  if [[ $APT_ROOT_LEXICAL == "$WORK_LEXICAL" ]] ||
     [[ $APT_ROOT_LEXICAL != "$WORK_LEXICAL"/* ]]; then
    echo "[ubuntu-systemd-overlay] APT_ROOT must be a lexical strict child of WORK: $APT_ROOT / $WORK" >&2
    return 1
  fi
  relative=${APT_ROOT_LEXICAL#"$WORK_LEXICAL"/}
  current=$WORK_LEXICAL
  IFS=/ read -r -a apt_root_components <<< "$relative"
  for component in "${apt_root_components[@]}"; do
    [[ -n $component ]] || continue
    current="$current/$component"
    [[ ! -L $current ]] || {
      echo "[ubuntu-systemd-overlay] APT_ROOT path component must not be a symlink: $current" >&2
      return 1
    }
    [[ ! -e $current || -d $current ]] || {
      echo "[ubuntu-systemd-overlay] APT_ROOT path component has unsafe type: $current" >&2
      return 1
    }
  done
}

validate_apt_layout() {
  local dir dir_real
  for dir in "${APT_MUTABLE_DIRS[@]}"; do
    [[ ! -L $dir ]] || {
      echo "[ubuntu-systemd-overlay] apt directory path must not be a symlink: $dir" >&2
      return 1
    }
    [[ ! -e $dir || -d $dir ]] || {
      echo "[ubuntu-systemd-overlay] apt directory path has unsafe type: $dir" >&2
      return 1
    }
    dir_real=$(realpath -m -- "$dir")
    if [[ $dir == "$APT_ROOT" ]]; then
      [[ $dir_real == "$APT_ROOT_REAL" ]] || {
        echo "[ubuntu-systemd-overlay] APT_ROOT changed after validation: $APT_ROOT" >&2
        return 1
      }
    elif [[ $dir_real == "$APT_ROOT_REAL" ]] ||
         ! path_is_within_or_equal "$dir_real" "$APT_ROOT_REAL"; then
      echo "[ubuntu-systemd-overlay] apt directory escaped APT_ROOT: $dir" >&2
      return 1
    fi
  done
  [[ ! -L $APT_SOURCES_LIST ]] || {
    echo "[ubuntu-systemd-overlay] apt sources file must not be a symlink: $APT_SOURCES_LIST" >&2
    return 1
  }
  [[ ! -e $APT_SOURCES_LIST || -f $APT_SOURCES_LIST ]] || {
    echo "[ubuntu-systemd-overlay] apt sources file has unsafe type: $APT_SOURCES_LIST" >&2
    return 1
  }
  path_is_within_or_equal "$APT_SOURCES_LIST" "$APT_ROOT_REAL" || {
    echo "[ubuntu-systemd-overlay] apt sources file escaped APT_ROOT: $APT_SOURCES_LIST" >&2
    return 1
  }
}

validate_overlay_lock_path() {
  local lock_path=$1 lock_real
  [[ -n $lock_path ]] || {
    echo "[ubuntu-systemd-overlay] overlay writer lock path is empty" >&2
    return 1
  }
  [[ ! -L $lock_path ]] || {
    echo "[ubuntu-systemd-overlay] overlay writer lock must not be a symlink: $lock_path" >&2
    return 1
  }
  [[ ! -e $lock_path || -f $lock_path ]] || {
    echo "[ubuntu-systemd-overlay] overlay writer lock has unsafe type: $lock_path" >&2
    return 1
  }
  lock_real=$(realpath -m -- "$lock_path")
  if path_is_within_or_equal "$lock_real" "$ROOTFS_REAL" ||
     path_is_within_or_equal "$lock_real" "$APT_ROOT_REAL"; then
    echo "[ubuntu-systemd-overlay] overlay writer lock conflicts with mutable tree: $lock_path" >&2
    return 1
  fi
}

validate_inherited_lock_fd() {
  local label=$1 lock_fd=$2 lock_path=$3 fd_path
  [[ $lock_fd =~ ^[0-9]+$ ]] || {
    echo "[ubuntu-systemd-overlay] missing inherited $label lock fd" >&2
    return 1
  }
  fd_path="/proc/$$/fd/$lock_fd"
  [[ -e $fd_path && $fd_path -ef $lock_path ]] || {
    echo "[ubuntu-systemd-overlay] inherited $label lock fd has wrong identity: $lock_fd / $lock_path" >&2
    return 1
  }
  flock -n "$lock_fd" || {
    echo "[ubuntu-systemd-overlay] inherited $label lock fd is not held: $lock_fd" >&2
    return 1
  }
}

if [ ! -d "$ROOTFS" ] || [ ! -f "$ROOTFS/etc/os-release" ]; then
  echo "[ubuntu-systemd-overlay] missing extracted Ubuntu rootfs: $ROOTFS" >&2
  echo "[ubuntu-systemd-overlay] run this after Ubuntu Base extraction or via build-ubuntu-rootfs.sh" >&2
  exit 1
fi

for tool in apt-get dpkg-deb flock mktemp realpath sort; do
  if ! command -v "$tool" >/dev/null; then
    echo "[ubuntu-systemd-overlay] missing tool: $tool" >&2
    exit 1
  fi
done

validate_apt_root_chain
validate_apt_layout
if [[ $PARENT_LOCK_HELD == 1 ]]; then
  [[ $(realpath -m -- "$OVERLAY_ROOTFS_LOCK") == "$ROOTFS_REAL.build.lock" ]] || {
    echo "[ubuntu-systemd-overlay] inherited ROOTFS lock path does not match ROOTFS" >&2
    exit 1
  }
  [[ $(realpath -m -- "$OVERLAY_APT_LOCK") == "$APT_ROOT_REAL.build.lock" ]] || {
    echo "[ubuntu-systemd-overlay] inherited APT lock path does not match APT_ROOT" >&2
    exit 1
  }
fi
OVERLAY_LOCK_CANDIDATES=(
  "$OVERLAY_WORK_LOCK"
  "$OVERLAY_ROOTFS_LOCK"
  "$OVERLAY_APT_LOCK"
)
OVERLAY_LOCK_REALS=()
for lock_path in "${OVERLAY_LOCK_CANDIDATES[@]}"; do
  validate_overlay_lock_path "$lock_path"
  OVERLAY_LOCK_REALS+=("$(realpath -m -- "$lock_path")")
done
mapfile -t OVERLAY_LOCK_PATHS < <(
  printf '%s\n' "${OVERLAY_LOCK_REALS[@]}" | LC_ALL=C sort -u
)
for ((i = 0; i < ${#OVERLAY_LOCK_PATHS[@]}; i++)); do
  for ((j = i + 1; j < ${#OVERLAY_LOCK_PATHS[@]}; j++)); do
    if [[ -e ${OVERLAY_LOCK_PATHS[i]} && -e ${OVERLAY_LOCK_PATHS[j]} &&
          ${OVERLAY_LOCK_PATHS[i]} -ef ${OVERLAY_LOCK_PATHS[j]} ]]; then
      echo "[ubuntu-systemd-overlay] distinct writer locks alias one inode: ${OVERLAY_LOCK_PATHS[i]} / ${OVERLAY_LOCK_PATHS[j]}" >&2
      exit 1
    fi
  done
done

case "$PARENT_LOCK_HELD" in
  0)
    OVERLAY_LOCK_FDS=()
    for lock_path in "${OVERLAY_LOCK_PATHS[@]}"; do
      mkdir -p "$(dirname -- "$lock_path")"
      exec {lock_fd}>>"$lock_path"
      flock "$lock_fd"
      OVERLAY_LOCK_FDS+=("$lock_fd")
    done
    ;;
  1)
    # The rootfs builder acquired these same canonical resources as part of
    # its globally sorted lock set.  Reuse and verify the inherited open file
    # descriptions instead of reopening them and self-deadlocking.
    validate_inherited_lock_fd WORK "$PARENT_WORK_LOCK_FD" "$OVERLAY_WORK_LOCK"
    validate_inherited_lock_fd ROOTFS "$PARENT_ROOTFS_LOCK_FD" "$OVERLAY_ROOTFS_LOCK"
    validate_inherited_lock_fd APT_ROOT "$PARENT_APT_LOCK_FD" "$OVERLAY_APT_LOCK"
    ;;
  *)
    echo "[ubuntu-systemd-overlay] invalid parent-lock marker: $PARENT_LOCK_HELD" >&2
    exit 1
    ;;
esac

# A previous direct invocation may have changed the tree while this process
# waited for the writer lock.  Revalidate before the first mkdir beneath it.
validate_apt_root_chain
validate_apt_layout
mkdir -p "$APT_ROOT/etc/apt" "$APT_ROOT/state/lists/partial" \
  "$APT_ARCHIVES/partial"
validate_apt_root_chain
validate_apt_layout

trusted_opt=
if [ "$APT_TRUSTED" = "1" ]; then
  trusted_opt="[trusted=yes] "
fi

sources_temp=$(mktemp "$APT_ROOT/etc/apt/.sources.list.tmp.XXXXXX")
cleanup_sources_temp() {
  local status=$?
  trap - EXIT HUP INT TERM
  [[ -z ${sources_temp:-} ]] || rm -f -- "$sources_temp"
  exit "$status"
}
trap cleanup_sources_temp EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$sources_temp" <<EOF
deb ${trusted_opt}${MIRROR} ${RELEASE} ${APT_COMPONENTS}
deb ${trusted_opt}${MIRROR} ${RELEASE}-updates ${APT_COMPONENTS}
deb ${trusted_opt}${MIRROR} ${RELEASE}-security ${APT_COMPONENTS}
EOF
mv -fT -- "$sources_temp" "$APT_SOURCES_LIST"
sources_temp=

STATUS_FILE="$ROOTFS/var/lib/dpkg/status"
mkdir -p "$(dirname "$STATUS_FILE")"
if [ ! -f "$STATUS_FILE" ]; then
  : > "$STATUS_FILE"
fi

apt_opts=(
  -o "APT::Architecture=$ARCH"
  -o "APT::Architectures::=$ARCH"
  -o "Dir::Etc::sourcelist=$APT_SOURCES_LIST"
  -o "Dir::Etc::sourceparts=-"
  -o "Dir::Etc::main=-"
  -o "Dir::State=$APT_ROOT/state"
  -o "Dir::State::status=$STATUS_FILE"
  -o "Dir::Cache=$APT_ROOT/cache"
  -o "Debug::NoLocking=1"
)

echo "[ubuntu-systemd-overlay] flavor: $ROOTFS_FLAVOR"
echo "[ubuntu-systemd-overlay] no-recommends: $APT_NO_RECOMMENDS"
# apt download-only 会保留旧 archive；若直接解包目录中的全部 .deb，缩减过的
# flavor 仍会被历史包污染。每次事务只保留本次依赖闭包。
validate_apt_layout
[[ $(realpath -m -- "$APT_ARCHIVES") == "$APT_ARCHIVES_REAL" ]] || {
  echo "[ubuntu-systemd-overlay] apt archives changed before cleanup: $APT_ARCHIVES" >&2
  exit 1
}
# Pin cleanup to the verified directory inode.  Even if a non-cooperating
# process swaps the pathname after cd, ./ remains the opened working directory
# and rm cannot traverse a replacement symlink to an external archive tree.
(
  cd -P -- "$APT_ARCHIVES"
  [[ $(pwd -P) == "$APT_ARCHIVES_REAL" ]] || {
    echo "[ubuntu-systemd-overlay] apt archives identity changed before cleanup: $APT_ARCHIVES" >&2
    exit 1
  }
  rm -f -- ./*.deb
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
debs=("$APT_ARCHIVES"/*.deb)
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
cp "$APT_SOURCES_LIST" "$ROOTFS/etc/apt/sources.list"

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
