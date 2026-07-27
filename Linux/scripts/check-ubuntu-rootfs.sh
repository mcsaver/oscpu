#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
REQUIRE_SYSTEMD=${UBUNTU_ROOTFS_REQUIRE_SYSTEMD:-0}
REQUIRE_NPC_CONSOLE_SHELL=${UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL:-0}
REQUIRE_NPC_TTY_READER=${UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER:-0}
REQUIRE_NPC_STRICT_AUTORUN=${UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN:-0}
REQUIRE_NPC_LOGIN_MARKER=${UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER:-0}
REQUIRE_NPC_LOGIN_TRACE=${UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_TRACE:-0}
REQUIRE_NPC_GENERATOR_TRACE=${UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE:-0}
REQUIRE_NPC_GENERATOR_SKIP=${UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP:-}
REQUIRE_NPC_GENERATOR_SKIP_MODE=${UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE:-shell}
REQUIRE_NPC_GENERATOR_REAL_MODE=${UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE:-}
REQUIRE_NEMU_LOGIN_MARKER=${UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER:-0}
REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE=${UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE:-0}
EXPECT_NPC_SYSTEMD_GENERATORS=${UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS:-disabled}
DEBUGFS=${DEBUGFS:-debugfs}
ROOTFS_FLAVOR=${UBUNTU_ROOTFS_FLAVOR:-systemd-minimal}
ROOTFS_ARCH=${UBUNTU_ARCH:-riscv64}
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
  rootfs_cat "$path" | grep -Eq -- "$pattern"
}

rootfs_file_contains_binary() {
  local path=$1
  local pattern=$2
  rootfs_cat "$path" | grep -aEq -- "$pattern"
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
  local info_package
  for info_package in "$package" "$package:$ROOTFS_ARCH"; do
    rootfs_cat "/var/lib/dpkg/info/$info_package.list" | grep -Fxq "$path" &&
      return 0
  done
  return 1
}

rootfs_dpkg_info_list_exists() {
  local package=$1
  rootfs_has "/var/lib/dpkg/info/$package.list" ||
    rootfs_has "/var/lib/dpkg/info/$package:$ROOTFS_ARCH.list"
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
  if [ "$ROOTFS_FLAVOR" = "full" ]; then
    if rootfs_has /lib/riscv64-linux-gnu/security/pam_systemd.so; then
      echo "[ubuntu-rootfs-check] OK      PAM systemd session module: /lib/riscv64-linux-gnu/security/pam_systemd.so"
    else
      echo "[ubuntu-rootfs-check] MISSING PAM systemd session module: /lib/riscv64-linux-gnu/security/pam_systemd.so"
      systemd_missing=1
    fi
    if rootfs_file_contains /etc/pam.d/common-session '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_systemd\.so([[:space:]]|$)'; then
      echo "[ubuntu-rootfs-check] OK      PAM common-session systemd hook"
    else
      echo "[ubuntu-rootfs-check] MISSING PAM common-session systemd hook"
      systemd_missing=1
    fi
  fi

  if [ "$REQUIRE_NEMU_LOGIN_MARKER" = "1" ]; then
    if rootfs_file_contains /root/.profile '^  echo __NEMU_LOGIN_CHECK_BEGIN__$' &&
       rootfs_file_contains /root/.profile '^  echo "__NEMU_LOGIN_CHECK_DONE__ rc=\$check_fail"$'; then
      echo "[ubuntu-rootfs-check] OK      NEMU login shell marker: /root/.profile"
    else
      echo "[ubuntu-rootfs-check] MISSING NEMU login shell marker"
      systemd_missing=1
    fi

    if rootfs_file_contains /root/.profile 'pass ttyS0-login'; then
      echo "[ubuntu-rootfs-check] OK      NEMU login ttyS0 assertion"
    else
      echo "[ubuntu-rootfs-check] MISSING NEMU login ttyS0 assertion"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^ExecStart=-/sbin/agetty --autologin root '; then
      echo "[ubuntu-rootfs-check] OK      NEMU serial-getty autologin drop-in"
    else
      echo "[ubuntu-rootfs-check] MISSING NEMU serial-getty autologin drop-in"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^Wants=systemd-logind\.service$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^After=systemd-logind\.service systemd-user-sessions\.service plymouth-quit-wait\.service getty-pre\.target rc-local\.service$'; then
      echo "[ubuntu-rootfs-check] OK      NEMU serial-getty waits for logind before autologin"
    else
      echo "[ubuntu-rootfs-check] MISSING NEMU serial-getty logind ordering"
      systemd_missing=1
    fi
  fi

  if [ "$REQUIRE_NPC_LOGIN_MARKER" = "1" ]; then
    if rootfs_file_contains /root/.bash_profile '^  echo __NPC_LOGIN_CHECK_BEGIN__$' &&
       rootfs_file_contains /root/.bash_profile '^  echo "__NPC_LOGIN_CHECK_DONE__ rc=\$check_fail"$'; then
      echo "[ubuntu-rootfs-check] OK      NPC login shell marker: /root/.bash_profile"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login shell marker"
      systemd_missing=1
    fi

    if rootfs_file_contains /root/.bash_profile 'pass ttyS0-login'; then
      echo "[ubuntu-rootfs-check] OK      NPC login ttyS0 assertion"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login ttyS0 assertion"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/profile '^# NPC_LOGIN_MARKER_MINIMAL_ETC_PROFILE$'; then
      echo "[ubuntu-rootfs-check] OK      NPC login minimal /etc/profile"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login minimal /etc/profile"
      systemd_missing=1
    fi

    if rootfs_has /root/.hushlogin; then
      echo "[ubuntu-rootfs-check] OK      NPC login MOTD suppressed: /root/.hushlogin"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login MOTD suppression"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/pam.d/login '^# NPC_LOGIN_MARKER_DISABLED[[:space:]]+auth[[:space:]]+optional[[:space:]]+pam_faildelay\.so[[:space:]]+delay=3000000$' &&
       rootfs_file_contains /etc/pam.d/login '^# NPC_LOGIN_MARKER_DISABLED[[:space:]]+session[[:space:]]+optional[[:space:]]+pam_motd\.so motd=/run/motd\.dynamic$' &&
       rootfs_file_contains /etc/pam.d/login '^# NPC_LOGIN_MARKER_DISABLED[[:space:]]+session[[:space:]]+optional[[:space:]]+pam_motd\.so noupdate$' &&
       rootfs_file_contains /etc/pam.d/login '^# NPC_LOGIN_MARKER_DISABLED[[:space:]]+session[[:space:]]+optional[[:space:]]+pam_lastlog\.so$' &&
       rootfs_file_contains /etc/pam.d/login '^# NPC_LOGIN_MARKER_DISABLED[[:space:]]+session[[:space:]]+optional[[:space:]]+pam_mail\.so standard$'; then
      echo "[ubuntu-rootfs-check] OK      NPC login PAM faildelay/motd/mail/lastlog disabled"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login PAM faildelay/optional-module trim"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^ExecStart=-/sbin/agetty --autologin root '; then
      echo "[ubuntu-rootfs-check] OK      ttyS0 serial-getty autologin drop-in"
    else
      echo "[ubuntu-rootfs-check] MISSING ttyS0 serial-getty autologin drop-in"
      systemd_missing=1
    fi

    if [ "$REQUIRE_NPC_LOGIN_TRACE" = "1" ]; then
      if rootfs_has /usr/local/sbin/ysyx-npc-login-trace &&
         rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '--login-program /usr/local/sbin/ysyx-npc-login-trace' &&
         rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '--login-program /usr/local/sbin/ysyx-npc-login-trace'; then
        echo "[ubuntu-rootfs-check] OK      NPC login trace wrapper"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC login trace wrapper"
        systemd_missing=1
      fi
    fi

    if [ "$REQUIRE_NPC_GENERATOR_TRACE" = "1" ]; then
      if rootfs_has /usr/local/lib/ysyx-npc-system-generators/lib/systemd-fstab-generator &&
         ! rootfs_has /lib/systemd/system-generators/systemd-fstab-generator.ysyx-real &&
         ! rootfs_has /usr/lib/systemd/system-generators/systemd-fstab-generator.ysyx-real &&
         rootfs_file_contains /lib/systemd/system-generators/systemd-fstab-generator '__NPC_GENERATOR_BEGIN__'; then
        echo "[ubuntu-rootfs-check] OK      NPC systemd generator trace wrappers"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC systemd generator trace wrappers"
        systemd_missing=1
      fi
      if [ -n "$REQUIRE_NPC_GENERATOR_SKIP" ]; then
        if [ "$REQUIRE_NPC_GENERATOR_SKIP_MODE" = "static" ]; then
          if rootfs_has /usr/local/sbin/ysyx-npc-generator-skip &&
             rootfs_file_contains /etc/ysyx-npc-generator-skip-list "^$REQUIRE_NPC_GENERATOR_SKIP$" &&
             rootfs_file_contains_binary /lib/systemd/system-generators/systemd-fstab-generator '__NPC_GENERATOR_STATIC_SKIP__' &&
             rootfs_file_contains_binary /lib/systemd/system-generators/systemd-fstab-generator '__NPC_GENERATOR_SKIP__'; then
            echo "[ubuntu-rootfs-check] OK      NPC systemd generator static skip wrappers"
          else
            echo "[ubuntu-rootfs-check] MISSING NPC systemd generator static skip wrappers"
            systemd_missing=1
          fi
          if [ -n "$REQUIRE_NPC_GENERATOR_REAL_MODE" ]; then
            if rootfs_file_contains /etc/ysyx-npc-generator-real-mode "^$REQUIRE_NPC_GENERATOR_REAL_MODE$"; then
              echo "[ubuntu-rootfs-check] OK      NPC systemd generator static real mode: $REQUIRE_NPC_GENERATOR_REAL_MODE"
            else
              echo "[ubuntu-rootfs-check] MISSING NPC systemd generator static real mode: $REQUIRE_NPC_GENERATOR_REAL_MODE"
              systemd_missing=1
            fi
          fi
        else
          if rootfs_file_contains /lib/systemd/system-generators/systemd-fstab-generator '__NPC_GENERATOR_SKIP__' &&
             rootfs_file_contains /lib/systemd/system-generators/systemd-fstab-generator "skip_list=\"$REQUIRE_NPC_GENERATOR_SKIP\""; then
            echo "[ubuntu-rootfs-check] OK      NPC systemd generator skip wrappers"
          else
            echo "[ubuntu-rootfs-check] MISSING NPC systemd generator skip wrappers"
            systemd_missing=1
          fi
        fi
      fi
    fi

    if rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^BindsTo=$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^After=$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf '^After=getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service$'; then
      echo "[ubuntu-rootfs-check] OK      ttyS0 serial-getty skips device and late boot waits"
    else
      echo "[ubuntu-rootfs-check] MISSING ttyS0 serial-getty early-login override"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '^ExecStart=-/sbin/agetty --autologin root ' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '^DefaultDependencies=no$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '^After=getty-pre.target systemd-remount-fs.service systemd-tmpfiles-setup-dev.service systemd-udevd.service$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '^Before=systemd-udev-trigger.service sysinit.target getty.target$' &&
       rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service '^Type=simple$' &&
       ! rootfs_file_contains /etc/systemd/system/serial-getty@ttyS0.service 'dev-%i\.device|^TTYPath=|systemd-user-sessions.service|plymouth-quit-wait.service|rc-local.service' &&
       rootfs_symlink_points_to /etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service ../serial-getty@ttyS0.service &&
       rootfs_symlink_points_to /etc/systemd/system/sysinit.target.wants/serial-getty@ttyS0.service ../serial-getty@ttyS0.service; then
      echo "[ubuntu-rootfs-check] OK      ttyS0 serial-getty instance starts early without device-unit dependency"
    else
      echo "[ubuntu-rootfs-check] MISSING ttyS0 serial-getty early instance"
      systemd_missing=1
    fi

    if rootfs_symlink_points_to /etc/systemd/system/default.target /lib/systemd/system/multi-user.target; then
      echo "[ubuntu-rootfs-check] OK      NPC login default target: multi-user.target"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login multi-user default target"
      systemd_missing=1
    fi

    plymouth_mask_missing=0
    for unit in \
      plymouth-read-write.service \
      plymouth-start.service \
      plymouth-quit.service \
      plymouth-quit-wait.service; do
      if ! rootfs_symlink_points_to "/etc/systemd/system/$unit" /dev/null; then
        plymouth_mask_missing=1
      fi
    done
    if [ "$plymouth_mask_missing" -eq 0 ]; then
      echo "[ubuntu-rootfs-check] OK      NPC login plymouth splash units masked"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC login plymouth unit masks"
      systemd_missing=1
    fi
  fi

  if [ "$REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE" = "1" ]; then
    if rootfs_has /etc/.updated && rootfs_has /var/.updated; then
      echo "[ubuntu-rootfs-check] OK      systemd update-done stamps preseeded"
    else
      echo "[ubuntu-rootfs-check] MISSING systemd update-done preseed stamps"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/passwd '^systemd-network:' &&
       rootfs_file_contains /etc/passwd '^messagebus:' &&
       rootfs_file_contains /etc/passwd '^systemd-timesync:' &&
       rootfs_file_contains /etc/passwd '^systemd-resolve:' &&
       rootfs_file_contains /etc/group '^systemd-journal:'; then
      echo "[ubuntu-rootfs-check] OK      sysusers entries preseeded"
    else
      echo "[ubuntu-rootfs-check] MISSING sysusers preseeded passwd/group entries"
      systemd_missing=1
    fi
  fi

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

  if rootfs_file_contains /etc/machine-id '^[0-9a-f]{32}$'; then
    echo "[ubuntu-rootfs-check] OK      deterministic machine-id seed: /etc/machine-id"
  else
    echo "[ubuntu-rootfs-check] MISSING deterministic machine-id seed"
    systemd_missing=1
  fi

  if [ "$REQUIRE_NPC_CONSOLE_SHELL" = "1" ]; then
    if rootfs_has /usr/local/sbin/ysyx-npc-console-shell; then
      echo "[ubuntu-rootfs-check] OK      NPC console shell hook: /usr/local/sbin/ysyx-npc-console-shell"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC console shell hook"
      systemd_missing=1
    fi

    if rootfs_file_contains /usr/local/sbin/ysyx-npc-console-shell '^echo __NPC_CONSOLE_SHELL_READY__$'; then
      echo "[ubuntu-rootfs-check] OK      NPC console shell ready marker"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC console shell ready marker"
      systemd_missing=1
    fi

    if rootfs_has /usr/local/sbin/ysyx-npc-systemd-wrapper; then
      echo "[ubuntu-rootfs-check] OK      NPC systemd wrapper: /usr/local/sbin/ysyx-npc-systemd-wrapper"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC systemd wrapper"
      systemd_missing=1
    fi

    if rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-wrapper '^echo __NPC_SYSTEMD_PREFLIGHT_BEGIN__$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-wrapper '^pass\(\) \{ echo "__NPC_PREFLIGHT_PASS__:\$1"; \}$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-wrapper '^echo "__NPC_SYSTEMD_PREFLIGHT_DONE__ rc=\$check_fail"$'; then
      echo "[ubuntu-rootfs-check] OK      NPC bounded systemd preflight markers"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC bounded systemd preflight markers"
      systemd_missing=1
    fi

    if rootfs_has /usr/local/sbin/ysyx-npc-systemd-autocheck; then
      echo "[ubuntu-rootfs-check] OK      NPC systemd autocheck: /usr/local/sbin/ysyx-npc-systemd-autocheck"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC systemd autocheck"
      systemd_missing=1
    fi

    if rootfs_has /usr/local/sbin/ysyx-npc-systemd-strict-check; then
      echo "[ubuntu-rootfs-check] OK      NPC strict guest check: /usr/local/sbin/ysyx-npc-systemd-strict-check"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC strict guest check"
      systemd_missing=1
    fi

    if rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-strict-check '^    done_marker=__NPC_SYSTEMD_STRICT_DONE__$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-strict-check '^echo "\$done_marker rc=\$check_fail"$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-strict-check 'pass virtio-blk-direct-read' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-strict-check '^  systemctl --no-wall poweroff '; then
      echo "[ubuntu-rootfs-check] OK      NPC strict guest markers and virtio-blk check"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC strict guest markers or virtio-blk check"
      systemd_missing=1
    fi

    npc_tty_reader_present=0
    if rootfs_has /usr/local/sbin/ysyx-npc-tty-reader; then
      npc_tty_reader_present=1
      echo "[ubuntu-rootfs-check] OK      NPC tty reader diagnostic: /usr/local/sbin/ysyx-npc-tty-reader"
    elif [ "$REQUIRE_NPC_TTY_READER" = "1" ]; then
      echo "[ubuntu-rootfs-check] MISSING NPC tty reader diagnostic"
      systemd_missing=1
    fi

    if [ "$npc_tty_reader_present" = "1" ] || [ "$REQUIRE_NPC_TTY_READER" = "1" ]; then
      if rootfs_file_contains /usr/local/sbin/ysyx-npc-tty-reader '^[[:space:]]*echo __NPC_TTY_READER_READY__$' &&
         rootfs_file_contains /usr/local/sbin/ysyx-npc-tty-reader '^[[:space:]]*echo "__NPC_TTY_READER_DONE__ rc=0"$'; then
        echo "[ubuntu-rootfs-check] OK      NPC tty reader markers"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC tty reader markers"
        systemd_missing=1
      fi
    fi

    if rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-autocheck '^echo __NPC_SYSTEMD_AUTOCHECK_BEGIN__$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-autocheck '^pass\(\) \{ echo "__NPC_AUTOCHECK_PASS__:\$1"; \}$' &&
       rootfs_file_contains /usr/local/sbin/ysyx-npc-systemd-autocheck '^echo "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=\$check_fail"$'; then
      echo "[ubuntu-rootfs-check] OK      NPC bounded systemd autocheck markers"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC bounded systemd autocheck markers"
      systemd_missing=1
    fi

    if rootfs_has /etc/systemd/system/ysyx-npc-systemd-autocheck.service; then
      echo "[ubuntu-rootfs-check] OK      NPC systemd autocheck unit: /etc/systemd/system/ysyx-npc-systemd-autocheck.service"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC systemd autocheck unit"
      systemd_missing=1
    fi

    if rootfs_has /etc/systemd/system/ysyx-npc-systemd-strict.service; then
      echo "[ubuntu-rootfs-check] OK      NPC strict rootfs unit: /etc/systemd/system/ysyx-npc-systemd-strict.service"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC strict rootfs unit"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^After=ysyx-npc-systemd-autocheck\.service$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^Before=sysinit\.target$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^StandardInput=null$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^StandardOutput=tty$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^TTYPath=/dev/ttyS0$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-strict.service '^ExecStart=/usr/local/sbin/ysyx-npc-systemd-strict-check --stage strict --poweroff$'; then
      echo "[ubuntu-rootfs-check] OK      NPC strict rootfs unit ordering and ttyS0 output"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC strict rootfs unit ordering or command"
      systemd_missing=1
    fi

    if [ "$REQUIRE_NPC_STRICT_AUTORUN" = "1" ]; then
      if rootfs_symlink_points_to /etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-strict.service ../ysyx-npc-systemd-strict.service; then
        echo "[ubuntu-rootfs-check] OK      NPC strict rootfs unit enabled for sysinit.target"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC strict rootfs sysinit.target enablement"
        systemd_missing=1
      fi
    elif rootfs_has /etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-strict.service; then
      echo "[ubuntu-rootfs-check] MISMATCH NPC strict rootfs unit enabled in non-autorun image"
      systemd_missing=1
    else
      echo "[ubuntu-rootfs-check] OK      NPC strict rootfs unit disabled in non-autorun image"
    fi

    npc_tty_reader_unit_present=0
    if rootfs_has /etc/systemd/system/ysyx-npc-tty-reader.service; then
      npc_tty_reader_unit_present=1
      echo "[ubuntu-rootfs-check] OK      NPC tty reader unit: /etc/systemd/system/ysyx-npc-tty-reader.service"
    elif [ "$REQUIRE_NPC_TTY_READER" = "1" ]; then
      echo "[ubuntu-rootfs-check] MISSING NPC tty reader unit"
      systemd_missing=1
    fi

    if [ "$npc_tty_reader_unit_present" = "1" ] || [ "$REQUIRE_NPC_TTY_READER" = "1" ]; then
      if rootfs_file_contains /etc/systemd/system/ysyx-npc-tty-reader.service '^StandardInput=tty-force$' &&
         rootfs_file_contains /etc/systemd/system/ysyx-npc-tty-reader.service '^TTYPath=/dev/ttyS0$' &&
         rootfs_file_contains /etc/systemd/system/ysyx-npc-tty-reader.service '^Before=.*ysyx-npc-systemd-autocheck\.service'; then
        echo "[ubuntu-rootfs-check] OK      NPC tty reader ttyS0 ordering"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC tty reader ttyS0 ordering"
        systemd_missing=1
      fi
    fi

    if rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-autocheck.service '^Before=.*systemd-sysusers\.service' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-autocheck.service '^Before=.*systemd-udev-trigger\.service' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-autocheck.service '^StandardOutput=tty$' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-systemd-autocheck.service '^TTYPath=/dev/ttyS0$'; then
      echo "[ubuntu-rootfs-check] OK      NPC systemd autocheck early ttyS0 ordering"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC systemd autocheck early ttyS0 ordering"
      systemd_missing=1
    fi

    if rootfs_symlink_points_to /etc/systemd/system/sysinit.target.wants/ysyx-npc-systemd-autocheck.service ../ysyx-npc-systemd-autocheck.service; then
      echo "[ubuntu-rootfs-check] OK      NPC systemd autocheck enabled for sysinit.target"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC systemd autocheck sysinit.target enablement"
      systemd_missing=1
    fi

    if [ "$REQUIRE_NPC_TTY_READER" = "1" ]; then
      if rootfs_symlink_points_to /etc/systemd/system/sysinit.target.wants/ysyx-npc-tty-reader.service ../ysyx-npc-tty-reader.service; then
        echo "[ubuntu-rootfs-check] OK      NPC tty reader enabled for sysinit.target"
      else
        echo "[ubuntu-rootfs-check] MISSING NPC tty reader sysinit.target enablement"
        systemd_missing=1
      fi
    elif rootfs_symlink_points_to /etc/systemd/system/sysinit.target.wants/ysyx-npc-console-shell.service ../ysyx-npc-console-shell.service; then
      echo "[ubuntu-rootfs-check] OK      NPC console shell enabled for sysinit.target"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC console shell sysinit.target enablement"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/ysyx-npc-console-shell.service '^Before=.*systemd-sysusers\.service' &&
       rootfs_file_contains /etc/systemd/system/ysyx-npc-console-shell.service '^Before=.*systemd-udev-trigger\.service'; then
      echo "[ubuntu-rootfs-check] OK      NPC console shell ordered before early sysinit blockers"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC console shell early sysinit ordering"
      systemd_missing=1
    fi

    if rootfs_file_contains /etc/systemd/system/ysyx-npc-console-shell.service '^TTYPath=/dev/ttyS0$'; then
      echo "[ubuntu-rootfs-check] OK      NPC console shell bound to ttyS0"
    else
      echo "[ubuntu-rootfs-check] MISSING NPC console shell ttyS0 binding"
      systemd_missing=1
    fi

    case "$EXPECT_NPC_SYSTEMD_GENERATORS" in
      disabled)
        if rootfs_has /usr/local/share/ysyx-disabled-system-generators/systemd-fstab-generator &&
           ! rootfs_has /lib/systemd/system-generators/systemd-fstab-generator; then
          echo "[ubuntu-rootfs-check] OK      NPC systemd generators disabled for staged gate"
        else
          echo "[ubuntu-rootfs-check] MISSING NPC systemd generator disablement"
          systemd_missing=1
        fi
        ;;
      enabled)
        if rootfs_has /lib/systemd/system-generators/systemd-fstab-generator &&
           ! rootfs_has /usr/local/share/ysyx-disabled-system-generators/systemd-fstab-generator; then
          echo "[ubuntu-rootfs-check] OK      NPC systemd generators enabled"
        else
          echo "[ubuntu-rootfs-check] MISSING NPC systemd generator enablement"
          systemd_missing=1
        fi
        ;;
      any)
        if rootfs_has /lib/systemd/system-generators/systemd-fstab-generator; then
          echo "[ubuntu-rootfs-check] OK      NPC systemd generators present"
        elif rootfs_has /usr/local/share/ysyx-disabled-system-generators/systemd-fstab-generator; then
          echo "[ubuntu-rootfs-check] OK      NPC systemd generators disabled for staged gate"
        else
          echo "[ubuntu-rootfs-check] MISSING NPC systemd generator state"
          systemd_missing=1
        fi
        ;;
      *)
        echo "[ubuntu-rootfs-check] invalid UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=$EXPECT_NPC_SYSTEMD_GENERATORS" >&2
        exit 1
        ;;
    esac
  fi

  if rootfs_has /etc/systemd/system/serial-getty@hvc0.service; then
    echo "[ubuntu-rootfs-check] OK      unavailable hvc0 getty masked: /etc/systemd/system/serial-getty@hvc0.service"
  else
    echo "[ubuntu-rootfs-check] MISSING unavailable hvc0 getty mask"
    systemd_missing=1
  fi

  if [ "$ROOTFS_FLAVOR" = "full" ]; then
    if rootfs_has /bin/su; then
      echo "[ubuntu-rootfs-check] OK      PAM su command: /bin/su"
    else
      echo "[ubuntu-rootfs-check] MISSING PAM su command: /bin/su"
      systemd_missing=1
    fi

    if rootfs_has /etc/pam.d/su; then
      echo "[ubuntu-rootfs-check] OK      PAM su config: /etc/pam.d/su"
    else
      echo "[ubuntu-rootfs-check] MISSING PAM su config: /etc/pam.d/su"
      systemd_missing=1
    fi

    if rootfs_has /usr/sbin/groupadd; then
      echo "[ubuntu-rootfs-check] OK      account groupadd command: /usr/sbin/groupadd"
    else
      echo "[ubuntu-rootfs-check] MISSING account groupadd command: /usr/sbin/groupadd"
      systemd_missing=1
    fi

    if rootfs_has /usr/sbin/groupdel; then
      echo "[ubuntu-rootfs-check] OK      account groupdel command: /usr/sbin/groupdel"
    else
      echo "[ubuntu-rootfs-check] MISSING account groupdel command: /usr/sbin/groupdel"
      systemd_missing=1
    fi

    if rootfs_has /usr/sbin/useradd; then
      echo "[ubuntu-rootfs-check] OK      account useradd command: /usr/sbin/useradd"
    else
      echo "[ubuntu-rootfs-check] MISSING account useradd command: /usr/sbin/useradd"
      systemd_missing=1
    fi

    if rootfs_has /usr/sbin/userdel; then
      echo "[ubuntu-rootfs-check] OK      account userdel command: /usr/sbin/userdel"
    else
      echo "[ubuntu-rootfs-check] MISSING account userdel command: /usr/sbin/userdel"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/passwd; then
      echo "[ubuntu-rootfs-check] OK      account passwd command: /usr/bin/passwd"
    else
      echo "[ubuntu-rootfs-check] MISSING account passwd command: /usr/bin/passwd"
      systemd_missing=1
    fi

    if rootfs_has /etc/default/useradd; then
      echo "[ubuntu-rootfs-check] OK      account useradd defaults: /etc/default/useradd"
    else
      echo "[ubuntu-rootfs-check] MISSING account useradd defaults: /etc/default/useradd"
      systemd_missing=1
    fi

    if rootfs_has /etc/login.defs; then
      echo "[ubuntu-rootfs-check] OK      login defaults: /etc/login.defs"
    else
      echo "[ubuntu-rootfs-check] MISSING login defaults: /etc/login.defs"
      systemd_missing=1
    fi

    if rootfs_has /etc/ssh/sshd_config; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH server config: /etc/ssh/sshd_config"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH server config: /etc/ssh/sshd_config"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/ssh; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH client command: /usr/bin/ssh"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH client command: /usr/bin/ssh"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/ssh-keygen; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH keygen command: /usr/bin/ssh-keygen"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH keygen command: /usr/bin/ssh-keygen"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/scp; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH scp command: /usr/bin/scp"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH scp command: /usr/bin/scp"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/sftp; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH sftp command: /usr/bin/sftp"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH sftp command: /usr/bin/sftp"
      systemd_missing=1
    fi

    if rootfs_has /usr/lib/openssh/sftp-server; then
      echo "[ubuntu-rootfs-check] OK      OpenSSH sftp server: /usr/lib/openssh/sftp-server"
    else
      echo "[ubuntu-rootfs-check] MISSING OpenSSH sftp server: /usr/lib/openssh/sftp-server"
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

    if rootfs_has /usr/bin/systemd-analyze; then
      echo "[ubuntu-rootfs-check] OK      systemd-analyze tool: /usr/bin/systemd-analyze"
    else
      echo "[ubuntu-rootfs-check] MISSING systemd-analyze tool: /usr/bin/systemd-analyze"
      systemd_missing=1
    fi

    if rootfs_has /usr/bin/timedatectl; then
      echo "[ubuntu-rootfs-check] OK      timedatectl tool: /usr/bin/timedatectl"
    else
      echo "[ubuntu-rootfs-check] MISSING timedatectl tool: /usr/bin/timedatectl"
      systemd_missing=1
    fi

    if rootfs_has /usr/sbin/netplan; then
      echo "[ubuntu-rootfs-check] OK      netplan tool: /usr/sbin/netplan"
    else
      echo "[ubuntu-rootfs-check] MISSING netplan tool: /usr/sbin/netplan"
      systemd_missing=1
    fi

    if rootfs_has /usr/share/netplan/netplan.script; then
      echo "[ubuntu-rootfs-check] OK      netplan command script: /usr/share/netplan/netplan.script"
    else
      echo "[ubuntu-rootfs-check] MISSING netplan command script: /usr/share/netplan/netplan.script"
      systemd_missing=1
    fi

    if rootfs_has /etc/netplan; then
      echo "[ubuntu-rootfs-check] OK      netplan config directory: /etc/netplan"
    else
      echo "[ubuntu-rootfs-check] MISSING netplan config directory: /etc/netplan"
      systemd_missing=1
    fi

    if rootfs_has /lib/netplan/generate; then
      echo "[ubuntu-rootfs-check] OK      netplan generator binary: /lib/netplan/generate"
    else
      echo "[ubuntu-rootfs-check] MISSING netplan generator binary: /lib/netplan/generate"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system-generators/netplan; then
      echo "[ubuntu-rootfs-check] OK      netplan systemd generator: /lib/systemd/system-generators/netplan"
    else
      echo "[ubuntu-rootfs-check] MISSING netplan systemd generator: /lib/systemd/system-generators/netplan"
      systemd_missing=1
    fi

    if rootfs_has /bin/networkctl; then
      echo "[ubuntu-rootfs-check] OK      networkctl tool: /bin/networkctl"
    else
      echo "[ubuntu-rootfs-check] MISSING networkctl tool: /bin/networkctl"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/systemd-networkd; then
      echo "[ubuntu-rootfs-check] OK      networkd service binary: /lib/systemd/systemd-networkd"
    else
      echo "[ubuntu-rootfs-check] MISSING networkd service binary: /lib/systemd/systemd-networkd"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-networkd.service; then
      echo "[ubuntu-rootfs-check] OK      networkd service unit: /lib/systemd/system/systemd-networkd.service"
    else
      echo "[ubuntu-rootfs-check] MISSING networkd service unit: /lib/systemd/system/systemd-networkd.service"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/systemd-networkd-wait-online; then
      echo "[ubuntu-rootfs-check] OK      networkd wait-online binary: /lib/systemd/systemd-networkd-wait-online"
    else
      echo "[ubuntu-rootfs-check] MISSING networkd wait-online binary: /lib/systemd/systemd-networkd-wait-online"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-networkd-wait-online.service; then
      echo "[ubuntu-rootfs-check] OK      networkd wait-online unit: /lib/systemd/system/systemd-networkd-wait-online.service"
    else
      echo "[ubuntu-rootfs-check] MISSING networkd wait-online unit: /lib/systemd/system/systemd-networkd-wait-online.service"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/network-online.target; then
      echo "[ubuntu-rootfs-check] OK      network-online target unit: /lib/systemd/system/network-online.target"
    else
      echo "[ubuntu-rootfs-check] MISSING network-online target unit: /lib/systemd/system/network-online.target"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/graphical.target; then
      echo "[ubuntu-rootfs-check] OK      graphical target unit: /lib/systemd/system/graphical.target"
    else
      echo "[ubuntu-rootfs-check] MISSING graphical target unit: /lib/systemd/system/graphical.target"
      systemd_missing=1
    fi

    if rootfs_has /etc/systemd/network; then
      echo "[ubuntu-rootfs-check] OK      networkd config directory: /etc/systemd/network"
    else
      echo "[ubuntu-rootfs-check] MISSING networkd config directory: /etc/systemd/network"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/systemd-timedated; then
      echo "[ubuntu-rootfs-check] OK      timedated service binary: /lib/systemd/systemd-timedated"
    else
      echo "[ubuntu-rootfs-check] MISSING timedated service binary: /lib/systemd/systemd-timedated"
      systemd_missing=1
    fi

    if rootfs_has /lib/systemd/system/systemd-timedated.service; then
      echo "[ubuntu-rootfs-check] OK      timedated service unit: /lib/systemd/system/systemd-timedated.service"
    else
      echo "[ubuntu-rootfs-check] MISSING timedated service unit: /lib/systemd/system/systemd-timedated.service"
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
    for package in systemd ubuntu-standard openssh-client openssh-server openssh-sftp-server curl wget dropbear-bin rsyslog cron anacron logrotate systemd-timesyncd systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring netplan.io netplan-generator passwd locales libc-bin; do
      if rootfs_dpkg_status_installed "$package"; then
        echo "[ubuntu-rootfs-check] OK      dpkg status installed: $package"
      else
        echo "[ubuntu-rootfs-check] MISSING dpkg status installed: $package"
        systemd_missing=1
      fi
    done
    for package in systemd ubuntu-standard openssh-client openssh-server openssh-sftp-server curl wget dropbear-bin rsyslog cron anacron logrotate systemd-timesyncd systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring netplan.io netplan-generator passwd locales libc-bin; do
      if rootfs_dpkg_info_list_exists "$package"; then
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
      "openssh-client:/usr/bin/ssh" \
      "openssh-client:/usr/bin/ssh-keygen" \
      "openssh-client:/usr/bin/scp" \
      "openssh-client:/usr/bin/sftp" \
      "openssh-server:/usr/sbin/sshd" \
      "openssh-sftp-server:/usr/lib/openssh/sftp-server" \
      "dropbear-bin:/usr/bin/dbclient" \
      "dropbear-bin:/usr/sbin/dropbear" \
      "rsyslog:/usr/sbin/rsyslogd" \
      "cron:/usr/sbin/cron" \
      "cron:/etc/crontab" \
      "cron:/etc/cron.d" \
      "cron:/etc/cron.daily" \
      "anacron:/usr/sbin/anacron" \
      "anacron:/etc/anacrontab" \
      "anacron:/etc/cron.d/anacron" \
      "anacron:/etc/cron.daily/0anacron" \
      "anacron:/etc/cron.weekly/0anacron" \
      "anacron:/etc/cron.monthly/0anacron" \
      "anacron:/var/spool/anacron" \
      "anacron:/lib/systemd/system/anacron.service" \
      "anacron:/lib/systemd/system/anacron.timer" \
      "logrotate:/usr/sbin/logrotate" \
      "logrotate:/etc/logrotate.conf" \
      "logrotate:/lib/systemd/system/logrotate.service" \
      "logrotate:/lib/systemd/system/logrotate.timer" \
      "systemd-oomd:/lib/systemd/systemd-oomd" \
      "systemd-oomd:/lib/systemd/system/systemd-oomd.service" \
      "systemd-oomd:/usr/bin/oomctl" \
      "systemd-oomd:/etc/systemd/oomd.conf" \
      "systemd-oomd:/usr/lib/systemd/oomd.conf.d/10-oomd-defaults.conf" \
      "systemd-oomd:/usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf" \
      "systemd-oomd:/usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf" \
      "systemd-oomd:/usr/lib/sysusers.d/systemd-oom.conf" \
      "systemd-oomd:/usr/share/dbus-1/system-services/org.freedesktop.oom1.service" \
      "systemd-oomd:/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf" \
      "locales:/usr/sbin/locale-gen" \
      "locales:/usr/share/i18n/SUPPORTED" \
      "libc-bin:/usr/bin/localedef" \
      "systemd:/bin/journalctl" \
      "systemd:/bin/systemd-machine-id-setup" \
      "systemd:/bin/systemd-sysusers" \
      "systemd:/bin/systemd-tmpfiles" \
      "systemd:/usr/bin/systemd-analyze" \
      "systemd:/usr/bin/systemd-run" \
      "systemd:/usr/bin/systemd-cat" \
      "systemd:/usr/bin/hostnamectl" \
      "systemd:/usr/bin/timedatectl" \
      "netplan.io:/usr/sbin/netplan" \
      "netplan.io:/usr/share/netplan/netplan.script" \
      "netplan-generator:/etc/netplan" \
      "netplan-generator:/lib/netplan/generate" \
      "netplan-generator:/lib/systemd/system-generators/netplan" \
      "systemd:/bin/networkctl" \
      "systemd:/usr/bin/resolvectl" \
      "systemd:/bin/loginctl" \
      "systemd:/lib/systemd/systemd-logind" \
      "systemd:/lib/systemd/systemd-networkd" \
      "systemd:/lib/systemd/systemd-resolved" \
      "systemd:/lib/systemd/systemd-hostnamed" \
      "systemd:/lib/systemd/systemd-timedated" \
      "systemd:/lib/systemd/system/systemd-logind.service" \
      "systemd:/lib/systemd/system/systemd-networkd.service" \
      "systemd:/lib/systemd/systemd-networkd-wait-online" \
      "systemd:/lib/systemd/system/systemd-networkd-wait-online.service" \
      "systemd:/lib/systemd/system/network-online.target" \
      "systemd:/lib/systemd/system/graphical.target" \
      "systemd:/lib/systemd/system/systemd-resolved.service" \
      "systemd:/lib/systemd/system/systemd-machine-id-commit.service" \
      "systemd:/lib/systemd/system/systemd-hostnamed.service" \
      "systemd:/lib/systemd/system/systemd-timedated.service" \
      "systemd:/etc/systemd/resolved.conf" \
      "systemd:/lib/systemd/system/user@.service" \
      "systemd:/lib/systemd/system/user-runtime-dir@.service" \
      "dbus-user-session:/usr/lib/systemd/user/dbus.socket" \
      "dbus-user-session:/usr/lib/systemd/user/dbus.service" \
      "dbus-user-session:/usr/lib/systemd/user/sockets.target.wants/dbus.socket" \
      "libpam-systemd:/lib/riscv64-linux-gnu/security/pam_systemd.so" \
      "gpgv:/usr/bin/gpgv" \
      "ubuntu-keyring:/usr/share/keyrings/ubuntu-archive-keyring.gpg" \
      "passwd:/usr/sbin/groupadd" \
      "passwd:/usr/sbin/groupdel" \
      "passwd:/usr/sbin/useradd" \
      "passwd:/usr/sbin/userdel" \
      "passwd:/usr/bin/passwd" \
      "passwd:/etc/default/useradd"; do
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
