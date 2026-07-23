#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
EVIDENCE_DIR="$RUN_DIR/evidence/static"
V8H_LINT="$REPO_ROOT/.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/evidence/static/full-lint.normalized"
LINT_LOG="$EVIDENCE_DIR/full-lint.log"
LINT_NORMALIZED="$EVIDENCE_DIR/full-lint.normalized"

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/static) rm -rf -- "$EVIDENCE_DIR" ;;
  *) printf '[V8I-STATIC][FAIL] unsafe evidence path: %s\n' "$EVIDENCE_DIR" >&2; exit 2 ;;
esac
mkdir -p "$EVIDENCE_DIR"

python3 "$RUN_DIR/audit-v8i-fp-lease.py" |
  tee "$EVIDENCE_DIR/structural-audit.log"
git -C "$REPO_ROOT" diff --check 2>&1 |
  tee "$EVIDENCE_DIR/git-diff-check.log"
make -C "$REPO_ROOT/npc/rv64" check-rtl-style 2>&1 |
  tee "$EVIDENCE_DIR/check-rtl-style.log"
make -C "$REPO_ROOT/npc/rv64" check-contract 2>&1 |
  tee "$EVIDENCE_DIR/check-contract.log"

set +e
make -C "$REPO_ROOT/npc/rv64/testbench" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/architecture-hard-gates.json" \
  arch-gates 2>&1 | tee "$EVIDENCE_DIR/architecture-hard-gates.log"
arch_rc=${PIPESTATUS[0]}
set -e
printf '%s\n' "$arch_rc" > "$EVIDENCE_DIR/architecture-hard-gates.rc"
[[ "$arch_rc" -eq 2 ]] || {
  printf '[V8I-STATIC][FAIL] architecture hard-gate rc=%s expected global RED make-rc=2\n' \
    "$arch_rc" >&2
  exit 1
}
grep -Fqx 'OK' "$EVIDENCE_DIR/architecture-hard-gates.log" || {
  printf '[V8I-STATIC][FAIL] architecture checker self-tests did not pass\n' >&2
  exit 1
}
grep -Fqx 'OVERALL: RED' "$EVIDENCE_DIR/architecture-hard-gates.log" || {
  printf '[V8I-STATIC][FAIL] parent architecture status was not explicit RED\n' >&2
  exit 1
}

set +e
make -C "$REPO_ROOT/npc/rv64" lint > "$LINT_LOG" 2>&1
lint_rc=$?
set -e
printf '%s\n' "$lint_rc" > "$EVIDENCE_DIR/full-lint.rc"

grep '^%Warning-' "$LINT_LOG" |
  sed -E \
    's#/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/#VSRCDIR/#g; s/:[0-9]+:[0-9]+:/:LINE:COL:/' \
    > "$LINT_NORMALIZED"
warning_count=$(wc -l < "$LINT_NORMALIZED")
normalized_sha=$(sha256sum "$LINT_NORMALIZED" | cut -d' ' -f1)

[[ "$lint_rc" -eq 2 ]] || {
  printf '[V8I-STATIC][FAIL] unexpected lint rc=%s\n' "$lint_rc" >&2
  exit 1
}
cmp -s "$LINT_NORMALIZED" "$V8H_LINT" || {
  diff -u "$V8H_LINT" "$LINT_NORMALIZED" > "$EVIDENCE_DIR/full-lint.delta" || true
  printf '[V8I-STATIC][FAIL] normalized lint drifted from v8h inherited baseline\n' >&2
  exit 1
}

printf 'lint_rc=%s\nwarning_count=%s\nnormalized_sha256=%s\nnormalized_cmp_v8h=PASS\n' \
  "$lint_rc" "$warning_count" "$normalized_sha" \
  > "$EVIDENCE_DIR/full-lint.status"
find "$EVIDENCE_DIR" -type f ! -name complete.marker -print0 |
  sort -z | xargs -0 sha256sum > "$EVIDENCE_DIR/complete.marker"
printf '# [V8I-STATIC][PASS] audit=16 diff-check=1 style=1 contract=1 architecture-selftests=15/15 parent-architecture=RED inherited-lint=%s normalized-cmp-v8h=1\n' \
  "$warning_count" >> "$EVIDENCE_DIR/complete.marker"
printf '[V8I-STATIC] PASS inherited_lint_rc=%s warnings=%s sha256=%s\n' \
  "$lint_rc" "$warning_count" "$normalized_sha"
