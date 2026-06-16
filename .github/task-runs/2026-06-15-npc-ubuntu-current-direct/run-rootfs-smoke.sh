#!/usr/bin/env bash
set -euo pipefail

repo=/home/lyg/PA/ysyx-workbench
result_dir="$repo/.github/task-runs/2026-06-15-npc-ubuntu-current-direct/evidence/npc-rv64-linux-rootfs-mount-smoke-script"

mkdir -p "$result_dir"

set +e
set -o pipefail
NPC_OOO_WINDOW=0 timeout 1200s \
  make -C "$repo/Linux" ARCH=riscv64-npc BOOT=ubuntu-rootfs \
    MAX_CYCLES=340000000 PROGRESS=0 LOG_DIR="$result_dir" run \
    2>&1 | tee "$result_dir/run.log"
rc=${PIPESTATUS[0]}
set +o pipefail
set -e

printf '%s\n' "$rc" > "$result_dir/run.rc"
exit "$rc"
