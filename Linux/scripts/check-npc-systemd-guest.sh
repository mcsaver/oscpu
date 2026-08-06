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
ROOTFS_WORK_IMAGE=${NPC_SYSTEMD_ROOTFS_WORK_IMAGE:-}
ROOTFS_EXPECTED_TEMPLATE_SHA256=${NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256:-}
ROOTFS_BINDING_LOG=${NPC_SYSTEMD_ROOTFS_BINDING_LOG:-"$LOG_DIR/rootfs-binding.txt"}
TRANSACTION_PARSER=${NPC_SYSTEMD_TRANSACTION_PARSER:-"$SCRIPT_DIR/npc_systemd_transaction_evidence.py"}
TRANSACTION_EVIDENCE=${NPC_SYSTEMD_TRANSACTION_EVIDENCE:-"$LOG_DIR/systemd-transaction-evidence.json"}
CANONICAL_TRANSACTION_VERIFIER="$SCRIPT_DIR/npc_systemd_transaction_evidence.py"
NEXT_ADDR_VALUE=${NEXT_ADDR:-}
DTB_ADDR_VALUE=${DTB_ADDR:-}
case "$GUEST_COMMAND_MODE" in
  uart|autocheck|systemd-strict) ;;
  *)
    echo "[npc-systemd-check] unsupported guest command mode: $GUEST_COMMAND_MODE" >&2
    exit 2
    ;;
esac
if [ "$POWEROFF_ENABLE" = "1" ] &&
   { { [ "$GUEST_COMMAND_MODE" != "uart" ] && [ "$GUEST_COMMAND_MODE" != "systemd-strict" ]; } ||
     [ "$STRICT_CHECK" != "1" ]; }; then
  echo "[npc-systemd-check] natural poweroff requires uart or systemd-strict mode + strict checks" >&2
  exit 2
fi
if [ "$GUEST_COMMAND_MODE" = "systemd-strict" ] &&
   { [ "$POWEROFF_ENABLE" != "1" ] || [ "$STRICT_CHECK" != "1" ]; }; then
  echo "[npc-systemd-check] systemd-strict mode requires strict checks + natural poweroff" >&2
  exit 2
fi
if [ -n "$ROOTFS_WORK_IMAGE" ] &&
   { [ "$POWEROFF_ENABLE" != "1" ] || [ -z "$RUN_ROOTFS_FILE" ]; }; then
  echo "[npc-systemd-check] isolated rootfs work image requires direct natural-poweroff run + RUN_ROOTFS" >&2
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
  elif [ "$GUEST_COMMAND_MODE" = "systemd-strict" ]; then
    DONE_MARKER="__NPC_SYSTEMD_STRICT_DONE__ rc=0"
  else
    DONE_MARKER="__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0"
  fi
fi
AUTOCHECK_EXPECT=${NPC_SYSTEMD_AUTOCHECK_EXPECT:-$DONE_MARKER}

LOG_DIR=$(abspath_from_cwd "$LOG_DIR")
CONSOLE_LOG=$(abspath_from_cwd "$CONSOLE_LOG")
NPC_LOG=$(abspath_from_cwd "$NPC_LOG")
GUEST_CMDS=$(abspath_from_cwd "$GUEST_CMDS")
TRANSACTION_PARSER=$(abspath_from_cwd "$TRANSACTION_PARSER")
TRANSACTION_EVIDENCE=$(abspath_from_cwd "$TRANSACTION_EVIDENCE")
if [ -n "$RUN_ROOTFS_FILE" ]; then
  RUN_ROOTFS_FILE=$(abspath_from_cwd "$RUN_ROOTFS_FILE")
fi
if [ -n "$ROOTFS_WORK_IMAGE" ]; then
  ROOTFS_WORK_IMAGE=$(abspath_from_cwd "$ROOTFS_WORK_IMAGE")
  ROOTFS_BINDING_LOG=$(abspath_from_cwd "$ROOTFS_BINDING_LOG")
fi

fail() {
  echo "[npc-systemd-check] FAIL: $*" >&2
  if [ "${LOG_OUTPUTS_READY:-0}" = "1" ] && [ -f "$CONSOLE_LOG" ]; then
    echo "[npc-systemd-check] ---- console tail ----" >&2
    tail -120 "$CONSOLE_LOG" >&2 || true
    echo "[npc-systemd-check] ----------------------" >&2
  fi
  exit 1
}

paths_alias() {
  local left=$1
  local right=$2
  local left_resolved
  local right_resolved
  left_resolved=$(realpath -m -- "$left") || return 2
  right_resolved=$(realpath -m -- "$right") || return 2
  if [ "$left_resolved" = "$right_resolved" ]; then
    return 0
  fi
  if [ -e "$left" ] && [ -e "$right" ] && [ "$left" -ef "$right" ]; then
    return 0
  fi
  return 1
}

require_no_path_alias() {
  local left_label=$1
  local left=$2
  local right_label=$3
  local right=$4
  local alias_rc
  if paths_alias "$left" "$right"; then
    fail "$left_label path aliases $right_label: $left"
  else
    alias_rc=$?
  fi
  [ "$alias_rc" -eq 1 ] ||
    fail "unable to resolve $left_label/$right_label path identity"
}

preclear_output() {
  local label=$1
  local path=$2
  if [ -d "$path" ]; then
    fail "$label output path is a directory: $path"
  fi
  rm -f -- "$path" || fail "unable to preclear $label output: $path"
}

require_distinct_output_paths() {
  if [ "$CONSOLE_LOG" = "$NPC_LOG" ] ||
     [ "$CONSOLE_LOG" = "$TRANSACTION_EVIDENCE" ] ||
     [ "$NPC_LOG" = "$TRANSACTION_EVIDENCE" ]; then
    fail "console, NPC and transaction evidence outputs must use distinct paths"
  fi
}

require_safe_managed_paths() {
  local managed_labels=(console "NPC log" "transaction evidence" "guest commands")
  local managed_paths=("$CONSOLE_LOG" "$NPC_LOG" "$TRANSACTION_EVIDENCE" "$GUEST_CMDS")
  local input_labels=(host-script "transaction parser" "canonical transaction verifier")
  local input_paths=(
    "$SCRIPT_DIR/check-npc-systemd-guest.sh"
    "$TRANSACTION_PARSER"
    "$CANONICAL_TRANSACTION_VERIFIER"
  )
  local index
  local other

  if [ -n "$ROOTFS_WORK_IMAGE" ]; then
    managed_labels+=("rootfs work image" "rootfs binding log")
    managed_paths+=("$ROOTFS_WORK_IMAGE" "$ROOTFS_BINDING_LOG")
  fi
  for index in "${!managed_paths[@]}"; do
    for ((other = index + 1; other < ${#managed_paths[@]}; other++)); do
      require_no_path_alias \
        "${managed_labels[$index]} output" "${managed_paths[$index]}" \
        "${managed_labels[$other]} output" "${managed_paths[$other]}"
    done
  done

  for index in NPC_SIM_BIN LINUX_IMAGE_FILE RUN_FW_FILE RUN_DTB_FILE RUN_ROOTFS_FILE; do
    if [ -n "${!index}" ]; then
      input_labels+=("$index input")
      input_paths+=("${!index}")
    fi
  done
  for index in "${!managed_paths[@]}"; do
    for other in "${!input_paths[@]}"; do
      require_no_path_alias \
        "${managed_labels[$index]} output" "${managed_paths[$index]}" \
        "${input_labels[$other]}" "${input_paths[$other]}"
    done
  done
}

HOST_TIMEOUT_DIAGNOSTIC=
cleanup_host_timeout_diagnostic() {
  if [ -n "$HOST_TIMEOUT_DIAGNOSTIC" ]; then
    rm -f -- "$HOST_TIMEOUT_DIAGNOSTIC"
  fi
}

run_with_host_timeout() {
  LC_ALL=C timeout --verbose "${HOST_TIMEOUT}s" \
    bash -c 'exec "$@" 2>&1' npc-host-timeout "$@" \
    2>"$HOST_TIMEOUT_DIAGNOSTIC"
}

host_timeout_expired() {
  [ -n "$HOST_TIMEOUT_DIAGNOSTIC" ] &&
    grep -qaF 'timeout: sending signal TERM to command' "$HOST_TIMEOUT_DIAGNOSTIC"
}

write_guest_commands() {
  mkdir -p "$LOG_DIR"
  if [ "$GUEST_CMDS_PRESERVE" = "1" ] && [ -s "$GUEST_CMDS" ]; then
    return
  fi
  if [ "$STRICT_CHECK" = "1" ]; then
    cat >"$GUEST_CMDS" <<'GUEST_CMDS_STRICT_LAUNCH_EOF'
set +e
set +u
stty -echo 2>/dev/null || true
GUEST_CMDS_STRICT_LAUNCH_EOF
    if [ "$POWEROFF_ENABLE" = "1" ]; then
      echo 'exec /usr/local/sbin/ysyx-npc-systemd-strict-check --poweroff' >>"$GUEST_CMDS"
    else
      echo 'exec /usr/local/sbin/ysyx-npc-systemd-strict-check' >>"$GUEST_CMDS"
    fi
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

  cat >>"$GUEST_CMDS" <<'GUEST_CMDS_DONE_EOF'
echo "__NPC_SYSTEMD_UART_CHECK_DONE__ rc=$check_fail"
GUEST_CMDS_DONE_EOF
}

check_console_clean() {
  if grep -qaiE 'Kernel panic|Oops|Call Trace|HIT BAD TRAP|Bad trap|(^|[^[:alnum:]_])BUG:|EXT4-fs error|Buffer I/O error|blk_update_request[^[:cntrl:]]*I/O error|end_request[^[:cntrl:]]*I/O error|virtio_blk[^[:cntrl:]]*(error|failed)|Timed out waiting for device .*ttyS0|Dependency failed for .*Serial Getty|Failed to start .*Create System Users' \
      "$CONSOLE_LOG" "$NPC_LOG" 2>/dev/null; then
    return 1
  fi
  return 0
}

console_has_rtl_assertion_failure() {
  grep -qaiE '\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT|V9R-(MEM-)?SQ-RETRY-C0-HANDOFF|S2-G1-TCOLL-INGRESS-DUP|V10D-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|\[.*ASSERT.*FAIL' \
    "$CONSOLE_LOG" "$NPC_LOG" 2>/dev/null
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

LOG_OUTPUTS_READY=0
require_distinct_output_paths
require_safe_managed_paths

if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
  write_guest_commands
else
  mkdir -p "$LOG_DIR"
  cat >"$GUEST_CMDS" <<'GUEST_CMDS_EOF'
# NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck or systemd-strict:
# guest checks are emitted by rootfs systemd units; no UART payload is used.
GUEST_CMDS_EOF
fi

mkdir -p "$LOG_DIR"
preclear_output "console" "$CONSOLE_LOG"
preclear_output "NPC log" "$NPC_LOG"
preclear_output "transaction evidence" "$TRANSACTION_EVIDENCE"

if [ -n "$ROOTFS_WORK_IMAGE" ]; then
  rootfs_prepare_args=(
    --template "$RUN_ROOTFS_FILE"
    --run-image "$ROOTFS_WORK_IMAGE"
    --binding-out "$ROOTFS_BINDING_LOG"
  )
  if [ -n "$ROOTFS_EXPECTED_TEMPLATE_SHA256" ]; then
    rootfs_prepare_args+=(
      --expected-template-sha256 "$ROOTFS_EXPECTED_TEMPLATE_SHA256"
    )
  fi
  "$SCRIPT_DIR/prepare-npc-rootfs-run-image.sh" "${rootfs_prepare_args[@]}"
  echo "[npc-systemd-check] rootfs template: $RUN_ROOTFS_FILE"
  echo "[npc-systemd-check] rootfs work image: $ROOTFS_WORK_IMAGE"
  echo "[npc-systemd-check] rootfs binding: $ROOTFS_BINDING_LOG"
  RUN_ROOTFS_FILE=$ROOTFS_WORK_IMAGE
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
if [ "$GUEST_COMMAND_MODE" = "autocheck" ]; then
  echo "[npc-systemd-check] autocheck stop expect: $AUTOCHECK_EXPECT"
elif [ "$GUEST_COMMAND_MODE" = "uart" ]; then
  echo "[npc-systemd-check] UART wait: $UART_WAIT"
else
  echo "[npc-systemd-check] strict unit: ysyx-npc-systemd-strict.service"
fi
echo "[npc-systemd-check] UART RX cycle gap: $UART_CYCLE_GAP"
echo "[npc-systemd-check] UART RX release delay cycles: $UART_RELEASE_DELAY"
echo "[npc-systemd-check] progress interval: $PROGRESS_INTERVAL"
echo "[npc-systemd-check] guest commands: $GUEST_CMDS"
if [ "$GUEST_COMMAND_MODE" = "systemd-strict" ]; then
  echo "[npc-systemd-check] transaction parser: $TRANSACTION_PARSER"
  echo "[npc-systemd-check] canonical transaction verifier: $CANONICAL_TRANSACTION_VERIFIER"
  echo "[npc-systemd-check] transaction evidence: $TRANSACTION_EVIDENCE"
fi

rootfs_args=()
if [ -n "$RUN_ROOTFS_FILE" ]; then
  rootfs_args+=("--block=$RUN_ROOTFS_FILE")
fi
progress_args=(--no-progress)
if [ -n "$PROGRESS_INTERVAL" ] && [ "$PROGRESS_INTERVAL" != "0" ]; then
  progress_args=("--progress=$PROGRESS_INTERVAL")
fi

HOST_TIMEOUT_DIAGNOSTIC=$(mktemp "$LOG_DIR/.npc-host-timeout.XXXXXX") ||
  fail "unable to allocate host-timeout diagnostic"
trap cleanup_host_timeout_diagnostic EXIT

set +e
tee_rc=0
if [ "$POWEROFF_ENABLE" = "1" ]; then
  [ -x "$NPC_SIM_BIN" ] || fail "NPC_SIM is not executable: ${NPC_SIM_BIN:-unset}"
  [ -s "$LINUX_IMAGE_FILE" ] || fail "LINUX_IMAGE is missing: ${LINUX_IMAGE_FILE:-unset}"
  [ -s "$RUN_FW_FILE" ] || fail "RUN_FW is missing: ${RUN_FW_FILE:-unset}"
  [ -s "$RUN_DTB_FILE" ] || fail "RUN_DTB is missing: ${RUN_DTB_FILE:-unset}"
  [ -s "$RUN_ROOTFS_FILE" ] || fail "RUN_ROOTFS is missing: ${RUN_ROOTFS_FILE:-unset}"
  [ -n "$NEXT_ADDR_VALUE" ] || fail "NEXT_ADDR is unset"
  [ -n "$DTB_ADDR_VALUE" ] || fail "DTB_ADDR is unset"
  sim_env=(env -u NPC_GUEST_EXPECT)
  if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
    sim_env+=(
      NPC_OOO_WINDOW=0
      NPC_UART_RX_FILE="$GUEST_CMDS"
      NPC_UART_RX_WAIT="$UART_WAIT"
      NPC_UART_RX_TRACE="$UART_TRACE"
      NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT"
      NPC_UART_RX_CYCLE_GAP="$UART_CYCLE_GAP"
      NPC_UART_RX_RELEASE_DELAY_CYCLES="$UART_RELEASE_DELAY"
    )
  else
    sim_env+=(
      -u NPC_UART_RX_FILE
      -u NPC_UART_RX_TEXT
      -u NPC_UART_RX_WAIT
      -u NPC_UART_RX_CYCLE_GAP
      -u NPC_UART_RX_RELEASE_DELAY_CYCLES
      NPC_OOO_WINDOW=0
      NPC_UART_RX_TRACE=1
      NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT"
    )
  fi
  run_with_host_timeout \
    "${sim_env[@]}" \
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
  run_with_host_timeout env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_FILE="$GUEST_CMDS" \
    NPC_UART_RX_WAIT="$UART_WAIT" \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_UART_RX_CYCLE_GAP="$UART_CYCLE_GAP" \
    NPC_UART_RX_RELEASE_DELAY_CYCLES="$UART_RELEASE_DELAY" \
    NPC_GUEST_EXPECT="$DONE_MARKER" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
  run_rc=$?
else
  run_with_host_timeout env NPC_OOO_WINDOW=0 \
    NPC_UART_RX_TRACE="$UART_TRACE" \
    NPC_UART_RX_TRACE_LIMIT="$UART_TRACE_LIMIT" \
    NPC_GUEST_EXPECT="$AUTOCHECK_EXPECT" \
      make -C "$LINUX_HOME" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
        MAX_CYCLES="$MAX_CYCLES" PROGRESS="$PROGRESS_INTERVAL" LOG_DIR="$LOG_DIR" run
  run_rc=$?
fi
set -e

LOG_OUTPUTS_READY=1
host_timed_out=0
if [ "$run_rc" -eq 124 ] && host_timeout_expired; then
  host_timed_out=1
fi
if [ -s "$HOST_TIMEOUT_DIAGNOSTIC" ]; then
  cat "$HOST_TIMEOUT_DIAGNOSTIC" >&2
fi

[ "$tee_rc" -eq 0 ] || fail "console tee failed (rc=$tee_rc)"
[ -f "$CONSOLE_LOG" ] && [ -r "$CONSOLE_LOG" ] ||
  fail "console log is not a readable regular file: $CONSOLE_LOG"
[ -f "$NPC_LOG" ] && [ -r "$NPC_LOG" ] ||
  fail "NPC log is not a readable regular file: $NPC_LOG"

transaction_rc=77
transaction_verify_rc=77
if [ "$GUEST_COMMAND_MODE" = "systemd-strict" ]; then
  [ -x "$TRANSACTION_PARSER" ] ||
    fail "systemd transaction parser is not executable: $TRANSACTION_PARSER"
  [ -x "$CANONICAL_TRANSACTION_VERIFIER" ] ||
    fail "canonical systemd transaction verifier is not executable: $CANONICAL_TRANSACTION_VERIFIER"
  set +e
  python3 -B "$TRANSACTION_PARSER" collect \
    --console "$CONSOLE_LOG" \
    --npc-log "$NPC_LOG" \
    --protocol auto \
    --terminal-contract natural-poweroff \
    --producer-closed \
    --json-out "$TRANSACTION_EVIDENCE"
  transaction_rc=$?
  python3 -B "$CANONICAL_TRANSACTION_VERIFIER" verify \
    --console "$CONSOLE_LOG" \
    --npc-log "$NPC_LOG" \
    --protocol auto \
    --terminal-contract natural-poweroff \
    --producer-closed \
    --evidence "$TRANSACTION_EVIDENCE" \
    --require-status PASS
  transaction_verify_rc=$?
  set -e
fi

check_console_clean || fail "console contains critical kernel/NPC failure"

rtl_assertion_scan_rc=0
console_has_rtl_assertion_failure || rtl_assertion_scan_rc=$?
if [ "$rtl_assertion_scan_rc" -gt 1 ]; then
  fail "RTL assertion evidence query failed (rc=$rtl_assertion_scan_rc)"
fi
if [ "$rtl_assertion_scan_rc" -eq 0 ]; then
  fail "RTL assertion marker was observed"
fi

if [ "$host_timed_out" -eq 1 ] && [ "$rtl_assertion_scan_rc" -eq 1 ]; then
  echo "[npc-systemd-check] GAP: RV64 host wall-clock budget expired before natural terminal transaction (host_timeout=${HOST_TIMEOUT}s max_cycles=$MAX_CYCLES)" >&2
  exit 124
fi

if [ "$run_rc" -ne 0 ] &&
   grep -qaE "cycles=${MAX_CYCLES}, commits=[0-9]+, core-state=" "$CONSOLE_LOG" &&
   grep -qaE 'npc: .*ABORT at pc' "$CONSOLE_LOG" &&
   [ "$rtl_assertion_scan_rc" -eq 1 ]; then
  echo "[npc-systemd-check] GAP: RV64 simulation cycle budget exhausted at cycles=$MAX_CYCLES before natural terminal transaction" >&2
  exit 124
fi

if [ "$REQUIRE_PROMPT" = "1" ] && ! grep -qaF "$PROMPT" "$CONSOLE_LOG"; then
  fail "guest root prompt was not observed (rc=$run_rc)"
fi

if [ "$POWEROFF_ENABLE" = "1" ]; then
  [ "$run_rc" -eq 0 ] || fail "NPC did not exit cleanly through reset-syscon (rc=$run_rc)"
  if [ "$GUEST_COMMAND_MODE" = "uart" ]; then
    grep -qaF "wait pattern matched; releasing input" "$CONSOLE_LOG" "$NPC_LOG" ||
      fail "guest command release marker was not observed"
  else
    grep -qaF "loaded bytes=0 file_bytes=0 text_bytes=0" "$CONSOLE_LOG" "$NPC_LOG" ||
      fail "zero-byte UART source evidence was not observed"
    ! grep -qaE 'uart-rx\][[:space:]]+pop=' "$CONSOLE_LOG" "$NPC_LOG" ||
      fail "UART RX activity was observed in systemd-strict mode"
  fi
  if [ "$GUEST_COMMAND_MODE" = "systemd-strict" ]; then
    [ "$transaction_rc" -eq 0 ] ||
      fail "bounded systemd transaction evidence is RED: $TRANSACTION_EVIDENCE"
    [ "$transaction_verify_rc" -eq 0 ] ||
      fail "canonical systemd transaction verification is RED: $TRANSACTION_EVIDENCE"
  else
    grep -qaF "$DONE_MARKER" "$CONSOLE_LOG" ||
      fail "strict guest done marker was not reached"
    ! grep -qaF '__NPC_CHECK_FAIL__:' "$CONSOLE_LOG" ||
      fail "strict guest checks reported failure"
    require_strict_passes
  fi
  require_poweroff_evidence "OpenSBI boot" 'OpenSBI v[0-9]'
  require_poweroff_evidence "OpenSBI reboot device" 'Platform Reboot Device[[:space:]]*: syscon-reboot'
  require_poweroff_evidence "OpenSBI shutdown device" 'Platform Shutdown Device[[:space:]]*: syscon-poweroff'
  require_poweroff_evidence "Linux SBI SRST" 'SBI SRST extension detected'
  echo "[npc-systemd-check] PASS strict guest + natural poweroff (mode=$GUEST_COMMAND_MODE)"
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
