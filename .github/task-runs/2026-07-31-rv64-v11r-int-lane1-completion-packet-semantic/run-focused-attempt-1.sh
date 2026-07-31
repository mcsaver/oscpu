#!/usr/bin/env bash
set -euo pipefail

python3 npc/rv64/testbench/scripts/run_v11r_int_lane1_packet_semantic.py \
  --result-dir \
  .github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic/evidence/focused-attempt-1 \
  --overwrite
