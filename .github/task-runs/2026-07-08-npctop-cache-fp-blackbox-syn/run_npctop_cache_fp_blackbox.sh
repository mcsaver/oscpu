#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench
TASK_DIR="$ROOT/.github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn"
EVIDENCE_DIR="$TASK_DIR/evidence"

mkdir -p "$EVIDENCE_DIR"

timeout 900s make -B -C "$ROOT/npc/rv64" syn \
  STA_DESIGN=NpcTop \
  STA_CLK_FREQ_MHZ=100 \
  STA_SYNTH_PUBLIC_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooFpArithGate" \
  2>&1 | tee "$EVIDENCE_DIR/NpcTop-cache-fp-blackbox-full.log"
