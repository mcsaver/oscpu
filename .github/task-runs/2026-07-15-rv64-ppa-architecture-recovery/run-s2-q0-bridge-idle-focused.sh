#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s2-q0-bridge-idle-green"
work_dir="$(mktemp -d /tmp/s2-q0-bridge-idle.XXXXXX)"
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
  "$rtl"
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
  -DS2_G1_BRIDGE_FOCUSED
  -P tb_ooo_mem_axi_bridge.S2_G1_CASE=8
)

for build in release assert; do
  extra_flags=()
  if [[ "$build" == assert ]]; then
    extra_flags=(-DOOO_ASSERT)
  fi
  compile_log="$evidence_dir/positive-$build.compile.log"
  sim_log="$evidence_dir/positive-$build.sim.log"
  "$iverilog_bin" "${common_flags[@]}" "${extra_flags[@]}" \
    -o "$work_dir/positive-$build.vvp" "${sources[@]}" \
    >"$compile_log" 2>&1
  "$vvp_bin" "$work_dir/positive-$build.vvp" >"$sim_log" 2>&1
  grep -q '\[S2-Q0-BRG-IDLE\]\[PASS\]' "$sim_log"
  grep -q '\[PASS\] tb_ooo_mem_axi_bridge' "$sim_log"
  if grep -Eq '\[CHECK-FAIL\]|ERROR:|FATAL:' "$sim_log"; then
    printf 'Q0 bridge-idle positive %s contains a failure marker\n' "$build" >&2
    exit 1
  fi
done

# Mutation 1: a state-only idle misses the request-station owner.  The assert
# build must terminate exactly at the safety marker before fallback PASS.
state_only_rtl="$work_dir/OooMemAxiBridge-state-only.v"
sed 's/assign mem0_idle_o = bridge_registered_facts_idle_w;/assign mem0_idle_o = (state_q == S_IDLE);/' \
  "$rtl" >"$state_only_rtl"
state_sources=("${sources[@]}")
state_sources[1]="$state_only_rtl"
"$iverilog_bin" "${common_flags[@]}" -DOOO_ASSERT \
  -o "$work_dir/state-only.vvp" "${state_sources[@]}" \
  >"$evidence_dir/mutation-state-only.compile.log" 2>&1
set +e
"$vvp_bin" "$work_dir/state-only.vvp" \
  >"$evidence_dir/mutation-state-only.sim.log" 2>&1
state_rc=$?
set -e
sed -i 's/[[:space:]]\+$//' "$evidence_dir/mutation-state-only.sim.log"
if [[ $state_rc -eq 0 ]] ||
   [[ "$(grep -c '\[S2-Q0-BRG-IDLE-SAFETY\]' \
       "$evidence_dir/mutation-state-only.sim.log")" -ne 1 ]] ||
   [[ "$(grep -c 'FATAL:' "$evidence_dir/mutation-state-only.sim.log")" -ne 1 ]] ||
   grep -q '\[PASS\] tb_ooo_mem_axi_bridge' \
     "$evidence_dir/mutation-state-only.sim.log"; then
  printf 'Q0 state-only mutation did not fail exactly\n' >&2
  exit 1
fi

# Mutation 2: sticky-low idle would deadlock the later epoch barrier.  The
# completeness assertion must reject it exactly.
stuck_low_rtl="$work_dir/OooMemAxiBridge-stuck-low.v"
sed "s/assign mem0_idle_o = bridge_registered_facts_idle_w;/assign mem0_idle_o = 1'b0;/" \
  "$rtl" >"$stuck_low_rtl"
low_sources=("${sources[@]}")
low_sources[1]="$stuck_low_rtl"
"$iverilog_bin" "${common_flags[@]}" -DOOO_ASSERT \
  -o "$work_dir/stuck-low.vvp" "${low_sources[@]}" \
  >"$evidence_dir/mutation-stuck-low.compile.log" 2>&1
set +e
"$vvp_bin" "$work_dir/stuck-low.vvp" \
  >"$evidence_dir/mutation-stuck-low.sim.log" 2>&1
low_rc=$?
set -e
sed -i 's/[[:space:]]\+$//' "$evidence_dir/mutation-stuck-low.sim.log"
if [[ $low_rc -eq 0 ]] ||
   [[ "$(grep -c '\[S2-Q0-BRG-IDLE-LIVENESS\]' \
       "$evidence_dir/mutation-stuck-low.sim.log")" -ne 1 ]] ||
   [[ "$(grep -c 'FATAL:' "$evidence_dir/mutation-stuck-low.sim.log")" -ne 1 ]] ||
   grep -q '\[PASS\] tb_ooo_mem_axi_bridge' \
     "$evidence_dir/mutation-stuck-low.sim.log"; then
  printf 'Q0 stuck-low mutation did not fail exactly\n' >&2
  exit 1
fi

# Q0 itself compiles the bridge leaf.  Close the NpcCoreTop port-binding claim
# by rechecking the separately rerun wrapper evidence against every current
# live source, rather than trusting a historical PASS string.
wrapper_evidence="$run_dir/evidence/r4-s2-g1-wrapper-exact-owner-green"
sha256sum -c "$wrapper_evidence/sources.sha256" \
  >"$evidence_dir/wrapper-sources.verify.log"
grep -q '^result=PASS$' "$wrapper_evidence/summary.txt"
grep -q '^- PASS tb_ooo_core_top_glue$' "$wrapper_evidence/module-summary.txt"
grep -q '^- PASS tb_ooo_sv39_boot$' "$wrapper_evidence/module-summary.txt"

mapfile -t support_sources < <(
  find "$vsrc/include" "$repo_root/npc/rv64/testbench/common" \
    -maxdepth 1 -type f -print | sort
)
printf '%s\n' "${sources[@]}" "${support_sources[@]}" \
  | sort -u >"$evidence_dir/compile-sources.txt"
mapfile -t manifest_sources <"$evidence_dir/compile-sources.txt"
sha256sum "${manifest_sources[@]}" "$0" \
  >"$evidence_dir/sources.sha256"
printf '%s\n' \
  "work_dir=$work_dir" \
  'scope=INTERMEDIATE_Q0_local_mem0_bridge_registered_fact_idle_only' \
  'positive=GREEN_release_and_OOO_ASSERT_2_OF_2' \
  'reachable_paths=GREEN_station_AR_R_AW_W_B_S_RESP_RMW_PTW_AD' \
  'mutation_state_only=EXPECTED_FATAL_safety_1_OF_1' \
  'mutation_stuck_low=EXPECTED_FATAL_liveness_1_OF_1' \
  'top_wiring=GREEN_separate_wrapper_source_bound_evidence_133_OF_133' \
  'dual_memory_global_quiet=RED_not_claimed' \
  'mmu_epoch_owner=RED_not_implemented' \
  'timing_qualification=UNQUALIFIED_not_measured' \
  'result=PASS' >"$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" >"$evidence_dir/tmp-work-dir.txt"
printf 'S2-Q0 bridge registered-fact idle GREEN: %s\n' "$evidence_dir"
