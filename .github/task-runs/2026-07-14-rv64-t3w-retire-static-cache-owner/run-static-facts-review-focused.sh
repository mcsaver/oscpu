#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3w-retire-static-cache-owner"
RESULT_DIR="$TASK_DIR/evidence/static-facts-review-focused-v1"
WORK_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3w-retire-static-cache-owner/static-facts-review-focused-v1"
BUILD_DIR="$WORK_DIR/build"
CONSOLE_LOG="$RESULT_DIR/make-console.log"
TESTS='tb_ooo_fetch_static_classify tb_ooo_fetch_head_classify_gate tb_ooo_fetch_packet_fifo tb_ooo_core_top_glue'

mkdir -p "$BUILD_DIR" "$RESULT_DIR/logs"
for test in $TESTS; do
  rm -f "$RESULT_DIR/logs/$test.log"
done
rm -f "$RESULT_DIR/summary.txt" "$CONSOLE_LOG"

make -C "$ROOT_DIR/npc/rv64/testbench" \
  TESTS="$TESTS" \
  BUILD_DIR="$BUILD_DIR" \
  RESULT_DIR="$RESULT_DIR" \
  run > "$CONSOLE_LOG" 2>&1

grep -Fq -- '- passed: 4' "$RESULT_DIR/summary.txt"
grep -Fq -- '- failed: 0' "$RESULT_DIR/summary.txt"
grep -Fq '[T3W-FETCH-FAULT-RAW]' \
  "$RESULT_DIR/logs/tb_ooo_core_top_glue.log"
grep -Fq '[T3W-FETCH-FAULT-STATIC] enqueue sanitized NOP facts=0' \
  "$RESULT_DIR/logs/tb_ooo_core_top_glue.log"
grep -Fq '[T3W-FETCH-FAULT-STATIC] FIFO head sanitized NOP facts=0' \
  "$RESULT_DIR/logs/tb_ooo_core_top_glue.log"
grep -Fq '[T3W-FIFO-WRAP] packet E atomic static/decode readback' \
  "$RESULT_DIR/logs/tb_ooo_fetch_packet_fifo.log"
grep -Fq '[T3W-FIFO-WRAP] packet F atomic static/decode readback' \
  "$RESULT_DIR/logs/tb_ooo_fetch_packet_fifo.log"
grep -Fq '[T3W-FIFO-WRAP] packet G atomic static/decode readback' \
  "$RESULT_DIR/logs/tb_ooo_fetch_packet_fifo.log"

cat "$RESULT_DIR/summary.txt"
