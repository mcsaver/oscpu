from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/"
    "load_queue_producer_semantic_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "load_queue_producer_semantic_evidence", TOOL_PATH
)
assert SPEC and SPEC.loader
EVIDENCE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVIDENCE
SPEC.loader.exec_module(EVIDENCE)


class LoadQueueProducerEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_path = ROOT / EVIDENCE.RTL_PATH
        cls.source = cls.source_path.read_text(encoding="utf-8")

    def test_current_load_queue_is_reviewed_architecture_source(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(self.source_path),
            EVIDENCE.EXPECTED_RTL_SHA256,
        )
        self.assertNotEqual(
            EVIDENCE.EXPECTED_PRE_FIX_RTL_SHA256,
            EVIDENCE.EXPECTED_RTL_SHA256,
        )

    def test_semantic_testbench_is_source_bound(self) -> None:
        self.assertEqual(
            EVIDENCE.sha256(ROOT / EVIDENCE.TB_PATH),
            EVIDENCE.EXPECTED_TB_SHA256,
        )

    def test_closure_unit_set_is_exact(self) -> None:
        self.assertEqual(
            EVIDENCE.UNIT_IDS,
            {"load-queue-producers"},
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

    def test_raw_q_knownness_assertion_is_source_bound(self) -> None:
        self.assertIn(
            EVIDENCE.ASSERTION_PROBE_MARKER,
            self.source,
        )
        self.assertIn(
            "(^producer_id_q[assert_i] === 1'bx)",
            self.source,
        )

    def test_system_rerun_scope_separates_local_and_system_gates(self) -> None:
        self.assertEqual(
            EVIDENCE.SYSTEM_RERUN_SCOPE,
            {
                "required_for_local_closure": False,
                "required_before_system_promotion": True,
                "run": False,
            },
        )

    def test_every_declared_mutation_changes_load_queue(self) -> None:
        self.assertEqual(len(EVIDENCE.MUTATION_CASES), 31)
        for case in EVIDENCE.MUTATION_CASES:
            with self.subTest(case=case):
                mutant = EVIDENCE.mutate_source(self.source, case)
                self.assertNotEqual(mutant, self.source)
                self.assertIn("module OooLoadQueue", mutant)
                self.assertIn("endmodule", mutant)

    def test_identity_lifetime_recovery_and_knownness_are_present(self) -> None:
        required = {
            "alloc0-pid-x",
            "alloc1-pid-x",
            "issue-full-pid-index-only",
            "launch-full-pid-index-only",
            "query-full-pid-index-only",
            "response-full-pid-index-only",
            "completion-full-pid-index-only",
            "terminal-full-pid-index-only",
            "release-full-pid-index-only",
            "terminal-not-recorded",
            "terminal-seen-x",
            "recovery-ignores-prior-terminal",
            "normal-terminal-clears-valid",
            "killed-terminal-keeps-valid",
            "launched-recovery-drops-entry",
            "same-edge-launch-ignored",
            "same-edge-completion-ignored",
            "same-edge-terminal-ignored",
            "release-before-completion",
            "alloc-borrows-same-edge-release",
        }
        self.assertTrue(required <= set(EVIDENCE.MUTATION_CASES))

    def test_unknown_mutation_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "unsupported mutation case",
        ):
            EVIDENCE.mutate_source(self.source, "not-load-queue-holder")

    def test_marker_count_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(
            EVIDENCE.EvidenceError,
            "marker count mismatch",
        ):
            EVIDENCE.require_once(
                "marker\nmarker\n", "marker", "duplicate"
            )


if __name__ == "__main__":
    unittest.main()
