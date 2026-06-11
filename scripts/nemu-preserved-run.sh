#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/nemu-preserved-run.sh <nemu-home> <build-jobs> -- <nemu-args...>

Build riscv64-linux NEMU, run it with the provided arguments, and restore the
user's NEMU configuration files afterwards.
USAGE
}

if [ "$#" -lt 4 ] || [ "${3:-}" != "--" ]; then
  usage
  exit 2
fi

nemu_home=$1
build_jobs=$2
shift 3

nemu_home=$(cd "$nemu_home" && pwd)
backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/nemu-config-preserve.XXXXXX")
paths=(
  ".config"
  ".config.old"
  "include/config"
  "include/generated"
)

snapshot_configs() {
  local rel
  mkdir -p "$backup_dir/state"
  for rel in "${paths[@]}"; do
    if [ -e "$nemu_home/$rel" ]; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      cp -a "$nemu_home/$rel" "$backup_dir/$rel"
      printf 'present\n' > "$backup_dir/state/${rel//\//__}"
    else
      printf 'absent\n' > "$backup_dir/state/${rel//\//__}"
    fi
  done
}

restore_configs() {
  local rel state parent
  for rel in "${paths[@]}"; do
    state=$(cat "$backup_dir/state/${rel//\//__}" 2>/dev/null || printf 'absent')
    if [ "$state" = "present" ]; then
      parent=$(dirname "$nemu_home/$rel")
      mkdir -p "$parent"
      rm -rf "$nemu_home/$rel"
      cp -a "$backup_dir/$rel" "$nemu_home/$rel"
    else
      rm -rf "$nemu_home/$rel"
    fi
  done
}

cleanup() {
  local status=$?
  set +e
  restore_configs
  rm -rf "$backup_dir"
  exit "$status"
}

snapshot_configs
trap cleanup EXIT INT TERM

NEMU_HOME="$nemu_home" make -C "$nemu_home" riscv64-linux_defconfig
NEMU_HOME="$nemu_home" make -C "$nemu_home" -j"$build_jobs"
NEMU_HOME="$nemu_home" "$nemu_home/build/riscv64-nemu-interpreter" "$@"
