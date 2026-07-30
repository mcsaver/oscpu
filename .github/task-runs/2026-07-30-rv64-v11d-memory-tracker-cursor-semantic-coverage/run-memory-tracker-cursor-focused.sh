#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$run_dir" rev-parse --show-toplevel)"
tb_home="$repo_root/npc/rv64/testbench"
tracker="$repo_root/npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
cursor_tb="tests/tb_ooo_mem_owner_tracker_cursor.sv"
snapshot_tool="$repo_root/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
evidence_tool="$repo_root/npc/rv64/eval/ppa/tools/memory_tracker_cursor_semantic_evidence.py"
attempt="${V11D_CURSOR_ATTEMPT:-1}"
evidence_dir="${V11D_CURSOR_EVIDENCE_DIR_OVERRIDE:-$run_dir/evidence/cursor-attempt-$attempt}"
base_flags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"
test_name="tb_ooo_mem_owner_tracker_cursor"

fail() {
  printf '[V11D-CURSOR-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ ! "$attempt" =~ ^[1-9][0-9]*$ ]]; then
  fail "V11D_CURSOR_ATTEMPT must be a positive integer"
fi
if [[ -e "$evidence_dir" ]]; then
  fail "evidence directory already exists: ${evidence_dir#$repo_root/}"
fi
mkdir -p "$evidence_dir"

source_paths=(
  ".github/task-runs/2026-07-30-rv64-v11d-memory-tracker-cursor-semantic-coverage/run-memory-tracker-cursor-focused.sh"
  "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/scripts/check_tb_result.py"
  "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker_cursor.sv"
  "npc/rv64/eval/ppa/tools/memory_tracker_cursor_semantic_evidence.py"
  "npc/rv64/eval/ppa/tests/test_memory_tracker_cursor_semantic_evidence.py"
  "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py"
  "npc/rv64/design/arch/producer-holder-census.json"
  "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
  "npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md"
)

(
  cd "$repo_root"
  sha256sum "${source_paths[@]}"
) > "$evidence_dir/sources.pre.sha256"
python3 "$snapshot_tool" \
  --snapshot-out "$evidence_dir/rtl-source-binding.pre.json"

run_positive() {
  local profile=$1
  local token_count=$2
  local token_w=$3
  local count_w=$4
  local assertions=$5
  local flags=$base_flags
  local profile_dir="$evidence_dir/$profile"
  if [[ "$assertions" == "on" ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  make -B -C "$tb_home" \
    BUILD_DIR="$profile_dir/build" \
    RESULT_DIR="$profile_dir/result" \
    EXTRA_TESTS="$test_name" \
    IVFLAGS="$flags" \
    TB_SRCS_tb_ooo_mem_owner_tracker_cursor="$cursor_tb $tracker" \
    TB_IVFLAGS_tb_ooo_mem_owner_tracker_cursor="\
-P${test_name}.TOKEN_COUNT=$token_count \
-P${test_name}.TOKEN_W=$token_w \
-P${test_name}.COUNT_W=$count_w" \
    "$profile_dir/result/logs/$test_name.log"
}

run_positive assert-t4 4 2 3 on
run_positive release-t4 4 2 3 off
run_positive assert-t32 32 5 6 on
run_positive release-t32 32 5 6 off

mutation_cases=(
  reset-to-one
  fixed-scan-base
  advance-step-two
  dual-advance-lane0
  advance-on-ready
  idle-increment
  lane1-does-not-exclude-lane0
  lane1-excludes-unclaimed-lane0
  truncate-scan-four
)
for case in "${mutation_cases[@]}"; do
  case_dir="$evidence_dir/mutations/$case"
  mkdir -p "$case_dir"
  python3 "$evidence_tool" mutate \
    --case "$case" \
    --input "$tracker" \
    --output "$case_dir/OooMemOwnerTracker.v" \
    --receipt "$case_dir/mutator.json" \
    > "$case_dir/mutator.log"
  set +e
  make -B -C "$tb_home" \
    BUILD_DIR="$case_dir/build" \
    RESULT_DIR="$case_dir/result" \
    EXTRA_TESTS="$test_name" \
    IVFLAGS="$base_flags" \
    TB_SRCS_tb_ooo_mem_owner_tracker_cursor="\
$cursor_tb $case_dir/OooMemOwnerTracker.v" \
    TB_IVFLAGS_tb_ooo_mem_owner_tracker_cursor="\
-P${test_name}.TOKEN_COUNT=32 \
-P${test_name}.TOKEN_W=5 \
-P${test_name}.COUNT_W=6" \
    "$case_dir/result/logs/$test_name.log"
  mutation_rc=$?
  set -e
  printf '%s\n' "$mutation_rc" > "$case_dir/make.rc"
  [[ "$mutation_rc" -ne 0 ]] ||
    fail "cursor RTL variant unexpectedly passed: $case"
done

python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_memory_tracker_cursor_semantic_evidence \
  > "$evidence_dir/evidence-tool-unit.log" 2>&1

(
  cd "$repo_root"
  sha256sum "${source_paths[@]}"
) > "$evidence_dir/sources.post.sha256"
cmp -s "$evidence_dir/sources.pre.sha256" \
  "$evidence_dir/sources.post.sha256" ||
  fail "focused source set changed during execution"
python3 "$snapshot_tool" \
  --snapshot-out "$evidence_dir/rtl-source-binding.post.json"
cmp -s "$evidence_dir/rtl-source-binding.pre.json" \
  "$evidence_dir/rtl-source-binding.post.json" ||
  fail "full RTL source set changed during execution"

python3 "$evidence_tool" build \
  --root "$repo_root" \
  --evidence-dir "$evidence_dir" \
  --output "$evidence_dir/summary.json"
printf '%s\n' \
  "[V11D-CURSOR-RUNNER][PASS] attempt=$attempt profiles=4 mutations=9/9"
