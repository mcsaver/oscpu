from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
SPEC = importlib.util.spec_from_file_location(
    "producer_holder_semantic_coverage", TOOL_PATH
)
assert SPEC and SPEC.loader
COVERAGE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = COVERAGE
SPEC.loader.exec_module(COVERAGE)

CENSUS = ROOT / "npc/rv64/design/arch/producer-holder-census.json"
GRAPH = COVERAGE.manifest_instance_graph_path(ROOT, CENSUS)
POLICY = (
    ROOT
    / "npc/rv64/design/arch/"
    "producer-holder-semantic-coverage-policy.json"
)


class CurrentWorkspaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.ledger = COVERAGE.build_ledger(ROOT, CENSUS, GRAPH, POLICY)

    def test_exact_inventory_is_expanded(self) -> None:
        counts = self.ledger["counts"]
        self.assertEqual(counts["semantic_units"], 46)
        self.assertEqual(counts["holder_instances"], 17)
        self.assertEqual(counts["unit_instance_bindings"], 52)
        self.assertEqual(counts["units_semantic_pass"], 46)
        self.assertEqual(counts["units_semantic_gap"], 0)
        self.assertEqual(counts["ledger_only_units"], 0)

    def test_local_only_mode_closes_units_without_promoting_system(self) -> None:
        local = COVERAGE.build_ledger(
            ROOT, CENSUS, GRAPH, POLICY, local_only=True
        )
        self.assertEqual(local["status"], "LOCAL_PASS")
        self.assertEqual(local["counts"]["semantic_units"], 46)
        self.assertEqual(local["counts"]["unit_instance_bindings"], 52)
        self.assertEqual(local["counts"]["units_semantic_pass"], 46)
        self.assertEqual(local["global_closure"]["status"], "NOT_EVALUATED")
        self.assertEqual(
            local["system_recertification"]["status"], "NOT_EVALUATED"
        )
        self.assertEqual(
            local["promotion"]["system_recertification"], "NOT_EVALUATED"
        )

    def test_global_and_system_promotions_are_independently_bounded(self) -> None:
        self.assertEqual(self.ledger["status"], "PASS")
        self.assertEqual(
            self.ledger["promotion"],
            {
                "global_no_live_reuse": "GREEN",
                "whole_architecture": "RED",
                "system_recertification": "PASS_CURRENT_CONFIG",
                "ppa": "UNPROMOTED",
            },
        )
        closure = self.ledger["global_closure"]
        self.assertEqual(closure["status"], "PASS")
        self.assertEqual(closure["semantic_units"], 46)
        self.assertEqual(closure["unit_instance_bindings"], 52)
        self.assertEqual(closure["v14g_baselines"], 4)
        self.assertEqual(
            closure["v14g_compile_success_mutations_rejected"], 22
        )
        self.assertEqual(
            closure["optional_lane1_product_configuration"],
            "PRODUCT_INACTIVE_CONSTANT_LOW",
        )
        self.assertEqual(closure["whole_architecture"], "RED")
        self.assertEqual(closure["system_recertification"], "REQUIRED")
        self.assertEqual(closure["ppa"], "UNPROMOTED")
        system = self.ledger["system_recertification"]
        self.assertEqual(system["status"], "PASS")
        self.assertEqual(
            system["system_recertification"], "PASS_CURRENT_CONFIG"
        )
        self.assertEqual(
            system["default_signoff_conjunction"],
            [
                "L0_DIRECTED_RTL",
                "L1_FULL_CORE_DIFFTEST",
                "L2_MINI_SYSTEM",
                "L3_LIGHTWEIGHT_LINUX",
            ],
        )
        self.assertEqual(
            (system["l0_passed"], system["l0_required"]), (113, 113)
        )
        self.assertEqual(
            (
                system["l1_official_passed"],
                system["l1_official_required"],
            ),
            (177, 177),
        )
        self.assertEqual(
            (system["l1_am_passed"], system["l1_am_required"]),
            (61, 61),
        )
        self.assertEqual(system["l2_case"], "all")
        self.assertEqual(system["l3_case"], "all")
        self.assertEqual(system["optional_ubuntu"], "NOT_RUN_OPTIONAL")
        self.assertEqual(system["rtl_assertion_failures"], 0)
        self.assertEqual(system["whole_architecture"], "RED")
        self.assertEqual(system["ppa"], "UNPROMOTED")

    def test_every_census_unit_and_instance_is_auditable(self) -> None:
        unit_ids = [unit["id"] for unit in self.ledger["units"]]
        self.assertEqual(len(unit_ids), len(set(unit_ids)))
        self.assertEqual(len(unit_ids), 46)
        graph = json.loads(GRAPH.read_text(encoding="utf-8"))
        expected_paths = {
            item["path"] for item in graph["graph"]["holder_instances"]
        }
        observed_paths = {
            item["instance_path"]
            for item in self.ledger["unit_instance_bindings"]
        }
        self.assertEqual(observed_paths, expected_paths)

    def test_duplicate_product_instances_are_distinguished_by_evidence(self) -> None:
        self.assertEqual(
            self.ledger["duplicate_instance_modules"],
            ["OooMemAxiBridge", "OooMemInflightQueue"],
        )
        bridge_rows = [
            row
            for row in self.ledger["unit_instance_bindings"]
            if row["module"] == "OooMemAxiBridge"
        ]
        inflight_rows = [
            row
            for row in self.ledger["unit_instance_bindings"]
            if row["module"] == "OooMemInflightQueue"
        ]
        self.assertEqual(len(bridge_rows), 10)
        self.assertTrue(
            all(
                row["semantic_status"] == "PASS"
                and not row["gap_classifications"]
                for row in bridge_rows
            )
        )
        self.assertTrue(inflight_rows)
        self.assertTrue(
            all(
                row["semantic_status"] == "PASS"
                and not row["gap_classifications"]
                for row in inflight_rows
            )
        )

    def test_current_and_stale_candidate_states_are_not_conflated(self) -> None:
        states = {
            item["id"]: item["binding_state"]
            for item in self.ledger["evidence_sets"]
        }
        self.assertEqual(
            states["v8l-current-global-subset"],
            "HISTORICAL_FULL_RTL_BOUND",
        )
        self.assertEqual(
            states["v9r-current-bank-retry-subset"],
            "HISTORICAL_SELECTED_SOURCE_BOUND",
        )
        self.assertEqual(
            states["v8h-leaf-source-and-tb-match"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(states["v8i-fp-stale-source"], "STALE_RTL_SOURCE")
        self.assertEqual(
            states["v8k-pending-system-stale-source"],
            "STALE_RTL_SOURCE",
        )
        self.assertEqual(
            states["v9y-terminal-rtl-match-tb-drift"],
            "STALE_RTL_SOURCE",
        )
        self.assertEqual(
            states["v11b-terminal-collector-current-closure"],
            "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        )
        self.assertEqual(
            states["v11c-memory-tracker-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11d-memory-tracker-cursor-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        expected_current_states = {
            "v11e-rob-slot-generation-current-closure":
                "CURRENT_SELECTED_MACRO_PROJECTION_BOUND",
            "v11f-int-iq-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            "v11g-store-queue-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11h-load-queue-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            "v11j-bridge-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            "v11k-miq-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11l-memory-retry-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11m-memory-reservation-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11n-memory-pending-holder-current-closure":
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            "v11o-memory-buffer-token-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11p-checkpoint-irrevocable-write-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11q-int-lane0-packet-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11r-int-lane1-packet-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11s-muldiv-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11t-clmul-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
            "v11u-pending-system-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            "v11v-fp-producer-current-closure":
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        }
        for evidence_id, expected_state in expected_current_states.items():
            self.assertEqual(states[evidence_id], expected_state)

    def test_selected_replay_binds_old_and_current_designs_explicitly(
        self,
    ) -> None:
        selected = [
            item
            for item in self.ledger["evidence_sets"]
            if item["id"].startswith("v11")
            and item["id"]
            != "v11h-load-queue-producer-current-closure"
        ]
        self.assertEqual(len(selected), 19)
        projection_ids = {"v11e-rob-slot-generation-current-closure"}
        delta_projection_ids = {
            "v11b-terminal-collector-current-closure",
            "v11g-store-queue-holder-current-closure",
            "v11k-miq-holder-current-closure",
            "v11l-memory-retry-holder-current-closure",
            "v11m-memory-reservation-holder-current-closure",
            "v11o-memory-buffer-token-current-closure",
            "v11p-checkpoint-irrevocable-write-current-closure",
            "v11q-int-lane0-packet-current-closure",
            "v11r-int-lane1-packet-current-closure",
            "v11s-muldiv-producer-current-closure",
            "v11t-clmul-producer-current-closure",
            "v11v-fp-producer-current-closure",
        }
        current_execution_ids = {
            "v11n-memory-pending-holder-current-closure",
            "v11u-pending-system-producer-current-closure",
        }
        for item in selected:
            expected_state = (
                "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND"
                if item["id"] in delta_projection_ids
                else (
                    "CURRENT_SELECTED_MACRO_PROJECTION_BOUND"
                    if item["id"] in projection_ids
                    else "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"
                )
            )
            self.assertEqual(item["binding_state"], expected_state)
            detail = item["detail"]
            if item["id"] in current_execution_ids:
                self.assertEqual(
                    detail["evidence_design_id"],
                    detail["current_design_id"],
                )
            else:
                self.assertNotEqual(
                    detail["evidence_design_id"],
                    detail["current_design_id"],
                )
            self.assertTrue(detail["selected_bindings"])
            if item["id"] in projection_ids:
                self.assertIn(
                    "selected_binding_compatibility_receipt", detail
                )
            if item["id"] in delta_projection_ids:
                self.assertIn(
                    "selected_binding_rtl_delta_projection_receipt", detail
                )

    def test_define_projection_is_narrow_and_auditable(self) -> None:
        projected = [
            item
            for item in self.ledger["evidence_sets"]
            if item["binding_state"]
            == "CURRENT_SELECTED_MACRO_PROJECTION_BOUND"
        ]
        self.assertEqual(len(projected), 1)
        receipt_paths = {
            item["detail"]["selected_binding_compatibility_receipt"][
                "path"
            ]
            for item in projected
        }
        self.assertEqual(
            receipt_paths,
            {
                ".github/task-runs/2026-08-06-rv64-"
                "v15h-architecture-debt-current-f7a/evidence/"
                "define-projection-current/receipt.json"
            },
        )
        receipt = json.loads(
            (ROOT / next(iter(receipt_paths))).read_text(encoding="utf-8")
        )
        self.assertEqual(
            {item["name"] for item in receipt["macro_delta"]},
            {"MSTATUS_UXL", "SSTATUS_MASK"},
        )
        self.assertEqual(
            receipt["lexical_dependency"]["selected_reference_hits"],
            [],
        )
        self.assertTrue(receipt["negative_probe"]["detected"])
        self.assertEqual(
            len(receipt["negative_probe"]["mismatches"]), 58
        )
        self.assertTrue(
            all(
                record["equivalent"]
                for profile in receipt["profiles"]
                for record in profile["records"]
            )
        )
        for item in projected:
            define_records = [
                record
                for record in item["detail"]["selected_bindings"]
                if record["path"]
                == "npc/rv64/vsrc/include/define.v"
            ]
            self.assertEqual(len(define_records), 1)
            self.assertFalse(define_records[0]["matches_live"])
            self.assertTrue(
                define_records[0]["semantic_projection_match"]
            )
            self.assertIn(
                "compatibility_receipt", define_records[0]
            )
            self.assertTrue(
                all(
                    binding["matches_live"]
                    for binding in item["detail"]["selected_bindings"]
                    if binding["path"]
                    != "npc/rv64/vsrc/include/define.v"
                )
            )

    def test_local_semantic_projection_excludes_orchestration_files(
        self,
    ) -> None:
        projected_ids = {
            "v11e-rob-slot-generation-current-closure",
            "v11f-int-iq-producer-current-closure",
            "v11g-store-queue-holder-current-closure",
            "v11k-miq-holder-current-closure",
            "v11l-memory-retry-holder-current-closure",
        }
        for evidence in self.ledger["evidence_sets"]:
            if evidence["id"] not in projected_ids:
                continue
            selected_paths = {
                item["path"] for item in evidence["detail"]["selected_bindings"]
            }
            self.assertNotIn("npc/rv64/vsrc/filelist.mk", selected_paths)
        self.assertEqual(
            COVERAGE.NON_SEMANTIC_ORCHESTRATION_PATHS,
            frozenset({"npc/rv64/testbench/Makefile"}),
        )

    def test_v11h_current_run_separates_local_and_system_gates(self) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11h-load-queue-producer-current-closure"
        )
        detail = closure["detail"]
        self.assertTrue(
            detail[
                "raw_q_producer_identity_knownness_assertion_closed"
            ]
        )
        self.assertEqual(detail["raw_q_knownness_assertion_probes"], 1)
        self.assertEqual(
            detail["system_rerun"],
            {
                "required_for_local_closure": False,
                "required_before_system_promotion": True,
                "run": False,
            },
        )
        replay = detail["checker_replay"]
        self.assertEqual(
            replay["mode"], "CURRENT_SELECTED_SOURCE_REUSE"
        )
        self.assertFalse(replay["historical_checker_replay_required"])
        self.assertFalse(replay["rtl_simulation_reexecuted"])
        self.assertEqual(
            replay["binding_state"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(len(replay["selected_bindings"]), 3)
        self.assertNotEqual(
            replay["evidence_design_id"], replay["current_design_id"]
        )
        self.assertEqual(replay["positive_profiles"], 4)
        self.assertEqual(replay["raw_q_knownness_assertion_probes"], 1)
        self.assertEqual(replay["mutation_simulations"], 62)
        self.assertTrue(
            replay["system_rerun_required_before_system_promotion"]
        )
        self.assertFalse(replay["system_rerun_executed"])

    def test_only_bounded_v11b_through_v14r_units_are_closed(self) -> None:
        passed = {
            unit["id"]
            for unit in self.ledger["units"]
            if unit["semantic_status"] == "PASS"
        }
        self.assertEqual(
            passed,
            {
                "terminal-output0-token",
                "terminal-output1-token",
                "terminal-pending-set",
                "memory-tracker-producer-map",
                "memory-tracker-live-set",
                "tracker-next-token-cursor",
                "rob-slot-generation",
                "integer-iq-producers",
                "store-queue-producers",
                "store-queue-owner-tokens",
                "load-queue-producers",
                "bridge-active-token",
                "bridge-response-token",
                "bridge-stage-token",
                "bridge-verified-token-alias",
                "bridge-residency-set",
                "miq-owner-tokens",
                "memory-retry0-producer-cache",
                "memory-retry0-token",
                "memory-retry1-producer-cache",
                "memory-retry1-token",
                "memory-reservation-producer",
                "memory-reservation-token",
                "memory-reservation1-producer",
                "memory-reservation1-token",
                "memory-pending-producer-cache",
                "memory-pending-token",
                "memory-request-hold0-token",
                "memory-request-hold1-token",
                "memory-buffer-token",
                "checkpoint-irrevocable-write-producer",
                "integer-ex0-packed-alias",
                "integer-ex0-packet",
                "branch-resolve-packet",
                "integer-ex1-packed-alias",
                "integer-ex1-packet",
                "muldiv-producer",
                "clmul-producer",
                "pending-system-producer",
                "fp-arith-stage-producers",
                "fp-done-fifo-producers",
                "fp-exec1-packed-alias",
                "fp-exec1-packet",
                "fp-iq-producers",
                "fp-issue-packet",
                "fp-long-producer",
            },
        )

    def test_v11j_bridge_closure_is_dual_instance_and_fail_closed(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"] == "v11j-bridge-holder-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            set(closure["instance_paths"]),
            {
                "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge0",
                "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge1",
            },
        )
        self.assertTrue(detail["raw_owner_tuple_knownness_closed"])
        self.assertTrue(
            detail["exact_residency_set_membership_closed"]
        )
        self.assertTrue(
            detail["stage_active_response_verified_lifecycle_closed"]
        )
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 13
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 26)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertFalse(detail["system_rerun"]["triggered_by_v11j"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11k_miq_closure_is_dual_instance_and_fail_closed(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"] == "v11k-miq-holder-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            set(closure["instance_paths"]),
            {
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend.u_mem1_inflight_queue",
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend.u_mem_inflight_queue",
            },
        )
        self.assertTrue(detail["raw_owner_tuple_xz_knownness_closed"])
        self.assertTrue(
            detail["exact_occupancy_set_membership_closed"]
        )
        self.assertTrue(
            detail[
                "capture_hold_cross_reject_flush_kill_consume_closed"
            ]
        )
        self.assertTrue(
            detail[
                "historical_v11j_v11k_elaborated_logic_identical"
            ]
        )
        self.assertFalse(
            detail["historical_full_yosys_json_retention_required"]
        )
        self.assertTrue(
            detail[
                "current_miq_elaboration_bound_by_selected_source_and_instance_graph"
            ]
        )
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 12
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 24)
        self.assertEqual(detail["interface_xz_probe_cases"], 4)
        self.assertEqual(detail["interface_probe_simulations"], 8)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(detail["push_pop_assertion_markers_closed"])
        self.assertTrue(
            detail[
                "regressions_current_source_artifact_post_bound"
            ]
        )
        self.assertTrue(
            detail[
                "regressions_current_backend_sq_delta_projection_bound"
            ]
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11k"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11l_retry_closure_is_lane_distinct_and_fail_closed(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11l-memory-retry-holder-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 32
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 32)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(
            detail["raw_producer_and_token_xz_knownness_closed"]
        )
        self.assertTrue(
            detail["simultaneous_lane_distinguishability_closed"]
        )
        self.assertTrue(
            detail["capture_hold_transfer_terminal_death_closed"]
        )
        self.assertTrue(detail["c0_empty_and_resident_barriers_closed"])
        self.assertTrue(detail["flush_cancel_over_fire_priority_closed"])
        self.assertTrue(detail["lane10_lane11_cancel_terminal_closed"])
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11l"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11m_reservation_closure_is_lane_distinct_and_fail_closed(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11m-memory-reservation-holder-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 2)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 37
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 37)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(
            detail["raw_producer_and_token_xz_knownness_closed"]
        )
        self.assertTrue(
            detail["pair_credit_and_turnover_atomicity_closed"]
        )
        self.assertTrue(
            detail["capture_hold_request_terminal_death_closed"]
        )
        self.assertTrue(
            detail["lane6_lane7_accepted_terminal_closed"]
        )
        self.assertTrue(
            detail["selective_and_global_recovery_closed"]
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        self.assertTrue(detail["a3_frozen_evidence_unchanged"])
        self.assertFalse(detail["system_rerun"]["triggered_by_v11m"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11n_pending_closure_is_phase_exact_and_fail_closed(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11n-memory-pending-holder-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 16
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 32)
        self.assertEqual(detail["assertion_mutation_cases_rejected"], 3)
        self.assertEqual(detail["release_oracle_mutation_cases_rejected"], 13)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertEqual(detail["retired_intermediate_artifacts"], 55)
        self.assertEqual(detail["retained_compile_images"], 0)
        self.assertTrue(detail["stimulus_owned_full_pid_and_token"])
        self.assertTrue(
            detail["read_write_hold_and_terminal_death_closed"]
        )
        self.assertTrue(detail["lane0_lane9_accepted_terminal_closed"])
        self.assertTrue(
            detail["dispatch_lane1_to_execution_terminal0_closed"]
        )
        self.assertTrue(detail["amo_transient_holder_disjoint_closed"])
        self.assertTrue(
            detail["lane9_vs_lane6_lane7_lane8_natural_cycle_closed"]
        )
        self.assertEqual(detail["a3_original_status"], "FAIL_RETAINED")
        self.assertEqual(
            detail["a3_checker_replay"], "PASS_INDEPENDENT"
        )
        self.assertTrue(detail["production_design_id_current"])
        self.assertFalse(detail["system_rerun"]["triggered_by_v11n"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11o_buffer_closure_conjoins_product_and_legacy(self) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11o-memory-buffer-token-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 8
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 16)
        self.assertEqual(detail["product_static_negative_tests"], 8)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(detail["product_parameter_chain_closed"])
        self.assertTrue(
            detail["product_birth_and_request_constant_zero"]
        )
        self.assertTrue(detail["legacy_lane0_lane1_birth_closed"])
        self.assertTrue(
            detail["legacy_hold_transfer_cancel_death_closed"]
        )
        self.assertEqual(detail["a3_original_status"], "FAIL_RETAINED")
        self.assertEqual(
            detail["a3_checker_replay"], "PASS_INDEPENDENT"
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertTrue(
            detail["current_product_reachability_design_id_current"]
        )
        self.assertFalse(detail["historical_full_yosys_json_retained"])
        self.assertFalse(
            detail["historical_full_yosys_json_retention_required"]
        )
        self.assertEqual(
            detail["selected_binding_rtl_delta_projection_receipt"]["path"],
            ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-"
            "current-f7a/evidence/selected-binding-rtl-delta-projection/"
            "receipt.json",
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11o"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11p_checkpoint_holder_closes_full_width_lifecycle(self) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11p-checkpoint-irrevocable-write-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 10
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 20)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(
            detail["store_and_amo_physical_write_birth_closed"]
        )
        self.assertTrue(detail["postterminal_holder_residency_closed"])
        self.assertTrue(
            detail["amo_tracker_death_before_retire_closed"]
        )
        self.assertTrue(detail["full_width_lane0_retire_guard_closed"])
        self.assertTrue(detail["restore_gate_closed"])
        self.assertEqual(detail["a3_original_status"], "FAIL_RETAINED")
        self.assertEqual(
            detail["a3_checker_replay"], "PASS_INDEPENDENT"
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11p"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11q_lane0_completion_and_resolve_are_paired(self) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11q-int-lane0-packet-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 12
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 24)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(
            detail["stimulus_owned_generation_one_index_two"]
        )
        self.assertTrue(detail["ex0_raw_packet_fields_closed"])
        self.assertTrue(detail["ex0_packed_alias_closed"])
        self.assertTrue(detail["branch_resolve_packet_fields_closed"])
        self.assertTrue(
            detail["raw_ex0_resolve_full_pid_coherence_closed"]
        )
        self.assertTrue(detail["wrong_generation_negative_closed"])
        self.assertTrue(
            detail["same_cycle_flush_and_next_cycle_death_closed"]
        )
        self.assertEqual(detail["a3_original_status"], "FAIL_RETAINED")
        self.assertEqual(
            detail["a3_checker_replay"], "PASS_INDEPENDENT"
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11q"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_v11r_lane1_alu_and_local_memory_share_exact_packet(
        self,
    ) -> None:
        closure = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["id"]
            == "v11r-int-lane1-packet-current-closure"
        )
        detail = closure["detail"]
        self.assertEqual(
            closure["instance_paths"],
            [
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ],
        )
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 14
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 28)
        self.assertEqual(detail["ordinary_regressions_passed"], 3)
        self.assertTrue(
            detail["stimulus_owned_generation_one_index_three"]
        )
        self.assertTrue(detail["ex1_alu_source_closed"])
        self.assertTrue(detail["ex1_local_memory_source_closed"])
        self.assertTrue(detail["ex1_raw_packet_fields_closed"])
        self.assertTrue(detail["ex1_packed_alias_closed"])
        self.assertTrue(
            detail["exact_open_and_full_pid_claim_closed"]
        )
        self.assertTrue(detail["wrong_generation_negative_closed"])
        self.assertTrue(
            detail["same_cycle_flush_and_next_cycle_death_closed"]
        )
        self.assertEqual(detail["a3_original_status"], "FAIL_RETAINED")
        self.assertEqual(detail["a3_execution_state"], "COMPLETE")
        self.assertEqual(detail["a3_terminal_state"], "COMPLETE")
        self.assertEqual(detail["a3_oracle_state"], "OLD_ORACLE_INVALID")
        self.assertEqual(
            detail["a3_checker_replay"], "PASS_INDEPENDENT"
        )
        self.assertEqual(
            detail["a3_interpretation"],
            "SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE",
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        self.assertFalse(detail["system_rerun"]["triggered_by_v11r"])
        self.assertFalse(detail["system_rerun"]["run"])

    def test_all_units_now_have_at_least_one_candidate(self) -> None:
        no_candidate = [
            unit
            for unit in self.ledger["units"]
            if not unit["candidate_evidence"]
        ]
        self.assertEqual(
            len(no_candidate),
            self.ledger["counts"]["units_without_candidate_evidence"],
        )
        self.assertFalse(no_candidate)

    def test_v11s_muldiv_producer_is_current_and_closed(self) -> None:
        evidence = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["binding_kind"] == "v11s_muldiv_producer"
        )
        detail = evidence["detail"]
        self.assertEqual(evidence["scope"], "COMPLETE")
        self.assertTrue(evidence["semantic_closure"])
        self.assertEqual(
            evidence["binding_state"],
            "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        )
        self.assertEqual(evidence["unit_ids"], ["muldiv-producer"])
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 9
        )
        self.assertEqual(
            detail["mutation_simulations_rejected"], 18
        )
        self.assertEqual(detail["ordinary_regressions_passed"], 4)
        self.assertTrue(
            detail["stimulus_owned_generation_one_index_two"]
        )
        self.assertTrue(
            detail["mul_and_div_iterative_paths_closed"]
        )
        self.assertTrue(
            detail["request_capture_and_holder_residency_closed"]
        )
        self.assertTrue(
            detail["exact_open_and_wrong_generation_negative_closed"]
        )
        self.assertTrue(
            detail["authorized_wb_and_ordered_retirement_closed"]
        )
        self.assertTrue(
            detail["terminal_release_and_full_flush_death_closed"]
        )
        self.assertTrue(
            detail["eight_younger_dual_issue_pressure_closed"]
        )
        self.assertTrue(
            detail["leaf_kill_and_functional_regression_closed"]
        )
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        unit = next(
            item
            for item in self.ledger["units"]
            if item["id"] == "muldiv-producer"
        )
        self.assertEqual(unit["semantic_status"], "PASS")
        self.assertFalse(unit["gap_classifications"])

    def test_v11t_clmul_producer_is_current_compact_and_closed(self) -> None:
        evidence = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        detail = evidence["detail"]
        self.assertEqual(evidence["scope"], "COMPLETE")
        self.assertTrue(evidence["semantic_closure"])
        self.assertEqual(
            evidence["binding_state"],
            "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        )
        self.assertEqual(evidence["unit_ids"], ["clmul-producer"])
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 9
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 18)
        self.assertEqual(detail["ordinary_regressions_passed"], 4)
        self.assertTrue(detail["clmul_low_and_high_paths_closed"])
        self.assertTrue(
            detail["request_capture_and_holder_residency_closed"]
        )
        self.assertTrue(
            detail["exact_open_and_wrong_generation_negative_closed"]
        )
        self.assertTrue(
            detail["authorized_wb_and_ordered_retirement_closed"]
        )
        self.assertTrue(
            detail["terminal_release_and_full_flush_death_closed"]
        )
        self.assertEqual(detail["retired_compile_artifacts_validated"], 36)
        self.assertTrue(detail["focused_testbench_overlay_reconstructed"])
        self.assertFalse(detail["eight_younger_pressure_closed"])
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        unit = next(
            item
            for item in self.ledger["units"]
            if item["id"] == "clmul-producer"
        )
        self.assertEqual(unit["semantic_status"], "PASS")
        self.assertFalse(unit["gap_classifications"])

    def test_v11u_pending_system_is_current_compact_and_closed(self) -> None:
        evidence = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        detail = evidence["detail"]
        self.assertEqual(evidence["scope"], "COMPLETE")
        self.assertTrue(evidence["semantic_closure"])
        self.assertEqual(
            evidence["binding_state"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(evidence["unit_ids"], ["pending-system-producer"])
        self.assertEqual(detail["positive_profiles"], 13)
        self.assertEqual(detail["assertion_negative_profiles_rejected"], 3)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 21
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 24)
        self.assertEqual(detail["release_mode_mutation_cases_rejected"], 10)
        self.assertEqual(
            detail["assertion_mode_mutation_cases_rejected"], 11
        )
        self.assertTrue(
            detail[
                "legacy_release_mutation_label_interpreted_as_mixed_mode"
            ]
        )
        self.assertEqual(detail["ordinary_regressions_passed"], 4)
        self.assertTrue(detail["pre_rob_has_no_lease_closed"])
        self.assertTrue(detail["csr_only_exact_birth_closed"])
        self.assertTrue(detail["raw_lease_metadata_independence_closed"])
        self.assertTrue(
            detail["ordinary_clear_and_clear_dispatched_hold_closed"]
        )
        self.assertTrue(detail["exact_commit_and_flush_death_closed"])
        self.assertTrue(detail["full_pid_and_pc_authorization_closed"])
        self.assertTrue(detail["global_live_mask_reuse_fence_closed"])
        self.assertTrue(
            detail["production_rob_birth_and_exact_death_closed"]
        )
        self.assertTrue(
            detail["production_core_local_flush_death_closed"]
        )
        self.assertTrue(detail["production_wrapper_chain_closed"])
        self.assertTrue(detail["actual_compiler_input_closure_closed"])
        self.assertEqual(detail["compiler_input_profiles_validated"], 41)
        self.assertEqual(
            detail["compiler_input_compilations_validated"], 48
        )
        self.assertEqual(
            set(detail["compiler_input_required_claim_rtl"]),
            {
                "npc/rv64/vsrc/writeback/OooRob.v",
                "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
                "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
                "npc/rv64/vsrc/control/"
                "OooPendingSystemAdmissionCancelGate.v",
            },
        )
        self.assertEqual(detail["retired_compile_artifacts_validated"], 169)
        self.assertTrue(detail["production_design_id_current"])
        unit = next(
            item
            for item in self.ledger["units"]
            if item["id"] == "pending-system-producer"
        )
        self.assertEqual(unit["semantic_status"], "PASS")
        self.assertFalse(unit["gap_classifications"])

    def test_v11v_fp_producers_are_current_compact_and_closed(self) -> None:
        evidence = next(
            item
            for item in self.ledger["evidence_sets"]
            if item["binding_kind"] == "v11v_fp_producer"
        )
        detail = evidence["detail"]
        expected_units = {
            "fp-arith-stage-producers",
            "fp-done-fifo-producers",
            "fp-exec1-packed-alias",
            "fp-exec1-packet",
            "fp-iq-producers",
            "fp-issue-packet",
            "fp-long-producer",
        }
        self.assertEqual(evidence["scope"], "COMPLETE")
        self.assertTrue(evidence["semantic_closure"])
        self.assertEqual(
            evidence["binding_state"],
            "CURRENT_SELECTED_SOURCE_DELTA_PROJECTION_BOUND",
        )
        self.assertEqual(set(evidence["unit_ids"]), expected_units)
        self.assertEqual(detail["positive_profiles"], 4)
        self.assertEqual(
            detail["compile_success_mutation_cases_rejected"], 14
        )
        self.assertEqual(detail["mutation_simulations_rejected"], 28)
        self.assertEqual(
            detail["raw_producer_identity_knownness_mutations_rejected"],
            6,
        )
        self.assertEqual(detail["ordinary_regressions_passed"], 4)
        for key in (
            "iq_birth_and_residency_closed",
            "issue_packet_capture_and_residency_closed",
            "arith_five_stage_residency_closed",
            "exec1_packet_and_packed_alias_closed",
            "long_iterative_residency_closed",
            "done_fifo_pending_and_terminal_release_closed",
            "wrong_generation_and_ordered_retirement_closed",
            "full_flush_death_closed",
            "focused_testbench_overlay_reconstructed",
        ):
            self.assertTrue(detail[key], key)
        self.assertEqual(detail["retired_compile_artifacts_validated"], 51)
        self.assertFalse(detail["production_design_id_current"])
        self.assertIn(
            "selected_binding_rtl_delta_projection_receipt", detail
        )
        units = {
            item["id"]: item
            for item in self.ledger["units"]
            if item["id"] in expected_units
        }
        self.assertEqual(set(units), expected_units)
        self.assertTrue(
            all(
                unit["semantic_status"] == "PASS"
                and not unit["gap_classifications"]
                for unit in units.values()
            )
        )


class NegativeContractTests(unittest.TestCase):
    def scratch_dir(self) -> pathlib.Path:
        scratch = getattr(self, "_scratch", None)
        if scratch is None:
            scratch_root = (
                ROOT
                / ".github/runtime-artifacts/test-scratch/"
                "producer-holder-semantic"
            )
            scratch_root.mkdir(parents=True, exist_ok=True)
            scratch = tempfile.TemporaryDirectory(
                prefix="case-", dir=scratch_root
            )
            self._scratch = scratch
            self.addCleanup(scratch.cleanup)
        return pathlib.Path(scratch.name)

    def write_policy(self, payload: dict) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            prefix="policy-",
            suffix=".json",
            dir=self.scratch_dir(),
            delete=False,
        )
        self.addCleanup(pathlib.Path(temporary.name).unlink, missing_ok=True)
        with temporary:
            json.dump(payload, temporary)
        return pathlib.Path(temporary.name)

    def write_v11t_summary_bundle(
        self,
        payload: dict,
        source_summary: pathlib.Path,
    ) -> pathlib.Path:
        del source_summary
        return self.write_policy(payload)

    def test_negative_fixture_uses_runtime_scratch(self) -> None:
        path = self.write_policy({"fixture": "scratch"})
        expected_root = (
            ROOT
            / ".github/runtime-artifacts/test-scratch/"
            "producer-holder-semantic"
        )
        path.relative_to(expected_root)
        self.assertNotEqual(path.parent, ROOT)

    def test_define_projection_negative_probe_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item.get("binding_kind") == "v11e_rob_slot_generation"
        )
        receipt = json.loads(
            (ROOT / closure["selected_binding_compatibility_receipt"])
            .read_text(encoding="utf-8")
        )
        receipt["negative_probe"]["detected"] = False
        receipt_path = self.write_policy(receipt)
        closure["selected_binding_compatibility_receipt"] = (
            receipt_path.relative_to(ROOT).as_posix()
        )
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "negative probe",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_define_projection_cannot_mask_consumer_drift(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item.get("binding_kind") == "v11e_rob_slot_generation"
        )
        receipt = json.loads(
            (ROOT / closure["selected_binding_compatibility_receipt"])
            .read_text(encoding="utf-8")
        )
        target = receipt["target"]
        records = [
            {
                "path": target["path"],
                "role": "rtl",
                "evidence_sha256": target["baseline_sha256"],
                "live_sha256": target["current_sha256"],
                "matches_live": False,
            },
            {
                "path": "npc/rv64/vsrc/writeback/OooRob.v",
                "role": "rtl",
                "evidence_sha256": "0" * 64,
                "live_sha256": COVERAGE.sha256_file(
                    ROOT / "npc/rv64/vsrc/writeback/OooRob.v"
                ),
                "matches_live": False,
            },
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "cannot cover non-define selected-source drift",
        ):
            COVERAGE.validate_selected_binding_projection(
                ROOT,
                closure,
                records,
                receipt["current_design_id"],
            )

    def test_internal_manifest_projection_requires_exact_sha_pair(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item.get("binding_kind") == "v11e_rob_slot_generation"
        )
        receipt = json.loads(
            (ROOT / closure["selected_binding_compatibility_receipt"])
            .read_text(encoding="utf-8")
        )
        target = receipt["target"]
        compatibility = {
            target["path"]: {
                "evidence_sha256": target["baseline_sha256"],
                "live_sha256": target["current_sha256"],
            }
        }
        self.assertEqual(
            COVERAGE.stale_manifest_paths(
                ROOT,
                {target["path"]: target["baseline_sha256"]},
                compatible_records=compatibility,
            ),
            [],
        )
        self.assertEqual(
            COVERAGE.stale_manifest_paths(
                ROOT,
                {target["path"]: "0" * 64},
                compatible_records=compatibility,
            ),
            [target["path"]],
        )

    def test_sha256_cache_invalidates_after_file_change(self) -> None:
        temporary = tempfile.NamedTemporaryFile(
            mode="wb", dir=self.scratch_dir(), delete=False
        )
        path = pathlib.Path(temporary.name)
        self.addCleanup(path.unlink, missing_ok=True)
        with temporary:
            temporary.write(b"a")
        first = COVERAGE.sha256_file(path)
        path.write_bytes(b"b")
        second = COVERAGE.sha256_file(path)
        self.assertNotEqual(first, second)

    def test_json_cache_invalidates_after_same_size_rewrite(self) -> None:
        temporary = tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=self.scratch_dir(),
            delete=False,
        )
        path = pathlib.Path(temporary.name)
        self.addCleanup(path.unlink, missing_ok=True)
        with temporary:
            temporary.write('{"value": 1}')
        first = COVERAGE.load_json(path)
        path.write_text('{"value": 2}', encoding="utf-8")
        second = COVERAGE.load_json(path)
        self.assertEqual(first, {"value": 1})
        self.assertEqual(second, {"value": 2})

    def test_unknown_unit_in_policy_is_rejected(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy["evidence_sets"][0]["unit_ids"].append("not-a-census-unit")
        with self.assertRaisesRegex(COVERAGE.CoverageError, "invalid unit IDs"):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_policy_cannot_drop_reviewed_semantic_completion(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy["semantic_complete"] = False
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "must bind the reviewed global"
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_policy_cannot_drop_global_closure_receipt(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy.pop("global_closure_receipt")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "global closure receipt is missing"
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_policy_cannot_drop_system_recertification_receipt(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy.pop("system_recertification_receipt")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "system recertification receipt is missing",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_system_recertification_pointer_cannot_select_other_receipt(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy["system_recertification_receipt"] = policy[
            "global_closure_receipt"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "system recertification receipt is not current PASS",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11b_closure_cannot_be_rebound_to_unrelated_unit(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11b_terminal_collector"
        )
        closure["unit_ids"][-1] = "pending-system-producer"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "exact collector unit set"
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11c_closure_cannot_be_rebound_to_cursor(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11c_memory_tracker"
        )
        closure["unit_ids"][-1] = "tracker-next-token-cursor"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "exact map/live-set unit set"
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11d_cursor_closure_cannot_be_rebound_to_live_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11d_memory_tracker_cursor"
        )
        closure["unit_ids"][-1] = "memory-tracker-live-set"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only tracker-next-token-cursor",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11e_generation_closure_cannot_be_rebound_to_cursor(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11e_rob_slot_generation"
        )
        closure["unit_ids"][-1] = "tracker-next-token-cursor"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only rob-slot-generation",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11f_integer_iq_closure_cannot_be_rebound_to_rob(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11f_int_iq_producer"
        )
        closure["unit_ids"][-1] = "rob-slot-generation"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only integer-iq-producers",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11g_store_queue_closure_cannot_drop_owner_tokens(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11g_store_queue_holder"
        )
        closure["unit_ids"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind exactly store-queue-producers",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11g_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11g_store_queue_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["role"] != "testbench"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11b_selected_source_role_cannot_be_relabeled(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11b_terminal_collector"
        )
        closure["current_selected_bindings"][-1]["role"] = "rtl"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11b_compact_image_receipt_cannot_claim_retention(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11b_terminal_collector"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["compile_success_mutations"][0]["compiled_image"][
            "retained"
        ] = True
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "compact image receipt is invalid"
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_load_queue_closure_cannot_be_rebound_to_store(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        closure["unit_ids"][-1] = "store-queue-producers"
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only load-queue-producers",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        closure["current_selected_bindings"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_system_promotion_rerun_requirement_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["scope"]["system_rerun"][
            "required_before_system_promotion"
        ] = False
        mutated_path = self.write_policy(summary)
        closure["summary"] = (
            mutated_path.relative_to(ROOT).as_posix()
        )
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "LoadQueue producer summary is not complete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_system_rerun_schema_cannot_drop_run_field(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        del summary["scope"]["system_rerun"]["run"]
        mutated_path = self.write_policy(summary)
        closure["summary"] = (
            mutated_path.relative_to(ROOT).as_posix()
        )
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "LoadQueue producer summary is not complete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_selected_source_reuse_rejects_unbound_replay_receipt(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        closure["checker_replay_receipt"] = (
            ".github/task-runs/2026-07-30-rv64-v11h-"
            "load-queue-producer-semantic-coverage/evidence/"
            "load-queue-producer-attempt-3-checker-replay/receipt.json"
        )
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11H checker-replay receipt is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_historical_summary_substitution_is_rejected(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        closure["summary"] = (
            ".github/task-runs/2026-07-30-rv64-v11h-"
            "load-queue-producer-semantic-coverage/evidence/"
            "load-queue-producer-attempt-4/summary.json"
        )
        closure.pop("checker_replay_receipt", None)
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11H production LoadQueue artifact hash/size mismatch",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11j_closure_requires_exact_five_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11j_bridge_holder"
        )
        closure["unit_ids"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind exactly the five bridge",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11j_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11j_bridge_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["role"] != "testbench"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11j_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("checks_both_product_instances", False),
            "instance": lambda summary: summary["production"][
                "product_instances"
            ].pop(),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 31),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(POLICY.read_text(encoding="utf-8"))
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"] == "v11j_bridge_holder"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                mutated_path = self.write_policy(summary)
                closure["summary"] = (
                    mutated_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11J bridge-holder summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11k_closure_requires_only_miq_owner_tokens(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        closure["unit_ids"].append("bridge-active-token")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only miq-owner-tokens",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11k_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if not binding["path"].endswith(
                "tb_ooo_dual_mem_inflight_queue_semantic.sv"
            )
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11k_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("checks_swapped_tuple_rejection", False),
            "instance": lambda summary: summary["production"][
                "product_instances"
            ].pop(),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 25),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(POLICY.read_text(encoding="utf-8"))
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"] == "v11k_miq_holder"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                mutated_path = self.write_policy(summary)
                closure["summary"] = (
                    mutated_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11K MIQ-holder summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11k_requires_two_state_elaborated_logic_identity(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        identity = json.loads(
            (ROOT / closure["elaborated_logic_identity"]).read_text(
                encoding="utf-8"
            )
        )
        identity["production_elaborated_logic_changed"] = True
        identity_path = self.write_policy(identity)
        closure["elaborated_logic_identity"] = (
            identity_path.relative_to(ROOT).as_posix()
        )
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "two-state elaborated RTL identity is not proven",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11k_does_not_require_cleaned_full_yosys_json(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        identity = json.loads(
            (ROOT / closure["elaborated_logic_identity"]).read_text(
                encoding="utf-8"
            )
        )
        self.assertTrue(
            all(
                not (ROOT / identity[label]["path"]).exists()
                for label in ("v11j", "v11k")
            )
        )
        ledger = COVERAGE.build_ledger(ROOT, CENSUS, GRAPH, POLICY)
        result = next(
            item
            for item in ledger["evidence_sets"]
            if item["id"] == "v11k-miq-holder-current-closure"
        )
        self.assertTrue(
            result["detail"][
                "current_miq_elaboration_bound_by_selected_source_and_instance_graph"
            ]
        )

    def test_v11k_push_interface_probe_marker_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        profile = next(
            item
            for item in summary["profiles"]
            if item["profile"] == "accepted-push-tuple-x-assert"
        )
        profile["markers"]["v11k_miq_push_tuple_known"] = 0
        profile["markers"]["assertion_marker_total"] = 0
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "interface assertion probe did not hit its marker",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11k_regression_source_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11k_miq_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        regression = next(
            item
            for item in summary["regressions"]
            if item["test"] == "tb_ooo_int_backend"
        )
        regression["source_pre_post_match"] = False
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11K regression binding is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11l_closure_requires_exact_four_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11l_memory_retry_holder"
        )
        closure["unit_ids"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind exactly the four bank-local",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11l_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11l_memory_retry_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["role"] != "testbench"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11l_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__(
                "simultaneous_dual_capture", False
            ),
            "instance": lambda summary: summary["production"][
                "product_instances"
            ].clear(),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 33),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(POLICY.read_text(encoding="utf-8"))
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11l_memory_retry_holder"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11L memory retry-holder summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11l_mutation_stage_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11l_memory_retry_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "retry1-fire-premature-terminal"
        )
        mutation["expected_stage"] = "tracker1-not-exact-live"
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11L mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11l_assert_compile_define_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11l_memory_retry_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        profile = next(
            item
            for item in summary["profiles"]
            if item["profile"] == "production-assert"
        )
        profile["compile"]["defines"].remove("-DOOO_ASSERT")
        profile["compile"]["command"].remove("-DOOO_ASSERT")
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11L production profile is not clean",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11l_regression_source_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11l_memory_retry_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        regression = next(
            item
            for item in summary["regressions"]
            if item["test"] == "tb_ooo_int_backend_v9r_sq_retry_c0"
        )
        regression["source_pre_post_match"] = False
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11L regression binding is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11m_closure_requires_exact_four_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11m_memory_reservation_holder"
        )
        closure["unit_ids"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind exactly the four reservation",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11m_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11m_memory_reservation_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["role"] != "testbench"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11m_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "generation_oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__(
                "nonzero_lane_distinct_producer_generation", False
            ),
            "token_oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("owner_token_high_bits_exercised", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 38),
            "a3_binding": lambda summary: summary[
                "scope"
            ].__setitem__("a3_frozen_evidence_unchanged", False),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(POLICY.read_text(encoding="utf-8"))
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11m_memory_reservation_holder"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11M memory-reservation holder summary "
                    "is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11m_mutation_stage_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11m_memory_reservation_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "reservation0-token-high-truncate"
        )
        mutation["expected_stage"] = "reservation1-holder-tuple"
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11M mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11m_assert_compile_define_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11m_memory_reservation_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        profile = next(
            item
            for item in summary["profiles"]
            if item["profile"] == "production-assert"
        )
        profile["compile"]["defines"].remove("-DOOO_ASSERT")
        profile["compile"]["command"].remove("-DOOO_ASSERT")
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11M production profile is not clean",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11m_regression_source_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11m_memory_reservation_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        regression = next(
            item
            for item in summary["regressions"]
            if item["test"]
            == "tb_ooo_int_backend_v11l_memory_retry_holder"
        )
        regression["source_pre_post_match"] = False
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11M regression binding is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11n_closure_requires_exact_pending_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11n_memory_pending_holder"
        )
        closure["unit_ids"].pop()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind exactly the singleton producer-cache/token",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11n_selected_source_set_cannot_drop_testbench(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11n_memory_pending_holder"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["role"] != "testbench"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11n_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "pid_oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("expected_pid_uses_pending_dut_state", True),
            "token_high_bits": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("owner_token_28_high_bits_exercised", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 29),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(POLICY.read_text(encoding="utf-8"))
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11n_memory_pending_holder"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11N memory-pending holder summary "
                    "is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11n_mutation_stage_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11n_memory_pending_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "capture-token-high-truncate"
        )
        mutation["expected_stage"] = "post-write-hold"
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11N mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11n_g1_assert_compile_define_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11n_memory_pending_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        profile = next(
            item
            for item in summary["profiles"]
            if item["profile"] == "production-g1-assert"
        )
        profile["compile"]["defines"].remove("-DOOO_ASSERT")
        profile["compile"]["command"].remove("-DOOO_ASSERT")
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11N production profile is not clean",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11n_regression_source_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11n_memory_pending_holder"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        regression = next(
            item
            for item in summary["regressions"]
            if item["test"]
            == "tb_ooo_int_backend_v11l_memory_retry_holder"
        )
        regression["source_pre_post_match"] = False
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11N regression binding is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11o_closure_requires_only_memory_buffer_token(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11o_memory_buffer_token"
        )
        closure["unit_ids"].append("memory-pending-token")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only memory-buffer-token",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11o_selected_source_set_cannot_drop_parameter_layer(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11o_memory_buffer_token"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/execute/OooExecuteBackend.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11o_summary_requires_product_legacy_conjunction(
        self,
    ) -> None:
        mutations = {
            "product": lambda summary: summary[
                "product_reachability"
            ].__setitem__("status", "FAIL"),
            "legacy": lambda summary: summary[
                "legacy_dynamic_oracle"
            ].__setitem__("lane1_birth", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 19),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(
                    POLICY.read_text(encoding="utf-8")
                )
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11o_memory_buffer_token"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11O memory-buffer token summary "
                    "is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11o_mutation_stage_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11o_memory_buffer_token"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "transfer-token-high-truncate"
        )
        mutation["expected_stage"] = "lane0-buffer-birth"
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11O mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11o_embedded_product_receipt_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11o_memory_buffer_token"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["product_reachability"]["receipt_payload"][
            "elaborated_contract"
        ]["constant_zero_nets"]["issue1_mem_buffer_fire_w"] = [17]
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "embedded reachability payload differs from receipt",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11p_closure_requires_only_checkpoint_holder(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11p_checkpoint_irrevocable_write"
        )
        closure["unit_ids"].append("memory-pending-token")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "must bind only checkpoint-irrevocable-write-producer",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11p_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("amo_tracker_death_before_retire", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 23),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(
                    POLICY.read_text(encoding="utf-8")
                )
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11p_checkpoint_irrevocable_write"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11P checkpoint irreversible-write summary "
                    "is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11p_mutation_stage_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11p_checkpoint_irrevocable_write"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "retire-compares-index-only"
        )
        mutation["expected_stage"] = "store-exact-retire-edge"
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11P mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11p_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"]
            == "v11p_checkpoint_irrevocable_write"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/memory/OooStoreQueue.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11q_closure_requires_exact_paired_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11q_int_lane0_packet"
        )
        closure["unit_ids"].append("integer-ex1-packet")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11Q integer lane0 packet evidence must bind exactly",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11q_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("raw_ex0_resolve_coherence_checked", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 27),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(
                    POLICY.read_text(encoding="utf-8")
                )
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"] == "v11q_int_lane0_packet"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11Q integer lane0 packet summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11q_mutation_stage_and_unit_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11q_int_lane0_packet"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "branch-coherence-index-only"
        )
        mutation["expected_stage"] = "branch-down-pid"
        mutation["unit_ids"] = ["integer-ex0-packet"]
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11Q mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11q_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11q_int_lane0_packet"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/pipeline/PipeStageReg.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11r_closure_requires_exact_lane1_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11r_int_lane1_packet"
        )
        closure["unit_ids"].append("integer-ex0-packet")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11R integer lane1 packet evidence must bind exactly",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11r_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__("lane1_local_memory_source_checked", False),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 31),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
            "a3_oracle": lambda summary: summary[
                "scope"
            ].__setitem__("a3_oracle_state", "VALID"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(
                    POLICY.read_text(encoding="utf-8")
                )
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"]
                    == "v11r_int_lane1_packet"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11R integer lane1 packet summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11r_mutation_stage_and_unit_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11r_int_lane1_packet"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "ex1-same-edge-claim-index-only"
        )
        mutation["expected_stage"] = "alu-down-packet-pid"
        mutation["unit_ids"] = ["integer-ex1-packed-alias"]
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11R mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11r_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11r_int_lane1_packet"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/pipeline/PipeStageReg.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11s_closure_requires_exact_muldiv_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11s_muldiv_producer"
        )
        closure["unit_ids"].append("clmul-producer")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11S MulDiv evidence must bind only muldiv-producer",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11s_summary_contract_is_fail_closed(self) -> None:
        mutations = {
            "oracle": lambda summary: summary[
                "independent_oracle"
            ].__setitem__(
                "wrong_generation_authorization_rejected", False
            ),
            "profile_count": lambda summary: summary[
                "counts"
            ].__setitem__("profiles_total", 21),
            "a3_original": lambda summary: summary[
                "scope"
            ].__setitem__("a3_original_status", "PASS"),
            "production_delta": lambda summary: summary[
                "scope"
            ].__setitem__("production_rtl_change", True),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                policy = json.loads(
                    POLICY.read_text(encoding="utf-8")
                )
                closure = next(
                    item
                    for item in policy["evidence_sets"]
                    if item["binding_kind"] == "v11s_muldiv_producer"
                )
                summary = json.loads(
                    (ROOT / closure["summary"]).read_text(
                        encoding="utf-8"
                    )
                )
                mutate(summary)
                summary_path = self.write_policy(summary)
                closure["summary"] = (
                    summary_path.relative_to(ROOT).as_posix()
                )
                with self.assertRaisesRegex(
                    COVERAGE.CoverageError,
                    "V11S MulDiv producer summary is not complete",
                ):
                    COVERAGE.build_ledger(
                        ROOT,
                        CENSUS,
                        GRAPH,
                        self.write_policy(policy),
                    )

    def test_v11s_mutation_stage_and_unit_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11s_muldiv_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "completion-bypasses-exact-open"
        )
        mutation["expected_stage"] = "terminal-authorization"
        mutation["unit_ids"] = ["clmul-producer"]
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11S mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11s_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11s_muldiv_producer"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/execute/OooMulDivUnit.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11s_generated_overlay_receipt_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11s_muldiv_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["production"]["overlay_injection_receipts"][0][
            "anchor_count"
        ] = 2
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "generated focused testbench overlay is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_closure_requires_exact_clmul_unit_set(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        closure["unit_ids"].append("muldiv-producer")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11T CLMUL evidence must bind only clmul-producer",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_summary_contract_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["independent_oracle"][
            "wrong_generation_authorization_rejected"
        ] = False
        summary_path = self.write_policy(summary)
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11T CLMUL producer summary is not complete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_compact_cleanup_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        source_summary = ROOT / closure["summary"]
        summary = json.loads(source_summary.read_text(encoding="utf-8"))
        summary["artifact_cleanup"]["removed_count"] = 35
        summary_path = self.write_v11t_summary_bundle(
            summary, source_summary
        )
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11T compact artifact cleanup is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_cleanup_artifact_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        closure["artifact_cleanup"] = closure["summary"]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11T cleanup artifact binding is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_mutation_stage_and_unit_binding_is_fail_closed(
        self,
    ) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        source_summary = ROOT / closure["summary"]
        summary = json.loads(source_summary.read_text(encoding="utf-8"))
        mutation = next(
            item
            for item in summary["variants"]
            if item["name"] == "completion-bypasses-exact-open"
        )
        mutation["expected_stage"] = "terminal-authorization"
        mutation["unit_ids"] = ["muldiv-producer"]
        summary_path = self.write_v11t_summary_bundle(
            summary, source_summary
        )
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11T mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/execute/OooClmulUnit.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11t_generated_overlay_receipt_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11t_clmul_producer"
        )
        source_summary = ROOT / closure["summary"]
        summary = json.loads(source_summary.read_text(encoding="utf-8"))
        summary["production"]["overlay_injection_receipts"][0][
            "anchor_count"
        ] = 2
        summary_path = self.write_v11t_summary_bundle(
            summary, source_summary
        )
        closure["summary"] = summary_path.relative_to(ROOT).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "generated focused testbench overlay is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_closure_requires_exact_pending_system_unit(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        closure["unit_ids"].append("clmul-producer")
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U pending-system evidence must bind only",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_summary_contract_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["independent_oracle"]["csr_only_birth"] = False
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U pending-system producer summary is not complete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_mutation_mode_metadata_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["configuration"]["parent_mutations_assertion_mode"] = False
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U pending-system producer summary is not complete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_compact_cleanup_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["artifact_cleanup"]["removed_count"] = 65
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U compact artifact cleanup is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_generated_overlay_receipt_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["production"]["generated_testbench_overlays"][0][
            "receipts"
        ][0]["anchor_count"] = 2
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U generated testbench overlay is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_mutation_unit_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["variants"][0]["unit_ids"] = ["clmul-producer"]
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_compile_cleanup_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["profiles"][0]["compile_artifacts"][0]["sha256"] = (
            "0" * 64
        )
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "cleanup binding is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_compiler_closure_cannot_drop_rob(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        rob_path = "npc/rv64/vsrc/writeback/OooRob.v"
        target = next(
            compile_input
            for profile in summary["profiles"]
            for compile_input in profile["compile_inputs"].values()
            if any(
                dependency["path"] == rob_path
                for dependency in compile_input["dependencies"]
            )
        )
        target["dependencies"] = [
            dependency
            for dependency in target["dependencies"]
            if dependency["path"] != rob_path
        ]
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U module dependency closure failed",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_makefile_selection_digest_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["compile_input_closure"]["build_controls"][
            "npc/rv64/testbench/Makefile"
        ] = "0" * 64
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U compiler input closure header is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11u_actual_compiler_argv_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11u_pending_system_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        first_compile_input = next(
            iter(summary["profiles"][0]["compile_inputs"].values())
        )
        first_compile_input.pop("compiler_argv_file")
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11U compiler argv binding failed",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11v_mutation_unit_binding_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11v_fp_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["variants"][0]["unit_ids"] = ["fp-long-producer"]
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11V mutation receipt is invalid",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11v_compact_cleanup_is_fail_closed(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11v_fp_producer"
        )
        summary = json.loads(
            (ROOT / closure["summary"]).read_text(encoding="utf-8")
        )
        summary["artifact_cleanup"]["removed_count"] = 50
        closure["summary"] = self.write_policy(summary).relative_to(
            ROOT
        ).as_posix()
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "V11V compact artifact cleanup is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11v_selected_source_set_is_exact(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11v_fp_producer"
        )
        closure["current_selected_bindings"] = [
            binding
            for binding in closure["current_selected_bindings"]
            if binding["path"]
            != "npc/rv64/vsrc/execute/OooFpArithGate.v"
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "selected RTL/TB binding set is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_duplicate_closure_requires_all_product_instances(self) -> None:
        evidence = [
            {
                "id": "incomplete-duplicate-closure",
                "semantic_closure": True,
                "scope": "COMPLETE",
                "binding_state":
                    "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
                "gap_classifications": [],
                "instance_paths": ["NpcTop.u_bridge0"],
            }
        ]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "exact per-instance evidence"
        ):
            COVERAGE.unit_is_closed(
                evidence,
                ["NpcTop.u_bridge0", "NpcTop.u_bridge1"],
            )

    def test_missing_instance_path_is_rejected(self) -> None:
        graph = json.loads(GRAPH.read_text(encoding="utf-8"))
        graph["graph"]["holder_instances"] = graph["graph"][
            "holder_instances"
        ][:-1]
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            suffix=".json",
            dir=self.scratch_dir(),
            delete=False,
        ) as temporary:
            json.dump(graph, temporary)
            path = pathlib.Path(temporary.name)
        self.addCleanup(path.unlink, missing_ok=True)
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "17 unique"
        ):
            COVERAGE.build_ledger(ROOT, CENSUS, path, POLICY)


if __name__ == "__main__":
    unittest.main()
