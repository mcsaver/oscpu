#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$root"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design"
focused_dir="$task_dir/evidence/focused"
module_dir="$task_dir/evidence/module-aggregate"
variant_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log"
temp_dir="$(mktemp -d /tmp/rv64-ifu-axi-v9g.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-ifu-axi-v9g.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside expected local RTL temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir" "$module_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS="tb_ooo_fetch_axi_bridge tb_ooo_fetch_axi_bridge_xbar tb_axi_xbar" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  run

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

for log_dir in "$focused_dir/logs" "$module_dir/logs"
do
  python3 "$task_dir/run-ifu-axi-variants.py" \
    --root "$root" \
    --normalize-log-dir "$log_dir" \
    --transient-dir "$temp_dir"
done

python3 "$task_dir/run-ifu-axi-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$root/npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py" \
  --root "$root" \
  --bridge-log "$focused_dir/logs/tb_ooo_fetch_axi_bridge.log" \
  --xbar-log "$focused_dir/logs/tb_ooo_fetch_axi_bridge_xbar.log" \
  --generic-xbar-log "$focused_dir/logs/tb_axi_xbar.log" \
  --module-summary "$module_dir/summary.txt" \
  --variant-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_ifu_axi_flush_drain_evidence -v

rg '^\[IFU-AXI-G1-|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs/tb_ooo_fetch_axi_bridge.log" \
  "$focused_dir/logs/tb_ooo_fetch_axi_bridge_xbar.log" \
  "$focused_dir/logs/tb_axi_xbar.log"
sed -n '1,120p' "$raw_log"
