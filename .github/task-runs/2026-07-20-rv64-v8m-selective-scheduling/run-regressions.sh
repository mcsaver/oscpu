#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
TB_HOME="$REPO_ROOT/npc/rv64/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/regressions"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8m-regressions.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8m-regressions.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8M-REGRESSION][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/regressions) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/module"

make -C "$TB_HOME" \
  "BUILD_DIR=$TEMP_DIR/module-build" \
  "RESULT_DIR=$EVIDENCE_DIR/module" run \
  > "$EVIDENCE_DIR/module.make.log" 2>&1

summary="$EVIDENCE_DIR/module/summary.txt"
[[ -s "$summary" ]] || fail "module summary is missing"
total=$(sed -n 's/^- total: \([0-9][0-9]*\)$/\1/p' "$summary")
passed=$(sed -n 's/^- passed: \([0-9][0-9]*\)$/\1/p' "$summary")
failed=$(sed -n 's/^- failed: \([0-9][0-9]*\)$/\1/p' "$summary")
[[ "$total" =~ ^[0-9]+$ && "$total" -gt 0 ]] ||
  fail "invalid module total: $total"
[[ "$passed" == "$total" && "$failed" == 0 ]] ||
  fail "module aggregate is not clean: total=$total passed=$passed failed=$failed"

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8M-REGRESSION][PASS] module=%s/%s\n' "$passed" "$total" \
  >> "$EVIDENCE_DIR/complete.marker"
printf '[V8M-REGRESSION][PASS] module=%s/%s\n' "$passed" "$total"
