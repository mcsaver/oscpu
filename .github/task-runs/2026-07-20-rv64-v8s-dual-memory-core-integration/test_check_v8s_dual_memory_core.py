#!/usr/bin/env python3
"""Mutation-negative unit tests for the v8s/F2 source/claim checker."""

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
SPEC = importlib.util.spec_from_file_location(
    "check_v8s", HERE / "check-v8s-dual-memory-core.py"
)
assert SPEC and SPEC.loader
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class CheckerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.baseline = CHECKER.load_sources(REPO)

    def result(self, sources: dict[str, str], check_id: str) -> bool:
        matches = [item for item in CHECKER.evaluate(sources)
                   if item.check_id == check_id]
        self.assertEqual(len(matches), 1, check_id)
        return matches[0].passed

    def mutated(self, key: str, old: str, new: str) -> dict[str, str]:
        sources = copy.deepcopy(self.baseline)
        self.assertEqual(sources[key].count(old), 1, old)
        sources[key] = sources[key].replace(old, new, 1)
        return sources

    def test_baseline_all_checks_pass(self) -> None:
        failed = [item for item in CHECKER.evaluate(self.baseline)
                  if not item.passed]
        self.assertEqual(failed, [])

    def test_comment_cannot_fake_parameter_handoff(self) -> None:
        old = ".ENABLE_DUAL_MEM(ENABLE_DUAL_MEM)"
        sources = self.mutated("decode", old, ".ENABLE_DUAL_MEM(1'b0)")
        sources["decode"] += "\n// " + old + "\n"
        self.assertFalse(self.result(
            sources, "hierarchy.explicit_parameter_handoff"
        ))

    def test_canonical_disable_is_rejected(self) -> None:
        sources = self.mutated(
            "core", ".ENABLE_DUAL_MEM(1)", ".ENABLE_DUAL_MEM(0)"
        )
        self.assertFalse(self.result(
            sources, "hierarchy.canonical_enable_exactly_once"
        ))

    def test_wrapper_lane_cross_is_rejected(self) -> None:
        sources = self.mutated(
            "core",
            ".lane1_req_valid_i(ooo_mem1_req_valid_w)",
            ".lane1_req_valid_i(ooo_mem0_req_valid_w)",
        )
        self.assertFalse(self.result(
            sources, "hierarchy.wrapper_lane_faces_not_crossed"
        ))

    def test_second_miq_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend", "u_mem1_inflight_queue (", "u_mem1_queue_removed ("
        )
        self.assertFalse(self.result(
            sources, "backend.two_independent_miq_instances"
        ))

    def test_mem1_rob_query_alias_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            ".completion7_query_producer_id_i(mem1_completion_producer_id_w)",
            ".completion7_query_producer_id_i(mem_completion_producer_id_w)",
        )
        self.assertFalse(self.result(
            sources, "backend.independent_mem1_rob_open_query"
        ))

    def test_bank1_tieoff_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "assign mem1_req_valid_o = ENABLE_DUAL_MEM &&",
            "assign mem1_req_valid_o = 1'b0 &&",
        )
        self.assertFalse(self.result(
            sources, "backend.captured_bit3_age_request_allocator"
        ))

    def test_second_wb_slot_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "wire mem1_wb_slot1_grant_w =",
            "wire mem1_wb_slot1_removed_w =",
        )
        self.assertFalse(self.result(
            sources, "backend.one_global_two_slot_response_allocator"
        ))

    def test_collector_ingress_shrink_is_rejected(self) -> None:
        sources = self.mutated(
            "backend", ".INGRESS_N(12)", ".INGRESS_N(10)"
        )
        self.assertFalse(self.result(
            sources, "backend.lossless_stage_terminal_set"
        ))

    def test_retry_terminal_lane_disconnect_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "wire mem_retry1_tagged_terminal_w = mem_retry1_cancel_w;",
            "wire mem_retry1_tagged_terminal_w = 1'b0;",
        )
        self.assertFalse(self.result(
            sources, "backend.lossless_stage_terminal_set"
        ))

    def test_second_sq_fill_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            ".fill1_valid_i(sq_fill1_valid_w)",
            ".fill1_valid_i(1'b0)",
        )
        self.assertFalse(self.result(
            sources, "backend.dual_sq_ports_and_singleton_exclusion"
        ))

    def test_rob_wrap_age_oracle_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "tb", "[V8S-ROB-WRAP-AGE]", "[V8S-ROB-LINEAR-AGE-ONLY]"
        )
        self.assertFalse(self.result(
            sources, "tb.focused_parameter_and_behavior_oracles"
        ))

    def test_dual_ex_wb_hold_oracle_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "tb", "[V8S-DUAL-EX-WB-HOLD]", "[V8S-ONE-EX-WB-HOLD-ONLY]"
        )
        self.assertFalse(self.result(
            sources, "tb.focused_parameter_and_behavior_oracles"
        ))

    def test_claim_inflation_is_rejected(self) -> None:
        sources = copy.deepcopy(self.baseline)
        sources["spec"] = sources["spec"].replace(
            "- DI-5: RED", "- DI-5: GREEN", 1
        )
        self.assertFalse(self.result(
            sources, "claim.explicit_checkpoint_red_unqualified_boundary"
        ))
        self.assertFalse(self.result(
            sources, "claim.no_f2_or_promotion_overclaim"
        ))

    def test_unknown_f3_state_is_rejected(self) -> None:
        sources = self.mutated(
            "spec",
            "- F3: `final_pa_sq_ordering_checkpoint`",
            "- F3: `final_pa_sq_ordering_unbound`",
        )
        self.assertFalse(self.result(
            sources, "claim.explicit_checkpoint_red_unqualified_boundary"
        ))


if __name__ == "__main__":
    unittest.main()
