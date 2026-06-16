#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)

NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
NEMU_PLATFORM_ROOT=${NEMU_PLATFORM_ROOT:-"$ENV_ROOT/platforms/nemu"}
LOG_DIR=${LOG_DIR:-"$NEMU_PLATFORM_ROOT/logs/linux-front/riscv64-nemu-python-int-preflight"}
LOG_FILE=${LOG_FILE:-"$LOG_DIR/nemu.log"}
CONSOLE_LOG=${CONSOLE_LOG:-"$LOG_DIR/console.log"}
SERIAL_FIFO=${NEMU_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}
GUEST_CMDS=${NEMU_PYTHON_INT_GUEST_CMDS:-"$LOG_DIR/python-int-preflight.cmd"}
PROBE_SRC=${NEMU_PYTHON_INT_PROBE_SRC:-"$LINUX_HOME/tools/nemu-python-int-preflight.py"}
PROBE_B64=${NEMU_PYTHON_INT_PROBE_B64:-"$LOG_DIR/nemu-python-int-preflight.py.b64"}
SUMMARY_FILE=${NEMU_PYTHON_INT_SUMMARY:-"$LOG_DIR/python-int-preflight-summary.tsv"}

LINUX_IMAGE=${LINUX_IMAGE:-"$NEMU_PLATFORM_ROOT/build/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$NEMU_PLATFORM_ROOT/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/riscv64-nemu/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$NEMU_PLATFORM_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4"}
RUN_ROOTFS_OVERLAY=${NEMU_PYTHON_INT_ROOTFS_OVERLAY-"$LOG_DIR/rootfs-overlay.raw"}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}
MAX_CYCLES=${MAX_CYCLES:-20000000000}

CHECK_TIMEOUT=${NEMU_PYTHON_INT_CHECK_TIMEOUT:-1200}
BOOT_TIMEOUT=${NEMU_PYTHON_INT_BOOT_TIMEOUT:-900}
FIFO_TIMEOUT=${NEMU_PYTHON_INT_FIFO_TIMEOUT:-60}
POLL_INTERVAL=${NEMU_PYTHON_INT_POLL_INTERVAL:-2}
INPUT_DELAY=${NEMU_PYTHON_INT_INPUT_DELAY:-0}
INPUT_CHUNK_BYTES=${NEMU_PYTHON_INT_INPUT_CHUNK_BYTES:-8}
INPUT_CHUNK_DELAY=${NEMU_PYTHON_INT_INPUT_CHUNK_DELAY:-0}
LOOPS=${NEMU_PYTHON_INT_LOOPS:-5}
POWEROFF_ENABLE=${NEMU_PYTHON_INT_POWEROFF:-1}
POWEROFF_TIMEOUT=${NEMU_PYTHON_INT_POWEROFF_TIMEOUT:-180}
STAGE_MODE=${NEMU_PYTHON_INT_STAGE_MODE:-focused}
STAGE_TIMEOUT=${NEMU_PYTHON_INT_STAGE_TIMEOUT:-120}
STAGE_PREWARM=${NEMU_PYTHON_INT_STAGE_PREWARM:-auto}

SUMMARY_INITIALIZED=0
SUMMARY_FINALIZED=0
host_start_seconds=
boot_seconds=
total_seconds=
done_line=

append_summary_result() {
  local status=$1
  local reason=${2:-}
  local done=${done_line:-}
  local total_value=${total_seconds:-}

  [ "${SUMMARY_INITIALIZED:-0}" = "1" ] || return 0
  [ "${SUMMARY_FINALIZED:-0}" = "0" ] || return 0
  SUMMARY_FINALIZED=1

  if [ -z "$total_value" ] && [ -n "${host_start_seconds:-}" ]; then
    total_value=$((SECONDS - host_start_seconds))
  fi

  # 失败也必须落结构化摘要；否则 evidence 只停在 started，会误导后续 DB/e2e 判断。
  local reason_clean="$reason"
  reason_clean=${reason_clean//$'\t'/ }
  reason_clean=${reason_clean//$'\r'/ }
  reason_clean=${reason_clean//$'\n'/ }

  {
    printf 'status\t%s\n' "$status"
    if [ -n "$done" ]; then
      printf 'done_line\t%s\n' "$done"
    fi
    if [ "$status" != "pass" ] && [ -n "$reason_clean" ]; then
      printf 'fail_reason\t%s\n' "$reason_clean"
    fi
    if [ -f "$CONSOLE_LOG" ]; then
      grep -aE '^__NEMU_PYTHON_INT_STAGE_RC__:' "$CONSOLE_LOG" |
        tr -d '\r' |
        awk -F: '{printf "stage_rc.%s\t%s\n", $2, $3}' || true
    fi
    if [ -n "${boot_seconds:-}" ]; then
      printf 'boot_seconds\t%s\n' "$boot_seconds"
    fi
    if [ -n "$total_value" ]; then
      printf 'total_seconds\t%s\n' "$total_value"
    fi
  } >>"$SUMMARY_FILE"
}

fail() {
  echo "[nemu-python-int] FAIL: $*" >&2
  append_summary_result "fail" "$*"
  if [ -f "$CONSOLE_LOG" ]; then
    echo "[nemu-python-int] ---- console tail ----" >&2
    tail -120 "$CONSOLE_LOG" >&2 || true
    echo "[nemu-python-int] ----------------------" >&2
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

require_nonnegative_decimal() {
  local name=$1
  local value=$2
  case "$value" in
    ''|*[!0-9.]*|*.*.*) fail "$name must be a non-negative decimal: $value" ;;
  esac
  case "$value" in
    *[0-9]*) ;;
    *) fail "$name must be a non-negative decimal: $value" ;;
  esac
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

wait_for_log_regex() {
  local pattern=$1
  local timeout=$2
  local deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if grep -qaE "$pattern" "$CONSOLE_LOG"; then
      return 0
    fi
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      fail "NEMU exited before log marker: $pattern"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for log marker: $pattern"
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

wait_for_nemu_exit() {
  local timeout=$1
  local deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if ! kill -0 "$nemu_pid" 2>/dev/null; then
      wait "$nemu_pid"
      return $?
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for NEMU poweroff exit"
}

send_guest_commands() {
  local line_delay=$1
  local chunk_delay=$2
  local cmd_file=$3
  local chunk_bytes=$INPUT_CHUNK_BYTES
  if [ "$line_delay" = "0" ] && [ "$chunk_bytes" = "0" ]; then
    cat "$cmd_file" >"$SERIAL_FIFO"
    return
  fi

  exec 3>"$SERIAL_FIFO"
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$chunk_bytes" -le 0 ] 2>/dev/null; then
      printf '%s\n' "$line" >&3
      [ "$line_delay" = "0" ] || sleep "$line_delay"
      continue
    fi
    local text="${line}"$'\n'
    local len=${#text}
    local pos=0
    while [ "$pos" -lt "$len" ]; do
      printf '%s' "${text:$pos:$chunk_bytes}" >&3
      pos=$((pos + chunk_bytes))
      [ "$chunk_delay" = "0" ] || sleep "$chunk_delay"
    done
    [ "$line_delay" = "0" ] || sleep "$line_delay"
  done <"$cmd_file"
  exec 3>&-
}

require_executable "$NEMU_SIM" "NEMU"
require_file "$LINUX_IMAGE" "Linux Image"
require_file "$RUN_FW" "OpenSBI firmware"
require_file "$RUN_DTB" "rootfs DTB"
require_file "$RUN_ROOTFS" "Ubuntu full rootfs"
require_file "$PROBE_SRC" "PyLong preflight probe"
require_uint "NEMU_PYTHON_INT_CHECK_TIMEOUT" "$CHECK_TIMEOUT"
require_uint "NEMU_PYTHON_INT_BOOT_TIMEOUT" "$BOOT_TIMEOUT"
require_uint "NEMU_PYTHON_INT_FIFO_TIMEOUT" "$FIFO_TIMEOUT"
require_uint "NEMU_PYTHON_INT_LOOPS" "$LOOPS"
require_uint "NEMU_PYTHON_INT_STAGE_TIMEOUT" "$STAGE_TIMEOUT"
require_uint "NEMU_PYTHON_INT_POWEROFF" "$POWEROFF_ENABLE"
require_uint "NEMU_PYTHON_INT_INPUT_CHUNK_BYTES" "$INPUT_CHUNK_BYTES"
require_nonnegative_decimal "NEMU_PYTHON_INT_INPUT_DELAY" "$INPUT_DELAY"
require_nonnegative_decimal "NEMU_PYTHON_INT_INPUT_CHUNK_DELAY" "$INPUT_CHUNK_DELAY"
[ "$LOOPS" -gt 0 ] || fail "NEMU_PYTHON_INT_LOOPS must be positive: $LOOPS"
[ "$STAGE_TIMEOUT" -gt 0 ] || fail "NEMU_PYTHON_INT_STAGE_TIMEOUT must be positive: $STAGE_TIMEOUT"

case "$STAGE_MODE" in
  focused)
    default_stage_tags="focused"
    default_stage_prewarm=0
    ;;
  full-lite)
    # 复用 full hard gate 的关键 tag 名称，让 focused gate 更接近 before/runtime/after 时序。
    default_stage_tags="before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime"
    default_stage_prewarm=1
    ;;
  systemctl-lite)
    default_stage_tags="before-runtime,runtime-after-core-tools,runtime-after-systemd-files,runtime-after-systemctl-daemon-reload,runtime-after-systemctl-root-enable,runtime-after-systemctl-runtime-start,runtime-after-systemctl,after-runtime"
    default_stage_prewarm=1
    ;;
  custom)
    default_stage_tags=""
    default_stage_prewarm=0
    ;;
  *)
    fail "unknown NEMU_PYTHON_INT_STAGE_MODE: $STAGE_MODE"
    ;;
esac

stage_tags_raw=${NEMU_PYTHON_INT_TAGS:-"$default_stage_tags"}
stage_tags_raw=${stage_tags_raw//,/ }
stage_tags=()
for stage_tag in $stage_tags_raw; do
  case "$stage_tag" in
    ''|*[!A-Za-z0-9._-]*) fail "invalid NEMU_PYTHON_INT_TAGS entry: $stage_tag" ;;
  esac
  stage_tags+=("$stage_tag")
done
[ "${#stage_tags[@]}" -gt 0 ] || fail "NEMU_PYTHON_INT_TAGS produced no stages"
stage_tags_space="${stage_tags[*]}"
stage_tags_csv=$(IFS=,; echo "${stage_tags[*]}")
case "$STAGE_PREWARM" in
  auto) stage_prewarm_effective=$default_stage_prewarm ;;
  0|1) stage_prewarm_effective=$STAGE_PREWARM ;;
  *) fail "NEMU_PYTHON_INT_STAGE_PREWARM must be auto, 0 or 1: $STAGE_PREWARM" ;;
esac

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$LOG_FILE" "$GUEST_CMDS" "$PROBE_B64" "$SUMMARY_FILE"
block_overlay_args=()
if [ -n "$RUN_ROOTFS_OVERLAY" ]; then
  # focused gate 会写 guest 临时文件；overlay 保护 full rootfs 基准镜像。
  mkdir -p "$(dirname -- "$RUN_ROOTFS_OVERLAY")"
  rm -f "$RUN_ROOTFS_OVERLAY"
  block_overlay_args=(--block-overlay="$RUN_ROOTFS_OVERLAY")
fi
: >"$CONSOLE_LOG"

probe_sha="$(sha256sum "$PROBE_SRC" | awk '{print $1}')" ||
  fail "failed to hash PyLong probe"
probe_bytes="$(wc -c <"$PROBE_SRC" | tr -d '[:space:]')" ||
  fail "failed to size PyLong probe"
base64 -w 76 "$PROBE_SRC" >"$PROBE_B64" ||
  fail "failed to encode PyLong probe"

{
  printf 'NEMU_GUEST_PYTHON_INT_LOOPS=%s\n' "$LOOPS"
  printf 'NEMU_GUEST_PYTHON_INT_STAGE_MODE=%s\n' "$STAGE_MODE"
  printf 'NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=%s\n' "$STAGE_TIMEOUT"
  printf 'NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=%s\n' "$stage_prewarm_effective"
  printf "NEMU_GUEST_PYTHON_INT_TAGS='%s'\n" "$stage_tags_space"
  printf 'NEMU_GUEST_POWEROFF=%s\n' "$POWEROFF_ENABLE"
  printf 'NEMU_GUEST_PROBE_SHA=%s\n' "$probe_sha"
  printf 'NEMU_GUEST_PROBE_BYTES=%s\n' "$probe_bytes"
  cat <<'GUEST_CMDS_HEAD'
stty -echo -ixon -ixoff 2>/dev/null || true
PS1=; PS2=; PS4=; export PS1 PS2 PS4
echo "__NEMU_PYTHON_INT_FOCUSED_BEGIN__"
check_fail=0
pass() { echo "__NEMU_CHECK_PASS__:$1"; }
fail() { echo "__NEMU_CHECK_FAIL__:$1"; check_fail=1; }
probe_py=/tmp/nemu-python-int-preflight.py
probe_b64=/tmp/nemu-python-int-preflight.py.b64
probe_log_dir=/tmp/nemu-python-int-preflight-logs
rm -rf "$probe_log_dir"
mkdir -p "$probe_log_dir"
cat > "$probe_b64" <<'__NEMU_PYTHON_INT_PROBE_B64__'
GUEST_CMDS_HEAD
  cat "$PROBE_B64"
  cat <<'GUEST_CMDS_TAIL'
__NEMU_PYTHON_INT_PROBE_B64__
if ! command -v base64 >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then
  echo "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__"
  fail python-int-preflight-focused-loop
elif ! base64 -d "$probe_b64" > "$probe_py"; then
  echo "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__"
  fail python-int-preflight-focused-loop
else
  chmod +x "$probe_py" 2>/dev/null || true
  probe_sha="$(sha256sum "$probe_py" 2>/dev/null)"
  probe_sha="${probe_sha%% *}"
  probe_bytes="$(wc -c < "$probe_py" 2>/dev/null || echo 0)"
  echo "__NEMU_PYTHON_INT_PROBE_BYTES__:$probe_bytes/$NEMU_GUEST_PROBE_BYTES"
  echo "__NEMU_PYTHON_INT_PROBE_SHA256__:$probe_sha/$NEMU_GUEST_PROBE_SHA"
  if [ "$probe_sha" != "$NEMU_GUEST_PROBE_SHA" ] ||
     [ "$probe_bytes" != "$NEMU_GUEST_PROBE_BYTES" ]; then
    echo "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__"
    fail python-int-preflight-focused-loop
  else
    run_python_int_stage_prewarm() {
      stage_tag="$1"
      if [ "${NEMU_GUEST_PYTHON_INT_STAGE_PREWARM:-0}" != "1" ]; then
        return 0
      fi
      case "$stage_tag" in
        focused|before-runtime) return 0 ;;
      esac
      echo "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__:$stage_tag"
      prewarm_rc=0
      timeout 60s python3 - "$stage_tag" <<'PY' || prewarm_rc=$?
import sys
tag = sys.argv[1]
import datetime
import optparse
import re
import sqlite3
import textwrap
print("__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__:%s:%s:%s" % (
    tag, datetime.datetime.utcfromtimestamp(0).isoformat(), len(textwrap.TextWrapper.wordsep_re.pattern)))
print("__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__:%s:%s" % (
    tag, re.compile(r"(?=-{2,}\w)").pattern))
print("__NEMU_PYTHON_INT_STAGE_PREWARM_SQLITE__:%s:%s" % (
    tag, sqlite3.sqlite_version))
PY
      timeout 20s sh -c 'uname -a >/dev/null; cat /etc/os-release >/dev/null; systemctl is-system-running >/dev/null 2>&1 || true; journalctl -n 1 --no-pager >/dev/null 2>&1 || true' || prewarm_rc=$?
      echo "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__:$stage_tag:$prewarm_rc"
      return "$prewarm_rc"
    }

    run_python_int_stage() {
      stage_tag="$1"
      stage_log="$probe_log_dir/$stage_tag.log"
      : >"$stage_log"
      stage_rc=0
      run_python_int_stage_prewarm "$stage_tag" >>"$stage_log" 2>&1 || stage_rc=$?
      if [ "$stage_rc" = "0" ]; then
        timeout "$NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT"s python3 "$probe_py" \
          --tag "$stage_tag" --loops "$NEMU_GUEST_PYTHON_INT_LOOPS" \
          >>"$stage_log" 2>&1 || stage_rc=$?
      fi
      echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__:$stage_tag"
      sed -n '1,220p' "$stage_log" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__:$stage_tag"
      echo "__NEMU_PYTHON_INT_STAGE_RC__:$stage_tag:$stage_rc"
      if [ "$stage_tag" = "focused" ]; then
        echo "__NEMU_PYTHON_INT_FOCUSED_RC__:$stage_rc"
      fi
      return "$stage_rc"
    }

    stage_ok=1
    stage_count=0
    for stage_tag in $NEMU_GUEST_PYTHON_INT_TAGS; do
      stage_count=$((stage_count + 1))
      if run_python_int_stage "$stage_tag"; then
        pass "python-int-preflight-focused-stage-$stage_tag"
      else
        stage_ok=0
        fail "python-int-preflight-focused-stage-$stage_tag"
      fi
    done
    echo "__NEMU_PYTHON_INT_STAGE_COUNT__:$stage_count"
    if [ "$stage_ok" = "1" ]; then
      echo "__NEMU_PYTHON_INT_FOCUSED_RC__:0"
      pass python-int-preflight-focused-loop
    else
      echo "__NEMU_PYTHON_INT_FOCUSED_RC__:1"
      fail python-int-preflight-focused-loop
    fi
  fi
fi
if [ "$check_fail" = "0" ]; then
  echo "__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0"
else
  echo "__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=1"
fi
sync
if [ "$NEMU_GUEST_POWEROFF" != "0" ]; then
  echo "__NEMU_PYTHON_INT_POWEROFF_BEGIN__"
  systemctl poweroff 2>/dev/null || poweroff -f 2>/dev/null || true
fi
GUEST_CMDS_TAIL
} >"$GUEST_CMDS"

echo "[nemu-python-int] log dir: $LOG_DIR"
echo "[nemu-python-int] serial fifo: $SERIAL_FIFO"
echo "[nemu-python-int] guest commands: $GUEST_CMDS"
echo "[nemu-python-int] max cycles: $MAX_CYCLES"
echo "[nemu-python-int] loops: $LOOPS"
echo "[nemu-python-int] stage mode: $STAGE_MODE"
echo "[nemu-python-int] stage tags: $stage_tags_csv"
echo "[nemu-python-int] stage prewarm: $stage_prewarm_effective"
echo "[nemu-python-int] stage timeout: $STAGE_TIMEOUT"
echo "[nemu-python-int] poweroff: $POWEROFF_ENABLE"
echo "[nemu-python-int] input chunk bytes: $INPUT_CHUNK_BYTES"
echo "[nemu-python-int] probe bytes: $probe_bytes"
echo "[nemu-python-int] probe sha256: $probe_sha"
echo "[nemu-python-int] rootfs: $RUN_ROOTFS"
echo "[nemu-python-int] overlay: ${RUN_ROOTFS_OVERLAY:-disabled}"
echo "[nemu-python-int] runtime wide_ifetch: ${NEMU_INTERPRETER_WIDE_IFETCH:-1}"
echo "[nemu-python-int] runtime decode_cache: ${NEMU_INTERPRETER_DECODE_CACHE:-1}"
echo "[nemu-python-int] runtime vaddr_host_fast: ${NEMU_VADDR_HOST_FAST:-1}"
echo "[nemu-python-int] runtime mmu_tlb: ${NEMU_RISCV_MMU_TLB:-1}"
{
  printf 'key\tvalue\n'
  printf 'status\tstarted\n'
  printf 'max_cycles\t%s\n' "$MAX_CYCLES"
  printf 'loops\t%s\n' "$LOOPS"
  printf 'stage_mode\t%s\n' "$STAGE_MODE"
  printf 'stage_tags\t%s\n' "$stage_tags_csv"
  printf 'stage_count\t%s\n' "${#stage_tags[@]}"
  printf 'stage_prewarm\t%s\n' "$stage_prewarm_effective"
  printf 'stage_timeout\t%s\n' "$STAGE_TIMEOUT"
  printf 'poweroff\t%s\n' "$POWEROFF_ENABLE"
  printf 'input_chunk_bytes\t%s\n' "$INPUT_CHUNK_BYTES"
  printf 'probe_bytes\t%s\n' "$probe_bytes"
  printf 'probe_sha256\t%s\n' "$probe_sha"
  printf 'runtime.wide_ifetch\t%s\n' "${NEMU_INTERPRETER_WIDE_IFETCH:-1}"
  printf 'runtime.decode_cache\t%s\n' "${NEMU_INTERPRETER_DECODE_CACHE:-1}"
  printf 'runtime.vaddr_host_fast\t%s\n' "${NEMU_VADDR_HOST_FAST:-1}"
  printf 'runtime.mmu_tlb\t%s\n' "${NEMU_RISCV_MMU_TLB:-1}"
} >"$SUMMARY_FILE"
SUMMARY_INITIALIZED=1

host_start_seconds=$SECONDS
NEMU_SERIAL_FIFO="$SERIAL_FIFO" \
NEMU_SERIAL_INPUT_STDIN="${NEMU_SERIAL_INPUT_STDIN:-0}" \
NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b \
  --max-insts="$MAX_CYCLES" \
  --log="$LOG_FILE" \
  --boot-hartid=0 \
  --boot-dtb="$DTB_ADDR" \
  -i "$RUN_FW" \
  --load="$NEXT_ADDR:$LINUX_IMAGE" \
  --load="$DTB_ADDR:$RUN_DTB" \
  --block="$RUN_ROOTFS" \
  "${block_overlay_args[@]}" \
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
boot_seconds=$((SECONDS - host_start_seconds))
send_guest_commands "$INPUT_DELAY" "$INPUT_CHUNK_DELAY" "$GUEST_CMDS"
wait_for_log_regex "^__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=" "$CHECK_TIMEOUT"

done_line="$(grep -aE '^__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=' "$CONSOLE_LOG" |
  tr -d '\r' | tail -1)"
echo "[nemu-python-int] done: $done_line"
case "$done_line" in
  "__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0") ;;
  *) fail "PyLong preflight focused gate failed: $done_line" ;;
esac

if [ "$POWEROFF_ENABLE" != "0" ]; then
  wait_for_log "__NEMU_PYTHON_INT_POWEROFF_BEGIN__" "$POWEROFF_TIMEOUT"
  set +e
  wait_for_nemu_exit "$POWEROFF_TIMEOUT"
  nemu_rc=$?
  set -e
  if [ "$nemu_rc" -ne 0 ]; then
    fail "NEMU poweroff exited with rc=$nemu_rc"
  fi
  if grep -qaF "HIT GOOD TRAP" "$CONSOLE_LOG"; then
    echo "[nemu-python-int] poweroff_good_trap=1"
  else
    echo "[nemu-python-int] poweroff_good_trap=0"
  fi
else
  echo "[nemu-python-int] poweroff skipped; focused gate will stop NEMU from host"
fi

total_seconds=$((SECONDS - host_start_seconds))
append_summary_result "pass"
echo "[nemu-python-int] boot_seconds=$boot_seconds total_seconds=$total_seconds"
echo "[nemu-python-int] PASS"
