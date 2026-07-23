#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency"
focused_dir="$task_dir/evidence/focused"
variant_summary="$task_dir/evidence/rtl-variants/summary.json"
result_json="$root/npc/rv64/eval/ppa/evidence/irrevocable-owner-residency-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/irrevocable-owner-residency.log"
builder="$root/npc/rv64/eval/ppa/tools/irrevocable_owner_residency_evidence.py"
temp_dir="$(mktemp -d /tmp/rv64-owner-residency-v9n.XXXXXXXX)"
design_id="$(python3 "$builder" --root "$root" --print-design-id)"
rtl_sha="${design_id#sha256:}"
if [[ ! "$rtl_sha" =~ ^[0-9a-f]{64}$ ]]; then
  printf '%s\n' "invalid current RTL design-id: $design_id" >&2
  exit 2
fi

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-owner-residency-v9n.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside the V9N temporary path: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$focused_dir"

make -B -C "$root/npc/rv64/testbench" \
  "RESULT_DIR=$focused_dir" \
  "BUILD_DIR=$temp_dir/focused-build" \
  "RTL_EVIDENCE_SHA=$rtl_sha" \
  "$focused_dir/logs/tb_v9n_sq_owner_residency.log" \
  "$focused_dir/logs/tb_v9n_amo_owner_residency.log"

python3 "$task_dir/run-owner-residency-rtl-variants.py" \
  --root "$root" \
  --output "$variant_summary"

python3 "$builder" \
  --root "$root" \
  --store-log "$focused_dir/logs/tb_v9n_sq_owner_residency.log" \
  --amo-log "$focused_dir/logs/tb_v9n_amo_owner_residency.log" \
  --variant-summary "$variant_summary" \
  --output "$result_json" \
  --raw-log "$raw_log"

python3 -m unittest \
  "$root/npc/rv64/eval/ppa/tests/test_irrevocable_owner_residency_evidence.py"

grep -E '^\[V9N-(SQ|AMO)-NEXT-EDGE-OWNER\]|^\[RTL-DESIGN-ID\]|^\[PASS\]|^\[RESULT\]' \
  "$focused_dir/logs/tb_v9n_sq_owner_residency.log" \
  "$focused_dir/logs/tb_v9n_amo_owner_residency.log"
cat "$raw_log"
