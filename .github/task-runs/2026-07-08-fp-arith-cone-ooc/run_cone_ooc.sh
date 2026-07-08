#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
TASK_DIR="$ROOT/.github/task-runs/2026-07-08-fp-arith-cone-ooc"
PROBE="$TASK_DIR/evidence/probes/OooFpArithGateConeProbes.v"
RTL="$ROOT/npc/rv64/vsrc/execute/OooFpArithGate.v $PROBE"

run_one() {
  local design="$1"
  local stop_after_coarse="$2"
  local suffix="$3"
  local timeout_s="$4"
  echo "[RUN] $suffix $design"
  timeout "$timeout_s" make -B -C "$ROOT/npc/rv64" syn \
    STA_DESIGN="$design" \
    STA_CLK_FREQ_MHZ=100 \
    STA_SYNTH_FLATTEN=1 \
    STA_SYNTH_STOP_AFTER_COARSE="$stop_after_coarse" \
    STA_SYNTH_PUBLIC_AUTONAME=0 \
    STA_RTL_FILES="$RTL" 2>&1 | tee "$TASK_DIR/evidence/${design}-${suffix}.log"
}

case "${1:-}" in
  coarse)
    run_one OooFpArithGateAddSubConeProbe 1 coarse 600
    run_one OooFpArithGateMulConeProbe 1 coarse 600
    run_one OooFpArithGateFmaConeProbe 1 coarse 600
    ;;
  full)
    run_one OooFpArithGateAddSubConeProbe 0 full 600
    run_one OooFpArithGateMulConeProbe 0 full 600
    run_one OooFpArithGateFmaConeProbe 0 full 600
    ;;
  full-addsub)
    run_one OooFpArithGateAddSubConeProbe 0 full 600
    ;;
  full-mul)
    run_one OooFpArithGateMulConeProbe 0 full 600
    ;;
  full-fma)
    run_one OooFpArithGateFmaConeProbe 0 full 600
    ;;
  *)
    echo "usage: $0 coarse|full" >&2
    exit 2
    ;;
esac
