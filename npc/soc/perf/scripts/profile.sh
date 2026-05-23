#!/bin/bash
# NPC callgrind 热点分析脚本
# 用法: ./perf/scripts/profile.sh [程序镜像]
set -e

NPC_HOME="$(cd "$(dirname "$0")/../.." && pwd)"
AM_HOME="${AM_HOME:-$(cd "$NPC_HOME/../../abstract-machine" && pwd)}"
RESULTS_DIR="$NPC_HOME/perf/results/$(date +%Y%m%d-%H%M%S)-callgrind"
mkdir -p "$RESULTS_DIR"

# 默认用 cpu-tests 的 add 做短程序分析（callgrind 很慢，不适合长程序）
if [ -n "$1" ]; then
  IMG="$1"
else
  AM_HOME="$AM_HOME" make -C "$NPC_HOME/../../am-kernels/tests/cpu-tests" \
    ARCH=riscv32-npc ALL=add image 2>&1 | tail -3
  IMG="$NPC_HOME/../../am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin"
fi

echo "=== NPC Callgrind Profile ==="
echo "Image     = $IMG"
echo "Results   = $RESULTS_DIR"
echo ""

# 运行 callgrind
echo "[1/2] Running callgrind (this is slow, ~20-40x)..."
valgrind --tool=callgrind \
  --callgrind-out-file="$RESULTS_DIR/callgrind.out" \
  "$NPC_HOME/build/NpcSimTop" "$IMG" --max-cycles 200000 2>&1 \
  | tee "$RESULTS_DIR/callgrind-run.log"

# 输出热点
echo ""
echo "[2/2] Top functions by instruction cost:"
callgrind_annotate --auto=yes "$RESULTS_DIR/callgrind.out" 2>&1 \
  | head -80 | tee "$RESULTS_DIR/callgrind-annotate.txt"

echo ""
echo "Full results: $RESULTS_DIR/"
echo "Use 'callgrind_annotate $RESULTS_DIR/callgrind.out' for details"
