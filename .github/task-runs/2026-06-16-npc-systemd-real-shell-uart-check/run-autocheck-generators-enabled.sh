#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_name=${NPC_GENERATORS_AUTOCHECK_LOG_NAME:-npc-systemd-autocheck-generators-enabled}
rc_name=${NPC_GENERATORS_AUTOCHECK_RC_NAME:-autocheck-generators-enabled.rc}
log_dir="$run_dir/evidence/$log_name"
rootfs_flavor=${NPC_GENERATORS_ROOTFS_FLAVOR:-systemd-minimal}
case "$rootfs_flavor" in
  systemd-minimal|minimal)
    rootfs_flavor=systemd-minimal
    default_rootfs_image=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-generators.ext4
    default_rootfs_cpio=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-generators-rootfs.cpio
    ;;
  interactive)
    default_rootfs_image=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-interactive-generators.ext4
    default_rootfs_cpio=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-interactive-generators-rootfs.cpio
    ;;
  full|standard)
    rootfs_flavor=full
    default_rootfs_image=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-generators.ext4
    default_rootfs_cpio=$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-generators-rootfs.cpio
    ;;
  *)
    echo "unsupported NPC_GENERATORS_ROOTFS_FLAVOR=$rootfs_flavor" >&2
    exit 1
    ;;
esac
rootfs_image=${NPC_GENERATORS_ROOTFS_IMAGE:-$default_rootfs_image}
rootfs_cpio=${NPC_GENERATORS_ROOTFS_CPIO:-$default_rootfs_cpio}
max_cycles=${NPC_GENERATORS_AUTOCHECK_MAX_CYCLES:-1200000000}
host_timeout=${NPC_GENERATORS_AUTOCHECK_HOST_TIMEOUT:-5400}
progress=${NPC_GENERATORS_AUTOCHECK_PROGRESS:-50000000}
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  echo "rootfs_flavor: $rootfs_flavor"
  echo "rootfs_image: $rootfs_image"
  echo "max_cycles: $max_cycles"
  echo "host_timeout: $host_timeout"
  UBUNTU_ROOTFS_FLAVOR="$rootfs_flavor" \
  UBUNTU_ROOTFS_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_SYSTEMD_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_INTERACTIVE_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_INTERACTIVE_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_FULL_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_FULL_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=0 \
  UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=enabled \
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck \
  NPC_SYSTEMD_CHECK_MAX_CYCLES="$max_cycles" \
  NPC_SYSTEMD_HOST_TIMEOUT="$host_timeout" \
  NPC_SYSTEMD_PROGRESS="$progress" \
    make -C Linux ARCH=riscv64-npc check-npc-systemd-guest
  rc=$?
  echo "$rc" > "$run_dir/$rc_name"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
