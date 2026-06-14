#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
REQUIRE_SYSTEMD=${UBUNTU_ROOTFS_REQUIRE_SYSTEMD:-0}
DEBUGFS=${DEBUGFS:-debugfs}
ROOTFS_FLAVOR=${UBUNTU_ROOTFS_FLAVOR:-systemd-minimal}
ROOTFS_FLAVOR_SCRIPT=${UBUNTU_ROOTFS_FLAVOR_SCRIPT:-"$SCRIPT_DIR/ubuntu-rootfs-flavors.sh"}
source "$ROOTFS_FLAVOR_SCRIPT"
ROOTFS_FLAVOR=$(ubuntu_rootfs_flavor_normalize "$ROOTFS_FLAVOR")
ROOTFS_ARTIFACT_SUFFIX=${UBUNTU_ROOTFS_ARTIFACT_SUFFIX:-$(ubuntu_rootfs_flavor_artifact_suffix "$ROOTFS_FLAVOR")}
IMAGE=${UBUNTU_ROOTFS_IMAGE:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64$ROOTFS_ARTIFACT_SUFFIX.ext4"}

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

rootfs_symlink_points_to() {
  local path=$1
  local target=$2
  local out
  out=$(debugfs_stat "$path")
  grep -q "Inode:" <<<"$out" &&
    ! grep -qi "File not found" <<<"$out" &&
    { grep -Fq "Fast link dest: $target" <<<"$out" ||
      grep -Fq "Fast link dest: \"$target\"" <<<"$out"; }
}

rootfs_cat() {
  local path=$1
  "$DEBUGFS" -R "cat $path" "$IMAGE" 2>/dev/null || true
}

rootfs_file_contains() {
  local path=$1
  local pattern=$2
  rootfs_cat "$path" | grep -Eq "$pattern"
}

rootfs_dpkg_status_installed() {
  local package=$1
  rootfs_cat /var/lib/dpkg/status | awk -v pkg="$package" '
    BEGIN { RS = ""; found = 0 }
    {
      has_package = 0
      has_status = 0
      n = split($0, lines, "\n")
      for (i = 1; i <= n; i++) {
        if (lines[i] == "Package: " pkg) has_package = 1
        if (lines[i] == "Status: install ok installed") has_status = 1
      }
      if (has_package && has_status) found = 1
    }
    END { exit found ? 0 : 1 }
  '
}

rootfs_dpkg_info_list_contains() {
  local package=$1
  local path=$2
  rootfs_cat "/var/lib/dpkg/info/$package.list" | grep -Fxq "$path"
}

rootfs_dpkg_info_list_files() {
  "$DEBUGFS" -R "ls -p /var/lib/dpkg/info" "$IMAGE" 2>/dev/null |
    awk -F/ '$6 ~ /\.list$/ { print $6 }'
}

rootfs_dpkg_info_list_invalid_records() {
  local package=$1
  rootfs_cat "/var/lib/dpkg/info/$package.list" | awk '
    $0 == "" {
      print "empty-line"
      invalid = 1
      next
    }
    $0 == "/" {
      print "root-slash:/"
      invalid = 1
      next
    }
    $0 !~ /^\// {
      print "not-absolute:" $0
      invalid = 1
      next
    }
    END { exit invalid ? 1 : 0 }
  '
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
echo "[ubuntu-rootfs-check] flavor: $ROOTFS_FLAVOR"

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

  if rootfs_has /usr/bin/lsb_release; then
    echo "[ubuntu-rootfs-check] OK      Ubuntu identity command: /usr/bin/lsb_release"
  else
    echo "[ubuntu-rootfs-check] MISSING Ubuntu identity command: /usr/bin/lsb_release"
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

  # autologin 仍会经过 /bin/login 的 PAM 栈；目录存在但关键模块不可搜索会导致反复
  # "Module is unknown"，因此严格 gate 必须检查 login 所需的基础模块。
  for module in pam_unix.so pam_deny.so pam_permit.so pam_env.so pam_loginuid.so pam_limits.so; do
    pam_module_path="/lib/riscv64-linux-gnu/security/$module"
    if rootfs_has "$pam_module_path"; then
      echo "[ubuntu-rootfs-check] OK      PAM login module: $pam_module_path"
    else
      echo "[ubuntu-rootfs-check] MISSING PAM login module: $pam_module_path"
      systemd_missing=1
    fi
  done

  if rootfs_has /sbin/e2scrub_all; then
    echo "[ubuntu-rootfs-check] OK      e2scrub service entrypoint: /sbin/e2scrub_all"
  else
    echo "[ubuntu-rootfs-check] MISSING e2scrub service entrypoint: /sbin/e2scrub_all"
    systemd_missing=1
  fi

  if rootfs_symlink_points_to /etc/systemd/system/e2scrub_reap.service /dev/null; then
    echo "[ubuntu-rootfs-check] OK      boot-blocking e2scrub reap masked: /etc/systemd/system/e2scrub_reap.service"
  else
    echo "[ubuntu-rootfs-check] MISSING boot-blocking e2scrub reap mask"
    systemd_missing=1
  fi

  if rootfs_symlink_points_to /etc/systemd/system/e2scrub_all.timer /dev/null; then
    echo "[ubuntu-rootfs-check] OK      periodic e2scrub timer masked: /etc/systemd/system/e2scrub_all.timer"
  else
    echo "[ubuntu-rootfs-check] MISSING periodic e2scrub timer mask"
    systemd_missing=1
  fi

  if rootfs_has /etc/systemd/system/serial-getty@hvc0.service; then
    echo "[ubuntu-rootfs-check] OK      unavailable hvc0 getty masked: /etc/systemd/system/serial-getty@hvc0.service"
  else
    echo "[ubuntu-rootfs-check] MISSING unavailable hvc0 getty mask"
    systemd_missing=1
  fi

  if [ "$ROOTFS_FLAVOR" = "full" ]; then
    if rootfs_has /etc/ssh/sshd_config; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH server config: /etc/ssh/sshd_config"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH server config: /etc/ssh/sshd_config"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/passwd '^syslog:'; then
      echo "[ubuntu-rootfs-check] OK      syslog passwd entry: /etc/passwd"
    else
      echo "[ubuntu-rootfs-check] MISSING syslog passwd entry"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/group '^syslog:'; then
      echo "[ubuntu-rootfs-check] OK      syslog group entry: /etc/group"
    else
      echo "[ubuntu-rootfs-check] MISSING syslog group entry"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/passwd '^sshd:'; then
      echo "[ubuntu-rootfs-check] OK      sshd passwd entry: /etc/passwd"
    else
      echo "[ubuntu-rootfs-check] MISSING sshd passwd entry"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/group '^sshd:'; then
      echo "[ubuntu-rootfs-check] OK      sshd group entry: /etc/group"
    else
      echo "[ubuntu-rootfs-check] MISSING sshd group entry"
      systemd_missing=1
    fi

    if rootfs_has /etc/ssh/ssh_host_ed25519_key; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH ed25519 host key: /etc/ssh/ssh_host_ed25519_key"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH ed25519 host key"
      systemd_missing=1
    fi

    if rootfs_has /etc/ssh/ssh_host_rsa_key; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH rsa host key: /etc/ssh/ssh_host_rsa_key"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH rsa host key"
      systemd_missing=1
    fi

    if rootfs_has /var/spool/rsyslog; then
      echo "[ubuntu-rootfs-check] OK      rsyslog spool directory: /var/spool/rsyslog"
    else
      echo "[ubuntu-rootfs-check] MISSING rsyslog spool directory: /var/spool/rsyslog"
      systemd_missing=1
    fi

    if rootfs_symlink_points_to /etc/systemd/system/syslog.service /lib/systemd/system/rsyslog.service; then
      echo "[ubuntu-rootfs-check] OK      syslog service alias: /etc/systemd/system/syslog.service"
    else
      echo "[ubuntu-rootfs-check] MISSING syslog service alias"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/gpgv; then
      echo "[ubuntu-rootfs-check] OK      apt signature verifier: /usr/bin/gpgv"
    else
      echo "[ubuntu-rootfs-check] MISSING apt signature verifier: /usr/bin/gpgv"
      systemd_missing=1
    fi

    if rootfs_has /bin/journalctl; then
      echo "[ubuntu-rootfs-check] OK      journal query tool: /bin/journalctl"
    else
      echo "[ubuntu-rootfs-check] MISSING journal query tool: /bin/journalctl"
      systemd_missing=1
    fi

    if rootfs_has /bin/systemd-machine-id-setup; then
      echo "[ubuntu-rootfs-check] OK      machine-id setup tool: /bin/systemd-machine-id-setup"
    else
      echo "[ubuntu-rootfs-check] MISSING machine-id setup tool: /bin/systemd-machine-id-setup"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/hostnamectl; then
      echo "[ubuntu-rootfs-check] OK      hostnamectl tool: /usr/bin/hostnamectl"
    else
      echo "[ubuntu-rootfs-check] MISSING hostnamectl tool: /usr/bin/hostnamectl"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/systemd-hostnamed; then
      echo "[ubuntu-rootfs-check] OK      hostnamed service binary: /lib/systemd/systemd-hostnamed"
    else
      echo "[ubuntu-rootfs-check] MISSING hostnamed service binary: /lib/systemd/systemd-hostnamed"
      systemd_missing=1
    fi

    if rootfs_has /etc/machine-id; then
      echo "[ubuntu-rootfs-check] OK      machine-id seed file: /etc/machine-id"
    else
      echo "[ubuntu-rootfs-check] MISSING machine-id seed file: /etc/machine-id"
      systemd_missing=1
    fi

    if rootfs_has /etc/hostname; then
      echo "[ubuntu-rootfs-check] OK      hostname seed file: /etc/hostname"
    else
      echo "[ubuntu-rootfs-check] MISSING hostname seed file: /etc/hostname"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-machine-id-commit.service; then
      echo "[ubuntu-rootfs-check] OK      machine-id commit unit: /lib/systemd/system/systemd-machine-id-commit.service"
    else
      echo "[ubuntu-rootfs-check] MISSING machine-id commit unit: /lib/systemd/system/systemd-machine-id-commit.service"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-hostnamed.service; then
      echo "[ubuntu-rootfs-check] OK      hostnamed unit: /lib/systemd/system/systemd-hostnamed.service"
    else
      echo "[ubuntu-rootfs-check] MISSING hostnamed unit: /lib/systemd/system/systemd-hostnamed.service"
      systemd_missing=1
    fi

    if rootfs_has /bin/systemd-sysusers; then
      echo "[ubuntu-rootfs-check] OK      sysusers tool: /bin/systemd-sysusers"
    else
      echo "[ubuntu-rootfs-check] MISSING sysusers tool: /bin/systemd-sysusers"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-sysusers.service; then
      echo "[ubuntu-rootfs-check] OK      sysusers setup unit: /lib/systemd/system/systemd-sysusers.service"
    else
      echo "[ubuntu-rootfs-check] MISSING sysusers setup unit: /lib/systemd/system/systemd-sysusers.service"
      systemd_missing=1
    fi

    if rootfs_has /usr/lib/sysusers.d/basic.conf; then
      echo "[ubuntu-rootfs-check] OK      sysusers base config: /usr/lib/sysusers.d/basic.conf"
    else
      echo "[ubuntu-rootfs-check] MISSING sysusers base config: /usr/lib/sysusers.d/basic.conf"
      systemd_missing=1
    fi

    if rootfs_has /bin/systemd-tmpfiles; then
      echo "[ubuntu-rootfs-check] OK      tmpfiles tool: /bin/systemd-tmpfiles"
    else
      echo "[ubuntu-rootfs-check] MISSING tmpfiles tool: /bin/systemd-tmpfiles"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-tmpfiles-setup.service; then
      echo "[ubuntu-rootfs-check] OK      tmpfiles setup unit: /lib/systemd/system/systemd-tmpfiles-setup.service"
    else
      echo "[ubuntu-rootfs-check] MISSING tmpfiles setup unit: /lib/systemd/system/systemd-tmpfiles-setup.service"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/systemd-cat; then
      echo "[ubuntu-rootfs-check] OK      journal stdin tool: /usr/bin/systemd-cat"
    else
      echo "[ubuntu-rootfs-check] MISSING journal stdin tool: /usr/bin/systemd-cat"
      systemd_missing=1
    fi

    if rootfs_has /usr/share/keyrings/ubuntu-archive-keyring.gpg; then
      ubuntu_keyring_sha256="$(rootfs_cat /usr/share/keyrings/ubuntu-archive-keyring.gpg | sha256sum | awk '{print $1}')"
      echo "[ubuntu-rootfs-check] OK      Ubuntu archive keyring: /usr/share/keyrings/ubuntu-archive-keyring.gpg sha256=$ubuntu_keyring_sha256"
    else
      echo "[ubuntu-rootfs-check] MISSING Ubuntu archive keyring: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
      systemd_missing=1
    fi

    # chrootless full overlay 也必须维护 dpkg 状态库，否则 apt/dpkg 在 guest 内会
    # 看不到由 dpkg-deb 解包出来的 server-like 用户态组件。
    for package in systemd ubuntu-standard openssh-server curl wget dropbear-bin rsyslog cron systemd-timesyncd gpgv ubuntu-keyring; do
      if rootfs_dpkg_status_installed "$package"; then
        echo "[ubuntu-rootfs-check] OK      dpkg status installed: $package"
      else
        echo "[ubuntu-rootfs-check] MISSING dpkg status installed: $package"
        systemd_missing=1
      fi
    done
    for package in systemd ubuntu-standard openssh-server curl wget dropbear-bin rsyslog cron systemd-timesyncd gpgv ubuntu-keyring; do
      if rootfs_has "/var/lib/dpkg/info/$package.list"; then
        echo "[ubuntu-rootfs-check] OK      dpkg info list: $package"
      else
        echo "[ubuntu-rootfs-check] MISSING dpkg info list: $package"
        systemd_missing=1
      fi
    done

    dpkg_info_list_count=0
    dpkg_info_list_invalid=0
    while IFS= read -r list_name; do
      [ -n "$list_name" ] || continue
      package=${list_name%.list}
      dpkg_info_list_count=$((dpkg_info_list_count + 1))
      invalid_records=$(rootfs_dpkg_info_list_invalid_records "$package" || true)
      if [ -n "$invalid_records" ]; then
        echo "[ubuntu-rootfs-check] MISSING dpkg info list valid names: $package $invalid_records"
        dpkg_info_list_invalid=1
      fi
    done < <(rootfs_dpkg_info_list_files)
    if [ "$dpkg_info_list_count" -gt 0 ] && [ "$dpkg_info_list_invalid" -eq 0 ]; then
      echo "[ubuntu-rootfs-check] OK      dpkg info list valid names: $dpkg_info_list_count list files"
    else
      echo "[ubuntu-rootfs-check] MISSING dpkg info list valid names"
      systemd_missing=1
    fi

    for ownership in \
      "curl:/usr/bin/curl" \
      "wget:/usr/bin/wget" \
      "openssh-server:/usr/sbin/sshd" \
      "dropbear-bin:/usr/bin/dbclient" \
      "dropbear-bin:/usr/sbin/dropbear" \
      "rsyslog:/usr/sbin/rsyslogd" \
      "cron:/usr/sbin/cron" \
      "systemd:/bin/journalctl" \
      "systemd:/bin/systemd-machine-id-setup" \
      "systemd:/bin/systemd-sysusers" \
      "systemd:/bin/systemd-tmpfiles" \
      "systemd:/usr/bin/systemd-cat" \
      "systemd:/usr/bin/hostnamectl" \
      "systemd:/lib/systemd/systemd-hostnamed" \
      "systemd:/lib/systemd/system/systemd-machine-id-commit.service" \
      "systemd:/lib/systemd/system/systemd-hostnamed.service" \
      "gpgv:/usr/bin/gpgv" \
      "ubuntu-keyring:/usr/share/keyrings/ubuntu-archive-keyring.gpg"; do
      package=${ownership%%:*}
      path=${ownership#*:}
      if rootfs_dpkg_info_list_contains "$package" "$path"; then
        echo "[ubuntu-rootfs-check] OK      dpkg info ownership: $package $path"
      else
        echo "[ubuntu-rootfs-check] MISSING dpkg info ownership: $package $path"
        systemd_missing=1
      fi
    done
  fi
fi

if [ "$systemd_missing" -ne 0 ]; then
  missing=1
fi

flavor_missing=0
while IFS='|' read -r path label; do
  [ -n "$path" ] || continue
  if rootfs_has "$path"; then
    echo "[ubuntu-rootfs-check] OK      $label: $path"
  else
    echo "[ubuntu-rootfs-check] MISSING $label: $path"
    flavor_missing=1
  fi
done < <(ubuntu_rootfs_flavor_required_paths "$ROOTFS_FLAVOR")

if [ "$flavor_missing" -ne 0 ]; then
  echo "[ubuntu-rootfs-check] flavor $ROOTFS_FLAVOR is incomplete"
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[ubuntu-rootfs-check] rootfs readiness check passed"
