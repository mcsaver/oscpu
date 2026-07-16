#!/usr/bin/env bash
set -euo pipefail

root="/home/lyg/PA/ysyx-workbench"
run_dir="$root/.github/task-runs/2026-07-14-rv64-t4m-posttranslate-device-owner"
src="$root/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
mutant_dir="$run_dir/evidence/red-mutant"
mutant="$mutant_dir/OooMemAxiBridge-old-leaf.v"
result_dir="$run_dir/evidence/red"
build_dir="$run_dir/evidence/build-red"
log="$result_dir/logs/tb_ooo_mem_axi_bridge.log"

mkdir -p "$mutant_dir" "$result_dir/logs" "$build_dir"

# Recreate exactly the old PTW-leaf behavior in a generated artifact.  Direct
# and A/D paths remain current so the focused counterexample can recover and
# finish after proving that the old leaf transition exposes a device AR.
sed \
  's/state_q <= walk_leaf_dcacheable_w ? S_LOOKUP : S_DEVICE_WAIT;/state_q <= S_LOOKUP; \/\* T4M old-logic mutation \*\//' \
  "$src" > "$mutant"

if [[ "$(grep -c 'T4M old-logic mutation' "$mutant")" != "1" ]]; then
  echo "[T4M-RED] mutation anchor count is not one" >&2
  exit 2
fi

set +e
make -B -C "$root/npc/rv64/testbench" \
  BUILD_DIR="$build_dir" \
  RESULT_DIR="$result_dir" \
  RTL_OOO_MEM_AXI_BRIDGE="$mutant" \
  "$log"
make_rc=$?
set -e

if [[ "$make_rc" == "0" ]]; then
  echo "[T4M-RED] old-logic mutation unexpectedly passed" >&2
  exit 3
fi

grep -F '[CHECK-FAIL] T4M translated device waits without AR' "$log"
grep -F '[T4M-OLD-LOGIC-LEAK] wrong-path AR addr=000000000c000004' "$log"
grep -F '[RESULT] FAIL' "$log"
echo "[T4M-RED] expected failure observed: translated PLIC AR escaped before owner release"

