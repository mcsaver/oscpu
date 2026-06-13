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

LOG_DIR=${LOG_DIR:-${NPC_SYSTEMD_CHECK_LOG_DIR:-"$LINUX_HOME/env/logs/linux-front/riscv64-npc-systemd-guest-check"}}
CONSOLE_LOG=${CONSOLE_LOG:-"$LOG_DIR/console.log"}
NPC_LOG=${NPC_LOG:-"$LOG_DIR/npc.log"}
GUEST_CMDS=${NPC_SYSTEMD_GUEST_CMDS:-"$LOG_DIR/npc-guest-check.cmd"}
PROMPT=${NPC_SYSTEMD_PROMPT:-"root@ysyx-ubuntu2204:~#"}
DONE_MARKER=${NPC_SYSTEMD_DONE_MARKER:-"__NPC_SYSTEMD_CHECK_DONE__ rc=0"}
MAX_CYCLES=${MAX_CYCLES:-${NPC_SYSTEMD_CHECK_MAX_CYCLES:-3000000000}}
HOST_TIMEOUT=${NPC_SYSTEMD_HOST_TIMEOUT:-10800}
UART_TRACE=${NPC_SYSTEMD_UART_TRACE:-1}
UART_TRACE_LIMIT=${NPC_SYSTEMD_UART_TRACE_LIMIT:-128}
PROGRESS_INTERVAL=${NPC_SYSTEMD_PROGRESS:-0}

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
  cat >"$GUEST_CMDS" <<'GUEST_CMDS_EOF'
stty -echo 2>/dev/null || true
PS1=; PS2=; PS4=; export PS1 PS2 PS4
echo __NPC_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NPC_CHECK_PASS__:$1"; }
fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; }

uname -m | grep -q '^riscv64$' && pass uname-riscv64 || fail uname-riscv64
if grep -q '^NAME="Ubuntu"' /etc/os-release 2>/dev/null &&
   { grep -q '^VERSION_ID="22.04"' /etc/os-release 2>/dev/null ||
     grep -q '^VERSION_ID=22.04' /etc/os-release 2>/dev/null; }; then
  pass os-release-ubuntu-2204
else
  cat /etc/os-release 2>/dev/null || true
  fail os-release-ubuntu-2204
fi

[ "$(id -u 2>/dev/null)" = "0" ] && pass root-shell || fail root-shell
[ -x /bin/sh ] && pass bin-sh || fail bin-sh
[ -x /bin/bash ] && pass bin-bash || fail bin-bash

systemd_state="$(systemctl --no-pager --plain is-system-running 2>/dev/null || true)"
echo "__NPC_CHECK_SYSTEMD_STATE__:$systemd_state"
case "$systemd_state" in
  running|degraded|starting|initializing) pass systemd-state ;;
  *) fail systemd-state ;;
esac

echo "__NPC_SYSTEMD_CHECK_DONE__ rc=$check_fail"
GUEST_CMDS_EOF
}

check_console_clean() {
  if grep -qaE 'Kernel panic|Oops|Call Trace|HIT BAD TRAP|Bad trap|BUG:|Timed out waiting for device .*ttyS0|Dependency failed for .*Serial Getty|Failed to start .*Create System Users' \
      "$CONSOLE_LOG" "$NPC_LOG" 2>/dev/null; then
    return 1
  fi
  return 0
}

write_guest_commands

echo "[npc-systemd-check] log dir: $LOG_DIR"
echo "[npc-systemd-check] prompt wait: $PROMPT"
echo "[npc-systemd-check] max cycles: $MAX_CYCLES"
echo "[npc-systemd-check] host timeout: ${HOST_TIMEOUT}s"
echo "[npc-systemd-check] progress interval: $PROGRESS_INTERVAL"
echo "[npc-systemd-check] guest commands: $GUEST_CMDS"

set +e
env NPC_OOO_WINDOW=0 \
  NPC_UART_RX_FILE="$GUEST_CMDS" \
  NPC_UART_RX_WAIT="$PROMPT" \
  NPC_UART_RX_TRACE="$UART_TRACE" \
  NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
  NPC_GUEST_EXPECT="$DONE_MARKER" \
  timeout "${HOST_TIMEOUT}s" \
    make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
      MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
run_rc=$?
set -e

check_console_clean || fail "console contains critical kernel/NPC failure"

if grep -qaF "$DONE_MARKER" "$CONSOLE_LOG" &&
   ! grep -qaE '^__NPC_CHECK_FAIL__:' "$CONSOLE_LOG"; then
  echo "[npc-systemd-check] PASS"
  exit 0
fi

if ! grep -qaF "wait pattern matched; releasing input" "$CONSOLE_LOG" "$NPC_LOG"; then
  fail "guest prompt was not reached before run ended (rc=$run_rc)"
fi

if grep -qaE '^__NPC_CHECK_FAIL__:' "$CONSOLE_LOG"; then
  fail "guest checks reported failure (rc=$run_rc)"
fi

fail "done marker not reached (rc=$run_rc)"
