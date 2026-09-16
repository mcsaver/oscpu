from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/"
    "store_queue_holder_semantic_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "store_queue_holder_semantic_evidence", TOOL_PATH
)
assert SPEC and SPEC.loader
EVIDENCE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVIDENCE
SPEC.loader.exec_module(EVIDENCE)


class StoreQueueHolderEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_path = ROOT / EVIDENCE.RTL_PATH
        cls.source = cls.source_path.read_text(encoding="utf-8")

    def test_current_store_queue_is_reviewed_production_source(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(self.source_path),
            EVIDENCE.EXPECTED_RTL_SHA256,
        )

    def test_current_testbench_is_source_bound(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(ROOT / EVIDENCE.TB_PATH),
            EVIDENCE.EXPECTED_TB_SHA256,
        )

    def test_closure_unit_set_is_exact(self) -> None:
        self.assertEqual(
            EVIDENCE.UNIT_IDS,
            {
                "store-queue-producers",
                "store-queue-owner-tokens",
            },
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

    def test_every_declared_mutation_changes_store_queue(self) -> None:
        self.assertEqual(len(EVIDENCE.MUTATION_CASES), 24)
        for case in EVIDENCE.MUTATION_CASES:
            with self.subTest(case=case):
                mutant = EVIDENCE.mutate_source(self.source, case)
                self.assertNotEqual(mutant, self.source)
                self.assertIn("module OooStoreQueue", mutant)
                self.assertIn("endmodule", mutant)

    def test_identity_lifetime_recovery_and_knownness_are_present(self) -> None:
        required = {
            "alloc0-generation-zero",
            "alloc1-uses-alloc0-pid",
            "request-full-pid-raw-only",
            "release-full-pid-raw-only",
            "request-clears-valid",
            "terminal-clears-valid",
            "selective-kills-boundary",
            "global-kills-request-sent",
            "bind1-uses-bind0-tuple",
            "bind0-kind-x",
            "bind0-token-x",
            "bind0-epoch-x",
            "owner-valid-dies-on-request",
            "owner-valid-dies-on-terminal",
            "release-mask-uses-rob-index",
            "bind-terminal-bypass-removed",
            "release-mask-bind-bypass-removed",
        }
        self.assertTrue(required <= set(EVIDENCE.MUTATION_CASES))

    def test_unknown_mutation_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "unsupported mutation case",
        ):
            EVIDENCE.mutate_source(self.source, "not-store-queue-holder")

    def test_marker_count_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "marker count mismatch",
        ):
            EVIDENCE.require_once("marker\nmarker\n", "marker", "duplicate")


if __name__ == "__main__":
    unittest.main()
