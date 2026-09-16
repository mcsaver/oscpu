from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/"
    "int_iq_producer_semantic_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "int_iq_producer_semantic_evidence", TOOL_PATH
)
assert SPEC and SPEC.loader
EVIDENCE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVIDENCE
SPEC.loader.exec_module(EVIDENCE)


class IntIqProducerEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_path = ROOT / EVIDENCE.RTL_PATH
        cls.source = cls.source_path.read_text(encoding="utf-8")

    def test_current_iq_is_reviewed_production_source(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(self.source_path),
            EVIDENCE.EXPECTED_RTL_SHA256,
        )

    def test_current_selector_and_testbench_are_source_bound(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(ROOT / EVIDENCE.SELECTOR_PATH),
            EVIDENCE.EXPECTED_SELECTOR_SHA256,
        )
        self.assertEqual(
            EVIDENCE.sha256(ROOT / EVIDENCE.TB_PATH),
            EVIDENCE.EXPECTED_TB_SHA256,
        )

    def test_closure_unit_set_is_exact(self) -> None:
        self.assertEqual(
            EVIDENCE.UNIT_IDS,
            {"integer-iq-producers"},
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

    def test_every_declared_mutation_changes_iq(self) -> None:
        self.assertEqual(len(EVIDENCE.MUTATION_CASES), 20)
        for case in EVIDENCE.MUTATION_CASES:
            with self.subTest(case=case):
                mutant = EVIDENCE.mutate_source(self.source, case)
                self.assertNotEqual(mutant, self.source)
                self.assertIn("module OooIntIssueQueue", mutant)
                self.assertIn("endmodule", mutant)

    def test_carrier_lifetime_and_knownness_mutations_are_present(self) -> None:
        required = {
            "dispatch0-generation-zero",
            "dispatch1-uses-lane0-pid",
            "compaction-uses-write-index-pid",
            "issue0-fire-not-removed",
            "pair-pop-only-entry0",
            "kill-boundary-inclusive",
            "regular-fire-dies-early-mask",
            "pair-fire-dies-early-mask",
            "mask-raw-rob-index",
            "dispatch0-pid-x",
            "dispatch1-pid-x",
            "compaction-pid-x",
        }
        self.assertTrue(required <= set(EVIDENCE.MUTATION_CASES))

    def test_unknown_mutation_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "unsupported mutation case",
        ):
            EVIDENCE.mutate_source(self.source, "not-int-iq-producer")

    def test_marker_count_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "marker count mismatch",
        ):
            EVIDENCE.require_once("marker\nmarker\n", "marker", "duplicate")


if __name__ == "__main__":
    unittest.main()
