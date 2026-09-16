#!/usr/bin/env bash
# Vivado OOC 综合驱动：从 Makefile 取核 RTL 清单，调 vivado 批处理跑 synth.tcl(4 核)。
# 注：WSL 环境下 8 核综合会内存压力过大导致崩溃，已降到 4 核(synth.tcl maxThreads 4)。
# 用法: vivado/run-synth.sh [PERIOD_ns] [PART]
#   PERIOD 默认 2.0ns(激进,逼出关键路径)；PART 默认 xc7a100tcsg324-1(ysyx Nexys)。
# 产物落 vivado/out/<时间戳>/，不入 git(见 .gitignore)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64="$(cd "$HERE/.." && pwd)"
VIVADO="${VIVADO:-/home/lyg/AMD/2025.2/2025.2/Vivado/bin/vivado}"
PERIOD="${1:-2.0}"
PART="${2:-xc7a100tcsg324-1}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/out/$TS"
mkdir -p "$OUT"

# 从 Makefile 导出核 RTL 清单与 include 目录(单一真源,避免重复维护)
RTL=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_CORE_SRCS :?=' | head -1 | sed 's/^RTL_CORE_SRCS :\?= *//')
INCDIR=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_INCLUDE_DIR :?=' | head -1 | sed 's/^RTL_INCLUDE_DIR :\?= *//')
TOP=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_CORE_TOP :?=' | head -1 | sed 's/^RTL_CORE_TOP :\?= *//'); TOP="${TOP:-NpcTop}"
echo "$RTL" | tr ' ' '\n' | grep -E '\.v$' > "$OUT/filelist.txt"
echo "[run-synth] $(wc -l < "$OUT/filelist.txt") files, top=$TOP part=$PART period=${PERIOD}ns -> $OUT"

cd "$OUT"
# CPU 亲和性 + 降优先级：把 vivado 绑到 4 个核(默认 8-11)、nice -n 15，给系统/Claude/vscode/wsl
# 留出其余核，避免综合把整机占满导致 WSL 崩溃。可用 CPUSET/NICE 覆盖。
CPUSET="${CPUSET:-8-11}"; NICE="${NICE:-15}"
TASKSET=""; command -v taskset >/dev/null 2>&1 && TASKSET="taskset -c $CPUSET"
echo "[run-synth] affinity: nice -n $NICE $TASKSET (总核 $(nproc))"
FILELIST="$OUT/filelist.txt" INCDIR="$INCDIR" TOP="$TOP" PART="$PART" PERIOD="$PERIOD" OUTDIR="$OUT" \
  nice -n "$NICE" $TASKSET "$VIVADO" -mode batch -nojournal -log "$OUT/vivado.log" -source "$HERE/synth.tcl" 2>&1 | tail -5
echo "[run-synth] reports: $OUT/timing_summary.rpt, timing_paths.rpt, utilization.rpt"
# 摘要 WNS / 关键路径起讫
echo "=== WNS / 关键路径 ==="
grep -E 'WNS|Slack' "$OUT/timing_summary.rpt" 2>/dev/null | head -3
ln -sfn "$OUT" "$HERE/out/latest"
