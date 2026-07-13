#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
OUT_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy/evidence/negative"
TB_DIR="$ROOT_DIR/npc/rv64/testbench"
MARKER='[CORE-RETIRE-REQUIRES-ROB]'

source "$ROOT_DIR/scripts/agent-env.sh"
export PATH="$ROOT_DIR/oss-cad-suite/bin:$PATH"
mkdir -p "$OUT_DIR"

run_probe() {
  local name=$1
  local macro=$2
  local result_dir="$OUT_DIR/$name"
  local console="$result_dir/console.log"
  local log="$result_dir/logs/tb_ooo_alu_core_slice.log"
  local make_rc error_count marker_count result_fail_count

  mkdir -p "$result_dir"
  set +e
  make -C "$TB_DIR" \
    TESTS=tb_ooo_alu_core_slice \
    RESULT_DIR="$result_dir" \
    BUILD_DIR="$result_dir/build" \
    IVFLAGS="-g2012 -Wall -I$ROOT_DIR/npc/rv64/vsrc -I$ROOT_DIR/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -D$macro" \
    run >"$console" 2>&1
  make_rc=$?
  set -e

  [[ -f $log ]] || { printf '%s: missing log\n' "$name" >&2; return 1; }
  error_count=$(grep -c '^ERROR:' "$log" || true)
  marker_count=$(grep -F -c "$MARKER" "$log" || true)
  result_fail_count=$(grep -c '^\[RESULT\] FAIL' "$log" || true)
  {
    printf 'probe=%s\n' "$name"
    printf 'macro=%s\n' "$macro"
    printf 'make_rc=%s\n' "$make_rc"
    printf 'error_count=%s\n' "$error_count"
    printf 'marker_count=%s\n' "$marker_count"
    printf 'result_fail_count=%s\n' "$result_fail_count"
  } >"$result_dir/status.txt"

  if [[ $make_rc -eq 0 || $error_count -ne 1 || $marker_count -ne 1 ||
        $result_fail_count -ne 1 ]]; then
    printf '%s: negative probe did not fail closed exactly once\n' "$name" >&2
    return 1
  fi
  printf '[T3I-NEGATIVE] PASS %s make_rc=%s exact_error=1 exact_marker=1\n' \
    "$name" "$make_rc"
}

run_probe retire-one OOO_NEGATIVE_CORE_RETIRE_WITH_EMPTY_ROB
run_probe retire-x OOO_NEGATIVE_CORE_RETIRE_X_WITH_EMPTY_ROB
