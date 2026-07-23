#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$root"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
focused_dir="$task_dir/evidence/focused"
module_dir="$task_dir/evidence/module-aggregate"
variant_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/ifu-fetch-provenance-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/ifu-fetch-provenance.log"
temp_dir="$(mktemp -d /tmp/rv64-ifu-fetch-v9h.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-ifu-fetch-v9h.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside expected local RTL temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir" "$module_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS="tb_ooo_fetch_packet_decode tb_ooo_fetch_page_end_fault" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  run

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

for log_dir in "$focused_dir/logs" "$module_dir/logs"
do
  python3 "$task_dir/run-ifu-fetch-variants.py" \
    --root "$root" \
    --normalize-log-dir "$log_dir" \
    --transient-dir "$temp_dir"
done

python3 "$task_dir/run-ifu-fetch-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$root/npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py" \
  --root "$root" \
  --decode-log "$focused_dir/logs/tb_ooo_fetch_packet_decode.log" \
  --page-log "$focused_dir/logs/tb_ooo_fetch_page_end_fault.log" \
  --module-summary "$module_dir/summary.txt" \
  --variant-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_ifu_fetch_provenance_evidence -v

rg '^\[G2-|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs/tb_ooo_fetch_packet_decode.log" \
  "$focused_dir/logs/tb_ooo_fetch_page_end_fault.log"
sed -n '1,120p' "$raw_log"
