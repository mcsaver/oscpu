#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$run_dir" rev-parse --show-toplevel)"
tb_home="$repo_root/npc/rv64/testbench"
tracker="$repo_root/npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
tracker_tb="tests/tb_ooo_mem_owner_tracker.sv"
tracker_checker="tests/tb_ooo_mem_owner_tracker_semantic_checker.sv"
snapshot_tool="$repo_root/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
evidence_tool="$repo_root/npc/rv64/eval/ppa/tools/memory_tracker_semantic_evidence.py"
attempt="${V11C_TRACKER_ATTEMPT:-1}"
evidence_dir="${V11C_TRACKER_EVIDENCE_DIR_OVERRIDE:-$run_dir/evidence/memory-tracker-attempt-$attempt}"
base_flags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"
test_name="tb_ooo_mem_owner_tracker"

fail() {
  printf '[V11C-TRACKER-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ ! "$attempt" =~ ^[1-9][0-9]*$ ]]; then
  fail "V11C_TRACKER_ATTEMPT must be a positive integer"
fi
if [[ -e "$evidence_dir" ]]; then
  fail "evidence directory already exists: ${evidence_dir#$repo_root/}"
fi
mkdir -p "$evidence_dir"

source_paths=(
  ".github/task-runs/2026-07-29-rv64-v11c-memory-tracker-semantic-coverage/run-memory-tracker-focused.sh"
  "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/scripts/check_tb_result.py"
  "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv"
  "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker_semantic_checker.sv"
  "npc/rv64/eval/ppa/tools/memory_tracker_semantic_evidence.py"
  "npc/rv64/eval/ppa/tests/test_memory_tracker_semantic_evidence.py"
  "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py"
  "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
)

(
  cd "$repo_root"
  sha256sum "${source_paths[@]}"
) > "$evidence_dir/sources.pre.sha256"
python3 "$snapshot_tool" \
  --snapshot-out "$evidence_dir/rtl-source-binding.pre.json"

run_positive() {
  local profile=$1
  local flags=$base_flags
  local profile_dir="$evidence_dir/$profile"
  if [[ "$profile" == "assert" ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  make -B -C "$tb_home" \
    BUILD_DIR="$profile_dir/build" \
    RESULT_DIR="$profile_dir/result" \
    IVFLAGS="$flags" \
    TB_SRCS_tb_ooo_mem_owner_tracker="$tracker_tb $tracker_checker $tracker" \
    "$profile_dir/result/logs/$test_name.log"
}

run_positive assert
run_positive release

negative_cases=(
  alloc-pid-unknown
  release-mask-unknown
  live-map-unknown
  live-set-unknown
)
for case in "${negative_cases[@]}"; do
  case "$case" in
    alloc-pid-unknown)
      define="-DV11C_ALLOC_PID_UNKNOWN_NEGATIVE"
      ;;
    release-mask-unknown)
      define="-DV11C_RELEASE_MASK_UNKNOWN_NEGATIVE"
      ;;
    live-map-unknown)
      define="-DV11C_LIVE_MAP_UNKNOWN_NEGATIVE"
      ;;
    live-set-unknown)
      define="-DV11C_LIVE_SET_UNKNOWN_NEGATIVE"
      ;;
    *)
      fail "unknown negative case: $case"
      ;;
  esac
  case_dir="$evidence_dir/negative/$case"
  set +e
  make -B -C "$tb_home" \
    BUILD_DIR="$case_dir/build" \
    RESULT_DIR="$case_dir/result" \
    IVFLAGS="$base_flags $define" \
    TB_SRCS_tb_ooo_mem_owner_tracker="$tracker_tb $tracker_checker $tracker" \
    "$case_dir/result/logs/$test_name.log"
  negative_rc=$?
  set -e
  printf '%s\n' "$negative_rc" > "$case_dir/make.rc"
  [[ "$negative_rc" -ne 0 ]] ||
    fail "unknown identity/state case unexpectedly passed: $case"
done

mutation_cases=(
  live-mask-output-zero
  drop-live-birth
  drop-live-death
  wrong-producer-map-birth0
  drop-producer-live-birth
  wrong-producer-clear
  same-edge-exact-token-reuse
  same-edge-bulk-token-reuse
  allow-dual-duplicate-pid
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
    IVFLAGS="$base_flags -DV11C_DISABLE_SEMANTIC_CHECKER" \
    TB_SRCS_tb_ooo_mem_owner_tracker="$tracker_tb $tracker_checker $case_dir/OooMemOwnerTracker.v" \
    "$case_dir/result/logs/$test_name.log"
  mutation_rc=$?
  set -e
  printf '%s\n' "$mutation_rc" > "$case_dir/make.rc"
  [[ "$mutation_rc" -ne 0 ]] ||
    fail "semantic RTL variant unexpectedly passed: $case"
done

python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_memory_tracker_semantic_evidence \
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
  "[V11C-TRACKER-RUNNER][PASS] attempt=$attempt profiles=2 unknown=4 mutations=9/9"
