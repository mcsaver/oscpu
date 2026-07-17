#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s1-id-terminal-collector-green"
build_dir="$(mktemp -d /tmp/s2-g1-terminal-collector-green.XXXXXX)"
rtl="$repo_root/npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
backend_rtl="$repo_root/npc/rv64/vsrc/execute/OooIntBackend.v"
core_filelist="$repo_root/npc/rv64/vsrc/filelist.mk"
mkdir -p "$evidence_dir"

green_log="$evidence_dir/green.log"
iverilog -g2012 -DOOO_ASSERT \
  -s tb_s2_g1_terminal_collector_green \
  -o "$build_dir/green.vvp" \
  "$run_dir/tests/tb_s2_g1_terminal_collector_green.sv" "$rtl" \
  > "$green_log" 2>&1
vvp "$build_dir/green.vvp" >> "$green_log" 2>&1
grep -Fq '[S2-G1-TCOLL-GREEN][PASS]' "$green_log"
if grep -Eq '\[(FAIL|ERROR)\]|FATAL' "$green_log"; then
  printf 'collector green test reported a failure marker\n' >&2
  exit 1
fi

# The leaf is only useful after the accounting collector is wired into the
# real backend and the production core source list.  Keep this as a structural
# integration gate; it does not qualify the full architecture or timing.
grep -Fq 'OooMemOwnerTerminalCollector #(' "$backend_rtl"
grep -Fq '$(RTL_OOO_MEM_OWNER_TERMINAL_COLLECTOR)' "$core_filelist"

failclosed_log="$evidence_dir/failclosed.log"
iverilog -g2012 \
  -s tb_s2_g1_terminal_collector_failclosed \
  -o "$build_dir/failclosed.vvp" \
  "$run_dir/tests/tb_s2_g1_terminal_collector_failclosed.sv" "$rtl" \
  > "$failclosed_log" 2>&1
vvp "$build_dir/failclosed.vvp" >> "$failclosed_log" 2>&1
grep -Fq '[S2-G1-TCOLL-FAILCLOSED][PASS]' "$failclosed_log"
if grep -Eq '\[(FAIL|ERROR)\]|FATAL' "$failclosed_log"; then
  printf 'collector fail-closed test reported a failure marker\n' >&2
  exit 1
fi

negative_markers=(
  '[S2-G1-TCOLL-RESERVED]'
  '[S2-G1-TCOLL-NONLIVE]'
  '[S2-G1-TCOLL-TUPLE-MISMATCH]'
  '[S2-G1-TCOLL-TUPLE-MISMATCH]'
  '[S2-G1-TCOLL-INGRESS-DUP]'
  '[S2-G1-TCOLL-PENDING-DUP]'
  '[S2-G1-TCOLL-SAME-EDGE-REENQUEUE]'
)
for case_id in 0 1 2 3 4 5 6; do
  neg_log="$evidence_dir/negative-case-$case_id.log"
  set +e
  iverilog -g2012 -DOOO_ASSERT \
    -P tb_s2_g1_terminal_collector_negative.CASE_ID="$case_id" \
    -s tb_s2_g1_terminal_collector_negative \
    -o "$build_dir/negative-case-$case_id.vvp" \
    "$run_dir/tests/tb_s2_g1_terminal_collector_negative.sv" "$rtl" \
    > "$neg_log" 2>&1 && \
    vvp "$build_dir/negative-case-$case_id.vvp" >> "$neg_log" 2>&1
  neg_rc=$?
  set -e
  if [[ $neg_rc -eq 0 ]]; then
    printf 'collector negative case %s unexpectedly passed\n' "$case_id" >&2
    exit 1
  fi
  if [[ "$(grep -Fc "${negative_markers[$case_id]}" "$neg_log")" -ne 1 ]]; then
    printf 'collector negative case %s did not produce exactly one target marker\n' \
      "$case_id" >&2
    exit 1
  fi
  if grep -Fq '[S2-G1-TCOLL-NEG][FAIL]' "$neg_log"; then
    printf 'collector negative case %s reached fallback failure\n' "$case_id" >&2
    exit 1
  fi
done

# Leaf-only structural legality: prefer Yosys when the shell provides it and
# otherwise use Verilator lint.  Neither path qualifies timing/area/power.
if command -v yosys >/dev/null 2>&1; then
  leaf_check_log="$evidence_dir/yosys-check.log"
  yosys -q -p \
    "read_verilog -sv $rtl; hierarchy -check -top OooMemOwnerTerminalCollector; proc; opt; check" \
    > "$leaf_check_log" 2>&1
  if grep -Eq 'ERROR:|found [1-9][0-9]* problems' "$leaf_check_log"; then
    printf 'collector leaf Yosys check reported a problem\n' >&2
    exit 1
  fi
  leaf_check_summary='GREEN_yosys_check'
else
  leaf_check_log="$evidence_dir/verilator-lint.log"
  verilator --lint-only --Wno-fatal --top-module OooMemOwnerTerminalCollector \
    "$rtl" > "$leaf_check_log" 2>&1
  if grep -Eq '%Error|Error:' "$leaf_check_log"; then
    printf 'collector leaf Verilator lint reported an error\n' >&2
    exit 1
  fi
  leaf_check_summary='GREEN_verilator_lint_yosys_unavailable'
fi

sha256sum \
  "$rtl" \
  "$backend_rtl" \
  "$core_filelist" \
  "$run_dir/tests/tb_s2_g1_terminal_collector_green.sv" \
  "$run_dir/tests/tb_s2_g1_terminal_collector_failclosed.sv" \
  "$run_dir/tests/tb_s2_g1_terminal_collector_negative.sv" \
  "$run_dir/run-s2-g1-terminal-collector-focused.sh" \
  "$run_dir/s2-g1-terminal-collector-rtl-derivation.md" \
  "$run_dir/s2-g1-exact-owner-provenance-errata.md" \
  > "$evidence_dir/sources.sha256"

printf '%s\n' \
  'ingress_capacity=GREEN_parameterized_default_6_same_edge' \
  'lossless_burst=GREEN_18_OF_18_exact_once' \
  'registered_dequeue=GREEN_2_ports_independent_backpressure' \
  'fail_closed=GREEN_duplicate_nonlive_kind_epoch_same_edge' \
  'negative=EXPECTED_FATAL_7_OF_7_single_target_marker' \
  "leaf_structural_check=$leaf_check_summary" \
  'collector_side_effect_authority=NONE_accounting_only' \
  'fault_tval_identity=ABSENT_BY_CONTRACT' \
  'integration=GREEN_backend_instance_and_production_core_filelist' \
  'timing_qualification=UNQUALIFIED_no_STA' \
  'power_area_qualification=UNQUALIFIED_leaf_check_only' \
  'architecture_qualification=INTERMEDIATE_epoch_and_true_dual_memory_pending' \
  'result=PASS' \
  > "$evidence_dir/summary.txt"
printf '%s\n' "$build_dir" > "$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 terminal collector focused GREEN: %s\n' "$evidence_dir"
