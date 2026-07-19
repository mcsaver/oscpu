#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
A="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2p5-icache/region-ab/binaries/NpcSimTop-A-R2p4-region"
B="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2p5-icache/region-ab/binaries/NpcSimTop-B-R2p5-region"
IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
ELF="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.elf"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r2p5-icache/region-ab/core-runs"

mkdir -p "$EVIDENCE"

run_one() {
  local ordinal="$1"
  local design="$2"
  local binary="$3"
  local destination="$EVIDENCE/${ordinal}-${design,,}"

  rm -rf "$destination"
  mkdir -p "$destination"
  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$IMAGE" "$ELF"
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
    sha256sum "$binary" "$IMAGE" "$ELF"
  } > "$destination/binding.post.sha256"
  cmp "$destination/binding.pre.sha256" "$destination/binding.post.sha256"

  grep -E 'region_probe.*(BOUNDARY|RESULT)|CoreMark Size|Iterations       |seedcrc|crclist|crcmatrix|crcstate|crcfinal|CoreMark PASS|CoreMark/MHz|HIT GOOD TRAP|exit via ebreak' "$destination/coremark.raw.log" > "$destination/semantic-and-whole.txt"
  printf '[CORE-AB] %s %s ' "$ordinal" "$design"
  grep -oE 'exit via ebreak, code=0, cycles=[0-9]+, commits=[0-9]+' "$destination/coremark.raw.log"
}

run_one ab1 A "$A"
run_one ab2 B "$B"
run_one ab3 B "$B"
run_one ab4 A "$A"
run_one ab5 A "$A"
run_one ab6 B "$B"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > "$EVIDENCE/SHA256SUMS"
