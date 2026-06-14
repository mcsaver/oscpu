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
    Linux/scripts/gen-nemu-hostless-apt-assets.py \
    Linux/scripts/ubuntu-rootfs-flavors.sh \
    Linux/scripts/check-ubuntu-rootfs.sh \
    Linux/scripts/check-nemu-systemd-guest.sh \
    Linux/scripts/check-nemu-performance-config.sh \
    Linux/scripts/check-nemu-kernel-config.sh \
    Linux/scripts/check-nemu-qmp-smoke.py \
    Linux/scripts/check-nemu-gdbstub-smoke.py \
    Linux/tools/Makefile \
    Linux/tools/amo-misaligned-smoke.S \
    Linux/tools/lrsc-reservation-smoke.S \
    Linux/tools/pmp-access-smoke.S \
    Linux/tools/pmp-pagewalk-smoke.S \
    Linux/tools/pmp-pagewalk-ad-smoke.S \
    Linux/tools/sv39-sfence-asid-smoke.S \
    Linux/tools/fp-convert-smoke.S \
    Linux/tools/fp-compare-sgnj-smoke.S \
    Linux/tools/fp-sqrt-smoke.S \
    Linux/tools/virtio-blk-error-smoke.S \
    Linux/tools/virtio-net-ctrl-smoke.S \
    Linux/platform/gen_dts.py \
    Linux/platform/npc-rv64.yml \
    scripts/nemu-preserved-run.sh \
    nemu/configs/riscv64-linux_defconfig \
    nemu/scripts/native.mk \
    nemu/src/cpu/cpu-exec.c \
    nemu/src/cpu/Kconfig \
    nemu/src/device/serial.c \
    nemu/src/device/uart16550.c \
    nemu/include/device/uart16550.h \
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
    nemu/src/isa/riscv64/filelist.mk \
    nemu/src/isa/riscv64/inst/common.c \
    nemu/src/isa/riscv64/inst/csr.c \
    nemu/src/isa/riscv64/inst/rv64i.c \
    nemu/src/isa/riscv64/inst/fp.c \
    nemu/src/isa/riscv64/inst/muldiv.c \
    nemu/src/isa/riscv64/inst/amo.c \
    nemu/src/isa/riscv64/inst/bitmanip.c \
    nemu/src/isa/riscv64/inst/compressed.c \
    nemu/src/isa/riscv64/inst/decode_cache.c \
    nemu/src/isa/riscv64/inst/decode.c \
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
    "$E2E_ROOT_DIR/Linux/scripts/ubuntu-rootfs-flavors.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-performance-config.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-nemu-kernel-config.sh" \
    "$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh" \
    "$E2E_ROOT_DIR/scripts/nemu-preserved-run.sh"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/scripts/check-nemu-qmp-smoke.py"
  python3 -m py_compile "$E2E_ROOT_DIR/Linux/scripts/check-nemu-gdbstub-smoke.py"

  echo
  echo "[nemu-ubuntu] rootfs flavor manifest"
  make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu ubuntu-rootfs-flavors-check

  echo
  echo "[nemu-ubuntu] rootfs flavor artifact dry-run"
  local flavor_run_dir="${E2E_RUN_DIR:-$E2E_ROOT_DIR/.github/task-runs/manual-nemu-rootfs-flavor-artifacts}"
  local flavor_artifact_log="$flavor_run_dir/evidence/nemu-rootfs-flavor-artifacts-dry-run.log"
  mkdir -p "$(dirname "$flavor_artifact_log")"
  make -C "$E2E_ROOT_DIR/Linux" -n ARCH=riscv64-nemu ubuntu-rootfs-full-image 2>&1 | tee "$flavor_artifact_log"
  local flavor_artifact_rc=${PIPESTATUS[0]}
  if [[ $flavor_artifact_rc -ne 0 ]]; then
    return "$flavor_artifact_rc"
  fi
  for pattern in \
    "UBUNTU_ROOTFS_FLAVOR=full" \
    "ubuntu-22.04-riscv64-full.ext4" \
    "ubuntu-22.04-riscv64-full-rootfs.cpio" \
    "rootfs-full"; do
    if grep -Fq -- "$pattern" "$flavor_artifact_log"; then
      printf 'PASS rootfs-flavor artifact %s\n' "$pattern"
    else
      printf 'FAIL rootfs-flavor artifact %s\n' "$pattern"
      missing=1
    fi
  done

  local flavor_guest_gate_log="$flavor_run_dir/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log"
  make -C "$E2E_ROOT_DIR/Linux" -n ARCH=riscv64-nemu check-nemu-systemd-guest-full 2>&1 | tee "$flavor_guest_gate_log"
  local flavor_guest_gate_rc=${PIPESTATUS[0]}
  if [[ $flavor_guest_gate_rc -ne 0 ]]; then
    return "$flavor_guest_gate_rc"
  fi
  for pattern in \
    "UBUNTU_ROOTFS_FLAVOR=full" \
    "NEMU_SYSTEMD_ROOTFS_FLAVOR=full" \
    "riscv64-nemu-systemd-guest-full-check" \
    "ubuntu-22.04-riscv64-full.ext4"; do
    if grep -Fq -- "$pattern" "$flavor_guest_gate_log"; then
      printf 'PASS rootfs-flavor guest-gate %s\n' "$pattern"
    else
      printf 'FAIL rootfs-flavor guest-gate %s\n' "$pattern"
      missing=1
    fi
  done

  local flavor_full_soak_gate_log="$flavor_run_dir/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log"
  make -C "$E2E_ROOT_DIR/Linux" -n ARCH=riscv64-nemu check-nemu-systemd-guest-full-soak 2>&1 | tee "$flavor_full_soak_gate_log"
  local flavor_full_soak_gate_rc=${PIPESTATUS[0]}
  if [[ $flavor_full_soak_gate_rc -ne 0 ]]; then
    return "$flavor_full_soak_gate_rc"
  fi
  for pattern in \
    "UBUNTU_ROOTFS_FLAVOR=full" \
    "NEMU_SYSTEMD_ROOTFS_FLAVOR=full" \
    "riscv64-nemu-systemd-guest-full-soak-check" \
    "NEMU_SYSTEMD_SOAK_SECONDS='300'" \
    "NEMU_SYSTEMD_FS_STRESS_MIB='32'" \
    "ubuntu-22.04-riscv64-full.ext4"; do
    if grep -Fq -- "$pattern" "$flavor_full_soak_gate_log"; then
      printf 'PASS rootfs-flavor full-soak-gate %s\n' "$pattern"
    else
      printf 'FAIL rootfs-flavor full-soak-gate %s\n' "$pattern"
      missing=1
    fi
  done

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
  echo "[nemu-ubuntu] NEMU LR/SC reservation smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-lrsc-reservation

  echo
  echo "[nemu-ubuntu] NEMU PMP access fault smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-pmp-access

  echo
  echo "[nemu-ubuntu] NEMU PMP page-table walk access fault smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-pmp-pagewalk

  echo
  echo "[nemu-ubuntu] NEMU PMP page-table A/D update access fault smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-pmp-pagewalk-ad

  echo
  echo "[nemu-ubuntu] NEMU Sv39 sfence.vma ASID/global smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-sv39-sfence-asid

  echo
  echo "[nemu-ubuntu] NEMU FP convert smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-fp-convert

  echo
  echo "[nemu-ubuntu] NEMU FP compare/sign-injection smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-fp-compare-sgnj

  echo
  echo "[nemu-ubuntu] NEMU FP sqrt smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-fp-sqrt

  echo
  echo "[nemu-ubuntu] NEMU virtio-blk error-path smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-virtio-blk-error

  echo
  echo "[nemu-ubuntu] NEMU config-preserving virtio-net control smoke"
  make -C "$E2E_ROOT_DIR/Linux/tools" smoke-nemu-config-preserve

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
    "config.interpreter_tb_max_inst=32" \
    "config.interpreter_wide_ifetch=1" \
    "config.interpreter_ifetch_page_cache=1" \
    "config.interpreter_decode_cache=1" \
    "config.interpreter_decode_direct_dispatch=1" \
    "config.interpreter_decode_cache_entries=32768" \
    "config.interpreter_intr_fast_flag=1" \
    "config.device_update_check_interval=512" \
    "platform.hart_count=1" \
    "platform.smp=unsupported" \
    "platform.pci=unsupported" \
    "platform.virtio_transport=mmio" \
    "platform.virtio_mmio_slots=3" \
    "monitor.machine_info=enabled" \
    "monitor.oneshot_cmd=enabled" \
    "monitor.qmp=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown" \
    "monitor.qmp.mode=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown-quit" \
    "debug.gdbstub=remote-startup-rw-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack" \
    "debug.gdbstub.mode=startup-rw-regmem-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack" \
    "snapshot.vm_state=unsupported" \
    "snapshot.block=raw-sparse-overlay" \
    "block.format=raw" \
    "time.clint.enabled=1" \
    "time.clint.timebase_hz=10000000" \
    "time.clint.source=instruction" \
    "time.csr_time_source=clint_mtime" \
    "interrupt.controller=riscv-clint+plic" \
    "interrupt.clint.enabled=1" \
    "interrupt.clint.model=riscv,clint0" \
    "interrupt.clint.mmio=0x02000000" \
    "interrupt.clint.size=0x00010000" \
    "interrupt.clint.timebase_hz=10000000" \
    "interrupt.clint.time_source=instruction" \
    "interrupt.clint.msip=0" \
    "interrupt.clint.mtip_pending=0" \
    "interrupt.plic.enabled=1" \
    "interrupt.plic.model=riscv,plic0" \
    "interrupt.plic.mmio=0x0c000000" \
    "interrupt.plic.size=0x04000000" \
    "interrupt.plic.nr_irqs=32" \
    "interrupt.plic.contexts=2" \
    "interrupt.plic.source.1.name=serial0" \
    "interrupt.plic.source.1.kind=uart16550" \
    "interrupt.plic.source.1.enabled=1" \
    "interrupt.plic.source.2.name=virtio-blk" \
    "interrupt.plic.source.2.kind=virtio-mmio" \
    "interrupt.plic.source.2.enabled=1" \
    "interrupt.plic.source.3.name=virtio-rng" \
    "interrupt.plic.source.3.kind=virtio-mmio" \
    "interrupt.plic.source.3.enabled=1" \
    "interrupt.plic.source.4.name=goldfish-rtc" \
    "interrupt.plic.source.4.kind=platform-rtc" \
    "interrupt.plic.source.4.enabled=1" \
    "interrupt.plic.source.5.name=virtio-net" \
    "interrupt.plic.source.5.kind=virtio-mmio" \
    "interrupt.plic.source.5.enabled=1" \
    "memory.base=0x80000000" \
    "memory.size=0x40000000" \
    "memory.end=0xbfffffff" \
    "memory.pmp.mode=rv64-basic" \
    "memory.pmp.entries=16" \
    "memory.pmp.active=0" \
    "device.serial.enabled=1" \
    "device.serial.mmio=0x10000000" \
    "device.serial.irq=1" \
    "device.serial.model=ns16550a" \
    "device.serial.backend=nemu-16550a" \
    "device.serial.host_backend=stderr,stdin,fifo:/tmp/nemu.serial" \
    "device.serial.bus_profile=8bit" \
    "device.serial.map_size=0x00001000" \
    "device.serial.rx_fifo_capacity=16" \
    "device.serial.rx_fifo_visible_capacity=1" \
    "device.serial.rx_fifo_count=0" \
    "device.serial.rx_trigger=1" \
    "device.serial.fifo_enabled=0" \
    "device.serial.irq_level=0" \
    "device.serial.ier=0x00" \
    "device.serial.iir=0x01" \
    "device.serial.lcr=0x00" \
    "device.serial.lsr=0x60" \
    "device.serial.host_rx_staging_capacity=1048576" \
    "device.serial.host_rx_staging_count=0" \
    "device.serial.host_rx_dropped=0" \
    "device.serial.host_rx_poll_interval=4" \
    "device.serial.tx_buffer_capacity=4096" \
    "device.serial.tx_buffer_count=0" \
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
    "device.virtio_blk.async_completion_fast_flag=1" \
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
    "device.virtio_rng.model=virtio-rng-mmio" \
    "device.virtio_rng.backend=host-urandom" \
    "device.virtio_rng.backend_source=/dev/urandom" \
    "device.virtio_rng.mmio_version=2" \
    "device.virtio_rng.device_id=4" \
    "device.virtio_rng.vendor_id=0x58535959" \
    "device.virtio_rng.queue_count=1" \
    "device.virtio_rng.queue_num_max=8" \
    "device.virtio_rng.features.version_1=1" \
    "device.virtio_rng.features.indirect_desc=1" \
    "device.virtio_rng.features.event_idx=1" \
    "device.virtio_rng.driver_features.version_1=0" \
    "device.virtio_rng.driver_features.indirect_desc=0" \
    "device.virtio_rng.driver_features.event_idx=0" \
    "device.virtio_rng.queue_ready=0" \
    "device.virtio_rng.status=0x00000000" \
    "device.virtio_rng.interrupt_status=0x00000000" \
    "device.goldfish_rtc.enabled=1" \
    "device.goldfish_rtc.mmio=0x10003000" \
    "device.goldfish_rtc.irq=4" \
    "device.goldfish_rtc.model=google,goldfish-rtc" \
    "device.goldfish_rtc.time_source=host-realtime-epoch+clint-mtime" \
    "device.goldfish_rtc.time_unit=ns" \
    "device.goldfish_rtc.virtual_timebase_hz=10000000" \
    "device.goldfish_rtc.mmio_size=0x00001000" \
    "device.goldfish_rtc.alarm_supported=1" \
    "device.goldfish_rtc.alarm_enabled=0" \
    "device.goldfish_rtc.alarm_running=0" \
    "device.goldfish_rtc.irq_enabled=0" \
    "device.goldfish_rtc.interrupt_pending=0" \
    "device.goldfish_rtc.interrupt_line=0" \
    "device.goldfish_rtc.time_latch=low-then-high" \
    "device.virtio_net.enabled=1" \
    "device.virtio_net.mmio=0x10004000" \
    "device.virtio_net.irq=5" \
    "device.virtio_net.backend=hostless-responder" \
    "device.virtio_net.mac=52:54:00:12:34:56" \
    "device.virtio_net.host_ip=10.0.2.2" \
    "device.virtio_net.guest_ip=10.0.2.15" \
    "device.virtio_net.dhcp=hostless" \
    "device.virtio_net.dns=nemu.local" \
    "device.virtio_net.tcp_http=/nemu-health" \
    "device.virtio_net.tcp_http_head=/nemu-health" \
    "device.virtio_net.tcp_http_404=enabled" \
    "device.virtio_net.tcp_http_large=/nemu-large bytes=4096" \
    "device.virtio_net.tcp_http_segment_payload_max=1200" \
    "device.virtio_net.tcp_http_apt_repo=/ubuntu jammy main" \
    "device.virtio_net.tcp_http_apt_signed_repo=InRelease signed-by=/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg key-fingerprint=E6742789E6F3AAEAD748589209108C9EAFAA6C14" \
    "device.virtio_net.tcp_http_apt_package=nemu-hostless-hello 1.0/1.1 riscv64" \
    "device.virtio_net.tcp_http_apt_meta_package=nemu-hostless-meta 1.0/1.1 riscv64 depends=nemu-hostless-hello (= matching-version)" \
    "device.virtio_net.tcp_http_apt_upgrade=nemu-hostless-meta 1.0->1.1" \
    "device.virtio_net.mtu=1500" \
    "device.virtio_net.config_bytes=17" \
    "device.virtio_net.speed_mbps=1000" \
    "device.virtio_net.duplex=full" \
    "device.virtio_net.queue_count=3" \
    "device.virtio_net.features.version_1=1" \
    "device.virtio_net.features.mtu=1" \
    "device.virtio_net.features.mac=1" \
    "device.virtio_net.features.mrg_rxbuf=1" \
    "device.virtio_net.features.status=1" \
    "device.virtio_net.features.ctrl_vq=1" \
    "device.virtio_net.features.ctrl_rx=1" \
    "device.virtio_net.features.ctrl_vlan=1" \
    "device.virtio_net.features.ctrl_rx_extra=1" \
    "device.virtio_net.features.guest_announce=1" \
    "device.virtio_net.features.ctrl_mac_addr=1" \
    "device.virtio_net.features.speed_duplex=1" \
    "device.virtio_net.features.indirect_desc=1" \
    "device.virtio_net.features.event_idx=1" \
    "device.virtio_net.driver_features.version_1=0" \
    "device.virtio_net.driver_features.mtu=0" \
    "device.virtio_net.driver_features.mac=0" \
    "device.virtio_net.driver_features.mrg_rxbuf=0" \
    "device.virtio_net.driver_features.status=0" \
    "device.virtio_net.driver_features.ctrl_vq=0" \
    "device.virtio_net.driver_features.ctrl_rx=0" \
    "device.virtio_net.driver_features.ctrl_vlan=0" \
    "device.virtio_net.driver_features.ctrl_rx_extra=0" \
    "device.virtio_net.driver_features.guest_announce=0" \
    "device.virtio_net.driver_features.ctrl_mac_addr=0" \
    "device.virtio_net.driver_features.speed_duplex=0" \
    "device.virtio_net.driver_features.indirect_desc=0" \
    "device.virtio_net.driver_features.event_idx=0" \
    "device.virtio_net.ctrl_rx.promisc=0" \
    "device.virtio_net.ctrl_rx.allmulti=0" \
    "device.virtio_net.ctrl_rx.alluni=0" \
    "device.virtio_net.ctrl_rx.nomulti=0" \
    "device.virtio_net.ctrl_rx.nouni=0" \
    "device.virtio_net.ctrl_rx.nobcast=0" \
    "device.virtio_net.ctrl_mac.current=52:54:00:12:34:56" \
    "device.virtio_net.ctrl_mac.table_set=0" \
    "device.virtio_net.ctrl_mac.addr_set=0" \
    "device.virtio_net.ctrl_mac.unicast=0" \
    "device.virtio_net.ctrl_mac.multicast=0" \
    "device.virtio_net.ctrl_vlan.filter_count=0" \
    "device.virtio_net.ctrl_vlan.last_vid_valid=0" \
    "device.virtio_net.ctrl_vlan.last_vid=0" \
    "device.virtio_net.ctrl_vlan.last_cmd=0" \
    "device.virtio_net.ctrl_announce.pending=0" \
    "device.virtio_net.ctrl_announce.requested=0" \
    "device.virtio_net.stats.tx_packets=0" \
    "device.virtio_net.stats.rx_packets=0" \
    "device.virtio_net.stats.tx_errors=0" \
    "device.virtio_net.stats.rx_drops=0" \
    "device.virtio_net.stats.ctrl_commands=0" \
    "device.virtio_net.stats.tcp_http_large_requests=0" \
    "device.virtio_net.stats.tcp_http_segmented_responses=0" \
    "device.virtio_net.stats.tcp_http_response_segments=0" \
    "device.virtio_net.stats.ctrl_rx_commands=0" \
    "device.virtio_net.stats.ctrl_rx_extra_commands=0" \
    "device.virtio_net.stats.ctrl_mac_table_commands=0" \
    "device.virtio_net.stats.ctrl_mac_addr_commands=0" \
    "device.virtio_net.stats.ctrl_vlan_commands=0" \
    "device.virtio_net.stats.ctrl_announce_commands=0" \
    "device.virtio_net.stats.ctrl_errors=0" \
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
    if grep -Fq -- "$pattern" "$monitor_cmd_log"; then
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
    "PASS query-chardev serial0" \
    "PASS query-serial serial0" \
    "PASS query-netdev net0" \
    "PASS query-netdev-features" \
    "PASS query-netdev-driver-features-zero-baseline" \
    "PASS query-netdev-stats-zero-baseline" \
    "PASS query-rng rng0" \
    "PASS query-rtc rtc0" \
    "PASS query-interrupts plic-clint" \
    "PASS query-pci entries=0" \
    "PASS query-version ysyx-nemu" \
    "PASS query-kvm disabled" \
    "PASS query-qmp-schema" \
    "PASS query-events events=4" \
    "PASS qmp-id-echo" \
    "PASS quit OK" \
    "PASS qmp-event-shutdown SHUTDOWN" \
    "PASS system-reset-event-reset RESET" \
    "PASS system-reset-prelaunch OK" \
    "PASS system-reset-query-status prelaunch" \
    "PASS system-reset-log-requested" \
    "PASS cont OK" \
    "PASS cont-event-resume RESUME" \
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
    "PASS block-event-shutdown SHUTDOWN" \
    "PASS block-quit OK" \
    "PASS block-nemu-exit rc=0" \
    "PASS runtime-qmp-greeting" \
    "PASS runtime-query-status-prelaunch prelaunch" \
    "PASS runtime-event-resume-start RESUME" \
    "PASS runtime-cont OK" \
    "PASS runtime-query-status running" \
    "PASS runtime-event-stop STOP" \
    "PASS runtime-stop OK" \
    "PASS runtime-query-status-paused paused" \
    "PASS runtime-query-blockstats virtio0" \
    "PASS runtime-query-chardev serial0" \
    "PASS runtime-query-serial serial0" \
    "PASS runtime-query-netdev net0" \
    "PASS runtime-query-netdev-features" \
    "PASS runtime-query-netdev-driver-features-zero-baseline" \
    "PASS runtime-query-netdev-stats-zero-baseline" \
    "PASS runtime-query-rng rng0" \
    "PASS runtime-query-rtc rtc0" \
    "PASS runtime-query-interrupts plic-clint" \
    "PASS runtime-event-resume-after-stop RESUME" \
    "PASS runtime-cont-after-stop OK" \
    "PASS runtime-query-status-resumed running" \
    "PASS runtime-event-shutdown SHUTDOWN" \
    "PASS runtime-quit OK" \
    "PASS runtime-nemu-exit rc=0" \
    "PASS system-powerdown-qmp-greeting" \
    "PASS system-powerdown-query-status-prelaunch prelaunch" \
    "PASS system-powerdown-event-resume RESUME" \
    "PASS system-powerdown-cont OK" \
    "PASS system-powerdown-query-status running" \
    "PASS system-powerdown-event-shutdown SHUTDOWN" \
    "PASS system-powerdown OK" \
    "PASS system-powerdown-nemu-exit rc=0" \
    "PASS system-powerdown-log-requested" \
    "PASS guest-shutdown-qmp-greeting" \
    "PASS guest-shutdown-query-status-prelaunch prelaunch" \
    "PASS guest-shutdown-event-resume RESUME" \
    "PASS guest-shutdown-cont OK" \
    "PASS guest-shutdown-event-shutdown SHUTDOWN" \
    "PASS guest-shutdown-nemu-exit rc=0" \
    "PASS guest-shutdown-syscon-poweroff" \
    "PASS guest-shutdown-qmp-emitted" \
    "PASS guest-shutdown-good-trap" \
    "__NEMU_QMP_SMOKE__:ok"; do
    if grep -Fq -- "$pattern" "$qmp_log"; then
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
    "PASS vCont-query" \
    "PASS thread-info" \
    "PASS thread-extra NEMU single hart" \
    "PASS target-xml riscv64" \
    "PASS memory-map ram start=0x80000000 length=0x40000000" \
    "PASS read-all-regs" \
    "PASS write-x0-ignored" \
    "PASS write-pc" \
    "PASS read-pmem-reset-vector" \
    "PASS write-pmem-reset-vector" \
    "PASS single-step S05" \
    "PASS vcont-step S05" \
    "PASS continue-exit W00" \
    "PASS continue-syscon-poweroff" \
    "PASS continue-good-trap" \
    "PASS swbreak-insert OK" \
    "PASS swbreak-hit S05" \
    "PASS swbreak-vcont-hit S05" \
    "PASS swbreak-pc" \
    "PASS swbreak-remove OK" \
    "PASS swbreak-continue-exit W00" \
    "PASS swbreak-vcont-continue-exit W00" \
    "PASS swbreak-syscon-poweroff" \
    "PASS swbreak-good-trap" \
    "PASS hbreak-insert OK" \
    "PASS hbreak-hit S05" \
    "PASS hbreak-vcont-hit S05" \
    "PASS hbreak-pc" \
    "PASS hbreak-remove OK" \
    "PASS hbreak-continue-exit W00" \
    "PASS hbreak-vcont-continue-exit W00" \
    "PASS hbreak-syscon-poweroff" \
    "PASS hbreak-good-trap" \
    "PASS watch-write-insert Z2 OK" \
    "PASS watch-write-hit S05" \
    "PASS watch-write-pc" \
    "PASS watch-write-remove OK" \
    "PASS watch-write-continue-exit W00" \
    "PASS watch-write-hit-log" \
    "PASS watch-write-syscon-poweroff" \
    "PASS watch-write-good-trap" \
    "PASS watch-read-insert Z3 OK" \
    "PASS watch-read-hit S05" \
    "PASS watch-read-pc" \
    "PASS watch-read-remove OK" \
    "PASS watch-read-continue-exit W00" \
    "PASS watch-read-hit-log" \
    "PASS watch-read-syscon-poweroff" \
    "PASS watch-read-good-trap" \
    "PASS watch-access-insert Z4 OK" \
    "PASS watch-access-hit S05" \
    "PASS watch-access-pc" \
    "PASS watch-access-remove OK" \
    "PASS watch-access-continue-exit W00" \
    "PASS watch-access-hit-log" \
    "PASS watch-access-syscon-poweroff" \
    "PASS watch-access-good-trap" \
    "PASS async-halt S05" \
    "PASS async-halt-pc" \
    "PASS async-halt-continue-exit W00" \
    "PASS async-halt-ctrl-c-log" \
    "PASS async-halt-syscon-poweroff" \
    "PASS async-halt-good-trap" \
    "PASS noack-start OK" \
    "PASS noack-stop-reason S05" \
    "PASS noack-read-pc" \
    "PASS noack-vCont-query vCont;c;s" \
    "PASS noack-detach OK" \
    "PASS noack-nemu-exit rc=0" \
    "PASS noack-log-enabled" \
    "PASS detach OK" \
    "__NEMU_GDBSTUB_SMOKE__:ok"; do
    if grep -Fq -- "$pattern" "$gdbstub_log"; then
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
      "device.virtio_blk.async_completion_fast_flag=1" \
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
      "device.virtio_blk.async_completion_fast_flag=1" \
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
    Linux/tools/lrsc-reservation-smoke.S \
    Linux/tools/pmp-access-smoke.S \
    Linux/tools/pmp-pagewalk-smoke.S \
    Linux/tools/pmp-pagewalk-ad-smoke.S \
    Linux/tools/sv39-sfence-asid-smoke.S \
    Linux/tools/fp-convert-smoke.S \
    Linux/tools/fp-compare-sgnj-smoke.S \
    Linux/tools/fp-sqrt-smoke.S \
    Linux/tools/virtio-blk-error-smoke.S \
    nemu/src/isa/riscv64/system/mmu.c \
    nemu/src/isa/riscv64/inst.c \
    nemu/src/isa/riscv64/filelist.mk \
    nemu/src/isa/riscv64/inst/common.c \
    nemu/src/isa/riscv64/inst/csr.c \
    nemu/src/isa/riscv64/inst/rv64i.c \
    nemu/src/isa/riscv64/inst/fp.c \
    nemu/src/isa/riscv64/inst/muldiv.c \
    nemu/src/isa/riscv64/inst/amo.c \
    nemu/src/isa/riscv64/inst/bitmanip.c \
    nemu/src/isa/riscv64/inst/compressed.c \
    nemu/src/isa/riscv64/inst/decode_cache.c \
    nemu/src/isa/riscv64/inst/decode.c \
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
    Linux/scripts/ubuntu-rootfs-flavors.sh \
    Linux/scripts/check-ubuntu-rootfs.sh \
    nemu/include/utils.h \
    .github/memory/modules/nemu.md \
    .github/memory/known-issues.md \
    .github/e2e/profiles/nemu-dev.tsv \
    .github/e2e/profiles/nemu-dev-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-soak.tsv \
    .github/e2e/profiles/npc-dev.tsv \
    .github/e2e/profiles/nemu-ubuntu.tsv \
    .github/e2e/profiles/nemu-ubuntu-focused.tsv \
    .github/e2e/profiles/nemu-ubuntu-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-soak.tsv \
    .github/e2e/profiles/software-flow.tsv \
    .github/agents/software-flow.agent.md \
    .github/e2e/modules/software-flow.md

  local check_script="$E2E_ROOT_DIR/Linux/scripts/check-nemu-systemd-guest.sh"
  local linux_makefile="$E2E_ROOT_DIR/Linux/Makefile"
  local build_ubuntu_rootfs_sh="$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-rootfs.sh"
  local build_ubuntu_systemd_overlay_sh="$E2E_ROOT_DIR/Linux/scripts/build-ubuntu-systemd-overlay.sh"
  local gen_nemu_hostless_apt_assets_py="$E2E_ROOT_DIR/Linux/scripts/gen-nemu-hostless-apt-assets.py"
  local ubuntu_rootfs_flavors_sh="$E2E_ROOT_DIR/Linux/scripts/ubuntu-rootfs-flavors.sh"
  local check_ubuntu_rootfs_sh="$E2E_ROOT_DIR/Linux/scripts/check-ubuntu-rootfs.sh"
  local nemu_module_sh="$E2E_ROOT_DIR/scripts/e2e/modules/nemu.sh"
  local agent_e2e_sh="$E2E_ROOT_DIR/scripts/agent-e2e.sh"
  local icmp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-icmp-probe.c"
  local dhcp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-dhcp-probe.c"
  local dns_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-dns-probe.c"
  local tcp_probe_c="$E2E_ROOT_DIR/Linux/tools/nemu-systemd-tcp-probe.c"
  local linux_tools_mk="$E2E_ROOT_DIR/Linux/tools/Makefile"
  local amo_misaligned_smoke_s="$E2E_ROOT_DIR/Linux/tools/amo-misaligned-smoke.S"
  local lrsc_reservation_smoke_s="$E2E_ROOT_DIR/Linux/tools/lrsc-reservation-smoke.S"
  local pmp_access_smoke_s="$E2E_ROOT_DIR/Linux/tools/pmp-access-smoke.S"
  local pmp_pagewalk_smoke_s="$E2E_ROOT_DIR/Linux/tools/pmp-pagewalk-smoke.S"
  local pmp_pagewalk_ad_smoke_s="$E2E_ROOT_DIR/Linux/tools/pmp-pagewalk-ad-smoke.S"
  local sv39_sfence_asid_smoke_s="$E2E_ROOT_DIR/Linux/tools/sv39-sfence-asid-smoke.S"
  local virtio_blk_error_smoke_s="$E2E_ROOT_DIR/Linux/tools/virtio-blk-error-smoke.S"
  local virtio_net_ctrl_smoke_s="$E2E_ROOT_DIR/Linux/tools/virtio-net-ctrl-smoke.S"
  local nemu_preserved_run_sh="$E2E_ROOT_DIR/scripts/nemu-preserved-run.sh"
  local build_linux_sh="$E2E_ROOT_DIR/Linux/scripts/build-linux.sh"
  local rng_c="$E2E_ROOT_DIR/nemu/src/device/rng.c"
  local goldfish_rtc_c="$E2E_ROOT_DIR/nemu/src/device/goldfish_rtc.c"
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
  local uart16550_h="$E2E_ROOT_DIR/nemu/include/device/uart16550.h"
  local device_c="$E2E_ROOT_DIR/nemu/src/device/device.c"
  local cpu_exec_c="$E2E_ROOT_DIR/nemu/src/cpu/cpu-exec.c"
  local cpu_kconfig="$E2E_ROOT_DIR/nemu/src/cpu/Kconfig"
  local linux_defconfig="$E2E_ROOT_DIR/nemu/configs/riscv64-linux_defconfig"
  local rv64_inst_c="$E2E_ROOT_DIR/nemu/src/isa/riscv64/inst.c"
  local rv64_inst_dir="$E2E_ROOT_DIR/nemu/src/isa/riscv64/inst"
  local rv64_inst_filelist="$E2E_ROOT_DIR/nemu/src/isa/riscv64/filelist.mk"
  local rv64_inst_files=("$rv64_inst_c" "$rv64_inst_dir"/*.c)
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
  echo "[nemu-ubuntu] required software-flow methodology hooks"
  local nemu_dev_profile=".github/e2e/profiles/nemu-dev.tsv"
  local nemu_dev_gate_profile=".github/e2e/profiles/nemu-dev-gate.tsv"
  local nemu_dev_full_gate_profile=".github/e2e/profiles/nemu-dev-full-gate.tsv"
  local nemu_dev_full_soak_profile=".github/e2e/profiles/nemu-dev-full-soak.tsv"
  local npc_dev_profile=".github/e2e/profiles/npc-dev.tsv"
  local nemu_ubuntu_profile=".github/e2e/profiles/nemu-ubuntu.tsv"
  local nemu_ubuntu_focused_profile=".github/e2e/profiles/nemu-ubuntu-focused.tsv"
  local nemu_ubuntu_gate_profile=".github/e2e/profiles/nemu-ubuntu-gate.tsv"
  local nemu_ubuntu_full_gate_profile=".github/e2e/profiles/nemu-ubuntu-full-gate.tsv"
  local nemu_ubuntu_full_soak_profile=".github/e2e/profiles/nemu-ubuntu-full-soak.tsv"
  local software_flow_profile=".github/e2e/profiles/software-flow.tsv"
  local software_flow_agent=".github/agents/software-flow.agent.md"
  if e2e_file_contains "$nemu_ubuntu_profile" '@include|software-flow'; then
    printf 'PASS nemu-ubuntu profile keeps software-flow include\n'
  else
    printf 'FAIL nemu-ubuntu profile keeps software-flow include\n'
    missing=1
  fi
  if e2e_file_contains "$nemu_dev_profile" '@include|nemu-ubuntu-focused'; then
    printf 'PASS nemu-dev profile includes nemu-ubuntu-focused\n'
  else
    printf 'FAIL nemu-dev profile includes nemu-ubuntu-focused\n'
    missing=1
  fi
  if e2e_file_contains "$nemu_ubuntu_focused_profile" '@include|software-flow' &&
     e2e_file_contains "$nemu_ubuntu_focused_profile" 'nemu-ubuntu-static|nemu|e2e_nemu_ubuntu_static_gate' &&
     e2e_file_contains "$nemu_ubuntu_focused_profile" 'nemu-ubuntu-slice-contract|nemu|e2e_nemu_ubuntu_slice_contract'; then
    printf 'PASS nemu-ubuntu-focused profile keeps NEMU-only static contract\n'
  else
    printf 'FAIL nemu-ubuntu-focused profile keeps NEMU-only static contract\n'
    missing=1
  fi
  if e2e_file_contains "$nemu_ubuntu_focused_profile" '@include|rv64-linux'; then
    printf 'FAIL nemu-ubuntu-focused profile must not include rv64-linux/NPC nodes\n'
    missing=1
  else
    printf 'PASS nemu-ubuntu-focused profile avoids rv64-linux/NPC nodes\n'
  fi
  if e2e_file_contains "$nemu_dev_profile" '@include|rv64-linux' ||
     e2e_file_contains "$nemu_dev_profile" 'npc-' ||
     e2e_file_contains "$nemu_ubuntu_focused_profile" 'npc-' ||
     e2e_file_contains "$npc_dev_profile" 'nemu-ubuntu-full-gate'; then
    printf 'FAIL NEMU/NPC dev profiles are not isolated\n'
    missing=1
  else
    printf 'PASS NEMU/NPC dev profiles keep scenario isolation\n'
  fi
  if grep -Fq 'validate_profile_boundary' "$agent_e2e_sh" &&
     grep -Fq 'mode=NEMU-only' "$agent_e2e_sh" &&
     grep -Fq 'mode=NPC-only' "$agent_e2e_sh" &&
     grep -Fq 'NEMU-only dev profile pulled NPC work' "$agent_e2e_sh" &&
     grep -Fq 'NPC-only dev profile pulled NEMU work' "$agent_e2e_sh"; then
    printf 'PASS agent-e2e runtime profile boundary guards NEMU/NPC dev isolation\n'
  else
    printf 'FAIL agent-e2e runtime profile boundary guards NEMU/NPC dev isolation\n'
    missing=1
  fi
  if e2e_file_contains "$nemu_dev_gate_profile" '@include|nemu-dev' &&
     e2e_file_contains "$nemu_dev_full_gate_profile" '@include|nemu-dev' &&
     e2e_file_contains "$nemu_dev_full_soak_profile" '@include|nemu-dev'; then
    printf 'PASS NEMU dev gate profiles include nemu-dev\n'
  else
    printf 'FAIL NEMU dev gate profiles include nemu-dev\n'
    missing=1
  fi
  if e2e_file_contains "$nemu_ubuntu_gate_profile" '@include|nemu-ubuntu' &&
     e2e_file_contains "$nemu_ubuntu_full_gate_profile" '@include|nemu-ubuntu' &&
     e2e_file_contains "$nemu_ubuntu_full_soak_profile" '@include|nemu-ubuntu'; then
    printf 'PASS NEMU Ubuntu integration gate profiles keep nemu-ubuntu include\n'
  else
    printf 'FAIL NEMU Ubuntu integration gate profiles keep nemu-ubuntu include\n'
    missing=1
  fi
  if e2e_file_contains "$software_flow_profile" 'software-flow-contract'; then
    printf 'PASS software-flow profile exposes software-flow-contract\n'
  else
    printf 'FAIL software-flow profile exposes software-flow-contract\n'
    missing=1
  fi
  for pattern in \
    'software-dev-loop' \
    'software-bugfix-loop' \
    'hardware-aware-software-loop' \
    'scope-contract -> hardware-semantic-contract -> design-plan -> implement -> software-focused-test -> system-or-hardware-gate -> review-record' \
    '不把“构建通过”单独当成软件任务完成' \
    '必须扫描 FAIL marker'; do
    if e2e_file_contains "$software_flow_agent" "$pattern"; then
      printf 'PASS software-flow methodology available to NEMU dev/integration %s\n' "$pattern"
    else
      printf 'FAIL software-flow methodology available to NEMU dev/integration %s\n' "$pattern"
      missing=1
    fi
  done

  echo
  echo "[nemu-ubuntu] required host build jobserver hooks"
  for pattern in \
    '+$(MAKE) -C '\''$(NEMU_HOME)'\'' NEMU_HOME='\''$(NEMU_HOME)'\'' -j'\''$(JOBS)'\''' \
    '+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-systemd-guest' \
    '+$(MAKE) -C '\''$(TOOLS_DIR)'\'''; do
    if grep -Fq -- "$pattern" "$linux_makefile"; then
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
    if grep -Fq -- "$pattern" "$native_mk"; then
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
    "__NEMU_CHECK_VIRTIO_NET_MTU__" \
    "__NEMU_CHECK_VIRTIO_NET_SPEED__" \
    "__NEMU_CHECK_VIRTIO_NET_DUPLEX__" \
    "__NEMU_CHECK_VIRTIO_NET_IPV4__" \
    "__NEMU_CHECK_VDA_CACHE_TYPE__" \
    "__NEMU_CHECK_VDA_DISCARD_MAX__" \
    "__NEMU_CHECK_VDA_WRITE_ZEROES_MAX__" \
    "__NEMU_CHECK_LSB_RELEASE__" \
    "__NEMU_CHECK_COMMON_COMMANDS__" \
    "__NEMU_CHECK_TOP_VERSION__" \
    "__NEMU_CHECK_TOP_BATCH_OPTIONAL__" \
    "__NEMU_CHECK_HOSTNAMECTL_VERSION__" \
    "__NEMU_CHECK_HTOP_OPTIONAL__" \
    "__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__" \
    "__NEMU_CHECK_SYSTEMD_RELOAD_ERROR__" \
    "__NEMU_CHECK_SYSTEMD_RELOAD_ERROR_OUTPUT__" \
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
    "common-free-present" \
    "common-free-mem" \
    "common-top-present" \
    "common-top-version" \
    "common-top-batch-optional" \
    "common-hostnamectl-present" \
    "common-hostnamectl-version" \
    "common-htop-optional" \
    "virtio-net-driver" \
    "virtio-net-feature-mtu" \
    "virtio-net-feature-ctrl-vq" \
    "virtio-net-feature-ctrl-rx" \
    "virtio-net-feature-ctrl-vlan" \
    "virtio-net-feature-ctrl-rx-extra" \
    "virtio-net-feature-guest-announce" \
    "virtio-net-feature-ctrl-mac-addr" \
    "virtio-net-feature-speed-duplex" \
    "virtio-rng-ring-feature-indirect-desc" \
    "virtio-rng-ring-feature-event-idx" \
    "virtio-net-dhcp-lease" \
    "virtio-net-dns-a" \
    "virtio-net-tcp-http" \
    "virtio-net-icmp-echo" \
    "virtio-net-mtu" \
    "virtio-net-speed" \
    "virtio-net-duplex" \
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
    "VIRTIO_NET_F_MTU" \
    "VIRTIO_NET_MTU" \
    "VIRTIO_NET_F_SPEED_DUPLEX" \
    "VIRTIO_NET_LINK_SPEED_MBIT" \
    "VIRTIO_NET_LINK_DUPLEX_FULL" \
    "VIRTIO_NET_F_MAC" \
    "VIRTIO_NET_F_MRG_RXBUF" \
    "VIRTIO_NET_F_STATUS" \
    "VIRTIO_NET_F_CTRL_VQ" \
    "VIRTIO_NET_F_CTRL_RX" \
    "VIRTIO_NET_F_CTRL_VLAN" \
    "VIRTIO_NET_F_CTRL_RX_EXTRA" \
    "VIRTIO_NET_F_GUEST_ANNOUNCE" \
    "VIRTIO_NET_F_CTRL_MAC_ADDR" \
    "VIRTIO_NET_QUEUE_CTRL" \
    "virtio_net_ctrl_vq_enabled" \
    "virtio_net_ctrl_rx_enabled" \
    "virtio_net_ctrl_vlan_enabled" \
    "virtio_net_ctrl_rx_extra_enabled" \
    "virtio_net_ctrl_rx_extra_cmd" \
    "virtio_net_guest_announce_enabled" \
    "virtio_net_request_guest_announce" \
    "virtio_net_ctrl_mac_addr_enabled" \
    "VIRTIO_NET_CTRL_RX_PROMISC" \
    "VIRTIO_NET_CTRL_RX_ALLMULTI" \
    "VIRTIO_NET_CTRL_RX_ALLUNI" \
    "VIRTIO_NET_CTRL_RX_NOMULTI" \
    "VIRTIO_NET_CTRL_RX_NOUNI" \
    "VIRTIO_NET_CTRL_RX_NOBCAST" \
    "VIRTIO_NET_CTRL_VLAN_ADD" \
    "VIRTIO_NET_CTRL_VLAN_DEL" \
    "VIRTIO_NET_CTRL_ANNOUNCE_ACK" \
    "VIRTIO_NET_CTRL_MAC_TABLE_SET" \
    "VIRTIO_NET_CTRL_MAC_ADDR_SET" \
    "virtio_net_parse_ctrl_mac_table" \
    "virtio_net_parse_ctrl_mac_addr" \
    "virtio_net_parse_ctrl_vlan" \
    "virtio_net_parse_ctrl_no_payload" \
    "virtio_net_process_ctrl_queue" \
    "virtio_net_handle_ctrl_chain" \
    "device.virtio_net.features.version_1" \
    "device.virtio_net.features.mtu" \
    "device.virtio_net.features.ctrl_vq" \
    "device.virtio_net.features.ctrl_rx" \
    "device.virtio_net.features.ctrl_vlan" \
    "device.virtio_net.features.ctrl_rx_extra" \
    "device.virtio_net.features.guest_announce" \
    "device.virtio_net.features.ctrl_mac_addr" \
    "device.virtio_net.features.speed_duplex" \
    "device.virtio_net.driver_features.version_1" \
    "device.virtio_net.driver_features.mtu" \
    "device.virtio_net.driver_features.ctrl_vq" \
    "device.virtio_net.driver_features.ctrl_rx" \
    "device.virtio_net.driver_features.ctrl_vlan" \
    "device.virtio_net.driver_features.ctrl_rx_extra" \
    "device.virtio_net.driver_features.guest_announce" \
    "device.virtio_net.driver_features.ctrl_mac_addr" \
    "device.virtio_net.driver_features.speed_duplex" \
    "device.virtio_net.ctrl_rx.promisc" \
    "device.virtio_net.ctrl_rx.alluni" \
    "device.virtio_net.stats.ctrl_rx_commands" \
    "device.virtio_net.stats.ctrl_rx_extra_commands" \
    "device.virtio_net.ctrl_mac.table_set" \
    "device.virtio_net.stats.ctrl_mac_table_commands" \
    "device.virtio_net.ctrl_mac.addr_set" \
    "device.virtio_net.stats.ctrl_mac_addr_commands" \
    "device.virtio_net.ctrl_vlan.filter_count" \
    "device.virtio_net.stats.ctrl_vlan_commands" \
    "device.virtio_net.ctrl_announce.pending" \
    "device.virtio_net.stats.ctrl_announce_commands" \
    "VIRTIO_NET_RX_HDR_LEN" \
    "VIRTIO_RING_F_INDIRECT_DESC" \
    "VIRTIO_RING_F_EVENT_IDX" \
    "virtio_net_event_idx_enabled" \
    "virtio_net_handle_arp" \
    "virtio_net_handle_icmp" \
    "virtio_net_handle_dhcp" \
    "virtio_net_handle_dns" \
    "virtio_net_handle_tcp_http" \
    "virtio_net_send_tcp_payload" \
    "VIRTIO_NET_TCP_HTTP_SEGMENT_PAYLOAD_MAX" \
    "VirtioNetStats" \
    "virtio_net_statistic" \
    "tcp_http_requests" \
    "tcp_http_head_requests" \
    "tcp_http_not_found" \
    "tcp_http_apt_requests" \
    "tcp_http_apt_deb_requests" \
    "tcp_http_large_requests" \
    "tcp_http_segmented_responses" \
    "tcp_http_response_segments" \
    "HEAD " \
    "404 Not Found" \
    "NEMU_HTTP_LARGE_4096" \
    "/nemu-large" \
    "nemu_apt_release" \
    "nemu_apt_inrelease" \
    "nemu_apt_keyring" \
    "nemu-hostless-hello_1.0_riscv64.deb" \
    "nemu-hostless-meta_1.0_riscv64.deb" \
    "nemu-hostless-hello_1.1_riscv64.deb" \
    "nemu-hostless-meta_1.1_riscv64.deb" \
    "Depends: nemu-hostless-hello (= 1.0)" \
    "Depends: nemu-hostless-hello (= 1.1)" \
    "/ubuntu/dists/jammy/Release" \
    "/ubuntu/dists/jammy/InRelease" \
    "/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg" \
    "/ubuntu/dists/jammy/main/binary-riscv64/Packages.gz" \
    "http-methods" \
    "http-not-found" \
    "http-large" \
    "apt-repo" \
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
    if grep -Fq -- "$pattern" "$net_c"; then
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
    "virtio-net-runtime" \
    "PASS rootfs-backing-unchanged" \
    "NEMU_SYSTEMD_ROOTFS_FLAVOR" \
    "NEMU_GUEST_ROOTFS_FLAVOR" \
    "NEMU_GUEST_APT_INSTALL_DIAG" \
    "NEMU_GUEST_APT_INSTALL_ACTUAL" \
    'NEMU_GUEST_APT_INSTALL_ACTUAL:-0' \
    "NEMU_GUEST_APT_INSTALL_DIAG_TIMEOUT" \
    "NEMU_GUEST_APT_REMOVE_DIAG_TIMEOUT" \
    "NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD" \
    "NEMU_GUEST_PYTHON_CNF_DIAG_HARD" \
    "python/cnf diag hard" \
    "__NEMU_CHECK_ROOTFS_FLAVOR__" \
    "__NEMU_CHECK_FULL_USERLAND__" \
    "full-userland-runtime" \
    "full-userland-apt-version" \
    "full-userland-gpgv-version" \
    "full-userland-machine-id-setup-version" \
    "full-userland-machine-id-committed" \
    "full-userland-hostnamed-active" \
    "full-userland-hostnamectl-status" \
    "full-userland-sysusers-version" \
    "full-userland-sysusers-unit" \
    "full-userland-sysusers-create" \
    "full-userland-tmpfiles-version" \
    "full-userland-tmpfiles-unit" \
    "full-userland-tmpfiles-create" \
    "full-userland-journald-active" \
    "full-userland-systemd-cat" \
    "full-userland-journalctl-query" \
    "full-userland-apt-archive-keyring" \
    "full-userland-dpkg-audit" \
    "full-userland-dpkg-package-" \
    "systemd ubuntu-standard openssh-server curl wget dropbear-bin rsyslog cron systemd-timesyncd gpgv ubuntu-keyring" \
    "full-userland-apt-policy" \
    "full-userland-sudo-root" \
    "full-userland-sshd-config" \
    "full-userland-ssh-active" \
    "full-userland-ssh-listen" \
    "full-userland-ssh-test-user" \
    "full-userland-ssh-keygen" \
    "full-userland-ssh-dbclient-key" \
    "full-userland-ssh-dropbear-hostkey" \
    "full-userland-ssh-local-login" \
    "full-userland-systemctl-enable-daemon-reload" \
    "__NEMU_CHECK_FULL_SYSTEMCTL_ENABLE_ROOT__" \
    "full-userland-systemctl-enable" \
    "full-userland-systemctl-enable-wants-link" \
    "full-userland-systemctl-enable-start" \
    "full-userland-systemctl-disable" \
    "full-userland-resolv-hostless" \
    "full-userland-curl-http" \
    "full-userland-wget-http" \
    "full-userland-curl-head-http" \
    "full-userland-curl-404-http" \
    "full-userland-curl-large-http" \
    "NEMU_GUEST_PYTHON_CNF_DIAG_HARD" \
    "full-userland-python-cnf-diag-skip" \
    "full-userland-python-cnf-diag-recorded" \
    "full-userland-python-datetime-sqlite3" \
    "full-userland-python-stdlib-file-sha256" \
    "full-userland-python-stdlib-import-loop" \
    "full-userland-lsb-release-retry-loop" \
    "full-userland-lsb-release-pycacheprefix-loop" \
    "full-userland-python-stdlib-stress-loop" \
    "full-userland-command-not-found-update-db" \
    "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__" \
    "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_SOFT_FAIL__" \
    "__NEMU_CHECK_FULL_PYTHON_TEXTWRAP_SHA256__" \
    "__NEMU_CHECK_FULL_PYTHON_TEXTWRAP_PYC_SHA256__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_SHA256__" \
    "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_RC__" \
    "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_SOFT_FAIL__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_RC__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_RC__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_PYCACHEPREFIX_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_RC__" \
    "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_SOFT_FAIL__" \
    "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__" \
    "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_CNF_UPDATE_DB_SOFT_FAIL__" \
    "DIVMOD_NEG_US" \
    "RE_REPEAT_COMPILE" \
    "TEXTWRAP_IMPORT" \
    "OPTPARSE_IMPORT" \
    "__PYTHON_CNF_DIAG_DATETIME_IMPORT__" \
    "__PYTHON_CNF_DIAG_SQLITE3_IMPORT__" \
    "COMMAND_NOT_FOUND_CREATOR_IMPORT" \
    "/usr/lib/cnf-update-db" \
    "__NEMU_CHECK_FULL_CURL_LARGE_RC__" \
    "__NEMU_CHECK_FULL_CURL_LARGE_BYTES__" \
    "__NEMU_CHECK_FULL_CURL_LARGE_SHA256__" \
    "http://nemu.local/nemu-large" \
    "full-userland-apt-hostless-keyring" \
    "full-userland-apt-hostless-inrelease-gpgv" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__" \
    "#clear APT::Update::Post-Invoke-Success" \
    "#clear DPkg::Post-Invoke" \
    "full-userland-apt-hostless-signed-update" \
    "full-userland-apt-hostless-unsigned-reject" \
    "full-userland-apt-hostless-update" \
    "full-userland-apt-hostless-install" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_SHA256__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_SOURCE__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_SOURCE__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_UPDATE_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_UNSIGNED_UPDATE_LOG_BEGIN__" \
    "signed-by=" \
    "Dir::Etc::parts=-" \
    "Dir::Etc::trusted=" \
    "empty-trusted.gpg" \
    "NO_PUBKEY" \
    "http://nemu.local/ubuntu/dists/jammy/InRelease" \
    "http://nemu.local/ubuntu/keyrings/nemu-hostless-archive-keyring.gpg" \
    "e99cff1585af5ae2587b50efeffd562cac5d3fb383145a4c79b8046f38159045" \
    "8b1d4ef06eaea91ce7e2cbc2a22d8b3feeadb5ab539dc79067f8e26a3729b363" \
    "full-userland-apt-direct-install-diag-skip" \
    "full-userland-apt-direct-empty-status-simulate" \
    "full-userland-apt-direct-empty-status-download" \
    "full-userland-apt-direct-actual-install-skip" \
    "full-userland-apt-direct-full-status-install" \
    "full-userland-apt-direct-full-status-dpkg-ownership" \
    "full-userland-apt-direct-full-status-remove" \
    "full-userland-apt-direct-full-status-purge-ownership" \
    "full-userland-cron-active" \
    "full-userland-cron-exec" \
    "full-userland-rsyslog-active" \
    "full-userland-rsyslog-logger" \
    "full-userland-timesyncd-active" \
    "__NEMU_CHECK_FULL_SYSUSERS_VERSION__" \
    "__NEMU_CHECK_FULL_MACHINE_ID_SETUP_VERSION__" \
    "__NEMU_CHECK_FULL_MACHINE_ID__" \
    "__NEMU_CHECK_FULL_MACHINE_ID_SIZE__" \
    "__NEMU_CHECK_FULL_MACHINE_ID_COMMIT_STATE__" \
    "__NEMU_CHECK_FULL_HOSTNAMED_UNIT_STATE__" \
    "__NEMU_CHECK_FULL_HOSTNAMED_START_RC__" \
    "__NEMU_CHECK_FULL_HOSTNAMED_UNIT_STATE_AFTER__" \
    "__NEMU_CHECK_FULL_HOSTNAMED_START_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_HOSTNAMECTL_RC__" \
    "__NEMU_CHECK_FULL_HOSTNAMECTL_STATUS_BEGIN__" \
    "__NEMU_CHECK_FULL_HOSTNAMECTL_ERROR_BEGIN__" \
    "__NEMU_CHECK_FULL_HOSTNAMECTL_HOSTNAME__" \
    "systemd-machine-id-setup" \
    "systemd-machine-id-commit.service" \
    "systemd-hostnamed.service" \
    "hostnamectl status" \
    "ysyx-ubuntu2204" \
    "/bin/systemd-machine-id-setup" \
    "/usr/bin/hostnamectl" \
    "/lib/systemd/systemd-hostnamed" \
    "systemd:/bin/systemd-machine-id-setup" \
    "systemd:/usr/bin/hostnamectl" \
    "systemd:/lib/systemd/systemd-hostnamed" \
    "__NEMU_CHECK_FULL_SYSUSERS_SETUP_STATE__" \
    "__NEMU_CHECK_FULL_SYSUSERS_CONF__" \
    "__NEMU_CHECK_FULL_SYSUSERS_CREATE_RC__" \
    "__NEMU_CHECK_FULL_SYSUSERS_PASSWD__" \
    "__NEMU_CHECK_FULL_SYSUSERS_GROUP__" \
    "__NEMU_CHECK_FULL_SYSUSERS_LOG_BEGIN__" \
    "systemd-sysusers" \
    "nemufullsysusers" \
    "__NEMU_CHECK_FULL_TMPFILES_VERSION__" \
    "__NEMU_CHECK_FULL_TMPFILES_SETUP_STATE__" \
    "__NEMU_CHECK_FULL_TMPFILES_CONF__" \
    "__NEMU_CHECK_FULL_TMPFILES_CREATE_RC__" \
    "__NEMU_CHECK_FULL_TMPFILES_DIR__" \
    "__NEMU_CHECK_FULL_TMPFILES_FILE__" \
    "__NEMU_CHECK_FULL_TMPFILES_LOG_BEGIN__" \
    "systemd-tmpfiles --create" \
    "nemu-full-tmpfiles-ok" \
    "__NEMU_CHECK_FULL_JOURNALD_ACTIVE__" \
    "__NEMU_CHECK_FULL_JOURNAL_DIR_BEGIN__" \
    "__NEMU_CHECK_FULL_JOURNAL_DIR_END__" \
    "/run/systemd/journal/stdout" \
    "/run/systemd/journal/socket" \
    "__NEMU_CHECK_FULL_JOURNAL_CAT_RC__" \
    "__NEMU_CHECK_FULL_JOURNAL_CAT_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_JOURNAL_CAT_LOG_END__" \
    "__NEMU_CHECK_FULL_JOURNALCTL_SYNC_RC__" \
    "__NEMU_CHECK_FULL_JOURNALCTL_RC__" \
    "__NEMU_CHECK_FULL_JOURNALCTL_TAG__" \
    "__NEMU_CHECK_FULL_JOURNALCTL_EXPECT__" \
    "__NEMU_CHECK_FULL_JOURNALCTL_OUTPUT_BEGIN__" \
    "full_userland_fail" \
    "full_userland_ok" \
    "systemd-cat -t" \
    "/bin/sh -c 'printf" \
    "nemu-full-journal-probe" \
    "journalctl --sync" \
    "journalctl -t" \
    "nemu-full-journal" \
    "systemctl start syslog.socket" \
    "systemctl restart rsyslog.service" \
    "rsyslogd -N1" \
    "__NEMU_CHECK_FULL_CRON_EXEC_FILE__" \
    "__NEMU_CHECK_FULL_RSYSLOG_PROBE_CONF__" \
    "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_RC__" \
    "__NEMU_CHECK_FULL_RSYSLOG_LOGGER_FILE__" \
    "logger -p user.notice" \
    "nemu-full-cron-check" \
    "99-nemu-full-rsyslog-check.conf" \
    "/var/log/nemu-full-rsyslog.log" \
    "nemu-full-rsyslog-ok" \
    "dpkg --audit" \
    "dpkg-query -W" \
    "dpkg -L" \
    "dpkg -S" \
    "apt-cache policy" \
    "__NEMU_CHECK_FULL_GPGV_VERSION__" \
    "__NEMU_CHECK_FULL_APT_KEYRING_SHA256__" \
    "1a4dd63e5c76728960a2edddae22e2e0fc53df8e8b87806deb971030ac704eb0" \
    "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__" \
    "__NEMU_CHECK_FULL_DPKG_QUERY__" \
    "__NEMU_CHECK_FULL_DPKG_LIST__" \
    "__NEMU_CHECK_FULL_DPKG_SEARCH__" \
    "__NEMU_CHECK_FULL_APT_POLICY_RC__" \
    "full-userland-dpkg-list-" \
    "full-userland-dpkg-search-" \
    "sshd -T" \
    "systemctl start ssh.service" \
    "__NEMU_CHECK_FULL_SSH_LISTEN_SOCKET__" \
    "__NEMU_CHECK_FULL_SSH_DROPBEAR_READY__" \
    "__NEMU_CHECK_FULL_SSH_SERVER__:dropbear-loopback" \
    "__NEMU_CHECK_FULL_SSH_CLIENT__:dbclient" \
    "__NEMU_CHECK_FULL_SSH_LOGIN_OK__" \
    "__NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_CURL_HTTP_CODE__" \
    "__NEMU_CHECK_FULL_WGET_HTTP_CODE__" \
    "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__" \
    "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__" \
    "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PREINST_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_EFFECT_OK_AFTER_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PREINST__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_START__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TARGET__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_APT_STATE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_STATUS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PID__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_SAMPLE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_TAIL_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOCKS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DEADLINE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_MESSAGE_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_PREINST_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_POSTINST_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_DPKG_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_MESSAGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_PREINST__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_POSTINST__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_DPKG_STATUS__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_EFFECT_OK_AFTER_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_HELLO_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_HELLO_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_META_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_META_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_OWNERSHIP_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_START__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_TARGET__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_APT_STATE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_STATUS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_PID__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_SAMPLE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_PS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_TAIL_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOCKS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_DEADLINE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_PRERM_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_POSTRM_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_META_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_HELLO_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_EFFECT_OK_AFTER_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PRERM__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTRM__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_REMOVE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_AFTER_REMOVE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_START__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_TARGET__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_APT_STATE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_STATUS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_PID__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_SAMPLE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_PS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_TAIL_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOCKS_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_TIMEOUT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_DEADLINE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_META_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_HELLO_STATUS_SNAPSHOT__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_PURGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE_AFTER_PURGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_SEARCH_AFTER_PURGE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_OWNERSHIP_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__" \
    "http://nemu.local/nemu-health" \
    "http://nemu.local/nemu-missing" \
    "http://nemu.local/ubuntu" \
    "apt-get download nemu-hostless-hello:riscv64=1.0" \
    "nemu-hostless-meta:riscv64=1.0" \
    "nemu-hostless-meta:riscv64=1.1" \
    "nemu-hostless-hello:riscv64=1.0 nemu-hostless-meta:riscv64=1.0" \
    "nemu-hostless-hello:riscv64=1.1 nemu-hostless-meta:riscv64=1.1" \
    "preinst from NEMU hostless meta" \
    "postinst from NEMU hostless meta" \
    "preinst from NEMU hostless meta v1.1" \
    "postinst from NEMU hostless meta v1.1" \
    "prerm from NEMU hostless meta v1.1" \
    "postrm from NEMU hostless meta v1.1" \
    "preinst-message" \
    "postinst-message" \
    "prerm-message" \
    "postrm-message" \
    "apt-get -s install" \
    "apt-get --download-only install" \
    "apt-get remove -y" \
    "Dir::State::status" \
    "status-empty-simulate" \
    "status-empty-download" \
    "status-empty-install" \
    "status-upgrade-installed-v1" \
    "status-remove-installed" \
    "status-purge-config-files" \
    "installed-v1-target-status-real-dpkg" \
    "installed-v1.1-target-status-real-dpkg" \
    "config-files-v1.1-target-status-real-dpkg" \
    "dpkg-query -s nemu-hostless-hello nemu-hostless-meta" \
    "dpkg -L nemu-hostless-hello" \
    "dpkg -L nemu-hostless-meta" \
    "dpkg -S /usr/share/nemu-hostless-hello/message" \
    "dpkg -S /usr/share/nemu-hostless-meta/message" \
    "apt-get purge -y" \
    "download-status-empty" \
    "Dpkg::Use-Pty=0" \
    "ps -eo pid,ppid,stat,etime,args" \
    "tail -n 80" \
    "kill -KILL" \
    "dpkg -i" \
    "curl -4 -fsS" \
    "--head" \
    "apt-get update" \
    "Dir::Etc::sourcelist" \
    "--inet4-only" \
    "--server-response" \
    "__NEMU_CHECK_FULL_SSH_DEBUG_READY__" \
    "__NEMU_CHECK_FULL_SSH_DEBUG_LOGIN_RC__" \
    "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_BEGIN__" \
    "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_SSH_NOPAM_READY__" \
    "__NEMU_CHECK_FULL_SSH_NOPAM_LOGIN_RC__" \
    "__NEMU_CHECK_FULL_SSH_NOPAM_CLIENT_BEGIN__" \
    "__NEMU_CHECK_FULL_SSH_NOPAM_DEBUGD_LOG_BEGIN__" \
    "__NEMU_CHECK_FULL_SSH_NOPAM_LOGIN_OK__" \
    "__NEMU_CHECK_FULL_SSH_SERVER_LOG_BEGIN__" \
    "sshd -D -ddd -e" \
    "p 2222" \
    "p 2223" \
    "UsePAM=no" \
    "PreferredAuthentications=publickey" \
    "KexAlgorithms=curve25519-sha256" \
    "HostKeyAlgorithms=ssh-ed25519" \
    "PubkeyAcceptedAlgorithms=ssh-ed25519" \
    "Ciphers=chacha20-poly1305@openssh.com" \
    "dropbearconvert openssh dropbear" \
    "dropbearkey -t ed25519" \
    "/usr/sbin/dropbear -E -F" \
    "127.0.0.1:2224" \
    "p 2224" \
    "dbclient -y" \
    "id_dropbear" \
    "NEMU SSH Test" \
    "ssh_login_user=nemu" \
    "ssh_login_uid=2000" \
    "ssh_login_gid=2000" \
    ">> /etc/passwd" \
    "BatchMode=yes" \
    "ConnectTimeout=120" \
    "authorized_keys" \
    "/proc/net/tcp6" \
    "check_nemu_net_runtime" \
    'guest_script_sha="${guest_script_sha%%%% *}"' \
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
    "check_efi_boot_path_context" \
    "efi-dtb-boot-benign" \
    "efi: UEFI not found" \
    "EFI services will not be available" \
    "Machine model: YSYX NPC RV64" \
    "Kernel command line: console=ttyS0,115200n8 root=/dev/vda" \
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
    if grep -Fq -- "$pattern" "$check_script"; then
      printf 'PASS check-nemu-systemd-guest.sh %s\n' "$pattern"
    else
      printf 'FAIL check-nemu-systemd-guest.sh %s\n' "$pattern"
      missing=1
    fi
  done

  if grep -Fq -- "trusted=yes" "$check_script"; then
    printf 'FAIL check-nemu-systemd-guest.sh avoids trusted=yes for hostless apt\n'
    missing=1
  else
    printf 'PASS check-nemu-systemd-guest.sh avoids trusted=yes for hostless apt\n'
  fi

  echo
  echo "[nemu-ubuntu] required focused wrapper host marker hooks"
  for pattern in \
    "focused-make.log" \
    "PASS focused host marker" \
    "FAIL focused host marker" \
    "PASS focused full userland marker" \
    "FAIL focused full userland marker" \
    "PASS focused soak marker" \
    "FAIL focused soak marker" \
    "__NEMU_CHECK_PASS__:full-userland-runtime" \
    "__NEMU_CHECK_PASS__:soak-uptime" \
    "__NEMU_CHECK_PASS__:interrupts-stat-monotonic" \
    "check-nemu-systemd-guest-full" \
    "check-nemu-systemd-guest-full-soak" \
    "AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_DIAG" \
    "AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL" \
    "AGENT_E2E_NEMU_UBUNTU_FULL_CHECK_MAX_CYCLES" \
    "240000000000" \
    "1200" \
    "AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE" \
    "[nemu-systemd-check] PASS virtio-blk-async-runtime" \
    "[nemu-systemd-check] PASS virtio-net-runtime" \
    "[nemu-systemd-check] PASS rootfs-backing-unchanged"; do
    if grep -Fq -- "$pattern" "$nemu_module_sh"; then
      printf 'PASS nemu.sh %s\n' "$pattern"
    else
      printf 'FAIL nemu.sh %s\n' "$pattern"
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
    if grep -Fq -- "$pattern" "$check_script"; then
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
    "serial_dump_machine_info" \
    "serial_qmp_query_serial" \
    "serial_host_backend_name" \
    "CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL" \
    "SERIAL_INPUT_HOST_POLL_INTERVAL" \
    "serial_port_service" \
    "host_rx_dropped" \
    "NEMU_SERIAL_FIFO" \
    "serial_port_poll_host"; do
    if grep -Fq -- "$pattern" "$serial_c"; then
      printf 'PASS serial.c %s\n' "$pattern"
    else
      printf 'FAIL serial.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "uart16550_rx_room" \
    "uart16550_receive" \
    "uart16550_snapshot"; do
    if grep -Fq -- "$pattern" "$uart16550_c"; then
      printf 'PASS uart16550.c %s\n' "$pattern"
    else
      printf 'FAIL uart16550.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "Uart16550Snapshot" \
    "uart16550_snapshot"; do
    if grep -Fq -- "$pattern" "$uart16550_h"; then
      printf 'PASS uart16550.h %s\n' "$pattern"
    else
      printf 'FAIL uart16550.h %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "device_update_after_inst" \
    "serial_poll_input"; do
    if grep -Fq -- "$pattern" "$device_c"; then
      printf 'PASS device.c %s\n' "$pattern"
    else
      printf 'FAIL device.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "def checked_dump_dir" \
    "def sign_release" \
    "HOSTLESS_APT_SIGNING_FINGERPRINT" \
    "E6742789E6F3AAEAD748589209108C9EAFAA6C14" \
    "--faked-system-time" \
    "InRelease" \
    "nemu-hostless-archive-keyring.gpg" \
    "refusing to dump hostless APT assets into the repository root" \
    "--allow-repo-root-dump" \
    "nemu-hostless-hello_1.1_riscv64.deb" \
    'depends="nemu-hostless-hello (= 1.1)"' \
    '"depends": "nemu-hostless-hello (= 1.1)"'; do
    if grep -Fq -- "$pattern" "$gen_nemu_hostless_apt_assets_py"; then
      printf 'PASS gen-nemu-hostless-apt-assets.py %s\n' "$pattern"
    else
      printf 'FAIL gen-nemu-hostless-apt-assets.py %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    'stdout-path = "serial0:115200n8";' \
    "serial0 = &UART0;" \
    'compatible = "ns16550a";'; do
    if grep -Fq -- "$pattern" "$gen_dts"; then
      printf 'PASS gen_dts.py %s\n' "$pattern"
    else
      printf 'FAIL gen_dts.py %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "ROOTFS_FLAVOR=\${UBUNTU_ROOTFS_FLAVOR:-systemd-minimal}" \
    "ubuntu_rootfs_flavor_artifact_suffix" \
    "ROOTFS_ARTIFACT_SUFFIX" \
    "ubuntu_rootfs_flavor_include_csv" \
    "ubuntu_rootfs_flavor_image_size" \
    "UBUNTU_DEBOOTSTRAP_VARIANT" \
    "pam_usr_dir" \
    "install_full_runtime_defaults" \
    "sshd_config" \
    "syslog:x:101:101" \
    "sshd:x:102:102" \
    "ssh-keygen -A" \
    "syslog.service" \
    "e2scrub_reap.service" \
    "e2scrub_all.timer" \
    "../../../usr/lib/riscv64-linux-gnu/security"; do
    if grep -Fq -- "$pattern" "$build_ubuntu_rootfs_sh"; then
      printf 'PASS build-ubuntu-rootfs.sh %s\n' "$pattern"
    else
      printf 'FAIL build-ubuntu-rootfs.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "ubuntu_rootfs_flavor_packages" \
    "ubuntu_rootfs_flavor_no_recommends" \
    "UBUNTU_ROOTFS_FLAVOR" \
    "dpkg_status_mark_installed" \
    "dpkg_info_install_records" \
    "print \"/.\"" \
    "Status: install ok installed" \
    "dpkg-deb -c" \
    "dpkg-deb -e" \
    "refresh dpkg status for unpacked packages" \
    "pam_usr_dir" \
    "sshd_config" \
    "syslog:x:101:101" \
    "sshd:x:102:102" \
    "ssh-keygen -A" \
    "syslog.service" \
    "e2scrub_reap.service" \
    "e2scrub_all.timer" \
    "../../../usr/lib/riscv64-linux-gnu/security"; do
    if grep -Fq -- "$pattern" "$build_ubuntu_systemd_overlay_sh"; then
      printf 'PASS build-ubuntu-systemd-overlay.sh %s\n' "$pattern"
    else
      printf 'FAIL build-ubuntu-systemd-overlay.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "ubuntu_rootfs_flavor_packages" \
    "systemd-minimal" \
    "interactive" \
    "/bin/ping" \
    "ubuntu-standard" \
    "openssh-server" \
    "dropbear-bin" \
    "/usr/bin/apt-cache" \
    "/usr/bin/gpgv" \
    "/bin/journalctl" \
    "/bin/systemd-sysusers" \
    "/bin/systemd-tmpfiles" \
    "/usr/bin/systemd-cat" \
    "/usr/bin/logger" \
    "/usr/bin/dpkg" \
    "/usr/bin/dpkg-query" \
    "ubuntu-keyring" \
    "/usr/bin/dbclient" \
    "/usr/bin/dropbearconvert" \
    "/usr/bin/dropbearkey" \
    "/usr/sbin/dropbear" \
    "/usr/share/keyrings/ubuntu-archive-keyring.gpg" \
    "ubuntu_rootfs_flavor_check" \
    "PASS rootfs-flavor manifest" \
    "ubuntu_rootfs_flavor_required_paths"; do
    if grep -Fq -- "$pattern" "$ubuntu_rootfs_flavors_sh"; then
      printf 'PASS ubuntu-rootfs-flavors.sh %s\n' "$pattern"
    else
      printf 'FAIL ubuntu-rootfs-flavors.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "/usr/bin/lsb_release" \
    "Ubuntu identity command" \
    "UBUNTU_ROOTFS_FLAVOR" \
    "ubuntu_rootfs_flavor_artifact_suffix" \
    "ROOTFS_ARTIFACT_SUFFIX" \
    "ubuntu_rootfs_flavor_required_paths" \
    "PAM login module" \
    "pam_unix.so" \
    "OpenSSH server config" \
    "syslog passwd entry" \
    "sshd passwd entry" \
    "OpenSSH ed25519 host key" \
    "OpenSSH rsa host key" \
    "syslog service alias" \
    "apt signature verifier" \
    "journal query tool" \
    "sysusers tool" \
    "sysusers setup unit" \
    "sysusers base config" \
    "tmpfiles tool" \
    "tmpfiles setup unit" \
    "journal stdin tool" \
    "Ubuntu archive keyring" \
    "rootfs_dpkg_status_installed" \
    "rootfs_dpkg_info_list_contains" \
    "rootfs_dpkg_info_list_files" \
    "rootfs_dpkg_info_list_invalid_records" \
    "dpkg status installed" \
    "dpkg info list" \
    "dpkg info list valid names" \
    "root-slash:/" \
    "dpkg info ownership" \
    "systemd:/bin/journalctl" \
    "systemd:/bin/systemd-sysusers" \
    "systemd:/bin/systemd-tmpfiles" \
    "systemd:/usr/bin/systemd-cat" \
    "ubuntu-standard openssh-server curl wget dropbear-bin rsyslog cron systemd-timesyncd gpgv ubuntu-keyring" \
    "boot-blocking e2scrub reap masked" \
    "periodic e2scrub timer masked" \
    "flavor_missing"; do
    if grep -Fq -- "$pattern" "$check_ubuntu_rootfs_sh"; then
      printf 'PASS check-ubuntu-rootfs.sh %s\n' "$pattern"
    else
      printf 'FAIL check-ubuntu-rootfs.sh %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "NEMU_SYSTEMD_CHECK_MAX_CYCLES ?= 50000000000" \
    "NEMU_SYSTEMD_FULL_CHECK_MAX_CYCLES ?= 80000000000" \
    "NEMU_SYSTEMD_FULL_CHECK_TIMEOUT ?= 3000" \
    "NEMU_SYSTEMD_APT_INSTALL_DIAG ?= 0" \
    "NEMU_SYSTEMD_APT_INSTALL_ACTUAL ?= 0" \
    "NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT ?= 300" \
    "NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT ?= 600" \
    "NEMU_SYSTEMD_SOAK_CHECK_MAX_CYCLES ?= 90000000000" \
    "NEMU_SYSTEMD_SOAK_CHECK_TIMEOUT ?= 3600" \
    "NEMU_SYSTEMD_ROOTFS_OVERLAY ?= \$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw" \
    "NEMU_SYSTEMD_ROOTFS_FLAVOR ?= systemd-minimal" \
    "NEMU_SYSTEMD_ROOTFS_CHECK_TARGET =" \
    "NEMU_SYSTEMD_FULL_CHECK_LOG_DIR ?= \$(LOG_ROOT)/riscv64-nemu-systemd-guest-full-check" \
    "NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR ?= \$(LOG_ROOT)/riscv64-nemu-systemd-guest-full-soak-check" \
    "UBUNTU_ROOTFS_FLAVOR ?= systemd-minimal" \
    "UBUNTU_ROOTFS_INTERACTIVE_IMAGE ?= \$(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-interactive.ext4" \
    "UBUNTU_ROOTFS_FULL_IMAGE ?= \$(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4" \
    "UBUNTU_ROOTFS_CPIO_IMAGE ?= \$(UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE)" \
    "NEMU_RUN_ROOTFS_OVERLAY ?=" \
    "NEMU_RUN_ROOTFS_OVERLAY_RESET ?= 1" \
    "--block-overlay='\$(NEMU_RUN_ROOTFS_OVERLAY)'" \
    "ubuntu-rootfs-flavors-check:" \
    "ubuntu-rootfs-flavors.sh' --check" \
    "ubuntu-rootfs-interactive-image:" \
    "UBUNTU_ROOTFS_FLAVOR=interactive" \
    "UBUNTU_ROOTFS_IMAGE='\$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)'" \
    "UBUNTU_ROOTFS_DIR='\$(ENV_ROOT)/images/ubuntu2204/rootfs-interactive'" \
    "ubuntu-rootfs-full-image:" \
    "UBUNTU_ROOTFS_FLAVOR=full" \
    "UBUNTU_ROOTFS_IMAGE='\$(UBUNTU_ROOTFS_FULL_IMAGE)'" \
    "UBUNTU_ROOTFS_DIR='\$(ENV_ROOT)/images/ubuntu2204/rootfs-full'" \
    "check-ubuntu-rootfs-interactive:" \
    "UBUNTU_ROOTFS_IMAGE='\$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_FLAVOR=interactive" \
    "check-ubuntu-rootfs-full:" \
    "UBUNTU_ROOTFS_IMAGE='\$(UBUNTU_ROOTFS_FULL_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_FLAVOR=full" \
    "UBUNTU_ROOTFS_FLAVOR='\$(UBUNTU_ROOTFS_FLAVOR)'" \
    "UBUNTU_ROOTFS_CPIO_IMAGE='\$(UBUNTU_ROOTFS_CPIO_IMAGE)'" \
    "check-nemu-systemd-guest-full:" \
    "NEMU_SYSTEMD_ROOTFS_FLAVOR=full" \
    "UBUNTU_ROOTFS_IMAGE='\$(UBUNTU_ROOTFS_FULL_IMAGE)'" \
    "NEMU_SYSTEMD_CHECK_LOG_DIR='\$(NEMU_SYSTEMD_FULL_CHECK_LOG_DIR)'" \
    "check-nemu-systemd-guest-full-soak:" \
    "NEMU_SYSTEMD_CHECK_LOG_DIR='\$(NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR)'" \
    "NEMU_SYSTEMD_SOAK_SECONDS='\$(NEMU_SYSTEMD_SOAK_SOAK_SECONDS)'" \
    "NEMU_SYSTEMD_FS_STRESS_MIB='\$(NEMU_SYSTEMD_SOAK_FS_STRESS_MIB)'" \
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
    "NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_NEMU_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke-system-powerdown-nemu.log" \
    "NEMU_QMP_SMOKE_GUEST_SHUTDOWN_NEMU_LOG ?= \$(BUILD_DIR)/nemu-qmp-smoke-guest-shutdown-nemu.log" \
    "NEMU_QMP_SMOKE_OVERLAY ?= \$(BUILD_DIR)/nemu-qmp-smoke-overlay.raw" \
    "NEMU_QMP_SMOKE_RUNTIME_OVERLAY ?= \$(BUILD_DIR)/nemu-qmp-smoke-runtime-overlay.raw" \
    "NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_IMAGE ?= \$(BUILD_DIR)/nemu-qmp-smoke-system-powerdown.bin" \
    "NEMU_QMP_SMOKE_GUEST_SHUTDOWN_IMAGE ?= \$(BUILD_DIR)/nemu-qmp-smoke-guest-shutdown.bin" \
    "NEMU_QMP_SMOKE_RUNTIME_MAX_INSTS ?= 1000000000" \
    "nemu-qmp-smoke: sim check-ubuntu-rootfs-systemd \$(OPENSBI_ROOTFS_FW) \$(NEMU_ROOTFS_DTB) \$(LINUX_IMAGE)" \
    "check-nemu-qmp-smoke.py" \
    "--block-image '\$(UBUNTU_ROOTFS_IMAGE)'" \
    "--overlay-image '\$(NEMU_QMP_SMOKE_OVERLAY)'" \
    "--runtime-overlay-image '\$(NEMU_QMP_SMOKE_RUNTIME_OVERLAY)'" \
    "--system-powerdown-nemu-log '\$(NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_NEMU_LOG)'" \
    "--system-powerdown-image '\$(NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_IMAGE)'" \
    "--guest-shutdown-nemu-log '\$(NEMU_QMP_SMOKE_GUEST_SHUTDOWN_NEMU_LOG)'" \
    "--guest-shutdown-image '\$(NEMU_QMP_SMOKE_GUEST_SHUTDOWN_IMAGE)'" \
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
    "VIRTIO_RING_F_INDIRECT_DESC" \
    "VIRTIO_RING_F_EVENT_IDX" \
    "virtio_rng_indirect_desc_enabled" \
    "virtio_rng_event_idx_enabled" \
    "virtq_collect_table" \
    "virtq_used_event_addr" \
    "virtq_avail_event_addr" \
    "virtq_need_event" \
    "virtq_set_avail_event" \
    "virtq_validate_queue_layout" \
    "virtq_dma_range_valid" \
    "virtio_rng_dump_machine_info" \
    "virtio_rng_qmp_query_rng" \
    "indirect-desc" \
    "host-urandom" \
    "queue-num-max" \
    "reject unsupported QueueNum"; do
    if grep -q "$pattern" "$rng_c"; then
      printf 'PASS rng.c %s\n' "$pattern"
    else
      printf 'FAIL rng.c %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "host_realtime_ns" \
    "goldfish_rtc_time_ns" \
    "goldfish_rtc_arm_alarm" \
    "alarm_running" \
    "irq_enabled" \
    "interrupt_pending && irq_enabled" \
    "goldfish_rtc_update_alarm" \
    "goldfish_rtc_dump_machine_info" \
    "goldfish_rtc_qmp_query_rtc" \
    "host-realtime-epoch+clint-mtime" \
    "low-then-high"; do
    if grep -q "$pattern" "$goldfish_rtc_c"; then
      printf 'PASS goldfish_rtc.c %s\n' "$pattern"
    else
      printf 'FAIL goldfish_rtc.c %s\n' "$pattern"
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
    "CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG" \
    "VirtioBlkAsyncReq" \
    "virtio_blk_worker_main" \
    "virtio_blk_submit_request" \
    "virtio_blk_complete_request" \
    "virtio_blk_mark_done_pending" \
    "virtio_blk_done_maybe_pending" \
    "virtio_blk_clear_done_pending_locked" \
    "__atomic_load_n" \
    "__atomic_store_n" \
    "async_completion_fast_flag" \
    "virtio_blk_update" \
    "virtio_blk_statistic" \
    "selected_queue" \
    "virtio_blk_process_queue(value)" \
    "virtio_blk_build_request" \
    "virtio_blk_req_copy_from_guest" \
    "virtio_blk_req_copy_to_guest" \
    "VIRTIO_BLK_S_IOERR" \
    "VIRTIO_BLK_S_UNSUPP" \
    "disk_range_ok" \
    "guest_range_ok" \
    "VIRTQ_DESC_F_INDIRECT" \
    "virtq_collect_table" \
    "virtq_collect_chain" \
    "seen\[idx\]" \
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
    "monitor.qmp.mode=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown-quit" \
    "serial_dump_machine_info" \
    "isa_riscv_clint_dump_machine_info" \
    "isa_riscv_plic_dump_machine_info" \
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
    "startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown" \
    "qmp_wait_for_client_if_enabled" \
    "atomic_bool qmp_cont_requested" \
    "atomic_bool qmp_stop_requested" \
    "atomic_bool qmp_shutdown_event_sent" \
    "atomic_int qmp_runtime_client_fd" \
    "pthread_cond_t qmp_pause_cond" \
    "pthread_mutex_t qmp_write_lock" \
    "atomic_exchange_explicit" \
    "atomic_compare_exchange_strong_explicit" \
    "MSG_NOSIGNAL" \
    "qmp_write_event" \
    "qmp_emit_shutdown_event" \
    "qmp_notify_shutdown_event" \
    "CLOCK_REALTIME" \
    "qmp_cpu_pause_point" \
    "pthread_cond_wait" \
    "qmp_capabilities" \
    "query-status" \
    "query-memory-size-summary" \
    "query-block" \
    "virtio_blk_qmp_query_block" \
    "query-blockstats" \
    "virtio_blk_qmp_query_blockstats" \
    "query-chardev" \
    "serial_qmp_query_chardev" \
    "query-serial" \
    "serial_qmp_query_serial" \
    "query-netdev" \
    "virtio_net_qmp_query_netdev" \
    "query-rng" \
    "virtio_rng_qmp_query_rng" \
    "query-rtc" \
    "goldfish_rtc_qmp_query_rtc" \
    "query-interrupts" \
    "qmp_query_interrupts" \
    "isa_riscv64_clint_qmp_snapshot" \
    "isa_riscv64_plic_qmp_snapshot" \
    "query-pci" \
    "query-version" \
    "query-kvm" \
    "query-qmp-schema" \
    "query-events" \
    "system_reset" \
    "qmp_request_system_reset" \
    "isa_riscv_restart" \
    "system_powerdown" \
    "qmp_request_powerdown" \
    "qmp_extract_execute" \
    "qmp_extract_request_id" \
    "qmp_write_reply" \
    "qmp_format_schema" \
    "qmp_format_event_list" \
    "EventInfoList" \
    "SchemaInfoList" \
    "meta-type" \
    "ysyx-nemu" \
    "query-cpus-fast" \
    "cont" \
    "stop" \
    "RESUME" \
    "RESET" \
    "STOP" \
    "SHUTDOWN" \
    "qmp_start_runtime_client" \
    "qmp_runtime_client_main" \
    "QMP runtime client active" \
    "QMP cont requested" \
    "QMP stop requested" \
    "QMP guest shutdown event emitted" \
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
    "qmp_cpu_pause_point" \
    "qmp_notify_shutdown_event"; do
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
    if grep -Fq -- "$pattern" "$nemu_filelist_mk"; then
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
  if grep -q "void qmp_notify_shutdown_event(void);" "$qmp_h"; then
    printf 'PASS qmp.h qmp_notify_shutdown_event prototype\n'
  else
    printf 'FAIL qmp.h qmp_notify_shutdown_event prototype\n'
    missing=1
  fi
  for pattern in \
    "gdbstub_set_port" \
    "gdbstub_capability" \
    "gdbstub_wait_for_client_if_enabled" \
    "qSupported" \
    "QStartNoAckMode+" \
    "QStartNoAckMode" \
    "gdbstub_no_ack_mode" \
    "GDB stub no-ack mode enabled" \
    "payload_len > 0" \
    "qXfer:features:read" \
    "gdbstub_target_xml" \
    "handle_qxfer_features_read" \
    "qXfer:memory-map:read" \
    "gdbstub_memory_map_xml" \
    "handle_qxfer_memory_map_read" \
    "CONFIG_MBASE" \
    "CONFIG_MSIZE" \
    "riscv:rv64" \
    "handle_read_all_regs" \
    "handle_write_one_reg" \
    "handle_read_memory" \
    "handle_write_memory" \
    "handle_single_step" \
    "handle_continue" \
    "handle_breakpoint_packet" \
    "gdbstub_breakpoint_hit" \
    "GDBSTUB_MAX_BREAKPOINTS" \
    "swbreak+" \
    "hwbreak+" \
    "watchpoint+" \
    "GDBSTUB_POINT_HW_BREAK" \
    "GDBSTUB_POINT_SW_BREAK" \
    "GDBSTUB_POINT_WRITE_WATCH" \
    "GDBSTUB_POINT_READ_WATCH" \
    "GDBSTUB_POINT_ACCESS_WATCH" \
    "gdbstub_watchpoint_after_access" \
    "gdbstub_range_overlap" \
    "GDB stub %s hit" \
    "vContSupported+" \
    "handle_vcont_packet" \
    "parse_vcont_segment" \
    "handle_thread_info_packet" \
    "qfThreadInfo" \
    "qThreadExtraInfo" \
    "async-stop+" \
    "gdbstub_async_stop_requested" \
    "MSG_DONTWAIT" \
    "cpu_exec(1)" \
    "cpu_exec(UINT64_MAX)" \
    "parse_word_le_hex" \
    "remote-startup-rw-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack" \
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
  if grep -q "bool gdbstub_breakpoint_hit(vaddr_t pc);" "$gdbstub_h"; then
    printf 'PASS gdbstub.h gdbstub_breakpoint_hit prototype\n'
  else
    printf 'FAIL gdbstub.h gdbstub_breakpoint_hit prototype\n'
    missing=1
  fi
  if grep -q "void gdbstub_watchpoint_after_access(vaddr_t addr, int len, bool is_write);" "$gdbstub_h"; then
    printf 'PASS gdbstub.h gdbstub_watchpoint_after_access prototype\n'
  else
    printf 'FAIL gdbstub.h gdbstub_watchpoint_after_access prototype\n'
    missing=1
  fi
  if grep -q "bool gdbstub_async_stop_requested(void);" "$gdbstub_h"; then
    printf 'PASS gdbstub.h gdbstub_async_stop_requested prototype\n'
  else
    printf 'FAIL gdbstub.h gdbstub_async_stop_requested prototype\n'
    missing=1
  fi
  for pattern in \
    "sdb_exec_line" \
    "cmd_table[i].handler" \
    "Unknown command"; do
    if grep -Fq -- "$pattern" "$sdb_c"; then
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
    "CONFIG_DEVICE_UPDATE_CHECK_INTERVAL" \
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
    "CONFIG_INTERPRETER_TB_MAX_INST" \
    "execute_basic_block" \
    "interpreter_tb_should_stop" \
    "debug_breakpoint_stop" \
    "gdbstub_breakpoint_hit" \
    "gdbstub_async_stop_requested" \
    "GDB stub breakpoint hit at pc" \
    "GDB stub async halt at pc" \
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
  if grep -q "config INTERPRETER_TB_MAX_INST" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_TB_MAX_INST\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_TB_MAX_INST\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_IFETCH_PAGE_CACHE" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_IFETCH_PAGE_CACHE\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_IFETCH_PAGE_CACHE\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_BASIC_BLOCK=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_BASIC_BLOCK=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_BASIC_BLOCK=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_TB_MAX_INST=32" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_TB_MAX_INST=32\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_TB_MAX_INST=32\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_WIDE_IFETCH=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_WIDE_IFETCH=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_WIDE_IFETCH=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_IFETCH_PAGE_CACHE=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_IFETCH_PAGE_CACHE=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_IFETCH_PAGE_CACHE=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_DECODE_CACHE=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH=y\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=32768" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=32768\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=32768\n'
    missing=1
  fi
  if grep -q "CONFIG_INTERPRETER_INTR_FAST_FLAG=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_INTERPRETER_INTR_FAST_FLAG=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_INTERPRETER_INTR_FAST_FLAG=y\n'
    missing=1
  fi
  if grep -q "CONFIG_DEVICE_UPDATE_CHECK_INTERVAL=512" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_DEVICE_UPDATE_CHECK_INTERVAL=512\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_DEVICE_UPDATE_CHECK_INTERVAL=512\n'
    missing=1
  fi
  if grep -q "CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL=4" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL=4\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL=4\n'
    missing=1
  fi
  if grep -q "CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG=y" "$linux_defconfig"; then
    printf 'PASS riscv64-linux_defconfig CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG=y\n'
  else
    printf 'FAIL riscv64-linux_defconfig CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG=y\n'
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
  if grep -q "require_config_value CONFIG_INTERPRETER_TB_MAX_INST 32" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_TB_MAX_INST=32\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_TB_MAX_INST=32\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_WIDE_IFETCH" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_WIDE_IFETCH\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_WIDE_IFETCH\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_IFETCH_PAGE_CACHE" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_IFETCH_PAGE_CACHE\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_IFETCH_PAGE_CACHE\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_DECODE_CACHE" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH\n'
    missing=1
  fi
  if grep -q "require_config_value CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES 32768" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=32768\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES=32768\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_INTERPRETER_INTR_FAST_FLAG" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_INTERPRETER_INTR_FAST_FLAG\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_INTERPRETER_INTR_FAST_FLAG\n'
    missing=1
  fi
  if grep -q "require_config_value CONFIG_DEVICE_UPDATE_CHECK_INTERVAL 512" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_DEVICE_UPDATE_CHECK_INTERVAL=512\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_DEVICE_UPDATE_CHECK_INTERVAL=512\n'
    missing=1
  fi
  if grep -q "require_config_value CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL 4" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL=4\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL=4\n'
    missing=1
  fi
  if grep -q "require_config_enabled CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG" "$perf_config_sh"; then
    printf 'PASS check-nemu-performance-config.sh CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG\n'
  else
    printf 'FAIL check-nemu-performance-config.sh CONFIG_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG\n'
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
  if grep -q "config INTERPRETER_DECODE_DIRECT_DISPATCH" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_DECODE_DIRECT_DISPATCH\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_DECODE_DIRECT_DISPATCH\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_DECODE_CACHE_ENTRIES" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_DECODE_CACHE_ENTRIES\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_DECODE_CACHE_ENTRIES\n'
    missing=1
  fi
  if grep -q "config INTERPRETER_INTR_FAST_FLAG" "$cpu_kconfig"; then
    printf 'PASS cpu/Kconfig config INTERPRETER_INTR_FAST_FLAG\n'
  else
    printf 'FAIL cpu/Kconfig config INTERPRETER_INTR_FAST_FLAG\n'
    missing=1
  fi
  if grep -q "config DEVICE_UPDATE_CHECK_INTERVAL" "$kconfig"; then
    printf 'PASS device/Kconfig config DEVICE_UPDATE_CHECK_INTERVAL\n'
  else
    printf 'FAIL device/Kconfig config DEVICE_UPDATE_CHECK_INTERVAL\n'
    missing=1
  fi
  if grep -q "config SERIAL_INPUT_HOST_POLL_INTERVAL" "$kconfig"; then
    printf 'PASS device/Kconfig config SERIAL_INPUT_HOST_POLL_INTERVAL\n'
  else
    printf 'FAIL device/Kconfig config SERIAL_INPUT_HOST_POLL_INTERVAL\n'
    missing=1
  fi
  if grep -q "config VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG" "$kconfig"; then
    printf 'PASS device/Kconfig config VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG\n'
  else
    printf 'FAIL device/Kconfig config VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG\n'
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
  for pattern in \
    "CONFIG_RISCV_CLINT_HOST_TIME" \
    "clint_sync_host_time" \
    "clint_rebase_host_time" \
    "host-monotonic"; do
    if grep -q "$pattern" "$rv64_intr_c"; then
      printf 'PASS riscv64/system/intr.c %s\n' "$pattern"
    else
      printf 'FAIL riscv64/system/intr.c %s\n' "$pattern"
      missing=1
    fi
  done
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
  if grep -q 'config RISCV_CLINT_HOST_TIME' "$rv64_kconfig" &&
     ! grep -q 'config RISCV_CLINT_HOST_TIME' "$rv32_kconfig"; then
    printf 'PASS riscv64-only Kconfig CONFIG_RISCV_CLINT_HOST_TIME\n'
  else
    printf 'FAIL riscv64-only Kconfig CONFIG_RISCV_CLINT_HOST_TIME\n'
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
    "isa_riscv64_clint_dump_machine_info" \
    "isa_riscv64_clint_qmp_snapshot" \
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
  if grep -q "isa_riscv64_plic_maybe_pending" "$rv64_plic_c" &&
     grep -q "isa_riscv64_plic_dump_machine_info" "$rv64_plic_c" &&
     grep -q "isa_riscv64_plic_qmp_snapshot" "$rv64_plic_c" &&
     grep -q "plic_sources" "$rv64_plic_c"; then
    printf 'PASS riscv64/system/plic.c plic introspection hooks\n'
  else
    printf 'FAIL riscv64/system/plic.c plic introspection hooks\n'
    missing=1
  fi
  if grep -Eq 'isa_riscv32_|exec_rv32|riscv32_|CONFIG_RVE' \
      "${rv64_inst_files[@]}" "$rv64_intr_c" "$rv64_plic_c" "$mmu_c" \
      "$rv64_platform_h" "$rv64_isa_def_h" "$rv64_kconfig"; then
    printf 'FAIL riscv64 ISA files contain stale RV32/RVE symbols\n'
    missing=1
  else
    printf 'PASS riscv64 ISA files contain no RV32/RVE symbols\n'
  fi
  if grep -Eq 'exec_rv32i_|exec_rv32c|RV32I|RV32C' "${rv64_inst_files[@]}"; then
    printf 'FAIL riscv64 inst files contain stale RV32 helper names\n'
    missing=1
  else
    printf 'PASS riscv64 inst files helper names are RV64-specific\n'
  fi
  local rv64_inst_top_lines
  rv64_inst_top_lines=$(wc -l < "$rv64_inst_c")
  if [ "$rv64_inst_top_lines" -le 120 ]; then
    printf 'PASS riscv64/inst.c unity top stays small lines=%s\n' "$rv64_inst_top_lines"
  else
    printf 'FAIL riscv64/inst.c unity top too large lines=%s\n' "$rv64_inst_top_lines"
    missing=1
  fi
  if grep -Eq '^[[:space:]]*(static[[:space:]]+inline[[:space:]]+)?[A-Za-z_][A-Za-z0-9_ *]*exec_' "$rv64_inst_c"; then
    printf 'FAIL riscv64/inst.c contains direct exec helper implementation\n'
    missing=1
  else
    printf 'PASS riscv64/inst.c only orchestrates inst fragments\n'
  fi
  local rv64_inst_fragment_count=0
  local rv64_inst_fragment_missing=0
  local rv64_inst_fragment_path
  for rv64_inst_fragment_path in "$rv64_inst_dir"/*.c; do
    [ -e "$rv64_inst_fragment_path" ] || continue
    local rv64_inst_fragment_name
    rv64_inst_fragment_name=$(basename "$rv64_inst_fragment_path")
    rv64_inst_fragment_count=$((rv64_inst_fragment_count + 1))
    if grep -Fq "#include \"inst/$rv64_inst_fragment_name\"" "$rv64_inst_c"; then
      printf 'PASS riscv64/inst.c includes inst/%s\n' "$rv64_inst_fragment_name"
    else
      printf 'FAIL riscv64/inst.c missing inst/%s include\n' "$rv64_inst_fragment_name"
      rv64_inst_fragment_missing=1
    fi
  done
  if [ "$rv64_inst_fragment_count" -ge 8 ] && [ "$rv64_inst_fragment_missing" -eq 0 ]; then
    printf 'PASS riscv64/inst.c covers all inst fragments count=%s\n' "$rv64_inst_fragment_count"
  else
    printf 'FAIL riscv64/inst.c fragment coverage count=%s missing=%s\n' \
      "$rv64_inst_fragment_count" "$rv64_inst_fragment_missing"
    missing=1
  fi
  if grep -q 'src/isa/riscv64/inst' "$rv64_inst_filelist" &&
     grep -q 'SRCS-BLACKLIST-y' "$rv64_inst_filelist"; then
    printf 'PASS riscv64/filelist.mk blacklists unity-included inst fragments\n'
  else
    printf 'FAIL riscv64/filelist.mk blacklists unity-included inst fragments\n'
    missing=1
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
    "isa_riscv64_clint_dump_machine_info" \
    "isa_riscv_clint_dump_machine_info" \
    "isa_riscv64_clint_qmp_snapshot" \
    "isa_riscv_clint_qmp_snapshot" \
    "isa_riscv64_plic_dump_machine_info" \
    "isa_riscv_plic_dump_machine_info" \
    "isa_riscv64_plic_qmp_snapshot" \
    "isa_riscv_plic_qmp_snapshot" \
    "isa_riscv64_mmu_fault_cause" \
    "isa_riscv_mmu_fault_cause" \
    "isa_riscv64_pmp_check" \
    "isa_riscv64_pmp_check_as_priv" \
    "isa_riscv_pmp_check" \
    "isa_riscv64_pmp_dump_machine_info" \
    "isa_riscv_pmp_dump_machine_info" \
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
    "isa_riscv_clint_time_source" \
    "isa_riscv32_mmu_fault_cause" \
    "isa_riscv_mmu_fault_cause" \
    "isa_riscv32_pmp_check" \
    "isa_riscv_pmp_check"; do
    if grep -q "$pattern" "$rv32_platform_h"; then
      printf 'PASS riscv32 isa-platform.h %s\n' "$pattern"
    else
      printf 'FAIL riscv32 isa-platform.h %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "CSR_TIME:.*isa_riscv64_mtime_value" "${rv64_inst_files[@]}"; then
    printf 'PASS riscv64 inst files CSR_TIME uses mtime\n'
  else
    printf 'FAIL riscv64 inst files CSR_TIME uses mtime\n'
    missing=1
  fi
  if grep -q "CSR_TIME:.*isa_riscv32_mtime_value" "$rv32_inst_c"; then
    printf 'PASS riscv32/inst.c CSR_TIME uses mtime\n'
  else
    printf 'FAIL riscv32/inst.c CSR_TIME uses mtime\n'
    missing=1
  fi
  if grep -q "vaddr_ifetch_wide" "${rv64_inst_files[@]}"; then
    printf 'PASS riscv64 inst files vaddr_ifetch_wide\n'
  else
    printf 'FAIL riscv64 inst files vaddr_ifetch_wide\n'
    missing=1
  fi
  for pattern in \
    "rv_decode_cache" \
    "rv_decode_cache_inst_key" \
    "rv_decode_cache_exec" \
    "rv_decode_cache_dispatch" \
    "RV_DECODE_CACHE_USE_DIRECT_DISPATCH" \
    "CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH" \
    "rv_decode_cache_fill" \
    "rv_decode_cache_flush" \
    "CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES"; do
    if grep -q "$pattern" "${rv64_inst_files[@]}"; then
      printf 'PASS riscv64 inst files %s\n' "$pattern"
    else
      printf 'FAIL riscv64 inst files %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "vaddr_set_fault" \
    "vaddr_ifetch_wide" \
    "vaddr_ifetch_cache_lookup" \
    "vaddr_ifetch_cache_fill" \
    "vaddr_ifetch_cache_flush" \
    "vaddr_ifetch_cache_invalidate_write" \
    "vaddr_paddr_host_fast" \
    "vaddr_paddr_read_fast" \
    "vaddr_paddr_write_fast" \
    "vaddr_gdbstub_watchpoint_after_access" \
    "gdbstub_watchpoint_after_access" \
    "vaddr_notify_write_committed" \
    "isa_riscv_lr_sc_invalidate" \
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
    if grep -q "$pattern" "${rv64_inst_files[@]}"; then
      printf 'PASS riscv64 inst files %s\n' "$pattern"
    else
      printf 'FAIL riscv64 inst files %s\n' "$pattern"
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
    "amo_translate_paddr" \
    "lr_reservation_paddr" \
    "lr_reservation_len" \
    "lr_sc_reservation_matches" \
    "isa_riscv64_lr_sc_invalidate"; do
    if grep -q "$pattern" "${rv64_inst_files[@]}" "$rv64_platform_h"; then
      printf 'PASS riscv64 LR/SC reservation %s\n' "$pattern"
    else
      printf 'FAIL riscv64 LR/SC reservation %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_riscv32_lr_sc_invalidate" \
    "lr_reservation_len"; do
    if grep -q "$pattern" "$rv32_inst_c" "$rv32_platform_h"; then
      printf 'PASS riscv32 LR/SC reservation %s\n' "$pattern"
    else
      printf 'FAIL riscv32 LR/SC reservation %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "CSR_PMPCFG0" \
    "CSR_PMPCFG2" \
    "CSR_PMPADDR0" \
    "CSR_PMPADDR15" \
    "RISCV64_PMP_ENTRY_COUNT" \
    "PMP_CFG_A_TOR" \
    "PMP_CFG_A_NA4" \
    "PMP_CFG_A_NAPOT"; do
    if grep -q "$pattern" "$rv64_isa_def_h" "${rv64_inst_files[@]}" "$mmu_c"; then
      printf 'PASS riscv64 PMP %s\n' "$pattern"
    else
      printf 'FAIL riscv64 PMP %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "csr_pmpcfg_base" \
    "csr_read_pmpcfg" \
    "csr_write_pmpcfg" \
    "csr_write_pmpaddr" \
    "csr_pmpaddr_write_locked" \
    "PMP_CFG_L" \
    "isa_riscv64_mmu_tlb_flush"; do
    if grep -q "$pattern" "${rv64_inst_files[@]}"; then
      printf 'PASS riscv64 PMP CSR %s\n' "$pattern"
    else
      printf 'FAIL riscv64 PMP CSR %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_riscv64_pmp_check" \
    "isa_riscv64_pmp_check_as_priv" \
    "pmp_check_with_priv" \
    "pmp_decode_range" \
    "pmp_decode_napot" \
    "pmp_permission_ok" \
    "pmp_any_active" \
    "mmu_effective_priv(type)" \
    "pmp-page-table-read" \
    "pmp-page-table-write" \
    "sv39_translate_fault_cause" \
    "isa_riscv64_mmu_fault_cause" \
    "isa_riscv64_pmp_dump_machine_info"; do
    if grep -q "$pattern" "$mmu_c"; then
      printf 'PASS mmu.c PMP %s\n' "$pattern"
    else
      printf 'FAIL mmu.c PMP %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "vaddr_translate_fault_cause_for_type" \
    "vaddr_access_fault_cause_for_type" \
    "CAUSE_INST_ACCESS" \
    "CAUSE_LOAD_ACCESS" \
    "CAUSE_STORE_ACCESS" \
    "isa_riscv_mmu_fault_cause" \
    "isa_riscv_pmp_check" \
    "vaddr_pmp_check_or_fault"; do
    if grep -q "$pattern" "$vaddr_c"; then
      printf 'PASS vaddr.c PMP/access-fault %s\n' "$pattern"
    else
      printf 'FAIL vaddr.c PMP/access-fault %s\n' "$pattern"
      missing=1
    fi
  done
  if grep -q "isa_riscv32_pmp_check" "$rv32_inst_c" "$rv32_platform_h" &&
     grep -q "isa_riscv32_mmu_fault_cause" "$rv32_inst_c" "$rv32_platform_h" &&
     grep -q "isa_riscv_pmp_check" "$rv32_platform_h"; then
    printf 'PASS riscv32 PMP/MMU neutral stub\n'
  else
    printf 'FAIL riscv32 PMP/MMU neutral stub\n'
    missing=1
  fi
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
    "smoke-nemu-pmp-access" \
    "pmp-access-smoke.S" \
    "PMP_ACCESS_BIN" \
    "NEMU_PMP_ACCESS_LOG" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-pmp-pagewalk" \
    "pmp-pagewalk-smoke.S" \
    "PMP_PAGEWALK_BIN" \
    "NEMU_PMP_PAGEWALK_LOG" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-pmp-pagewalk-ad" \
    "pmp-pagewalk-ad-smoke.S" \
    "PMP_PAGEWALK_AD_BIN" \
    "NEMU_PMP_PAGEWALK_AD_LOG" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-lrsc-reservation" \
    "lrsc-reservation-smoke.S" \
    "LRSC_RESERVATION_BIN" \
    "NEMU_LRSC_RESERVATION_LOG" \
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
    "smoke-nemu-fp-convert" \
    "smoke-nemu-fp-compare-sgnj" \
    "smoke-nemu-fp-sqrt" \
    "fp-convert-smoke.S" \
    "fp-compare-sgnj-smoke.S" \
    "fp-sqrt-smoke.S" \
    "FP_CONVERT_NEMU_BIN" \
    "FP_COMPARE_SGNJ_NEMU_BIN" \
    "FP_SQRT_NEMU_BIN" \
    "NEMU_FP_CONVERT_LOG" \
    "NEMU_FP_COMPARE_SGNJ_LOG" \
    "NEMU_FP_SQRT_LOG" \
    "FP_SMOKE_NEMU_SYSCON_EXIT=1" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-virtio-blk-error" \
    "virtio-blk-error-smoke.S" \
    "VIRTIO_BLK_ERROR_BIN" \
    "NEMU_VIRTIO_BLK_ERROR_LOG" \
    "VIRTIO_BLK_ERROR_MAX_INSTS" \
    "HIT GOOD TRAP"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "smoke-nemu-virtio-net-ctrl" \
    "virtio-net-ctrl-smoke.S" \
    "VIRTIO_NET_CTRL_BIN" \
    "NEMU_VIRTIO_NET_CTRL_LOG" \
    "VIRTIO_NET_CTRL_MAX_INSTS" \
    "NEMU_PRESERVED_RUN" \
    "HIT GOOD TRAP" \
    "ctrl=8/1" \
    "ctrl_rx=2" \
    "ctrl_rx_extra=1" \
    "ctrl_vlan=2" \
    "vlan_active=0 vlan_last=42" \
    "ctrl_announce=1" \
    "announce_pending=0 announce_requested=1" \
    "alluni=1" \
    "ctrl_mac_table=1" \
    "ctrl_mac_addr=1" \
    "mac_uni=1 mac_multi=1" \
    "mac=02:00:5e:00:53:02" \
    "promisc=1"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "NEMU_CONFIG_PATHS" \
    "smoke-nemu-config-preserve" \
    "NEMU_CONFIG_HASH_BEFORE" \
    "NEMU_CONFIG_HASH_AFTER" \
    "PASS nemu-config-preserve"; do
    if grep -q "$pattern" "$linux_tools_mk"; then
      printf 'PASS Linux/tools/Makefile config-preserve %s\n' "$pattern"
    else
      printf 'FAIL Linux/tools/Makefile config-preserve %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    ".config" \
    ".config.old" \
    "include/config" \
    "include/generated" \
    "riscv64-linux_defconfig" \
    "restore_configs" \
    "trap cleanup EXIT INT TERM" \
    "build/riscv64-nemu-interpreter"; do
    if grep -q "$pattern" "$nemu_preserved_run_sh"; then
      printf 'PASS nemu-preserved-run.sh %s\n' "$pattern"
    else
      printf 'FAIL nemu-preserved-run.sh %s\n' "$pattern"
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
    "lr.w" \
    "sc.w" \
    "lr.d" \
    "sc.d" \
    "sw t0, 0(s0)" \
    "sb t0, 1(s0)" \
    "sw zero, 4(s1)" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$lrsc_reservation_smoke_s"; then
      printf 'PASS lrsc-reservation-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL lrsc-reservation-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "pmpaddr0" \
    "pmpaddr1" \
    "pmpcfg0" \
    "CAUSE_LOAD_ACCESS" \
    "CAUSE_STORE_ACCESS" \
    "CAUSE_INST_ACCESS" \
    "mret" \
    "mcause" \
    "mtval" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$pmp_access_smoke_s"; then
      printf 'PASS pmp-access-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL pmp-access-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "TEST_VA" \
    "l0_test_table" \
    "pmpaddr0" \
    "pmpaddr1" \
    "pmpcfg0" \
    "csrw satp" \
    "sfence.vma" \
    "CAUSE_LOAD_ACCESS" \
    "mcause" \
    "mtval" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$pmp_pagewalk_smoke_s"; then
      printf 'PASS pmp-pagewalk-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL pmp-pagewalk-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "TEST_VA" \
    "l0_test_table" \
    "PMP_CFG_R_NAPOT" \
    "PTE_VR" \
    "pmpaddr0" \
    "pmpaddr1" \
    "pmpcfg0" \
    "csrw satp" \
    "sfence.vma" \
    "CAUSE_LOAD_ACCESS" \
    "mcause" \
    "mtval" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$pmp_pagewalk_ad_smoke_s"; then
      printf 'PASS pmp-pagewalk-ad-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL pmp-pagewalk-ad-smoke.S %s\n' "$pattern"
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
    "VIRTIO_BLK_S_IOERR" \
    "VIRTIO_BLK_S_UNSUPP" \
    "setup_bad_read_direction" \
    "setup_bad_dma_range" \
    "setup_beyond_capacity" \
    "setup_unsupported_request" \
    "setup_cycle_chain" \
    "setup_nested_indirect" \
    "submit_expect_malformed_completion" \
    "VIRTIO_RING_F_INDIRECT_DESC_MASK" \
    "VIRTQ_DESC_F_INDIRECT" \
    "VIRTIO_INDIRECT_ADDR" \
    "REG_INTERRUPT_ACK" \
    "fail_used_len" \
    "fail_status_touched" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$virtio_blk_error_smoke_s"; then
      printf 'PASS virtio-blk-error-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL virtio-blk-error-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "VIRTIO_NET_F_CTRL_VQ_MASK" \
    "VIRTIO_NET_F_CTRL_RX_MASK" \
    "VIRTIO_NET_F_CTRL_VLAN_MASK" \
    "VIRTIO_NET_F_CTRL_RX_EXTRA_MASK" \
    "VIRTIO_NET_F_GUEST_ANNOUNCE_MASK" \
    "VIRTIO_NET_F_CTRL_MAC_ADDR_MASK" \
    "VIRTIO_NET_CTRL_QUEUE" \
    "VIRTIO_NET_CTRL_ACK_OK" \
    "VIRTIO_NET_CTRL_ACK_ERR" \
    "VIRTIO_NET_CTRL_RX_PROMISC" \
    "VIRTIO_NET_CTRL_RX_ALLUNI" \
    "VIRTIO_NET_CTRL_VLAN_ADD" \
    "VIRTIO_NET_CTRL_VLAN_DEL" \
    "VIRTIO_NET_CTRL_ANNOUNCE_ACK" \
    "VIRTIO_NET_CTRL_MAC_TABLE_SET" \
    "VIRTIO_NET_CTRL_MAC_ADDR_SET" \
    "setup_ctrl_rx_promisc_cmd" \
    "setup_ctrl_rx_alluni_cmd" \
    "setup_vlan_add_cmd" \
    "setup_vlan_del_cmd" \
    "setup_announce_ack_cmd" \
    "setup_mac_table_cmd" \
    "setup_mac_addr_cmd" \
    "REG_QUEUE_NOTIFY" \
    "REG_INTERRUPT_ACK" \
    "fail_used_len" \
    "fail_ack" \
    "SYSCON_POWEROFF_VALUE"; do
    if grep -q "$pattern" "$virtio_net_ctrl_smoke_s"; then
      printf 'PASS virtio-net-ctrl-smoke.S %s\n' "$pattern"
    else
      printf 'FAIL virtio-net-ctrl-smoke.S %s\n' "$pattern"
      missing=1
    fi
  done
  for pattern in \
    "isa_mmu_translate_host" \
    "host_page" \
    "sv39_host_page_base" \
    "vaddr_ifetch_cache_flush" \
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
    if grep -q "$pattern" "${rv64_inst_files[@]}"; then
      printf 'PASS riscv64 inst files %s\n' "$pattern"
    else
      printf 'FAIL riscv64 inst files %s\n' "$pattern"
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

e2e_nemu_ubuntu_focused_gate_impl() {
  local enable_var=$1
  local profile_name=$2
  local make_target=$3
  local gate_subdir=$4
  local timeout_var=$5

  if [[ ${!enable_var:-0} != 1 ]]; then
    echo "[nemu-ubuntu] SKIP: ${enable_var}=1 未设置，默认不跑十几分钟 focused guest gate"
    echo "[nemu-ubuntu] next: 需要真实 guest 证据时运行 ${enable_var}=1 scripts/agent-e2e.sh --profile ${profile_name}"
    return 77
  fi

  local gate_dir="$E2E_RUN_DIR/$gate_subdir"
  mkdir -p "$gate_dir"
  echo "[nemu-ubuntu] focused gate target: $make_target"
  echo "[nemu-ubuntu] focused gate log dir: $(e2e_relpath "$gate_dir")"
  local make_log="$gate_dir/focused-make.log"
  local gate_rc=0
  local gate_timeout="${!timeout_var:-${AGENT_E2E_NEMU_UBUNTU_TIMEOUT:-1700}}"
  local apt_install_diag_timeout="${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_DIAG_TIMEOUT:-}"
  if [[ -z "$apt_install_diag_timeout" ]]; then
    if [[ "${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL:-0}" == 1 ]]; then
      apt_install_diag_timeout=1200
    else
      apt_install_diag_timeout=300
    fi
  fi
  local full_check_max_cycles="${AGENT_E2E_NEMU_UBUNTU_FULL_CHECK_MAX_CYCLES:-}"
  if [[ -z "$full_check_max_cycles" \
    && "$make_target" == check-nemu-systemd-guest-full \
    && "${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL:-0}" == 1 ]]; then
    full_check_max_cycles=240000000000
  fi
  timeout "${gate_timeout}s" \
    make -C "$E2E_ROOT_DIR/Linux" ARCH=riscv64-nemu \
      NEMU_SYSTEMD_CHECK_LOG_DIR="$gate_dir" \
      NEMU_SYSTEMD_FULL_CHECK_LOG_DIR="$gate_dir" \
      NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR="$gate_dir" \
      NEMU_SYSTEMD_FULL_CHECK_MAX_CYCLES="${full_check_max_cycles:-80000000000}" \
      NEMU_SYSTEMD_SOAK_SECONDS="${AGENT_E2E_NEMU_UBUNTU_SOAK_SECONDS:-0}" \
      NEMU_SYSTEMD_FS_STRESS_MIB="${AGENT_E2E_NEMU_UBUNTU_FS_STRESS_MIB:-1}" \
      NEMU_SYSTEMD_FS_TREE_FILES="${AGENT_E2E_NEMU_UBUNTU_FS_TREE_FILES:-8}" \
      NEMU_SYSTEMD_PROCESS_LOOPS="${AGENT_E2E_NEMU_UBUNTU_PROCESS_LOOPS:-4}" \
      NEMU_SYSTEMD_UART_RX_STRESS_LINES="${AGENT_E2E_NEMU_UBUNTU_UART_RX_STRESS_LINES:-64}" \
      NEMU_SYSTEMD_INPUT_CHUNK_BYTES="${AGENT_E2E_NEMU_UBUNTU_INPUT_CHUNK_BYTES:-8}" \
      NEMU_SYSTEMD_INPUT_CHUNK_DELAY="${AGENT_E2E_NEMU_UBUNTU_INPUT_CHUNK_DELAY:-0}" \
      NEMU_SYSTEMD_APT_INSTALL_DIAG="${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_DIAG:-0}" \
      NEMU_SYSTEMD_APT_INSTALL_ACTUAL="${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL:-0}" \
      NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT="$apt_install_diag_timeout" \
      NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT="${AGENT_E2E_NEMU_UBUNTU_APT_REMOVE_DIAG_TIMEOUT:-600}" \
      NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS="${AGENT_E2E_NEMU_UBUNTU_BLOCK_PARALLEL_JOBS:-1}" \
      NEMU_SYSTEMD_BLOCK_JOB_MIB="${AGENT_E2E_NEMU_UBUNTU_BLOCK_JOB_MIB:-1}" \
      "$make_target" >"$make_log" 2>&1 || gate_rc=$?
  cat "$make_log"

  echo
  echo "[nemu-ubuntu] focused gate markers"
  grep -aE \
    "__NEMU_CHECK_(MEMTOTAL_KB|MIN_MEMTOTAL_KB|VDA_CACHE_TYPE|VDA_DISCARD_MAX|VDA_WRITE_ZEROES_MAX|RTC0_(NAME|HWCLOCK)|HWRNG_CURRENT|VIRTIO_RNG_(MODALIAS|DRIVER|STATUS|FEATURES)|VIRTIO_NET_(MODALIAS|DRIVER|STATUS|FEATURES|IFACE|MAC|MTU|SPEED|DUPLEX|IPV4|OPERSTATE|TX_PACKETS_(BEGIN|END)|RX_PACKETS_(BEGIN|END)|ROUTE|NEIGH|ARP)|FULL_(PYTHON_CNF|CNF_UPDATE_DB|PYTHON_TEXTWRAP|PYTHON_STDLIB|LSB_RELEASE))|__PYTHON_CNF_DIAG_|__NEMU_(ICMP|DHCP|DNS|TCP)_PROBE_(BURST|ITER|CONNECT|TX|RX|OFFER|ACK|PASS|FAIL)__|virtio-(blk-feature-(config-wce|topology|discard|write-zeroes)|rng-(modalias|driver|features-bitstring|feature-version-1|ring-feature-(indirect-desc|event-idx))|net-(modalias|driver|features-bitstring|feature-(version-1|mtu|mac|mrg-rxbuf|status|ctrl-vq|ctrl-rx|ctrl-vlan|ctrl-rx-extra|guest-announce|ctrl-mac-addr|speed-duplex)|ring-feature-(indirect-desc|event-idx)|interface|mac|mtu|speed|duplex|ipv4-static|icmp-echo|dhcp-lease|dns-a|tcp-http|runtime))|hwclock-rtc0-show|guest-memtotal-min|virtio-ring-feature-event-idx|__NEMU_SYSTEMD_CHECK_DONE__|HIT GOOD TRAP" \
    "$gate_dir/console.log" || true
  grep -aE "virtio-blk async runtime|virtio-blk-async-runtime|virtio-net runtime|virtio-net-runtime" \
    "$gate_dir/nemu.log" "$gate_dir/console.log" "$make_log" 2>/dev/null || true

  if [ "$gate_rc" -ne 0 ]; then
    printf 'FAIL focused gate command rc=%s\n' "$gate_rc"
    return "$gate_rc"
  fi
  for focused_marker in \
    "[nemu-systemd-check] PASS virtio-blk-async-runtime" \
    "[nemu-systemd-check] PASS virtio-net-runtime" \
    "[nemu-systemd-check] PASS rootfs-backing-unchanged"; do
    if grep -aFq "$focused_marker" "$make_log"; then
      printf 'PASS focused host marker %s\n' "$focused_marker"
    else
      printf 'FAIL focused host marker %s\n' "$focused_marker"
      return 1
    fi
  done
  if [[ "$make_target" == check-nemu-systemd-guest-full* ]]; then
    for full_marker in \
      "__NEMU_CHECK_PASS__:full-userland-ssh-active" \
      "__NEMU_CHECK_PASS__:full-userland-ssh-listen" \
      "__NEMU_CHECK_PASS__:full-userland-ssh-local-login" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-audit" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-package-ubuntu-standard" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-package-openssh-server" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-list-curl-curl" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-search-curl-curl" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-list-openssh-server-sshd" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-search-openssh-server-sshd" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-list-dropbear-bin-dbclient" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-search-dropbear-bin-dbclient" \
      "__NEMU_CHECK_PASS__:full-userland-gpgv-version" \
      "__NEMU_CHECK_PASS__:full-userland-apt-archive-keyring" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-package-gpgv" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-package-ubuntu-keyring" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-list-gpgv-gpgv" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-search-gpgv-gpgv" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-list-ubuntu-keyring-ubuntu-archive-keyring.gpg" \
      "__NEMU_CHECK_PASS__:full-userland-dpkg-search-ubuntu-keyring-ubuntu-archive-keyring.gpg" \
      "__NEMU_CHECK_PASS__:full-userland-apt-policy" \
      "__NEMU_CHECK_PASS__:full-userland-machine-id-setup-version" \
      "__NEMU_CHECK_PASS__:full-userland-machine-id-committed" \
      "__NEMU_CHECK_PASS__:full-userland-hostnamed-active" \
      "__NEMU_CHECK_PASS__:full-userland-hostnamectl-status" \
      "__NEMU_CHECK_PASS__:full-userland-sysusers-version" \
      "__NEMU_CHECK_PASS__:full-userland-sysusers-unit" \
      "__NEMU_CHECK_PASS__:full-userland-sysusers-create" \
      "__NEMU_CHECK_PASS__:full-userland-tmpfiles-version" \
      "__NEMU_CHECK_PASS__:full-userland-tmpfiles-unit" \
      "__NEMU_CHECK_PASS__:full-userland-tmpfiles-create" \
      "__NEMU_CHECK_PASS__:full-userland-journald-active" \
      "__NEMU_CHECK_PASS__:full-userland-systemd-cat" \
      "__NEMU_CHECK_PASS__:full-userland-journalctl-query" \
      "__NEMU_CHECK_PASS__:full-userland-cron-exec" \
      "__NEMU_CHECK_PASS__:full-userland-rsyslog-logger" \
      "__NEMU_CHECK_PASS__:full-userland-systemctl-enable-daemon-reload" \
      "__NEMU_CHECK_PASS__:full-userland-systemctl-enable" \
      "__NEMU_CHECK_PASS__:full-userland-systemctl-enable-wants-link" \
      "__NEMU_CHECK_PASS__:full-userland-systemctl-enable-start" \
      "__NEMU_CHECK_PASS__:full-userland-systemctl-disable" \
      "__NEMU_CHECK_PASS__:full-userland-resolv-hostless" \
      "__NEMU_CHECK_PASS__:full-userland-curl-http" \
      "__NEMU_CHECK_PASS__:full-userland-wget-http" \
      "__NEMU_CHECK_PASS__:full-userland-curl-head-http" \
      "__NEMU_CHECK_PASS__:full-userland-curl-404-http" \
      "__NEMU_CHECK_PASS__:full-userland-curl-large-http" \
      "__NEMU_CHECK_PASS__:full-userland-python-stdlib-file-sha256" \
      "__NEMU_CHECK_PASS__:full-userland-python-stdlib-import-loop" \
      "__NEMU_CHECK_PASS__:full-userland-lsb-release-retry-loop" \
      "__NEMU_CHECK_PASS__:full-userland-lsb-release-pycacheprefix-loop" \
      "__NEMU_CHECK_PASS__:full-userland-python-stdlib-stress-loop" \
      "__NEMU_CHECK_PASS__:full-userland-python-datetime-sqlite3" \
      "__NEMU_CHECK_PASS__:full-userland-command-not-found-update-db" \
      "__NEMU_CHECK_PASS__:full-userland-python-cnf-diag-recorded" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-keyring" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-inrelease-gpgv" \
      "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-signed-update" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-unsigned-reject" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-update" \
      "__NEMU_CHECK_PASS__:full-userland-apt-hostless-install" \
      "__NEMU_CHECK_PASS__:full-userland-runtime"; do
      if grep -aFq "$full_marker" "$gate_dir/console.log"; then
        printf 'PASS focused full userland marker %s\n' "$full_marker"
      else
        printf 'FAIL focused full userland marker %s\n' "$full_marker"
        return 1
      fi
    done
    if [[ ${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_DIAG:-0} == 1 ]]; then
      local apt_diag_marker
      for apt_diag_marker in \
        "__NEMU_CHECK_PASS__:full-userland-apt-direct-empty-status-simulate" \
        "__NEMU_CHECK_PASS__:full-userland-apt-direct-empty-status-download"; do
        if grep -aFq "$apt_diag_marker" "$gate_dir/console.log"; then
          printf 'PASS focused apt install diagnostic marker %s\n' "$apt_diag_marker"
        else
          printf 'FAIL focused apt install diagnostic marker %s\n' "$apt_diag_marker"
          return 1
        fi
      done
      if [[ ${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL:-0} == 1 ]]; then
        apt_diag_marker="__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-install"
      else
        apt_diag_marker="__NEMU_CHECK_PASS__:full-userland-apt-direct-actual-install-skip"
      fi
      if grep -aFq "$apt_diag_marker" "$gate_dir/console.log"; then
        printf 'PASS focused apt install diagnostic marker %s\n' "$apt_diag_marker"
      else
        printf 'FAIL focused apt install diagnostic marker %s\n' "$apt_diag_marker"
        return 1
      fi
      local apt_diag_detail
      for apt_diag_detail in \
        "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__:49f963a8d5e812279f07b29e9e6df366ccabd08c4c3402f6a89724f20811cbe7" \
        "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__:045eea5e02492c3ea2b05729b8feef54f51044d24f5b752012335b4d82de2d67"; do
        if grep -aFq "$apt_diag_detail" "$gate_dir/console.log"; then
          printf 'PASS focused apt install diagnostic detail %s\n' "$apt_diag_detail"
        else
          printf 'FAIL focused apt install diagnostic detail %s\n' "$apt_diag_detail"
          return 1
        fi
      done
      if [[ ${AGENT_E2E_NEMU_UBUNTU_APT_INSTALL_ACTUAL:-0} == 1 ]]; then
        for apt_diag_detail in \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__:nemu-hostless-hello=1.0 nemu-hostless-meta=1.0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__:empty-status-real-dpkg" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_MESSAGE__:hello from NEMU hostless meta" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PREINST__:preinst from NEMU hostless meta" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST__:postinst from NEMU hostless meta" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS__:install ok installed 1.0 riscv64" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-dpkg-ownership" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__:0" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-upgrade" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TARGET__:nemu-hostless-hello=1.1 nemu-hostless-meta=1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_APT_STATE__:installed-v1-target-status-real-dpkg" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE__:hello from NEMU hostless apt v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS__:install ok installed 1.1 riscv64" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_MESSAGE__:hello from NEMU hostless meta v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_PREINST__:preinst from NEMU hostless meta v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_POSTINST__:postinst from NEMU hostless meta v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_DPKG_STATUS__:install ok installed 1.1 riscv64" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-upgrade-ownership" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_HELLO_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_HELLO_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_LIST_META_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_SEARCH_META_RC__:0" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-remove" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_TARGET__:nemu-hostless-meta" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_APT_STATE__:installed-v1.1-target-status-real-dpkg" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PRERM__:prerm from NEMU hostless meta v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTRM__:postrm from NEMU hostless meta v1.1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_AFTER_REMOVE__:deinstall ok config-files 1.1 riscv64" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__:install ok installed 1.1 riscv64" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-purge" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_TARGET__:nemu-hostless-meta" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_APT_STATE__:config-files-v1.1-target-status-real-dpkg" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_RC__:0" \
          "__NEMU_CHECK_PASS__:full-userland-apt-direct-full-status-purge-ownership" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_SEARCH_AFTER_PURGE_RC__:1" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__:0" \
          "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__:install ok installed 1.1 riscv64"; do
          if grep -aFq "$apt_diag_detail" "$gate_dir/console.log"; then
            printf 'PASS focused apt install actual detail %s\n' "$apt_diag_detail"
          else
            printf 'FAIL focused apt install actual detail %s\n' "$apt_diag_detail"
            return 1
          fi
        done
        if grep -aFq "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_RC__:0" "$gate_dir/console.log" ||
           grep -aFq "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_EFFECT_OK_AFTER_TIMEOUT__:124" "$gate_dir/console.log"; then
          printf 'PASS focused apt remove rc/effect diagnostic\n'
        else
          printf 'FAIL focused apt remove rc/effect diagnostic\n'
          return 1
        fi
      fi
    fi
  fi
  if [[ "$make_target" == *soak ]]; then
    for soak_marker in \
      "__NEMU_CHECK_PASS__:soak-uptime" \
      "__NEMU_CHECK_PASS__:interrupts-stat-monotonic"; do
      if grep -aFq "$soak_marker" "$gate_dir/console.log"; then
        printf 'PASS focused soak marker %s\n' "$soak_marker"
      else
        printf 'FAIL focused soak marker %s\n' "$soak_marker"
        return 1
      fi
    done
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

e2e_nemu_ubuntu_focused_gate() {
  e2e_nemu_ubuntu_focused_gate_impl \
    AGENT_E2E_NEMU_UBUNTU_GATE \
    nemu-ubuntu-gate \
    check-nemu-systemd-guest \
    nemu-ubuntu-focused \
    AGENT_E2E_NEMU_UBUNTU_TIMEOUT
}

e2e_nemu_ubuntu_full_focused_gate() {
  local AGENT_E2E_NEMU_UBUNTU_FULL_TIMEOUT="${AGENT_E2E_NEMU_UBUNTU_FULL_TIMEOUT:-4200}"
  e2e_nemu_ubuntu_focused_gate_impl \
    AGENT_E2E_NEMU_UBUNTU_FULL_GATE \
    nemu-ubuntu-full-gate \
    check-nemu-systemd-guest-full \
    nemu-ubuntu-full-focused \
    AGENT_E2E_NEMU_UBUNTU_FULL_TIMEOUT
}

e2e_nemu_ubuntu_full_soak_gate() {
  local AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_TIMEOUT="${AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_TIMEOUT:-5400}"
  e2e_nemu_ubuntu_focused_gate_impl \
    AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE \
    nemu-ubuntu-full-soak \
    check-nemu-systemd-guest-full-soak \
    nemu-ubuntu-full-soak \
    AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_TIMEOUT
}
