#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage"
output_log="${task_run_dir}/evidence/arch-stable-unittest.log"

mkdir -p "$(dirname "${output_log}")"
cd "${repo_root}"

set +e
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_arch_stable_freeze \
  > "${output_log}" 2>&1
test_rc=$?
set -e

if [[ "${test_rc}" -ne 1 ]]; then
  echo "[V11F-ARCH-STABLE-OBSERVATION][FAIL] unexpected unittest rc=${test_rc}" |
    tee -a "${output_log}"
  exit 1
fi

if [[ "$(grep -c ' \.\.\. FAIL$' "${output_log}")" -ne 2 ]] ||
   ! grep -Fq \
     "test_control_event_debt_evidence_is_current (npc.rv64.eval.ppa.tests.test_arch_stable_freeze.CurrentWorkspaceTests.test_control_event_debt_evidence_is_current) ... FAIL" \
     "${output_log}" ||
   ! grep -Fq \
     "test_current_candidate_is_honest_gap_with_dynamic_inventory (npc.rv64.eval.ppa.tests.test_arch_stable_freeze.CurrentWorkspaceTests.test_current_candidate_is_honest_gap_with_dynamic_inventory) ... FAIL" \
     "${output_log}" ||
   ! grep -Fq "Ran 53 tests" "${output_log}" ||
   ! grep -Fq "FAILED (failures=2)" "${output_log}"; then
  echo "[V11F-ARCH-STABLE-OBSERVATION][FAIL] unexpected failure set" |
    tee -a "${output_log}"
  exit 1
fi

echo "[V11F-ARCH-STABLE-OBSERVATION] EXPECTED_GAP pass=51 fail=2 v11f_new_failures=0" |
  tee -a "${output_log}"
