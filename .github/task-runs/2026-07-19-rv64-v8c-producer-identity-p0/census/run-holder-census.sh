#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../../.." && pwd)"
EVIDENCE_DIR="${SCRIPT_DIR}/../evidence/census"
mkdir -p "${EVIDENCE_DIR}"

PYTHONDONTWRITEBYTECODE=1 python3 -B "${SCRIPT_DIR}/check-holder-census.py" \
  --repo-root "${REPO_ROOT}" \
  --manifest "${SCRIPT_DIR}/holder-census.json" \
  --self-test | tee "${EVIDENCE_DIR}/census.log"

sha256sum \
  "${SCRIPT_DIR}/check-holder-census.py" \
  "${SCRIPT_DIR}/holder-census.json" \
  "${SCRIPT_DIR}/contract.md" \
  "${SCRIPT_DIR}/run-holder-census.sh" \
  >"${EVIDENCE_DIR}/census-inputs.sha256"

find "${REPO_ROOT}/npc/rv64/vsrc" -type f \
  \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print0 | sort -z | xargs -0 sha256sum \
  >"${EVIDENCE_DIR}/production-sources.sha256"
