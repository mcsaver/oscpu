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
    Linux/scripts/build-ubuntu-rootfs.sh \
    Linux/scripts/build-ubuntu-systemd-overlay.sh \
    Linux/scripts/check-ubuntu-rootfs.sh \
    Linux/scripts/check-nemu-systemd-guest.sh \
    Linux/scripts/check-nemu-performance-config.sh \
    Linux/scripts/check-nemu-kernel-config.sh \
    Linux/scripts/check-nemu-qmp-smoke.py \
    Linux/scripts/check-nemu-gdbstub-smoke.py \
    Linux/tools/Makefile \
    Linux/tools/amo-misaligned-smoke.S \
    Linux/tools/sv39-sfence-asid-smoke.S \
    Linux/platform/gen_dts.py \
    Linux/platform/npc-rv64.yml \
    nemu/configs/riscv64-linux_defconfig \
    nemu/scripts/native.mk \
    nemu/src/cpu/cpu-exec.c \
    nemu/src/cpu/Kconfig \
    nemu/src/device/serial.c \
    nemu/src/device/uart16550.c \
    nemu/src/device/device.c \
    nemu/src/device/io/mmio.c \
    nemu/src/device/io/port-io.c \
    nemu/src/device/disk.c \
    nemu/src/device/net.c \
    nemu/src/monitor/monitor.c \
    nemu/src/monitor/qmp.c \
    nemu/src/monitor/qmp.h \
    nemu/src/monitor/gdbstub.c \
    nemu/src/monitor/gdbstub.h \
    nemu/src/monitor/sdb/sdb.c \
    nemu/src/monitor/sdb/sdb.h \
    nemu/include/utils.h \
    nemu/include/device/map.h \
    nemu/include/memory/vaddr.h \
    nemu/src/memory/vaddr.c \
    nemu/src/isa/riscv64/inst.c \
    nemu/src/isa/riscv32/inst.c \
    nemu/src/isa/riscv64/include/isa-platform.h \
    nemu/src/isa/riscv32/include/isa-platform.h \
    nemu/src/isa/riscv64/system/intr.c \
    nemu/src/isa/riscv32/system/intr.c \
    nemu/src/isa/riscv64/system/plic.c \
    nemu/src/isa/riscv64/system/mmu.c \
    nemu/src/isa/riscv32/system/mmu.c \
    nemu/include/isa.h \
    nemu/src/device/filelist.mk

  local missing=0

  echo
  echo "[nemu-ubuntu] script syntax"
  bash -n \
    "$E2E_ROOT_DIR/Linux/scripts/build-linux.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-rootfs.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-systemd-overlay.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-performance-config.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-kernel-config.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/scripts/check-nemu-qmp-smoke.py"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/scripts/check-nemu-gdbstub-smoke.py"

  echo
  echo "[nemu-ubuntu] host build jobserver contract"
  local host_build_run_dir="${E2E_RUN_DIR:-$E2E_ROOT_DIR/.github/task-runs/manual-nemu-host-build}"
  local host_build_log="$host_build_run_dir/evidence/nemu-host-build.log"
  mkdir -p "$(dirname "$host_build_log")"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu sim 2>&1 | tee "$host_build_log"
  local host_build_rc=${PIPESTATUS[0]}
  if [[ $host_build_rc -ne 0 ]]; then
    return "$host_build_rc"
  fi
  if grep -Fq "jobserver unavailable" "$host_build_log"; then
    printf 'FAIL host build log contains jobserver unavailable\n'
    missing=1
  else
    printf 'PASS host build log has no jobserver unavailable\n'
  fi
  if grep -Fq "Entering directory '$E2E_ROOT_DIR'" "$host_build_log"; then
    printf 'FAIL host build log exposes tracer root make directory noise\n'
    missing=1
  else
    printf 'PASS host build log hides tracer root make directory noise\n'
  fi
  if grep -Fq 'include $(NEMU_HOME)/../Makefile' "$E2E_ROOT_DIR/nemu/scripts/native.mk"; then
    printf 'FAIL native.mk directly includes workspace root Makefile\n'
    missing=1
  else
    printf 'PASS native.mk avoids direct workspace root Makefile include\n'
  fi

  echo
  echo "[nemu-ubuntu] DTS generator syntax"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/platform/gen_dts.py"

  echo
  echo "[nemu-ubuntu] performance config"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu check-nemu-performance-config

  echo
  echo "[nemu-ubuntu] Linux kernel config"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu check-nemu-kernel-config

  echo
  echo "[nemu-ubuntu] NEMU AMO/LR/SC misaligned smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-amo-misaligned

  echo
  echo "[nemu-ubuntu] NEMU Sv39 sfence.vma ASID/global smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-sv39-sfence-asid

  echo
  echo "[nemu-ubuntu] machine info contract"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-machine-info
  local machine_info="$E2E_ROOT_DIR/Linux/build/nemu-machine-info.txt"
  for pattern in \
    "nemu.machine_info.version=1" \
    "config.isa=riscv64" \
    "config.engine=interpreter" \
    "config.mode_system=1" \
    "config.performance=1" \
    "config.riscv_ext_b=0" \
    "config.riscv_ext_e=0" \
    "config.cache=0" \
    "config.interpreter_basic_block=1" \
    "config.interpreter_wide_ifetch=1" \
    "config.interpreter_decode_cache=1" \
    "config.interpreter_intr_fast_flag=1" \
    "platform.hart_count=1" \
    "platform.smp=unsupported" \
    "platform.pci=unsupported" \
    "platform.virtio_transport=mmio" \
    "platform.virtio_mmio_slots=3" \
    "monitor.machine_info=enabled" \
    "monitor.oneshot_cmd=enabled" \
    "monitor.qmp=startup-query-cont-stop-runtime-query" \
    "monitor.qmp.mode=startup-query-cont-stop-runtime-query-quit" \
    "debug.gdbstub=remote-readonly" \
    "debug.gdbstub.mode=startup-readonly" \
    "snapshot.vm_state=unsupported" \
    "snapshot.block=raw-sparse-overlay" \
    "block.format=raw" \
    "time.clint.enabled=1" \
    "time.clint.timebase_hz=10000000" \
    "time.clint.source=instruction" \
    "time.csr_time_source=clint_mtime" \
    "memory.base=0x80000000" \
    "memory.size=0x40000000" \
    "memory.end=0xbfffffff" \
    "device.serial.enabled=1" \
    "device.serial.mmio=0x10000000" \
    "device.serial.irq=1" \
    "device.virtio_blk.enabled=1" \
    "device.virtio_blk.mmio=0x10001000" \
    "device.virtio_blk.irq=2" \
    "device.virtio_blk.block_image=detached" \
    "device.virtio_blk.mmio_device_id=0" \
    "device.virtio_blk.capacity_bytes=0" \
    "device.virtio_blk.capacity_sectors=0" \
    "device.virtio_blk.readonly=0" \
    "device.virtio_blk.writeback=1" \
    "device.virtio_blk.queue_count=4" \
    "device.virtio_blk.multiqueue=enabled" \
    "device.virtio_blk.async=threaded-poll" \
    "device.virtio_blk.queue_num_max=64" \
    "device.virtio_blk.read_mmap=disabled" \
    "device.virtio_blk.read_mmap_bytes=0" \
    "device.virtio_blk.backing_readonly=0" \
    "device.virtio_blk.overlay=disabled" \
    "device.virtio_blk.write_target=backing" \
    "device.virtio_blk.overlay_dirty_sectors=0" \
    "device.virtio_rng.enabled=1" \
    "device.virtio_rng.mmio=0x10002000" \
    "device.virtio_rng.irq=3" \
    "device.goldfish_rtc.enabled=1" \
    "device.goldfish_rtc.mmio=0x10003000" \
    "device.goldfish_rtc.irq=4" \
    "device.virtio_net.enabled=1" \
    "device.virtio_net.mmio=0x10004000" \
    "device.virtio_net.irq=5" \
    "device.syscon_reset.enabled=1" \
    "device.syscon_reset.mmio=0x00100000" \
    "mmio.serial=0x10000000..0x10000fff" \
    "mmio.virtio-blk=0x10001000..0x10001fff" \
    "mmio.virtio-rng=0x10002000..0x10002fff" \
    "mmio.goldfish-rtc=0x10003000..0x10003fff" \
    "mmio.virtio-net=0x10004000..0x10004fff" \
    "mmio.syscon-reset=0x00100000..0x00100fff"; do
    if grep -Fxq "$pattern" "$machine_info"; then
      printf 'PASS machine-info %s\n' "$pattern"
    else
      printf 'FAIL machine-info %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] monitor one-shot command smoke"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-monitor-cmd-smoke
  local monitor_cmd_log="$E2E_ROOT_DIR/Linux/build/nemu-monitor-cmd-smoke.log"
  for pattern in \
    "[monitor-cmd] info r" \
    "x0  (" \
    "pc  ="; do
    if grep -Fq "$pattern" "$monitor_cmd_log"; then
      printf 'PASS monitor command smoke %s\n' "$pattern"
    else
      printf 'FAIL monitor command smoke %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] QMP startup query smoke"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-qmp-smoke
  local qmp_log="$E2E_ROOT_DIR/Linux/build/nemu-qmp-smoke.log"
  for pattern in \
    "PASS qmp-greeting" \
    "PASS qmp_capabilities" \
    "PASS query-status" \
    "PASS query-memory-size-summary" \
    "PASS query-cpus-fast" \
    "PASS query-block entries=0" \
    "PASS query-blockstats entries=0" \
    "PASS quit OK" \
    "PASS cont OK" \
    "PASS cont-nemu-exit rc=0" \
    "PASS cont-monitor-cmd" \
    "PASS cont-pc-reset-vector" \
    "PASS query-block-attached virtio0" \
    "PASS query-block-capacity" \
    "PASS query-block-overlay enabled" \
    "PASS query-block-read-mmap enabled" \
    "PASS query-blockstats-attached virtio0" \
    "PASS query-blockstats-zero-baseline" \
    "PASS query-blockstats-async-baseline" \
    "PASS block-quit OK" \
    "PASS block-nemu-exit rc=0" \
    "PASS runtime-qmp-greeting" \
    "PASS runtime-query-status-prelaunch prelaunch" \
    "PASS runtime-cont OK" \
    "PASS runtime-query-status running" \
    "PASS runtime-stop OK" \
    "PASS runtime-query-status-paused paused" \
    "PASS runtime-query-blockstats virtio0" \
    "PASS runtime-cont-after-stop OK" \
    "PASS runtime-query-status-resumed running" \
    "PASS runtime-quit OK" \
    "PASS runtime-nemu-exit rc=0" \
    "__NEMU_QMP_SMOKE__:ok"; do
    if grep -Fq "$pattern" "$qmp_log"; then
      printf 'PASS qmp smoke %s\n' "$pattern"
    else
      printf 'FAIL qmp smoke %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] GDB remote stub smoke"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-gdbstub-smoke
  local gdbstub_log="$E2E_ROOT_DIR/Linux/build/nemu-gdbstub-smoke.log"
  for pattern in \
    "PASS qSupported" \
    "PASS read-all-regs" \
    "PASS read-pmem-reset-vector" \
    "PASS detach OK" \
    "__NEMU_GDBSTUB_SMOKE__:ok"; do
    if grep -Fq "$pattern" "$gdbstub_log"; then
      printf 'PASS gdbstub smoke %s\n' "$pattern"
    else
      printf 'FAIL gdbstub smoke %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] rootfs-attached machine info contract"
  local rootfs_image="$E2E_ROOT_DIR/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"
  if [[ -f "$rootfs_image" ]]; then
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-rootfs-machine-info
    local rootfs_machine_info="$E2E_ROOT_DIR/Linux/build/nemu-rootfs-machine-info.txt"
    local rootfs_size rootfs_sectors
    rootfs_size=$(stat -c '%s' "$rootfs_image")
    if (( rootfs_size > 0 && rootfs_size % 512 == 0 )); then
      rootfs_sectors=$((rootfs_size / 512))
      printf 'PASS rootfs image size=%s sectors=%s\n' "$rootfs_size" "$rootfs_sectors"
    else
      rootfs_sectors=0
      printf 'FAIL rootfs image size=%s is not a positive 512-byte multiple\n' "$rootfs_size"
      missing=1
    fi
    for pattern in \
      "device.virtio_blk.enabled=1" \
      "device.virtio_blk.mmio=0x10001000" \
      "device.virtio_blk.irq=2" \
      "device.virtio_blk.block_image=attached" \
      "device.virtio_blk.mmio_device_id=2" \
      "device.virtio_blk.capacity_bytes=$rootfs_size" \
      "device.virtio_blk.capacity_sectors=$rootfs_sectors" \
      "device.virtio_blk.readonly=0" \
      "device.virtio_blk.writeback=1" \
      "device.virtio_blk.queue_count=4" \
      "device.virtio_blk.multiqueue=enabled" \
      "device.virtio_blk.async=threaded-poll" \
      "device.virtio_blk.queue_num_max=64" \
      "device.virtio_blk.read_mmap=enabled" \
      "device.virtio_blk.read_mmap_bytes=$rootfs_size" \
      "device.virtio_blk.backing_readonly=0" \
      "device.virtio_blk.overlay=disabled" \
      "device.virtio_blk.write_target=backing" \
      "device.virtio_blk.overlay_dirty_sectors=0" \
      "mmio.virtio-blk=0x10001000..0x10001fff"; do
      if grep -Fxq "$pattern" "$rootfs_machine_info"; then
        printf 'PASS rootfs machine-info %s\n' "$pattern"
      else
        printf 'FAIL rootfs machine-info %s\n' "$pattern"
        missing=1
      fi
    done

    echo
    echo "[nemu-ubuntu] rootfs-overlay machine info contract"
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu nemu-rootfs-overlay-machine-info
    local rootfs_overlay_machine_info="$E2E_ROOT_DIR/Linux/build/nemu-rootfs-overlay-machine-info.txt"
    local rootfs_overlay_stat_file="$E2E_ROOT_DIR/Linux/build/nemu-rootfs-overlay-machine-info-overlay.stat"
    local rootfs_overlay_file="$E2E_ROOT_DIR/Linux/build/nemu-rootfs-overlay-machine-info.raw"
    for pattern in \
      "device.virtio_blk.enabled=1" \
      "device.virtio_blk.mmio=0x10001000" \
      "device.virtio_blk.irq=2" \
      "device.virtio_blk.block_image=attached" \
      "device.virtio_blk.mmio_device_id=2" \
      "device.virtio_blk.capacity_bytes=$rootfs_size" \
      "device.virtio_blk.capacity_sectors=$rootfs_sectors" \
      "device.virtio_blk.readonly=0" \
      "device.virtio_blk.writeback=1" \
      "device.virtio_blk.queue_count=4" \
      "device.virtio_blk.multiqueue=enabled" \
      "device.virtio_blk.async=threaded-poll" \
      "device.virtio_blk.queue_num_max=64" \
      "device.virtio_blk.read_mmap=enabled" \
      "device.virtio_blk.read_mmap_bytes=$rootfs_size" \
      "device.virtio_blk.backing_readonly=0" \
      "device.virtio_blk.overlay=enabled" \
      "device.virtio_blk.write_target=overlay" \
      "device.virtio_blk.overlay_dirty_sectors=0" \
      "mmio.virtio-blk=0x10001000..0x10001fff"; do
      if grep -Fxq "$pattern" "$rootfs_overlay_machine_info"; then
        printf 'PASS rootfs overlay machine-info %s\n' "$pattern"
      else
        printf 'FAIL rootfs overlay machine-info %s\n' "$pattern"
        missing=1
      fi
    done
    local rootfs_overlay_stat rootfs_overlay_size rootfs_overlay_blocks
    rootfs_overlay_stat=$(cat "$rootfs_overlay_stat_file" 2>/dev/null || true)
    rootfs_overlay_size=$(printf '%s\n' "$rootfs_overlay_stat" | sed -n 's/.*overlay_size=\([0-9][0-9]*\).*/\1/p')
    rootfs_overlay_blocks=$(printf '%s\n' "$rootfs_overlay_stat" | sed -n 's/.*overlay_blocks=\([0-9][0-9]*\).*/\1/p')
    if [[ "$rootfs_overlay_size" == "$rootfs_size" && "$rootfs_overlay_blocks" == "0" ]]; then
      printf 'PASS rootfs overlay stat %s\n' "$rootfs_overlay_stat"
    else
      printf 'FAIL rootfs overlay stat %s\n' "$rootfs_overlay_stat"
      missing=1
    fi
    if [[ ! -e "$rootfs_overlay_file" ]]; then
      printf 'PASS rootfs overlay machine-info cleanup\n'
    else
      printf 'FAIL rootfs overlay machine-info cleanup left %s\n' "$rootfs_overlay_file"
      rm -f "$rootfs_overlay_file"
      missing=1
    fi
  else
    printf 'SKIP rootfs-attached machine info: missing %s\n' "$rootfs_image"
  fi

  echo
  echo "[nemu-ubuntu] rootfs DTB memory/ISA properties"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu rootfs-dtb
  local rootfs_dtb="$E2E_ROOT_DIR/Linux/build/npc-rv64-nemu-rootfs.dtb"
  local isa_base isa_exts ext mem_reg
  mem_reg=$(fdtget -t x "$rootfs_dtb" /memory@80000000 reg)
  if [[ "$mem_reg" == "0 80000000 0 40000000" ]]; then
    printf 'PASS dtb memory reg=%s\n' "$mem_reg"
  else
    printf 'FAIL dtb memory reg=%s\n' "$mem_reg"
    missing=1
  fi
  isa_base=$(fdtget -t s "$rootfs_dtb" /cpus/cpu@0 riscv,isa-base)
  if [[ "$isa_base" == "rv64i" ]]; then
    printf 'PASS dtb riscv,isa-base=%s\n' "$isa_base"
  else
    printf 'FAIL dtb riscv,isa-base=%s\n' "$isa_base"
    missing=1
  fi
  isa_exts=$(fdtget -t s "$rootfs_dtb" /cpus/cpu@0 riscv,isa-extensions)
  for ext in i m a f d c zicsr zifencei; do
    if grep -qw "$ext" <<<"$isa_exts"; then
      printf 'PASS dtb riscv,isa-extensions %s\n' "$ext"
    else
      printf 'FAIL dtb riscv,isa-extensions %s\n' "$ext"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] rootfs DTB virtio-net node"
  local net_node="/soc/virtio_mmio@10004000"
  local net_compat net_irq
  if net_compat=$(fdtget -t s "$rootfs_dtb" "$net_node" compatible 2>/dev/null); then
    if [[ "$net_compat" == "virtio,mmio" ]]; then
      printf 'PASS dtb virtio-net compatible=%s\n' "$net_compat"
    else
      printf 'FAIL dtb virtio-net compatible=%s\n' "$net_compat"
      missing=1
    fi
  else
    printf 'FAIL dtb virtio-net node missing %s\n' "$net_node"
    missing=1
  fi
  if net_irq=$(fdtget "$rootfs_dtb" "$net_node" interrupts 2>/dev/null); then
    if [[ "$net_irq" == "5" ]]; then
      printf 'PASS dtb virtio-net irq=%s\n' "$net_irq"
    else
      printf 'FAIL dtb virtio-net irq=%s\n' "$net_irq"
      missing=1
    fi
  else
    printf 'FAIL dtb virtio-net interrupts missing\n'
    missing=1
  fi
  return "$missing"
}

e2e_nemu_ubuntu_slice_contract() {
  echo "[nemu-ubuntu] slice contract guard"
  e2e_print_required_files \
    nemu/src/device/rng.c \
    nemu/src/device/net.c \
    nemu/src/device/goldfish_rtc.c \
    Linux/tools/nemu-systemd-icmp-probe.c \
    Linux/tools/nemu-systemd-dhcp-probe.c \
    Linux/tools/nemu-systemd-dns-probe.c \
    Linux/tools/nemu-systemd-tcp-probe.c \
    Linux/tools/amo-misaligned-smoke.S \
    Linux/tools/sv39-sfence-asid-smoke.S \
    nemu/src/isa/riscv64/system/mmu.c \
    nemu/src/isa/riscv64/inst.c \
    nemu/include/isa.h \
    nemu/src/monitor/monitor.c \
    nemu/src/monitor/qmp.c \
    nemu/src/monitor/qmp.h \
    nemu/src/monitor/gdbstub.c \
    nemu/src/monitor/gdbstub.h \
    nemu/src/monitor/sdb/sdb.c \
    nemu/src/monitor/sdb/sdb.h \
    nemu/scripts/native.mk \
    nemu/src/filelist.mk \
    Linux/scripts/build-ubuntu-rootfs.sh \
    Linux/scripts/build-ubuntu-systemd-overlay.sh \
    Linux/scripts/check-ubuntu-rootfs.sh \
    nemu/include/utils.h \
    .github/memory/modules/nemu.md \
    .github/memory/known-issues.md

  local check_script="$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh"
  local linux_makefile="$E2E_ROOT_DIR/Linux/Makefile"
  local build_ubuntu_rootfs_sh="$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-rootfs.sh"
  local build_ubuntu_systemd_overlay_sh="$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-systemd-overlay.sh"
  local check_ubuntu_rootfs_sh="$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh"
  local icmp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-icmp-probe.c"
  local dhcp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-dhcp-probe.c"
  local dns_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-dns-probe.c"
  local tcp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-tcp-probe.c"
  local linux_tools_mk="$E2E_ROOT_DIR/Linux/tools/Makefile"
  local amo_misaligned_smoke_s="$E2E_ROOT_DIR/Linux/tools/amo-misaligned-smoke.S"
  local sv39_sfence_asid_smoke_s="$E2E_ROOT_DIR/Linux/tools/sv39-sfence-asid-smoke.S"
  local build_linux_sh="$E2E_ROOT_DIR/Linux/scripts/build-linux.sh"
  local rng_c="$E2E_ROOT_DIR/nemu/src/device/rng.c"
  local disk_c="$E2E_ROOT_DIR/nemu/src/device/disk.c"
  local monitor_c="$E2E_ROOT_DIR/nemu/src/monitor/monitor.c"
  local qmp_c="$E2E_ROOT_DIR/nemu/src/monitor/qmp.c"
  local qmp_h="$E2E_ROOT_DIR/nemu/src/monitor/qmp.h"
  local gdbstub_c="$E2E_ROOT_DIR/nemu/src/monitor/gdbstub.c"
  local gdbstub_h="$E2E_ROOT_DIR/nemu/src/monitor/gdbstub.h"
  local sdb_c="$E2E_ROOT_DIR/nemu/src/monitor/sdb/sdb.c"
  local sdb_h="$E2E_ROOT_DIR/nemu/src/monitor/sdb/sdb.h"
  local native_mk="$E2E_ROOT_DIR/nemu/scripts/native.mk"
  local nemu_filelist_mk="$E2E_ROOT_DIR/nemu/src/filelist.mk"
  local utils_h="$E2E_ROOT_DIR/nemu/include/utils.h"
  local net_c="$E2E_ROOT_DIR/nemu/src/device/net.c"
  local serial_c="$E2E_ROOT_DIR/nemu/src/device/serial.c"
  local uart16550_c="$E2E_ROOT_DIR/nemu/src/device/uart16550.c"
  local device_c="$E2E_ROOT_DIR/nemu/src/device/device.c"
  local cpu_exec_c="$E2E_ROOT_DIR/nemu/src/cpu/cpu-exec.c"
  local cpu_kconfig="$E2E_ROOT_DIR/nemu/src/cpu/Kconfig"
  local linux_defconfig="$E2E_ROOT_DIR/nemu/configs/riscv64-linux_defconfig"
  local rv64_inst_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/inst.c"
  local rv32_inst_c="$E2E_ROOT_DIR/nemu/src/isa/riscv32/inst.c"
  local rv64_platform_h="$E2E_ROOT_DIR/nemu/src/isa/riscv64/include/isa-platform.h"
  local rv32_platform_h="$E2E_ROOT_DIR/nemu/src/isa/riscv32/include/isa-platform.h"
  local rv64_isa_def_h="$E2E_ROOT_DIR/nemu/src/isa/riscv64/include/isa-def.h"
  local rv32_isa_def_h="$E2E_ROOT_DIR/nemu/src/isa/riscv32/include/isa-def.h"
  local rv64_intr_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/intr.c"
  local rv32_intr_c="$E2E_ROOT_DIR/nemu/src/isa/riscv32/system/intr.c"
  local rv64_plic_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/plic.c"
  local vaddr_c="$E2E_ROOT_DIR/nemu/src/memory/vaddr.c"
  local vaddr_h="$E2E_ROOT_DIR/nemu/include/memory/vaddr.h"
  local mmu_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/system/mmu.c"
  local rv32_mmu_c="$E2E_ROOT_DIR/nemu/src/isa/riscv32/system/mmu.c"
  local isa_h="$E2E_ROOT_DIR/nemu/include/isa.h"
  local nemu_kconfig="$E2E_ROOT_DIR/nemu/Kconfig"
  local rv64_kconfig="$E2E_ROOT_DIR/nemu/src/isa/riscv64/Kconfig"
  local rv32_kconfig="$E2E_ROOT_DIR/nemu/src/isa/riscv32/Kconfig"
  local gen_dts="$E2E_ROOT_DIR/Linux/platform/gen_dts.py"
  local perf_config_sh="$E2E_ROOT_DIR/Linux/scripts/check-nemu-performance-config.sh"
  local kernel_config_sh="$E2E_ROOT_DIR/Linux/scripts/check-nemu-kernel-config.sh"
  local kconfig="$E2E_ROOT_DIR/nemu/src/device/Kconfig"

  echo
  echo "[nemu-ubuntu] required host build jobserver hooks"
  for pattern in \
    '+$(MAKE) -C '\''$(NEMU_HOME)'\'' NEMU_HOME='\''$(NEMU_HOME)'\'' -j'\''$(JOBS)'\''' \
    '+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-systemd-guest' \
    '+$(MAKE) -C '\''$(TOOLS_DIR)'\'''; do
    if grep -Fq "$pattern" "$linux_makefile"; then
      printf 'PASS Linux/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    'NEMU_YSYX_TRACE_MAKE' \
    '不应直接 include 根 Makefile' \
    '+@-flock $(NEMU_YSYX_TRACE_LOCK_DIR) $(MAKE) --no-print-directory -C $(NEMU_YSYX_HOME)' \
    'include $(NEMU_HOME)/scripts/build.mk'; do
    if grep -Fq "$pattern" "$native_mk"; then
      printf 'PASS native.mk %s\n' "$pattern"
    else
      printf 'FAIL native.mk %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -Fq 'include $(NEMU_HOME)/../Makefile' "$native_mk"; then
    printf 'FAIL native.mk still directly includes workspace root Makefile\n'
    missing=1
  else
    printf 'PASS native.mk has no direct workspace root Makefile include\n'
  fi

  echo
  echo "[nemu-ubuntu] required guest markers"
  local missing=0 pattern
  for pattern in \
    "__NEMU_CHECK_HWRNG_CURRENT__" \
    "__NEMU_CHECK_VIRTIO_RNG_DRIVER__" \
    "__NEMU_CHECK_VIRTIO_RNG_STATUS__" \
    "__NEMU_CHECK_VIRTIO_RNG_FEATURES__" \
    "__NEMU_CHECK_MEMTOTAL_LINE__" \
    "__NEMU_CHECK_MEMTOTAL_KB__" \
    "__NEMU_CHECK_RTC0_NAME__" \
    "__NEMU_CHECK_VIRTIO_NET_MODALIAS__" \
    "__NEMU_CHECK_VIRTIO_NET_FEATURES__" \
    "__NEMU_CHECK_VIRTIO_NET_IFACE__" \
    "__NEMU_CHECK_VIRTIO_NET_MAC__" \
    "__NEMU_CHECK_VIRTIO_NET_IPV4__" \
    "__NEMU_CHECK_VDA_CACHE_TYPE__" \
    "__NEMU_CHECK_VDA_DISCARD_MAX__" \
    "__NEMU_CHECK_VDA_WRITE_ZEROES_MAX__" \
    "__NEMU_CHECK_LSB_RELEASE__" \
    "__NEMU_GUEST_SCRIPT_SHA256__" \
    "__NEMU_GUEST_SCRIPT_READY__" \
    "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL__" \
    "__NEMU_CHECK_IRQ_VISIBLE__" \
    "virtio-blk-feature-config-wce" \
    "virtio-blk-feature-mq" \
    "virtio-blk-feature-discard" \
    "virtio-blk-feature-topology" \
    "virtio-blk-feature-write-zeroes" \
    "proc-interrupts-total" \
    "guest-memtotal-min" \
    "lsb-release-present" \
    "lsb-release-ubuntu2204" \
    "virtio-net-driver" \
    "virtio-rng-ring-feature-event-idx" \
    "virtio-net-dhcp-lease" \
    "virtio-net-dns-a" \
    "virtio-net-tcp-http" \
    "virtio-net-icmp-echo" \
    "virtio-net-ring-feature-event-idx" \
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
  for pattern in \
    "__NEMU_ICMP_PROBE_PASS__" \
    "SOCK_RAW" \
    "IPPROTO_ICMP"; do
    if grep -q "$pattern" "$icmp_probe_c"; then
      printf 'PASS icmp-probe.c %s\n' "$pattern"
    else
      printf 'FAIL icmp-probe.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "__NEMU_DHCP_PROBE_PASS__" \
    "DHCPDISCOVER" \
    "DHCPREQUEST" \
    "AF_PACKET" \
    "SOCK_RAW"; do
    if grep -q "$pattern" "$dhcp_probe_c"; then
      printf 'PASS dhcp-probe.c %s\n' "$pattern"
    else
      printf 'FAIL dhcp-probe.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "__NEMU_DNS_PROBE_PASS__" \
    "nemu.local" \
    "SOCK_DGRAM" \
    "SO_BINDTODEVICE"; do
    if grep -q "$pattern" "$dns_probe_c"; then
      printf 'PASS dns-probe.c %s\n' "$pattern"
    else
      printf 'FAIL dns-probe.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "__NEMU_TCP_PROBE_PASS__" \
    "__NEMU_TCP_PROBE_BURST__" \
    "SOCK_STREAM" \
    "SO_BINDTODEVICE" \
    "/nemu-health"; do
    if grep -q "$pattern" "$tcp_probe_c"; then
      printf 'PASS tcp-probe.c %s\n' "$pattern"
    else
      printf 'FAIL tcp-probe.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "VIRTIO_NET_DEVICE_ID" \
    "VIRTIO_NET_F_MAC" \
    "VIRTIO_NET_F_MRG_RXBUF" \
    "VIRTIO_NET_F_STATUS" \
    "VIRTIO_NET_RX_HDR_LEN" \
    "VIRTIO_RING_F_INDIRECT_DESC" \
    "VIRTIO_RING_F_EVENT_IDX" \
    "virtio_net_event_idx_enabled" \
    "virtio_net_handle_arp" \
    "virtio_net_handle_icmp" \
    "virtio_net_handle_dhcp" \
    "virtio_net_handle_dns" \
    "virtio_net_handle_tcp_http" \
    "DHCPDISCOVER" \
    "DHCPACK" \
    "DNS_QTYPE_A" \
    "TCP_HTTP_PORT" \
    "virtq_collect_table" \
    "virtio_net_handle_tx_chain" \
    "virtio_net_process_tx_queue" \
    "virtio_net_try_deliver_rx_queue" \
    "virtq_need_event" \
    "virtq_set_avail_event" \
    "virtq_validate_queue_layout" \
    "virtq_dma_range_valid" \
    "CONFIG_VIRTIO_NET_MMIO"; do
    if grep -q "$pattern" "$net_c"; then
      printf 'PASS net.c %s\n' "$pattern"
    else
      printf 'FAIL net.c %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] required host console clean hooks"
  for pattern in \
    "NEMU_SYSTEMD_NET_TCP_BURST_LOOPS" \
    "NEMU_SYSTEMD_ROOTFS_OVERLAY" \
    "NEMU_SYSTEMD_MIN_MEMTOTAL_KB" \
    "NEMU_SYSTEMD_INPUT_DELAY:-0.001" \
    "NEMU_SYSTEMD_INPUT_CHUNK_BYTES:-8" \
    "NEMU_SYSTEMD_INPUT_CHUNK_DELAY:-0" \
    "serial input model: FIFO/stdin bytes -> NEMU SerialPort staging -> 16550 RX FIFO -> Linux ttyS0" \
    "guest-check-upload.cmd" \
    "virtio-blk-async-runtime" \
    "block-overlay" \
    "rootfs overlay" \
    "ROOTFS_STAT_BEFORE" \
    "rootfs-backing-unchanged" \
    "build_guest_upload_commands" \
    "stty -echo" \
    "PS1=; PS2=; PS4=; export PS1 PS2 PS4" \
    "base64 -d" \
    "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__" \
    "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW_DIAG__" \
    "irq-vda-direct-read" \
    "net_tcp_burst_loops" \
    "input_chunk_bytes" \
    "input_chunk_delay" \
    "check_console_clean" \
    "check_shutdown_watchdog_notify" \
    "shutdown-watchdog-notify-benign" \
    "Failed to send WATCHDOG=1 notification message: Connection refused" \
    "jobserver unavailable" \
    "Failed to look up module alias 'autofs4'" \
    "does not support BPF/cgroup firewalling" \
    "Falling back to deprecated \"riscv,isa\"" \
    "System Power Off" \
    "reboot: Power down" \
    "syscon-reset: poweroff requested" \
    "Kernel panic" \
    "Oops" \
    "Call Trace" \
    "HIT BAD TRAP" \
    "EXT4-fs error" \
    "I/O error"; do
    if grep -Fq "$pattern" "$check_script"; then
      printf 'PASS check-nemu-systemd-guest.sh %s\n' "$pattern"
    else
      printf 'FAIL check-nemu-systemd-guest.sh %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] required serial console input path hooks"
  for pattern in \
    'NEMU_SERIAL_FIFO' \
    'send_guest_commands' \
    'INPUT_CHUNK_BYTES' \
    'exec 3>"$SERIAL_FIFO"' \
    'printf '\''%s'\'' "${text:$pos:$chunk_bytes}"' \
    'serial input model: FIFO/stdin bytes -> NEMU SerialPort staging -> 16550 RX FIFO -> Linux ttyS0'; do
    if grep -Fq "$pattern" "$check_script"; then
      printf 'PASS check-nemu-systemd-guest.sh %s\n' "$pattern"
    else
      printf 'FAIL check-nemu-systemd-guest.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "SERIAL_HOST_RX_STAGING_CAP" \
    "serial_host_rx_drain_to_uart" \
    "uart16550_rx_room" \
    "uart16550_receive" \
    "NEMU_SERIAL_FIFO" \
    "serial_port_poll_host"; do
    if grep -Fq "$pattern" "$serial_c"; then
      printf 'PASS serial.c %s\n' "$pattern"
    else
      printf 'FAIL serial.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "uart16550_rx_room" \
    "uart16550_receive"; do
    if grep -Fq "$pattern" "$uart16550_c"; then
      printf 'PASS uart16550.c %s\n' "$pattern"
    else
      printf 'FAIL uart16550.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "device_update_after_inst" \
    "serial_poll_input"; do
    if grep -Fq "$pattern" "$device_c"; then
      printf 'PASS device.c %s\n' "$pattern"
    else
      printf 'FAIL device.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    'stdout-path = "serial0:115200n8";' \
    "serial0 = &UART0;" \
    'compatible = "ns16550a";'; do
    if grep -Fq "$pattern" "$gen_dts"; then
      printf 'PASS gen_dts.py %s\n' "$pattern"
    else
      printf 'FAIL gen_dts.py %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "ROOTFS_INCLUDE=\${UBUNTU_ROOTFS_INCLUDE:-systemd-sysv,udev,dbus,procps,iproute2,kmod,util-linux,lsb-release}"; do
    if grep -Fq "$pattern" "$build_ubuntu_rootfs_sh"; then
      printf 'PASS build-ubuntu-rootfs.sh %s\n' "$pattern"
    else
      printf 'FAIL build-ubuntu-rootfs.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "OVERLAY_PACKAGES=\${UBUNTU_SYSTEMD_OVERLAY_PACKAGES:-\"systemd systemd-sysv udev dbus procps iproute2 kmod util-linux lsb-release login passwd adduser\"}"; do
    if grep -Fq "$pattern" "$build_ubuntu_systemd_overlay_sh"; then
      printf 'PASS build-ubuntu-systemd-overlay.sh %s\n' "$pattern"
    else
      printf 'FAIL build-ubuntu-systemd-overlay.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "/usr/bin/lsb_release" \
    "Ubuntu identity command"; do
    if grep -Fq "$pattern" "$check_ubuntu_rootfs_sh"; then
      printf 'PASS check-ubuntu-rootfs.sh %s\n' "$pattern"
    else
      printf 'FAIL check-ubuntu-rootfs.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "NEMU_SYSTEMD_CHECK_MAX_CYCLES ?= 50000000000" \
    "NEMU_SYSTEMD_ROOTFS_OVERLAY ?= \$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw" \
    "NEMU_RUN_ROOTFS_OVERLAY ?=" \
    "NEMU_RUN_ROOTFS_OVERLAY_RESET ?= 1" \
    "--block-overlay='\$(NEMU_RUN_ROOTFS_OVERLAY)'" \
    "NEMU_ROOTFS_OVERLAY_MACHINE_INFO_FILE ?= \$(BUILD_DIR)/nemu-rootfs-overlay-machine-info.txt" \
    "nemu-rootfs-overlay-machine-info: sim check-ubuntu-rootfs-systemd" \
    "block-overlay='\$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)'" \
    "NEMU_MONITOR_CMD_SMOKE_LOG ?= \$(BUILD_DIR)/nemu-monitor-cmd-smoke.log" \
    "nemu-monitor-cmd-smoke: sim" \
    "--monitor-cmd='\$(NEMU_MONITOR_CMD_SMOKE_CMD)'" \
    "NEMU_QMP_SMOKE_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke.log" \
    "NEMU_QMP_SMOKE_CONT_NEMU_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke-cont-nemu.log" \
    "NEMU_QMP_SMOKE_BLOCK_NEMU_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke-block-nemu.log" \
    "NEMU_QMP_SMOKE_RUNTIME_NEMU_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke-runtime-nemu.log" \
    "NEMU_QMP_SMOKE_OVERLAY ?= \$(BUILD_DIR)/nemu-qmp-smoke-overlay.raw" \
    "NEMU_QMP_SMOKE_RUNTIME_OVERLAY ?= \$(BUILD_DIR)/nemu-qmp-smoke-runtime-overlay.raw" \
    "NEMU_QMP_SMOKE_RUNTIME_MAX_INSTS ?= 1000000000" \
    "nemu-qmp-smoke: sim check-ubuntu-rootfs-systemd \$(OPENSBI_ROOTFS_FW) \$(NEMU_ROOTFS_DTB) \$(LINUX_IMAGE)" \
    "check-nemu-qmp-smoke.py" \
    "--block-image '\$(UBUNTU_ROOTFS_IMAGE)'" \
    "--overlay-image '\$(NEMU_QMP_SMOKE_OVERLAY)'" \
    "--runtime-overlay-image '\$(NEMU_QMP_SMOKE_RUNTIME_OVERLAY)'" \
    "--firmware '\$(OPENSBI_ROOTFS_FW)'" \
    "--kernel '\$(LINUX_IMAGE)'" \
    "--dtb '\$(NEMU_ROOTFS_DTB)'" \
    "--runtime-max-insts '\$(NEMU_QMP_SMOKE_RUNTIME_MAX_INSTS)'" \
    "NEMU_GDBSTUB_SMOKE_LOG ?= \$(BUILD_DIR)/nemu-gdbstub-smoke.log" \
    "nemu-gdbstub-smoke: sim" \
    "check-nemu-gdbstub-smoke.py" \
    "NEMU_SYSTEMD_INPUT_CHUNK_BYTES ?= 8" \
    "NEMU_SYSTEMD_INPUT_CHUNK_DELAY ?= 0" \
    "NEMU_SYSTEMD_ROOTFS_OVERLAY='\$(NEMU_SYSTEMD_ROOTFS_OVERLAY)'" \
    "NEMU_SYSTEMD_INPUT_CHUNK_BYTES='\$(NEMU_SYSTEMD_INPUT_CHUNK_BYTES)'" \
    "NEMU_SYSTEMD_INPUT_CHUNK_DELAY='\$(NEMU_SYSTEMD_INPUT_CHUNK_DELAY)'"; do
    if grep -Fq -- "$pattern" "$linux_makefile"; then
      printf 'PASS Linux/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/Makefile %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] default run overlay dry-run"
  local run_dry_log="$E2E_RUN_DIR/evidence/nemu-run-overlay-dry.log"
  mkdir -p "$(dirname "$run_dry_log")"
  if make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu -n run > "$run_dry_log"; then
    printf 'PASS make -n run\n'
  else
    printf 'FAIL make -n run\n'
    missing=1
  fi
  for pattern in \
    "--block='$E2E_ROOT_DIR/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4'" \
    "--block-overlay='$E2E_ROOT_DIR/Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs/rootfs-overlay.raw'" \
    "rm -f '$E2E_ROOT_DIR/Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs/rootfs-overlay.raw'" \
    "[Linux] overlay:"; do
    if grep -Fq -- "$pattern" "$run_dry_log"; then
      printf 'PASS run dry %s\n' "$pattern"
    else
      printf 'FAIL run dry %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "check-nemu-kernel-config" \
    "LINUX_KERNEL_CONFIG='\$(ENV_ROOT)/src/linux/.config'" \
    "\$(LINUX_IMAGE): \$(SCRIPT_DIR)/build-linux.sh"; do
    if grep -Fq -- "$pattern" "$linux_makefile"; then
      printf 'PASS Linux/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  local memtotal_line uart_stress_line
  memtotal_line=$(awk '/GUEST_CMDS/ {in_guest=1; next} in_guest && /memtotal_kb=/ {print NR; exit}' "$check_script")
  uart_stress_line=$(awk '/GUEST_CMDS/ {in_guest=1; next} in_guest && /__NEMU_UART_RX_STRESS_COMMANDS__/ {print NR; exit}' "$check_script")
  if [[ -n "$memtotal_line" && -n "$uart_stress_line" && "$memtotal_line" -lt "$uart_stress_line" ]]; then
    printf 'PASS check-nemu-systemd-guest.sh memtotal-before-uart-rx-stress\n'
  else
    printf 'FAIL check-nemu-systemd-guest.sh memtotal-before-uart-rx-stress\n'
    missing=1
  fi

  echo
  echo "[nemu-ubuntu] required device/config hooks"
  for pattern in \
    "VIRTIO_RING_F_EVENT_IDX" \
    "virtio_rng_event_idx_enabled" \
    "virtq_used_event_addr" \
    "virtq_avail_event_addr" \
    "virtq_need_event" \
    "virtq_set_avail_event" \
    "virtq_validate_queue_layout" \
    "virtq_dma_range_valid" \
    "reject unsupported QueueNum"; do
    if grep -q "$pattern" "$rng_c"; then
      printf 'PASS rng.c %s\n' "$pattern"
    else
      printf 'FAIL rng.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "VIRTIO_BLK_F_CONFIG_WCE" \
    "VIRTIO_BLK_F_MQ" \
    "VIRTIO_BLK_F_DISCARD" \
    "VIRTIO_BLK_F_TOPOLOGY" \
    "VIRTIO_BLK_F_WRITE_ZEROES" \
    "VIRTIO_RING_F_EVENT_IDX" \
    "VIRTIO_BLK_T_DISCARD" \
    "VIRTIO_BLK_T_WRITE_ZEROES" \
    "VIRTIO_BLK_CONFIG_WCE" \
    "pread(" \
    "pwrite(" \
    "mmap(" \
    "disk_mmap_read" \
    "read_mmap" \
    "disk_backing_pread_all" \
    "disk_overlay_pread_all" \
    "disk_overlay_pwrite_all" \
    "disk_overlay_prepare_write" \
    "disk_overlay_dirty" \
    "write_target" \
    "overlay_dirty_sectors" \
    "VIRTIO_BLK_QUEUE_COUNT" \
    "VIRTIO_BLK_CONFIG_NUM_QUEUES" \
    "VIRTIO_BLK_ASYNC_BACKEND" \
    "VirtioBlkAsyncReq" \
    "virtio_blk_worker_main" \
    "virtio_blk_submit_request" \
    "virtio_blk_complete_request" \
    "virtio_blk_update" \
    "virtio_blk_statistic" \
    "selected_queue" \
    "virtio_blk_process_queue(value)" \
    "virtio_blk_build_request" \
    "virtio_blk_req_copy_from_guest" \
    "virtio_blk_req_copy_to_guest" \
    "virtq_validate_queue_layout" \
    "virtq_dma_range_valid" \
    "reject unsupported QueueNum"; do
    if grep -q "$pattern" "$disk_c"; then
      printf 'PASS disk.c %s\n' "$pattern"
    else
      printf 'FAIL disk.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "OPT_BLOCK_OVERLAY" \
    "block-overlay" \
    "disk_set_overlay" \
    "OPT_MONITOR_CMD" \
    "monitor-cmd" \
    "OPT_QMP" \
    "qmp" \
    "OPT_GDBSTUB" \
    "gdbstub" \
    "add_monitor_cmd" \
    "run_monitor_cmds_and_exit" \
    "qmp_wait_for_client_if_enabled" \
    "gdbstub_wait_for_client_if_enabled" \
    "sdb_exec_line"; do
    if grep -q "$pattern" "$monitor_c"; then
      printf 'PASS monitor.c %s\n' "$pattern"
    else
      printf 'FAIL monitor.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "qmp_set_port" \
    "qmp_capability" \
    "qmp_wait_for_client_if_enabled" \
    "atomic_bool qmp_cont_requested" \
    "atomic_bool qmp_stop_requested" \
    "pthread_cond_t qmp_pause_cond" \
    "atomic_exchange_explicit" \
    "qmp_cpu_pause_point" \
    "pthread_cond_wait" \
    "qmp_capabilities" \
    "query-status" \
    "query-memory-size-summary" \
    "query-block" \
    "virtio_blk_qmp_query_block" \
    "query-blockstats" \
    "virtio_blk_qmp_query_blockstats" \
    "query-cpus-fast" \
    "cont" \
    "stop" \
    "qmp_start_runtime_client" \
    "qmp_runtime_client_main" \
    "QMP runtime client active" \
    "QMP cont requested" \
    "QMP stop requested" \
    "QMP CPU paused" \
    "QMP listening"; do
    if grep -q "$pattern" "$qmp_c"; then
      printf 'PASS qmp.c %s\n' "$pattern"
    else
      printf 'FAIL qmp.c %s\n' "$pattern"
      missing=1
    fi
  done

  for pattern in \
    "../monitor/qmp.h" \
    "qmp_cpu_pause_point"; do
    if grep -q "$pattern" "$cpu_exec_c"; then
      printf 'PASS cpu-exec.c qmp-pause %s\n' "$pattern"
    else
      printf 'FAIL cpu-exec.c qmp-pause %s\n' "$pattern"
      missing=1
    fi
  done

  if grep -q "_Atomic int state" "$utils_h"; then
    printf 'PASS utils.h _Atomic int state\n'
  else
    printf 'FAIL utils.h _Atomic int state\n'
    missing=1
  fi

  # QMP runtime 线程不是纯源码能力，构建规则也必须显式链接 pthread。
  for pattern in \
    "CFLAGS += -pthread" \
    "LIBS += -pthread"; do
    if grep -Fq "$pattern" "$nemu_filelist_mk"; then
      printf 'PASS src/filelist.mk %s\n' "$pattern"
    else
      printf 'FAIL src/filelist.mk %s\n' "$pattern"
      missing=1
    fi
  done

  for pattern in \
    "virtio_blk_qmp_query_block" \
    "virtio_blk_qmp_query_blockstats" \
    "VirtioBlkStats" \
    "capacity-bytes" \
    "overlay-dirty-sectors" \
    "read-mmap" \
    "async-submitted" \
    "rd_bytes" \
    "wr_operations" \
    "failed-operations"; do
    if grep -q "$pattern" "$disk_c"; then
      printf 'PASS disk.c qmp-block %s\n' "$pattern"
    else
      printf 'FAIL disk.c qmp-block %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "bool qmp_wait_for_client_if_enabled(void);" "$qmp_h"; then
    printf 'PASS qmp.h qmp_wait_for_client_if_enabled prototype\n'
  else
    printf 'FAIL qmp.h qmp_wait_for_client_if_enabled prototype\n'
    missing=1
  fi
  if grep -q "void qmp_cpu_pause_point(void);" "$qmp_h"; then
    printf 'PASS qmp.h qmp_cpu_pause_point prototype\n'
  else
    printf 'FAIL qmp.h qmp_cpu_pause_point prototype\n'
    missing=1
  fi
  for pattern in \
    "gdbstub_set_port" \
    "gdbstub_capability" \
    "gdbstub_wait_for_client_if_enabled" \
    "qSupported" \
    "handle_read_all_regs" \
    "handle_read_memory" \
    "GDB stub listening"; do
    if grep -q "$pattern" "$gdbstub_c"; then
      printf 'PASS gdbstub.c %s\n' "$pattern"
    else
      printf 'FAIL gdbstub.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "void gdbstub_wait_for_client_if_enabled(void);" "$gdbstub_h"; then
    printf 'PASS gdbstub.h gdbstub_wait_for_client_if_enabled prototype\n'
  else
    printf 'FAIL gdbstub.h gdbstub_wait_for_client_if_enabled prototype\n'
    missing=1
  fi
  for pattern in \
    "sdb_exec_line" \
    "cmd_table[i].handler" \
    "Unknown command"; do
    if grep -Fq "$pattern" "$sdb_c"; then
      printf 'PASS sdb.c %s\n' "$pattern"
    else
      printf 'FAIL sdb.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "int sdb_exec_line(char \\*line);" "$sdb_h"; then
    printf 'PASS sdb.h sdb_exec_line prototype\n'
  else
    printf 'FAIL sdb.h sdb_exec_line prototype\n'
    missing=1
  fi
  if grep -q "int is_exit_status_bad(void);" "$utils_h"; then
    printf 'PASS utils.h is_exit_status_bad prototype\n'
  else
    printf 'FAIL utils.h is_exit_status_bad prototype\n'
    missing=1
  fi
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
  if grep -q "CONFIG_HAS_VIRTIO_NET=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_HAS_VIRTIO_NET=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_HAS_VIRTIO_NET=y\n'
    missing=1
  fi
  if grep -q "CONFIG_MSIZE=0x40000000" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_MSIZE=0x40000000\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_MSIZE=0x40000000\n'
    missing=1
  fi
  if grep -q "CONFIG_VIRTIO_NET" "$build_linux_sh"; then
    printf 'PASS build-linux.sh CONFIG_VIRTIO_NET\n'
  else
    printf 'FAIL build-linux.sh CONFIG_VIRTIO_NET\n'
    missing=1
  fi
  for pattern in \
    "CONFIG_AUTOFS_FS" \
    "CONFIG_BPF_SYSCALL" \
    "CONFIG_CGROUP_BPF"; do
    if grep -q "$pattern" "$build_linux_sh"; then
      printf 'PASS build-linux.sh %s\n' "$pattern"
    else
      printf 'FAIL build-linux.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "require_config_enabled CONFIG_AUTOFS_FS" \
    "require_config_enabled CONFIG_BPF_SYSCALL" \
    "require_config_enabled CONFIG_CGROUP_BPF" \
    "__NEMU_KERNEL_CONFIG__:ok"; do
    if grep -q "$pattern" "$kernel_config_sh"; then
      printf 'PASS check-nemu-kernel-config.sh %s\n' "$pattern"
    else
      printf 'FAIL check-nemu-kernel-config.sh %s\n' "$pattern"
      missing=1
    fi
  done
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
  if grep -q "require_config_value CONFIG_MSIZE 0x40000000" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_MSIZE=0x40000000\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_MSIZE=0x40000000\n'
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
    "isa_riscv_intr_pending_fast" \
    "isa_query_intr()"; do
    if grep -q "$pattern" "$cpu_exec_c"; then
      printf 'PASS cpu-exec.c %s\n' "$pattern"
    else
      printf 'FAIL cpu-exec.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_riscv64_intr_pending_fast" "$rv64_intr_c"; then
    printf 'PASS riscv64/system/intr.c isa_riscv64_intr_pending_fast\n'
  else
    printf 'FAIL riscv64/system/intr.c isa_riscv64_intr_pending_fast\n'
    missing=1
  fi
  if grep -q 'source "src/isa/riscv64/Kconfig"' "$nemu_kconfig" &&
     grep -q 'source "src/isa/riscv32/Kconfig"' "$nemu_kconfig"; then
    printf 'PASS nemu/Kconfig width-specific riscv Kconfig sources\n'
  else
    printf 'FAIL nemu/Kconfig width-specific riscv Kconfig sources\n'
    missing=1
  fi
  if grep -q 'ISA-dependent Options for riscv64' "$rv64_kconfig" &&
     grep -q 'ISA-dependent Options for riscv32' "$rv32_kconfig"; then
    printf 'PASS riscv32/riscv64 Kconfig menu split\n'
  else
    printf 'FAIL riscv32/riscv64 Kconfig menu split\n'
    missing=1
  fi
  if grep -q 'config RVE' "$rv32_kconfig" &&
     grep -q 'config SOC_SIM' "$rv32_kconfig" &&
     ! grep -Eq 'config RVE|config SOC_SIM|RV32[MC]' "$rv64_kconfig"; then
    printf 'PASS riscv32-only Kconfig options stay out of riscv64 Kconfig\n'
  else
    printf 'FAIL riscv32-only Kconfig options stay out of riscv64 Kconfig\n'
    missing=1
  fi
  for pattern in \
    "CLINT_TIMEBASE_HZ      10000000ull" \
    "isa_riscv64_clint_timebase_hz" \
    "isa_riscv64_mtime_value" \
    "isa_riscv64_clint_time_source" \
    "return \"instruction\""; do
    if grep -q "$pattern" "$rv64_intr_c"; then
      printf 'PASS riscv64/system/intr.c %s\n' "$pattern"
    else
      printf 'FAIL riscv64/system/intr.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "CLINT_TIMEBASE_HZ      10000000ull" \
    "isa_riscv32_mtime_value"; do
    if grep -q "$pattern" "$rv32_intr_c"; then
      printf 'PASS riscv32/system/intr.c %s\n' "$pattern"
    else
      printf 'FAIL riscv32/system/intr.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_riscv64_plic_maybe_pending" "$rv64_plic_c"; then
    printf 'PASS riscv64/system/plic.c isa_riscv64_plic_maybe_pending\n'
  else
    printf 'FAIL riscv64/system/plic.c isa_riscv64_plic_maybe_pending\n'
    missing=1
  fi
  if grep -Eq 'isa_riscv32_|exec_rv32|riscv32_|CONFIG_RVE' \
      "$rv64_inst_c" "$rv64_intr_c" "$rv64_plic_c" "$mmu_c" \
      "$rv64_platform_h" "$rv64_isa_def_h" "$rv64_kconfig"; then
    printf 'FAIL riscv64 ISA files contain stale RV32/RVE symbols\n'
    missing=1
  else
    printf 'PASS riscv64 ISA files contain no RV32/RVE symbols\n'
  fi
  if grep -Eq 'exec_rv32i_|exec_rv32c|RV32I|RV32C' "$rv64_inst_c"; then
    printf 'FAIL riscv64/inst.c contains stale RV32 helper names\n'
    missing=1
  else
    printf 'PASS riscv64/inst.c helper names are RV64-specific\n'
  fi
  if grep -Eq 'isa_riscv64_|exec_rv64|riscv64_|CONFIG_ISA64|SATP64|Sv39|sv39|OP_IMM_32|OP_32|\.uw|c\.ld|c\.sd|c\.addiw|c\.subw|c\.addw|lwu|mulw' \
      "$rv32_inst_c" "$rv32_mmu_c" "$rv32_platform_h" "$rv32_isa_def_h"; then
    printf 'FAIL riscv32 ISA files contain stale RV64/ISA64 symbols\n'
    missing=1
  else
    printf 'PASS riscv32 ISA files contain no RV64/ISA64 symbols\n'
  fi
  if grep -q 'riscv64_CSR_state' "$rv64_isa_def_h" &&
     grep -q 'riscv64_CPU_state' "$rv64_isa_def_h" &&
     grep -q 'riscv64_ISADecodeInfo' "$rv64_isa_def_h" &&
     ! grep -Eq 'riscv32_CSR_state|riscv32_CPU_state|riscv32_ISADecodeInfo|MUXDEF\(CONFIG_RV64' "$rv64_isa_def_h"; then
    printf 'PASS riscv64 isa-def.h exports only riscv64 types\n'
  else
    printf 'FAIL riscv64 isa-def.h exports only riscv64 types\n'
    missing=1
  fi
  if grep -q 'riscv32_CSR_state' "$rv32_isa_def_h" &&
     grep -q 'riscv32_CPU_state' "$rv32_isa_def_h" &&
     grep -q 'riscv32_ISADecodeInfo' "$rv32_isa_def_h" &&
     ! grep -Eq 'riscv64_CSR_state|riscv64_CPU_state|riscv64_ISADecodeInfo|MUXDEF\(CONFIG_RV64' "$rv32_isa_def_h"; then
    printf 'PASS riscv32 isa-def.h exports only riscv32 types\n'
  else
    printf 'FAIL riscv32 isa-def.h exports only riscv32 types\n'
    missing=1
  fi
  if grep -q "#include <isa-platform.h>" "$isa_h" &&
     ! grep -Eq 'isa_riscv32_|isa_riscv64_|CONFIG_ISA64|CONFIG_RVE' "$isa_h"; then
    printf 'PASS isa.h delegates RISC-V platform hooks to ISA-local header\n'
  else
    printf 'FAIL isa.h delegates RISC-V platform hooks to ISA-local header\n'
    missing=1
  fi
  for pattern in \
    "isa_riscv64_clint_timebase_hz" \
    "isa_riscv_clint_timebase_hz" \
    "isa_riscv64_mtime_value" \
    "isa_riscv_mtime_value" \
    "isa_riscv64_clint_time_source" \
    "isa_riscv_clint_time_source" \
    "isa_mmu_translate_host"; do
    if grep -q "$pattern" "$rv64_platform_h"; then
      printf 'PASS riscv64 isa-platform.h %s\n' "$pattern"
    else
      printf 'FAIL riscv64 isa-platform.h %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_riscv32_clint_timebase_hz" \
    "isa_riscv_clint_timebase_hz" \
    "isa_riscv32_mtime_value" \
    "isa_riscv_mtime_value" \
    "isa_riscv32_clint_time_source" \
    "isa_riscv_clint_time_source"; do
    if grep -q "$pattern" "$rv32_platform_h"; then
      printf 'PASS riscv32 isa-platform.h %s\n' "$pattern"
    else
      printf 'FAIL riscv32 isa-platform.h %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "CSR_TIME:.*isa_riscv64_mtime_value" "$rv64_inst_c"; then
    printf 'PASS riscv64/inst.c CSR_TIME uses mtime\n'
  else
    printf 'FAIL riscv64/inst.c CSR_TIME uses mtime\n'
    missing=1
  fi
  if grep -q "CSR_TIME:.*isa_riscv32_mtime_value" "$rv32_inst_c"; then
    printf 'PASS riscv32/inst.c CSR_TIME uses mtime\n'
  else
    printf 'FAIL riscv32/inst.c CSR_TIME uses mtime\n'
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
    "vaddr_set_fault" \
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
  if grep -q "vaddr_set_fault" "$vaddr_h"; then
    printf 'PASS vaddr.h vaddr_set_fault\n'
  else
    printf 'FAIL vaddr.h vaddr_set_fault\n'
    missing=1
  fi
  for pattern in \
    "amo_raise_misaligned" \
    "CAUSE_LOAD_MISALIGNED" \
    "CAUSE_STORE_MISALIGNED"; do
    if grep -q "$pattern" "$rv64_inst_c"; then
      printf 'PASS riscv64/inst.c %s\n' "$pattern"
    else
      printf 'FAIL riscv64/inst.c %s\n' "$pattern"
      missing=1
    fi
    if grep -q "$pattern" "$rv32_inst_c"; then
      printf 'PASS riscv32/inst.c %s\n' "$pattern"
    else
      printf 'FAIL riscv32/inst.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-amo-misaligned" \
    "amo-misaligned-smoke.S" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-sv39-sfence-asid" \
    "sv39-sfence-asid-smoke.S" \
    "SV39_SFENCE_ASID_BIN" \
    "NEMU_SV39_SFENCE_ASID_LOG" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "lr.w" \
    "sc.w" \
    "amoadd.w" \
    "lr.d" \
    "sc.d" \
    "amoadd.d" \
    "csrr t0, mcause" \
    "csrr t0, mtval" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$amo_misaligned_smoke_s"; then
      printf 'PASS amo-misaligned-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL amo-misaligned-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "VA_NONGLOBAL" \
    "VA_GLOBAL" \
    "SATP_ASID1" \
    "SATP_ASID2" \
    "PTE_G_VRWAD" \
    "switch_sv39_asid" \
    "csrw satp, t4" \
    "sfence.vma t0, t1" \
    "sfence.vma t0, zero" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$sv39_sfence_asid_smoke_s"; then
      printf 'PASS sv39-sfence-asid-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL sv39-sfence-asid-smoke.S %s\n' "$pattern"
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
  for pattern in \
    "SATP64_ASID" \
    "PTE_G" \
    "root_ppn" \
    "global" \
    "sv39_tlb_flush_set" \
    "isa_riscv64_mmu_tlb_flush_selective"; do
    if grep -q "$pattern" "$mmu_c"; then
      printf 'PASS mmu.c %s\n' "$pattern"
    else
      printf 'FAIL mmu.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_riscv64_mmu_tlb_flush_selective" \
    "satp 切换本身不需要粗暴全刷" \
    "rs1 != 0" \
    "rs2 != 0"; do
    if grep -q "$pattern" "$rv64_inst_c"; then
      printf 'PASS riscv64/inst.c %s\n' "$pattern"
    else
      printf 'FAIL riscv64/inst.c %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_mmu_translate_host" "$rv64_platform_h"; then
    printf 'PASS riscv64 isa-platform.h isa_mmu_translate_host\n'
  else
    printf 'FAIL riscv64 isa-platform.h isa_mmu_translate_host\n'
    missing=1
  fi
  if grep -q "isa_riscv_mmu_tlb_flush_selective" "$rv64_platform_h" &&
     grep -q "isa_riscv_mmu_tlb_flush_selective" "$rv32_platform_h"; then
    printf 'PASS ISA-local platform headers isa_riscv_mmu_tlb_flush_selective\n'
  else
    printf 'FAIL ISA-local platform headers isa_riscv_mmu_tlb_flush_selective\n'
    missing=1
  fi
  for pattern in \
    "google,goldfish-rtc" \
    "virtio_mmio" \
    "virtio_net" \
    "--virtio-net" \
    "timebase-frequency = <10000000>" \
    "riscv,isa-base" \
    "riscv,isa-extensions"; do
    if grep -q -- "$pattern" "$gen_dts"; then
      printf 'PASS gen_dts.py %s\n' "$pattern"
    else
      printf 'FAIL gen_dts.py %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "HAS_GOLDFISH_RTC" \
    "HAS_VIRTIO_RNG" \
    "HAS_VIRTIO_NET"; do
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
  local gate_rc=0
  timeout "${AGENT_E2E_NEMU_UBUNTU_TIMEOUT:-1700}s" \
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu \
      NEMU_SYSTEMD_CHECK_LOG_DIR="$gate_dir" \
      NEMU_SYSTEMD_SOAK_SECONDS="${AGENT_E2E_NEMU_UBUNTU_SOAK_SECONDS:-0}" \
      NEMU_SYSTEMD_FS_STRESS_MIB="${AGENT_E2E_NEMU_UBUNTU_FS_STRESS_MIB:-1}" \
      NEMU_SYSTEMD_FS_TREE_FILES="${AGENT_E2E_NEMU_UBUNTU_FS_TREE_FILES:-8}" \
      NEMU_SYSTEMD_PROCESS_LOOPS="${AGENT_E2E_NEMU_UBUNTU_PROCESS_LOOPS:-4}" \
      NEMU_SYSTEMD_UART_RX_STRESS_LINES="${AGENT_E2E_NEMU_UBUNTU_UART_RX_STRESS_LINES:-64}" \
      NEMU_SYSTEMD_INPUT_CHUNK_BYTES="${AGENT_E2E_NEMU_UBUNTU_INPUT_CHUNK_BYTES:-8}" \
      NEMU_SYSTEMD_INPUT_CHUNK_DELAY="${AGENT_E2E_NEMU_UBUNTU_INPUT_CHUNK_DELAY:-0}" \
      NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS="${AGENT_E2E_NEMU_UBUNTU_BLOCK_PARALLEL_JOBS:-1}" \
      NEMU_SYSTEMD_BLOCK_JOB_MIB="${AGENT_E2E_NEMU_UBUNTU_BLOCK_JOB_MIB:-1}" \
      check-nemu-systemd-guest || gate_rc=$?

  echo
  echo "[nemu-ubuntu] focused gate markers"
  grep -aE \
    "__NEMU_CHECK_(MEMTOTAL_KB|MIN_MEMTOTAL_KB|VDA_CACHE_TYPE|VDA_DISCARD_MAX|VDA_WRITE_ZEROES_MAX|RTC0_NAME|HWRNG_CURRENT|VIRTIO_RNG_(MODALIAS|DRIVER|STATUS|FEATURES)|VIRTIO_NET_(MODALIAS|DRIVER|STATUS|FEATURES|IFACE|MAC|IPV4|OPERSTATE|TX_PACKETS_(BEGIN|END)|RX_PACKETS_(BEGIN|END)|ROUTE|NEIGH|ARP))|__NEMU_(ICMP|DHCP|DNS|TCP)_PROBE_(BURST|ITER|CONNECT|TX|RX|OFFER|ACK|PASS|FAIL)__|virtio-(blk-feature-(config-wce|topology|discard|write-zeroes)|rng-(modalias|driver|features-bitstring|feature-version-1|ring-feature-event-idx)|net-(modalias|driver|features-bitstring|feature-(version-1|mac|mrg-rxbuf|status)|ring-feature-(indirect-desc|event-idx)|interface|mac|ipv4-static|icmp-echo|dhcp-lease|dns-a|tcp-http))|guest-memtotal-min|virtio-ring-feature-event-idx|__NEMU_SYSTEMD_CHECK_DONE__|HIT GOOD TRAP" \
    "$gate_dir/console.log" || true
  grep -aE "virtio-blk async runtime|virtio-blk-async-runtime" \
    "$gate_dir/nemu.log" "$gate_dir/console.log" "$E2E_RUN_DIR/evidence/nemu-ubuntu-focused-gate.log" 2>/dev/null || true

  if [ "$gate_rc" -ne 0 ]; then
    printf 'FAIL focused gate command rc=%s\n' "$gate_rc"
    return "$gate_rc"
  fi
  if grep -qaF "__NEMU_SYSTEMD_CHECK_DONE__ rc=0" "$gate_dir/console.log" &&
     ! grep -qaE "^__NEMU_CHECK_FAIL__:" "$gate_dir/console.log" &&
     grep -qaF "HIT GOOD TRAP" "$gate_dir/console.log"; then
    printf 'PASS focused guest rc=0 no check failures good trap\n'
  else
    printf 'FAIL focused guest completion markers\n'
    return 1
  fi
}
