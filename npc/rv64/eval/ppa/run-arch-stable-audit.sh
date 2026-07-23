#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../../.." && pwd)"
CANDIDATE="${REPO_ROOT}/npc/rv64/eval/ppa/arch-stable/full-core-current.json"
RESULT="${ARCH_STABLE_RESULT:-${REPO_ROOT}/npc/rv64/eval/ppa/evidence/arch-stable-current.json}"
REQUIRE_STABLE=0

if [[ "${1:-}" == "--require-stable" ]]; then
  REQUIRE_STABLE=1
elif [[ -n "${1:-}" ]]; then
  printf 'usage: %s [--require-stable]\n' "$0" >&2
  exit 64
fi

cd "${REPO_ROOT}"
python3 -m unittest -v \
  npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py \
  npc/rv64/eval/ppa/tests/test_fdg_arch_trap_evidence.py \
  npc/rv64/eval/ppa/tests/test_xret_current_mode_evidence.py \
  npc/rv64/eval/ppa/tests/test_instret_retirement_evidence.py \
  npc/rv64/eval/ppa/tests/test_memory_issue_lifecycle_evidence.py \
  npc/rv64/eval/ppa/tests/test_ifu_axi_flush_drain_evidence.py \
  npc/rv64/eval/ppa/tests/test_ifu_fetch_provenance_evidence.py \
  npc/rv64/eval/ppa/tests/test_ifu_access_evidence.py \
  npc/rv64/eval/ppa/tests/test_ifu_tval_evidence.py \
  npc/rv64/eval/ppa/tests/test_ptw_pmp_evidence.py

audit_args=(
  audit
  "${CANDIDATE}"
  --output "${RESULT}"
)
verify_args=(verify "${RESULT}")
if [[ "${REQUIRE_STABLE}" -eq 1 ]]; then
  audit_args+=(--require-stable)
  verify_args+=(--require-stable)
fi

python3 npc/rv64/eval/ppa/tools/arch_stable_freeze.py "${audit_args[@]}"
python3 npc/rv64/eval/ppa/tools/arch_stable_freeze.py "${verify_args[@]}"
printf '[ARCH-STABLE-EVIDENCE] %s\n' "${RESULT}"
