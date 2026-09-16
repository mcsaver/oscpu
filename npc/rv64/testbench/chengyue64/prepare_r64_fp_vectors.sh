#!/usr/bin/env bash
# Isolated RISCV specialization: never replace the workspace default SoftFloat.
set -euo pipefail
if [[ $# != 1 ]]; then echo "usage: $0 OUTPUT_DIRECTORY" >&2; exit 2; fi
repo=$(cd -- "$(dirname -- "$0")/../../../.." && pwd)
out=$(mkdir -p -- "$1" && cd -- "$1" && pwd)
sf="$repo/tool/softfloat"
mkdir -p "$out/softfloat-riscv"
cp "$sf/build/Linux-x86_64-GCC/platform.h" "$out/softfloat-riscv/platform.h"
make -s -C "$out/softfloat-riscv" -f "$sf/build/Linux-x86_64-GCC/Makefile" \
  SOURCE_DIR="$sf/source" SPECIALIZE_TYPE=RISCV -j4
gcc -O2 -DSOFTFLOAT_FAST_INT64 -I "$sf/source/include" \
  "$repo/npc/rv64/testbench/chengyue64/generate_r64_fp_vectors.c" \
  "$out/softfloat-riscv/softfloat.a" -o "$out/fp-vectors"
"$out/fp-vectors" > "$out/fp-round-vectors.txt"
"$out/fp-vectors" fma > "$out/fp-fma-vectors.txt"
"$out/fp-vectors" long > "$out/fp-long-vectors.txt"
"$out/fp-vectors" convert > "$out/fp-fast-vectors.txt"
