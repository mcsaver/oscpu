#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
PARENT_SLUG=2026-07-15-rv64-ppa-architecture-recovery
SYNTH_SLUG="$PARENT_SLUG/ppa-r2p4-frontend"
PARENT_TASK="$ROOT_DIR/.github/task-runs/$PARENT_SLUG"
TASK_DIR="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/$PARENT_SLUG/ppa-r2p3-frontend/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CANONICAL_AUDIT="$TASK_DIR/evidence/synthesis/summary.json"

if [[ -e $TMP_DIR || -e $CANONICAL_AUDIT ]]; then
  printf '[PPA-R2P4F-SYNTH] refusing stale task output: %s or %s\n' "$TMP_DIR" "$CANONICAL_AUDIT" >&2
  exit 2
fi

export TMPDIR="$TMP_DIR/tool-tmp"
mkdir -p "$TMPDIR"
export SYNTH_TASK_SLUG="$SYNTH_SLUG"
export SYNTH_LABEL=PPA-R2P4F
export SYNTH_EXPECTED_RTL_COUNT=115
export SYNTH_RUN_SCRIPT_INPUT="$PARENT_TASK/run-ppa-r2p4-frontend-synthesis.sh"
export SYNTH_AUDIT_SCRIPT_INPUT="$T4Q_TASK/audit-t4q-synthesis.py"
export SYNTH_OPENSTA_SCRIPT_INPUT="$PARENT_TASK/run-ppa-r2p4-frontend-opensta.sh"
export SYNTH_COMMON_RUNNER_INPUT="$COMMON_TASK/run-fresh-synthesis.sh"
"$COMMON_TASK/run-fresh-synthesis.sh"

python3 "$T4Q_TASK/audit-t4q-synthesis.py" "$TMP_DIR"   --prefix PPA-R2P4F-SYNTH-AUDIT --json-out "$CANONICAL_AUDIT"   --expected-rtl-count 115 --expected-evidence-count 7 --expected-module-count 117   --previous-netlist "$PREVIOUS_NETLIST"   >"$TASK_DIR/evidence/synthesis/audit.log" 2>&1
printf '[PPA-R2P4F-SYNTH] PASS canonical audit=%s\n' "$CANONICAL_AUDIT"
