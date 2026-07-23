#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design"
focused_dir="$task_dir/evidence/focused"
module_dir="$task_dir/evidence/module-aggregate"
variant_summary="$task_dir/evidence/rtl-variants/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/fence-ordering-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/fence-ordering.log"
temp_dir="$(mktemp -d /tmp/rv64-fence-v9m.XXXXXXXX)"
design_id="$(python3 \
  "$root/npc/rv64/eval/ppa/tools/fence_ordering_evidence.py" \
  --root "$root" --print-design-id)"
rtl_sha="${design_id#sha256:}"
if [[ ! "$rtl_sha" =~ ^[0-9a-f]{64}$ ]]; then
  printf '%s\n' "invalid current RTL design-id: $design_id" >&2
  exit 2
fi

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-fence-v9m.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside /tmp/rv64-fence-v9m.*: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir" "$module_dir"

# Fail fast on the real full-core ordering program and the independent
# drain-completion combinational oracle before running the full inventory.
make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  "RTL_EVIDENCE_SHA=$rtl_sha" \
  "$focused_dir/logs/tb_ooo_priv_system.log" \
  "$focused_dir/logs/tb_ooo_pending_drain_resolve_gate.log"

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$module_dir" \
  "BUILD_DIR=$temp_dir/module-build" \
  "RTL_EVIDENCE_SHA=$rtl_sha" \
  run

python3 "$task_dir/run-fence-rtl-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$root/npc/rv64/eval/ppa/tools/fence_ordering_evidence.py" \
  --root "$root" \
  --program-log "$focused_dir/logs/tb_ooo_priv_system.log" \
  --drain-gate-log "$focused_dir/logs/tb_ooo_pending_drain_resolve_gate.log" \
  --module-summary "$module_dir/summary.txt" \
  --variant-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

python3 -m unittest \
  "$root/npc/rv64/eval/ppa/tests/test_fence_ordering_evidence.py"

grep -E '^\[FENCE-G1-PROGRAM\]|^\[RTL-DESIGN-ID\]|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs/tb_ooo_priv_system.log"
cat "$raw_log"
