#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation"
readonly CSR_FILE="$ROOT_DIR/npc/rv64/vsrc/core/CsrFile.v"
readonly TB_FILE="$TASK_DIR/tb-t3k-csr-equiv-negative.sv"
readonly RESULT_CHECKER="$ROOT_DIR/npc/rv64/testbench/scripts/check_tb_result.py"
readonly LOG_CHECKER="$TASK_DIR/check-t3k-negative-probe-log.py"
readonly CALLER_CWD=$(pwd -P)
readonly OUT_DIR_RAW=${1:-"$TASK_DIR/evidence/negative-csr-equiv"}
readonly OUT_DIR=$(realpath -m -- "$OUT_DIR_RAW")

die() {
  printf '[T3K-NEGATIVE-PROBES] FAIL: %s\n' "$*" >&2
  exit 2
}

if [[ "$OUT_DIR_RAW" != /* ]]; then
  readonly EXPECTED_OUT_DIR=$(realpath -m -- "$CALLER_CWD/$OUT_DIR_RAW")
  [[ "$OUT_DIR" == "$EXPECTED_OUT_DIR" ]] \
    || die "relative output resolution drift: raw=$OUT_DIR_RAW got=$OUT_DIR expected=$EXPECTED_OUT_DIR"
fi
case "$OUT_DIR" in
  "$(realpath -m -- "$TASK_DIR/evidence")"/*) ;;
  *) die "output escapes the T3K evidence root: $OUT_DIR" ;;
esac
[[ ! -e "$OUT_DIR" ]] || die "refusing stale negative evidence: $OUT_DIR"

for input in "$CSR_FILE" "$TB_FILE" "$RESULT_CHECKER" "$LOG_CHECKER"; do
  [[ -f "$input" && ! -L "$input" && -s "$input" ]] \
    || die "missing, empty, or symlink input: $input"
done
command -v iverilog >/dev/null || die "iverilog not found"
command -v vvp >/dev/null || die "vvp not found"

mkdir -p -- "$OUT_DIR"
readonly BINARY="$OUT_DIR/tb-t3k-csr-equiv-negative.vvp"
readonly COMPILE_LOG="$OUT_DIR/compile.log"
readonly SIM_LOG="$OUT_DIR/sim.log"
readonly CLASSIFIER_LOG="$OUT_DIR/classifier.log"
readonly COMBINED_LOG="$OUT_DIR/result.log"
readonly AUDIT_LOG="$OUT_DIR/audit.log"
readonly -a COMPILE_CMD=(
  iverilog
  -g2012
  -Wall
  -DOOO_ASSERT
  -s tb_t3k_csr_equiv_negative
  -I "$ROOT_DIR/npc/rv64/vsrc"
  -I "$ROOT_DIR/npc/rv64/vsrc/include"
  -o "$BINARY"
  "$CSR_FILE"
  "$TB_FILE"
)

set +e
"${COMPILE_CMD[@]}" >"$COMPILE_LOG" 2>&1
compile_rc=$?
set -e
[[ $compile_rc -eq 0 ]] || die "negative harness compile failed rc=$compile_rc (see $COMPILE_LOG)"

set +e
vvp "$BINARY" >"$SIM_LOG" 2>&1
sim_rc=$?
python3 "$RESULT_CHECKER" \
  --test tb_t3k_csr_equiv_negative \
  --source "$TB_FILE" \
  --log "$SIM_LOG" \
  --compile-rc "$compile_rc" \
  --sim-rc "$sim_rc" >"$CLASSIFIER_LOG" 2>&1
classifier_rc=$?
set -e
[[ $classifier_rc -ne 0 ]] \
  || die "module result checker falsely accepted the assertion-negative log"

{
  printf '[COMPILE]'
  printf ' %q' "${COMPILE_CMD[@]}"
  printf '\n'
  cat "$COMPILE_LOG"
  cat "$SIM_LOG"
  cat "$CLASSIFIER_LOG"
  printf '[RESULT] FAIL status=%s\n' "$classifier_rc"
} >"$COMBINED_LOG"

python3 "$LOG_CHECKER" \
  --log "$COMBINED_LOG" \
  --compile-rc "$compile_rc" \
  --sim-rc "$sim_rc" \
  --classifier-rc "$classifier_rc" \
  --exercise-fail-closed >"$AUDIT_LOG" 2>&1

{
  printf 'case=csr-legal-view-equiv\n'
  printf 'assertion_marker=[CSR-LEGAL-VIEW-EQUIV]\n'
  printf 'premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1\n'
  printf 'compile_rc=%s\n' "$compile_rc"
  printf 'sim_rc=%s\n' "$sim_rc"
  printf 'classifier_rc=%s\n' "$classifier_rc"
  printf 'global_result=EXPECTED_FAIL\n'
  printf 'marker_audit=PASS\n'
  printf 'missing_duplicate_false_green_selftest=PASS\n'
} >"$OUT_DIR/status.txt"

printf '[T3K-NEGATIVE-PROBES] PASS assertion=%s premise=non-vacuous classifier_rc=%s output=%s\n' \
  '[CSR-LEGAL-VIEW-EQUIV]' "$classifier_rc" "$OUT_DIR"
