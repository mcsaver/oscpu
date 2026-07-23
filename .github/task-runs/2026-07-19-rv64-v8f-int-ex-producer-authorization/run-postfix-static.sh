#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
EVIDENCE_DIR="$RUN_DIR/evidence"
V8D_LINT="$REPO_ROOT/.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/evidence/full-lint.normalized"
LINT_LOG="$EVIDENCE_DIR/full-lint-postfix.log"
LINT_NORMALIZED="$EVIDENCE_DIR/full-lint-postfix.normalized"

python3 "$RUN_DIR/audit-v8f-wb-credit-cut.py" |
  tee "$EVIDENCE_DIR/wb-credit-cut-audit-postfix.log"
make -C "$REPO_ROOT/npc/rv64" check-rtl-style 2>&1 |
  tee "$EVIDENCE_DIR/check-rtl-style-postfix.log"
make -C "$REPO_ROOT/npc/rv64" check-contract 2>&1 |
  tee "$EVIDENCE_DIR/check-contract-postfix.log"

set +e
make -C "$REPO_ROOT/npc/rv64" lint > "$LINT_LOG" 2>&1
lint_rc=$?
set -e
printf '%s\n' "$lint_rc" > "$EVIDENCE_DIR/full-lint-postfix.rc"

grep '^%Warning-' "$LINT_LOG" |
  sed -E \
    's#/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/#VSRCDIR/#g; s/:[0-9]+:[0-9]+:/:LINE:COL:/' \
    > "$LINT_NORMALIZED"
warning_count=$(wc -l < "$LINT_NORMALIZED")
normalized_sha=$(sha256sum "$LINT_NORMALIZED" | cut -d' ' -f1)

[[ "$lint_rc" -eq 2 ]] || {
  printf '[V8F-POSTFIX-STATIC][FAIL] unexpected lint rc=%s\n' "$lint_rc" >&2
  exit 1
}
[[ "$warning_count" -eq 115 ]] || {
  printf '[V8F-POSTFIX-STATIC][FAIL] warning count=%s expected=115\n' \
    "$warning_count" >&2
  exit 1
}
cmp -s "$LINT_NORMALIZED" "$V8D_LINT" || {
  printf '[V8F-POSTFIX-STATIC][FAIL] normalized lint drifted from v8d\n' >&2
  exit 1
}

printf 'lint_rc=%s\nwarning_count=%s\nnormalized_sha256=%s\nnormalized_cmp_v8d=PASS\n' \
  "$lint_rc" "$warning_count" "$normalized_sha" \
  > "$EVIDENCE_DIR/full-lint-postfix.status"
printf '[V8F-POSTFIX-STATIC] PASS lint_rc=%s inherited_warnings=%s sha256=%s\n' \
  "$lint_rc" "$warning_count" "$normalized_sha"
