#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${repo_root}"

# Rebuild each CLOSED architecture record whose source binding includes the
# shared arch_stable_freeze.py validator extended by IFU-ACCESS-G1.
make -C npc/rv64 check-fdg-arch-trap
make -C npc/rv64 check-xret-current-mode
make -C npc/rv64 check-memory-issue-lifecycle
make -C npc/rv64 check-ifu-axi-flush-drain
make -C npc/rv64 check-ifu-fetch-provenance
make -C npc/rv64 check-instret-retirement
