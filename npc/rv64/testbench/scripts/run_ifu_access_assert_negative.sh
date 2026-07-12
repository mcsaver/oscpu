#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../../.." && pwd)"
output_dir="${1:-$repo_root/npc/rv64/testbench/build/ifu-access-assert-negative}"
mkdir -p "$output_dir"

source "$repo_root/scripts/agent-env.sh"
iverilog_bin="${IVERILOG:-iverilog}"
vvp_bin="${VVP:-$(dirname "$(command -v "$iverilog_bin")")/vvp}"
image="$output_dir/tb_ooo_ifu_access_assert_negative.vvp"
tracked_sources=(
  "$repo_root/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
  "$repo_root/npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv"
)
sha256sum "${tracked_sources[@]}" >"$output_dir/source-hashes.before.txt"

"$iverilog_bin" -g2012 -Wall \
  -I"$repo_root/npc/rv64/vsrc" \
  -I"$repo_root/npc/rv64/vsrc/include" \
  -I"$repo_root/npc/rv64/testbench/common" \
  -DOOO_ASSERT \
  -s tb_ooo_fetch_axi_bridge \
  -s tb_ooo_ifu_access_assert_negative_driver \
  -o "$image" \
  "$repo_root/npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv" \
  "$repo_root/npc/rv64/testbench/tests/tb_ooo_ifu_access_assert_negative_driver.sv" \
  "$repo_root/npc/rv64/vsrc/memory/PmpChecker.v" \
  "$repo_root/npc/rv64/vsrc/cache/OooFetchPacketCache.v" \
  "$repo_root/npc/rv64/vsrc/sram/Sram4096x199.v" \
  "$repo_root/npc/rv64/vsrc/memory/OooSv39Tlb.v" \
  "$repo_root/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v" \
  >"$output_dir/compile.log" 2>&1

summary="$output_dir/summary.tsv"
printf 'case\texpected_marker\tmarker_count\terror_count\tdone_count\tstatus\n' >"$summary"

run_case() {
  local case_name="$1"
  local expected="$2"
  local log="$output_dir/${case_name}.log"
  "$vvp_bin" "$image" "+ACCESS_ASSERT=${case_name}" >"$log" 2>&1

  local marker_count error_count done_count status
  marker_count="$(grep -F -c "[$expected]" "$log" || true)"
  error_count="$(grep -c '^ERROR:' "$log" || true)"
  done_count="$(grep -F -c "ACCESS-ASSERT-NEGATIVE-DONE marker=${case_name}" "$log" || true)"
  status=PASS
  if [[ "$marker_count" != 1 || "$error_count" != 1 || "$done_count" != 1 ]]; then
    status=FAIL
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$case_name" "$expected" "$marker_count" "$error_count" "$done_count" "$status" \
    >>"$summary"
  [[ "$status" == PASS ]]
}

run_case HOLD IFU-FETCH-G2-HOLD
run_case SPLIT-RANGE IFU-ACCESS-SPLIT-RANGE
run_case SUCCESS-SPLIT IFU-ACCESS-SUCCESS-SPLIT
run_case FAULT-ABI IFU-ACCESS-FAULT-ABI

sha256sum "${tracked_sources[@]}" >"$output_dir/source-hashes.after.txt"
cmp -s "$output_dir/source-hashes.before.txt" "$output_dir/source-hashes.after.txt"
cat "$summary"
echo "IFU_ACCESS_ASSERT_NEGATIVE_PASS cases=4 production_sources_unchanged=1"
