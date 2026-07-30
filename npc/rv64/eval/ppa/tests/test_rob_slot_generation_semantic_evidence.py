from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/"
    "rob_slot_generation_semantic_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "rob_slot_generation_semantic_evidence", TOOL_PATH
)
assert SPEC and SPEC.loader
EVIDENCE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVIDENCE
SPEC.loader.exec_module(EVIDENCE)


class RobSlotGenerationEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_path = ROOT / EVIDENCE.ROB_PATH
        cls.source = cls.source_path.read_text(encoding="utf-8")

    def test_current_rob_is_reviewed_production_source(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(self.source_path),
            EVIDENCE.EXPECTED_ROB_SHA256,
        )

    def test_current_testbench_is_source_bound(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(ROOT / EVIDENCE.TB_PATH),
            EVIDENCE.EXPECTED_TB_SHA256,
        )

    def test_closure_unit_set_is_exact(self) -> None:
        self.assertEqual(
            EVIDENCE.UNIT_IDS,
            {"rob-slot-generation"},
        )

    def test_assert_release_width_matrix_is_exact(self) -> None:
        self.assertEqual(
            EVIDENCE.POSITIVE_PROFILES,
            {
                "assert-g1": (1, True),
                "release-g1": (1, False),
                "assert-g4": (4, True),
                "release-g4": (4, False),
            },
        )
        self.assertEqual(EVIDENCE.MUTATION_WIDTHS, (1, 4))

    def test_every_declared_mutation_changes_rob(self) -> None:
        self.assertEqual(len(EVIDENCE.MUTATION_CASES), 17)
        for case in EVIDENCE.MUTATION_CASES:
            with self.subTest(case=case):
                mutant = EVIDENCE.mutate_source(self.source, case)
                self.assertNotEqual(mutant, self.source)
                self.assertIn("module OooRob", mutant)
                self.assertIn("endmodule", mutant)

    def test_rejected_edge_and_query_mutations_are_present(self) -> None:
        self.assertIn(
            "lane0-write-on-valid",
            EVIDENCE.MUTATION_CASES,
        )
        self.assertIn(
            "full-borrows-commit-slot",
            EVIDENCE.MUTATION_CASES,
        )
        self.assertIn(
            "current-query-ignore-generation",
            EVIDENCE.MUTATION_CASES,
        )
        self.assertIn(
            "completion-query-ignore-generation",
            EVIDENCE.MUTATION_CASES,
        )
        self.assertIn(
            "resolve-query-ignore-generation",
            EVIDENCE.MUTATION_CASES,
        )

    def test_lane_sources_are_mutated_independently(self) -> None:
        lane1 = EVIDENCE.mutate_source(
            self.source, "lane1-uses-lane0-generation"
        )
        self.assertIn(
            "slot_generation_q[dispatch0_rob_idx_o] +",
            lane1,
        )
        pair = EVIDENCE.mutate_source(
            self.source, "pair-uses-actual-lane1-slot"
        )
        self.assertIn(
            "slot_generation_q[dispatch1_rob_idx_o] +",
            pair,
        )

    def test_unknown_mutation_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "unsupported mutation case",
        ):
            EVIDENCE.mutate_source(self.source, "not-slot-generation")

    def test_marker_count_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "marker count mismatch",
        ):
            EVIDENCE.require_once("marker\nmarker\n", "marker", "duplicate")


if __name__ == "__main__":
    unittest.main()
