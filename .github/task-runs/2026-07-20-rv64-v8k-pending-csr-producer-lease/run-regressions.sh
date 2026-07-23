#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
TB_HOME="$REPO_ROOT/npc/rv64/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/regressions"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8k-regressions.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8k-regressions.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/regressions) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8K-REGRESSION][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT'

run_int_slice() {
  local label=$1
  local macro=$2
  local result="$EVIDENCE_DIR/$label"
  make -B -C "$TB_HOME" \
    "TESTS=tb_ooo_int_backend" \
    "BUILD_DIR=$TEMP_DIR/build-$label" \
    "RESULT_DIR=$result" \
    "IVFLAGS=$base_flags -D$macro" run \
    > "$EVIDENCE_DIR/$label.make.log" 2>&1
  grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/$label.make.log"
}

run_int_slice v8d-int-ex-kill INT_EX_KILL_CUT_FOCUSED
run_int_slice v8f-int-ex-auth INT_EX_PRODUCER_AUTH_FOCUSED
run_int_slice v8g-memory-lease V8G_MEMORY_PRODUCER_LEASE_FOCUSED
run_int_slice v8h-longop-lease V8H_LONGOP_PRODUCER_LEASE_FOCUSED
run_int_slice v8i-fp-lease V8I_FP_PRODUCER_LEASE_FOCUSED
run_int_slice v8j-branch-auth V8J_BRANCH_RESOLVE_AUTH_FOCUSED

make -B -C "$TB_HOME" \
  "BUILD_DIR=$TEMP_DIR/build-module-aggregate" \
  "RESULT_DIR=$EVIDENCE_DIR/module-aggregate" run \
  > "$EVIDENCE_DIR/module-aggregate.make.log" 2>&1
grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/module-aggregate.make.log"

total=$(sed -n 's/^- total: //p' \
  "$EVIDENCE_DIR/module-aggregate/summary.txt")
passed=$(sed -n 's/^- passed: //p' \
  "$EVIDENCE_DIR/module-aggregate/summary.txt")
[[ -n "$total" && "$total" == "$passed" ]]

{
  printf '# v8k regression summary\n\n'
  printf -- '- legacy ProducerId focused slices v8d/v8f/v8g/v8h/v8i/v8j: 6/6 PASS\n'
  printf -- '- fresh OOO_ASSERT module aggregate: %s/%s PASS\n' "$passed" "$total"
  printf -- '- aggregate includes pending/CSR leaves, IntBackend, wrappers, CoreTopGlue and privilege forward TB\n'
} > "$EVIDENCE_DIR/summary.md"

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8K-REGRESSION][PASS] legacy=6 aggregate=%s/%s\n' \
  "$passed" "$total" >> "$EVIDENCE_DIR/complete.marker"
printf '[V8K-REGRESSION] PASS legacy=6 aggregate=%s/%s\n' "$passed" "$total"
