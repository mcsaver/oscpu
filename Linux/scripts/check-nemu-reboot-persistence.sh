#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)

NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
NEMU_REBOOT_LOOP=${NEMU_REBOOT_LOOP:-"$SCRIPT_DIR/run-nemu-reboot-loop.sh"}
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
NEMU_PLATFORM_ROOT=${NEMU_PLATFORM_ROOT:-"$ENV_ROOT/platforms/nemu"}

LINUX_IMAGE=${LINUX_IMAGE:-"$NEMU_PLATFORM_ROOT/build/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$NEMU_PLATFORM_ROOT/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/riscv64-nemu/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$NEMU_PLATFORM_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}

LOG_DIR=${NEMU_REBOOT_PERSIST_LOG_DIR:-"$NEMU_PLATFORM_ROOT/logs/linux-front/riscv64-nemu-reboot-persistence-check"}
CONSOLE_LOG=${NEMU_REBOOT_PERSIST_CONSOLE_LOG:-"$LOG_DIR/console.log"}
NEMU_LOG=${NEMU_REBOOT_PERSIST_NEMU_LOG:-"$LOG_DIR/nemu.log"}
SERIAL_FIFO=${NEMU_REBOOT_PERSIST_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}
ROOTFS_OVERLAY=${NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY:-"$LOG_DIR/rootfs-overlay.raw"}
ROOTFS_OVERLAY_META=${ROOTFS_OVERLAY}.meta
ROOTFS_OVERLAY_META_TMP=${ROOTFS_OVERLAY}.meta.tmp
ROOTFS_OVERLAY_LOCK=${ROOTFS_OVERLAY}.lock
BACKING_PRE_STAT_FILE=${NEMU_REBOOT_PERSIST_BACKING_PRE_STAT:-"$LOG_DIR/backing.pre.stat"}
BACKING_POST_STAT_FILE=${NEMU_REBOOT_PERSIST_BACKING_POST_STAT:-"$LOG_DIR/backing.post.stat"}
BACKING_PRE_SHA_FILE=${NEMU_REBOOT_PERSIST_BACKING_PRE_SHA256:-"$LOG_DIR/backing.pre.sha256"}
BACKING_POST_SHA_FILE=${NEMU_REBOOT_PERSIST_BACKING_POST_SHA256:-"$LOG_DIR/backing.post.sha256"}
OVERLAY_FINAL_STAT_FILE=${NEMU_REBOOT_PERSIST_OVERLAY_FINAL_STAT:-"$LOG_DIR/overlay.final.stat"}

HOST_TIMEOUT=${NEMU_REBOOT_PERSIST_TIMEOUT:-2400}
BOOT_TIMEOUT=${NEMU_REBOOT_PERSIST_BOOT_TIMEOUT:-900}
POWEROFF_TIMEOUT=${NEMU_REBOOT_PERSIST_POWEROFF_TIMEOUT:-300}
FIFO_TIMEOUT=${NEMU_REBOOT_PERSIST_FIFO_TIMEOUT:-60}
POLL_INTERVAL=${NEMU_REBOOT_PERSIST_POLL_INTERVAL:-1}
TIMEOUT_KILL_AFTER=${NEMU_REBOOT_PERSIST_KILL_AFTER:-15}
MAX_INSTS=${NEMU_REBOOT_PERSIST_MAX_INSTS:-${MAX_INSTS:-50000000000}}
REBOOT_EXIT_CODE=${NEMU_REBOOT_EXIT_CODE:-32}
INPUT_CHUNK_BYTES=${NEMU_REBOOT_PERSIST_INPUT_CHUNK_BYTES:-8}
INPUT_CHUNK_DELAY=${NEMU_REBOOT_PERSIST_INPUT_CHUNK_DELAY:-0.002}
INPUT_LINE_DELAY=${NEMU_REBOOT_PERSIST_INPUT_LINE_DELAY:-0.05}

readonly GUEST_MARKER_PATH=/root/.nemu-reboot-persistence-v1
readonly GUEST_MARKER_VALUE=nemu-reboot-persistence-v1
readonly CHANNEL_READY_BOOT1=__NEMU_REBOOT_PERSIST_CHANNEL_READY__:boot1
readonly CHANNEL_READY_BOOT2=__NEMU_REBOOT_PERSIST_CHANNEL_READY__:boot2
readonly BOOT1_ABSENT=__NEMU_REBOOT_PERSIST_BOOT1_MARKER_ABSENT__
readonly BOOT1_WRITTEN=__NEMU_REBOOT_PERSIST_BOOT1_WRITTEN__:nemu-reboot-persistence-v1
readonly REBOOT_BEGIN=__NEMU_REBOOT_PERSIST_REBOOT_BEGIN__
readonly READBACK_PASS=__NEMU_REBOOT_PERSIST_PASS__:nemu-reboot-persistence-v1
readonly POWEROFF_BEGIN=__NEMU_REBOOT_PERSIST_POWEROFF_BEGIN__
readonly GUEST_FAIL_PREFIX=__NEMU_REBOOT_PERSIST_FAIL__:

runner_pid=
runner_pgid=
runner_rc=
writer_pid=
host_deadline=0
serial_fifo_identity=
console_log_initialized=0

cleanup() {
  local status=$?
  local shell_pgid
  trap - EXIT HUP INT TERM

  if [[ -n ${writer_pid:-} ]]; then
    kill "$writer_pid" 2>/dev/null || true
    wait "$writer_pid" 2>/dev/null || true
    writer_pid=
  fi

  if [[ -n ${runner_pid:-} ]]; then
    shell_pgid=$(ps -o pgid= -p $$ 2>/dev/null | tr -d '[:space:]' || true)
    if [[ ${runner_pgid:-} =~ ^[0-9]+$ ]] &&
       [[ -n $shell_pgid ]] && [[ $runner_pgid != "$shell_pgid" ]]; then
      kill -TERM -- "-$runner_pgid" 2>/dev/null || true
    else
      kill -TERM "$runner_pid" 2>/dev/null || true
    fi

    local i
    for ((i = 0; i < 25; i++)); do
      kill -0 "$runner_pid" 2>/dev/null || break
      sleep 0.2
    done
    if kill -0 "$runner_pid" 2>/dev/null; then
      if [[ ${runner_pgid:-} =~ ^[0-9]+$ ]] &&
         [[ -n $shell_pgid ]] && [[ $runner_pgid != "$shell_pgid" ]]; then
        kill -KILL -- "-$runner_pgid" 2>/dev/null || true
      else
        kill -KILL "$runner_pid" 2>/dev/null || true
      fi
    fi
    wait "$runner_pid" 2>/dev/null || true
    runner_pid=
    runner_pgid=
  fi

  if [[ -n ${serial_fifo_identity:-} && -p $SERIAL_FIFO ]]; then
    local current_fifo_identity
    current_fifo_identity=$(stat -c '%d:%i' -- "$SERIAL_FIFO" 2>/dev/null || true)
    if [[ $current_fifo_identity == "$serial_fifo_identity" ]]; then
      rm -f -- "$SERIAL_FIFO"
    fi
  fi
  exit "$status"
}

fail() {
  printf '[nemu-reboot-persistence-check] FAIL: %s\n' "$*" >&2
  if (( console_log_initialized == 1 )) && [[ -s $CONSOLE_LOG ]]; then
    printf '%s\n' '[nemu-reboot-persistence-check] ---- console tail ----' >&2
    tail -n 160 "$CONSOLE_LOG" >&2 || true
    printf '%s\n' '[nemu-reboot-persistence-check] ----------------------' >&2
  fi
  exit 1
}

require_file() {
  local path=$1
  local label=$2
  [[ -f $path ]] || fail "missing $label: $path"
}

require_executable() {
  local path=$1
  local label=$2
  [[ -x $path ]] || fail "missing executable $label: $path"
}

require_uint() {
  local name=$1
  local value=$2
  [[ $value =~ ^[0-9]+$ ]] || fail "$name must be a non-negative integer: $value"
}

require_positive_uint() {
  local name=$1
  local value=$2
  require_uint "$name" "$value"
  (( value > 0 )) || fail "$name must be positive: $value"
}

require_nonnegative_decimal() {
  local name=$1
  local value=$2
  [[ $value =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] ||
    fail "$name must be a non-negative decimal: $value"
}

guard_artifact_paths() {
  local -a readonly_paths=(
    "$BASH_SOURCE"
    "$NEMU_REBOOT_LOOP"
    "$NEMU_SIM"
    "$LINUX_IMAGE"
    "$RUN_FW"
    "$RUN_DTB"
    "$RUN_ROOTFS"
  )
  local -a writable_paths=(
    "$CONSOLE_LOG"
    "$NEMU_LOG"
    "$SERIAL_FIFO"
    "$ROOTFS_OVERLAY"
    "$ROOTFS_OVERLAY_META"
    "$ROOTFS_OVERLAY_META_TMP"
    "$ROOTFS_OVERLAY_LOCK"
    "$BACKING_PRE_STAT_FILE"
    "$BACKING_POST_STAT_FILE"
    "$BACKING_PRE_SHA_FILE"
    "$BACKING_POST_SHA_FILE"
    "$OVERLAY_FINAL_STAT_FILE"
  )
  local -a readonly_real=()
  local -a writable_real=()
  local path resolved other i j

  for path in "${readonly_paths[@]}"; do
    resolved=$(realpath -e -- "$path") || fail "cannot resolve required input: $path"
    readonly_real+=("$resolved")
  done

  for ((i = 0; i < ${#writable_paths[@]}; i++)); do
    path=${writable_paths[i]}
    [[ -n $path ]] || fail "writable artifact path is empty"
    resolved=$(realpath -m -- "$path") || fail "cannot resolve writable artifact: $path"
    case $resolved in
      /|'') fail "unsafe writable artifact path: $resolved" ;;
    esac
    if [[ -e $path || -L $path ]]; then
      [[ ! -d $path ]] || fail "writable artifact is a directory: $path"
      if [[ ! -f $path && ! -p $path && ! -L $path ]]; then
        fail "writable artifact has unsafe existing file type: $path"
      fi
    fi
    for ((j = 0; j < ${#readonly_paths[@]}; j++)); do
      other=${readonly_paths[j]}
      if [[ $resolved == "${readonly_real[j]}" ]] ||
         { [[ -e $path || -L $path ]] && [[ $path -ef $other ]]; }; then
        fail "writable artifact aliases required input: $path -> ${readonly_real[j]}"
      fi
    done
    for ((j = 0; j < ${#writable_real[@]}; j++)); do
      other=${writable_paths[j]}
      if [[ $resolved == "${writable_real[j]}" ]] ||
         { [[ -e $path || -L $path ]] && [[ -e $other || -L $other ]] &&
           [[ $path -ef $other ]]; }; then
        fail "writable artifacts alias each other: $path and $other"
      fi
    done
    writable_real+=("$resolved")
  done
}

remaining_seconds() {
  local remaining=$((host_deadline - SECONDS))
  (( remaining > 0 )) || fail "total host timeout expired (${HOST_TIMEOUT}s)"
  printf '%s\n' "$remaining"
}

hash_file_bounded() {
  local path=$1
  local remaining output
  remaining=$(remaining_seconds)
  if ! output=$(timeout --signal=TERM --kill-after=5s "${remaining}s" sha256sum -- "$path"); then
    fail "failed or timed out hashing backing image: $path"
  fi
  output=${output%% *}
  [[ $output =~ ^[[:xdigit:]]{64}$ ]] || fail "invalid SHA-256 output for $path"
  printf '%s\n' "$output"
}

fixed_count() {
  local marker=$1
  awk -v marker="$marker" 'index($0, marker) { count++ } END { print count + 0 }' \
    "$CONSOLE_LOG" 2>/dev/null
}

fixed_occurrence_line() {
  local marker=$1
  local occurrence=$2
  awk -v marker="$marker" -v occurrence="$occurrence" '
    index($0, marker) {
      count++
      if (count == occurrence) {
        print NR
        exit
      }
    }
  ' "$CONSOLE_LOG" 2>/dev/null
}

reap_runner() {
  if [[ -z ${runner_pid:-} ]]; then
    return 0
  fi
  if wait "$runner_pid"; then
    runner_rc=0
  else
    runner_rc=$?
  fi
  runner_pid=
  runner_pgid=
  return 0
}

check_guest_failure_marker() {
  if (( $(fixed_count "$GUEST_FAIL_PREFIX") > 0 )); then
    grep -aF "$GUEST_FAIL_PREFIX" "$CONSOLE_LOG" | tail -n 20 >&2 || true
    fail "guest reported a reboot-persistence failure"
  fi
}

wait_for_fixed_count() {
  local marker=$1
  local wanted=$2
  local timeout_seconds=$3
  local label=$4
  local deadline=$((SECONDS + timeout_seconds))
  local count

  while (( SECONDS < deadline && SECONDS < host_deadline )); do
    count=$(fixed_count "$marker")
    if (( count >= wanted )); then
      return 0
    fi
    check_guest_failure_marker
    if [[ -z ${runner_pid:-} ]] || ! kill -0 "$runner_pid" 2>/dev/null; then
      reap_runner
      fail "runner exited with rc=${runner_rc:-unknown} before $label"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for $label: marker=$marker wanted=$wanted"
}

wait_for_fifo() {
  local deadline=$((SECONDS + FIFO_TIMEOUT))
  while (( SECONDS < deadline && SECONDS < host_deadline )); do
    if [[ -p $SERIAL_FIFO ]]; then
      serial_fifo_identity=$(stat -c '%d:%i' -- "$SERIAL_FIFO") || continue
      return 0
    fi
    if [[ -z ${runner_pid:-} ]] || ! kill -0 "$runner_pid" 2>/dev/null; then
      reap_runner
      fail "runner exited with rc=${runner_rc:-unknown} before serial FIFO appeared"
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for serial FIFO: $SERIAL_FIFO"
}

send_guest_lines() {
  local line text len pos
  (
    exec 3>"$SERIAL_FIFO"
    for line in "$@"; do
      text=${line}$'\n'
      len=${#text}
      pos=0
      while (( pos < len )); do
        printf '%s' "${text:pos:INPUT_CHUNK_BYTES}" >&3
        pos=$((pos + INPUT_CHUNK_BYTES))
        [[ $INPUT_CHUNK_DELAY == 0 ]] || sleep "$INPUT_CHUNK_DELAY"
      done
      [[ $INPUT_LINE_DELAY == 0 ]] || sleep "$INPUT_LINE_DELAY"
    done
    exec 3>&-
  ) &
  writer_pid=$!

  local deadline=$((SECONDS + FIFO_TIMEOUT))
  while kill -0 "$writer_pid" 2>/dev/null; do
    if (( SECONDS >= deadline || SECONDS >= host_deadline )); then
      kill "$writer_pid" 2>/dev/null || true
      wait "$writer_pid" 2>/dev/null || true
      writer_pid=
      fail "timeout writing guest commands to serial FIFO"
    fi
    if [[ -z ${runner_pid:-} ]] || ! kill -0 "$runner_pid" 2>/dev/null; then
      kill "$writer_pid" 2>/dev/null || true
      wait "$writer_pid" 2>/dev/null || true
      writer_pid=
      reap_runner
      fail "runner exited with rc=${runner_rc:-unknown} while writing guest commands"
    fi
    sleep 0.1
  done

  local write_rc
  if wait "$writer_pid"; then
    write_rc=0
  else
    write_rc=$?
  fi
  writer_pid=
  (( write_rc == 0 )) || fail "serial FIFO writer failed with rc=$write_rc"
}

wait_for_runner_exit() {
  local timeout_seconds=$1
  local deadline=$((SECONDS + timeout_seconds))
  while (( SECONDS < deadline && SECONDS < host_deadline )); do
    if [[ -z ${runner_pid:-} ]] || ! kill -0 "$runner_pid" 2>/dev/null; then
      reap_runner
      return 0
    fi
    sleep "$POLL_INTERVAL"
  done
  fail "timeout waiting for final NEMU poweroff"
}

require_count_equal() {
  local label=$1
  local marker=$2
  local expected=$3
  local actual
  actual=$(fixed_count "$marker")
  (( actual == expected )) ||
    fail "$label count mismatch: expected=$expected actual=$actual marker=$marker"
  printf '[nemu-reboot-persistence-check] PASS %s count=%d\n' "$label" "$actual"
}

require_count_at_least() {
  local label=$1
  local marker=$2
  local expected=$3
  local actual
  actual=$(fixed_count "$marker")
  (( actual >= expected )) ||
    fail "$label count too small: expected-at-least=$expected actual=$actual marker=$marker"
  printf '[nemu-reboot-persistence-check] PASS %s count=%d\n' "$label" "$actual"
}

read_le_uint() {
  local path=$1
  local offset=$2
  local width=$3
  local bytes
  local -a octets
  local value=0
  local i

  bytes=$(od -An -v -tx1 -j "$offset" -N "$width" "$path") ||
    fail "failed reading little-endian field offset=$offset width=$width from $path"
  read -r -a octets <<<"$bytes"
  (( ${#octets[@]} == width )) ||
    fail "short little-endian field offset=$offset width=$width in $path"
  for ((i = width - 1; i >= 0; i--)); do
    value=$(( (value << 8) + 16#${octets[i]} ))
  done
  printf '%s\n' "$value"
}

require_file "$NEMU_REBOOT_LOOP" "NEMU reboot-loop wrapper"
require_executable "$NEMU_SIM" "NEMU"
require_file "$LINUX_IMAGE" "Linux Image"
require_file "$RUN_FW" "OpenSBI firmware"
require_file "$RUN_DTB" "rootfs DTB"
require_file "$RUN_ROOTFS" "Ubuntu rootfs backing image"
require_file "$SCRIPT_DIR/prepare-nemu-overlay.sh" "NEMU overlay preparation helper"
command -v awk >/dev/null 2>&1 || fail "missing host awk"
command -v od >/dev/null 2>&1 || fail "missing host od"
command -v realpath >/dev/null 2>&1 || fail "missing host realpath"
command -v setsid >/dev/null 2>&1 || fail "missing host setsid"
command -v sha256sum >/dev/null 2>&1 || fail "missing host sha256sum"
command -v stat >/dev/null 2>&1 || fail "missing host stat"
command -v timeout >/dev/null 2>&1 || fail "missing host timeout"

require_positive_uint "NEMU_REBOOT_PERSIST_TIMEOUT" "$HOST_TIMEOUT"
require_positive_uint "NEMU_REBOOT_PERSIST_BOOT_TIMEOUT" "$BOOT_TIMEOUT"
require_positive_uint "NEMU_REBOOT_PERSIST_POWEROFF_TIMEOUT" "$POWEROFF_TIMEOUT"
require_positive_uint "NEMU_REBOOT_PERSIST_FIFO_TIMEOUT" "$FIFO_TIMEOUT"
require_positive_uint "NEMU_REBOOT_PERSIST_POLL_INTERVAL" "$POLL_INTERVAL"
require_positive_uint "NEMU_REBOOT_PERSIST_KILL_AFTER" "$TIMEOUT_KILL_AFTER"
require_uint "NEMU_REBOOT_PERSIST_MAX_INSTS" "$MAX_INSTS"
require_positive_uint "NEMU_REBOOT_PERSIST_INPUT_CHUNK_BYTES" "$INPUT_CHUNK_BYTES"
require_nonnegative_decimal "NEMU_REBOOT_PERSIST_INPUT_CHUNK_DELAY" "$INPUT_CHUNK_DELAY"
require_nonnegative_decimal "NEMU_REBOOT_PERSIST_INPUT_LINE_DELAY" "$INPUT_LINE_DELAY"
require_positive_uint "NEMU_REBOOT_EXIT_CODE" "$REBOOT_EXIT_CODE"
(( REBOOT_EXIT_CODE <= 125 )) ||
  fail "NEMU_REBOOT_EXIT_CODE must be in the portable wrapper range [1, 125]: $REBOOT_EXIT_CODE"

# All user-overridable outputs are removed or truncated below. Validate the whole
# write set before installing cleanup traps or touching any path.
guard_artifact_paths

RUN_ROOTFS_REAL=$(realpath -e -- "$RUN_ROOTFS") || fail "cannot resolve backing image: $RUN_ROOTFS"
ROOTFS_OVERLAY_REAL=$(realpath -m -- "$ROOTFS_OVERLAY") || fail "cannot resolve overlay path: $ROOTFS_OVERLAY"
ROOTFS_OVERLAY_META_REAL=$(realpath -m -- "$ROOTFS_OVERLAY_META") || fail "cannot resolve overlay metadata path"
ROOTFS_OVERLAY_META_TMP_REAL=$(realpath -m -- "$ROOTFS_OVERLAY_META_TMP") || fail "cannot resolve temporary overlay metadata path"
ROOTFS_OVERLAY_LOCK_REAL=$(realpath -m -- "$ROOTFS_OVERLAY_LOCK") || fail "cannot resolve stable overlay lock path"
case $ROOTFS_OVERLAY_REAL in
  /|'') fail "unsafe overlay path: $ROOTFS_OVERLAY_REAL" ;;
esac
[[ $ROOTFS_OVERLAY_REAL != "$RUN_ROOTFS_REAL" ]] ||
  fail "overlay path aliases the immutable backing image: $RUN_ROOTFS_REAL"
[[ $ROOTFS_OVERLAY_META_REAL != "$RUN_ROOTFS_REAL" ]] ||
  fail "overlay metadata path aliases the immutable backing image: $RUN_ROOTFS_REAL"
[[ $ROOTFS_OVERLAY_META_TMP_REAL != "$RUN_ROOTFS_REAL" ]] ||
  fail "temporary overlay metadata path aliases the immutable backing image: $RUN_ROOTFS_REAL"
[[ $ROOTFS_OVERLAY_LOCK_REAL != "$RUN_ROOTFS_REAL" ]] ||
  fail "overlay lock path aliases the immutable backing image: $RUN_ROOTFS_REAL"
for path in \
    "$ROOTFS_OVERLAY" "$ROOTFS_OVERLAY_META" "$ROOTFS_OVERLAY_META_TMP" \
    "$ROOTFS_OVERLAY_LOCK"; do
  [[ ! -d $path ]] || fail "overlay artifact path is a directory: $path"
done

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p -- "$LOG_DIR" "$(dirname -- "$ROOTFS_OVERLAY")" \
  "$(dirname -- "$CONSOLE_LOG")" "$(dirname -- "$NEMU_LOG")" \
  "$(dirname -- "$SERIAL_FIFO")"
rm -f -- "$CONSOLE_LOG" "$NEMU_LOG" "$SERIAL_FIFO" \
  "$BACKING_PRE_STAT_FILE" "$BACKING_POST_STAT_FILE" \
  "$BACKING_PRE_SHA_FILE" "$BACKING_POST_SHA_FILE" "$OVERLAY_FINAL_STAT_FILE"
# This gate owns a dedicated overlay.  Reset it exactly once before boot 1; the
# EXIT cleanup intentionally keeps the final raw image and v1 sidecar for review.
bash "$SCRIPT_DIR/prepare-nemu-overlay.sh" \
  --backing="$RUN_ROOTFS" --overlay="$ROOTFS_OVERLAY" --reset=1
: >"$CONSOLE_LOG"
console_log_initialized=1

host_deadline=$((SECONDS + HOST_TIMEOUT))
backing_stat_before=$(stat -Lc '%d:%i:%f:%u:%g:%h:%s:%b:%Y:%Z' "$RUN_ROOTFS") ||
  fail "failed to stat backing image before run"
backing_sha_before=$(hash_file_bounded "$RUN_ROOTFS")
printf '%s\n' "$backing_stat_before" >"$BACKING_PRE_STAT_FILE"
printf '%s  %s\n' "$backing_sha_before" "$RUN_ROOTFS_REAL" >"$BACKING_PRE_SHA_FILE"

printf '[nemu-reboot-persistence-check] log dir: %s\n' "$LOG_DIR"
printf '[nemu-reboot-persistence-check] console log: %s\n' "$CONSOLE_LOG"
printf '[nemu-reboot-persistence-check] serial FIFO: %s\n' "$SERIAL_FIFO"
printf '[nemu-reboot-persistence-check] backing image: %s\n' "$RUN_ROOTFS_REAL"
printf '[nemu-reboot-persistence-check] backing pre stat: %s\n' "$backing_stat_before"
printf '[nemu-reboot-persistence-check] backing pre sha256: %s\n' "$backing_sha_before"
printf '[nemu-reboot-persistence-check] persistent overlay: %s\n' "$ROOTFS_OVERLAY_REAL"
printf '[nemu-reboot-persistence-check] persistent sidecar: %s\n' "$ROOTFS_OVERLAY_META_REAL"
printf '[nemu-reboot-persistence-check] max insts per boot: %s\n' "$MAX_INSTS"
printf '[nemu-reboot-persistence-check] total host timeout: %ss\n' "$HOST_TIMEOUT"

nemu_command=(
  env
  "NEMU_HOME=$NEMU_HOME"
  "NEMU_SERIAL_FIFO=$SERIAL_FIFO"
  NEMU_SERIAL_INPUT_STDIN=0
  "$NEMU_SIM"
  -b
  "--max-insts=$MAX_INSTS"
  "--log=$NEMU_LOG"
  --boot-hartid=0
  "--boot-dtb=$DTB_ADDR"
  -i "$RUN_FW"
  "--load=$NEXT_ADDR:$LINUX_IMAGE"
  "--load=$DTB_ADDR:$RUN_DTB"
  "--block=$RUN_ROOTFS"
  "--block-overlay=$ROOTFS_OVERLAY"
)

remaining=$(remaining_seconds)
setsid timeout --foreground --signal=TERM --kill-after="${TIMEOUT_KILL_AFTER}s" \
  "${remaining}s" bash "$NEMU_REBOOT_LOOP" \
  --reboot-exit-code "$REBOOT_EXIT_CODE" --max-boots 2 -- \
  "${nemu_command[@]}" >"$CONSOLE_LOG" 2>&1 </dev/null &
runner_pid=$!
runner_pgid=$(ps -o pgid= -p "$runner_pid" 2>/dev/null | tr -d '[:space:]' || true)

wait_for_fifo
wait_for_fixed_count 'OpenSBI v' 1 "$BOOT_TIMEOUT" "boot 1 OpenSBI"
wait_for_fixed_count 'Linux version' 1 "$BOOT_TIMEOUT" "boot 1 Linux"
wait_for_fixed_count '__NEMU_LOGIN_CHECK_DONE__ rc=0' 1 "$BOOT_TIMEOUT" "boot 1 ttyS0 root login"

send_guest_lines \
  '' \
  'stty -echo -ixon -ixoff 2>/dev/null || true' \
  "persist_file=$GUEST_MARKER_PATH; persist_value=$GUEST_MARKER_VALUE" \
  'marker_prefix=__NEMU_REBOOT_' \
  'printf "%s\n" "${marker_prefix}PERSIST_CHANNEL_READY__:boot1"'
wait_for_fixed_count "$CHANNEL_READY_BOOT1" 1 "$FIFO_TIMEOUT" "boot 1 command channel"

send_guest_lines \
  'if [ -e "$persist_file" ]; then printf "%s\n" "${marker_prefix}PERSIST_FAIL__:boot1-marker-present"; else printf "%s\n" "${marker_prefix}PERSIST_BOOT1_MARKER_ABSENT__"; fi'
wait_for_fixed_count "$BOOT1_ABSENT" 1 "$FIFO_TIMEOUT" "boot 1 marker-absence proof"

send_guest_lines \
  'if printf "%s\n" "$persist_value" >"$persist_file" && sync && [ "$(cat "$persist_file" 2>/dev/null)" = "$persist_value" ]; then printf "%s\n" "${marker_prefix}PERSIST_BOOT1_WRITTEN__:nemu-reboot-persistence-v1"; else printf "%s\n" "${marker_prefix}PERSIST_FAIL__:boot1-write-or-readback"; fi'
wait_for_fixed_count "$BOOT1_WRITTEN" 1 "$FIFO_TIMEOUT" "boot 1 synced marker write"

send_guest_lines \
  'printf "%s\n" "${marker_prefix}PERSIST_REBOOT_BEGIN__"; if ! systemctl --no-wall reboot; then printf "%s\n" "${marker_prefix}PERSIST_FAIL__:systemctl-reboot"; fi'
wait_for_fixed_count "$REBOOT_BEGIN" 1 "$FIFO_TIMEOUT" "guest reboot request"
wait_for_fixed_count '[nemu-reboot-loop] reboot 1/1' 1 "$POWEROFF_TIMEOUT" "wrapper reboot transition"

wait_for_fixed_count 'OpenSBI v' 2 "$BOOT_TIMEOUT" "boot 2 OpenSBI"
wait_for_fixed_count 'Linux version' 2 "$BOOT_TIMEOUT" "boot 2 Linux"
wait_for_fixed_count '__NEMU_LOGIN_CHECK_DONE__ rc=0' 2 "$BOOT_TIMEOUT" "boot 2 ttyS0 root login"

send_guest_lines \
  '' \
  'stty -echo -ixon -ixoff 2>/dev/null || true' \
  "persist_file=$GUEST_MARKER_PATH; persist_value=$GUEST_MARKER_VALUE" \
  'marker_prefix=__NEMU_REBOOT_' \
  'printf "%s\n" "${marker_prefix}PERSIST_CHANNEL_READY__:boot2"'
wait_for_fixed_count "$CHANNEL_READY_BOOT2" 1 "$FIFO_TIMEOUT" "boot 2 command channel"

send_guest_lines \
  'persist_actual=$(cat "$persist_file" 2>/dev/null || true); printf "${marker_prefix}PERSIST_READBACK__:%s\n" "$persist_actual"; if [ "$persist_actual" = "$persist_value" ]; then printf "${marker_prefix}PERSIST_PASS__:%s\n" "$persist_actual"; else printf "%s\n" "${marker_prefix}PERSIST_FAIL__:boot2-readback"; fi'
wait_for_fixed_count "$READBACK_PASS" 1 "$FIFO_TIMEOUT" "boot 2 persistent marker readback"

send_guest_lines \
  'printf "%s\n" "${marker_prefix}PERSIST_POWEROFF_BEGIN__"; sync; if ! systemctl --no-wall poweroff; then printf "%s\n" "${marker_prefix}PERSIST_FAIL__:systemctl-poweroff"; fi'
wait_for_fixed_count "$POWEROFF_BEGIN" 1 "$FIFO_TIMEOUT" "guest poweroff request"
wait_for_runner_exit "$POWEROFF_TIMEOUT"
(( runner_rc == 0 )) || fail "reboot-loop runner exited with rc=$runner_rc instead of final poweroff rc=0"

check_guest_failure_marker
if grep -qaE '__NEMU_LOGIN_CHECK_DONE__ rc=[1-9][0-9]*' "$CONSOLE_LOG"; then
  fail "a ttyS0 automatic-login self-check reported non-zero rc"
fi
if grep -qaiE 'HIT BAD TRAP|Kernel panic|I/O error|EXT4-fs error|sbi_trap_error|load fault handler failed' \
    "$CONSOLE_LOG"; then
  grep -aiE 'HIT BAD TRAP|Kernel panic|I/O error|EXT4-fs error|sbi_trap_error|load fault handler failed' \
    "$CONSOLE_LOG" | tail -n 30 >&2 || true
  fail "console contains a fatal trap, panic, firmware fault, ext4 error, or I/O error"
fi

require_count_equal "wrapper-reboot" '[nemu-reboot-loop] reboot 1/1' 1
require_count_equal "syscon-reboot" 'syscon-reset: reboot requested value=0x00007777' 1
require_count_equal "kernel-reboot" 'reboot: Restarting system' 1
require_count_equal "NEMU-reboot-exit" 'GUEST REBOOT' 1
require_count_at_least "OpenSBI-boots" 'OpenSBI v' 2
require_count_at_least "Linux-boots" 'Linux version' 2
require_count_at_least "ttyS0-root-logins" '__NEMU_LOGIN_CHECK_DONE__ rc=0' 2
require_count_equal "readback-pass" "$READBACK_PASS" 1
require_count_equal "poweroff-begin" "$POWEROFF_BEGIN" 1
require_count_equal "kernel-poweroff" 'reboot: Power down' 1
require_count_equal "syscon-poweroff" 'syscon-reset: poweroff requested value=0x00005555' 1
require_count_equal "final-good-trap" 'HIT GOOD TRAP' 1
require_count_equal "new-overlay-open" 'state=new' 1
require_count_equal "restored-overlay-open" 'state=restored' 1

new_overlay_line=$(awk '/state=new.*dirty_sectors=0/ { print; exit }' "$CONSOLE_LOG")
[[ -n $new_overlay_line ]] || fail "fresh boot did not report state=new dirty_sectors=0"
restored_overlay_line=$(awk '/state=restored.*dirty_sectors=[0-9]+/ { line=$0 } END { print line }' "$CONSOLE_LOG")
[[ -n $restored_overlay_line ]] || fail "boot 2 did not report restored overlay metadata"
restored_dirty_sectors=$(sed -n 's/.*state=restored.*dirty_sectors=\([0-9][0-9]*\).*/\1/p' \
  <<<"$restored_overlay_line")
[[ $restored_dirty_sectors =~ ^[0-9]+$ ]] && (( restored_dirty_sectors > 0 )) ||
  fail "restored overlay dirty-sector count is not positive: ${restored_dirty_sectors:-missing}"

[[ -f $ROOTFS_OVERLAY ]] || fail "persistent raw overlay missing after final poweroff: $ROOTFS_OVERLAY"
[[ -f $ROOTFS_OVERLAY_META ]] || fail "persistent overlay sidecar missing after final poweroff: $ROOTFS_OVERLAY_META"
[[ ! -e $ROOTFS_OVERLAY_META_TMP ]] || fail "temporary overlay sidecar survived clean final poweroff: $ROOTFS_OVERLAY_META_TMP"
backing_size=$(stat -Lc %s "$RUN_ROOTFS")
overlay_size=$(stat -Lc %s "$ROOTFS_OVERLAY")
overlay_blocks=$(stat -Lc %b "$ROOTFS_OVERLAY")
meta_size=$(stat -Lc %s "$ROOTFS_OVERLAY_META")
meta_blocks=$(stat -Lc %b "$ROOTFS_OVERLAY_META")
(( overlay_size == backing_size )) ||
  fail "raw overlay virtual size differs from backing: overlay=$overlay_size backing=$backing_size"
(( overlay_blocks > 0 )) || fail "raw overlay contains no allocated dirty blocks"
(( meta_size >= 128 )) || fail "overlay sidecar is smaller than its v1 header: $meta_size"
(( meta_blocks > 0 )) || fail "overlay sidecar has no allocated blocks"
meta_magic=$(dd if="$ROOTFS_OVERLAY_META" bs=1 count=8 status=none)
[[ $meta_magic == NEMUOVL1 ]] || fail "overlay sidecar has invalid v1 magic: $meta_magic"
meta_dirty_sectors=$(read_le_uint "$ROOTFS_OVERLAY_META" 48 8)
(( meta_dirty_sectors > 0 )) || fail "final overlay sidecar records zero dirty sectors"

backing_stat_after=$(stat -Lc '%d:%i:%f:%u:%g:%h:%s:%b:%Y:%Z' "$RUN_ROOTFS") ||
  fail "failed to stat backing image after run"
backing_sha_after=$(hash_file_bounded "$RUN_ROOTFS")
printf '%s\n' "$backing_stat_after" >"$BACKING_POST_STAT_FILE"
printf '%s  %s\n' "$backing_sha_after" "$RUN_ROOTFS_REAL" >"$BACKING_POST_SHA_FILE"
printf 'raw_size=%s raw_blocks=%s meta_size=%s meta_blocks=%s restored_dirty_sectors=%s final_meta_dirty_sectors=%s\n' \
  "$overlay_size" "$overlay_blocks" "$meta_size" "$meta_blocks" \
  "$restored_dirty_sectors" "$meta_dirty_sectors" >"$OVERLAY_FINAL_STAT_FILE"
[[ $backing_stat_after == "$backing_stat_before" ]] ||
  fail "backing image stat changed: $backing_stat_before -> $backing_stat_after"
[[ $backing_sha_after == "$backing_sha_before" ]] ||
  fail "backing image content changed: $backing_sha_before -> $backing_sha_after"

line_absent=$(fixed_occurrence_line "$BOOT1_ABSENT" 1)
line_written=$(fixed_occurrence_line "$BOOT1_WRITTEN" 1)
line_reboot_begin=$(fixed_occurrence_line "$REBOOT_BEGIN" 1)
line_kernel_reboot=$(fixed_occurrence_line 'reboot: Restarting system' 1)
line_syscon_reboot=$(fixed_occurrence_line 'syscon-reset: reboot requested value=0x00007777' 1)
line_wrapper_reboot=$(fixed_occurrence_line '[nemu-reboot-loop] reboot 1/1' 1)
line_linux_boot2=$(fixed_occurrence_line 'Linux version' 2)
line_login_boot2=$(fixed_occurrence_line '__NEMU_LOGIN_CHECK_DONE__ rc=0' 2)
line_readback=$(fixed_occurrence_line "$READBACK_PASS" 1)
line_poweroff_begin=$(fixed_occurrence_line "$POWEROFF_BEGIN" 1)
line_kernel_poweroff=$(fixed_occurrence_line 'reboot: Power down' 1)
line_syscon_poweroff=$(fixed_occurrence_line 'syscon-reset: poweroff requested value=0x00005555' 1)
line_good_trap=$(fixed_occurrence_line 'HIT GOOD TRAP' 1)
for line in "$line_absent" "$line_written" "$line_reboot_begin" "$line_kernel_reboot" \
  "$line_syscon_reboot" "$line_wrapper_reboot" "$line_linux_boot2" "$line_login_boot2" \
  "$line_readback" "$line_poweroff_begin" "$line_kernel_poweroff" \
  "$line_syscon_poweroff" "$line_good_trap"; do
  [[ $line =~ ^[0-9]+$ ]] || fail "missing line-number evidence for reboot/persistence ordering"
done
if ! (( line_absent < line_written &&
        line_written < line_reboot_begin &&
        line_reboot_begin < line_kernel_reboot &&
        line_kernel_reboot < line_syscon_reboot &&
        line_syscon_reboot < line_wrapper_reboot &&
        line_wrapper_reboot < line_linux_boot2 &&
        line_linux_boot2 < line_login_boot2 &&
        line_login_boot2 < line_readback &&
        line_readback < line_poweroff_begin &&
        line_poweroff_begin < line_kernel_poweroff &&
        line_kernel_poweroff < line_syscon_poweroff &&
        line_syscon_poweroff < line_good_trap )); then
  fail "reboot/persistence/poweroff evidence is out of order"
fi

printf '[nemu-reboot-persistence-check] PASS backing-unchanged stat=%s sha256=%s\n' \
  "$backing_stat_after" "$backing_sha_after"
printf '[nemu-reboot-persistence-check] PASS overlay-restored restored_dirty_sectors=%s final_meta_dirty_sectors=%s raw_blocks=%s meta_blocks=%s\n' \
  "$restored_dirty_sectors" "$meta_dirty_sectors" "$overlay_blocks" "$meta_blocks"
printf '[nemu-reboot-persistence-check] PASS reboot -> persistent readback -> poweroff; overlay retained at %s\n' \
  "$ROOTFS_OVERLAY_REAL"
