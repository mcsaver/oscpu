#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("finalize-v8t-final-pa-sq-query.py")
SPEC = importlib.util.spec_from_file_location("v8t_finalize", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FinalizeV8tTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp.name)
        self.contract_rel = pathlib.Path(
            ".github/task-runs/run/subagent-contracts/review.json"
        )
        self.contract = self.root / self.contract_rel
        self.contract.parent.mkdir(parents=True)
        self.contract.write_text('{"contract": "v3"}\n', encoding="utf-8")
        self.contract_sha = hashlib.sha256(self.contract.read_bytes()).hexdigest()
        self.mutations = self.root / "mutation-summary.tsv"
        lines = []
        for index in range(38):
            dynamic = "not_required" if index == 36 else "target_rejected"
            name = "legacy_all_load_block" if index == 36 else f"mutation_{index:02d}"
            lines.append(
                f"{name}|backend|oracle.{index}|{dynamic}|{'a' * 64}|{'b' * 64}|2"
            )
        self.mutations.write_text("\n".join(lines) + "\n", encoding="utf-8")
        self.review = self.root / "review-result.json"
        self.candidate = self.root / "candidate-result.json"
        self.closure = "c" * 64
        self.candidate_run_id = "v8t-f3-20260720T000001Z-2"

        candidate = MODULE.build_payload(
            run_id=self.candidate_run_id,
            source_closure_sha256=self.closure,
            mutation_path=self.mutations,
            review_path=None,
            candidate_result_path=None,
            repo_root=self.root,
        )
        self.candidate.write_text(json.dumps(candidate), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def review_payload(self) -> dict[str, object]:
        return {
            "schema": "v8t-f3-independent-implementation-review/v1",
            "reviewer_task": "/root/v8t_f3_impl_rereview_v2",
            "contract_json": self.contract_rel.as_posix(),
            "contract_json_sha256": self.contract_sha,
            "verdict": "PASS",
            "authorized_claim": "final_pa_sq_ordering_checkpoint",
            "reviewed_candidate_run_id": self.candidate_run_id,
            "reviewed_candidate_result_sha256": hashlib.sha256(
                self.candidate.read_bytes()
            ).hexdigest(),
            "reviewed_mutation_summary_sha256": hashlib.sha256(
                self.mutations.read_bytes()
            ).hexdigest(),
            "reviewed_source_closure_sha256": self.closure,
            "reviewed_runner_status": "PASS",
            "reviewed_mutations": 38,
            "reviewed_dynamic_rejections": 37,
            "reviewed_profiles": 11,
            "reviewed_retry_holder_proof": "PASS",
            "reviewed_predecessors": {"F0": "PASS", "F1": "PASS", "F2": "PASS"},
            "unresolved_blockers": {"P0": [], "P1": []},
            "claim_boundary": {
                "architecture": "RED",
                "ppa": "UNQUALIFIED",
                "promotion_eligible": False,
            },
        }

    def build(self, *, promote: bool = True) -> dict[str, object]:
        return MODULE.build_payload(
            run_id=self.candidate_run_id,
            source_closure_sha256=self.closure,
            mutation_path=self.mutations,
            review_path=self.review if promote else None,
            candidate_result_path=self.candidate if promote else None,
            repo_root=self.root,
        )

    def test_missing_review_keeps_candidate(self) -> None:
        payload = self.build(promote=False)
        self.assertEqual(payload["claim"], "final_pa_sq_ordering_candidate")
        self.assertFalse(payload["checkpoint_eligible"])
        self.assertIsNone(payload["reviewer_provenance"])

    def test_matching_review_promotes_checkpoint(self) -> None:
        self.review.write_text(json.dumps(self.review_payload()), encoding="utf-8")
        payload = self.build()
        self.assertEqual(payload["claim"], "final_pa_sq_ordering_checkpoint")
        self.assertTrue(payload["checkpoint_eligible"])
        self.assertEqual(payload["remaining_p0_categories"], [])

    def test_closure_mismatch_is_rejected(self) -> None:
        review = self.review_payload()
        review["reviewed_source_closure_sha256"] = "d" * 64
        self.review.write_text(json.dumps(review), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "reviewed_source_closure"):
            self.build()

    def test_candidate_run_mismatch_is_rejected(self) -> None:
        review = self.review_payload()
        review["reviewed_candidate_run_id"] = "v8t-f3-20260720T000000Z-1"
        self.review.write_text(json.dumps(review), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "reviewed_candidate_run_id"):
            self.build()

    def test_contract_hash_mismatch_is_rejected(self) -> None:
        review = self.review_payload()
        review["contract_json_sha256"] = "0" * 64
        self.review.write_text(json.dumps(review), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "contract SHA mismatch"):
            self.build()

    def test_claim_boundary_inflation_is_rejected(self) -> None:
        review = self.review_payload()
        review["claim_boundary"] = {
            "architecture": "GREEN",
            "ppa": "QUALIFIED",
            "promotion_eligible": True,
        }
        self.review.write_text(json.dumps(review), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "claim_boundary"):
            self.build()

    def test_candidate_result_tamper_is_rejected(self) -> None:
        review = self.review_payload()
        self.review.write_text(json.dumps(review), encoding="utf-8")
        self.candidate.write_text("{}\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "reviewed_candidate_result_sha256"):
            self.build()


if __name__ == "__main__":
    unittest.main()
