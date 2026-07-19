#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
BIN="$ROOT/tmp/2026-07-15-rv64-ppa-architecture-recovery/build-r3p5-staged-rotate-v2/NpcSimTop"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p5-staged-rotate/performance"
CORE_IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
DHR_IMAGE="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.bin"

test -x "$BIN"
test -f "$CORE_IMAGE"
test -f "$DHR_IMAGE"
test ! -e "$EVIDENCE"
mkdir -p "$EVIDENCE"

binding() {
  sha256sum \
    "$BIN" \
    "$ROOT/npc/rv64/.config" \
    "$ROOT/npc/rv64/include/config/auto.conf" \
    "$ROOT/npc/rv64/include/generated/autoconf.h" \
    "$ROOT/npc/rv64/vsrc/execute/OooBitmanipGate.v" \
    "$ROOT/npc/rv64/vsrc/execute/OooIntBackend.v" \
    "$ROOT/npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v" \
    "$ROOT/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v" \
    "$ROOT/npc/rv64/csrc/cpu/cpu-exec.cpp"
}

run_one() {
  local workload="$1"
  local image="$2"
  local start_pc="$3"
  local end_pc="$4"
  local expected_start_hits="$5"
  local expected_retired="$6"
  local destination="$EVIDENCE/$workload"

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
  test "$(grep -c "region_probe.*retired=$expected_retired" "$destination/raw.log")" -eq 1
  ! grep -qE 'region_probe.*ERROR|HIT BAD TRAP|CoreMark FAIL|Errors detected' \
    "$destination/raw.log"

  if [[ $workload == coremark ]]; then
    test "$(grep -c 'Running CoreMark for 10 iterations' "$destination/raw.log")" -eq 1
    test "$(grep -c 'Iterations       : 10' "$destination/raw.log")" -eq 1
    test "$(grep -c 'seedcrc          : 0xe9f5' "$destination/raw.log")" -eq 1
    test "$(grep -c '\[0\]crclist       : 0xe714' "$destination/raw.log")" -eq 1
    test "$(grep -c '\[0\]crcmatrix     : 0x1fd7' "$destination/raw.log")" -eq 1
    test "$(grep -c '\[0\]crcstate      : 0x8e3a' "$destination/raw.log")" -eq 1
    test "$(grep -c '\[0\]crcfinal      : 0xfcaf' "$destination/raw.log")" -eq 1
    test "$(grep -c 'CoreMark PASS       5 Marks' "$destination/raw.log")" -eq 1
  else
    test "$(grep -c 'Trying 10000 runs through Dhrystone' "$destination/raw.log")" -eq 1
    test "$(grep -c 'Dhrystone PASS         1 Marks' "$destination/raw.log")" -eq 1
  fi

  grep -E 'region_probe.*(BOUNDARY|RESULT)|CoreMark Size|Iterations       |seedcrc|crclist|crcmatrix|crcstate|crcfinal|CoreMark PASS|Dhrystone PASS|HIT GOOD TRAP|exit via ebreak' \
    "$destination/raw.log" >"$destination/semantic-and-region.txt"
  grep -oE 'RESULT start_hits=[0-9]+ end_hits=[0-9]+ start_cycle=[0-9]+ end_cycle=[0-9]+ cycles=[0-9]+ start_retired=[0-9]+ end_retired=[0-9]+ retired=[0-9]+' \
    "$destination/raw.log"
}

run_one coremark "$CORE_IMAGE" 0x800017a8 0x800017b0 1 3183617
run_one dhrystone "$DHR_IMAGE" 0x80000334 0x8000047c 10000 4250000

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 \
  | LC_ALL=C sort -z | xargs -0 sha256sum >"$EVIDENCE/SHA256SUMS"
