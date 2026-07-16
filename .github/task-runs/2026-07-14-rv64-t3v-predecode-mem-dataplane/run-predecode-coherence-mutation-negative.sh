#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
EVIDENCE_DIR="$TASK_DIR/evidence/predecode-coherence-mutation-negative-v1"
WORK_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/predecode-coherence-mutation-negative-v1"
SOURCE="$ROOT_DIR/npc/rv64/vsrc/frontend/OooFrontend.v"
MUTANT="$WORK_DIR/OooFrontend.mutated.v"
BUILD_DIR="$WORK_DIR/build"
LOG_DIR="$EVIDENCE_DIR/logs"
TEST_LOG="$LOG_DIR/tb_ooo_core_top_glue.log"
CONSOLE_LOG="$EVIDENCE_DIR/make-console.log"
MUTATION_DIFF="$EVIDENCE_DIR/mutation.diff"
SUMMARY="$EVIDENCE_DIR/summary.txt"

mkdir -p "$WORK_DIR" "$BUILD_DIR" "$LOG_DIR"
rm -f "$TEST_LOG" "$CONSOLE_LOG" "$MUTATION_DIFF" "$SUMMARY"
cp "$SOURCE" "$MUTANT"

# Flip one stored lane0 rd bit only when the paired lane1 carries a fetch
# fault.  This targets the new integration scenario without corrupting every
# normal packet.  The formal RTL is untouched; only this local unit is mutated.
perl -0pi -e \
  's/\.enqueue_rd0_i\(fetch_dec0_rd_w\),/.enqueue_rd0_i(fetch_dec0_rd_w ^ (|fetch_dec1_resp_w)),/' \
  "$MUTANT"

grep -Fq '.enqueue_rd0_i(fetch_dec0_rd_w),' "$SOURCE"
grep -Fq '.enqueue_rd0_i(fetch_dec0_rd_w ^ (|fetch_dec1_resp_w)),' "$MUTANT"

diff_rc=0
diff -u "$SOURCE" "$MUTANT" > "$MUTATION_DIFF" || diff_rc=$?
if [[ "$diff_rc" -ne 1 ]]; then
  echo "expected exactly a textual mutation diff, diff_rc=$diff_rc" >&2
  exit 1
fi

set +e
make -C "$ROOT_DIR/npc/rv64/testbench" \
  BUILD_DIR="$BUILD_DIR" \
  RESULT_DIR="$EVIDENCE_DIR" \
  RTL_OOO_FRONTEND="$MUTANT" \
  "$TEST_LOG" > "$CONSOLE_LOG" 2>&1
make_rc=$?
set -e

grep -Fq "$MUTANT" "$TEST_LOG"
grep -Fq '[T3V-PREDECODE-COHERENCE] lane0 stored decode mismatches instruction' \
  "$TEST_LOG"
grep -Fq '[RESULT] FAIL' "$TEST_LOG"
if [[ "$make_rc" -eq 0 ]]; then
  echo "mutation unexpectedly passed the test harness" >&2
  exit 1
fi

signature_count=$(grep -Fc \
  '[T3V-PREDECODE-COHERENCE] lane0 stored decode mismatches instruction' \
  "$TEST_LOG")
{
  echo "PASS predecode_coherence_mutation_negative"
  echo "timestamp=$(date --iso-8601=seconds)"
  echo "head=$(git -C "$ROOT_DIR" rev-parse HEAD)"
  echo "mutation=lane1_fault_flips_stored_lane0_rd_lsb"
  echo "formal_rtl_modified=no"
  echo "make_rc=$make_rc"
  echo "assertion_signature_count=$signature_count"
  echo "source_sha256=$(sha256sum "$SOURCE" | awk '{print $1}')"
  echo "mutant_sha256=$(sha256sum "$MUTANT" | awk '{print $1}')"
  echo "test_log_sha256=$(sha256sum "$TEST_LOG" | awk '{print $1}')"
} > "$SUMMARY"

cat "$SUMMARY"
