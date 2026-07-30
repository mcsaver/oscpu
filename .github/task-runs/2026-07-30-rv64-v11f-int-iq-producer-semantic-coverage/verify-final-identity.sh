#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage"
canonical_evidence="${task_run_dir}/evidence/int-iq-producer-attempt-3"
previous_ledger="${repo_root}/.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage/evidence/semantic-coverage-ledger.json"
current_ledger="${task_run_dir}/evidence/semantic-coverage-ledger.json"
output_log="${task_run_dir}/evidence/final-identity.log"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
temporary_binding="$(mktemp /tmp/v11f-final-rtl.XXXXXX.json)"
temporary_ledger="$(mktemp "${task_run_dir}/evidence/.v11f-final-ledger.XXXXXX.json")"

cleanup() {
  rm -f -- "${temporary_binding}" "${temporary_ledger}"
}
trap cleanup EXIT

exec > >(tee "${output_log}") 2>&1
cd "${repo_root}"

cmp "${canonical_evidence}/sources.pre.sha256" \
  "${canonical_evidence}/sources.post.sha256"
sha256sum -c "${canonical_evidence}/sources.post.sha256"

python3 "${snapshot_tool}" --snapshot-out "${temporary_binding}"
cmp "${temporary_binding}" "${canonical_evidence}/rtl-source-binding.post.json"
cmp "${canonical_evidence}/rtl-source-binding.pre.json" \
  "${canonical_evidence}/rtl-source-binding.post.json"

printf '%s  %s\n' \
  "89eb9d8e126b81cf0441640320c1df9f47101c05cfd0e7754fb2deda886b41ce" \
  "${canonical_evidence}/summary.json" |
  sha256sum -c -

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  --root "${repo_root}" \
  build \
  --output "${temporary_ledger}"
cmp "${temporary_ledger}" "${current_ledger}"

python3 - \
  "${canonical_evidence}/summary.json" \
  "${previous_ledger}" \
  "${current_ledger}" <<'PY'
import json
import pathlib
import sys

summary = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
previous = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
current = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))

assert summary["status"] == "PASS"
assert summary["schema"] == "rv64-v11f-int-iq-producer-semantic-evidence-v1"
assert summary["design_id"] == (
    "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375"
)
assert summary["unit_ids"] == ["integer-iq-producers"]
assert summary["counts"] == {
    "compile_success_mutation_cases": 20,
    "mutation_simulations": 40,
    "positive_profiles": 4,
    "rejected_mutation_simulations": 40,
}
assert set(summary["positive_profiles"]) == {
    "assert-g1",
    "assert-g4",
    "release-g1",
    "release-g4",
}
assert len(summary["mutations"]) == 20
assert summary["independent_oracle"]["checks_all_entries"] is True
assert summary["independent_oracle"]["checks_all_generation_bits"] is True
assert summary["independent_oracle"]["checks_every_directed_edge"] is True
assert summary["independent_oracle"]["checks_raw_identity_knownness"] is True

for name, profile in summary["positive_profiles"].items():
    assert profile["assertions_enabled"] is name.startswith("assert-")
    assert profile["generation_width"] == (1 if name.endswith("g1") else 4)

for mutation in summary["mutations"]:
    assert set(mutation["runs"]) == {"g1", "g4"}
    for width_name, run in mutation["runs"].items():
        assert run["assertions_enabled"] is False
        assert run["generation_width"] == (1 if width_name == "g1" else 4)
        assert run["simulation_rc"] == 1
        assert "-DOOO_ASSERT" not in run["compile_command"]

previous_status = {unit["id"]: unit["semantic_status"] for unit in previous["units"]}
current_status = {unit["id"]: unit["semantic_status"] for unit in current["units"]}
assert set(previous_status) == set(current_status)
changed = {
    unit_id: (previous_status[unit_id], current_status[unit_id])
    for unit_id in previous_status
    if previous_status[unit_id] != current_status[unit_id]
}
assert changed == {"integer-iq-producers": ("GAP", "PASS")}
assert current["counts"]["semantic_units"] == 44
assert current["counts"]["holder_instances"] == 17
assert current["counts"]["unit_instance_bindings"] == 50
assert current["counts"]["units_semantic_pass"] == 8
assert current["counts"]["units_semantic_gap"] == 36
assert current["status"] == "GAP"
assert current["promotion"]["whole_architecture"] == "RED"
assert current["promotion"]["ppa"] == "UNPROMOTED"
PY

grep -Fq "Ran 8 tests" "${canonical_evidence}/evidence-tool-unit.log"
grep -Fq "Ran 22 tests" "${task_run_dir}/evidence/semantic-ledger-unit.log"
grep -Fq "OK" "${task_run_dir}/evidence/semantic-ledger-unit.log"
grep -Fq "[PASS] tb_ooo_int_issue_queue" \
  "${task_run_dir}/evidence/module-regression/logs/tb_ooo_int_issue_queue.log"
grep -Fq "[RESULT] PASS" \
  "${task_run_dir}/evidence/module-regression/logs/tb_ooo_int_issue_queue.log"
grep -Fq \
  "[V11F-ARCH-STABLE-OBSERVATION] EXPECTED_GAP pass=51 fail=2 v11f_new_failures=0" \
  "${task_run_dir}/evidence/arch-stable-unittest.log"
grep -Fq "[V11F-SCOPED-GUARD][PASS] paths=8 profile=npc-dev" \
  "${task_run_dir}/evidence/scoped-strict-guard.log"
grep -Fq \
  "[V11F-FULL-GUARD] EXPECTED_GAP profile=rv64-linux scope=shared-worktree" \
  "${task_run_dir}/evidence/full-worktree-strict-guard.log"

python3 \
  .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${task_run_dir}/subagent-contracts/v11f-int-iq-producer-pre-review.json"
python3 \
  .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${task_run_dir}/subagent-contracts/v11f-int-iq-producer-final-review.json"

bash -n \
  "${task_run_dir}/run-int-iq-producer-focused.sh" \
  "${task_run_dir}/run-arch-stable-observation.sh" \
  "${task_run_dir}/run-guards.sh" \
  "${task_run_dir}/audit-commit-gate.sh" \
  "${task_run_dir}/verify-final-identity.sh"

git diff --check -- \
  npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv \
  npc/rv64/eval/ppa/tools/int_iq_producer_semantic_evidence.py \
  npc/rv64/eval/ppa/tests/test_int_iq_producer_semantic_evidence.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  npc/rv64/design/specs/ooo-int-issue-queue.md \
  .github/memory/project-status.md \
  .github/memory/modules/npc.md

echo "[V11F-FINAL-IDENTITY][PASS] design_id=sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375 iq_sha256=d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b ledger=8/36"
