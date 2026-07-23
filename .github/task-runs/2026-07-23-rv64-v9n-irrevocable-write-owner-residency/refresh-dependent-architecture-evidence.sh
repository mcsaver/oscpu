#!/usr/bin/env bash
set -euo pipefail

# Rebuild only the already-closed local RV64 architecture-debt evidence whose
# provenance binds the shared processor Makefiles or architecture-freeze
# validator changed by V9N.  Each target owns its focused RTL simulations,
# source-variant checks and exact evidence publication.

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
log="$run_dir/evidence/dependent-architecture-refresh.log"

mkdir -p "$run_dir/evidence"
: > "$log"

targets=(
  check-fence-ordering
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
  printf '[V9N-DEPENDENT-EVIDENCE] target=%s state=START\n' "$target" | tee -a "$log"
  make -C "$repo_root/npc/rv64" "$target" 2>&1 | tee -a "$log"
  printf '[V9N-DEPENDENT-EVIDENCE] target=%s state=PASS\n' "$target" | tee -a "$log"
done

printf '[V9N-DEPENDENT-EVIDENCE] refreshed=%d status=PASS\n' \
  "${#targets[@]}" | tee -a "$log"
