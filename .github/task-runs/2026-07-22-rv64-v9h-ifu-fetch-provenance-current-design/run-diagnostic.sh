#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$root"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
result_dir="$task_dir/evidence/diagnostic-focused"
temp_dir="$(mktemp -d /tmp/rv64-ifu-fetch-v9h.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-ifu-fetch-v9h.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside expected local RTL temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$result_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS="tb_ooo_fetch_packet_decode tb_ooo_fetch_page_end_fault" \
  "RESULT_DIR=$result_dir" \
  "BUILD_DIR=$temp_dir/build" \
  run

rg '^\[G2-|^\[PASS\]|^\[RESULT\]' "$result_dir/logs/"*.log
