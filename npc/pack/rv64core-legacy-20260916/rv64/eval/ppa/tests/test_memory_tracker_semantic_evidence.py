from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT / "npc/rv64/eval/ppa/tools/memory_tracker_semantic_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "memory_tracker_semantic_evidence", TOOL_PATH
)
assert SPEC and SPEC.loader
EVIDENCE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVIDENCE
SPEC.loader.exec_module(EVIDENCE)


class MutationContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_path = (
            ROOT / "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
        )
        cls.source = cls.source_path.read_text(encoding="utf-8")

    def test_current_tracker_is_the_reviewed_production_source(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(self.source_path),
            EVIDENCE.EXPECTED_TRACKER_SHA256,
        )

    def test_every_declared_mutation_changes_exactly_one_contract(self) -> None:
        self.assertEqual(len(EVIDENCE.MUTATION_MARKERS), 9)
        for case in EVIDENCE.MUTATION_MARKERS:
            with self.subTest(case=case):
                mutant = EVIDENCE.mutate_source(self.source, case)
                self.assertNotEqual(mutant, self.source)
                self.assertIn("module OooMemOwnerTracker", mutant)
                self.assertIn("endmodule", mutant)

    def test_unknown_mutation_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError, "unsupported mutation case"
        ):
            EVIDENCE.mutate_source(self.source, "not-a-tracker-contract")

    def test_closure_unit_set_excludes_cursor(self) -> None:
        self.assertEqual(
            EVIDENCE.UNIT_IDS,
            {
                "memory-tracker-producer-map",
                "memory-tracker-live-set",
            },
        )
        self.assertNotIn("tracker-next-token-cursor", EVIDENCE.UNIT_IDS)

    def test_marker_count_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError, "marker count mismatch"
        ):
            EVIDENCE.require_once("marker\nmarker\n", "marker", "duplicate")


if __name__ == "__main__":
    unittest.main()
