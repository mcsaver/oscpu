from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT
    / "npc/rv64/eval/ppa/tools/"
    "load_queue_producer_checker_replay.py"
)
SPEC = importlib.util.spec_from_file_location(
    "load_queue_producer_checker_replay", TOOL_PATH
)
assert SPEC and SPEC.loader
REPLAY = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = REPLAY
SPEC.loader.exec_module(REPLAY)


class LoadQueueProducerCheckerReplayTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.receipt = REPLAY.build_receipt(ROOT)

    def test_frozen_attempt_builds_pass_receipt(self) -> None:
        self.assertEqual(
            self.receipt["schema"],
            "rv64-v11h-load-queue-attempt4-checker-replay-v3",
        )
        self.assertEqual(self.receipt["status"], "PASS")
        self.assertEqual(self.receipt["original_attempt"], 4)
        self.assertEqual(
            self.receipt["original_failure"]["stage"],
            "semantic-ledger-unit",
        )
        self.assertEqual(
            self.receipt["frozen_simulation_evidence"][
                "mutation_simulations"
            ],
            62,
        )
        self.assertEqual(
            self.receipt["frozen_simulation_evidence"][
                "raw_q_knownness_assertion_probes"
            ],
            1,
        )
        selected = self.receipt["historical_selected_binding"]
        self.assertEqual(
            selected["binding_state"],
            "HISTORICAL_FROZEN_SELECTED_BINDING",
        )
        self.assertEqual(len(selected["records"]), 3)
        self.assertTrue(
            all(len(record["evidence_sha256"]) == 64
                for record in selected["records"])
        )
        self.assertFalse(
            self.receipt["replay_contract"]["current_rtl_binding_claimed"]
        )

    def test_original_pass_status_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            REPLAY.ReplayError, "semantic-ledger-unit FAIL"
        ):
            REPLAY.validate_original_status_line("PASS")

    def test_receipt_count_edit_is_rejected(self) -> None:
        mutated = copy.deepcopy(self.receipt)
        mutated["frozen_simulation_evidence"]["mutation_cases"] = 30
        with self.assertRaisesRegex(
            REPLAY.ReplayError, "differs from frozen inputs"
        ):
            REPLAY.verify_payload(ROOT, mutated)

    def test_receipt_checker_hash_edit_is_rejected(self) -> None:
        mutated = copy.deepcopy(self.receipt)
        mutated["replacement_checker_sources"]["semantic_checker"][
            "sha256"
        ] = "0" * 64
        with self.assertRaisesRegex(
            REPLAY.ReplayError, "differs from frozen inputs"
        ):
            REPLAY.verify_payload(ROOT, mutated)

    def test_receipt_design_rebind_is_rejected(self) -> None:
        mutated = copy.deepcopy(self.receipt)
        mutated["design_id"] = "sha256:" + "0" * 64
        with self.assertRaisesRegex(
            REPLAY.ReplayError, "differs from frozen inputs"
        ):
            REPLAY.verify_payload(ROOT, mutated)

    def test_selected_binding_hash_edit_is_rejected(self) -> None:
        mutated = copy.deepcopy(self.receipt)
        mutated["historical_selected_binding"]["records"][0][
            "evidence_sha256"
        ] = "0" * 64
        with self.assertRaisesRegex(
            REPLAY.ReplayError, "differs from frozen inputs"
        ):
            REPLAY.verify_payload(ROOT, mutated)


if __name__ == "__main__":
    unittest.main()
