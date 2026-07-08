#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
TASK_DIR="$ROOT/.github/task-runs/2026-07-08-fp-arith-internal-cones"
PROBE="$TASK_DIR/evidence/probes/OooFpArithInternalConeProbes.v"

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
    STA_RTL_FILES="$PROBE" 2>&1 | tee "$TASK_DIR/evidence/${design}-${suffix}.log"
}

case "${1:-}" in
  coarse)
    run_one OooFpMulProductProbe 1 coarse 300
    run_one OooFpMulNormRoundProbe 1 coarse 300
    run_one OooFpFmaRefProbe 1 coarse 300
    run_one OooFpFmaAlignAddProbe 1 coarse 300
    run_one OooFpFmaNormRoundProbe 1 coarse 300
    ;;
  full)
    run_one OooFpMulProductProbe 0 full 300
    run_one OooFpMulNormRoundProbe 0 full 300
    run_one OooFpFmaRefProbe 0 full 300
    run_one OooFpFmaAlignAddProbe 0 full 300
    run_one OooFpFmaNormRoundProbe 0 full 300
    ;;
  full-mul-product)
    run_one OooFpMulProductProbe 0 full 300
    ;;
  full-mul-norm-round)
    run_one OooFpMulNormRoundProbe 0 full 300
    ;;
  full-fma-ref)
    run_one OooFpFmaRefProbe 0 full 300
    ;;
  full-fma-align-add)
    run_one OooFpFmaAlignAddProbe 0 full 300
    ;;
  full-fma-norm-round)
    run_one OooFpFmaNormRoundProbe 0 full 300
    ;;
  *)
    echo "usage: $0 coarse|full|full-mul-product|full-mul-norm-round|full-fma-ref|full-fma-align-add|full-fma-norm-round" >&2
    exit 2
    ;;
esac
