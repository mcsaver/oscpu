#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s1-id-owner-tracker-green"
build_dir="$(mktemp -d /tmp/s2-g1-owner-tracker-green.XXXXXX)"
rtl="$repo_root/npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
mkdir -p "$evidence_dir"

run_one() {
  local name="$1"
  local log="$evidence_dir/$name.log"
  iverilog -g2012 -DOOO_ASSERT -s "$name" -o "$build_dir/$name.vvp" \
    "$run_dir/tests/$name.sv" "$rtl" > "$log" 2>&1
  vvp "$build_dir/$name.vvp" >> "$log" 2>&1
  grep -q '\[PASS\]' "$log"
}

run_one tb_s2_g1_owner_tracker_contract
run_one tb_s2_g1_owner_tracker_green

negative_markers=(
  'reserved owner kind'
  'free0 owner tuple did not match'
  'duplicate dual free'
  'tagged free overlapped STORE release mask'
  'release_mask named a non-live/non-STORE token'
  'free0 owner tuple did not match'
)
for case_id in 0 1 2 3 4 5; do
  neg_log="$evidence_dir/negative-case-$case_id.log"
  set +e
  iverilog -g2012 -DOOO_ASSERT \
    -P tb_s2_g1_owner_tracker_negative.CASE_ID="$case_id" \
    -s tb_s2_g1_owner_tracker_negative \
    -o "$build_dir/negative-case-$case_id.vvp" \
    "$run_dir/tests/tb_s2_g1_owner_tracker_negative.sv" "$rtl" \
    > "$neg_log" 2>&1 && \
    vvp "$build_dir/negative-case-$case_id.vvp" >> "$neg_log" 2>&1
  neg_rc=$?
  set -e
  if [[ $neg_rc -eq 0 ]]; then
    printf 'negative case %s unexpectedly passed\n' "$case_id" >&2
    exit 1
  fi
  grep -q "${negative_markers[$case_id]}" "$neg_log"
  if grep -q '\[S2-G1-OWNER-NEG\]\[FAIL\]' "$neg_log"; then
    printf 'negative case %s reached fallback failure after DUT marker\n' "$case_id" >&2
    exit 1
  fi
done
sha256sum \
  "$rtl" \
  "$run_dir/tests/tb_s2_g1_owner_tracker_contract.sv" \
  "$run_dir/tests/tb_s2_g1_owner_tracker_green.sv" \
  "$run_dir/tests/tb_s2_g1_owner_tracker_negative.sv" \
  "$run_dir/run-s2-g1-owner-tracker-focused.sh" \
  > "$evidence_dir/sources.sha256"
printf 'work_dir=%s\npositive=GREEN_2_OF_2\nnegative=EXPECTED_FATAL_6_OF_6\nsemantic_result=PASS\ntiming_qualification=UNQUALIFIED_linear_priority_encoder\nresult=PASS\n' \
  "$build_dir" > "$evidence_dir/summary.txt"
printf '%s\n' "$build_dir" > "$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 owner tracker focused GREEN: %s\n' "$evidence_dir"
