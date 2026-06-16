#!/usr/bin/env bash
set -o pipefail
cd /home/lyg/PA/ysyx-workbench
run_dir=.github/task-runs/2026-06-15-npc-systemd-guest-machine-id-autocheck
log_dir="$run_dir/evidence/npc-systemd-guest"
mkdir -p "$log_dir"
exec > "$run_dir/run.log" 2>&1
date -Is
LOG_DIR="$PWD/$log_dir" \
CONSOLE_LOG="$PWD/$log_dir/console.log" \
NPC_LOG="$PWD/$log_dir/npc.log" \
NPC_SYSTEMD_PROMPT="root@ysyx-ubuntu2204:~#" \
NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck \
NPC_SYSTEMD_CHECK_MAX_CYCLES=1200000000 \
NPC_SYSTEMD_HOST_TIMEOUT=7200 \
NPC_SYSTEMD_PROGRESS=50000000 \
make -C Linux ARCH=riscv64-npc check-npc-systemd-guest
rc=$?
echo "$rc" > "$run_dir/run.rc"
echo "run.rc=$rc"
date -Is
exit "$rc"