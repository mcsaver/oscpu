#!/usr/bin/env bash
# Build every current AM CPU test against this hart's full declared ISA.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
workspace=$(cd -- "$script_dir/../../../../.." && pwd)
out=$(realpath -m -- "${1:-$workspace/npc/rv64/build/chengyue64/am-source}")
mkdir -p "$out/recipes" "$out/images"
for src in "$workspace/am-kernels/tests/cpu-tests/tests/"*.c; do
  name=$(basename -- "$src" .c)
  cat > "$out/recipes/$name.mk" <<MAKE
NAME=$name
SRCS=tests/$name.c
include $workspace/abstract-machine/Makefile
COMMON_CFLAGS += -march=rv64imafdc_zicsr_zifencei_zba_zbb_zbc_zbs
MAKE
  AM_HOME="$workspace/abstract-machine" make -s -C "$workspace/am-kernels/tests/cpu-tests" -f "$out/recipes/$name.mk" ARCH=riscv64-npc AM_BUILD_ROOT="$out/objects" image
  cp -p -- "$out/objects/$name-riscv64-npc.bin" "$out/images/"
done
