#!/usr/bin/env bash
set -euo pipefail

repo=/home/lyg/PA/ysyx-workbench
result_dir="$repo/.github/task-runs/2026-06-15-npc-ubuntu-current-direct/evidence/rebuild-systemd-rootfs"

mkdir -p "$result_dir"

set +e
set -o pipefail
make -C "$repo/Linux" ubuntu-rootfs-systemd-image 2>&1 | tee "$result_dir/rebuild.log"
rc=${PIPESTATUS[0]}
set +o pipefail
set -e

printf '%s\n' "$rc" > "$result_dir/rebuild.rc"
exit "$rc"
