#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
COMMON_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"

export STA_TASK_SLUG=2026-07-14-rv64-t4b-fifo-head-presence
export STA_LABEL=T4B
export STA_OUT_STEM=opensta-fresh-t4b
export STA_SCRIPT_INPUT="$ROOT_DIR/.github/task-runs/$STA_TASK_SLUG/run-global-opensta.sh"

exec "$COMMON_TASK/run-global-opensta.sh"
