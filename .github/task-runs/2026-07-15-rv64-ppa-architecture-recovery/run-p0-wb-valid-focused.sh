#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK="$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
EVIDENCE="$TASK/evidence/p0-a-wb-valid-matrix22-v2"
TMP="$ROOT/tmp/2026-07-15-rv64-ppa-architecture-recovery/p0-a-wb-valid-matrix22-v2"
TB_DIR="$ROOT/npc/rv64/testbench"

if [[ -e "$EVIDENCE" || -e "$TMP" ]]; then
  printf '[P0-A-WB-VALID] refusing stale output: %s or %s\n' \
    "$EVIDENCE" "$TMP" >&2
  exit 2
fi
mkdir -p "$EVIDENCE" "$TMP"

run_case() {
  local name=$1
  local macro=$2
  local expectation=$3
  local marker=${4:-}
  local case_tmp="$TMP/$name"
  local case_result="$EVIDENCE/$name"
  local tb_log="$case_result/logs/tb_ooo_int_backend.log"
  local rc

  mkdir -p "$case_tmp" "$case_result"
  set +e
  make -C "$TB_DIR" \
    TESTS=tb_ooo_int_backend \
    BUILD_DIR="$case_tmp/build" \
    RESULT_DIR="$case_result" \
    IVFLAGS="-g2012 -Wall -I$ROOT/npc/rv64/vsrc -I$ROOT/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -D$macro" \
    run >"$case_result/make.stdout.log" 2>&1
  rc=$?
  set -e

  test -f "$tb_log"
  if [[ "$expectation" == pass ]]; then
    test "$rc" -eq 0
    if [[ "$name" == focused ]]; then
      test "$(grep -Fxc '[P0-A-WB-VALID-SOURCE-MATRIX] 22/22 PASS: 2 lanes x (5 nonzero + 5 p0), plus 2 FP rd-disable' "$tb_log")" -eq 1
    fi
    test "$(grep -c '\[RESULT\] PASS' "$tb_log")" -eq 1
    ! grep -qE '(^|[^A-Z])(ERROR|FATAL):|\[CHECK-FAIL\]' "$tb_log"
  else
    test "$rc" -ne 0
    test "$(grep -c "$marker" "$tb_log")" -eq 1
    test "$(grep -c '^ERROR:' "$tb_log")" -eq 1
    test "$(grep -c '\[RESULT\] FAIL' "$tb_log")" -eq 1
  fi
  printf '%s rc=%d expectation=%s marker=%s\n' \
    "$name" "$rc" "$expectation" "${marker:-none}" \
    >>"$EVIDENCE/results.tsv"
}

printf 'case rc expectation marker\n' >"$EVIDENCE/results.tsv"
run_case focused INT_WB_VALID_SOURCE_FOCUSED pass
run_case standard INT_WB_VALID_STANDARD pass
run_case equiv-negative INT_WB_WRITE_VALID_EQUIV_NEGATIVE fail \
  '\[INT-WB0-WRITE-VALID-EQUIV\]'
run_case onehot-negative INT_WB_SOURCE_ONEHOT_NEGATIVE fail \
  '\[INT-WB0-SOURCE-ONEHOT0\]'

make -C "$ROOT/npc/rv64" check-rtl-style \
  >"$EVIDENCE/check-rtl-style.log" 2>&1
make -C "$ROOT/npc/rv64" lint \
  >"$EVIDENCE/lint.log" 2>&1
make -C "$ROOT/npc/rv64" check-contract \
  >"$EVIDENCE/check-contract.log" 2>&1

sha256sum \
  "$ROOT/npc/rv64/vsrc/execute/OooIntBackend.v" \
  "$ROOT/npc/rv64/testbench/tests/tb_ooo_int_backend.sv" \
  "$TASK/run-p0-wb-valid-focused.sh" \
  >"$EVIDENCE/inputs.sha256"

{
  printf '# P0-A WB write-valid focused verification\n\n'
  printf -- '- focused: 22/22 PASS = 2 lanes x (5 nonzero + 5 p0), plus 2 FP rd-disable\n'
  printf -- '- standard OooIntBackend regression: PASS\n'
  printf -- '- equivalence negative: exact legacy-shadow mismatch marker PASS\n'
  printf -- '- onehot negative: exact overlapping-source marker PASS\n'
  printf -- '- check-rtl-style: PASS\n'
  printf -- '- full Verilator lint: PASS\n'
  printf -- '- check-contract: PASS\n'
} >"$EVIDENCE/summary.md"

find "$EVIDENCE" -type f ! -name SHA256SUMS -print0 \
  | LC_ALL=C sort -z | xargs -0 sha256sum >"$EVIDENCE/SHA256SUMS"

printf '[P0-A-WB-VALID] PASS evidence=%s\n' "$EVIDENCE"
