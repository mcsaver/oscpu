#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage"
canonical_evidence="${task_run_dir}/evidence/slot-generation-attempt-3"
output_log="${task_run_dir}/evidence/final-identity.log"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
temporary_binding="$(mktemp /tmp/v11e-final-rtl.XXXXXX.json)"
temporary_ledger="$(mktemp "${task_run_dir}/evidence/.v11e-final-ledger.XXXXXX.json")"

cleanup() {
  rm -f -- "${temporary_binding}" "${temporary_ledger}"
}
trap cleanup EXIT

exec > >(tee "${output_log}") 2>&1
cd "${repo_root}"

python3 "${snapshot_tool}" --snapshot-out "${temporary_binding}"
cmp "${temporary_binding}" "${canonical_evidence}/rtl-source-binding.post.json"

# The active specification header is intentionally synchronized after final
# review. All executable focused inputs remain byte-identical to attempt-3.
grep -Fv \
  "npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md" \
  "${canonical_evidence}/sources.post.sha256" |
  sha256sum -c -

printf '%s  %s\n' \
  "c4800737dd6e9e7155f0fff1acfa04dd61a649935d769210f62c893247686a23" \
  "${canonical_evidence}/summary.json" |
  sha256sum -c -

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  --root "${repo_root}" \
  build \
  --output "${temporary_ledger}"
cmp "${temporary_ledger}" "${task_run_dir}/evidence/semantic-coverage-ledger.json"

python3 - "${canonical_evidence}/summary.json" \
  "${task_run_dir}/evidence/semantic-coverage-ledger.json" \
  "${task_run_dir}/evidence/post-review-publication-receipt.json" <<'PY'
import json
import pathlib
import sys

summary = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
ledger = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
receipt = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))

assert summary["status"] == "PASS"
assert summary["counts"] == {
    "compile_success_mutation_cases": 17,
    "mutation_simulations": 34,
    "positive_profiles": 4,
    "rejected_mutation_simulations": 34,
}
assert summary["unit_ids"] == ["rob-slot-generation"]
assert ledger["status"] == "GAP"
assert ledger["counts"]["semantic_units"] == 44
assert ledger["counts"]["units_semantic_pass"] == 7
assert ledger["counts"]["units_semantic_gap"] == 37
assert receipt["canonical_evidence_rewritten"] is False
assert receipt["production_rtl_changed"] is False
assert receipt["executable_verification_input_changed"] is False
assert receipt["publication_header_synchronized"] is True
print("[V11E-PUBLICATION-RECEIPT][PASS]")
PY

python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_rob_slot_generation_semantic_evidence \
  npc.rv64.eval.ppa.tests.test_producer_holder_semantic_coverage

grep -Fq "状态：v11e current-production-top 审计合同" \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md
grep -Fq "余下 37 个保持 GAP" \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md

python3 -m json.tool "${task_run_dir}/round-state.json" >/dev/null
grep -Fxq "COMPLETED" "${task_run_dir}/status"
grep -Fq "slot_generation_scope=PASS" \
  "${task_run_dir}/v11e-rob-slot-generation-semantic.status"

bash -n \
  "${task_run_dir}/run-rob-slot-generation-focused.sh" \
  "${task_run_dir}/run-arch-stable-observation.sh" \
  "${task_run_dir}/run-guards.sh" \
  "${task_run_dir}/audit-commit-gate.sh" \
  "${task_run_dir}/publish-db-memory.sh" \
  "${task_run_dir}/verify-final-identity.sh"

git diff --check -- \
  npc/rv64/testbench/tests/tb_ooo_rob.sv \
  npc/rv64/eval/ppa/tools/rob_slot_generation_semantic_evidence.py \
  npc/rv64/eval/ppa/tests/test_rob_slot_generation_semantic_evidence.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  .github/memory/project-status.md \
  .github/memory/modules/npc.md

echo "[V11E-FINAL-IDENTITY][PASS] design_id=sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375 rob_sha256=bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561"
