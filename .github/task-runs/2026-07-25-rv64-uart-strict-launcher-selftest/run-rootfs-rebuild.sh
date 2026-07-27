#!/usr/bin/env bash
set -uo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
run_dir="$repo_root/.github/task-runs/2026-07-25-rv64-uart-strict-launcher-selftest"
status_file="$run_dir/rootfs-rebuild.status"
log_file="$run_dir/rootfs-rebuild.log"
hash_file="$run_dir/rootfs-rebuild.sha256"
rootfs_image="$repo_root/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4"

printf 'RUNNING\n' >"$status_file"
set +e
make -C "$repo_root/Linux" ARCH=riscv64-npc ubuntu-rootfs-systemd-image \
  >"$log_file" 2>&1
rc=$?
set -e

if [ -f "$rootfs_image" ]; then
  sha256sum "$rootfs_image" >"$hash_file"
fi

if [ "$rc" -eq 0 ]; then
  printf 'PASS rc=0\n' >"$status_file"
else
  printf 'FAIL rc=%s\n' "$rc" >"$status_file"
fi
exit "$rc"
