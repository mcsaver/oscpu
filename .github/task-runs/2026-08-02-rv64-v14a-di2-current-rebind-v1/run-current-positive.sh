#!/usr/bin/env bash
set -euo pipefail

# Current-design RV64 DI-2 positive discriminator.  Generated images and the
# full compile log remain in a bounded temporary directory and are removed on
# every exit; only exact architectural markers are emitted to stdout.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
TB_HOME="$REPO_ROOT/npc/rv64/testbench"
TEMP_PREFIX="${TMPDIR:-/tmp}/v14a-di2-positive."
TEMP_DIR=$(mktemp -d "${TEMP_PREFIX}XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "$TEMP_PREFIX"* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

make -B -C "$TB_HOME" \
  BUILD_DIR="$TEMP_DIR/build" \
  RESULT_DIR="$TEMP_DIR/result" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT' \
  v9a-width-continuity > "$TEMP_DIR/make.log" 2>&1

LOG="$TEMP_DIR/result/logs/tb_ooo_core_top_glue_v9a_width_continuity.log"
[[ "$(grep -F -c '[RESULT] PASS' "$LOG" || true)" -eq 1 ]]
[[ "$(grep -F -c '[V9A-DI2-TRACE]' "$LOG" || true)" -eq 64 ]]
grep -E '^\[V9A-DI2-(ANCHOR|METRIC|IDENTITY|DRAIN)|^\[RESULT\]' "$LOG"
