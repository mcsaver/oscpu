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
PERF_LOG=${NEMU_SYSTEMD_PERF_LOG:-"$LOG_DIR/perf.tsv"}
SERIAL_FIFO=${NEMU_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}

LINUX_IMAGE=${LINUX_IMAGE:-"$ENV_ROOT/src/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$ENV_ROOT/build/opensbi-nemu-rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}
MAX_CYCLES=${MAX_CYCLES:-12000000000}
SYSCALL_PROBE_SRC=${NEMU_SYSTEMD_SYSCALL_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-syscall-probe.c"}
SYSCALL_PROBE_BIN=${NEMU_SYSTEMD_SYSCALL_PROBE_BIN:-"$LOG_DIR/nemu-systemd-syscall-probe.riscv64"}
SYSCALL_PROBE_B64=${NEMU_SYSTEMD_SYSCALL_PROBE_B64:-"$LOG_DIR/nemu-systemd-syscall-probe.b64"}
SYSCALL_PROBE_ENABLE=${NEMU_SYSTEMD_SYSCALL_PROBE:-1}
RISCV64_LINUX_GCC=${RISCV64_LINUX_GCC:-riscv64-linux-gnu-gcc}
RISCV64_LINUX_STRIP=${RISCV64_LINUX_STRIP:-riscv64-linux-gnu-strip}
VDA_HASH_WINDOW_BYTES=${NEMU_SYSTEMD_VDA_HASH_WINDOW_BYTES:-65536}
VDA_HASH_EXPECT=${NEMU_SYSTEMD_VDA_HASH_EXPECT:-"$LOG_DIR/vda-direct-read-sha256.tsv"}

CHECK_TIMEOUT=${NEMU_SYSTEMD_CHECK_TIMEOUT:-1200}
BOOT_TIMEOUT=${NEMU_SYSTEMD_BOOT_TIMEOUT:-900}
FIFO_TIMEOUT=${NEMU_SYSTEMD_FIFO_TIMEOUT:-60}
POLL_INTERVAL=${NEMU_SYSTEMD_POLL_INTERVAL:-2}
SOAK_SECONDS=${NEMU_SYSTEMD_SOAK_SECONDS:-20}
FS_STRESS_MIB=${NEMU_SYSTEMD_FS_STRESS_MIB:-4}
FS_TREE_FILES=${NEMU_SYSTEMD_FS_TREE_FILES:-64}
PROCESS_LOOPS=${NEMU_SYSTEMD_PROCESS_LOOPS:-16}
UART_RX_STRESS_LINES=${NEMU_SYSTEMD_UART_RX_STRESS_LINES:-512}
BLOCK_PARALLEL_JOBS=${NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS:-4}
BLOCK_JOB_MIB=${NEMU_SYSTEMD_BLOCK_JOB_MIB:-1}
SYSTEMD_RELOAD_TIMEOUT=${NEMU_SYSTEMD_RELOAD_TIMEOUT:-180}
INPUT_DELAY=${NEMU_SYSTEMD_INPUT_DELAY:-0}
POWEROFF_ENABLE=${NEMU_SYSTEMD_POWEROFF:-1}
POWEROFF_TIMEOUT=${NEMU_SYSTEMD_POWEROFF_TIMEOUT:-180}
ROOTFS_BYTES=$(stat -c %s "$RUN_ROOTFS" 2>/dev/null || echo 0)
VDA_HASH_WINDOW_COUNT=0

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

require_uint() {
  local name=$1
  local value=$2
  case "$value" in
    ''|*[!0-9]*) fail "$name must be a non-negative integer: $value" ;;
  esac
}

build_syscall_probe() {
  [ "$SYSCALL_PROBE_ENABLE" = "0" ] && return
  require_file "$SYSCALL_PROBE_SRC" "guest syscall probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$SYSCALL_PROBE_BIN" "$SYSCALL_PROBE_SRC" ||
    fail "failed to build guest syscall probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$SYSCALL_PROBE_BIN" || true
  fi
  base64 -w 76 "$SYSCALL_PROBE_BIN" >"$SYSCALL_PROBE_B64" ||
    fail "failed to encode guest syscall probe"
}

inject_syscall_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$SYSCALL_PROBE_B64" -v enabled="$SYSCALL_PROBE_ENABLE" '
    /__NEMU_SYSCALL_PROBE_PAYLOAD__/ {
      if (enabled != "0") {
        while ((getline line < payload) > 0) print line
        close(payload)
      }
      next
    }
    { print }
  ' "$cmd_file" >"$tmp_file" &&
    mv "$tmp_file" "$cmd_file"
}

inject_uart_rx_stress_commands() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v count="$UART_RX_STRESS_LINES" '
    /__NEMU_UART_RX_STRESS_COMMANDS__/ {
      print "uart_rx_stress_count=0"
      print "uart_rx_stress_expect=" count
      for (i = 0; i < count; i++) {
        printf "uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo \"__NEMU_UART_RX_STRESS_LINE__:%04d\"\n", i
      }
      print "echo \"__NEMU_UART_RX_STRESS_COUNT__:$uart_rx_stress_count/$uart_rx_stress_expect\""
      print "[ \"$uart_rx_stress_count\" = \"$uart_rx_stress_expect\" ] && pass uart-rx-command-burst || fail uart-rx-command-burst"
      next
    }
    { print }
  ' "$cmd_file" >"$tmp_file" &&
    mv "$tmp_file" "$cmd_file"
}

build_vda_hash_expectations() {
  command -v sha256sum >/dev/null 2>&1 || fail "missing host sha256sum"
  require_uint "NEMU_SYSTEMD_VDA_HASH_WINDOW_BYTES" "$VDA_HASH_WINDOW_BYTES"
  [ "$VDA_HASH_WINDOW_BYTES" -gt 0 ] || fail "VDA hash window must be positive"
  [ $((VDA_HASH_WINDOW_BYTES % 4096)) -eq 0 ] ||
    fail "VDA hash window must be 4096-byte aligned: $VDA_HASH_WINDOW_BYTES"
  [ "$ROOTFS_BYTES" -ge "$VDA_HASH_WINDOW_BYTES" ] ||
    fail "rootfs image is smaller than VDA hash window: $ROOTFS_BYTES < $VDA_HASH_WINDOW_BYTES"

  local offsets=""
  add_hash_offset() {
    local offset=$1
    case " $offsets " in
      *" $offset "*) ;;
      *) offsets="$offsets $offset" ;;
    esac
  }

  # rootfs 是读写挂载，systemd/journal 会在启动中改写前部和中部块；
  # 强 hash 比对只选镜像尾部稳定窗口，用来证明高 offset 映射没有截断/回卷。
  add_hash_offset $(( ((ROOTFS_BYTES - VDA_HASH_WINDOW_BYTES) / 4096) * 4096 ))

  : >"$VDA_HASH_EXPECT"
  local count_blocks=$((VDA_HASH_WINDOW_BYTES / 4096))
  local offset skip_blocks sha
  for offset in $offsets; do
    skip_blocks=$((offset / 4096))
    if ! sha=$(dd if="$RUN_ROOTFS" bs=4096 skip="$skip_blocks" \
        count="$count_blocks" iflag=fullblock status=none |
        sha256sum | awk '{print $1}'); then
      fail "failed to hash rootfs window at offset $offset"
    fi
    printf '%s:%s\n' "$offset" "$sha" >>"$VDA_HASH_EXPECT"
    VDA_HASH_WINDOW_COUNT=$((VDA_HASH_WINDOW_COUNT + 1))
  done
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

write_perf_log() {
  local boot_seconds=$1
  local guest_check_seconds=$2
  local poweroff_seconds=$3
  local total_seconds=$4
  # 这里记录 host 侧墙钟基线，方便后续 NEMU 设备/解释器优化做同口径 A/B。
  {
    printf 'boot_seconds\tguest_check_seconds\tpoweroff_seconds\ttotal_seconds\tsoak_seconds\tfs_stress_mib\tfs_tree_files\tprocess_loops\tuart_rx_stress_lines\tblock_parallel_jobs\tblock_job_mib\tmax_cycles\n'
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds" \
      "$SOAK_SECONDS" "$FS_STRESS_MIB" "$FS_TREE_FILES" "$PROCESS_LOOPS" \
      "$UART_RX_STRESS_LINES" "$BLOCK_PARALLEL_JOBS" "$BLOCK_JOB_MIB" "$MAX_CYCLES"
  } >"$PERF_LOG"
  echo "[nemu-systemd-check] perf boot=${boot_seconds}s guest_check=${guest_check_seconds}s poweroff=${poweroff_seconds}s total=${total_seconds}s"
  echo "[nemu-systemd-check] perf log: $PERF_LOG"
}

send_guest_commands() {
  local delay=$1
  if [ "$delay" = "0" ]; then
    cat "$LOG_DIR/guest-check.cmd" >"$SERIAL_FIFO"
    return
  fi

  exec 3>"$SERIAL_FIFO"
  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line" >&3
    sleep "$delay"
  done <"$LOG_DIR/guest-check.cmd"
  exec 3>&-
}

require_executable "$NEMU_SIM" "NEMU"
require_file "$LINUX_IMAGE" "Linux Image"
require_file "$RUN_FW" "OpenSBI firmware"
require_file "$RUN_DTB" "rootfs DTB"
require_file "$RUN_ROOTFS" "Ubuntu rootfs"
require_uint "NEMU_SYSTEMD_SOAK_SECONDS" "$SOAK_SECONDS"
require_uint "NEMU_SYSTEMD_FS_STRESS_MIB" "$FS_STRESS_MIB"
require_uint "NEMU_SYSTEMD_FS_TREE_FILES" "$FS_TREE_FILES"
require_uint "NEMU_SYSTEMD_PROCESS_LOOPS" "$PROCESS_LOOPS"
require_uint "NEMU_SYSTEMD_UART_RX_STRESS_LINES" "$UART_RX_STRESS_LINES"
require_uint "NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS" "$BLOCK_PARALLEL_JOBS"
require_uint "NEMU_SYSTEMD_BLOCK_JOB_MIB" "$BLOCK_JOB_MIB"
require_uint "NEMU_SYSTEMD_RELOAD_TIMEOUT" "$SYSTEMD_RELOAD_TIMEOUT"
require_uint "NEMU_SYSTEMD_SYSCALL_PROBE" "$SYSCALL_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_POWEROFF" "$POWEROFF_ENABLE"
require_uint "NEMU_SYSTEMD_POWEROFF_TIMEOUT" "$POWEROFF_TIMEOUT"
require_uint "rootfs image size" "$ROOTFS_BYTES"
[ "$SYSTEMD_RELOAD_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_RELOAD_TIMEOUT must be positive: $SYSTEMD_RELOAD_TIMEOUT"

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$LOG_FILE" "$PERF_LOG" \
  "$LOG_DIR/guest-check.cmd" "$SYSCALL_PROBE_BIN" "$SYSCALL_PROBE_B64" \
  "$VDA_HASH_EXPECT"
: >"$CONSOLE_LOG"
build_syscall_probe
build_vda_hash_expectations

echo "[nemu-systemd-check] log dir: $LOG_DIR"
echo "[nemu-systemd-check] serial fifo: $SERIAL_FIFO"
echo "[nemu-systemd-check] max cycles: $MAX_CYCLES"
echo "[nemu-systemd-check] soak seconds: $SOAK_SECONDS"
echo "[nemu-systemd-check] fs stress MiB: $FS_STRESS_MIB"
echo "[nemu-systemd-check] fs tree files: $FS_TREE_FILES"
echo "[nemu-systemd-check] process loops: $PROCESS_LOOPS"
echo "[nemu-systemd-check] UART RX stress lines: $UART_RX_STRESS_LINES"
echo "[nemu-systemd-check] block parallel jobs: $BLOCK_PARALLEL_JOBS"
echo "[nemu-systemd-check] block job MiB: $BLOCK_JOB_MIB"
echo "[nemu-systemd-check] systemd reload timeout: $SYSTEMD_RELOAD_TIMEOUT"
echo "[nemu-systemd-check] input delay: $INPUT_DELAY"
echo "[nemu-systemd-check] syscall probe: $SYSCALL_PROBE_ENABLE"
echo "[nemu-systemd-check] poweroff: $POWEROFF_ENABLE"
echo "[nemu-systemd-check] poweroff timeout: $POWEROFF_TIMEOUT"
if [ "$SYSCALL_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] syscall probe bytes: $(stat -c %s "$SYSCALL_PROBE_BIN")"
fi
echo "[nemu-systemd-check] rootfs bytes: $ROOTFS_BYTES"
echo "[nemu-systemd-check] vda hash window bytes: $VDA_HASH_WINDOW_BYTES"
echo "[nemu-systemd-check] vda hash windows: $VDA_HASH_WINDOW_COUNT"
echo "[nemu-systemd-check] perf log: $PERF_LOG"

host_start_seconds=$SECONDS
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
boot_seconds=$((SECONDS - host_start_seconds))

{
  printf 'NEMU_GUEST_SOAK_SECONDS=%s\n' "$SOAK_SECONDS"
  printf 'NEMU_GUEST_FS_STRESS_MIB=%s\n' "$FS_STRESS_MIB"
  printf 'NEMU_GUEST_FS_TREE_FILES=%s\n' "$FS_TREE_FILES"
  printf 'NEMU_GUEST_PROCESS_LOOPS=%s\n' "$PROCESS_LOOPS"
  printf 'NEMU_GUEST_UART_RX_STRESS_LINES=%s\n' "$UART_RX_STRESS_LINES"
  printf 'NEMU_GUEST_BLOCK_PARALLEL_JOBS=%s\n' "$BLOCK_PARALLEL_JOBS"
  printf 'NEMU_GUEST_BLOCK_JOB_MIB=%s\n' "$BLOCK_JOB_MIB"
  printf 'NEMU_GUEST_SYSTEMD_RELOAD_TIMEOUT=%s\n' "$SYSTEMD_RELOAD_TIMEOUT"
  printf 'NEMU_GUEST_ROOTFS_BYTES=%s\n' "$ROOTFS_BYTES"
  printf 'NEMU_GUEST_SYSCALL_PROBE=%s\n' "$SYSCALL_PROBE_ENABLE"
  printf 'NEMU_GUEST_POWEROFF=%s\n' "$POWEROFF_ENABLE"
  printf 'NEMU_GUEST_VDA_HASH_WINDOW_BYTES=%s\n' "$VDA_HASH_WINDOW_BYTES"
  printf 'NEMU_GUEST_VDA_HASH_EXPECT_FILE=/tmp/nemu-vda-direct-read-sha256.tsv\n'
  printf "cat > \"\$NEMU_GUEST_VDA_HASH_EXPECT_FILE\" <<'__NEMU_VDA_HASH_EXPECT__'\n"
  cat "$VDA_HASH_EXPECT"
  printf '__NEMU_VDA_HASH_EXPECT__\n'
} >"$LOG_DIR/guest-check.cmd"

cat >>"$LOG_DIR/guest-check.cmd" <<'GUEST_CMDS'
echo __NEMU_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NEMU_CHECK_PASS__:$1"; }
fail() { echo "__NEMU_CHECK_FAIL__:$1"; check_fail=1; }
__NEMU_UART_RX_STRESS_COMMANDS__
check_dir="/root/nemu-systemd-guest-check.d"
guest_check_uptime0="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
echo "__NEMU_CHECK_GUEST_UPTIME_BEGIN__:$guest_check_uptime0"

intr_sum() {
  intr_try=0
  while [ "$intr_try" -lt 3 ]; do
    intr_value="$(sed -n 's/^intr \([0-9][0-9]*\).*/\1/p' /proc/stat 2>/dev/null | head -n 1)"
    case "$intr_value" in
      ''|*[!0-9]*) intr_value=0 ;;
    esac
    if [ "$intr_value" -gt 0 ] 2>/dev/null; then
      echo "$intr_value"
      return
    fi
    intr_try=$((intr_try + 1))
    sleep 1
  done
  echo "$intr_value"
}

interrupts_table_sum() {
  awk '
    NR > 1 {
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^[0-9]+$/) sum += $i
      }
    }
    END { print sum + 0 }
  ' /proc/interrupts 2>/dev/null
}

interrupts_match_sum() {
  irq_pattern="$1"
  awk -v pat="$irq_pattern" '
    tolower($0) ~ pat {
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^[0-9]+$/) sum += $i
      }
    }
    END { print sum + 0 }
  ' /proc/interrupts 2>/dev/null
}

check_mount_fstype() {
  mount_target="$1"
  expected_fstype="$2"
  actual_fstype="$(findmnt -n -o FSTYPE --target "$mount_target" 2>/dev/null || true)"
  echo "__NEMU_CHECK_MOUNT_FSTYPE__:$mount_target:$actual_fstype"
  if [ "$actual_fstype" = "$expected_fstype" ]; then
    pass "mount-fstype-$mount_target"
  else
    fail "mount-fstype-$mount_target"
  fi
}

check_systemd_unit_active() {
  unit="$1"
  marker="$2"
  unit_state="$(systemctl is-active "$unit" 2>/dev/null || true)"
  echo "__NEMU_CHECK_SYSTEMD_UNIT__:$unit:$unit_state"
  if [ "$unit_state" = "active" ]; then
    pass "$marker"
  else
    fail "$marker"
  fi
}

virtio_feature_bit() {
  feature_bits="$1"
  feature_bit="$2"
  feature_pos=$((feature_bit + 1))
  printf '%s' "$feature_bits" | cut -c "$feature_pos"
}

systemd_daemon_reload_request() {
  reload_unit="$1"
  reload_goal="$2"

  # NEMU 下同步 daemon-reload reply 可能很慢；reload 请求本身用短 D-Bus
  # 尝试 + PID1 HUP 兜底，真正“PID1 已看到 unit”的证明交给后续 start/output。
  if ! timeout 5s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload; then
    echo "__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__:$reload_unit:$reload_goal"
    kill -HUP 1 || return 1
  fi
  return 0
}

systemd_start_runtime_unit_after_reload() {
  runtime_unit="$1"
  runtime_marker="$2"

  start_limit="$NEMU_GUEST_SYSTEMD_RELOAD_TIMEOUT"
  [ "$start_limit" -gt 30 ] 2>/dev/null && start_limit=30
  start_i=0
  while [ "$start_i" -lt "$start_limit" ]; do
    timeout 5s env SYSTEMD_BUS_TIMEOUT=5s \
      systemctl start "$runtime_unit" >/dev/null 2>&1 || true
    if [ -s "$runtime_marker" ]; then
      echo "__NEMU_CHECK_SYSTEMD_RUNTIME_START_OBSERVED__:$runtime_unit:$start_i"
      return 0
    fi
    if [ "$start_i" -eq 0 ] || [ $((start_i % 5)) -eq 0 ]; then
      echo "__NEMU_CHECK_SYSTEMD_RUNTIME_START_RETRY__:$runtime_unit:$start_i"
    fi
    start_i=$((start_i + 1))
    sleep 1
  done
  echo "__NEMU_CHECK_SYSTEMD_RUNTIME_START_TIMEOUT__:$runtime_unit:$start_limit"
  return 1
}

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

systemd_version="$(systemctl --version 2>/dev/null | head -n 1 || true)"
echo "__NEMU_CHECK_SYSTEMD_VERSION__:$systemd_version"
echo "$systemd_version" | grep -Eq '^systemd [0-9]+' && pass systemd-version || fail systemd-version

systemd_show_state="$(systemctl show --property=SystemState --value 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_SHOW_STATE__:$systemd_show_state"
[ "$systemd_show_state" = "running" ] &&
  pass systemd-show-system-state || fail systemd-show-system-state

systemd_failed_count="$(systemctl show --property=NFailedUnits --value 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_FAILED_COUNT__:$systemd_failed_count"
[ "$systemd_failed_count" = "0" ] &&
  pass systemd-show-failed-count || fail systemd-show-failed-count

# 这些 target 是 systemd 从早期 init 到普通多用户态的主干，能把
# “PID1 存在”推进为“完整 target 链已经跑完”。
for systemd_target in \
  local-fs.target \
  sysinit.target \
  basic.target \
  multi-user.target \
  getty.target; do
  check_systemd_unit_active "$systemd_target" "systemd-target-$systemd_target"
done
check_systemd_unit_active serial-getty@ttyS0.service serial-getty-ttyS0-active

systemctl --quiet is-active systemd-journald.service &&
  pass journald-active || fail journald-active
if command -v journalctl >/dev/null 2>&1; then
  pass journalctl-present
  journalctl --no-pager -b -n 5 >/dev/null 2>&1 &&
    pass journalctl-boot-read || fail journalctl-boot-read
else
  fail journalctl-present
fi

systemctl --quiet is-active dbus.service && pass dbus-active || fail dbus-active
if command -v busctl >/dev/null 2>&1; then
  pass busctl-present
  busctl --system --no-pager list >/dev/null 2>&1 &&
    pass busctl-system-list || fail busctl-system-list
else
  fail busctl-present
fi

transient_dir="/run/nemu-systemd-transient-check.d"
transient_service_name="nemu-transient-check"
transient_service="$transient_service_name.service"
transient_timer_name="nemu-transient-timer-check"
transient_timer="$transient_timer_name.timer"
transient_timer_service="$transient_timer_name.service"
rm -rf "$transient_dir"
mkdir -p "$transient_dir" || fail systemd-transient-dir
systemctl stop "$transient_timer" "$transient_timer_service" "$transient_service" >/dev/null 2>&1 || true
systemctl reset-failed "$transient_timer" "$transient_timer_service" "$transient_service" >/dev/null 2>&1 || true
if command -v systemd-run >/dev/null 2>&1; then
  pass systemd-run-present
  if timeout 30s systemd-run --unit="$transient_service_name" --wait \
      --property=StandardOutput=journal \
      /bin/sh -c "echo __NEMU_TRANSIENT_SERVICE_JOURNAL__; printf transient-ok > '$transient_dir/service.out'; cat /proc/self/cgroup > '$transient_dir/service.cgroup'"; then
    pass systemd-run-transient-service
  else
    fail systemd-run-transient-service
  fi
  if [ "$(cat "$transient_dir/service.out" 2>/dev/null || true)" = "transient-ok" ]; then
    pass systemd-transient-service-output
  else
    fail systemd-transient-service-output
  fi
  transient_result="$(systemctl show --property=Result --value "$transient_service" 2>/dev/null || true)"
  echo "__NEMU_CHECK_SYSTEMD_TRANSIENT_RESULT__:$transient_result"
  [ "$transient_result" = "success" ] &&
    pass systemd-transient-service-result || fail systemd-transient-service-result
  if grep -q "^0::.*$transient_service" "$transient_dir/service.cgroup" 2>/dev/null; then
    pass systemd-transient-service-cgroup
  else
    cat "$transient_dir/service.cgroup" 2>/dev/null || true
    fail systemd-transient-service-cgroup
  fi
  journal_i=0
  journal_ok=0
  while [ "$journal_i" -lt 10 ]; do
    if journalctl --no-pager -u "$transient_service" -n 50 2>/dev/null |
       grep -q "__NEMU_TRANSIENT_SERVICE_JOURNAL__"; then
      journal_ok=1
      break
    fi
    journal_i=$((journal_i + 1))
    sleep 1
  done
  [ "$journal_ok" = "1" ] &&
    pass systemd-transient-service-journal || fail systemd-transient-service-journal

  rm -f "$transient_dir/timer.out"
  if timeout 30s systemd-run --unit="$transient_timer_name" --on-active=1s \
      --timer-property=AccuracySec=100ms \
      /bin/sh -c "printf timer-ok > '$transient_dir/timer.out'"; then
    pass systemd-run-transient-timer
  else
    fail systemd-run-transient-timer
  fi
  timer_i=0
  while [ "$timer_i" -lt 30 ] && [ ! -s "$transient_dir/timer.out" ]; do
    sleep 1
    timer_i=$((timer_i + 1))
  done
  if [ "$(cat "$transient_dir/timer.out" 2>/dev/null || true)" = "timer-ok" ]; then
    pass systemd-transient-timer-fired
  else
    systemctl status "$transient_timer" "$transient_timer_service" --no-pager 2>/dev/null || true
    fail systemd-transient-timer-fired
  fi
else
  fail systemd-run-present
fi
systemctl stop "$transient_timer" "$transient_timer_service" >/dev/null 2>&1 || true
systemctl reset-failed "$transient_timer" "$transient_timer_service" "$transient_service" >/dev/null 2>&1 || true
rm -rf "$transient_dir"

runtime_unit_name="nemu-runtime-unit-check.service"
runtime_unit_dir="/run/nemu-systemd-runtime-unit-check.d"
runtime_unit_path="/run/systemd/system/$runtime_unit_name"
rm -rf "$runtime_unit_dir"
mkdir -p "$runtime_unit_dir" || fail systemd-runtime-unit-dir
systemctl stop "$runtime_unit_name" >/dev/null 2>&1 || true
systemctl reset-failed "$runtime_unit_name" >/dev/null 2>&1 || true
rm -f "$runtime_unit_path"
cat > "$runtime_unit_path" <<UNIT
[Unit]
Description=NEMU runtime unit lifecycle check
After=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/bin/sh -c 'echo __NEMU_RUNTIME_UNIT_JOURNAL__; printf runtime-ok > "$runtime_unit_dir/runtime.out"; cat /proc/self/cgroup > "$runtime_unit_dir/runtime.cgroup"'
UNIT

if systemd_daemon_reload_request "$runtime_unit_name" present &&
   systemd_start_runtime_unit_after_reload "$runtime_unit_name" \
     "$runtime_unit_dir/runtime.out"; then
  pass systemd-runtime-daemon-reload
  pass systemd-runtime-unit-start
else
  systemctl status "$runtime_unit_name" --no-pager 2>/dev/null || true
  fail systemd-runtime-daemon-reload
  fail systemd-runtime-unit-start
fi
if [ "$(cat "$runtime_unit_dir/runtime.out" 2>/dev/null || true)" = "runtime-ok" ]; then
  pass systemd-runtime-unit-output
else
  fail systemd-runtime-unit-output
fi
runtime_active="$(systemctl show --property=ActiveState --value "$runtime_unit_name" 2>/dev/null || true)"
runtime_result="$(systemctl show --property=Result --value "$runtime_unit_name" 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_RUNTIME_ACTIVE__:$runtime_active"
echo "__NEMU_CHECK_SYSTEMD_RUNTIME_RESULT__:$runtime_result"
[ "$runtime_active" = "active" ] &&
  pass systemd-runtime-unit-active || fail systemd-runtime-unit-active
[ "$runtime_result" = "success" ] &&
  pass systemd-runtime-unit-result || fail systemd-runtime-unit-result
systemctl --no-pager --plain status "$runtime_unit_name" >/dev/null 2>&1 &&
  pass systemd-runtime-unit-status || fail systemd-runtime-unit-status
if grep -q "^0::.*$runtime_unit_name" "$runtime_unit_dir/runtime.cgroup" 2>/dev/null; then
  pass systemd-runtime-unit-cgroup
else
  cat "$runtime_unit_dir/runtime.cgroup" 2>/dev/null || true
  fail systemd-runtime-unit-cgroup
fi
runtime_journal_i=0
runtime_journal_ok=0
while [ "$runtime_journal_i" -lt 10 ]; do
  if journalctl --no-pager -u "$runtime_unit_name" -n 50 2>/dev/null |
     grep -q "__NEMU_RUNTIME_UNIT_JOURNAL__"; then
    runtime_journal_ok=1
    break
  fi
  runtime_journal_i=$((runtime_journal_i + 1))
  sleep 1
done
[ "$runtime_journal_ok" = "1" ] &&
  pass systemd-runtime-unit-journal || fail systemd-runtime-unit-journal
systemctl stop "$runtime_unit_name" >/dev/null 2>&1 || true
systemctl reset-failed "$runtime_unit_name" >/dev/null 2>&1 || true
rm -f "$runtime_unit_path"
rm -rf "$runtime_unit_dir"
runtime_cleanup_state="$(timeout 10s env SYSTEMD_BUS_TIMEOUT=5s \
  systemctl is-active "$runtime_unit_name" 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_RUNTIME_CLEANUP_ACTIVE__:$runtime_cleanup_state"
if [ ! -e "$runtime_unit_path" ] &&
   [ ! -d "$runtime_unit_dir" ] &&
   [ "$runtime_cleanup_state" != "active" ]; then
  pass systemd-runtime-unit-cleanup
else
  fail systemd-runtime-unit-cleanup
fi

for m in /dev /proc /sys /run /dev/pts /dev/shm /sys/fs/cgroup; do
  if mountpoint -q "$m"; then
    echo "__NEMU_CHECK_MOUNT_OK__:$m"
  else
    echo "__NEMU_CHECK_MOUNT_MISSING__:$m"
    check_fail=1
  fi
done
check_mount_fstype /dev devtmpfs
check_mount_fstype /proc proc
check_mount_fstype /sys sysfs
check_mount_fstype /run tmpfs
check_mount_fstype /dev/pts devpts
check_mount_fstype /dev/shm tmpfs
check_mount_fstype /sys/fs/cgroup cgroup2

[ -c /dev/ttyS0 ] && pass ttyS0-node || fail ttyS0-node
[ -c /dev/console ] && pass console-node || fail console-node
tty_name="$(tty 2>&1 || true)"
echo "__NEMU_CHECK_TTY__:$tty_name"
echo "$tty_name" | grep -Eq '/dev/(ttyS0|console)' && pass interactive-tty || fail interactive-tty
stty -F /dev/ttyS0 -a >/dev/null 2>&1 && pass ttyS0-stty || fail ttyS0-stty
if printf '__NEMU_CHECK_TTYS0_WRITE__\n' > /dev/ttyS0; then
  pass ttyS0-write
else
  fail ttyS0-write
fi
if printf '__NEMU_CHECK_CONSOLE_WRITE__\n' > /dev/console; then
  pass console-write
else
  fail console-write
fi

if command -v udevadm >/dev/null 2>&1; then
  pass udevadm-present
  udevadm settle --timeout=30 >/dev/null 2>&1 && pass udev-settle || fail udev-settle
else
  fail udevadm-present
fi
systemctl --quiet is-active systemd-udevd.service && pass udevd-active || fail udevd-active

hwrng_misc="/sys/class/misc/hw_random"
hwrng_current="$(cat "$hwrng_misc/rng_current" 2>/dev/null || true)"
hwrng_available="$(cat "$hwrng_misc/rng_available" 2>/dev/null || true)"
rng_virtio_modalias="$(grep -h '^virtio:d00000004v58535959$' \
  /sys/bus/virtio/devices/*/modalias 2>/dev/null | head -n 1 || true)"
echo "__NEMU_CHECK_HWRNG_CURRENT__:$hwrng_current"
echo "__NEMU_CHECK_HWRNG_AVAILABLE__:$hwrng_available"
echo "__NEMU_CHECK_VIRTIO_RNG_MODALIAS__:$rng_virtio_modalias"
[ -c /dev/hwrng ] && pass hwrng-node || fail hwrng-node
[ -d "$hwrng_misc" ] && pass hwrng-sysfs || fail hwrng-sysfs
printf '%s\n%s\n' "$hwrng_current" "$hwrng_available" | grep -qi 'virtio' &&
  pass hwrng-virtio-selected || fail hwrng-virtio-selected
[ "$rng_virtio_modalias" = "virtio:d00000004v58535959" ] &&
  pass virtio-rng-modalias || fail virtio-rng-modalias
hwrng_out="/tmp/nemu-hwrng.bin"
rm -f "$hwrng_out"
if timeout 10s dd if=/dev/hwrng of="$hwrng_out" bs=64 count=1 \
    iflag=fullblock status=none; then
  hwrng_bytes="$(wc -c < "$hwrng_out" 2>/dev/null || echo 0)"
  echo "__NEMU_CHECK_HWRNG_BYTES__:$hwrng_bytes"
  [ "$hwrng_bytes" = "64" ] && pass hwrng-read || fail hwrng-read
else
  fail hwrng-read
fi
rm -f "$hwrng_out"

rtc_sys="/sys/class/rtc/rtc0"
rtc_name="$(cat "$rtc_sys/name" 2>/dev/null || true)"
rtc_since_epoch="$(cat "$rtc_sys/since_epoch" 2>/dev/null || true)"
rtc_date="$(cat "$rtc_sys/date" 2>/dev/null || true)"
rtc_time="$(cat "$rtc_sys/time" 2>/dev/null || true)"
echo "__NEMU_CHECK_RTC0_NAME__:$rtc_name"
echo "__NEMU_CHECK_RTC0_SINCE_EPOCH__:$rtc_since_epoch"
echo "__NEMU_CHECK_RTC0_DATE__:$rtc_date"
echo "__NEMU_CHECK_RTC0_TIME__:$rtc_time"
[ -c /dev/rtc0 ] && pass rtc0-node || fail rtc0-node
[ -d "$rtc_sys" ] && pass rtc0-sysfs || fail rtc0-sysfs
echo "$rtc_name" | grep -qi 'goldfish' &&
  pass rtc0-goldfish-driver || fail rtc0-goldfish-driver
[ "${rtc_since_epoch:-0}" -gt 1577836800 ] 2>/dev/null &&
  pass rtc0-since-epoch-plausible || fail rtc0-since-epoch-plausible
if command -v hwclock >/dev/null 2>&1; then
  pass hwclock-present
  rtc_hwclock="$(timeout 10s hwclock --show --rtc=/dev/rtc0 2>&1)"
  rtc_hwclock_rc=$?
  echo "__NEMU_CHECK_RTC0_HWCLOCK__:$rtc_hwclock"
  if [ "$rtc_hwclock_rc" -eq 0 ] && echo "$rtc_hwclock" | grep -Eq '[0-9]{4}'; then
    pass hwclock-rtc0-show
  else
    # util-linux hwclock may wait for update IRQ/UIE behavior that this minimal
    # RTC model does not yet claim; sysfs rtc0 reads above remain the hard gate.
    echo "__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:$rtc_hwclock_rc"
  fi
else
  echo "__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:missing"
fi

[ -b /dev/vda ] && pass vda-block-node || fail vda-block-node
vda_dev_node="$(stat -c '%F %t:%T' /dev/vda 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_DEV_NODE__:$vda_dev_node"
vda_size="$(blockdev --getsize64 /dev/vda 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_SIZE__:$vda_size"
[ "${vda_size:-0}" -gt 0 ] 2>/dev/null && pass vda-size || fail vda-size
if [ "${NEMU_GUEST_ROOTFS_BYTES:-0}" -gt 0 ] 2>/dev/null; then
  [ "$vda_size" = "$NEMU_GUEST_ROOTFS_BYTES" ] && pass vda-size-matches-rootfs || fail vda-size-matches-rootfs
fi
vda_lbs="$(cat /sys/block/vda/queue/logical_block_size 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_LOGICAL_BLOCK__:$vda_lbs"
[ "$vda_lbs" = "512" ] && pass vda-logical-block-size || fail vda-logical-block-size
vda_pbs="$(cat /sys/block/vda/queue/physical_block_size 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_PHYSICAL_BLOCK__:$vda_pbs"
[ "$vda_pbs" = "512" ] && pass vda-physical-block-size || fail vda-physical-block-size
vda_min_io="$(cat /sys/block/vda/queue/minimum_io_size 2>/dev/null || true)"
vda_opt_io="$(cat /sys/block/vda/queue/optimal_io_size 2>/dev/null || true)"
vda_alignment="$(cat /sys/block/vda/alignment_offset 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_MIN_IO__:$vda_min_io"
echo "__NEMU_CHECK_VDA_OPT_IO__:$vda_opt_io"
echo "__NEMU_CHECK_VDA_ALIGNMENT_OFFSET__:$vda_alignment"
[ "$vda_min_io" = "512" ] && pass vda-minimum-io-size || fail vda-minimum-io-size
[ "$vda_opt_io" = "0" ] && pass vda-optimal-io-size || fail vda-optimal-io-size
[ "$vda_alignment" = "0" ] && pass vda-alignment-offset || fail vda-alignment-offset
vda_discard_max="$(cat /sys/block/vda/queue/discard_max_bytes 2>/dev/null || true)"
vda_discard_granularity="$(cat /sys/block/vda/queue/discard_granularity 2>/dev/null || true)"
vda_write_zeroes_max="$(cat /sys/block/vda/queue/write_zeroes_max_bytes 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_DISCARD_MAX__:$vda_discard_max"
echo "__NEMU_CHECK_VDA_DISCARD_GRANULARITY__:$vda_discard_granularity"
echo "__NEMU_CHECK_VDA_WRITE_ZEROES_MAX__:$vda_write_zeroes_max"
[ "$vda_discard_max" = "2097152" ] &&
  pass vda-discard-max-bytes || fail vda-discard-max-bytes
[ "$vda_discard_granularity" = "512" ] &&
  pass vda-discard-granularity || fail vda-discard-granularity
[ "$vda_write_zeroes_max" = "2097152" ] &&
  pass vda-write-zeroes-max-bytes || fail vda-write-zeroes-max-bytes
vda_cache_type_path="/sys/block/vda/cache_type"
vda_cache_type="$(cat "$vda_cache_type_path" 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_CACHE_TYPE__:$vda_cache_type"
echo "$vda_cache_type" | grep -Eq 'write (back|through)' &&
  pass vda-cache-type-visible || fail vda-cache-type-visible
if [ -w "$vda_cache_type_path" ]; then
  pass vda-cache-type-writable
else
  fail vda-cache-type-writable
fi
if printf 'write through\n' > "$vda_cache_type_path" 2>/dev/null &&
   [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write through" ]; then
  pass vda-cache-type-write-through
else
  fail vda-cache-type-write-through
fi
if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null &&
   [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then
  pass vda-cache-type-write-back
else
  fail vda-cache-type-write-back
fi
vda_serial="$(cat /sys/block/vda/serial 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_SERIAL__:$vda_serial"
[ "$vda_serial" = "ysyx-nemu-virtio-blk" ] &&
  pass vda-serial-get-id || fail vda-serial-get-id
vda_sys_dev="$(cat /sys/class/block/vda/dev 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_SYS_DEV__:$vda_sys_dev"
echo "$vda_sys_dev" | grep -Eq '^[0-9]+:[0-9]+$' && pass sysfs-vda-dev || fail sysfs-vda-dev
[ -e /sys/class/block/vda ] && pass sysfs-vda-block || fail sysfs-vda-block
vda_driver="$(basename "$(readlink -f /sys/class/block/vda/device/driver 2>/dev/null || true)")"
echo "__NEMU_CHECK_VDA_DRIVER__:$vda_driver"
[ "$vda_driver" = "virtio_blk" ] && pass sysfs-vda-driver || fail sysfs-vda-driver
vda_virtio_dev="$(readlink -f /sys/class/block/vda/device 2>/dev/null || true)"
echo "__NEMU_CHECK_VDA_VIRTIO_DEV__:$vda_virtio_dev"
[ -n "$vda_virtio_dev" ] && [ -d "$vda_virtio_dev" ] &&
  pass sysfs-vda-virtio-device || fail sysfs-vda-virtio-device
virtio_modalias="$(cat "$vda_virtio_dev/modalias" 2>/dev/null || true)"
virtio_status="$(cat "$vda_virtio_dev/status" 2>/dev/null || true)"
virtio_features="$(tr -d '\n' < "$vda_virtio_dev/features" 2>/dev/null || true)"
echo "__NEMU_CHECK_VIRTIO_MODALIAS__:$virtio_modalias"
echo "__NEMU_CHECK_VIRTIO_STATUS__:$virtio_status"
echo "__NEMU_CHECK_VIRTIO_FEATURES__:$virtio_features"
[ "$virtio_modalias" = "virtio:d00000002v58535959" ] &&
  pass virtio-vda-modalias || fail virtio-vda-modalias
echo "$virtio_status" | grep -Eq '^0x[0-9a-fA-F]+$' &&
  pass virtio-vda-status || fail virtio-vda-status
echo "$virtio_features" | grep -Eq '^[01]+$' &&
  pass virtio-vda-features-bitstring || fail virtio-vda-features-bitstring
[ "$(virtio_feature_bit "$virtio_features" 32)" = "1" ] &&
  pass virtio-feature-version-1 || fail virtio-feature-version-1
[ "$(virtio_feature_bit "$virtio_features" 6)" = "1" ] &&
  pass virtio-blk-feature-blk-size || fail virtio-blk-feature-blk-size
[ "$(virtio_feature_bit "$virtio_features" 9)" = "1" ] &&
  pass virtio-blk-feature-flush || fail virtio-blk-feature-flush
[ "$(virtio_feature_bit "$virtio_features" 10)" = "1" ] &&
  pass virtio-blk-feature-topology || fail virtio-blk-feature-topology
[ "$(virtio_feature_bit "$virtio_features" 11)" = "1" ] &&
  pass virtio-blk-feature-config-wce || fail virtio-blk-feature-config-wce
[ "$(virtio_feature_bit "$virtio_features" 13)" = "1" ] &&
  pass virtio-blk-feature-discard || fail virtio-blk-feature-discard
[ "$(virtio_feature_bit "$virtio_features" 14)" = "1" ] &&
  pass virtio-blk-feature-write-zeroes || fail virtio-blk-feature-write-zeroes
[ "$(virtio_feature_bit "$virtio_features" 28)" = "1" ] &&
  pass virtio-ring-feature-indirect-desc || fail virtio-ring-feature-indirect-desc
[ "$(virtio_feature_bit "$virtio_features" 29)" = "1" ] &&
  pass virtio-ring-feature-event-idx || fail virtio-ring-feature-event-idx
if command -v udevadm >/dev/null 2>&1; then
  vda_udev_props="$(udevadm info --query=property --name=/dev/vda 2>/dev/null || true)"
  if printf '%s\n' "$vda_udev_props" | grep -qx 'DEVNAME=/dev/vda' &&
     printf '%s\n' "$vda_udev_props" | grep -qx 'SUBSYSTEM=block' &&
     printf '%s\n' "$vda_udev_props" | grep -qx 'DEVTYPE=disk'; then
    pass udev-vda-properties
  else
    fail udev-vda-properties
  fi
fi
dev_disk_link="$(find /dev/disk -type l -lname '*vda*' -print -quit 2>/dev/null || true)"
echo "__NEMU_CHECK_DEV_DISK_LINK__:$dev_disk_link"
[ -n "$dev_disk_link" ] && pass dev-disk-symlink || fail dev-disk-symlink
grep -Eq '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+vda$' /proc/partitions &&
  pass proc-partitions-vda || fail proc-partitions-vda

irq_total0="$(interrupts_table_sum)"
irq_serial0="$(interrupts_match_sum 'ttys0|serial|10000000')"
irq_virtio0="$(interrupts_match_sum 'virtio|vda|10001000')"
echo "__NEMU_CHECK_INTERRUPTS_TOTAL__:$irq_total0"
echo "__NEMU_CHECK_IRQ_SERIAL__:$irq_serial0"
echo "__NEMU_CHECK_IRQ_VIRTIO_BLK__:$irq_virtio0"
sed 's/^/__NEMU_CHECK_INTERRUPTS_LINE__:/' /proc/interrupts 2>/dev/null || true
[ "$irq_total0" -gt 0 ] 2>/dev/null && pass proc-interrupts-total || fail proc-interrupts-total
[ "$irq_serial0" -gt 0 ] 2>/dev/null && pass irq-serial-visible || fail irq-serial-visible
[ "$irq_virtio0" -gt 0 ] 2>/dev/null && pass irq-virtio-blk-visible || fail irq-virtio-blk-visible

if dd if=/dev/vda of=/dev/null bs=4096 count=16 iflag=direct status=none; then
  pass irq-vda-direct-read
else
  fail irq-vda-direct-read
fi
sleep 1
irq_total1="$(interrupts_table_sum)"
irq_virtio1="$(interrupts_match_sum 'virtio|vda|10001000')"
echo "__NEMU_CHECK_INTERRUPTS_TOTAL_GROW__:$irq_total0->$irq_total1"
echo "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__:$irq_virtio0->$irq_virtio1"
[ "$irq_total1" -ge "$irq_total0" ] 2>/dev/null &&
  pass proc-interrupts-total-monotonic || fail proc-interrupts-total-monotonic
[ "$irq_virtio1" -gt "$irq_virtio0" ] 2>/dev/null &&
  pass irq-virtio-blk-read-growth || fail irq-virtio-blk-read-growth

root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
echo "__NEMU_CHECK_ROOT_SOURCE__:$root_source"
case "$root_source" in
  /dev/vda*|/dev/root) pass rootfs-source ;;
  *) fail rootfs-source ;;
esac

rm -f /nemu-systemd-guest-check.bin /root/nemu-systemd-guest-check.bin
rm -rf "$check_dir"
if mkdir -p "$check_dir/sub"; then
  pass fs-mkdir
else
  fail fs-mkdir
fi

root_fstype="$(stat -f -c %T / 2>/dev/null || true)"
echo "__NEMU_CHECK_ROOT_FSTYPE__:$root_fstype"
case "$root_fstype" in
  ext2/ext3|ext4) pass rootfs-fstype ;;
  *) fail rootfs-fstype ;;
esac

raw_vda_head="$check_dir/vda-head.bin"
if dd if=/dev/vda of="$raw_vda_head" bs=4096 count=16 iflag=direct status=none; then
  raw_vda_bytes="$(wc -c < "$raw_vda_head" 2>/dev/null || echo 0)"
  echo "__NEMU_CHECK_VDA_DIRECT_READ_BYTES__:$raw_vda_bytes"
  [ "$raw_vda_bytes" = "65536" ] && pass vda-direct-read || fail vda-direct-read
  rm -f "$raw_vda_head"
else
  fail vda-direct-read
fi

if [ -s "${NEMU_GUEST_VDA_HASH_EXPECT_FILE:-}" ] &&
   [ "${NEMU_GUEST_VDA_HASH_WINDOW_BYTES:-0}" -gt 0 ] 2>/dev/null; then
  vda_hash_ok=1
  vda_hash_count=0
  vda_hash_blocks=$((NEMU_GUEST_VDA_HASH_WINDOW_BYTES / 4096))
  while IFS=: read -r vda_hash_offset vda_hash_expected; do
    [ -n "$vda_hash_offset" ] || continue
    vda_hash_file="$check_dir/vda-window-$vda_hash_offset.bin"
    vda_hash_skip=$((vda_hash_offset / 4096))
    if dd if=/dev/vda of="$vda_hash_file" bs=4096 skip="$vda_hash_skip" \
        count="$vda_hash_blocks" iflag=direct,fullblock status=none; then
      vda_hash_actual="$(sha256sum "$vda_hash_file" 2>/dev/null | awk '{print $1}')"
      echo "__NEMU_CHECK_VDA_WINDOW_SHA256__:$vda_hash_offset:$vda_hash_actual:$vda_hash_expected"
      if [ "$vda_hash_actual" != "$vda_hash_expected" ]; then
        vda_hash_ok=0
      fi
    else
      echo "__NEMU_CHECK_VDA_WINDOW_READ_FAIL__:$vda_hash_offset"
      vda_hash_ok=0
    fi
    rm -f "$vda_hash_file"
    vda_hash_count=$((vda_hash_count + 1))
  done < "$NEMU_GUEST_VDA_HASH_EXPECT_FILE"
  echo "__NEMU_CHECK_VDA_WINDOW_COUNT__:$vda_hash_count"
  if [ "$vda_hash_ok" = "1" ] && [ "$vda_hash_count" -gt 0 ]; then
    pass vda-direct-read-sha256-windows
  else
    fail vda-direct-read-sha256-windows
  fi
else
  fail vda-direct-read-sha256-windows
fi

blockdev --flushbufs /dev/vda >/dev/null 2>&1 && pass vda-flushbufs || fail vda-flushbufs

if printf 'alpha\nbeta\n' > "$check_dir/file" &&
   [ "$(wc -l < "$check_dir/file" 2>/dev/null || echo 0)" = "2" ]; then
  pass fs-small-write-read
else
  fail fs-small-write-read
fi

if ln -s file "$check_dir/link" &&
   [ "$(readlink "$check_dir/link" 2>/dev/null || true)" = "file" ]; then
  pass symlink-readlink
else
  fail symlink-readlink
fi

if chmod 640 "$check_dir/file" &&
   [ "$(stat -c %a "$check_dir/file" 2>/dev/null || true)" = "640" ]; then
  pass chmod-stat
else
  fail chmod-stat
fi

if mv "$check_dir/file" "$check_dir/sub/file2" &&
   cp "$check_dir/sub/file2" "$check_dir/copy" &&
   cmp -s "$check_dir/sub/file2" "$check_dir/copy"; then
  pass rename-copy-cmp
else
  fail rename-copy-cmp
fi

if [ "$NEMU_GUEST_FS_TREE_FILES" -gt 0 ]; then
  tree_dir="$check_dir/rootfs-metadata-tree"
  tree_ok=1
  rm -rf "$tree_dir"
  mkdir -p "$tree_dir/a" "$tree_dir/b" || tree_ok=0
  tree_i=0
  while [ "$tree_i" -lt "$NEMU_GUEST_FS_TREE_FILES" ]; do
    tree_bucket=$((tree_i % 8))
    tree_name="$(printf 'file-%04d' "$tree_i")"
    tree_payload="$(printf 'metadata-%04d' "$tree_i")"
    tree_src="$tree_dir/a/$tree_bucket/$tree_name"
    tree_hard="$tree_dir/a/$tree_bucket/hard-$tree_name"
    tree_dst="$tree_dir/b/$tree_bucket/$tree_name"
    if mkdir -p "$tree_dir/a/$tree_bucket" "$tree_dir/b/$tree_bucket" &&
       printf '%s\n' "$tree_payload" > "$tree_src" &&
       ln "$tree_src" "$tree_hard" &&
       mv "$tree_src" "$tree_dst"; then
      tree_dst_payload="$(cat "$tree_dst" 2>/dev/null || true)"
      tree_hard_payload="$(cat "$tree_hard" 2>/dev/null || true)"
      tree_dst_inode="$(stat -c %i "$tree_dst" 2>/dev/null || true)"
      tree_hard_inode="$(stat -c %i "$tree_hard" 2>/dev/null || true)"
      if [ "$tree_dst_payload" != "$tree_payload" ] ||
         [ "$tree_hard_payload" != "$tree_payload" ] ||
         [ -z "$tree_dst_inode" ] ||
         [ "$tree_dst_inode" != "$tree_hard_inode" ]; then
        tree_ok=0
      fi
    else
      tree_ok=0
    fi
    tree_i=$((tree_i + 1))
  done
  tree_expected=$((NEMU_GUEST_FS_TREE_FILES * 2))
  tree_count="$(find "$tree_dir" -type f 2>/dev/null | wc -l | tr -d '[:space:]')"
  echo "__NEMU_CHECK_FS_TREE_FILES__:$tree_count/$tree_expected"
  sync
  if [ "$tree_ok" = "1" ] && [ "$tree_count" = "$tree_expected" ]; then
    pass rootfs-metadata-tree
  else
    fail rootfs-metadata-tree
  fi
  rm -rf "$tree_dir"
  sync
else
  echo "__NEMU_CHECK_FS_TREE_SKIP__"
fi

if mkfifo "$check_dir/fifo"; then
  ( IFS= read -r fifo_line < "$check_dir/fifo"; printf '%s\n' "$fifo_line" > "$check_dir/fifo.out" ) &
  fifo_pid=$!
  printf 'fifo-ok\n' > "$check_dir/fifo"
  wait "$fifo_pid" || true
  [ "$(cat "$check_dir/fifo.out" 2>/dev/null || true)" = "fifo-ok" ] && pass fifo-ipc || fail fifo-ipc
else
  fail fifo-ipc
fi

pipe_bytes="$(printf 'syscall-battery' | wc -c 2>/dev/null | tr -d '[:space:]' || echo 0)"
echo "__NEMU_CHECK_PIPE_BYTES__:$pipe_bytes"
[ "$pipe_bytes" = "15" ] && pass pipe-wc || fail pipe-wc

proc_ok=1
proc_i=0
while [ "$proc_i" -lt "$NEMU_GUEST_PROCESS_LOOPS" ]; do
  ( exit 0 ) &
  child=$!
  wait "$child" || proc_ok=0
  proc_i=$((proc_i + 1))
done
[ "$proc_ok" = "1" ] && pass fork-wait-loop || fail fork-wait-loop

if /bin/sh -c 'exit 0' && /usr/bin/env true; then
  pass execve-basic
else
  fail execve-basic
fi

if [ "$NEMU_GUEST_SYSCALL_PROBE" != "0" ]; then
  probe_b64="$check_dir/syscall-probe.b64"
  probe_bin="$check_dir/syscall-probe"
  cat > "$probe_b64" <<'__NEMU_SYSCALL_PROBE_B64__'
__NEMU_SYSCALL_PROBE_PAYLOAD__
__NEMU_SYSCALL_PROBE_B64__
  if base64 -d "$probe_b64" > "$probe_bin" &&
     chmod +x "$probe_bin" &&
     "$probe_bin" "$check_dir"; then
    pass syscall-probe
  else
    fail syscall-probe
  fi
else
  echo "__NEMU_CHECK_SYSCALL_PROBE_SKIP__"
fi

sleep 60 &
sig_pid=$!
kill -TERM "$sig_pid" 2>/dev/null || true
wait "$sig_pid"
sig_rc=$?
echo "__NEMU_CHECK_SIGNAL_RC__:$sig_rc"
[ "$sig_rc" -gt 128 ] 2>/dev/null && pass signal-kill-wait || fail signal-kill-wait

write_file="$check_dir/nemu-systemd-guest-check.bin"
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

direct_file="$check_dir/rootfs-direct.bin"
direct_copy="$check_dir/rootfs-direct.copy"
if dd if=/dev/zero of="$direct_file" bs=4096 count=32 oflag=direct conv=fsync status=none &&
   dd if="$direct_file" of="$direct_copy" bs=4096 iflag=direct status=none; then
  direct_bytes="$(wc -c < "$direct_copy" 2>/dev/null || echo 0)"
  echo "__NEMU_CHECK_ROOTFS_DIRECT_BYTES__:$direct_bytes"
  if [ "$direct_bytes" = "131072" ] && cmp -s "$direct_file" "$direct_copy"; then
    pass rootfs-direct-io
  else
    fail rootfs-direct-io
  fi
  rm -f "$direct_file" "$direct_copy"
  sync
else
  fail rootfs-direct-io
fi

if [ "$NEMU_GUEST_BLOCK_PARALLEL_JOBS" -gt 0 ] &&
   [ "$NEMU_GUEST_BLOCK_JOB_MIB" -gt 0 ]; then
  parallel_dir="$check_dir/block-parallel"
  mkdir -p "$parallel_dir" || fail rootfs-parallel-direct-io
  parallel_ok=1
  parallel_pids=""
  parallel_i=0
  parallel_expected_job=$((NEMU_GUEST_BLOCK_JOB_MIB * 1048576))
  parallel_expected_total=$((NEMU_GUEST_BLOCK_PARALLEL_JOBS * parallel_expected_job))

  while [ "$parallel_i" -lt "$NEMU_GUEST_BLOCK_PARALLEL_JOBS" ]; do
    job_id=$parallel_i
    (
      job_file="$parallel_dir/job-$job_id.bin"
      job_copy="$parallel_dir/job-$job_id.copy"
      if dd if=/dev/zero of="$job_file" bs=1M count="$NEMU_GUEST_BLOCK_JOB_MIB" oflag=direct conv=fsync status=none &&
         dd if="$job_file" of="$job_copy" bs=1M iflag=direct status=none; then
        job_bytes="$(wc -c < "$job_copy" 2>/dev/null || echo 0)"
        echo "__NEMU_CHECK_BLOCK_PARALLEL_JOB__:$job_id:$job_bytes"
        if [ "$job_bytes" = "$parallel_expected_job" ] &&
           cmp -s "$job_file" "$job_copy"; then
          exit 0
        fi
      fi
      echo "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__:$job_id"
      exit 1
    ) &
    parallel_pids="$parallel_pids $!"
    parallel_i=$((parallel_i + 1))
  done

  for p in $parallel_pids; do
    wait "$p" || parallel_ok=0
  done

  parallel_total=0
  parallel_i=0
  while [ "$parallel_i" -lt "$NEMU_GUEST_BLOCK_PARALLEL_JOBS" ]; do
    job_copy="$parallel_dir/job-$parallel_i.copy"
    job_bytes="$(wc -c < "$job_copy" 2>/dev/null || echo 0)"
    parallel_total=$((parallel_total + job_bytes))
    parallel_i=$((parallel_i + 1))
  done
  echo "__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:$parallel_total/$parallel_expected_total"
  if [ "$parallel_ok" = "1" ] &&
     [ "$parallel_total" = "$parallel_expected_total" ]; then
    pass rootfs-parallel-direct-io
  else
    fail rootfs-parallel-direct-io
  fi
  rm -rf "$parallel_dir"
  sync
else
  echo "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__"
fi

stress_file="$check_dir/rootfs-stress.bin"
stress_copy="$check_dir/rootfs-stress.copy"
if dd if=/dev/zero of="$stress_file" bs=1M count="$NEMU_GUEST_FS_STRESS_MIB" conv=fsync status=none; then
  stress_bytes="$(wc -c < "$stress_file" 2>/dev/null || echo 0)"
  stress_expected=$((NEMU_GUEST_FS_STRESS_MIB * 1048576))
  echo "__NEMU_CHECK_FS_STRESS_BYTES__:$stress_bytes/$stress_expected"
  if [ "$stress_bytes" = "$stress_expected" ] &&
     cp "$stress_file" "$stress_copy" &&
     cmp -s "$stress_file" "$stress_copy"; then
    pass rootfs-stress-copy-cmp
  else
    fail rootfs-stress-copy-cmp
  fi
  rm -f "$stress_file" "$stress_copy"
  sync
else
  fail rootfs-stress-copy-cmp
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

if [ "$NEMU_GUEST_SOAK_SECONDS" -gt 0 ]; then
  soak_uptime0="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
  soak_intr0="$(intr_sum)"
  soak_i=0
  while [ "$soak_i" -lt "$NEMU_GUEST_SOAK_SECONDS" ]; do
    sleep 1
    if [ $((soak_i % 5)) -eq 0 ]; then
      systemctl --no-pager --plain is-system-running >/dev/null 2>&1 || fail systemd-soak-running
    fi
    soak_i=$((soak_i + 1))
  done
  soak_uptime1="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
  soak_intr1="$(intr_sum)"
  echo "__NEMU_CHECK_SOAK_UPTIME__:$soak_uptime0->$soak_uptime1"
  echo "__NEMU_CHECK_INTERRUPTS__:$soak_intr0->$soak_intr1"
  [ "$soak_uptime1" -gt "$soak_uptime0" ] 2>/dev/null && pass soak-uptime || fail soak-uptime
  [ "$soak_intr1" -ge "$soak_intr0" ] 2>/dev/null && pass interrupts-stat-monotonic || fail interrupts-stat-monotonic
else
  echo "__NEMU_CHECK_SOAK_SKIP__"
fi

rm -rf "$check_dir"

bad_dmesg="$(dmesg | grep -i -E 'unhandled signal|illegal instruction|sigill|segfault|kernel panic|oops' | tail -20 || true)"
if [ -z "$bad_dmesg" ]; then
  pass dmesg-no-critical
else
  echo "$bad_dmesg"
  fail dmesg-no-critical
fi

guest_check_uptime1="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
echo "__NEMU_CHECK_GUEST_UPTIME_END__:$guest_check_uptime1"
echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=$check_fail"
if [ "$check_fail" = "0" ] && [ "${NEMU_GUEST_POWEROFF:-1}" != "0" ]; then
  # 检查全部通过后才走 systemd 的真实关机路径；host 侧随后要求
  # OpenSBI/syscon/NEMU 自然退出，避免把强杀当作系统收尾证据。
  echo "__NEMU_SYSTEMD_POWEROFF_BEGIN__"
  sync
  systemctl --no-wall poweroff || poweroff -f || echo "__NEMU_SYSTEMD_POWEROFF_CMD_FAIL__"
fi
GUEST_CMDS
inject_syscall_probe_payload "$LOG_DIR/guest-check.cmd"
inject_uart_rx_stress_commands "$LOG_DIR/guest-check.cmd"

guest_check_start_seconds=$SECONDS
send_guest_commands "$INPUT_DELAY"
wait_for_log_regex "^__NEMU_SYSTEMD_CHECK_DONE__ rc=" "$CHECK_TIMEOUT"
guest_check_seconds=$((SECONDS - guest_check_start_seconds))

if grep -qaF "__NEMU_SYSTEMD_CHECK_DONE__ rc=0" "$CONSOLE_LOG" &&
   ! grep -qaE "^__NEMU_CHECK_FAIL__:" "$CONSOLE_LOG"; then
  poweroff_seconds=0
  if [ "$POWEROFF_ENABLE" != "0" ]; then
    poweroff_start_seconds=$SECONDS
    wait_for_log "__NEMU_SYSTEMD_POWEROFF_BEGIN__" "$POWEROFF_TIMEOUT"
    if wait_for_nemu_exit "$POWEROFF_TIMEOUT"; then
      poweroff_seconds=$((SECONDS - poweroff_start_seconds))
      echo "[nemu-systemd-check] poweroff exit: rc=0 seconds=${poweroff_seconds}"
    else
      fail "NEMU exited with non-zero status during poweroff"
    fi
  fi
  total_seconds=$((SECONDS - host_start_seconds))
  write_perf_log "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds"
  echo "[nemu-systemd-check] PASS"
else
  fail "guest checks reported failure"
fi
