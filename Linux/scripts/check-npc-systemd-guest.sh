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
UART_WAIT=${NPC_SYSTEMD_UART_WAIT:-$PROMPT}
GUEST_COMMAND_MODE=${NPC_SYSTEMD_GUEST_COMMAND_MODE:-autocheck}
GUEST_CMDS_PRESERVE=${NPC_SYSTEMD_GUEST_CMDS_PRESERVE:-0}
PROGRESS_INTERVAL=${NPC_SYSTEMD_PROGRESS:-0}

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

echo "__NPC_SYSTEMD_UART_CHECK_DONE__ rc=$check_fail"
GUEST_CMDS_EOF
}

check_console_clean() {
  if grep -qaE 'Kernel panic|Oops|Call Trace|HIT BAD TRAP|Bad trap|BUG:|Timed out waiting for device .*ttyS0|Dependency failed for .*Serial Getty|Failed to start .*Create System Users' \
      "$CONSOLE_LOG" "$NPC_LOG" 2>/dev/null; then
    return 1
  fi
  return 0
}

check_autocheck_boot_evidence() {
  grep -qaE 'systemd [0-9][^[:cntrl:]]* running in system mode' "$CONSOLE_LOG" &&
    grep -qaF 'Ubuntu 22.04' "$CONSOLE_LOG"
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
if [ "$GUEST_COMMAND_MODE" != "uart" ]; then
  echo "[npc-systemd-check] autocheck stop expect: $AUTOCHECK_EXPECT"
else
  echo "[npc-systemd-check] UART wait: $UART_WAIT"
fi
echo "[npc-systemd-check] UART RX cycle gap: $UART_CYCLE_GAP"
echo "[npc-systemd-check] progress interval: $PROGRESS_INTERVAL"
echo "[npc-systemd-check] guest commands: $GUEST_CMDS"

set +e
if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
  env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_FILE="$GUEST_CMDS" \
    NPC_UART_RX_WAIT="$UART_WAIT" \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_UART_RX_CYCLE_GAP="$UART_CYCLE_GAP" \
    NPC_GUEST_EXPECT="$DONE_MARKER" \
    timeout "${HOST_TIMEOUT}s" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
else
  env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_GUEST_EXPECT="$AUTOCHECK_EXPECT" \
    timeout "${HOST_TIMEOUT}s" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
fi
run_rc=$?
set -e

check_console_clean || fail "console contains critical kernel/NPC failure"

if ! grep -qaF "$PROMPT" "$CONSOLE_LOG"; then
  fail "guest root prompt was not observed (rc=$run_rc)"
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
