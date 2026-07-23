#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$root"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design"
focused_dir="$task_dir/evidence/focused"
module_dir="$task_dir/evidence/module-aggregate"
dpi_dir="$task_dir/evidence/sized-dpi"
variant_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/ifu-access-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/ifu-access.log"
temp_dir="$(mktemp -d /tmp/rv64-ifu-access-v9i.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-ifu-access-v9i.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside expected local RTL temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir" "$module_dir" "$dpi_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS="tb_ooo_fetch_access_footprint tb_ooo_fetch_axi_access_attrs tb_ooo_ifu_lane1_fault_owner tb_axi_exec_firewall" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  run

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

AXI_DPI_SIZED_BUILD_DIR="$temp_dir/axi-dpi-sized" \
  make -B -C "$root/npc/rv64/testbench" axi-dpi-sized \
  >"$dpi_dir/run.log" 2>&1

for log_dir in "$focused_dir/logs" "$module_dir/logs"
do
  python3 "$task_dir/run-ifu-access-variants.py" \
    --root "$root" \
    --normalize-log-dir "$log_dir" \
    --transient-dir "$temp_dir"
done

python3 "$task_dir/run-ifu-access-variants.py" \
  --root "$root" \
  --normalize-log "$dpi_dir/run.log" \
  --transient-dir "$temp_dir"

python3 "$task_dir/run-ifu-access-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$root/npc/rv64/eval/ppa/tools/ifu_access_evidence.py" \
  --root "$root" \
  --footprint-log "$focused_dir/logs/tb_ooo_fetch_access_footprint.log" \
  --attrs-log "$focused_dir/logs/tb_ooo_fetch_axi_access_attrs.log" \
  --firewall-log "$focused_dir/logs/tb_axi_exec_firewall.log" \
  --lane-log "$focused_dir/logs/tb_ooo_ifu_lane1_fault_owner.log" \
  --dpi-log "$dpi_dir/run.log" \
  --module-summary "$module_dir/summary.txt" \
  --variant-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

python3 -m unittest npc.rv64.eval.ppa.tests.test_ifu_access_evidence -v

rg '^\[ACCESS-G1-|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs/tb_ooo_fetch_access_footprint.log" \
  "$focused_dir/logs/tb_ooo_fetch_axi_access_attrs.log" \
  "$focused_dir/logs/tb_ooo_ifu_lane1_fault_owner.log" \
  "$focused_dir/logs/tb_axi_exec_firewall.log"
rg 'AXI_DPI_SIZED_PASS|SIZED_DPI_GUARD_PASS|AXI_DPI_SIZED_SUITE_PASS' \
  "$dpi_dir/run.log"
sed -n '1,120p' "$raw_log"
