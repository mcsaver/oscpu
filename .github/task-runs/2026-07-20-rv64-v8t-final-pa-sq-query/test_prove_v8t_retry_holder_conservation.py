#!/usr/bin/env python3
"""Mutation-oriented unit tests for the v8t retry-holder proof binding."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
PROOF = HERE / "prove-v8t-retry-holder-conservation.py"

SPEC = importlib.util.spec_from_file_location("v8t_retry_proof", PROOF)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def failed_ids(text: str) -> set[str]:
    result = MODULE.prove_text(text, "mutant-OooIntBackend.v")
    return {
        check["check_id"]
        for check in result["checks"]
        if not check["passed"]
    }


class RetryHolderProofBindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.baseline = SOURCE.read_text(encoding="utf-8")

    def mutate_once(self, old: str, new: str) -> str:
        self.assertEqual(self.baseline.count(old), 1)
        return self.baseline.replace(old, new, 1)

    def test_baseline_passes(self) -> None:
        result = MODULE.prove_text(self.baseline, SOURCE.name)
        self.assertTrue(result["passed"])
        self.assertEqual(result["per_bank_boolean_vectors"], 8192)
        self.assertEqual(result["two_bank_action_pairs"], 25)

    def test_cancel_priority_deletion_is_rejected(self) -> None:
        mutant = self.mutate_once(
            "end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin",
            "end else if (mem_retry1_req_fire_w) begin",
        )
        self.assertIn(
            "source.cancel_or_fire_precedes_capture", failed_ids(mutant)
        )

    def test_atomic_repush_deletion_is_rejected(self) -> None:
        mutant = self.mutate_once(
            "wire push_retry1_w = mem_retry1_req_fire_w;",
            "wire push_retry1_w = 1'b0;",
        )
        self.assertIn(
            "source.request_fire_atomic_exact_miq_repush", failed_ids(mutant)
        )

    def test_terminal_lane_swap_is_rejected(self) -> None:
        mutant = self.mutate_once(
            "mem_retry1_tagged_terminal_w,\n      mem_retry0_tagged_terminal_w,",
            "mem_retry0_tagged_terminal_w,\n      mem_retry1_tagged_terminal_w,",
        )
        self.assertIn(
            "source.cancel_exact_terminal_lanes_10_11", failed_ids(mutant)
        )

    def test_holder_census_deletion_is_rejected(self) -> None:
        mutant = self.mutate_once(
            "mem_buffer_owner_mask_w | mem_retry0_owner_mask_w |\n"
            "      mem_retry1_owner_mask_w |",
            "mem_buffer_owner_mask_w | mem_retry0_owner_mask_w |",
        )
        self.assertIn(
            "source.holder_in_owner_census_and_next_q_oracles",
            failed_ids(mutant),
        )


if __name__ == "__main__":
    unittest.main()
