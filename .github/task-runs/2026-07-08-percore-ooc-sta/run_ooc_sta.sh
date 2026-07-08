#!/usr/bin/env bash
# 7 个 keep 模块逐个 OOC syn+sta，产出全核分模块时序/功耗账本。
# STA_RTL_FILES 用 Makefile 默认(RTL_CORE_SRCS 全集)，yosys hierarchy -top 自动剪未用模块；
# 黑盒集统一传四黑盒(无关黑盒被剪)；EXTRA_LIB_FILES 走 npc Makefile 默认(四占位 lib)。
set -u
ROOT=/home/lyg/PA/ysyx-workbench
OUT=$ROOT/.github/task-runs/2026-07-08-percore-ooc-sta/evidence
BB="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"
for m in OooRob OooIntIssueQueue OooFrontend OooMemAxiBridge OooFetchAxiBridge OooFpBackend OooIntBackend; do
  echo "[$(date +%H:%M:%S)] === $m syn ==="
  timeout 2400 make -B -C $ROOT/npc/rv64 syn STA_DESIGN=$m STA_CLK_FREQ_MHZ=100 \
    STA_SYNTH_FLATTEN=1 STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
    STA_SYNTH_BLACKBOX_MODULES="$BB" > $OUT/$m-syn.log 2>&1
  rc=$?
  echo "[$(date +%H:%M:%S)] $m syn exit=$rc"
  [ $rc -ne 0 ] && continue
  echo "[$(date +%H:%M:%S)] === $m sta ==="
  timeout 1800 make -C $ROOT/npc/rv64 sta STA_DESIGN=$m STA_CLK_FREQ_MHZ=100 \
    STA_SYNTH_BLACKBOX_MODULES="$BB" > $OUT/$m-sta.log 2>&1
  echo "[$(date +%H:%M:%S)] $m sta exit=$?"
  R=$ROOT/npc/rv64/build/sta/$m-100MHz
  [ -f $R/$m.rpt ] && cp $R/$m.rpt $R/$m.pwr $OUT/ 2>/dev/null && echo "$m: rpt/pwr collected"
done
echo ALL_DONE
