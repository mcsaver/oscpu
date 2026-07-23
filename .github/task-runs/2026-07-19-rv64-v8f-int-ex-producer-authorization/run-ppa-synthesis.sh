#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
RUN_ID=${1:-run1}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[V8F-PPA-SYNTH] invalid run id: %s\n' "$RUN_ID" >&2; exit 64 ;;
esac

RUN_DIR="$ROOT_DIR/.github/task-runs/2026-07-19-rv64-v8f-int-ex-producer-authorization"
COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
SYNTH_SLUG="2026-07-19-rv64-v8f-int-ex-producer-authorization/evidence/ppa-current/fresh-synth-$RUN_ID"
SYNTH_TASK="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/2026-07-15-rv64-ppa-architecture-recovery/evidence/r4-p0a-wb-valid/fresh-synth-run1/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CANONICAL_AUDIT="$SYNTH_TASK/evidence/synthesis/summary.json"

if [[ -e "$TMP_DIR" || -e "$CANONICAL_AUDIT" ]]; then
  printf '[V8F-PPA-SYNTH] refusing stale output: %s or %s\n' \
    "$TMP_DIR" "$CANONICAL_AUDIT" >&2
  exit 2
fi
[[ -f "$PREVIOUS_NETLIST" && ! -L "$PREVIOUS_NETLIST" && -s "$PREVIOUS_NETLIST" ]] || {
  printf '[V8F-PPA-SYNTH] invalid comparison netlist: %s\n' "$PREVIOUS_NETLIST" >&2
  exit 2
}

export TMPDIR="$TMP_DIR/tool-tmp"
mkdir -p "$TMPDIR"
export SYNTH_TASK_SLUG="$SYNTH_SLUG"
export SYNTH_LABEL="V8F-PPA-${RUN_ID^^}"
export SYNTH_EXPECTED_RTL_COUNT=122
export SYNTH_RUN_SCRIPT_INPUT="$RUN_DIR/run-ppa-synthesis.sh"
export SYNTH_AUDIT_SCRIPT_INPUT="$T4Q_TASK/audit-t4q-synthesis.py"
export SYNTH_OPENSTA_SCRIPT_INPUT="$RUN_DIR/run-ppa-opensta.sh"
export SYNTH_COMMON_RUNNER_INPUT="$COMMON_TASK/run-fresh-synthesis.sh"
"$COMMON_TASK/run-fresh-synthesis.sh"

python3 "$T4Q_TASK/audit-t4q-synthesis.py" "$TMP_DIR" \
  --prefix "V8F-PPA-${RUN_ID^^}-SYNTH-AUDIT" \
  --json-out "$CANONICAL_AUDIT" \
  --expected-rtl-count 122 \
  --expected-evidence-count 7 \
  --expected-module-count 121 \
  --required-pipestage-width 149 \
  --previous-netlist "$PREVIOUS_NETLIST" \
  > "$SYNTH_TASK/evidence/synthesis/audit.log" 2>&1

printf '[V8F-PPA-SYNTH] PASS run=%s audit=%s\n' "$RUN_ID" "$CANONICAL_AUDIT"
