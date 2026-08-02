#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$run_dir" rev-parse --show-toplevel)"
tb_home="$repo_root/npc/rv64/testbench"
collector="$repo_root/npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
snapshot_tool="$repo_root/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
lane_tool="$repo_root/npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py"
mutator="$run_dir/mutate-terminal-collector.py"
builder="$run_dir/build-terminal-collector-evidence.py"
attempt="${V11B_TCOLL_ATTEMPT:-1}"
evidence_dir="${V11B_TCOLL_EVIDENCE_DIR_OVERRIDE:-$run_dir/evidence/terminal-collector-attempt-$attempt}"
compact_images="${V11B_TCOLL_COMPACT_IMAGES:-0}"
base_flags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"

fail() {
  printf '[V11B-TCOLL-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ ! "$attempt" =~ ^[1-9][0-9]*$ ]]; then
  fail "V11B_TCOLL_ATTEMPT must be a positive integer"
fi
if [[ "$compact_images" != "0" && "$compact_images" != "1" ]]; then
  fail "V11B_TCOLL_COMPACT_IMAGES must be 0 or 1"
fi
if [[ -e "$evidence_dir" ]]; then
  fail "evidence directory already exists: ${evidence_dir#$repo_root/}"
fi
mkdir -p "$evidence_dir"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/v11b-tcoll.XXXXXX")"
cleanup() {
  if [[ -d "$temp_dir" &&
        "$temp_dir" == "${TMPDIR:-/tmp}"/v11b-tcoll.* ]]; then
    rm -rf -- "$temp_dir"
  fi
}
trap cleanup EXIT

source_paths=(
  ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/run-terminal-collector-focused.sh"
  ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/mutate-terminal-collector.py"
  ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/build-terminal-collector-evidence.py"
  "npc/rv64/vsrc/execute/OooIntBackend.v"
  "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/scripts/check_tb_result.py"
  "npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv"
  "npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py"
  "npc/rv64/eval/ppa/tests/test_terminal_collector_lane_contract.py"
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
    "$profile_dir/result/logs/tb_ooo_mem_owner_terminal_collector.log"
}

run_positive assert
run_positive release

unknown_dir="$evidence_dir/unknown-negative"
set +e
make -B -C "$tb_home" \
  BUILD_DIR="$unknown_dir/build" \
  RESULT_DIR="$unknown_dir/result" \
  IVFLAGS="$base_flags -DOOO_ASSERT -DV11B_TCOLL_UNKNOWN_NEGATIVE" \
  "$unknown_dir/result/logs/tb_ooo_mem_owner_terminal_collector.log"
unknown_rc=$?
set -e
printf '%s\n' "$unknown_rc" > "$unknown_dir/make.rc"
[[ "$unknown_rc" -ne 0 ]] ||
  fail "unknown valid ingress unexpectedly passed"

mutation_cases=(
  drop-ingress-known-assertion
  lane1-reuses-lane0-grant
  same-edge-accept-cut
)
for case in "${mutation_cases[@]}"; do
  case_dir="$evidence_dir/mutations/$case"
  mkdir -p "$case_dir"
  python3 "$mutator" \
    --case "$case" \
    --input "$collector" \
    --output "$case_dir/OooMemOwnerTerminalCollector.v" \
    --receipt "$case_dir/mutator.json" \
    > "$case_dir/mutator.log"
  flags="$base_flags -DOOO_ASSERT"
  if [[ "$case" == "drop-ingress-known-assertion" ]]; then
    flags="$flags -DV11B_TCOLL_UNKNOWN_NEGATIVE"
  fi
  set +e
  make -B -C "$tb_home" \
    BUILD_DIR="$case_dir/build" \
    RESULT_DIR="$case_dir/result" \
    IVFLAGS="$flags" \
    RTL_OOO_MEM_OWNER_TERMINAL_COLLECTOR="$case_dir/OooMemOwnerTerminalCollector.v" \
    "$case_dir/result/logs/tb_ooo_mem_owner_terminal_collector.log"
  mutation_rc=$?
  set -e
  printf '%s\n' "$mutation_rc" > "$case_dir/make.rc"
  [[ "$mutation_rc" -ne 0 ]] ||
    fail "semantic mutation unexpectedly passed: $case"
done

python3 "$lane_tool" build \
  --output "$evidence_dir/terminal-collector-lane-contract.json"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_terminal_collector_lane_contract \
  > "$evidence_dir/lane-contract-unit.log" 2>&1

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

builder_args=(
  --root "$repo_root"
  --evidence-dir "$evidence_dir"
  --output "$evidence_dir/summary.json"
)
if [[ "$compact_images" == "1" ]]; then
  builder_args+=(--compact-images)
fi
python3 "$builder" "${builder_args[@]}"

if [[ "$compact_images" == "1" ]]; then
  rm -rf -- \
    "$evidence_dir/assert/build" \
    "$evidence_dir/release/build" \
    "$evidence_dir/unknown-negative/build"
  for case in "${mutation_cases[@]}"; do
    rm -rf -- "$evidence_dir/mutations/$case/build"
  done
  if find "$evidence_dir" -type f -name '*.vvp' -print -quit | grep -q .; then
    fail "compact evidence retained a compiled image"
  fi
fi
printf '%s\n' \
  "[V11B-TCOLL-RUNNER][PASS] attempt=$attempt ingress=12 free=2 profiles=2 mutations=3/3 retained_vvp=$((compact_images == 1 ? 0 : 6))"
