#!/usr/bin/env bash
set -euo pipefail

run_dir=.github/task-runs/2026-06-24-npc-login-profile-rerun
log_name=${NPC_LOGIN_AUTOCHECK_LOG_NAME:-npc-systemd-login-full-profile-rerun}
rc_name=${NPC_LOGIN_AUTOCHECK_RC_NAME:-login-full-profile-rerun.rc}
log_dir=$run_dir/evidence/$log_name
log_dir_abs=$PWD/$log_dir
rootfs_image=${NPC_LOGIN_ROOTFS_IMAGE:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-profile.ext4}
rootfs_cpio=${NPC_LOGIN_ROOTFS_CPIO:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-profile-rootfs.cpio}
rootfs_dir=${NPC_LOGIN_ROOTFS_DIR:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/rootfs-full-login-profile}
max_cycles=${NPC_LOGIN_AUTOCHECK_MAX_CYCLES:-2500000000}
host_timeout=${NPC_LOGIN_AUTOCHECK_HOST_TIMEOUT:-10800}
progress=${NPC_LOGIN_AUTOCHECK_PROGRESS:-50000000}

mkdir -p "$log_dir_abs"
{
  echo "start: $(date -Is)"
  echo "rootfs_flavor: full-login-profile"
  echo "rootfs_image: $rootfs_image"
  echo "max_cycles: $max_cycles"
  echo "host_timeout: $host_timeout"
  echo "login_trace: 0"
} | tee "$log_dir_abs/run.log"

set +e
timeout "${host_timeout}s" env   UBUNTU_ROOTFS_FLAVOR=full   UBUNTU_ROOTFS_IMAGE="$rootfs_image"   UBUNTU_ROOTFS_CPIO_IMAGE="$rootfs_cpio"   UBUNTU_ROOTFS_DIR="$rootfs_dir"   UBUNTU_ROOTFS_FULL_IMAGE="$rootfs_image"   UBUNTU_ROOTFS_FULL_CPIO_IMAGE="$rootfs_cpio"   UBUNTU_ROOTFS_FULL_DIR="$rootfs_dir"   UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=0   UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=0   UBUNTU_ROOTFS_NPC_LOGIN_MARKER=1   UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER=1   UBUNTU_ROOTFS_NPC_LOGIN_TRACE=0   UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_TRACE=0   UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE=1   UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE=1   UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=0   UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=enabled   NPC_SYSTEMD_CHECK_LOG_DIR="$log_dir_abs"   NPC_SYSTEMD_CHECK_MAX_CYCLES="$max_cycles"   NPC_SYSTEMD_CHECK_TIMEOUT="$host_timeout"   NPC_SYSTEMD_PROGRESS_INTERVAL="$progress"   NPC_SYSTEMD_DONE_MARKER="__NPC_LOGIN_CHECK_DONE__ rc=0"   NPC_SYSTEMD_AUTOCHECK_EXPECT="__NPC_LOGIN_CHECK_DONE__ rc=0"   make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs check-npc-systemd-guest 2>&1 | tee -a "$log_dir_abs/run.log"
rc=${PIPESTATUS[0]}
set -e
printf "%s\n" "$rc" > "$run_dir/$rc_name"
echo "run.rc=$rc" | tee -a "$log_dir_abs/run.log"
echo "end: $(date -Is)" | tee -a "$log_dir_abs/run.log"
exit "$rc"
