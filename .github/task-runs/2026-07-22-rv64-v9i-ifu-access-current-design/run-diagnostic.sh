#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design"
focused_dir="$task_dir/evidence/diagnostic-focused"
dpi_dir="$task_dir/evidence/diagnostic-axi-dpi"
temp_dir="$(mktemp -d /tmp/rv64-ifu-access-v9i.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-ifu-access-v9i.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside expected local RTL temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir" "$dpi_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS="tb_ooo_fetch_access_footprint tb_ooo_fetch_axi_access_attrs tb_ooo_ifu_lane1_fault_owner tb_axi_exec_firewall" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  run

AXI_DPI_SIZED_BUILD_DIR="$temp_dir/axi-dpi-sized" \
  make -B -C "$root/npc/rv64/testbench" axi-dpi-sized \
  >"$dpi_dir/run.log" 2>&1

rg 'ACCESS-G1|IFU-LANE1|AXI_DPI_SIZED_SUITE_PASS|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs" "$dpi_dir/run.log"
