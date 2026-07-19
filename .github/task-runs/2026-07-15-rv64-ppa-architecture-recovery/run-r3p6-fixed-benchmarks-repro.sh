#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
BIN="$ROOT/tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r3p6-onehot-prf/NpcSimTop"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p6-onehot-prf/performance-repro"
CORE_IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
DHR_IMAGE="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.bin"

test -x "$BIN"
test -f "$CORE_IMAGE"
test -f "$DHR_IMAGE"

binding() {
  sha256sum \
    "$BIN" \
    "$ROOT/npc/rv64/.config" \
    "$ROOT/npc/rv64/include/config/auto.conf" \
    "$ROOT/npc/rv64/include/generated/autoconf.h" \
    "$ROOT/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v" \
    "$ROOT/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v" \
    "$ROOT/npc/rv64/vsrc/execute/OooIntBackend.v" \
    "$ROOT/npc/rv64/csrc/cpu/cpu-exec.cpp"
}

run_one() {
  local repetition="$1"
  local workload="$2"
  local image="$3"
  local start_pc="$4"
  local end_pc="$5"
  local expected_start_hits="$6"
  local expected_retired="$7"
  local expected_cycles="$8"
  local destination="$EVIDENCE/$repetition/$workload"

  test ! -e "$destination"
  mkdir -p "$destination"
  binding >"$destination/binding.pre.sha256"
  NPC_REGION_START_PC="$start_pc" NPC_REGION_END_PC="$end_pc" \
    timeout 1200 "$BIN" "$image" --no-progress --max-cycles 20000000 \
    >"$destination/raw.log" 2>&1
  binding >"$destination/binding.post.sha256"
  cmp "$destination/binding.pre.sha256" "$destination/binding.post.sha256"

  test "$(grep -c 'HIT GOOD TRAP' "$destination/raw.log")" -eq 1
  test "$(grep -c 'exit via ebreak, code=0' "$destination/raw.log")" -eq 1
  test "$(grep -c 'region_probe.*BOUNDARY kind=start' "$destination/raw.log")" -eq 1
  test "$(grep -c 'region_probe.*BOUNDARY kind=end' "$destination/raw.log")" -eq 1
  test "$(grep -c "region_probe.*RESULT start_hits=$expected_start_hits end_hits=1" "$destination/raw.log")" -eq 1
  test "$(grep -c "region_probe.*cycles=$expected_cycles .*retired=$expected_retired" "$destination/raw.log")" -eq 1
  ! grep -qE 'region_probe.*ERROR|HIT BAD TRAP|CoreMark FAIL|Errors detected' \
    "$destination/raw.log"

  if [[ $workload == coremark ]]; then
    test "$(grep -c 'Iterations       : 10' "$destination/raw.log")" -eq 1
    test "$(grep -c '\[0\]crcfinal      : 0xfcaf' "$destination/raw.log")" -eq 1
    test "$(grep -c 'CoreMark PASS       5 Marks' "$destination/raw.log")" -eq 1
  else
    test "$(grep -c 'Trying 10000 runs through Dhrystone' "$destination/raw.log")" -eq 1
    test "$(grep -c 'Dhrystone PASS         1 Marks' "$destination/raw.log")" -eq 1
  fi

  grep -E 'region_probe.*(BOUNDARY|RESULT)|Iterations       |crcfinal|CoreMark PASS|Dhrystone PASS|HIT GOOD TRAP|exit via ebreak' \
    "$destination/raw.log" >"$destination/semantic-and-region.txt"
  grep -oE 'RESULT start_hits=[0-9]+ end_hits=[0-9]+ start_cycle=[0-9]+ end_cycle=[0-9]+ cycles=[0-9]+ start_retired=[0-9]+ end_retired=[0-9]+ retired=[0-9]+' \
    "$destination/raw.log"
}

mkdir -p "$EVIDENCE"
for repetition in rep02 rep03; do
  run_one "$repetition" coremark "$CORE_IMAGE" 0x800017a8 0x800017b0 1 3183617 4904511
  run_one "$repetition" dhrystone "$DHR_IMAGE" 0x80000334 0x8000047c 10000 4250000 9481620
done

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 \
  | LC_ALL=C sort -z | xargs -0 sha256sum >"$EVIDENCE/SHA256SUMS"

