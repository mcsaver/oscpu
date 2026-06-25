#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_name=${NPC_LOGIN_AUTOCHECK_LOG_NAME:-npc-systemd-login-full-generators-enabled}
rc_name=${NPC_LOGIN_AUTOCHECK_RC_NAME:-login-full-generators-enabled.rc}
log_dir="$run_dir/evidence/$log_name"
rootfs_image=${NPC_LOGIN_ROOTFS_IMAGE:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-generators.ext4}
rootfs_cpio=${NPC_LOGIN_ROOTFS_CPIO:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-generators-rootfs.cpio}
rootfs_dir=${NPC_LOGIN_ROOTFS_DIR:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/rootfs-full-login-generators}
max_cycles=${NPC_LOGIN_AUTOCHECK_MAX_CYCLES:-2500000000}
host_timeout=${NPC_LOGIN_AUTOCHECK_HOST_TIMEOUT:-10800}
progress=${NPC_LOGIN_AUTOCHECK_PROGRESS:-50000000}
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  echo "rootfs_flavor: full-login"
  echo "rootfs_image: $rootfs_image"
  echo "max_cycles: $max_cycles"
  echo "host_timeout: $host_timeout"
  UBUNTU_ROOTFS_FLAVOR=full \
  UBUNTU_ROOTFS_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_FULL_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_FULL_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_FULL_DIR="$rootfs_dir" \
  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=0 \
  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=0 \
  UBUNTU_ROOTFS_NPC_LOGIN_MARKER=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER=1 \
  UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE=1 \
  UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=0 \
  UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=enabled \
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck \
  NPC_SYSTEMD_DONE_MARKER="__NPC_LOGIN_CHECK_DONE__ rc=0" \
  NPC_SYSTEMD_AUTOCHECK_EXPECT="__NPC_LOGIN_CHECK_DONE__ rc=0" \
  NPC_SYSTEMD_REQUIRE_PROMPT=0 \
  NPC_SYSTEMD_CHECK_MAX_CYCLES="$max_cycles" \
  NPC_SYSTEMD_HOST_TIMEOUT="$host_timeout" \
  NPC_SYSTEMD_PROGRESS="$progress" \
    make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs check-npc-systemd-guest
  rc=$?
  echo "$rc" > "$run_dir/$rc_name"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
