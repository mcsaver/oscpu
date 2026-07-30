#!/bin/sh
set +e
set +u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

poweroff_enable=0
marker_stage=uart
while [ "$#" -gt 0 ]; do
  case "$1" in
    --poweroff)
      poweroff_enable=1
      shift
      ;;
    --stage)
      [ "$#" -ge 2 ] || exit 2
      marker_stage=$2
      shift 2
      ;;
    --stage=*)
      marker_stage=${1#--stage=}
      shift
      ;;
    *)
      exit 2
      ;;
  esac
done

case "$marker_stage" in
  strict)
    begin_marker=__NPC_SYSTEMD_STRICT_BEGIN__
    done_marker=__NPC_SYSTEMD_STRICT_DONE__
    ;;
  uart)
    begin_marker=__NPC_SYSTEMD_CHECK_BEGIN__
    done_marker=__NPC_SYSTEMD_UART_CHECK_DONE__
    ;;
  *)
    exit 2
    ;;
esac

echo "$begin_marker"
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

[ "$(id -u 2>/dev/null)" = "0" ] && pass root-shell || fail root-shell
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

[ -b /dev/vda ] && pass block-vda || fail block-vda
vda_driver="$(basename "$(readlink -f /sys/class/block/vda/device/driver 2>/dev/null || true)")"
echo "__NPC_CHECK_VDA_DRIVER__:$vda_driver"
[ "$vda_driver" = "virtio_blk" ] && pass virtio-blk-driver || fail virtio-blk-driver

root_fstype="$(awk '$2 == "/" { print $3; exit }' /proc/mounts 2>/dev/null)"
root_opts="$(awk '$2 == "/" { print $4; exit }' /proc/mounts 2>/dev/null)"
root_source="$(awk '$2 == "/" { print $1; exit }' /proc/mounts 2>/dev/null)"
root_majmin="$(awk '$5 == "/" { print $3; exit }' /proc/self/mountinfo 2>/dev/null)"
vda_majmin="$(cat /sys/class/block/vda/dev 2>/dev/null || true)"
echo "__NPC_CHECK_ROOT_SOURCE__:${root_source}:${root_majmin}:${vda_majmin}"
echo "__NPC_CHECK_ROOT_MOUNT__:${root_fstype}:${root_opts}"
[ -n "$root_majmin" ] && [ "$root_majmin" = "$vda_majmin" ] &&
  pass root-on-vda || fail root-on-vda
[ "$root_fstype" = "ext4" ] && pass root-ext4 || fail root-ext4
case ",$root_opts," in
  *,rw,*) pass root-rw ;;
  *) fail root-rw ;;
esac

vda_virtio_device="$(readlink -f /sys/class/block/vda/device 2>/dev/null || true)"
vda_virtio_name="${vda_virtio_device##*/}"
echo "__NPC_CHECK_VIRTIO_IRQ_OWNER__:${vda_virtio_name}"
case "$vda_virtio_name" in
  virtio[0-9]*) pass virtio-device-name ;;
  *) fail virtio-device-name ;;
esac

virtio_irq_sum() {
  awk -v dev="$vda_virtio_name" '
    NR == 1 {
      for (i = 1; i <= NF; i++) if ($i ~ /^CPU[0-9]+$/) cpu_cols++;
      next;
    }
    {
      owner = 0;
      for (i = 2 + cpu_cols; i <= NF; i++) {
        if ($i == dev) owner = 1;
      }
      if (owner) {
        owners++;
        for (i = 2; i < 2 + cpu_cols; i++) {
          if ($i !~ /^[0-9]+$/) bad = 1;
          else sum += $i;
        }
      }
    }
    END {
      if (cpu_cols < 1 || dev == "" || owners != 1 || bad)
        exit 1;
      printf "%.0f\n", sum;
    }
  ' /proc/interrupts 2>/dev/null
}

check_file=/root/.npc-systemd-rw-check
check_payload="npc-systemd-rw-$PPID-$$"
if printf '%s\n' "$check_payload" >"$check_file" 2>/dev/null &&
   sync &&
   [ "$(cat "$check_file" 2>/dev/null || true)" = "$check_payload" ]; then
  pass rootfs-write-sync-readback
else
  fail rootfs-write-sync-readback
fi
rm -f "$check_file"

irq_before=
if irq_before="$(virtio_irq_sum)" &&
   case "$irq_before" in ''|*[!0-9]*) false ;; *) true ;; esac; then
  pass virtio-irq-before-parse
else
  fail virtio-irq-before-parse
fi

if dd if=/dev/vda of=/dev/null bs=4096 count=128 skip=4096 iflag=direct,fullblock status=none 2>/dev/null; then
  pass virtio-blk-direct-read
else
  fail virtio-blk-direct-read
fi
sleep 1

irq_after=
if ! irq_after="$(virtio_irq_sum)"; then
  fail virtio-irq-owner-stable
fi
echo "__NPC_CHECK_VIRTIO_IRQ__:${irq_before}->${irq_after}"
case "$irq_before:$irq_after" in
  *[!0-9:]*|:*) fail virtio-irq-numeric ;;
  *)
    if [ "$irq_after" -gt "$irq_before" ] 2>/dev/null; then
      pass virtio-irq-growth
    else
      fail virtio-irq-growth
    fi
    ;;
esac

bad_dmesg="$(dmesg 2>/dev/null | grep -i -E 'kernel panic|oops|BUG:|bad trap|illegal instruction|segfault|I/O error|Buffer I/O error|EXT4-fs error' | tail -20 || true)"
if [ -z "$bad_dmesg" ]; then
  pass dmesg-no-critical
else
  printf '%s\n' "$bad_dmesg"
  fail dmesg-no-critical
fi

echo "$done_marker rc=$check_fail"

if [ "$poweroff_enable" = "1" ]; then
  echo "__NPC_SYSTEMD_POWEROFF_BEGIN__"
  sync
  systemctl --no-wall poweroff || echo "__NPC_SYSTEMD_POWEROFF_CMD_FAIL__"
fi

exit "$check_fail"
