#!/bin/bash
# NPC CoreMark 基准跑分脚本
# 用法: ./perf/scripts/bench.sh [RUN_ARGS]
set -e

NPC_HOME="$(cd "$(dirname "$0")/../.." && pwd)"
AM_HOME="${AM_HOME:-$(cd "$NPC_HOME/../../abstract-machine" && pwd)}"
RESULTS_DIR="$NPC_HOME/perf/results/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo "=== NPC CoreMark Benchmark ==="
echo "NPC_HOME  = $NPC_HOME"
echo "AM_HOME   = $AM_HOME"
echo "Results   = $RESULTS_DIR"
echo ""

# 构建 CoreMark 镜像
echo "[1/3] Building CoreMark image..."
AM_HOME="$AM_HOME" make -C "$NPC_HOME/../../am-kernels/benchmarks/coremark" \
  ARCH=riscv32-npc image 2>&1 | tail -3

IMG="$NPC_HOME/../../am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.bin"
if [ ! -f "$IMG" ]; then
  echo "ERROR: CoreMark image not found at $IMG"
  exit 1
fi

# 运行
echo "[2/3] Running CoreMark..."
EXTRA_ARGS="${1:---max-cycles 0 --no-progress}"
"$NPC_HOME/build/NpcSimTop" "$IMG" $EXTRA_ARGS 2>&1 | tee "$RESULTS_DIR/coremark.log"

# 提取关键指标
echo ""
echo "[3/3] Summary:"
grep -E "simulation frequency|total guest instructions|host time spent|CoreMark" \
  "$RESULTS_DIR/coremark.log" | tee "$RESULTS_DIR/summary.txt"

echo ""
echo "Full log: $RESULTS_DIR/coremark.log"
