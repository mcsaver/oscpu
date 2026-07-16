#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"

export SYNTH_TASK_SLUG=2026-07-14-rv64-t4c-walk-lookup-payload-owner
export SYNTH_LABEL=T4C
export SYNTH_EXPECTED_RTL_COUNT=112
export SYNTH_RUN_SCRIPT_INPUT="$ROOT_DIR/.github/task-runs/$SYNTH_TASK_SLUG/run-fresh-synthesis.sh"
export SYNTH_AUDIT_SCRIPT_INPUT="$COMMON_TASK/audit-t3p-synthesis.py"
export SYNTH_OPENSTA_SCRIPT_INPUT="$ROOT_DIR/.github/task-runs/$SYNTH_TASK_SLUG/run-global-opensta.sh"
export SYNTH_COMMON_RUNNER_INPUT="$COMMON_TASK/run-fresh-synthesis.sh"

exec "$COMMON_TASK/run-fresh-synthesis.sh"
