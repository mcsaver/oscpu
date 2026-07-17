#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s1-id-miq-green"
work_dir="$(mktemp -d /tmp/s2-g1-miq-green.XXXXXX)"
rtl="$repo_root/npc/rv64/vsrc/memory/OooMemInflightQueue.v"
include_dir="$repo_root/npc/rv64/vsrc/include"
tb_dir="$repo_root/npc/rv64/testbench"
mkdir -p "$evidence_dir"

iverilog -g2012 -Wall -DOOO_ASSERT \
  -I "$repo_root/npc/rv64/vsrc" -I "$include_dir" -I "$tb_dir/common" \
  -s tb_ooo_mem_inflight_queue \
  -o "$work_dir/tb_ooo_mem_inflight_queue.vvp" \
  "$tb_dir/tests/tb_ooo_mem_inflight_queue.sv" "$rtl" \
  > "$evidence_dir/tb_ooo_mem_inflight_queue.log" 2>&1
vvp "$work_dir/tb_ooo_mem_inflight_queue.vvp" \
  >> "$evidence_dir/tb_ooo_mem_inflight_queue.log" 2>&1
grep -q '\[PASS\] tb_ooo_mem_inflight_queue' \
  "$evidence_dir/tb_ooo_mem_inflight_queue.log"
if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:' "$evidence_dir/tb_ooo_mem_inflight_queue.log"; then
  printf 'main MIQ focused log contains a failure marker\n' >&2
  exit 1
fi

iverilog -g2012 -I "$include_dir" \
  -s tb_s2_g1_miq_owner_ports \
  -o "$work_dir/tb_s2_g1_miq_owner_ports.vvp" \
  "$run_dir/tests/tb_s2_g1_miq_owner_ports.sv" "$rtl" \
  > "$evidence_dir/tb_s2_g1_miq_owner_ports.log" 2>&1
vvp "$work_dir/tb_s2_g1_miq_owner_ports.vvp" \
  >> "$evidence_dir/tb_s2_g1_miq_owner_ports.log" 2>&1
grep -q '\[S2-G1-MIQ\]\[PASS\]' "$evidence_dir/tb_s2_g1_miq_owner_ports.log"

for mutation in 1 2 3 4; do
  positive_log="$evidence_dir/mismatch-drain-$mutation.log"
  negative_log="$evidence_dir/mismatch-assert-$mutation.log"
  iverilog -g2012 -I "$include_dir" \
    -P tb_s2_g1_miq_mismatch_drain.MUTATION="$mutation" \
    -s tb_s2_g1_miq_mismatch_drain \
    -o "$work_dir/mismatch-drain-$mutation.vvp" \
    "$run_dir/tests/tb_s2_g1_miq_mismatch_drain.sv" "$rtl" \
    > "$positive_log" 2>&1
  vvp "$work_dir/mismatch-drain-$mutation.vvp" >> "$positive_log" 2>&1
  if [[ $mutation -le 3 ]]; then
    grep -q "\[S2-G1-MIQ-MISMATCH\]\[PASS\] identity mutation $mutation retained owner" "$positive_log"
  else
    grep -q '\[S2-G1-MIQ-TVAL\]\[PASS\] tval drift consumed 9-bit owner with captured provenance' "$positive_log"
  fi
  if grep -Eq '\[FAIL\]|ERROR:|FATAL:' "$positive_log"; then
    printf 'mutation %s fail-closed log contains a failure marker\n' "$mutation" >&2
    exit 1
  fi

  iverilog -g2012 -DOOO_ASSERT -I "$include_dir" \
    -P tb_s2_g1_miq_mismatch_drain.MUTATION="$mutation" \
    -s tb_s2_g1_miq_mismatch_drain \
    -o "$work_dir/mismatch-assert-$mutation.vvp" \
    "$run_dir/tests/tb_s2_g1_miq_mismatch_drain.sv" "$rtl" \
    > "$negative_log" 2>&1
  set +e
  vvp "$work_dir/mismatch-assert-$mutation.vvp" >> "$negative_log" 2>&1
  negative_rc=$?
  set -e
  if [[ $negative_rc -eq 0 ]]; then
    printf 'mutation %s assertion run unexpectedly passed\n' "$mutation" >&2
    exit 1
  fi
  expected_marker='MIQ-OWNER-MISMATCH'
  if [[ $mutation -eq 4 ]]; then
    expected_marker='MIQ-TVAL-ECHO-MISMATCH'
  fi
  if [[ "$(grep -c "\[$expected_marker\]" "$negative_log")" -ne 1 ]]; then
    printf 'mutation %s mismatch marker was not emitted exactly once\n' "$mutation" >&2
    exit 1
  fi
  if [[ "$(grep -c 'FATAL:' "$negative_log")" -ne 1 ]] || grep -q 'ERROR:' "$negative_log"; then
    printf 'mutation %s assertion log contains non-exact fatal/error markers\n' "$mutation" >&2
    exit 1
  fi
  if grep -q '\[S2-G1-MIQ-MISMATCH\]\[PASS\]' "$negative_log"; then
    printf 'mutation %s assertion run reached fallback PASS\n' "$mutation" >&2
    exit 1
  fi
done

protocol_markers=(
  MIQ-OWNER-EMPTY
  MIQ-OWNER-RESERVED
  MIQ-OWNER-DUP
  MIQ-OWNER-DUP
  MIQ-PHASE-OWNER-MISMATCH
)
for case_id in 0 1 2 3 4; do
  protocol_log="$evidence_dir/protocol-assert-$case_id.log"
  iverilog -g2012 -DOOO_ASSERT -I "$include_dir" \
    -P tb_s2_g1_miq_protocol_negative.CASE_ID="$case_id" \
    -s tb_s2_g1_miq_protocol_negative \
    -o "$work_dir/protocol-assert-$case_id.vvp" \
    "$run_dir/tests/tb_s2_g1_miq_protocol_negative.sv" "$rtl" \
    > "$protocol_log" 2>&1
  set +e
  vvp "$work_dir/protocol-assert-$case_id.vvp" >> "$protocol_log" 2>&1
  protocol_rc=$?
  set -e
  if [[ $protocol_rc -eq 0 ]]; then
    printf 'MIQ protocol case %s unexpectedly passed\n' "$case_id" >&2
    exit 1
  fi
  if [[ "$(grep -c "\[${protocol_markers[$case_id]}\]" "$protocol_log")" -ne 1 ]]; then
    printf 'MIQ protocol case %s marker was not emitted exactly once\n' "$case_id" >&2
    exit 1
  fi
  if grep -q '\[S2-G1-MIQ-PROTOCOL\]\[FAIL\]' "$protocol_log"; then
    printf 'MIQ protocol case %s reached fallback failure\n' "$case_id" >&2
    exit 1
  fi
done

sha256sum \
  "$rtl" \
  "$tb_dir/tests/tb_ooo_mem_inflight_queue.sv" \
  "$run_dir/tests/tb_s2_g1_miq_owner_ports.sv" \
  "$run_dir/tests/tb_s2_g1_miq_mismatch_drain.sv" \
  "$run_dir/tests/tb_s2_g1_miq_protocol_negative.sv" \
  "$run_dir/s2-g1-exact-owner-provenance-errata.md" \
  "$run_dir/run-s2-g1-miq-focused.sh" \
  > "$evidence_dir/sources.sha256"
printf 'work_dir=%s\nidentity_positive=GREEN_kind_token_epoch_transport_drained_owner_retained_3_OF_3\ntval_positive=GREEN_exact_9bit_owner_consumed_with_capture_tval_truth_1_OF_1\nnegative=EXPECTED_FATAL_identity_3_OF_3_tval_echo_1_OF_1_protocol_5_OF_5\nready_match_independence=LEAF_ONLY_outer_bridge_pending\ntiming_qualification=UNQUALIFIED_not_measured\nresult=PASS\n' \
  "$work_dir" > "$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" > "$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 MIQ focused GREEN: %s\n' "$evidence_dir"
