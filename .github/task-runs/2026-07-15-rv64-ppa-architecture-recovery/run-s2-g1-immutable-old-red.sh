#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
bundle="$run_dir/dse-archive/source-bundles/a80d45cb559652773c43fe6a765eff2bba7607e968b9565703b26c4a8a87adf1.tar"
expected_sha="a80d45cb559652773c43fe6a765eff2bba7607e968b9565703b26c4a8a87adf1"
evidence_dir="$run_dir/evidence/r4-s1-id-old-red"
work_dir="$(mktemp -d /tmp/s2-g1-id-old-red.XXXXXX)"
src_root="$work_dir/source"
build_dir="$work_dir/build"
summary="$evidence_dir/summary.txt"

mkdir -p "$src_root" "$build_dir" "$evidence_dir"
actual_sha="$(sha256sum "$bundle" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
  printf 'bundle_sha_mismatch expected=%s actual=%s\n' "$expected_sha" "$actual_sha" > "$summary"
  exit 1
fi
tar xf "$bundle" -C "$src_root"

printf 'bundle_sha256=%s\nwork_dir=%s\n' "$actual_sha" "$work_dir" > "$summary"

run_expected_red() {
  local name="$1"
  local top="$2"
  local rtl="$3"
  local marker="$4"
  local tb="$run_dir/tests/$name.sv"
  local log="$evidence_dir/$name.log"
  local rc=0

  set +e
  iverilog -g2012 \
    -I "$src_root/npc/rv64/vsrc/include" \
    -s "$top" \
    -o "$build_dir/$name.vvp" \
    "$tb" "$src_root/$rtl" > "$log" 2>&1
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    printf '%s=UNEXPECTED_GREEN\n' "$name" >> "$summary"
    return 1
  fi
  if ! grep -Eq "$marker" "$log"; then
    printf '%s=RED_WRONG_REASON rc=%s\n' "$name" "$rc" >> "$summary"
    return 1
  fi
  printf '%s=EXPECTED_RED rc=%s marker=%s\n' "$name" "$rc" "$marker" >> "$summary"
}

run_expected_red \
  tb_s2_g1_owner_tracker_contract \
  tb_s2_g1_owner_tracker_contract \
  npc/rv64/vsrc/memory/OooMemOwnerTracker.v \
  'OooMemOwnerTracker'
run_expected_red \
  tb_s2_g1_mmu_epoch_owner_contract \
  tb_s2_g1_mmu_epoch_owner_contract \
  npc/rv64/vsrc/memory/OooMmuEpochOwner.v \
  'OooMmuEpochOwner'
run_expected_red \
  tb_s2_g1_miq_owner_ports \
  tb_s2_g1_miq_owner_ports \
  npc/rv64/vsrc/memory/OooMemInflightQueue.v \
  'push_owner_token_i|pop_owner_token_i|head_owner_token_o'
run_expected_red \
  tb_s2_g1_sq_owner_ports \
  tb_s2_g1_sq_owner_ports \
  npc/rv64/vsrc/memory/OooStoreQueue.v \
  'owner_bind_token_i|terminal_owner_token_i|req_owner_token_o'
bridge_log="$evidence_dir/tb_s2_g1_bridge_owner_ports.log"
bridge_rc=0
set +e
iverilog -g2012 \
  -I "$src_root/npc/rv64/vsrc/include" \
  -s tb_s2_g1_bridge_owner_ports \
  -o "$build_dir/tb_s2_g1_bridge_owner_ports.vvp" \
  "$run_dir/tests/tb_s2_g1_bridge_owner_ports.sv" \
  "$src_root/npc/rv64/vsrc/memory/OooMemAxiBridge.v" \
  "$src_root/npc/rv64/vsrc/memory/OooSv39Tlb.v" \
  "$src_root/npc/rv64/vsrc/memory/PmpChecker.v" \
  "$src_root/npc/rv64/vsrc/memory/OooTypedPmaChecker.v" \
  "$src_root/npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v" \
  "$src_root/npc/rv64/vsrc/cache/OooDataWordCache.v" \
  "$src_root/npc/rv64/vsrc/sram/Sram4096x113.v" \
  > "$bridge_log" 2>&1
bridge_rc=$?
set -e
if [[ $bridge_rc -eq 0 ]]; then
  printf 'tb_s2_g1_bridge_owner_ports=UNEXPECTED_GREEN\n' >> "$summary"
  exit 1
fi
if ! grep -Eq 'mem0_req_owner_token_i|mem0_rsp_owner_token_o|mem0_drop0_owner_token_o' "$bridge_log"; then
  printf 'tb_s2_g1_bridge_owner_ports=RED_WRONG_REASON rc=%s\n' "$bridge_rc" >> "$summary"
  exit 1
fi
printf 'tb_s2_g1_bridge_owner_ports=EXPECTED_RED rc=%s marker=owner_tuple_ports\n' \
  "$bridge_rc" >> "$summary"

printf 'result=EXPECTED_RED_5_OF_5\n' >> "$summary"
printf '%s\n' "$work_dir" > "$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 immutable-old RED evidence: %s\n' "$summary"
