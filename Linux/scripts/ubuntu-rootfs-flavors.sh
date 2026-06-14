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
  local full="$interactive ubuntu-standard openssh-server dropbear-bin sudo locales tzdata bash-completion man-db cron rsyslog systemd-timesyncd gpgv ubuntu-keyring"

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
/usr/bin/systemd-cat|Ubuntu full command systemd-cat
/usr/bin/hostnamectl|Ubuntu full command hostnamectl
/usr/bin/logger|Ubuntu full command logger
/usr/bin/dpkg|Ubuntu full command dpkg
/usr/bin/dpkg-query|Ubuntu full command dpkg-query
/usr/bin/sudo|Ubuntu full command sudo
/usr/bin/man|Ubuntu full command man
/usr/bin/dbclient|Ubuntu full command dbclient
/usr/bin/dropbearconvert|Ubuntu full command dropbearconvert
/usr/bin/dropbearkey|Ubuntu full command dropbearkey
/usr/sbin/sshd|Ubuntu full service sshd
/usr/sbin/dropbear|Ubuntu full service dropbear
/usr/sbin/cron|Ubuntu full service cron
/usr/sbin/rsyslogd|Ubuntu full service rsyslogd
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
  for package in ubuntu-standard openssh-server sudo locales man-db cron rsyslog gpgv ubuntu-keyring; do
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
