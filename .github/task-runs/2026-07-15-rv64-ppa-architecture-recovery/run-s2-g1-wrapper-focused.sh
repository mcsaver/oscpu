#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s2-g1-wrapper-exact-owner-green"
work_dir="$(mktemp -d /tmp/s2-g1-wrapper-green.XXXXXX)"
module_dir="$work_dir/module"
tb_dir="$repo_root/npc/rv64/testbench"
vsrc="$repo_root/npc/rv64/vsrc"
mkdir -p "$evidence_dir/logs"

resolve_make_tb_sources() {
  local variable_name="$1"
  local line
  local source
  local -a resolved=()
  line="$(make -C "$tb_dir" -pn 2>/dev/null |
    sed -n "s/^${variable_name} := //p")"
  [[ -n "$line" ]]
  read -r -a resolved <<<"$line"
  for source in "${resolved[@]}"; do
    if [[ "$source" = /* ]]; then
      printf '%s\n' "$source"
    else
      printf '%s\n' "$tb_dir/$source"
    fi
  done
}

python3 "$run_dir/check-s2-g1-wrapper-owner-abi.py" --self-test \
  >"$evidence_dir/abi-check.log" 2>&1
grep -q '\[S2-G1-WRAPPER-ABI\]\[PASS\] checks=228' \
  "$evidence_dir/abi-check.log"
grep -q '\[S2-G1-WRAPPER-ABI-MUTATION\]\[EXPECTED-FAIL\]' \
  "$evidence_dir/abi-check.log"

make -C "$tb_dir" \
  TESTS='tb_ooo_core_top_glue tb_ooo_sv39_boot' \
  RESULT_DIR="$module_dir" BUILD_DIR="$work_dir/build" run \
  >"$evidence_dir/module-run.log" 2>&1
grep -q -- '- PASS tb_ooo_core_top_glue' "$module_dir/summary.txt"
grep -q -- '- PASS tb_ooo_sv39_boot' "$module_dir/summary.txt"
grep -q '\[S2-G1-WRAPPER-EXACT-OWNER\]\[PASS\]' \
  "$module_dir/logs/tb_ooo_core_top_glue.log"
if grep -Eq 'dangling input port.*mem_' "$module_dir"/logs/*.log; then
  printf 'exact-owner memory ABI has a dangling integration input\n' >&2
  exit 1
fi
if grep -Eq '\[S2-G1-WRAPPER-(OWNER|STATION)\]\[FAIL\]' \
     "$module_dir"/logs/*.log; then
  printf 'dynamic wrapper owner roundtrip failed\n' >&2
  exit 1
fi

cp "$module_dir/summary.txt" "$evidence_dir/module-summary.txt"
cp "$module_dir/logs/tb_ooo_core_top_glue.log" "$evidence_dir/logs/"
cp "$module_dir/logs/tb_ooo_sv39_boot.log" "$evidence_dir/logs/"

mapfile -t wrapper_compile_sources < <(
  resolve_make_tb_sources TB_SRCS_tb_ooo_core_top_glue
  resolve_make_tb_sources TB_SRCS_tb_ooo_sv39_boot
)
mapfile -t support_sources < <(
  find "$vsrc/include" "$tb_dir/common" -maxdepth 1 -type f -print | sort
)
printf '%s\n' \
  "${wrapper_compile_sources[@]}" \
  "${support_sources[@]}" \
  "$tb_dir/Makefile" \
  "$vsrc/filelist.mk" \
  | sort -u >"$evidence_dir/compile-sources.txt"
mapfile -t manifest_sources <"$evidence_dir/compile-sources.txt"
sha256sum \
  "${manifest_sources[@]}" \
  "$run_dir/s2-g1-exact-owner-provenance-completion-definition.md" \
  "$run_dir/s2-g1-effective-kill-coherence-maintenance-addendum.md" \
  "$run_dir/check-s2-g1-wrapper-owner-abi.py" \
  "$run_dir/run-s2-g1-wrapper-focused.sh" \
  >"$evidence_dir/sources.sha256"

printf '%s\n' \
  "work_dir=$work_dir" \
  'static_abi=GREEN_228_checks' \
  'mutation_negative=EXPECTED_FAIL_constant_request_token_1_OF_1' \
  'dynamic_wrapper=GREEN_request_response_MIQ_tracker_station_exact_roundtrip' \
  'npc_core_top_bridge=GREEN_sv39_module_test' \
  'dangling_exact_owner_inputs=ZERO' \
  'architecture_qualification=INTERMEDIATE_epoch_and_true_dual_memory_pending' \
  'timing_qualification=UNQUALIFIED_not_measured' \
  'result=PASS' >"$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" >"$evidence_dir/tmp-work-dir.txt"
printf 'S2-G1 wrapper exact-owner GREEN: %s\n' "$evidence_dir"
