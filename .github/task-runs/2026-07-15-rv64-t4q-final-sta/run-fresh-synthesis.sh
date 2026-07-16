#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
TASK_SLUG=2026-07-15-rv64-t4q-final-sta
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$TASK_SLUG"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/2026-07-14-rv64-t4i-standard-axi-lanes/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CANONICAL_AUDIT="$TASK_DIR/evidence/synthesis/summary.json"

if [[ -e $TMP_DIR || -e $CANONICAL_AUDIT ]]; then
  printf '[T4Q-SYNTH] refusing stale task output: %s or %s\n' "$TMP_DIR" "$CANONICAL_AUDIT" >&2
  exit 2
fi

export SYNTH_TASK_SLUG="$TASK_SLUG"
export SYNTH_LABEL=T4Q
export SYNTH_EXPECTED_RTL_COUNT=115
export SYNTH_RUN_SCRIPT_INPUT="$TASK_DIR/run-fresh-synthesis.sh"
export SYNTH_AUDIT_SCRIPT_INPUT="$TASK_DIR/audit-t4q-synthesis.py"
export SYNTH_OPENSTA_SCRIPT_INPUT="$TASK_DIR/run-global-opensta.sh"
export SYNTH_COMMON_RUNNER_INPUT="$COMMON_TASK/run-fresh-synthesis.sh"
"$COMMON_TASK/run-fresh-synthesis.sh"

python3 "$TASK_DIR/audit-t4q-synthesis.py" "$TMP_DIR" \
  --json-out "$CANONICAL_AUDIT" \
  --expected-rtl-count 115 --expected-evidence-count 7 --expected-module-count 117 \
  --previous-netlist "$PREVIOUS_NETLIST" \
  >"$TASK_DIR/evidence/synthesis/audit.log" 2>&1
printf '[T4Q-SYNTH] PASS canonical audit=%s\n' "$CANONICAL_AUDIT"
