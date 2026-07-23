#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle"
mem_dir="$task_dir/evidence/focused/mem-issue"
miq_dir="$task_dir/evidence/focused/miq-flush"
module_dir="$task_dir/evidence/module-aggregate"
variant_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/memory-issue-lifecycle-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/memory-issue-lifecycle.log"
temp_dir="$(mktemp -d /tmp/rv64-memory-lifecycle-v9f.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-memory-lifecycle-v9f.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' \
      "refusing cleanup outside /tmp/rv64-memory-lifecycle-v9f.*: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$mem_dir" "$miq_dir" "$module_dir"

make -B -C "$root/npc/rv64/testbench" \
  TESTS=tb_ooo_int_backend \
  "RESULT_DIR=$mem_dir" \
  "BUILD_DIR=$temp_dir/mem-build" \
  TB_IVFLAGS_tb_ooo_int_backend=-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED \
  run

make -B -C "$root/npc/rv64/testbench" \
  TESTS=tb_ooo_mem_inflight_queue \
  "RESULT_DIR=$miq_dir" \
  "BUILD_DIR=$temp_dir/miq-build" \
  run

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

for log_dir in \
  "$mem_dir/logs" \
  "$miq_dir/logs" \
  "$module_dir/logs"
do
  python3 "$task_dir/run-memory-lifecycle-variants.py" \
    --root "$root" \
    --normalize-log-dir "$log_dir" \
    --transient-dir "$temp_dir"
done

python3 "$task_dir/run-memory-lifecycle-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$root/npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py" \
  --root "$root" \
  --mem-log "$mem_dir/logs/tb_ooo_int_backend.log" \
  --miq-log "$miq_dir/logs/tb_ooo_mem_inflight_queue.log" \
  --module-summary "$module_dir/summary.txt" \
  --mutation-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

rg '^\[MEM-ISSUE-G1-|^\[MIQ-FLUSH-G1-|^\[PASS\]|^\[RESULT\]' \
  "$mem_dir/logs/tb_ooo_int_backend.log" \
  "$miq_dir/logs/tb_ooo_mem_inflight_queue.log"
sed -n '1,120p' "$raw_log"
