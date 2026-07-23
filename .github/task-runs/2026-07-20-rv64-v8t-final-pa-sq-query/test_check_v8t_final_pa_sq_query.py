#!/usr/bin/env python3
"""Mutation-negative tests for the v8t/F3 fail-closed source checker."""

from __future__ import annotations

import argparse
import copy
import importlib.util
import pathlib
import sys
import unittest


HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
SPEC = importlib.util.spec_from_file_location(
    "check_v8t", HERE / "check-v8t-final-pa-sq-query.py"
)
assert SPEC and SPEC.loader
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class CheckerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        args = argparse.Namespace(
            repo_root=str(REPO), sq=None, bridge=None, backend=None,
            json_out=None,
        )
        cls.baseline = CHECKER.load_sources(args)

    def result(self, sources: dict[str, str], check_id: str) -> bool:
        matches = [item for item in CHECKER.structural_checks(sources)
                   if item.check_id == check_id]
        self.assertEqual(len(matches), 1, check_id)
        return matches[0].passed

    def mutated(
        self, key: str, old: str, new: str, expected_count: int = 1,
    ) -> dict[str, str]:
        sources = copy.deepcopy(self.baseline)
        self.assertEqual(sources[key].count(old), expected_count, old)
        sources[key] = sources[key].replace(old, new)
        return sources

    def test_baseline_all_checks_pass(self) -> None:
        failed = [item for item in CHECKER.structural_checks(self.baseline)
                  if not item.passed]
        self.assertEqual(failed, [])

    def test_comments_cannot_fake_physical_compare(self) -> None:
        sources = self.mutated(
            "sq",
            "store_byte_addr_r = paddr_q[entry_idx_r] + store_byte_i;",
            "store_byte_addr_r = vaddr_q[entry_idx_r] + store_byte_i;",
            expected_count=2,
        )
        sources["sq"] += (
            "\n// store_byte_addr_r = paddr_q[entry_idx_r] + "
            "store_byte_i;\n"
        )
        self.assertFalse(self.result(
            sources, "sq.final_physical_byte_compare_only"
        ))

    def test_terminal_exclusion_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "sq", "!terminal_q[entry_idx_r]", "1'b1", expected_count=2
        )
        self.assertFalse(self.result(
            sources, "sq.fail_closed_youngest_merge_semantics"
        ))

    def test_partial_coverage_allow_is_rejected(self) -> None:
        sources = self.mutated(
            "sq",
            "(covered_r & query0_strb_i) == query0_strb_i",
            "(|(covered_r & query0_strb_i))",
        )
        self.assertFalse(self.result(
            sources, "sq.fail_closed_youngest_merge_semantics"
        ))

    def test_linear_rob_age_is_rejected(self) -> None:
        sources = self.mutated(
            "sq",
            "rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <\n"
            "            rob_dist(query0_producer_id_i[ROB_INDEX_W-1:0],\n"
            "                     rob_head_idx_i)",
            "rob_idx_q[entry_idx_r] <\n"
            "            query0_producer_id_i[ROB_INDEX_W-1:0]",
        )
        self.assertFalse(self.result(sources, "sq.edge_old_full_pid_age"))

    def test_query1_pa_crossing_is_rejected(self) -> None:
        sources = self.mutated(
            "sq", "load_byte_addr_r = query1_paddr_i + load_byte_i;",
            "load_byte_addr_r = query0_paddr_i + load_byte_i;",
        )
        self.assertFalse(self.result(
            sources, "sq.bank_local_query_payloads_not_crossed"
        ))

    def test_invalid_metadata_allow_is_rejected(self) -> None:
        sources = self.mutated(
            "sq",
            "default: query0_replay_r = 1'b1;\n"
            "        endcase\n"
            "      end\n"
            "      default: begin end",
            "default: query0_allow_r = 1'b1;\n"
            "        endcase\n"
            "      end\n"
            "      default: begin end",
        )
        self.assertFalse(self.result(
            sources, "sq.invalid_and_unknown_metadata_fail_closed"
        ))

    def test_query1_poison_allow_is_rejected(self) -> None:
        sources = self.mutated(
            "sq",
            "default: query1_replay_r = 1'b1;\n"
            "        endcase\n"
            "      end\n"
            "      default: begin end",
            "default: query1_allow_r = 1'b1;\n"
            "        endcase\n"
            "      end\n"
            "      default: begin end",
        )
        self.assertFalse(self.result(
            sources, "sq.invalid_and_unknown_metadata_fail_closed"
        ))

    def test_forward_cannot_authorize_cache_lookup(self) -> None:
        sources = self.mutated(
            "bridge", "mem0_sq_query_allow_i &&\n      access_cacheable_w",
            "mem0_sq_query_forward_i &&\n      access_cacheable_w",
        )
        self.assertFalse(self.result(
            sources, "bridge.only_exact_allow_owns_cache_lookup"
        ))

    def test_pmp_fault_cannot_enter_sq_query(self) -> None:
        sources = self.mutated(
            "bridge",
            "end else if (req_data_pmp_fault_w) begin\n"
            "        rsp_error_q <= 1'b1;\n"
            "        rsp_page_fault_q <= 1'b0;\n"
            "        state_q <= S_RESP;",
            "end else if (req_data_pmp_fault_w) begin\n"
            "        rsp_error_q <= 1'b1;\n"
            "        rsp_page_fault_q <= 1'b0;\n"
            "        state_q <= S_SQ_QUERY;",
        )
        self.assertFalse(self.result(
            sources, "bridge.prequery_fault_and_late_response_quiet"
        ))

    def test_killed_late_ad_cannot_fill_dtlb(self) -> None:
        sources = self.mutated(
            "bridge",
            "wire dtlb_fill_valid_w =\n"
            "      active_expected_identity_match_w",
            "wire dtlb_fill_valid_w =\n"
            "      (killed_write_maintenance_authorized_w && "
            "ad_update_b_ok_w) ||\n"
            "      active_expected_identity_match_w",
        )
        self.assertFalse(self.result(
            sources, "bridge.prequery_fault_and_late_response_quiet"
        ))

    def test_retry_pop_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "miq1_pop_transport_w || mem_sq_retry1_capture_w",
            "miq1_pop_transport_w",
        )
        self.assertFalse(self.result(
            sources, "backend.retry_pop_repush_and_kill_terminal"
        ))

    def test_cross_bank_query_pid_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "mem1_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W",
            "mem_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W",
        )
        self.assertFalse(self.result(
            sources, "backend.bank_local_exact_query_mapping"
        ))

    def test_retry_store_age_priority_inversion_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "mem_retry1_candidate_w &&\n      !mem_bank1_store_older_than_retry_w",
            "mem_retry1_candidate_w &&\n      mem_bank1_store_older_than_retry_w",
        )
        self.assertFalse(self.result(
            sources, "backend.edge_old_store_priority_and_slot_backing"
        ))

    def test_dual_valid_without_slot_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "issue1_dual_ordinary_candidate_w &&\n"
            "      issue1_dual_bank_slot_open_w &&",
            "issue1_dual_ordinary_candidate_w &&",
        )
        self.assertFalse(self.result(
            sources, "backend.edge_old_store_priority_and_slot_backing"
        ))

    def test_retry_load_fence_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
            "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
            "mem_bank1_load_admission_block_w =\n"
            "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
        )
        self.assertFalse(self.result(
            sources, "backend.one_retry_slot_load_admission_fence"
        ))

    def test_bridge_active_load_fence_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
            "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
            "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
            "      mem1_bridge_station_load_w",
        )
        self.assertFalse(self.result(
            sources, "backend.one_retry_slot_load_admission_fence"
        ))

    def test_retry_cancel_priority_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin",
            "end else if (mem_retry1_req_fire_w) begin",
        )
        self.assertFalse(self.result(
            sources, "backend.retry_control_order_and_symmetric_directed"
        ))

    def test_retry_fp_domain_drop_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "mem_retry1_pdest_fp_q <= miq1_head_pdest_fp_w;",
            "mem_retry1_pdest_fp_q <= 1'b0;",
        )
        self.assertFalse(self.result(
            sources, "backend.forwarded_integer_fp_sink_equivalence"
        ))

    def test_legacy_va_gate_in_canonical_mode_is_rejected(self) -> None:
        sources = self.mutated(
            "backend",
            "issue0_load_waits_for_inflight_store_w =\n"
            "      !ENABLE_DUAL_MEM &&",
            "issue0_load_waits_for_inflight_store_w =\n      ",
        )
        self.assertFalse(self.result(
            sources, "backend.canonical_dual_disables_legacy_va_blind_gate"
        ))

    def test_core_bank1_query_cross_wiring_is_rejected(self) -> None:
        sources = self.mutated(
            "core",
            ".mem1_sq_query_valid_i(ooo_mem1_sq_query_valid_w)",
            ".mem1_sq_query_valid_i(ooo_mem0_sq_query_valid_w)",
        )
        self.assertFalse(self.result(
            sources, "hierarchy.two_query_faces_mechanically_propagated"
        ))

    def test_directed_marker_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "backend_tb", "[V8T-F3-BACKEND-RETRY]",
            "[V8T-F3-BACKEND-RETRY-REMOVED]",
        )
        self.assertFalse(self.result(
            sources, "verification.directed_markers_present"
        ))

    def test_claim_inflation_is_rejected(self) -> None:
        sources = copy.deepcopy(self.baseline)
        sources["contract"] = sources["contract"].replace(
            "architecture=RED", "architecture=GREEN", 1
        )
        self.assertFalse(self.result(
            sources, "claim.checkpoint_boundary_remains_fail_closed"
        ))


if __name__ == "__main__":
    unittest.main()
