#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_name=${NPC_UART_PING_LOG_NAME:-npc-systemd-uart-ping-slow}
rc_name=${NPC_UART_PING_RC_NAME:-uart-ping-slow.rc}
log_dir="$run_dir/evidence/$log_name"
cmd_file="$PWD/$log_dir/npc-uart-ping.cmd"
mkdir -p "$log_dir"

cat >"$cmd_file" <<'GUEST_CMDS_EOF'
m=__NPC_UART_PING_BEGIN__
printf '%s\n' "$m"
m=__NPC_UART_PING_DONE__
printf '%s rc=0\n' "$m"
GUEST_CMDS_EOF

{
  echo "start: $(date -Is)"
  echo "cmd_file: $cmd_file"
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_PROMPT="__NPC_CONSOLE_SHELL_READY__" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=uart \
  NPC_SYSTEMD_GUEST_CMDS="$cmd_file" \
  NPC_SYSTEMD_GUEST_CMDS_PRESERVE=1 \
  NPC_SYSTEMD_DONE_MARKER="__NPC_UART_PING_DONE__ rc=0" \
  NPC_SYSTEMD_UART_WAIT="__NPC_CONSOLE_SHELL_READY__" \
  NPC_SYSTEMD_UART_CYCLE_GAP=100000 \
  NPC_SYSTEMD_CHECK_MAX_CYCLES=900000000 \
  NPC_SYSTEMD_HOST_TIMEOUT=4200 \
  NPC_SYSTEMD_PROGRESS=50000000 \
    make -C Linux ARCH=riscv64-npc check-npc-systemd-guest
  rc=$?
  echo "$rc" > "$run_dir/$rc_name"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
