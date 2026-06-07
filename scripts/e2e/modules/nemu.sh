#!/usr/bin/env bash

e2e_nemu_config_probe() {
  echo "[nemu] config summary"
  e2e_nemu_config_summary
  echo
  e2e_print_required_files \
    nemu/Kconfig \
    nemu/Makefile \
    nemu/configs/riscv32-am_defconfig \
    nemu/configs/riscv64-am_defconfig \
    nemu/configs/riscv64-linux_defconfig \
    nemu/src/device/filelist.mk
}

e2e_nemu_am_add_smoke() {
  local arch
  arch=$(e2e_default_nemu_arch)
  if ! e2e_nemu_am_compatible; then
    echo "[nemu] SKIP: $(e2e_nemu_config_summary)，不是 CONFIG_TARGET_AM=y"
    echo "[nemu] next: 需要 AM smoke 时先切 riscv32-am_defconfig/riscv64-am_defconfig，或设置 AGENT_E2E_FORCE_SMOKE=1"
    return 77
  fi

  echo "[nemu] command: cpu-tests add ARCH=$arch"
  local log_tmp
  log_tmp=$(mktemp)
  timeout "${AGENT_E2E_QUICK_TIMEOUT:-300}s" \
    env AM_HOME="$E2E_ROOT_DIR/abstract-machine" NEMU_HOME="$E2E_ROOT_DIR/nemu" \
    make -C "$E2E_ROOT_DIR/am-kernels/tests/cpu-tests" ARCH="$arch" ALL=add run NEMUFLAGS=-b \
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

e2e_nemu_ubuntu_static_gate() {
  echo "[nemu-ubuntu] static production gate"
  e2e_print_required_files \
    Linux/Makefile \
    Linux/scripts/build-linux.sh \
    Linux/scripts/check-nemu-systemd-guest.sh \
    Linux/scripts/check-nemu-performance-config.sh \
    Linux/platform/gen_dts.py \
    Linux/platform/npc-rv64.yml \
    nemu/configs/riscv64-linux_defconfig \
    nemu/src/cpu/cpu-exec.c \
    nemu/src/cpu/Kconfig \
    nemu/src/device/serial.c \
    nemu/src/device/device.c \
    nemu/src/device/disk.c \
    nemu/src/memory/vaddr.c \
    nemu/src/isa/riscv64/inst.c \
    nemu/src/isa/riscv64/system/intr.c \
    nemu/src/isa/riscv64/system/plic.c \
    nemu/src/isa/riscv64/system/mmu.c \
    nemu/include/isa.h \
    nemu/src/device/filelist.mk

  echo
  echo "[nemu-ubuntu] script syntax"
  bash -n \
    "$E2E_ROOT_DIR/Linux/scripts/build-linux.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-performance-config.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh"

  echo
  echo "[nemu-ubuntu] DTS generator syntax"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/platform/gen_dts.py"

  echo
  echo "[nemu-ubuntu] performance config"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu check-nemu-performance-config
}

e2e_nemu_ubuntu_slice_contract() {
  echo "[nemu-ubuntu] slice contract guard"
  e2e_print_required_files \
    nemu/src/device/rng.c \
    nemu/src/device/goldfish_rtc.c \
    .github/memory/modules/nemu.md \
    .github/memory/known-issues.md

  local check_script="$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh"
  local disk_c="$E2E_ROOT_DIR/nemu/src/device/disk.c"
  local serial_c="$E2E_ROOT_DIR/nemu/src/device/serial.c"
  local device_c="$E2E_ROOT_DIR/nemu/src/device/device.c"
  local cpu_exec_c="$E2E_ROOT_DIR/nemu/src/cpu/cpu-exec.c"
  local cpu_kconfig="$E2E_ROOT_DIR/nemu/src/cpu/Kconfig"
  local linux_defconfig="$E2E_ROOT_DIR/nemu/configs/riscv64-linux_defconfig"
  local rv64_inst_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/inst.c"
  local rv64_intr_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/intr.c"
  local rv64_plic_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/plic.c"
  local vaddr_c="$E2E_ROOT_DIR/nemu/src/memory/vaddr.c"
  local mmu_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/mmu.c"
  local isa_h="$E2E_ROOT_DIR/nemu/include/isa.h"
  local gen_dts="$E2E_ROOT_DIR/Linux/platform/gen_dts.py"
  local perf_config_sh="$E2E_ROOT_DIR/Linux/scripts/check-nemu-performance-config.sh"
  local kconfig="$E2E_ROOT_DIR/nemu/src/device/Kconfig"

  echo
  echo "[nemu-ubuntu] required guest markers"
  local missing=0 pattern
  for pattern in \
    "__NEMU_CHECK_HWRNG_CURRENT__" \
    "__NEMU_CHECK_RTC0_NAME__" \
    "__NEMU_CHECK_VDA_CACHE_TYPE__" \
    "__NEMU_CHECK_VDA_DISCARD_MAX__" \
    "__NEMU_CHECK_VDA_WRITE_ZEROES_MAX__" \
    "virtio-blk-feature-config-wce" \
    "virtio-blk-feature-discard" \
    "virtio-blk-feature-topology" \
    "virtio-blk-feature-write-zeroes" \
    "virtio-ring-feature-event-idx" \
    "vda-cache-type-write-through" \
    "vda-cache-type-write-back"; do
    if grep -q "$pattern" "$check_script"; then
      printf 'PASS marker %s\n' "$pattern"
    else
      printf 'FAIL marker %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] required device/config hooks"
  for pattern in \
    "VIRTIO_BLK_F_CONFIG_WCE" \
    "VIRTIO_BLK_F_DISCARD" \
    "VIRTIO_BLK_F_TOPOLOGY" \
    "VIRTIO_BLK_F_WRITE_ZEROES" \
    "VIRTIO_RING_F_EVENT_IDX" \
    "VIRTIO_BLK_T_DISCARD" \
    "VIRTIO_BLK_T_WRITE_ZEROES" \
    "VIRTIO_BLK_CONFIG_WCE" \
    "pread(" \
    "pwrite(" \
    "guest_host_buffer" \
    "disk_pread_all(host_buf" \
    "disk_pwrite_all(host_buf"; do
    if grep -q "$pattern" "$disk_c"; then
      printf 'PASS disk.c %s\n' "$pattern"
    else
      printf 'FAIL disk.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "SERIAL_TX_BUFFER_CAP" \
    "serial_port_flush_tx" \
    "fwrite(port->tx_buffer"; do
    if grep -q "$pattern" "$serial_c"; then
      printf 'PASS serial.c %s\n' "$pattern"
    else
      printf 'FAIL serial.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "device_update_after_inst" \
    "skip += retired"; do
    if grep -q "$pattern" "$device_c"; then
      printf 'PASS device.c %s\n' "$pattern"
    else
      printf 'FAIL device.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "INTERPRETER_TB_MAX_INST" \
    "execute_basic_block" \
    "interpreter_tb_should_stop" \
    "device_update_after_inst(retired"; do
    if grep -q "$pattern" "$cpu_exec_c"; then
      printf 'PASS cpu-exec.c %s\n' "$pattern"
    else
      printf 'FAIL cpu-exec.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "config INTERPRETER_BASIC_BLOCK" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_BASIC_BLOCK\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_BASIC_BLOCK\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_BASIC_BLOCK=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_BASIC_BLOCK=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_BASIC_BLOCK=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_WIDE_IFETCH=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_WIDE_IFETCH=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_WIDE_IFETCH=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_DECODE_CACHE=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_INTR_FAST_FLAG=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_INTR_FAST_FLAG=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_INTR_FAST_FLAG=y\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_BASIC_BLOCK" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_BASIC_BLOCK\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_BASIC_BLOCK\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_WIDE_IFETCH" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_WIDE_IFETCH\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_WIDE_IFETCH\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_DECODE_CACHE" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_INTR_FAST_FLAG" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_INTR_FAST_FLAG\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_INTR_FAST_FLAG\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_WIDE_IFETCH" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_WIDE_IFETCH\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_WIDE_IFETCH\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_DECODE_CACHE" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_DECODE_CACHE\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_DECODE_CACHE\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_INTR_FAST_FLAG" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_INTR_FAST_FLAG\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_INTR_FAST_FLAG\n'
    missing=1
  fi
  for pattern in \
    "isa_riscv32_intr_pending_fast" \
    "isa_query_intr()"; do
    if grep -q "$pattern" "$cpu_exec_c"; then
      printf 'PASS cpu-exec.c %s\n' "$pattern"
    else
      printf 'FAIL cpu-exec.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_riscv32_intr_pending_fast" "$rv64_intr_c"; then
    printf 'PASS riscv64/system/intr.c isa_riscv32_intr_pending_fast\n'
  else
    printf 'FAIL riscv64/system/intr.c isa_riscv32_intr_pending_fast\n'
    missing=1
  fi
  if grep -q "isa_riscv32_plic_maybe_pending" "$rv64_plic_c"; then
    printf 'PASS riscv64/system/plic.c isa_riscv32_plic_maybe_pending\n'
  else
    printf 'FAIL riscv64/system/plic.c isa_riscv32_plic_maybe_pending\n'
    missing=1
  fi
  if grep -q "isa_riscv32_intr_pending_fast" "$isa_h"; then
    printf 'PASS isa.h isa_riscv32_intr_pending_fast\n'
  else
    printf 'FAIL isa.h isa_riscv32_intr_pending_fast\n'
    missing=1
  fi
  if grep -q "vaddr_ifetch_wide" "$rv64_inst_c"; then
    printf 'PASS riscv64/inst.c vaddr_ifetch_wide\n'
  else
    printf 'FAIL riscv64/inst.c vaddr_ifetch_wide\n'
    missing=1
  fi
  for pattern in \
    "rv_decode_cache" \
    "rv_decode_cache_inst_key" \
    "rv_decode_cache_exec" \
    "rv_decode_cache_fill" \
    "rv_decode_cache_flush"; do
    if grep -q "$pattern" "$rv64_inst_c"; then
      printf 'PASS riscv64/inst.c %s\n' "$pattern"
    else
      printf 'FAIL riscv64/inst.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "vaddr_ifetch_wide" \
    "vaddr_paddr_host_fast" \
    "vaddr_paddr_read_fast" \
    "vaddr_paddr_write_fast" \
    "host_read(trans.host_addr" \
    "host_write(trans.host_addr"; do
    if grep -q "$pattern" "$vaddr_c"; then
      printf 'PASS vaddr.c %s\n' "$pattern"
    else
      printf 'FAIL vaddr.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_mmu_translate_host" \
    "host_page" \
    "sv39_host_page_base" \
    "sv39_itlb" \
    "sv39_dtlb" \
    "sv39_tlb_set_for_type"; do
    if grep -q "$pattern" "$mmu_c"; then
      printf 'PASS mmu.c %s\n' "$pattern"
    else
      printf 'FAIL mmu.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_mmu_translate_host" "$isa_h"; then
    printf 'PASS isa.h isa_mmu_translate_host\n'
  else
    printf 'FAIL isa.h isa_mmu_translate_host\n'
    missing=1
  fi
  for pattern in \
    "google,goldfish-rtc" \
    "virtio_mmio"; do
    if grep -q "$pattern" "$gen_dts"; then
      printf 'PASS gen_dts.py %s\n' "$pattern"
    else
      printf 'FAIL gen_dts.py %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "HAS_GOLDFISH_RTC" \
    "HAS_VIRTIO_RNG"; do
    if grep -q "$pattern" "$kconfig"; then
      printf 'PASS Kconfig %s\n' "$pattern"
    else
      printf 'FAIL Kconfig %s\n' "$pattern"
      missing=1
    fi
  done

  return "$missing"
}

e2e_nemu_ubuntu_focused_gate() {
  if [[ ${AGENT_E2E_NEMU_UBUNTU_GATE:-0} != 1 ]]; then
    echo "[nemu-ubuntu] SKIP: AGENT_E2E_NEMU_UBUNTU_GATE=1 未设置，默认不跑十几分钟 focused guest gate"
    echo "[nemu-ubuntu] next: 需要完整 guest 证据时运行 AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate"
    return 77
  fi

  local gate_dir="$E2E_RUN_DIR/nemu-ubuntu-focused"
  mkdir -p "$gate_dir"
  echo "[nemu-ubuntu] focused gate log dir: $(e2e_relpath "$gate_dir")"
  timeout "${AGENT_E2E_NEMU_UBUNTU_TIMEOUT:-1700}s" \
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu \
      NEMU_SYSTEMD_CHECK_LOG_DIR="$gate_dir" \
      NEMU_SYSTEMD_SOAK_SECONDS="${AGENT_E2E_NEMU_UBUNTU_SOAK_SECONDS:-0}" \
      NEMU_SYSTEMD_FS_STRESS_MIB="${AGENT_E2E_NEMU_UBUNTU_FS_STRESS_MIB:-1}" \
      NEMU_SYSTEMD_FS_TREE_FILES="${AGENT_E2E_NEMU_UBUNTU_FS_TREE_FILES:-8}" \
      NEMU_SYSTEMD_PROCESS_LOOPS="${AGENT_E2E_NEMU_UBUNTU_PROCESS_LOOPS:-4}" \
      NEMU_SYSTEMD_UART_RX_STRESS_LINES="${AGENT_E2E_NEMU_UBUNTU_UART_RX_STRESS_LINES:-64}" \
      NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS="${AGENT_E2E_NEMU_UBUNTU_BLOCK_PARALLEL_JOBS:-1}" \
      NEMU_SYSTEMD_BLOCK_JOB_MIB="${AGENT_E2E_NEMU_UBUNTU_BLOCK_JOB_MIB:-1}" \
      check-nemu-systemd-guest

  echo
  echo "[nemu-ubuntu] focused gate markers"
  grep -aE \
    "__NEMU_CHECK_(VDA_CACHE_TYPE|VDA_DISCARD_MAX|VDA_WRITE_ZEROES_MAX|RTC0_NAME|HWRNG_CURRENT)|virtio-blk-feature-(config-wce|topology|discard|write-zeroes)|virtio-ring-feature-event-idx|__NEMU_SYSTEMD_CHECK_DONE__|HIT GOOD TRAP" \
    "$gate_dir/console.log"
}
