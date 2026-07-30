#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$run_dir" rev-parse --show-toplevel)"
tb_home="$repo_root/npc/rv64/testbench"
rtl="$repo_root/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v"
selector="$repo_root/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v"
tb="$repo_root/npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv"
snapshot_tool="$repo_root/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
evidence_tool="$repo_root/npc/rv64/eval/ppa/tools/int_iq_producer_semantic_evidence.py"
attempt="${V11F_INT_IQ_ATTEMPT:-1}"
evidence_dir="${V11F_INT_IQ_EVIDENCE_DIR_OVERRIDE:-$run_dir/evidence/int-iq-producer-attempt-$attempt}"
test_name="tb_ooo_int_issue_queue"
base_flags=(
  -g2012
  -Wall
  "-I$repo_root/npc/rv64/vsrc"
  "-I$repo_root/npc/rv64/vsrc/include"
  "-I$tb_home/common"
)
iverilog_bin="$(command -v iverilog)"
vvp_bin="$(dirname "$iverilog_bin")/vvp"
if [[ ! -x "$vvp_bin" ]]; then
  vvp_bin="$(command -v vvp)"
fi

fail() {
  printf '[V11F-INT-IQ-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ ! "$attempt" =~ ^[1-9][0-9]*$ ]]; then
  fail "V11F_INT_IQ_ATTEMPT must be a positive integer"
fi
if [[ -e "$evidence_dir" ]]; then
  fail "evidence directory already exists: ${evidence_dir#$repo_root/}"
fi
mkdir -p "$evidence_dir"

source_paths=(
  ".github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/run-int-iq-producer-focused.sh"
  "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v"
  "npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v"
  "npc/rv64/vsrc/include/define.v"
  "npc/rv64/vsrc/filelist.mk"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/common/tb_common.svh"
  "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv"
  "npc/rv64/eval/ppa/tools/int_iq_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tests/test_int_iq_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py"
  "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
  "npc/rv64/design/arch/producer-holder-census.json"
  "npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md"
  "npc/rv64/design/specs/ooo-int-issue-queue.md"
)

(
  cd "$repo_root"
  sha256sum "${source_paths[@]}"
) > "$evidence_dir/sources.pre.sha256"
python3 "$snapshot_tool" \
  --snapshot-out "$evidence_dir/rtl-source-binding.pre.json"
"$iverilog_bin" -V > "$evidence_dir/iverilog.version" 2>&1
"$vvp_bin" -V > "$evidence_dir/vvp.version" 2>&1

compile_image() {
  local run_path=$1
  local generation_width=$2
  local assertions=$3
  local rtl_source=$4
  local image="$run_path/build/$test_name.vvp"
  local flags=("${base_flags[@]}")
  local command
  mkdir -p "$run_path/build"
  if [[ "$assertions" == "on" ]]; then
    flags+=(-DOOO_ASSERT)
  fi
  flags+=("-DOOO_PRODUCER_GEN_W=$generation_width")
  command=(
    "$iverilog_bin"
    "${flags[@]}"
    -s "$test_name"
    -o "$image"
    "$tb"
    "$rtl_source"
    "$selector"
  )
  {
    printf '[V11F-COMPILE]'
    printf ' %q' "${command[@]}"
    printf '\n'
  } > "$run_path/compile.log"
  set +e
  "${command[@]}" >> "$run_path/compile.log" 2>&1
  local compile_rc=$?
  set -e
  printf '%s\n' "$compile_rc" > "$run_path/compile.rc"
  return "$compile_rc"
}

simulate_image() {
  local run_path=$1
  local image="$run_path/build/$test_name.vvp"
  set +e
  "$vvp_bin" "$image" +V11F_INT_IQ_PRODUCER_ONLY \
    > "$run_path/sim.log" 2>&1
  local sim_rc=$?
  set -e
  printf '%s\n' "$sim_rc" > "$run_path/sim.rc"
  return "$sim_rc"
}

run_positive() {
  local profile=$1
  local generation_width=$2
  local assertions=$3
  local profile_dir="$evidence_dir/profiles/$profile"
  mkdir -p "$profile_dir"
  compile_image "$profile_dir" "$generation_width" "$assertions" "$rtl" ||
    fail "positive profile did not compile: $profile"
  simulate_image "$profile_dir" ||
    fail "positive profile did not pass: $profile"
}

run_positive assert-g1 1 on
run_positive release-g1 1 off
run_positive assert-g4 4 on
run_positive release-g4 4 off

mutation_cases=(
  dispatch0-generation-zero
  dispatch1-uses-lane0-pid
  compaction-uses-write-index-pid
  compaction-generation-zero
  issue0-generation-zero
  issue1-generation-zero
  issue0-raw-index-entry0
  issue1-raw-index-issue0
  issue0-fire-not-removed
  issue1-fire-not-removed
  pair-pop-only-entry0
  kill-boundary-inclusive
  flush-ignored
  reset-ignored
  regular-fire-dies-early-mask
  pair-fire-dies-early-mask
  mask-raw-rob-index
  dispatch0-pid-x
  dispatch1-pid-x
  compaction-pid-x
)
for case in "${mutation_cases[@]}"; do
  case_dir="$evidence_dir/mutations/$case"
  mkdir -p "$case_dir"
  python3 "$evidence_tool" mutate \
    --case "$case" \
    --input "$rtl" \
    --output "$case_dir/OooIntIssueQueue.v" \
    --receipt "$case_dir/mutator.json" \
    > "$case_dir/mutator.log"
  for generation_width in 1 4; do
    mutation_dir="$case_dir/g$generation_width"
    mkdir -p "$mutation_dir"
    compile_image \
      "$mutation_dir" \
      "$generation_width" \
      off \
      "$case_dir/OooIntIssueQueue.v" ||
      fail "RTL variant did not compile: $case/g$generation_width"
    if simulate_image "$mutation_dir"; then
      fail "RTL variant unexpectedly passed: $case/g$generation_width"
    fi
    grep -q '\[V11F-INT-IQ-ORACLE\]\[FAIL\]' \
      "$mutation_dir/sim.log" ||
      fail "RTL variant lacked independent oracle marker: $case/g$generation_width"
  done
done

python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_int_iq_producer_semantic_evidence \
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
  "[V11F-INT-IQ-RUNNER][PASS] attempt=$attempt profiles=4 mutations=20x2"
