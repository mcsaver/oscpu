#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
RUN_ID=${1:-run1}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[PPA-R3P6-SYNTH] invalid run id: %s\n' "$RUN_ID" >&2; exit 64 ;;
esac

COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
PARENT_SLUG=2026-07-15-rv64-ppa-architecture-recovery
PARENT_TASK="$ROOT_DIR/.github/task-runs/$PARENT_SLUG"
SYNTH_SLUG="$PARENT_SLUG/evidence/ppa-r3p6-onehot-prf/fresh-synth-$RUN_ID"
TASK_DIR="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/$PARENT_SLUG/evidence/ppa-r3p3-r3p4-canonical/fresh-synth-run1/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CANONICAL_AUDIT="$TASK_DIR/evidence/synthesis/summary.json"

if [[ -e $TMP_DIR || -e $CANONICAL_AUDIT ]]; then
  printf '[PPA-R3P6-SYNTH] refusing stale output: %s or %s\n' \
    "$TMP_DIR" "$CANONICAL_AUDIT" >&2
  exit 2
fi

export TMPDIR="$TMP_DIR/tool-tmp"
mkdir -p "$TMPDIR"
export SYNTH_TASK_SLUG="$SYNTH_SLUG"
export SYNTH_LABEL="PPA-R3P6-${RUN_ID^^}"
export SYNTH_EXPECTED_RTL_COUNT=116
export SYNTH_RUN_SCRIPT_INPUT="$PARENT_TASK/run-ppa-r3p6-synthesis.sh"
export SYNTH_AUDIT_SCRIPT_INPUT="$T4Q_TASK/audit-t4q-synthesis.py"
export SYNTH_OPENSTA_SCRIPT_INPUT="$PARENT_TASK/run-ppa-r3p6-opensta.sh"
export SYNTH_COMMON_RUNNER_INPUT="$COMMON_TASK/run-fresh-synthesis.sh"
"$COMMON_TASK/run-fresh-synthesis.sh"

python3 "$T4Q_TASK/audit-t4q-synthesis.py" "$TMP_DIR" \
  --prefix "PPA-R3P6-${RUN_ID^^}-SYNTH-AUDIT" \
  --json-out "$CANONICAL_AUDIT" \
  --expected-rtl-count 116 \
  --expected-evidence-count 7 \
  --expected-module-count 118 \
  --previous-netlist "$PREVIOUS_NETLIST" \
  >"$TASK_DIR/evidence/synthesis/audit.log" 2>&1

printf '[PPA-R3P6-SYNTH] PASS run=%s audit=%s\n' "$RUN_ID" "$CANONICAL_AUDIT"

