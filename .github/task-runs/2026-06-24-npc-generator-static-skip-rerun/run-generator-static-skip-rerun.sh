#!/usr/bin/env bash
set -euo pipefail

run_dir=.github/task-runs/2026-06-24-npc-generator-static-skip-rerun
log_name=${NPC_GENERATOR_STATIC_SKIP_LOG_NAME:-npc-systemd-login-generator-static-skip-rerun}
rc_name=${NPC_GENERATOR_STATIC_SKIP_RC_NAME:-generator-static-skip-rerun.rc}
log_dir=$run_dir/evidence/$log_name
log_dir_abs=$PWD/$log_dir
rootfs_image=${NPC_GENERATOR_STATIC_SKIP_ROOTFS_IMAGE:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-generator-static-skip.ext4}
rootfs_cpio=${NPC_GENERATOR_STATIC_SKIP_ROOTFS_CPIO:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-full-login-generator-static-skip-rootfs.cpio}
rootfs_dir=${NPC_GENERATOR_STATIC_SKIP_ROOTFS_DIR:-$PWD/Linux/env/platforms/npc/images/ubuntu2204/rootfs-full-login-generator-static-skip}
max_cycles=${NPC_GENERATOR_STATIC_SKIP_MAX_CYCLES:-400000000}
host_timeout=${NPC_GENERATOR_STATIC_SKIP_HOST_TIMEOUT:-4200}
progress=${NPC_GENERATOR_STATIC_SKIP_PROGRESS:-50000000}
skip_list=${NPC_GENERATOR_STATIC_SKIP_LIST:-all}

mkdir -p "$log_dir_abs"
{
  echo "start: $(date -Is)"
  echo "rootfs_flavor: full-login-generator-static-skip"
  echo "rootfs_image: $rootfs_image"
  echo "max_cycles: $max_cycles"
  echo "host_timeout: $host_timeout"
  echo "progress: $progress"
  echo "skip_list: $skip_list"
  echo "skip_mode: static"
} | tee "$log_dir_abs/run.log"

set +e
timeout "${host_timeout}s" env \
  UBUNTU_ROOTFS_FLAVOR=full \
  UBUNTU_ROOTFS_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_DIR="$rootfs_dir" \
  UBUNTU_ROOTFS_FULL_IMAGE="$rootfs_image" \
  UBUNTU_ROOTFS_FULL_CPIO_IMAGE="$rootfs_cpio" \
  UBUNTU_ROOTFS_FULL_DIR="$rootfs_dir" \
  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=0 \
  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=0 \
  UBUNTU_ROOTFS_NPC_LOGIN_MARKER=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER=1 \
  UBUNTU_ROOTFS_NPC_LOGIN_TRACE=0 \
  UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_TRACE=0 \
  UBUNTU_ROOTFS_NPC_GENERATOR_TRACE=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE=1 \
  UBUNTU_ROOTFS_NPC_GENERATOR_SKIP="$skip_list" \
  UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP="$skip_list" \
  UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE=static \
  UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE=static \
  UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE=1 \
  UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=0 \
  UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=enabled \
  NPC_SYSTEMD_CHECK_LOG_DIR="$log_dir_abs" \
  NPC_SYSTEMD_CHECK_MAX_CYCLES="$max_cycles" \
  NPC_SYSTEMD_HOST_TIMEOUT="$host_timeout" \
  NPC_SYSTEMD_PROGRESS="$progress" \
  NPC_SYSTEMD_REQUIRE_PROMPT=0 \
  NPC_SYSTEMD_DONE_MARKER="__NPC_LOGIN_CHECK_DONE__ rc=0" \
  NPC_SYSTEMD_AUTOCHECK_EXPECT="__NPC_LOGIN_CHECK_DONE__ rc=0" \
  make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs check-npc-systemd-guest 2>&1 | tee -a "$log_dir_abs/run.log"
rc=${PIPESTATUS[0]}
set -e
printf "%s\n" "$rc" > "$run_dir/$rc_name"
echo "run.rc=$rc" | tee -a "$log_dir_abs/run.log"
echo "end: $(date -Is)" | tee -a "$log_dir_abs/run.log"
exit "$rc"
