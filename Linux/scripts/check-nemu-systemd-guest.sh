#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)

NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
LOG_DIR=${LOG_DIR:-"$ENV_ROOT/logs/linux-front/riscv64-nemu-systemd-guest-check"}
LOG_FILE=${LOG_FILE:-"$LOG_DIR/nemu.log"}
CONSOLE_LOG=${CONSOLE_LOG:-"$LOG_DIR/console.log"}
SERIAL_FIFO=${NEMU_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}

LINUX_IMAGE=${LINUX_IMAGE:-"$ENV_ROOT/src/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$ENV_ROOT/build/opensbi-nemu-rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/npc-rv64-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}
MAX_CYCLES=${MAX_CYCLES:-12000000000}

CHECK_TIMEOUT=${NEMU_SYSTEMD_CHECK_TIMEOUT:-1200}
BOOT_TIMEOUT=${NEMU_SYSTEMD_BOOT_TIMEOUT:-900}
FIFO_TIMEOUT=${NEMU_SYSTEMD_FIFO_TIMEOUT:-60}
POLL_INTERVAL=${NEMU_SYSTEMD_POLL_INTERVAL:-2}

fail() {
  echo "[nemu-systemd-check] FAIL: $*" >&2
  if [ -f "$CONSOLE_LOG" ]; then
    echo "[nemu-systemd-check] ---- console tail ----" >&2
    tail -120 "$CONSOLE_LOG" >&2 || true
    echo "[nemu-systemd-check] ----------------------" >&2
  fi
  exit 1
}

require_file() {
  local path=$1
  local label=$2
  [ -f "$path" ] || fail "missing $label: $path"
}

require_executable() {
  local path=$1
  local label=$2
  [ -x "$path" ] || fail "missing executable $label: $path"
}

wait_for_log() {
  local needle=$1
  local timeout=$2
  local deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if grep -qaF "$needle" "$CONSOLE_LOG"; then
      return 0
    fi
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      fail "NEMU exited before log marker: $needle"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for log marker: $needle"
}

wait_for_fifo() {
  local deadline=$((SECONDS + FIFO_TIMEOUT))
  while [ "$SECONDS" -lt "$deadline" ]; do
    [ -p "$SERIAL_FIFO" ] && return 0
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      fail "NEMU exited before serial FIFO appeared: $SERIAL_FIFO"
    fi
    sleep 1
  done
  fail "timeout waiting for serial FIFO: $SERIAL_FIFO"
}

require_executable "$NEMU_SIM" "NEMU"
require_file "$LINUX_IMAGE" "Linux Image"
require_file "$RUN_FW" "OpenSBI firmware"
require_file "$RUN_DTB" "rootfs DTB"
require_file "$RUN_ROOTFS" "Ubuntu rootfs"

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$LOG_FILE" "$LOG_DIR/guest-check.cmd"
: >"$CONSOLE_LOG"

echo "[nemu-systemd-check] log dir: $LOG_DIR"
echo "[nemu-systemd-check] serial fifo: $SERIAL_FIFO"
echo "[nemu-systemd-check] max cycles: $MAX_CYCLES"

NEMU_SERIAL_FIFO="$SERIAL_FIFO" NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b \
  --max-insts="$MAX_CYCLES" \
  --log="$LOG_FILE" \
  --boot-hartid=0 \
  --boot-dtb="$DTB_ADDR" \
  -i "$RUN_FW" \
  --load="$NEXT_ADDR:$LINUX_IMAGE" \
  --load="$DTB_ADDR:$RUN_DTB" \
  --block="$RUN_ROOTFS" \
  >"$CONSOLE_LOG" 2>&1 &
nemu_pid=$!

cleanup() {
  if kill -0 "$nemu_pid" 2>/dev/null; then
    kill "$nemu_pid" 2>/dev/null || true
    wait "$nemu_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

wait_for_fifo
wait_for_log "root@ysyx-ubuntu2204:~#" "$BOOT_TIMEOUT"

cat >"$LOG_DIR/guest-check.cmd" <<'GUEST_CMDS'
echo __NEMU_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NEMU_CHECK_PASS__:$1"; }
fail() { echo "__NEMU_CHECK_FAIL__:$1"; check_fail=1; }

wait_i=0
while [ "$wait_i" -lt 150 ]; do
  state="$(systemctl --no-pager --plain is-system-running 2>&1 || true)"
  echo "__NEMU_CHECK_SYSTEMD_WAIT__:$wait_i:$state"
  [ "$state" = "running" ] && break
  sleep 2
  wait_i=$((wait_i + 1))
done

state="$(systemctl --no-pager --plain is-system-running 2>&1)"
echo "__NEMU_CHECK_SYSTEMD_STATE__:$state"
[ "$state" = "running" ] && pass systemd-running || fail systemd-running

failed_units="$(systemctl --no-pager --plain --failed 2>&1)"
echo "$failed_units"
echo "$failed_units" | grep -q "0 loaded units listed" && pass systemd-failed-units || fail systemd-failed-units

jobs="$(systemctl --no-pager --plain list-jobs 2>&1)"
echo "$jobs"
echo "$jobs" | grep -q "No jobs running" && pass systemd-jobs || fail systemd-jobs

pid1="$(ps -p 1 -o comm= 2>/dev/null)"
echo "__NEMU_CHECK_PID1__:$pid1"
[ "$pid1" = "systemd" ] && pass pid1-systemd || fail pid1-systemd

for m in /dev /proc /sys /run /dev/pts /dev/shm /sys/fs/cgroup; do
  if mountpoint -q "$m"; then
    echo "__NEMU_CHECK_MOUNT_OK__:$m"
  else
    echo "__NEMU_CHECK_MOUNT_MISSING__:$m"
    check_fail=1
  fi
done

[ -c /dev/ttyS0 ] && pass ttyS0-node || fail ttyS0-node
[ -c /dev/console ] && pass console-node || fail console-node
tty_name="$(tty 2>&1 || true)"
echo "__NEMU_CHECK_TTY__:$tty_name"
echo "$tty_name" | grep -Eq '/dev/(ttyS0|console)' && pass interactive-tty || fail interactive-tty

[ -b /dev/vda ] && pass vda-block-node || fail vda-block-node
vda_size="$(blockdev --getsize64 /dev/vda 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_SIZE__:$vda_size"
[ "${vda_size:-0}" -gt 0 ] 2>/dev/null && pass vda-size || fail vda-size

root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
echo "__NEMU_CHECK_ROOT_SOURCE__:$root_source"
case "$root_source" in
  /dev/vda*|/dev/root) pass rootfs-source ;;
  *) fail rootfs-source ;;
esac

write_file="/root/nemu-systemd-guest-check.bin"
if dd if=/dev/zero of="$write_file" bs=4096 count=8 conv=fsync status=none; then
  bytes="$(wc -c < "$write_file" 2>/dev/null || echo 0)"
  echo "__NEMU_CHECK_WRITE_BYTES__:$bytes"
  [ "$bytes" = "32768" ] && pass rootfs-write-read || fail rootfs-write-read
  sha256sum "$write_file" || check_fail=1
  rm -f "$write_file"
  sync
else
  fail rootfs-write-read
fi

uptime0="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
sleep 2
uptime1="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
echo "__NEMU_CHECK_UPTIME__:$uptime0->$uptime1"
[ "$uptime1" -gt "$uptime0" ] 2>/dev/null && pass timer-sleep || fail timer-sleep

stat /proc/self/status >/dev/null 2>&1 && pass proc-stat || fail proc-stat
readlink /proc/self/fd/0 >/dev/null 2>&1 && pass proc-fd-readlink || fail proc-fd-readlink
cat /etc/os-release | grep -q 'PRETTY_NAME="Ubuntu 22.04.5 LTS"' && pass os-release || fail os-release
uname -m | grep -q '^riscv64$' && pass uname-riscv64 || fail uname-riscv64

bad_dmesg="$(dmesg | grep -i -E 'unhandled signal 4|illegal instruction|sigill|kernel panic|oops' | tail -20 || true)"
if [ -z "$bad_dmesg" ]; then
  pass dmesg-no-critical
else
  echo "$bad_dmesg"
  fail dmesg-no-critical
fi

echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=$check_fail"
GUEST_CMDS

cat "$LOG_DIR/guest-check.cmd" >"$SERIAL_FIFO"
wait_for_log "__NEMU_SYSTEMD_CHECK_DONE__ rc=" "$CHECK_TIMEOUT"

if grep -qaF "__NEMU_SYSTEMD_CHECK_DONE__ rc=0" "$CONSOLE_LOG" &&
   ! grep -qaE "^__NEMU_CHECK_FAIL__:" "$CONSOLE_LOG"; then
  echo "[nemu-systemd-check] PASS"
else
  fail "guest checks reported failure"
fi
