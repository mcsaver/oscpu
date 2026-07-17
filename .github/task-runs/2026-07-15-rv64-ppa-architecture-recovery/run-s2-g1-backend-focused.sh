#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
run_dir="$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
evidence_dir="$run_dir/evidence/r4-s2-g1-backend-effective-kill-green"
work_dir="$(mktemp -d /tmp/s2-g1-backend-green.XXXXXX)"
tb_dir="$repo_root/npc/rv64/testbench"
vsrc="$repo_root/npc/rv64/vsrc"
rtl="$repo_root/npc/rv64/vsrc/execute/OooIntBackend.v"
tb="$tb_dir/tests/tb_ooo_int_backend.sv"
miq_rtl="$repo_root/npc/rv64/vsrc/memory/OooMemInflightQueue.v"
include_dir="$repo_root/npc/rv64/vsrc/include"
assert_result="$work_dir/assert-result"
nonassert_result="$work_dir/nonassert-result"
assert_log="$evidence_dir/tb_ooo_int_backend-assert.log"
nonassert_log="$evidence_dir/tb_ooo_int_backend-nonassert.log"
miq_negative_log="$evidence_dir/miq-empty-assert.log"

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

mkdir -p "$evidence_dir"

make -C "$tb_dir" BUILD_DIR="$work_dir/assert-build" RESULT_DIR="$assert_result" "$assert_result/logs/tb_ooo_int_backend.log"
cp "$assert_result/logs/tb_ooo_int_backend.log" "$assert_log"

grep -Fq '[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS' "$assert_log"
grep -Fq '[T4S-AMO-RESTORE] read+restore lane0, interphase lane5, selected-grant-only write PASS' "$assert_log"
grep -Fq '[PASS] tb_ooo_int_backend' "$assert_log"
grep -Fq '[RESULT] PASS' "$assert_log"
if grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|ERROR:|FATAL:' "$assert_log"; then
  printf 'backend assert focused log contains a failure marker\n' >&2
  exit 1
fi

make -C "$tb_dir" "IVFLAGS=-g2012 -Wall -I$repo_root/npc/rv64/vsrc -I$include_dir -Icommon" BUILD_DIR="$work_dir/nonassert-build" RESULT_DIR="$nonassert_result" "$nonassert_result/logs/tb_ooo_int_backend.log"
cp "$nonassert_result/logs/tb_ooo_int_backend.log" "$nonassert_log"

grep -Fq '[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS' "$nonassert_log"
grep -Fq '[T4S-AMO-RESTORE] read+restore lane0, interphase lane5, selected-grant-only write PASS' "$nonassert_log"
grep -Fq '[T4S-STALE-DRAIN] empty MIQ drains transport with zero side effects PASS' "$nonassert_log"
grep -Fq '[PASS] tb_ooo_int_backend' "$nonassert_log"
grep -Fq '[RESULT] PASS' "$nonassert_log"
if grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|ERROR:|FATAL:' "$nonassert_log"; then
  printf 'backend nonassert focused log contains a failure marker\n' >&2
  exit 1
fi

iverilog -g2012 -DOOO_ASSERT -I "$include_dir" -P tb_s2_g1_miq_protocol_negative.CASE_ID=0 -s tb_s2_g1_miq_protocol_negative -o "$work_dir/miq-empty-assert.vvp" "$run_dir/tests/tb_s2_g1_miq_protocol_negative.sv" "$miq_rtl" > "$miq_negative_log" 2>&1
set +e
vvp "$work_dir/miq-empty-assert.vvp" >> "$miq_negative_log" 2>&1
miq_negative_rc=$?
set -e
if [[ $miq_negative_rc -eq 0 ]]; then
  printf 'MIQ empty-owner assertion run unexpectedly passed\n' >&2
  exit 1
fi
if [[ "$(grep -c '\[MIQ-OWNER-EMPTY\]' "$miq_negative_log")" -ne 1 ]] ||
   [[ "$(grep -c 'FATAL:' "$miq_negative_log")" -ne 1 ]]; then
  printf 'MIQ empty-owner assertion marker/fatal was not exact\n' >&2
  exit 1
fi

mapfile -t backend_compile_sources < <(
  resolve_make_tb_sources TB_SRCS_tb_ooo_int_backend
)
mapfile -t support_sources < <(
  find "$include_dir" "$tb_dir/common" -maxdepth 1 -type f -print | sort
)
printf '%s\n' \
  "${backend_compile_sources[@]}" \
  "${support_sources[@]}" \
  "$tb_dir/Makefile" \
  "$vsrc/filelist.mk" \
  "$run_dir/tests/tb_s2_g1_miq_protocol_negative.sv" \
  | sort -u >"$evidence_dir/compile-sources.txt"
mapfile -t manifest_sources <"$evidence_dir/compile-sources.txt"
sha256sum \
  "${manifest_sources[@]}" \
  "$run_dir/s2-g1-exact-owner-provenance-errata.md" \
  "$run_dir/s2-g1-effective-kill-coherence-maintenance-addendum.md" \
  "$run_dir/run-s2-g1-backend-focused.sh" \
  >"$evidence_dir/sources.sha256"

{
  printf 'work_dir=%s\n' "$work_dir"
  printf 'effective_kill=GREEN_LOAD_PROBE_exact_pop_terminal_once_zero_WB_SQ_side_effects\n'
  printf 'amo_restore=GREEN_read_restore_lane0_interphase_lane5_selected_grant_only\n'
  printf 'stale_release=GREEN_empty_MIQ_transport_drained_zero_side_effects\n'
  printf 'stale_assert=EXPECTED_FATAL_MIQ_OWNER_EMPTY_1_OF_1\n'
  printf 'timing_qualification=UNQUALIFIED_not_measured\n'
  printf 'architecture_qualification=INTERMEDIATE_not_seed\n'
  printf 'result=PASS\n'
} > "$evidence_dir/summary.txt"
printf '%s\n' "$work_dir" > "$evidence_dir/tmp-work-dir.txt"
{
  iverilog -V 2>/dev/null | sed -n '1p'
  vvp -V 2>&1 | sed -n '1p'
} > "$evidence_dir/tool-versions.txt"

printf 'S2-G1 backend focused GREEN: %s\n' "$evidence_dir"
