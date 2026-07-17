#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s2-g1-bridge-effective-kill-green"
work_dir="$(mktemp -d /tmp/s2-g1-bridge-green.XXXXXX)"
vsrc="$repo_root/npc/rv64/vsrc"
tb="$repo_root/npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv"
rtl="$vsrc/memory/OooMemAxiBridge.v"
iverilog_bin="$(command -v iverilog)"
vvp_bin="$(dirname "$iverilog_bin")/vvp"
if [[ ! -x "$vvp_bin" ]]; then
  vvp_bin="$(command -v vvp)"
fi
mkdir -p "$evidence_dir"

sources=(
  "$vsrc/cache/OooDataWordCache.v"
  "$vsrc/memory/OooMemAxiBridge.v"
  "$vsrc/memory/OooPmaChecker.v"
  "$vsrc/memory/OooPostTranslateMemoryClass.v"
  "$vsrc/memory/OooSv39Tlb.v"
  "$vsrc/memory/OooTypedMemoryClassifier.v"
  "$vsrc/memory/OooTypedPmaChecker.v"
  "$vsrc/memory/PmpChecker.v"
  "$vsrc/sram/Sram4096x113.v"
  "$tb"
)
common_flags=(
  -g2012 -Wall
  -I "$vsrc"
  -I "$vsrc/include"
  -I "$repo_root/npc/rv64/testbench/common"
  -s tb_ooo_mem_axi_bridge
)

main_compile="$evidence_dir/main.compile.log"
main_sim="$evidence_dir/main.sim.log"
"$iverilog_bin" "${common_flags[@]}" -DOOO_ASSERT \
  -o "$work_dir/main.vvp" "${sources[@]}" >"$main_compile" 2>&1
"$vvp_bin" "$work_dir/main.vvp" >"$main_sim" 2>&1
grep -q '\[PASS\] tb_ooo_mem_axi_bridge' "$main_sim"
grep -q '\[S2-G1-BRG-AW-W-HOLD\]\[PASS\] mode=0' "$main_sim"
grep -q '\[S2-G1-BRG-AW-W-HOLD\]\[PASS\] mode=1' "$main_sim"
grep -q '\[S2-G1-BRG-AW-W-HOLD\]\[PASS\] mode=2' "$main_sim"
grep -q '\[S2-G1-BRG-DUAL-DROP\]\[PASS\]' "$main_sim"
grep -q '\[S2-G1-BRG-ATOMIC-REPLACE\]\[PASS\]' "$main_sim"
if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:' "$main_sim"; then
  printf 'bridge main simulation contains a failure marker\n' >&2
  exit 1
fi

positive_markers=(
  unused
  'S2-G1-BRG-STATION-FAILCLOSED'
  'S2-G1-BRG-RSP-FAILCLOSED'
  'S2-G1-BRG-TRACKER-FAILCLOSED'
  'S2-G1-BRG-TVAL-PAYLOAD'
)
negative_markers=(
  unused
  'S2-G1-BRG-STATION-OWNER'
  'S2-G1-BRG-RSP-OWNER'
  'S2-G1-BRG-ACTIVE-TRACKER'
  'S2-G1-BRG-RSP-TVAL-ECHO'
)

for case_id in 1 2 3 4; do
  positive_compile="$evidence_dir/focused-positive-$case_id.compile.log"
  positive_sim="$evidence_dir/focused-positive-$case_id.sim.log"
  "$iverilog_bin" "${common_flags[@]}" -DS2_G1_BRIDGE_FOCUSED \
    -P tb_ooo_mem_axi_bridge.S2_G1_CASE="$case_id" \
    -o "$work_dir/focused-positive-$case_id.vvp" "${sources[@]}" \
    >"$positive_compile" 2>&1
  "$vvp_bin" "$work_dir/focused-positive-$case_id.vvp" \
    >"$positive_sim" 2>&1
  grep -q "\[${positive_markers[$case_id]}\]\[PASS\]" "$positive_sim"
  grep -q '\[PASS\] tb_ooo_mem_axi_bridge' "$positive_sim"
  if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:' "$positive_sim"; then
    printf 'bridge focused positive case %s contains a failure marker\n' \
      "$case_id" >&2
    exit 1
  fi

  negative_compile="$evidence_dir/focused-negative-$case_id.compile.log"
  negative_sim="$evidence_dir/focused-negative-$case_id.sim.log"
  "$iverilog_bin" "${common_flags[@]}" -DOOO_ASSERT \
    -DS2_G1_BRIDGE_FOCUSED \
    -P tb_ooo_mem_axi_bridge.S2_G1_CASE="$case_id" \
    -o "$work_dir/focused-negative-$case_id.vvp" "${sources[@]}" \
    >"$negative_compile" 2>&1
  set +e
  "$vvp_bin" "$work_dir/focused-negative-$case_id.vvp" \
    >"$negative_sim" 2>&1
  negative_rc=$?
  set -e
  if [[ $negative_rc -eq 0 ]]; then
    printf 'bridge focused negative case %s unexpectedly passed\n' \
      "$case_id" >&2
    exit 1
  fi
  if [[ "$(grep -c "\[${negative_markers[$case_id]}\]" "$negative_sim")" -ne 1 ]] ||
     [[ "$(grep -c 'FATAL:' "$negative_sim")" -ne 1 ]] ||
     grep -q 'ERROR:' "$negative_sim"; then
    printf 'bridge focused negative case %s has non-exact markers\n' \
      "$case_id" >&2
    exit 1
  fi
  if grep -q '\[PASS\] tb_ooo_mem_axi_bridge' "$negative_sim"; then
    printf 'bridge focused negative case %s reached fallback PASS\n' \
      "$case_id" >&2
    exit 1
  fi
done

maintenance_markers=(
  unused unused unused unused unused
  'S2-G1-BRG-KILLED-AD-MAINT'
  'S2-G1-BRG-KILLED-WRITE-FAILCLOSED'
  'S2-G1-BRG-PREWRITE-KILL'
)
for case_id in 5 6 7; do
  for build in release assert; do
    extra_flags=()
    if [[ "$build" == assert ]]; then
      extra_flags=(-DOOO_ASSERT)
    fi
    maintenance_compile="$evidence_dir/maintenance-$case_id-$build.compile.log"
    maintenance_sim="$evidence_dir/maintenance-$case_id-$build.sim.log"
    "$iverilog_bin" "${common_flags[@]}" "${extra_flags[@]}" \
      -DS2_G1_BRIDGE_FOCUSED \
      -P tb_ooo_mem_axi_bridge.S2_G1_CASE="$case_id" \
      -o "$work_dir/maintenance-$case_id-$build.vvp" "${sources[@]}" \
      >"$maintenance_compile" 2>&1
    "$vvp_bin" "$work_dir/maintenance-$case_id-$build.vvp" \
      >"$maintenance_sim" 2>&1
    grep -q "\[${maintenance_markers[$case_id]}\]\[PASS\]" \
      "$maintenance_sim"
    grep -q '\[PASS\] tb_ooo_mem_axi_bridge' "$maintenance_sim"
    if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:' "$maintenance_sim"; then
      printf 'bridge maintenance case %s/%s contains a failure marker\n' \
        "$case_id" "$build" >&2
      exit 1
    fi
  done
done

mapfile -t support_sources < <(
  find "$vsrc/include" "$repo_root/npc/rv64/testbench/common" \
    -maxdepth 1 -type f -print | sort
)
printf '%s\n' \
  "${sources[@]}" \
  "${support_sources[@]}" \
  | sort -u >"$evidence_dir/compile-sources.txt"
mapfile -t manifest_sources <"$evidence_dir/compile-sources.txt"
sha256sum \
  "${manifest_sources[@]}" \
  "$run_dir/s2-g1-exact-owner-provenance-errata.md" \
  "$run_dir/s2-g1-exact-owner-provenance-completion-definition.md" \
  "$run_dir/s2-g1-effective-kill-coherence-maintenance-addendum.md" \
  "$run_dir/run-s2-g1-bridge-focused.sh" \
  >"$evidence_dir/sources.sha256"
printf '%s\n' \
  "work_dir=$work_dir" \
  'long_regression=GREEN_OOO_ASSERT' \
  'write_visibility_hold=GREEN_both_stalled_AW_only_W_only_3_OF_3' \
  'dual_drop_and_atomic_replace=GREEN_2_OF_2' \
  'station_mismatch=GREEN_release_failclosed_and_exact_recovery_drop_1_OF_1' \
  'response_identity=GREEN_transport_independent_fill_blocked_1_OF_1' \
  'tracker_liveness=GREEN_transport_independent_fill_blocked_1_OF_1' \
  'tval_payload=GREEN_exact_9bit_progress_capture_tval_truth_1_OF_1' \
  'negative=EXPECTED_FATAL_station_rsp_tracker_tval_4_OF_4' \
  'killed_ad_maintenance=GREEN_exact_kill_capture_late_B_invalidate_only_release_and_assert_2_OF_2' \
  'killed_owner_mismatch=GREEN_raw_flush_and_kill_cannot_authorize_cache_maintenance_release_and_assert_2_OF_2' \
  'prewrite_kill=GREEN_no_escaped_write_authority_release_and_assert_2_OF_2' \
  'ready_match_independence=GREEN_transport_ready_not_gated_by_exact_equality' \
  'top_integration=SEPARATE_wrapper_source_bound_evidence_required' \
  'timing_qualification=UNQUALIFIED_not_measured' \
  'result=PASS' >"$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" >"$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 bridge focused GREEN: %s\n' "$evidence_dir"
