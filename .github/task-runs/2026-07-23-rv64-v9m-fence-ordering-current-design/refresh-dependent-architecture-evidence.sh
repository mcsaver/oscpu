#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

# The shared RV64 Makefiles, full-core privilege testbench and semantic freeze
# validator are provenance-bound by these already-closed architecture debts.
# Re-run their canonical local RTL evidence commands after those shared files
# change so ARCH_STABLE never accepts a metadata-only hash refresh.
targets=(
  check-fdg-arch-trap
  check-xret-current-mode
  check-instret-retirement
  check-memory-issue-lifecycle
  check-ifu-axi-flush-drain
  check-ifu-fetch-provenance
  check-ifu-access
  check-ifu-tval
  check-ptw-pmp
)

for target in "${targets[@]}"; do
  printf '[FENCE-G1-DEPENDENT-EVIDENCE] target=%s state=START\n' "$target"
  make -C "$root/npc/rv64" "$target"
  printf '[FENCE-G1-DEPENDENT-EVIDENCE] target=%s state=PASS\n' "$target"
done

printf '[FENCE-G1-DEPENDENT-EVIDENCE] refreshed=%d status=PASS\n' \
  "${#targets[@]}"
