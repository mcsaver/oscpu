#!/usr/bin/env bash

e2e_npc_sim_contract() {
  echo "[npc] sim contract"
  local rc=0
  e2e_print_required_files \
    npc/sim/Makefile \
    npc/sim/backends/single.mk \
    npc/sim/backends/rv64.mk \
    npc/sim/backends/soc.mk \
    npc/single/Makefile \
    npc/soc/Makefile \
    npc/rv64/Makefile \
    .github/e2e/profiles/npc-dev.tsv \
    .github/e2e/profiles/nemu-dev.tsv || rc=1

  echo "[npc] dev profile isolation"
  if e2e_file_contains .github/e2e/profiles/npc-dev.tsv '@include|software-flow' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-sim-contract|npc|e2e_npc_sim_contract' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-single-contract|npc|e2e_npc_single_contract' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-soc-contract|npc|e2e_npc_soc_contract' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-rv64-contract|npc|e2e_npc_rv64_contract'; then
    printf 'PASS npc-dev profile exposes NPC-only contract set\n'
  else
    printf 'FAIL npc-dev profile exposes NPC-only contract set\n'
    rc=1
  fi
  if e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'nemu-dev' ||
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'nemu-ubuntu' ||
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'nemu-ubuntu-full-gate'; then
    printf 'FAIL npc-dev profile must not include NEMU Ubuntu gates\n'
    rc=1
  else
    printf 'PASS npc-dev profile avoids NEMU Ubuntu gates\n'
  fi
  return "$rc"
}

e2e_npc_single_contract() {
  echo "[npc-single] contract"
  e2e_print_required_files \
    npc/single/Makefile \
    npc/single/Kconfig \
    npc/single/vsrc/filelist.mk \
    npc/single/csrc/cpu/cpu-exec.cpp
}

e2e_npc_soc_contract() {
  echo "[npc-soc] contract"
  e2e_print_required_files \
    npc/soc/Makefile \
    npc/soc/Kconfig \
    ysyxSoC/spec/cpu-interface.md \
    .github/memory/modules/ysyx-soc.md
}

e2e_npc_rv64_contract() {
  echo "[npc-rv64] contract"
  e2e_print_required_files \
    npc/rv64/Makefile \
    npc/rv64/Kconfig \
    npc/rv64/README.md \
    npc/rv64/design/history/study/README.md \
    Linux/README.md
}

e2e_npc_rv64_sv39_sret_u_mode() {
  echo "[npc-rv64] command: focused Sv39 SRET-to-U-mode regression"
  local result_dir target_log
  result_dir="$E2E_EVIDENCE_DIR/npc-rv64-sv39-sret-u-mode"
  target_log="$result_dir/logs/tb_ooo_sv39_boot.log"

  make -C "$E2E_ROOT_DIR/npc/rv64/testbench" \
    RESULT_DIR="$result_dir" \
    "$target_log"

  echo "[npc-rv64] evidence=$(e2e_relpath "$target_log")"
  grep -q '\[PASS\] tb_ooo_sv39_boot' "$target_log"
  grep -q 'sv39 page walks ifu=' "$target_log"
  grep -q '\[RESULT\] PASS' "$target_log"
}

e2e_npc_rv64_linux_focused_smokes() {
  echo "[npc-rv64] command: Linux bring-up focused smokes on NpcSimTop"
  local log_file pass_count
  log_file="$E2E_EVIDENCE_DIR/npc-rv64-linux-focused-smokes.log"
  mkdir -p "$(dirname "$log_file")"

  set -o pipefail
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-npc \
    smoke-sret-user-sv39 \
    smoke-sret-user-sv39-halfword \
    smoke-sret-restore \
    smoke-sret-user-pagefault \
    smoke-virtio-blk 2>&1 | tee "$log_file"

  echo "[npc-rv64] evidence=$(e2e_relpath "$log_file")"
  pass_count=$(grep -c 'HIT GOOD TRAP' "$log_file" || true)
  if [[ "$pass_count" -lt 5 ]]; then
    echo "[npc-rv64] expected at least 5 GOOD TRAP markers, saw $pass_count" >&2
    return 1
  fi
  grep -q 'smoke-sret-user-sv39' "$log_file"
  grep -q 'smoke-sret-user-sv39-halfword' "$log_file"
  grep -q 'smoke-sret-restore' "$log_file"
  grep -q 'smoke-sret-user-pagefault' "$log_file"
  grep -q 'smoke-virtio-blk' "$log_file"
  grep -q 'virtio-blk.*capacity=4194304 sectors' "$log_file"
}

e2e_npc_rv64_uart_rx_smoke() {
  echo "[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke"
  local result_dir tb_log run_log runtime_dir max_cycles
  result_dir="$E2E_EVIDENCE_DIR/npc-rv64-uart-rx-smoke"
  tb_log="$result_dir/module-testbench.log"
  runtime_dir="$result_dir/runtime"
  run_log="$result_dir/runtime.log"
  max_cycles="${AGENT_E2E_NPC_UART_RX_MAX_CYCLES:-8000000}"
  mkdir -p "$result_dir" "$runtime_dir"

  set -o pipefail
  make -C "$E2E_ROOT_DIR/npc/rv64/testbench" \
    TESTS="tb_uart tb_axi_to_uart" \
    RESULT_DIR="$result_dir/module-testbench" run 2>&1 | tee "$tb_log"
  local tb_rc=${PIPESTATUS[0]}
  if [[ $tb_rc -ne 0 ]]; then
    return "$tb_rc"
  fi

  NPC_OOO_WINDOW=0 NPC_UART_RX_TEXT=xy NPC_UART_RX_WAIT=OpenSBI \
    NPC_UART_RX_TRACE=1 NPC_UART_RX_TRACE_LIMIT=8 \
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
      MAX_CYCLES="$max_cycles" PROGRESS=0 LOG_DIR="$runtime_dir" run \
      2>&1 | tee "$run_log"
  local run_rc=${PIPESTATUS[0]}
  if [[ $run_rc -ne 0 ]]; then
    return "$run_rc"
  fi

  echo "[npc-rv64] evidence=$(e2e_relpath "$tb_log")"
  echo "[npc-rv64] evidence=$(e2e_relpath "$run_log")"
  echo "[npc-rv64] evidence=$(e2e_relpath "$runtime_dir/console.log")"
  echo "[npc-rv64] evidence=$(e2e_relpath "$runtime_dir/npc.log")"

  grep -q -- '- PASS tb_uart' "$tb_log"
  grep -q -- '- PASS tb_axi_to_uart' "$tb_log"
  grep -q "uart-rx.*loaded bytes=2.*wait='OpenSBI'" "$run_log"
  grep -q "uart-rx.*waiting for guest output pattern='OpenSBI'" "$run_log"
  grep -q 'OpenSBI' "$run_log"
  grep -q 'uart-rx.*wait pattern matched; releasing input' "$run_log"
  grep -q "uart-rx.*pop=1.*data=0x78" "$run_log"
  grep -q "uart-rx.*pop=2.*data=0x79" "$run_log"
}

e2e_npc_rv64_linux_rootfs_mount_smoke() {
  echo "[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop"
  local result_dir run_log console_log npc_log max_cycles timeout_s expect_marker
  result_dir="$E2E_EVIDENCE_DIR/npc-rv64-linux-rootfs-mount-smoke"
  run_log="$result_dir/run.log"
  console_log="$result_dir/console.log"
  npc_log="$result_dir/npc.log"
  max_cycles="${AGENT_E2E_NPC_ROOTFS_MOUNT_MAX_CYCLES:-340000000}"
  timeout_s="${AGENT_E2E_NPC_ROOTFS_MOUNT_TIMEOUT:-1200}"
  expect_marker='Hostname set to <ysyx-ubuntu2204>'
  mkdir -p "$result_dir"

  set -o pipefail
  NPC_OOO_WINDOW=0 timeout "${timeout_s}s" \
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
      MAX_CYCLES="$max_cycles" PROGRESS=0 LOG_DIR="$result_dir" \
      RUN_EXPECT="$expect_marker" run 2>&1 | tee "$run_log"
  local pipe_rc=${PIPESTATUS[0]}
  if [[ $pipe_rc -ne 0 ]]; then
    return "$pipe_rc"
  fi

  echo "[npc-rv64] evidence=$(e2e_relpath "$run_log")"
  echo "[npc-rv64] evidence=$(e2e_relpath "$console_log")"
  echo "[npc-rv64] evidence=$(e2e_relpath "$npc_log")"

  if grep -Eqi 'panic|Oops|Bad trap|HIT BAD TRAP|ABORT|STOP after requested budget|max cycles|TIMEOUT' "$console_log" "$npc_log"; then
    return 1
  fi

  local rc=0
  if ! grep -Eq 'Kernel command line: console=ttyS0,115200n8 root=/dev/vda rw init=(/lib/systemd/systemd|/usr/local/sbin/ysyx-npc-systemd-wrapper)' "$console_log"; then
    echo "[npc-rv64] missing Linux command line rootfs init marker" >&2
    rc=1
  fi
  if ! grep -q 'Serial: 8250/16550 driver' "$console_log"; then
    echo "[npc-rv64] missing 16550 driver marker" >&2
    rc=1
  fi
  if ! grep -q 'printk: console \[ttyS0\] enabled' "$console_log"; then
    echo "[npc-rv64] missing ttyS0 console marker" >&2
    rc=1
  fi
  if ! grep -q 'virtio_blk virtio0: \[vda\] 4194304 512-byte logical blocks' "$console_log"; then
    echo "[npc-rv64] missing virtio-blk rootfs capacity marker" >&2
    rc=1
  fi
  if ! grep -q 'EXT4-fs (vda): mounted filesystem' "$console_log"; then
    echo "[npc-rv64] missing EXT4 mount marker" >&2
    rc=1
  fi
  if ! grep -q 'VFS: Mounted root (ext4 filesystem) on device 254:0.' "$console_log"; then
    echo "[npc-rv64] missing VFS root mount marker" >&2
    rc=1
  fi
  if ! grep -Eq 'Run (/lib/systemd/systemd|/usr/local/sbin/ysyx-npc-systemd-wrapper) as init process' "$console_log"; then
    echo "[npc-rv64] missing init process marker" >&2
    rc=1
  fi
  if grep -q 'Run /usr/local/sbin/ysyx-npc-systemd-wrapper as init process' "$console_log"; then
    if ! grep -q '__NPC_SYSTEMD_CHECK_DONE__ rc=0' "$console_log"; then
      echo "[npc-rv64] missing NPC systemd wrapper preflight marker" >&2
      rc=1
    fi
    if ! grep -q 'exec systemd: /lib/systemd/systemd' "$console_log"; then
      echo "[npc-rv64] missing NPC wrapper exec systemd marker" >&2
      rc=1
    fi
  fi
  if ! grep -q 'systemd .* running in system mode' "$console_log"; then
    echo "[npc-rv64] missing systemd PID1 marker" >&2
    rc=1
  fi
  if ! grep -q 'Ubuntu 22.04' "$console_log"; then
    echo "[npc-rv64] missing Ubuntu banner marker" >&2
    rc=1
  fi
  if ! grep -q "$expect_marker" "$console_log"; then
    echo "[npc-rv64] missing hostname marker" >&2
    rc=1
  fi
  if ! grep -q 'GUEST EXPECT MATCH' "$console_log" "$npc_log"; then
    echo "[npc-rv64] missing guest-watch clean exit marker" >&2
    rc=1
  fi
  return "$rc"
}

e2e_npc_rv64_systemd_guest_check_contract() {
  echo "[npc-rv64] contract: NPC systemd guest prompt/script gate"
  local result_dir dry_log rootfs_tmp rootfs_template rootfs_run
  local rootfs_binding rootfs_sha bad_rootfs_run bad_rootfs_rc
  result_dir="$E2E_EVIDENCE_DIR/npc-rv64-systemd-guest-check-contract"
  dry_log="$result_dir/make-dry-run.log"
  mkdir -p "$result_dir"

  e2e_print_required_files \
    Linux/scripts/check-npc-systemd-guest.sh \
    Linux/scripts/npc-systemd-strict-check.sh \
    Linux/scripts/npc_systemd_transaction_evidence.py \
    Linux/scripts/tests/test_npc_systemd_strict_check.py \
    Linux/scripts/tests/test_check_npc_systemd_guest_contract.py \
    Linux/scripts/tests/test_npc_systemd_transaction_evidence.py \
    Linux/scripts/tests/fixtures/v9s-rerun4-incomplete.console \
    Linux/scripts/prepare-npc-rootfs-run-image.sh \
    Linux/Makefile \
    npc/rv64/vsrc/bus/AxiClint.v \
    npc/rv64/vsrc/core/NpcTop.v \
    npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py \
    npc/rv64/csrc/dpi.c \
    npc/rv64/csrc/cpu/cpu-exec.cpp \
    npc/rv64/csrc/monitor/log.c

  bash -n "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  bash -n "$E2E_ROOT_DIR/Linux/scripts/npc-systemd-strict-check.sh"
  bash -n "$E2E_ROOT_DIR/Linux/scripts/prepare-npc-rootfs-run-image.sh"
  python3 "$E2E_ROOT_DIR/Linux/scripts/tests/test_npc_systemd_strict_check.py"
  python3 "$E2E_ROOT_DIR/Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
  python3 "$E2E_ROOT_DIR/Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
  python3 "$E2E_ROOT_DIR/npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"
  grep -nE 'check-npc-systemd-guest|NPC_SYSTEMD_|check-npc-systemd-guest\.sh' \
    "$E2E_ROOT_DIR/Linux/Makefile" | tee "$dry_log"

  echo "[npc-rv64] evidence=$(e2e_relpath "$dry_log")"
  grep -q 'check-npc-systemd-guest.sh' "$dry_log"
  grep -q 'NPC_SYSTEMD_CHECK_MAX_CYCLES' "$dry_log"
  grep -q 'NPC_SYSTEMD_PROMPT' "$dry_log"
  grep -q 'NPC_SYSTEMD_PROGRESS' "$dry_log"
  grep -q 'NPC_UART_RX_FILE' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'NPC_UART_RX_WAIT' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'NPC_GUEST_EXPECT' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'NPC_SYSTEMD_CHECK_LOG_DIR' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'NPC_SYSTEMD_ROOTFS_WORK_IMAGE' "$E2E_ROOT_DIR/Linux/Makefile"
  grep -q 'NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256' "$E2E_ROOT_DIR/Linux/Makefile"
  grep -q 'prepare-npc-rootfs-run-image.sh' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'PROGRESS="$PROGRESS_INTERVAL"' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'abspath_from_cwd' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'LOG_DIR=$(abspath_from_cwd "$LOG_DIR")' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'Timed out waiting for device .*ttyS0' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'Failed to start .*Create System Users' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'MTIME_DIVISOR' "$E2E_ROOT_DIR/npc/rv64/vsrc/bus/AxiClint.v"
  grep -q "CLINT_MTIME_DIVISOR = 32'd10" "$E2E_ROOT_DIR/npc/rv64/vsrc/core/NpcTop.v"
  grep -q 'NPC_USER_ECALL_TRACE' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'NPC_USER_ECALL_TRACE_PRIV' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'NPC_USER_ECALL_MIN_COMMIT' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'NPC_USER_ECALL_PATH_TRACE' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'debug_ooo_satp_o' "$E2E_ROOT_DIR/npc/rv64/vsrc/sim/NpcSimTop.sv"
  grep -q "bool debug_valid = ((flags >> 63) & 0x1u) != 0;" \
    "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'NPC_USER_PROGRESS_INTERVAL' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'maybe_log_ecall_trap' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'trap_hit=' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'LogBothTag("user_ecall"' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'LogBothTag("user_progress"' "$E2E_ROOT_DIR/npc/rv64/csrc/cpu/cpu-exec.cpp"
  grep -q 'npc_systemd_transaction_evidence.py' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q 'systemd-transaction-evidence.json' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"
  grep -q '__NPC_SYSTEMD_STRICT_DONE__' "$E2E_ROOT_DIR/Linux/scripts/npc-systemd-strict-check.sh"
  grep -q 'root@ysyx-ubuntu2204:~#' "$E2E_ROOT_DIR/Linux/scripts/check-npc-systemd-guest.sh"

  rootfs_tmp=$(mktemp -d)
  rootfs_template="$rootfs_tmp/template.ext4"
  rootfs_run="$rootfs_tmp/run.ext4"
  rootfs_binding="$rootfs_tmp/binding.txt"
  bad_rootfs_run="$rootfs_tmp/bad-run.ext4"
  printf '%s\n' "rv64-rootfs-template-fixture" >"$rootfs_template"
  rootfs_sha=$(sha256sum "$rootfs_template" | awk '{print $1}')
  "$E2E_ROOT_DIR/Linux/scripts/prepare-npc-rootfs-run-image.sh" \
    --template "$rootfs_template" \
    --run-image "$rootfs_run" \
    --binding-out "$rootfs_binding" \
    --expected-template-sha256 "$rootfs_sha"
  cmp -s "$rootfs_template" "$rootfs_run"
  grep -q "rootfs_template_sha256_pre=$rootfs_sha" "$rootfs_binding"
  grep -q "rootfs_run_image_sha256_pre=$rootfs_sha" "$rootfs_binding"

  set +e
  "$E2E_ROOT_DIR/Linux/scripts/prepare-npc-rootfs-run-image.sh" \
    --template "$rootfs_template" \
    --run-image "$bad_rootfs_run" \
    --binding-out "$rootfs_tmp/bad-binding.txt" \
    --expected-template-sha256 \
      0000000000000000000000000000000000000000000000000000000000000000 \
    >"$rootfs_tmp/bad.log" 2>&1
  bad_rootfs_rc=$?
  set -e
  if [[ "$bad_rootfs_rc" -eq 0 ]]; then
    printf '%s\n' "[npc-rv64] rootfs helper accepted a mismatched template SHA" >&2
    rm -rf -- "$rootfs_tmp"
    return 1
  fi
  rm -rf -- "$rootfs_tmp"
}

e2e_npc_add_smoke() {
  echo "[npc] command: cpu-tests add ARCH=riscv32-npc via npc/sim"
  local log_tmp run_args
  run_args=${AGENT_E2E_NPC_RUN_ARGS:-$(e2e_npc_default_run_args)}
  log_tmp=$(mktemp)
  echo "[npc] run_args=$run_args"
  timeout "${AGENT_E2E_NPC_TIMEOUT:-900}s" \
    env AM_HOME="$E2E_ROOT_DIR/abstract-machine" NEMU_HOME="$E2E_ROOT_DIR/nemu" NPC_HOME="$E2E_ROOT_DIR/npc" \
    make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="$run_args" \
    | tee "$log_tmp"
  local pipe_rc=${PIPESTATUS[0]}
  if [[ $pipe_rc -ne 0 ]]; then
    rm -f "$log_tmp"
    return "$pipe_rc"
  fi
  e2e_validate_cpu_test_log "$log_tmp"
  local rc=$?
  rm -f "$log_tmp"
  return "$rc"
}

e2e_npc_selected_backend() {
  local selected
  selected=${NPC_SIM_BACKEND:-${BACKEND:-${PLATFORM:-${NPC_PLATFORM:-}}}}
  if [[ -z "$selected" ]]; then
    selected=$(sed -n 's/^CONFIG_NPC_SIM_BACKEND="\([^"]*\)"/\1/p' "$E2E_ROOT_DIR/npc/sim/include/config/auto.conf" 2>/dev/null | head -n 1)
  fi
  case "$selected" in
    "") echo "single" ;;
    am) echo "single" ;;
    ysyx-soc | ysyxSoC) echo "soc" ;;
    *) echo "$selected" ;;
  esac
}

e2e_npc_default_run_args() {
  local backend config_file
  backend=$(e2e_npc_selected_backend)
  config_file="$E2E_ROOT_DIR/npc/$backend/.config"
  if [[ -f "$config_file" ]] && grep -q '^CONFIG_NPC_DIFFTEST=y' "$config_file"; then
    echo "--diff=default --no-progress -m 0"
  else
    echo "--no-progress -m 0"
  fi
}

e2e_npc_cpu_tests_full() {
  echo "[npc] command: full cpu-tests ARCH=riscv32-npc via npc/sim"
  echo "[npc] backend follows npc/sim current configuration; override with NPC_SIM_BACKEND only when the task explicitly asks for it."

  local tests_dir expected log_tmp run_args selected_backend
  tests_dir="$E2E_ROOT_DIR/am-kernels/tests/cpu-tests/tests"
  expected=$(find "$tests_dir" -name '*.c' | wc -l)
  selected_backend=$(e2e_npc_selected_backend)
  run_args=${AGENT_E2E_NPC_RUN_ARGS:-$(e2e_npc_default_run_args)}
  log_tmp=$(mktemp)

  echo "[npc] selected_backend=$selected_backend"
  echo "[npc] run_args=$run_args"

  echo "[npc] clean stale AM/cpu-tests artifacts before full run"
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" clean; then
    rm -f "$log_tmp"
    return 1
  fi
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/abstract-machine/am" clean; then
    rm -f "$log_tmp"
    return 1
  fi
  if ! env AM_HOME="$E2E_ROOT_DIR/abstract-machine" make -C "$E2E_ROOT_DIR/abstract-machine/klib" clean; then
    rm -f "$log_tmp"
    return 1
  fi

  timeout "${AGENT_E2E_NPC_FULL_TIMEOUT:-3600}s" \
    env AM_HOME="$E2E_ROOT_DIR/abstract-machine" NEMU_HOME="$E2E_ROOT_DIR/nemu" NPC_HOME="$E2E_ROOT_DIR/npc" \
    make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" ARCH=riscv32-npc run NPC_RUN_ARGS="$run_args" \
    | tee "$log_tmp"
  local pipe_rc=${PIPESTATUS[0]}
  if [[ $pipe_rc -ne 0 ]]; then
    rm -f "$log_tmp"
    return "$pipe_rc"
  fi

  if grep -Eq '\*\*\*FAIL\*\*\*|HIT BAD TRAP|Assertion .*failed|address .*out of bound|ABORT|TIMEOUT' "$log_tmp"; then
    rm -f "$log_tmp"
    return 1
  fi

  local pass_count
  pass_count=$(grep -Ec '^\[[^]]+\].*PASS' "$log_tmp" || true)
  echo "[npc] cpu-tests pass_count=$pass_count expected=$expected"
  if [[ $pass_count -lt $expected ]]; then
    rm -f "$log_tmp"
    return 1
  fi

  rm -f "$log_tmp"
  return 0
}
