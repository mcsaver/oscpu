#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)
CALLER_CWD=$(pwd -P)

abspath_from_cwd() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$CALLER_CWD" "$1" ;;
  esac
}

NPC_PLATFORM_ROOT=${NPC_PLATFORM_ROOT:-"$LINUX_HOME/env/platforms/npc"}
LOG_DIR=${LOG_DIR:-${NPC_SYSTEMD_CHECK_LOG_DIR:-"$NPC_PLATFORM_ROOT/logs/linux-front/riscv64-npc-systemd-guest-check"}}
CONSOLE_LOG=${CONSOLE_LOG:-"$LOG_DIR/console.log"}
NPC_LOG=${NPC_LOG:-"$LOG_DIR/npc.log"}
GUEST_CMDS=${NPC_SYSTEMD_GUEST_CMDS:-"$LOG_DIR/npc-guest-check.cmd"}
PROMPT=${NPC_SYSTEMD_PROMPT:-"root@ysyx-ubuntu2204:~#"}
DONE_MARKER=${NPC_SYSTEMD_DONE_MARKER:-}
MAX_CYCLES=${MAX_CYCLES:-${NPC_SYSTEMD_CHECK_MAX_CYCLES:-3000000000}}
HOST_TIMEOUT=${NPC_SYSTEMD_HOST_TIMEOUT:-10800}
UART_TRACE=${NPC_SYSTEMD_UART_TRACE:-1}
UART_TRACE_LIMIT=${NPC_SYSTEMD_UART_TRACE_LIMIT:-128}
UART_CYCLE_GAP=${NPC_SYSTEMD_UART_CYCLE_GAP:-${NPC_UART_RX_CYCLE_GAP:-0}}
UART_RELEASE_DELAY=${NPC_SYSTEMD_UART_RELEASE_DELAY_CYCLES:-${NPC_UART_RX_RELEASE_DELAY_CYCLES:-}}
UART_WAIT=${NPC_SYSTEMD_UART_WAIT:-$PROMPT}
GUEST_COMMAND_MODE=${NPC_SYSTEMD_GUEST_COMMAND_MODE:-autocheck}
GUEST_CMDS_PRESERVE=${NPC_SYSTEMD_GUEST_CMDS_PRESERVE:-0}
REQUIRE_PROMPT=${NPC_SYSTEMD_REQUIRE_PROMPT:-1}
PROGRESS_INTERVAL=${NPC_SYSTEMD_PROGRESS:-0}
STRICT_CHECK=${NPC_SYSTEMD_STRICT_CHECK:-0}
POWEROFF_ENABLE=${NPC_SYSTEMD_GUEST_POWEROFF:-0}
NPC_SIM_BIN=${NPC_SIM:-}
LINUX_IMAGE_FILE=${LINUX_IMAGE:-}
RUN_FW_FILE=${RUN_FW:-}
RUN_DTB_FILE=${RUN_DTB:-}
RUN_ROOTFS_FILE=${RUN_ROOTFS:-}
NEXT_ADDR_VALUE=${NEXT_ADDR:-}
DTB_ADDR_VALUE=${DTB_ADDR:-}
if [ "$POWEROFF_ENABLE" = "1" ] &&
   { [ "$GUEST_COMMAND_MODE" != "uart" ] || [ "$STRICT_CHECK" != "1" ]; }; then
  echo "[npc-systemd-check] natural poweroff requires uart mode + strict checks" >&2
  exit 2
fi
if [ -z "$UART_RELEASE_DELAY" ]; then
  UART_RELEASE_DELAY=0
  if [ "$GUEST_COMMAND_MODE" = "uart" ] &&
     [ "$UART_WAIT" = "__NPC_CONSOLE_SHELL_READY__" ]; then
    UART_RELEASE_DELAY=${NPC_SYSTEMD_CONSOLE_SHELL_RELEASE_DELAY_CYCLES:-20000000}
  fi
fi

if [ -z "$DONE_MARKER" ]; then
  if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
    DONE_MARKER="__NPC_SYSTEMD_UART_CHECK_DONE__ rc=0"
  else
    DONE_MARKER="__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0"
  fi
fi
AUTOCHECK_EXPECT=${NPC_SYSTEMD_AUTOCHECK_EXPECT:-$DONE_MARKER}

LOG_DIR=$(abspath_from_cwd "$LOG_DIR")
CONSOLE_LOG=$(abspath_from_cwd "$CONSOLE_LOG")
NPC_LOG=$(abspath_from_cwd "$NPC_LOG")
GUEST_CMDS=$(abspath_from_cwd "$GUEST_CMDS")

fail() {
  echo "[npc-systemd-check] FAIL: $*" >&2
  if [ -f "$CONSOLE_LOG" ]; then
    echo "[npc-systemd-check] ---- console tail ----" >&2
    tail -120 "$CONSOLE_LOG" >&2 || true
    echo "[npc-systemd-check] ----------------------" >&2
  fi
  exit 1
}

write_guest_commands() {
  mkdir -p "$LOG_DIR"
  if [ "$GUEST_CMDS_PRESERVE" = "1" ] && [ -s "$GUEST_CMDS" ]; then
    return
  fi
  cat >"$GUEST_CMDS" <<'GUEST_CMDS_EOF'
set +e
set +u
stty -echo 2>/dev/null || true
PS1=; PS2=; PS4=; export PS1 PS2 PS4
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

GUEST_CMDS_EOF

  if [ "$STRICT_CHECK" = "1" ]; then
    cat >>"$GUEST_CMDS" <<'GUEST_CMDS_STRICT_EOF'

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
GUEST_CMDS_STRICT_EOF
  fi

  cat >>"$GUEST_CMDS" <<'GUEST_CMDS_DONE_EOF'
echo "__NPC_SYSTEMD_UART_CHECK_DONE__ rc=$check_fail"
GUEST_CMDS_DONE_EOF

  if [ "$POWEROFF_ENABLE" = "1" ]; then
    cat >>"$GUEST_CMDS" <<'GUEST_CMDS_POWEROFF_EOF'
echo "__NPC_SYSTEMD_POWEROFF_BEGIN__"
sync
systemctl --no-wall poweroff || echo "__NPC_SYSTEMD_POWEROFF_CMD_FAIL__"
GUEST_CMDS_POWEROFF_EOF
  fi
}

check_console_clean() {
  if grep -qaE 'Kernel panic|Oops|Call Trace|HIT BAD TRAP|Bad trap|BUG:|EXT4-fs error|Buffer I/O error|blk_update_request[^[:cntrl:]]*I/O error|end_request[^[:cntrl:]]*I/O error|virtio_blk[^[:cntrl:]]*(error|failed)|Timed out waiting for device .*ttyS0|Dependency failed for .*Serial Getty|Failed to start .*Create System Users' \
      "$CONSOLE_LOG" "$NPC_LOG" 2>/dev/null; then
    return 1
  fi
  return 0
}

check_autocheck_boot_evidence() {
  grep -qaE 'systemd [0-9][^[:cntrl:]]* running in system mode' "$CONSOLE_LOG" &&
    grep -qaF 'Ubuntu 22.04' "$CONSOLE_LOG"
}

require_poweroff_evidence() {
  local label=$1
  local pattern=$2
  grep -qaE "$pattern" "$CONSOLE_LOG" ||
    fail "missing natural-poweroff evidence: $label"
}

require_strict_passes() {
  local label
  for label in \
    uname-riscv64 os-release-ubuntu-2204 root-shell bin-sh bin-bash \
    systemd-state block-vda virtio-blk-driver root-on-vda root-ext4 root-rw \
    rootfs-write-sync-readback virtio-device-name virtio-irq-before-parse \
    virtio-blk-direct-read virtio-irq-growth dmesg-no-critical; do
    grep -qaF "__NPC_CHECK_PASS__:$label" "$CONSOLE_LOG" ||
      fail "missing strict guest PASS marker: $label"
  done
}

if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
  write_guest_commands
else
  mkdir -p "$LOG_DIR"
  cat >"$GUEST_CMDS" <<'GUEST_CMDS_EOF'
# NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck:
# guest checks are emitted by the rootfs wrapper and the run is stopped only
# after systemd/Ubuntu boot evidence appears, so no UART payload is injected.
GUEST_CMDS_EOF
fi

echo "[npc-systemd-check] log dir: $LOG_DIR"
echo "[npc-systemd-check] prompt wait: $PROMPT"
echo "[npc-systemd-check] max cycles: $MAX_CYCLES"
echo "[npc-systemd-check] host timeout: ${HOST_TIMEOUT}s"
echo "[npc-systemd-check] guest command mode: $GUEST_COMMAND_MODE"
echo "[npc-systemd-check] done marker: $DONE_MARKER"
echo "[npc-systemd-check] require prompt: $REQUIRE_PROMPT"
echo "[npc-systemd-check] strict guest checks: $STRICT_CHECK"
echo "[npc-systemd-check] natural poweroff: $POWEROFF_ENABLE"
if [ "$GUEST_COMMAND_MODE" != "uart" ]; then
  echo "[npc-systemd-check] autocheck stop expect: $AUTOCHECK_EXPECT"
else
  echo "[npc-systemd-check] UART wait: $UART_WAIT"
fi
echo "[npc-systemd-check] UART RX cycle gap: $UART_CYCLE_GAP"
echo "[npc-systemd-check] UART RX release delay cycles: $UART_RELEASE_DELAY"
echo "[npc-systemd-check] progress interval: $PROGRESS_INTERVAL"
echo "[npc-systemd-check] guest commands: $GUEST_CMDS"

rootfs_args=()
if [ -n "$RUN_ROOTFS_FILE" ]; then
  rootfs_args+=("--block=$RUN_ROOTFS_FILE")
fi
progress_args=(--no-progress)
if [ -n "$PROGRESS_INTERVAL" ] && [ "$PROGRESS_INTERVAL" != "0" ]; then
  progress_args=("--progress=$PROGRESS_INTERVAL")
fi

set +e
tee_rc=0
if [ "$GUEST_COMMAND_MODE" = "uart" ] && [ "$POWEROFF_ENABLE" = "1" ]; then
  [ -x "$NPC_SIM_BIN" ] || fail "NPC_SIM is not executable: ${NPC_SIM_BIN:-unset}"
  [ -s "$LINUX_IMAGE_FILE" ] || fail "LINUX_IMAGE is missing: ${LINUX_IMAGE_FILE:-unset}"
  [ -s "$RUN_FW_FILE" ] || fail "RUN_FW is missing: ${RUN_FW_FILE:-unset}"
  [ -s "$RUN_DTB_FILE" ] || fail "RUN_DTB is missing: ${RUN_DTB_FILE:-unset}"
  [ -s "$RUN_ROOTFS_FILE" ] || fail "RUN_ROOTFS is missing: ${RUN_ROOTFS_FILE:-unset}"
  [ -n "$NEXT_ADDR_VALUE" ] || fail "NEXT_ADDR is unset"
  [ -n "$DTB_ADDR_VALUE" ] || fail "DTB_ADDR is unset"
  env -u NPC_GUEST_EXPECT \
    NPC_OOO_WINDOW=0 \
    NPC_UART_RX_FILE="$GUEST_CMDS" \
    NPC_UART_RX_WAIT="$UART_WAIT" \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_UART_RX_CYCLE_GAP="$UART_CYCLE_GAP" \
    NPC_UART_RX_RELEASE_DELAY_CYCLES="$UART_RELEASE_DELAY" \
    timeout "${HOST_TIMEOUT}s" \
      "$NPC_SIM_BIN" -b "${progress_args[@]}" --no-diff --max="$MAX_CYCLES" \
        --log="$NPC_LOG" \
        -i "$RUN_FW_FILE" \
        --load="$NEXT_ADDR_VALUE:$LINUX_IMAGE_FILE" \
        --load="$DTB_ADDR_VALUE:$RUN_DTB_FILE" \
        "${rootfs_args[@]}" 2>&1 | tee "$CONSOLE_LOG"
  pipe_rc=("${PIPESTATUS[@]}")
  run_rc=${pipe_rc[0]:-125}
  tee_rc=${pipe_rc[1]:-125}
elif [ "$GUEST_COMMAND_MODE" = "uart" ]; then
  env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_FILE="$GUEST_CMDS" \
    NPC_UART_RX_WAIT="$UART_WAIT" \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_UART_RX_CYCLE_GAP="$UART_CYCLE_GAP" \
    NPC_UART_RX_RELEASE_DELAY_CYCLES="$UART_RELEASE_DELAY" \
    NPC_GUEST_EXPECT="$DONE_MARKER" \
    timeout "${HOST_TIMEOUT}s" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
  run_rc=$?
else
  env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_GUEST_EXPECT="$AUTOCHECK_EXPECT" \
    timeout "${HOST_TIMEOUT}s" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
  run_rc=$?
fi
set -e

[ "$tee_rc" -eq 0 ] || fail "console tee failed (rc=$tee_rc)"

check_console_clean || fail "console contains critical kernel/NPC failure"

if [ "$REQUIRE_PROMPT" = "1" ] && ! grep -qaF "$PROMPT" "$CONSOLE_LOG"; then
  fail "guest root prompt was not observed (rc=$run_rc)"
fi

if [ "$GUEST_COMMAND_MODE" = "uart" ] && [ "$POWEROFF_ENABLE" = "1" ]; then
  [ "$run_rc" -eq 0 ] || fail "NPC did not exit cleanly through reset-syscon (rc=$run_rc)"
  grep -qaF "wait pattern matched; releasing input" "$CONSOLE_LOG" "$NPC_LOG" ||
    fail "guest command release marker was not observed"
  grep -qaF "$DONE_MARKER" "$CONSOLE_LOG" ||
    fail "strict guest done marker was not reached"
  ! grep -qaF '__NPC_CHECK_FAIL__:' "$CONSOLE_LOG" ||
    fail "strict guest checks reported failure"
  ! grep -qaF '__NPC_SYSTEMD_POWEROFF_CMD_FAIL__' "$CONSOLE_LOG" ||
    fail "systemctl poweroff command failed"
  require_strict_passes
  require_poweroff_evidence "OpenSBI boot" 'OpenSBI v[0-9]'
  require_poweroff_evidence "OpenSBI reboot device" 'Platform Reboot Device[[:space:]]*: syscon-reboot'
  require_poweroff_evidence "OpenSBI shutdown device" 'Platform Shutdown Device[[:space:]]*: syscon-poweroff'
  require_poweroff_evidence "Linux SBI SRST" 'SBI SRST extension detected'
  require_poweroff_evidence "guest poweroff command" '__NPC_SYSTEMD_POWEROFF_BEGIN__'
  require_poweroff_evidence "kernel power down" 'reboot: Power down'
  require_poweroff_evidence "OpenSBI system power off" 'System Power Off'
  require_poweroff_evidence "RTL syscon terminal" 'syscon-reset: poweroff requested value=0x00005555'
  require_poweroff_evidence "host system-reset exit" 'exit via system-reset, code=0'
  require_poweroff_evidence "zero exit status" 'HIT GOOD TRAP'
  echo "[npc-systemd-check] PASS strict guest + natural poweroff"
  exit 0
fi

if grep -qaF "$DONE_MARKER" "$CONSOLE_LOG" &&
   ! grep -qaF '__NPC_CHECK_FAIL__:' "$CONSOLE_LOG"; then
  if [ "$GUEST_COMMAND_MODE" != "uart" ] && ! check_autocheck_boot_evidence; then
    fail "guest checks passed but systemd/Ubuntu boot evidence was not observed (rc=$run_rc)"
  fi
  echo "[npc-systemd-check] PASS"
  exit 0
fi

if [ "$GUEST_COMMAND_MODE" = "uart" ] &&
   ! grep -qaF "wait pattern matched; releasing input" "$CONSOLE_LOG" "$NPC_LOG"; then
  fail "guest prompt was not reached before run ended (rc=$run_rc)"
fi

if grep -qaF '__NPC_CHECK_FAIL__:' "$CONSOLE_LOG"; then
  fail "guest checks reported failure (rc=$run_rc)"
fi

fail "done marker not reached (rc=$run_rc)"
