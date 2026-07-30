#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest
from types import SimpleNamespace
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[3]
AUDITOR = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay"
    / "audit-current-debt-evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "testable_v10c_currentness_auditor", AUDITOR
)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class CurrentnessEvidenceDispatchTests(unittest.TestCase):
    def exact_entry(self) -> dict[str, object]:
        return {
            "id": "SERIALIZE-G1",
            "canonical_command": MODULE.SERIALIZE_COMMAND,
            "evidence": [
                dict(item) for item in MODULE.SERIALIZE_EXPECTED_EVIDENCE
            ],
        }

    @mock.patch.object(MODULE.subprocess, "run")
    def test_serialize_tuple_requires_canonical_pass(
        self, run: mock.Mock
    ) -> None:
        run.return_value = SimpleNamespace(
            returncode=0,
            stdout="[SERIALIZE-G1-VERIFY] review=APPROVED PASS\n",
            stderr="",
        )
        self.assertIsNone(MODULE.verify_serialize_entry(self.exact_entry()))

    @mock.patch.object(MODULE.subprocess, "run")
    def test_serialize_tuple_rejects_failed_verifier(
        self, run: mock.Mock
    ) -> None:
        run.return_value = SimpleNamespace(
            returncode=1,
            stdout="",
            stderr="candidate drift",
        )
        self.assertEqual(
            MODULE.verify_serialize_entry(self.exact_entry()),
            "serialize_canonical_verifier_failed",
        )

    @mock.patch.object(MODULE.subprocess, "run")
    def test_serialize_tuple_rejects_remapped_evidence(
        self, run: mock.Mock
    ) -> None:
        entry = self.exact_entry()
        entry["evidence"][1] = {
            **entry["evidence"][1],
            "kind": "serialize_closure_candidate",
        }
        self.assertEqual(
            MODULE.verify_serialize_entry(entry),
            "serialize_evidence_tuple_not_exact",
        )
        run.assert_not_called()

    def test_serialize_review_markdown_is_hash_bound_not_json_parsed(
        self,
    ) -> None:
        self.assertFalse(
            MODULE.requires_generic_json(
                "SERIALIZE-G1",
                "independent_review_report",
                pathlib.Path("final-reviewer-report-v2.md"),
            )
        )

    def test_unrelated_markdown_cannot_bypass_json_currentness(self) -> None:
        with self.assertRaisesRegex(
            RuntimeError, "unexpected non-JSON structured evidence"
        ):
            MODULE.requires_generic_json(
                "CONTROL-EVENT-G1",
                "structured_result",
                pathlib.Path("not-structured.md"),
            )

    def test_known_raw_log_remains_hash_only(self) -> None:
        self.assertFalse(
            MODULE.requires_generic_json(
                "F0-G1",
                "raw_log",
                pathlib.Path("functional.log"),
            )
        )

    def test_closed_semantic_gap_is_rejected(self) -> None:
        checks = {
            "debt.FDG-G1.closed_binding": {"status": "PASS"},
            "debt.FDG-G1.semantic_evidence": {"status": "GAP"},
        }
        self.assertEqual(
            MODULE.closed_semantic_failures(["FDG-G1"], checks),
            [{
                "entry": "FDG-G1",
                "reason": (
                    "canonical_check_not_pass:"
                    "debt.FDG-G1.semantic_evidence:GAP"
                ),
            }],
        )

    def test_closed_semantic_pair_passes(self) -> None:
        checks = {
            "debt.FDG-G1.closed_binding": {"status": "PASS"},
            "debt.FDG-G1.semantic_evidence": {"status": "PASS"},
        }
        self.assertEqual(
            MODULE.closed_semantic_failures(["FDG-G1"], checks),
            [],
        )

    def test_missing_canonical_check_is_rejected(self) -> None:
        failures = MODULE.closed_semantic_failures(
            ["FDG-G1"],
            {"debt.FDG-G1.closed_binding": {"status": "PASS"}},
        )
        self.assertEqual(
            failures,
            [{
                "entry": "FDG-G1",
                "reason": (
                    "canonical_check_missing:"
                    "debt.FDG-G1.semantic_evidence"
                ),
            }],
        )


if __name__ == "__main__":
    unittest.main()
