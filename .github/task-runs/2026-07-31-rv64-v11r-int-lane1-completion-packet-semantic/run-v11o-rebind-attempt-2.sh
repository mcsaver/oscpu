#!/usr/bin/env bash
set -euo pipefail

python3 npc/rv64/testbench/scripts/run_v11o_memory_buffer_token_semantic.py \
  --result-dir \
  .github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic/evidence/v11o-rebind-current \
  --overwrite
