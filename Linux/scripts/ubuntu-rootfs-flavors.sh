#!/usr/bin/env bash

# 统一维护 Ubuntu rootfs flavor，避免 debootstrap 与 chrootless overlay
# 各自散落包清单，导致 minimized/full 路线的完成口径漂移。

ubuntu_rootfs_flavor_normalize() {
  local flavor=${1:-systemd-minimal}
  case "$flavor" in
    systemd-minimal|minimal)
      printf '%s\n' systemd-minimal
      ;;
    interactive)
      printf '%s\n' interactive
      ;;
    full|standard)
      printf '%s\n' full
      ;;
    *)
      echo "[ubuntu-rootfs-flavors] unknown UBUNTU_ROOTFS_FLAVOR=$flavor" >&2
      echo "[ubuntu-rootfs-flavors] supported: systemd-minimal, interactive, full" >&2
      return 1
      ;;
  esac
}

ubuntu_rootfs_flavor_packages() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1

  local systemd_minimal="systemd systemd-sysv udev dbus procps iproute2 kmod util-linux lsb-release login passwd adduser"
  local interactive="$systemd_minimal ca-certificates curl wget iputils-ping netcat-openbsd openssh-client htop less vim-tiny nano file strace psmisc"
  local full="$interactive ubuntu-standard openssh-server openssh-sftp-server dropbear-bin sudo locales tzdata bash-completion man-db cron anacron rsyslog logrotate systemd-timesyncd systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring netplan.io netplan-generator"

  case "$flavor" in
    systemd-minimal)
      printf '%s\n' "$systemd_minimal"
      ;;
    interactive)
      printf '%s\n' "$interactive"
      ;;
    full)
      printf '%s\n' "$full"
      ;;
  esac
}

ubuntu_rootfs_flavor_include_csv() {
  local packages
  packages=$(ubuntu_rootfs_flavor_packages "${1:-systemd-minimal}") || return 1
  printf '%s\n' "${packages// /,}"
}

ubuntu_rootfs_flavor_image_size() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1
  case "$flavor" in
    systemd-minimal)
      printf '%s\n' 2G
      ;;
    interactive)
      printf '%s\n' 4G
      ;;
    full)
      printf '%s\n' 8G
      ;;
  esac
}

ubuntu_rootfs_flavor_artifact_suffix() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1
  case "$flavor" in
    systemd-minimal)
      # 保持历史默认文件名，避免已有 minimized/systemd rootfs 路线被迁移打断。
      printf '%s\n' ""
      ;;
    interactive)
      printf '%s\n' "-interactive"
      ;;
    full)
      printf '%s\n' "-full"
      ;;
  esac
}

ubuntu_rootfs_flavor_debootstrap_variant() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1
  case "$flavor" in
    systemd-minimal|interactive|full)
      printf '%s\n' minbase
      ;;
  esac
}

ubuntu_rootfs_flavor_no_recommends() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1
  case "$flavor" in
    systemd-minimal|interactive)
      printf '%s\n' 1
      ;;
    full)
      printf '%s\n' 0
      ;;
  esac
}

ubuntu_rootfs_flavor_required_paths() {
  local flavor
  flavor=$(ubuntu_rootfs_flavor_normalize "${1:-systemd-minimal}") || return 1
  case "$flavor" in
    systemd-minimal)
      return 0
      ;;
    interactive)
      cat <<'EOF'
/usr/bin/curl|Ubuntu interactive command curl
/usr/bin/wget|Ubuntu interactive command wget
/bin/ping|Ubuntu interactive command ping
/usr/bin/ssh|Ubuntu interactive command ssh
/usr/bin/scp|Ubuntu interactive command scp
/usr/bin/sftp|Ubuntu interactive command sftp
/usr/bin/htop|Ubuntu interactive command htop
/usr/bin/less|Ubuntu interactive command less
/usr/bin/strace|Ubuntu interactive command strace
EOF
      ;;
    full)
      ubuntu_rootfs_flavor_required_paths interactive
      cat <<'EOF'
/usr/bin/apt-get|Ubuntu full command apt-get
/usr/bin/apt-cache|Ubuntu full command apt-cache
/usr/bin/gpgv|Ubuntu full command gpgv
/bin/journalctl|Ubuntu full command journalctl
/bin/systemd-machine-id-setup|Ubuntu full command systemd-machine-id-setup
/bin/systemd-sysusers|Ubuntu full command systemd-sysusers
/bin/systemd-tmpfiles|Ubuntu full command systemd-tmpfiles
/usr/bin/systemd-analyze|Ubuntu full command systemd-analyze
/usr/bin/systemd-run|Ubuntu full command systemd-run
/usr/bin/systemd-cat|Ubuntu full command systemd-cat
/usr/bin/hostnamectl|Ubuntu full command hostnamectl
/usr/bin/timedatectl|Ubuntu full command timedatectl
/usr/sbin/netplan|Ubuntu full command netplan
/usr/share/netplan/netplan.script|Ubuntu full netplan command script
/etc/netplan|Ubuntu full netplan config directory
/lib/netplan/generate|Ubuntu full netplan generator binary
/lib/systemd/system-generators/netplan|Ubuntu full netplan systemd generator
/bin/networkctl|Ubuntu full command networkctl
/bin/loginctl|Ubuntu full command loginctl
/lib/systemd/systemd-logind|Ubuntu full service systemd-logind
/lib/systemd/system/systemd-logind.service|Ubuntu full unit systemd-logind
/lib/riscv64-linux-gnu/security/pam_systemd.so|Ubuntu full PAM systemd session module
/etc/pam.d/common-session|Ubuntu full PAM common session config
/lib/systemd/systemd-networkd|Ubuntu full service systemd-networkd
/lib/systemd/system/systemd-networkd.service|Ubuntu full unit systemd-networkd
/lib/systemd/systemd-networkd-wait-online|Ubuntu full service systemd-networkd-wait-online
/lib/systemd/system/systemd-networkd-wait-online.service|Ubuntu full unit systemd-networkd-wait-online
/lib/systemd/system/network-online.target|Ubuntu full unit network-online target
/lib/systemd/system/graphical.target|Ubuntu full unit graphical target
/etc/systemd/network|Ubuntu full systemd-networkd config directory
/lib/systemd/systemd-timedated|Ubuntu full service systemd-timedated
/lib/systemd/system/systemd-timedated.service|Ubuntu full unit systemd-timedated
/lib/systemd/system/user@.service|Ubuntu full unit systemd user manager
/lib/systemd/system/user-runtime-dir@.service|Ubuntu full unit systemd user runtime dir
/usr/lib/systemd/user/dbus.socket|Ubuntu full systemd user bus socket
/usr/lib/systemd/user/dbus.service|Ubuntu full systemd user bus service
/usr/lib/systemd/user/sockets.target.wants/dbus.socket|Ubuntu full systemd user bus default socket
/usr/bin/logger|Ubuntu full command logger
/usr/bin/dpkg|Ubuntu full command dpkg
/usr/bin/dpkg-query|Ubuntu full command dpkg-query
/usr/bin/sudo|Ubuntu full command sudo
/bin/su|Ubuntu full command su
/etc/pam.d/su|Ubuntu full PAM su config
/usr/sbin/groupadd|Ubuntu full account command groupadd
/usr/sbin/groupdel|Ubuntu full account command groupdel
/usr/sbin/useradd|Ubuntu full account command useradd
/usr/sbin/userdel|Ubuntu full account command userdel
/usr/bin/passwd|Ubuntu full account command passwd
/etc/default/useradd|Ubuntu full account defaults
/etc/login.defs|Ubuntu full login defaults
/usr/bin/ssh-keygen|Ubuntu full command ssh-keygen
/usr/bin/man|Ubuntu full command man
/usr/sbin/locale-gen|Ubuntu full locale command locale-gen
/usr/bin/localedef|Ubuntu full locale command localedef
/usr/share/i18n/SUPPORTED|Ubuntu full locale supported database
/usr/bin/dbclient|Ubuntu full command dbclient
/usr/bin/dropbearconvert|Ubuntu full command dropbearconvert
/usr/bin/dropbearkey|Ubuntu full command dropbearkey
/usr/sbin/sshd|Ubuntu full service sshd
/usr/lib/openssh/sftp-server|Ubuntu full service OpenSSH sftp-server
/usr/sbin/dropbear|Ubuntu full service dropbear
/usr/sbin/cron|Ubuntu full service cron
/etc/crontab|Ubuntu full cron system crontab
/etc/cron.d|Ubuntu full cron.d directory
/etc/cron.daily|Ubuntu full cron.daily directory
/usr/sbin/anacron|Ubuntu full maintenance anacron
/etc/anacrontab|Ubuntu full anacron table
/etc/cron.d/anacron|Ubuntu full anacron cron entry
/etc/cron.daily/0anacron|Ubuntu full anacron daily stamp entry
/etc/cron.weekly/0anacron|Ubuntu full anacron weekly stamp entry
/etc/cron.monthly/0anacron|Ubuntu full anacron monthly stamp entry
/var/spool/anacron|Ubuntu full anacron spool directory
/lib/systemd/system/anacron.service|Ubuntu full anacron service
/lib/systemd/system/anacron.timer|Ubuntu full anacron timer
/usr/sbin/rsyslogd|Ubuntu full service rsyslogd
/usr/sbin/logrotate|Ubuntu full maintenance logrotate
/etc/logrotate.conf|Ubuntu full logrotate config
/etc/cron.daily/logrotate|Ubuntu full logrotate cron entry
/lib/systemd/system/logrotate.service|Ubuntu full logrotate service
/lib/systemd/system/logrotate.timer|Ubuntu full logrotate timer
/lib/systemd/systemd-oomd|Ubuntu full service systemd-oomd
/lib/systemd/system/systemd-oomd.service|Ubuntu full unit systemd-oomd
/usr/bin/oomctl|Ubuntu full command oomctl
/etc/systemd/oomd.conf|Ubuntu full oomd config
/usr/lib/systemd/oomd.conf.d/10-oomd-defaults.conf|Ubuntu full oomd defaults
/usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf|Ubuntu full oomd root slice defaults
/usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf|Ubuntu full oomd user service defaults
/usr/lib/sysusers.d/systemd-oom.conf|Ubuntu full oomd sysusers config
/usr/share/dbus-1/system-services/org.freedesktop.oom1.service|Ubuntu full oomd dbus service
/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf|Ubuntu full oomd dbus policy
/lib/systemd/systemd-hostnamed|Ubuntu full service systemd-hostnamed
/lib/systemd/system/systemd-hostnamed.service|Ubuntu full unit systemd-hostnamed
/usr/share/keyrings/ubuntu-archive-keyring.gpg|Ubuntu full apt archive keyring
/usr/share/zoneinfo/UTC|Ubuntu full timezone database
EOF
      ;;
  esac
}

ubuntu_rootfs_flavor_list() {
  printf '%s\n' systemd-minimal interactive full
}

ubuntu_rootfs_flavor_package_count() {
  local flavor=${1:-systemd-minimal}
  local count=0 package
  for package in $(ubuntu_rootfs_flavor_packages "$flavor"); do
    count=$((count + 1))
  done
  printf '%s\n' "$count"
}

ubuntu_rootfs_flavor_check_contains_package() {
  local flavor=$1
  local required=$2
  local package
  for package in $(ubuntu_rootfs_flavor_packages "$flavor"); do
    if [ "$package" = "$required" ]; then
      return 0
    fi
  done
  echo "FAIL rootfs-flavor $flavor missing package $required"
  return 1
}

ubuntu_rootfs_flavor_check_no_duplicate_packages() {
  local flavor=$1
  local seen=" " package
  for package in $(ubuntu_rootfs_flavor_packages "$flavor"); do
    case "$seen" in
      *" $package "*)
        echo "FAIL rootfs-flavor $flavor duplicate package $package"
        return 1
        ;;
    esac
    seen="$seen$package "
  done
  return 0
}

ubuntu_rootfs_flavor_check_required_paths() {
  local flavor=$1
  local line path label
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path=${line%%|*}
    label=${line#*|}
    if [ "$path" = "$line" ] || [ -z "$path" ] || [ -z "$label" ]; then
      echo "FAIL rootfs-flavor $flavor malformed required path: $line"
      return 1
    fi
    case "$path" in
      /*) ;;
      *)
        echo "FAIL rootfs-flavor $flavor required path is not absolute: $path"
        return 1
        ;;
    esac
  done < <(ubuntu_rootfs_flavor_required_paths "$flavor")
  return 0
}

ubuntu_rootfs_flavor_check() {
  local missing=0 flavor package_count image_size no_recommends
  for flavor in $(ubuntu_rootfs_flavor_list); do
    package_count=$(ubuntu_rootfs_flavor_package_count "$flavor") || missing=1
    image_size=$(ubuntu_rootfs_flavor_image_size "$flavor") || missing=1
    no_recommends=$(ubuntu_rootfs_flavor_no_recommends "$flavor") || missing=1
    ubuntu_rootfs_flavor_check_no_duplicate_packages "$flavor" || missing=1
    ubuntu_rootfs_flavor_check_required_paths "$flavor" || missing=1
    printf 'PASS rootfs-flavor %s packages=%s image_size=%s no_recommends=%s\n' \
      "$flavor" "$package_count" "$image_size" "$no_recommends"
  done

  for package in systemd systemd-sysv udev dbus procps iproute2 lsb-release; do
    ubuntu_rootfs_flavor_check_contains_package systemd-minimal "$package" || missing=1
  done
  for package in curl wget iputils-ping openssh-client htop strace; do
    ubuntu_rootfs_flavor_check_contains_package interactive "$package" || missing=1
  done
  for package in ubuntu-standard openssh-server openssh-sftp-server sudo locales man-db cron anacron rsyslog logrotate systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring; do
    ubuntu_rootfs_flavor_check_contains_package full "$package" || missing=1
  done

  if [ "$missing" -ne 0 ]; then
    return 1
  fi
  echo "PASS rootfs-flavor manifest"
}

ubuntu_rootfs_flavor_print_manifest() {
  local flavor
  for flavor in $(ubuntu_rootfs_flavor_list); do
    printf 'flavor=%s\n' "$flavor"
    printf 'artifact_suffix=%s\n' "$(ubuntu_rootfs_flavor_artifact_suffix "$flavor")"
    printf 'image_size=%s\n' "$(ubuntu_rootfs_flavor_image_size "$flavor")"
    printf 'debootstrap_variant=%s\n' "$(ubuntu_rootfs_flavor_debootstrap_variant "$flavor")"
    printf 'no_recommends=%s\n' "$(ubuntu_rootfs_flavor_no_recommends "$flavor")"
    printf 'packages=%s\n' "$(ubuntu_rootfs_flavor_packages "$flavor")"
    printf 'required_paths_begin\n'
    ubuntu_rootfs_flavor_required_paths "$flavor"
    printf 'required_paths_end\n'
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:---check}" in
    --check)
      ubuntu_rootfs_flavor_check
      ;;
    --print)
      ubuntu_rootfs_flavor_print_manifest
      ;;
    --packages)
      ubuntu_rootfs_flavor_packages "${2:-systemd-minimal}"
      ;;
    --include-csv)
      ubuntu_rootfs_flavor_include_csv "${2:-systemd-minimal}"
      ;;
    --required-paths)
      ubuntu_rootfs_flavor_required_paths "${2:-systemd-minimal}"
      ;;
    *)
      echo "usage: $0 [--check|--print|--packages FLAVOR|--include-csv FLAVOR|--required-paths FLAVOR]" >&2
      exit 2
      ;;
  esac
fi
