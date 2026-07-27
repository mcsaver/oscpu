#!/usr/bin/env bash
set -o pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
run_root="$repo_root/.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear"

cd "$repo_root"
scripts/agent-e2e.sh --guard --guard-mode strict 2>&1 |
  tee "$run_root/strict-guard.log"
