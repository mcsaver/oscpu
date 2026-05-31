#!/usr/bin/env bash
set -euo pipefail

LOG=${1:?usage: collect-linux-log.sh <npc-log> [out-dir]}
OUT_DIR=${2:-$(dirname "$LOG")}
mkdir -p "$OUT_DIR"

grep -E "cyc=[0-9]+.* pc=0x[0-9a-fA-F]+" "$LOG" | tail -n 1 > "$OUT_DIR/final-pc.txt" || \
  grep -E "pc=0x[0-9a-fA-F]+" "$LOG" | tail -n 1 > "$OUT_DIR/final-pc.txt" || true
grep -E "TRAP|HIT GOOD TRAP|HIT BAD TRAP|trap cause|ABORT|timeout|max cycles" "$LOG" | tail -n 20 > "$OUT_DIR/final-trap.txt" || true
grep -E "cycles=|commits=|CPI|inst/s|\\[progress\\]" "$LOG" | tail -n 40 > "$OUT_DIR/perf-counter.txt" || true

echo "[collect-log] outputs: $OUT_DIR/final-pc.txt $OUT_DIR/final-trap.txt $OUT_DIR/perf-counter.txt"
