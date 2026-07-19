#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
A="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/core-region-diagnostic/binaries/NpcSimTop-A-core-region"
B="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/core-region-diagnostic/binaries/NpcSimTop-B-core-region"
CANDIDATE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/candidate.patch"
PROBE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/core-region-diagnostic/core-region-probe.patch"
C="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r3p2-early-wake/core-region-diagnostic/binaries/NpcSimTop-C-core-region"
IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
ELF="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.elf"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p2-early-wake/region-abc/core-region-diagnostic/runs"

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

  timeout 1200 "$binary" "$IMAGE" --no-progress --max-cycles 20000000 > "$destination/coremark.raw.log" 2>&1
  test "$(grep -c 'HIT GOOD TRAP' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c 'exit via ebreak, code=0' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c 'Running CoreMark for 10 iterations' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c 'Iterations       : 10' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c 'seedcrc          : 0xe9f5' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c '\[0\]crclist       : 0xe714' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c '\[0\]crcmatrix     : 0x1fd7' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c '\[0\]crcstate      : 0x8e3a' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c '\[0\]crcfinal      : 0xfcaf' "$destination/coremark.raw.log")" -eq 1
  test "$(grep -c 'CoreMark PASS       5 Marks' "$destination/coremark.raw.log")" -eq 1
  ! grep -qE 'CoreMark FAIL|Errors detected|HIT BAD TRAP|region_probe.*ERROR' "$destination/coremark.raw.log"

  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$IMAGE" "$ELF" "$PROBE" "$CANDIDATE"
  } > "$destination/binding.post.sha256"
  cmp "$destination/binding.pre.sha256" "$destination/binding.post.sha256"

  grep -E 'region_probe.*(BOUNDARY|RESULT)|CoreMark Size|Iterations       |seedcrc|crclist|crcmatrix|crcstate|crcfinal|CoreMark PASS|CoreMark/MHz|HIT GOOD TRAP|exit via ebreak' "$destination/coremark.raw.log" > "$destination/semantic-and-whole.txt"
  printf '[CORE-REGION-ABC] %s %s ' "$ordinal" "$design"
  grep -oE 'exit via ebreak, code=0, cycles=[0-9]+, commits=[0-9]+' "$destination/coremark.raw.log"
}

run_one 01 A "$A"
run_one 02 B "$B"
run_one 03 C "$C"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > "$EVIDENCE/SHA256SUMS"
