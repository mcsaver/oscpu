#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage"
canonical_evidence="${task_run_dir}/evidence/store-queue-holder-attempt-1"
previous_ledger="${repo_root}/.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/evidence/semantic-coverage-ledger.json"
current_ledger="${task_run_dir}/evidence/semantic-coverage-ledger.json"
output_log="${task_run_dir}/evidence/final-identity.log"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
temporary_binding="$(mktemp /tmp/v11g-final-rtl.XXXXXX.json)"
temporary_ledger="$(mktemp "${task_run_dir}/evidence/.v11g-final-ledger.XXXXXX.json")"

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
  "cb6d3d9061b008cc716024202886529ebde2e18babcfec5751767f0d80cf817d" \
  "${canonical_evidence}/summary.json" |
  sha256sum -c -
printf '%s  %s\n' \
  "5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241" \
  "npc/rv64/vsrc/memory/OooStoreQueue.v" |
  sha256sum -c -
printf '%s  %s\n' \
  "86ea1b71c03071c965fc09af1068475d0c0bca314b73b6b4338bb23ab1516fb0" \
  "npc/rv64/testbench/tests/tb_ooo_store_queue.sv" |
  sha256sum -c -
git diff --quiet -- npc/rv64/vsrc/memory/OooStoreQueue.v

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
assert summary["schema"] == "rv64-v11g-store-queue-holder-semantic-evidence-v1"
assert summary["design_id"] == (
    "sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375"
)
assert summary["unit_ids"] == [
    "store-queue-owner-tokens",
    "store-queue-producers",
]
assert summary["counts"] == {
    "compile_success_mutation_cases": 24,
    "mutation_simulations": 48,
    "positive_profiles": 4,
    "rejected_mutation_simulations": 48,
}
assert set(summary["positive_profiles"]) == {
    "assert-g1",
    "assert-g4",
    "release-g1",
    "release-g4",
}
assert len(summary["mutations"]) == 24
assert summary["independent_oracle"]["checks_all_entries"] is True
assert summary["independent_oracle"]["checks_all_generation_bits"] is True
assert summary["independent_oracle"]["checks_every_directed_edge"] is True
assert summary["independent_oracle"]["checks_raw_owner_tuple_knownness"] is True
assert summary["independent_oracle"]["checks_raw_producer_id_knownness"] is True
assert summary["independent_oracle"]["stimulus_owned_four_entry_model"] is True
assert summary["independent_oracle"]["uses_asymmetric_token_epoch"] is True

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
assert changed == {
    "store-queue-owner-tokens": ("GAP", "PASS"),
    "store-queue-producers": ("GAP", "PASS"),
}
assert current["counts"]["semantic_units"] == 44
assert current["counts"]["holder_instances"] == 17
assert current["counts"]["unit_instance_bindings"] == 50
assert current["counts"]["units_semantic_pass"] == 10
assert current["counts"]["units_semantic_gap"] == 34
assert current["status"] == "GAP"
assert current["promotion"]["whole_architecture"] == "RED"
assert current["promotion"]["ppa"] == "UNPROMOTED"
PY

grep -Fq "Ran 8 tests" "${canonical_evidence}/evidence-tool-unit.log"
grep -Fq "Ran 15 tests" "${canonical_evidence}/semantic-ledger-unit.log"
grep -Fq "OK" "${canonical_evidence}/semantic-ledger-unit.log"
grep -Fq "[PASS] tb_ooo_store_queue" \
  "${task_run_dir}/evidence/normal-regression/result/logs/tb_ooo_store_queue.log"
grep -Fq "[RESULT] PASS" \
  "${task_run_dir}/evidence/normal-regression/result/logs/tb_ooo_store_queue.log"
grep -Fq \
  "[V11G-ARCH-STABLE-OBSERVATION] EXPECTED_GAP pass=51 fail=2 v11g_new_failures=0" \
  "${task_run_dir}/evidence/arch-stable-unittest.log"
grep -Fq "[V11G-SCOPED-GUARD][PASS] paths=8 profile=npc-dev" \
  "${task_run_dir}/evidence/scoped-strict-guard.log"
grep -Fq \
  "[V11G-FULL-GUARD] EXPECTED_GAP profile=rv64-linux scope=shared-worktree" \
  "${task_run_dir}/evidence/full-worktree-strict-guard.log"

printf '%s  %s\n' \
  "154d7ac6cf6a03352ddaff393d03af8f8e2c81cf47a40bc8bbf8305cdad257f8" \
  "${task_run_dir}/subagent-contracts/v11g-store-queue-holder-pre-review.json" |
  sha256sum -c -
printf '%s  %s\n' \
  "60ae84f5ea0a1b09a337ec6f71f2d0a284cc9f1f9e59f7a3eaca5780cc888dd5" \
  "${task_run_dir}/subagent-contracts/v11g-store-queue-holder-final-review.json" |
  sha256sum -c -
python3 \
  .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${task_run_dir}/subagent-contracts/v11g-store-queue-holder-pre-review.json"
python3 \
  .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${task_run_dir}/subagent-contracts/v11g-store-queue-holder-final-review.json"

bash -n \
  "${task_run_dir}/run-store-queue-holder-focused.sh" \
  "${task_run_dir}/run-arch-stable-observation.sh" \
  "${task_run_dir}/run-guards.sh" \
  "${task_run_dir}/publish-db-memory.sh" \
  "${task_run_dir}/audit-commit-gate.sh" \
  "${task_run_dir}/verify-final-identity.sh"

git diff --check -- \
  npc/rv64/testbench/tests/tb_ooo_store_queue.sv \
  npc/rv64/eval/ppa/tools/store_queue_holder_semantic_evidence.py \
  npc/rv64/eval/ppa/tests/test_store_queue_holder_semantic_evidence.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md \
  .github/memory/project-status.md \
  .github/memory/modules/npc.md

echo "[V11G-FINAL-IDENTITY][PASS] design_id=sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375 sq_sha256=5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241 ledger=10/34"
