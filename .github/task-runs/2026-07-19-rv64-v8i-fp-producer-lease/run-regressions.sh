#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
TB_HOME="$REPO_ROOT/npc/rv64/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/regression"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8i-regression.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8i-regression.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/regression) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8I-REGRESSION][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

fail() {
  printf '[V8I-REGRESSION][FAIL] %s\n' "$*" >&2
  exit 1
}

source_paths=(
  "$REPO_ROOT/npc/rv64/vsrc/execute/OooFpBackend.v"
  "$REPO_ROOT/npc/rv64/vsrc/execute/OooIntBackend.v"
  "$REPO_ROOT/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v"
  "$REPO_ROOT/npc/rv64/vsrc/writeback/OooRob.v"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

run_focus() {
  local label=$1
  local define=$2
  local assert_flag=$3
  local result_dir="$EVIDENCE_DIR/$label"
  local build_dir="$TEMP_DIR/build-$label"
  local flags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -D$define"
  if [[ "$assert_flag" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  make -C "$TB_HOME" \
    "TESTS=tb_ooo_int_backend" \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$flags" run > "$EVIDENCE_DIR/$label.make.log" 2>&1 ||
    fail "$label did not pass"
  grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/$label.make.log" ||
    fail "$label lacks zero-failure summary"
}

run_focus v8f-release INT_EX_PRODUCER_AUTH_FOCUSED release
run_focus v8f-assert INT_EX_PRODUCER_AUTH_FOCUSED assert
run_focus v8g-release V8G_MEMORY_PRODUCER_LEASE_FOCUSED release
run_focus v8g-assert V8G_MEMORY_PRODUCER_LEASE_FOCUSED assert
run_focus v8h-release V8H_LONGOP_PRODUCER_LEASE_FOCUSED release
run_focus v8h-assert V8H_LONGOP_PRODUCER_LEASE_FOCUSED assert

make -C "$TB_HOME" \
  "BUILD_DIR=$TEMP_DIR/build-module-aggregate" \
  "RESULT_DIR=$EVIDENCE_DIR/module-aggregate" run \
  > "$EVIDENCE_DIR/module-aggregate.make.log" 2>&1 ||
  fail 'module aggregate did not pass'
grep -Fq -- '- failed: 0' "$EVIDENCE_DIR/module-aggregate.make.log" ||
  fail 'module aggregate lacks zero-failure summary'

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail 'canonical sources changed while running regressions'

total=$(sed -n 's/^- total: //p' "$EVIDENCE_DIR/module-aggregate/summary.txt")
passed=$(sed -n 's/^- passed: //p' "$EVIDENCE_DIR/module-aggregate/summary.txt")
failed=$(sed -n 's/^- failed: //p' "$EVIDENCE_DIR/module-aggregate/summary.txt")
[[ -n "$total" && "$total" == "$passed" && "$failed" == 0 ]] ||
  fail "module aggregate summary is inconsistent: total=$total passed=$passed failed=$failed"

{
  printf '# v8i regression summary\n\n'
  printf -- '- v8f integer EX authorization: release + OOO_ASSERT PASS\n'
  printf -- '- v8g memory producer lease: release + OOO_ASSERT PASS\n'
  printf -- '- v8h integer long-op lease: release + OOO_ASSERT PASS\n'
  printf -- '- module aggregate: %s/%s PASS\n' "$passed" "$total"
  printf -- '- canonical source hash stability: PASS\n'
} > "$EVIDENCE_DIR/summary.md"

printf '[V8I-REGRESSION] PASS legacy-focus=6/6 module=%s/%s\n' "$passed" "$total"
