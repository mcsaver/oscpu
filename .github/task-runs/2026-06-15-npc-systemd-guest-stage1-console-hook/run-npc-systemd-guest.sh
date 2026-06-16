#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
run_dir="$repo/.github/task-runs/2026-06-15-npc-systemd-guest-stage1-console-hook"
evidence_dir="$run_dir/evidence/npc-systemd-guest"
mkdir -p "$evidence_dir"

export NPC_SYSTEMD_CHECK_LOG_DIR="$evidence_dir"
export NPC_SYSTEMD_CHECK_MAX_CYCLES=1000000000
export NPC_SYSTEMD_HOST_TIMEOUT=7200
export NPC_SYSTEMD_PROGRESS=50000000
export NPC_SYSTEMD_UART_TRACE_LIMIT=128
export NPC_OOO_WINDOW=0

set +e
make -C "$repo/Linux" ARCH=riscv64-npc check-npc-systemd-guest 2>&1 | tee "$run_dir/run.log"
rc=${PIPESTATUS[0]}
set -e

printf '%s\n' "$rc" > "$run_dir/run.rc"
exit "$rc"
