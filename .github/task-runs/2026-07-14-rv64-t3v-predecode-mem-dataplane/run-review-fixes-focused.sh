#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
EVIDENCE_DIR="$TASK_DIR/evidence/review-fixes"
MODULE_DIR="$EVIDENCE_DIR/module"
BUILD_DIR="$EVIDENCE_DIR/build"

mkdir -p "$MODULE_DIR" "$BUILD_DIR"

python3 "$ROOT_DIR/scripts/github_index_db.py" brief \
  'T3V memory reservation MIQ branch kill LR SC' --profile npc \
  >"$EVIDENCE_DIR/context-brief.txt"

make -B -C "$ROOT_DIR/npc/rv64/testbench" \
  BUILD_DIR="$BUILD_DIR" \
  RESULT_DIR="$MODULE_DIR" \
  "$MODULE_DIR/logs/tb_ooo_int_backend.log" \
  "$MODULE_DIR/logs/tb_ooo_int_issue_queue.log"

cp -- "$MODULE_DIR/logs/tb_ooo_int_backend.log" \
  "$EVIDENCE_DIR/tb_ooo_int_backend.log"
cp -- "$MODULE_DIR/logs/tb_ooo_int_issue_queue.log" \
  "$EVIDENCE_DIR/tb_ooo_int_issue_queue.log"

make -C "$ROOT_DIR/npc/rv64" lint \
  >"$EVIDENCE_DIR/verilator-lint.log" 2>&1
make -C "$ROOT_DIR/npc/rv64" check-rtl-style \
  >"$EVIDENCE_DIR/rtl-style.log" 2>&1
make -C "$ROOT_DIR/npc/rv64" check-contract \
  >"$EVIDENCE_DIR/contract.log" 2>&1

git -C "$ROOT_DIR" diff --check -- \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  npc/rv64/design/specs/ooo-int-issue-queue.md \
  >"$EVIDENCE_DIR/diff-check.log" 2>&1

{
  printf 'T3V review-fix focused verification PASS\n'
  printf 'command=.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/run-review-fixes-focused.sh\n'
  printf 'build_dir=%s\n' "$BUILD_DIR"
  printf 'result_dir=%s\n' "$MODULE_DIR"
  printf 'git_head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf '\n[input-sha256]\n'
  sha256sum \
    "$ROOT_DIR/npc/rv64/vsrc/execute/OooIntBackend.v" \
    "$ROOT_DIR/npc/rv64/testbench/tests/tb_ooo_int_backend.sv" \
    "$ROOT_DIR/npc/rv64/design/specs/ooo-int-issue-queue.md"
  printf '\n[evidence-sha256]\n'
  sha256sum \
    "$EVIDENCE_DIR/tb_ooo_int_backend.log" \
    "$EVIDENCE_DIR/tb_ooo_int_issue_queue.log" \
    "$EVIDENCE_DIR/verilator-lint.log" \
    "$EVIDENCE_DIR/rtl-style.log" \
    "$EVIDENCE_DIR/contract.log" \
    "$EVIDENCE_DIR/diff-check.log"
  printf '\n[int-backend-markers]\n'
  grep -E '\[T3V-(MEM-RES-RELEASE|MEM-BUFFER-KILL|MIQ-FULL-POP|LRSC-WIDTH-MISALIGN)\]|\[PASS\]|\[RESULT\]' \
    "$EVIDENCE_DIR/tb_ooo_int_backend.log"
  printf '\n[int-iq-result]\n'
  grep -E '\[PASS\]|\[RESULT\]' "$EVIDENCE_DIR/tb_ooo_int_issue_queue.log"
} >"$EVIDENCE_DIR/summary.txt"

cat "$EVIDENCE_DIR/summary.txt"
