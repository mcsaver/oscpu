#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-21-rv64-v9c-instret-retirement"
module_dir="$task_dir/evidence/module-aggregate"
mutation_summary="$task_dir/evidence/mutations/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/instret-retirement-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/instret-retirement.log"
temp_dir="$(mktemp -d /tmp/rv64-instret.XXXXXXXX)"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-instret.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside /tmp/rv64-instret.*: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$module_dir"
make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  run

python3 "$task_dir/run-instret-mutations.py" \
  --root "$root" \
  --output "$mutation_summary"

python3 "$root/npc/rv64/eval/ppa/tools/instret_retirement_evidence.py" \
  --root "$root" \
  --program-log "$module_dir/logs/tb_ooo_sv39_boot.log" \
  --commit-output-mux-log "$module_dir/logs/tb_ooo_commit_output_mux.log" \
  --alu-core-slice-log "$module_dir/logs/tb_ooo_alu_core_slice.log" \
  --csr-file-log "$module_dir/logs/tb_csr_file.log" \
  --module-summary "$module_dir/summary.txt" \
  --mutation-summary "$mutation_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

grep -E '^\[INSTRET-G1-PROGRAM\]|^\[PASS\]|^\[RESULT\]' \
  "$module_dir/logs/tb_ooo_sv39_boot.log"
cat "$raw_log"
