#!/usr/bin/env python3
"""Mutation-negative unit tests for the v8r/F1 source/claim checker."""

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
SPEC = importlib.util.spec_from_file_location(
    "check_v8r", HERE / "check-v8r-dual-mem-bridge.py"
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
        self.assertEqual(sources[key].count(old), 1)
        sources[key] = sources[key].replace(old, new, 1)
        return sources

    def test_baseline_all_checks_pass(self) -> None:
        failed = [item for item in CHECKER.evaluate(self.baseline)
                  if not item.passed]
        self.assertEqual(failed, [])

    def test_comment_cannot_fake_cross_connection(self) -> None:
        old = ".peer_invalidate_valid_i(lane0_peer_maintenance_valid_w),"
        sources = self.mutated("wrapper", old,
                               ".peer_invalidate_valid_i(1'b0),")
        sources["wrapper"] += "\n// " + old + "\n"
        self.assertFalse(self.result(
            sources, "wrapper.maintenance_exact_cross"
        ))

    def test_ready_gate_is_rejected(self) -> None:
        sources = self.mutated(
            "wrapper",
            "assign lane1_req_ready_o = lane1_req_ready_w;",
            "assign lane1_req_ready_o = lane1_req_ready_w && 1'b0;",
        )
        self.assertFalse(self.result(
            sources, "wrapper.independent_ready_response"
        ))

    def test_response_merge_is_rejected(self) -> None:
        sources = self.mutated(
            "wrapper",
            "assign lane1_rsp_valid_o = lane1_rsp_valid_w;",
            "assign lane1_rsp_valid_o = lane1_rsp_valid_w && "
            "!lane0_rsp_valid_w;",
        )
        self.assertFalse(self.result(
            sources, "wrapper.independent_ready_response"
        ))

    def test_ifu_ad_invalidate_source_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "wrapper",
            "dcache_dma_invalidate_all_i || ifu_ad_update_invalidate_all_i;",
            "dcache_dma_invalidate_all_i || dcache_dma_invalidate_all_i;",
        )
        self.assertFalse(self.result(
            sources, "wrapper.invalidate_sources_exact_merge"
        ))

    def test_one_lane_invalidate_fanout_bypass_is_rejected(self) -> None:
        old = (
            "  ) u_bridge1 (\n"
            "    .clk(clk),\n"
            "    .rst(rst),\n"
            "    .flush_i(flush_i),\n"
            "    .control_full_flush_barrier_i(control_full_flush_barrier_i),\n"
            "    .mmu_flush_i(mmu_flush_i),\n"
            "    .dcache_dma_invalidate_all_i(dcache_invalidate_all_w),"
        )
        new = old.replace(
            ".dcache_dma_invalidate_all_i(dcache_invalidate_all_w),",
            ".dcache_dma_invalidate_all_i(dcache_dma_invalidate_all_i),",
        )
        sources = self.mutated("wrapper", old, new)
        self.assertFalse(self.result(
            sources, "wrapper.common_context_dual_fanout"
        ))

    def test_reconstructed_maintenance_is_rejected(self) -> None:
        sources = self.mutated(
            "bridge",
            "assign peer_maintenance_valid_o = dcache_store_commit_w;",
            "assign peer_maintenance_valid_o = lsu_axi_bvalid_i;",
        )
        self.assertFalse(self.result(
            sources, "bridge.direct_authorized_maintenance"
        ))

    def test_same_cycle_hit_mask_removal_is_rejected(self) -> None:
        sources = self.mutated(
            "dcache",
            "!dma_invalidate_all_i && !peer_lookup_conflict_w;",
            "!dma_invalidate_all_i;",
        )
        self.assertFalse(self.result(
            sources, "dcache.same_cycle_exact_hit_block"
        ))

    def test_fill_after_peer_is_rejected(self) -> None:
        old = (
            "if (peer_invalidate_apply_w) begin\n"
            "        valid_q[peer_idx0_w] <= 1'b0;\n"
            "        if (peer_cross_w)\n"
            "          valid_q[peer_idx1_w] <= 1'b0;\n"
            "      end"
        )
        sources = self.mutated(
            "dcache", old,
            old + "\n      if (fill_we_w) valid_q[fill_idx_w] <= 1'b1;",
        )
        self.assertFalse(self.result(
            sources, "dcache.per_entry_clear_wins_merge"
        ))

    def test_peer_sram_owner_is_rejected(self) -> None:
        sources = self.mutated(
            "dcache",
            "wire sram_en_w = lookup_en_i || fill_we_w || rmw_start_w || rmw_hit_w;",
            "wire sram_en_w = lookup_en_i || fill_we_w || rmw_start_w || "
            "rmw_hit_w || peer_invalidate_event_w;",
        )
        self.assertFalse(self.result(sources, "dcache.peer_not_sram_owner"))

    def test_duplicate_canonical_instantiation_is_rejected(self) -> None:
        sources = copy.deepcopy(self.baseline)
        sources["core"] += "\nOooDualMemBridgeWrapper duplicate();\n"
        self.assertFalse(self.result(
            sources, "claim.canonical_stage_topology_recognized"
        ))

    def test_promoted_stage_without_enable_is_rejected(self) -> None:
        sources = self.mutated(
            "core", ".ENABLE_DUAL_MEM(1)", ".ENABLE_DUAL_MEM(0)"
        )
        self.assertFalse(self.result(
            sources, "claim.canonical_stage_topology_recognized"
        ))

    def test_promoted_stage_requires_exact_handoff(self) -> None:
        sources = self.mutated(
            "f2_contract",
            "v8s/F2 canonical dual-memory integration contract",
            "v8s/F2 stale integration contract",
        )
        self.assertFalse(self.result(
            sources, "claim.stage_promotion_handoff_exact"
        ))

    def test_claim_inflation_is_rejected(self) -> None:
        sources = copy.deepcopy(self.baseline)
        sources["spec"] = sources["spec"].replace(
            "PPA unqualified", "PPA GREEN"
        )
        self.assertFalse(self.result(
            sources, "claim.explicit_leaf_red_unqualified_boundary"
        ))


if __name__ == "__main__":
    unittest.main()
