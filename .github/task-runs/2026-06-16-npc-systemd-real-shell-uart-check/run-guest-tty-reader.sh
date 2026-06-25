#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
reader_mode=${NPC_TTY_READER_MODE:-line}
reader_artifact=tty-reader
if [ "$reader_mode" != "line" ]; then
  reader_artifact="tty-reader-$reader_mode"
fi
log_name=${NPC_TTY_READER_LOG_NAME:-npc-systemd-$reader_artifact-loop}
rc_name=${NPC_TTY_READER_RC_NAME:-$reader_artifact-loop.rc}
log_dir="$run_dir/evidence/$log_name"
cmd_file="$PWD/$log_dir/npc-tty-reader.cmd"
diag_image=${NPC_TTY_READER_IMAGE:-Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-$reader_artifact.ext4}
diag_cpio=${NPC_TTY_READER_CPIO:-Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-$reader_artifact-rootfs.cpio}
diag_rootfs=${NPC_TTY_READER_ROOTFS_DIR:-Linux/env/platforms/npc/images/ubuntu2204/rootfs-$reader_artifact}
skip_build=${NPC_TTY_READER_SKIP_BUILD:-0}
skip_image_check=${NPC_TTY_READER_SKIP_IMAGE_CHECK:-0}
max_cycles=${NPC_TTY_READER_MAX_CYCLES:-900000000}
host_timeout=${NPC_TTY_READER_HOST_TIMEOUT:-4200}
progress_interval=${NPC_TTY_READER_PROGRESS:-50000000}
uart_cycle_gap=${NPC_TTY_READER_UART_CYCLE_GAP:-100000}
done_marker=${NPC_TTY_READER_DONE_MARKER:-__NPC_TTY_READER_DONE__ rc=0}
mkdir -p "$log_dir" "$(dirname "$diag_image")" "$(dirname "$diag_cpio")" "$diag_rootfs"

printf '%s\n' '__NPC_TTY_READER_PING__' >"$cmd_file"

{
  set -e
  echo "start: $(date -Is)"
  echo "cmd_file: $cmd_file"
  echo "reader_mode: $reader_mode"
  echo "diag_image: $PWD/$diag_image"
  echo "diag_rootfs: $PWD/$diag_rootfs"
  echo "skip_build: $skip_build"
  echo "skip_image_check: $skip_image_check"
  echo "max_cycles: $max_cycles"
  echo "host_timeout: $host_timeout"
  echo "progress_interval: $progress_interval"
  echo "uart_cycle_gap: $uart_cycle_gap"
  echo "done_marker: $done_marker"
  echo "uart_access_trace: ${NPC_UART_ACCESS_TRACE:-0}"
  echo "irq_trace: ${NPC_IRQ_TRACE:-0}"

  if [ "$skip_build" = "1" ]; then
    test -f "$diag_image"
    echo "reuse existing diagnostic image"
  else
    UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
    UBUNTU_ROOTFS_IMAGE="$PWD/$diag_image" \
    UBUNTU_ROOTFS_CPIO_IMAGE="$PWD/$diag_cpio" \
    UBUNTU_ROOTFS_WORK="$PWD/Linux/env/platforms/npc/images/ubuntu2204" \
    UBUNTU_ROOTFS_DIR="$PWD/$diag_rootfs" \
    UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
    UBUNTU_ROOTFS_NPC_TTY_READER=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER=1 \
    UBUNTU_ROOTFS_NPC_TTY_READER_MODE="$reader_mode" \
    UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=1 \
    UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 \
    UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
      bash Linux/scripts/build-ubuntu-rootfs.sh
  fi

  if [ "$skip_image_check" = "1" ]; then
    echo "skip diagnostic image static check"
  else
    UBUNTU_ROOTFS_IMAGE="$PWD/$diag_image" \
    UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER=1 \
    UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
      bash Linux/scripts/check-ubuntu-rootfs.sh
  fi

  set +e
  UBUNTU_ROOTFS_IMAGE="$PWD/$diag_image" \
  UBUNTU_ROOTFS_SYSTEMD_IMAGE="$PWD/$diag_image" \
  UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE="$PWD/$diag_cpio" \
  UBUNTU_ROOTFS_SYSTEMD_DIR="$PWD/$diag_rootfs" \
  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
  UBUNTU_ROOTFS_NPC_TTY_READER=1 \
  UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER=1 \
  UBUNTU_ROOTFS_NPC_TTY_READER_MODE="$reader_mode" \
  UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=1 \
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_PROMPT="__NPC_TTY_READER_READY__" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=uart \
  NPC_SYSTEMD_GUEST_CMDS="$cmd_file" \
  NPC_SYSTEMD_GUEST_CMDS_PRESERVE=1 \
  NPC_SYSTEMD_DONE_MARKER="$done_marker" \
  NPC_SYSTEMD_UART_WAIT="__NPC_TTY_READER_READY__" \
  NPC_SYSTEMD_UART_CYCLE_GAP="$uart_cycle_gap" \
  NPC_SYSTEMD_CHECK_MAX_CYCLES="$max_cycles" \
  NPC_SYSTEMD_HOST_TIMEOUT="$host_timeout" \
  NPC_SYSTEMD_PROGRESS="$progress_interval" \
    bash Linux/scripts/check-npc-systemd-guest.sh
  rc=$?
  set -e

  echo "$rc" > "$run_dir/$rc_name"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
