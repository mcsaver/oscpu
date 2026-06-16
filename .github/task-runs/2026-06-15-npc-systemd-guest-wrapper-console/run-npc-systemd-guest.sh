#!/usr/bin/env bash
set -euo pipefail

repo=/home/lyg/PA/ysyx-workbench
run_dir="$repo/.github/task-runs/2026-06-15-npc-systemd-guest-wrapper-console"

mkdir -p "$run_dir/evidence/npc-systemd-guest"

export NPC_SYSTEMD_CHECK_LOG_DIR="$run_dir/evidence/npc-systemd-guest"
export NPC_SYSTEMD_CHECK_MAX_CYCLES="${NPC_SYSTEMD_CHECK_MAX_CYCLES:-1000000000}"
export NPC_SYSTEMD_HOST_TIMEOUT="${NPC_SYSTEMD_HOST_TIMEOUT:-7200}"
export NPC_SYSTEMD_PROGRESS="${NPC_SYSTEMD_PROGRESS:-50000000}"
export NPC_SYSTEMD_UART_TRACE="${NPC_SYSTEMD_UART_TRACE:-1}"
export NPC_SYSTEMD_UART_TRACE_LIMIT="${NPC_SYSTEMD_UART_TRACE_LIMIT:-128}"
export NPC_OOO_WINDOW=0

set +e
make -C "$repo/Linux" ARCH=riscv64-npc check-npc-systemd-guest 2>&1 | tee "$run_dir/run.log"
rc=${PIPESTATUS[0]}
set -e

printf '%s\n' "$rc" > "$run_dir/run.rc"
exit "$rc"
