#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)

NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-linux-gui/riscv64-nemu-interpreter"}
NEMU_PLATFORM_ROOT=${NEMU_PLATFORM_ROOT:-"$LINUX_HOME/env/platforms/nemu"}
LOG_DIR=${NEMU_GUI_LOG_DIR:-"$NEMU_PLATFORM_ROOT/logs/linux-front/riscv64-nemu-ubuntu-gui-check"}
CONSOLE_LOG=${NEMU_GUI_CONSOLE_LOG:-"$LOG_DIR/console.log"}
NEMU_LOG=${NEMU_GUI_NEMU_LOG:-"$LOG_DIR/nemu.log"}
SERIAL_FIFO=${NEMU_GUI_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}
ROOTFS_OVERLAY=${NEMU_GUI_ROOTFS_OVERLAY:-"$LOG_DIR/rootfs-overlay.raw"}
SCREENSHOT=${NEMU_GUI_SCREENSHOT:-"$LOG_DIR/tty1.png"}
SCREENSHOT_BEFORE=${NEMU_GUI_SCREENSHOT_BEFORE:-"$SCREENSHOT.before.png"}
INJECTOR_SOURCE=${NEMU_GUI_INJECTOR_SOURCE:-"$LINUX_HOME/tools/nemu-x11-key-inject.c"}
INJECTOR=${NEMU_GUI_INJECTOR:-"$LOG_DIR/nemu-x11-key-inject"}

LINUX_IMAGE=${LINUX_IMAGE:-"$NEMU_PLATFORM_ROOT/build/linux-gui/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$NEMU_PLATFORM_ROOT/build/opensbi-gui/rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/riscv64-nemu-gui/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$NEMU_PLATFORM_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64-gui.ext4"}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}
MAX_CYCLES=${NEMU_GUI_MAX_CYCLES:-50000000000}
CHECK_TIMEOUT=${NEMU_GUI_CHECK_TIMEOUT:-1800}
BOOT_TIMEOUT=${NEMU_GUI_BOOT_TIMEOUT:-900}
POWEROFF_TIMEOUT=${NEMU_GUI_POWEROFF_TIMEOUT:-180}
FIFO_TIMEOUT=${NEMU_GUI_FIFO_TIMEOUT:-60}
POLL_INTERVAL=${NEMU_GUI_POLL_INTERVAL:-1}
WINDOW_TITLE=${NEMU_GUI_WINDOW_TITLE:--NEMU}

nemu_pid=
console_log_initialized=0

fail() {
  echo "[nemu-gui-check] FAIL: $*" >&2
  if [ "$console_log_initialized" = 1 ] && [ -f "$CONSOLE_LOG" ]; then
    echo "[nemu-gui-check] ---- console tail ----" >&2
    tail -120 "$CONSOLE_LOG" >&2 || true
    echo "[nemu-gui-check] ----------------------" >&2
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

require_uint() {
  local name=$1
  local value=$2
  case "$value" in
    ''|*[!0-9]*) fail "$name must be a non-negative integer: $value" ;;
  esac
}

protected_cleanup_reals=()
protected_cleanup_paths=()
guarded_cleanup_reals=()
guarded_cleanup_paths=()

guard_cleanup_path() {
  local path=$1
  local label=$2
  local resolved protected index

  [ -n "$path" ] || fail "$label path is empty"
  resolved=$(realpath -m -- "$path") || fail "cannot resolve $label path: $path"
  case "$resolved" in
    /|'') fail "unsafe $label path: $resolved" ;;
  esac
  [ ! -d "$path" ] || fail "$label path is a directory: $path"
  for index in "${!protected_cleanup_reals[@]}"; do
    protected=${protected_cleanup_paths[index]}
    if [ "$resolved" = "${protected_cleanup_reals[index]}" ] || \
       { { [ -e "$path" ] || [ -L "$path" ]; } && [ "$path" -ef "$protected" ]; }; then
      fail "$label path aliases a required input: $resolved"
    fi
  done
  for index in "${!guarded_cleanup_reals[@]}"; do
    protected=${guarded_cleanup_paths[index]}
    if [ "$resolved" = "${guarded_cleanup_reals[index]}" ] || \
       { { [ -e "$path" ] || [ -L "$path" ]; } &&
         { [ -e "$protected" ] || [ -L "$protected" ]; } &&
         [ "$path" -ef "$protected" ]; }; then
      fail "$label path aliases another writable artifact: $protected"
    fi
  done
  guarded_cleanup_paths+=("$path")
  guarded_cleanup_reals+=("$resolved")
}

wait_for_fifo() {
  local deadline=$((SECONDS + FIFO_TIMEOUT))
  while [ "$SECONDS" -lt "$deadline" ]; do
    [ -p "$SERIAL_FIFO" ] && return 0
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      fail "NEMU exited before serial FIFO appeared"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for serial FIFO: $SERIAL_FIFO"
}

wait_for_log() {
  local pattern=$1
  local timeout=$2
  local deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if grep -qaE "$pattern" "$CONSOLE_LOG"; then
      return 0
    fi
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      fail "NEMU exited before console marker: $pattern"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for console marker: $pattern"
}

send_serial_line() {
  local line=$1
  python3 - "$SERIAL_FIFO" "$line" <<'PY'
import sys
import time

path, line = sys.argv[1], sys.argv[2]
payload = (line + "\n").encode("utf-8")
with open(path, "wb", buffering=0) as stream:
    for offset in range(0, len(payload), 8):
        stream.write(payload[offset : offset + 8])
        time.sleep(0.002)
PY
}

wait_for_nemu_exit() {
  local timeout=$1
  local deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      local rc=0
      wait "$nemu_pid" || rc=$?
      [ "$rc" = 0 ] || fail "NEMU exited with status $rc"
      nemu_pid=
      return 0
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for guest poweroff"
}

cleanup() {
  if [ -n "$nemu_pid" ] && kill -0 "$nemu_pid" 2>/dev/null; then
    kill "$nemu_pid" 2>/dev/null || true
    wait "$nemu_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

for numeric in "$MAX_CYCLES" "$CHECK_TIMEOUT" "$BOOT_TIMEOUT" \
    "$POWEROFF_TIMEOUT" "$FIFO_TIMEOUT"; do
  require_uint "timeout/cycle value" "$numeric"
done
[ -n "${DISPLAY:-}" ] || fail "DISPLAY is unset; run this gate through xvfb-run"

require_executable "$NEMU_SIM" NEMU
require_file "$LINUX_IMAGE" "Linux Image"
require_file "$RUN_FW" "OpenSBI fw_jump"
require_file "$RUN_DTB" DTB
require_file "$RUN_ROOTFS" "Ubuntu rootfs"
require_file "$INJECTOR_SOURCE" "X11 keyboard injector source"
require_file "$SCRIPT_DIR/prepare-nemu-overlay.sh" "NEMU overlay preparation helper"
for command in cc pkg-config python3 import identify compare realpath; do
  command -v "$command" >/dev/null 2>&1 || fail "missing host command: $command"
done
pkg-config --exists x11 xtst || fail "missing X11/XTest development packages"

for required_input in "$NEMU_SIM" "$LINUX_IMAGE" "$RUN_FW" "$RUN_DTB" \
    "$RUN_ROOTFS" "$INJECTOR_SOURCE"; do
  protected_cleanup_reals+=(
    "$(realpath -e -- "$required_input")"
  )
  protected_cleanup_paths+=("$required_input")
done
guard_cleanup_path "$SERIAL_FIFO" "serial FIFO"
guard_cleanup_path "$CONSOLE_LOG" "console log"
guard_cleanup_path "$NEMU_LOG" "NEMU log"
guard_cleanup_path "$SCREENSHOT" screenshot
guard_cleanup_path "$SCREENSHOT_BEFORE" "pre-input screenshot"
guard_cleanup_path "$INJECTOR" "X11 injector"
if [ -n "$ROOTFS_OVERLAY" ]; then
  guard_cleanup_path "$ROOTFS_OVERLAY" "rootfs overlay"
  guard_cleanup_path "$ROOTFS_OVERLAY.meta" "rootfs overlay metadata"
  guard_cleanup_path "$ROOTFS_OVERLAY.meta.tmp" "temporary rootfs overlay metadata"
  guard_cleanup_path "$ROOTFS_OVERLAY.lock" "stable rootfs overlay lock"
fi

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$NEMU_LOG" "$SCREENSHOT" \
  "$SCREENSHOT_BEFORE" "$INJECTOR"
if [ -n "$ROOTFS_OVERLAY" ]; then
  mkdir -p "$(dirname -- "$ROOTFS_OVERLAY")"
  bash "$SCRIPT_DIR/prepare-nemu-overlay.sh" \
    --backing="$RUN_ROOTFS" --overlay="$ROOTFS_OVERLAY" --reset=1
fi
: >"$CONSOLE_LOG"
console_log_initialized=1

cc -std=c11 -D_DEFAULT_SOURCE -O2 -Wall -Wextra -Werror \
  "$INJECTOR_SOURCE" -o "$INJECTOR" \
  $(pkg-config --cflags --libs x11 xtst)

overlay_args=()
if [ -n "$ROOTFS_OVERLAY" ]; then
  overlay_args=(--block-overlay="$ROOTFS_OVERLAY")
fi
rootfs_stat_before=$(stat -c '%s:%Y' "$RUN_ROOTFS")

echo "[nemu-gui-check] display: $DISPLAY"
echo "[nemu-gui-check] NEMU: $NEMU_SIM"
echo "[nemu-gui-check] kernel: $LINUX_IMAGE"
echo "[nemu-gui-check] DTB: $RUN_DTB"
echo "[nemu-gui-check] rootfs: $RUN_ROOTFS"
echo "[nemu-gui-check] screenshot: $SCREENSHOT"

NEMU_SERIAL_FIFO="$SERIAL_FIFO" \
NEMU_SERIAL_INPUT_STDIN=0 \
NEMU_HOME="$NEMU_HOME" \
timeout --foreground --preserve-status "${CHECK_TIMEOUT}s" \
  "$NEMU_SIM" -b \
  --max-insts="$MAX_CYCLES" \
  --log="$NEMU_LOG" \
  --boot-hartid=0 \
  --boot-dtb="$DTB_ADDR" \
  -i "$RUN_FW" \
  --load="$NEXT_ADDR:$LINUX_IMAGE" \
  --load="$DTB_ADDR:$RUN_DTB" \
  --block="$RUN_ROOTFS" \
  "${overlay_args[@]}" \
  >"$CONSOLE_LOG" 2>&1 &
nemu_pid=$!

wait_for_fifo
wait_for_log '^__NEMU_LOGIN_CHECK_DONE__ rc=0[[:space:]]*$' "$BOOT_TIMEOUT"
wait_for_log 'root@ysyx-ubuntu2204:~#' "$BOOT_TIMEOUT"

guest_probe='gui_rc=0; test -c /dev/fb0 || gui_rc=1; test -c /dev/tty1 || gui_rc=1; grep -qx "0 simple" /proc/fb || gui_rc=1; grep -qx "simple" /sys/class/graphics/fb0/name || gui_rc=1; grep -qx "800,600" /sys/class/graphics/fb0/virtual_size || gui_rc=1; grep -q "frame buffer device" /sys/class/vtconsole/vtcon*/name || gui_rc=1; systemctl is-active --quiet getty@tty1.service || gui_rc=1; input_node=$(grep -l -x "0x0012" /sys/bus/virtio/devices/virtio*/device 2>/dev/null | head -n1); test -n "$input_node" || gui_rc=1; input_root=${input_node%/device}; test "$(basename "$(readlink -f "$input_root/driver" 2>/dev/null)")" = virtio_input || gui_rc=1; grep -q "NEMU SDL virtio keyboard" /proc/bus/input/devices || gui_rc=1; ls /dev/input/event* >/dev/null 2>&1 || gui_rc=1; rm -f /tmp/nemu-gui-input-ok; test ! -e /tmp/nemu-gui-input-ok || gui_rc=1; echo __NEMU_GUI_GUEST_READY__:rc=$gui_rc'
send_serial_line "$guest_probe"
wait_for_log '^__NEMU_GUI_GUEST_READY__:rc=0[[:space:]]*$' 90

# 这里注入的是 X11 键事件，SDL 收到后必须经 virtio-input/PLIC/Linux
# input core 到达当前 tty1；串口仅负责在另一终端核验结果文件。
sleep 3
window_id=$("$INJECTOR" --title "$WINDOW_TITLE" --find-only --wait-seconds 10)
import -window "$window_id" "$SCREENSHOT_BEFORE"
"$INJECTOR" --title "$WINDOW_TITLE" \
  --text $'echo GUIFRAME123456789; touch /tmp/nemu-gui-input-ok\n' \
  --delay-us 60000 --wait-seconds 10 \
  >/dev/null

input_probe='input_rc=1; input_wait=0; while test ! -e /tmp/nemu-gui-input-ok && test "$input_wait" -lt 100; do sleep 0.1; input_wait=$((input_wait + 1)); done; test -e /tmp/nemu-gui-input-ok && input_rc=0; echo __NEMU_GUI_INPUT_OK__:rc=$input_rc:wait=$input_wait'
send_serial_line "$input_probe"
wait_for_log '^__NEMU_GUI_INPUT_OK__:rc=0:wait=[0-9]+[[:space:]]*$' 30

import -window "$window_id" "$SCREENSHOT"
set +e
frame_delta=$(compare -metric AE "$SCREENSHOT_BEFORE" "$SCREENSHOT" null: 2>&1)
frame_compare_rc=$?
set -e
[ "$frame_compare_rc" -le 1 ] || fail "ImageMagick failed comparing GUI frames"
case "$frame_delta" in
  ''|*[!0-9]*) fail "invalid GUI frame pixel delta: $frame_delta" ;;
esac
[ "$frame_delta" -gt 100 ] || \
  fail "SDL framebuffer did not visibly update after tty1 input: changed_pixels=$frame_delta"
read -r screenshot_width screenshot_height screenshot_colors < <(
  identify -format '%w %h %k\n' "$SCREENSHOT"
)
[ "$screenshot_width" = 800 ] || fail "unexpected SDL width: $screenshot_width"
[ "$screenshot_height" = 600 ] || fail "unexpected SDL height: $screenshot_height"
case "$screenshot_colors" in
  ''|*[!0-9]*) fail "invalid screenshot color count: $screenshot_colors" ;;
esac
[ "$screenshot_colors" -gt 1 ] || fail "SDL framebuffer screenshot is blank"
echo "__NEMU_GUI_SCREENSHOT__:${screenshot_width}x${screenshot_height}:colors=$screenshot_colors"
echo "__NEMU_GUI_FRAME_DELTA__:${frame_delta}"

send_serial_line 'power_rc=0; echo __NEMU_GUI_POWEROFF_BEGIN__:rc=$power_rc; sync; systemctl --no-wall poweroff || poweroff -f'
wait_for_log '^__NEMU_GUI_POWEROFF_BEGIN__:rc=0[[:space:]]*$' 30
wait_for_nemu_exit "$POWEROFF_TIMEOUT"

rootfs_stat_after=$(stat -c '%s:%Y' "$RUN_ROOTFS")
[ "$rootfs_stat_after" = "$rootfs_stat_before" ] || \
  fail "rootfs backing changed despite overlay: $rootfs_stat_before -> $rootfs_stat_after"
grep -qa 'reboot: Power down' "$CONSOLE_LOG" || fail "missing Linux poweroff evidence"
grep -qa 'SBI SRST extension detected' "$CONSOLE_LOG" || \
  fail "Linux did not discover the OpenSBI SRST extension"
grep -qa 'syscon-reset: poweroff requested value=0x00005555' "$CONSOLE_LOG" || \
  fail "missing OpenSBI-to-syscon poweroff evidence"
grep -qa 'HIT GOOD TRAP' "$CONSOLE_LOG" || fail "missing NEMU terminal evidence"
syscon_pc=$(
  grep -a 'syscon-reset: poweroff requested value=0x00005555' "$CONSOLE_LOG" |
    sed -n 's/.*pc=\(0x[[:xdigit:]]\+\).*/\1/p' | tail -n1
)
terminal_pc=$(
  grep -a 'HIT GOOD TRAP' "$CONSOLE_LOG" |
    sed -n 's/.*pc = \(0x[[:xdigit:]]\+\).*/\1/p' | tail -n1
)
[ -n "$syscon_pc" ] && [ "$syscon_pc" = "$terminal_pc" ] || \
  fail "syscon/terminal PC mismatch: ${syscon_pc:-missing} != ${terminal_pc:-missing}"

echo "__NEMU_GUI_GUEST_READY__:ok"
echo "__NEMU_GUI_INPUT_OK__:ok"
echo "__NEMU_GUI_PRESENTER__:ok"
echo "[nemu-gui-check] PASS"
