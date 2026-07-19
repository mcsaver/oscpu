#!/usr/bin/env python3
"""Negative/self-tests for the executable architecture gates."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)


def dual_sources() -> dict[str, str]:
    return {
        "scheduling/OooIntIssueQueue.v": "module IQ; endmodule\n",
        "execute/OooIntBackend.v": """
            wire issue0_mem_req_valid_w = issue0_valid_w;
            wire issue1_mem_req_valid_w = issue1_valid_w;
            wire [63:0] issue0_mem_paddr_w;
            wire [63:0] issue1_mem_paddr_w;
            wire mem_issue0_credit_w;
            wire mem_issue1_credit_w;
            LSU u_issue0_lsu();
            LSU u_issue1_lsu();
        """,
        "memory/OooMemAxiBridge.v": """
            module Bridge(
              input mem0_req_valid_i, output mem0_req_ready_o,
              input mem1_req_valid_i, output mem1_req_ready_o,
              output mem0_rsp_valid_o, input mem0_rsp_ready_i,
              output mem1_rsp_valid_o, input mem1_rsp_ready_i);
              wire req0_lookup_valid_w;
              wire req1_lookup_valid_w;
            endmodule
        """,
        "memory/OooMemInflightQueue.v":
            "module MIQ(input push0_valid_i, input push1_valid_i); endmodule\n",
        "memory/OooStoreQueue.v":
            "module SQ(output [127:0] snoop_paddr_o); endmodule\n",
        "cache/OooDataWordCache.v":
            "module DC(input req0_lookup_valid_i,"
            " input req1_lookup_valid_i); endmodule\n",
        "memory/OooLoadQueue.v":
            "module OooLoadQueue #(parameter ENTRY_N = 4)(); endmodule\n",
    }


def width_metrics() -> dict[str, object]:
    return {
        "trace_cycles": 64,
        "independent_alu_ipc": 1.90,
        "boundary_activity": {
            boundary: {
                "peak_uops_per_cycle": 2,
                "total_uops": 122,
            }
            for boundary in arch.WIDTH_BOUNDARIES
        },
    }


class NegativeTests(unittest.TestCase):
    def test_required_gate_inventory_cannot_shrink(self) -> None:
        self.assertEqual(
            arch.GATE_IDS,
            (
                "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
                "OOO-1", "OOO-2", "OOO-3", "OOO-4",
            ),
        )
        self.assertEqual(set(arch.EVIDENCE_TEST), set(arch.GATE_IDS))
        self.assertEqual(
            arch.RESULT_SCHEMA,
            "npc-rv64-architecture-hard-gates-result-v2")
        self.assertEqual(
            arch.EVIDENCE_SCHEMA,
            "npc-rv64-architecture-directed-suite-v2")

    def test_comment_cannot_hide_or_invent_static_lane_role(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += (
            "// ctrl_is_lane1_simple_alu is only a comment\n")
        stripped = {
            name: arch.strip_comments(text) for name, text in sources.items()
        }
        self.assertTrue(all(item.passed for item in arch.di4_checks(stripped)))
        stripped["scheduling/OooIntIssueQueue.v"] += (
            "\nfunction ctrl_is_lane1_simple_alu; endfunction\n")
        checks = {item.check_id: item for item in arch.di4_checks(stripped)}
        self.assertFalse(
            checks["source.capability_predicate_has_entry_metadata"].passed)
        self.assertFalse(
            checks["source.capability_predicate_has_dynamic_steering"].passed)

    def test_capability_metadata_and_swap_make_asymmetry_legal(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += """
            function ctrl_is_lane1_simple_alu; endfunction
            reg [1:0] entry_fu_mask_q [0:7];
            wire issue_pair_swapped_w;
        """
        self.assertTrue(all(item.passed for item in arch.di4_checks(sources)))

    def test_memory_tieoff_is_di3_di5_red_but_not_di4_red(self) -> None:
        sources = dual_sources()
        self.assertTrue(all(item.passed for item in arch.di5_checks(sources)))
        sources["execute/OooIntBackend.v"] = sources[
            "execute/OooIntBackend.v"].replace(
                "wire issue1_mem_req_valid_w = issue1_valid_w;",
                "wire issue1_mem_req_valid_w = 1'b0;")
        self.assertTrue(all(item.passed for item in arch.di4_checks(sources)))
        checks = {item.check_id: item for item in arch.di5_checks(sources)}
        self.assertFalse(
            checks["source.two_live_memory_issue_terminals"].passed)
        di3 = {
            item.check_id: item for item in arch.source_checks(sources)["DI-3"]
        }
        self.assertFalse(di3["source.memory_pairs_two_terminals"].passed)

    def test_frontend_missing_one_consecutive_packet_is_red(self) -> None:
        metrics = {
            "packets_observed": 64,
            "preheated_cycles": 64,
            "accepted_packets": 64,
            "produced_packets": 64,
            "max_initiation_interval": 1,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "frontend_ii1", metrics)))
        metrics["accepted_packets"] = 63
        failures = [item.check_id for item in arch.metric_checks(
            "frontend_ii1", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.frontend.accept_every_cycle"])

    def test_width_one_at_any_boundary_is_red(self) -> None:
        metrics = width_metrics()
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "width_continuity", metrics)))
        activity = metrics["boundary_activity"]
        assert isinstance(activity, dict)
        execute = activity["execute"]
        assert isinstance(execute, dict)
        execute["peak_uops_per_cycle"] = 1
        failures = [item.check_id for item in arch.metric_checks(
            "width_continuity", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.width.execute.peak"])

    def test_speculation_exactly_once_violation_is_red(self) -> None:
        metrics = {
            "multiple_controls_inflight": True,
            "oldest_mispredict_wins": True,
            "wrong_path_selective_squash": True,
            "fired_axi_drained": True,
            "exactly_once_complete_violations": 0,
            "exactly_once_retire_violations": 0,
            "ghost_after_recovery": 0,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "speculation_recovery", metrics)))
        metrics["exactly_once_complete_violations"] = 1
        failures = [item.check_id for item in arch.metric_checks(
            "speculation_recovery", metrics) if not item.passed]
        self.assertEqual(
            failures, ["metric.recovery.exactly_once_complete"])

    def test_store_authorization_and_precise_b_are_hard_gates(self) -> None:
        metrics = {
            "nonalias_load_bypass": True,
            "alias_forward_wait_replay": True,
            "physical_disambiguation": True,
            "stale_read_count": 0,
            "ghost_after_flush": 0,
            "store_side_effect_before_authorization": 0,
            "store_authorization_fire_violations": 0,
            "store_b_terminal_violations": 0,
            "store_retire_before_b_success": 0,
            "precise_b_error_trap": True,
            "fired_store_drain_exactly_once": True,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "memory_ordering", metrics)))

        expected = {
            "store_side_effect_before_authorization":
                "metric.order.store_pre_auth",
            "store_authorization_fire_violations":
                "metric.order.store_exactly_once_fire",
            "store_b_terminal_violations":
                "metric.order.store_b_terminal",
            "store_retire_before_b_success":
                "metric.order.store_retire_after_b",
            "precise_b_error_trap":
                "metric.order.store_precise_b_error",
            "fired_store_drain_exactly_once":
                "metric.order.store_drain_exactly_once",
        }
        for field, check_id in expected.items():
            broken = dict(metrics)
            broken[field] = False if isinstance(metrics[field], bool) else 1
            failures = [item.check_id for item in arch.metric_checks(
                "memory_ordering", broken) if not item.passed]
            self.assertEqual(failures, [check_id])

    def test_missing_second_translation_and_completion_are_red(self) -> None:
        sources = dual_sources()
        sources["memory/OooMemAxiBridge.v"] = sources[
            "memory/OooMemAxiBridge.v"].replace(
                "input mem1_req_valid_i,", "").replace(
                "output mem1_rsp_valid_o,", "")
        checks = {item.check_id: item for item in arch.di5_checks(sources)}
        self.assertFalse(checks["source.two_translation_admissions"].passed)
        self.assertFalse(checks["source.two_completions"].passed)

    def test_arbitrary_older_valid_and_reservation_freeze_are_red(self) -> None:
        sources = dual_sources()
        sources["scheduling/OooIntIssueQueue.v"] += (
            "always @(*) entry_mem_order_block_r = "
            "is_mem && older_valid_seen_r;\n")
        sources["execute/OooIntBackend.v"] += (
            "assign iq_issue0_ready_w = mem_issue_res_valid_q "
            "? 1'b0 : resource_ready_w;\n")
        checks = {item.check_id: item for item in arch.ooo2_checks(sources)}
        self.assertFalse(
            checks["source.no_arbitrary_older_valid_block"].passed)
        self.assertFalse(
            checks["source.no_single_reservation_global_freeze"].passed)

    def test_pair_matrix_cannot_omit_store_store(self) -> None:
        metrics = {
            "pair_matrix": {name: True for name in arch.PAIR_MATRIX}
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "pair_matrix", metrics)))
        del metrics["pair_matrix"]["store_store"]
        failures = [item.check_id for item in arch.metric_checks(
            "pair_matrix", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.pair.store_store"])

    def test_program_slot_permutation_cannot_omit_one_slot(self) -> None:
        metrics = {
            "program_slot_permutation": {
                kind: {"slot0": True, "slot1": True}
                for kind in ("branch", "jal", "jalr", "load", "store", "muldiv")
            },
            "static_lane_role_violations": 0,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "no_static_lane_semantics", metrics)))
        metrics["program_slot_permutation"]["load"]["slot1"] = False
        failures = [item.check_id for item in arch.metric_checks(
            "no_static_lane_semantics", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.perm.load.slot1"])

    def test_inactive_second_memory_face_is_red(self) -> None:
        metrics = {
            "trace_cycles": 64,
            "memory_issue_ipc": 1.90,
            "dual_issue_cycles": 58,
            "agu_accepts": [64, 58],
            "translation_accepts": [64, 58],
            "physical_lsq_queries": [64, 58],
            "cache_admissions": [64, 58],
            "completions": [64, 58],
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "dual_memory_issue", metrics)))
        metrics["translation_accepts"] = [122, 0]
        failures = [item.check_id for item in arch.metric_checks(
            "dual_memory_issue", metrics) if not item.passed]
        self.assertEqual(
            failures, ["metric.dual.translation_accepts"])

    def test_long_latency_requires_old_plus_eight_younger_in_rob(self) -> None:
        metrics = {
            "younger_completed_before_old": {
                "load_miss": 8,
                "mul": 8,
                "div": 8,
            },
            "rob_peak": 9,
            "retire_order_violations": 0,
        }
        self.assertTrue(all(item.passed for item in arch.metric_checks(
            "true_ooo_long_latency", metrics)))
        metrics["rob_peak"] = 8
        failures = [item.check_id for item in arch.metric_checks(
            "true_ooo_long_latency", metrics) if not item.passed]
        self.assertEqual(failures, ["metric.long.rob"])

    def test_missing_evidence_is_red(self) -> None:
        checks, metrics = arch.evidence_checks(
            pathlib.Path.cwd(), {}, "0" * 64, "pair_matrix")
        self.assertEqual(metrics, {})
        self.assertTrue(checks)
        self.assertTrue(all(not item.passed for item in checks))


if __name__ == "__main__":
    unittest.main()
