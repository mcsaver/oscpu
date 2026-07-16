#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3w-retire-static-cache-owner"
EVIDENCE_DIR="$TASK_DIR/evidence/static-facts-coherence-mutation-negative-v1"
WORK_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3w-retire-static-cache-owner/static-facts-coherence-mutation-negative-v1"
SOURCE="$ROOT_DIR/npc/rv64/vsrc/frontend/OooFrontend.v"
MUTANT="$WORK_DIR/OooFrontend.static-facts-mutated.v"
BUILD_DIR="$WORK_DIR/build"
LOG_DIR="$EVIDENCE_DIR/logs"
TEST_LOG="$LOG_DIR/tb_ooo_core_top_glue.log"
CONSOLE_LOG="$EVIDENCE_DIR/make-console.log"
MUTATION_DIFF="$EVIDENCE_DIR/mutation.diff"
SUMMARY="$EVIDENCE_DIR/summary.txt"
ASSERTION='[T3W-STATIC-FACTS-COHERENCE] lane1 stored facts mismatch instruction'

sha256_of() { sha256sum "$1" | awk '{print $1}'; }

source_sha_before=$(sha256_of "$SOURCE")
verify_source_unchanged() {
  local rc=$?
  local source_sha_after
  trap - EXIT
  source_sha_after=$(sha256_of "$SOURCE")
  if [[ "$source_sha_after" != "$source_sha_before" ]]; then
    echo "formal RTL changed during mutation-negative run" >&2
    exit 97
  fi
  exit "$rc"
}
trap verify_source_unchanged EXIT

mkdir -p "$WORK_DIR" "$BUILD_DIR" "$LOG_DIR"
rm -f "$TEST_LOG" "$CONSOLE_LOG" "$MUTATION_DIFF" "$SUMMARY"
cp "$SOURCE" "$MUTANT"

# Corrupt exactly one cached lane1 static bit only for a fetch-fault packet.
# This is a workspace-local copy; the formal OooFrontend.v remains untouched.
perl -0pi -e \
  "s/\\.enqueue_static_facts1_i\\(fetch_dec1_static_facts_w\\),/.enqueue_static_facts1_i(fetch_dec1_static_facts_w ^ ({18{|fetch_dec1_resp_w}} \& 18'h00008)),/" \
  "$MUTANT"

grep -Fq '.enqueue_static_facts1_i(fetch_dec1_static_facts_w),' "$SOURCE"
grep -Fq ".enqueue_static_facts1_i(fetch_dec1_static_facts_w ^ ({18{|fetch_dec1_resp_w}} & 18'h00008))," \
  "$MUTANT"

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
grep -Fq "$ASSERTION" "$TEST_LOG"
grep -Fq '[RESULT] FAIL' "$TEST_LOG"
if [[ "$make_rc" -eq 0 ]]; then
  echo "static-facts mutation unexpectedly passed the test harness" >&2
  exit 1
fi

source_sha_after=$(sha256_of "$SOURCE")
[[ "$source_sha_after" == "$source_sha_before" ]]
signature_count=$(grep -Fc "$ASSERTION" "$TEST_LOG")
{
  echo "PASS static_facts_coherence_mutation_negative"
  echo "timestamp=$(date --iso-8601=seconds)"
  echo "head=$(git -C "$ROOT_DIR" rev-parse HEAD)"
  echo "mutation=lane1_fetch_fault_flips_stored_static_fp_move_to_gpr_bit"
  echo "formal_rtl_modified=no"
  echo "make_rc=$make_rc"
  echo "assertion_signature_count=$signature_count"
  echo "source_sha256_before=$source_sha_before"
  echo "source_sha256_after=$source_sha_after"
  echo "mutant_sha256=$(sha256_of "$MUTANT")"
  echo "test_log_sha256=$(sha256_of "$TEST_LOG")"
} > "$SUMMARY"

cat "$SUMMARY"
