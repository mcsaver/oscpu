#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/static-gates"

fail() {
  printf '[V8M-STATIC][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/static-gates) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR"

make -C "$NPC_HOME" check-rtl-style > "$EVIDENCE_DIR/rtl-style.log" 2>&1
make -C "$NPC_HOME" check-producer-holder-census \
  > "$EVIDENCE_DIR/producer-holder-census.log" 2>&1
make -C "$NPC_HOME" check-contract > "$EVIDENCE_DIR/check-contract.log" 2>&1

set +e
make -C "$NPC_HOME" lint > "$EVIDENCE_DIR/lint.log" 2>&1
lint_rc=$?
make -C "$TB_HOME" arch-gates > "$EVIDENCE_DIR/architecture-gates.log" 2>&1
arch_rc=$?
set -e

warning_count=$(grep -c '%Warning-' "$EVIDENCE_DIR/lint.log" || true)
[[ "$lint_rc" -eq 2 && "$warning_count" -eq 115 ]] ||
  fail "full lint signature drifted: rc=$lint_rc warnings=$warning_count expected=2/115"
[[ "$arch_rc" -eq 2 ]] ||
  fail "architecture inventory did not return expected make-level RED rc=2: rc=$arch_rc"
grep -Fq 'OOO-2: GREEN (0 red checks)' "$EVIDENCE_DIR/architecture-gates.log" ||
  fail "OOO-2 lost scoped GREEN"
grep -Fq 'OVERALL: RED' "$EVIDENCE_DIR/architecture-gates.log" ||
  fail "architecture inventory lost truthful OVERALL RED"
grep -Fq 'OK' "$EVIDENCE_DIR/architecture-gates.log" ||
  fail "architecture checker self-tests did not pass"

arch_test_expected=$(grep -Ec '^[[:space:]]+def test_' \
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py")
arch_test_actual=$(sed -n \
  's/^Ran \([0-9][0-9]*\) tests.*/\1/p' \
  "$EVIDENCE_DIR/architecture-gates.log")
[[ "$arch_test_actual" == "$arch_test_expected" ]] ||
  fail "architecture checker self-test inventory mismatch: actual=$arch_test_actual expected=$arch_test_expected"

contract_counts=$(sed -n \
  's/.*当前=\([0-9][0-9]*\) 基线=\([0-9][0-9]*\).*/\1 \2/p' \
  "$EVIDENCE_DIR/check-contract.log")
[[ $(printf '%s\n' "$contract_counts" | grep -c .) -eq 1 ]] ||
  fail "could not extract one current/baseline assertion count"
read -r contract_current contract_baseline <<< "$contract_counts"
[[ "$contract_current" -ge "$contract_baseline" ]] ||
  fail "contract assertion count regressed: current=$contract_current baseline=$contract_baseline"

{
  printf '# v8m static gate summary\n\n'
  printf -- '- RTL style: PASS\n'
  printf -- '- ProducerId holder census: PASS\n'
  printf -- '- check-contract: PASS (%s immediate assertions >= %s baseline)\n' \
    "$contract_current" "$contract_baseline"
  printf -- '- full lint: inherited rc=%s, warnings=%s (signature unchanged; not promoted to PASS)\n' \
    "$lint_rc" "$warning_count"
  printf -- '- architecture checker self-tests: %s/%s PASS\n' \
    "$arch_test_actual" "$arch_test_expected"
  printf -- '- OOO-2 selective scheduling: scoped GREEN\n'
  printf -- '- real architecture inventory: OVERALL RED; no PPA promotion\n'
} > "$EVIDENCE_DIR/summary.md"

find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8M-STATIC][PASS] style/census/contract; lint=2/115; OOO-2=GREEN; architecture=RED\n' \
  >> "$EVIDENCE_DIR/complete.marker"
printf '[V8M-STATIC][PASS] style/census/contract lint=2/115 OOO-2=GREEN architecture=OVERALL_RED\n'

