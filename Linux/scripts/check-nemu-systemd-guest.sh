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
GUEST_UPLOAD_CMDS=${NEMU_SYSTEMD_GUEST_UPLOAD_CMDS:-"$LOG_DIR/guest-check-upload.cmd"}
GUEST_SCRIPT_PATH=${NEMU_SYSTEMD_GUEST_SCRIPT_PATH:-"/tmp/nemu-systemd-guest-check.sh"}
GUEST_SCRIPT_B64_PATH=${NEMU_SYSTEMD_GUEST_SCRIPT_B64_PATH:-"/tmp/nemu-systemd-guest-check.sh.b64"}

LINUX_IMAGE=${LINUX_IMAGE:-"$ENV_ROOT/src/linux/arch/riscv/boot/Image"}
RUN_FW=${RUN_FW:-"$ENV_ROOT/build/opensbi-nemu-rootfs/platform/generic/firmware/fw_jump.bin"}
RUN_DTB=${RUN_DTB:-"$LINUX_HOME/build/npc-rv64-nemu-rootfs.dtb"}
RUN_ROOTFS=${RUN_ROOTFS:-"$ENV_ROOT/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"}
RUN_ROOTFS_OVERLAY=${NEMU_SYSTEMD_ROOTFS_OVERLAY-"$LOG_DIR/rootfs-overlay.raw"}
ROOTFS_FLAVOR=${NEMU_SYSTEMD_ROOTFS_FLAVOR:-systemd-minimal}
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
ICMP_PROBE_ENABLE=${NEMU_SYSTEMD_ICMP_PROBE:-1}
DHCP_PROBE_SRC=${NEMU_SYSTEMD_DHCP_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-dhcp-probe.c"}
DHCP_PROBE_BIN=${NEMU_SYSTEMD_DHCP_PROBE_BIN:-"$LOG_DIR/nemu-systemd-dhcp-probe.riscv64"}
DHCP_PROBE_B64=${NEMU_SYSTEMD_DHCP_PROBE_B64:-"$LOG_DIR/nemu-systemd-dhcp-probe.b64"}
DHCP_PROBE_ENABLE=${NEMU_SYSTEMD_DHCP_PROBE:-1}
DNS_PROBE_SRC=${NEMU_SYSTEMD_DNS_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-dns-probe.c"}
DNS_PROBE_BIN=${NEMU_SYSTEMD_DNS_PROBE_BIN:-"$LOG_DIR/nemu-systemd-dns-probe.riscv64"}
DNS_PROBE_B64=${NEMU_SYSTEMD_DNS_PROBE_B64:-"$LOG_DIR/nemu-systemd-dns-probe.b64"}
DNS_PROBE_ENABLE=${NEMU_SYSTEMD_DNS_PROBE:-1}
TCP_PROBE_SRC=${NEMU_SYSTEMD_TCP_PROBE_SRC:-"$LINUX_HOME/tools/nemu-systemd-tcp-probe.c"}
TCP_PROBE_BIN=${NEMU_SYSTEMD_TCP_PROBE_BIN:-"$LOG_DIR/nemu-systemd-tcp-probe.riscv64"}
TCP_PROBE_B64=${NEMU_SYSTEMD_TCP_PROBE_B64:-"$LOG_DIR/nemu-systemd-tcp-probe.b64"}
TCP_PROBE_ENABLE=${NEMU_SYSTEMD_TCP_PROBE:-1}
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
  local tcp_segments tcp_replies tcp_http_requests tcp_http_head_requests tcp_http_not_found
  local tcp_http_apt_requests tcp_http_apt_deb_requests
  local tcp_http_large_requests tcp_http_segmented_responses tcp_http_response_segments
  local ctrl_commands ctrl_errors ctrl_rx_commands ctrl_rx_extra_commands
  local ctrl_mac_table_commands ctrl_mac_addr_commands ctrl_vlan_commands ctrl_announce_commands
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

  echo "[nemu-systemd-check] virtio-net runtime: tx=$tx_packets rx=$rx_packets errors=$tx_errors drops=$rx_drops pending=$rx_pending arp=$arp_req/$arp_rep icmp=$icmp_req/$icmp_rep dhcp=$dhcp_req/$dhcp_rep dns=$dns_req/$dns_rep tcp=$tcp_segments/$tcp_replies http=$tcp_http_requests head=$tcp_http_head_requests not_found=$tcp_http_not_found apt=$tcp_http_apt_requests apt_deb=$tcp_http_apt_deb_requests large=$tcp_http_large_requests segmented=$tcp_http_segmented_responses segments=$tcp_http_response_segments ctrl=$ctrl_commands/$ctrl_errors ctrl_rx=$ctrl_rx_commands ctrl_rx_extra=$ctrl_rx_extra_commands ctrl_mac_table=$ctrl_mac_table_commands ctrl_mac_addr=$ctrl_mac_addr_commands ctrl_vlan=$ctrl_vlan_commands ctrl_announce=$ctrl_announce_commands"
  if [ "$tx_packets" -gt 0 ] &&
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
       [ "$tcp_http_response_segments" -gt 0 ]; }; } &&
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
    printf 'boot_seconds\tguest_check_seconds\tpoweroff_seconds\ttotal_seconds\tsoak_seconds\tfs_stress_mib\tfs_tree_files\tprocess_loops\tuart_rx_stress_lines\tblock_parallel_jobs\tblock_job_mib\tnet_tcp_burst_loops\tinput_chunk_bytes\tinput_chunk_delay\tmax_cycles\trootfs_overlay\n'
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$boot_seconds" "$guest_check_seconds" "$poweroff_seconds" "$total_seconds" \
      "$SOAK_SECONDS" "$FS_STRESS_MIB" "$FS_TREE_FILES" "$PROCESS_LOOPS" \
      "$UART_RX_STRESS_LINES" "$BLOCK_PARALLEL_JOBS" "$BLOCK_JOB_MIB" \
      "$NET_TCP_BURST_LOOPS" "$INPUT_CHUNK_BYTES" "$INPUT_CHUNK_DELAY" "$MAX_CYCLES" \
      "${RUN_ROOTFS_OVERLAY:-disabled}"
  } >"$PERF_LOG"
  echo "[nemu-systemd-check] perf boot=${boot_seconds}s guest_check=${guest_check_seconds}s poweroff=${poweroff_seconds}s total=${total_seconds}s"
  echo "[nemu-systemd-check] perf log: $PERF_LOG"
}

build_guest_upload_commands() {
  local src_file=$1
  local dst_file=$2
  local script_sha script_bytes
  script_sha="$(sha256sum "$src_file" | awk '{print $1}')" ||
    fail "failed to hash guest check script"
  script_bytes="$(wc -c <"$src_file" | tr -d '[:space:]')" ||
    fail "failed to size guest check script"

  {
    printf 'stty -echo 2>/dev/null || true\n'
    printf 'PS1=; PS2=; PS4=; export PS1 PS2 PS4\n'
    printf 'echo "__NEMU_GUEST_UPLOAD_BEGIN__"\n'
    printf "cat > '%s' <<'__NEMU_GUEST_CHECK_B64__'\n" "$GUEST_SCRIPT_B64_PATH"
    base64 -w 76 "$src_file"
    printf '__NEMU_GUEST_CHECK_B64__\n'
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
require_nonnegative_decimal "NEMU_SYSTEMD_INPUT_DELAY" "$INPUT_DELAY"
require_nonnegative_decimal "NEMU_SYSTEMD_INPUT_CHUNK_DELAY" "$INPUT_CHUNK_DELAY"
require_uint "NEMU_SYSTEMD_APT_INSTALL_DIAG" "$APT_INSTALL_DIAG"
require_uint "NEMU_SYSTEMD_APT_INSTALL_ACTUAL" "$APT_INSTALL_ACTUAL"
require_uint "NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT" "$APT_INSTALL_DIAG_TIMEOUT"
require_uint "NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT" "$APT_REMOVE_DIAG_TIMEOUT"
require_uint "NEMU_SYSTEMD_SYSCALL_PROBE" "$SYSCALL_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_ICMP_PROBE" "$ICMP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_DHCP_PROBE" "$DHCP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_DNS_PROBE" "$DNS_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_TCP_PROBE" "$TCP_PROBE_ENABLE"
require_uint "NEMU_SYSTEMD_NET_TCP_BURST_LOOPS" "$NET_TCP_BURST_LOOPS"
require_uint "NEMU_SYSTEMD_POWEROFF" "$POWEROFF_ENABLE"
require_uint "NEMU_SYSTEMD_POWEROFF_TIMEOUT" "$POWEROFF_TIMEOUT"
require_uint "rootfs image size" "$ROOTFS_BYTES"
[ "$SYSTEMD_RELOAD_TIMEOUT" -gt 0 ] ||
  fail "NEMU_SYSTEMD_RELOAD_TIMEOUT must be positive: $SYSTEMD_RELOAD_TIMEOUT"
[ "$NET_TCP_BURST_LOOPS" -gt 0 ] ||
  fail "NEMU_SYSTEMD_NET_TCP_BURST_LOOPS must be positive: $NET_TCP_BURST_LOOPS"

mkdir -p "$LOG_DIR"
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG" "$LOG_FILE" "$PERF_LOG" \
  "$LOG_DIR/guest-check.cmd" "$GUEST_UPLOAD_CMDS" \
  "$SYSCALL_PROBE_BIN" "$SYSCALL_PROBE_B64" \
  "$ICMP_PROBE_BIN" "$ICMP_PROBE_B64" \
  "$DHCP_PROBE_BIN" "$DHCP_PROBE_B64" \
  "$DNS_PROBE_BIN" "$DNS_PROBE_B64" \
  "$TCP_PROBE_BIN" "$TCP_PROBE_B64" "$VDA_HASH_EXPECT"
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
build_vda_hash_expectations

echo "[nemu-systemd-check] log dir: $LOG_DIR"
echo "[nemu-systemd-check] serial fifo: $SERIAL_FIFO"
echo "[nemu-systemd-check] guest upload commands: $GUEST_UPLOAD_CMDS"
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
echo "[nemu-systemd-check] serial input model: FIFO/stdin bytes -> NEMU SerialPort staging -> 16550 RX FIFO -> Linux ttyS0"
echo "[nemu-systemd-check] syscall probe: $SYSCALL_PROBE_ENABLE"
echo "[nemu-systemd-check] ICMP probe: $ICMP_PROBE_ENABLE"
echo "[nemu-systemd-check] DHCP probe: $DHCP_PROBE_ENABLE"
echo "[nemu-systemd-check] DNS probe: $DNS_PROBE_ENABLE"
echo "[nemu-systemd-check] TCP probe: $TCP_PROBE_ENABLE"
echo "[nemu-systemd-check] TCP burst loops: $NET_TCP_BURST_LOOPS"
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
NEMU_SERIAL_FIFO="$SERIAL_FIFO" NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b \
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
  printf 'NEMU_GUEST_APT_INSTALL_DIAG=%s\n' "$APT_INSTALL_DIAG"
  printf 'NEMU_GUEST_APT_INSTALL_ACTUAL=%s\n' "$APT_INSTALL_ACTUAL"
  printf 'NEMU_GUEST_APT_INSTALL_DIAG_TIMEOUT=%s\n' "$APT_INSTALL_DIAG_TIMEOUT"
  printf 'NEMU_GUEST_APT_REMOVE_DIAG_TIMEOUT=%s\n' "$APT_REMOVE_DIAG_TIMEOUT"
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
    /usr/bin/dpkg \
    /usr/bin/dpkg-query \
    /usr/bin/sudo \
    /usr/bin/man \
    /usr/bin/locale \
    /usr/bin/curl \
    /usr/bin/wget \
    /usr/bin/ssh \
    /usr/bin/ssh-keygen \
    /usr/bin/dbclient \
    /usr/bin/dropbearconvert \
    /usr/bin/dropbearkey \
    /usr/sbin/sshd \
    /usr/sbin/dropbear \
    /usr/sbin/cron \
    /usr/sbin/rsyslogd; do
    full_label=${full_path##*/}
    if [ -x "$full_path" ]; then
      pass "full-userland-command-$full_label"
    else
      full_userland_fail "full-userland-command-$full_label"
    fi
  done

  apt_version="$(apt-get --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_APT_VERSION__:$apt_version"
  if echo "$apt_version" | grep -Eq '^apt [0-9]+'; then
    pass full-userland-apt-version
  else
    full_userland_fail full-userland-apt-version
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

  for full_package in ubuntu-standard openssh-server curl wget dropbear-bin rsyslog cron systemd-timesyncd; do
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
    "openssh-server:/usr/sbin/sshd" \
    "dropbear-bin:/usr/bin/dbclient" \
    "dropbear-bin:/usr/sbin/dropbear" \
    "rsyslog:/usr/sbin/rsyslogd" \
    "cron:/usr/sbin/cron"; do
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
  apt_policy_output="$(apt-cache policy ubuntu-standard openssh-server curl wget dropbear-bin 2>&1)" ||
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

  timedatectl_version="$(timedatectl --version 2>/dev/null | sed -n '1p' || true)"
  echo "__NEMU_CHECK_FULL_TIMEDATECTL_VERSION__:$timedatectl_version"
  if echo "$timedatectl_version" | grep -Eq '^systemd [0-9]+'; then
    pass full-userland-timedatectl-version
  else
    full_userland_fail full-userland-timedatectl-version
  fi

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
  else
    full_userland_fail full-userland-ssh-test-user
    full_userland_fail full-userland-ssh-keygen
    full_userland_fail full-userland-ssh-local-login
  fi
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
  if systemctl start rsyslog.service >/dev/null 2>&1 &&
     systemctl --quiet is-active rsyslog.service; then
    pass full-userland-rsyslog-active
  else
    systemctl status --no-pager syslog.socket 2>/dev/null || true
    systemctl status --no-pager rsyslog.service 2>/dev/null || true
    full_userland_fail full-userland-rsyslog-active
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
    apt-get -s install -y --no-install-recommends nemu-hostless-meta:riscv64 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
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
    apt-get -s install -y --no-install-recommends nemu-hostless-meta:riscv64 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
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
    "$apt_diag_archives"/nemu-hostless-meta_1.0_riscv64.deb
  apt_direct_download_log="$apt_diag_dir/empty-status-download-only.log"
  apt_direct_download_rc=0
  apt_direct_download_sha256=
  apt_direct_download_meta_sha256=
  apt_direct_download_targets="nemu-hostless-hello:riscv64 nemu-hostless-meta:riscv64"
  DEBIAN_FRONTEND=noninteractive timeout "${apt_diag_timeout}s" \
    apt-get --download-only install -y --no-install-recommends \
      nemu-hostless-hello:riscv64 nemu-hostless-meta:riscv64 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
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
     [ "$apt_direct_download_sha256" = "073216e022c5d7f98d7d07279921a2576920784a0895d870c5f962cb07647187" ] &&
     [ "$apt_direct_download_meta_sha256" = "b40a91a80a056423051d440ef614d76d36666f88b29ed8a2a86aa76716e3d0e5" ]; then
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
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__:nemu-hostless-meta"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__:empty-status-real-dpkg"
  (
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nemu-hostless-meta:riscv64 \
      -o "Dir::Etc::sourcelist=$apt_diag_source" \
      -o "Dir::Etc::sourceparts=-" \
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
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_APT_STATE__:installed-target-status-real-dpkg"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_STATUS_BEGIN__"
  sed -n '1,120p' "$apt_direct_remove_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_STATUS_END__"
  if [ "$apt_direct_install_effect_ok" = "1" ]; then
    (
      DEBIAN_FRONTEND=noninteractive \
      apt-get remove -y nemu-hostless-meta:riscv64 \
        -o "Dir::Etc::sourcelist=$apt_diag_source" \
        -o "Dir::Etc::sourceparts=-" \
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
    echo "skip remove because install effect was not complete" >"$apt_direct_remove_log"
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
     [ "$apt_direct_remove_meta_prerm" = "prerm from NEMU hostless meta" ] &&
     [ "$apt_direct_remove_meta_postrm" = "postrm from NEMU hostless meta" ] &&
     [ "$apt_direct_remove_meta_status" = "deinstall ok config-files 1.0 riscv64" ] &&
     [ -z "$apt_direct_remove_meta_message" ] &&
     [ "$apt_direct_remove_hello_status" = "install ok installed 1.0 riscv64" ] &&
     [ "$apt_direct_remove_hello_message" = "hello from NEMU hostless apt" ]; then
    pass full-userland-apt-direct-full-status-remove
  elif [ "$apt_direct_remove_rc" = "124" ] &&
       [ "$apt_direct_remove_meta_prerm" = "prerm from NEMU hostless meta" ] &&
       [ "$apt_direct_remove_meta_postrm" = "postrm from NEMU hostless meta" ] &&
       [ -z "$apt_direct_remove_meta_status" ] &&
       [ -z "$apt_direct_remove_meta_message" ] &&
       [ "$apt_direct_remove_hello_status" = "install ok installed 1.0 riscv64" ] &&
       [ "$apt_direct_remove_hello_message" = "hello from NEMU hostless apt" ]; then
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
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_APT_STATE__:config-files-target-status-real-dpkg"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_STATUS_BEGIN__"
  sed -n '1,120p' "$apt_direct_purge_status" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_STATUS_END__"
  if [ "$apt_direct_remove_rc" = "0" ]; then
    (
      DEBIAN_FRONTEND=noninteractive \
      apt-get purge -y nemu-hostless-meta:riscv64 \
        -o "Dir::Etc::sourcelist=$apt_diag_source" \
        -o "Dir::Etc::sourceparts=-" \
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
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_RC__:$apt_direct_purge_rc"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_PURGE__:$apt_direct_purge_meta_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_AFTER_PURGE__:$apt_direct_purge_meta_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__:$apt_direct_purge_hello_status"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__:$apt_direct_purge_hello_message"
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_BEGIN__"
  sed -n '1,180p' "$apt_direct_purge_log" 2>/dev/null || true
  echo "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_END__"
  if [ "$apt_direct_purge_rc" = "0" ] &&
     [ -z "$apt_direct_purge_meta_status" ] &&
     [ -z "$apt_direct_purge_meta_message" ] &&
     [ "$apt_direct_purge_hello_status" = "install ok installed 1.0 riscv64" ] &&
     [ "$apt_direct_purge_hello_message" = "hello from NEMU hostless apt" ]; then
    pass full-userland-apt-direct-full-status-purge
  else
    fail full-userland-apt-direct-full-status-purge
  fi
}

check_full_userland_network_clients() {
  if [ "${NEMU_GUEST_ROOTFS_FLAVOR:-systemd-minimal}" != "full" ]; then
    pass full-userland-network-clients-skip
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
  apt_hostless_log="$apt_hostless_root/update.log"
  rm -rf "$apt_hostless_root"
  mkdir -p "$apt_hostless_root/lists/partial" "$apt_hostless_root/cache/archives/partial"
  printf 'deb [trusted=yes arch=riscv64] http://nemu.local/ubuntu jammy main\n' > "$apt_hostless_source"
  apt_hostless_rc=0
  timeout 240s apt-get update \
    -o "Dir::Etc::sourcelist=$apt_hostless_source" \
    -o "Dir::Etc::sourceparts=-" \
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
     grep -q 'http://nemu.local/ubuntu jammy Release' "$apt_hostless_log" &&
     grep -q 'Reading package lists' "$apt_hostless_log"; then
    pass full-userland-apt-hostless-update
  else
    fail full-userland-apt-hostless-update
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
      timeout 240s apt-get download nemu-hostless-hello:riscv64 \
        -o "Dir::Etc::sourcelist=$apt_hostless_source" \
        -o "Dir::Etc::sourceparts=-" \
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
       [ "$apt_hostless_deb_sha256" = "073216e022c5d7f98d7d07279921a2576920784a0895d870c5f962cb07647187" ]; then
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
  if [ "$reload_rc" -ne 0 ]; then
    case "$reload_rc:$reload_output" in
      124:*|*'Connection timed out'*|*'Timed out'*|*'timed out'*)
        echo "__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__:$reload_unit:$reload_goal"
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

check_full_userland_runtime

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
    if [ "${NEMU_GUEST_DHCP_PROBE:-1}" != "0" ]; then
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
      echo "__NEMU_CHECK_VIRTIO_NET_DHCP_SKIP__"
    fi
    ip addr replace 10.0.2.15/24 dev "$virtio_net_iface" 2>/dev/null || true
    virtio_net_ipv4="$(ip -o -4 addr show dev "$virtio_net_iface" 2>/dev/null |
      awk '$4 == "10.0.2.15/24" { print $4; exit }')"
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
[ "$virtio_net_ipv4" = "10.0.2.15/24" ] &&
  pass virtio-net-ipv4-static || fail virtio-net-ipv4-static
[ "$virtio_net_speed" = "1000" ] &&
  pass virtio-net-speed || fail virtio-net-speed
[ "$virtio_net_duplex" = "full" ] &&
  pass virtio-net-duplex || fail virtio-net-duplex

if [ "${NEMU_GUEST_DNS_PROBE:-1}" != "0" ]; then
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
  echo "__NEMU_CHECK_VIRTIO_NET_DNS_SKIP__"
fi

virtio_net_tx_packets0=""
virtio_net_rx_packets0=""
virtio_net_route=""
if [ -n "$virtio_net_iface" ]; then
  virtio_net_tx_packets0="$(cat "/sys/class/net/$virtio_net_iface/statistics/tx_packets" 2>/dev/null || true)"
  virtio_net_rx_packets0="$(cat "/sys/class/net/$virtio_net_iface/statistics/rx_packets" 2>/dev/null || true)"
  virtio_net_route="$(ip route get 10.0.2.2 2>/dev/null || true)"
fi
echo "__NEMU_CHECK_VIRTIO_NET_TX_PACKETS_BEGIN__:$virtio_net_tx_packets0"
echo "__NEMU_CHECK_VIRTIO_NET_RX_PACKETS_BEGIN__:$virtio_net_rx_packets0"
echo "__NEMU_CHECK_VIRTIO_NET_ROUTE__:$virtio_net_route"

if [ "${NEMU_GUEST_TCP_PROBE:-1}" != "0" ]; then
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
  echo "__NEMU_CHECK_VIRTIO_NET_TCP_SKIP__"
fi

check_full_userland_network_clients

if [ "${NEMU_GUEST_ICMP_PROBE:-1}" != "0" ]; then
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
  echo "__NEMU_CHECK_VIRTIO_NET_ICMP_SKIP__"
fi
if [ -n "$virtio_net_iface" ]; then
  virtio_net_tx_packets1="$(cat "/sys/class/net/$virtio_net_iface/statistics/tx_packets" 2>/dev/null || true)"
  virtio_net_rx_packets1="$(cat "/sys/class/net/$virtio_net_iface/statistics/rx_packets" 2>/dev/null || true)"
  virtio_net_neigh="$(ip neigh show 10.0.2.2 dev "$virtio_net_iface" 2>/dev/null || true)"
  virtio_net_arp="$(grep -F '10.0.2.2' /proc/net/arp 2>/dev/null || true)"
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
inject_uart_rx_stress_commands "$LOG_DIR/guest-check.cmd"
build_guest_upload_commands "$LOG_DIR/guest-check.cmd" "$GUEST_UPLOAD_CMDS"

guest_check_start_seconds=$SECONDS
send_guest_commands "$INPUT_DELAY" "$INPUT_CHUNK_DELAY" "$GUEST_UPLOAD_CMDS"
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
else
  fail "guest checks reported failure"
fi
