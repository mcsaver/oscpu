#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
TASK_DIR="$ROOT/.github/task-runs/2026-07-08-npctop-cache-data-fp-bpu-blackbox-syn"
EVIDENCE_DIR="$TASK_DIR/evidence"

mkdir -p "$EVIDENCE_DIR"

timeout 1200s make -B -C "$ROOT/npc/rv64" syn \
  STA_DESIGN=NpcTop \
  STA_CLK_FREQ_MHZ=100 \
  STA_SYNTH_PUBLIC_AUTONAME=0 \
  STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooDataWordCache OooFpArithGate OooBranchDirectionPredictor" \
  2>&1 | tee "$EVIDENCE_DIR/NpcTop-cache-data-fp-bpu-blackbox-full.log"
