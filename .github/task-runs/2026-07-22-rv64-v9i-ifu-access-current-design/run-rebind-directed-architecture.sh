#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${repo_root}"

# DI-2 is the canonical root of the directed-record dependency chain. Its
# runner removes DI-2, invokes DI-1, and DI-1 recursively rebuilds the OOO-4,
# OOO-3, DI-5, DI-3/DI-4 and OOO-1/OOO-2 predecessors before republishing
# DI-1 and finally DI-2. Calling the leaf targets a second time would violate
# their exact sibling-inventory phase contracts.
make -C npc/rv64 check-width-continuity
