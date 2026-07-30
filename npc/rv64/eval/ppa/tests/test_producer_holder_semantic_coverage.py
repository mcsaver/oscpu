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
GRAPH = (
    ROOT
    / ".github/task-runs/2026-07-30-rv64-v11h-"
    "load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/"
    "holder-instance-graph.json"
)
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
        self.assertEqual(counts["semantic_units"], 44)
        self.assertEqual(counts["holder_instances"], 17)
        self.assertEqual(counts["unit_instance_bindings"], 50)
        self.assertEqual(counts["units_semantic_pass"], 11)
        self.assertEqual(counts["units_semantic_gap"], 33)
        self.assertEqual(counts["ledger_only_units"], 0)

    def test_every_census_unit_and_instance_is_auditable(self) -> None:
        unit_ids = [unit["id"] for unit in self.ledger["units"]]
        self.assertEqual(len(unit_ids), len(set(unit_ids)))
        self.assertEqual(len(unit_ids), 44)
        graph = json.loads(GRAPH.read_text(encoding="utf-8"))
        expected_paths = {
            item["path"] for item in graph["graph"]["holder_instances"]
        }
        observed_paths = {
            item["instance_path"]
            for item in self.ledger["unit_instance_bindings"]
        }
        self.assertEqual(observed_paths, expected_paths)

    def test_duplicate_product_instances_remain_distinguished_gaps(self) -> None:
        self.assertEqual(
            self.ledger["duplicate_instance_modules"],
            ["OooMemAxiBridge", "OooMemInflightQueue"],
        )
        duplicate_rows = [
            row
            for row in self.ledger["unit_instance_bindings"]
            if row["module"] in self.ledger["duplicate_instance_modules"]
        ]
        self.assertTrue(duplicate_rows)
        self.assertTrue(
            all(
                "PRODUCT_INSTANCE_DISTINGUISHABILITY_GAP"
                in row["gap_classifications"]
                for row in duplicate_rows
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
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
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
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11c-memory-tracker-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11d-memory-tracker-cursor-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11e-rob-slot-generation-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11f-int-iq-producer-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11g-store-queue-holder-current-closure"],
            "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
        )
        self.assertEqual(
            states["v11h-load-queue-producer-current-closure"],
            "CURRENT_FULL_RTL_BOUND",
        )

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
        self.assertEqual(len(selected), 6)
        for item in selected:
            self.assertEqual(
                item["binding_state"],
                "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
            )
            detail = item["detail"]
            self.assertNotEqual(
                detail["evidence_design_id"],
                detail["current_design_id"],
            )
            self.assertTrue(detail["selected_bindings"])
            self.assertTrue(
                all(
                    binding["matches_live"]
                    for binding in detail["selected_bindings"]
                )
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
        self.assertEqual(replay["original_attempt"], 4)
        self.assertTrue(replay["original_fail_preserved"])
        self.assertFalse(replay["rtl_simulation_reexecuted"])
        self.assertEqual(replay["frozen_positive_profiles"], 4)
        self.assertEqual(
            replay["frozen_raw_q_knownness_assertion_probes"],
            1,
        )
        self.assertEqual(replay["frozen_mutation_simulations"], 62)
        self.assertTrue(
            replay["system_rerun_required_before_system_promotion"]
        )
        self.assertFalse(replay["system_rerun_executed"])

    def test_only_bounded_v11b_through_v11h_units_are_closed(self) -> None:
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
            },
        )

    def test_no_candidate_is_not_reported_as_ledger_only(self) -> None:
        no_candidate = [
            unit
            for unit in self.ledger["units"]
            if not unit["candidate_evidence"]
        ]
        self.assertEqual(
            len(no_candidate),
            self.ledger["counts"]["units_without_candidate_evidence"],
        )
        self.assertTrue(no_candidate)
        self.assertTrue(
            all(
                "NO_DYNAMIC_EVIDENCE_CANDIDATE"
                in unit["gap_classifications"]
                for unit in no_candidate
            )
        )


class NegativeContractTests(unittest.TestCase):
    def write_policy(self, payload: dict) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            suffix=".json",
            dir=ROOT,
            delete=False,
        )
        self.addCleanup(pathlib.Path(temporary.name).unlink, missing_ok=True)
        with temporary:
            json.dump(payload, temporary)
        return pathlib.Path(temporary.name)

    def test_unknown_unit_in_policy_is_rejected(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy["evidence_sets"][0]["unit_ids"].append("not-a-census-unit")
        with self.assertRaisesRegex(COVERAGE.CoverageError, "invalid unit IDs"):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_policy_cannot_predeclare_semantic_completion(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        policy["semantic_complete"] = True
        with self.assertRaisesRegex(
            COVERAGE.CoverageError, "cannot claim semantic completion"
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

    def test_v11h_attempt3_historical_replay_cannot_close_current_design(
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
            "checker-replay receipt is incomplete",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
            )

    def test_v11h_current_closure_cannot_omit_attempt4_replay(self) -> None:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
        closure = next(
            item
            for item in policy["evidence_sets"]
            if item["binding_kind"] == "v11h_load_queue_producer"
        )
        del closure["checker_replay_receipt"]
        with self.assertRaisesRegex(
            COVERAGE.CoverageError,
            "requires the attempt-4 checker replay",
        ):
            COVERAGE.build_ledger(
                ROOT, CENSUS, GRAPH, self.write_policy(policy)
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
            dir=ROOT,
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
