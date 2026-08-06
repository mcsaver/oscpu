#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"

printf '%s\n' \
  "[V9L-FUNCTIONAL][RETIRED] forwarding to immutable current-design runner" >&2
exec "${root}/npc/rv64/eval/ppa/run-full-core-current.sh" "$@"
