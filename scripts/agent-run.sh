#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# Keep manual Codex/WSL commands on the same soft environment path as agent-e2e.
source "$REPO_ROOT/scripts/agent-env.sh"

if [[ $# -eq 0 ]]; then
  echo "usage: scripts/agent-run.sh <command> [args...]" >&2
  exit 2
fi

exec "$@"
