#!/usr/bin/env bash
# 按模块 OOC 综合(内存安全,不崩 WSL)。用法: run-synth-module.sh <ModuleName> [PERIOD_ns] [PART]
# 只综合该模块子树→内存/时间骤降；用于定位单模块关键路径,做数据驱动时序优化。
# 默认绑核 8-11 + nice 15,2 线程(synth-module.tcl)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64="$(cd "$HERE/.." && pwd)"
VIVADO="${VIVADO:-/home/lyg/AMD/2025.2/2025.2/Vivado/bin/vivado}"
MOD="${1:?用法: run-synth-module.sh <ModuleName> [period] [part]}"
PERIOD="${2:-2.0}"; PART="${3:-xc7a100tcsg324-1}"
CPUSET="${CPUSET:-8-11}"; NICE="${NICE:-15}"
TS="$(date +%Y%m%d-%H%M%S)"; OUT="$HERE/out/mod-$MOD-$TS"; mkdir -p "$OUT"

RTL=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_CORE_SRCS :?=' | head -1 | sed 's/^RTL_CORE_SRCS :\?= *//')
INCDIR=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_INCLUDE_DIR :?=' | head -1 | sed 's/^RTL_INCLUDE_DIR :\?= *//')
echo "$RTL" | tr ' ' '\n' | grep -E '\.v$' > "$OUT/filelist.txt"
TASKSET=""; command -v taskset >/dev/null 2>&1 && TASKSET="taskset -c $CPUSET"
echo "[run-synth-module] $MOD period=${PERIOD}ns part=$PART affinity='nice -n $NICE $TASKSET' -> $OUT"
cd "$OUT"
FILELIST="$OUT/filelist.txt" INCDIR="$INCDIR" TOP="$MOD" PART="$PART" PERIOD="$PERIOD" OUTDIR="$OUT" \
  nice -n "$NICE" $TASKSET "$VIVADO" -mode batch -nojournal -log "$OUT/vivado.log" \
  -source "$HERE/synth-module.tcl" 2>&1 | tail -4
ln -sfn "$OUT" "$HERE/out/latest-mod"
echo "=== $MOD 最差路径(数据延迟) ==="
grep -E 'Data Path Delay|Slack' "$OUT/timing_paths.rpt" 2>/dev/null | head -4
