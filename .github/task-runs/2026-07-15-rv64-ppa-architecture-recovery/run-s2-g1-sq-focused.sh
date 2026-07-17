#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s1-id-sq-green"
work_dir="$(mktemp -d /tmp/s2-g1-sq-green.XXXXXX)"
rtl="$repo_root/npc/rv64/vsrc/memory/OooStoreQueue.v"
include_dir="$repo_root/npc/rv64/vsrc/include"
tb_dir="$repo_root/npc/rv64/testbench"
mkdir -p "$evidence_dir"

iverilog -g2012 -DOOO_ASSERT \
  -I "$repo_root/npc/rv64/vsrc" -I "$include_dir" -I "$tb_dir/common" \
  -s tb_ooo_store_queue -o "$work_dir/tb_ooo_store_queue.vvp" \
  "$tb_dir/tests/tb_ooo_store_queue.sv" "$rtl" \
  > "$evidence_dir/tb_ooo_store_queue.log" 2>&1
vvp "$work_dir/tb_ooo_store_queue.vvp" >> "$evidence_dir/tb_ooo_store_queue.log" 2>&1
grep -q '\[PASS\] tb_ooo_store_queue' "$evidence_dir/tb_ooo_store_queue.log"
if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:|warning:' "$evidence_dir/tb_ooo_store_queue.log"; then
  printf 'main SQ focused log contains a failure/warning marker\n' >&2
  exit 1
fi
grep -q '\[S2-G1-SQ-GLOBAL-SURVIVE-BOK\].*PASS' \
  "$evidence_dir/tb_ooo_store_queue.log"
grep -q '\[S2-G1-SQ-GLOBAL-SURVIVE-BERR\].*PASS' \
  "$evidence_dir/tb_ooo_store_queue.log"

iverilog -g2012 -I "$include_dir" \
  -s tb_s2_g1_sq_owner_ports -o "$work_dir/tb_s2_g1_sq_owner_ports.vvp" \
  "$run_dir/tests/tb_s2_g1_sq_owner_ports.sv" "$rtl" \
  > "$evidence_dir/tb_s2_g1_sq_owner_ports.log" 2>&1
vvp "$work_dir/tb_s2_g1_sq_owner_ports.vvp" \
  >> "$evidence_dir/tb_s2_g1_sq_owner_ports.log" 2>&1
grep -q '\[S2-G1-SQ\]\[PASS\]' "$evidence_dir/tb_s2_g1_sq_owner_ports.log"

for case_id in 1 2 3 4 5 6 7 8; do
  semantic_log="$evidence_dir/fail-closed-$case_id.log"
  iverilog -g2012 -I "$include_dir" \
    -P tb_s2_g1_sq_owner_negative.CASE_ID="$case_id" \
    -s tb_s2_g1_sq_owner_negative \
    -o "$work_dir/fail-closed-$case_id.vvp" \
    "$run_dir/tests/tb_s2_g1_sq_owner_negative.sv" "$rtl" \
    > "$semantic_log" 2>&1
  vvp "$work_dir/fail-closed-$case_id.vvp" >> "$semantic_log" 2>&1
  if [[ $case_id -eq 4 || $case_id -eq 8 ]]; then
    grep -q "\[S2-G1-SQ-TVAL\]\[PASS\] captured provenance accepted case=$case_id" "$semantic_log"
  else
    grep -q "\[S2-G1-SQ-NEG\]\[PASS\] identity fail-closed case=$case_id" "$semantic_log"
  fi
  if grep -Eq '\[FAIL\]|ERROR:|FATAL:|warning:' "$semantic_log"; then
    printf 'SQ fail-closed case %s contains a failure/warning marker\n' "$case_id" >&2
    exit 1
  fi
done

negative_markers=(
  unused
  S2-G1-SQ-FILL0-OWNER
  S2-G1-SQ-FILL0-OWNER
  S2-G1-SQ-FILL0-OWNER
  S2-G1-SQ-FILL0-TVAL-ECHO
  T4N-SQ-TERMINAL0-HIT
  T4N-SQ-TERMINAL0-HIT
  T4N-SQ-TERMINAL0-HIT
  S2-G1-SQ-TERMINAL0-TVAL-ECHO
  S2-G1-SQ-BIND-HIT
  S2-G1-SQ-BIND-KIND
  S2-G1-SQ-BIND-DUP-TOKEN
  T4N-SQ-TERMINAL-SAME-TAG
)
for case_id in 1 2 3 4 5 6 7 8 9 10 11 12; do
  negative_log="$evidence_dir/assert-negative-$case_id.log"
  iverilog -g2012 -DOOO_ASSERT -I "$include_dir" \
    -P tb_s2_g1_sq_owner_negative.CASE_ID="$case_id" \
    -s tb_s2_g1_sq_owner_negative \
    -o "$work_dir/assert-negative-$case_id.vvp" \
    "$run_dir/tests/tb_s2_g1_sq_owner_negative.sv" "$rtl" \
    > "$negative_log" 2>&1
  set +e
  vvp "$work_dir/assert-negative-$case_id.vvp" >> "$negative_log" 2>&1
  negative_rc=$?
  set -e
  if [[ $negative_rc -eq 0 ]]; then
    printf 'SQ negative case %s unexpectedly passed\n' "$case_id" >&2
    exit 1
  fi
  if [[ "$(grep -c "${negative_markers[$case_id]}" "$negative_log")" -ne 1 ]]; then
    printf 'SQ negative case %s marker was not emitted exactly once\n' "$case_id" >&2
    exit 1
  fi
  if [[ "$(grep -c 'FATAL:' "$negative_log")" -ne 1 ]] ||
     grep -Eq 'ERROR:|warning:' "$negative_log"; then
    printf 'SQ negative case %s contains non-exact fatal/error/warning markers\n' "$case_id" >&2
    exit 1
  fi
  if grep -q '\[S2-G1-SQ-NEG\]\[PASS\]' "$negative_log"; then
    printf 'SQ negative case %s reached fallback PASS\n' "$case_id" >&2
    exit 1
  fi
done

sha256sum \
  "$rtl" \
  "$tb_dir/tests/tb_ooo_store_queue.sv" \
  "$run_dir/tests/tb_s2_g1_sq_owner_ports.sv" \
  "$run_dir/tests/tb_s2_g1_sq_owner_negative.sv" \
  "$run_dir/s2-g1-exact-owner-provenance-errata.md" \
  "$run_dir/run-s2-g1-sq-focused.sh" \
  > "$evidence_dir/sources.sha256"
printf 'work_dir=%s\npositive=GREEN_existing_plus_ports\nrequest_sent_global_flush=GREEN_BOK_BERR\nidentity_fail_closed=GREEN_fill_3_OF_3_terminal_3_OF_3\ntval_payload=GREEN_fill_accept_capture_truth_1_OF_1_terminal_release_bound_token_1_OF_1\nnegative=EXPECTED_FATAL_identity_6_OF_6_tval_echo_2_OF_2_protocol_4_OF_4\ntiming_qualification=UNQUALIFIED_not_measured\nresult=PASS\n' \
  "$work_dir" > "$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" > "$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 SQ focused GREEN: %s\n' "$evidence_dir"
