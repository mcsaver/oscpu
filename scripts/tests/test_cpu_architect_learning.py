#!/usr/bin/env python3
"""Unit tests for the CPU Architect grounded learning contracts."""

from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "scripts/cpu_architect_learning.py"
SPEC = importlib.util.spec_from_file_location("cpu_architect_learning", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class LearningContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = MODULE.load_json(MODULE.DEFAULT_POLICY)

    def setUp(self) -> None:
        self.examples = MODULE._valid_examples()

    def assertRejected(self, kind: str, record: dict) -> None:
        with self.assertRaises(MODULE.LearningContractError):
            MODULE.validate_record(kind, record, self.policy)

    def test_contracts_and_examples_validate(self) -> None:
        MODULE.validate_contracts(self.policy)
        for kind, record in self.examples.items():
            MODULE.validate_record(kind, record, self.policy)

    def test_unknown_capability_is_not_fabricated_as_validated(self) -> None:
        record = copy.deepcopy(self.examples["capability"])
        node = record["nodes"][0]
        node["status"] = "validated"
        self.assertRejected("capability", record)

    def test_capability_prerequisite_must_exist_in_graph(self) -> None:
        record = copy.deepcopy(self.examples["capability"])
        record["nodes"][0]["prerequisites"] = ["missing.capability"]
        self.assertRejected("capability", record)

    def test_prediction_must_precede_measurement(self) -> None:
        record = copy.deepcopy(self.examples["experience"])
        record["timestamps"]["predicted_at"] = "2026-08-09T12:00:00+08:00"
        record["timestamps"]["measured_at"] = "2026-08-09T11:00:00+08:00"
        self.assertRejected("experience", record)

    def test_prediction_comparison_is_recomputed(self) -> None:
        record = copy.deepcopy(self.examples["experience"])
        record["comparison"]["prediction_error"] = 0.0
        self.assertRejected("experience", record)

    def test_deterministic_experiment_rejects_repeat_reason(self) -> None:
        record = copy.deepcopy(self.examples["experience"])
        record["experiment"]["repeat_reason"] = "run it twice just in case"
        self.assertRejected("experience", record)

    def test_llm_output_cannot_be_training_ground_truth(self) -> None:
        record = copy.deepcopy(self.examples["experience"])
        record["training"].update({
            "eligible": True,
            "ground_truth_level": "llm_opinion",
            "unseen_exam_passed": True,
        })
        self.assertRejected("experience", record)

    def test_objective_evidence_and_exam_can_form_export_candidate(self) -> None:
        record = copy.deepcopy(self.examples["experience"])
        record["training"].update({"eligible": True, "unseen_exam_passed": True})
        MODULE.validate_record("experience", record, self.policy)

    def test_knowledge_gap_priority_formula_is_enforced(self) -> None:
        record = copy.deepcopy(self.examples["gap"])
        record["priority"]["score"] = 99.0
        self.assertRejected("gap", record)

    def test_knowledge_gap_voi_formula_is_enforced(self) -> None:
        record = copy.deepcopy(self.examples["gap"])
        record["validation_plan"]["voi"] = 1.0
        self.assertRejected("gap", record)


if __name__ == "__main__":
    unittest.main(verbosity=2)
