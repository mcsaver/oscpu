#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
A="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r1-backend/binaries/NpcSimTop-A"
C="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/artifacts/ppa-r2-frontend/binaries/NpcSimTop-C"
EVIDENCE="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r2-frontend/benchmarks"
CORE_IMAGE="$ROOT/am-kernels/benchmarks/coremark/build/coremark-riscv64-npc.bin"
DHRY_IMAGE="$ROOT/am-kernels/benchmarks/dhrystone/build/dhrystone-riscv64-npc.bin"
MAX_CYCLES=20000000

mkdir -p "$EVIDENCE"

run_benchmark() {
  local binary="$1"
  local image="$2"
  local log="$3"

  timeout 1200 "$binary" "$image" --no-progress --max-cycles "$MAX_CYCLES" > "$log" 2>&1
  grep -q 'HIT GOOD TRAP' "$log"
  grep -q 'exit via ebreak, code=0' "$log"
}

run_one() {
  local ordinal="$1"
  local design="$2"
  local binary="$3"
  local destination="$EVIDENCE/${ordinal}-${design,,}"
  local core_cycles
  local core_commits
  local dhry_cycles
  local dhry_commits

  rm -rf "$destination"
  mkdir -p "$destination"

  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$CORE_IMAGE" "$DHRY_IMAGE"
  } > "$destination/binding.pre.sha256"

  run_benchmark "$binary" "$CORE_IMAGE" "$destination/coremark.raw.log"
  run_benchmark "$binary" "$DHRY_IMAGE" "$destination/dhrystone-10000.raw.log"

  core_cycles="$(grep -oE 'cycles=[0-9]+, commits=[0-9]+' "$destination/coremark.raw.log" |
                 tail -n1 | sed -E 's/cycles=([0-9]+), commits=([0-9]+)/\1/')"
  core_commits="$(grep -oE 'cycles=[0-9]+, commits=[0-9]+' "$destination/coremark.raw.log" |
                  tail -n1 | sed -E 's/cycles=([0-9]+), commits=([0-9]+)/\2/')"
  dhry_cycles="$(grep -oE 'cycles=[0-9]+, commits=[0-9]+' "$destination/dhrystone-10000.raw.log" |
                 tail -n1 | sed -E 's/cycles=([0-9]+), commits=([0-9]+)/\1/')"
  dhry_commits="$(grep -oE 'cycles=[0-9]+, commits=[0-9]+' "$destination/dhrystone-10000.raw.log" |
                  tail -n1 | sed -E 's/cycles=([0-9]+), commits=([0-9]+)/\2/')"

  {
    printf '# %s %s fixed-binary benchmark\n\n' "$ordinal" "$design"
    printf -- '- CoreMark: cycles=%s, retired=%s\n' "$core_cycles" "$core_commits"
    printf -- '- Dhrystone10000: cycles=%s, retired=%s\n' "$dhry_cycles" "$dhry_commits"
  } > "$destination/summary.md"

  {
    printf 'sequence=%s\n' "$ordinal"
    printf 'design=%s\n' "$design"
    sha256sum "$binary" "$CORE_IMAGE" "$DHRY_IMAGE"
  } > "$destination/binding.post.sha256"

  cmp "$destination/binding.pre.sha256" "$destination/binding.post.sha256"
  printf '[PPA-R2-BENCH] %s %s core=%s/%s dhry=%s/%s\n'     "$ordinal" "$design" "$core_cycles" "$core_commits" "$dhry_cycles" "$dhry_commits"
}

run_one ac1 A "$A"
run_one ac2 C "$C"
run_one ac3 C "$C"
run_one ac4 A "$A"
run_one ac5 A "$A"
run_one ac6 C "$C"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > "$EVIDENCE/SHA256SUMS"
