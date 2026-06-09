NEMU_GUEST_SOAK_SECONDS=0
NEMU_GUEST_FS_STRESS_MIB=1
NEMU_GUEST_FS_TREE_FILES=8
NEMU_GUEST_PROCESS_LOOPS=4
NEMU_GUEST_UART_RX_STRESS_LINES=64
NEMU_GUEST_BLOCK_PARALLEL_JOBS=1
NEMU_GUEST_BLOCK_JOB_MIB=1
NEMU_GUEST_SYSTEMD_RELOAD_TIMEOUT=180
NEMU_GUEST_ROOTFS_BYTES=2147483648
NEMU_GUEST_SYSCALL_PROBE=1
NEMU_GUEST_ICMP_PROBE=1
NEMU_GUEST_DHCP_PROBE=1
NEMU_GUEST_POWEROFF=1
NEMU_GUEST_VDA_HASH_WINDOW_BYTES=65536
NEMU_GUEST_VDA_HASH_EXPECT_FILE=/tmp/nemu-vda-direct-read-sha256.tsv
cat > "$NEMU_GUEST_VDA_HASH_EXPECT_FILE" <<'__NEMU_VDA_HASH_EXPECT__'
2147418112:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31
__NEMU_VDA_HASH_EXPECT__
echo __NEMU_SYSTEMD_CHECK_BEGIN__
check_fail=0
pass() { echo "__NEMU_CHECK_PASS__:$1"; }
fail() { echo "__NEMU_CHECK_FAIL__:$1"; check_fail=1; }
uart_rx_stress_count=0
uart_rx_stress_expect=64
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0000"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0001"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0002"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0003"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0004"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0005"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0006"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0007"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0008"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0009"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0010"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0011"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0012"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0013"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0014"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0015"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0016"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0017"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0018"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0019"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0020"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0021"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0022"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0023"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0024"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0025"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0026"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0027"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0028"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0029"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0030"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0031"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0032"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0033"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0034"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0035"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0036"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0037"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0038"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0039"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0040"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0041"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0042"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0043"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0044"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0045"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0046"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0047"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0048"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0049"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0050"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0051"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0052"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0053"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0054"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0055"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0056"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0057"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0058"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0059"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0060"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0061"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0062"
uart_rx_stress_count=$((uart_rx_stress_count + 1)); echo "__NEMU_UART_RX_STRESS_LINE__:0063"
echo "__NEMU_UART_RX_STRESS_COUNT__:$uart_rx_stress_count/$uart_rx_stress_expect"
[ "$uart_rx_stress_count" = "$uart_rx_stress_expect" ] && pass uart-rx-command-burst || fail uart-rx-command-burst
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
if [ -n "$virtio_net_dev" ]; then
  virtio_net_driver="$(basename "$(readlink -f "$virtio_net_dev/driver" 2>/dev/null || true)")"
fi
echo "__NEMU_CHECK_VIRTIO_NET_DRIVER__:$virtio_net_driver"
[ "$virtio_net_driver" = "virtio_net" ] &&
  pass virtio-net-driver || fail virtio-net-driver

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
if [ -n "$virtio_net_iface" ]; then
  virtio_net_mac="$(cat "/sys/class/net/$virtio_net_iface/address" 2>/dev/null || true)"
  virtio_net_carrier="$(cat "/sys/class/net/$virtio_net_iface/carrier" 2>/dev/null || true)"
fi
echo "__NEMU_CHECK_VIRTIO_NET_MAC__:$virtio_net_mac"
echo "__NEMU_CHECK_VIRTIO_NET_CARRIER__:$virtio_net_carrier"
[ "$virtio_net_mac" = "52:54:00:12:34:56" ] &&
  pass virtio-net-mac || fail virtio-net-mac

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
f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAfA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK
AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA
AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA
AAAAAAADAABwBAAAADUgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFMAAAAAAAAAAAAAAAAAAAABAAAA
AAAAAAEAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+BkAAAAAAAD4GQAAAAAAAAAQAAAA
AAAAAQAAAAYAAAAIHQAAAAAAAAgtAAAAAAAACC0AAAAAAAAAAwAAAAAAAAgDAAAAAAAAABAAAAAA
AAACAAAABgAAACAdAAAAAAAAIC0AAAAAAAAgLQAAAAAAAAACAAAAAAAAAAIAAAAAAAAIAAAAAAAA
AAQAAAAEAAAAlAIAAAAAAACUAgAAAAAAAJQCAAAAAAAARAAAAAAAAABEAAAAAAAAAAQAAAAAAAAA
UOV0ZAQAAABkFwAAAAAAAGQXAAAAAAAAZBcAAAAAAABUAAAAAAAAAFQAAAAAAAAABAAAAAAAAABR
5XRkBgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAFLl
dGQEAAAACB0AAAAAAAAILQAAAAAAAAgtAAAAAAAA+AIAAAAAAAD4AgAAAAAAAAEAAAAAAAAAL2xp
Yi9sZC1saW51eC1yaXNjdjY0LWxwNjRkLnNvLjEAAAAABAAAABQAAAADAAAAR05VAC464UN/BflR
MKlxEBrCdEu+5//5BAAAABAAAAABAAAAR05VAAAAAAAEAAAADwAAAAAAAAACAAAAGgAAAAEAAAAG
AAAAAAAAAAAEACAaAAAAAAAAAGt/mnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMA
DABgCwAAAAAAAAAAAAAAAAAAXgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAEgEAACAAAAAAAAAAAAAA
AAAAAAAAAAAAUgAAABIAAAAAAAAAAAAAAAAAAAAAAAAARAAAABIAAAAAAAAAAAAAAAAAAAAAAAAA
CgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAKwAAABIAAAAAAAAAAAAAAAAAAAAAAAAAswAAABIAAAAA
AAAAAAAAAAAAAAAAAAAAGgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAPQAAABIAAAAAAAAAAAAAAAAA
AAAAAAAAcAAAABIAAAAAAAAAAAAAAAAAAAAAAAAArAAAABIAAAAAAAAAAAAAAAAAAAAAAAAASwAA
ABIAAAAAAAAAAAAAAAAAAAAAAAAAxAAAABEAAAAAAAAAAAAAAAAAAAAAAAAAkAAAABIAAAAAAAAA
AAAAAAAAAAAAAAAApgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAAQAAABIAAAAAAAAAAAAAAAAAAAAA
AAAAdwAAABIAAAAAAAAAAAAAAAAAAAAAAAAAFQAAABIAAAAAAAAAAAAAAAAAAAAAAAAAoAAAABIA
AAAAAAAAAAAAAAAAAAAAAAAAOAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAgQAAACIAAAAAAAAAAAAA
AAAAAAAAAAAALgEAACAAAAAAAAAAAAAAAAAAAAAAAAAAVwAAABEAAAAAAAAAAAAAAAAAAAAAAAAA
mQAAABIAAAAAAAAAAAAAAAAAAAAAAAAAawAAABIADABgCwAAAAAAABwEAAAAAAAAAHNucHJpbnRm
AHNldHNvY2tvcHQAcHV0cwBfX3N0YWNrX2Noa19mYWlsAF9fcHJpbnRmX2NoawBiaW5kAGZmbHVz
aABzb2NrZXQAc3RybGVuAHJlY3YAc3Rkb3V0AF9fbGliY19zdGFydF9tYWluAHNlbmR0bwBpbmV0
X250b3AAX19jeGFfZmluYWxpemUAc3RyZXJyb3IAbWVtc2V0AGlvY3RsAGNsb3NlAG1lbWNweQBf
X2Vycm5vX2xvY2F0aW9uAF9fc3RhY2tfY2hrX2d1YXJkAGxpYmMuc28uNgBsZC1saW51eC1yaXNj
djY0LWxwNjRkLnNvLjEAR0xJQkNfMi4yNwBHTElCQ18yLjM0AF9JVE1fZGVyZWdpc3RlclRNQ2xv
bmVUYWJsZQBfSVRNX3JlZ2lzdGVyVE1DbG9uZVRhYmxlAAAAAAACAAEAAwADAAMAAwADAAMAAwAD
AAMAAwAEAAMAAwADAAMAAwADAAMAAwABAAMAAwABAAAAAQABAOAAAAAQAAAAIAAAAIeRlgYAAAQA
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
AAgbFoUBG1eFAJOGBvB1j9GPImTZjxsVhQA3B/8AeY1djQElQQGCgAEAAgAAAAAAX19ORU1VX0RI
Q1BfUFJPQkVfRkFJTF9fOiVzOiVzCgBzZW5kdG8AAAAAAAAAAAAAc2hvcnQtd3JpdGUAAAAAAHJl
Y3YAAAAAbWlzc2luZwBzZXJ2ZXItaWQAAAAAAAAAZXRoMAAAAABzb2NrZXQAAHNldHNvY2tvcHQt
YnJvYWRjYXN0AAAAAHNldHNvY2tvcHQtYmluZC1kZXZpY2UAAHNldHNvY2tvcHQtdGltZW91dAAA
AAAAAGJpbmQAAAAAJXMAAAAAAABpb2N0bC1tYWMAAAAAAAAAcGFja2V0LWJ1aWxkAAAAAGRpc2Nv
dmVyAAAAAAAAAABfX05FTVVfREhDUF9QUk9CRV9UWF9fOmRpc2NvdmVyOiVzCgAAAAAAX19ORU1V
X0RIQ1BfUFJPQkVfT0ZGRVJfXzolczolcwoAAAAAAAAAAHJlcXVlc3QAX19ORU1VX0RIQ1BfUFJP
QkVfVFhfXzpyZXF1ZXN0OiVzCgAAAAAAAF9fTkVNVV9ESENQX1BST0JFX0FDS19fOiVzOiVzCgAA
bWlzbWF0Y2gAAAAAAAAAAGFjawAAAAAAX19ORU1VX0RIQ1BfUFJPQkVfUEFTU19fOmRoY3AtbGVh
c2UAARsDO1AAAAAJAAAA/PP//7QBAAAY+P//aAAAAPz4//98AAAALvn//6AAAABc+f//wAAAAN75
///sAAAANvr//wABAABS/P//fAEAAPL9//9sAgAAEAAAAAAAAAADelIAAXwBARsNAgAQAAAAGAAA
AKj3//8iAAAAAAcBACAAAAAsAAAAePj//zIAAAAAQg4gRogEiQaBAmLBQshCyUIOABwAAABQAAAA
hvj//y4AAAAAQg4QRIECiARgwULIRA4AKAAAAHAAAACU+P//ggAAAABCDkBIiQZciASBAgJCCsFC
yELJQg4AQgsAAAAQAAAAnAAAAOr4//9YAAAAAAAAAHgAAACwAAAALvn//xwCAAAARA6ACUSWEGyI
BIkGkgiTCpQMlQ6XEpgUgQICopkWmhh62UTaasFEyETJRNJE00TURNVE1kTXRNhEDgBCDoAJgQKI
BIkGkgiTCpQMlQ6WEJcSmBSZFpoYAnIK2UTaSAtk2UTaSpkWmhgAAAA0AAAALAEAAM76//+gAQAA
AEIOUEKSCE6JBlSBAogEkwpElAwC6grBQshCyULSQtNC1EIOAEILALQAAABkAQAAQPL//xwEAAAA
RA6wBkSSCGCTCoECiARkiQYCtpQMlQ54lhACPpcSTJgUmRYDHAHWRNdE2ETZRNRE1WzBRMhE0kTT
RslEDgBCDrAGgQKIBJIIkwpUyETBRNJE00wOAEIOsAaBAogEiQaSCJMKAkKUDJUOlhBK1ETVRNZY
lAyVDmaWEJcSmBSZFlYK1ETVRNZE10TYRNlCC1jJ1NXW19jZRIkGWJQMlQ6WEJcSmBSZFgAgAAAA
HAIAAH77//8yAAAAAEIOEEiIAkIMCABSyAwCEFIOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAA1gAA
AAAAAAABAAAAAAAAAOAAAAAAAAAAIAAAAAAAAAAILQAAAAAAACEAAAAAAAAACAAAAAAAAAAZAAAA
AAAAABAtAAAAAAAAGwAAAAAAAAAIAAAAAAAAABoAAAAAAAAAGC0AAAAAAAAcAAAAAAAAAAgAAAAA
AAAA9f7/bwAAAADYAgAAAAAAAAUAAAAAAAAAiAUAAAAAAAAGAAAAAAAAAAADAAAAAAAACgAAAAAA
AABIAQAAAAAAAAsAAAAAAAAAGAAAAAAAAAAVAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAgLwAAAAAA
AAIAAAAAAAAAyAEAAAAAAAAUAAAAAAAAAAcAAAAAAAAAFwAAAAAAAABICAAAAAAAAAcAAAAAAAAA
WAcAAAAAAAAIAAAAAAAAALgCAAAAAAAACQAAAAAAAAAYAAAAAAAAAB4AAAAAAAAACAAAAAAAAAD7
//9vAAAAAAEAAAgAAAAA/v//bwAAAAAIBwAAAAAAAP///28AAAAAAgAAAAAAAADw//9vAAAAANAG
AAAAAAAA+f//bwAAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////8AAAAA
AAAAABAKAAAAAAAAEAoAAAAAAAAQCgAAAAAAABAKAAAAAAAAEAoAAAAAAAAQCgAAAAAAABAKAAAA
AAAAEAoAAAAAAAAQCgAAAAAAABAKAAAAAAAAEAoAAAAAAAAQCgAAAAAAABAKAAAAAAAAEAoAAAAA
AAAQCgAAAAAAABAKAAAAAAAAEAoAAAAAAAAQCgAAAAAAABAKAAAAAAAAIC0AAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEdDQzogKFVi
dW50dSAxMy4zLjAtNnVidW50dTJ+MjQuMDQuMSkgMTMuMy4wAEFSAAAAcmlzY3YAAUgAAAAEEAVy
djY0aTJwMV9tMnAwX2EycDFfZjJwMl9kMnAyX2MycDBfemljc3IycDBfemlmZW5jZWkycDBfem1t
dWwxcDAAAC5zaHN0cnRhYgAuaW50ZXJwAC5ub3RlLmdudS5idWlsZC1pZAAubm90ZS5BQkktdGFn
AC5nbnUuaGFzaAAuZHluc3ltAC5keW5zdHIALmdudS52ZXJzaW9uAC5nbnUudmVyc2lvbl9yAC5y
ZWxhLmR5bgAucmVsYS5wbHQALnRleHQALnJvZGF0YQAuZWhfZnJhbWVfaGRyAC5laF9mcmFtZQAu
cHJlaW5pdF9hcnJheQAuaW5pdF9hcnJheQAuZmluaV9hcnJheQAuZHluYW1pYwAuZ290AC5kYXRh
AC5ic3MALmNvbW1lbnQALnJpc2N2LmF0dHJpYnV0ZXMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALAAAAAQAAAAIAAAAAAAAA
cAIAAAAAAABwAgAAAAAAACEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAEwAAAAcAAAAC
AAAAAAAAAJQCAAAAAAAAlAIAAAAAAAAkAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAACYA
AAAHAAAAAgAAAAAAAAC4AgAAAAAAALgCAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAA
AAAAAAA0AAAA9v//bwIAAAAAAAAA2AIAAAAAAADYAgAAAAAAACQAAAAAAAAABQAAAAAAAAAIAAAA
AAAAAAAAAAAAAAAAPgAAAAsAAAACAAAAAAAAAAADAAAAAAAAAAMAAAAAAACIAgAAAAAAAAYAAAAC
AAAACAAAAAAAAAAYAAAAAAAAAEYAAAADAAAAAgAAAAAAAACIBQAAAAAAAIgFAAAAAAAASAEAAAAA
AAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAABOAAAA////bwIAAAAAAAAA0AYAAAAAAADQBgAAAAAA
ADYAAAAAAAAABQAAAAAAAAACAAAAAAAAAAIAAAAAAAAAWwAAAP7//28CAAAAAAAAAAgHAAAAAAAA
CAcAAAAAAABQAAAAAAAAAAYAAAACAAAACAAAAAAAAAAAAAAAAAAAAGoAAAAEAAAAAgAAAAAAAABY
BwAAAAAAAFgHAAAAAAAA8AAAAAAAAAAFAAAAAAAAAAgAAAAAAAAAGAAAAAAAAAB0AAAABAAAAEIA
AAAAAAAASAgAAAAAAABICAAAAAAAAMgBAAAAAAAABQAAABQAAAAIAAAAAAAAABgAAAAAAAAAeQAA
AAEAAAAGAAAAAAAAABAKAAAAAAAAEAoAAAAAAABQAQAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAA
AAAAAH4AAAABAAAABgAAAAAAAABgCwAAAAAAAGALAAAAAAAAKAoAAAAAAAAAAAAAAAAAAAQAAAAA
AAAAAAAAAAAAAACEAAAAAQAAAAIAAAAAAAAAiBUAAAAAAACIFQAAAAAAANwBAAAAAAAAAAAAAAAA
AAAIAAAAAAAAAAAAAAAAAAAAjAAAAAEAAAACAAAAAAAAAGQXAAAAAAAAZBcAAAAAAABUAAAAAAAA
AAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAJoAAAABAAAAAgAAAAAAAAC4FwAAAAAAALgXAAAAAAAA
QAIAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAACkAAAAEAAAAAMAAAAAAAAACC0AAAAAAAAI
HQAAAAAAAAgAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAswAAAA4AAAADAAAAAAAAABAt
AAAAAAAAEB0AAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAL8AAAAPAAAAAwAA
AAAAAAAYLQAAAAAAABgdAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAAAAAAADLAAAA
BgAAAAMAAAAAAAAAIC0AAAAAAAAgHQAAAAAAAAACAAAAAAAABgAAAAAAAAAIAAAAAAAAABAAAAAA
AAAA1AAAAAEAAAADAAAAAAAAACAvAAAAAAAAIB8AAAAAAADgAAAAAAAAAAAAAAAAAAAACAAAAAAA
AAAIAAAAAAAAANkAAAABAAAAAwAAAAAAAAAAMAAAAAAAAAAgAAAAAAAACAAAAAAAAAAAAAAAAAAA
AAgAAAAAAAAAAAAAAAAAAADfAAAACAAAAAMAAAAAAAAACDAAAAAAAAAIIAAAAAAAAAgAAAAAAAAA
AAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA5AAAAAEAAAAwAAAAAAAAAAAAAAAAAAAACCAAAAAAAAAt
AAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAO0AAAADAABwAAAAAAAAAAAAAAAAAAAAADUg
AAAAAAAAUwAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAwAAAAAAAAAAAAAAAAAA
AAAAAACIIAAAAAAAAP8AAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA
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
  fi
else
  fail iproute2-present
fi
echo "__NEMU_CHECK_VIRTIO_NET_IPV4__:$virtio_net_ipv4"
echo "__NEMU_CHECK_VIRTIO_NET_OPERSTATE__:$virtio_net_operstate"
echo "__NEMU_CHECK_VIRTIO_NET_CARRIER_AFTER_UP__:$virtio_net_carrier_up"
[ "$virtio_net_ipv4" = "10.0.2.15/24" ] &&
  pass virtio-net-ipv4-static || fail virtio-net-ipv4-static

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

if [ "${NEMU_GUEST_ICMP_PROBE:-1}" != "0" ]; then
  icmp_probe_b64="$check_dir/icmp-probe.b64"
  icmp_probe_bin="$check_dir/icmp-probe"
  mkdir -p "$check_dir"
  cat > "$icmp_probe_b64" <<'__NEMU_ICMP_PROBE_B64__'
f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK
AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA
AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA
AAAAAAADAABwBAAAADUgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFMAAAAAAAAAAAAAAAAAAAABAAAA
AAAAAAEAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA3BEAAAAAAADcEQAAAAAAAAAQAAAA
AAAAAQAAAAYAAAAgHQAAAAAAACAtAAAAAAAAIC0AAAAAAADoAgAAAAAAAPACAAAAAAAAABAAAAAA
AAACAAAABgAAADgdAAAAAAAAOC0AAAAAAAA4LQAAAAAAAAACAAAAAAAAAAIAAAAAAAAIAAAAAAAA
AAQAAAAEAAAAlAIAAAAAAACUAgAAAAAAAJQCAAAAAAAARAAAAAAAAABEAAAAAAAAAAQAAAAAAAAA
UOV0ZAQAAADoEAAAAAAAAOgQAAAAAAAA6BAAAAAAAAAkAAAAAAAAACQAAAAAAAAABAAAAAAAAABR
5XRkBgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAFLl
dGQEAAAAIB0AAAAAAAAgLQAAAAAAACAtAAAAAAAA4AIAAAAAAADgAgAAAAAAAAEAAAAAAAAAL2xp
Yi9sZC1saW51eC1yaXNjdjY0LWxwNjRkLnNvLjEAAAAABAAAABQAAAADAAAAR05VAMfalteTtcAE
y+bP/US7pl3WP0HiBAAAABAAAAABAAAAR05VAAAAAAAEAAAADwAAAAAAAAACAAAAFwAAAAEAAAAG
AAAAAAAAAAAEACAXAAAAAAAAAGt/mnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMA
DACQCgAAAAAAAAAAAAAAAAAAVAAAABIAAAAAAAAAAAAAAAAAAAAAAAAABQEAACAAAAAAAAAAAAAA
AAAAAAAAAAAANgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAAQAAABIAAAAAAAAAAAAAAAAAAAAAAAAA
IgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAnAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAEQAAABIAAAAA
AAAAAAAAAAAAAAAAAAAALwAAABIAAAAAAAAAAAAAAAAAAAAAAAAAZgAAABIAAAAAAAAAAAAAAAAA
AAAAAAAAPQAAABIAAAAAAAAAAAAAAAAAAAAAAAAAtwAAABEAAAAAAAAAAAAAAAAAAAAAAAAAhgAA
ABIAAAAAAAAAAAAAAAAAAAAAAAAAlgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAbQAAABIAAAAAAAAA
AAAAAAAAAAAAAAAADAAAABIAAAAAAAAAAAAAAAAAAAAAAAAARgAAABIAAAAAAAAAAAAAAAAAAAAA
AAAAdwAAACIAAAAAAAAAAAAAAAAAAAAAAAAAIQEAACAAAAAAAAAAAAAAAAAAAAAAAAAATQAAABEA
AAAAAAAAAAAAAAAAAAAAAAAAjwAAABIAAAAAAAAAAAAAAAAAAAAAAAAArQAAABIAAAAAAAAAAAAA
AAAAAAAAAAAAYQAAABIADACQCgAAAAAAACQEAAAAAAAAAHNldHNvY2tvcHQAcHV0cwBfX3N0YWNr
X2Noa19mYWlsAF9fcHJpbnRmX2NoawBmZmx1c2gAc29ja2V0AHJlY3Zmcm9tAGdldHBpZABzdGRv
dXQAX19saWJjX3N0YXJ0X21haW4Ac2VuZHRvAGluZXRfbnRvcABfX2N4YV9maW5hbGl6ZQBzdHJl
cnJvcgBtZW1zZXQAY2xvc2UAX19lcnJub19sb2NhdGlvbgBpbmV0X3B0b24AX19zdGFja19jaGtf
Z3VhcmQAbGliYy5zby42AGxkLWxpbnV4LXJpc2N2NjQtbHA2NGQuc28uMQBHTElCQ18yLjI3AEdM
SUJDXzIuMzQAX0lUTV9kZXJlZ2lzdGVyVE1DbG9uZVRhYmxlAF9JVE1fcmVnaXN0ZXJUTUNsb25l
VGFibGUAAAAAAAACAAEAAwADAAMAAwADAAMAAwADAAQAAwADAAMAAwADAAMAAQADAAMAAwABAAAA
AAABAAEA0wAAABAAAAAgAAAAh5GWBgAABADvAAAAAAAAAAEAAgDJAAAAEAAAAAAAAACHkZYGAAAD
AO8AAAAQAAAAtJGWBgAAAgD6AAAAAAAAACAtAAAAAAAAAwAAAAAAAADWDgAAAAAAACgtAAAAAAAA
AwAAAAAAAACMDwAAAAAAADAtAAAAAAAAAwAAAAAAAABMDwAAAAAAAOAvAAAAAAAAAwAAAAAAAACQ
CgAAAAAAAAAwAAAAAAAAAwAAAAAAAAAAMAAAAAAAANAvAAAAAAAAAgAAAAMAAAAAAAAAAAAAANgv
AAAAAAAAAgAAAAwAAAAAAAAAAAAAAOgvAAAAAAAAAgAAABIAAAAAAAAAAAAAAPAvAAAAAAAAAgAA
ABMAAAAAAAAAAAAAAPgvAAAAAAAAAgAAABQAAAAAAAAAAAAAAEgvAAAAAAAABQAAAAIAAAAAAAAA
AAAAAFAvAAAAAAAABQAAAAQAAAAAAAAAAAAAAFgvAAAAAAAABQAAAAUAAAAAAAAAAAAAAGAvAAAA
AAAABQAAAAYAAAAAAAAAAAAAAGgvAAAAAAAABQAAAAcAAAAAAAAAAAAAAHAvAAAAAAAABQAAAAgA
AAAAAAAAAAAAAHgvAAAAAAAABQAAAAkAAAAAAAAAAAAAAIAvAAAAAAAABQAAAAoAAAAAAAAAAAAA
AIgvAAAAAAAABQAAAAsAAAAAAAAAAAAAAJAvAAAAAAAABQAAAA0AAAAAAAAAAAAAAJgvAAAAAAAA
BQAAAA4AAAAAAAAAAAAAAKAvAAAAAAAABQAAAA8AAAAAAAAAAAAAAKgvAAAAAAAABQAAABAAAAAA
AAAAAAAAALAvAAAAAAAABQAAABEAAAAAAAAAAAAAALgvAAAAAAAABQAAABUAAAAAAAAAAAAAAMAv
AAAAAAAABQAAABYAAAAAAAAAAAAAAJcjAAAzA8NBA76DXBMDQ/2TgoNcE1MTAIOyggBnAA4AFy4A
AAM+jltnAw4AEwAAABcuAAADPg5bZwMOABMAAAAXLgAAAz6OWmcDDgATAAAAFy4AAAM+DlpnAw4A
EwAAABcuAAADPo5ZZwMOABMAAAAXLgAAAz4OWWcDDgATAAAAFy4AAAM+jlhnAw4AEwAAABcuAAAD
Pg5YZwMOABMAAAAXLgAAAz6OV2cDDgATAAAAFy4AAAM+DldnAw4AEwAAABcuAAADPo5WZwMOABMA
AAAXLgAAAz4OVmcDDgATAAAAFy4AAAM+jlVnAw4AEwAAABcuAAADPg5VZwMOABMAAAAXLgAAAz6O
VGcDDgATAAAAFy4AAAM+DlRnAw4AEwAAAGlxhWdO5lLiBvYi8ibuSurW/dr53vXi8ebt6unu5ROH
h4oTAQGBlykAAIO5KVIKl4O3CQAc44FHhUcXCgAAEwpqUmPUpwADuoUABUaNRQlF7/Af7KqEY0MF
DgVm/XqTBwaL1pf9drOKJwCThoZ2kwcGi7aXs4YnAEFHlUdRRoVFI7T6diO4Cnbv8J/pKokl4f13
BWeThwd5EwcHiz6XMwQnADlGgUUTBSQA7/B/84lHEwZEANKFCUUjmPp47/Bf84VHYw31CiaF7/Cf
7ZcGAACThkZMFwYAABMGxkyXBQAAk4VFRglF7/C/5AVJGagmhe/wH+sXBQAAEwVFSO8AwEAqiYVn
k4eHioqXmGODtwkAuY8BR2OWBzATAQF/snBKhRJ08mRSabJpEmruek57rnsOfO5sTm2ubVVhgoCF
Z5OHh4qKl5hjg7cJALmPAUdjmQcsEwEBf7JwEnTyZFJpsmkSau56Tnuuew587mxOba5tFwUAABMF
BUBVYXmmlwcAAJOHR0yMY5RLkGcDxUcBfXeFZxMHB3uThweLupczhCcAIUcjMAQAIzwEACOwun4j
qNp+DOQjiOp6FMwjtMp+I4qqfhDo7/Df4JsXBQGb1wcBm9eHABsVhQBdjZMHABAihyOaqnojm/p6
gUaTBcQBg1cHAAkHG5aHAKGD0Y+blwcBm9cHAbWfm4YHAOMSt/4b1wcBG9YHAQnPQWd9F/mPsZ8b
1gcBm4YHAAHG+Y+bhhcAhWp9dJOHCouil5PG9v9ShjOEJwCXBQAAk4XFNglFIxnUeu/w/82XJwAA
g7cnMYhj1ozv8P/PfXf9dRMHB3mThQV7k4YKixOFCou6li6VwUczhyYAswUlAIFGcUYmhe/wP87x
RyqKYxb1En17EwsLepOHDIval/16k4rKdTOLJwCThwyL1pd9ehMKin+ziicAk4cMi4Vr0pf9fUFM
M4onAJOLC4DtTBMNAATWh1qHgUZehtKFJoUjLoR17/B/yWNABRDj9Kz+gzeEf2pXynYjPPR2IyTk
eCMw1HgT9wcPvYvjFaf9igdNR+Nx9/wTh4cA423l+oNGFHgFR+OY5vqDJkR4AydEeeOS5voFZxMH
B4s+l7MHJwDulwOnh3+Dp8d/IyDkdkIXIyL0dkGTPf8bhwcAgydEe+Ma9/YFZf13k4cHfRMHBYv9
dT6Xk4VFeJMHBYszCicArpezhScAwUZShglFIzgEfCM8BHzv8H/BUoaXBQAAk4WFJQlF7/B/uBcF
AAATBaUm7/C/wCaF7/BfvomzJoXv8N+9Y0QKBJcGAACThsYgFwYAABMGxh+XBQAAk4VFFglF7/C/
tAVJGbvv8D+1GEGRR+MC9+4mhe/wX7oXBQAAEwWFHu8AABAqidW5FwUAABMFBRzvAAAPKonVse/w
H7PvACACqocXJQAAAzVlEoJlMAATcQH/gUYBRwqI7/AfrAKQlzEAAJOBoZKCgAAAQREi5AAIFyUA
ABMFBRKXJwAAk4eHEWOKpwCXJwAAg7dHDYHHImRBAYKHImRBAYKAFyUAABMFZQ+XJQAAk4XlDomN
QRGT1zVA/ZEi5L6VAAiFhYnJlycAAIO3pwuBxyJkQQGChyJkQQGCgAERIugm5AbsABCXJAAAk4Qk
C4PHBACF45cnAACDt0cIkccXJQAAAzUlCYKX7/C/9oVHI4D0AOJgQmSiZAVhgoBBESLkAAgiZEEB
tb9BEQbkIuAqhO/wH6MIQe/wv6eqhiKGlwUAAJOFJQIJRe/wn6CiYAJkBUVBAYKAAAABAAIAAAAA
AF9fTkVNVV9JQ01QX1BST0JFX0ZBSUxfXzolczolcwoAMTAuMC4yLjIAAAAAAAAAAHNvY2tldAAA
c2V0c29ja29wdC10aW1lb3V0AAAAAAAAYmFkLWRlc3RpbmF0aW9uAGluZXQtcHRvbgAAAAAAAABf
X05FTVVfSUNNUF9QUk9CRV9UWF9fOiVzCgAAAAAAAHNlbmR0bwAAc2hvcnQtd3JpdGUAAAAAAHJl
Y3Zmcm9tAAAAAAAAAABfX05FTVVfSUNNUF9QUk9CRV9SWF9fOiVzCgAAAAAAAF9fTkVNVV9JQ01Q
X1BST0JFX1BBU1NfXzppY21wLWVjaG8AAAAAAABuZW11LXZpcnRpby1uZXQtaWNtcAAAAAABGwM7
JAAAAAMAAACo+f//cAAAAMz9//88AAAAsP7//1AAAAAAAAAAEAAAAAAAAAADelIAAXwBARsNAgAQ
AAAAGAAAAIj9//8iAAAAAAcBABwAAAAsAAAAWP7//y4AAAAAQg4QRIECiARgwULIRA4AfAAAAEwA
AAAw+f//JAQAAABCDrACZA6gEpMKlAyBAogEiQaSCJUOlhCXEpgUmRaaGJsaA/YACg6wAkLBRMhC
yULSQtNC1ELVQtZC10LYQtlC2kLbQg4AQgtaCg6wAkLBQshCyULSQtNC1ELVQtZC10LYQtlC2kLb
Sg4AQgsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAEAAAAAAAAAyQAAAAAAAAABAAAAAAAAANMAAAAAAAAAIAAAAAAAAAAgLQAA
AAAAACEAAAAAAAAACAAAAAAAAAAZAAAAAAAAACgtAAAAAAAAGwAAAAAAAAAIAAAAAAAAABoAAAAA
AAAAMC0AAAAAAAAcAAAAAAAAAAgAAAAAAAAA9f7/bwAAAADYAgAAAAAAAAUAAAAAAAAAQAUAAAAA
AAAGAAAAAAAAAAADAAAAAAAACgAAAAAAAAA7AQAAAAAAAAsAAAAAAAAAGAAAAAAAAAAVAAAAAAAA
AAAAAAAAAAAAAwAAAAAAAAA4LwAAAAAAAAIAAAAAAAAAgAEAAAAAAAAUAAAAAAAAAAcAAAAAAAAA
FwAAAAAAAADwBwAAAAAAAAcAAAAAAAAAAAcAAAAAAAAIAAAAAAAAAHACAAAAAAAACQAAAAAAAAAY
AAAAAAAAAB4AAAAAAAAACAAAAAAAAAD7//9vAAAAAAEAAAgAAAAA/v//bwAAAACwBgAAAAAAAP//
/28AAAAAAgAAAAAAAADw//9vAAAAAHwGAAAAAAAA+f//bwAAAAAFAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAA//////////8AAAAAAAAAAHAJAAAAAAAAcAkAAAAAAABwCQAAAAAAAHAJAAAA
AAAAcAkAAAAAAABwCQAAAAAAAHAJAAAAAAAAcAkAAAAAAABwCQAAAAAAAHAJAAAAAAAAcAkAAAAA
AABwCQAAAAAAAHAJAAAAAAAAcAkAAAAAAABwCQAAAAAAAHAJAAAAAAAAOC0AAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEdDQzogKFVi
dW50dSAxMy4zLjAtNnVidW50dTJ+MjQuMDQuMSkgMTMuMy4wAEFSAAAAcmlzY3YAAUgAAAAEEAVy
djY0aTJwMV9tMnAwX2EycDFfZjJwMl9kMnAyX2MycDBfemljc3IycDBfemlmZW5jZWkycDBfem1t
dWwxcDAAAC5zaHN0cnRhYgAuaW50ZXJwAC5ub3RlLmdudS5idWlsZC1pZAAubm90ZS5BQkktdGFn
AC5nbnUuaGFzaAAuZHluc3ltAC5keW5zdHIALmdudS52ZXJzaW9uAC5nbnUudmVyc2lvbl9yAC5y
ZWxhLmR5bgAucmVsYS5wbHQALnRleHQALnJvZGF0YQAuZWhfZnJhbWVfaGRyAC5laF9mcmFtZQAu
cHJlaW5pdF9hcnJheQAuaW5pdF9hcnJheQAuZmluaV9hcnJheQAuZHluYW1pYwAuZ290AC5kYXRh
AC5ic3MALmNvbW1lbnQALnJpc2N2LmF0dHJpYnV0ZXMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALAAAAAQAAAAIAAAAAAAAA
cAIAAAAAAABwAgAAAAAAACEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAEwAAAAcAAAAC
AAAAAAAAAJQCAAAAAAAAlAIAAAAAAAAkAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAACYA
AAAHAAAAAgAAAAAAAAC4AgAAAAAAALgCAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAA
AAAAAAA0AAAA9v//bwIAAAAAAAAA2AIAAAAAAADYAgAAAAAAACQAAAAAAAAABQAAAAAAAAAIAAAA
AAAAAAAAAAAAAAAAPgAAAAsAAAACAAAAAAAAAAADAAAAAAAAAAMAAAAAAABAAgAAAAAAAAYAAAAC
AAAACAAAAAAAAAAYAAAAAAAAAEYAAAADAAAAAgAAAAAAAABABQAAAAAAAEAFAAAAAAAAOwEAAAAA
AAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAABOAAAA////bwIAAAAAAAAAfAYAAAAAAAB8BgAAAAAA
ADAAAAAAAAAABQAAAAAAAAACAAAAAAAAAAIAAAAAAAAAWwAAAP7//28CAAAAAAAAALAGAAAAAAAA
sAYAAAAAAABQAAAAAAAAAAYAAAACAAAACAAAAAAAAAAAAAAAAAAAAGoAAAAEAAAAAgAAAAAAAAAA
BwAAAAAAAAAHAAAAAAAA8AAAAAAAAAAFAAAAAAAAAAgAAAAAAAAAGAAAAAAAAAB0AAAABAAAAEIA
AAAAAAAA8AcAAAAAAADwBwAAAAAAAIABAAAAAAAABQAAABQAAAAIAAAAAAAAABgAAAAAAAAAeQAA
AAEAAAAGAAAAAAAAAHAJAAAAAAAAcAkAAAAAAAAgAQAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAA
AAAAAH4AAAABAAAABgAAAAAAAACQCgAAAAAAAJAKAAAAAAAANgUAAAAAAAAAAAAAAAAAAAQAAAAA
AAAAAAAAAAAAAACEAAAAAQAAAAIAAAAAAAAAyA8AAAAAAADIDwAAAAAAAB0BAAAAAAAAAAAAAAAA
AAAIAAAAAAAAAAAAAAAAAAAAjAAAAAEAAAACAAAAAAAAAOgQAAAAAAAA6BAAAAAAAAAkAAAAAAAA
AAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAJoAAAABAAAAAgAAAAAAAAAQEQAAAAAAABARAAAAAAAA
zAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAACkAAAAEAAAAAMAAAAAAAAAIC0AAAAAAAAg
HQAAAAAAAAgAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAswAAAA4AAAADAAAAAAAAACgt
AAAAAAAAKB0AAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAL8AAAAPAAAAAwAA
AAAAAAAwLQAAAAAAADAdAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAAAAAAADLAAAA
BgAAAAMAAAAAAAAAOC0AAAAAAAA4HQAAAAAAAAACAAAAAAAABgAAAAAAAAAIAAAAAAAAABAAAAAA
AAAA1AAAAAEAAAADAAAAAAAAADgvAAAAAAAAOB8AAAAAAADIAAAAAAAAAAAAAAAAAAAACAAAAAAA
AAAIAAAAAAAAANkAAAABAAAAAwAAAAAAAAAAMAAAAAAAAAAgAAAAAAAACAAAAAAAAAAAAAAAAAAA
AAgAAAAAAAAAAAAAAAAAAADfAAAACAAAAAMAAAAAAAAACDAAAAAAAAAIIAAAAAAAAAgAAAAAAAAA
AAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA5AAAAAEAAAAwAAAAAAAAAAAAAAAAAAAACCAAAAAAAAAt
AAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAO0AAAADAABwAAAAAAAAAAAAAAAAAAAAADUg
AAAAAAAAUwAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAwAAAAAAAAAAAAAAAAAA
AAAAAACIIAAAAAAAAP8AAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA
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
f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK
AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA
AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA
AAAAAAADAABwBAAAADWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFMAAAAAAAAAAAAAAAAAAAABAAAA
AAAAAAEAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAXHIAAAAAAABccgAAAAAAAAAQAAAA
AAAAAQAAAAYAAACYegAAAAAAAJiKAAAAAAAAmIoAAAAAAABwBQAAAAAAAIgFAAAAAAAAABAAAAAA
AAACAAAABgAAALB6AAAAAAAAsIoAAAAAAACwigAAAAAAAAACAAAAAAAAAAIAAAAAAAAIAAAAAAAA
AAQAAAAEAAAAlAIAAAAAAACUAgAAAAAAAJQCAAAAAAAARAAAAAAAAABEAAAAAAAAAAQAAAAAAAAA
UOV0ZAQAAACIbAAAAAAAAIhsAAAAAAAAiGwAAAAAAACkAAAAAAAAAKQAAAAAAAAABAAAAAAAAABR
5XRkBgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAFLl
dGQEAAAAmHoAAAAAAACYigAAAAAAAJiKAAAAAAAAaAUAAAAAAABoBQAAAAAAAAEAAAAAAAAAL2xp
Yi9sZC1saW51eC1yaXNjdjY0LWxwNjRkLnNvLjEAAAAABAAAABQAAAADAAAAR05VACMT/8auGC+i
0kGB260NIG/vsIEaBAAAABAAAAABAAAAR05VAAAAAAAEAAAADwAAAAAAAAACAAAAaAAAAAEAAAAG
AAAAAAAAAAAEACBoAAAAAAAAAGt/mnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMA
DAAwIgAAAAAAAAAAAAAAAAAA7AEAABIAAAAAAAAAAAAAAAAAAAAAAAAAMAAAABIAAAAAAAAAAAAA
AAAAAAAAAAAASQMAABIAAAAAAAAAAAAAAAAAAAAAAAAACgIAABIAAAAAAAAAAAAAAAAAAAAAAAAA
QwIAABIAAAAAAAAAAAAAAAAAAAAAAAAAUwIAABIAAAAAAAAAAAAAAAAAAAAAAAAABAEAABIAAAAA
AAAAAAAAAAAAAAAAAAAAjwEAABIAAAAAAAAAAAAAAAAAAAAAAAAABQMAABIAAAAAAAAAAAAAAAAA
AAAAAAAAtAMAACAAAAAAAAAAAAAAAAAAAAAAAAAAIwMAABIAAAAAAAAAAAAAAAAAAAAAAAAARwMA
ABIAAAAAAAAAAAAAAAAAAAAAAAAA2gAAABIAAAAAAAAAAAAAAAAAAAAAAAAAwgAAABIAAAAAAAAA
AAAAAAAAAAAAAAAAiAEAABIAAAAAAAAAAAAAAAAAAAAAAAAAlwAAABIAAAAAAAAAAAAAAAAAAAAA
AAAAdQIAABIAAAAAAAAAAAAAAAAAAAAAAAAAPgAAABIAAAAAAAAAAAAAAAAAAAAAAAAALQMAABIA
AAAAAAAAAAAAAAAAAAAAAAAAiAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAZAAAABIAAAAAAAAAAAAA
AAAAAAAAAAAANQIAABIAAAAAAAAAAAAAAAAAAAAAAAAADwEAABIAAAAAAAAAAAAAAAAAAAAAAAAA
yAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAdgEAABIAAAAAAAAAAAAAAAAAAAAAAAAA9QEAABIAAAAA
AAAAAAAAAAAAAAAAAAAA5gIAABIAAAAAAAAAAAAAAAAAAAAAAAAAIgAAABIAAAAAAAAAAAAAAAAA
AAAAAAAABAIAABIAAAAAAAAAAAAAAAAAAAAAAAAAngAAABIAAAAAAAAAAAAAAAAAAAAAAAAA2gEA
ABIAAAAAAAAAAAAAAAAAAAAAAAAAUwAAABIAAAAAAAAAAAAAAAAAAAAAAAAA4QAAABIAAAAAAAAA
AAAAAAAAAAAAAAAAlwIAABIAAAAAAAAAAAAAAAAAAAAAAAAAGAEAABIAAAAAAAAAAAAAAAAAAAAA
AAAAjwIAABIAAAAAAAAAAAAAAAAAAAAAAAAAGAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAKAAAABIA
AAAAAAAAAAAAAAAAAAAAAAAADQMAABIAAAAAAAAAAAAAAAAAAAAAAAAAcAEAABIAAAAAAAAAAAAA
AAAAAAAAAAAAqgEAABIAAAAAAAAAAAAAAAAAAAAAAAAAYQEAABIAAAAAAAAAAAAAAAAAAAAAAAAA
yQEAABIAAAAAAAAAAAAAAAAAAAAAAAAAZgMAABEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAABIAAAAA
AAAAAAAAAAAAAAAAAAAAagEAABIAAAAAAAAAAAAAAAAAAAAAAAAA/QEAABIAAAAAAAAAAAAAAAAA
AAAAAAAARQAAABIAAAAAAAAAAAAAAAAAAAAAAAAAFAMAABIAAAAAAAAAAAAAAAAAAAAAAAAAOwMA
ABIAAAAAAAAAAAAAAAAAAAAAAAAA3QIAABIAAAAAAAAAAAAAAAAAAAAAAAAA0wAAABIAAAAAAAAA
AAAAAAAAAAAAAAAA/wAAABIAAAAAAAAAAAAAAAAAAAAAAAAASgIAABIAAAAAAAAAAAAAAAAAAAAA
AAAA8gAAABIAAAAAAAAAAAAAAAAAAAAAAAAAiQIAABIAAAAAAAAAAAAAAAAAAAAAAAAAQQMAABIA
AAAAAAAAAAAAAAAAAAAAAAAAFAIAABIAAAAAAAAAAAAAAAAAAAAAAAAAbwIAABIAAAAAAAAAAAAA
AAAAAAAAAAAAwQEAABIAAAAAAAAAAAAAAAAAAAAAAAAAoQIAABIAAAAAAAAAAAAAAAAAAAAAAAAA
OgEAABIAAAAAAAAAAAAAAAAAAAAAAAAAvAIAABIAAAAAAAAAAAAAAAAAAAAAAAAAqAAAABIAAAAA
AAAAAAAAAAAAAAAAAAAAYAMAABIAAAAAAAAAAAAAAAAAAAAAAAAATAEAABIAAAAAAAAAAAAAAAAA
AAAAAAAAWAMAABIAAAAAAAAAAAAAAAAAAAAAAAAARwEAABIAAAAAAAAAAAAAAAAAAAAAAAAAWAIA
ABIAAAAAAAAAAAAAAAAAAAAAAAAAgwEAABIAAAAAAAAAAAAAAAAAAAAAAAAADgAAABIAAAAAAAAA
AAAAAAAAAAAAAAAA+QAAABIAAAAAAAAAAAAAAAAAAAAAAAAAgwIAABIAAAAAAAAAAAAAAAAAAAAA
AAAAtQEAABIAAAAAAAAAAAAAAAAAAAAAAAAAKgEAABIAAAAAAAAAAAAAAAAAAAAAAAAA9wIAABIA
AAAAAAAAAAAAAAAAAAAAAAAA6AAAABIAAAAAAAAAAAAAAAAAAAAAAAAAsAAAABIAAAAAAAAAAAAA
AAAAAAAAAAAAxgIAABIAAAAAAAAAAAAAAAAAAAAAAAAAaAIAABIAAAAAAAAAAAAAAAAAAAAAAAAA
rwEAABIAAAAAAAAAAAAAAAAAAAAAAAAAqQEAABIAAAAAAAAAAAAAAAAAAAAAAAAA1QIAABIAAAAA
AAAAAAAAAAAAAAAAAAAAuAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAHAIAACIAAAAAAAAAAAAAAAAA
AAAAAAAA4wEAABIAAAAAAAAAAAAAAAAAAAAAAAAA/wIAABIAAAAAAAAAAAAAAAAAAAAAAAAAUwEA
ABIAAAAAAAAAAAAAAAAAAAAAAAAAKwIAABIAAAAAAAAAAAAAAAAAAAAAAAAAoQEAABIAAAAAAAAA
AAAAAAAAAAAAAAAAUQMAABIAAAAAAAAAAAAAAAAAAAAAAAAA0AMAACAAAAAAAAAAAAAAAAAAAAAA
AAAAdgAAABIAAAAAAAAAAAAAAAAAAAAAAAAAggAAABIAAAAAAAAAAAAAAAAAAAAAAAAAzgIAABIA
AAAAAAAAAAAAAAAAAAAAAAAANgMAABIAAAAAAAAAAAAAAAAAAAAAAAAAsAIAABIAAAAAAAAAAAAA
AAAAAAAAAAAAawEAABIAAAAAAAAAAAAAAAAAAAAAAAAAEQEAABIAAAAAAAAAAAAAAAAAAAAAAAAA
fAIAABIAAAAAAAAAAAAAAAAAAAAAAAAAcQAAABIAAAAAAAAAAAAAAAAAAAAAAAAA3wIAABIAAAAA
AAAAAAAAAAAAAAAAAAAAnAEAABIADAAwIgAAAAAAABAaAAAAAAAAAHRpbWVyX2RlbGV0ZQB0Y3Nl
dHBncnAAZXBvbGxfY3RsAHByY3RsAHN5c2NvbmYAdGltZXJfc2V0dGltZQBzZXRzaWQAY2xvY2tf
Z2V0dGltZQBfX3N0YWNrX2Noa19mYWlsAF9fcHJpbnRmX2NoawBmcmVlAF9fZmRlbHRfY2hrAG1z
eW5jAHRpbWVyZmRfY3JlYXRlAGV4ZWNscABzaWdhZGRzZXQAbWtkaXJhdABwdHNuYW1lAHNpZ2Fj
dGlvbgBmY250bABzb2NrZXRwYWlyAHVubGluawBtdW5tYXAAZmZsdXNoAGZ0cnVuY2F0ZQB3YWl0
aWQAZmxvY2sAZm9yawBlcG9sbF93YWl0AHRjZ2V0c2lkAGlub3RpZnlfYWRkX3dhdGNoAHRpbWVy
ZmRfc2V0dGltZQBwb3NpeF9vcGVucHQAZHVwMwBnZXRwaWQAaW5vdGlmeV9pbml0MQBzaWduYWxm
ZABwcG9sbABfZXhpdAB0aW1lcl9jcmVhdGUAb3BlbgBtYWxsb2MAX19saWJjX3N0YXJ0X21haW4A
cmVjdm1zZwBwcmVhZABleGVjbABzaWdwcm9jbWFzawBtaW5jb3JlAGlub3RpZnlfcm1fd2F0Y2gA
ZmNobW9kYXQAbXByb3RlY3QAdW5sb2NrcHQAc2VuZG1zZwBtcmVtYXAAY2xvY2tfbmFub3NsZWVw
AGV2ZW50ZmQAX19jeGFfZmluYWxpemUAdXRpbWVuc2F0AGVwb2xsX2NyZWF0ZTEAb3BlbmF0AHN0
cmVycm9yAGtpbGwAcG9zaXhfZmFsbG9jYXRlAGNhbGxvYwBmc3luYwBtZW1jbXAAbWVtc2V0AGlv
Y3RsAGNsb3NlAHdhaXRwaWQAdGNnZXRhdHRyAF9fc25wcmludGZfY2hrAHNpZ2VtcHR5c2V0AHRj
c2V0YXR0cgBwc2VsZWN0AHN0cmNtcABncmFudHB0AHVubGlua2F0AF9fZXJybm9fbG9jYXRpb24A
bWFkdmlzZQB3cml0ZQBzeXNjYWxsAHN5bmNmcwBwb3NpeF9tZW1hbGlnbgBzZXRpdGltZXIAc2Vu
ZGZpbGUAbW1hcABwYXVzZQBsc2VlawB0Y2dldHBncnAAc3BsaWNlAHN0cm5jbXAAcGlwZTIAX19z
dGFja19jaGtfZ3VhcmQAbGliYy5zby42AGxkLWxpbnV4LXJpc2N2NjQtbHA2NGQuc28uMQBHTElC
Q18yLjI3AEdMSUJDXzIuMzQAX0lUTV9kZXJlZ2lzdGVyVE1DbG9uZVRhYmxlAF9JVE1fcmVnaXN0
ZXJUTUNsb25lVGFibGUAAAAAAAIAAwACAAIAAgACAAIAAwACAAEAAgACAAIAAgACAAIAAgACAAIA
AgACAAIAAgACAAMAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIABAADAAIAAgAC
AAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIA
AgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAQACAAIAAgACAAIAAgACAAIAAgACAAEAAAAA
AAEAAQCCAwAAEAAAACAAAACHkZYGAAAEAJ4DAAAAAAAAAQACAHgDAAAQAAAAAAAAALSRlgYAAAMA
qQMAABAAAACHkZYGAAACAJ4DAAAAAAAAmIoAAAAAAAADAAAAAAAAAGI8AAAAAAAAoIoAAAAAAAAD
AAAAAAAAABg9AAAAAAAAqIoAAAAAAAADAAAAAAAAANg8AAAAAAAA6I8AAAAAAAADAAAAAAAAADAi
AAAAAAAAAJAAAAAAAAADAAAAAAAAAACQAAAAAAAA2I8AAAAAAAACAAAACwAAAAAAAAAAAAAA4I8A
AAAAAAACAAAALQAAAAAAAAAAAAAA8I8AAAAAAAACAAAAVgAAAAAAAAAAAAAA+I8AAAAAAAACAAAA
XQAAAAAAAAAAAAAAwIwAAAAAAAAFAAAAAgAAAAAAAAAAAAAAyIwAAAAAAAAFAAAAAwAAAAAAAAAA
AAAA0IwAAAAAAAAFAAAABAAAAAAAAAAAAAAA2IwAAAAAAAAFAAAABQAAAAAAAAAAAAAA4IwAAAAA
AAAFAAAABgAAAAAAAAAAAAAA6IwAAAAAAAAFAAAABwAAAAAAAAAAAAAA8IwAAAAAAAAFAAAACAAA
AAAAAAAAAAAA+IwAAAAAAAAFAAAACQAAAAAAAAAAAAAAAI0AAAAAAAAFAAAACgAAAAAAAAAAAAAA
CI0AAAAAAAAFAAAADAAAAAAAAAAAAAAAEI0AAAAAAAAFAAAADQAAAAAAAAAAAAAAGI0AAAAAAAAF
AAAADgAAAAAAAAAAAAAAII0AAAAAAAAFAAAADwAAAAAAAAAAAAAAKI0AAAAAAAAFAAAAEAAAAAAA
AAAAAAAAMI0AAAAAAAAFAAAAEQAAAAAAAAAAAAAAOI0AAAAAAAAFAAAAEgAAAAAAAAAAAAAAQI0A
AAAAAAAFAAAAEwAAAAAAAAAAAAAASI0AAAAAAAAFAAAAFAAAAAAAAAAAAAAAUI0AAAAAAAAFAAAA
FQAAAAAAAAAAAAAAWI0AAAAAAAAFAAAAFgAAAAAAAAAAAAAAYI0AAAAAAAAFAAAAFwAAAAAAAAAA
AAAAaI0AAAAAAAAFAAAAGAAAAAAAAAAAAAAAcI0AAAAAAAAFAAAAGQAAAAAAAAAAAAAAeI0AAAAA
AAAFAAAAGgAAAAAAAAAAAAAAgI0AAAAAAAAFAAAAGwAAAAAAAAAAAAAAiI0AAAAAAAAFAAAAHAAA
AAAAAAAAAAAAkI0AAAAAAAAFAAAAHQAAAAAAAAAAAAAAmI0AAAAAAAAFAAAAHgAAAAAAAAAAAAAA
oI0AAAAAAAAFAAAAHwAAAAAAAAAAAAAAqI0AAAAAAAAFAAAAIAAAAAAAAAAAAAAAsI0AAAAAAAAF
AAAAIQAAAAAAAAAAAAAAuI0AAAAAAAAFAAAAIgAAAAAAAAAAAAAAwI0AAAAAAAAFAAAAIwAAAAAA
AAAAAAAAyI0AAAAAAAAFAAAAJAAAAAAAAAAAAAAA0I0AAAAAAAAFAAAAJQAAAAAAAAAAAAAA2I0A
AAAAAAAFAAAAJgAAAAAAAAAAAAAA4I0AAAAAAAAFAAAAJwAAAAAAAAAAAAAA6I0AAAAAAAAFAAAA
KAAAAAAAAAAAAAAA8I0AAAAAAAAFAAAAKQAAAAAAAAAAAAAA+I0AAAAAAAAFAAAAKgAAAAAAAAAA
AAAAAI4AAAAAAAAFAAAAKwAAAAAAAAAAAAAACI4AAAAAAAAFAAAALAAAAAAAAAAAAAAAEI4AAAAA
AAAFAAAALgAAAAAAAAAAAAAAGI4AAAAAAAAFAAAALwAAAAAAAAAAAAAAII4AAAAAAAAFAAAAMAAA
AAAAAAAAAAAAKI4AAAAAAAAFAAAAMQAAAAAAAAAAAAAAMI4AAAAAAAAFAAAAMgAAAAAAAAAAAAAA
OI4AAAAAAAAFAAAAMwAAAAAAAAAAAAAAQI4AAAAAAAAFAAAANAAAAAAAAAAAAAAASI4AAAAAAAAF
AAAANQAAAAAAAAAAAAAAUI4AAAAAAAAFAAAANgAAAAAAAAAAAAAAWI4AAAAAAAAFAAAANwAAAAAA
AAAAAAAAYI4AAAAAAAAFAAAAOAAAAAAAAAAAAAAAaI4AAAAAAAAFAAAAOQAAAAAAAAAAAAAAcI4A
AAAAAAAFAAAAOgAAAAAAAAAAAAAAeI4AAAAAAAAFAAAAOwAAAAAAAAAAAAAAgI4AAAAAAAAFAAAA
PAAAAAAAAAAAAAAAiI4AAAAAAAAFAAAAPQAAAAAAAAAAAAAAkI4AAAAAAAAFAAAAPgAAAAAAAAAA
AAAAmI4AAAAAAAAFAAAAPwAAAAAAAAAAAAAAoI4AAAAAAAAFAAAAQAAAAAAAAAAAAAAAqI4AAAAA
AAAFAAAAQQAAAAAAAAAAAAAAsI4AAAAAAAAFAAAAQgAAAAAAAAAAAAAAuI4AAAAAAAAFAAAAQwAA
AAAAAAAAAAAAwI4AAAAAAAAFAAAARAAAAAAAAAAAAAAAyI4AAAAAAAAFAAAARQAAAAAAAAAAAAAA
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
7/APjiqEY0kFZmMRBRYKVe/wD5CXRwAAk4dH3JhjGlWDx4cAJUasAiMI8RS65u/wL6ylR2MB9WYT
BeAH7+Bf/hc1AAATBYVy7wCwc0qF7/AvjG/wn4gXRQAAEwWll+8AUHIdtRdFAAATBUWI7wBwcRW+
FzUAABMF5V7vAJBwEwqBFO/w74UqhGNHBUBjEQUe7/APgvW/FzUAABMFJW7vAFBuToXv8M+GSoXv
8G+Gb/Dfgpc1AACTheVvFzUAABMFZXXvAHBpUoXv8I+Eb/DfjBdFAAATBYWC7wCwakqF7/Avg8m0
FzUAABMFRWHvAHBpb/Av9Bc1AAATBcVU7wBwaEqF7/DvgE6F7/CPgG/wD9oXRQAAEwUFne8AsGYB
Rs6FWoWCwO/g3+vjCKvgF0UAABMFRZzvAPBkAbW3V0wAk4cHtIFFiAC+5ILg7+B/yoVHHMABSIFH
AUeFRgVGooUTBSAG7+D/zQFF7+Cf6xpVEwqBFO/g//kKVUFG0oWC5oLq7+Af6yqJClXv4J/4AUaM
ACKFgsDv4N/kYwekIBdFAAATBUWg7wDwXem9FzUAABMFZWTvABBdUoXv4J/1b/DP/Rc1AAATBYVG
7wCwW2PdCcxv8M/NF0UAABMFxZfvAHBaEb0XRQAAEwXll+8AkFkihe/gH/IBtQpVBUaMAO/gX+Nj
GDUBA0cBBINHAQPjB/cGlzUAAJOFBUoXNQAAEwWFSO8AkFNv8A/VF0UAABMFhYnvADBVMbMXNQAA
EwWlVYW1F0YAABMGBpOXNQAAk4UFlwlF7+D/yUG7FzUAABMFhWrvADBSSoXv4L/qb/C/k6qFAUYT
BSAb7+C/vBsJBQBjTAlqF0YAABMG5pmXNQAAk4XlkglF7+DfxQFHgUY9RsqFEwWAGu/g37ljFQVQ
F0YAABMGRpiXNQAAk4VFkAlF7+A/w4VJEwaAPoVFiADKwM7C7/APjGMXNQGDV2EEhYtjmwd6lzUA
AJOF5bQXRQAAEwXlle8AcEYTBgAIgUVmhe/wL4uRRmaGyoUNRe/gf99jGQVqyldjlocAKleJR+MC
9wSXRQAAk4WFlBdFAAATBQWT7wCQQkqF7+C/3aWiFzUAABMFRSHvAPBDb/DPnhc1AAATBUVS7wDw
QgZV7+B/2xZV7+Af22/wD/YXNQAAEwWFI+8AMEFv8G+pFzUAABMFhR7vADBAhWVOhe/gn65v8I+a
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
uY8BR6HrvnD6elp7fWGCgBcVAAATBQWf7+Cvyvm/FxYAABMGpqKXBQAAk4UlDQlF78APwFW3FxUA
ABMFpZ/v4E/IAmXvwM/VAUbahTFF78Av/GW3ovOm78rrzufS4+/AL8gAAAAAAAABAAIAAAAAAF9f
TkVNVV9TWVNDQUxMX1BST0JFX0ZBSUxfXzolczolcwoAAAAAAAAlcy9wcm9iZS1tbWFwLmJpbgAA
AAAAAABvcGVuLW1tYXAtZmlsZQAAZnRydW5jYXRlAAAAAAAAAG1tYXAtc2hhcmVkAAAAAABtc3lu
YwAAAG1tYXAtbXN5bmMAAAAAAABfX05FTVVfU1lTQ0FMTF9QUk9CRV9QQVNTX186JXMKAG11bm1h
cAAAc2hvcnQtcmVhZAAAAAAAAHByZWFkLW1tYXAtZmlsZQBwb3NpeC1mYWxsb2NhdGUAZmxvY2st
ZXhjbHVzaXZlAGZsb2NrLXVubG9jawAAAABmbG9jawAAAHN5bmNmcwAAcGF0dGVybi1taXNtYXRj
aAAAAAAAAAAAJXMvcHJvYmUtZ2V0ZGVudHMtZW50cnkAb3Blbi1nZXRkZW50cy1lbnRyeQAAAAAA
ZGlyZW50AABzaG9ydC13cml0ZQAAAAAAd3JpdGUtZ2V0ZGVudHMtZW50cnkAAAAAZmNudGwtcmVj
b3JkLWxvY2sAAAAAAAAAZmNudGwtcmVjb3JkLXVubG9jawAAAAAAZmFjY2Vzc2F0Mi1za2lwLWVu
b3N5cwAAZmFjY2Vzc2F0Mi1lYWNjZXNzAAAAAAAAb3Blbi1nZXRkZW50cy1kaXIAAAAAAAAAZ2V0
ZGVudHM2NC1kaXIAAHByb2JlLWdldGRlbnRzLWVudHJ5AAAAAG1hbGZvcm1lZC1kaXJlbnQAAAAA
AAAAAGVudHJ5LW1pc3NpbmcAAAAlcy9wcm9iZS1vZGlyZWN0LmJpbgAAAABvcGVuLW9kaXJlY3QA
AAAAZmFpbGVkAABwb3NpeC1tZW1hbGlnbgAAd3JpdGUtb2RpcmVjdAAAAGZzeW5jLW9kaXJlY3QA
AABvZGlyZWN0LXdyaXRlLWZzeW5jAAAAAABzaWdwcm9jbWFzay1ibG9jawAAAAAAAABzaWduYWxm
ZC1jcmVhdGUAc2lnbmFsZmQta2lsbAAAAG5vdC1yZWFkYWJsZQAAAABzaWduYWxmZC1wb2xsAAAA
YmFkLXNpZ25hbAAAAAAAAHNpZ25hbGZkLXJlYWQAAABzaWduYWxmZAAAAAAAAAAAaW5vdGlmeS1p
bml0AAAAAGlub3RpZnktYWRkLXdhdGNoAAAAAAAAACVzL3Byb2JlLWlub3RpZnktZXZlbnQAAGlu
b3RpZnktb3Blbi10YXJnZXQAAAAAAGlub3RpZnkAaW5vdGlmeS13cml0ZS10YXJnZXQAAAAAaW5v
dGlmeS1wb2xsAAAAAGlub3RpZnktY3JlYXRlLWNsb3NlAAAAAGV2ZW50LW1pc3NpbmcAAABpbm90
aWZ5LXJlYWQAAAAAbW9kZXJuLWZzLW9wZW4tZGlyAAAAAAAAc3RhdHgtZGlyAAAAAAAAAG5vdC1k
aXJlY3RvcnkAAABwcm9iZS1vcGVuYXQyLXNyYwAAAAAAAABvcGVuYXQyLWNyZWF0ZQAAd3JpdGUt
b3ItZnN5bmMtZmFpbGVkAAAAb3BlbmF0Mi13cml0ZS1mc3luYwAAAAAAb3BlbmF0Mi1jcmVhdGUt
d3JpdGUAAAAAc3RhdHgtZmlsZQAAAAAAAGJhZC1zaXplAAAAAAAAAABzdGF0eC1maWxlLXNpemUA
cHJvYmUtY29weS1yYW5nZS1kc3QAAAAAY29weS1maWxlLXJhbmdlLW9wZW4tZHN0AAAAAAAAAABj
b3B5LWZpbGUtcmFuZ2UtbHNlZWsAAABzaG9ydC1jb3B5AAAAAAAAY29weS1maWxlLXJhbmdlAGNv
cHktZmlsZS1yYW5nZS1kc3QtbHNlZWsAAAAAAAAAY29weS1maWxlLXJhbmdlLXJlYWRiYWNrAAAA
AAAAAABwcm9iZS1yZW5hbWVhdDItZHN0AAAAAAByZW5hbWVhdDItbm9yZXBsYWNlAAAAAABwcm9i
ZS1tZXRhLWRpci9wcm9iZS1oYXJkbGluawAAAHByb2JlLW1ldGEtZGlyAABta2RpcmF0LW1ldGFk
YXRhLWRpcgAAAABsaW5rYXQtaGFyZGxpbmsAc3RhdHgtaGFyZGxpbmsAAGlub2RlLW9yLW5saW5r
LW1pc21hdGNoAGZjaG1vZGF0LWhhcmRsaW5rAAAAAAAAAHN0YXR4LWhhcmRsaW5rLW1vZGUAAAAA
AG1vZGUtbWlzbWF0Y2gAAAB1dGltZW5zYXQtaGFyZGxpbmsAAAAAAABzdGF0eC1oYXJkbGluay1t
dGltZQAAAABtdGltZS1taXNtYXRjaAAAZGlyZWN0b3J5LWZzeW5jAG1vZGVybi1mcy1zeXNjYWxs
cy1vawAAACVzL3Byb2JlLXNjbS1yaWdodHMudHh0AHNjbS1yaWdodHMtb3BlbgB3cml0ZS1vci1s
c2Vlay1mYWlsZWQAAABzY20tcmlnaHRzLXdyaXRlAAAAAAAAAABzY20tcmlnaHRzLXNvY2tldHBh
aXIAAABzaG9ydC1zZW5kAAAAAAAAc2NtLXJpZ2h0cy1zZW5kbXNnAAAAAAAAYmFkLW1lc3NhZ2UA
AAAAAHNjbS1yaWdodHMtcmVjdm1zZwAAAAAAAG1pc3NpbmctZmQAAAAAAABwYXlsb2FkLW1pc21h
dGNoAAAAAAAAAABzY20tcmlnaHRzLWZkLXJlYWQAAAAAAAB1bml4LXNjbS1yaWdodHMAc2NtLXJp
Z2h0cy1vawAAACVzL3Byb2JlLXplcm9jb3B5LXNyYy5iaW4AAAAAAAAAJXMvcHJvYmUtc2VuZGZp
bGUtZHN0LmJpbgAAAAAAAAAlcy9wcm9iZS1zcGxpY2UtZHN0LmJpbgB6ZXJvY29weS1vcGVuLXNy
YwAAAAAAAAB6ZXJvY29weS13cml0ZS1zcmMAAAAAAABzZW5kZmlsZS1vcGVuLWRzdAAAAAAAAABz
aG9ydC1vci1mYWlsZWQAc2VuZGZpbGUtcmVndWxhci1maWxlAAAAc3BsaWNlLW9wZW4tZHN0AHNw
bGljZS1waXBlMgAAAABzcGxpY2UtbHNlZWstc3JjAAAAAAAAAABzcGxpY2UtZmlsZS1waXBlLWZp
bGUAAABjb3B5LW9yLXZlcmlmeS1mYWlsZWQAAABzaWdhY3Rpb24tc2lnYWxybQAAAAAAAABzZXRp
dGltZXItcmVhbAAAc2V0aXRpbWVyLXNpZ2Fscm0AAAAAAAAAbm90LWRlbGl2ZXJlZAAAAHBvc2l4
LXRpbWVyLXNpZ2FjdGlvbgAAAHBvc2l4LXRpbWVyLWNyZWF0ZQAAAAAAAHBvc2l4LXRpbWVyLXNl
dHRpbWUAAAAAAHBvc2l4LXRpbWVyLXNpZ25hbAAAAAAAAC90bXAAAAAAX19ORU1VX1NZU0NBTExf
UFJPQkVfQkVHSU5fXzolcwoAAAAAAAAAAG1tYXAtYW5vbgAAAAAAAABtcmVtYXAtYW5vbgAAAAAA
bXByb3RlY3QtcmVhZG9ubHktcGFnZQAAbXByb3RlY3QtcmVzdG9yZS1wYWdlAAAAbW1hcC1hZHZp
Y2UtYW5vbgAAAAAAAAAAbWFkdmlzZS13aWxsbmVlZAAAAAAAAAAAYWxsb2MAAABtaW5jb3JlLXJl
c2lkZW50AAAAAAAAAABwYWdlLW5vdC1yZXNpZGVudAAAAAAAAAAvZGV2L251bGwAAAAAAAAAL2Rl
di96ZXJvAAAAAAAAAGNsb3NlLXJhbmdlLW9wZW4AAAAAAAAAAGNsb3NlLXJhbmdlAAAAAABmZC1z
dGlsbC1vcGVuAAAAcGlwZTIAAABwaXBlMi1mY250bAAAAAAAZmxhZ3MtbWlzc2luZwAAAHBpcGUy
LWNsb2V4ZWMtbm9uYmxvY2sAAGR1cDMtcGlwZS13cml0ZQBiYWQtcmVhZGJhY2sAAAAAc29ja2V0
cGFpcgAAAAAAAHNvY2tldHBhaXItd3JpdGUAAAAAAAAAAHNvY2tldHBhaXItcmVhZABldmVudGZk
AGV2ZW50ZmQtd3JpdGUAAABldmVudGZkLXBvbGwAAAAAYmFkLXZhbHVlAAAAAAAAAGV2ZW50ZmQt
cmVhZAAAAABldmVudGZkLXBvbGwtcmVhZAAAAAAAAABlcG9sbC1jcmVhdGUAAAAAdGltZXJmZC1j
cmVhdGUAAGVwb2xsLWN0bC1hZGQtdGltZXJmZAAAAHRpbWVyZmQtc2V0dGltZQBlcG9sbC10aW1l
cmZkAAAAYmFkLWV4cGlyYXRpb24tY291bnQAAAAAdGltZXJmZC1yZWFkAAAAAHBlcmlvZGljLXRp
bWVyZmQtY3JlYXRlAHBlcmlvZGljLXRpbWVyZmQtc2V0dGltZQAAAAAAAAAAcGVyaW9kaWMtdGlt
ZXJmZC1yZWFkAAAAcGVyaW9kaWMtdGltZXJmZAAAAAAAAAAAdG9vLWZldy1leHBpcmF0aW9ucwAA
AAAAcHBvbGwtcHNlbGVjdC1waXBlMgAAAAAAcHBvbGwtcHNlbGVjdC1mb3JrAAAAAAAAcHBvbGwt
cGlwZQAAAAAAAHBzZWxlY3QtcGlwZQAAAABwcG9sbC1wc2VsZWN0LXdhaXRwaWQAAABiYWQtZXhp
dAAAAAAAAAAAcHBvbGwtcHNlbGVjdC1jaGlsZAAAAAAAcG9zaXgtb3BlbnB0AAAAAGdyYW50cHQA
dW5sb2NrcHQAAAAAAAAAAG9wZW4tcHR5LXNsYXZlAAB0Y2dldGF0dHItcHR5AAAAdGNzZXRhdHRy
LXB0eQAAAHB0eS10ZXJtaW9zAAAAAABwdHktdGlvY3N3aW5zegAAcHR5LXRpb2Nnd2luc3oAAHB0
eS13aW5zaXplAAAAAABwdHktbWFzdGVyLXdyaXRlAAAAAAAAAABwdHktc2xhdmUtcG9sbAAAcHR5
LXNsYXZlLXJlYWQAAHB0eS1tYXN0ZXItc2xhdmUAAAAAAAAAAGpvYi1wdHktb3BlbnB0AABqb2It
cHR5LWdyYW50LXVubG9jawAAAABqb2ItcHR5LXB0c25hbWUAam9iLXB0eS1waXBlMgAAAGpvYi1w
dHktZm9yawAAAABqb2ItcHR5LXdhaXRwaWQAbWlzc2luZy1jaGlsZC1yZXN1bHQAAAAAam9iLXB0
eS1yZXN1bHQAAHB0eS1jb250cm9sbGluZy10dHkAAAAAAG5vdC1hY3F1aXJlZAAAAABwdHktZm9y
ZWdyb3VuZC1wZ3JwAAAAAABwdHktc2lnd2luY2gAAAAAam9iLXB0eS1jaGlsZAAAAGZ1dGV4LW1t
YXAAAAAAAABmdXRleC1mb3JrAAAAAAAAZnV0ZXgtd2FpdAAAAAAAAGZ1dGV4LXdhaXRwaWQAAABm
dXRleC1jaGlsZAAAAAAAZnV0ZXgtd2FpdC13YWtlAHdvcmQtbm90LXVwZGF0ZWQAAAAAAAAAAG5l
bXUtcHJvYmUtbWVtZmQAAAAAAAAAAG1lbWZkLWNyZWF0ZQAAAABtZW1mZC1mdHJ1bmNhdGUAbWVt
ZmQtbW1hcAAAAAAAAGZvcmsAAAAAdHJ1ZQAAAAAvdXNyL2Jpbi90cnVlAAAAd2FpdHBpZABiYWQt
Y2hpbGQtbWVzc2FnZQAAAAAAAABmb3JrLXBpcGUAAAAAAAAAZXhlY3ZlLXRydWUAAAAAAGZvcmst
cGlwZS1leGVjdmUAAAAAAAAAAHBpZGZkLWZvcmsAAAAAAABwaWRmZC1za2lwLWVub3N5cwAAAAAA
AABwaWRmZC1vcGVuAAAAAAAAcGlkZmQtc2VuZC1zaWduYWwAAAAAAAAAcGlkZmQtcG9sbC1leGl0
AHdhaXRpZC1waWRmZAAAAABiYWQtc2lnaW5mbwAAAAAAcHJjdGwtc2V0LW5hbWUAAHByY3RsLWdl
dC1uYW1lAABwcmN0bC1uYW1lAAAAAAAAZ2V0cmFuZG9tAAAAAAAAAGNsb2NrLWdldHRpbWUtYQBu
YW5vc2xlZXAAAAAAAAAAY2xvY2stZ2V0dGltZS1iAHRpbWUtbm90LWZvcndhcmQAAAAAAAAAAGNs
b2NrLW5hbm9zbGVlcABjbG9jay1hYnN0aW1lLWdldHRpbWUtYQBjbG9jay1uYW5vc2xlZXAtYWJz
dGltZQBjbG9jay1hYnN0aW1lLWdldHRpbWUtYgByZXR1cm5lZC1iZWZvcmUtdGFyZ2V0AABfX05F
TVVfU1lTQ0FMTF9QUk9CRV9ET05FX18gcmM9JWQKAAAAAAAAbWVtZmQtcGF0dGVybgAAAHJlYWRi
YWNrLW1pc21hdGNoAAAAAAAAAHNvY2tldHBhaXItb2sAAABwdHktb2sAAGNoaWxkLW9rAAAAAAAA
AABuZW11LXByb2JlAAAAAAAAAPFTZQAAAAAVzVsHAAAAAAHxU2UAAAAAsWjeOgAAAAAAAAAAAAAA
AEBLTAAAAAAAAAAAAAAAAABAS0wAAAAAAAEbAzukAAAAEwAAAKi1//+ABQAAuM///7wAAACc0P//
0AAAAKjQ///kAAAAtND///gAAADA0P//DAEAACDR//84AQAAStH//1QBAACE0f//dAEAAC7U//+s
AQAADNf///gBAABa2P//RAIAAKbZ//+EAgAAyNv//xADAABm4v//wAMAAD7l//80BAAAsOX//2gE
AAAK6v//vAQAAF7r//8gBQAAAAAAABAAAAAAAAAAA3pSAAF8AQEbDQIAEAAAABgAAAD0zv//IgAA
AAAHAQAQAAAALAAAAMTP//8MAAAAAAAAABAAAABAAAAAvM///wwAAAAAAAAAEAAAAFQAAAC0z///
DAAAAAAAAAAoAAAAaAAAAKzP//9gAAAAAE4OQEKSCE6IBIkGgQJ0CsFCyELJQtJCDgBCCxgAAACU
AAAA4M///yoAAAAAQg4QUIECUMFGDgAcAAAAsAAAAO7P//86AAAAAEIOEESBAogEasFCyEYOADQA
AADQAAAACND//6oCAAAASA6wBF4OsESIBIkGgQKSCANQAQoOsAREwUTIRMlE0kQOAEILAAAASAAA
AAgBAAB60v//3gIAAABEDoAFRokGcA6AJYgEkwqUDIECkgiVDpYQlxID2gEKDoAFRMFEyETJRNJE
00TURNVE1kTXRA4AQgsAAEgAAABUAQAADNX//04BAAAARA7ABEiIBJMKboECXpIIUIkGAlrJRNJS
CsFEyETTRA4AQgtOiQaSCFbJXtJCiQaSCFjJ0kiJBpIIAAA8AAAAoAEAAA7W//9MAQAAAEIOwANE
iASJBlaBApIIAkSTCgJ000wKwULIQslC0kIOAEILAkSTCljTQpMKAAAAiAAAAOABAAAa1///IgIA
AABEDsAMSIkGkwpggQJWiASSCFCUDAK6yETBRNJE1ETJRNNEDgBCDsAMgQKJBpMKVMFEyUTTTA4A
RA7ADIECiASJBpIIkwqUDAJA1GDIRNJEwUTJRNNEDgBEDsAMgQKIBIkGkgiTCpQMAkDURJQMRMjS
1EyIBJIIlAwAAACsAAAAbAIAALDY//+eBgAAAEQOsAdEkwpeiQaBAk6SCE6IBAKOlAwCwJUOZNVI
1E7I0lTBRMlE00wOAEQOsAeBAogEiQaSCJMKlAwD3gDUVMhEwUTSRMlE00QOAEIOsAeBAogEiQaS
CJMKlAwDMAHUVJQMcNRYlAwCyJUOUJYQAkbVRNZ0lQ5Q1QJOlQ6WEFrVRNZa1EyUDJUOlhBEyNLU
1dZUiASSCJQMlQ6WEAAAAHAAAAAcAwAAnt7//9gCAAAARA7ABkiJBpIIboECbpMKUIgEAjTIRNNU
wUTJRNJEDgBCDsAGgQKIBIkGkgiTCmyWEFyUDJUOAmDIRNNE1ETVRNZQiASTCk6UDJUOlhADAAHI
09TV1lSIBJMKlAyVDpYQAAAAMAAAAJADAAAC4f//cgAAAABCDiBCiQZGgQJIiARcyETBQslCDgBC
DiCBAogEiQZ4yAAAAFAAAADEAwAAQOH//1oEAAAARA6ADUaTCngOgE2BAogEiQaSCJQMlQ6WEJcS
mBSZFgM6AQoOgA1EwUTIRMlE0kTTRNRE1UTWRNdE2ETZRA4AQgsAAGAAAAAYBAAARuX//1QBAAAA
Qg7AA0SVDlyBApYQAkSTCkyIBIkGkgiUDAJ4yELJQtJC00LUTsFC1ULWQg4AQg7AA4ECiASJBpII
kwqUDJUOlhBYyMnS09RwiASJBpIIkwqUDABcAAAAfAQAADbm//+MAQAAAEIO8ANElQ5cgQKWEAJw
kwpMiASJBpIIlAwCZshCyULSQtNC1GYKwULVQtZCDgBCC06IBIkGkgiTCpQMWMjJ0tPUaIgEiQaS
CJMKlAwAAABMAAAA3AQAACCw//8QGgAAAEIOwANCiQZkiASBApIIkwqUDJUOlhCXEpgUmRaaGAM+
EgrBQshCyULSQtNC1ELVQtZC10LYQtlC2kIOAEILAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAEAAAAAAAAAeAMAAAAAAAABAAAAAAAAAIIDAAAAAAAAIAAAAAAAAACYigAAAAAAACEAAAAAAAAA
CAAAAAAAAAAZAAAAAAAAAKCKAAAAAAAAGwAAAAAAAAAIAAAAAAAAABoAAAAAAAAAqIoAAAAAAAAc
AAAAAAAAAAgAAAAAAAAA9f7/bwAAAADYAgAAAAAAAAUAAAAAAAAA2AwAAAAAAAAGAAAAAAAAAAAD
AAAAAAAACgAAAAAAAADqAwAAAAAAAAsAAAAAAAAAGAAAAAAAAAAVAAAAAAAAAAAAAAAAAAAAAwAA
AAAAAACwjAAAAAAAAAIAAAAAAAAAMAkAAAAAAAAUAAAAAAAAAAcAAAAAAAAAFwAAAAAAAADAEgAA
AAAAAAcAAAAAAAAA6BEAAAAAAAAIAAAAAAAAAAgKAAAAAAAACQAAAAAAAAAYAAAAAAAAAB4AAAAA
AAAACAAAAAAAAAD7//9vAAAAAAEAAAgAAAAA/v//bwAAAACYEQAAAAAAAP///28AAAAAAgAAAAAA
AADw//9vAAAAAMIQAAAAAAAA+f//bwAAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//////////8AAAAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADw
GwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAb
AAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsA
AAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAA
AAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAA
AAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAA
AADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAA
APAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA
8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADw
GwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAb
AAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsA
AAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAA
AAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAA
AAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAAAADwGwAAAAAAAPAbAAAAAAAA8BsAAAAA
AACwigAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AEdDQzogKFVidW50dSAxMy4zLjAtNnVidW50dTJ+MjQuMDQuMSkgMTMuMy4wAEFSAAAAcmlzY3YA
AUgAAAAEEAVydjY0aTJwMV9tMnAwX2EycDFfZjJwMl9kMnAyX2MycDBfemljc3IycDBfemlmZW5j
ZWkycDBfem1tdWwxcDAAAC5zaHN0cnRhYgAuaW50ZXJwAC5ub3RlLmdudS5idWlsZC1pZAAubm90
ZS5BQkktdGFnAC5nbnUuaGFzaAAuZHluc3ltAC5keW5zdHIALmdudS52ZXJzaW9uAC5nbnUudmVy
c2lvbl9yAC5yZWxhLmR5bgAucmVsYS5wbHQALnRleHQALnJvZGF0YQAuZWhfZnJhbWVfaGRyAC5l
aF9mcmFtZQAucHJlaW5pdF9hcnJheQAuaW5pdF9hcnJheQAuZmluaV9hcnJheQAuZHluYW1pYwAu
Z290AC5kYXRhAC5ic3MALmNvbW1lbnQALnJpc2N2LmF0dHJpYnV0ZXMAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALAAAAAQAA
AAIAAAAAAAAAcAIAAAAAAABwAgAAAAAAACEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA
EwAAAAcAAAACAAAAAAAAAJQCAAAAAAAAlAIAAAAAAAAkAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAA
AAAAAAAAACYAAAAHAAAAAgAAAAAAAAC4AgAAAAAAALgCAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAQA
AAAAAAAAAAAAAAAAAAA0AAAA9v//bwIAAAAAAAAA2AIAAAAAAADYAgAAAAAAACQAAAAAAAAABQAA
AAAAAAAIAAAAAAAAAAAAAAAAAAAAPgAAAAsAAAACAAAAAAAAAAADAAAAAAAAAAMAAAAAAADYCQAA
AAAAAAYAAAACAAAACAAAAAAAAAAYAAAAAAAAAEYAAAADAAAAAgAAAAAAAADYDAAAAAAAANgMAAAA
AAAA6gMAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAABOAAAA////bwIAAAAAAAAAwhAAAAAA
AADCEAAAAAAAANIAAAAAAAAABQAAAAAAAAACAAAAAAAAAAIAAAAAAAAAWwAAAP7//28CAAAAAAAA
AJgRAAAAAAAAmBEAAAAAAABQAAAAAAAAAAYAAAACAAAACAAAAAAAAAAAAAAAAAAAAGoAAAAEAAAA
AgAAAAAAAADoEQAAAAAAAOgRAAAAAAAA2AAAAAAAAAAFAAAAAAAAAAgAAAAAAAAAGAAAAAAAAAB0
AAAABAAAAEIAAAAAAAAAwBIAAAAAAADAEgAAAAAAADAJAAAAAAAABQAAABQAAAAIAAAAAAAAABgA
AAAAAAAAeQAAAAEAAAAGAAAAAAAAAPAbAAAAAAAA8BsAAAAAAABABgAAAAAAAAAAAAAAAAAAEAAA
AAAAAAAQAAAAAAAAAH4AAAABAAAABgAAAAAAAAAwIgAAAAAAADAiAAAAAAAAQjcAAAAAAAAAAAAA
AAAAAAQAAAAAAAAAAAAAAAAAAACEAAAAAQAAAAIAAAAAAAAAeFkAAAAAAAB4WQAAAAAAABATAAAA
AAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAjAAAAAEAAAACAAAAAAAAAIhsAAAAAAAAiGwAAAAA
AACkAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAJoAAAABAAAAAgAAAAAAAAAwbQAAAAAA
ADBtAAAAAAAALAUAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAACkAAAAEAAAAAMAAAAAAAAA
mIoAAAAAAACYegAAAAAAAAgAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAswAAAA4AAAAD
AAAAAAAAAKCKAAAAAAAAoHoAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAL8A
AAAPAAAAAwAAAAAAAACoigAAAAAAAKh6AAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAA
AAAAAADLAAAABgAAAAMAAAAAAAAAsIoAAAAAAACwegAAAAAAAAACAAAAAAAABgAAAAAAAAAIAAAA
AAAAABAAAAAAAAAA1AAAAAEAAAADAAAAAAAAALCMAAAAAAAAsHwAAAAAAABQAwAAAAAAAAAAAAAA
AAAACAAAAAAAAAAIAAAAAAAAANkAAAABAAAAAwAAAAAAAAAAkAAAAAAAAACAAAAAAAAACAAAAAAA
AAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAADfAAAACAAAAAMAAAAAAAAACJAAAAAAAAAIgAAAAAAA
ABgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAA5AAAAAEAAAAwAAAAAAAAAAAAAAAAAAAA
CIAAAAAAAAAtAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAO0AAAADAABwAAAAAAAAAAAA
AAAAAAAAADWAAAAAAAAAUwAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAwAAAAAA
AAAAAAAAAAAAAAAAAACIgAAAAAAAAP8AAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAA
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
