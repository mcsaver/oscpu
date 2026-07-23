#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-21-rv64-v9e-xret-current-design"
module_dir="$task_dir/evidence/module-aggregate"
mutation_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/xret-current-mode-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/xret-current-mode.log"
temp_dir="$(mktemp -d /tmp/rv64-xret-v9e.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-xret-v9e.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside /tmp/rv64-xret-v9e.*: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$module_dir"
make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

python3 "$task_dir/run-xret-mutations.py" \
  --root "$root" \
  --normalize-log-dir "$module_dir/logs" \
  --transient-dir "$temp_dir"

python3 "$task_dir/run-xret-mutations.py" \
  --root "$root" \
  --output "$mutation_summary"

python3 "$root/npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py" \
  --root "$root" \
  --focused-log "$module_dir/logs/tb_ooo_fetch_head_classify_gate.log" \
  --program-log "$module_dir/logs/tb_ooo_priv_system.log" \
  --module-summary "$module_dir/summary.txt" \
  --mutation-summary "$mutation_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

grep -E '^\[XRET-G1-(FOCUSED|PROGRAM)|^\[PASS\]|^\[RESULT\]' \
  "$module_dir/logs/tb_ooo_fetch_head_classify_gate.log" \
  "$module_dir/logs/tb_ooo_priv_system.log"
cat "$raw_log"
