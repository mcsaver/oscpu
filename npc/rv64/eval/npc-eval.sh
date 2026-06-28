#!/usr/bin/env bash
# =============================================================================
# npc-eval.sh — RV64 OoO 核统一评估系统
# -----------------------------------------------------------------------------
# 目标：把"正确性 gate + 性能画像"固化为一条可复用、可对比、可追溯的命令，
#       作为每轮优化迭代后的"深度再评估"入口。详见 eval/README.md。
#
# 用法：
#   eval/npc-eval.sh [--build] [--module] [--riscv] [--am] [--bench]
#                    [--all] [--quick] [--tag NAME] [--max-cycles N]
#
#   --build   先重建 NPC（默认复用现有 build/NpcSimTop）
#   --module  跑模块 testbench 回归（iverilog，112 项）
#   --riscv   跑官方 riscv-tests（默认 + 特权）
#   --am      跑 AM cpu-tests 全量并采集每测试 cycles/commits/CPI
#   --bench   跑 CoreMark/Dhrystone（长，需较大 max-cycles）
#   --all     = --module --riscv --am
#   --quick   仅 --am（最快的性能回归）
#   --tag     给本次结果打标签（写进结果目录名，便于对比）
#   --max-cycles  AM/bench 单测试周期上限（默认 4000000）
#
# 产物：eval/results/<时间戳>-<tag>/
#   summary.md       人读汇总（gate 状态 + CPI 表 + 三类样本 + top 贡献 + 对比上一次）
#   am-cpi.tsv       AM 每测试 cycles/commits/cpi
#   riscv.log        riscv-tests 原始日志
#   module.log       模块 TB 原始日志
#   meta.txt         运行环境/时间/git 状态
# =============================================================================
set -uo pipefail

EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64="$(cd "$EVAL_DIR/.." && pwd)"
ROOT="$(cd "$NPC_RV64/../.." && pwd)"
AM_HOME="$ROOT/abstract-machine"
BIN="$NPC_RV64/build/NpcSimTop"
RISCV_DIR="$NPC_RV64/testsuites/core-tests/src/riscv-tests"
CPUT="$ROOT/am-kernels/tests/cpu-tests"
NM="$(command -v riscv64-unknown-elf-nm || echo riscv64-unknown-elf-nm)"
OC="$(command -v riscv64-unknown-elf-objcopy || echo riscv64-unknown-elf-objcopy)"

DO_BUILD=0 DO_MODULE=0 DO_RISCV=0 DO_AM=0 DO_BENCH=0
TAG="" MAXCYC=4000000
while [[ $# -gt 0 ]]; do case "$1" in
  --build) DO_BUILD=1;; --module) DO_MODULE=1;; --riscv) DO_RISCV=1;;
  --am) DO_AM=1;; --bench) DO_BENCH=1;;
  --all) DO_MODULE=1; DO_RISCV=1; DO_AM=1;;
  --quick) DO_AM=1;;
  --tag) shift; TAG="$1";; --max-cycles) shift; MAXCYC="$1";;
  *) echo "unknown arg: $1"; exit 2;;
esac; shift; done
[[ $DO_MODULE -eq 0 && $DO_RISCV -eq 0 && $DO_AM -eq 0 && $DO_BENCH -eq 0 ]] && { DO_MODULE=1; DO_RISCV=1; DO_AM=1; }

TS="$(date +%Y%m%d-%H%M%S)"
OUT="$EVAL_DIR/results/${TS}${TAG:+-$TAG}"
mkdir -p "$OUT"
SUM="$OUT/summary.md"

log(){ echo "[npc-eval] $*"; }
{
  echo "time: $TS"; echo "tag: ${TAG:-none}"; echo "max_cycles: $MAXCYC"
  echo "git_head: $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)"
  echo "git_dirty_npc: $(git -C "$ROOT" status --porcelain -- npc/rv64/vsrc | wc -l) changed vsrc files"
} > "$OUT/meta.txt"

echo "# NPC RV64 评估报告 — $TS ${TAG:+($TAG)}" > "$SUM"
echo "" >> "$SUM"

# ---- build ----
if [[ $DO_BUILD -eq 1 ]]; then
  log "building NPC ..."
  if make -C "$NPC_RV64" -j4 default > "$OUT/build.log" 2>&1; then
    echo "- **build**: OK" >> "$SUM"
  else
    echo "- **build**: FAIL (见 build.log)" >> "$SUM"; log "build FAILED"; exit 1
  fi
fi
[[ -x "$BIN" ]] || { log "no binary $BIN (用 --build)"; echo "- **build**: 缺二进制" >> "$SUM"; }

# ---- module TB ----
if [[ $DO_MODULE -eq 1 ]]; then
  log "module testbench regression ..."
  ( cd "$NPC_RV64/testbench" && make run ) > "$OUT/module.log" 2>&1
  mtot=$(grep -oE 'total: [0-9]+' "$OUT/module.log" | grep -oE '[0-9]+' | tail -1)
  mpass=$(grep -oE 'passed: [0-9]+' "$OUT/module.log" | grep -oE '[0-9]+' | tail -1)
  mfail=$(grep -oE 'failed: [0-9]+' "$OUT/module.log" | grep -oE '[0-9]+' | tail -1)
  echo "- **module TB**: ${mpass:-?}/${mtot:-?} PASS, ${mfail:-?} FAIL" >> "$SUM"
fi

# ---- riscv-tests ----
if [[ $DO_RISCV -eq 1 ]]; then
  log "riscv-tests (default + privileged) ..."
  NPC_HOME="$NPC_RV64" bash "$NPC_RV64/testsuites/scripts/npc-rv64-core-regress.sh" \
      --riscv-tests-dir "$RISCV_DIR" --riscv-privileged \
      --skip-module --skip-lint --skip-build --skip-am > "$OUT/riscv.log" 2>&1
  rp=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/riscv.log" | grep -cE '  PASS ')
  rf=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/riscv.log" | grep -cE '  FAIL ')
  echo "- **riscv-tests**: $rp PASS, $rf FAIL" >> "$SUM"
  [[ "$rf" -gt 0 ]] && sed 's/\x1b\[[0-9;]*m//g' "$OUT/riscv.log" | grep -E '  FAIL ' >> "$OUT/riscv-fails.txt"
fi

# ---- AM cpu-tests + CPI ----
if [[ $DO_AM -eq 1 ]]; then
  # 评估自校验(评估评估)：先跑已知必过的 dummy。若它都不 GOOD TRAP，说明评估环境
  # 异常(如与其它 sim 并发争用 npc/sim、二进制损坏)，此时任何 CPI 数字都不可信，
  # 直接中止报错，避免输出 0/56 这类误导性"结论"。
  log "self-check: dummy smoke ..."
  timeout 120 make -C "$CPUT" AM_HOME="$AM_HOME" ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 \
        ALL=dummy run NPC_RUN_ARGS="--no-progress --max-cycles 100000" > "$OUT/selfcheck.log" 2>&1
  if ! grep -q 'HIT GOOD TRAP' "$OUT/selfcheck.log"; then
    echo "- **AM cpu-tests**: 评估环境自校验失败(dummy 未 GOOD TRAP)——结果不可信，已中止。" >> "$SUM"
    echo "  常见原因：与其它 sim 并发争用 npc/sim 构建；先确保独占运行(无后台 sim)。" >> "$SUM"
    log "SELF-CHECK FAILED — aborting AM phase (环境异常,勿信结果)"; cat "$SUM"; exit 3
  fi
  log "AM cpu-tests + CPI (max-cycles=$MAXCYC) ..."
  TSV="$OUT/am-cpi.tsv"
  printf 'test\tresult\tcycles\tcommits\tcpi\n' > "$TSV"
  for t in $(ls "$CPUT"/tests/*.c | xargs -n1 basename | sed 's/\.c$//' | sort); do
    out=$(timeout 600 make -C "$CPUT" AM_HOME="$AM_HOME" ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 \
            ALL="$t" run NPC_RUN_ARGS="--no-progress --max-cycles $MAXCYC" 2>&1)
    res=FAIL; echo "$out" | grep -q 'HIT GOOD TRAP' && res=PASS
    line=$(echo "$out" | grep -oE 'cycles=[0-9]+, commits=[0-9]+' | tail -1)
    cyc=$(echo "$line" | grep -oE 'cycles=[0-9]+' | grep -oE '[0-9]+')
    com=$(echo "$line" | grep -oE 'commits=[0-9]+' | grep -oE '[0-9]+')
    cpi=$(echo "$out" | grep -oE 'CPI \(cycles/instruction\) = [0-9.]+' | grep -oE '[0-9.]+$' | tail -1)
    printf '%s\t%s\t%s\t%s\t%s\n' "$t" "$res" "${cyc:-NA}" "${com:-NA}" "${cpi:-NA}" >> "$TSV"
  done
  # 汇总
  pass=$(awk -F'\t' 'NR>1&&$2=="PASS"' "$TSV" | wc -l)
  fail=$(awk -F'\t' 'NR>1&&$2=="FAIL"' "$TSV" | wc -l)
  read wcpi wcyc wcom < <(awk -F'\t' 'NR>1&&$2=="PASS"&&$3!="NA"{c+=$3;m+=$4} END{if(m>0)printf "%.4f %d %d",c/m,c,m; else printf "NA 0 0"}' "$TSV")
  echo "- **AM cpu-tests**: $pass PASS, $fail FAIL" >> "$SUM"
  echo "- **加权 CPI (PASS 子集, 含 PMP)**: \`$wcpi\`  (cycles=$wcyc commits=$wcom)" >> "$SUM"
  [[ "$fail" -gt 0 ]] && { echo "  - 失败: $(awk -F'\t' 'NR>1&&$2=="FAIL"{printf "%s ",$1}' "$TSV")" >> "$SUM"; }
  {
    echo ""; echo "### 三类代表样本 + Top cycles 贡献"; echo ""
    echo '```'
    echo "[highest CPI]"; awk -F'\t' 'NR>1&&$5!="NA"&&$5+0>0{printf "  %-20s cpi=%-7s cyc=%s\n",$1,$5,$3}' "$TSV" | sort -t= -k2 -rn | head -3
    echo "[lowest CPI]";  awk -F'\t' 'NR>1&&$5!="NA"&&$5+0>0{printf "  %-20s cpi=%-7s cyc=%s\n",$1,$5,$3}' "$TSV" | sort -t= -k2 -n | head -3
    echo "[top cycles 贡献]"; awk -F'\t' 'NR>1&&$3!="NA"{printf "  %-20s cyc=%-9s cpi=%s\n",$1,$3,$5}' "$TSV" | sort -t= -k2 -rn | head -6
    echo '```'
  } >> "$SUM"
  # 与上一次结果对比加权 CPI
  prev=$(ls -dt "$EVAL_DIR"/results/*/ 2>/dev/null | grep -v "$OUT" | head -1)
  if [[ -n "$prev" && -f "$prev/am-cpi.tsv" ]]; then
    pcpi=$(awk -F'\t' 'NR>1&&$2=="PASS"&&$3!="NA"{c+=$3;m+=$4} END{if(m)printf "%.4f",c/m}' "$prev/am-cpi.tsv")
    echo "" >> "$SUM"
    echo "- **对比上次** ($(basename "$prev")): 加权 CPI $pcpi → $wcpi $(awk -v a="$pcpi" -v b="$wcpi" 'BEGIN{if(a>0)printf "(%.1f%%)",100*(b-a)/a}')" >> "$SUM"
    # 第 2 层自校验(评估的评估):逐测试 CPI 与上次对比,|Δ|>20% 即标红——同时抓性能回归与评估异常。
    flags=$(awk -F'\t' '
      NR==FNR{ if(FNR>1 && $5!="NA") prev[$1]=$5; next }
      FNR>1 && $5!="NA" && ($1 in prev) && prev[$1]+0>0 {
        d=100*($5-prev[$1])/prev[$1]; if(d<0)d=-d;
        if(d>20) printf "  - ⚠ %s: cpi %.3f→%.3f (%.0f%%)\n",$1,prev[$1],$5,100*($5-prev[$1])/prev[$1]
      }' "$prev/am-cpi.tsv" "$TSV")
    if [[ -n "$flags" ]]; then
      echo "- **逐测试 CPI 异常(|Δ|>20%,需复核是真回归还是评估问题)**:" >> "$SUM"
      echo "$flags" >> "$SUM"
    else
      echo "- 逐测试 CPI 无 >20% 异常(无回归/无评估漂移)。" >> "$SUM"
    fi
  fi
fi

# ---- benchmarks ----
if [[ $DO_BENCH -eq 1 ]]; then
  log "benchmarks (CoreMark/Dhrystone) ..."
  echo "" >> "$SUM"; echo "### benchmarks" >> "$SUM"; echo '```' >> "$SUM"
  for b in coremark dhrystone; do
    out=$(timeout 1200 make -C "$ROOT/am-kernels/benchmarks/$b" AM_HOME="$AM_HOME" ARCH=riscv64-npc \
            NPC_SIM_BACKEND=rv64 run NPC_RUN_ARGS="--no-progress --max-cycles 2000000000" 2>&1)
    cc=$(echo "$out" | grep -oE 'cycles=[0-9]+, commits=[0-9]+|CPI \(cycles/instruction\) = [0-9.]+|Marks|GOOD TRAP' | tr '\n' ' ')
    echo "  $b: $cc" >> "$SUM"
  done
  echo '```' >> "$SUM"
fi

log "done. report: $SUM"
echo "" >> "$SUM"
echo "_meta: $(cat "$OUT/meta.txt" | tr '\n' '; ')_" >> "$SUM"
cat "$SUM"
