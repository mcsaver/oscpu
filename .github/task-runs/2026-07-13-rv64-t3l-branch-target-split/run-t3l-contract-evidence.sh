#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split"
OUT_DIR=${1:-"$TASK_DIR/evidence/current-contract"}

[[ ! -e $OUT_DIR ]] || {
  printf '[T3L-CONTRACT] FAIL stale output=%s\n' "$OUT_DIR" >&2
  exit 2
}
mkdir -p "$OUT_DIR"

inputs=(
  "$ROOT_DIR/npc/rv64/vsrc/frontend/OooFetchBranchTarget.v"
  "$ROOT_DIR/npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"
  "$ROOT_DIR/npc/rv64/vsrc/frontend/OooFrontend.v"
  "$ROOT_DIR/npc/rv64/vsrc/filelist.mk"
  "$TASK_DIR/t3l_branch_target_contract.py"
  "$TASK_DIR/check-t3l-source-contract.py"
  "$TASK_DIR/prove-t3l-target-domain.py"
  "$TASK_DIR/run-t3l-source-mutations.py"
  "$TASK_DIR/check-t3l-negative-log.py"
  "$TASK_DIR/run-t3l-negative-probe.sh"
  "$TASK_DIR/tb-t3l-target-equiv-negative.sv"
)
sha256sum "${inputs[@]}" >"$OUT_DIR/inputs.pre.sha256"

cd "$ROOT_DIR"
python3 "$TASK_DIR/check-t3l-source-contract.py" \
  | tee "$OUT_DIR/source-contract.log"
python3 "$TASK_DIR/check-t3l-source-contract.py" \
  --git-revision 31e90c679 --expect legacy \
  | tee "$OUT_DIR/legacy-source-red.log"
python3 "$TASK_DIR/prove-t3l-target-domain.py" \
  | tee "$OUT_DIR/target-domain.log"
python3 "$TASK_DIR/run-t3l-source-mutations.py" \
  | tee "$OUT_DIR/source-mutations.log"
"$TASK_DIR/run-t3l-negative-probe.sh" "$OUT_DIR/negative-target-equiv" \
  | tee "$OUT_DIR/negative-console.log"

sha256sum "${inputs[@]}" >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256" || {
  printf '[T3L-CONTRACT] FAIL inputs changed during run\n' >&2
  exit 3
}

{
  printf 'status=PASS\n'
  printf 'legacy_source_expected_red=true\n'
  printf 'low_imm_cases=16777216\n'
  printf 'high_wrap_cases=131072\n'
  printf 'source_mutations=7\n'
  printf 'semantic_mutations=5\n'
  printf 'negative_assertion_marker_count=1\n'
  printf 'inputs_frozen=true\n'
} >"$OUT_DIR/complete.txt"

printf '[T3L-CONTRACT] PASS output=%s\n' "$OUT_DIR"
