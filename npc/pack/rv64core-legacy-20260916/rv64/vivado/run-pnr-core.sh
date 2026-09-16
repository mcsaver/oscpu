#!/usr/bin/env bash
# 整核 P&R 驱动(内存看门狗护航,绝不崩 WSL)。取【真实布线后】WNS→判 dispatch 流水化净收益。
# 用法: run-pnr-core.sh [PERIOD_ns] [PART]   PERIOD 默认 8.0ns(给整核留余量,非逼极限)
#
# ⚠️ 实测结论(2026-06-28):本 15.7GB WSL 上**不可行**。整核 synth 阶段 Vivado 会自动 spawn 多个
#    `vivado -notrace` 并行综合 worker 进程(各 ~3.2GB),`maxThreads` 只限进程内线程、不限 worker
#    进程数,总 RSS ~11.4GB → free 跌到 167MB、avail 紧贴看门狗 floor,OOM/崩溃风险。已主动终止。
#    → 整核 P&R 需更大内存机器(≥32GB)或先 disable 并行综合;此 WSL 改用模块级 OOC 做时序决策
#      (run-synth-module.sh,单模块内存安全)。详见 .github/memory/known-issues.md。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64="$(cd "$HERE/.." && pwd)"
VIVADO="${VIVADO:-/home/lyg/AMD/2025.2/2025.2/Vivado/bin/vivado}"
PERIOD="${1:-8.0}"; PART="${2:-xc7a100tcsg324-1}"
CPUSET="${CPUSET:-8-11}"; NICE="${NICE:-15}"; MEM_FLOOR_MB="${MEM_FLOOR_MB:-3000}"
TS="$(date +%Y%m%d-%H%M%S)"; OUT="$HERE/out/pnr-$TS"; mkdir -p "$OUT"

RTL=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_CORE_SRCS :?=' | head -1 | sed 's/^RTL_CORE_SRCS :\?= *//')
INCDIR=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_INCLUDE_DIR :?=' | head -1 | sed 's/^RTL_INCLUDE_DIR :\?= *//')
TOP=$(make -C "$NPC_RV64" -p 2>/dev/null | grep -E '^RTL_CORE_TOP :?=' | head -1 | sed 's/^RTL_CORE_TOP :\?= *//'); TOP="${TOP:-NpcTop}"
echo "$RTL" | tr ' ' '\n' | grep -E '\.v$' > "$OUT/filelist.txt"
TASKSET=""; command -v taskset >/dev/null 2>&1 && TASKSET="taskset -c $CPUSET"
echo "[run-pnr-core] top=$TOP $(wc -l < "$OUT/filelist.txt") files period=${PERIOD}ns affinity='nice -n $NICE $TASKSET' mem_floor=${MEM_FLOOR_MB}MB -> $OUT"
cd "$OUT"
FILELIST="$OUT/filelist.txt" INCDIR="$INCDIR" TOP="$TOP" PART="$PART" PERIOD="$PERIOD" OUTDIR="$OUT" \
  nice -n "$NICE" $TASKSET "$VIVADO" -mode batch -nojournal -log "$OUT/vivado.log" \
  -source "$HERE/pnr-core.tcl" > "$OUT/stdout.log" 2>&1 &
VPID=$!
( while kill -0 "$VPID" 2>/dev/null; do
    avail=$(free -m | awk '/Mem:/{print $7}')
    if [ "${avail:-99999}" -lt "$MEM_FLOOR_MB" ]; then
      echo "[watchdog] avail ${avail}MB < ${MEM_FLOOR_MB}MB —— 杀 vivado 保护 WSL" | tee -a "$OUT/stdout.log"
      for p in $(ps aux | grep -E 'AMD/2025' | grep -v grep | awk '{print $2}'); do kill -9 "$p" 2>/dev/null; done
      echo "WATCHDOG_KILLED" > "$OUT/RESULT"; break
    fi
    sleep 3
  done ) & WDPID=$!
wait "$VPID" 2>/dev/null
kill "$WDPID" 2>/dev/null
[ -f "$OUT/RESULT" ] || echo "VIVADO_EXITED" > "$OUT/RESULT"
tail -6 "$OUT/stdout.log"
ln -sfn "$OUT" "$HERE/out/latest-pnr"
echo "=== 整核布线后 WNS ==="
grep -E 'WNS|Worst Slack|Slack' "$OUT/timing_routed.rpt" 2>/dev/null | head -4 || echo "(无 routed 报告:可能被看门狗中止或 P&R 未完成)"
