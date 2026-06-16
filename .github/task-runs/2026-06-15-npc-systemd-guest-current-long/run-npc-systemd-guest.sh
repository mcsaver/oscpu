#!/usr/bin/env bash
set -euo pipefail

repo=/home/lyg/PA/ysyx-workbench
result_dir="$repo/.github/task-runs/2026-06-15-npc-systemd-guest-current-long/evidence/npc-systemd-guest"

mkdir -p "$result_dir"

set +e
set -o pipefail
NPC_SYSTEMD_CHECK_LOG_DIR="$result_dir" \
NPC_SYSTEMD_CHECK_MAX_CYCLES=3000000000 \
NPC_SYSTEMD_HOST_TIMEOUT=10800 \
NPC_SYSTEMD_PROGRESS=50000000 \
NPC_USER_PROGRESS_INTERVAL=50000000 \
NPC_USER_PROGRESS_LIMIT=256 \
NPC_USER_ECALL_TRACE=1 \
NPC_USER_ECALL_MIN_COMMIT=900000000 \
NPC_USER_ECALL_TRACE_LIMIT=8192 \
NPC_USER_ECALL_PATH_TRACE=1 \
NPC_OOO_WINDOW=0 \
  make -C "$repo/Linux" check-npc-systemd-guest 2>&1 | tee "$result_dir/run.log"
rc=${PIPESTATUS[0]}
set +o pipefail
set -e

printf '%s\n' "$rc" > "$result_dir/run.rc"
exit "$rc"
