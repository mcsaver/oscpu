#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)

NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
NEMU_PLATFORM_ROOT=${NEMU_PLATFORM_ROOT:-"$ENV_ROOT/platforms/nemu"}
LOG_DIR=${LOG_DIR:-"$NEMU_PLATFORM_ROOT/logs/linux-front/riscv64-nemu-systemd-guest-check"}
LOG_FILE=${LOG_FILE:-"$LOG_DIR/nemu.log"}
CONSOLE_LOG=${CONSOLE_LOG:-"$LOG_DIR/console.log"}
PERF_LOG=${NEMU_SYSTEMD_PERF_LOG:-"$LOG_DIR/perf.tsv"}
SERIAL_FIFO=${NEMU_SERIAL_FIFO:-"$LOG_DIR/nemu.serial"}
GUEST_UPLOAD_CMDS=${NEMU_SYSTEMD_GUEST_UPLOAD_CMDS:-"$LOG_DIR/guest-check-upload.cmd"}
GUEST_SCRIPT_PATH=${NEMU_SYSTEMD_GUEST_SCRIPT_PATH:-"/tmp/nemu-systemd-guest-check.sh"}
GUEST_SCRIPT_B64_PATH=${NEMU_SYSTEMD_GUEST_SCRIPT_B64_PATH:-"/tmp/nemu-systemd-guest-check.sh.b64"}
GUEST_UPLOAD_GROUP_LINES=${NEMU_SYSTEMD_GUEST_UPLOAD_GROUP_LINES:-32}

LINUX_IMAGE=${LINUX_IMAGE:-"$NEMU_PLATFORM_ROOT/build/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$NEMU_PLATFORM_ROOT/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/riscv64-nemu/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$NEMU_PLATFORM_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
RUN_ROOTFS_OVERLAY=${NEMU_SYSTEMD_ROOTFS_OVERLAY-"$LOG_DIR/rootfs-overlay.raw"}
ROOTFS_FLAVOR=${NEMU_SYSTEMD_ROOTFS_FLAVOR:-systemd-minimal}
NET_BACKEND=${NEMU_SYSTEMD_NET_BACKEND:-hostless}
NET_TAP=${NEMU_SYSTEMD_NET_TAP:-}
if [ -n "$NET_TAP" ] && [ -z "${NEMU_SYSTEMD_NET_BACKEND:-}" ]; then
  NET_BACKEND=tap
fi
TAP_IPV4_CIDR=${NEMU_SYSTEMD_TAP_IPV4_CIDR:-}
TAP_GATEWAY=${NEMU_SYSTEMD_TAP_GATEWAY:-}
TAP_DNS=${NEMU_SYSTEMD_TAP_DNS:-}
TAP_PING_TARGET=${NEMU_SYSTEMD_TAP_PING_TARGET:-}
TAP_HTTP_URL=${NEMU_SYSTEMD_TAP_HTTP_URL:-}
TAP_REQUIRE_EXTERNAL=${NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL:-0}
TAP_REQUIRE_PACKETS=${NEMU_SYSTEMD_TAP_REQUIRE_PACKETS:-0}
NEXT_ADDR=${NEXT_ADDR:-0x80200000}
DTB_ADDR=${DTB_ADDR:-0x82200000}
MAX_CYCLES=${MAX_CYCLES:-12000000000}
SYSCALL_PROBE_SRC=${NEMU_SYSTEMD_SYSCALL_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-syscall-probe.c"}
SYSCALL_PROBE_BIN=${NEMU_SYSTEMD_SYSCALL_PROBE_BIN:-"$LOG_DIR/nemu-systemd-syscall-probe.riscv64"}
SYSCALL_PROBE_B64=${NEMU_SYSTEMD_SYSCALL_PROBE_B64:-"$LOG_DIR/nemu-systemd-syscall-probe.b64"}
SYSCALL_PROBE_ENABLE=${NEMU_SYSTEMD_SYSCALL_PROBE:-1}
ICMP_PROBE_SRC=${NEMU_SYSTEMD_ICMP_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-icmp-probe.c"}
ICMP_PROBE_BIN=${NEMU_SYSTEMD_ICMP_PROBE_BIN:-"$LOG_DIR/nemu-systemd-icmp-probe.riscv64"}
ICMP_PROBE_B64=${NEMU_SYSTEMD_ICMP_PROBE_B64:-"$LOG_DIR/nemu-systemd-icmp-probe.b64"}
DEFAULT_NET_PROBE_ENABLE=1
if [ "$NET_BACKEND" = "tap" ]; then
  DEFAULT_NET_PROBE_ENABLE=0
fi
ICMP_PROBE_ENABLE=${NEMU_SYSTEMD_ICMP_PROBE:-$DEFAULT_NET_PROBE_ENABLE}
DHCP_PROBE_SRC=${NEMU_SYSTEMD_DHCP_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-dhcp-probe.c"}
DHCP_PROBE_BIN=${NEMU_SYSTEMD_DHCP_PROBE_BIN:-"$LOG_DIR/nemu-systemd-dhcp-probe.riscv64"}
DHCP_PROBE_B64=${NEMU_SYSTEMD_DHCP_PROBE_B64:-"$LOG_DIR/nemu-systemd-dhcp-probe.b64"}
DHCP_PROBE_ENABLE=${NEMU_SYSTEMD_DHCP_PROBE:-$DEFAULT_NET_PROBE_ENABLE}
DNS_PROBE_SRC=${NEMU_SYSTEMD_DNS_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-dns-probe.c"}
DNS_PROBE_BIN=${NEMU_SYSTEMD_DNS_PROBE_BIN:-"$LOG_DIR/nemu-systemd-dns-probe.riscv64"}
DNS_PROBE_B64=${NEMU_SYSTEMD_DNS_PROBE_B64:-"$LOG_DIR/nemu-systemd-dns-probe.b64"}
DNS_PROBE_ENABLE=${NEMU_SYSTEMD_DNS_PROBE:-$DEFAULT_NET_PROBE_ENABLE}
TCP_PROBE_SRC=${NEMU_SYSTEMD_TCP_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-tcp-probe.c"}
TCP_PROBE_BIN=${NEMU_SYSTEMD_TCP_PROBE_BIN:-"$LOG_DIR/nemu-systemd-tcp-probe.riscv64"}
TCP_PROBE_B64=${NEMU_SYSTEMD_TCP_PROBE_B64:-"$LOG_DIR/nemu-systemd-tcp-probe.b64"}
TCP_PROBE_ENABLE=${NEMU_SYSTEMD_TCP_PROBE:-$DEFAULT_NET_PROBE_ENABLE}
OOMD_PRESSURE_PROBE_SRC=${NEMU_SYSTEMD_OOMD_PRESSURE_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-oomd-pressure-probe.c"}
OOMD_PRESSURE_PROBE_BIN=${NEMU_SYSTEMD_OOMD_PRESSURE_PROBE_BIN:-"$LOG_DIR/nemu-systemd-oomd-pressure-probe.riscv64"}
OOMD_PRESSURE_PROBE_B64=${NEMU_SYSTEMD_OOMD_PRESSURE_PROBE_B64:-"$LOG_DIR/nemu-systemd-oomd-pressure-probe.b64"}
NET_TCP_BURST_LOOPS=${NEMU_SYSTEMD_NET_TCP_BURST_LOOPS:-8}
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
MIN_MEMTOTAL_KB=${NEMU_SYSTEMD_MIN_MEMTOTAL_KB:-900000}
SYSTEMD_RELOAD_TIMEOUT=${NEMU_SYSTEMD_RELOAD_TIMEOUT:-180}
# 默认逐行轻微节流，避免大脚本零间隔灌入 16550 串口 FIFO 时丢命令前缀；
# 需要做串口压力复现时仍可显式设为 0。
INPUT_DELAY=${NEMU_SYSTEMD_INPUT_DELAY:-0.001}
# 一整行命令仍可能超过 16550 RX FIFO；上传阶段已有 guest 侧 sha 校验，
# 因此默认让 8B 分块背靠背发送，必要时可显式加块间节流做保守复现。
# 输入本质仍只是 host 字节流，不是直接传给 Ubuntu 的 shell 命令对象。
INPUT_CHUNK_BYTES=${NEMU_SYSTEMD_INPUT_CHUNK_BYTES:-8}
INPUT_CHUNK_DELAY=${NEMU_SYSTEMD_INPUT_CHUNK_DELAY:-0}
APT_INSTALL_DIAG=${NEMU_SYSTEMD_APT_INSTALL_DIAG:-0}
APT_INSTALL_ACTUAL=${NEMU_SYSTEMD_APT_INSTALL_ACTUAL:-0}
APT_INSTALL_DIAG_TIMEOUT=${NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT:-300}
APT_REMOVE_DIAG_TIMEOUT=${NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT:-600}
CRON_JOB_TIMEOUT=${NEMU_SYSTEMD_CRON_JOB_TIMEOUT:-180}
ANACRON_TIMEOUT=${NEMU_SYSTEMD_ANACRON_TIMEOUT:-120}
CALENDAR_TIMER_TIMEOUT=${NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT:-90}
LOCALE_GEN_TIMEOUT=${NEMU_SYSTEMD_LOCALE_GEN_TIMEOUT:-600}
TIMEDATECTL_TIMEOUT=${NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT:-120}
NETWORKD_DHCP_TIMEOUT=${NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT:-90}
NETWORKD_WAIT_ONLINE_TIMEOUT=${NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT:-90}
TIMESYNCD_NTP_TIMEOUT=${NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT:-120}
RESOLVED_DNS_TIMEOUT=${NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT:-90}
OOMD_PRESSURE_TIMEOUT=${NEMU_SYSTEMD_OOMD_PRESSURE_TIMEOUT:-180}
PYTHON_CNF_DIAG_HARD=${NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD:-1}
PYTHON_RE_DIAG_LOOPS=${NEMU_SYSTEMD_PYTHON_RE_DIAG_LOOPS:-20}
STOP_AFTER_SYSTEMCTL_RELOAD_DIAG=${NEMU_SYSTEMD_STOP_AFTER_SYSTEMCTL_RELOAD_DIAG:-0}
if [ "$STOP_AFTER_SYSTEMCTL_RELOAD_DIAG" != "0" ]; then
  SYSCALL_PROBE_ENABLE=${NEMU_SYSTEMD_SYSCALL_PROBE:-0}
  ICMP_PROBE_ENABLE=${NEMU_SYSTEMD_ICMP_PROBE:-0}
  DHCP_PROBE_ENABLE=${NEMU_SYSTEMD_DHCP_PROBE:-0}
  DNS_PROBE_ENABLE=${NEMU_SYSTEMD_DNS_PROBE:-0}
  TCP_PROBE_ENABLE=${NEMU_SYSTEMD_TCP_PROBE:-0}
fi
POWEROFF_ENABLE=${NEMU_SYSTEMD_POWEROFF:-1}
POWEROFF_TIMEOUT=${NEMU_SYSTEMD_POWEROFF_TIMEOUT:-180}
ROOTFS_BYTES=$(stat -c %s "$RUN_ROOTFS" 2>/dev/null || echo 0)
ROOTFS_STAT_BEFORE=$(stat -c '%s:%Y' "$RUN_ROOTFS" 2>/dev/null || echo "$ROOTFS_BYTES:0")
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

build_icmp_probe() {
  [ "$ICMP_PROBE_ENABLE" = "0" ] && return
  require_file "$ICMP_PROBE_SRC" "guest ICMP probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$ICMP_PROBE_BIN" "$ICMP_PROBE_SRC" ||
    fail "failed to build guest ICMP probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$ICMP_PROBE_BIN" || true
  fi
  base64 -w 76 "$ICMP_PROBE_BIN" >"$ICMP_PROBE_B64" ||
    fail "failed to encode guest ICMP probe"
}

build_dhcp_probe() {
  [ "$DHCP_PROBE_ENABLE" = "0" ] && return
  require_file "$DHCP_PROBE_SRC" "guest DHCP probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$DHCP_PROBE_BIN" "$DHCP_PROBE_SRC" ||
    fail "failed to build guest DHCP probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$DHCP_PROBE_BIN" || true
  fi
  base64 -w 76 "$DHCP_PROBE_BIN" >"$DHCP_PROBE_B64" ||
    fail "failed to encode guest DHCP probe"
}

build_dns_probe() {
  [ "$DNS_PROBE_ENABLE" = "0" ] && return
  require_file "$DNS_PROBE_SRC" "guest DNS probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$DNS_PROBE_BIN" "$DNS_PROBE_SRC" ||
    fail "failed to build guest DNS probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$DNS_PROBE_BIN" || true
  fi
  base64 -w 76 "$DNS_PROBE_BIN" >"$DNS_PROBE_B64" ||
    fail "failed to encode guest DNS probe"
}

build_tcp_probe() {
  [ "$TCP_PROBE_ENABLE" = "0" ] && return
  require_file "$TCP_PROBE_SRC" "guest TCP probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$TCP_PROBE_BIN" "$TCP_PROBE_SRC" ||
    fail "failed to build guest TCP probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$TCP_PROBE_BIN" || true
  fi
  base64 -w 76 "$TCP_PROBE_BIN" >"$TCP_PROBE_B64" ||
    fail "failed to encode guest TCP probe"
}

build_oomd_pressure_probe() {
  [ "$ROOTFS_FLAVOR" != "full" ] && return
  require_file "$OOMD_PRESSURE_PROBE_SRC" "guest systemd-oomd pressure probe source"
  command -v "$RISCV64_LINUX_GCC" >/dev/null 2>&1 ||
    fail "missing riscv64 guest compiler: $RISCV64_LINUX_GCC"
  command -v base64 >/dev/null 2>&1 || fail "missing host base64"

  "$RISCV64_LINUX_GCC" -O2 -Wall -Werror -o "$OOMD_PRESSURE_PROBE_BIN" "$OOMD_PRESSURE_PROBE_SRC" ||
    fail "failed to build guest systemd-oomd pressure probe"
  if command -v "$RISCV64_LINUX_STRIP" >/dev/null 2>&1; then
    "$RISCV64_LINUX_STRIP" "$OOMD_PRESSURE_PROBE_BIN" || true
  fi
  base64 -w 76 "$OOMD_PRESSURE_PROBE_BIN" >"$OOMD_PRESSURE_PROBE_B64" ||
    fail "failed to encode guest systemd-oomd pressure probe"
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

inject_dhcp_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$DHCP_PROBE_B64" -v enabled="$DHCP_PROBE_ENABLE" '
    /__NEMU_DHCP_PROBE_PAYLOAD__/ {
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

inject_dns_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$DNS_PROBE_B64" -v enabled="$DNS_PROBE_ENABLE" '
    /__NEMU_DNS_PROBE_PAYLOAD__/ {
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

inject_tcp_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$TCP_PROBE_B64" -v enabled="$TCP_PROBE_ENABLE" '
    /__NEMU_TCP_PROBE_PAYLOAD__/ {
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

inject_icmp_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$ICMP_PROBE_B64" -v enabled="$ICMP_PROBE_ENABLE" '
    /__NEMU_ICMP_PROBE_PAYLOAD__/ {
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

inject_oomd_pressure_probe_payload() {
  local cmd_file=$1
  local tmp_file="$cmd_file.tmp"
  awk -v payload="$OOMD_PRESSURE_PROBE_B64" -v flavor="$ROOTFS_FLAVOR" '
    /__NEMU_OOMD_PRESSURE_PROBE_PAYLOAD__/ {
      if (flavor == "full") {
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

read_guest_done_rc() {
  local rc
  rc="$(
    sed -n \
      -e 's/\r$//' \
      -e 's/^__NEMU_SYSTEMD_CHECK_DONE__ rc=\([0-9][0-9]*\)$/\1/p' \
      "$CONSOLE_LOG" | tail -n 1
  )"
  if [ -z "$rc" ]; then
    fail "missing complete guest check rc marker"
  fi
  printf '%s\n' "$rc"
}

read_nemu_login_done_rc() {
  local rc
  rc="$(
    sed -n \
      -e 's/\r$//' \
      -e 's/^__NEMU_LOGIN_CHECK_DONE__ rc=\([0-9][0-9]*\)$/\1/p' \
      "$CONSOLE_LOG" | tail -n 1
  )"
  if [ -z "$rc" ]; then
    fail "missing complete NEMU serial login rc marker"
  fi
  printf '%s\n' "$rc"
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

check_console_absent() {
  local label=$1
  local pattern=$2
  if grep -qaE "$pattern" "$CONSOLE_LOG"; then
    echo "[nemu-systemd-check] FAIL console-clean-$label: $pattern" >&2
    grep -aE "$pattern" "$CONSOLE_LOG" | tail -20 >&2 || true
    return 1
  fi
  echo "[nemu-systemd-check] PASS console-clean-$label"
}

check_console_clean() {
  local failed=0
  # 这些是近期真实启动日志里修过的噪声/错误模式。放到 host 侧扫
  # console，避免 guest 内 dmesg 检查漏掉构建层或 early boot 层回归。
  check_console_absent jobserver 'jobserver unavailable' || failed=1
  check_console_absent autofs4 "Failed to look up module alias 'autofs4'|autofs4.*Function not implemented" || failed=1
  check_console_absent bpf-cgroup 'does not support BPF/cgroup firewalling|unit configures an IP firewall' || failed=1
  check_console_absent riscv-isa-fallback 'Falling back to deprecated "riscv,isa"|Unable to find "riscv,isa"' || failed=1
  check_console_absent panic 'Kernel panic' || failed=1
  check_console_absent oops 'Oops' || failed=1
  check_console_absent call-trace 'Call Trace' || failed=1
  check_console_absent bad-trap 'HIT BAD TRAP' || failed=1
  check_console_absent ext4-error 'EXT4-fs error' || failed=1
  check_console_absent io-error 'I/O error' || failed=1
  return "$failed"
}

check_efi_boot_path_context() {
  local has_efi_message=0
  if grep -qaF "efi: UEFI not found" "$CONSOLE_LOG" ||
     grep -qaF "EFI services will not be available" "$CONSOLE_LOG"; then
    has_efi_message=1
  fi

  if [ "$has_efi_message" -eq 0 ]; then
    echo "[nemu-systemd-check] PASS efi-dtb-boot-message-absent"
    return 0
  fi

  # 当前 NEMU Ubuntu 路线由 OpenSBI 通过 DTB handoff Linux，不提供 UEFI
  # firmware。只有同时看到 SBI/OF/command line 上下文时，才把 EFI 缺失
  # 消息归为预期启动路径，避免把真正的早期启动断链误判成良性噪声。
  if grep -qaF "OpenSBI" "$CONSOLE_LOG" &&
     grep -qaF "Machine model: YSYX NPC RV64" "$CONSOLE_LOG" &&
     grep -qaF "SBI specification" "$CONSOLE_LOG" &&
     grep -qaF "OF: reserved mem" "$CONSOLE_LOG" &&
     grep -qaF "Kernel command line: console=ttyS0,115200n8 root=/dev/vda" "$CONSOLE_LOG"; then
    echo "[nemu-systemd-check] PASS efi-dtb-boot-benign"
    grep -aE "efi: UEFI not found|EFI services will not be available|OpenSBI|Machine model: YSYX NPC RV64|SBI specification|OF: reserved mem|Kernel command line" "$CONSOLE_LOG" | head -20 || true
    return 0
  fi

  echo "[nemu-systemd-check] FAIL efi-message-without-opensbi-dtb-context" >&2
  grep -aE "efi: UEFI not found|EFI services will not be available|OpenSBI|Machine model: YSYX NPC RV64|SBI specification|OF: reserved mem|Kernel command line" "$CONSOLE_LOG" | head -40 >&2 || true
  return 1
}

check_shutdown_watchdog_notify() {
  local pattern='systemd-journald\[[0-9]+\]: Failed to send WATCHDOG=1 notification message: Connection refused'
  if ! grep -qaE "$pattern" "$CONSOLE_LOG"; then
    echo "[nemu-systemd-check] PASS shutdown-watchdog-notify-absent"
    return 0
  fi

  # journald 在 systemd 关机收尾阶段可能还会发送 WATCHDOG=1；此时 notify
  # socket 已退出会返回 Connection refused。只有同时看到完整 poweroff 链路时
  # 才把它归类为非致命收尾噪声，避免掩盖运行期 notify/socket 异常。
  if grep -qaF "System Power Off" "$CONSOLE_LOG" &&
     grep -qaF "reboot: Power down" "$CONSOLE_LOG" &&
     grep -qaF "syscon-reset: poweroff requested" "$CONSOLE_LOG" &&
     grep -qaF "HIT GOOD TRAP" "$CONSOLE_LOG"; then
    echo "[nemu-systemd-check] PASS shutdown-watchdog-notify-benign"
    grep -aE "$pattern" "$CONSOLE_LOG" | tail -5 || true
    return 0
  fi

  echo "[nemu-systemd-check] FAIL shutdown-watchdog-notify-without-clean-poweroff" >&2
  grep -aE "$pattern|System Power Off|reboot: Power down|syscon-reset: poweroff requested|HIT GOOD TRAP" "$CONSOLE_LOG" | tail -20 >&2 || true
  return 1
}

check_nemu_async_runtime() {
  local line submitted completed pending done
  line=$(grep -aE 'virtio-blk async runtime submitted=[0-9]+ completed=[0-9]+ pending=[0-9]+ done=[0-9]+' "$LOG_FILE" "$CONSOLE_LOG" 2>/dev/null | tail -1 || true)
  if [ -z "$line" ]; then
    fail "missing virtio-blk async runtime statistic in $LOG_FILE or $CONSOLE_LOG"
  fi
  submitted=$(printf '%s\n' "$line" | sed -n 's/.*submitted=\([0-9][0-9]*\).*/\1/p')
  completed=$(printf '%s\n' "$line" | sed -n 's/.*completed=\([0-9][0-9]*\).*/\1/p')
  pending=$(printf '%s\n' "$line" | sed -n 's/.*pending=\([0-9][0-9]*\).*/\1/p')
  done=$(printf '%s\n' "$line" | sed -n 's/.*done=\([0-9][0-9]*\).*/\1/p')
  echo "[nemu-systemd-check] virtio-blk async runtime: submitted=$submitted completed=$completed pending=$pending done=$done"
  if [ "$submitted" -gt 0 ] &&
     [ "$completed" -eq "$submitted" ] &&
     [ "$pending" -eq 0 ] &&
     [ "$done" -eq 0 ]; then
    echo "[nemu-systemd-check] PASS virtio-blk-async-runtime"
  else
    fail "virtio-blk async runtime counters invalid: submitted=$submitted completed=$completed pending=$pending done=$done"
  fi
}

check_nemu_net_runtime() {
  local line tx_packets rx_packets tx_errors rx_drops rx_pending
  local arp_req arp_rep icmp_req icmp_rep dhcp_req dhcp_rep dns_req dns_rep
  local ntp_req ntp_rep
  local tcp_segments tcp_replies tcp_http_requests tcp_http_head_requests tcp_http_not_found
  local tcp_http_apt_requests tcp_http_apt_deb_requests
  local tcp_http_large_requests tcp_http_segmented_responses tcp_http_response_segments
  local ctrl_commands ctrl_errors ctrl_rx_commands ctrl_rx_extra_commands
  local ctrl_mac_table_commands ctrl_mac_addr_commands ctrl_vlan_commands ctrl_announce_commands
  local tap_tx_packets tap_tx_bytes tap_tx_errors tap_rx_packets tap_rx_bytes tap_rx_errors
  line=$(grep -aE 'virtio-net runtime tx_packets=[0-9]+' "$LOG_FILE" "$CONSOLE_LOG" 2>/dev/null | tail -1 || true)
  if [ -z "$line" ]; then
    fail "missing virtio-net runtime statistic in $LOG_FILE or $CONSOLE_LOG"
  fi

  tx_packets=$(printf '%s\n' "$line" | sed -n 's/.*tx_packets=\([0-9][0-9]*\).*/\1/p')
  rx_packets=$(printf '%s\n' "$line" | sed -n 's/.*rx_packets=\([0-9][0-9]*\).*/\1/p')
  tx_errors=$(printf '%s\n' "$line" | sed -n 's/.*tx_errors=\([0-9][0-9]*\).*/\1/p')
  rx_drops=$(printf '%s\n' "$line" | sed -n 's/.*rx_drops=\([0-9][0-9]*\).*/\1/p')
  rx_pending=$(printf '%s\n' "$line" | sed -n 's/.*rx_pending=\([0-9][0-9]*\).*/\1/p')
  arp_req=$(printf '%s\n' "$line" | sed -n 's/.*arp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  arp_rep=$(printf '%s\n' "$line" | sed -n 's/.*arp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  icmp_req=$(printf '%s\n' "$line" | sed -n 's/.*icmp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  icmp_rep=$(printf '%s\n' "$line" | sed -n 's/.*icmp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  dhcp_req=$(printf '%s\n' "$line" | sed -n 's/.*dhcp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  dhcp_rep=$(printf '%s\n' "$line" | sed -n 's/.*dhcp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  dns_req=$(printf '%s\n' "$line" | sed -n 's/.*dns=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  dns_rep=$(printf '%s\n' "$line" | sed -n 's/.*dns=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  ntp_req=$(printf '%s\n' "$line" | sed -n 's/.*ntp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  ntp_rep=$(printf '%s\n' "$line" | sed -n 's/.*ntp=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  tcp_segments=$(printf '%s\n' "$line" | sed -n 's/.*tcp_segments=\([0-9][0-9]*\).*/\1/p')
  tcp_replies=$(printf '%s\n' "$line" | sed -n 's/.*tcp_replies=\([0-9][0-9]*\).*/\1/p')
  tcp_http_requests=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_requests=\([0-9][0-9]*\).*/\1/p')
  tcp_http_head_requests=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_head_requests=\([0-9][0-9]*\).*/\1/p')
  tcp_http_not_found=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_not_found=\([0-9][0-9]*\).*/\1/p')
  tcp_http_apt_requests=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_apt_requests=\([0-9][0-9]*\).*/\1/p')
  tcp_http_apt_deb_requests=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_apt_deb_requests=\([0-9][0-9]*\).*/\1/p')
  tcp_http_large_requests=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_large_requests=\([0-9][0-9]*\).*/\1/p')
  tcp_http_segmented_responses=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_segmented_responses=\([0-9][0-9]*\).*/\1/p')
  tcp_http_response_segments=$(printf '%s\n' "$line" | sed -n 's/.*tcp_http_response_segments=\([0-9][0-9]*\).*/\1/p')
  ctrl_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  ctrl_errors=$(printf '%s\n' "$line" | sed -n 's/.*ctrl=\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  ctrl_rx_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_rx=\([0-9][0-9]*\).*/\1/p')
  ctrl_rx_extra_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_rx_extra=\([0-9][0-9]*\).*/\1/p')
  ctrl_mac_table_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_mac_table=\([0-9][0-9]*\).*/\1/p')
  ctrl_mac_addr_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_mac_addr=\([0-9][0-9]*\).*/\1/p')
  ctrl_vlan_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_vlan=\([0-9][0-9]*\).*/\1/p')
  ctrl_announce_commands=$(printf '%s\n' "$line" | sed -n 's/.*ctrl_announce=\([0-9][0-9]*\).*/\1/p')
  tap_tx_packets=$(printf '%s\n' "$line" | sed -n 's/.*tap_tx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  tap_tx_bytes=$(printf '%s\n' "$line" | sed -n 's/.*tap_tx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  tap_tx_errors=$(printf '%s\n' "$line" | sed -n 's/.*tap_tx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\3/p')
  tap_rx_packets=$(printf '%s\n' "$line" | sed -n 's/.*tap_rx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\1/p')
  tap_rx_bytes=$(printf '%s\n' "$line" | sed -n 's/.*tap_rx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\2/p')
  tap_rx_errors=$(printf '%s\n' "$line" | sed -n 's/.*tap_rx=\([0-9][0-9]*\)\/\([0-9][0-9]*\)\/\([0-9][0-9]*\).*/\3/p')
  tx_packets=${tx_packets:-0}
  rx_packets=${rx_packets:-0}
  tx_errors=${tx_errors:-0}
  rx_drops=${rx_drops:-0}
  rx_pending=${rx_pending:-0}
  arp_req=${arp_req:-0}
  arp_rep=${arp_rep:-0}
  icmp_req=${icmp_req:-0}
  icmp_rep=${icmp_rep:-0}
  dhcp_req=${dhcp_req:-0}
  dhcp_rep=${dhcp_rep:-0}
  dns_req=${dns_req:-0}
  dns_rep=${dns_rep:-0}
  ntp_req=${ntp_req:-0}
  ntp_rep=${ntp_rep:-0}
  tcp_segments=${tcp_segments:-0}
  tcp_replies=${tcp_replies:-0}
  tcp_http_requests=${tcp_http_requests:-0}
  tcp_http_head_requests=${tcp_http_head_requests:-0}
  tcp_http_not_found=${tcp_http_not_found:-0}
  tcp_http_apt_requests=${tcp_http_apt_requests:-0}
  tcp_http_apt_deb_requests=${tcp_http_apt_deb_requests:-0}
  tcp_http_large_requests=${tcp_http_large_requests:-0}
  tcp_http_segmented_responses=${tcp_http_segmented_responses:-0}
  tcp_http_response_segments=${tcp_http_response_segments:-0}
  ctrl_commands=${ctrl_commands:-0}
  ctrl_errors=${ctrl_errors:-0}
  ctrl_rx_commands=${ctrl_rx_commands:-0}
  ctrl_rx_extra_commands=${ctrl_rx_extra_commands:-0}
  ctrl_mac_table_commands=${ctrl_mac_table_commands:-0}
  ctrl_mac_addr_commands=${ctrl_mac_addr_commands:-0}
  ctrl_vlan_commands=${ctrl_vlan_commands:-0}
  ctrl_announce_commands=${ctrl_announce_commands:-0}
  tap_tx_packets=${tap_tx_packets:-0}
  tap_tx_bytes=${tap_tx_bytes:-0}
  tap_tx_errors=${tap_tx_errors:-0}
  tap_rx_packets=${tap_rx_packets:-0}
  tap_rx_bytes=${tap_rx_bytes:-0}
  tap_rx_errors=${tap_rx_errors:-0}

  echo "[nemu-systemd-check] virtio-net runtime: backend=$NET_BACKEND tap=${NET_TAP:-none} tx=$tx_packets rx=$rx_packets errors=$tx_errors drops=$rx_drops pending=$rx_pending arp=$arp_req/$arp_rep icmp=$icmp_req/$icmp_rep dhcp=$dhcp_req/$dhcp_rep dns=$dns_req/$dns_rep ntp=$ntp_req/$ntp_rep tcp=$tcp_segments/$tcp_replies http=$tcp_http_requests head=$tcp_http_head_requests not_found=$tcp_http_not_found apt=$tcp_http_apt_requests apt_deb=$tcp_http_apt_deb_requests large=$tcp_http_large_requests segmented=$tcp_http_segmented_responses segments=$tcp_http_response_segments tap_tx=$tap_tx_packets/$tap_tx_bytes/$tap_tx_errors tap_rx=$tap_rx_packets/$tap_rx_bytes/$tap_rx_errors ctrl=$ctrl_commands/$ctrl_errors ctrl_rx=$ctrl_rx_commands ctrl_rx_extra=$ctrl_rx_extra_commands ctrl_mac_table=$ctrl_mac_table_commands ctrl_mac_addr=$ctrl_mac_addr_commands ctrl_vlan=$ctrl_vlan_commands ctrl_announce=$ctrl_announce_commands"
  if [ "$NET_BACKEND" = "tap" ]; then
    if ! grep -aFq "virtio-net: TAP backend attached ifname=$NET_TAP" "$LOG_FILE" "$CONSOLE_LOG" 2>/dev/null; then
      fail "missing TAP backend attached log for $NET_TAP"
    fi
    if [ "$tx_errors" -eq 0 ] &&
       [ "$tap_tx_errors" -eq 0 ] &&
       [ "$tap_rx_errors" -eq 0 ] &&
       { [ "$TAP_REQUIRE_PACKETS" = "0" ] || {
         [ "$tap_tx_packets" -gt 0 ] &&
         [ "$tap_rx_packets" -gt 0 ]; }; }; then
      echo "[nemu-systemd-check] PASS virtio-net-runtime"
    else
      fail "virtio-net TAP runtime counters invalid: $line"
    fi
  elif [ "$tx_packets" -gt 0 ] &&
     [ "$rx_packets" -gt 0 ] &&
     [ "$tx_errors" -eq 0 ] &&
     [ "$rx_drops" -eq 0 ] &&
     [ "$rx_pending" -eq 0 ] &&
     [ "$arp_rep" -gt 0 ] &&
     [ "$icmp_rep" -gt 0 ] &&
     [ "$dhcp_rep" -gt 0 ] &&
     [ "$dns_rep" -gt 0 ] &&
     [ "$tcp_segments" -gt 0 ] &&
     [ "$tcp_replies" -gt 0 ] &&
     [ "$tcp_http_requests" -gt 0 ] &&
     { [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" != "full" ] || {
       [ "$tcp_http_head_requests" -gt 0 ] &&
       [ "$tcp_http_not_found" -gt 0 ] &&
       [ "$tcp_http_apt_requests" -gt 0 ] &&
       [ "$tcp_http_apt_deb_requests" -gt 0 ] &&
       [ "$tcp_http_large_requests" -gt 0 ] &&
       [ "$tcp_http_segmented_responses" -gt 0 ] &&
       [ "$tcp_http_response_segments" -gt 0 ] &&
       [ "$ntp_rep" -gt 0 ]; }; } &&
     [ "$ctrl_commands" -gt 0 ] &&
     [ "$ctrl_errors" -eq 0 ] &&
     [ "$ctrl_rx_commands" -gt 0 ] &&
     [ "$ctrl_mac_table_commands" -gt 0 ] &&
     [ "$ctrl_announce_commands" -gt 0 ]; then
    echo "[nemu-systemd-check] PASS virtio-net-runtime"
  else
    fail "virtio-net runtime counters invalid: $line"
  fi
}

write_perf_log() {
  local boot_seconds=$1
  local guest_check_seconds=$2
  local poweroff_seconds=$3
  local total_seconds=$4
  # 这里记录 host 侧墙钟基线，方便后续 NEMU 设备/解释器优化做同口径 A/B。
  {
    printf 'boot_seconds\tguest_check_seconds\tpoweroff_seconds\ttotal_seconds\tsoak_seconds\tfs_stress_mib\tfs_tree_files\tprocess_loops\tuart_rx_stress_lines\tblock_parallel_jobs\tblock_job_mib\tnet_tcp_burst_loops\tnet_backend\tnet_tap\tinput_chunk_bytes\tinput_chunk_delay\tcron_job_timeout\tanacron_timeout\tcalendar_timer_timeout\tlocale_gen_timeout\ttimedatectl_timeout\tnetworkd_dhcp_timeout\tnetworkd_wait_online_timeout\ttimesyncd_ntp_timeout\tresolved_dns_timeout\toomd_pressure_timeout\tmax_cycles\trootfs_overlay\n'
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds" \
      "$SOAK_SECONDS" "$FS_STRESS_MIB" "$FS_TREE_FILES" "$PROCESS_LOOPS" \
      "$UART_RX_STRESS_LINES" "$BLOCK_PARALLEL_JOBS" "$BLOCK_JOB_MIB" \
      "$NET_TCP_BURST_LOOPS" "$NET_BACKEND" "${NET_TAP:-none}" \
      "$INPUT_CHUNK_BYTES" "$INPUT_CHUNK_DELAY" \
      "$CRON_JOB_TIMEOUT" "$ANACRON_TIMEOUT" "$CALENDAR_TIMER_TIMEOUT" "$LOCALE_GEN_TIMEOUT" \
      "$TIMEDATECTL_TIMEOUT" "$NETWORKD_DHCP_TIMEOUT" "$NETWORKD_WAIT_ONLINE_TIMEOUT" "$TIMESYNCD_NTP_TIMEOUT" "$RESOLVED_DNS_TIMEOUT" \
      "$OOMD_PRESSURE_TIMEOUT" "$MAX_CYCLES" "${RUN_ROOTFS_OVERLAY:-disabled}"
  } >"$PERF_LOG"
  echo "[nemu-systemd-check] perf boot=${boot_seconds}s guest_check=${guest_check_seconds}s poweroff=${poweroff_seconds}s total=${total_seconds}s"
  echo "[nemu-systemd-check] perf log: $PERF_LOG"
}

build_guest_upload_commands() {
  local src_file=$1
  local dst_file=$2
  local script_sha script_bytes upload_group_lines b64_line
  local -a b64_group=()
  local b64_line_count=0
  local upload_group_count=0
  script_sha="$(sha256sum "$src_file" | awk '{print $1}')" ||
    fail "failed to hash guest check script"
  script_bytes="$(wc -c <"$src_file" | tr -d '[:space:]')" ||
    fail "failed to size guest check script"
  upload_group_lines="$GUEST_UPLOAD_GROUP_LINES"

  emit_b64_group() {
    local group_index=$1
    local group_count=$2
    shift 2
    printf "printf '%%s\\\\n'"
    for b64_line in "$@"; do
      printf " '%s'" "$b64_line"
    done
    printf " >> '%s'\n" "$GUEST_SCRIPT_B64_PATH"
    if [ "$group_index" = "1" ] || [ "$((group_index % 16))" = "0" ]; then
      printf 'echo "__NEMU_GUEST_UPLOAD_GROUP__:%s:%s"\n' "$group_index" "$group_count"
    fi
  }

  {
    printf 'stty -echo -ixon -ixoff 2>/dev/null || true\n'
    printf 'PS1=; PS2=; PS4=; export PS1 PS2 PS4\n'
    printf 'echo "__NEMU_GUEST_UPLOAD_BEGIN__"\n'
    printf 'echo "__NEMU_GUEST_UPLOAD_MODE__:append-lines:%s"\n' "$upload_group_lines"
    printf ": > '%s'\n" "$GUEST_SCRIPT_B64_PATH"
    while IFS= read -r b64_line || [ -n "$b64_line" ]; do
      b64_group+=("$b64_line")
      b64_line_count=$((b64_line_count + 1))
      if [ "${#b64_group[@]}" -ge "$upload_group_lines" ]; then
        upload_group_count=$((upload_group_count + 1))
        emit_b64_group "$upload_group_count" "$b64_line_count" "${b64_group[@]}"
        b64_group=()
      fi
    done < <(base64 -w 76 "$src_file")
    if [ "${#b64_group[@]}" -gt 0 ]; then
      upload_group_count=$((upload_group_count + 1))
      emit_b64_group "$upload_group_count" "$b64_line_count" "${b64_group[@]}"
    fi
    printf 'echo "__NEMU_GUEST_UPLOAD_APPEND_DONE__:%s:%s"\n' \
      "$upload_group_count" "$b64_line_count"
    printf 'if ! command -v base64 >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then\n'
    printf '  echo "__NEMU_GUEST_SCRIPT_TOOL_MISSING__"\n'
    printf '  echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=1"\n'
    printf "elif ! base64 -d '%s' > '%s'; then\n" "$GUEST_SCRIPT_B64_PATH" "$GUEST_SCRIPT_PATH"
    printf '  echo "__NEMU_GUEST_SCRIPT_DECODE_FAIL__"\n'
    printf '  echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=1"\n'
    printf 'else\n'
    printf "  guest_script_sha=\"\$(sha256sum '%s' 2>/dev/null)\"\n" "$GUEST_SCRIPT_PATH"
    printf '  guest_script_sha="${guest_script_sha%%%% *}"\n'
    printf "  guest_script_bytes=\"\$(wc -c < '%s' 2>/dev/null || echo 0)\"\n" "$GUEST_SCRIPT_PATH"
    printf "  echo \"__NEMU_GUEST_SCRIPT_BYTES__:\$guest_script_bytes/%s\"\n" "$script_bytes"
    printf "  echo \"__NEMU_GUEST_SCRIPT_SHA256__:\$guest_script_sha/%s\"\n" "$script_sha"
    printf "  if [ \"\$guest_script_sha\" = '%s' ] && [ \"\$guest_script_bytes\" = '%s' ]; then\n" "$script_sha" "$script_bytes"
    printf '    echo "__NEMU_GUEST_SCRIPT_READY__"\n'
    printf "    sh '%s'\n" "$GUEST_SCRIPT_PATH"
    printf '  else\n'
    printf '    echo "__NEMU_GUEST_SCRIPT_SHA256_FAIL__"\n'
    printf '    echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=1"\n'
    printf '  fi\n'
    printf 'fi\n'
  } >"$dst_file"
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
require_file "$RUN_ROOTFS" "Ubuntu rootfs"
case "$ROOTFS_FLAVOR" in
  systemd-minimal|interactive|full) ;;
  *) fail "unsupported NEMU_SYSTEMD_ROOTFS_FLAVOR=$ROOTFS_FLAVOR" ;;
esac
require_uint "NEMU_SYSTEMD_SOAK_SECONDS" "$SOAK_SECONDS"
require_uint "NEMU_SYSTEMD_FS_STRESS_MIB" "$FS_STRESS_MIB"
require_uint "NEMU_SYSTEMD_FS_TREE_FILES" "$FS_TREE_FILES"
require_uint "NEMU_SYSTEMD_PROCESS_LOOPS" "$PROCESS_LOOPS"
require_uint "NEMU_SYSTEMD_UART_RX_STRESS_LINES" "$UART_RX_STRESS_LINES"
require_uint "NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS" "$BLOCK_PARALLEL_JOBS"
require_uint "NEMU_SYSTEMD_BLOCK_JOB_MIB" "$BLOCK_JOB_MIB"
require_uint "NEMU_SYSTEMD_MIN_MEMTOTAL_KB" "$MIN_MEMTOTAL_KB"
require_uint "NEMU_SYSTEMD_RELOAD_TIMEOUT" "$SYSTEMD_RELOAD_TIMEOUT"
require_uint "NEMU_SYSTEMD_INPUT_CHUNK_BYTES" "$INPUT_CHUNK_BYTES"
require_uint "NEMU_SYSTEMD_GUEST_UPLOAD_GROUP_LINES" "$GUEST_UPLOAD_GROUP_LINES"
require_nonnegative_decimal "NEMU_SYSTEMD_INPUT_DELAY" "$INPUT_DELAY"
require_nonnegative_decimal "NEMU_SYSTEMD_INPUT_CHUNK_DELAY" "$INPUT_CHUNK_DELAY"
[ "$GUEST_UPLOAD_GROUP_LINES" -gt 0 ] ||
  fail "NEMU_SYSTEMD_GUEST_UPLOAD_GROUP_LINES must be positive: $GUEST_UPLOAD_GROUP_LINES"
require_uint "NEMU_SYSTEMD_APT_INSTALL_DIAG" "$APT_INSTALL_DIAG"
require_uint "NEMU_SYSTEMD_APT_INSTALL_ACTUAL" "$APT_INSTALL_ACTUAL"
require_uint "NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT" "$APT_INSTALL_DIAG_TIMEOUT"
require_uint "NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT" "$APT_REMOVE_DIAG_TIMEOUT"
require_uint "NEMU_SYSTEMD_CRON_JOB_TIMEOUT" "$CRON_JOB_TIMEOUT"
require_uint "NEMU_SYSTEMD_ANACRON_TIMEOUT" "$ANACRON_TIMEOUT"
require_uint "NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT" "$CALENDAR_TIMER_TIMEOUT"
require_uint "NEMU_SYSTEMD_LOCALE_GEN_TIMEOUT" "$LOCALE_GEN_TIMEOUT"
require_uint "NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT" "$TIMEDATECTL_TIMEOUT"
require_uint "NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT" "$NETWORKD_DHCP_TIMEOUT"
require_uint "NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT" "$NETWORKD_WAIT_ONLINE_TIMEOUT"
require_uint "NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT" "$TIMESYNCD_NTP_TIMEOUT"
require_uint "NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT" "$RESOLVED_DNS_TIMEOUT"
require_uint "NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD" "$PYTHON_CNF_DIAG_HARD"
require_uint "NEMU_SYSTEMD_PYTHON_RE_DIAG_LOOPS" "$PYTHON_RE_DIAG_LOOPS"
require_uint "NEMU_SYSTEMD_STOP_AFTER_SYSTEMCTL_RELOAD_DIAG" "$STOP_AFTER_SYSTEMCTL_RELOAD_DIAG"
require_uint "NEMU_SYSTEMD_SYSCALL_PROBE" "$SYSCALL_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_ICMP_PROBE" "$ICMP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_DHCP_PROBE" "$DHCP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_DNS_PROBE" "$DNS_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_TCP_PROBE" "$TCP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_NET_TCP_BURST_LOOPS" "$NET_TCP_BURST_LOOPS"
require_uint "NEMU_SYSTEMD_POWEROFF" "$POWEROFF_ENABLE"
require_uint "NEMU_SYSTEMD_POWEROFF_TIMEOUT" "$POWEROFF_TIMEOUT"
require_uint "NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL" "$TAP_REQUIRE_EXTERNAL"
require_uint "NEMU_SYSTEMD_TAP_REQUIRE_PACKETS" "$TAP_REQUIRE_PACKETS"
require_uint "rootfs image size" "$ROOTFS_BYTES"
[ "$SYSTEMD_RELOAD_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_RELOAD_TIMEOUT must be positive: $SYSTEMD_RELOAD_TIMEOUT"
[ "$NET_TCP_BURST_LOOPS" -gt 0 ] ||
  fail "NEMU_SYSTEMD_NET_TCP_BURST_LOOPS must be positive: $NET_TCP_BURST_LOOPS"
[ "$CRON_JOB_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_CRON_JOB_TIMEOUT must be positive: $CRON_JOB_TIMEOUT"
[ "$ANACRON_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_ANACRON_TIMEOUT must be positive: $ANACRON_TIMEOUT"
[ "$CALENDAR_TIMER_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT must be positive: $CALENDAR_TIMER_TIMEOUT"
[ "$TIMEDATECTL_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT must be positive: $TIMEDATECTL_TIMEOUT"
[ "$NETWORKD_DHCP_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT must be positive: $NETWORKD_DHCP_TIMEOUT"
[ "$NETWORKD_WAIT_ONLINE_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT must be positive: $NETWORKD_WAIT_ONLINE_TIMEOUT"
[ "$TIMESYNCD_NTP_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT must be positive: $TIMESYNCD_NTP_TIMEOUT"
[ "$RESOLVED_DNS_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT must be positive: $RESOLVED_DNS_TIMEOUT"

net_backend_args=()
case "$NET_BACKEND" in
  hostless)
    [ -z "$NET_TAP" ] ||
      fail "NEMU_SYSTEMD_NET_BACKEND=hostless conflicts with NEMU_SYSTEMD_NET_TAP=$NET_TAP"
    ;;
  tap)
    [ -n "$NET_TAP" ] ||
      fail "NEMU_SYSTEMD_NET_BACKEND=tap requires NEMU_SYSTEMD_NET_TAP"
    case "$NET_TAP" in
      *[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-]*)
        fail "NEMU_SYSTEMD_NET_TAP contains unsupported char: $NET_TAP"
        ;;
    esac
    net_backend_args=(--net-tap="$NET_TAP")
    ;;
  *)
    fail "unsupported NEMU_SYSTEMD_NET_BACKEND=$NET_BACKEND"
    ;;
esac

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$LOG_FILE" "$PERF_LOG" \
  "$LOG_DIR/guest-check.cmd" "$GUEST_UPLOAD_CMDS" \
  "$SYSCALL_PROBE_BIN" "$SYSCALL_PROBE_B64" \
  "$ICMP_PROBE_BIN" "$ICMP_PROBE_B64" \
  "$DHCP_PROBE_BIN" "$DHCP_PROBE_B64" \
  "$DNS_PROBE_BIN" "$DNS_PROBE_B64" \
  "$TCP_PROBE_BIN" "$TCP_PROBE_B64" \
  "$OOMD_PRESSURE_PROBE_BIN" "$OOMD_PRESSURE_PROBE_B64" "$VDA_HASH_EXPECT"
block_overlay_args=()
if [ -n "$RUN_ROOTFS_OVERLAY" ]; then
  # focused gate 会做真实 fs/block 写压力；overlay 用来保护基准 rootfs 不被测试污染。
  mkdir -p "$(dirname -- "$RUN_ROOTFS_OVERLAY")"
  rm -f "$RUN_ROOTFS_OVERLAY"
  block_overlay_args=(--block-overlay="$RUN_ROOTFS_OVERLAY")
fi
: >"$CONSOLE_LOG"
build_syscall_probe
build_icmp_probe
build_dhcp_probe
build_dns_probe
build_tcp_probe
build_oomd_pressure_probe
build_vda_hash_expectations

echo "[nemu-systemd-check] log dir: $LOG_DIR"
echo "[nemu-systemd-check] serial fifo: $SERIAL_FIFO"
echo "[nemu-systemd-check] guest upload commands: $GUEST_UPLOAD_CMDS"
echo "[nemu-systemd-check] guest upload group lines: $GUEST_UPLOAD_GROUP_LINES"
echo "[nemu-systemd-check] max cycles: $MAX_CYCLES"
echo "[nemu-systemd-check] soak seconds: $SOAK_SECONDS"
echo "[nemu-systemd-check] fs stress MiB: $FS_STRESS_MIB"
echo "[nemu-systemd-check] fs tree files: $FS_TREE_FILES"
echo "[nemu-systemd-check] process loops: $PROCESS_LOOPS"
echo "[nemu-systemd-check] UART RX stress lines: $UART_RX_STRESS_LINES"
echo "[nemu-systemd-check] block parallel jobs: $BLOCK_PARALLEL_JOBS"
echo "[nemu-systemd-check] block job MiB: $BLOCK_JOB_MIB"
echo "[nemu-systemd-check] min MemTotal KiB: $MIN_MEMTOTAL_KB"
echo "[nemu-systemd-check] systemd reload timeout: $SYSTEMD_RELOAD_TIMEOUT"
echo "[nemu-systemd-check] input delay: $INPUT_DELAY"
echo "[nemu-systemd-check] input chunk bytes: $INPUT_CHUNK_BYTES"
echo "[nemu-systemd-check] input chunk delay: $INPUT_CHUNK_DELAY"
echo "[nemu-systemd-check] apt install diag: $APT_INSTALL_DIAG"
echo "[nemu-systemd-check] apt install actual: $APT_INSTALL_ACTUAL"
echo "[nemu-systemd-check] apt install diag timeout: $APT_INSTALL_DIAG_TIMEOUT"
echo "[nemu-systemd-check] apt remove diag timeout: $APT_REMOVE_DIAG_TIMEOUT"
echo "[nemu-systemd-check] cron job timeout: $CRON_JOB_TIMEOUT"
echo "[nemu-systemd-check] anacron timeout: $ANACRON_TIMEOUT"
echo "[nemu-systemd-check] calendar timer timeout: $CALENDAR_TIMER_TIMEOUT"
echo "[nemu-systemd-check] locale-gen timeout: $LOCALE_GEN_TIMEOUT"
echo "[nemu-systemd-check] timedatectl timeout: $TIMEDATECTL_TIMEOUT"
echo "[nemu-systemd-check] networkd DHCP timeout: $NETWORKD_DHCP_TIMEOUT"
echo "[nemu-systemd-check] networkd wait-online timeout: $NETWORKD_WAIT_ONLINE_TIMEOUT"
echo "[nemu-systemd-check] timesyncd NTP timeout: $TIMESYNCD_NTP_TIMEOUT"
echo "[nemu-systemd-check] resolved DNS timeout: $RESOLVED_DNS_TIMEOUT"
echo "[nemu-systemd-check] python/cnf diag hard: $PYTHON_CNF_DIAG_HARD"
echo "[nemu-systemd-check] python re diag loops: $PYTHON_RE_DIAG_LOOPS"
echo "[nemu-systemd-check] virtio blk sync: ${NEMU_VIRTIO_BLK_SYNC:-0}"
echo "[nemu-systemd-check] serial input model: FIFO bytes -> NEMU SerialPort staging -> 16550 RX FIFO -> Linux ttyS0 (stdin disabled by default)"
echo "[nemu-systemd-check] syscall probe: $SYSCALL_PROBE_ENABLE"
echo "[nemu-systemd-check] ICMP probe: $ICMP_PROBE_ENABLE"
echo "[nemu-systemd-check] DHCP probe: $DHCP_PROBE_ENABLE"
echo "[nemu-systemd-check] DNS probe: $DNS_PROBE_ENABLE"
echo "[nemu-systemd-check] TCP probe: $TCP_PROBE_ENABLE"
echo "[nemu-systemd-check] TCP burst loops: $NET_TCP_BURST_LOOPS"
echo "[nemu-systemd-check] net backend: $NET_BACKEND"
echo "[nemu-systemd-check] net tap: ${NET_TAP:-none}"
echo "[nemu-systemd-check] TAP ipv4 cidr: ${TAP_IPV4_CIDR:-none}"
echo "[nemu-systemd-check] TAP gateway: ${TAP_GATEWAY:-none}"
echo "[nemu-systemd-check] TAP dns: ${TAP_DNS:-none}"
echo "[nemu-systemd-check] TAP ping target: ${TAP_PING_TARGET:-none}"
echo "[nemu-systemd-check] TAP http url: ${TAP_HTTP_URL:-none}"
echo "[nemu-systemd-check] TAP require external: $TAP_REQUIRE_EXTERNAL"
echo "[nemu-systemd-check] TAP require packets: $TAP_REQUIRE_PACKETS"
echo "[nemu-systemd-check] poweroff: $POWEROFF_ENABLE"
echo "[nemu-systemd-check] poweroff timeout: $POWEROFF_TIMEOUT"
echo "[nemu-systemd-check] rootfs flavor: $ROOTFS_FLAVOR"
if [ "$SYSCALL_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] syscall probe bytes: $(stat -c %s "$SYSCALL_PROBE_BIN")"
fi
if [ "$ICMP_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] ICMP probe bytes: $(stat -c %s "$ICMP_PROBE_BIN")"
fi
if [ "$DHCP_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] DHCP probe bytes: $(stat -c %s "$DHCP_PROBE_BIN")"
fi
if [ "$DNS_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] DNS probe bytes: $(stat -c %s "$DNS_PROBE_BIN")"
fi
if [ "$TCP_PROBE_ENABLE" != "0" ]; then
  echo "[nemu-systemd-check] TCP probe bytes: $(stat -c %s "$TCP_PROBE_BIN")"
fi
if [ "$ROOTFS_FLAVOR" = "full" ]; then
  echo "[nemu-systemd-check] oomd pressure probe bytes: $(stat -c %s "$OOMD_PRESSURE_PROBE_BIN")"
fi
echo "[nemu-systemd-check] rootfs bytes: $ROOTFS_BYTES"
echo "[nemu-systemd-check] rootfs backing stat: $ROOTFS_STAT_BEFORE"
if [ -n "$RUN_ROOTFS_OVERLAY" ]; then
  echo "[nemu-systemd-check] rootfs overlay: $RUN_ROOTFS_OVERLAY"
else
  echo "[nemu-systemd-check] rootfs overlay: disabled"
fi
echo "[nemu-systemd-check] vda hash window bytes: $VDA_HASH_WINDOW_BYTES"
echo "[nemu-systemd-check] vda hash windows: $VDA_HASH_WINDOW_COUNT"
echo "[nemu-systemd-check] perf log: $PERF_LOG"

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
  "${net_backend_args[@]}" \
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
wait_for_log_regex "^__NEMU_LOGIN_CHECK_DONE__ rc=[0-9]" "$BOOT_TIMEOUT"
login_done_rc="$(read_nemu_login_done_rc)"
echo "[nemu-systemd-check] serial login marker rc: $login_done_rc"
if [ "$login_done_rc" != "0" ]; then
  fail "serial login marker reported failure rc=$login_done_rc"
fi
boot_seconds=$((SECONDS - host_start_seconds))

{
  printf 'NEMU_GUEST_SOAK_SECONDS=%s\n' "$SOAK_SECONDS"
  printf 'NEMU_GUEST_FS_STRESS_MIB=%s\n' "$FS_STRESS_MIB"
  printf 'NEMU_GUEST_FS_TREE_FILES=%s\n' "$FS_TREE_FILES"
  printf 'NEMU_GUEST_PROCESS_LOOPS=%s\n' "$PROCESS_LOOPS"
  printf 'NEMU_GUEST_UART_RX_STRESS_LINES=%s\n' "$UART_RX_STRESS_LINES"
  printf 'NEMU_GUEST_BLOCK_PARALLEL_JOBS=%s\n' "$BLOCK_PARALLEL_JOBS"
  printf 'NEMU_GUEST_BLOCK_JOB_MIB=%s\n' "$BLOCK_JOB_MIB"
  printf 'NEMU_GUEST_MIN_MEMTOTAL_KB=%s\n' "$MIN_MEMTOTAL_KB"
  printf 'NEMU_GUEST_SYSTEMD_RELOAD_TIMEOUT=%s\n' "$SYSTEMD_RELOAD_TIMEOUT"
  printf 'NEMU_GUEST_ROOTFS_FLAVOR=%s\n' "$ROOTFS_FLAVOR"
  printf 'NEMU_GUEST_ROOTFS_BYTES=%s\n' "$ROOTFS_BYTES"
  printf 'NEMU_GUEST_SYSCALL_PROBE=%s\n' "$SYSCALL_PROBE_ENABLE"
  printf 'NEMU_GUEST_ICMP_PROBE=%s\n' "$ICMP_PROBE_ENABLE"
  printf 'NEMU_GUEST_DHCP_PROBE=%s\n' "$DHCP_PROBE_ENABLE"
  printf 'NEMU_GUEST_DNS_PROBE=%s\n' "$DNS_PROBE_ENABLE"
  printf 'NEMU_GUEST_TCP_PROBE=%s\n' "$TCP_PROBE_ENABLE"
  printf 'NEMU_GUEST_NET_TCP_BURST_LOOPS=%s\n' "$NET_TCP_BURST_LOOPS"
  printf 'NEMU_GUEST_NET_BACKEND=%s\n' "$NET_BACKEND"
  printf 'NEMU_GUEST_NET_TAP_IFNAME=%s\n' "$NET_TAP"
  printf 'NEMU_GUEST_TAP_IPV4_CIDR=%s\n' "$TAP_IPV4_CIDR"
  printf 'NEMU_GUEST_TAP_GATEWAY=%s\n' "$TAP_GATEWAY"
  printf 'NEMU_GUEST_TAP_DNS=%s\n' "$TAP_DNS"
  printf 'NEMU_GUEST_TAP_PING_TARGET=%s\n' "$TAP_PING_TARGET"
  printf 'NEMU_GUEST_TAP_HTTP_URL=%s\n' "$TAP_HTTP_URL"
  printf 'NEMU_GUEST_TAP_REQUIRE_EXTERNAL=%s\n' "$TAP_REQUIRE_EXTERNAL"
  printf 'NEMU_GUEST_APT_INSTALL_DIAG=%s\n' "$APT_INSTALL_DIAG"
  printf 'NEMU_GUEST_APT_INSTALL_ACTUAL=%s\n' "$APT_INSTALL_ACTUAL"
  printf 'NEMU_GUEST_APT_INSTALL_DIAG_TIMEOUT=%s\n' "$APT_INSTALL_DIAG_TIMEOUT"
  printf 'NEMU_GUEST_APT_REMOVE_DIAG_TIMEOUT=%s\n' "$APT_REMOVE_DIAG_TIMEOUT"
  printf 'NEMU_GUEST_CRON_JOB_TIMEOUT=%s\n' "$CRON_JOB_TIMEOUT"
  printf 'NEMU_GUEST_ANACRON_TIMEOUT=%s\n' "$ANACRON_TIMEOUT"
  printf 'NEMU_GUEST_CALENDAR_TIMER_TIMEOUT=%s\n' "$CALENDAR_TIMER_TIMEOUT"
  printf 'NEMU_GUEST_LOCALE_GEN_TIMEOUT=%s\n' "$LOCALE_GEN_TIMEOUT"
  printf 'NEMU_GUEST_TIMEDATECTL_TIMEOUT=%s\n' "$TIMEDATECTL_TIMEOUT"
  printf 'NEMU_GUEST_NETWORKD_DHCP_TIMEOUT=%s\n' "$NETWORKD_DHCP_TIMEOUT"
  printf 'NEMU_GUEST_NETWORKD_WAIT_ONLINE_TIMEOUT=%s\n' "$NETWORKD_WAIT_ONLINE_TIMEOUT"
  printf 'NEMU_GUEST_TIMESYNCD_NTP_TIMEOUT=%s\n' "$TIMESYNCD_NTP_TIMEOUT"
  printf 'NEMU_GUEST_RESOLVED_DNS_TIMEOUT=%s\n' "$RESOLVED_DNS_TIMEOUT"
  printf 'NEMU_GUEST_OOMD_PRESSURE_TIMEOUT=%s\n' "$OOMD_PRESSURE_TIMEOUT"
  printf 'NEMU_GUEST_PYTHON_CNF_DIAG_HARD=%s\n' "$PYTHON_CNF_DIAG_HARD"
  printf 'NEMU_GUEST_PYTHON_RE_DIAG_LOOPS=%s\n' "$PYTHON_RE_DIAG_LOOPS"
  printf 'NEMU_GUEST_STOP_AFTER_SYSTEMCTL_RELOAD_DIAG=%s\n' "$STOP_AFTER_SYSTEMCTL_RELOAD_DIAG"
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
check_dir="/root/nemu-systemd-guest-check.d"
guest_check_uptime0="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
echo "__NEMU_CHECK_GUEST_UPTIME_BEGIN__:$guest_check_uptime0"
memtotal_line="$(grep -m 1 '^MemTotal:' /proc/meminfo 2>/dev/null || true)"
memtotal_kb="$(
  while read -r mem_key mem_value _; do
    if [ "$mem_key" = "MemTotal:" ]; then
      echo "$mem_value"
      break
    fi
  done </proc/meminfo 2>/dev/null
)"
case "$memtotal_kb" in
  ''|*[!0-9]*)
    memtotal_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null | head -n 1)"
    case "$memtotal_kb" in
      ''|*[!0-9]*) memtotal_kb=0 ;;
    esac
    ;;
esac
echo "__NEMU_CHECK_MEMTOTAL_LINE__:$memtotal_line"
echo "__NEMU_CHECK_MEMTOTAL_KB__:$memtotal_kb"
echo "__NEMU_CHECK_MIN_MEMTOTAL_KB__:$NEMU_GUEST_MIN_MEMTOTAL_KB"
if [ "$memtotal_kb" -ge "$NEMU_GUEST_MIN_MEMTOTAL_KB" ] 2>/dev/null; then
  pass guest-memtotal-min
else
  fail guest-memtotal-min
fi

# UART RX stress 会注入大段串口输入，关键 hard gate 放在它之前，避免后续命令被输入流截断。
__NEMU_UART_RX_STRESS_COMMANDS__

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
  irq_total=0
  while IFS= read -r irq_line; do
    case "$irq_line" in
      *:*)
        irq_line_total="$(interrupts_line_sum "$irq_line")"
        irq_total=$((irq_total + irq_line_total))
        ;;
    esac
  done </proc/interrupts 2>/dev/null || true
  echo "$irq_total"
}

interrupts_match_sum() {
  irq_pattern="$1"
  irq_total=0
  while IFS= read -r irq_line; do
    if printf '%s\n' "$irq_line" | grep -Eiq "$irq_pattern"; then
      irq_line_total="$(interrupts_line_sum "$irq_line")"
      irq_total=$((irq_total + irq_line_total))
    fi
  done </proc/interrupts 2>/dev/null || true
  echo "$irq_total"
}

interrupts_line_sum() {
  irq_line="$1"
  irq_line_total=0
  set -- $irq_line
  shift || true
  for irq_field in "$@"; do
    case "$irq_field" in
      ''|*[!0-9]*) ;;
      *) irq_line_total=$((irq_line_total + irq_field)) ;;
    esac
  done
  echo "$irq_line_total"
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

full_userland_fail() {
  fail "$1"
  full_userland_ok=0
}

check_full_userland_runtime() {
  echo "__NEMU_CHECK_ROOTFS_FLAVOR__:${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}"
  echo "__NEMU_CHECK_FULL_USERLAND__"
  if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" != "full" ]; then
    echo "__NEMU_CHECK_FULL_USERLAND_SKIP__:${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}"
    pass full-userland-skip
    return
  fi

  full_userland_ok=1
  for full_path in \
    /usr/bin/apt-get \
    /usr/bin/apt-cache \
    /usr/bin/gpgv \
    /bin/journalctl \
    /bin/systemd-machine-id-setup \
    /bin/systemd-sysusers \
    /bin/systemd-tmpfiles \
    /usr/bin/systemd-analyze \
    /usr/bin/systemd-run \
    /usr/bin/systemd-cat \
    /usr/bin/hostnamectl \
    /usr/bin/timedatectl \
    /usr/sbin/netplan \
    /bin/networkctl \
    /bin/loginctl \
    /lib/systemd/systemd-logind \
    /lib/systemd/systemd-networkd \
    /lib/systemd/systemd-networkd-wait-online \
    /lib/systemd/systemd-resolved \
    /lib/systemd/systemd-oomd \
    /usr/bin/oomctl \
    /lib/systemd/systemd-hostnamed \
    /lib/systemd/systemd-timedated \
    /usr/bin/resolvectl \
    /usr/bin/dpkg \
    /usr/bin/dpkg-query \
    /usr/bin/sudo \
    /usr/bin/man \
    /usr/bin/locale \
    /usr/sbin/locale-gen \
    /usr/bin/localedef \
    /usr/bin/curl \
    /usr/bin/wget \
    /usr/bin/logger \
    /usr/bin/ssh \
    /usr/bin/ssh-keygen \
    /usr/bin/dbclient \
    /usr/bin/dropbearconvert \
    /usr/bin/dropbearkey \
    /usr/sbin/sshd \
    /usr/sbin/dropbear \
    /usr/sbin/cron \
    /usr/sbin/anacron \
    /usr/sbin/rsyslogd \
    /usr/sbin/logrotate; do
    full_label=${full_path##*/}
    if [ -x "$full_path" ]; then
      pass "full-userland-command-$full_label"
    else
      full_userland_fail "full-userland-command-$full_label"
    fi
  done

  for full_path_check in \
    "/usr/lib/systemd/user/dbus.socket:full-userland-systemd-user-bus-socket" \
    "/usr/lib/systemd/user/dbus.service:full-userland-systemd-user-bus-service" \
    "/usr/lib/systemd/user/sockets.target.wants/dbus.socket:full-userland-systemd-user-bus-default-socket" \
    "/lib/riscv64-linux-gnu/security/pam_systemd.so:full-userland-pam-systemd-module" \
    "/etc/pam.d/common-session:full-userland-pam-common-session-config"; do
    full_path=${full_path_check%%:*}
    full_label=${full_path_check#*:}
    if [ -e "$full_path" ]; then
      pass "$full_label"
    else
      full_userland_fail "$full_label"
    fi
  done
  full_pam_systemd_module=0
  [ -r /lib/riscv64-linux-gnu/security/pam_systemd.so ] &&
    full_pam_systemd_module=1
  full_pam_common_session_hook=0
  grep -Eq '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_systemd\.so([[:space:]]|$)' \
    /etc/pam.d/common-session 2>/dev/null &&
    full_pam_common_session_hook=1
  echo "__NEMU_CHECK_FULL_PAM_SYSTEMD_MODULE__:$full_pam_systemd_module"
  echo "__NEMU_CHECK_FULL_PAM_COMMON_SESSION_SYSTEMD_HOOK__:$full_pam_common_session_hook"
  if [ "$full_pam_systemd_module" = "1" ] &&
     [ "$full_pam_common_session_hook" = "1" ]; then
    pass full-userland-pam-systemd-session-hook
  else
    full_userland_fail full-userland-pam-systemd-session-hook
  fi
  if [ -x /usr/bin/systemd-analyze ]; then
    pass full-userland-command-systemd-analyze
  else
    full_userland_fail full-userland-command-systemd-analyze
  fi
  if [ -x /lib/systemd/systemd-networkd-wait-online ]; then
    pass full-userland-command-systemd-networkd-wait-online
  else
    full_userland_fail full-userland-command-systemd-networkd-wait-online
  fi

  logind_root_session_xdg=${XDG_SESSION_ID:-}
  logind_start_rc=0
  timeout 30s env SYSTEMD_BUS_TIMEOUT=5s \
    systemctl start systemd-logind.service >/dev/null 2>&1 ||
    logind_start_rc=$?
  logind_active="$(systemctl show --property=ActiveState --value systemd-logind.service 2>/dev/null || true)"
  logind_list_sessions_rc=0
  logind_list_sessions="$(/bin/loginctl list-sessions --no-legend 2>&1)" ||
    logind_list_sessions_rc=$?
  logind_root_session_id=
  logind_root_session_source=
  logind_root_session_name=
  logind_root_session_user=
  logind_root_session_tty=
  logind_root_session_type=
  logind_root_session_class=
  logind_root_session_remote=
  logind_root_session_active=
  logind_root_session_state=
  logind_root_session_scope=
  logind_root_session_tty_ok=0
  logind_root_session_state_ok=0
  logind_root_session_scope_ok=0
  logind_seen_candidates=
  for logind_candidate_id in $logind_root_session_xdg $(printf '%s\n' "$logind_list_sessions" | awk '{print $1}'); do
    [ -n "$logind_candidate_id" ] || continue
    case " $logind_seen_candidates " in
      *" $logind_candidate_id "*) continue ;;
    esac
    logind_seen_candidates="$logind_seen_candidates $logind_candidate_id"
    if ! /bin/loginctl show-session "$logind_candidate_id" >/dev/null 2>&1; then
      continue
    fi
    logind_candidate_name="$(/bin/loginctl show-session --property=Name --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_user="$(/bin/loginctl show-session --property=User --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_tty="$(/bin/loginctl show-session --property=TTY --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_type="$(/bin/loginctl show-session --property=Type --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_class="$(/bin/loginctl show-session --property=Class --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_remote="$(/bin/loginctl show-session --property=Remote --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_active="$(/bin/loginctl show-session --property=Active --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_state="$(/bin/loginctl show-session --property=State --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_scope="$(/bin/loginctl show-session --property=Scope --value "$logind_candidate_id" 2>/dev/null || true)"
    logind_candidate_tty_ok=0
    case "$logind_candidate_tty" in
      ttyS0|/dev/ttyS0) logind_candidate_tty_ok=1 ;;
    esac
    if [ "$logind_candidate_name" = "root" ] &&
       [ "$logind_candidate_user" = "0" ] &&
       [ "$logind_candidate_type" = "tty" ] &&
       [ "$logind_candidate_class" = "user" ] &&
       [ "$logind_candidate_remote" = "no" ] &&
       [ "$logind_candidate_tty_ok" = "1" ]; then
      logind_root_session_id=$logind_candidate_id
      logind_root_session_source=list-sessions
      [ "$logind_candidate_id" = "$logind_root_session_xdg" ] &&
        logind_root_session_source=xdg-session-id
      logind_root_session_name=$logind_candidate_name
      logind_root_session_user=$logind_candidate_user
      logind_root_session_tty=$logind_candidate_tty
      logind_root_session_type=$logind_candidate_type
      logind_root_session_class=$logind_candidate_class
      logind_root_session_remote=$logind_candidate_remote
      logind_root_session_active=$logind_candidate_active
      logind_root_session_state=$logind_candidate_state
      logind_root_session_scope=$logind_candidate_scope
      logind_root_session_tty_ok=$logind_candidate_tty_ok
      break
    fi
  done
  case "$logind_root_session_state" in
    active|online) logind_root_session_state_ok=1 ;;
  esac
  case "$logind_root_session_scope" in
    session-*.scope) logind_root_session_scope_ok=1 ;;
  esac
  logind_list_seats_rc=0
  logind_list_seats="$(/bin/loginctl list-seats --no-legend 2>&1)" ||
    logind_list_seats_rc=$?
  logind_seat0_seen=0
  printf '%s\n' "$logind_list_seats" | awk '{print $1}' | grep -Fxq seat0 &&
    logind_seat0_seen=1
  logind_seat0_status_rc=0
  logind_seat0_status="$(/bin/loginctl seat-status seat0 2>&1)" ||
    logind_seat0_status_rc=$?
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_XDG__:$logind_root_session_xdg"
  echo "__NEMU_CHECK_FULL_LOGIND_START_RC__:$logind_start_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_ACTIVE__:$logind_active"
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SESSIONS_RC__:$logind_list_sessions_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SESSIONS_BEGIN__"
  printf '%s\n' "$logind_list_sessions" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SESSIONS_END__"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_ID__:$logind_root_session_id"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_SOURCE__:$logind_root_session_source"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_NAME__:$logind_root_session_name"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_USER__:$logind_root_session_user"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_TTY__:$logind_root_session_tty"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_TTY_OK__:$logind_root_session_tty_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_TYPE__:$logind_root_session_type"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_CLASS__:$logind_root_session_class"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_REMOTE__:$logind_root_session_remote"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_ACTIVE__:$logind_root_session_active"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_STATE__:$logind_root_session_state"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_STATE_OK__:$logind_root_session_state_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_SCOPE__:$logind_root_session_scope"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_SESSION_SCOPE_OK__:$logind_root_session_scope_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SEATS_RC__:$logind_list_seats_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_SEAT0_SEEN__:$logind_seat0_seen"
  echo "__NEMU_CHECK_FULL_LOGIND_SEAT0_STATUS_RC__:$logind_seat0_status_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SEATS_BEGIN__"
  printf '%s\n' "$logind_list_seats" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOGIND_LIST_SEATS_END__"
  echo "__NEMU_CHECK_FULL_LOGIND_SEAT0_STATUS_BEGIN__"
  printf '%s\n' "$logind_seat0_status" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_LOGIND_SEAT0_STATUS_END__"
  if [ "$logind_active" = "active" ] &&
     [ "$logind_list_sessions_rc" = "0" ] &&
     [ -n "$logind_root_session_id" ] &&
     [ "$logind_root_session_name" = "root" ] &&
     [ "$logind_root_session_user" = "0" ] &&
     [ "$logind_root_session_tty_ok" = "1" ] &&
     [ "$logind_root_session_type" = "tty" ] &&
     [ "$logind_root_session_class" = "user" ] &&
     [ "$logind_root_session_remote" = "no" ] &&
     [ "$logind_root_session_active" = "yes" ] &&
     [ "$logind_root_session_state_ok" = "1" ] &&
     [ "$logind_root_session_scope_ok" = "1" ] &&
     [ "$logind_list_seats_rc" = "0" ]; then
    pass full-userland-logind-root-serial-session
  else
    systemctl status systemd-logind.service --no-pager 2>/dev/null || true
    journalctl -u systemd-logind.service --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    full_userland_fail full-userland-logind-root-serial-session
  fi

  logind_root_user_runtime_dir=/run/user/0
  logind_root_user_env_runtime_dir=${XDG_RUNTIME_DIR:-}
  logind_root_user_env_runtime_dir_ok=0
  [ "$logind_root_user_env_runtime_dir" = "$logind_root_user_runtime_dir" ] &&
    logind_root_user_env_runtime_dir_ok=1
  logind_root_user_wait_seconds=0
  logind_root_user_manager_active=
  while [ "$logind_root_user_wait_seconds" -lt 60 ]; do
    logind_root_user_manager_active="$(systemctl show --property=ActiveState --value user@0.service 2>/dev/null || true)"
    [ "$logind_root_user_manager_active" = "active" ] && break
    sleep 1
    logind_root_user_wait_seconds=$((logind_root_user_wait_seconds + 1))
  done
  logind_root_user_runtime_owner="$(stat -c '%U:%G:%a:%n' "$logind_root_user_runtime_dir" 2>/dev/null || true)"
  logind_root_user_private_socket=0
  [ -S "$logind_root_user_runtime_dir/systemd/private" ] && logind_root_user_private_socket=1
  logind_root_user_bus_socket=0
  [ -S "$logind_root_user_runtime_dir/bus" ] && logind_root_user_bus_socket=1
  logind_root_user_show_rc=0
  logind_root_user_show="$(/bin/loginctl show-user root --no-pager 2>&1)" ||
    logind_root_user_show_rc=$?
  logind_root_user_name="$(printf '%s\n' "$logind_root_user_show" | sed -n 's/^Name=//p' | sed -n '1p')"
  logind_root_user_uid="$(printf '%s\n' "$logind_root_user_show" | sed -n 's/^UID=//p' | sed -n '1p')"
  logind_root_user_state="$(printf '%s\n' "$logind_root_user_show" | sed -n 's/^State=//p' | sed -n '1p')"
  logind_root_user_runtime_path="$(printf '%s\n' "$logind_root_user_show" | sed -n 's/^RuntimePath=//p' | sed -n '1p')"
  logind_root_user_sessions="$(printf '%s\n' "$logind_root_user_show" | sed -n 's/^Sessions=//p' | sed -n '1p')"
  logind_root_user_state_ok=0
  case "$logind_root_user_state" in
    active|online) logind_root_user_state_ok=1 ;;
  esac
  logind_root_user_session_seen=0
  if [ -n "$logind_root_session_id" ]; then
    case " $logind_root_user_sessions " in
      *" $logind_root_session_id "*) logind_root_user_session_seen=1 ;;
    esac
  fi
  logind_root_user_busctl_rc=0
  logind_root_user_busctl_output="$(
    timeout 30s env \
      XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      busctl --user --no-pager list 2>&1
  )" || logind_root_user_busctl_rc=$?
  logind_root_user_busctl_has_dbus=0
  printf '%s\n' "$logind_root_user_busctl_output" | awk '{print $1}' |
    grep -Fxq org.freedesktop.DBus &&
    logind_root_user_busctl_has_dbus=1
  logind_root_user_busctl_has_systemd=0
  printf '%s\n' "$logind_root_user_busctl_output" | awk '{print $1}' |
    grep -Fxq org.freedesktop.systemd1 &&
    logind_root_user_busctl_has_systemd=1

  logind_root_user_unit=nemu-full-root-user-manager-session.service
  logind_root_user_unit_dir=/root/.config/systemd/user
  logind_root_user_unit_path=$logind_root_user_unit_dir/$logind_root_user_unit
  logind_root_user_output=$logind_root_user_runtime_dir/nemu-full-root-user-manager-session.out
  logind_root_user_cgroup_file=$logind_root_user_runtime_dir/nemu-full-root-user-manager-session.cgroup
  mkdir -p "$logind_root_user_unit_dir"
  rm -f "$logind_root_user_output" "$logind_root_user_cgroup_file"
  cat >"$logind_root_user_unit_path" <<ROOT_USER_MANAGER_UNIT
[Unit]
Description=NEMU full Ubuntu root logind user manager session smoke

[Service]
Type=simple
ExecStart=/bin/sh -c 'cat /proc/self/cgroup > $logind_root_user_cgroup_file; printf root-user-manager-ok > $logind_root_user_output; sleep 120'
ROOT_USER_MANAGER_UNIT
  logind_root_user_reload_rc=0
  logind_root_user_reload_output="$(
    timeout 30s env \
      XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      systemctl --user daemon-reload 2>&1
  )" || logind_root_user_reload_rc=$?
  logind_root_user_start_rc=0
  logind_root_user_start_output="$(
    timeout 30s env \
      XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      systemctl --user start "$logind_root_user_unit" 2>&1
  )" || logind_root_user_start_rc=$?
  logind_root_user_service_wait_seconds=0
  while [ "$logind_root_user_service_wait_seconds" -lt 60 ]; do
    [ "$(cat "$logind_root_user_output" 2>/dev/null || true)" = "root-user-manager-ok" ] && break
    sleep 1
    logind_root_user_service_wait_seconds=$((logind_root_user_service_wait_seconds + 1))
  done
  logind_root_user_service_active="$(
    env XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      systemctl --user show --property=ActiveState --value "$logind_root_user_unit" 2>/dev/null ||
      true
  )"
  logind_root_user_service_control_group="$(
    env XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      systemctl --user show --property=ControlGroup --value "$logind_root_user_unit" 2>/dev/null ||
      true
  )"
  logind_root_user_value="$(cat "$logind_root_user_output" 2>/dev/null || true)"
  logind_root_user_cgroup="$(sed -n 's/^0:://p' "$logind_root_user_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  [ -n "$logind_root_user_cgroup" ] || logind_root_user_cgroup=$logind_root_user_service_control_group
  logind_root_user_cgroup_ok=0
  case "$logind_root_user_cgroup" in
    "/user.slice/user-0.slice/user@0.service/"*) logind_root_user_cgroup_ok=1 ;;
  esac
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_MANAGER_ENV_XDG_RUNTIME_DIR__:$logind_root_user_env_runtime_dir"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_MANAGER_ENV_XDG_RUNTIME_DIR_OK__:$logind_root_user_env_runtime_dir_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_MANAGER_WAIT_SECONDS__:$logind_root_user_wait_seconds"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_MANAGER_ACTIVE__:$logind_root_user_manager_active"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_RUNTIME_DIR__:$logind_root_user_runtime_owner"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_MANAGER_PRIVATE_SOCKET__:$logind_root_user_private_socket"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUS_SOCKET__:$logind_root_user_bus_socket"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SHOW_RC__:$logind_root_user_show_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_NAME__:$logind_root_user_name"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UID__:$logind_root_user_uid"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_STATE__:$logind_root_user_state"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_STATE_OK__:$logind_root_user_state_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_RUNTIME_PATH__:$logind_root_user_runtime_path"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SESSIONS__:$logind_root_user_sessions"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SESSION_SEEN__:$logind_root_user_session_seen"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_RC__:$logind_root_user_busctl_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_HAS_DBUS__:$logind_root_user_busctl_has_dbus"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_HAS_SYSTEMD__:$logind_root_user_busctl_has_systemd"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_RELOAD_RC__:$logind_root_user_reload_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_START_RC__:$logind_root_user_start_rc"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_WAIT_SECONDS__:$logind_root_user_service_wait_seconds"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_ACTIVE__:$logind_root_user_service_active"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_OUTPUT__:$logind_root_user_value"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_CGROUP__:$logind_root_user_cgroup"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_CGROUP_OK__:$logind_root_user_cgroup_ok"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SHOW_BEGIN__"
  printf '%s\n' "$logind_root_user_show" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SHOW_END__"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_BEGIN__"
  printf '%s\n' "$logind_root_user_busctl_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_END__"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_RELOAD_OUTPUT_BEGIN__"
  printf '%s\n' "$logind_root_user_reload_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_RELOAD_OUTPUT_END__"
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_START_OUTPUT_BEGIN__"
  printf '%s\n' "$logind_root_user_start_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOGIND_ROOT_USER_UNIT_START_OUTPUT_END__"
  if [ "$logind_root_user_env_runtime_dir_ok" = "1" ] &&
     [ "$logind_root_user_manager_active" = "active" ] &&
     [ "$logind_root_user_runtime_owner" = "root:root:700:$logind_root_user_runtime_dir" ] &&
     [ "$logind_root_user_private_socket" = "1" ] &&
     [ "$logind_root_user_bus_socket" = "1" ] &&
     [ "$logind_root_user_show_rc" = "0" ] &&
     [ "$logind_root_user_name" = "root" ] &&
     [ "$logind_root_user_uid" = "0" ] &&
     [ "$logind_root_user_state_ok" = "1" ] &&
     [ "$logind_root_user_runtime_path" = "$logind_root_user_runtime_dir" ] &&
     [ "$logind_root_user_session_seen" = "1" ] &&
     [ "$logind_root_user_busctl_rc" = "0" ] &&
     [ "$logind_root_user_busctl_has_dbus" = "1" ] &&
     [ "$logind_root_user_busctl_has_systemd" = "1" ] &&
     [ "$logind_root_user_reload_rc" = "0" ] &&
     [ "$logind_root_user_start_rc" = "0" ] &&
     [ "$logind_root_user_service_active" = "active" ] &&
     [ "$logind_root_user_value" = "root-user-manager-ok" ] &&
     [ "$logind_root_user_cgroup_ok" = "1" ]; then
    pass full-userland-logind-root-user-manager-session
  else
    systemctl status systemd-logind.service user@0.service --no-pager 2>/dev/null || true
    env XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
      systemctl --user status "$logind_root_user_unit" --no-pager 2>/dev/null || true
    journalctl -u systemd-logind.service -u user@0.service --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    full_userland_fail full-userland-logind-root-user-manager-session
  fi
  timeout 30s env \
    XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
    systemctl --user stop "$logind_root_user_unit" >/dev/null 2>&1 || true
  timeout 30s env \
    XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
    systemctl --user reset-failed "$logind_root_user_unit" >/dev/null 2>&1 || true
  rm -f "$logind_root_user_unit_path" "$logind_root_user_output" "$logind_root_user_cgroup_file"
  timeout 30s env \
    XDG_RUNTIME_DIR="$logind_root_user_runtime_dir" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$logind_root_user_runtime_dir/bus" \
    systemctl --user daemon-reload >/dev/null 2>&1 || true

  apt_version="$(apt-get --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_APT_VERSION__:$apt_version"
  if echo "$apt_version" | grep -Eq '^apt [0-9]+'; then
    pass full-userland-apt-version
  else
    full_userland_fail full-userland-apt-version
  fi

  gpgv_version="$(gpgv --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_GPGV_VERSION__:$gpgv_version"
  if echo "$gpgv_version" | grep -Eq '^gpgv '; then
    pass full-userland-gpgv-version
  else
    full_userland_fail full-userland-gpgv-version
  fi

  ubuntu_archive_keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg
  ubuntu_archive_keyring_sha256=
  if [ -r "$ubuntu_archive_keyring" ]; then
    ubuntu_archive_keyring_sha256="$(sha256sum "$ubuntu_archive_keyring" | awk '{print $1}')"
  fi
  echo "__NEMU_CHECK_FULL_APT_KEYRING__:$ubuntu_archive_keyring"
  echo "__NEMU_CHECK_FULL_APT_KEYRING_SHA256__:$ubuntu_archive_keyring_sha256"
  if [ "$ubuntu_archive_keyring_sha256" = "1a4dd63e5c76728960a2edddae22e2e0fc53df8e8b87806deb971030ac704eb0" ]; then
    pass full-userland-apt-archive-keyring
  else
    full_userland_fail full-userland-apt-archive-keyring
  fi

  dpkg_audit_rc=0
  dpkg_audit_output="$(dpkg --audit 2>&1)" || dpkg_audit_rc=$?
  echo "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__:$dpkg_audit_rc"
  echo "__NEMU_CHECK_FULL_DPKG_AUDIT_BEGIN__"
  printf '%s\n' "$dpkg_audit_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_DPKG_AUDIT_END__"
  if [ "$dpkg_audit_rc" = "0" ] && [ -z "$dpkg_audit_output" ]; then
    pass full-userland-dpkg-audit
  else
    full_userland_fail full-userland-dpkg-audit
  fi

  for full_package in systemd ubuntu-standard openssh-client openssh-server openssh-sftp-server curl wget dropbear-bin rsyslog cron anacron logrotate systemd-timesyncd systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring locales libc-bin netplan.io netplan-generator; do
    dpkg_query_rc=0
    dpkg_query_output="$(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' "$full_package" 2>&1)" ||
      dpkg_query_rc=$?
    echo "__NEMU_CHECK_FULL_DPKG_QUERY__:$full_package:$dpkg_query_rc:$dpkg_query_output"
    if [ "$dpkg_query_rc" = "0" ] &&
       echo "$dpkg_query_output" | grep -Eq '^ii[[:space:]]'; then
      pass "full-userland-dpkg-package-$full_package"
    else
      full_userland_fail "full-userland-dpkg-package-$full_package"
    fi
  done

  for ownership in \
    "curl:/usr/bin/curl" \
    "wget:/usr/bin/wget" \
    "openssh-client:/usr/bin/ssh" \
    "openssh-client:/usr/bin/ssh-keygen" \
    "openssh-client:/usr/bin/scp" \
    "openssh-client:/usr/bin/sftp" \
    "openssh-server:/usr/sbin/sshd" \
    "openssh-sftp-server:/usr/lib/openssh/sftp-server" \
    "dropbear-bin:/usr/bin/dbclient" \
    "dropbear-bin:/usr/sbin/dropbear" \
    "rsyslog:/usr/sbin/rsyslogd" \
    "cron:/usr/sbin/cron" \
    "anacron:/usr/sbin/anacron" \
    "anacron:/etc/anacrontab" \
    "anacron:/etc/cron.d/anacron" \
    "anacron:/etc/cron.daily/0anacron" \
    "anacron:/etc/cron.weekly/0anacron" \
    "anacron:/etc/cron.monthly/0anacron" \
    "anacron:/var/spool/anacron" \
    "anacron:/lib/systemd/system/anacron.service" \
    "anacron:/lib/systemd/system/anacron.timer" \
    "logrotate:/usr/sbin/logrotate" \
    "systemd-oomd:/lib/systemd/systemd-oomd" \
    "systemd-oomd:/lib/systemd/system/systemd-oomd.service" \
    "systemd-oomd:/usr/bin/oomctl" \
    "systemd-oomd:/etc/systemd/oomd.conf" \
    "systemd-oomd:/usr/lib/systemd/oomd.conf.d/10-oomd-defaults.conf" \
    "systemd-oomd:/usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf" \
    "systemd-oomd:/usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf" \
    "systemd-oomd:/usr/lib/sysusers.d/systemd-oom.conf" \
    "systemd-oomd:/usr/share/dbus-1/system-services/org.freedesktop.oom1.service" \
    "systemd-oomd:/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf" \
    "locales:/usr/sbin/locale-gen" \
    "locales:/usr/share/i18n/SUPPORTED" \
    "libc-bin:/usr/bin/localedef" \
    "systemd:/bin/journalctl" \
    "systemd:/bin/systemd-machine-id-setup" \
    "systemd:/bin/systemd-sysusers" \
    "systemd:/bin/systemd-tmpfiles" \
    "systemd:/usr/bin/systemd-run" \
    "systemd:/usr/bin/systemd-cat" \
    "systemd:/usr/bin/hostnamectl" \
    "systemd:/usr/bin/timedatectl" \
    "netplan.io:/usr/sbin/netplan" \
    "netplan.io:/usr/share/netplan/netplan.script" \
    "netplan-generator:/etc/netplan" \
    "netplan-generator:/lib/netplan/generate" \
    "netplan-generator:/lib/systemd/system-generators/netplan" \
    "systemd:/bin/networkctl" \
    "systemd:/usr/bin/resolvectl" \
    "systemd:/bin/loginctl" \
    "systemd:/lib/systemd/systemd-logind" \
    "systemd:/lib/systemd/systemd-networkd" \
    "systemd:/lib/systemd/systemd-networkd-wait-online" \
    "systemd:/lib/systemd/systemd-resolved" \
    "systemd:/lib/systemd/systemd-hostnamed" \
    "systemd:/lib/systemd/systemd-timedated" \
    "systemd:/lib/systemd/system/systemd-logind.service" \
    "systemd:/lib/systemd/system/systemd-resolved.service" \
    "systemd:/lib/systemd/system/systemd-machine-id-commit.service" \
    "systemd:/lib/systemd/system/systemd-hostnamed.service" \
    "systemd:/lib/systemd/system/systemd-timedated.service" \
    "systemd:/etc/systemd/resolved.conf" \
    "systemd:/lib/systemd/system/user@.service" \
    "systemd:/lib/systemd/system/user-runtime-dir@.service" \
    "systemd:/lib/systemd/system/systemd-networkd.service" \
    "systemd:/lib/systemd/system/systemd-networkd-wait-online.service" \
    "dbus-user-session:/usr/lib/systemd/user/dbus.socket" \
    "dbus-user-session:/usr/lib/systemd/user/dbus.service" \
    "dbus-user-session:/usr/lib/systemd/user/sockets.target.wants/dbus.socket" \
    "libpam-systemd:/lib/riscv64-linux-gnu/security/pam_systemd.so" \
    "gpgv:/usr/bin/gpgv" \
    "ubuntu-keyring:/usr/share/keyrings/ubuntu-archive-keyring.gpg"; do
    ownership_package=${ownership%%:*}
    ownership_path=${ownership#*:}
    ownership_label="${ownership_package}-${ownership_path##*/}"

    dpkg_list_rc=0
    dpkg_list_output="$(dpkg -L "$ownership_package" 2>&1)" || dpkg_list_rc=$?
    echo "__NEMU_CHECK_FULL_DPKG_LIST__:$ownership_package:$ownership_path:$dpkg_list_rc"
    if [ "$dpkg_list_rc" = "0" ] &&
       printf '%s\n' "$dpkg_list_output" | grep -Fxq "$ownership_path"; then
      pass "full-userland-dpkg-list-$ownership_label"
    else
      printf '%s\n' "$dpkg_list_output" | sed -n '1,40p'
      full_userland_fail "full-userland-dpkg-list-$ownership_label"
    fi

    dpkg_search_rc=0
    dpkg_search_output="$(dpkg -S "$ownership_path" 2>&1)" || dpkg_search_rc=$?
    echo "__NEMU_CHECK_FULL_DPKG_SEARCH__:$ownership_package:$ownership_path:$dpkg_search_rc:$dpkg_search_output"
    if [ "$dpkg_search_rc" = "0" ] &&
       printf '%s\n' "$dpkg_search_output" | grep -Eq "(^|, )${ownership_package}(:[^:[:space:]]+)?: ${ownership_path}$"; then
      pass "full-userland-dpkg-search-$ownership_label"
    else
      full_userland_fail "full-userland-dpkg-search-$ownership_label"
    fi
  done

  apt_policy_rc=0
  apt_policy_output="$(apt-cache policy ubuntu-standard openssh-client openssh-server openssh-sftp-server curl wget dropbear-bin cron anacron rsyslog logrotate systemd-oomd dbus-user-session libpam-systemd gpgv ubuntu-keyring netplan.io netplan-generator locales libc-bin 2>&1)" ||
    apt_policy_rc=$?
  echo "__NEMU_CHECK_FULL_APT_POLICY_RC__:$apt_policy_rc"
  echo "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__"
  printf '%s\n' "$apt_policy_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_APT_POLICY_END__"
  if [ "$apt_policy_rc" = "0" ] &&
     echo "$apt_policy_output" | grep -q 'Installed:'; then
    pass full-userland-apt-policy
  else
    full_userland_fail full-userland-apt-policy
  fi

  sudo_version="$(sudo -V 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_SUDO_VERSION__:$sudo_version"
  if echo "$sudo_version" | grep -Eiq '^Sudo version'; then
    pass full-userland-sudo-version
  else
    full_userland_fail full-userland-sudo-version
  fi
  if sudo -n true >/dev/null 2>&1; then
    pass full-userland-sudo-root
  else
    full_userland_fail full-userland-sudo-root
  fi

  man_version="$(man --version 2>&1 | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_MAN_VERSION__:$man_version"
  if echo "$man_version" | grep -Eiq '(man-db|man )'; then
    pass full-userland-man-version
  else
    full_userland_fail full-userland-man-version
  fi

  locale_charmap="$(locale charmap 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_LOCALE_CHARMAP__:$locale_charmap"
  if [ -n "$locale_charmap" ]; then
    pass full-userland-locale-charmap
  else
    full_userland_fail full-userland-locale-charmap
  fi
  if locale -a 2>/dev/null | grep -Eiq '^(C|C\.utf8|C.UTF-8|POSIX)$'; then
    pass full-userland-locale-list
  else
    locale -a 2>/dev/null || true
    full_userland_fail full-userland-locale-list
  fi

  locale_gen_rc=0
  locale_gen_output=
  locale_gen_conf=/etc/locale.gen
  locale_gen_locale=
  locale_gen_charmap=
  locale_gen_timeout=${NEMU_GUEST_LOCALE_GEN_TIMEOUT:-600}
  if [ -x /usr/sbin/locale-gen ] && [ -x /usr/bin/localedef ] && [ -r /usr/share/i18n/SUPPORTED ]; then
    [ -f "$locale_gen_conf" ] || : >"$locale_gen_conf"
    if grep -Eq '^[#[:space:]]*en_US\.UTF-8[[:space:]]+UTF-8' "$locale_gen_conf"; then
      sed -i 's/^[#[:space:]]*en_US\.UTF-8[[:space:]]\+UTF-8/en_US.UTF-8 UTF-8/' "$locale_gen_conf" || true
    else
      printf '%s\n' 'en_US.UTF-8 UTF-8' >>"$locale_gen_conf"
    fi
    locale_gen_output="$(timeout "${locale_gen_timeout}s" /usr/sbin/locale-gen en_US.UTF-8 2>&1)" || locale_gen_rc=$?
    locale_gen_locale="$(locale -a 2>/dev/null | grep -Eix 'en_US\.utf8|en_US\.UTF-8' | sed -n '1p' || true)"
    locale_gen_charmap="$(LC_ALL=en_US.UTF-8 locale charmap 2>/dev/null || true)"
  else
    locale_gen_rc=127
    locale_gen_output='missing locale-gen/localedef/SUPPORTED'
  fi
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_TIMEOUT__:$locale_gen_timeout"
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_RC__:$locale_gen_rc"
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_LOCALE__:$locale_gen_locale"
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_CHARMAP__:$locale_gen_charmap"
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_OUTPUT_BEGIN__"
  printf '%s\n' "$locale_gen_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOCALE_GEN_OUTPUT_END__"
  if [ "$locale_gen_rc" = "0" ] &&
     [ -n "$locale_gen_locale" ] &&
     echo "$locale_gen_charmap" | grep -Eiq '^UTF-?8$'; then
    pass full-userland-locale-gen-en-us-utf8
  else
    full_userland_fail full-userland-locale-gen-en-us-utf8
  fi

  if [ -f /usr/share/zoneinfo/UTC ]; then
    pass full-userland-tzdata-utc
  else
    full_userland_fail full-userland-tzdata-utc
  fi
  if date -u '+__NEMU_CHECK_FULL_DATE_UTC__:%Y-%m-%dT%H:%M:%SZ'; then
    pass full-userland-date-utc
  else
    full_userland_fail full-userland-date-utc
  fi

  systemd_analyze_timeout=120
  systemd_analyze_version="$(systemd-analyze --version 2>/dev/null | sed -n '1p' || true)"
  systemd_analyze_time_rc=0
  systemd_analyze_time_output="$(
    timeout "${systemd_analyze_timeout}s" systemd-analyze --no-pager time 2>&1
  )" || systemd_analyze_time_rc=$?
  systemd_analyze_time_nonempty=0
  [ -n "$systemd_analyze_time_output" ] && systemd_analyze_time_nonempty=1
  systemd_analyze_time_startup=0
  printf '%s\n' "$systemd_analyze_time_output" | grep -Fq "Startup finished in" &&
    systemd_analyze_time_startup=1
  systemd_analyze_chain_rc=0
  systemd_analyze_chain_output="$(
    timeout "${systemd_analyze_timeout}s" systemd-analyze --no-pager critical-chain multi-user.target 2>&1
  )" || systemd_analyze_chain_rc=$?
  systemd_analyze_chain_nonempty=0
  [ -n "$systemd_analyze_chain_output" ] && systemd_analyze_chain_nonempty=1
  systemd_analyze_chain_target_seen=0
  printf '%s\n' "$systemd_analyze_chain_output" | grep -Fq "multi-user.target" &&
    systemd_analyze_chain_target_seen=1
  systemd_analyze_graphical_chain_rc=0
  systemd_analyze_graphical_chain_output="$(
    timeout "${systemd_analyze_timeout}s" systemd-analyze --no-pager critical-chain graphical.target 2>&1
  )" || systemd_analyze_graphical_chain_rc=$?
  systemd_analyze_graphical_chain_nonempty=0
  [ -n "$systemd_analyze_graphical_chain_output" ] && systemd_analyze_graphical_chain_nonempty=1
  systemd_analyze_graphical_chain_target_seen=0
  printf '%s\n' "$systemd_analyze_graphical_chain_output" | grep -Fq "graphical.target" &&
    systemd_analyze_graphical_chain_target_seen=1
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIMEOUT__:$systemd_analyze_timeout"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_VERSION__:$systemd_analyze_version"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIME_RC__:$systemd_analyze_time_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIME_NONEMPTY__:$systemd_analyze_time_nonempty"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIME_STARTUP_SEEN__:$systemd_analyze_time_startup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIME_BEGIN__"
  printf '%s\n' "$systemd_analyze_time_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_TIME_END__"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_CRITICAL_CHAIN_RC__:$systemd_analyze_chain_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_CRITICAL_CHAIN_NONEMPTY__:$systemd_analyze_chain_nonempty"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_CRITICAL_CHAIN_TARGET_SEEN__:$systemd_analyze_chain_target_seen"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_CRITICAL_CHAIN_BEGIN__"
  printf '%s\n' "$systemd_analyze_chain_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_CRITICAL_CHAIN_END__"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_GRAPHICAL_CRITICAL_CHAIN_RC__:$systemd_analyze_graphical_chain_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_GRAPHICAL_CRITICAL_CHAIN_NONEMPTY__:$systemd_analyze_graphical_chain_nonempty"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_GRAPHICAL_CRITICAL_CHAIN_TARGET_SEEN__:$systemd_analyze_graphical_chain_target_seen"
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_GRAPHICAL_CRITICAL_CHAIN_BEGIN__"
  printf '%s\n' "$systemd_analyze_graphical_chain_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_SYSTEMD_ANALYZE_GRAPHICAL_CRITICAL_CHAIN_END__"
  if echo "$systemd_analyze_version" | grep -Eq '^systemd [0-9]+' &&
     [ "$systemd_analyze_time_rc" = "0" ] &&
     [ "$systemd_analyze_time_nonempty" = "1" ] &&
     [ "$systemd_analyze_time_startup" = "1" ]; then
    pass full-userland-systemd-analyze-time
  else
    full_userland_fail full-userland-systemd-analyze-time
  fi
  if [ "$systemd_analyze_chain_rc" = "0" ] &&
     [ "$systemd_analyze_chain_nonempty" = "1" ] &&
     [ "$systemd_analyze_chain_target_seen" = "1" ]; then
    pass full-userland-systemd-analyze-critical-chain
  else
    full_userland_fail full-userland-systemd-analyze-critical-chain
  fi
  if [ "$systemd_analyze_graphical_chain_rc" = "0" ] &&
     [ "$systemd_analyze_graphical_chain_nonempty" = "1" ] &&
     [ "$systemd_analyze_graphical_chain_target_seen" = "1" ]; then
    pass full-userland-systemd-analyze-graphical-critical-chain
  else
    full_userland_fail full-userland-systemd-analyze-graphical-critical-chain
  fi

  timedatectl_version="$(timedatectl --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_VERSION__:$timedatectl_version"
  if echo "$timedatectl_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-timedatectl-version
  else
    full_userland_fail full-userland-timedatectl-version
  fi

  timedatectl_timeout=${NEMU_GUEST_TIMEDATECTL_TIMEOUT:-120}
  timedated_start_log=/tmp/nemu-full-timedated-start.log
  timedated_start_rc=0
  timeout "${timedatectl_timeout}s" env SYSTEMD_BUS_TIMEOUT=15s \
    systemctl start systemd-timedated.service >"$timedated_start_log" 2>&1 ||
    timedated_start_rc=$?
  timedated_active="$(systemctl show --property=ActiveState --value systemd-timedated.service 2>/dev/null || true)"
  timedatectl_set_rc=0
  timedatectl_set_output="$(
    timeout "${timedatectl_timeout}s" env SYSTEMD_BUS_TIMEOUT=15s \
      timedatectl set-timezone UTC 2>&1
  )" || timedatectl_set_rc=$?
  timedatectl_show_rc=0
  timedatectl_show_output="$(
    timeout "${timedatectl_timeout}s" env SYSTEMD_BUS_TIMEOUT=15s \
      timedatectl show --property=Timezone --value 2>&1
  )" || timedatectl_show_rc=$?
  timedatectl_timezone="$(printf '%s\n' "$timedatectl_show_output" | sed -n '1p')"
  timedatectl_localtime="$(readlink /etc/localtime 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_TIMEOUT__:$timedatectl_timeout"
  echo "__NEMU_CHECK_FULL_TIMEDATED_START_RC__:$timedated_start_rc"
  echo "__NEMU_CHECK_FULL_TIMEDATED_ACTIVE__:$timedated_active"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_SET_TIMEZONE_RC__:$timedatectl_set_rc"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_TIMEZONE_RC__:$timedatectl_show_rc"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_TIMEZONE__:$timedatectl_timezone"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_LOCALTIME__:$timedatectl_localtime"
  echo "__NEMU_CHECK_FULL_TIMEDATED_START_OUTPUT_BEGIN__"
  sed -n '1,80p' "$timedated_start_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_TIMEDATED_START_OUTPUT_END__"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_SET_TIMEZONE_OUTPUT_BEGIN__"
  printf '%s\n' "$timedatectl_set_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_SET_TIMEZONE_OUTPUT_END__"
  if [ "$timedated_start_rc" = "0" ] &&
     [ "$timedatectl_set_rc" = "0" ] &&
     [ "$timedatectl_show_rc" = "0" ] &&
     { [ "$timedatectl_timezone" = "UTC" ] || [ "$timedatectl_timezone" = "Etc/UTC" ]; }; then
    pass full-userland-timedatectl-timezone-utc
  else
    systemctl status systemd-timedated.service --no-pager 2>/dev/null || true
    journalctl -u systemd-timedated.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    full_userland_fail full-userland-timedatectl-timezone-utc
  fi

  networkd_dhcp_timeout=${NEMU_GUEST_NETWORKD_DHCP_TIMEOUT:-90}
  networkd_wait_online_timeout=${NEMU_GUEST_NETWORKD_WAIT_ONLINE_TIMEOUT:-90}
  networkd_dhcp_conf_ok=0
  netplan_conf_ok=0
  netplan_generate_rc=0
  netplan_generated_network_ok=0
  netplan_generated_network=""
  netplan_generate_log=/tmp/nemu-full-netplan-generate.log
  netplan_generated_contents=""
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    netplan_conf_dir=/etc/netplan
    netplan_conf="$netplan_conf_dir/10-nemu-hostless.yaml"
    networkd_dhcp_conf=/run/systemd/network/10-netplan-nemu-hostless.network
    mkdir -p "$netplan_conf_dir"
    rm -f /etc/systemd/network/10-nemu-hostless.network 2>/dev/null || true
    # 用 netplan 生成 networkd 配置，覆盖 Ubuntu server 默认网络配置路径。
    cat >"$netplan_conf" <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    nemu-hostless:
      match:
        macaddress: "52:54:00:12:34:56"
      dhcp4: true
      dhcp6: false
      link-local: []
      dhcp-identifier: mac
EOF
    chmod 600 "$netplan_conf" 2>/dev/null || true
    if grep -Fq 'dhcp4: true' "$netplan_conf" &&
       grep -Fq 'macaddress: "52:54:00:12:34:56"' "$netplan_conf" &&
       grep -Fq 'renderer: networkd' "$netplan_conf"; then
      netplan_conf_ok=1
    fi
    timeout "${networkd_dhcp_timeout}s" /usr/sbin/netplan generate >"$netplan_generate_log" 2>&1 ||
      netplan_generate_rc=$?
    if [ ! -f "$networkd_dhcp_conf" ]; then
      networkd_dhcp_conf="$(grep -Rsl 'PermanentMACAddress=52:54:00:12:34:56' /run/systemd/network/*.network 2>/dev/null | sed -n '1p' || true)"
    fi
    netplan_generated_network="$networkd_dhcp_conf"
    if [ -n "$netplan_generated_network" ] &&
       [ -f "$netplan_generated_network" ]; then
      netplan_generated_contents="$(sed -n '1,120p' "$netplan_generated_network" 2>/dev/null || true)"
      if printf '%s\n' "$netplan_generated_contents" | grep -Fq 'PermanentMACAddress=52:54:00:12:34:56' &&
         printf '%s\n' "$netplan_generated_contents" | grep -Fq 'DHCP=ipv4'; then
        netplan_generated_network_ok=1
        networkd_dhcp_conf_ok=1
      fi
    fi
  fi

  netplan_version="$(/usr/sbin/netplan info 2>&1 | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_NETPLAN_VERSION__:$netplan_version"
  if echo "$netplan_version" | grep -Eiq 'netplan'; then
    pass full-userland-netplan-version
  else
    full_userland_fail full-userland-netplan-version
  fi
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    echo "__NEMU_CHECK_FULL_NETPLAN_CONF__:$netplan_conf_ok:$netplan_conf"
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATE_RC__:$netplan_generate_rc"
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATED_NETWORK__:$netplan_generated_network_ok:$netplan_generated_network"
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATE_OUTPUT_BEGIN__"
    sed -n '1,120p' "$netplan_generate_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATE_OUTPUT_END__"
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATED_NETWORK_BEGIN__"
    printf '%s\n' "$netplan_generated_contents"
    echo "__NEMU_CHECK_FULL_NETPLAN_GENERATED_NETWORK_END__"
    if [ "$netplan_conf_ok" = "1" ] &&
       [ "$netplan_generate_rc" = "0" ] &&
       [ "$netplan_generated_network_ok" = "1" ]; then
      pass full-userland-netplan-generate-networkd
    else
      full_userland_fail full-userland-netplan-generate-networkd
    fi
  else
    echo "__NEMU_CHECK_FULL_NETPLAN_SKIP__:backend=${NEMU_GUEST_NET_BACKEND:-hostless}"
  fi

  networkctl_version="$(/bin/networkctl --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_NETWORKCTL_VERSION__:$networkctl_version"
  if echo "$networkctl_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-networkctl-version
  else
    full_userland_fail full-userland-networkctl-version
  fi
  if systemctl cat systemd-networkd.service >/dev/null 2>&1; then
    pass full-userland-systemd-networkd-unit
  else
    full_userland_fail full-userland-systemd-networkd-unit
  fi
  networkd_start_log=/tmp/nemu-full-networkd-start.log
  networkd_start_rc=0
  timeout "${networkd_dhcp_timeout}s" env SYSTEMD_BUS_TIMEOUT=15s \
    systemctl start systemd-networkd.service >"$networkd_start_log" 2>&1 ||
    networkd_start_rc=$?
  networkd_active="$(systemctl show --property=ActiveState --value systemd-networkd.service 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_TIMEOUT__:$networkd_dhcp_timeout"
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_CONF__:$networkd_dhcp_conf_ok:$networkd_dhcp_conf"
    echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_DEFERRED__:after-virtio-net-link-up"
  else
    echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_SKIP__:backend=${NEMU_GUEST_NET_BACKEND:-hostless}"
  fi
  echo "__NEMU_CHECK_FULL_NETWORKD_START_RC__:$networkd_start_rc"
  echo "__NEMU_CHECK_FULL_NETWORKD_ACTIVE__:$networkd_active"
  echo "__NEMU_CHECK_FULL_NETWORKD_START_OUTPUT_BEGIN__"
  sed -n '1,120p' "$networkd_start_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_NETWORKD_START_OUTPUT_END__"
  if [ "$networkd_start_rc" = "0" ] &&
     [ "$networkd_active" = "active" ]; then
    pass full-userland-systemd-networkd-active
  else
    systemctl status systemd-networkd.service --no-pager 2>/dev/null || true
    journalctl -u systemd-networkd.service --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    full_userland_fail full-userland-systemd-networkd-active
  fi
  check_full_userland_python_int_preflight runtime-after-core-tools

  machine_id_setup_version="$(/bin/systemd-machine-id-setup --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_MACHINE_ID_SETUP_VERSION__:$machine_id_setup_version"
  if echo "$machine_id_setup_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-machine-id-setup-version
  else
    full_userland_fail full-userland-machine-id-setup-version
  fi
  machine_id_value="$(cat /etc/machine-id 2>/dev/null | tr -d '\n' || true)"
  machine_id_size=0
  if [ -r /etc/machine-id ]; then
    machine_id_size="$(wc -c < /etc/machine-id 2>/dev/null | tr -d ' ' || true)"
  fi
  machine_id_commit_state="$(systemctl show -p ActiveState -p Result systemd-machine-id-commit.service 2>/dev/null | tr '\n' ' ' || true)"
  echo "__NEMU_CHECK_FULL_MACHINE_ID__:$machine_id_value"
  echo "__NEMU_CHECK_FULL_MACHINE_ID_SIZE__:$machine_id_size"
  echo "__NEMU_CHECK_FULL_MACHINE_ID_COMMIT_STATE__:$machine_id_commit_state"
  if [ "$machine_id_size" = "33" ] &&
     echo "$machine_id_value" | grep -Eq '^[0-9a-f]{32}$' &&
     systemctl cat systemd-machine-id-commit.service >/dev/null 2>&1; then
    pass full-userland-machine-id-committed
  else
    full_userland_fail full-userland-machine-id-committed
  fi

  hostnamed_unit_state="$(systemctl show -p ActiveState -p Result systemd-hostnamed.service 2>/dev/null | tr '\n' ' ' || true)"
  hostnamed_start_log=/tmp/nemu-full-hostnamed-start.log
  hostnamed_start_rc=0
  if systemctl cat systemd-hostnamed.service >/dev/null 2>&1 &&
     systemctl start systemd-hostnamed.service >"$hostnamed_start_log" 2>&1; then
    :
  else
    hostnamed_start_rc=$?
  fi
  hostnamed_unit_state_after="$(systemctl show -p ActiveState -p Result systemd-hostnamed.service 2>/dev/null | tr '\n' ' ' || true)"
  echo "__NEMU_CHECK_FULL_HOSTNAMED_UNIT_STATE__:$hostnamed_unit_state"
  echo "__NEMU_CHECK_FULL_HOSTNAMED_START_RC__:$hostnamed_start_rc"
  echo "__NEMU_CHECK_FULL_HOSTNAMED_UNIT_STATE_AFTER__:$hostnamed_unit_state_after"
  echo "__NEMU_CHECK_FULL_HOSTNAMED_START_LOG_BEGIN__"
  sed -n '1,80p' "$hostnamed_start_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_HOSTNAMED_START_LOG_END__"
  if [ "$hostnamed_start_rc" = "0" ]; then
    pass full-userland-hostnamed-active
  else
    full_userland_fail full-userland-hostnamed-active
  fi

  hostnamectl_stdout=/tmp/nemu-full-hostnamectl.out
  hostnamectl_stderr=/tmp/nemu-full-hostnamectl.err
  hostnamectl_rc=0
  /usr/bin/hostnamectl status >"$hostnamectl_stdout" 2>"$hostnamectl_stderr" ||
    hostnamectl_rc=$?
  hostnamectl_status="$(cat "$hostnamectl_stdout" 2>/dev/null || true)"
  hostnamectl_error="$(cat "$hostnamectl_stderr" 2>/dev/null || true)"
  hostnamectl_hostname="$(printf '%s\n' "$hostnamectl_status" | sed -n 's/^[[:space:]]*Static hostname:[[:space:]]*//p' | sed -n '1p')"
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_RC__:$hostnamectl_rc"
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_STATUS_BEGIN__"
  printf '%s\n' "$hostnamectl_status" | sed -n '1,40p'
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_STATUS_END__"
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_ERROR_BEGIN__"
  printf '%s\n' "$hostnamectl_error" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_ERROR_END__"
  echo "__NEMU_CHECK_FULL_HOSTNAMECTL_HOSTNAME__:$hostnamectl_hostname"
  if [ "$hostnamectl_rc" = "0" ] && [ "$hostnamectl_hostname" = "ysyx-ubuntu2204" ]; then
    pass full-userland-hostnamectl-status
  else
    full_userland_fail full-userland-hostnamectl-status
  fi
  check_full_userland_python_int_preflight runtime-after-identity

  sysusers_version="$(/bin/systemd-sysusers --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_SYSUSERS_VERSION__:$sysusers_version"
  if echo "$sysusers_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-sysusers-version
  else
    full_userland_fail full-userland-sysusers-version
  fi
  sysusers_setup_state="$(systemctl show -p ActiveState -p Result systemd-sysusers.service 2>/dev/null | tr '\n' ' ' || true)"
  echo "__NEMU_CHECK_FULL_SYSUSERS_SETUP_STATE__:$sysusers_setup_state"
  if systemctl cat systemd-sysusers.service >/dev/null 2>&1; then
    pass full-userland-sysusers-unit
  else
    full_userland_fail full-userland-sysusers-unit
  fi
  sysusers_conf=/etc/sysusers.d/nemu-full-sysusers-check.conf
  sysusers_log=/tmp/nemu-full-sysusers.log
  sysusers_user=nemufullsysusers
  sysusers_group=nemufullsysusers
  sysusers_uid=611
  sysusers_gid=611
  mkdir -p /etc/sysusers.d
  cat >"$sysusers_conf" <<EOF
g $sysusers_group $sysusers_gid -
u $sysusers_user $sysusers_uid:$sysusers_gid "NEMU Full Sysusers" /nonexistent /usr/sbin/nologin
EOF
  echo "__NEMU_CHECK_FULL_SYSUSERS_CONF__:$sysusers_conf:$sysusers_user:$sysusers_uid:$sysusers_group:$sysusers_gid"
  sysusers_create_rc=0
  /bin/systemd-sysusers "$sysusers_conf" >"$sysusers_log" 2>&1 ||
    sysusers_create_rc=$?
  sysusers_passwd_line="$(grep "^$sysusers_user:" /etc/passwd 2>/dev/null || true)"
  sysusers_group_line="$(grep "^$sysusers_group:" /etc/group 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSUSERS_CREATE_RC__:$sysusers_create_rc"
  echo "__NEMU_CHECK_FULL_SYSUSERS_PASSWD__:$sysusers_passwd_line"
  echo "__NEMU_CHECK_FULL_SYSUSERS_GROUP__:$sysusers_group_line"
  echo "__NEMU_CHECK_FULL_SYSUSERS_LOG_BEGIN__"
  sed -n '1,80p' "$sysusers_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSUSERS_LOG_END__"
  if [ "$sysusers_create_rc" = "0" ] &&
     [ "$sysusers_passwd_line" = "$sysusers_user:x:$sysusers_uid:$sysusers_gid:NEMU Full Sysusers:/nonexistent:/usr/sbin/nologin" ] &&
     [ "$sysusers_group_line" = "$sysusers_group:x:$sysusers_gid:" ]; then
    pass full-userland-sysusers-create
  else
    full_userland_fail full-userland-sysusers-create
  fi

  account_user=nemuacct
  account_group=nemuacct
  account_uid=2010
  account_gid=2010
  account_home=/home/nemuacct
  account_log=/tmp/nemu-full-account-useradd.log
  account_cleanup_log=/tmp/nemu-full-account-cleanup.log
  : >"$account_cleanup_log"
  account_cleanup_rc=0
  if grep -q "^$account_user:" /etc/passwd 2>/dev/null; then
    /usr/sbin/userdel -r "$account_user" >>"$account_cleanup_log" 2>&1 ||
      account_cleanup_rc=$?
  fi
  if grep -q "^$account_group:" /etc/group 2>/dev/null; then
    /usr/sbin/groupdel "$account_group" >>"$account_cleanup_log" 2>&1 ||
      account_cleanup_rc=$?
  fi
  echo "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__:$account_cleanup_rc"
  echo "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__"
  sed -n '1,80p' "$account_cleanup_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__"

  account_groupadd_rc=0
  /usr/sbin/groupadd -g "$account_gid" "$account_group" >"$account_log" 2>&1 ||
    account_groupadd_rc=$?
  account_useradd_rc=0
  if [ "$account_groupadd_rc" = "0" ]; then
    /usr/sbin/useradd -m -u "$account_uid" -g "$account_group" \
      -s /bin/sh -c "NEMU Account Test" "$account_user" >>"$account_log" 2>&1 ||
      account_useradd_rc=$?
  else
    account_useradd_rc=127
  fi
  account_passwd_status_rc=0
  account_passwd_status="$(/usr/bin/passwd -S "$account_user" 2>&1)" ||
    account_passwd_status_rc=$?
  account_passwd_line="$(grep "^$account_user:" /etc/passwd 2>/dev/null || true)"
  account_group_line="$(grep "^$account_group:" /etc/group 2>/dev/null || true)"
  account_home_owner="$(stat -c '%U:%G:%n' "$account_home" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__:$account_groupadd_rc"
  echo "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__:$account_useradd_rc"
  echo "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__:$account_passwd_status_rc"
  echo "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__:$account_passwd_status"
  echo "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__:$account_passwd_line"
  echo "__NEMU_CHECK_FULL_ACCOUNT_GROUP__:$account_group_line"
  echo "__NEMU_CHECK_FULL_ACCOUNT_HOME__:$account_home_owner"
  echo "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__"
  sed -n '1,120p' "$account_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__"

  account_su_rc=0
  account_su_output="$(
    timeout 120s /bin/su -l "$account_user" -s /bin/sh -c '
      printf "__NEMU_CHECK_FULL_ACCOUNT_SU_USER__:%s\n" "$(id -un)"
      printf "__NEMU_CHECK_FULL_ACCOUNT_SU_UID__:%s\n" "$(id -u)"
      printf "__NEMU_CHECK_FULL_ACCOUNT_SU_GID__:%s\n" "$(id -g)"
      printf "__NEMU_CHECK_FULL_ACCOUNT_SU_HOME__:%s\n" "$HOME"
      test "$(id -un)" = "nemuacct" &&
        test "$(id -u)" = "2010" &&
        test "$(id -g)" = "2010" &&
        test "$HOME" = "/home/nemuacct" &&
        printf "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__\n"
    ' 2>&1
  )" || account_su_rc=$?
  echo "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__:$account_su_rc"
  echo "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_BEGIN__"
  printf '%s\n' "$account_su_output" | sed -n '1,160p'
  echo "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_END__"
  if [ "$account_cleanup_rc" = "0" ] &&
     [ "$account_groupadd_rc" = "0" ] &&
     [ "$account_useradd_rc" = "0" ] &&
     [ "$account_passwd_status_rc" = "0" ] &&
     [ "$account_passwd_line" = "$account_user:x:$account_uid:$account_gid:NEMU Account Test:$account_home:/bin/sh" ] &&
     [ "$account_group_line" = "$account_group:x:$account_gid:" ] &&
     [ "$account_home_owner" = "$account_user:$account_group:$account_home" ] &&
     [ "$account_su_rc" = "0" ] &&
     echo "$account_su_output" | grep -q '__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__'; then
    pass full-userland-account-useradd-su-session
  else
    full_userland_fail full-userland-account-useradd-su-session
  fi

  account_sudoers=/etc/sudoers.d/nemu-full-sudo-nopasswd
  account_sudoers_rc=0
  account_sudoers_mode=
  rm -f "$account_sudoers"
  if [ "$account_groupadd_rc" = "0" ] && [ "$account_useradd_rc" = "0" ]; then
    mkdir -p /etc/sudoers.d
    {
      printf '%s ALL=(ALL) NOPASSWD: /usr/bin/id\n' "$account_user"
    } >"$account_sudoers" 2>/dev/null ||
      account_sudoers_rc=$?
    if [ "$account_sudoers_rc" = "0" ]; then
      chmod 0440 "$account_sudoers" 2>/dev/null ||
        account_sudoers_rc=$?
    fi
  else
    account_sudoers_rc=127
  fi
  account_sudoers_mode="$(stat -c '%a:%U:%G:%n' "$account_sudoers" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SUDOERS_FILE__:$account_sudoers"
  echo "__NEMU_CHECK_FULL_SUDOERS_RC__:$account_sudoers_rc"
  echo "__NEMU_CHECK_FULL_SUDOERS_MODE__:$account_sudoers_mode"

  account_sudo_rc=0
  account_sudo_output="$(
    timeout 120s /bin/su -l "$account_user" -s /bin/sh -c '
      sudo_uid="$(/usr/bin/sudo -n /usr/bin/id -u)" || exit $?
      sudo_user="$(/usr/bin/sudo -n /usr/bin/id -un)" || exit $?
      printf "__NEMU_CHECK_FULL_SUDO_NONROOT_UID__:%s\n" "$sudo_uid"
      printf "__NEMU_CHECK_FULL_SUDO_NONROOT_USER__:%s\n" "$sudo_user"
      test "$sudo_uid" = "0" &&
        test "$sudo_user" = "root" &&
        printf "__NEMU_CHECK_FULL_SUDO_NONROOT_OK__\n"
    ' 2>&1
  )" || account_sudo_rc=$?
  echo "__NEMU_CHECK_FULL_SUDO_NONROOT_RC__:$account_sudo_rc"
  echo "__NEMU_CHECK_FULL_SUDO_NONROOT_OUTPUT_BEGIN__"
  printf '%s\n' "$account_sudo_output" | sed -n '1,160p'
  echo "__NEMU_CHECK_FULL_SUDO_NONROOT_OUTPUT_END__"
  if [ "$account_sudoers_rc" = "0" ] &&
     [ "$account_sudoers_mode" = "440:root:root:$account_sudoers" ] &&
     [ "$account_sudo_rc" = "0" ] &&
     echo "$account_sudo_output" | grep -q '__NEMU_CHECK_FULL_SUDO_NONROOT_OK__'; then
    pass full-userland-sudo-nonroot-nopasswd
  else
    full_userland_fail full-userland-sudo-nonroot-nopasswd
  fi

  tmpfiles_version="$(/bin/systemd-tmpfiles --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_TMPFILES_VERSION__:$tmpfiles_version"
  if echo "$tmpfiles_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-tmpfiles-version
  else
    full_userland_fail full-userland-tmpfiles-version
  fi
  tmpfiles_setup_state="$(systemctl show -p ActiveState -p Result systemd-tmpfiles-setup.service 2>/dev/null | tr '\n' ' ' || true)"
  echo "__NEMU_CHECK_FULL_TMPFILES_SETUP_STATE__:$tmpfiles_setup_state"
  if systemctl cat systemd-tmpfiles-setup.service >/dev/null 2>&1; then
    pass full-userland-tmpfiles-unit
  else
    full_userland_fail full-userland-tmpfiles-unit
  fi
  tmpfiles_conf=/etc/tmpfiles.d/nemu-full-tmpfiles-check.conf
  tmpfiles_dir=/run/nemu-full-tmpfiles
  tmpfiles_file="$tmpfiles_dir/probe"
  tmpfiles_log=/tmp/nemu-full-tmpfiles.log
  rm -rf "$tmpfiles_dir"
  cat >"$tmpfiles_conf" <<EOF
d $tmpfiles_dir 0755 root root -
f $tmpfiles_file 0644 root root -
w $tmpfiles_file - - - - nemu-full-tmpfiles-ok
EOF
  echo "__NEMU_CHECK_FULL_TMPFILES_CONF__:$tmpfiles_conf:$tmpfiles_dir:$tmpfiles_file"
  tmpfiles_create_rc=0
  /bin/systemd-tmpfiles --create "$tmpfiles_conf" >"$tmpfiles_log" 2>&1 ||
    tmpfiles_create_rc=$?
  tmpfiles_file_value="$(cat "$tmpfiles_file" 2>/dev/null || true)"
  tmpfiles_dir_mode="$(stat -c '%a:%U:%G' "$tmpfiles_dir" 2>/dev/null || true)"
  tmpfiles_file_mode="$(stat -c '%a:%U:%G' "$tmpfiles_file" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_TMPFILES_CREATE_RC__:$tmpfiles_create_rc"
  echo "__NEMU_CHECK_FULL_TMPFILES_DIR__:$tmpfiles_dir_mode:$tmpfiles_dir"
  echo "__NEMU_CHECK_FULL_TMPFILES_FILE__:$tmpfiles_file_mode:$tmpfiles_file:$tmpfiles_file_value"
  echo "__NEMU_CHECK_FULL_TMPFILES_LOG_BEGIN__"
  sed -n '1,80p' "$tmpfiles_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_TMPFILES_LOG_END__"
  if [ "$tmpfiles_create_rc" = "0" ] &&
     [ "$tmpfiles_dir_mode" = "755:root:root" ] &&
     [ "$tmpfiles_file_mode" = "644:root:root" ] &&
     [ "$tmpfiles_file_value" = "nemu-full-tmpfiles-ok" ]; then
    pass full-userland-tmpfiles-create
  else
    full_userland_fail full-userland-tmpfiles-create
  fi
  check_full_userland_python_int_preflight runtime-after-systemd-files

  journald_state="$(systemctl is-active systemd-journald.service 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_JOURNALD_ACTIVE__:$journald_state"
  if [ "$journald_state" = "active" ]; then
    pass full-userland-journald-active
  else
    systemctl status --no-pager systemd-journald.service 2>/dev/null || true
    full_userland_fail full-userland-journald-active
  fi

  echo "__NEMU_CHECK_FULL_JOURNAL_DIR_BEGIN__"
  ls -ld \
    /run/systemd/journal \
    /run/systemd/journal/stdout \
    /run/systemd/journal/socket \
    /run/systemd/journal/dev-log \
    2>&1 || true
  echo "__NEMU_CHECK_FULL_JOURNAL_DIR_END__"
  journal_probe_tag=nemu-full-journal
  journal_probe_msg="nemu-full-journal-ok-$(date +%s)"
  journal_cat_log=/tmp/nemu-full-systemd-cat.log
  journal_cat_rc=0
  systemd-cat -t "$journal_probe_tag" -p info \
    /bin/sh -c 'printf "%s\n" "$1"' nemu-full-journal-probe "$journal_probe_msg" \
    >"$journal_cat_log" 2>&1 ||
    journal_cat_rc=$?
  echo "__NEMU_CHECK_FULL_JOURNAL_CAT_RC__:$journal_cat_rc"
  echo "__NEMU_CHECK_FULL_JOURNAL_CAT_LOG_BEGIN__"
  sed -n '1,80p' "$journal_cat_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_JOURNAL_CAT_LOG_END__"
  if [ "$journal_cat_rc" = "0" ]; then
    pass full-userland-systemd-cat
  else
    full_userland_fail full-userland-systemd-cat
  fi

  journal_sync_rc=0
  journalctl --sync >/dev/null 2>&1 || journal_sync_rc=$?
  echo "__NEMU_CHECK_FULL_JOURNALCTL_SYNC_RC__:$journal_sync_rc"
  journalctl_rc=0
  journalctl_output=
  journal_probe_i=0
  while [ "$journal_probe_i" -lt 20 ]; do
    journalctl_rc=0
    journalctl_output="$(journalctl -t "$journal_probe_tag" --no-pager -n 20 2>&1)" ||
      journalctl_rc=$?
    if [ "$journalctl_rc" = "0" ] &&
       printf '%s\n' "$journalctl_output" | grep -Fq "$journal_probe_msg"; then
      break
    fi
    sleep 1
    journal_probe_i=$((journal_probe_i + 1))
  done
  echo "__NEMU_CHECK_FULL_JOURNALCTL_RC__:$journalctl_rc"
  echo "__NEMU_CHECK_FULL_JOURNALCTL_TAG__:$journal_probe_tag"
  echo "__NEMU_CHECK_FULL_JOURNALCTL_EXPECT__:$journal_probe_msg"
  echo "__NEMU_CHECK_FULL_JOURNALCTL_OUTPUT_BEGIN__"
  printf '%s\n' "$journalctl_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_JOURNALCTL_OUTPUT_END__"
  if [ "$journalctl_rc" = "0" ] &&
     printf '%s\n' "$journalctl_output" | grep -Fq "$journal_probe_msg"; then
    pass full-userland-journalctl-query
  else
    systemctl status --no-pager systemd-journald.service 2>/dev/null || true
    full_userland_fail full-userland-journalctl-query
  fi
  check_full_userland_python_int_preflight runtime-after-journal

  mkdir -p /run/sshd
  sshd_config="$(/usr/sbin/sshd -T 2>&1 | sed -n '1,25p' || true)"
  echo "__NEMU_CHECK_FULL_SSHD_CONFIG_BEGIN__"
  printf '%s\n' "$sshd_config"
  echo "__NEMU_CHECK_FULL_SSHD_CONFIG_END__"
  if echo "$sshd_config" | grep -q '^port 22$'; then
    pass full-userland-sshd-config
  else
    full_userland_fail full-userland-sshd-config
  fi
  if systemctl cat ssh.service >/dev/null 2>&1; then
    pass full-userland-ssh-unit
  else
    full_userland_fail full-userland-ssh-unit
  fi
  # full rootfs 不只要求 OpenSSH 配置可解析，还要证明服务能在 guest 内实际起来。
  ssh_start_log=/tmp/nemu-full-userland-ssh-start.log
  if systemctl start ssh.service >"$ssh_start_log" 2>&1 &&
     systemctl --quiet is-active ssh.service; then
    ssh_state="$(systemctl is-active ssh.service 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_SSH_ACTIVE__:$ssh_state"
    pass full-userland-ssh-active
  else
    ssh_state="$(systemctl is-active ssh.service 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_SSH_ACTIVE__:$ssh_state"
    sed -n '1,20p' "$ssh_start_log" 2>/dev/null || true
    systemctl status --no-pager ssh.service 2>/dev/null || true
    full_userland_fail full-userland-ssh-active
  fi
  ssh_listen=0
  for ssh_tcp_file in /proc/net/tcp /proc/net/tcp6; do
    [ -r "$ssh_tcp_file" ] || continue
    while read -r tcp_sl tcp_local tcp_remote tcp_state tcp_rest; do
      case "$tcp_local:$tcp_state" in
        *:0016:0A)
          ssh_listen=1
          echo "__NEMU_CHECK_FULL_SSH_LISTEN_SOCKET__:$ssh_tcp_file:$tcp_local:$tcp_state"
          ;;
      esac
    done <"$ssh_tcp_file"
  done
  echo "__NEMU_CHECK_FULL_SSH_LISTEN__:$ssh_listen"
  if [ "$ssh_listen" = "1" ]; then
    pass full-userland-ssh-listen
  else
    full_userland_fail full-userland-ssh-listen
  fi
  ssh_login_user=nemu
  ssh_login_uid=2000
  ssh_login_gid=2000
  ssh_login_home=/home/nemu
  ssh_login_dir=/tmp/nemu-full-userland-ssh-login
  ssh_auth_keys="$ssh_login_home/.ssh/authorized_keys"
  ssh_dbclient_key="$ssh_login_dir/id_dropbear"
  ssh_dropbear_hostkey="$ssh_login_dir/dropbear_host_ed25519"
  ssh_dropbear_log="$ssh_login_dir/dropbear.log"
  rm -rf "$ssh_login_dir"
  # 只做 guest 内 loopback 登录，验证 sshd 认证/会话链路；外网/TAP/NAT 另由后续 gate 证明。
  # root 串口 autologin 不等于 OpenSSH root 登录策略，smoke 使用 overlay 内临时普通用户。
  if ! grep -q "^$ssh_login_user:" /etc/group 2>/dev/null; then
    echo "$ssh_login_user:x:$ssh_login_gid:" >> /etc/group
  fi
  if [ -f /etc/gshadow ] && ! grep -q "^$ssh_login_user:" /etc/gshadow 2>/dev/null; then
    echo "$ssh_login_user:!::" >> /etc/gshadow
  fi
  if ! grep -q "^$ssh_login_user:" /etc/passwd 2>/dev/null; then
    echo "$ssh_login_user:x:$ssh_login_uid:$ssh_login_gid:NEMU SSH Test:$ssh_login_home:/bin/sh" >> /etc/passwd
  fi
  if [ -f /etc/shadow ] && ! grep -q "^$ssh_login_user:" /etc/shadow 2>/dev/null; then
    echo "$ssh_login_user::20000:0:99999:7:::" >> /etc/shadow
  fi
  if grep -q "^$ssh_login_user:" /etc/passwd 2>/dev/null &&
     mkdir -p "$ssh_login_dir" "$ssh_login_home/.ssh" &&
     chmod 700 "$ssh_login_dir" "$ssh_login_home" "$ssh_login_home/.ssh" &&
     ssh-keygen -q -t ed25519 -N '' -f "$ssh_login_dir/id_ed25519" >/dev/null 2>&1 &&
     dropbearconvert openssh dropbear "$ssh_login_dir/id_ed25519" "$ssh_dbclient_key" >/dev/null 2>&1 &&
     dropbearkey -t ed25519 -f "$ssh_dropbear_hostkey" >/dev/null 2>&1 &&
     cat "$ssh_login_dir/id_ed25519.pub" >> "$ssh_auth_keys" &&
     chmod 600 "$ssh_auth_keys" "$ssh_dbclient_key" "$ssh_dropbear_hostkey" &&
     chown -R "$ssh_login_uid:$ssh_login_gid" "$ssh_login_home"; then
    pass full-userland-ssh-test-user
    pass full-userland-ssh-keygen
    pass full-userland-ssh-dbclient-key
    pass full-userland-ssh-dropbear-hostkey
    pam_su_rc=0
    pam_su_output="$(
      timeout 120s /bin/su -l "$ssh_login_user" -s /bin/sh -c '
        printf "__NEMU_CHECK_FULL_PAM_SU_USER__:%s\n" "$(id -un)"
        printf "__NEMU_CHECK_FULL_PAM_SU_UID__:%s\n" "$(id -u)"
        printf "__NEMU_CHECK_FULL_PAM_SU_GID__:%s\n" "$(id -g)"
        printf "__NEMU_CHECK_FULL_PAM_SU_HOME__:%s\n" "$HOME"
        test "$(id -un)" = "nemu" &&
          test "$(id -u)" = "2000" &&
          test "$HOME" = "/home/nemu" &&
          printf "__NEMU_CHECK_FULL_PAM_SU_LOGIN_OK__\n"
      ' 2>&1
    )" || pam_su_rc=$?
    echo "__NEMU_CHECK_FULL_PAM_SU_RC__:$pam_su_rc"
    echo "__NEMU_CHECK_FULL_PAM_SU_OUTPUT_BEGIN__"
    printf '%s\n' "$pam_su_output" | sed -n '1,160p'
    echo "__NEMU_CHECK_FULL_PAM_SU_OUTPUT_END__"
    if [ "$pam_su_rc" = "0" ] &&
       echo "$pam_su_output" | grep -q '__NEMU_CHECK_FULL_PAM_SU_LOGIN_OK__'; then
      pass full-userland-pam-su-session
    else
      full_userland_fail full-userland-pam-su-session
    fi
    (
      timeout 180s /usr/sbin/dropbear -E -F \
        -r "$ssh_dropbear_hostkey" \
        -p 127.0.0.1:2224 \
        -s -g
    ) >"$ssh_dropbear_log" 2>&1 &
    ssh_dropbear_pid=$!
    ssh_dropbear_ready=0
    for _ in $(seq 1 60); do
      if grep -q ':08B0 ' /proc/net/tcp 2>/dev/null ||
         grep -q ':08B0 ' /proc/net/tcp6 2>/dev/null; then
        ssh_dropbear_ready=1
        break
      fi
      sleep 1
    done
    echo "__NEMU_CHECK_FULL_SSH_DROPBEAR_READY__:$ssh_dropbear_ready"
    ssh_login_rc=0
    echo "__NEMU_CHECK_FULL_SSH_SERVER__:dropbear-loopback"
    echo "__NEMU_CHECK_FULL_SSH_CLIENT__:dbclient"
    if [ "$ssh_dropbear_ready" = "1" ]; then
      ssh_login_output="$(
        timeout 180s dbclient -y \
          -i "$ssh_dbclient_key" \
          -p 2224 \
          "$ssh_login_user@127.0.0.1" \
          'test "$(id -un)" = "nemu" && printf __NEMU_CHECK_FULL_SSH_LOGIN_OK__' 2>&1
      )" || ssh_login_rc=$?
    else
      ssh_login_rc=124
      ssh_login_output="dropbear loopback server did not become ready"
    fi
    if kill -0 "$ssh_dropbear_pid" 2>/dev/null; then
      kill "$ssh_dropbear_pid" 2>/dev/null || true
    fi
    wait "$ssh_dropbear_pid" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SSH_LOGIN_RC__:$ssh_login_rc"
    echo "__NEMU_CHECK_FULL_SSH_LOGIN_OUTPUT_BEGIN__"
    printf '%s\n' "$ssh_login_output" | sed -n '1,160p'
    echo "__NEMU_CHECK_FULL_SSH_LOGIN_OUTPUT_END__"
    if [ "$ssh_login_rc" = "0" ] &&
       echo "$ssh_login_output" | grep -q '__NEMU_CHECK_FULL_SSH_LOGIN_OK__'; then
      pass full-userland-ssh-local-login
    else
      echo "__NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_BEGIN__"
      sed -n '1,160p' "$ssh_dropbear_log" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_END__"
      ssh_debug_log=/tmp/nemu-full-userland-sshd-debug.log
      ssh_debug_output=/tmp/nemu-full-userland-ssh-debug-client.log
      rm -f "$ssh_debug_log" "$ssh_debug_output"
      (
        timeout 180s /usr/sbin/sshd -D -ddd -e \
          -p 2222 \
          -o ListenAddress=127.0.0.1 \
          -o PidFile=/tmp/nemu-full-userland-sshd-debug.pid \
          -o LogLevel=DEBUG3
      ) >"$ssh_debug_log" 2>&1 &
      ssh_debug_pid=$!
      ssh_debug_ready=0
      for _ in $(seq 1 60); do
        if grep -q ':08AE ' /proc/net/tcp 2>/dev/null ||
           grep -q ':08AE ' /proc/net/tcp6 2>/dev/null; then
          ssh_debug_ready=1
          break
        fi
        sleep 1
      done
      echo "__NEMU_CHECK_FULL_SSH_DEBUG_READY__:$ssh_debug_ready"
      ssh_debug_rc=0
      if [ "$ssh_debug_ready" = "1" ]; then
        timeout 180s ssh -vvv -4 \
          -p 2222 \
          -i "$ssh_login_dir/id_ed25519" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          "$ssh_login_user@127.0.0.1" \
          'test "$(id -un)" = "nemu" && printf __NEMU_CHECK_FULL_SSH_DEBUG_LOGIN_OK__' \
          >"$ssh_debug_output" 2>&1 || ssh_debug_rc=$?
      else
        ssh_debug_rc=124
      fi
      echo "__NEMU_CHECK_FULL_SSH_DEBUG_LOGIN_RC__:$ssh_debug_rc"
      if kill -0 "$ssh_debug_pid" 2>/dev/null; then
        kill "$ssh_debug_pid" 2>/dev/null || true
      fi
      wait "$ssh_debug_pid" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_BEGIN__"
      sed -n '1,220p' "$ssh_debug_output" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_END__"
      echo "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_BEGIN__"
      sed -n '1,500p' "$ssh_debug_log" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_END__"
      ssh_nopam_log=/tmp/nemu-full-userland-sshd-nopam.log
      ssh_nopam_output=/tmp/nemu-full-userland-ssh-nopam-client.log
      rm -f "$ssh_nopam_log" "$ssh_nopam_output"
      (
        timeout 180s /usr/sbin/sshd -D -ddd -e \
          -p 2223 \
          -o ListenAddress=127.0.0.1 \
          -o PidFile=/tmp/nemu-full-userland-sshd-nopam.pid \
          -o LogLevel=DEBUG3 \
          -o UsePAM=no
      ) >"$ssh_nopam_log" 2>&1 &
      ssh_nopam_pid=$!
      ssh_nopam_ready=0
      for _ in $(seq 1 60); do
        if grep -q ':08AF ' /proc/net/tcp 2>/dev/null ||
           grep -q ':08AF ' /proc/net/tcp6 2>/dev/null; then
          ssh_nopam_ready=1
          break
        fi
        sleep 1
      done
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_READY__:$ssh_nopam_ready"
      ssh_nopam_rc=0
      if [ "$ssh_nopam_ready" = "1" ]; then
        timeout 180s ssh -vvv -4 \
          -p 2223 \
          -i "$ssh_login_dir/id_ed25519" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          "$ssh_login_user@127.0.0.1" \
          'test "$(id -un)" = "nemu" && printf __NEMU_CHECK_FULL_SSH_NOPAM_LOGIN_OK__' \
          >"$ssh_nopam_output" 2>&1 || ssh_nopam_rc=$?
      else
        ssh_nopam_rc=124
      fi
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_LOGIN_RC__:$ssh_nopam_rc"
      if kill -0 "$ssh_nopam_pid" 2>/dev/null; then
        kill "$ssh_nopam_pid" 2>/dev/null || true
      fi
      wait "$ssh_nopam_pid" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_CLIENT_BEGIN__"
      sed -n '1,220p' "$ssh_nopam_output" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_CLIENT_END__"
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_DEBUGD_LOG_BEGIN__"
      sed -n '1,500p' "$ssh_nopam_log" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_NOPAM_DEBUGD_LOG_END__"
      echo "__NEMU_CHECK_FULL_SSH_SERVER_LOG_BEGIN__"
      journalctl -u ssh.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
      journalctl -t sshd --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
      tail -80 /var/log/auth.log /var/log/syslog 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_SSH_SERVER_LOG_END__"
      full_userland_fail full-userland-ssh-local-login
    fi
    openssh_login_rc=0
    openssh_login_output="$(
      timeout 240s ssh -4 \
        -p 22 \
        -i "$ssh_login_dir/id_ed25519" \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o GlobalKnownHostsFile=/dev/null \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o PreferredAuthentications=publickey \
        -o IdentitiesOnly=yes \
        -o KexAlgorithms=curve25519-sha256 \
        -o HostKeyAlgorithms=ssh-ed25519 \
        -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
        -o Ciphers=chacha20-poly1305@openssh.com \
        -o ConnectTimeout=120 \
        -o LogLevel=ERROR \
        "$ssh_login_user@127.0.0.1" \
        'printf "__NEMU_CHECK_FULL_OPENSSH_USER__:%s\n" "$(id -un)"
         printf "__NEMU_CHECK_FULL_OPENSSH_UID__:%s\n" "$(id -u)"
         printf "__NEMU_CHECK_FULL_OPENSSH_GID__:%s\n" "$(id -g)"
         printf "__NEMU_CHECK_FULL_OPENSSH_HOME__:%s\n" "$HOME"
         test "$(id -un)" = "nemu" &&
           test "$(id -u)" = "2000" &&
           test "$HOME" = "/home/nemu" &&
           printf "__NEMU_CHECK_FULL_OPENSSH_LOGIN_OK__\n"' 2>&1
    )" || openssh_login_rc=$?
    echo "__NEMU_CHECK_FULL_OPENSSH_SERVER__:ssh.service"
    echo "__NEMU_CHECK_FULL_OPENSSH_CLIENT__:ssh"
    echo "__NEMU_CHECK_FULL_OPENSSH_LOGIN_RC__:$openssh_login_rc"
    echo "__NEMU_CHECK_FULL_OPENSSH_LOGIN_OUTPUT_BEGIN__"
    printf '%s\n' "$openssh_login_output" | sed -n '1,160p'
    echo "__NEMU_CHECK_FULL_OPENSSH_LOGIN_OUTPUT_END__"
    if [ "$openssh_login_rc" = "0" ] &&
       echo "$openssh_login_output" | grep -q '__NEMU_CHECK_FULL_OPENSSH_LOGIN_OK__'; then
      pass full-userland-openssh-local-login
      openssh_scp_src="$ssh_login_dir/scp-source.txt"
      openssh_scp_dst="/tmp/nemu-full-openssh-scp.txt"
      printf 'nemu-openssh-scp-ok\n' >"$openssh_scp_src"
      openssh_scp_rc=0
      openssh_scp_output="$(
        timeout 240s scp -4 \
          -P 22 \
          -i "$ssh_login_dir/id_ed25519" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o GlobalKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o IdentitiesOnly=yes \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          -o LogLevel=ERROR \
          "$openssh_scp_src" \
          "$ssh_login_user@127.0.0.1:$openssh_scp_dst" 2>&1
      )" || openssh_scp_rc=$?
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_CLIENT__:scp"
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_RC__:$openssh_scp_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_OUTPUT_BEGIN__"
      printf '%s\n' "$openssh_scp_output" | sed -n '1,120p'
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_OUTPUT_END__"
      openssh_scp_verify_rc=0
      if [ "$openssh_scp_rc" = "0" ]; then
        openssh_scp_verify_output="$(
          timeout 120s ssh -4 \
            -p 22 \
            -i "$ssh_login_dir/id_ed25519" \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -o PasswordAuthentication=no \
            -o KbdInteractiveAuthentication=no \
            -o PreferredAuthentications=publickey \
            -o IdentitiesOnly=yes \
            -o KexAlgorithms=curve25519-sha256 \
            -o HostKeyAlgorithms=ssh-ed25519 \
            -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
            -o Ciphers=chacha20-poly1305@openssh.com \
            -o ConnectTimeout=120 \
            -o LogLevel=ERROR \
            "$ssh_login_user@127.0.0.1" \
            "test \"\$(cat $openssh_scp_dst 2>/dev/null)\" = \"nemu-openssh-scp-ok\" && printf \"__NEMU_CHECK_FULL_OPENSSH_SCP_OK__\\n\"" 2>&1
        )" || openssh_scp_verify_rc=$?
      else
        openssh_scp_verify_rc=124
        openssh_scp_verify_output="scp transfer did not complete"
      fi
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_VERIFY_RC__:$openssh_scp_verify_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_VERIFY_BEGIN__"
      printf '%s\n' "$openssh_scp_verify_output" | sed -n '1,120p'
      echo "__NEMU_CHECK_FULL_OPENSSH_SCP_VERIFY_END__"
      if [ "$openssh_scp_rc" = "0" ] &&
         [ "$openssh_scp_verify_rc" = "0" ] &&
         echo "$openssh_scp_verify_output" | grep -q '__NEMU_CHECK_FULL_OPENSSH_SCP_OK__'; then
        pass full-userland-openssh-scp-transfer
      else
        echo "__NEMU_CHECK_FULL_OPENSSH_SCP_SERVER_LOG_BEGIN__"
        journalctl -u ssh.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        journalctl -t sshd --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        tail -80 /var/log/auth.log /var/log/syslog 2>/dev/null || true
        echo "__NEMU_CHECK_FULL_OPENSSH_SCP_SERVER_LOG_END__"
        full_userland_fail full-userland-openssh-scp-transfer
      fi

      openssh_sftp_src="$ssh_login_dir/sftp-source.txt"
      openssh_sftp_dst="/tmp/nemu-full-openssh-sftp.txt"
      openssh_sftp_batch="$ssh_login_dir/sftp.batch"
      printf 'nemu-openssh-sftp-ok\n' >"$openssh_sftp_src"
      printf 'put %s %s\n' "$openssh_sftp_src" "$openssh_sftp_dst" >"$openssh_sftp_batch"
      openssh_sftp_rc=0
      openssh_sftp_output="$(
        timeout 240s sftp -4 \
          -P 22 \
          -i "$ssh_login_dir/id_ed25519" \
          -b "$openssh_sftp_batch" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o GlobalKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o IdentitiesOnly=yes \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          -o LogLevel=ERROR \
          "$ssh_login_user@127.0.0.1" 2>&1
      )" || openssh_sftp_rc=$?
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_SERVER__:/usr/lib/openssh/sftp-server"
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_CLIENT__:sftp"
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_RC__:$openssh_sftp_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_OUTPUT_BEGIN__"
      printf '%s\n' "$openssh_sftp_output" | sed -n '1,160p'
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_OUTPUT_END__"
      openssh_sftp_verify_rc=0
      if [ "$openssh_sftp_rc" = "0" ]; then
        openssh_sftp_verify_output="$(
          timeout 120s ssh -4 \
            -p 22 \
            -i "$ssh_login_dir/id_ed25519" \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -o PasswordAuthentication=no \
            -o KbdInteractiveAuthentication=no \
            -o PreferredAuthentications=publickey \
            -o IdentitiesOnly=yes \
            -o KexAlgorithms=curve25519-sha256 \
            -o HostKeyAlgorithms=ssh-ed25519 \
            -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
            -o Ciphers=chacha20-poly1305@openssh.com \
            -o ConnectTimeout=120 \
            -o LogLevel=ERROR \
            "$ssh_login_user@127.0.0.1" \
            "test \"\$(cat $openssh_sftp_dst 2>/dev/null)\" = \"nemu-openssh-sftp-ok\" && printf \"__NEMU_CHECK_FULL_OPENSSH_SFTP_OK__\\n\"" 2>&1
        )" || openssh_sftp_verify_rc=$?
      else
        openssh_sftp_verify_rc=124
        openssh_sftp_verify_output="sftp transfer did not complete"
      fi
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_VERIFY_RC__:$openssh_sftp_verify_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_VERIFY_BEGIN__"
      printf '%s\n' "$openssh_sftp_verify_output" | sed -n '1,120p'
      echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_VERIFY_END__"
      if [ "$openssh_sftp_rc" = "0" ] &&
         [ "$openssh_sftp_verify_rc" = "0" ] &&
         echo "$openssh_sftp_verify_output" | grep -q '__NEMU_CHECK_FULL_OPENSSH_SFTP_OK__'; then
        pass full-userland-openssh-sftp-transfer
      else
        echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_SERVER_LOG_BEGIN__"
        journalctl -u ssh.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        journalctl -t sshd --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        tail -80 /var/log/auth.log /var/log/syslog 2>/dev/null || true
        echo "__NEMU_CHECK_FULL_OPENSSH_SFTP_SERVER_LOG_END__"
        full_userland_fail full-userland-openssh-sftp-transfer
      fi

      openssh_forward_port=2226
      openssh_forward_hex=08B2
      openssh_forward_log="$ssh_login_dir/ssh-local-forward.log"
      openssh_forward_rc=0
      (
        timeout 360s ssh -4 -N \
          -L "127.0.0.1:${openssh_forward_port}:127.0.0.1:22" \
          -p 22 \
          -i "$ssh_login_dir/id_ed25519" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o GlobalKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o IdentitiesOnly=yes \
          -o ExitOnForwardFailure=yes \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          -o LogLevel=ERROR \
          "$ssh_login_user@127.0.0.1"
      ) >"$openssh_forward_log" 2>&1 &
      openssh_forward_pid=$!
      openssh_forward_ready=0
      for _ in $(seq 1 90); do
        if grep -q ":${openssh_forward_hex} " /proc/net/tcp 2>/dev/null ||
           grep -q ":${openssh_forward_hex} " /proc/net/tcp6 2>/dev/null; then
          openssh_forward_ready=1
          break
        fi
        if ! kill -0 "$openssh_forward_pid" 2>/dev/null; then
          break
        fi
        sleep 1
      done
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_PORT__:$openssh_forward_port"
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_READY__:$openssh_forward_ready"
      openssh_forward_output=""
      if [ "$openssh_forward_ready" = "1" ]; then
        openssh_forward_output="$(
          timeout 240s ssh -4 \
            -p "$openssh_forward_port" \
            -i "$ssh_login_dir/id_ed25519" \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -o PasswordAuthentication=no \
            -o KbdInteractiveAuthentication=no \
            -o PreferredAuthentications=publickey \
            -o IdentitiesOnly=yes \
            -o KexAlgorithms=curve25519-sha256 \
            -o HostKeyAlgorithms=ssh-ed25519 \
            -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
            -o Ciphers=chacha20-poly1305@openssh.com \
            -o ConnectTimeout=120 \
            -o LogLevel=ERROR \
            "$ssh_login_user@127.0.0.1" \
            'printf "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_USER__:%s\n" "$(id -un)"
             test "$(id -un)" = "nemu" &&
               printf "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_OK__\n"' 2>&1
        )" || openssh_forward_rc=$?
      else
        openssh_forward_rc=124
        openssh_forward_output="OpenSSH local forward listener did not become ready"
      fi
      if kill -0 "$openssh_forward_pid" 2>/dev/null; then
        kill "$openssh_forward_pid" 2>/dev/null || true
      fi
      wait "$openssh_forward_pid" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_CLIENT__:ssh-L"
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_RC__:$openssh_forward_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_OUTPUT_BEGIN__"
      printf '%s\n' "$openssh_forward_output" | sed -n '1,160p'
      echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_OUTPUT_END__"
      if [ "$openssh_forward_ready" = "1" ] &&
         [ "$openssh_forward_rc" = "0" ] &&
         echo "$openssh_forward_output" | grep -q '__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_OK__'; then
        pass full-userland-openssh-local-forward
      else
        echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_LOG_BEGIN__"
        sed -n '1,160p' "$openssh_forward_log" 2>/dev/null || true
        journalctl -u ssh.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        journalctl -t sshd --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        echo "__NEMU_CHECK_FULL_OPENSSH_LOCAL_FORWARD_LOG_END__"
        full_userland_fail full-userland-openssh-local-forward
      fi

      openssh_remote_forward_port=2227
      openssh_remote_forward_hex=08B3
      openssh_remote_forward_log="$ssh_login_dir/ssh-remote-forward.log"
      openssh_remote_forward_rc=0
      # local-forward covers client-side listeners; this checks sshd-side remote forwarding too.
      (
        timeout 360s ssh -4 -N \
          -R "127.0.0.1:${openssh_remote_forward_port}:127.0.0.1:22" \
          -p 22 \
          -i "$ssh_login_dir/id_ed25519" \
          -o BatchMode=yes \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o GlobalKnownHostsFile=/dev/null \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o PreferredAuthentications=publickey \
          -o IdentitiesOnly=yes \
          -o ExitOnForwardFailure=yes \
          -o KexAlgorithms=curve25519-sha256 \
          -o HostKeyAlgorithms=ssh-ed25519 \
          -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
          -o Ciphers=chacha20-poly1305@openssh.com \
          -o ConnectTimeout=120 \
          -o LogLevel=ERROR \
          "$ssh_login_user@127.0.0.1"
      ) >"$openssh_remote_forward_log" 2>&1 &
      openssh_remote_forward_pid=$!
      openssh_remote_forward_ready=0
      for _ in $(seq 1 90); do
        if grep -q ":${openssh_remote_forward_hex} " /proc/net/tcp 2>/dev/null ||
           grep -q ":${openssh_remote_forward_hex} " /proc/net/tcp6 2>/dev/null; then
          openssh_remote_forward_ready=1
          break
        fi
        if ! kill -0 "$openssh_remote_forward_pid" 2>/dev/null; then
          break
        fi
        sleep 1
      done
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_PORT__:$openssh_remote_forward_port"
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_READY__:$openssh_remote_forward_ready"
      openssh_remote_forward_output=""
      if [ "$openssh_remote_forward_ready" = "1" ]; then
        openssh_remote_forward_output="$(
          timeout 240s ssh -4 \
            -p "$openssh_remote_forward_port" \
            -i "$ssh_login_dir/id_ed25519" \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -o PasswordAuthentication=no \
            -o KbdInteractiveAuthentication=no \
            -o PreferredAuthentications=publickey \
            -o IdentitiesOnly=yes \
            -o KexAlgorithms=curve25519-sha256 \
            -o HostKeyAlgorithms=ssh-ed25519 \
            -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
            -o Ciphers=chacha20-poly1305@openssh.com \
            -o ConnectTimeout=120 \
            -o LogLevel=ERROR \
            "$ssh_login_user@127.0.0.1" \
            'printf "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_USER__:%s\n" "$(id -un)"
             test "$(id -un)" = "nemu" &&
               printf "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_OK__\n"' 2>&1
        )" || openssh_remote_forward_rc=$?
      else
        openssh_remote_forward_rc=124
        openssh_remote_forward_output="OpenSSH remote forward listener did not become ready"
      fi
      if kill -0 "$openssh_remote_forward_pid" 2>/dev/null; then
        kill "$openssh_remote_forward_pid" 2>/dev/null || true
      fi
      wait "$openssh_remote_forward_pid" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_CLIENT__:ssh-R"
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_RC__:$openssh_remote_forward_rc"
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_OUTPUT_BEGIN__"
      printf '%s\n' "$openssh_remote_forward_output" | sed -n '1,160p'
      echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_OUTPUT_END__"
      if [ "$openssh_remote_forward_ready" = "1" ] &&
         [ "$openssh_remote_forward_rc" = "0" ] &&
         echo "$openssh_remote_forward_output" | grep -q '__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_OK__'; then
        pass full-userland-openssh-remote-forward
      else
        echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_LOG_BEGIN__"
        sed -n '1,160p' "$openssh_remote_forward_log" 2>/dev/null || true
        journalctl -u ssh.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        journalctl -t sshd --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
        echo "__NEMU_CHECK_FULL_OPENSSH_REMOTE_FORWARD_LOG_END__"
        full_userland_fail full-userland-openssh-remote-forward
      fi
    else
      openssh_debug_output=/tmp/nemu-full-userland-openssh-debug-client.log
      rm -f "$openssh_debug_output"
      timeout 240s ssh -vvv -4 \
        -p 22 \
        -i "$ssh_login_dir/id_ed25519" \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o GlobalKnownHostsFile=/dev/null \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o PreferredAuthentications=publickey \
        -o IdentitiesOnly=yes \
        -o KexAlgorithms=curve25519-sha256 \
        -o HostKeyAlgorithms=ssh-ed25519 \
        -o PubkeyAcceptedAlgorithms=ssh-ed25519 \
        -o Ciphers=chacha20-poly1305@openssh.com \
        -o ConnectTimeout=120 \
        "$ssh_login_user@127.0.0.1" \
        'test "$(id -un)" = "nemu" && printf __NEMU_CHECK_FULL_OPENSSH_DEBUG_LOGIN_OK__' \
        >"$openssh_debug_output" 2>&1 || true
      echo "__NEMU_CHECK_FULL_OPENSSH_DEBUG_CLIENT_BEGIN__"
      sed -n '1,260p' "$openssh_debug_output" 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_OPENSSH_DEBUG_CLIENT_END__"
      echo "__NEMU_CHECK_FULL_OPENSSH_SERVER_LOG_BEGIN__"
      journalctl -u ssh.service --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
      journalctl -t sshd --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
      tail -120 /var/log/auth.log /var/log/syslog 2>/dev/null || true
      echo "__NEMU_CHECK_FULL_OPENSSH_SERVER_LOG_END__"
      full_userland_fail full-userland-openssh-local-login
      full_userland_fail full-userland-openssh-scp-transfer
      full_userland_fail full-userland-openssh-sftp-transfer
      full_userland_fail full-userland-openssh-local-forward
      full_userland_fail full-userland-openssh-remote-forward
    fi
  else
    full_userland_fail full-userland-ssh-test-user
    full_userland_fail full-userland-ssh-keygen
    full_userland_fail full-userland-ssh-local-login
    full_userland_fail full-userland-openssh-local-login
    full_userland_fail full-userland-openssh-scp-transfer
    full_userland_fail full-userland-openssh-sftp-transfer
    full_userland_fail full-userland-openssh-local-forward
    full_userland_fail full-userland-openssh-remote-forward
  fi
  check_full_userland_python_int_preflight runtime-after-ssh
  rm -rf "$ssh_login_dir"

  if systemctl cat cron.service >/dev/null 2>&1; then
    pass full-userland-cron-unit
  else
    full_userland_fail full-userland-cron-unit
  fi
  if systemctl start cron.service >/dev/null 2>&1 &&
     systemctl --quiet is-active cron.service; then
    pass full-userland-cron-active
  else
    systemctl status --no-pager cron.service 2>/dev/null || true
    full_userland_fail full-userland-cron-active
  fi
  cron_probe_job=/etc/cron.d/nemu-full-cron-check
  cron_probe_file=/run/nemu-full-cron.out
  cron_job_timeout=${NEMU_GUEST_CRON_JOB_TIMEOUT:-180}
  rm -f "$cron_probe_file"
  cat >"$cron_probe_job" <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * root /bin/sh -c 'printf "nemu-full-cron-ok\n" > /run/nemu-full-cron.out'
EOF
  chmod 0644 "$cron_probe_job"
  echo "__NEMU_CHECK_FULL_CRON_JOB_TIMEOUT__:$cron_job_timeout"
  echo "__NEMU_CHECK_FULL_CRON_JOB__:$cron_probe_job:$cron_probe_file"
  cron_probe_elapsed=0
  cron_probe_ok=0
  while [ "$cron_probe_elapsed" -lt "$cron_job_timeout" ]; do
    if [ "$(cat "$cron_probe_file" 2>/dev/null || true)" = "nemu-full-cron-ok" ]; then
      cron_probe_ok=1
      break
    fi
    sleep 2
    cron_probe_elapsed=$((cron_probe_elapsed + 2))
  done
  if [ "$cron_probe_ok" != "1" ] &&
     [ "$(cat "$cron_probe_file" 2>/dev/null || true)" = "nemu-full-cron-ok" ]; then
    cron_probe_ok=1
  fi
  echo "__NEMU_CHECK_FULL_CRON_EXEC_WAIT_SECONDS__:$cron_probe_elapsed"
  echo "__NEMU_CHECK_FULL_CRON_EXEC_FILE__:$cron_probe_ok:$cron_probe_file"
  if [ "$cron_probe_ok" = "1" ]; then
    pass full-userland-cron-exec
  else
    echo "__NEMU_CHECK_FULL_CRON_STATUS_BEGIN__"
    sed -n '1,40p' "$cron_probe_job" 2>/dev/null || true
    systemctl status --no-pager cron.service 2>/dev/null || true
    journalctl -u cron.service --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    tail -80 /var/log/syslog 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_CRON_STATUS_END__"
    full_userland_fail full-userland-cron-exec
  fi
  rm -f "$cron_probe_job"

  anacron_timeout=${NEMU_GUEST_ANACRON_TIMEOUT:-120}
  anacron_probe_tab=/run/nemu-full-anacron.tab
  anacron_probe_spool=/run/nemu-full-anacron-spool
  anacron_probe_file=/run/nemu-full-anacron.out
  anacron_probe_log=/run/nemu-full-anacron.log
  rm -f "$anacron_probe_tab" "$anacron_probe_file" "$anacron_probe_log"
  rm -rf "$anacron_probe_spool"
  mkdir -p "$anacron_probe_spool"
  cat >"$anacron_probe_tab" <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
1 0 nemu-full-anacron-test /bin/sh -c 'printf nemu-full-anacron-ok > /run/nemu-full-anacron.out'
EOF
  anacron_version="$(/usr/sbin/anacron -V 2>&1 | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_ANACRON_VERSION__:$anacron_version"
  echo "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__:$anacron_timeout"
  echo "__NEMU_CHECK_FULL_ANACRON_TAB__:$anacron_probe_tab:$anacron_probe_spool:$anacron_probe_file"
  if systemctl cat anacron.service >/dev/null 2>&1 &&
     systemctl cat anacron.timer >/dev/null 2>&1; then
    echo "__NEMU_CHECK_FULL_ANACRON_UNITS__:anacron.service:anacron.timer"
    pass full-userland-anacron-units
  else
    systemctl status --no-pager anacron.service 2>/dev/null || true
    systemctl status --no-pager anacron.timer 2>/dev/null || true
    full_userland_fail full-userland-anacron-units
  fi
  anacron_probe_rc=0
  timeout "${anacron_timeout}s" /usr/sbin/anacron \
    -d -f -n -s \
    -t "$anacron_probe_tab" \
    -S "$anacron_probe_spool" \
    >"$anacron_probe_log" 2>&1 || anacron_probe_rc=$?
  anacron_probe_value="$(cat "$anacron_probe_file" 2>/dev/null | tr -d '\n' || true)"
  echo "__NEMU_CHECK_FULL_ANACRON_RC__:$anacron_probe_rc"
  echo "__NEMU_CHECK_FULL_ANACRON_OUTPUT__:$anacron_probe_value"
  echo "__NEMU_CHECK_FULL_ANACRON_LOG_BEGIN__"
  sed -n '1,80p' "$anacron_probe_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_ANACRON_LOG_END__"
  if [ "$anacron_probe_rc" = "0" ] &&
     [ "$anacron_probe_value" = "nemu-full-anacron-ok" ]; then
    pass full-userland-anacron-run
  else
    full_userland_fail full-userland-anacron-run
  fi
  rm -f "$anacron_probe_tab" "$anacron_probe_file" "$anacron_probe_log"
  rm -rf "$anacron_probe_spool"

  rsyslog_probe_tag=nemu-full-rsyslog
  rsyslog_probe_file=/var/log/nemu-full-rsyslog.log
  rsyslog_probe_conf=/etc/rsyslog.d/99-nemu-full-rsyslog-check.conf
  rm -f "$rsyslog_probe_file"
  mkdir -p /etc/rsyslog.d
  : >"$rsyslog_probe_file"
  if getent group adm >/dev/null 2>&1; then
    chown syslog:adm "$rsyslog_probe_file" 2>/dev/null || true
  else
    chown syslog:syslog "$rsyslog_probe_file" 2>/dev/null || true
  fi
  chmod 0640 "$rsyslog_probe_file" 2>/dev/null || true
  {
    printf "if \$programname == '%s' then %s\n" "$rsyslog_probe_tag" "$rsyslog_probe_file"
    printf '& stop\n'
  } >"$rsyslog_probe_conf"
  echo "__NEMU_CHECK_FULL_RSYSLOG_PROBE_CONF__:$rsyslog_probe_conf:$rsyslog_probe_file"
  rsyslog_rc=0
  rsyslog_check="$(/usr/sbin/rsyslogd -N1 2>&1)" || rsyslog_rc=$?
  echo "__NEMU_CHECK_FULL_RSYSLOG_CONFIG_BEGIN__"
  printf '%s\n' "$rsyslog_check" | sed -n '1,20p'
  echo "__NEMU_CHECK_FULL_RSYSLOG_CONFIG_END__"
  if [ "$rsyslog_rc" = "0" ]; then
    pass full-userland-rsyslog-config
  else
    full_userland_fail full-userland-rsyslog-config
  fi
  if systemctl cat rsyslog.service >/dev/null 2>&1; then
    pass full-userland-rsyslog-unit
  else
    full_userland_fail full-userland-rsyslog-unit
  fi
  systemctl start syslog.socket >/dev/null 2>&1 || true
  if systemctl restart rsyslog.service >/dev/null 2>&1 &&
     systemctl --quiet is-active rsyslog.service; then
    pass full-userland-rsyslog-active
  else
    systemctl status --no-pager syslog.socket 2>/dev/null || true
    systemctl status --no-pager rsyslog.service 2>/dev/null || true
    full_userland_fail full-userland-rsyslog-active
  fi
  rsyslog_probe_msg="nemu-full-rsyslog-ok-$(date +%s)"
  rsyslog_probe_rc=0
  logger -p user.notice -t "$rsyslog_probe_tag" "$rsyslog_probe_msg" ||
    rsyslog_probe_rc=$?
  rsyslog_probe_i=0
  rsyslog_probe_log=
  while [ "$rsyslog_probe_i" -lt 30 ]; do
    if grep -Fq "$rsyslog_probe_msg" "$rsyslog_probe_file" 2>/dev/null; then
      rsyslog_probe_log=$rsyslog_probe_file
      break
    fi
    sleep 1
    rsyslog_probe_i=$((rsyslog_probe_i + 1))
  done
  echo "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_RC__:$rsyslog_probe_rc"
  echo "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_FILE__:$rsyslog_probe_log"
  if [ "$rsyslog_probe_rc" = "0" ] && [ -n "$rsyslog_probe_log" ]; then
    pass full-userland-rsyslog-logger
  else
    echo "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_LOG_BEGIN__"
    cat "$rsyslog_probe_conf" 2>/dev/null || true
    tail -80 "$rsyslog_probe_file" 2>/dev/null || true
    systemctl status --no-pager syslog.socket 2>/dev/null || true
    systemctl status --no-pager rsyslog.service 2>/dev/null || true
    tail -80 /var/log/syslog /var/log/messages 2>/dev/null || true
    journalctl -t "$rsyslog_probe_tag" --no-pager -n 40 2>/dev/null | sed -n '1,40p' || true
    echo "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_LOG_END__"
    full_userland_fail full-userland-rsyslog-logger
  fi

  logrotate_version="$(/usr/sbin/logrotate --version 2>&1 | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_LOGROTATE_VERSION__:$logrotate_version"
  if echo "$logrotate_version" | grep -Eiq '^logrotate '; then
    pass full-userland-logrotate-version
  else
    full_userland_fail full-userland-logrotate-version
  fi
  if systemctl cat logrotate.service >/dev/null 2>&1 &&
     systemctl cat logrotate.timer >/dev/null 2>&1; then
    pass full-userland-logrotate-units
  else
    full_userland_fail full-userland-logrotate-units
  fi
  logrotate_probe_conf=/tmp/nemu-full-logrotate.conf
  logrotate_probe_state=/tmp/nemu-full-logrotate.state
  logrotate_probe_log=/var/log/nemu-full-logrotate.log
  logrotate_probe_rotated=/var/log/nemu-full-logrotate.log.1
  rm -f "$logrotate_probe_conf" "$logrotate_probe_state" "$logrotate_probe_log" "$logrotate_probe_rotated"
  printf 'nemu-full-logrotate-before\n' >"$logrotate_probe_log"
  cat >"$logrotate_probe_conf" <<'EOF'
/var/log/nemu-full-logrotate.log {
  rotate 1
  size 1
  missingok
  notifempty
  su root root
  create 0644 root root
}
EOF
  logrotate_probe_rc=0
  logrotate_probe_output="$(/usr/sbin/logrotate -vf -s "$logrotate_probe_state" "$logrotate_probe_conf" 2>&1)" ||
    logrotate_probe_rc=$?
  logrotate_probe_new_size="$(wc -c < "$logrotate_probe_log" 2>/dev/null | tr -d ' ' || true)"
  logrotate_probe_rotated_content="$(cat "$logrotate_probe_rotated" 2>/dev/null | tr -d '\n' || true)"
  echo "__NEMU_CHECK_FULL_LOGROTATE_RC__:$logrotate_probe_rc"
  echo "__NEMU_CHECK_FULL_LOGROTATE_STATE__:$logrotate_probe_state"
  echo "__NEMU_CHECK_FULL_LOGROTATE_NEW_SIZE__:$logrotate_probe_new_size"
  echo "__NEMU_CHECK_FULL_LOGROTATE_ROTATED__:$logrotate_probe_rotated_content"
  echo "__NEMU_CHECK_FULL_LOGROTATE_OUTPUT_BEGIN__"
  printf '%s\n' "$logrotate_probe_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_LOGROTATE_OUTPUT_END__"
  if [ "$logrotate_probe_rc" = "0" ] &&
     [ -f "$logrotate_probe_state" ] &&
     [ "$logrotate_probe_new_size" = "0" ] &&
     [ "$logrotate_probe_rotated_content" = "nemu-full-logrotate-before" ]; then
    pass full-userland-logrotate-rotate
  else
    full_userland_fail full-userland-logrotate-rotate
  fi

  timesyncd_ntp_timeout=${NEMU_GUEST_TIMESYNCD_NTP_TIMEOUT:-120}
  timesyncd_ntp_conf_ok=0
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    timesyncd_ntp_conf_dir=/etc/systemd/timesyncd.conf.d
    timesyncd_ntp_conf="$timesyncd_ntp_conf_dir/99-nemu-hostless-ntp.conf"
    mkdir -p "$timesyncd_ntp_conf_dir"
    # 先写 hostless NTP 配置再启动 timesyncd，避免依赖 guest 内 restart/reload 慢路径。
    cat >"$timesyncd_ntp_conf" <<'EOF'
[Time]
NTP=10.0.2.2
FallbackNTP=
RootDistanceMaxSec=30
PollIntervalMinSec=16
PollIntervalMaxSec=32
EOF
    if grep -Fq 'NTP=10.0.2.2' "$timesyncd_ntp_conf" &&
       grep -Fq 'FallbackNTP=' "$timesyncd_ntp_conf"; then
      timesyncd_ntp_conf_ok=1
    fi
  fi

  if systemctl cat systemd-timesyncd.service >/dev/null 2>&1; then
    pass full-userland-timesyncd-unit
  else
    full_userland_fail full-userland-timesyncd-unit
  fi
  if systemctl start systemd-timesyncd.service >/dev/null 2>&1 &&
     systemctl --quiet is-active systemd-timesyncd.service; then
    pass full-userland-timesyncd-active
  else
    systemctl status --no-pager systemd-timesyncd.service 2>/dev/null || true
    full_userland_fail full-userland-timesyncd-active
  fi

  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_TIMEOUT__:$timesyncd_ntp_timeout"
    echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_CONF__:$timesyncd_ntp_conf_ok:$timesyncd_ntp_conf"
    timesyncd_ntp_active=unknown
    timesyncd_ntp_active="$(
      timeout 10s env SYSTEMD_BUS_TIMEOUT=5s \
        systemctl show --property=ActiveState --value systemd-timesyncd.service 2>/dev/null |
        sed -n '1p'
    )" || timesyncd_ntp_active=unknown

    echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_ACTIVE__:$timesyncd_ntp_active"
    echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_DEFERRED__:after-virtio-net-route"
  else
    echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_SKIP__:backend=${NEMU_GUEST_NET_BACKEND:-hostless}"
  fi

  resolved_dns_timeout=${NEMU_GUEST_RESOLVED_DNS_TIMEOUT:-90}
  resolved_dns_conf_ok=0
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    resolved_dns_conf_dir=/etc/systemd/resolved.conf.d
    resolved_dns_conf="$resolved_dns_conf_dir/99-nemu-hostless-dns.conf"
    mkdir -p "$resolved_dns_conf_dir"
    # 先写 hostless DNS 配置再启动 resolved；真正查询等 virtio-net route/DNS probe 完成后再做。
    cat >"$resolved_dns_conf" <<'EOF'
[Resolve]
DNS=10.0.2.2
Domains=~.
DNSSEC=no
DNSOverTLS=no
EOF
    if grep -Fq 'DNS=10.0.2.2' "$resolved_dns_conf" &&
       grep -Fq 'Domains=~.' "$resolved_dns_conf"; then
      resolved_dns_conf_ok=1
    fi
  fi

  resolvectl_version="$(resolvectl --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_RESOLVECTL_VERSION__:$resolvectl_version"
  if echo "$resolvectl_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-resolvectl-version
  else
    full_userland_fail full-userland-resolvectl-version
  fi
  if systemctl cat systemd-resolved.service >/dev/null 2>&1; then
    pass full-userland-systemd-resolved-unit
  else
    full_userland_fail full-userland-systemd-resolved-unit
  fi
  if systemctl start systemd-resolved.service >/dev/null 2>&1 &&
     systemctl --quiet is-active systemd-resolved.service; then
    pass full-userland-systemd-resolved-active
  else
    systemctl status --no-pager systemd-resolved.service 2>/dev/null || true
    full_userland_fail full-userland-systemd-resolved-active
  fi

  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" = "hostless" ]; then
    echo "__NEMU_CHECK_FULL_RESOLVED_DNS_TIMEOUT__:$resolved_dns_timeout"
    echo "__NEMU_CHECK_FULL_RESOLVED_DNS_CONF__:$resolved_dns_conf_ok:$resolved_dns_conf"
    resolved_dns_active=unknown
    resolved_dns_active="$(
      timeout 10s env SYSTEMD_BUS_TIMEOUT=5s \
        systemctl show --property=ActiveState --value systemd-resolved.service 2>/dev/null |
        sed -n '1p'
    )" || resolved_dns_active=unknown
    echo "__NEMU_CHECK_FULL_RESOLVED_DNS_ACTIVE__:$resolved_dns_active"
    echo "__NEMU_CHECK_FULL_RESOLVED_DNS_QUERY_DEFERRED__:after-virtio-net-dns-probe"
  else
    echo "__NEMU_CHECK_FULL_RESOLVED_DNS_SKIP__:backend=${NEMU_GUEST_NET_BACKEND:-hostless}"
  fi

  systemd_run_version="$(/usr/bin/systemd-run --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_VERSION__:$systemd_run_version"
  if echo "$systemd_run_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-systemd-run-version
  else
    full_userland_fail full-userland-systemd-run-version
  fi

  transient_service_unit=nemu-full-transient.service
  transient_service_output=/run/nemu-full-transient-service.out
  transient_service_log=/tmp/nemu-full-systemd-run-service.log
  rm -f "$transient_service_output" "$transient_service_log"
  systemctl stop "$transient_service_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$transient_service_unit" >/dev/null 2>&1 || true
  transient_service_rc=0
  /usr/bin/systemd-run \
    --unit="$transient_service_unit" \
    --wait \
    --collect \
    /bin/sh -c 'printf systemd-run-service-ok > /run/nemu-full-transient-service.out' \
    >"$transient_service_log" 2>&1 || transient_service_rc=$?
  transient_service_value="$(cat "$transient_service_output" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_SERVICE_UNIT__:$transient_service_unit:$transient_service_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_SERVICE_RC__:$transient_service_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_SERVICE_OUTPUT__:$transient_service_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_SERVICE_LOG_BEGIN__"
  sed -n '1,120p' "$transient_service_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_SERVICE_LOG_END__"
  if [ "$transient_service_rc" = "0" ] &&
     [ "$transient_service_value" = "systemd-run-service-ok" ]; then
    pass full-userland-systemd-run-transient-service
  else
    systemctl status "$transient_service_unit" --no-pager 2>/dev/null || true
    journalctl -u "$transient_service_unit" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    full_userland_fail full-userland-systemd-run-transient-service
  fi
  systemctl stop "$transient_service_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$transient_service_unit" >/dev/null 2>&1 || true

  transient_timer_base=nemu-full-transient-timer
  transient_timer_service=${transient_timer_base}.service
  transient_timer_unit=${transient_timer_base}.timer
  transient_timer_output=/run/nemu-full-transient-timer.out
  transient_timer_log=/tmp/nemu-full-systemd-run-timer.log
  rm -f "$transient_timer_output" "$transient_timer_log"
  systemctl stop "$transient_timer_unit" "$transient_timer_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$transient_timer_unit" "$transient_timer_service" >/dev/null 2>&1 || true
  transient_timer_rc=0
  /usr/bin/systemd-run \
    --unit="$transient_timer_base" \
    --on-active=5s \
    --timer-property=AccuracySec=1s \
    --collect \
    /bin/sh -c 'printf systemd-run-timer-ok > /run/nemu-full-transient-timer.out' \
    >"$transient_timer_log" 2>&1 || transient_timer_rc=$?
  transient_timer_elapsed=0
  transient_timer_ok=0
  while [ "$transient_timer_elapsed" -lt 60 ]; do
    if [ "$(cat "$transient_timer_output" 2>/dev/null || true)" = "systemd-run-timer-ok" ]; then
      transient_timer_ok=1
      break
    fi
    sleep 1
    transient_timer_elapsed=$((transient_timer_elapsed + 1))
  done
  transient_timer_value="$(cat "$transient_timer_output" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_UNIT__:$transient_timer_unit:$transient_timer_service:$transient_timer_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_RC__:$transient_timer_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_WAIT_SECONDS__:$transient_timer_elapsed"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_OUTPUT__:$transient_timer_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_LOG_BEGIN__"
  sed -n '1,120p' "$transient_timer_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSTEMD_RUN_TIMER_LOG_END__"
  if [ "$transient_timer_rc" = "0" ] &&
     [ "$transient_timer_ok" = "1" ]; then
    pass full-userland-systemd-run-transient-timer
  else
    systemctl list-timers --all --no-pager 2>/dev/null | sed -n '1,80p' || true
    systemctl status "$transient_timer_unit" "$transient_timer_service" --no-pager 2>/dev/null || true
    journalctl -u "$transient_timer_unit" -u "$transient_timer_service" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    full_userland_fail full-userland-systemd-run-transient-timer
  fi
  systemctl stop "$transient_timer_unit" "$transient_timer_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$transient_timer_unit" "$transient_timer_service" >/dev/null 2>&1 || true

  calendar_timer_timeout=${NEMU_GUEST_CALENDAR_TIMER_TIMEOUT:-90}
  calendar_timer_base=nemu-full-calendar-timer
  calendar_timer_service=${calendar_timer_base}.service
  calendar_timer_unit=${calendar_timer_base}.timer
  calendar_timer_service_path=/run/systemd/system/$calendar_timer_service
  calendar_timer_unit_path=/run/systemd/system/$calendar_timer_unit
  calendar_timer_output=/run/nemu-full-calendar-timer.out
  calendar_timer_log=/tmp/nemu-full-calendar-timer.log
  rm -f "$calendar_timer_output" "$calendar_timer_log" \
    "$calendar_timer_service_path" "$calendar_timer_unit_path"
  systemctl stop "$calendar_timer_unit" "$calendar_timer_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$calendar_timer_unit" "$calendar_timer_service" >/dev/null 2>&1 || true
  cat >"$calendar_timer_service_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu calendar timer service smoke

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'printf systemd-calendar-timer-ok > /run/nemu-full-calendar-timer.out'
UNIT
  cat >"$calendar_timer_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu calendar timer smoke

[Timer]
OnCalendar=*-*-* *:*:*
AccuracySec=1s
RandomizedDelaySec=0
Unit=nemu-full-calendar-timer.service

[Install]
WantedBy=timers.target
UNIT
  calendar_timer_rc=0
  calendar_timer_elapsed=0
  calendar_timer_ok=0
  calendar_timer_reload_ok=0
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_FILES__:$calendar_timer_unit_path:$calendar_timer_service_path"
  if systemd_daemon_reload_request "$calendar_timer_unit" calendar-timer; then
    calendar_timer_reload_ok=1
    timeout 30s env SYSTEMD_BUS_TIMEOUT=5s systemctl start "$calendar_timer_unit" \
      >"$calendar_timer_log" 2>&1 || calendar_timer_rc=$?
  else
    calendar_timer_rc=$?
  fi
  while [ "$calendar_timer_elapsed" -lt "$calendar_timer_timeout" ]; do
    if [ "$(cat "$calendar_timer_output" 2>/dev/null || true)" = "systemd-calendar-timer-ok" ]; then
      calendar_timer_ok=1
      break
    fi
    sleep 1
    calendar_timer_elapsed=$((calendar_timer_elapsed + 1))
  done
  calendar_timer_value="$(cat "$calendar_timer_output" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_TIMEOUT__:$calendar_timer_timeout"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_UNIT__:$calendar_timer_unit:$calendar_timer_service:$calendar_timer_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_RELOAD_OK__:$calendar_timer_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_RC__:$calendar_timer_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_WAIT_SECONDS__:$calendar_timer_elapsed"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_OUTPUT__:$calendar_timer_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_LIST_BEGIN__"
  systemctl list-timers --all --no-pager "$calendar_timer_unit" 2>/dev/null | sed -n '1,80p' || true
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_LIST_END__"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_LOG_BEGIN__"
  sed -n '1,120p' "$calendar_timer_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSTEMD_CALENDAR_TIMER_LOG_END__"
  if [ "$calendar_timer_reload_ok" = "1" ] &&
     [ "$calendar_timer_ok" = "1" ]; then
    pass full-userland-systemd-calendar-timer
  else
    systemctl status "$calendar_timer_unit" "$calendar_timer_service" --no-pager 2>/dev/null || true
    journalctl -u "$calendar_timer_unit" -u "$calendar_timer_service" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    full_userland_fail full-userland-systemd-calendar-timer
  fi
  systemctl stop "$calendar_timer_unit" "$calendar_timer_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$calendar_timer_unit" "$calendar_timer_service" >/dev/null 2>&1 || true
  rm -f "$calendar_timer_output" "$calendar_timer_log" \
    "$calendar_timer_service_path" "$calendar_timer_unit_path"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true

  resource_control_unit=nemu-full-resource-control.service
  resource_control_unit_path=/run/systemd/system/$resource_control_unit
  resource_control_output=/run/nemu-full-resource-control.out
  resource_control_cgroup_file=/run/nemu-full-resource-control.cgroup
  rm -f "$resource_control_unit_path" "$resource_control_output" "$resource_control_cgroup_file"
  systemctl stop "$resource_control_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$resource_control_unit" >/dev/null 2>&1 || true
  cat >"$resource_control_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd resource-control smoke
After=basic.target

[Service]
Type=simple
MemoryAccounting=yes
MemoryMax=64M
CPUAccounting=yes
TasksAccounting=yes
TasksMax=64
ExecStart=/bin/sh -c 'printf systemd-resource-control-ok > /run/nemu-full-resource-control.out; cat /proc/self/cgroup > /run/nemu-full-resource-control.cgroup; sleep 120'
UNIT
  resource_control_reload_ok=0
  resource_control_start_ok=0
  if systemd_daemon_reload_request "$resource_control_unit" resource-control; then
    resource_control_reload_ok=1
    if systemd_start_runtime_unit_after_reload "$resource_control_unit" "$resource_control_output"; then
      resource_control_start_ok=1
    fi
  fi
  resource_control_value="$(cat "$resource_control_output" 2>/dev/null || true)"
  resource_control_cgroup="$(sed -n 's/^0:://p' "$resource_control_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  resource_control_cgroup_dir=/sys/fs/cgroup$resource_control_cgroup
  resource_control_memory_max="$(cat "$resource_control_cgroup_dir/memory.max" 2>/dev/null || true)"
  resource_control_pids_max="$(cat "$resource_control_cgroup_dir/pids.max" 2>/dev/null || true)"
  resource_control_show_memory_accounting="$(systemctl show --property=MemoryAccounting --value "$resource_control_unit" 2>/dev/null || true)"
  resource_control_show_cpu_accounting="$(systemctl show --property=CPUAccounting --value "$resource_control_unit" 2>/dev/null || true)"
  resource_control_show_tasks_accounting="$(systemctl show --property=TasksAccounting --value "$resource_control_unit" 2>/dev/null || true)"
  resource_control_show_memory_max="$(systemctl show --property=MemoryMax --value "$resource_control_unit" 2>/dev/null || true)"
  resource_control_show_tasks_max="$(systemctl show --property=TasksMax --value "$resource_control_unit" 2>/dev/null || true)"
  resource_control_active="$(systemctl show --property=ActiveState --value "$resource_control_unit" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_UNIT__:$resource_control_unit:$resource_control_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_RELOAD_OK__:$resource_control_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_START_OK__:$resource_control_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_ACTIVE__:$resource_control_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_OUTPUT__:$resource_control_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_CGROUP__:$resource_control_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_MEMORY_MAX__:$resource_control_memory_max"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_PIDS_MAX__:$resource_control_pids_max"
  echo "__NEMU_CHECK_FULL_SYSTEMD_RESOURCE_CONTROL_SHOW__:$resource_control_show_memory_accounting:$resource_control_show_memory_max:$resource_control_show_cpu_accounting:$resource_control_show_tasks_accounting:$resource_control_show_tasks_max"
  if [ "$resource_control_reload_ok" = "1" ] &&
     [ "$resource_control_start_ok" = "1" ] &&
     [ "$resource_control_active" = "active" ] &&
     [ "$resource_control_value" = "systemd-resource-control-ok" ] &&
     [ "$resource_control_memory_max" = "67108864" ] &&
     [ "$resource_control_pids_max" = "64" ] &&
     [ "$resource_control_show_memory_accounting" = "yes" ] &&
     [ "$resource_control_show_cpu_accounting" = "yes" ] &&
     [ "$resource_control_show_tasks_accounting" = "yes" ]; then
    pass full-userland-systemd-resource-control
  else
    systemctl status "$resource_control_unit" --no-pager 2>/dev/null || true
    journalctl -u "$resource_control_unit" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    if [ -n "$resource_control_cgroup" ]; then
      find "$resource_control_cgroup_dir" -maxdepth 1 -type f \
        \( -name 'memory.*' -o -name 'pids.*' -o -name 'cpu.*' \) \
        -print -exec sed -n '1,20p' {} \; 2>/dev/null | sed -n '1,120p' || true
    fi
    full_userland_fail full-userland-systemd-resource-control
  fi
  systemctl stop "$resource_control_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$resource_control_unit" >/dev/null 2>&1 || true
  rm -f "$resource_control_unit_path" "$resource_control_output" "$resource_control_cgroup_file"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true

  cpu_quota_unit=nemu-full-cpu-quota.service
  cpu_quota_unit_path=/run/systemd/system/$cpu_quota_unit
  cpu_quota_output=/run/nemu-full-cpu-quota.out
  cpu_quota_cgroup_file=/run/nemu-full-cpu-quota.cgroup
  rm -f "$cpu_quota_unit_path" "$cpu_quota_output" "$cpu_quota_cgroup_file"
  systemctl stop "$cpu_quota_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$cpu_quota_unit" >/dev/null 2>&1 || true
  cat >"$cpu_quota_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd CPU quota smoke
After=basic.target

[Service]
Type=simple
CPUAccounting=yes
CPUQuota=50%
CPUQuotaPeriodSec=100ms
ExecStart=/bin/sh -c 'printf systemd-cpu-quota-ok > /run/nemu-full-cpu-quota.out; cat /proc/self/cgroup > /run/nemu-full-cpu-quota.cgroup; sleep 120'
UNIT
  cpu_quota_reload_ok=0
  cpu_quota_start_ok=0
  if systemd_daemon_reload_request "$cpu_quota_unit" cpu-quota; then
    cpu_quota_reload_ok=1
    if systemd_start_runtime_unit_after_reload "$cpu_quota_unit" "$cpu_quota_output"; then
      cpu_quota_start_ok=1
    fi
  fi
  cpu_quota_value="$(cat "$cpu_quota_output" 2>/dev/null || true)"
  cpu_quota_cgroup="$(sed -n 's/^0:://p' "$cpu_quota_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  cpu_quota_cgroup_dir=/sys/fs/cgroup$cpu_quota_cgroup
  cpu_quota_cpu_max="$(cat "$cpu_quota_cgroup_dir/cpu.max" 2>/dev/null || true)"
  cpu_quota_cpu_stat_readable=0
  [ -r "$cpu_quota_cgroup_dir/cpu.stat" ] && cpu_quota_cpu_stat_readable=1
  cpu_quota_show_cpu_accounting="$(systemctl show --property=CPUAccounting --value "$cpu_quota_unit" 2>/dev/null || true)"
  cpu_quota_show_cpu_quota="$(systemctl show --property=CPUQuotaPerSecUSec --value "$cpu_quota_unit" 2>/dev/null || true)"
  cpu_quota_show_cpu_period="$(systemctl show --property=CPUQuotaPeriodUSec --value "$cpu_quota_unit" 2>/dev/null || true)"
  cpu_quota_active="$(systemctl show --property=ActiveState --value "$cpu_quota_unit" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_UNIT__:$cpu_quota_unit:$cpu_quota_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_RELOAD_OK__:$cpu_quota_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_START_OK__:$cpu_quota_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_ACTIVE__:$cpu_quota_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_OUTPUT__:$cpu_quota_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_CGROUP__:$cpu_quota_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_CPU_MAX__:$cpu_quota_cpu_max"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_CPU_STAT_READABLE__:$cpu_quota_cpu_stat_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_CPU_QUOTA_SHOW__:$cpu_quota_show_cpu_accounting:$cpu_quota_show_cpu_quota:$cpu_quota_show_cpu_period"
  if [ "$cpu_quota_reload_ok" = "1" ] &&
     [ "$cpu_quota_start_ok" = "1" ] &&
     [ "$cpu_quota_active" = "active" ] &&
     [ "$cpu_quota_value" = "systemd-cpu-quota-ok" ] &&
     [ "$cpu_quota_cgroup" = "/system.slice/$cpu_quota_unit" ] &&
     [ "$cpu_quota_cpu_max" = "50000 100000" ] &&
     [ "$cpu_quota_cpu_stat_readable" = "1" ] &&
     [ "$cpu_quota_show_cpu_accounting" = "yes" ]; then
    pass full-userland-systemd-cpu-quota
  else
    systemctl status "$cpu_quota_unit" --no-pager 2>/dev/null || true
    journalctl -u "$cpu_quota_unit" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    if [ -n "$cpu_quota_cgroup" ]; then
      find "$cpu_quota_cgroup_dir" -maxdepth 1 -type f \
        \( -name 'cgroup.*' -o -name 'cpu.*' \) \
        -print -exec sed -n '1,20p' {} \; 2>/dev/null | sed -n '1,120p' || true
    fi
    full_userland_fail full-userland-systemd-cpu-quota
  fi
  systemctl stop "$cpu_quota_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$cpu_quota_unit" >/dev/null 2>&1 || true
  rm -f "$cpu_quota_unit_path" "$cpu_quota_output" "$cpu_quota_cgroup_file"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true

  pressure_feedback_unit=nemu-full-pressure-feedback.service
  pressure_feedback_unit_path=/run/systemd/system/$pressure_feedback_unit
  pressure_feedback_output=/run/nemu-full-pressure-feedback.out
  pressure_feedback_cgroup_file=/run/nemu-full-pressure-feedback.cgroup
  rm -f "$pressure_feedback_unit_path" "$pressure_feedback_output" "$pressure_feedback_cgroup_file"
  systemctl stop "$pressure_feedback_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$pressure_feedback_unit" >/dev/null 2>&1 || true
  cat >"$pressure_feedback_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd PSI pressure feedback smoke
After=basic.target

[Service]
Type=simple
MemoryAccounting=yes
CPUAccounting=yes
TasksAccounting=yes
ExecStart=/bin/sh -c 'printf systemd-pressure-feedback-ok > /run/nemu-full-pressure-feedback.out; cat /proc/self/cgroup > /run/nemu-full-pressure-feedback.cgroup; sleep 120'
UNIT
  pressure_feedback_reload_ok=0
  pressure_feedback_start_ok=0
  if systemd_daemon_reload_request "$pressure_feedback_unit" pressure-feedback; then
    pressure_feedback_reload_ok=1
    if systemd_start_runtime_unit_after_reload "$pressure_feedback_unit" "$pressure_feedback_output"; then
      pressure_feedback_start_ok=1
    fi
  fi
  pressure_feedback_value="$(cat "$pressure_feedback_output" 2>/dev/null || true)"
  pressure_feedback_cgroup="$(sed -n 's/^0:://p' "$pressure_feedback_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  pressure_feedback_cgroup_dir=/sys/fs/cgroup$pressure_feedback_cgroup
  pressure_feedback_active="$(systemctl show --property=ActiveState --value "$pressure_feedback_unit" 2>/dev/null || true)"
  pressure_feedback_show_memory_accounting="$(systemctl show --property=MemoryAccounting --value "$pressure_feedback_unit" 2>/dev/null || true)"
  pressure_feedback_show_cpu_accounting="$(systemctl show --property=CPUAccounting --value "$pressure_feedback_unit" 2>/dev/null || true)"
  pressure_feedback_proc_cpu_readable=0
  pressure_feedback_proc_memory_readable=0
  pressure_feedback_proc_io_readable=0
  pressure_feedback_cgroup_cpu_readable=0
  pressure_feedback_cgroup_memory_readable=0
  pressure_feedback_cgroup_io_readable=0
  [ -r /proc/pressure/cpu ] && pressure_feedback_proc_cpu_readable=1
  [ -r /proc/pressure/memory ] && pressure_feedback_proc_memory_readable=1
  [ -r /proc/pressure/io ] && pressure_feedback_proc_io_readable=1
  [ -r "$pressure_feedback_cgroup_dir/cpu.pressure" ] && pressure_feedback_cgroup_cpu_readable=1
  [ -r "$pressure_feedback_cgroup_dir/memory.pressure" ] && pressure_feedback_cgroup_memory_readable=1
  [ -r "$pressure_feedback_cgroup_dir/io.pressure" ] && pressure_feedback_cgroup_io_readable=1
  pressure_feedback_proc_cpu_line="$(sed -n '1p' /proc/pressure/cpu 2>/dev/null || true)"
  pressure_feedback_proc_memory_line="$(sed -n '1p' /proc/pressure/memory 2>/dev/null || true)"
  pressure_feedback_proc_io_line="$(sed -n '1p' /proc/pressure/io 2>/dev/null || true)"
  pressure_feedback_cgroup_cpu_line="$(sed -n '1p' "$pressure_feedback_cgroup_dir/cpu.pressure" 2>/dev/null || true)"
  pressure_feedback_cgroup_memory_line="$(sed -n '1p' "$pressure_feedback_cgroup_dir/memory.pressure" 2>/dev/null || true)"
  pressure_feedback_cgroup_io_line="$(sed -n '1p' "$pressure_feedback_cgroup_dir/io.pressure" 2>/dev/null || true)"
  pressure_feedback_proc_cpu_some=0
  pressure_feedback_proc_memory_some=0
  pressure_feedback_proc_io_some=0
  pressure_feedback_cgroup_cpu_some=0
  pressure_feedback_cgroup_memory_some=0
  pressure_feedback_cgroup_io_some=0
  case "$pressure_feedback_proc_cpu_line" in some\ avg10=*) pressure_feedback_proc_cpu_some=1 ;; esac
  case "$pressure_feedback_proc_memory_line" in some\ avg10=*) pressure_feedback_proc_memory_some=1 ;; esac
  case "$pressure_feedback_proc_io_line" in some\ avg10=*) pressure_feedback_proc_io_some=1 ;; esac
  case "$pressure_feedback_cgroup_cpu_line" in some\ avg10=*) pressure_feedback_cgroup_cpu_some=1 ;; esac
  case "$pressure_feedback_cgroup_memory_line" in some\ avg10=*) pressure_feedback_cgroup_memory_some=1 ;; esac
  case "$pressure_feedback_cgroup_io_line" in some\ avg10=*) pressure_feedback_cgroup_io_some=1 ;; esac
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_UNIT__:$pressure_feedback_unit:$pressure_feedback_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_RELOAD_OK__:$pressure_feedback_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_START_OK__:$pressure_feedback_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_ACTIVE__:$pressure_feedback_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_OUTPUT__:$pressure_feedback_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP__:$pressure_feedback_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_CPU_READABLE__:$pressure_feedback_proc_cpu_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_MEMORY_READABLE__:$pressure_feedback_proc_memory_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_IO_READABLE__:$pressure_feedback_proc_io_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_CPU_READABLE__:$pressure_feedback_cgroup_cpu_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_MEMORY_READABLE__:$pressure_feedback_cgroup_memory_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_IO_READABLE__:$pressure_feedback_cgroup_io_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_CPU_SOME__:$pressure_feedback_proc_cpu_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_MEMORY_SOME__:$pressure_feedback_proc_memory_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_IO_SOME__:$pressure_feedback_proc_io_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_CPU_SOME__:$pressure_feedback_cgroup_cpu_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_MEMORY_SOME__:$pressure_feedback_cgroup_memory_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_CGROUP_IO_SOME__:$pressure_feedback_cgroup_io_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_SHOW__:$pressure_feedback_show_memory_accounting:$pressure_feedback_show_cpu_accounting"
  if [ "$pressure_feedback_reload_ok" = "1" ] &&
     [ "$pressure_feedback_start_ok" = "1" ] &&
     [ "$pressure_feedback_active" = "active" ] &&
     [ "$pressure_feedback_value" = "systemd-pressure-feedback-ok" ] &&
     [ "$pressure_feedback_cgroup" = "/system.slice/$pressure_feedback_unit" ] &&
     [ "$pressure_feedback_proc_cpu_readable" = "1" ] &&
     [ "$pressure_feedback_proc_memory_readable" = "1" ] &&
     [ "$pressure_feedback_proc_io_readable" = "1" ] &&
     [ "$pressure_feedback_cgroup_cpu_readable" = "1" ] &&
     [ "$pressure_feedback_cgroup_memory_readable" = "1" ] &&
     [ "$pressure_feedback_cgroup_io_readable" = "1" ] &&
     [ "$pressure_feedback_proc_cpu_some" = "1" ] &&
     [ "$pressure_feedback_proc_memory_some" = "1" ] &&
     [ "$pressure_feedback_proc_io_some" = "1" ] &&
     [ "$pressure_feedback_cgroup_cpu_some" = "1" ] &&
     [ "$pressure_feedback_cgroup_memory_some" = "1" ] &&
     [ "$pressure_feedback_cgroup_io_some" = "1" ] &&
     [ "$pressure_feedback_show_memory_accounting" = "yes" ] &&
     [ "$pressure_feedback_show_cpu_accounting" = "yes" ]; then
    pass full-userland-systemd-pressure-feedback
  else
    systemctl status "$pressure_feedback_unit" --no-pager 2>/dev/null || true
    journalctl -u "$pressure_feedback_unit" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_DUMP_BEGIN__"
    sed -n '1,20p' /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_PRESSURE_FEEDBACK_PROC_DUMP_END__"
    if [ -n "$pressure_feedback_cgroup" ]; then
      find "$pressure_feedback_cgroup_dir" -maxdepth 1 -type f \
        \( -name 'cgroup.*' -o -name '*.pressure' -o -name 'memory.*' -o -name 'cpu.*' \) \
        -print -exec sed -n '1,20p' {} \; 2>/dev/null | sed -n '1,160p' || true
    fi
    full_userland_fail full-userland-systemd-pressure-feedback
  fi
  systemctl stop "$pressure_feedback_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$pressure_feedback_unit" >/dev/null 2>&1 || true
  rm -f "$pressure_feedback_unit_path" "$pressure_feedback_output" "$pressure_feedback_cgroup_file"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true

  oom_policy_unit=nemu-full-oom-policy.service
  oom_policy_unit_path=/run/systemd/system/$oom_policy_unit
  oom_policy_output=/run/nemu-full-oom-policy.out
  oom_policy_cgroup_file=/run/nemu-full-oom-policy.cgroup
  oom_policy_alloc_script=/run/nemu-full-oom-policy-alloc.py
  oom_policy_alloc_log=/run/nemu-full-oom-policy.alloc.log
  oom_policy_memory_events_file=/run/nemu-full-oom-policy.memory.events
  oom_policy_stop_post=/run/nemu-full-oom-policy.stop-post
  rm -f "$oom_policy_unit_path" "$oom_policy_output" "$oom_policy_cgroup_file" \
    "$oom_policy_alloc_script" "$oom_policy_alloc_log" \
    "$oom_policy_memory_events_file" "$oom_policy_stop_post"
  systemctl stop "$oom_policy_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$oom_policy_unit" >/dev/null 2>&1 || true
  cat >"$oom_policy_alloc_script" <<'PY'
import time

chunks = []
while True:
    chunks.append(bytearray(1024 * 1024))
    time.sleep(0.02)
PY
  cat >"$oom_policy_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd OOM policy smoke
After=basic.target

[Service]
Type=simple
MemoryAccounting=yes
MemoryMax=64M
CPUAccounting=yes
TasksAccounting=yes
OOMPolicy=stop
KillMode=control-group
TimeoutStopSec=30s
ExecStart=/bin/sh -c 'printf systemd-oom-policy-started > /run/nemu-full-oom-policy.out; cat /proc/self/cgroup > /run/nemu-full-oom-policy.cgroup; /usr/bin/python3 /run/nemu-full-oom-policy-alloc.py > /run/nemu-full-oom-policy.alloc.log 2>&1 & sleep 120 & wait'
ExecStopPost=/bin/sh -c 'cat /sys/fs/cgroup/system.slice/nemu-full-oom-policy.service/memory.events > /run/nemu-full-oom-policy.memory.events 2>/dev/null || true; printf systemd-oom-policy-stop-post > /run/nemu-full-oom-policy.stop-post'
UNIT
  oom_policy_reload_ok=0
  oom_policy_start_ok=0
  if systemd_daemon_reload_request "$oom_policy_unit" oom-policy; then
    oom_policy_reload_ok=1
    if systemd_start_runtime_unit_after_reload "$oom_policy_unit" "$oom_policy_output"; then
      oom_policy_start_ok=1
    fi
  fi
  oom_policy_wait_seconds=0
  oom_policy_done=0
  oom_policy_active=""
  while [ "$oom_policy_wait_seconds" -lt 90 ]; do
    oom_policy_active="$(systemctl show --property=ActiveState --value "$oom_policy_unit" 2>/dev/null || true)"
    if [ -s "$oom_policy_memory_events_file" ]; then
      oom_policy_done=1
      break
    fi
    case "$oom_policy_active" in
      active|activating)
        ;;
      *)
        oom_policy_done=1
        break
        ;;
    esac
    sleep 1
    oom_policy_wait_seconds=$((oom_policy_wait_seconds + 1))
  done
  oom_policy_value="$(cat "$oom_policy_output" 2>/dev/null || true)"
  oom_policy_stop_post_value="$(cat "$oom_policy_stop_post" 2>/dev/null || true)"
  oom_policy_cgroup="$(sed -n 's/^0:://p' "$oom_policy_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  oom_policy_cgroup_dir=/sys/fs/cgroup$oom_policy_cgroup
  if [ ! -s "$oom_policy_memory_events_file" ] &&
     [ -r "$oom_policy_cgroup_dir/memory.events" ]; then
    cat "$oom_policy_cgroup_dir/memory.events" >"$oom_policy_memory_events_file" 2>/dev/null || true
  fi
  oom_policy_memory_events_oom="$(awk '$1 == "oom" {print $2}' "$oom_policy_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  oom_policy_memory_events_oom_kill="$(awk '$1 == "oom_kill" {print $2}' "$oom_policy_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  oom_policy_memory_events_max="$(awk '$1 == "max" {print $2}' "$oom_policy_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  case "$oom_policy_memory_events_oom" in ''|*[!0-9]*) oom_policy_memory_events_oom=0 ;; esac
  case "$oom_policy_memory_events_oom_kill" in ''|*[!0-9]*) oom_policy_memory_events_oom_kill=0 ;; esac
  case "$oom_policy_memory_events_max" in ''|*[!0-9]*) oom_policy_memory_events_max=0 ;; esac
  oom_policy_active_final="$(systemctl show --property=ActiveState --value "$oom_policy_unit" 2>/dev/null || true)"
  oom_policy_result="$(systemctl show --property=Result --value "$oom_policy_unit" 2>/dev/null || true)"
  oom_policy_show_oom_policy="$(systemctl show --property=OOMPolicy --value "$oom_policy_unit" 2>/dev/null || true)"
  oom_policy_show_memory_accounting="$(systemctl show --property=MemoryAccounting --value "$oom_policy_unit" 2>/dev/null || true)"
  oom_policy_show_memory_max="$(systemctl show --property=MemoryMax --value "$oom_policy_unit" 2>/dev/null || true)"
  oom_policy_stopped=0
  case "$oom_policy_active_final" in
    failed|inactive) oom_policy_stopped=1 ;;
  esac
  oom_policy_oom_result=0
  if [ "$oom_policy_result" = "oom-kill" ] ||
     [ "$oom_policy_memory_events_oom_kill" -ge 1 ]; then
    oom_policy_oom_result=1
  fi
  oom_policy_stop_post_seen=0
  [ "$oom_policy_stop_post_value" = "systemd-oom-policy-stop-post" ] && oom_policy_stop_post_seen=1
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_UNIT__:$oom_policy_unit:$oom_policy_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_RELOAD_OK__:$oom_policy_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_START_OK__:$oom_policy_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_WAIT_SECONDS__:$oom_policy_wait_seconds"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_DONE__:$oom_policy_done"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_OUTPUT__:$oom_policy_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_CGROUP__:$oom_policy_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_ACTIVE__:$oom_policy_active_final"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_RESULT__:$oom_policy_result"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_SHOW__:$oom_policy_show_oom_policy:$oom_policy_show_memory_accounting:$oom_policy_show_memory_max"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_STOP_POST__:$oom_policy_stop_post_seen:$oom_policy_stop_post_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_MEMORY_EVENTS_OOM__:$oom_policy_memory_events_oom"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_MEMORY_EVENTS_OOM_KILL__:$oom_policy_memory_events_oom_kill"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_MEMORY_EVENTS_MAX__:$oom_policy_memory_events_max"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_STOPPED__:$oom_policy_stopped"
  if [ "$oom_policy_reload_ok" = "1" ] &&
     [ "$oom_policy_start_ok" = "1" ] &&
     [ "$oom_policy_done" = "1" ] &&
     [ "$oom_policy_value" = "systemd-oom-policy-started" ] &&
     [ "$oom_policy_cgroup" = "/system.slice/$oom_policy_unit" ] &&
     [ "$oom_policy_show_oom_policy" = "stop" ] &&
     [ "$oom_policy_show_memory_accounting" = "yes" ] &&
     [ "$oom_policy_show_memory_max" = "67108864" ] &&
     [ "$oom_policy_stop_post_seen" = "1" ] &&
     [ "$oom_policy_stopped" = "1" ] &&
     [ "$oom_policy_oom_result" = "1" ]; then
    pass full-userland-systemd-oom-policy
  else
    systemctl status "$oom_policy_unit" --no-pager 2>/dev/null || true
    journalctl -u "$oom_policy_unit" --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_MEMORY_EVENTS_BEGIN__"
    sed -n '1,40p' "$oom_policy_memory_events_file" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_MEMORY_EVENTS_END__"
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_ALLOC_LOG_BEGIN__"
    sed -n '1,80p' "$oom_policy_alloc_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOM_POLICY_ALLOC_LOG_END__"
    full_userland_fail full-userland-systemd-oom-policy
  fi
  systemctl stop "$oom_policy_unit" >/dev/null 2>&1 || true
  systemctl reset-failed "$oom_policy_unit" >/dev/null 2>&1 || true
  rm -f "$oom_policy_unit_path" "$oom_policy_output" "$oom_policy_cgroup_file" \
    "$oom_policy_alloc_script" "$oom_policy_alloc_log" \
    "$oom_policy_memory_events_file" "$oom_policy_stop_post"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true

  oomd_unit=systemd-oomd.service
  oomd_dump=/run/nemu-full-systemd-oomd.dump
  oomd_files_ok=1
  for oomd_path in \
    /lib/systemd/systemd-oomd \
    /lib/systemd/system/systemd-oomd.service \
    /usr/bin/oomctl \
    /etc/systemd/oomd.conf \
    /usr/lib/systemd/oomd.conf.d/10-oomd-defaults.conf \
    /usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf \
    /usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf \
    /usr/lib/sysusers.d/systemd-oom.conf \
    /usr/share/dbus-1/system-services/org.freedesktop.oom1.service \
    /usr/share/dbus-1/system.d/org.freedesktop.oom1.conf; do
    if [ -e "$oomd_path" ]; then
      echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_FILE__:$oomd_path:1"
    else
      echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_FILE__:$oomd_path:0"
      oomd_files_ok=0
    fi
  done
  oomd_user_entry="$(getent passwd systemd-oom 2>/dev/null | cut -d: -f1 || true)"
  oomd_default_duration=0
  oomd_root_swap=0
  oomd_user_pressure=0
  grep -Fxq 'DefaultMemoryPressureDurationSec=20s' /usr/lib/systemd/oomd.conf.d/10-oomd-defaults.conf 2>/dev/null &&
    oomd_default_duration=1
  grep -Fxq 'ManagedOOMSwap=auto' /usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf 2>/dev/null &&
    oomd_root_swap=1
  if grep -Fxq 'ManagedOOMMemoryPressure=kill' /usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf 2>/dev/null &&
     grep -Fxq 'ManagedOOMMemoryPressureLimit=50%' /usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf 2>/dev/null; then
    oomd_user_pressure=1
  fi
  oomd_reload_ok=0
  oomd_start_rc=0
  oomd_start_ok=0
  oomd_wait_seconds=0
  oomd_active=""
  oomd_substate=""
  oomd_mainpid=""
  rm -f "$oomd_dump"
  if systemd_daemon_reload_request "$oomd_unit" systemd-oomd; then
    oomd_reload_ok=1
    timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl start "$oomd_unit" >/dev/null 2>&1 ||
      oomd_start_rc=$?
    while [ "$oomd_wait_seconds" -lt 30 ]; do
      oomd_active="$(systemctl show --property=ActiveState --value "$oomd_unit" 2>/dev/null || true)"
      oomd_substate="$(systemctl show --property=SubState --value "$oomd_unit" 2>/dev/null || true)"
      oomd_mainpid="$(systemctl show --property=MainPID --value "$oomd_unit" 2>/dev/null || true)"
      if [ "$oomd_active" = "active" ]; then
        oomd_start_ok=1
        break
      fi
      if [ "$oomd_wait_seconds" -ne 0 ] && [ $((oomd_wait_seconds % 5)) -eq 0 ]; then
        timeout 5s env SYSTEMD_BUS_TIMEOUT=5s systemctl start "$oomd_unit" >/dev/null 2>&1 || true
      fi
      sleep 1
      oomd_wait_seconds=$((oomd_wait_seconds + 1))
    done
  else
    oomd_start_rc=1
  fi
  oomd_show_user="$(systemctl show --property=User --value "$oomd_unit" 2>/dev/null || true)"
  oomd_show_bus_name="$(systemctl show --property=BusName --value "$oomd_unit" 2>/dev/null || true)"
  oomd_show_memory_min="$(systemctl show --property=MemoryMin --value "$oomd_unit" 2>/dev/null || true)"
  oomd_show_memory_low="$(systemctl show --property=MemoryLow --value "$oomd_unit" 2>/dev/null || true)"
  oomd_oomctl_rc=0
  oomd_oomctl_output="$(oomctl --no-pager dump 2>&1)" || oomd_oomctl_rc=$?
  printf '%s\n' "$oomd_oomctl_output" >"$oomd_dump"
  oomd_oomctl_nonempty=0
  [ -s "$oomd_dump" ] && oomd_oomctl_nonempty=1
  oomd_mainpid_ok=0
  case "$oomd_mainpid" in
    ''|*[!0-9]*|0|1) ;;
    *) oomd_mainpid_ok=1 ;;
  esac
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_FILES__:$oomd_files_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_USER__:$oomd_user_entry"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_CONFIG__:$oomd_default_duration:$oomd_root_swap:$oomd_user_pressure"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_UNIT__:$oomd_unit"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_RELOAD_OK__:$oomd_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_START_RC__:$oomd_start_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_START_OK__:$oomd_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_WAIT_SECONDS__:$oomd_wait_seconds"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_ACTIVE__:$oomd_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_SUBSTATE__:$oomd_substate"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_MAINPID__:$oomd_mainpid"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_SHOW__:$oomd_show_user:$oomd_show_bus_name:$oomd_show_memory_min:$oomd_show_memory_low"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_OOMCTL_RC__:$oomd_oomctl_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_OOMCTL_NONEMPTY__:$oomd_oomctl_nonempty"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_OOMCTL_BEGIN__"
  sed -n '1,80p' "$oomd_dump" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_OOMCTL_END__"
  if [ "$oomd_files_ok" = "1" ] &&
     [ "$oomd_user_entry" = "systemd-oom" ] &&
     [ "$oomd_default_duration" = "1" ] &&
     [ "$oomd_root_swap" = "1" ] &&
     [ "$oomd_user_pressure" = "1" ] &&
     [ "$oomd_reload_ok" = "1" ] &&
     [ "$oomd_start_ok" = "1" ] &&
     [ "$oomd_active" = "active" ] &&
     [ "$oomd_substate" = "running" ] &&
     [ "$oomd_mainpid_ok" = "1" ] &&
     [ "$oomd_show_user" = "systemd-oom" ] &&
     [ "$oomd_show_bus_name" = "org.freedesktop.oom1" ] &&
     [ "$oomd_show_memory_min" = "67108864" ] &&
     [ "$oomd_show_memory_low" = "67108864" ] &&
     [ "$oomd_oomctl_rc" = "0" ] &&
     [ "$oomd_oomctl_nonempty" = "1" ]; then
    pass full-userland-systemd-oomd-service
  else
    systemctl status "$oomd_unit" --no-pager 2>/dev/null || true
    journalctl -u "$oomd_unit" --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    full_userland_fail full-userland-systemd-oomd-service
  fi
  rm -f "$oomd_dump"


  oomd_pressure_timeout=${NEMU_GUEST_OOMD_PRESSURE_TIMEOUT:-180}
  case "$oomd_pressure_timeout" in ''|*[!0-9]*) oomd_pressure_timeout=180 ;; esac
  [ "$oomd_pressure_timeout" -lt 30 ] 2>/dev/null && oomd_pressure_timeout=30
  oomd_pressure_slice=nemuoomdpressure.slice
  oomd_pressure_service=nemuoomdpressure-victim.service
  oomd_pressure_slice_path=/run/systemd/system/$oomd_pressure_slice
  oomd_pressure_service_path=/run/systemd/system/$oomd_pressure_service
  oomd_pressure_conf=/etc/systemd/oomd.conf.d/99-nemu-pressure-kill.conf
  oomd_pressure_output=/run/nemu-full-oomd-pressure.out
  oomd_pressure_cgroup_file=/run/nemu-full-oomd-pressure.cgroup
  oomd_pressure_probe_b64=/run/nemu-full-oomd-pressure-probe.b64
  oomd_pressure_probe_bin=/run/nemu-full-oomd-pressure-probe
  oomd_pressure_alloc_log=/run/nemu-full-oomd-pressure.alloc.log
  oomd_pressure_memory_events_file=/run/nemu-full-oomd-pressure.memory.events
  oomd_pressure_memory_pressure_file=/run/nemu-full-oomd-pressure.memory.pressure
  oomd_pressure_memory_current_file=/run/nemu-full-oomd-pressure.memory.current
  oomd_pressure_slice_memory_events_file=/run/nemu-full-oomd-pressure.slice.memory.events
  oomd_pressure_slice_memory_pressure_file=/run/nemu-full-oomd-pressure.slice.memory.pressure
  oomd_pressure_slice_memory_current_file=/run/nemu-full-oomd-pressure.slice.memory.current
  oomd_pressure_stop_post=/run/nemu-full-oomd-pressure.stop-post
  oomd_pressure_dump_before=/run/nemu-full-oomd-pressure.oomctl.before
  oomd_pressure_dump_after=/run/nemu-full-oomd-pressure.oomctl.after
  rm -f "$oomd_pressure_slice_path" "$oomd_pressure_service_path" "$oomd_pressure_conf" \
    "$oomd_pressure_output" "$oomd_pressure_cgroup_file" "$oomd_pressure_probe_b64" \
    "$oomd_pressure_probe_bin" "$oomd_pressure_alloc_log" \
    "$oomd_pressure_memory_events_file" "$oomd_pressure_memory_pressure_file" \
    "$oomd_pressure_memory_current_file" "$oomd_pressure_slice_memory_events_file" \
    "$oomd_pressure_slice_memory_pressure_file" "$oomd_pressure_slice_memory_current_file" \
    "$oomd_pressure_stop_post" "$oomd_pressure_dump_before" "$oomd_pressure_dump_after"
  mkdir -p /etc/systemd/oomd.conf.d
  systemctl stop "$oomd_pressure_service" "$oomd_pressure_slice" >/dev/null 2>&1 || true
  systemctl reset-failed "$oomd_pressure_service" "$oomd_pressure_slice" >/dev/null 2>&1 || true
  cat > "$oomd_pressure_probe_b64" <<'__NEMU_OOMD_PRESSURE_PROBE_B64__'
__NEMU_OOMD_PRESSURE_PROBE_PAYLOAD__
__NEMU_OOMD_PRESSURE_PROBE_B64__
  oomd_pressure_probe_ok=0
  if base64 -d "$oomd_pressure_probe_b64" > "$oomd_pressure_probe_bin" &&
     chmod +x "$oomd_pressure_probe_bin"; then
    oomd_pressure_probe_ok=1
  fi
  cat >"$oomd_pressure_conf" <<'UNIT'
[OOM]
DefaultMemoryPressureLimit=1%
DefaultMemoryPressureDurationSec=1s
UNIT
  # systemd-oomd 订阅的是父 slice；MemoryHigh 放在这里，才能让被监控 cgroup 自身产生 PSI 压力。
  cat >"$oomd_pressure_slice_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd-oomd pressure parent

[Slice]
MemoryAccounting=yes
MemoryHigh=32M
ManagedOOMMemoryPressure=kill
ManagedOOMMemoryPressureLimit=1%
UNIT
  cat >"$oomd_pressure_service_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd-oomd pressure victim
After=basic.target

[Service]
Type=simple
Slice=nemuoomdpressure.slice
MemoryAccounting=yes
CPUAccounting=yes
TasksAccounting=yes
ManagedOOMPreference=none
KillMode=control-group
TimeoutStopSec=10s
ExecStart=/bin/sh -c 'printf systemd-oomd-pressure-started > /run/nemu-full-oomd-pressure.out; cat /proc/self/cgroup > /run/nemu-full-oomd-pressure.cgroup; exec /run/nemu-full-oomd-pressure-probe 512 4 128 /var/tmp/nemu-full-oomd-pressure-cache.bin > /run/nemu-full-oomd-pressure.alloc.log 2>&1'
ExecStopPost=/bin/sh -c 'cat /sys/fs/cgroup/nemuoomdpressure.slice/nemuoomdpressure-victim.service/memory.events > /run/nemu-full-oomd-pressure.memory.events 2>/dev/null || true; cat /sys/fs/cgroup/nemuoomdpressure.slice/nemuoomdpressure-victim.service/memory.pressure > /run/nemu-full-oomd-pressure.memory.pressure 2>/dev/null || true; cat /sys/fs/cgroup/nemuoomdpressure.slice/nemuoomdpressure-victim.service/memory.current > /run/nemu-full-oomd-pressure.memory.current 2>/dev/null || true; cat /sys/fs/cgroup/nemuoomdpressure.slice/memory.events > /run/nemu-full-oomd-pressure.slice.memory.events 2>/dev/null || true; cat /sys/fs/cgroup/nemuoomdpressure.slice/memory.pressure > /run/nemu-full-oomd-pressure.slice.memory.pressure 2>/dev/null || true; cat /sys/fs/cgroup/nemuoomdpressure.slice/memory.current > /run/nemu-full-oomd-pressure.slice.memory.current 2>/dev/null || true; printf systemd-oomd-pressure-stop-post > /run/nemu-full-oomd-pressure.stop-post'
UNIT
  oomd_pressure_conf_ok=0
  if grep -Fxq 'DefaultMemoryPressureLimit=1%' "$oomd_pressure_conf" &&
     grep -Fxq 'DefaultMemoryPressureDurationSec=1s' "$oomd_pressure_conf"; then
    oomd_pressure_conf_ok=1
  fi
  oomd_pressure_reload_ok=0
  oomd_pressure_oomd_restart_rc=0
  oomd_pressure_oomd_ready=0
  oomd_pressure_oomd_wait_seconds=0
  oomd_pressure_start_ok=0
  if systemd_daemon_reload_request "$oomd_pressure_service" oomd-pressure-kill; then
    oomd_pressure_reload_ok=1
    timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl restart "$oomd_unit" >/dev/null 2>&1 ||
      oomd_pressure_oomd_restart_rc=$?
    while [ "$oomd_pressure_oomd_wait_seconds" -lt 30 ]; do
      oomd_pressure_oomd_active="$(systemctl show --property=ActiveState --value "$oomd_unit" 2>/dev/null || true)"
      oomd_pressure_oomd_substate="$(systemctl show --property=SubState --value "$oomd_unit" 2>/dev/null || true)"
      if [ "$oomd_pressure_oomd_active" = "active" ] && [ "$oomd_pressure_oomd_substate" = "running" ]; then
        oomd_pressure_oomd_ready=1
        break
      fi
      sleep 1
      oomd_pressure_oomd_wait_seconds=$((oomd_pressure_oomd_wait_seconds + 1))
    done
    if [ "$oomd_pressure_oomd_ready" = "1" ] &&
       systemd_start_runtime_unit_after_reload "$oomd_pressure_service" "$oomd_pressure_output"; then
      oomd_pressure_start_ok=1
    fi
  else
    oomd_pressure_oomd_restart_rc=1
  fi
  oomd_pressure_value="$(cat "$oomd_pressure_output" 2>/dev/null || true)"
  oomd_pressure_cgroup="$(sed -n 's/^0:://p' "$oomd_pressure_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  oomd_pressure_cgroup_dir=/sys/fs/cgroup$oomd_pressure_cgroup
  oomd_pressure_slice_dir=/sys/fs/cgroup/$oomd_pressure_slice
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_PROBE_OK__:$oomd_pressure_probe_ok"
  oomd_pressure_oom_group_before="$(cat "$oomd_pressure_cgroup_dir/memory.oom.group" 2>/dev/null || true)"
  oomd_pressure_oom_group_write_ok=0
  if [ "$oomd_pressure_oom_group_before" = "1" ]; then
    oomd_pressure_oom_group_write_ok=1
  elif [ -w "$oomd_pressure_cgroup_dir/memory.oom.group" ]; then
    if printf '1' >"$oomd_pressure_cgroup_dir/memory.oom.group" 2>/dev/null; then
      oomd_pressure_oom_group_write_ok=1
    fi
  fi
  oomd_pressure_oom_group_after="$(cat "$oomd_pressure_cgroup_dir/memory.oom.group" 2>/dev/null || true)"
  oomd_pressure_slice_managed="$(systemctl show --property=ManagedOOMMemoryPressure --value "$oomd_pressure_slice" 2>/dev/null || true)"
  oomd_pressure_slice_limit="$(systemctl show --property=ManagedOOMMemoryPressureLimit --value "$oomd_pressure_slice" 2>/dev/null || true)"
  oomd_pressure_slice_memacct="$(systemctl show --property=MemoryAccounting --value "$oomd_pressure_slice" 2>/dev/null || true)"
  oomd_pressure_slice_memory_high="$(systemctl show --property=MemoryHigh --value "$oomd_pressure_slice" 2>/dev/null || true)"
  oomd_pressure_service_memacct="$(systemctl show --property=MemoryAccounting --value "$oomd_pressure_service" 2>/dev/null || true)"
  oomd_pressure_service_memory_high="$(systemctl show --property=MemoryHigh --value "$oomd_pressure_service" 2>/dev/null || true)"
  oomd_pressure_service_preference="$(systemctl show --property=ManagedOOMPreference --value "$oomd_pressure_service" 2>/dev/null || true)"
  oomd_pressure_slice_limit_ok=1
  case "$oomd_pressure_slice_limit" in ''|0|0%|0.00%) oomd_pressure_slice_limit_ok=0 ;; esac
  oomd_pressure_oomctl_rc_before=0
  oomctl --no-pager dump >"$oomd_pressure_dump_before" 2>&1 || oomd_pressure_oomctl_rc_before=$?
  oomd_pressure_oomctl_has_slice=0
  if grep -Fq "/$oomd_pressure_slice" "$oomd_pressure_dump_before" 2>/dev/null; then
    oomd_pressure_oomctl_has_slice=1
  fi
  oomd_pressure_wait_seconds=0
  oomd_pressure_stopped=0
  oomd_pressure_journal_kill=0
  oomd_pressure_active_final=""
  oomd_pressure_result=""
  while [ "$oomd_pressure_wait_seconds" -lt "$oomd_pressure_timeout" ]; do
    oomd_pressure_active_final="$(systemctl show --property=ActiveState --value "$oomd_pressure_service" 2>/dev/null || true)"
    oomd_pressure_result="$(systemctl show --property=Result --value "$oomd_pressure_service" 2>/dev/null || true)"
    if [ -r "$oomd_pressure_cgroup_dir/memory.events" ]; then
      cat "$oomd_pressure_cgroup_dir/memory.events" >"$oomd_pressure_memory_events_file" 2>/dev/null || true
    fi
    if [ -r "$oomd_pressure_cgroup_dir/memory.pressure" ]; then
      cat "$oomd_pressure_cgroup_dir/memory.pressure" >"$oomd_pressure_memory_pressure_file" 2>/dev/null || true
    fi
    if [ -r "$oomd_pressure_cgroup_dir/memory.current" ]; then
      cat "$oomd_pressure_cgroup_dir/memory.current" >"$oomd_pressure_memory_current_file" 2>/dev/null || true
    fi
    if [ -r "$oomd_pressure_slice_dir/memory.events" ]; then
      cat "$oomd_pressure_slice_dir/memory.events" >"$oomd_pressure_slice_memory_events_file" 2>/dev/null || true
    fi
    if [ -r "$oomd_pressure_slice_dir/memory.pressure" ]; then
      cat "$oomd_pressure_slice_dir/memory.pressure" >"$oomd_pressure_slice_memory_pressure_file" 2>/dev/null || true
    fi
    if [ -r "$oomd_pressure_slice_dir/memory.current" ]; then
      cat "$oomd_pressure_slice_dir/memory.current" >"$oomd_pressure_slice_memory_current_file" 2>/dev/null || true
    fi
    if journalctl -u "$oomd_unit" --no-pager -n 240 2>/dev/null |
       grep -F 'Killed' | grep -Fq 'nemuoomdpressure'; then
      oomd_pressure_journal_kill=1
    fi
    case "$oomd_pressure_active_final" in
      failed|inactive) oomd_pressure_stopped=1 ;;
    esac
    if [ "$oomd_pressure_stopped" = "1" ] && [ "$oomd_pressure_journal_kill" = "1" ]; then
      break
    fi
    if [ "$oomd_pressure_wait_seconds" -ne 0 ] && [ $((oomd_pressure_wait_seconds % 30)) -eq 0 ]; then
      oomd_pressure_progress_current="$(cat "$oomd_pressure_memory_current_file" 2>/dev/null || true)"
      oomd_pressure_progress_high="$(awk '$1 == "high" {print $2}' "$oomd_pressure_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
      oomd_pressure_progress_slice_current="$(cat "$oomd_pressure_slice_memory_current_file" 2>/dev/null || true)"
      oomd_pressure_progress_slice_high="$(awk '$1 == "high" {print $2}' "$oomd_pressure_slice_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
      echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_WAIT_PROGRESS__:$oomd_pressure_wait_seconds:$oomd_pressure_active_final:$oomd_pressure_result:$oomd_pressure_progress_current:$oomd_pressure_progress_high:$oomd_pressure_progress_slice_current:$oomd_pressure_progress_slice_high"
    fi
    sleep 1
    oomd_pressure_wait_seconds=$((oomd_pressure_wait_seconds + 1))
  done
  oomd_pressure_active_final="$(systemctl show --property=ActiveState --value "$oomd_pressure_service" 2>/dev/null || true)"
  oomd_pressure_substate_final="$(systemctl show --property=SubState --value "$oomd_pressure_service" 2>/dev/null || true)"
  oomd_pressure_result="$(systemctl show --property=Result --value "$oomd_pressure_service" 2>/dev/null || true)"
  case "$oomd_pressure_active_final" in
    failed|inactive) oomd_pressure_stopped=1 ;;
  esac
  if journalctl -u "$oomd_unit" --no-pager -n 240 2>/dev/null |
     grep -F 'Killed' | grep -Fq 'nemuoomdpressure'; then
    oomd_pressure_journal_kill=1
  fi
  if [ -r "$oomd_pressure_cgroup_dir/memory.events" ]; then
    cat "$oomd_pressure_cgroup_dir/memory.events" >"$oomd_pressure_memory_events_file" 2>/dev/null || true
  fi
  if [ -r "$oomd_pressure_cgroup_dir/memory.pressure" ]; then
    cat "$oomd_pressure_cgroup_dir/memory.pressure" >"$oomd_pressure_memory_pressure_file" 2>/dev/null || true
  fi
  if [ -r "$oomd_pressure_cgroup_dir/memory.current" ]; then
    cat "$oomd_pressure_cgroup_dir/memory.current" >"$oomd_pressure_memory_current_file" 2>/dev/null || true
  fi
  if [ -r "$oomd_pressure_slice_dir/memory.events" ]; then
    cat "$oomd_pressure_slice_dir/memory.events" >"$oomd_pressure_slice_memory_events_file" 2>/dev/null || true
  fi
  if [ -r "$oomd_pressure_slice_dir/memory.pressure" ]; then
    cat "$oomd_pressure_slice_dir/memory.pressure" >"$oomd_pressure_slice_memory_pressure_file" 2>/dev/null || true
  fi
  if [ -r "$oomd_pressure_slice_dir/memory.current" ]; then
    cat "$oomd_pressure_slice_dir/memory.current" >"$oomd_pressure_slice_memory_current_file" 2>/dev/null || true
  fi
  oomd_pressure_stop_post_seen=0
  oomd_pressure_stop_post_value="$(cat "$oomd_pressure_stop_post" 2>/dev/null || true)"
  [ "$oomd_pressure_stop_post_value" = "systemd-oomd-pressure-stop-post" ] && oomd_pressure_stop_post_seen=1
  oomd_pressure_memory_events_oom_kill="$(awk '$1 == "oom_kill" {print $2}' "$oomd_pressure_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  oomd_pressure_memory_events_oom="$(awk '$1 == "oom" {print $2}' "$oomd_pressure_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  oomd_pressure_memory_events_high="$(awk '$1 == "high" {print $2}' "$oomd_pressure_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  oomd_pressure_slice_memory_events_high="$(awk '$1 == "high" {print $2}' "$oomd_pressure_slice_memory_events_file" 2>/dev/null | sed -n '1p' || true)"
  case "$oomd_pressure_memory_events_oom_kill" in ''|*[!0-9]*) oomd_pressure_memory_events_oom_kill=0 ;; esac
  case "$oomd_pressure_memory_events_oom" in ''|*[!0-9]*) oomd_pressure_memory_events_oom=0 ;; esac
  case "$oomd_pressure_memory_events_high" in ''|*[!0-9]*) oomd_pressure_memory_events_high=0 ;; esac
  case "$oomd_pressure_slice_memory_events_high" in ''|*[!0-9]*) oomd_pressure_slice_memory_events_high=0 ;; esac
  oomd_pressure_memory_some_line="$(sed -n '1p' "$oomd_pressure_memory_pressure_file" 2>/dev/null || true)"
  oomd_pressure_memory_current="$(cat "$oomd_pressure_memory_current_file" 2>/dev/null || true)"
  oomd_pressure_slice_memory_some_line="$(sed -n '1p' "$oomd_pressure_slice_memory_pressure_file" 2>/dev/null || true)"
  oomd_pressure_slice_memory_current="$(cat "$oomd_pressure_slice_memory_current_file" 2>/dev/null || true)"
  oomd_pressure_alloc_started=0
  oomd_pressure_cache_started=0
  oomd_pressure_cache_write_seen=0
  oomd_pressure_alloc_reached=0
  grep -Fq 'oomd-pressure-probe-start' "$oomd_pressure_alloc_log" 2>/dev/null && oomd_pressure_alloc_started=1
  grep -Fq 'oomd-pressure-probe-cache-start' "$oomd_pressure_alloc_log" 2>/dev/null && oomd_pressure_cache_started=1
  grep -Fq 'oomd-pressure-probe-cache-write' "$oomd_pressure_alloc_log" 2>/dev/null && oomd_pressure_cache_write_seen=1
  grep -Fq 'oomd-pressure-probe-target-reached' "$oomd_pressure_alloc_log" 2>/dev/null && oomd_pressure_alloc_reached=1
  oomd_pressure_oomctl_rc_after=0
  oomctl --no-pager dump >"$oomd_pressure_dump_after" 2>&1 || oomd_pressure_oomctl_rc_after=$?
  oomd_pressure_killed=0
  if [ "$oomd_pressure_stopped" = "1" ] && [ "$oomd_pressure_journal_kill" = "1" ]; then
    oomd_pressure_killed=1
  fi
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_TIMEOUT__:$oomd_pressure_timeout"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_UNITS__:$oomd_pressure_slice:$oomd_pressure_service"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_CONF__:$oomd_pressure_conf_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_RELOAD_OK__:$oomd_pressure_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMD_RESTART_RC__:$oomd_pressure_oomd_restart_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMD_READY__:$oomd_pressure_oomd_ready:$oomd_pressure_oomd_wait_seconds"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_START_OK__:$oomd_pressure_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OUTPUT__:$oomd_pressure_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_CGROUP__:$oomd_pressure_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_PROBE_OK__:$oomd_pressure_probe_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOM_GROUP_BEFORE__:$oomd_pressure_oom_group_before"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOM_GROUP_WRITE_OK__:$oomd_pressure_oom_group_write_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOM_GROUP_AFTER__:$oomd_pressure_oom_group_after"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SLICE_SHOW__:$oomd_pressure_slice_managed:$oomd_pressure_slice_limit:$oomd_pressure_slice_memacct:$oomd_pressure_slice_memory_high"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SERVICE_SHOW__:$oomd_pressure_service_memacct:$oomd_pressure_service_memory_high:$oomd_pressure_service_preference"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_RC__:$oomd_pressure_oomctl_rc_before:$oomd_pressure_oomctl_rc_after"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_HAS_SLICE__:$oomd_pressure_oomctl_has_slice"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_WAIT_SECONDS__:$oomd_pressure_wait_seconds"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_ACTIVE__:$oomd_pressure_active_final"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SUBSTATE__:$oomd_pressure_substate_final"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_RESULT__:$oomd_pressure_result"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_STOPPED__:$oomd_pressure_stopped"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_KILLED__:$oomd_pressure_killed"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_JOURNAL_KILL__:$oomd_pressure_journal_kill"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_STOP_POST__:$oomd_pressure_stop_post_seen:$oomd_pressure_stop_post_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_MEMORY_EVENTS_OOM__:$oomd_pressure_memory_events_oom"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_MEMORY_EVENTS_OOM_KILL__:$oomd_pressure_memory_events_oom_kill"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_MEMORY_EVENTS_HIGH__:$oomd_pressure_memory_events_high"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_MEMORY_CURRENT__:$oomd_pressure_memory_current"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_MEMORY_SOME__:$oomd_pressure_memory_some_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SLICE_MEMORY_EVENTS_HIGH__:$oomd_pressure_slice_memory_events_high"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SLICE_MEMORY_CURRENT__:$oomd_pressure_slice_memory_current"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_SLICE_MEMORY_SOME__:$oomd_pressure_slice_memory_some_line"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_ALLOC_STARTED__:$oomd_pressure_alloc_started"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_CACHE_STARTED__:$oomd_pressure_cache_started"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_CACHE_WRITE_SEEN__:$oomd_pressure_cache_write_seen"
  echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_ALLOC_REACHED__:$oomd_pressure_alloc_reached"
  if [ "$oomd_pressure_reload_ok" = "1" ] &&
     [ "$oomd_pressure_oomd_ready" = "1" ] &&
     [ "$oomd_pressure_start_ok" = "1" ] &&
     [ "$oomd_pressure_probe_ok" = "1" ] &&
     [ "$oomd_pressure_conf_ok" = "1" ] &&
     [ "$oomd_pressure_value" = "systemd-oomd-pressure-started" ] &&
     [ "$oomd_pressure_cgroup" = "/$oomd_pressure_slice/$oomd_pressure_service" ] &&
     [ "$oomd_pressure_oom_group_after" = "1" ] &&
     [ "$oomd_pressure_slice_managed" = "kill" ] &&
     [ "$oomd_pressure_slice_limit_ok" = "1" ] &&
     [ "$oomd_pressure_slice_memacct" = "yes" ] &&
     [ "$oomd_pressure_slice_memory_high" = "33554432" ] &&
     [ "$oomd_pressure_service_memacct" = "yes" ] &&
     [ "$oomd_pressure_oomctl_has_slice" = "1" ] &&
     [ "$oomd_pressure_alloc_started" = "1" ] &&
     [ "$oomd_pressure_slice_memory_events_high" -gt 0 ] &&
     [ "$oomd_pressure_killed" = "1" ] &&
     [ "$oomd_pressure_stop_post_seen" = "1" ]; then
    pass full-userland-systemd-oomd-pressure-kill
  else
    systemctl status "$oomd_pressure_slice" "$oomd_pressure_service" "$oomd_unit" --no-pager 2>/dev/null || true
    journalctl -u "$oomd_unit" --no-pager -n 240 2>/dev/null | sed -n '1,240p' || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_BEFORE_BEGIN__"
    sed -n '1,120p' "$oomd_pressure_dump_before" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_BEFORE_END__"
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_AFTER_BEGIN__"
    sed -n '1,120p' "$oomd_pressure_dump_after" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_OOMCTL_AFTER_END__"
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_ALLOC_LOG_BEGIN__"
    sed -n '1,120p' "$oomd_pressure_alloc_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_SYSTEMD_OOMD_PRESSURE_ALLOC_LOG_END__"
    full_userland_fail full-userland-systemd-oomd-pressure-kill
  fi
  systemctl stop "$oomd_pressure_service" "$oomd_pressure_slice" >/dev/null 2>&1 || true
  systemctl reset-failed "$oomd_pressure_service" "$oomd_pressure_slice" >/dev/null 2>&1 || true
  rm -f "$oomd_pressure_slice_path" "$oomd_pressure_service_path" "$oomd_pressure_conf" \
    "$oomd_pressure_output" "$oomd_pressure_cgroup_file" "$oomd_pressure_probe_b64" \
    "$oomd_pressure_probe_bin" "$oomd_pressure_alloc_log" \
    "$oomd_pressure_memory_events_file" "$oomd_pressure_memory_pressure_file" \
    "$oomd_pressure_memory_current_file" "$oomd_pressure_slice_memory_events_file" \
    "$oomd_pressure_slice_memory_pressure_file" "$oomd_pressure_slice_memory_current_file" \
    "$oomd_pressure_stop_post" "$oomd_pressure_dump_before" "$oomd_pressure_dump_after"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl restart "$oomd_unit" >/dev/null 2>&1 || true

  slice_delegation_slice=nemu.slice
  slice_delegation_service=nemu-full-delegated.service
  slice_delegation_slice_path=/run/systemd/system/$slice_delegation_slice
  slice_delegation_service_path=/run/systemd/system/$slice_delegation_service
  slice_delegation_output=/run/nemu-full-slice-delegation.out
  slice_delegation_cgroup_file=/run/nemu-full-slice-delegation.cgroup
  rm -f "$slice_delegation_slice_path" "$slice_delegation_service_path" \
    "$slice_delegation_output" "$slice_delegation_cgroup_file"
  systemctl stop "$slice_delegation_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$slice_delegation_service" "$slice_delegation_slice" >/dev/null 2>&1 || true
  cat >"$slice_delegation_slice_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu custom slice smoke

[Slice]
CPUAccounting=yes
MemoryAccounting=yes
TasksAccounting=yes
UNIT
  cat >"$slice_delegation_service_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemd slice delegation smoke
After=basic.target

[Service]
Type=simple
Slice=nemu.slice
Delegate=yes
CPUAccounting=yes
MemoryAccounting=yes
TasksAccounting=yes
ExecStart=/bin/sh -c 'cat /proc/self/cgroup > /run/nemu-full-slice-delegation.cgroup; printf systemd-slice-delegation-ok > /run/nemu-full-slice-delegation.out; sleep 120'
UNIT
  slice_delegation_reload_ok=0
  slice_delegation_start_ok=0
  if systemd_daemon_reload_request "$slice_delegation_service" slice-delegation; then
    slice_delegation_reload_ok=1
    if systemd_start_runtime_unit_after_reload "$slice_delegation_service" "$slice_delegation_output"; then
      slice_delegation_start_ok=1
    fi
  fi
  slice_delegation_value="$(cat "$slice_delegation_output" 2>/dev/null || true)"
  slice_delegation_guest_cgroup="$(sed -n 's/^0:://p' "$slice_delegation_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  slice_delegation_show_cgroup="$(systemctl show --property=ControlGroup --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_cgroup="$slice_delegation_guest_cgroup"
  [ -n "$slice_delegation_cgroup" ] || slice_delegation_cgroup="$slice_delegation_show_cgroup"
  slice_delegation_cgroup_dir=/sys/fs/cgroup$slice_delegation_cgroup
  slice_delegation_slice_show="$(systemctl show --property=Slice --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_delegate_show="$(systemctl show --property=Delegate --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_show_cpu_accounting="$(systemctl show --property=CPUAccounting --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_show_memory_accounting="$(systemctl show --property=MemoryAccounting --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_show_tasks_accounting="$(systemctl show --property=TasksAccounting --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_active="$(systemctl show --property=ActiveState --value "$slice_delegation_service" 2>/dev/null || true)"
  slice_delegation_controllers_readable=0
  slice_delegation_controllers=""
  slice_delegation_subtree_control=""
  if [ -n "$slice_delegation_cgroup" ] &&
     [ -r "$slice_delegation_cgroup_dir/cgroup.controllers" ]; then
    slice_delegation_controllers_readable=1
    slice_delegation_controllers="$(cat "$slice_delegation_cgroup_dir/cgroup.controllers" 2>/dev/null || true)"
  fi
  if [ -n "$slice_delegation_cgroup" ] &&
     [ -r "$slice_delegation_cgroup_dir/cgroup.subtree_control" ]; then
    slice_delegation_subtree_control="$(cat "$slice_delegation_cgroup_dir/cgroup.subtree_control" 2>/dev/null || true)"
  fi
  slice_delegation_cgroup_ok=0
  case "$slice_delegation_cgroup" in
    "/$slice_delegation_slice/$slice_delegation_service")
      slice_delegation_cgroup_ok=1
      ;;
  esac
  slice_delegation_show_cgroup_ok=0
  case "$slice_delegation_show_cgroup" in
    "/$slice_delegation_slice/$slice_delegation_service")
      slice_delegation_show_cgroup_ok=1
      ;;
  esac
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_FILES__:$slice_delegation_slice_path:$slice_delegation_service_path"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_UNITS__:$slice_delegation_slice:$slice_delegation_service:$slice_delegation_output"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_RELOAD_OK__:$slice_delegation_reload_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_START_OK__:$slice_delegation_start_ok"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_ACTIVE__:$slice_delegation_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_OUTPUT__:$slice_delegation_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_CGROUP__:$slice_delegation_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_GUEST_CGROUP__:$slice_delegation_guest_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_SHOW_CGROUP__:$slice_delegation_show_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_SLICE__:$slice_delegation_slice_show"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_DELEGATE__:$slice_delegation_delegate_show"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_SHOW__:$slice_delegation_slice_show:$slice_delegation_delegate_show:$slice_delegation_show_cpu_accounting:$slice_delegation_show_memory_accounting:$slice_delegation_show_tasks_accounting"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_CONTROLLERS_READABLE__:$slice_delegation_controllers_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_CONTROLLERS__:$slice_delegation_controllers"
  echo "__NEMU_CHECK_FULL_SYSTEMD_SLICE_DELEGATION_SUBTREE_CONTROL__:$slice_delegation_subtree_control"
  if [ "$slice_delegation_reload_ok" = "1" ] &&
     [ "$slice_delegation_start_ok" = "1" ] &&
     [ "$slice_delegation_active" = "active" ] &&
     [ "$slice_delegation_value" = "systemd-slice-delegation-ok" ] &&
     [ "$slice_delegation_cgroup_ok" = "1" ] &&
     [ "$slice_delegation_show_cgroup_ok" = "1" ] &&
     [ "$slice_delegation_slice_show" = "$slice_delegation_slice" ] &&
     [ "$slice_delegation_delegate_show" = "yes" ] &&
     [ "$slice_delegation_show_cpu_accounting" = "yes" ] &&
     [ "$slice_delegation_show_memory_accounting" = "yes" ] &&
     [ "$slice_delegation_show_tasks_accounting" = "yes" ] &&
     [ "$slice_delegation_controllers_readable" = "1" ]; then
    pass full-userland-systemd-slice-delegation
  else
    systemctl status "$slice_delegation_service" "$slice_delegation_slice" --no-pager 2>/dev/null || true
    journalctl -u "$slice_delegation_service" --no-pager -n 80 2>/dev/null | sed -n '1,80p' || true
    if [ -n "$slice_delegation_cgroup" ]; then
      find "$slice_delegation_cgroup_dir" -maxdepth 1 -type f \
        \( -name 'cgroup.*' -o -name 'cpu.*' -o -name 'memory.*' -o -name 'pids.*' \) \
        -print -exec sed -n '1,20p' {} \; 2>/dev/null | sed -n '1,160p' || true
    fi
    full_userland_fail full-userland-systemd-slice-delegation
  fi
  systemctl stop "$slice_delegation_service" >/dev/null 2>&1 || true
  systemctl reset-failed "$slice_delegation_service" "$slice_delegation_slice" >/dev/null 2>&1 || true
  rm -f "$slice_delegation_slice_path" "$slice_delegation_service_path" \
    "$slice_delegation_output" "$slice_delegation_cgroup_file"

  user_manager_user=$account_user
  user_manager_uid=$account_uid
  user_manager_group=$account_group
  user_manager_unit=nemu-full-user-manager.service
  user_manager_script=/run/nemu-full-user-manager-check.sh
  user_manager_log=/tmp/nemu-full-user-manager.log
  user_manager_runtime_dir=/run/user/$user_manager_uid
  user_manager_output=$user_manager_runtime_dir/nemu-full-user-manager.out
  user_manager_cgroup_file=$user_manager_runtime_dir/nemu-full-user-manager.cgroup
  rm -f "$user_manager_script" "$user_manager_log" "$user_manager_output" "$user_manager_cgroup_file"
  user_manager_logind_rc=0
  timeout 30s env SYSTEMD_BUS_TIMEOUT=5s systemctl start systemd-logind.service >/dev/null 2>&1 ||
    user_manager_logind_rc=$?
  user_manager_logind_active="$(systemctl show --property=ActiveState --value systemd-logind.service 2>/dev/null || true)"
  user_manager_linger_rc=0
  /bin/loginctl enable-linger "$user_manager_user" >/dev/null 2>&1 ||
    user_manager_linger_rc=$?
  user_manager_linger_file=/var/lib/systemd/linger/$user_manager_user
  user_manager_linger_enabled=0
  [ -e "$user_manager_linger_file" ] && user_manager_linger_enabled=1
  user_manager_start_rc=0
  timeout 60s env SYSTEMD_BUS_TIMEOUT=5s systemctl start "user@$user_manager_uid.service" >/dev/null 2>&1 ||
    user_manager_start_rc=$?
  user_manager_wait_seconds=0
  user_manager_user_service_active=""
  while [ "$user_manager_wait_seconds" -lt 60 ]; do
    user_manager_user_service_active="$(systemctl show --property=ActiveState --value "user@$user_manager_uid.service" 2>/dev/null || true)"
    [ "$user_manager_user_service_active" = "active" ] && break
    sleep 1
    user_manager_wait_seconds=$((user_manager_wait_seconds + 1))
  done
  user_manager_runtime_owner="$(stat -c '%U:%G:%a:%n' "$user_manager_runtime_dir" 2>/dev/null || true)"
  user_manager_private_socket=0
  [ -S "$user_manager_runtime_dir/systemd/private" ] && user_manager_private_socket=1
  user_manager_bus_socket=0
  [ -S "$user_manager_runtime_dir/bus" ] && user_manager_bus_socket=1
  cat >"$user_manager_script" <<'USER_MANAGER_SCRIPT'
#!/bin/sh
set -u
unit=nemu-full-user-manager.service
runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
unit_dir=$HOME/.config/systemd/user
output=$runtime_dir/nemu-full-user-manager.out
cgroup_file=$runtime_dir/nemu-full-user-manager.cgroup
mkdir -p "$unit_dir"
rm -f "$output" "$cgroup_file"
cat >"$unit_dir/$unit" <<UNIT
[Unit]
Description=NEMU full Ubuntu systemd user manager service smoke

[Service]
Type=simple
Delegate=yes
CPUAccounting=yes
MemoryAccounting=yes
TasksAccounting=yes
ExecStart=/bin/sh -c 'cat /proc/self/cgroup > $runtime_dir/nemu-full-user-manager.cgroup; printf systemd-user-manager-ok > $runtime_dir/nemu-full-user-manager.out; sleep 120'
UNIT
systemctl --user stop "$unit" >/dev/null 2>&1 || true
systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
systemctl --user daemon-reload || exit $?
systemctl --user start "$unit" || exit $?
wait_seconds=0
while [ "$wait_seconds" -lt 60 ]; do
  [ "$(cat "$output" 2>/dev/null || true)" = "systemd-user-manager-ok" ] && break
  sleep 1
  wait_seconds=$((wait_seconds + 1))
done
active="$(systemctl --user show --property=ActiveState --value "$unit" 2>/dev/null || true)"
control_group="$(systemctl --user show --property=ControlGroup --value "$unit" 2>/dev/null || true)"
delegate="$(systemctl --user show --property=Delegate --value "$unit" 2>/dev/null || true)"
cpu_accounting="$(systemctl --user show --property=CPUAccounting --value "$unit" 2>/dev/null || true)"
memory_accounting="$(systemctl --user show --property=MemoryAccounting --value "$unit" 2>/dev/null || true)"
tasks_accounting="$(systemctl --user show --property=TasksAccounting --value "$unit" 2>/dev/null || true)"
value="$(cat "$output" 2>/dev/null || true)"
cgroup="$(sed -n 's/^0:://p' "$cgroup_file" 2>/dev/null | sed -n '1p' || true)"
[ -n "$cgroup" ] || cgroup="$control_group"
cgroup_dir=/sys/fs/cgroup$cgroup
controllers_readable=0
controllers=
subtree_control=
if [ -r "$cgroup_dir/cgroup.controllers" ]; then
  controllers_readable=1
  controllers="$(cat "$cgroup_dir/cgroup.controllers" 2>/dev/null || true)"
fi
if [ -r "$cgroup_dir/cgroup.subtree_control" ]; then
  subtree_control="$(cat "$cgroup_dir/cgroup.subtree_control" 2>/dev/null || true)"
fi
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_ACTIVE__:%s\n' "$active"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_OUTPUT__:%s\n' "$value"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_WAIT_SECONDS__:%s\n' "$wait_seconds"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_CGROUP__:%s\n' "$cgroup"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_CONTROL_GROUP__:%s\n' "$control_group"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_SHOW__:%s:%s:%s:%s\n' "$delegate" "$cpu_accounting" "$memory_accounting" "$tasks_accounting"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_CONTROLLERS_READABLE__:%s\n' "$controllers_readable"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_CONTROLLERS__:%s\n' "$controllers"
printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_SUBTREE_CONTROL__:%s\n' "$subtree_control"
if [ "$active" = "active" ] &&
   [ "$value" = "systemd-user-manager-ok" ] &&
   [ "$delegate" = "yes" ] &&
   [ "$cpu_accounting" = "yes" ] &&
   [ "$memory_accounting" = "yes" ] &&
   [ "$tasks_accounting" = "yes" ] &&
   [ "$controllers_readable" = "1" ]; then
  printf '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_OK__\n'
else
  exit 1
fi
USER_MANAGER_SCRIPT
  chmod 0755 "$user_manager_script" 2>/dev/null || true
  user_manager_script_rc=0
  user_manager_script_output="$(
    timeout 180s /bin/su -l "$user_manager_user" -s /bin/sh -c \
      "env XDG_RUNTIME_DIR=$user_manager_runtime_dir /bin/sh $user_manager_script" 2>&1
  )" || user_manager_script_rc=$?
  printf '%s\n' "$user_manager_script_output" >"$user_manager_log"
  user_manager_value="$(cat "$user_manager_output" 2>/dev/null || true)"
  user_manager_cgroup="$(sed -n 's/^0:://p' "$user_manager_cgroup_file" 2>/dev/null | sed -n '1p' || true)"
  user_manager_script_active="$(printf '%s\n' "$user_manager_script_output" | sed -n 's/^__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_ACTIVE__://p' | sed -n '1p')"
  user_manager_script_show="$(printf '%s\n' "$user_manager_script_output" | sed -n 's/^__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_SHOW__://p' | sed -n '1p')"
  user_manager_script_controllers_readable="$(printf '%s\n' "$user_manager_script_output" | sed -n 's/^__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_CONTROLLERS_READABLE__://p' | sed -n '1p')"
  user_manager_script_ok=0
  printf '%s\n' "$user_manager_script_output" | grep -Fxq '__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_OK__' &&
    user_manager_script_ok=1
  user_manager_cgroup_ok=0
  case "$user_manager_cgroup" in
    "/user.slice/user-$user_manager_uid.slice/user@$user_manager_uid.service/"*)
      user_manager_cgroup_ok=1
      ;;
  esac
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_LOGIND_RC__:$user_manager_logind_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_LOGIND_ACTIVE__:$user_manager_logind_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_LINGER__:$user_manager_linger_rc:$user_manager_linger_enabled:$user_manager_linger_file"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_START_RC__:$user_manager_start_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_WAIT_SECONDS__:$user_manager_wait_seconds"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_USER_SERVICE_ACTIVE__:$user_manager_user_service_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_RUNTIME_DIR__:$user_manager_runtime_owner"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_PRIVATE_SOCKET__:$user_manager_private_socket"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_BUS_SOCKET__:$user_manager_bus_socket"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT__:$user_manager_script:$user_manager_unit"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_RC__:$user_manager_script_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_OUTPUT__:$user_manager_value"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_CGROUP__:$user_manager_cgroup"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_ACTIVE__:$user_manager_script_active"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_SCRIPT_SHOW__:$user_manager_script_show"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_CONTROLLERS_READABLE__:$user_manager_script_controllers_readable"
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_LOG_BEGIN__"
  printf '%s\n' "$user_manager_script_output" | sed -n '1,160p'
  echo "__NEMU_CHECK_FULL_SYSTEMD_USER_MANAGER_LOG_END__"
  if [ "$user_manager_logind_active" = "active" ] &&
     [ "$user_manager_linger_rc" = "0" ] &&
     [ "$user_manager_linger_enabled" = "1" ] &&
     [ "$user_manager_user_service_active" = "active" ] &&
     [ "$user_manager_runtime_owner" = "$user_manager_user:$user_manager_group:700:$user_manager_runtime_dir" ] &&
     [ "$user_manager_private_socket" = "1" ] &&
     [ "$user_manager_bus_socket" = "1" ] &&
     [ "$user_manager_script_rc" = "0" ] &&
     [ "$user_manager_script_ok" = "1" ] &&
     [ "$user_manager_value" = "systemd-user-manager-ok" ] &&
     [ "$user_manager_cgroup_ok" = "1" ] &&
     [ "$user_manager_script_show" = "yes:yes:yes:yes" ] &&
     [ "$user_manager_script_controllers_readable" = "1" ]; then
    pass full-userland-systemd-user-manager-service
  else
    systemctl status systemd-logind.service "user@$user_manager_uid.service" --no-pager 2>/dev/null || true
    journalctl -u systemd-logind.service -u "user@$user_manager_uid.service" --no-pager -n 120 2>/dev/null | sed -n '1,120p' || true
    if [ -n "$user_manager_cgroup" ]; then
      find "/sys/fs/cgroup$user_manager_cgroup" -maxdepth 1 -type f \
        \( -name 'cgroup.*' -o -name 'cpu.*' -o -name 'memory.*' -o -name 'pids.*' \) \
        -print -exec sed -n '1,20p' {} \; 2>/dev/null | sed -n '1,160p' || true
    fi
    full_userland_fail full-userland-systemd-user-manager-service
  fi
  timeout 60s /bin/su -l "$user_manager_user" -s /bin/sh -c \
    "env XDG_RUNTIME_DIR=$user_manager_runtime_dir systemctl --user stop $user_manager_unit >/dev/null 2>&1 || true; env XDG_RUNTIME_DIR=$user_manager_runtime_dir systemctl --user reset-failed $user_manager_unit >/dev/null 2>&1 || true" >/dev/null 2>&1 || true
  systemctl stop "user@$user_manager_uid.service" >/dev/null 2>&1 || true
  /bin/loginctl disable-linger "$user_manager_user" >/dev/null 2>&1 || true
  rm -f "$user_manager_script" "$user_manager_log" "$user_manager_output" "$user_manager_cgroup_file"
  timeout 10s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload >/dev/null 2>&1 || true
  check_full_userland_python_int_preflight runtime-after-daemons

  enable_unit_name=nemu-full-enable-check.service
  enable_unit_path=/etc/systemd/system/$enable_unit_name
  enable_unit_output=/run/nemu-full-enable-check.out
  enable_unit_wants=/etc/systemd/system/multi-user.target.wants/$enable_unit_name
  enable_unit_log=/tmp/nemu-full-systemctl-enable.log
  rm -f "$enable_unit_output" "$enable_unit_log"
  systemctl disable --now "$enable_unit_name" >/dev/null 2>&1 || true
  systemctl reset-failed "$enable_unit_name" >/dev/null 2>&1 || true
  rm -f "$enable_unit_wants" "$enable_unit_path"
  mkdir -p /etc/systemd/system /etc/systemd/system/multi-user.target.wants
  check_full_userland_python_int_preflight runtime-after-systemctl-pre-cleanup
  cat >"$enable_unit_path" <<'UNIT'
[Unit]
Description=NEMU full Ubuntu systemctl enable smoke
After=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'printf systemctl-enable-ok > /run/nemu-full-enable-check.out'

[Install]
WantedBy=multi-user.target
UNIT
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_UNIT__:$enable_unit_path:$enable_unit_wants"
  if systemd_daemon_reload_request "$enable_unit_name" enable-check; then
    pass full-userland-systemctl-enable-daemon-reload
  else
    full_userland_fail full-userland-systemctl-enable-daemon-reload
  fi
  check_full_userland_python_int_preflight runtime-after-systemctl-daemon-reload
  if [ "${NEMU_GUEST_STOP_AFTER_SYSTEMCTL_RELOAD_DIAG:-0}" != "0" ]; then
    echo "__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__"
    echo "__NEMU_SYSTEMD_CHECK_DONE__ rc=77"
    exit 0
  fi
  systemctl_enable_rc=0
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_ROOT__:/"
  systemctl --root=/ enable "$enable_unit_name" >"$enable_unit_log" 2>&1 ||
    systemctl_enable_rc=$?
  check_full_userland_python_int_preflight runtime-after-systemctl-root-enable
  systemctl_enabled_state="$(systemctl --root=/ is-enabled "$enable_unit_name" 2>/dev/null || true)"
  systemctl_enabled_link="$(readlink "$enable_unit_wants" 2>/dev/null || true)"
  systemctl_enabled_link_target="$(readlink -f "$enable_unit_wants" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_RC__:$systemctl_enable_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_STATE__:$systemctl_enabled_state"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_LINK__:$systemctl_enabled_link"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_LINK_TARGET__:$systemctl_enabled_link_target"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_LOG_BEGIN__"
  sed -n '1,80p' "$enable_unit_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_LOG_END__"
  if [ "$systemctl_enable_rc" = "0" ] &&
     [ "$systemctl_enabled_state" = "enabled" ]; then
    pass full-userland-systemctl-enable
  else
    full_userland_fail full-userland-systemctl-enable
  fi
  if [ -L "$enable_unit_wants" ] &&
     [ "$systemctl_enabled_link_target" = "$enable_unit_path" ]; then
    pass full-userland-systemctl-enable-wants-link
  else
    full_userland_fail full-userland-systemctl-enable-wants-link
  fi
  check_full_userland_python_int_preflight runtime-after-systemctl-root-is-enabled
  systemctl_start_rc=0
  systemd_start_runtime_unit_after_reload "$enable_unit_name" "$enable_unit_output" \
    >>"$enable_unit_log" 2>&1 || systemctl_start_rc=$?
  enable_unit_value="$(cat "$enable_unit_output" 2>/dev/null || true)"
  enable_unit_active="$(systemctl show --property=ActiveState --value "$enable_unit_name" 2>/dev/null || true)"
  enable_unit_result="$(systemctl show --property=Result --value "$enable_unit_name" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_START_RC__:$systemctl_start_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_OUTPUT__:$enable_unit_value"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_ACTIVE__:$enable_unit_active"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_RESULT__:$enable_unit_result"
  if [ "$systemctl_start_rc" = "0" ] &&
     [ "$enable_unit_value" = "systemctl-enable-ok" ] &&
     [ "$enable_unit_active" = "active" ] &&
     [ "$enable_unit_result" = "success" ]; then
    pass full-userland-systemctl-enable-start
  else
    systemctl status "$enable_unit_name" --no-pager 2>/dev/null || true
    full_userland_fail full-userland-systemctl-enable-start
  fi
  check_full_userland_python_int_preflight runtime-after-systemctl-runtime-start
  systemctl_disable_rc=0
  systemctl --root=/ disable "$enable_unit_name" >>"$enable_unit_log" 2>&1 ||
    systemctl_disable_rc=$?
  check_full_userland_python_int_preflight runtime-after-systemctl-root-disable
  systemctl_disabled_state="$(systemctl is-enabled "$enable_unit_name" 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_DISABLE_RC__:$systemctl_disable_rc"
  echo "__NEMU_CHECK_FULL_SYSTEMCTL_DISABLE_STATE__:$systemctl_disabled_state"
  if [ "$systemctl_disable_rc" = "0" ] &&
     [ ! -e "$enable_unit_wants" ] &&
     [ "$systemctl_disabled_state" = "disabled" ]; then
    pass full-userland-systemctl-disable
  else
    full_userland_fail full-userland-systemctl-disable
  fi
  systemctl stop "$enable_unit_name" >/dev/null 2>&1 || true
  systemctl reset-failed "$enable_unit_name" >/dev/null 2>&1 || true
  rm -f "$enable_unit_path" "$enable_unit_wants" "$enable_unit_output"
  systemd_daemon_reload_request "$enable_unit_name" cleanup >/dev/null 2>&1 || true
  check_full_userland_python_int_preflight runtime-after-systemctl-cleanup
  check_full_userland_python_int_preflight runtime-after-systemctl

  if [ "$full_userland_ok" = "1" ]; then
    pass full-userland-runtime
  else
    fail full-userland-runtime
  fi
}

check_full_userland_apt_install_diag() {
  apt_diag_root=$1
  apt_diag_source=$2
  if [ "${NEMU_GUEST_APT_INSTALL_DIAG:-0}" = "0" ] &&
     [ "${NEMU_GUEST_APT_INSTALL_ACTUAL:-0}" != "1" ]; then
    pass full-userland-apt-direct-install-diag-skip
    return
  fi

  apt_diag_timeout=${NEMU_GUEST_APT_INSTALL_DIAG_TIMEOUT:-300}
  apt_remove_timeout=${NEMU_GUEST_APT_REMOVE_DIAG_TIMEOUT:-600}
  apt_diag_dir="$apt_diag_root/direct-install-diag"
  apt_diag_archives="$apt_diag_dir/archives"
  apt_diag_empty_sim_status="$apt_diag_dir/status-empty-simulate"
  apt_diag_empty_download_status="$apt_diag_dir/status-empty-download"
  apt_diag_empty_install_status="$apt_diag_dir/status-empty-install"
  mkdir -p "$apt_diag_archives/partial"
  : > "$apt_diag_empty_sim_status"
  : > "$apt_diag_empty_download_status"
  : > "$apt_diag_empty_install_status"

  apt_direct_full_log="$apt_diag_dir/full-status-simulate.log"
  apt_direct_full_rc=0
  DEBIAN_FRONTEND=noninteractive timeout "${apt_diag_timeout}s" \
    apt-get -s install -y --no-install-recommends \
      nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
      -o "Dir::Etc::parts=-" \
      -o "Dir::State::lists=$apt_diag_root/lists" \
      -o "Dir::Cache::archives=$apt_diag_archives" \
      -o "APT::Architecture=riscv64" \
      -o "Acquire::Languages=none" \
      -o "Acquire::Retries=0" \
      -o "Acquire::http::Timeout=60" \
      -o "APT::Get::List-Cleanup=0" \
      >"$apt_direct_full_log" 2>&1 || apt_direct_full_rc=$?
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_RC__:$apt_direct_full_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_LOG_BEGIN__"
  sed -n '1,120p' "$apt_direct_full_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_LOG_END__"
  if [ "$apt_direct_full_rc" = "0" ] &&
     grep -Eq '^(Inst|Conf) nemu-hostless-hello' "$apt_direct_full_log" &&
     grep -Eq '^(Inst|Conf) nemu-hostless-meta' "$apt_direct_full_log"; then
    pass full-userland-apt-direct-full-status-simulate
  elif [ "$apt_direct_full_rc" = "124" ]; then
    pass full-userland-apt-direct-full-status-timeout-observed
  else
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_NONZERO__:$apt_direct_full_rc"
  fi

  apt_direct_empty_sim_log="$apt_diag_dir/empty-status-simulate.log"
  apt_direct_empty_sim_rc=0
  DEBIAN_FRONTEND=noninteractive timeout "${apt_diag_timeout}s" \
    apt-get -s install -y --no-install-recommends \
      nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
      -o "Dir::Etc::parts=-" \
      -o "Dir::State::lists=$apt_diag_root/lists" \
      -o "Dir::State::status=$apt_diag_empty_sim_status" \
      -o "Dir::Cache::archives=$apt_diag_archives" \
      -o "APT::Architecture=riscv64" \
      -o "Acquire::Languages=none" \
      -o "Acquire::Retries=0" \
      -o "Acquire::http::Timeout=60" \
      -o "APT::Get::List-Cleanup=0" \
      >"$apt_direct_empty_sim_log" 2>&1 || apt_direct_empty_sim_rc=$?
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__:$apt_direct_empty_sim_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__"
  sed -n '1,120p' "$apt_direct_empty_sim_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__"
  if [ "$apt_direct_empty_sim_rc" = "0" ] &&
     grep -Eq '^(Inst|Conf) nemu-hostless-hello' "$apt_direct_empty_sim_log" &&
     grep -Eq '^(Inst|Conf) nemu-hostless-meta' "$apt_direct_empty_sim_log"; then
    pass full-userland-apt-direct-empty-status-simulate
  else
    fail full-userland-apt-direct-empty-status-simulate
  fi

  rm -f "$apt_diag_archives"/nemu-hostless-hello_1.0_riscv64.deb \
    "$apt_diag_archives"/nemu-hostless-meta_1.0_riscv64.deb \
    "$apt_diag_archives"/nemu-hostless-hello_1.1_riscv64.deb \
    "$apt_diag_archives"/nemu-hostless-meta_1.1_riscv64.deb
  apt_direct_download_log="$apt_diag_dir/empty-status-download-only.log"
  apt_direct_download_rc=0
  apt_direct_download_sha256=
  apt_direct_download_meta_sha256=
  apt_direct_download_targets="nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0"
  DEBIAN_FRONTEND=noninteractive timeout "${apt_diag_timeout}s" \
    apt-get --download-only install -y --no-install-recommends \
      nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
      -o "Dir::Etc::parts=-" \
      -o "Dir::State::lists=$apt_diag_root/lists" \
      -o "Dir::State::status=$apt_diag_empty_download_status" \
      -o "Dir::Cache::archives=$apt_diag_archives" \
      -o "APT::Architecture=riscv64" \
      -o "Acquire::Languages=none" \
      -o "Acquire::Retries=0" \
      -o "Acquire::http::Timeout=60" \
      -o "APT::Get::List-Cleanup=0" \
      >"$apt_direct_download_log" 2>&1 || apt_direct_download_rc=$?
  if [ -f "$apt_diag_archives/nemu-hostless-hello_1.0_riscv64.deb" ]; then
    apt_direct_download_sha256="$(
      sha256sum "$apt_diag_archives/nemu-hostless-hello_1.0_riscv64.deb" | awk '{print $1}'
    )"
  fi
  if [ -f "$apt_diag_archives/nemu-hostless-meta_1.0_riscv64.deb" ]; then
    apt_direct_download_meta_sha256="$(
      sha256sum "$apt_diag_archives/nemu-hostless-meta_1.0_riscv64.deb" | awk '{print $1}'
    )"
  fi
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__:$apt_direct_download_targets"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__:$apt_direct_download_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__:$apt_direct_download_sha256"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__:$apt_direct_download_meta_sha256"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__"
  sed -n '1,160p' "$apt_direct_download_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__"
  if [ "$apt_direct_download_rc" = "0" ] &&
     [ "$apt_direct_download_sha256" = "49f963a8d5e812279f07b29e9e6df366ccabd08c4c3402f6a89724f20811cbe7" ] &&
     [ "$apt_direct_download_meta_sha256" = "045eea5e02492c3ea2b05729b8feef54f51044d24f5b752012335b4d82de2d67" ]; then
    pass full-userland-apt-direct-empty-status-download
  else
    fail full-userland-apt-direct-empty-status-download
  fi

  apt_direct_install_snapshot() {
    apt_direct_snapshot_label=$1
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__:$apt_direct_snapshot_label"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__"
    ps -eo pid,ppid,stat,etime,args 2>/dev/null | grep -E 'apt-get|dpkg|timeout' | grep -v grep || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__"
    if [ -s "$apt_direct_install_log" ]; then
      tail -n 80 "$apt_direct_install_log" 2>/dev/null || true
    else
      echo "(install-log-empty)"
    fi
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__"
    ls -l /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
      /var/cache/apt/archives/lock 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__:$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_SNAPSHOT__:$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PREINST_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/preinst-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/postinst-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
    )"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
    )"
  }

  if [ "${NEMU_GUEST_APT_INSTALL_ACTUAL:-0}" != "1" ]; then
    pass full-userland-apt-direct-actual-install-skip
    return
  fi

  apt_direct_install_log="$apt_diag_dir/full-status-install-no-pty.log"
  apt_direct_install_rc=0
  rm -f "$apt_direct_install_log"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__:nemu-hostless-hello=1.0 nemu-hostless-meta=1.0"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__:empty-status-real-dpkg"
  (
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
      -o "Dir::Etc::parts=-" \
      -o "Dir::State::lists=$apt_diag_root/lists" \
      -o "Dir::State::status=$apt_diag_empty_install_status" \
      -o "Dir::Cache::archives=$apt_diag_archives" \
      -o "APT::Architecture=riscv64" \
      -o "Acquire::Languages=none" \
      -o "Acquire::Retries=0" \
      -o "Acquire::http::Timeout=60" \
      -o "APT::Get::List-Cleanup=0" \
      -o "Dpkg::Use-Pty=0" \
      >"$apt_direct_install_log" 2>&1
  ) &
  apt_direct_install_pid=$!
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__:$apt_direct_install_pid"
  apt_direct_install_snapshot "start"
  (
    apt_direct_monitor_i=0
    while kill -0 "$apt_direct_install_pid" 2>/dev/null; do
      sleep 15
      apt_direct_monitor_i=$((apt_direct_monitor_i + 1))
      apt_direct_install_snapshot "monitor-$apt_direct_monitor_i"
    done
  ) &
  apt_direct_monitor_pid=$!
  apt_direct_deadline_rc=0
  timeout "${apt_diag_timeout}s" sh -c "while kill -0 $apt_direct_install_pid 2>/dev/null; do sleep 1; done" || apt_direct_deadline_rc=$?
  if kill -0 "$apt_direct_install_pid" 2>/dev/null; then
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TIMEOUT__:$apt_diag_timeout"
    apt_direct_install_snapshot "timeout"
    kill "$apt_direct_install_pid" 2>/dev/null || true
    sleep 5
    if kill -0 "$apt_direct_install_pid" 2>/dev/null; then
      kill -KILL "$apt_direct_install_pid" 2>/dev/null || true
    fi
    wait "$apt_direct_install_pid" 2>/dev/null || true
    apt_direct_install_rc=124
  else
    wait "$apt_direct_install_pid" || apt_direct_install_rc=$?
  fi
  kill "$apt_direct_monitor_pid" 2>/dev/null || true
  wait "$apt_direct_monitor_pid" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__:$apt_direct_deadline_rc"
  apt_direct_install_snapshot "final"
  apt_direct_install_message="$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
  apt_direct_install_meta_message="$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
  apt_direct_install_meta_preinst="$(cat /var/lib/nemu-hostless-meta/preinst-message 2>/dev/null || true)"
  apt_direct_install_meta_postinst="$(cat /var/lib/nemu-hostless-meta/postinst-message 2>/dev/null || true)"
  apt_direct_install_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
  )"
  apt_direct_install_meta_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
  )"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__:$apt_direct_install_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__:$apt_direct_install_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__:$apt_direct_install_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE__:$apt_direct_install_meta_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PREINST__:$apt_direct_install_meta_preinst"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST__:$apt_direct_install_meta_postinst"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS__:$apt_direct_install_meta_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_BEGIN__"
  sed -n '1,180p' "$apt_direct_install_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_END__"
  apt_direct_install_effect_ok=0
  if [ "$apt_direct_install_message" = "hello from NEMU hostless apt" ] &&
     [ "$apt_direct_install_status" = "install ok installed 1.0 riscv64" ] &&
     [ "$apt_direct_install_meta_message" = "hello from NEMU hostless meta" ] &&
     [ "$apt_direct_install_meta_preinst" = "preinst from NEMU hostless meta" ] &&
     [ "$apt_direct_install_meta_postinst" = "postinst from NEMU hostless meta" ] &&
     [ "$apt_direct_install_meta_status" = "install ok installed 1.0 riscv64" ]; then
    apt_direct_install_effect_ok=1
  fi
  if [ "$apt_direct_install_rc" = "0" ] &&
     [ "$apt_direct_install_effect_ok" = "1" ]; then
    pass full-userland-apt-direct-full-status-install
  elif [ "$apt_direct_install_rc" = "124" ] &&
       [ "$apt_direct_install_effect_ok" = "1" ]; then
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_EFFECT_OK_AFTER_TIMEOUT__:124"
    pass full-userland-apt-direct-full-status-install
  else
    fail full-userland-apt-direct-full-status-install
  fi

  apt_direct_hello_list_log="$apt_diag_dir/full-status-dpkg-list-hello.log"
  apt_direct_hello_search_log="$apt_diag_dir/full-status-dpkg-search-hello.log"
  apt_direct_meta_list_log="$apt_diag_dir/full-status-dpkg-list-meta.log"
  apt_direct_meta_search_log="$apt_diag_dir/full-status-dpkg-search-meta.log"
  apt_direct_hello_list_rc=0
  apt_direct_hello_search_rc=0
  apt_direct_meta_list_rc=0
  apt_direct_meta_search_rc=0
  if [ "$apt_direct_install_effect_ok" = "1" ]; then
    dpkg -L nemu-hostless-hello >"$apt_direct_hello_list_log" 2>&1 || apt_direct_hello_list_rc=$?
    dpkg -S /usr/share/nemu-hostless-hello/message >"$apt_direct_hello_search_log" 2>&1 || apt_direct_hello_search_rc=$?
    dpkg -L nemu-hostless-meta >"$apt_direct_meta_list_log" 2>&1 || apt_direct_meta_list_rc=$?
    dpkg -S /usr/share/nemu-hostless-meta/message >"$apt_direct_meta_search_log" 2>&1 || apt_direct_meta_search_rc=$?
  else
    apt_direct_hello_list_rc=125
    apt_direct_hello_search_rc=125
    apt_direct_meta_list_rc=125
    apt_direct_meta_search_rc=125
  fi
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__:$apt_direct_hello_list_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__:$apt_direct_hello_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__:$apt_direct_meta_list_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__:$apt_direct_meta_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"
  sed -n '1,80p' "$apt_direct_hello_list_log" 2>/dev/null || true
  sed -n '1,40p' "$apt_direct_hello_search_log" 2>/dev/null || true
  sed -n '1,80p' "$apt_direct_meta_list_log" 2>/dev/null || true
  sed -n '1,40p' "$apt_direct_meta_search_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_END__"
  if [ "$apt_direct_hello_list_rc" = "0" ] &&
     [ "$apt_direct_hello_search_rc" = "0" ] &&
     [ "$apt_direct_meta_list_rc" = "0" ] &&
     [ "$apt_direct_meta_search_rc" = "0" ] &&
     grep -Fxq /usr/share/nemu-hostless-hello/message "$apt_direct_hello_list_log" &&
     grep -Fq "nemu-hostless-hello: /usr/share/nemu-hostless-hello/message" "$apt_direct_hello_search_log" &&
     grep -Fxq /usr/share/nemu-hostless-meta/message "$apt_direct_meta_list_log" &&
     grep -Fq "nemu-hostless-meta: /usr/share/nemu-hostless-meta/message" "$apt_direct_meta_search_log"; then
    pass full-userland-apt-direct-full-status-dpkg-ownership
  else
    fail full-userland-apt-direct-full-status-dpkg-ownership
  fi

  apt_direct_upgrade_log="$apt_diag_dir/full-status-upgrade-no-pty.log"
  apt_direct_upgrade_status="$apt_diag_dir/status-upgrade-installed-v1"
  apt_direct_upgrade_rc=0
  apt_direct_upgrade_effect_ok=0
  apt_direct_upgrade_snapshot() {
    apt_direct_upgrade_snapshot_label=$1
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_SAMPLE__:$apt_direct_upgrade_snapshot_label"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PS_BEGIN__"
    ps -eo pid,ppid,stat,etime,args 2>/dev/null | grep -E 'apt-get|dpkg|timeout' | grep -v grep || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_TAIL_BEGIN__"
    if [ -s "$apt_direct_upgrade_log" ]; then
      tail -n 80 "$apt_direct_upgrade_log" 2>/dev/null || true
    else
      echo "(upgrade-log-empty)"
    fi
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_TAIL_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOCKS_BEGIN__"
    ls -l /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
      /var/cache/apt/archives/lock 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOCKS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE_SNAPSHOT__:$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_MESSAGE_SNAPSHOT__:$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_PREINST_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/preinst-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_POSTINST_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/postinst-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
    )"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_DPKG_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
    )"
  }
  rm -f "$apt_direct_upgrade_log"
  dpkg-query -s nemu-hostless-hello nemu-hostless-meta >"$apt_direct_upgrade_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_START__"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TARGET__:nemu-hostless-hello=1.1 nemu-hostless-meta=1.1"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_APT_STATE__:installed-v1-target-status-real-dpkg"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_STATUS_BEGIN__"
  sed -n '1,120p' "$apt_direct_upgrade_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_STATUS_END__"
  if [ "$apt_direct_install_effect_ok" = "1" ]; then
    (
      DEBIAN_FRONTEND=noninteractive \
      apt-get install -y --no-install-recommends \
          nemu-hostless-hello:riscv64=1.1 nemu-hostless-meta:riscv64=1.1 \
          -o "Dir::Etc::sourcelist=$apt_diag_source" \
          -o "Dir::Etc::sourceparts=-" \
          -o "Dir::Etc::parts=-" \
          -o "Dir::State::lists=$apt_diag_root/lists" \
          -o "Dir::State::status=$apt_direct_upgrade_status" \
          -o "Dir::Cache::archives=$apt_diag_archives" \
          -o "APT::Architecture=riscv64" \
          -o "Acquire::Languages=none" \
          -o "Acquire::Retries=0" \
          -o "Acquire::http::Timeout=60" \
          -o "APT::Get::List-Cleanup=0" \
          -o "Dpkg::Use-Pty=0" \
          >"$apt_direct_upgrade_log" 2>&1
    ) &
    apt_direct_upgrade_pid=$!
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PID__:$apt_direct_upgrade_pid"
    apt_direct_upgrade_snapshot "start"
    (
      apt_direct_upgrade_monitor_i=0
      while kill -0 "$apt_direct_upgrade_pid" 2>/dev/null; do
        sleep 15
        apt_direct_upgrade_monitor_i=$((apt_direct_upgrade_monitor_i + 1))
        apt_direct_upgrade_snapshot "monitor-$apt_direct_upgrade_monitor_i"
      done
    ) &
    apt_direct_upgrade_monitor_pid=$!
    apt_direct_upgrade_deadline_rc=0
    timeout "${apt_diag_timeout}s" sh -c "while kill -0 $apt_direct_upgrade_pid 2>/dev/null; do sleep 1; done" || apt_direct_upgrade_deadline_rc=$?
    if kill -0 "$apt_direct_upgrade_pid" 2>/dev/null; then
      echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TIMEOUT__:$apt_diag_timeout"
      apt_direct_upgrade_snapshot "timeout"
      kill "$apt_direct_upgrade_pid" 2>/dev/null || true
      sleep 5
      if kill -0 "$apt_direct_upgrade_pid" 2>/dev/null; then
        kill -KILL "$apt_direct_upgrade_pid" 2>/dev/null || true
      fi
      wait "$apt_direct_upgrade_pid" 2>/dev/null || true
      apt_direct_upgrade_rc=124
    else
      wait "$apt_direct_upgrade_pid" || apt_direct_upgrade_rc=$?
    fi
    kill "$apt_direct_upgrade_monitor_pid" 2>/dev/null || true
    wait "$apt_direct_upgrade_monitor_pid" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DEADLINE_RC__:$apt_direct_upgrade_deadline_rc"
    apt_direct_upgrade_snapshot "final"
  else
    apt_direct_upgrade_rc=125
    echo "skip upgrade because install effect was not complete" >"$apt_direct_upgrade_log"
  fi
  apt_direct_upgrade_message="$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
  apt_direct_upgrade_meta_message="$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
  apt_direct_upgrade_meta_preinst="$(cat /var/lib/nemu-hostless-meta/preinst-message 2>/dev/null || true)"
  apt_direct_upgrade_meta_postinst="$(cat /var/lib/nemu-hostless-meta/postinst-message 2>/dev/null || true)"
  apt_direct_upgrade_status_value="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
  )"
  apt_direct_upgrade_meta_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
  )"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_RC__:$apt_direct_upgrade_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE__:$apt_direct_upgrade_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS__:$apt_direct_upgrade_status_value"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_MESSAGE__:$apt_direct_upgrade_meta_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_PREINST__:$apt_direct_upgrade_meta_preinst"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_POSTINST__:$apt_direct_upgrade_meta_postinst"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_DPKG_STATUS__:$apt_direct_upgrade_meta_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_BEGIN__"
  sed -n '1,180p' "$apt_direct_upgrade_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_END__"
  if [ "$apt_direct_upgrade_message" = "hello from NEMU hostless apt v1.1" ] &&
     [ "$apt_direct_upgrade_status_value" = "install ok installed 1.1 riscv64" ] &&
     [ "$apt_direct_upgrade_meta_message" = "hello from NEMU hostless meta v1.1" ] &&
     [ "$apt_direct_upgrade_meta_preinst" = "preinst from NEMU hostless meta v1.1" ] &&
     [ "$apt_direct_upgrade_meta_postinst" = "postinst from NEMU hostless meta v1.1" ] &&
     [ "$apt_direct_upgrade_meta_status" = "install ok installed 1.1 riscv64" ]; then
    apt_direct_upgrade_effect_ok=1
  fi
  if [ "$apt_direct_upgrade_rc" = "0" ] &&
     [ "$apt_direct_upgrade_effect_ok" = "1" ]; then
    pass full-userland-apt-direct-full-status-upgrade
  elif [ "$apt_direct_upgrade_rc" = "124" ] &&
       [ "$apt_direct_upgrade_effect_ok" = "1" ]; then
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_EFFECT_OK_AFTER_TIMEOUT__:124"
    pass full-userland-apt-direct-full-status-upgrade
  else
    fail full-userland-apt-direct-full-status-upgrade
  fi

  apt_direct_upgrade_hello_list_log="$apt_diag_dir/full-status-upgrade-dpkg-list-hello.log"
  apt_direct_upgrade_hello_search_log="$apt_diag_dir/full-status-upgrade-dpkg-search-hello.log"
  apt_direct_upgrade_meta_list_log="$apt_diag_dir/full-status-upgrade-dpkg-list-meta.log"
  apt_direct_upgrade_meta_search_log="$apt_diag_dir/full-status-upgrade-dpkg-search-meta.log"
  apt_direct_upgrade_hello_list_rc=0
  apt_direct_upgrade_hello_search_rc=0
  apt_direct_upgrade_meta_list_rc=0
  apt_direct_upgrade_meta_search_rc=0
  if [ "$apt_direct_upgrade_effect_ok" = "1" ]; then
    dpkg -L nemu-hostless-hello >"$apt_direct_upgrade_hello_list_log" 2>&1 || apt_direct_upgrade_hello_list_rc=$?
    dpkg -S /usr/share/nemu-hostless-hello/message >"$apt_direct_upgrade_hello_search_log" 2>&1 || apt_direct_upgrade_hello_search_rc=$?
    dpkg -L nemu-hostless-meta >"$apt_direct_upgrade_meta_list_log" 2>&1 || apt_direct_upgrade_meta_list_rc=$?
    dpkg -S /usr/share/nemu-hostless-meta/message >"$apt_direct_upgrade_meta_search_log" 2>&1 || apt_direct_upgrade_meta_search_rc=$?
  else
    apt_direct_upgrade_hello_list_rc=125
    apt_direct_upgrade_hello_search_rc=125
    apt_direct_upgrade_meta_list_rc=125
    apt_direct_upgrade_meta_search_rc=125
  fi
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_HELLO_RC__:$apt_direct_upgrade_hello_list_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_HELLO_RC__:$apt_direct_upgrade_hello_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_META_RC__:$apt_direct_upgrade_meta_list_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_META_RC__:$apt_direct_upgrade_meta_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_OWNERSHIP_LOG_BEGIN__"
  sed -n '1,80p' "$apt_direct_upgrade_hello_list_log" 2>/dev/null || true
  sed -n '1,40p' "$apt_direct_upgrade_hello_search_log" 2>/dev/null || true
  sed -n '1,80p' "$apt_direct_upgrade_meta_list_log" 2>/dev/null || true
  sed -n '1,40p' "$apt_direct_upgrade_meta_search_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_OWNERSHIP_LOG_END__"
  if [ "$apt_direct_upgrade_hello_list_rc" = "0" ] &&
     [ "$apt_direct_upgrade_hello_search_rc" = "0" ] &&
     [ "$apt_direct_upgrade_meta_list_rc" = "0" ] &&
     [ "$apt_direct_upgrade_meta_search_rc" = "0" ] &&
     grep -Fxq /usr/share/nemu-hostless-hello/message "$apt_direct_upgrade_hello_list_log" &&
     grep -Fq "nemu-hostless-hello: /usr/share/nemu-hostless-hello/message" "$apt_direct_upgrade_hello_search_log" &&
     grep -Fxq /usr/share/nemu-hostless-meta/message "$apt_direct_upgrade_meta_list_log" &&
     grep -Fq "nemu-hostless-meta: /usr/share/nemu-hostless-meta/message" "$apt_direct_upgrade_meta_search_log"; then
    pass full-userland-apt-direct-full-status-upgrade-ownership
  else
    fail full-userland-apt-direct-full-status-upgrade-ownership
  fi

  apt_direct_remove_snapshot() {
    apt_direct_remove_snapshot_label=$1
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_SAMPLE__:$apt_direct_remove_snapshot_label"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_PS_BEGIN__"
    ps -eo pid,ppid,stat,etime,args 2>/dev/null | grep -E 'apt-get|dpkg|timeout' | grep -v grep || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_PS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_TAIL_BEGIN__"
    if [ -s "$apt_direct_remove_log" ]; then
      tail -n 80 "$apt_direct_remove_log" 2>/dev/null || true
    else
      echo "(remove-log-empty)"
    fi
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_TAIL_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOCKS_BEGIN__"
    ls -l /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
      /var/cache/apt/archives/lock 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOCKS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_PRERM_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/prerm-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_POSTRM_SNAPSHOT__:$(cat /var/lib/nemu-hostless-meta/postrm-message 2>/dev/null || true)"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
    )"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_HELLO_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
    )"
  }

  apt_direct_remove_log="$apt_diag_dir/full-status-remove-no-pty.log"
  apt_direct_remove_status="$apt_diag_dir/status-remove-installed"
  apt_direct_remove_rc=0
  rm -f "$apt_direct_remove_log"
  dpkg-query -s nemu-hostless-hello nemu-hostless-meta >"$apt_direct_remove_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_START__"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_TARGET__:nemu-hostless-meta"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_APT_STATE__:installed-v1.1-target-status-real-dpkg"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_STATUS_BEGIN__"
  sed -n '1,120p' "$apt_direct_remove_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_STATUS_END__"
  if [ "$apt_direct_upgrade_effect_ok" = "1" ]; then
    (
      DEBIAN_FRONTEND=noninteractive \
      apt-get remove -y nemu-hostless-meta:riscv64 \
        -o "Dir::Etc::sourcelist=$apt_diag_source" \
        -o "Dir::Etc::sourceparts=-" \
        -o "Dir::Etc::parts=-" \
        -o "Dir::State::lists=$apt_diag_root/lists" \
        -o "Dir::State::status=$apt_direct_remove_status" \
        -o "Dir::Cache::archives=$apt_diag_archives" \
        -o "APT::Architecture=riscv64" \
        -o "Acquire::Languages=none" \
        -o "Acquire::Retries=0" \
        -o "Acquire::http::Timeout=60" \
        -o "APT::Get::List-Cleanup=0" \
        -o "Dpkg::Use-Pty=0" \
        >"$apt_direct_remove_log" 2>&1
    ) &
    apt_direct_remove_pid=$!
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_PID__:$apt_direct_remove_pid"
    apt_direct_remove_snapshot "start"
    (
      apt_direct_remove_monitor_i=0
      while kill -0 "$apt_direct_remove_pid" 2>/dev/null; do
        sleep 15
        apt_direct_remove_monitor_i=$((apt_direct_remove_monitor_i + 1))
        apt_direct_remove_snapshot "monitor-$apt_direct_remove_monitor_i"
      done
    ) &
    apt_direct_remove_monitor_pid=$!
    apt_direct_remove_deadline_rc=0
    timeout "${apt_remove_timeout}s" sh -c "while kill -0 $apt_direct_remove_pid 2>/dev/null; do sleep 1; done" || apt_direct_remove_deadline_rc=$?
    if kill -0 "$apt_direct_remove_pid" 2>/dev/null; then
      echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_TIMEOUT__:$apt_remove_timeout"
      apt_direct_remove_snapshot "timeout"
      kill "$apt_direct_remove_pid" 2>/dev/null || true
      sleep 5
      if kill -0 "$apt_direct_remove_pid" 2>/dev/null; then
        kill -KILL "$apt_direct_remove_pid" 2>/dev/null || true
      fi
      wait "$apt_direct_remove_pid" 2>/dev/null || true
      apt_direct_remove_rc=124
    else
      wait "$apt_direct_remove_pid" || apt_direct_remove_rc=$?
    fi
    kill "$apt_direct_remove_monitor_pid" 2>/dev/null || true
    wait "$apt_direct_remove_monitor_pid" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_DEADLINE_RC__:$apt_direct_remove_deadline_rc"
    apt_direct_remove_snapshot "final"
  else
    apt_direct_remove_rc=125
    echo "skip remove because upgrade effect was not complete" >"$apt_direct_remove_log"
  fi
  apt_direct_remove_meta_prerm="$(cat /var/lib/nemu-hostless-meta/prerm-message 2>/dev/null || true)"
  apt_direct_remove_meta_postrm="$(cat /var/lib/nemu-hostless-meta/postrm-message 2>/dev/null || true)"
  apt_direct_remove_meta_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
  )"
  apt_direct_remove_meta_message="$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
  apt_direct_remove_hello_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
  )"
  apt_direct_remove_hello_message="$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_RC__:$apt_direct_remove_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PRERM__:$apt_direct_remove_meta_prerm"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTRM__:$apt_direct_remove_meta_postrm"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_REMOVE__:$apt_direct_remove_meta_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_AFTER_REMOVE__:$apt_direct_remove_meta_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__:$apt_direct_remove_hello_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__:$apt_direct_remove_hello_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_BEGIN__"
  sed -n '1,180p' "$apt_direct_remove_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_END__"
  if [ "$apt_direct_remove_rc" = "0" ] &&
     [ "$apt_direct_remove_meta_prerm" = "prerm from NEMU hostless meta v1.1" ] &&
     [ "$apt_direct_remove_meta_postrm" = "postrm from NEMU hostless meta v1.1" ] &&
     [ "$apt_direct_remove_meta_status" = "deinstall ok config-files 1.1 riscv64" ] &&
     [ -z "$apt_direct_remove_meta_message" ] &&
     [ "$apt_direct_remove_hello_status" = "install ok installed 1.1 riscv64" ] &&
     [ "$apt_direct_remove_hello_message" = "hello from NEMU hostless apt v1.1" ]; then
    pass full-userland-apt-direct-full-status-remove
  elif [ "$apt_direct_remove_rc" = "124" ] &&
       [ "$apt_direct_remove_meta_prerm" = "prerm from NEMU hostless meta v1.1" ] &&
       [ "$apt_direct_remove_meta_postrm" = "postrm from NEMU hostless meta v1.1" ] &&
       [ -z "$apt_direct_remove_meta_status" ] &&
       [ -z "$apt_direct_remove_meta_message" ] &&
       [ "$apt_direct_remove_hello_status" = "install ok installed 1.1 riscv64" ] &&
       [ "$apt_direct_remove_hello_message" = "hello from NEMU hostless apt v1.1" ]; then
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_EFFECT_OK_AFTER_TIMEOUT__:124"
    pass full-userland-apt-direct-full-status-remove
  else
    fail full-userland-apt-direct-full-status-remove
  fi

  apt_direct_purge_snapshot() {
    apt_direct_purge_snapshot_label=$1
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_SAMPLE__:$apt_direct_purge_snapshot_label"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_PS_BEGIN__"
    ps -eo pid,ppid,stat,etime,args 2>/dev/null | grep -E 'apt-get|dpkg|timeout' | grep -v grep || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_PS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_TAIL_BEGIN__"
    if [ -s "$apt_direct_purge_log" ]; then
      tail -n 80 "$apt_direct_purge_log" 2>/dev/null || true
    else
      echo "(purge-log-empty)"
    fi
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_TAIL_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOCKS_BEGIN__"
    ls -l /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
      /var/cache/apt/archives/lock 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOCKS_END__"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_META_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
    )"
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_HELLO_STATUS_SNAPSHOT__:$(
      dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
    )"
  }

  apt_direct_purge_log="$apt_diag_dir/full-status-purge-no-pty.log"
  apt_direct_purge_status="$apt_diag_dir/status-purge-config-files"
  apt_direct_purge_rc=0
  rm -f "$apt_direct_purge_log"
  dpkg-query -s nemu-hostless-meta nemu-hostless-hello >"$apt_direct_purge_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_START__"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_TARGET__:nemu-hostless-meta"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_APT_STATE__:config-files-v1.1-target-status-real-dpkg"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_STATUS_BEGIN__"
  sed -n '1,120p' "$apt_direct_purge_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_STATUS_END__"
  if [ "$apt_direct_remove_rc" = "0" ]; then
    (
      DEBIAN_FRONTEND=noninteractive \
      apt-get purge -y nemu-hostless-meta:riscv64 \
        -o "Dir::Etc::sourcelist=$apt_diag_source" \
        -o "Dir::Etc::sourceparts=-" \
        -o "Dir::Etc::parts=-" \
        -o "Dir::State::lists=$apt_diag_root/lists" \
        -o "Dir::State::status=$apt_direct_purge_status" \
        -o "Dir::Cache::archives=$apt_diag_archives" \
        -o "APT::Architecture=riscv64" \
        -o "Acquire::Languages=none" \
        -o "Acquire::Retries=0" \
        -o "Acquire::http::Timeout=60" \
        -o "APT::Get::List-Cleanup=0" \
        -o "Dpkg::Use-Pty=0" \
        >"$apt_direct_purge_log" 2>&1
    ) &
    apt_direct_purge_pid=$!
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_PID__:$apt_direct_purge_pid"
    apt_direct_purge_snapshot "start"
    (
      apt_direct_purge_monitor_i=0
      while kill -0 "$apt_direct_purge_pid" 2>/dev/null; do
        sleep 15
        apt_direct_purge_monitor_i=$((apt_direct_purge_monitor_i + 1))
        apt_direct_purge_snapshot "monitor-$apt_direct_purge_monitor_i"
      done
    ) &
    apt_direct_purge_monitor_pid=$!
    apt_direct_purge_deadline_rc=0
    timeout "${apt_remove_timeout}s" sh -c "while kill -0 $apt_direct_purge_pid 2>/dev/null; do sleep 1; done" || apt_direct_purge_deadline_rc=$?
    if kill -0 "$apt_direct_purge_pid" 2>/dev/null; then
      echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_TIMEOUT__:$apt_remove_timeout"
      apt_direct_purge_snapshot "timeout"
      kill "$apt_direct_purge_pid" 2>/dev/null || true
      sleep 5
      if kill -0 "$apt_direct_purge_pid" 2>/dev/null; then
        kill -KILL "$apt_direct_purge_pid" 2>/dev/null || true
      fi
      wait "$apt_direct_purge_pid" 2>/dev/null || true
      apt_direct_purge_rc=124
    else
      wait "$apt_direct_purge_pid" || apt_direct_purge_rc=$?
    fi
    kill "$apt_direct_purge_monitor_pid" 2>/dev/null || true
    wait "$apt_direct_purge_monitor_pid" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_DEADLINE_RC__:$apt_direct_purge_deadline_rc"
    apt_direct_purge_snapshot "final"
  else
    apt_direct_purge_rc=125
    echo "skip purge because remove did not complete" >"$apt_direct_purge_log"
  fi
  apt_direct_purge_meta_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-meta 2>/dev/null || true
  )"
  apt_direct_purge_meta_message="$(cat /usr/share/nemu-hostless-meta/message 2>/dev/null || true)"
  apt_direct_purge_hello_status="$(
    dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true
  )"
  apt_direct_purge_hello_message="$(cat /usr/share/nemu-hostless-hello/message 2>/dev/null || true)"
  apt_direct_purge_meta_search_log="$apt_diag_dir/full-status-dpkg-search-meta-after-purge.log"
  apt_direct_purge_hello_search_log="$apt_diag_dir/full-status-dpkg-search-hello-after-purge.log"
  apt_direct_purge_meta_search_rc=0
  apt_direct_purge_hello_search_rc=0
  dpkg -S /usr/share/nemu-hostless-meta/message >"$apt_direct_purge_meta_search_log" 2>&1 || apt_direct_purge_meta_search_rc=$?
  dpkg -S /usr/share/nemu-hostless-hello/message >"$apt_direct_purge_hello_search_log" 2>&1 || apt_direct_purge_hello_search_rc=$?
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_RC__:$apt_direct_purge_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_PURGE__:$apt_direct_purge_meta_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_AFTER_PURGE__:$apt_direct_purge_meta_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__:$apt_direct_purge_hello_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__:$apt_direct_purge_hello_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_SEARCH_AFTER_PURGE_RC__:$apt_direct_purge_meta_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__:$apt_direct_purge_hello_search_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_BEGIN__"
  sed -n '1,180p' "$apt_direct_purge_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_END__"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_OWNERSHIP_LOG_BEGIN__"
  sed -n '1,40p' "$apt_direct_purge_meta_search_log" 2>/dev/null || true
  sed -n '1,40p' "$apt_direct_purge_hello_search_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_OWNERSHIP_LOG_END__"
  if [ "$apt_direct_purge_rc" = "0" ] &&
     [ -z "$apt_direct_purge_meta_status" ] &&
     [ -z "$apt_direct_purge_meta_message" ] &&
     [ "$apt_direct_purge_hello_status" = "install ok installed 1.1 riscv64" ] &&
     [ "$apt_direct_purge_hello_message" = "hello from NEMU hostless apt v1.1" ]; then
    pass full-userland-apt-direct-full-status-purge
  else
    fail full-userland-apt-direct-full-status-purge
  fi
  if [ "$apt_direct_purge_rc" = "0" ] &&
     [ "$apt_direct_purge_meta_search_rc" != "0" ] &&
     [ "$apt_direct_purge_hello_search_rc" = "0" ] &&
     grep -Fq "nemu-hostless-hello: /usr/share/nemu-hostless-hello/message" "$apt_direct_purge_hello_search_log"; then
    pass full-userland-apt-direct-full-status-purge-ownership
  else
    fail full-userland-apt-direct-full-status-purge-ownership
  fi
}

check_full_userland_python_int_preflight() {
  preflight_tag="$1"
  python_int_dir=/tmp/nemu-full-userland-python-int
  python_int_log="$python_int_dir/$preflight_tag.log"
  mkdir -p "$python_int_dir"
  : >"$python_int_log"

  python_int_ok=1
  python_int_i=1
  while [ "$python_int_i" -le 5 ]; do
    python_int_rc=0
    if timeout 60s python3 - >>"$python_int_log" 2>&1 <<'PY'
import traceback

def emit(name, value):
    try:
        text = str(value)
    except BaseException as exc:
        print("__PYTHON_INT_PREFLIGHT_%s_STR_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        print("__PYTHON_INT_PREFLIGHT_%s_TYPE__:%s" % (name, type(value).__name__))
        if isinstance(value, int):
            try:
                print("__PYTHON_INT_PREFLIGHT_%s_BIT_LENGTH__:%s" % (
                    name, value.bit_length()))
            except BaseException as bit_exc:
                print("__PYTHON_INT_PREFLIGHT_%s_BIT_LENGTH_ERROR__:%s:%s" % (
                    name, type(bit_exc).__name__, bit_exc))
        return
    print("__PYTHON_INT_PREFLIGHT_%s__:%s" % (name, text))

try:
    for text, expected in (("0", 0), ("2", 2), ("169", 169), ("254", 254), ("4294967295", 4294967295)):
        emit("TEXT_%s_REPR" % text, repr(text))
        emit("TEXT_%s_LEN" % text, len(text))
        emit("TEXT_%s_ORDS" % text, ",".join(str(ord(ch)) for ch in text))
        value = int(text, 10)
        emit("VALUE_%s" % text, value)
        emit("VALUE_%s_BIT_LENGTH" % text, value.bit_length())
        if value != expected:
            raise AssertionError("int(%r)=%r expected=%r" % (text, value, expected))

    octets = [169, 254, 0, 0]
    octet_bytes = bytes(octets)
    emit("OCTET_BYTES_HEX", octet_bytes.hex())
    for name, source in (
        ("BYTES", octet_bytes),
        ("LIST", octets),
        ("MAP", map(lambda octet: octet, octets)),
    ):
        value = int.from_bytes(source, "big")
        emit("INT_FROM_BYTES_%s" % name, value)
        emit("INT_FROM_BYTES_%s_BIT_LENGTH" % name, value.bit_length())
        if value != 2851995648:
            raise AssertionError("int.from_bytes(%s)=%r" % (name, value))
    print("__PYTHON_INT_PREFLIGHT_OK__")
except BaseException:
    traceback.print_exc()
    raise
PY
    then
      :
    else
      python_int_rc=$?
      python_int_ok=0
    fi
    echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:$preflight_tag:$python_int_i:$python_int_rc"
    python_int_i=$((python_int_i + 1))
  done

  echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__:$preflight_tag"
  sed -n '1,220p' "$python_int_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__:$preflight_tag"
  case "$preflight_tag" in
    before-runtime) python_int_marker=full-userland-python-int-preflight-before-runtime-loop ;;
    runtime-after-core-tools) python_int_marker=full-userland-python-int-preflight-runtime-after-core-tools-loop ;;
    runtime-after-identity) python_int_marker=full-userland-python-int-preflight-runtime-after-identity-loop ;;
    runtime-after-systemd-files) python_int_marker=full-userland-python-int-preflight-runtime-after-systemd-files-loop ;;
    runtime-after-journal) python_int_marker=full-userland-python-int-preflight-runtime-after-journal-loop ;;
    runtime-after-ssh) python_int_marker=full-userland-python-int-preflight-runtime-after-ssh-loop ;;
    runtime-after-daemons) python_int_marker=full-userland-python-int-preflight-runtime-after-daemons-loop ;;
    runtime-after-systemctl-pre-cleanup) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-pre-cleanup-loop ;;
    runtime-after-systemctl-daemon-reload-command) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-daemon-reload-command-loop ;;
    runtime-after-systemctl-daemon-reload-timeout) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-daemon-reload-timeout-loop ;;
    runtime-after-systemctl-daemon-reload-before-hup) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-daemon-reload-before-hup-loop ;;
    runtime-after-systemctl-daemon-reload-after-hup) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-daemon-reload-after-hup-loop ;;
    runtime-after-systemctl-daemon-reload) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-daemon-reload-loop ;;
    runtime-after-systemctl-root-enable) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-root-enable-loop ;;
    runtime-after-systemctl-root-is-enabled) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-root-is-enabled-loop ;;
    runtime-after-systemctl-runtime-start) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-runtime-start-loop ;;
    runtime-after-systemctl-root-disable) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-root-disable-loop ;;
    runtime-after-systemctl-cleanup) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-cleanup-loop ;;
    runtime-after-systemctl) python_int_marker=full-userland-python-int-preflight-runtime-after-systemctl-loop ;;
    after-runtime) python_int_marker=full-userland-python-int-preflight-after-runtime-loop ;;
    *) python_int_marker=full-userland-python-int-preflight-unknown-loop ;;
  esac
  if [ "$python_int_ok" = "1" ]; then
    pass "$python_int_marker"
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail "$python_int_marker"
  else
    echo "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_SOFT_FAIL__:$preflight_tag"
  fi
}

check_full_userland_python_cnf_diag() {
  if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" != "full" ]; then
    pass full-userland-python-cnf-diag-skip
    return
  fi

  python_cnf_dir=/tmp/nemu-full-userland-python-cnf
  python_cnf_log="$python_cnf_dir/python-cnf.log"
  python_stdlib_loop_log="$python_cnf_dir/python-stdlib-loop.log"
  lsb_release_loop_log="$python_cnf_dir/lsb-release-loop.log"
  cnf_update_log="$python_cnf_dir/cnf-update-db.log"
  rm -rf "$python_cnf_dir"
  mkdir -p "$python_cnf_dir"

  python_cnf_rc=0
  timeout 120s python3 - >"$python_cnf_log" 2>&1 <<'PY' || python_cnf_rc=$?
import sys

def emit(name, value):
    print("__PYTHON_CNF_DIAG_%s__:%s" % (name, value))

def run_expr(name, fn):
    try:
        emit(name, repr(fn()))
    except BaseException as exc:
        emit(name + "_ERROR", "%s:%s" % (type(exc).__name__, exc))

emit("VERSION", sys.version.split()[0])
run_expr("DIVMOD_NEG_US", lambda: divmod(-1, 1000000))
run_expr("ABS_MICROSECONDS_LT_FLOAT", lambda: abs(999999) < 3.1e6)
run_expr("ABS_NEG_ONE_LT_FLOAT", lambda: abs(-1) < 3.1e6)
run_expr("RE_REPEAT_COMPILE", lambda: __import__("re").compile(r"(?=-{2,}\w)").pattern)

try:
    import textwrap
    emit("TEXTWRAP_IMPORT", "ok")
    emit("TEXTWRAP_WORDSEP_LEN", len(textwrap.TextWrapper.wordsep_re.pattern))
except BaseException as exc:
    emit("TEXTWRAP_IMPORT_ERROR", "%s:%s" % (type(exc).__name__, exc))

try:
    import optparse
    emit("OPTPARSE_IMPORT", "ok")
except BaseException as exc:
    emit("OPTPARSE_IMPORT_ERROR", "%s:%s" % (type(exc).__name__, exc))

try:
    import datetime
    emit("DATETIME_IMPORT", "ok")
    run_expr(
        "DATETIME_MAXOFFSET",
        lambda: datetime.timedelta(hours=24, microseconds=-1),
    )
except BaseException as exc:
    emit("DATETIME_IMPORT_ERROR", "%s:%s" % (type(exc).__name__, exc))

try:
    import sqlite3
    emit("SQLITE3_IMPORT", "ok")
except BaseException as exc:
    emit("SQLITE3_IMPORT_ERROR", "%s:%s" % (type(exc).__name__, exc))

try:
    from CommandNotFound.db.creator import DbCreator  # noqa: F401
    emit("COMMAND_NOT_FOUND_CREATOR_IMPORT", "ok")
except BaseException as exc:
    emit(
        "COMMAND_NOT_FOUND_CREATOR_IMPORT_ERROR",
        "%s:%s" % (type(exc).__name__, exc),
    )
PY

  python_textwrap_sha_expected=e1541a31ac906294f915cadd0d780e1e5b256dc1897b560cdaf3fbf46d104cf0
  python_lsb_release_sha_expected=484b6a9de8b41aa9310a305b64c092e473ee73bead994e52c4271c66df9ba3c8
  python_textwrap_pyc=/usr/lib/python3.10/__pycache__/textwrap.cpython-310.pyc
  python_hash_ok=1
  python_hash_i=1
  while [ "$python_hash_i" -le 3 ]; do
    python_textwrap_sha="$(sha256sum /usr/lib/python3.10/textwrap.py 2>/dev/null | awk '{print $1}')"
    python_lsb_release_sha="$(sha256sum /usr/bin/lsb_release 2>/dev/null | awk '{print $1}')"
    python_textwrap_pyc_sha=missing
    if [ -e "$python_textwrap_pyc" ]; then
      python_textwrap_pyc_sha="$(sha256sum "$python_textwrap_pyc" 2>/dev/null | awk '{print $1}')"
    fi
    echo "__NEMU_CHECK_FULL_PYTHON_TEXTWRAP_SHA256__:$python_hash_i:$python_textwrap_sha"
    echo "__NEMU_CHECK_FULL_PYTHON_TEXTWRAP_PYC_SHA256__:$python_hash_i:$python_textwrap_pyc_sha"
    echo "__NEMU_CHECK_FULL_LSB_RELEASE_SHA256__:$python_hash_i:$python_lsb_release_sha"
    if [ "$python_textwrap_sha" != "$python_textwrap_sha_expected" ] ||
       [ "$python_lsb_release_sha" != "$python_lsb_release_sha_expected" ]; then
      python_hash_ok=0
    fi
    python_hash_i=$((python_hash_i + 1))
  done
  if [ "$python_hash_ok" = "1" ]; then
    pass full-userland-python-stdlib-file-sha256
  else
    fail full-userland-python-stdlib-file-sha256
  fi

  : >"$python_stdlib_loop_log"
  python_stdlib_loop_ok=1
  python_stdlib_loop_i=1
  while [ "$python_stdlib_loop_i" -le 3 ]; do
    python_stdlib_loop_rc=0
    timeout 120s python3 -c \
      'import re, textwrap, optparse; print("stdlib-import-ok", len(textwrap.TextWrapper.wordsep_re.pattern))' \
      >>"$python_stdlib_loop_log" 2>&1 || python_stdlib_loop_rc=$?
    echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_RC__:$python_stdlib_loop_i:$python_stdlib_loop_rc"
    if [ "$python_stdlib_loop_rc" != "0" ]; then
      python_stdlib_loop_ok=0
    fi
    python_stdlib_loop_i=$((python_stdlib_loop_i + 1))
  done
  echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_LOG_BEGIN__"
  sed -n '1,160p' "$python_stdlib_loop_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_LOG_END__"
  if [ "$python_stdlib_loop_ok" = "1" ]; then
    pass full-userland-python-stdlib-import-loop
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-python-stdlib-import-loop
  else
    echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_SOFT_FAIL__"
  fi

  : >"$lsb_release_loop_log"
  lsb_release_loop_ok=1
  lsb_release_loop_i=1
  while [ "$lsb_release_loop_i" -le 3 ]; do
    lsb_release_loop_rc=0
    timeout 120s lsb_release -a >>"$lsb_release_loop_log" 2>&1 || lsb_release_loop_rc=$?
    echo "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_RC__:$lsb_release_loop_i:$lsb_release_loop_rc"
    if [ "$lsb_release_loop_rc" != "0" ]; then
      lsb_release_loop_ok=0
    fi
    lsb_release_loop_i=$((lsb_release_loop_i + 1))
  done
  echo "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_BEGIN__"
  sed -n '1,160p' "$lsb_release_loop_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_END__"
  if [ "$lsb_release_loop_ok" = "1" ]; then
    pass full-userland-lsb-release-retry-loop
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-lsb-release-retry-loop
  else
    echo "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_SOFT_FAIL__"
  fi

  lsb_release_pycacheprefix_log="$python_cnf_dir/lsb-release-pycacheprefix-loop.log"
  rm -rf /tmp/nemu-python-pycacheprefix
  mkdir -p /tmp/nemu-python-pycacheprefix
  : >"$lsb_release_pycacheprefix_log"
  lsb_release_pycacheprefix_ok=1
  lsb_release_pycacheprefix_i=1
  while [ "$lsb_release_pycacheprefix_i" -le 3 ]; do
    lsb_release_pycacheprefix_rc=0
    PYTHONPYCACHEPREFIX=/tmp/nemu-python-pycacheprefix \
      timeout 120s lsb_release -a >>"$lsb_release_pycacheprefix_log" 2>&1 ||
      lsb_release_pycacheprefix_rc=$?
    echo "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_RC__:$lsb_release_pycacheprefix_i:$lsb_release_pycacheprefix_rc"
    if [ "$lsb_release_pycacheprefix_rc" != "0" ]; then
      lsb_release_pycacheprefix_ok=0
    fi
    lsb_release_pycacheprefix_i=$((lsb_release_pycacheprefix_i + 1))
  done
  echo "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_LOG_BEGIN__"
  sed -n '1,160p' "$lsb_release_pycacheprefix_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_LOG_END__"
  if [ "$lsb_release_pycacheprefix_ok" = "1" ]; then
    pass full-userland-lsb-release-pycacheprefix-loop
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-lsb-release-pycacheprefix-loop
  else
    echo "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_SOFT_FAIL__"
  fi

  python_re_source_diag_log="$python_cnf_dir/python-re-source-exec.log"
  python_re_source_diag_loops="${NEMU_GUEST_PYTHON_RE_DIAG_LOOPS:-20}"
  : >"$python_re_source_diag_log"
  python_re_source_diag_i=1
  while [ "$python_re_source_diag_i" -le "$python_re_source_diag_loops" ]; do
    python_re_source_diag_rc=0
if timeout 120s python3 - >>"$python_re_source_diag_log" 2>&1 <<'PY'
import hashlib
import traceback

def emit(name, value):
    try:
        text = str(value)
    except BaseException as exc:
        print("__PYTHON_RE_SOURCE_DIAG_%s_STR_ERROR__:%s:%s" % (
            name, type(exc).__name__, exc))
        print("__PYTHON_RE_SOURCE_DIAG_%s_TYPE__:%s" % (name, type(value).__name__))
        if isinstance(value, int):
            try:
                print("__PYTHON_RE_SOURCE_DIAG_%s_BIT_LENGTH__:%s" % (
                    name, value.bit_length()))
            except BaseException as bit_exc:
                print("__PYTHON_RE_SOURCE_DIAG_%s_BIT_LENGTH_ERROR__:%s:%s" % (
                    name, type(bit_exc).__name__, bit_exc))
        return
    print("__PYTHON_RE_SOURCE_DIAG_%s__:%s" % (name, text))

def emit_exc(name, exc):
    emit(name, "%s:%s" % (type(exc).__name__, exc))

def read_bytes_for_diag(path):
    try:
        with open(path, "rb") as fp:
            return fp.read()
    except BaseException as exc:
        emit_exc("%s_READ_ERROR" % (path.rsplit("/", 1)[-1].upper().replace(".", "_")), exc)
        traceback.print_exc()
        return None

try:
    parts = "169.254.0.0".split(".")
    emit("IPADDRESS_LOCAL_SPLIT", ",".join(parts))
    octets = []
    for index, part in enumerate(parts):
        emit("IPADDRESS_LOCAL_OCTET_TEXT_%d" % index, repr(part))
        emit("IPADDRESS_LOCAL_OCTET_LEN_%d" % index, len(part))
        emit("IPADDRESS_LOCAL_OCTET_ORDS_%d" % index, ",".join(str(ord(ch)) for ch in part))
        octet = int(part, 10)
        emit("IPADDRESS_LOCAL_OCTET_VALUE_%d" % index, octet)
        if octet > 255:
            raise ValueError("local octet %d (> 255) not permitted" % octet)
        octets.append(octet)
    emit("IPADDRESS_LOCAL_OCTETS", ",".join(str(octet) for octet in octets))
    local_bytes = bytes(octets)
    emit("IPADDRESS_LOCAL_BYTES_HEX", local_bytes.hex())
    emit("IPADDRESS_LOCAL_INT_FROM_BYTES_BYTES", int.from_bytes(local_bytes, "big"))
    emit("IPADDRESS_LOCAL_INT_FROM_BYTES_LIST", int.from_bytes(octets, "big"))
    emit("IPADDRESS_LOCAL_INT_FROM_BYTES_MAP", int.from_bytes(map(lambda octet: octet, octets), "big"))
except BaseException as exc:
    emit_exc("IPADDRESS_LOCAL_ERROR", exc)
    traceback.print_exc()

ipaddress_path = "/usr/lib/python3.10/ipaddress.py"
ipaddress_src = read_bytes_for_diag(ipaddress_path)
if ipaddress_src is not None:
    emit("IPADDRESS_BYTES", len(ipaddress_src))
    emit("IPADDRESS_SHA256", hashlib.sha256(ipaddress_src).hexdigest())
    idx_ip = ipaddress_src.find(b"int.from_bytes(map(cls._parse_octet")
    emit("IPADDRESS_INT_FROM_BYTES_TOKEN_OFFSET", idx_ip)
    if idx_ip >= 0:
        start_ip = max(0, idx_ip - 40)
        end_ip = min(len(ipaddress_src), idx_ip + 80)
        emit("IPADDRESS_INT_FROM_BYTES_WINDOW_HEX", ipaddress_src[start_ip:end_ip].hex())

try:
    import ipaddress
    emit("IPADDRESS_IMPORT", "ok")
    network = ipaddress.IPv4Network("169.254.0.0/16")
    emit("IPADDRESS_LINKLOCAL_NETWORK", str(network))
    emit("IPADDRESS_LINKLOCAL_NETWORK_INT", int(network.network_address))
except BaseException as exc:
    emit_exc("IPADDRESS_IMPORT_ERROR", exc)
    traceback.print_exc()

path = "/usr/lib/python3.10/textwrap.py"
src = read_bytes_for_diag(path)
if src is not None:
    emit("TEXTWRAP_BYTES", len(src))
    emit("TEXTWRAP_SHA256", hashlib.sha256(src).hexdigest())
    idx = src.find(b"{2,}")
    emit("TEXTWRAP_REPEAT_TOKEN_OFFSET", idx)
    if idx >= 0:
        start = max(0, idx - 40)
        end = min(len(src), idx + 40)
        emit("TEXTWRAP_REPEAT_TOKEN_WINDOW_HEX", src[start:end].hex())

try:
    import _sre
    import sre_constants
    import sre_parse
    emit("_SRE_MAXREPEAT", repr(_sre.MAXREPEAT))
    emit("SRE_CONSTANTS_MAXREPEAT", repr(sre_constants.MAXREPEAT))
    emit("SRE_PARSE_MAXREPEAT", repr(sre_parse.MAXREPEAT))
    emit("SRE_PARSE_MAXREPEAT_INT", int(sre_parse.MAXREPEAT))
except BaseException as exc:
    emit("SRE_MAXREPEAT_ERROR", "%s:%s" % (type(exc).__name__, exc))
    traceback.print_exc()

try:
    if src is None:
        raise RuntimeError("textwrap source unavailable")
    code = compile(src, path, "exec")
    ns = {"__name__": "__nemu_textwrap_source_diag__"}
    exec(code, ns)
    wrapper = ns["TextWrapper"]
    pattern = wrapper.wordsep_re.pattern
    emit("TEXTWRAP_SOURCE_EXEC", "ok")
    emit("TEXTWRAP_PATTERN_LEN", len(pattern))
    emit("TEXTWRAP_PATTERN_SHA256", hashlib.sha256(pattern.encode()).hexdigest())
except BaseException as exc:
    emit("TEXTWRAP_SOURCE_EXEC_ERROR", "%s:%s" % (type(exc).__name__, exc))
    traceback.print_exc()
PY
    then
      :
    else
      python_re_source_diag_rc=$?
    fi
    echo "__NEMU_CHECK_FULL_PYTHON_RE_SOURCE_EXEC_RC__:$python_re_source_diag_i:$python_re_source_diag_rc"
    python_re_source_diag_i=$((python_re_source_diag_i + 1))
  done
  echo "__NEMU_CHECK_FULL_PYTHON_RE_SOURCE_EXEC_LOG_BEGIN__"
  sed -n '1,260p' "$python_re_source_diag_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_PYTHON_RE_SOURCE_EXEC_LOG_END__"
  pass full-userland-python-re-source-exec-recorded

  python_stdlib_stress_log="$python_cnf_dir/python-stdlib-stress.log"
  : >"$python_stdlib_stress_log"
  python_stdlib_stress_ok=1
  python_stdlib_stress_i=1
  while [ "$python_stdlib_stress_i" -le 5 ]; do
    python_stdlib_stress_rc=0
    if timeout 120s python3 - >>"$python_stdlib_stress_log" 2>&1 <<'PY'
import _sre
import datetime
import re
import textwrap

print("__PYTHON_STDLIB_STRESS_MAXREPEAT__:%s" % (_sre.MAXREPEAT,))
assert _sre.MAXREPEAT >= 4294967295
assert datetime.timedelta(-999999999).days == -999999999
assert re.compile(r"(?=-{2,}\w)").pattern == r"(?=-{2,}\w)"
assert re.compile(textwrap.TextWrapper.wordsep_re.pattern, re.VERBOSE).pattern
print("__PYTHON_STDLIB_STRESS_OK__")
PY
    then
      :
    else
      python_stdlib_stress_rc=$?
    fi
    echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_RC__:$python_stdlib_stress_i:$python_stdlib_stress_rc"
    if [ "$python_stdlib_stress_rc" != "0" ]; then
      python_stdlib_stress_ok=0
    fi
    python_stdlib_stress_i=$((python_stdlib_stress_i + 1))
  done
  echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_BEGIN__"
  sed -n '1,220p' "$python_stdlib_stress_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_END__"
  if [ "$python_stdlib_stress_ok" = "1" ]; then
    pass full-userland-python-stdlib-stress-loop
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-python-stdlib-stress-loop
  else
    echo "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_SOFT_FAIL__"
  fi

  cnf_update_rc=127
  if [ -x /usr/lib/cnf-update-db ]; then
    cnf_update_rc=0
    timeout 180s /usr/lib/cnf-update-db >"$cnf_update_log" 2>&1 || cnf_update_rc=$?
  else
    echo "/usr/lib/cnf-update-db is not executable" >"$cnf_update_log"
  fi

  echo "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__:$python_cnf_rc"
  echo "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__"
  sed -n '1,160p' "$python_cnf_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_END__"
  echo "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__:$cnf_update_rc"
  echo "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__"
  sed -n '1,160p' "$cnf_update_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__"

  if [ "$python_cnf_rc" = "0" ] &&
     grep -Fq "__PYTHON_CNF_DIAG_DATETIME_IMPORT__:ok" "$python_cnf_log" &&
     grep -Fq "__PYTHON_CNF_DIAG_SQLITE3_IMPORT__:ok" "$python_cnf_log"; then
    pass full-userland-python-datetime-sqlite3
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-python-datetime-sqlite3
  else
    echo "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_SOFT_FAIL__:datetime-sqlite3"
  fi

  if [ "$cnf_update_rc" = "0" ]; then
    pass full-userland-command-not-found-update-db
  elif [ "${NEMU_GUEST_PYTHON_CNF_DIAG_HARD:-0}" = "1" ]; then
    fail full-userland-command-not-found-update-db
  else
    echo "__NEMU_CHECK_FULL_CNF_UPDATE_DB_SOFT_FAIL__:$cnf_update_rc"
  fi
  pass full-userland-python-cnf-diag-recorded
}

check_full_userland_network_clients() {
  if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" != "full" ]; then
    pass full-userland-network-clients-skip
    return
  fi
  if [ "${NEMU_GUEST_NET_BACKEND:-hostless}" != "hostless" ]; then
    echo "__NEMU_CHECK_FULL_NETWORK_CLIENTS_HOSTLESS_SKIP__:${NEMU_GUEST_NET_BACKEND:-hostless}"
    pass full-userland-network-clients-hostless-skip
    return
  fi

  # 这里验证 full rootfs 自带的真实网络客户端；DNS 指向 NEMU hostless responder，
  # 证明的是当前 hostless virtio-net 用户态访问能力，不是 TAP/NAT/外网能力。
  full_net_url=http://nemu.local/nemu-health
  printf 'nameserver 10.0.2.2\noptions timeout:2 attempts:1\n' > /etc/resolv.conf
  echo "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__"
  sed -n '1,20p' /etc/resolv.conf 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_RESOLV_CONF_END__"
  pass full-userland-resolv-hostless

  curl_body=/tmp/nemu-full-userland-curl.body
  curl_err=/tmp/nemu-full-userland-curl.err
  curl_rc=0
  curl_code="$(
    timeout 120s curl -4 -fsS \
      --connect-timeout 30 \
      --max-time 120 \
      -o "$curl_body" \
      -w '%{http_code}' \
      "$full_net_url" 2>"$curl_err"
  )" || curl_rc=$?
  echo "__NEMU_CHECK_FULL_CURL_HTTP_CODE__:$curl_rc:$curl_code"
  if [ "$curl_rc" = "0" ] && [ "$curl_code" = "204" ]; then
    pass full-userland-curl-http
  else
    echo "__NEMU_CHECK_FULL_CURL_ERROR_BEGIN__"
    sed -n '1,80p' "$curl_err" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_CURL_ERROR_END__"
    fail full-userland-curl-http
  fi

  wget_body=/tmp/nemu-full-userland-wget.body
  wget_log=/tmp/nemu-full-userland-wget.log
  wget_rc=0
  timeout 120s wget \
    --inet4-only \
    --server-response \
    --tries=1 \
    --timeout=120 \
    --output-document="$wget_body" \
    --output-file="$wget_log" \
    "$full_net_url" >/dev/null 2>&1 || wget_rc=$?
  wget_code="$(sed -n 's/.*HTTP\/1\.[01] \([0-9][0-9][0-9]\).*/\1/p' "$wget_log" | tail -1)"
  echo "__NEMU_CHECK_FULL_WGET_HTTP_CODE__:$wget_rc:$wget_code"
  if [ "$wget_code" = "204" ]; then
    pass full-userland-wget-http
  else
    echo "__NEMU_CHECK_FULL_WGET_LOG_BEGIN__"
    sed -n '1,120p' "$wget_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_WGET_LOG_END__"
    fail full-userland-wget-http
  fi

  curl_head_headers=/tmp/nemu-full-userland-curl-head.headers
  curl_head_err=/tmp/nemu-full-userland-curl-head.err
  curl_head_rc=0
  curl_head_code="$(
    timeout 120s curl -4 -fsS \
      --head \
      --connect-timeout 30 \
      --max-time 120 \
      --dump-header "$curl_head_headers" \
      -o /tmp/nemu-full-userland-curl-head.body \
      -w '%{http_code}' \
      "$full_net_url" 2>"$curl_head_err"
  )" || curl_head_rc=$?
  echo "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__:$curl_head_rc:$curl_head_code"
  if [ "$curl_head_rc" = "0" ] && [ "$curl_head_code" = "204" ] &&
     grep -qi '^Content-Length: 0' "$curl_head_headers"; then
    pass full-userland-curl-head-http
  else
    echo "__NEMU_CHECK_FULL_CURL_HEAD_ERROR_BEGIN__"
    sed -n '1,80p' "$curl_head_err" 2>/dev/null || true
    sed -n '1,80p' "$curl_head_headers" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_CURL_HEAD_ERROR_END__"
    fail full-userland-curl-head-http
  fi

  curl_404_body=/tmp/nemu-full-userland-curl-404.body
  curl_404_err=/tmp/nemu-full-userland-curl-404.err
  curl_404_rc=0
  curl_404_code="$(
    timeout 120s curl -4 -fsS \
      --connect-timeout 30 \
      --max-time 120 \
      -o "$curl_404_body" \
      -w '%{http_code}' \
      http://nemu.local/nemu-missing 2>"$curl_404_err"
  )" || curl_404_rc=$?
  echo "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__:$curl_404_rc:$curl_404_code"
  if [ "$curl_404_rc" = "22" ] && [ "$curl_404_code" = "404" ]; then
    pass full-userland-curl-404-http
  else
    echo "__NEMU_CHECK_FULL_CURL_404_ERROR_BEGIN__"
    sed -n '1,80p' "$curl_404_err" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_CURL_404_ERROR_END__"
    fail full-userland-curl-404-http
  fi

  curl_large_body=/tmp/nemu-full-userland-curl-large.body
  curl_large_err=/tmp/nemu-full-userland-curl-large.err
  curl_large_rc=0
  curl_large_bytes=0
  curl_large_sha256=
  timeout 180s curl -4 -fsS \
    --connect-timeout 30 \
    --max-time 180 \
    -o "$curl_large_body" \
    http://nemu.local/nemu-large 2>"$curl_large_err" || curl_large_rc=$?
  if [ -f "$curl_large_body" ]; then
    curl_large_bytes="$(wc -c < "$curl_large_body" 2>/dev/null | tr -d ' ')"
    curl_large_sha256="$(sha256sum "$curl_large_body" 2>/dev/null | awk '{print $1}')"
  fi
  echo "__NEMU_CHECK_FULL_CURL_LARGE_RC__:$curl_large_rc"
  echo "__NEMU_CHECK_FULL_CURL_LARGE_BYTES__:$curl_large_bytes"
  echo "__NEMU_CHECK_FULL_CURL_LARGE_SHA256__:$curl_large_sha256"
  if [ "$curl_large_rc" = "0" ] &&
     [ "$curl_large_bytes" = "4096" ] &&
     [ "$curl_large_sha256" = "8b186a8da3ad0c154cd7b0f2b57fd7c3ca7d4dc767ec45d27bcb155739be90b8" ]; then
    pass full-userland-curl-large-http
  else
    echo "__NEMU_CHECK_FULL_CURL_LARGE_ERROR_BEGIN__"
    sed -n '1,80p' "$curl_large_err" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_CURL_LARGE_ERROR_END__"
    fail full-userland-curl-large-http
  fi

  apt_hostless_root=/tmp/nemu-full-userland-apt-hostless
  apt_hostless_source="$apt_hostless_root/sources.list"
  apt_hostless_source_line=
  apt_hostless_clear_conf=/etc/apt/apt.conf.d/99nemu-hostless-clear-hooks
  apt_hostless_keyring="$apt_hostless_root/nemu-hostless-archive-keyring.gpg"
  apt_hostless_keyring_log="$apt_hostless_root/keyring.log"
  apt_hostless_inrelease="$apt_hostless_root/InRelease"
  apt_hostless_inrelease_log="$apt_hostless_root/inrelease.log"
  apt_hostless_gpgv_log="$apt_hostless_root/gpgv.log"
  apt_hostless_log="$apt_hostless_root/update.log"
  rm -rf "$apt_hostless_root"
  mkdir -p "$apt_hostless_root/lists/partial" "$apt_hostless_root/cache/archives/partial"
  mkdir -p /etc/apt/apt.conf.d
  cat >"$apt_hostless_clear_conf" <<'EOF'
#clear APT::Update::Post-Invoke-Success;
#clear DPkg::Post-Invoke;
APT::Update::Post-Invoke-Success "";
DPkg::Post-Invoke "";
EOF
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__:$apt_hostless_clear_conf"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_BEGIN__"
  sed -n '1,20p' "$apt_hostless_clear_conf" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_END__"
  apt_hostless_keyring_rc=0
  timeout 120s curl -4 -fsS \
    --connect-timeout 30 \
    --max-time 120 \
    -o "$apt_hostless_keyring" \
    http://nemu.local/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg \
    >"$apt_hostless_keyring_log" 2>&1 || apt_hostless_keyring_rc=$?
  chmod 0644 "$apt_hostless_keyring" 2>/dev/null || true
  apt_hostless_keyring_sha256=
  if [ -f "$apt_hostless_keyring" ]; then
    apt_hostless_keyring_sha256="$(sha256sum "$apt_hostless_keyring" | awk '{print $1}')"
  fi
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_RC__:$apt_hostless_keyring_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_SHA256__:$apt_hostless_keyring_sha256"
  if [ "$apt_hostless_keyring_rc" = "0" ] &&
     [ "$apt_hostless_keyring_sha256" = "e99cff1585af5ae2587b50efeffd562cac5d3fb383145a4c79b8046f38159045" ]; then
    pass full-userland-apt-hostless-keyring
  else
    echo "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_LOG_BEGIN__"
    sed -n '1,80p' "$apt_hostless_keyring_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_LOG_END__"
    fail full-userland-apt-hostless-keyring
  fi
  apt_hostless_inrelease_rc=0
  timeout 120s curl -4 -fsS \
    --connect-timeout 30 \
    --max-time 120 \
    -o "$apt_hostless_inrelease" \
    http://nemu.local/ubuntu/dists/jammy/InRelease \
    >"$apt_hostless_inrelease_log" 2>&1 || apt_hostless_inrelease_rc=$?
  apt_hostless_inrelease_sha256=
  if [ -f "$apt_hostless_inrelease" ]; then
    apt_hostless_inrelease_sha256="$(sha256sum "$apt_hostless_inrelease" | awk '{print $1}')"
  fi
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__:$apt_hostless_inrelease_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__:$apt_hostless_inrelease_sha256"
  apt_hostless_gpgv_rc=0
  gpgv --keyring "$apt_hostless_keyring" "$apt_hostless_inrelease" \
    >"$apt_hostless_gpgv_log" 2>&1 || apt_hostless_gpgv_rc=$?
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__:$apt_hostless_gpgv_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_BEGIN__"
  sed -n '1,80p' "$apt_hostless_gpgv_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_END__"
  if [ "$apt_hostless_inrelease_rc" = "0" ] &&
     [ "$apt_hostless_inrelease_sha256" = "8b1d4ef06eaea91ce7e2cbc2a22d8b3feeadb5ab539dc79067f8e26a3729b363" ] &&
     [ "$apt_hostless_gpgv_rc" = "0" ]; then
    pass full-userland-apt-hostless-inrelease-gpgv
  else
    echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_LOG_BEGIN__"
    sed -n '1,80p' "$apt_hostless_inrelease_log" 2>/dev/null || true
    echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_LOG_END__"
    fail full-userland-apt-hostless-inrelease-gpgv
  fi
  apt_hostless_source_line="deb [signed-by=$apt_hostless_keyring arch=riscv64] http://nemu.local/ubuntu jammy main"
  printf '%s\n' "$apt_hostless_source_line" > "$apt_hostless_source"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_SOURCE__:$apt_hostless_source_line"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__:Dir::Etc::parts=-"
  apt_hostless_rc=0
  timeout 240s apt-get update \
    -o "Dir::Etc::sourcelist=$apt_hostless_source" \
    -o "Dir::Etc::sourceparts=-" \
    -o "Dir::Etc::parts=-" \
    -o "Dir::State::lists=$apt_hostless_root/lists" \
    -o "Dir::Cache::archives=$apt_hostless_root/cache/archives" \
    -o "APT::Architecture=riscv64" \
    -o "Acquire::Languages=none" \
    -o "Acquire::Retries=0" \
    -o "Acquire::http::Timeout=60" \
    -o "APT::Get::List-Cleanup=0" \
    >"$apt_hostless_log" 2>&1 || apt_hostless_rc=$?
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__:$apt_hostless_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__"
  sed -n '1,120p' "$apt_hostless_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__"
  if [ "$apt_hostless_rc" = "0" ] &&
     grep -q 'http://nemu.local/ubuntu jammy InRelease' "$apt_hostless_log" &&
     grep -q 'Reading package lists' "$apt_hostless_log"; then
    pass full-userland-apt-hostless-update
    pass full-userland-apt-hostless-signed-update
  else
    fail full-userland-apt-hostless-update
    fail full-userland-apt-hostless-signed-update
  fi

  apt_hostless_unsigned_root="$apt_hostless_root/unsigned-no-key"
  apt_hostless_unsigned_source="$apt_hostless_unsigned_root/sources.list"
  apt_hostless_unsigned_log="$apt_hostless_unsigned_root/update.log"
  apt_hostless_unsigned_empty_trusted="$apt_hostless_unsigned_root/empty-trusted.gpg"
  rm -rf "$apt_hostless_unsigned_root"
  mkdir -p \
    "$apt_hostless_unsigned_root/lists/partial" \
    "$apt_hostless_unsigned_root/cache/archives/partial"
  : >"$apt_hostless_unsigned_empty_trusted"
  apt_hostless_unsigned_source_line="deb [arch=riscv64] http://nemu.local/ubuntu jammy main"
  printf '%s\n' "$apt_hostless_unsigned_source_line" >"$apt_hostless_unsigned_source"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_SOURCE__:$apt_hostless_unsigned_source_line"
  apt_hostless_unsigned_rc=0
  timeout 240s apt-get update \
    -o "Dir::Etc::sourcelist=$apt_hostless_unsigned_source" \
    -o "Dir::Etc::sourceparts=-" \
    -o "Dir::Etc::parts=-" \
    -o "Dir::Etc::trusted=$apt_hostless_unsigned_empty_trusted" \
    -o "Dir::Etc::trustedparts=-" \
    -o "Dir::State::lists=$apt_hostless_unsigned_root/lists" \
    -o "Dir::Cache::archives=$apt_hostless_unsigned_root/cache/archives" \
    -o "APT::Architecture=riscv64" \
    -o "Acquire::Languages=none" \
    -o "Acquire::Retries=0" \
    -o "Acquire::http::Timeout=60" \
    -o "APT::Get::List-Cleanup=0" \
    >"$apt_hostless_unsigned_log" 2>&1 || apt_hostless_unsigned_rc=$?
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_UPDATE_RC__:$apt_hostless_unsigned_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_UPDATE_LOG_BEGIN__"
  sed -n '1,120p' "$apt_hostless_unsigned_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_UPDATE_LOG_END__"
  if [ "$apt_hostless_unsigned_rc" != "0" ] &&
     grep -Eq 'NO_PUBKEY|public key is not available|repository .* is not signed|signatures.*verified' \
       "$apt_hostless_unsigned_log"; then
    pass full-userland-apt-hostless-unsigned-reject
  else
    fail full-userland-apt-hostless-unsigned-reject
  fi

  if [ "$apt_hostless_rc" = "0" ]; then
    check_full_userland_apt_install_diag "$apt_hostless_root" "$apt_hostless_source"
  fi

  apt_hostless_install_log="$apt_hostless_root/install.log"
  apt_hostless_download_log="$apt_hostless_root/download.log"
  apt_hostless_dpkg_log="$apt_hostless_root/dpkg-install.log"
  apt_hostless_download_dir="$apt_hostless_root/download"
  apt_hostless_download_status="$apt_hostless_root/download-status-empty"
  apt_hostless_deb="$apt_hostless_download_dir/nemu-hostless-hello_1.0_riscv64.deb"
  apt_hostless_deb_sha256=
  apt_hostless_download_rc=0
  apt_hostless_dpkg_rc=0
  apt_hostless_install_rc=0
  if [ "$apt_hostless_rc" = "0" ]; then
    mkdir -p "$apt_hostless_download_dir"
    : > "$apt_hostless_download_status"
    (
      cd "$apt_hostless_download_dir" &&
      timeout 240s apt-get download nemu-hostless-hello:riscv64=1.0 \
        -o "Dir::Etc::sourcelist=$apt_hostless_source" \
        -o "Dir::Etc::sourceparts=-" \
        -o "Dir::Etc::parts=-" \
        -o "Dir::State::lists=$apt_hostless_root/lists" \
        -o "Dir::State::status=$apt_hostless_download_status" \
        -o "Dir::Cache::archives=$apt_hostless_root/cache/archives" \
        -o "APT::Architecture=riscv64" \
        -o "Acquire::Languages=none" \
        -o "Acquire::Retries=0" \
        -o "Acquire::http::Timeout=60" \
        -o "APT::Get::List-Cleanup=0"
    ) >"$apt_hostless_download_log" 2>&1 || apt_hostless_download_rc=$?
    if [ -f "$apt_hostless_deb" ]; then
      apt_hostless_deb_sha256="$(sha256sum "$apt_hostless_deb" | awk '{print $1}')"
    fi
    if [ "$apt_hostless_download_rc" = "0" ] &&
       [ "$apt_hostless_deb_sha256" = "49f963a8d5e812279f07b29e9e6df366ccabd08c4c3402f6a89724f20811cbe7" ]; then
      DEBIAN_FRONTEND=noninteractive timeout 240s dpkg -i "$apt_hostless_deb" \
        >"$apt_hostless_dpkg_log" 2>&1 || apt_hostless_dpkg_rc=$?
    else
      apt_hostless_dpkg_rc=125
      echo "skip dpkg install because download rc=$apt_hostless_download_rc sha256=$apt_hostless_deb_sha256" \
        >"$apt_hostless_dpkg_log"
    fi
    cat "$apt_hostless_download_log" "$apt_hostless_dpkg_log" >"$apt_hostless_install_log"
    if [ "$apt_hostless_download_rc" != "0" ] || [ "$apt_hostless_dpkg_rc" != "0" ]; then
      apt_hostless_install_rc=1
    fi
  else
    apt_hostless_install_rc=125
    apt_hostless_download_rc=125
    apt_hostless_dpkg_rc=125
    echo "skip install because apt-get update rc=$apt_hostless_rc" \
      >"$apt_hostless_install_log"
    cp "$apt_hostless_install_log" "$apt_hostless_download_log"
    cp "$apt_hostless_install_log" "$apt_hostless_dpkg_log"
  fi
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__:$apt_hostless_download_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__:$apt_hostless_deb_sha256"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__:$apt_hostless_dpkg_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__:$apt_hostless_install_rc"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__"
  sed -n '1,160p' "$apt_hostless_install_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_END__"
  apt_hostless_message=/usr/share/nemu-hostless-hello/message
  apt_hostless_message_value="$(cat "$apt_hostless_message" 2>/dev/null || true)"
  apt_hostless_dpkg_status="$(dpkg-query -W -f='${Status} ${Version} ${Architecture}' nemu-hostless-hello 2>/dev/null || true)"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__:$apt_hostless_message_value"
  echo "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__:$apt_hostless_dpkg_status"
  if [ "$apt_hostless_install_rc" = "0" ] &&
     [ "$apt_hostless_message_value" = "hello from NEMU hostless apt" ] &&
     [ "$apt_hostless_dpkg_status" = "install ok installed 1.0 riscv64" ]; then
    pass full-userland-apt-hostless-install
  else
    fail full-userland-apt-hostless-install
  fi
  rm -f "$apt_hostless_clear_conf"
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
  reload_output=""
  reload_rc=0

  # NEMU 下同步 daemon-reload reply 可能很慢；reload 请求本身用短 D-Bus
  # 尝试 + PID1 HUP 兜底，真正“PID1 已看到 unit”的证明交给后续 start/output。
  reload_output="$(timeout 5s env SYSTEMD_BUS_TIMEOUT=5s systemctl daemon-reload 2>&1)" ||
    reload_rc=$?
  echo "__NEMU_CHECK_SYSTEMD_RELOAD_RC__:$reload_unit:$reload_goal:$reload_rc"
  check_full_userland_python_int_preflight runtime-after-systemctl-daemon-reload-command
  if [ "$reload_rc" -ne 0 ]; then
    case "$reload_rc:$reload_output" in
      124:*|*'Connection timed out'*|*'Timed out'*|*'timed out'*)
        echo "__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__:$reload_unit:$reload_goal"
        check_full_userland_python_int_preflight runtime-after-systemctl-daemon-reload-timeout
        ;;
      *)
        echo "__NEMU_CHECK_SYSTEMD_RELOAD_ERROR__:$reload_unit:$reload_goal:$reload_rc"
        if [ -n "$reload_output" ]; then
          printf '%s\n' "$reload_output" |
            while IFS= read -r reload_line; do
              echo "__NEMU_CHECK_SYSTEMD_RELOAD_ERROR_OUTPUT__:$reload_line"
            done
        fi
        return 1
        ;;
    esac
    check_full_userland_python_int_preflight runtime-after-systemctl-daemon-reload-before-hup
    if kill -HUP 1; then
      echo "__NEMU_CHECK_SYSTEMD_RELOAD_HUP_RC__:$reload_unit:$reload_goal:0"
    else
      reload_hup_rc=$?
      echo "__NEMU_CHECK_SYSTEMD_RELOAD_HUP_RC__:$reload_unit:$reload_goal:$reload_hup_rc"
      return 1
    fi
    check_full_userland_python_int_preflight runtime-after-systemctl-daemon-reload-after-hup
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

stale_failed_session_scopes="$(
  systemctl --no-pager --plain list-units --failed --type=scope --state=failed 2>/dev/null |
    awk '$1 ~ /^session-[^[:space:]]+\.scope$/ {print $1}' |
    tr '\n' ' '
)"
stale_failed_session_reset_rc=0
if [ -n "$stale_failed_session_scopes" ]; then
  systemctl reset-failed $stale_failed_session_scopes >/dev/null 2>&1 ||
    stale_failed_session_reset_rc=$?
fi
echo "__NEMU_CHECK_SYSTEMD_STALE_FAILED_SESSION_SCOPES__:$stale_failed_session_scopes"
echo "__NEMU_CHECK_SYSTEMD_STALE_FAILED_SESSION_RESET_RC__:$stale_failed_session_reset_rc"

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

echo "__NEMU_CHECK_LSB_RELEASE__"
if command -v lsb_release >/dev/null 2>&1; then
  pass lsb-release-present
  lsb_release_output="$(lsb_release -a 2>&1 || true)"
  printf '%s\n' "$lsb_release_output"
  echo "$lsb_release_output" | grep -q "Ubuntu 22.04" &&
    pass lsb-release-ubuntu2204 || fail lsb-release-ubuntu2204
else
  fail lsb-release-present
  fail lsb-release-ubuntu2204
fi

echo "__NEMU_CHECK_COMMON_COMMANDS__"
if command -v free >/dev/null 2>&1; then
  pass common-free-present
  free_output="$(free -m 2>/dev/null || true)"
  printf '%s\n' "$free_output"
  echo "$free_output" | grep -q '^Mem:' &&
    pass common-free-mem || fail common-free-mem
else
  fail common-free-present
  fail common-free-mem
fi

if command -v top >/dev/null 2>&1; then
  pass common-top-present
  top_version="$(top -v 2>&1 | sed -n '1p' || true)"
  echo "__NEMU_CHECK_TOP_VERSION__:$top_version"
  echo "$top_version" | grep -Eiq '(top|procps)' &&
    pass common-top-version || fail common-top-version
  top_output="$(timeout 10s env TERM=dumb top -b -n1 2>&1 | sed -n '1,5p' || true)"
  if echo "$top_output" | grep -Eq '^(top|Tasks:|MiB Mem|KiB Mem)'; then
    printf '%s\n' "$top_output"
    pass common-top-batch-optional
  else
    echo "__NEMU_CHECK_TOP_BATCH_OPTIONAL__:top-batch-no-output"
    [ -n "$top_output" ] && printf '%s\n' "$top_output"
    pass common-top-batch-optional
  fi
else
  fail common-top-present
  fail common-top-version
fi

if command -v hostnamectl >/dev/null 2>&1; then
  pass common-hostnamectl-present
  hostnamectl_version="$(hostnamectl --version 2>/dev/null | head -n 1 || true)"
  echo "__NEMU_CHECK_HOSTNAMECTL_VERSION__:$hostnamectl_version"
  echo "$hostnamectl_version" | grep -Eq '^systemd [0-9]+' &&
    pass common-hostnamectl-version || fail common-hostnamectl-version
else
  fail common-hostnamectl-present
  fail common-hostnamectl-version
fi

if command -v htop >/dev/null 2>&1; then
  htop_version="$(htop --version 2>/dev/null | head -n 1 || true)"
  echo "__NEMU_CHECK_HTOP_OPTIONAL__:$htop_version"
  pass common-htop-optional-present
  pass common-htop-optional
else
  echo "__NEMU_CHECK_HTOP_OPTIONAL__:htop-optional-not-installed"
  pass common-htop-optional
fi

check_full_userland_python_int_preflight before-runtime
check_full_userland_runtime
check_full_userland_python_int_preflight after-runtime
check_full_userland_python_cnf_diag

systemd_show_state="$(systemctl show --property=SystemState --value 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_SHOW_STATE__:$systemd_show_state"
[ "$systemd_show_state" = "running" ] &&
  pass systemd-show-system-state || fail systemd-show-system-state

systemd_failed_count="$(systemctl show --property=NFailedUnits --value 2>/dev/null || true)"
echo "__NEMU_CHECK_SYSTEMD_FAILED_COUNT__:$systemd_failed_count"
[ "$systemd_failed_count" = "0" ] &&
  pass systemd-show-failed-count || fail systemd-show-failed-count

systemd_default_target_rc=0
systemd_default_target="$(systemctl get-default 2>/dev/null)" ||
  systemd_default_target_rc=$?
echo "__NEMU_CHECK_SYSTEMD_DEFAULT_TARGET_RC__:$systemd_default_target_rc"
echo "__NEMU_CHECK_SYSTEMD_DEFAULT_TARGET__:$systemd_default_target"
[ "$systemd_default_target_rc" = "0" ] &&
  [ "$systemd_default_target" = "graphical.target" ] &&
  pass systemd-default-target-graphical || fail systemd-default-target-graphical

# 这些 target 是 systemd 从早期 init 到普通多用户态的主干，能把
# “PID1 存在”推进为“默认 graphical target 链已经跑完”。
for systemd_target in \
  local-fs.target \
  sysinit.target \
  basic.target \
  multi-user.target \
  getty.target; do
  check_systemd_unit_active "$systemd_target" "systemd-target-$systemd_target"
done
check_systemd_unit_active graphical.target systemd-target-graphical.target
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
rng_virtio_modalias=""
rng_virtio_dev=""
for virtio_candidate in /sys/bus/virtio/devices/*; do
  [ -e "$virtio_candidate/modalias" ] || continue
  virtio_candidate_modalias="$(cat "$virtio_candidate/modalias" 2>/dev/null || true)"
  if [ "$virtio_candidate_modalias" = "virtio:d00000004v58535959" ]; then
    rng_virtio_modalias="$virtio_candidate_modalias"
    rng_virtio_dev="$virtio_candidate"
    break
  fi
done
rng_virtio_driver=""
rng_virtio_status=""
rng_virtio_features=""
if [ -n "$rng_virtio_dev" ]; then
  rng_virtio_driver="$(basename "$(readlink -f "$rng_virtio_dev/driver" 2>/dev/null || true)")"
  rng_virtio_status="$(cat "$rng_virtio_dev/status" 2>/dev/null || true)"
  rng_virtio_features="$(tr -d '\n' < "$rng_virtio_dev/features" 2>/dev/null || true)"
fi
echo "__NEMU_CHECK_HWRNG_CURRENT__:$hwrng_current"
echo "__NEMU_CHECK_HWRNG_AVAILABLE__:$hwrng_available"
echo "__NEMU_CHECK_VIRTIO_RNG_MODALIAS__:$rng_virtio_modalias"
echo "__NEMU_CHECK_VIRTIO_RNG_DRIVER__:$rng_virtio_driver"
echo "__NEMU_CHECK_VIRTIO_RNG_STATUS__:$rng_virtio_status"
echo "__NEMU_CHECK_VIRTIO_RNG_FEATURES__:$rng_virtio_features"
[ -c /dev/hwrng ] && pass hwrng-node || fail hwrng-node
[ -d "$hwrng_misc" ] && pass hwrng-sysfs || fail hwrng-sysfs
printf '%s\n%s\n' "$hwrng_current" "$hwrng_available" | grep -qi 'virtio' &&
  pass hwrng-virtio-selected || fail hwrng-virtio-selected
[ "$rng_virtio_modalias" = "virtio:d00000004v58535959" ] &&
  pass virtio-rng-modalias || fail virtio-rng-modalias
[ "$rng_virtio_driver" = "virtio_rng" ] &&
  pass virtio-rng-driver || fail virtio-rng-driver
echo "$rng_virtio_status" | grep -Eq '^0x[0-9a-fA-F]+$' &&
  pass virtio-rng-status || fail virtio-rng-status
echo "$rng_virtio_features" | grep -Eq '^[01]+$' &&
  pass virtio-rng-features-bitstring || fail virtio-rng-features-bitstring
[ "$(virtio_feature_bit "$rng_virtio_features" 32)" = "1" ] &&
  pass virtio-rng-feature-version-1 || fail virtio-rng-feature-version-1
[ "$(virtio_feature_bit "$rng_virtio_features" 28)" = "1" ] &&
  pass virtio-rng-ring-feature-indirect-desc || fail virtio-rng-ring-feature-indirect-desc
[ "$(virtio_feature_bit "$rng_virtio_features" 29)" = "1" ] &&
  pass virtio-rng-ring-feature-event-idx || fail virtio-rng-ring-feature-event-idx
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
  rtc_hwclock="$(timeout 20s hwclock --show --rtc=/dev/rtc0 2>&1)"
  rtc_hwclock_rc=$?
  echo "__NEMU_CHECK_RTC0_HWCLOCK__:$rtc_hwclock"
  if [ "$rtc_hwclock_rc" -eq 0 ] && echo "$rtc_hwclock" | grep -Eq '[0-9]{4}'; then
    pass hwclock-rtc0-show
  else
    echo "__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:$rtc_hwclock_rc"
    fail hwclock-rtc0-show
  fi
else
  echo "__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:missing"
fi

virtio_net_modalias=""
virtio_net_dev=""
for virtio_candidate in /sys/bus/virtio/devices/*; do
  [ -e "$virtio_candidate/modalias" ] || continue
  virtio_candidate_modalias="$(cat "$virtio_candidate/modalias" 2>/dev/null || true)"
  if [ "$virtio_candidate_modalias" = "virtio:d00000001v58535959" ]; then
    virtio_net_modalias="$virtio_candidate_modalias"
    virtio_net_dev="$virtio_candidate"
    break
  fi
done
echo "__NEMU_CHECK_VIRTIO_NET_MODALIAS__:$virtio_net_modalias"
[ "$virtio_net_modalias" = "virtio:d00000001v58535959" ] &&
  pass virtio-net-modalias || fail virtio-net-modalias

virtio_net_driver=""
virtio_net_status=""
virtio_net_features=""
if [ -n "$virtio_net_dev" ]; then
  virtio_net_driver="$(basename "$(readlink -f "$virtio_net_dev/driver" 2>/dev/null || true)")"
  virtio_net_status="$(cat "$virtio_net_dev/status" 2>/dev/null || true)"
  virtio_net_features="$(tr -d '\n' < "$virtio_net_dev/features" 2>/dev/null || true)"
fi
echo "__NEMU_CHECK_VIRTIO_NET_DRIVER__:$virtio_net_driver"
echo "__NEMU_CHECK_VIRTIO_NET_STATUS__:$virtio_net_status"
echo "__NEMU_CHECK_VIRTIO_NET_FEATURES__:$virtio_net_features"
[ "$virtio_net_driver" = "virtio_net" ] &&
  pass virtio-net-driver || fail virtio-net-driver
echo "$virtio_net_status" | grep -Eq '^0x[0-9a-fA-F]+$' &&
  pass virtio-net-status || fail virtio-net-status
echo "$virtio_net_features" | grep -Eq '^[01]+$' &&
  pass virtio-net-features-bitstring || fail virtio-net-features-bitstring
[ "$(virtio_feature_bit "$virtio_net_features" 32)" = "1" ] &&
  pass virtio-net-feature-version-1 || fail virtio-net-feature-version-1
[ "$(virtio_feature_bit "$virtio_net_features" 3)" = "1" ] &&
  pass virtio-net-feature-mtu || fail virtio-net-feature-mtu
[ "$(virtio_feature_bit "$virtio_net_features" 5)" = "1" ] &&
  pass virtio-net-feature-mac || fail virtio-net-feature-mac
[ "$(virtio_feature_bit "$virtio_net_features" 15)" = "1" ] &&
  pass virtio-net-feature-mrg-rxbuf || fail virtio-net-feature-mrg-rxbuf
[ "$(virtio_feature_bit "$virtio_net_features" 16)" = "1" ] &&
  pass virtio-net-feature-status || fail virtio-net-feature-status
[ "$(virtio_feature_bit "$virtio_net_features" 17)" = "1" ] &&
  pass virtio-net-feature-ctrl-vq || fail virtio-net-feature-ctrl-vq
[ "$(virtio_feature_bit "$virtio_net_features" 18)" = "1" ] &&
  pass virtio-net-feature-ctrl-rx || fail virtio-net-feature-ctrl-rx
[ "$(virtio_feature_bit "$virtio_net_features" 19)" = "1" ] &&
  pass virtio-net-feature-ctrl-vlan || fail virtio-net-feature-ctrl-vlan
if [ "$(virtio_feature_bit "$virtio_net_features" 20)" = "1" ]; then
  pass virtio-net-feature-ctrl-rx-extra
else
  echo "__NEMU_CHECK_INFO__:virtio-net-feature-ctrl-rx-extra-driver-not-negotiated"
  pass virtio-net-feature-ctrl-rx-extra-driver-optional
fi
[ "$(virtio_feature_bit "$virtio_net_features" 21)" = "1" ] &&
  pass virtio-net-feature-guest-announce || fail virtio-net-feature-guest-announce
[ "$(virtio_feature_bit "$virtio_net_features" 23)" = "1" ] &&
  pass virtio-net-feature-ctrl-mac-addr || fail virtio-net-feature-ctrl-mac-addr
[ "$(virtio_feature_bit "$virtio_net_features" 63)" = "1" ] &&
  pass virtio-net-feature-speed-duplex || fail virtio-net-feature-speed-duplex
[ "$(virtio_feature_bit "$virtio_net_features" 28)" = "1" ] &&
  pass virtio-net-ring-feature-indirect-desc || fail virtio-net-ring-feature-indirect-desc
[ "$(virtio_feature_bit "$virtio_net_features" 29)" = "1" ] &&
  pass virtio-net-ring-feature-event-idx || fail virtio-net-ring-feature-event-idx

virtio_net_iface=""
virtio_net_real="$(readlink -f "$virtio_net_dev" 2>/dev/null || true)"
for iface_path in /sys/class/net/*; do
  [ -e "$iface_path" ] || continue
  iface="$(basename "$iface_path")"
  [ "$iface" = "lo" ] && continue
  iface_dev="$(readlink -f "$iface_path/device" 2>/dev/null || true)"
  if [ -n "$iface_dev" ] && [ "$iface_dev" = "$virtio_net_real" ]; then
    virtio_net_iface="$iface"
    break
  fi
done
echo "__NEMU_CHECK_VIRTIO_NET_IFACE__:$virtio_net_iface"
[ -n "$virtio_net_iface" ] && pass virtio-net-interface || fail virtio-net-interface
virtio_net_backend="${NEMU_GUEST_NET_BACKEND:-hostless}"
echo "__NEMU_CHECK_VIRTIO_NET_BACKEND__:$virtio_net_backend"

virtio_net_mac=""
virtio_net_carrier=""
virtio_net_mtu=""
virtio_net_speed=""
virtio_net_duplex=""
if [ -n "$virtio_net_iface" ]; then
  virtio_net_mac="$(cat "/sys/class/net/$virtio_net_iface/address" 2>/dev/null || true)"
  virtio_net_carrier="$(cat "/sys/class/net/$virtio_net_iface/carrier" 2>/dev/null || true)"
  virtio_net_mtu="$(cat "/sys/class/net/$virtio_net_iface/mtu" 2>/dev/null || true)"
fi
echo "__NEMU_CHECK_VIRTIO_NET_MAC__:$virtio_net_mac"
echo "__NEMU_CHECK_VIRTIO_NET_CARRIER__:$virtio_net_carrier"
echo "__NEMU_CHECK_VIRTIO_NET_MTU__:$virtio_net_mtu"
[ "$virtio_net_mac" = "52:54:00:12:34:56" ] &&
  pass virtio-net-mac || fail virtio-net-mac
[ "$virtio_net_mtu" = "1500" ] &&
  pass virtio-net-mtu || fail virtio-net-mtu

virtio_net_ipv4=""
virtio_net_operstate=""
virtio_net_carrier_up=""
if command -v ip >/dev/null 2>&1; then
  pass iproute2-present
  if [ -n "$virtio_net_iface" ]; then
    if ip link set dev "$virtio_net_iface" up; then
      pass virtio-net-link-set-up
    else
      fail virtio-net-link-set-up
    fi
    if [ "$virtio_net_backend" = "hostless" ] &&
       [ "${NEMU_GUEST_DHCP_PROBE:-1}" != "0" ]; then
      dhcp_probe_b64="$check_dir/dhcp-probe.b64"
      dhcp_probe_bin="$check_dir/dhcp-probe"
      mkdir -p "$check_dir"
      cat > "$dhcp_probe_b64" <<'__NEMU_DHCP_PROBE_B64__'
__NEMU_DHCP_PROBE_PAYLOAD__
__NEMU_DHCP_PROBE_B64__
      if base64 -d "$dhcp_probe_b64" > "$dhcp_probe_bin" &&
         chmod +x "$dhcp_probe_bin" &&
         "$dhcp_probe_bin" "$virtio_net_iface"; then
        pass virtio-net-dhcp-lease
      else
        fail virtio-net-dhcp-lease
      fi
    else
      echo "__NEMU_CHECK_VIRTIO_NET_DHCP_SKIP__:$virtio_net_backend"
    fi
    if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" = "full" ] &&
       [ "$virtio_net_backend" = "hostless" ]; then
      networkd_dhcp_ipv4=""
      networkd_dhcp_route=""
      networkd_dhcp_lease_seen=0
      networkd_dhcp_lease_path=""
      networkd_dhcp_wait=0
      while [ "$networkd_dhcp_wait" -lt "${networkd_dhcp_timeout:-90}" ]; do
        networkd_dhcp_ipv4="$(ip -o -4 addr show dev "$virtio_net_iface" 2>/dev/null |
          awk '$4 == "10.0.2.15/24" { print $4; exit }')"
        networkd_dhcp_route="$(ip route get 10.0.2.2 2>/dev/null || true)"
        networkd_dhcp_lease_seen=0
        networkd_dhcp_lease_path=""
        for networkd_lease in /run/systemd/netif/leases/*; do
          [ -f "$networkd_lease" ] || continue
          if grep -Fxq 'ADDRESS=10.0.2.15' "$networkd_lease" &&
             grep -Fxq 'ROUTER=10.0.2.2' "$networkd_lease" &&
             grep -Fxq 'DNS=10.0.2.2' "$networkd_lease"; then
            networkd_dhcp_lease_seen=1
            networkd_dhcp_lease_path="$networkd_lease"
            break
          fi
        done
        if [ "$networkd_dhcp_ipv4" = "10.0.2.15/24" ] &&
           printf '%s\n' "$networkd_dhcp_route" | grep -Fq '10.0.2.2 dev ' &&
           printf '%s\n' "$networkd_dhcp_route" | grep -Fq 'src 10.0.2.15' &&
           [ "$networkd_dhcp_lease_seen" = "1" ]; then
          break
        fi
        sleep 3
        networkd_dhcp_wait=$((networkd_dhcp_wait + 3))
      done
      networkd_dhcp_status_output="$(
        timeout 20s env SYSTEMD_BUS_TIMEOUT=10s \
          /bin/networkctl --no-pager status "$virtio_net_iface" 2>&1
      )" || true
      networkd_dhcp_lease_output=""
      if [ -n "$networkd_dhcp_lease_path" ]; then
        networkd_dhcp_lease_output="$(sed -n '1,120p' "$networkd_dhcp_lease_path" 2>/dev/null || true)"
      fi
      networkd_dhcp_netplan_file_seen=0
      if [ "${netplan_generated_network_ok:-0}" = "1" ] &&
         printf '%s\n' "$networkd_dhcp_status_output" | grep -Fq "Network File: ${netplan_generated_network:-}"; then
        networkd_dhcp_netplan_file_seen=1
      fi
      networkd_wait_online_rc=0
      networkd_wait_online_output="$(
        timeout "${networkd_wait_online_timeout}s" \
          /lib/systemd/systemd-networkd-wait-online \
            --interface="$virtio_net_iface" \
            --timeout="$networkd_wait_online_timeout" 2>&1
      )" || networkd_wait_online_rc=$?
      networkd_wait_online_state="$(printf '%s\n' "$networkd_dhcp_status_output" |
        sed -n 's/^[[:space:]]*Online state:[[:space:]]*//p' |
        sed -n '1p')"
      network_online_unit=nemu-full-network-online.service
      network_online_marker=/run/nemu-full-network-online.out
      network_online_unit_file=/run/systemd/system/$network_online_unit
      network_online_timeout=$((networkd_wait_online_timeout + 30))
      network_online_reload_ok=0
      network_online_start_rc=0
      network_online_start_output=""
      network_online_target_active=""
      network_online_target_result=""
      network_online_wait_unit_active=""
      network_online_wait_unit_result=""
      network_online_service_active=""
      network_online_service_result=""
      network_online_service_output=""
      mkdir -p /run/systemd/system
      rm -f "$network_online_marker" "$network_online_unit_file" 2>/dev/null || true
      # 用真实 PID1 事务证明 network-online.target 排序语义，而不只是在 shell 中直接运行 wait-online。
      cat >"$network_online_unit_file" <<EOF
[Unit]
Description=NEMU full network-online target smoke
Wants=network-online.target systemd-networkd-wait-online.service
After=network-online.target systemd-networkd-wait-online.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'printf network-online-target-ok > $network_online_marker'
EOF
      if systemd_daemon_reload_request "$network_online_unit" network-online-target; then
        network_online_reload_ok=1
        network_online_start_output="$(
          timeout "${network_online_timeout}s" env SYSTEMD_BUS_TIMEOUT=15s \
            systemctl start "$network_online_unit" 2>&1
        )" || network_online_start_rc=$?
      else
        network_online_start_rc=125
      fi
      network_online_target_active="$(systemctl show --property=ActiveState --value network-online.target 2>/dev/null || true)"
      network_online_target_result="$(systemctl show --property=Result --value network-online.target 2>/dev/null || true)"
      network_online_wait_unit_active="$(systemctl show --property=ActiveState --value systemd-networkd-wait-online.service 2>/dev/null || true)"
      network_online_wait_unit_result="$(systemctl show --property=Result --value systemd-networkd-wait-online.service 2>/dev/null || true)"
      network_online_service_active="$(systemctl show --property=ActiveState --value "$network_online_unit" 2>/dev/null || true)"
      network_online_service_result="$(systemctl show --property=Result --value "$network_online_unit" 2>/dev/null || true)"
      if [ -f "$network_online_marker" ]; then
        network_online_service_output="$(sed -n '1p' "$network_online_marker" 2>/dev/null || true)"
      fi
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_IPV4__:$networkd_dhcp_ipv4"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_ROUTE__:$networkd_dhcp_route"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_WAIT_SECONDS__:$networkd_dhcp_wait"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_LEASE_SEEN__:$networkd_dhcp_lease_seen"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_LEASE_PATH__:$networkd_dhcp_lease_path"
      echo "__NEMU_CHECK_FULL_NETPLAN_NETWORKD_FILE_SEEN__:$networkd_dhcp_netplan_file_seen"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_TIMEOUT__:$networkd_wait_online_timeout"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_IFACE__:$virtio_net_iface"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_RC__:$networkd_wait_online_rc"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_STATE__:$networkd_wait_online_state"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_OUTPUT_BEGIN__"
      printf '%s\n' "$networkd_wait_online_output" | sed -n '1,120p'
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_OUTPUT_END__"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_TARGET_TIMEOUT__:$network_online_timeout"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_UNIT__:$network_online_unit"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_RELOAD_OK__:$network_online_reload_ok"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_RC__:$network_online_start_rc"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_TARGET_ACTIVE__:$network_online_target_active"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_TARGET_RESULT__:$network_online_target_result"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_UNIT_ACTIVE__:$network_online_wait_unit_active"
      echo "__NEMU_CHECK_FULL_NETWORKD_WAIT_ONLINE_UNIT_RESULT__:$network_online_wait_unit_result"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_ACTIVE__:$network_online_service_active"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_RESULT__:$network_online_service_result"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_OUTPUT__:$network_online_service_output"
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_START_OUTPUT_BEGIN__"
      printf '%s\n' "$network_online_start_output" | sed -n '1,120p'
      echo "__NEMU_CHECK_FULL_NETWORK_ONLINE_SERVICE_START_OUTPUT_END__"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_LEASE_BEGIN__"
      printf '%s\n' "$networkd_dhcp_lease_output"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_LEASE_END__"
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_STATUS_BEGIN__"
      printf '%s\n' "$networkd_dhcp_status_output" | sed -n '1,160p'
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_STATUS_END__"
      if [ "${networkd_dhcp_conf_ok:-0}" = "1" ] &&
         [ "${netplan_generated_network_ok:-0}" = "1" ] &&
         [ "$networkd_dhcp_netplan_file_seen" = "1" ] &&
         [ "${networkd_active:-unknown}" = "active" ] &&
         [ "$networkd_dhcp_ipv4" = "10.0.2.15/24" ] &&
         printf '%s\n' "$networkd_dhcp_route" | grep -Fq '10.0.2.2 dev ' &&
         printf '%s\n' "$networkd_dhcp_route" | grep -Fq 'src 10.0.2.15' &&
         [ "$networkd_dhcp_lease_seen" = "1" ] &&
         [ "$networkd_wait_online_rc" = "0" ] &&
         [ "$networkd_wait_online_state" = "online" ] &&
         [ "$network_online_reload_ok" = "1" ] &&
         [ "$network_online_start_rc" = "0" ] &&
         [ "$network_online_target_active" = "active" ] &&
         [ "$network_online_wait_unit_result" = "success" ] &&
         [ "$network_online_service_result" = "success" ] &&
         [ "$network_online_service_output" = "network-online-target-ok" ]; then
        pass full-userland-systemd-networkd-wait-online-hostless
        pass full-userland-systemd-network-online-target
        pass full-userland-netplan-networkd-hostless-dhcp
        pass full-userland-systemd-networkd-hostless-dhcp
      else
        if [ "$networkd_wait_online_rc" != "0" ] ||
           [ "$networkd_wait_online_state" != "online" ]; then
          fail full-userland-systemd-networkd-wait-online-hostless
        fi
        if [ "$network_online_reload_ok" != "1" ] ||
           [ "$network_online_start_rc" != "0" ] ||
           [ "$network_online_target_active" != "active" ] ||
           [ "$network_online_wait_unit_result" != "success" ] ||
           [ "$network_online_service_result" != "success" ] ||
           [ "$network_online_service_output" != "network-online-target-ok" ]; then
          fail full-userland-systemd-network-online-target
        fi
        systemctl status systemd-networkd.service --no-pager 2>/dev/null || true
        systemctl status network-online.target systemd-networkd-wait-online.service "$network_online_unit" --no-pager 2>/dev/null || true
        journalctl -u systemd-networkd.service --no-pager -n 160 2>/dev/null | sed -n '1,160p' || true
        fail full-userland-systemd-networkd-hostless-dhcp
      fi
    else
      echo "__NEMU_CHECK_FULL_NETWORKD_DHCP_LEASE_SKIP__:${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}:$virtio_net_backend"
    fi
    if [ "$virtio_net_backend" = "hostless" ]; then
      ip addr replace 10.0.2.15/24 dev "$virtio_net_iface" 2>/dev/null || true
      virtio_net_ipv4="$(ip -o -4 addr show dev "$virtio_net_iface" 2>/dev/null |
        awk '$4 == "10.0.2.15/24" { print $4; exit }')"
    elif [ "$virtio_net_backend" = "tap" ]; then
      echo "__NEMU_CHECK_VIRTIO_NET_TAP_IFNAME__:${NEMU_GUEST_NET_TAP_IFNAME:-}"
      if [ -n "${NEMU_GUEST_TAP_IPV4_CIDR:-}" ]; then
        if ip addr replace "${NEMU_GUEST_TAP_IPV4_CIDR}" dev "$virtio_net_iface"; then
          pass virtio-net-tap-ipv4-static
        else
          fail virtio-net-tap-ipv4-static
        fi
      else
        echo "__NEMU_CHECK_VIRTIO_NET_TAP_IPV4_STATIC_SKIP__"
      fi
      if [ -n "${NEMU_GUEST_TAP_GATEWAY:-}" ]; then
        if ip route replace default via "${NEMU_GUEST_TAP_GATEWAY}" dev "$virtio_net_iface"; then
          pass virtio-net-tap-default-route
        else
          fail virtio-net-tap-default-route
        fi
      else
        echo "__NEMU_CHECK_VIRTIO_NET_TAP_GATEWAY_SKIP__"
      fi
      if [ -n "${NEMU_GUEST_TAP_DNS:-}" ]; then
        printf 'nameserver %s\noptions timeout:2 attempts:1\n' \
          "${NEMU_GUEST_TAP_DNS}" > /etc/resolv.conf
        pass virtio-net-tap-dns-config
      else
        echo "__NEMU_CHECK_VIRTIO_NET_TAP_DNS_SKIP__"
      fi
      virtio_net_ipv4="$(ip -o -4 addr show dev "$virtio_net_iface" 2>/dev/null |
        awk '{ print $4; exit }')"
    else
      fail virtio-net-backend
    fi
    virtio_net_operstate="$(cat "/sys/class/net/$virtio_net_iface/operstate" 2>/dev/null || true)"
    virtio_net_carrier_up="$(cat "/sys/class/net/$virtio_net_iface/carrier" 2>/dev/null || true)"
    virtio_net_speed="$(cat "/sys/class/net/$virtio_net_iface/speed" 2>/dev/null || true)"
    virtio_net_duplex="$(cat "/sys/class/net/$virtio_net_iface/duplex" 2>/dev/null || true)"
  fi
else
  fail iproute2-present
fi
echo "__NEMU_CHECK_VIRTIO_NET_IPV4__:$virtio_net_ipv4"
echo "__NEMU_CHECK_VIRTIO_NET_OPERSTATE__:$virtio_net_operstate"
echo "__NEMU_CHECK_VIRTIO_NET_CARRIER_AFTER_UP__:$virtio_net_carrier_up"
echo "__NEMU_CHECK_VIRTIO_NET_SPEED__:$virtio_net_speed"
echo "__NEMU_CHECK_VIRTIO_NET_DUPLEX__:$virtio_net_duplex"
if [ "$virtio_net_backend" = "hostless" ]; then
  [ "$virtio_net_ipv4" = "10.0.2.15/24" ] &&
    pass virtio-net-ipv4-static || fail virtio-net-ipv4-static
elif [ "$virtio_net_backend" = "tap" ] &&
     [ -n "${NEMU_GUEST_TAP_IPV4_CIDR:-}" ]; then
  [ "$virtio_net_ipv4" = "$NEMU_GUEST_TAP_IPV4_CIDR" ] &&
    pass virtio-net-ipv4-static || fail virtio-net-ipv4-static
else
  echo "__NEMU_CHECK_VIRTIO_NET_IPV4_STATIC_SKIP__:$virtio_net_backend"
fi
[ "$virtio_net_speed" = "1000" ] &&
  pass virtio-net-speed || fail virtio-net-speed
[ "$virtio_net_duplex" = "full" ] &&
  pass virtio-net-duplex || fail virtio-net-duplex

if [ "$virtio_net_backend" = "hostless" ] &&
   [ "${NEMU_GUEST_DNS_PROBE:-1}" != "0" ]; then
  dns_probe_b64="$check_dir/dns-probe.b64"
  dns_probe_bin="$check_dir/dns-probe"
  mkdir -p "$check_dir"
  cat > "$dns_probe_b64" <<'__NEMU_DNS_PROBE_B64__'
__NEMU_DNS_PROBE_PAYLOAD__
__NEMU_DNS_PROBE_B64__
  if base64 -d "$dns_probe_b64" > "$dns_probe_bin" &&
     chmod +x "$dns_probe_bin" &&
     "$dns_probe_bin" "$virtio_net_iface" 10.0.2.2 nemu.local; then
    pass virtio-net-dns-a
  else
    fail virtio-net-dns-a
  fi
else
  echo "__NEMU_CHECK_VIRTIO_NET_DNS_SKIP__:$virtio_net_backend"
fi

if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" = "full" ] &&
   [ "$virtio_net_backend" = "hostless" ]; then
  resolved_dns_link_rc=127
  resolved_dns_domain_rc=127
  resolved_dns_query_rc=124
  resolved_dns_query_output=""
  resolved_dns_status_output=""
  resolved_dns_wait=0
  resolved_dns_address_seen=0
  if [ -n "$virtio_net_iface" ] &&
     command -v resolvectl >/dev/null 2>&1 &&
     [ "${resolved_dns_active:-unknown}" = "active" ]; then
    timeout 15s env SYSTEMD_BUS_TIMEOUT=5s \
      resolvectl dns "$virtio_net_iface" 10.0.2.2 >/dev/null 2>&1 ||
      resolved_dns_link_rc=$?
    [ "$resolved_dns_link_rc" = "127" ] && resolved_dns_link_rc=0
    timeout 15s env SYSTEMD_BUS_TIMEOUT=5s \
      resolvectl domain "$virtio_net_iface" '~.' >/dev/null 2>&1 ||
      resolved_dns_domain_rc=$?
    [ "$resolved_dns_domain_rc" = "127" ] && resolved_dns_domain_rc=0
    while [ "$resolved_dns_wait" -lt "${resolved_dns_timeout:-90}" ]; do
      resolved_dns_query_rc=0
      resolved_dns_query_output="$(
        timeout 30s env SYSTEMD_BUS_TIMEOUT=10s \
          resolvectl query -4 nemu.local 2>&1
      )" || resolved_dns_query_rc=$?
      if printf '%s\n' "$resolved_dns_query_output" |
         grep -Eq '(^|[^0-9])10\.0\.2\.2([^0-9]|$)'; then
        resolved_dns_address_seen=1
        break
      fi
      sleep 3
      resolved_dns_wait=$((resolved_dns_wait + 3))
    done
    resolved_dns_status_output="$(
      timeout 20s env SYSTEMD_BUS_TIMEOUT=10s \
        resolvectl status "$virtio_net_iface" 2>&1
    )" || true
  else
    resolved_dns_query_output="resolvectl unavailable, inactive, or virtio-net interface missing"
  fi
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_LINK_RC__:$resolved_dns_link_rc"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_DOMAIN_RC__:$resolved_dns_domain_rc"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_QUERY_RC__:$resolved_dns_query_rc"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_WAIT_SECONDS__:$resolved_dns_wait"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_ADDRESS_SEEN__:$resolved_dns_address_seen"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_QUERY_BEGIN__"
  printf '%s\n' "$resolved_dns_query_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_QUERY_END__"
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_STATUS_BEGIN__"
  printf '%s\n' "$resolved_dns_status_output" | sed -n '1,160p'
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_STATUS_END__"
  if [ "${resolved_dns_conf_ok:-0}" = "1" ] &&
     [ "${resolved_dns_active:-unknown}" = "active" ] &&
     [ "$resolved_dns_link_rc" = "0" ] &&
     [ "$resolved_dns_domain_rc" = "0" ] &&
     [ "$resolved_dns_query_rc" = "0" ] &&
     [ "$resolved_dns_address_seen" = "1" ]; then
    pass full-userland-systemd-resolved-hostless-dns
  else
    fail full-userland-systemd-resolved-hostless-dns
  fi
else
  echo "__NEMU_CHECK_FULL_RESOLVED_DNS_QUERY_SKIP__:${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}:$virtio_net_backend"
fi

virtio_net_tx_packets0=""
virtio_net_rx_packets0=""
virtio_net_route=""
if [ -n "$virtio_net_iface" ]; then
  virtio_net_tx_packets0="$(cat "/sys/class/net/$virtio_net_iface/statistics/tx_packets" 2>/dev/null || true)"
  virtio_net_rx_packets0="$(cat "/sys/class/net/$virtio_net_iface/statistics/rx_packets" 2>/dev/null || true)"
  if [ "$virtio_net_backend" = "tap" ] && [ -n "${NEMU_GUEST_TAP_GATEWAY:-}" ]; then
    virtio_net_route="$(ip route get "${NEMU_GUEST_TAP_GATEWAY}" 2>/dev/null || ip route show default 2>/dev/null || true)"
  else
    virtio_net_route="$(ip route get 10.0.2.2 2>/dev/null || true)"
  fi
fi
echo "__NEMU_CHECK_VIRTIO_NET_TX_PACKETS_BEGIN__:$virtio_net_tx_packets0"
echo "__NEMU_CHECK_VIRTIO_NET_RX_PACKETS_BEGIN__:$virtio_net_rx_packets0"
echo "__NEMU_CHECK_VIRTIO_NET_ROUTE__:$virtio_net_route"

if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" = "full" ] &&
   [ "$virtio_net_backend" = "hostless" ]; then
  hostless_ntp_probe_rc=0
  hostless_ntp_probe_output="$(
    timeout "${timesyncd_ntp_timeout:-120}s" python3 - <<'PY'
import socket
import struct
import time

server = "10.0.2.2"
port = 123
unix_delta = 2208988800
now = time.time()
seconds = int(now) + unix_delta
fraction = int((now - int(now)) * (1 << 32)) & 0xffffffff
packet = bytearray(48)
packet[0] = (4 << 3) | 3
struct.pack_into("!II", packet, 40, seconds, fraction)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(15.0)
start = time.time()
sock.sendto(packet, (server, port))
data, addr = sock.recvfrom(512)
elapsed_ms = int((time.time() - start) * 1000)
sock.close()

mode = data[0] & 0x7 if len(data) >= 1 else -1
version = (data[0] >> 3) & 0x7 if len(data) >= 1 else -1
stratum = data[1] if len(data) >= 2 else -1
origin_match = int(len(data) >= 32 and data[24:32] == bytes(packet[40:48]))
tx_nonzero = int(len(data) >= 48 and data[40:48] != b"\0" * 8)
print(f"server={server}")
print(f"peer={addr[0]}:{addr[1]}")
print(f"reply_len={len(data)}")
print(f"version={version}")
print(f"mode={mode}")
print(f"stratum={stratum}")
print(f"origin_match={origin_match}")
print(f"tx_nonzero={tx_nonzero}")
print(f"elapsed_ms={elapsed_ms}")
if addr[0] != server or len(data) < 48 or mode != 4 or stratum <= 0 or not origin_match or not tx_nonzero:
    raise SystemExit(1)
PY
  )" || hostless_ntp_probe_rc=$?
  hostless_ntp_probe_server="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^server=//p' | sed -n '1p'
  )"
  hostless_ntp_probe_peer="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^peer=//p' | sed -n '1p'
  )"
  hostless_ntp_probe_mode="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^mode=//p' | sed -n '1p'
  )"
  hostless_ntp_probe_stratum="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^stratum=//p' | sed -n '1p'
  )"
  hostless_ntp_probe_origin_match="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^origin_match=//p' | sed -n '1p'
  )"
  hostless_ntp_probe_tx_nonzero="$(
    printf '%s\n' "$hostless_ntp_probe_output" |
      sed -n 's/^tx_nonzero=//p' | sed -n '1p'
  )"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_RC__:$hostless_ntp_probe_rc"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_SERVER__:$hostless_ntp_probe_server"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_PEER__:$hostless_ntp_probe_peer"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_MODE__:$hostless_ntp_probe_mode"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_STRATUM__:$hostless_ntp_probe_stratum"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_ORIGIN_MATCH__:$hostless_ntp_probe_origin_match"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_TX_NONZERO__:$hostless_ntp_probe_tx_nonzero"
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_OUTPUT_BEGIN__"
  printf '%s\n' "$hostless_ntp_probe_output" | sed -n '1,80p'
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_OUTPUT_END__"
  timesyncd_status_rc=124
  timesyncd_status_output=""
  timesyncd_status_wait=0
  timesyncd_status_server_name=""
  timesyncd_status_server_address=""
  timesyncd_status_message_seen=0
  timesyncd_status_synchronized=""
  while [ "$timesyncd_status_wait" -lt "${timesyncd_ntp_timeout:-120}" ]; do
    timesyncd_status_rc=0
    timesyncd_status_output="$(
      timeout 15s env SYSTEMD_BUS_TIMEOUT=5s \
        timedatectl show-timesync --all --no-pager 2>&1
    )" || timesyncd_status_rc=$?
    timesyncd_status_server_name="$(
      printf '%s\n' "$timesyncd_status_output" |
        sed -n 's/^ServerName=//p' | sed -n '1p'
    )"
    timesyncd_status_server_address="$(
      printf '%s\n' "$timesyncd_status_output" |
        sed -n 's/^ServerAddress=//p' | sed -n '1p'
    )"
    if printf '%s\n' "$timesyncd_status_output" |
       grep -Eq '^NTPMessage=\{ .*Mode=4, Stratum=[1-9]'; then
      timesyncd_status_message_seen=1
    else
      timesyncd_status_message_seen=0
    fi
    timesyncd_status_synchronized="$(
      timeout 10s env SYSTEMD_BUS_TIMEOUT=5s \
        timedatectl show --property=NTPSynchronized --value 2>/dev/null |
        sed -n '1p'
    )" || timesyncd_status_synchronized=unknown
    if [ "$timesyncd_status_rc" = "0" ] &&
       { [ "$timesyncd_status_server_name" = "10.0.2.2" ] ||
         [ "$timesyncd_status_server_address" = "10.0.2.2" ]; } &&
       [ "$timesyncd_status_message_seen" = "1" ]; then
      break
    fi
    sleep 4
    timesyncd_status_wait=$((timesyncd_status_wait + 4))
  done
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_STATUS_RC__:$timesyncd_status_rc"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_STATUS_WAIT_SECONDS__:$timesyncd_status_wait"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_SERVER_NAME__:$timesyncd_status_server_name"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_SERVER_ADDRESS__:$timesyncd_status_server_address"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_MESSAGE_SEEN__:$timesyncd_status_message_seen"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_SYNCHRONIZED__:$timesyncd_status_synchronized"
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_STATUS_BEGIN__"
  printf '%s\n' "$timesyncd_status_output" | sed -n '1,120p'
  echo "__NEMU_CHECK_FULL_TIMESYNCD_NTP_STATUS_END__"
  if [ "${timesyncd_ntp_conf_ok:-0}" = "1" ] &&
     [ "${timesyncd_ntp_active:-unknown}" = "active" ] &&
     [ "$hostless_ntp_probe_rc" = "0" ] &&
     [ "$hostless_ntp_probe_server" = "10.0.2.2" ] &&
     [ "$hostless_ntp_probe_mode" = "4" ] &&
     [ "$hostless_ntp_probe_origin_match" = "1" ] &&
     [ "$hostless_ntp_probe_tx_nonzero" = "1" ] &&
     [ "$timesyncd_status_rc" = "0" ] &&
     { [ "$timesyncd_status_server_name" = "10.0.2.2" ] ||
       [ "$timesyncd_status_server_address" = "10.0.2.2" ]; } &&
     [ "$timesyncd_status_message_seen" = "1" ]; then
    pass full-userland-hostless-ntp-probe
    pass full-userland-timesyncd-hostless-status
  else
    fail full-userland-hostless-ntp-probe
  fi
else
  echo "__NEMU_CHECK_FULL_HOSTLESS_NTP_PROBE_SKIP__:${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}:$virtio_net_backend"
fi

if [ "$virtio_net_backend" = "hostless" ] &&
   [ "${NEMU_GUEST_TCP_PROBE:-1}" != "0" ]; then
  tcp_probe_b64="$check_dir/tcp-probe.b64"
  tcp_probe_bin="$check_dir/tcp-probe"
  mkdir -p "$check_dir"
  cat > "$tcp_probe_b64" <<'__NEMU_TCP_PROBE_B64__'
__NEMU_TCP_PROBE_PAYLOAD__
__NEMU_TCP_PROBE_B64__
  if base64 -d "$tcp_probe_b64" > "$tcp_probe_bin" &&
     chmod +x "$tcp_probe_bin" &&
     "$tcp_probe_bin" "$virtio_net_iface" 10.0.2.2 80 /nemu-health \
       "${NEMU_GUEST_NET_TCP_BURST_LOOPS:-1}"; then
    pass virtio-net-tcp-http
  else
    fail virtio-net-tcp-http
  fi
else
  echo "__NEMU_CHECK_VIRTIO_NET_TCP_SKIP__:$virtio_net_backend"
fi

check_full_userland_network_clients

if [ "$virtio_net_backend" = "hostless" ] &&
   [ "${NEMU_GUEST_ICMP_PROBE:-1}" != "0" ]; then
  icmp_probe_b64="$check_dir/icmp-probe.b64"
  icmp_probe_bin="$check_dir/icmp-probe"
  mkdir -p "$check_dir"
  cat > "$icmp_probe_b64" <<'__NEMU_ICMP_PROBE_B64__'
__NEMU_ICMP_PROBE_PAYLOAD__
__NEMU_ICMP_PROBE_B64__
  if base64 -d "$icmp_probe_b64" > "$icmp_probe_bin" &&
     chmod +x "$icmp_probe_bin" &&
     "$icmp_probe_bin" 10.0.2.2; then
    pass virtio-net-icmp-echo
  else
    fail virtio-net-icmp-echo
  fi
else
  echo "__NEMU_CHECK_VIRTIO_NET_ICMP_SKIP__:$virtio_net_backend"
fi
tap_external_checks=0
tap_external_passes=0
if [ "$virtio_net_backend" = "tap" ]; then
  if [ -n "${NEMU_GUEST_TAP_PING_TARGET:-}" ]; then
    tap_external_checks=$((tap_external_checks + 1))
    tap_ping_rc=0
    if command -v ping >/dev/null 2>&1; then
      timeout 30s ping -4 -c 1 -W 10 "${NEMU_GUEST_TAP_PING_TARGET}" ||
        tap_ping_rc=$?
    else
      tap_ping_rc=127
    fi
    echo "__NEMU_CHECK_VIRTIO_NET_TAP_PING_RC__:${NEMU_GUEST_TAP_PING_TARGET}:$tap_ping_rc"
    if [ "$tap_ping_rc" = "0" ]; then
      tap_external_passes=$((tap_external_passes + 1))
      pass virtio-net-tap-ping
    else
      fail virtio-net-tap-ping
    fi
  fi
  if [ -n "${NEMU_GUEST_TAP_HTTP_URL:-}" ]; then
    tap_external_checks=$((tap_external_checks + 1))
    tap_http_body=/tmp/nemu-tap-http.body
    tap_http_err=/tmp/nemu-tap-http.err
    tap_http_rc=0
    tap_http_code=
    if command -v curl >/dev/null 2>&1; then
      tap_http_code="$(
        timeout 120s curl -4 -fsS \
          --connect-timeout 30 \
          --max-time 120 \
          -o "$tap_http_body" \
          -w '%{http_code}' \
          "${NEMU_GUEST_TAP_HTTP_URL}" 2>"$tap_http_err"
      )" || tap_http_rc=$?
    else
      tap_http_rc=127
      printf 'curl not found\n' >"$tap_http_err"
    fi
    echo "__NEMU_CHECK_VIRTIO_NET_TAP_HTTP_CODE__:$tap_http_rc:$tap_http_code:${NEMU_GUEST_TAP_HTTP_URL}"
    if [ "$tap_http_rc" = "0" ] && echo "$tap_http_code" | grep -Eq '^2[0-9][0-9]$|^3[0-9][0-9]$'; then
      tap_external_passes=$((tap_external_passes + 1))
      pass virtio-net-tap-http
    else
      echo "__NEMU_CHECK_VIRTIO_NET_TAP_HTTP_ERROR_BEGIN__"
      sed -n '1,80p' "$tap_http_err" 2>/dev/null || true
      echo "__NEMU_CHECK_VIRTIO_NET_TAP_HTTP_ERROR_END__"
      fail virtio-net-tap-http
    fi
  fi
  echo "__NEMU_CHECK_VIRTIO_NET_TAP_EXTERNAL__:$tap_external_passes/$tap_external_checks"
  if [ "${NEMU_GUEST_TAP_REQUIRE_EXTERNAL:-0}" = "1" ]; then
    [ "$tap_external_checks" -gt 0 ] &&
      [ "$tap_external_passes" -eq "$tap_external_checks" ] &&
      pass virtio-net-tap-external || fail virtio-net-tap-external
  else
    echo "__NEMU_CHECK_VIRTIO_NET_TAP_EXTERNAL_SKIP__"
  fi
fi
if [ -n "$virtio_net_iface" ]; then
  virtio_net_tx_packets1="$(cat "/sys/class/net/$virtio_net_iface/statistics/tx_packets" 2>/dev/null || true)"
  virtio_net_rx_packets1="$(cat "/sys/class/net/$virtio_net_iface/statistics/rx_packets" 2>/dev/null || true)"
  if [ "$virtio_net_backend" = "tap" ] && [ -n "${NEMU_GUEST_TAP_GATEWAY:-}" ]; then
    virtio_net_neigh="$(ip neigh show "${NEMU_GUEST_TAP_GATEWAY}" dev "$virtio_net_iface" 2>/dev/null || true)"
    virtio_net_arp="$(grep -F "${NEMU_GUEST_TAP_GATEWAY}" /proc/net/arp 2>/dev/null || true)"
  else
    virtio_net_neigh="$(ip neigh show 10.0.2.2 dev "$virtio_net_iface" 2>/dev/null || true)"
    virtio_net_arp="$(grep -F '10.0.2.2' /proc/net/arp 2>/dev/null || true)"
  fi
else
  virtio_net_tx_packets1=""
  virtio_net_rx_packets1=""
  virtio_net_neigh=""
  virtio_net_arp=""
fi
echo "__NEMU_CHECK_VIRTIO_NET_TX_PACKETS_END__:$virtio_net_tx_packets1"
echo "__NEMU_CHECK_VIRTIO_NET_RX_PACKETS_END__:$virtio_net_rx_packets1"
echo "__NEMU_CHECK_VIRTIO_NET_NEIGH__:$virtio_net_neigh"
echo "__NEMU_CHECK_VIRTIO_NET_ARP__:$virtio_net_arp"

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
[ "$(virtio_feature_bit "$virtio_features" 12)" = "1" ] &&
  pass virtio-blk-feature-mq || fail virtio-blk-feature-mq
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

irq_total_table0="$(interrupts_table_sum)"
irq_serial0="$(interrupts_match_sum 'ttys0|serial|10000000')"
irq_virtio0="$(interrupts_match_sum 'virtio|vda|10001000')"
irq_visible0=$((irq_serial0 + irq_virtio0))
irq_total0="$irq_total_table0"
if [ "$irq_total0" -le 0 ] 2>/dev/null && [ "$irq_visible0" -gt 0 ] 2>/dev/null; then
  irq_total0="$irq_visible0"
fi
echo "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL__:$irq_total_table0"
echo "__NEMU_CHECK_IRQ_VISIBLE__:$irq_visible0"
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
irq_total_table1="$(interrupts_table_sum)"
irq_serial1="$(interrupts_match_sum 'ttys0|serial|10000000')"
irq_virtio1="$(interrupts_match_sum 'virtio|vda|10001000')"
irq_visible1=$((irq_serial1 + irq_virtio1))
irq_total1="$irq_total_table1"
if [ "$irq_total1" -le 0 ] 2>/dev/null && [ "$irq_visible1" -gt 0 ] 2>/dev/null; then
  irq_total1="$irq_visible1"
fi
echo "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL_GROW__:$irq_total_table0->$irq_total_table1"
echo "__NEMU_CHECK_IRQ_VISIBLE_GROW__:$irq_visible0->$irq_visible1"
echo "__NEMU_CHECK_INTERRUPTS_TOTAL_GROW__:$irq_total0->$irq_total1"
echo "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__:$irq_virtio0->$irq_virtio1"
[ "$irq_total1" -ge "$irq_total0" ] 2>/dev/null &&
  pass proc-interrupts-total-monotonic || fail proc-interrupts-total-monotonic
if [ "$irq_virtio1" -gt "$irq_virtio0" ] 2>/dev/null; then
  pass irq-virtio-blk-read-growth
else
  echo "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW_DIAG__:no-growth"
fi

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
inject_icmp_probe_payload "$LOG_DIR/guest-check.cmd"
inject_dhcp_probe_payload "$LOG_DIR/guest-check.cmd"
inject_dns_probe_payload "$LOG_DIR/guest-check.cmd"
inject_tcp_probe_payload "$LOG_DIR/guest-check.cmd"
inject_oomd_pressure_probe_payload "$LOG_DIR/guest-check.cmd"
inject_uart_rx_stress_commands "$LOG_DIR/guest-check.cmd"
build_guest_upload_commands "$LOG_DIR/guest-check.cmd" "$GUEST_UPLOAD_CMDS"

guest_check_start_seconds=$SECONDS
send_guest_commands "$INPUT_DELAY" "$INPUT_CHUNK_DELAY" "$GUEST_UPLOAD_CMDS"
wait_for_log_regex "^__NEMU_SYSTEMD_CHECK_DONE__ rc=[0-9]" "$CHECK_TIMEOUT"
guest_check_seconds=$((SECONDS - guest_check_start_seconds))

guest_done_rc="$(read_guest_done_rc)"
diag_stop_reached=0
if [ "$STOP_AFTER_SYSTEMCTL_RELOAD_DIAG" != "0" ] &&
   [ "$guest_done_rc" = "77" ] &&
   grep -qaF "__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__" "$CONSOLE_LOG"; then
  diag_stop_reached=1
fi
if grep -qaE "^__NEMU_CHECK_FAIL__:" "$CONSOLE_LOG"; then
  if [ "$diag_stop_reached" = "1" ]; then
    fail "diagnostic stop reached with guest check failure"
  fi
  fail "guest checks reported failure"
fi

if [ "$guest_done_rc" = "0" ]; then
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
  check_nemu_async_runtime
  check_nemu_net_runtime
  if [ -n "$RUN_ROOTFS_OVERLAY" ]; then
    rootfs_stat_after=$(stat -c '%s:%Y' "$RUN_ROOTFS" 2>/dev/null || echo missing)
    echo "[nemu-systemd-check] rootfs backing stat after: $rootfs_stat_after"
    if [ "$rootfs_stat_after" != "$ROOTFS_STAT_BEFORE" ]; then
      fail "rootfs backing changed despite overlay: $ROOTFS_STAT_BEFORE -> $rootfs_stat_after"
    fi
    echo "[nemu-systemd-check] PASS rootfs-backing-unchanged"
  fi
  total_seconds=$((SECONDS - host_start_seconds))
  check_console_clean || fail "console log contains fixed warning/error regression"
  check_efi_boot_path_context || fail "EFI message appeared without OpenSBI/DTB boot context"
  check_shutdown_watchdog_notify || fail "journald WATCHDOG notify failed outside clean poweroff"
  write_perf_log "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds"
  echo "[nemu-systemd-check] PASS"
elif [ "$diag_stop_reached" = "1" ]; then
  poweroff_seconds=0
  total_seconds=$((SECONDS - host_start_seconds))
  check_console_clean || fail "console log contains fixed warning/error regression"
  write_perf_log "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds"
  echo "[nemu-systemd-check] PASS diagnostic-stop systemctl-reload"
else
  fail "guest checks reported failure rc=$guest_done_rc"
fi
