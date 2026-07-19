#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
A="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2p5-icache/region-ab/binaries/NpcSimTop-B-R2p5-region"
B="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/binaries/NpcSimTop-R3p1-region"
CANDIDATE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/candidate.patch"
PROBE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2p5-icache/region-ab/region-probe.patch"
C="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/binaries/NpcSimTop-R3p2-region"
IMAGE="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.bin"
ELF="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.elf"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p2-early-wake/region-abc/dhr-runs"

mkdir -p "$EVIDENCE"

run_one() {
  local ordinal="$1"
  local design="$2"
  local binary="$3"
  local destination="$EVIDENCE/${ordinal}-${design,,}"

  test ! -e "$destination"
  mkdir -p "$destination"
  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$IMAGE" "$ELF" "$PROBE" "$CANDIDATE"
  } > "$destination/binding.pre.sha256"

  timeout 1200 "$binary" "$IMAGE" --no-progress --max-cycles 20000000 > "$destination/dhrystone-10000.raw.log" 2>&1
  test "$(grep -c 'HIT GOOD TRAP' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'exit via ebreak, code=0' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'Trying 10000 runs through Dhrystone' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'Dhrystone PASS         1 Marks' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'region_probe.*BOUNDARY kind=start' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'region_probe.*BOUNDARY kind=end' "$destination/dhrystone-10000.raw.log")" -eq 1
  test "$(grep -c 'region_probe.*RESULT start_hits=10000 end_hits=1' "$destination/dhrystone-10000.raw.log")" -eq 1
  ! grep -q 'region_probe.*ERROR' "$destination/dhrystone-10000.raw.log"

  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$IMAGE" "$ELF" "$PROBE" "$CANDIDATE"
  } > "$destination/binding.post.sha256"
  cmp "$destination/binding.pre.sha256" "$destination/binding.post.sha256"

  grep -E 'region_probe.*(BOUNDARY|RESULT)|Finished in|Dhrystone PASS|HIT GOOD TRAP|exit via ebreak' "$destination/dhrystone-10000.raw.log" > "$destination/semantic-and-region.txt"
  printf '[DHR-ABC] %s %s ' "$ordinal" "$design"
  grep -oE 'RESULT start_hits=[0-9]+ end_hits=[0-9]+ start_cycle=[0-9]+ end_cycle=[0-9]+ cycles=[0-9]+ start_retired=[0-9]+ end_retired=[0-9]+ retired=[0-9]+' "$destination/dhrystone-10000.raw.log"
}

run_one 01 A "$A"
run_one 02 B "$B"
run_one 03 C "$C"
run_one 04 C "$C"
run_one 05 B "$B"
run_one 06 A "$A"
run_one 07 C "$C"
run_one 08 A "$A"
run_one 09 B "$B"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > "$EVIDENCE/SHA256SUMS"
