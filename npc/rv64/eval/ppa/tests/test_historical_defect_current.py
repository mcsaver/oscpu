#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/historical_defect_current.py"


def load_tool():
    spec = importlib.util.spec_from_file_location(
        "historical_defect_current_tested",
        TOOL_PATH,
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class HistoricalDefectCurrentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()
        cls.receipt = cls.tool.load_json(ROOT, cls.tool.RECEIPT_PATH)
        cls.ledger = cls.tool.load_json(ROOT, cls.tool.LEDGER_PATH)
        cls.closed_ledger = copy.deepcopy(cls.ledger)
        cls.a3_checker_contract = cls.tool.validate_a3_checker_contract(ROOT)

    def test_closed_ledger_builds_exact_current_receipt(self) -> None:
        self.tool._cached_expected.cache_clear()
        self.assertEqual(self.tool.build_receipt(ROOT), self.receipt)
        self.assertEqual(
            self.tool.validate_current_contract(ROOT),
            self.receipt,
        )
        self.assertEqual(len(self.receipt["defect_ids"]), 6)
        self.assertEqual(set(self.receipt["inputs"]), set(self.tool.INPUT_PATHS))

    def test_current_config_identity_is_exact_and_live(self) -> None:
        self.assertEqual(
            set(self.receipt["config_identity"]),
            set(self.tool.CONFIG_PATHS),
        )
        for name, relative in self.tool.CONFIG_PATHS.items():
            record = self.receipt["config_identity"][name]
            self.assertEqual(record["path"], relative.as_posix())
            self.assertEqual(
                record["sha256"],
                self.tool.sha256_file(self.tool.safe_file(ROOT, relative)),
            )

    def test_receipt_design_id_drift_is_rejected(self) -> None:
        drifted = copy.deepcopy(self.receipt)
        drifted["design_id"] = "sha256:" + "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_receipt_payload(drifted, self.receipt)

    def test_a3_original_fail_cannot_be_rewritten(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_A3_PATH)
        historical["source_run"]["original_status"] = "PASS rc=0"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_a3(
                ROOT,
                historical,
                self.a3_checker_contract,
                self.tool.validate_layered_system_current(
                    ROOT,
                    self.tool.load_json(
                        ROOT, self.tool.LAYERED_SYSTEM_CURRENT_PATH
                    ),
                    self.receipt["design_id"],
                ),
            )

    def test_exit_compile_success_mutation_must_be_rejected(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        payload["mutations"][0]["rejected"] = False
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_current(
                ROOT,
                payload,
                self.receipt["design_id"],
            )

    def test_queue_head_current_mutation_set_is_exact(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        current["mutations"].pop("typed-apply-c2-replay")
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_younger_store(
                ROOT,
                historical,
                current,
                self.receipt["design_id"],
            )

    def test_queue_head_negative_return_code_cannot_be_hidden_by_aggregate(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        row = next(
            item for item in current["profiles"]
            if item["name"] == "mutation-typed-apply-c2-replay"
        )
        row["make_returncode"] = 0
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_younger_store(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_queue_head_negative_marker_spoof_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        row = next(
            item for item in current["profiles"]
            if item["name"] == "mutation-rob-queue-head-selection-disabled"
        )
        row["markers"] = {"arbitrary marker": 1}
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_younger_store(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_queue_head_positive_counts_are_derived_from_retained_log(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        original = self.tool.validate_retained_log

        def spoofed_log(root, record, label, **kwargs):
            text = original(root, record, label, **kwargs)
            if label == "current QH assert result log":
                return text.replace("[V10G-QH-CSR-KILL]", "[SPOOFED-QH-KILL]", 1)
            return text

        with mock.patch.object(
            self.tool,
            "validate_retained_log",
            side_effect=spoofed_log,
        ):
            with self.assertRaises(self.tool.HistoricalCurrentError):
                self.tool.validate_qh_younger_store(
                    ROOT, historical, current, self.receipt["design_id"]
                )

    def test_removed_compile_rc_must_match_cleanup_manifest(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        compile_record = next(
            item for item in current["cleanup"]["artifacts"]
            if item["kind"] == "compiler-return-code"
        )
        compile_record["sha256"] = "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_younger_store(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_stop_hold_event_deduplication_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_STOP_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_SYSTEM_PATH)
        historical["coverage"]["event_deduplication"] = True
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_stop_hold(
                ROOT,
                historical,
                current,
                self.receipt["design_id"],
            )

    def test_stop_hold_negative_expectation_spoof_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_STOP_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_SYSTEM_PATH)
        row = next(
            item for item in current["profiles"]
            if item["name"] == "retain-stop-after-drain-terminal"
        )
        row["expect_pass"] = True
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_stop_hold(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_current_build_control_hash_drift_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_QH_PATH)
        current = self.tool.load_json(ROOT, self.tool.V14E_QH_PATH)
        current["build_controls"]["npc/rv64/testbench/Makefile"]["sha256"] = "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_qh_younger_store(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_v8l_current_mutation_shortfall_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_V8L_PATH)
        current = self.tool.load_json(ROOT, self.tool.HOLDER_CURRENT_PATH)
        current["counts"]["mutations_rejected"] = 8
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v8l(
                ROOT,
                historical,
                current,
                self.receipt["design_id"],
            )

    def test_v8l_single_mutation_survivor_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_V8L_PATH)
        current = self.tool.load_json(ROOT, self.tool.HOLDER_CURRENT_PATH)
        current["compile_success_mutations"][0]["result"] = "SURVIVED"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v8l(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_v8l_retained_log_hash_drift_is_rejected(self) -> None:
        historical = self.tool.load_json(ROOT, self.tool.HISTORICAL_V8L_PATH)
        current = self.tool.load_json(ROOT, self.tool.HOLDER_CURRENT_PATH)
        current["compile_success_mutations"][0]["log"]["sha256"] = "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v8l(
                ROOT, historical, current, self.receipt["design_id"]
            )

    def test_v8l_mutation_return_code_spoof_is_rejected(self) -> None:
        current = self.tool.load_json(ROOT, self.tool.HOLDER_CURRENT_PATH)
        current["compile_success_mutations"][0]["make_return_code"] = 0
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v8l(
                ROOT,
                self.tool.load_json(ROOT, self.tool.HISTORICAL_V8L_PATH),
                current,
                self.receipt["design_id"],
            )

    def test_v9p_immutable_lane_nonclaim_cannot_be_rewritten(self) -> None:
        historical = self.tool.load_json(
            ROOT, self.tool.HISTORICAL_V9P_ROOT_CAUSE_PATH
        )
        historical["root_cause"]["frozen_instance_lane_pair"] = [2, 10]
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v9p_terminal_duplicate(
                ROOT,
                historical,
                self.tool.load_json(ROOT, self.tool.V9R_CURRENT_PATH),
                self.tool.load_json(ROOT, self.tool.LAYERED_SYSTEM_CURRENT_PATH),
                self.tool.load_json(ROOT, self.tool.V15G_INDEPENDENT_REVIEW_PATH),
                self.receipt["design_id"],
            )

    def test_v9p_compile_success_mutation_survivor_is_rejected(self) -> None:
        current = self.tool.load_json(ROOT, self.tool.V9R_CURRENT_PATH)
        current["compile_success_rtl_variants"][0]["result"] = "SURVIVED"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v9p_terminal_duplicate(
                ROOT,
                self.tool.load_json(
                    ROOT, self.tool.HISTORICAL_V9P_ROOT_CAUSE_PATH
                ),
                current,
                self.tool.load_json(ROOT, self.tool.LAYERED_SYSTEM_CURRENT_PATH),
                self.tool.load_json(ROOT, self.tool.V15G_INDEPENDENT_REVIEW_PATH),
                self.receipt["design_id"],
            )

    def test_v9p_optional_ubuntu_cannot_be_claimed_by_default_signoff(self) -> None:
        layered = self.tool.load_json(ROOT, self.tool.LAYERED_SYSTEM_CURRENT_PATH)
        layered["optional_full_ubuntu"]["status"] = "PASS"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v9p_terminal_duplicate(
                ROOT,
                self.tool.load_json(
                    ROOT, self.tool.HISTORICAL_V9P_ROOT_CAUSE_PATH
                ),
                self.tool.load_json(ROOT, self.tool.V9R_CURRENT_PATH),
                layered,
                self.tool.load_json(ROOT, self.tool.V15G_INDEPENDENT_REVIEW_PATH),
                self.receipt["design_id"],
            )

    def test_v9p_independent_review_must_preserve_unknown_frozen_lane(self) -> None:
        review = self.tool.load_json(ROOT, self.tool.V15G_INDEPENDENT_REVIEW_PATH)
        review["conclusions"]["frozen_lane_claim"] = "BANK0_PROVEN"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_v9p_terminal_duplicate(
                ROOT,
                self.tool.load_json(
                    ROOT, self.tool.HISTORICAL_V9P_ROOT_CAUSE_PATH
                ),
                self.tool.load_json(ROOT, self.tool.V9R_CURRENT_PATH),
                self.tool.load_json(ROOT, self.tool.LAYERED_SYSTEM_CURRENT_PATH),
                review,
                self.receipt["design_id"],
            )

    def test_exit_rejection_marker_spoof_is_rejected(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        payload["mutations"][0]["expected_rejection_marker"] = "arbitrary marker"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_current(
                ROOT, payload, self.receipt["design_id"]
            )

    def test_exit_mutated_source_hash_spoof_is_rejected(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        first = payload["mutations"][0]["mutated_sources"]
        first[next(iter(first))] = "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_current(
                ROOT, payload, self.receipt["design_id"]
            )

    def test_exit_source_binding_set_and_role_are_exact(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        payload["source_bindings"][-1] = copy.deepcopy(payload["source_bindings"][0])
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_current(
                ROOT, payload, self.receipt["design_id"]
            )

    def test_exit_focused_plusarg_drift_is_rejected(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        payload["configuration"]["plusarg"] = "+UNRELATED_MODE"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_current(
                ROOT, payload, self.receipt["design_id"]
            )

    def test_exit_compile_invocation_rejects_unbound_compiler(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        runner = self.tool.load_module(
            self.tool.safe_file(ROOT, self.tool.EXIT_RUNNER_PATH),
            "historical_exit_invocation_fake_compiler_test",
        )
        row = payload["baselines"][0]
        text = (ROOT / row["compile_log"]["path"]).read_text(encoding="utf-8")
        text = text.replace(payload["configuration"]["iverilog"]["path"],
                            "/tmp/fake-iverilog", 1)
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_compile_log(
                text,
                runner=runner,
                configuration=payload["configuration"],
                assertions=True,
                label="baseline-assert",
            )

    def test_exit_compile_invocation_rejects_extra_source(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        runner = self.tool.load_module(
            self.tool.safe_file(ROOT, self.tool.EXIT_RUNNER_PATH),
            "historical_exit_invocation_extra_source_test",
        )
        row = payload["baselines"][0]
        text = (ROOT / row["compile_log"]["path"]).read_text(encoding="utf-8")
        text = text.replace(str(runner.TB), f"/tmp/extra.v {runner.TB}", 1)
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_compile_log(
                text,
                runner=runner,
                configuration=payload["configuration"],
                assertions=True,
                label="baseline-assert",
            )

    def test_exit_compile_invocation_rejects_cross_scratch_mutation(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        runner = self.tool.load_module(
            self.tool.safe_file(ROOT, self.tool.EXIT_RUNNER_PATH),
            "historical_exit_invocation_cross_scratch_test",
        )
        row = payload["mutations"][0]
        text = (ROOT / row["compile_log"]["path"]).read_text(encoding="utf-8")
        target = next(iter(row["mutated_sources"]))
        target_name = pathlib.PurePosixPath(target).name
        command_line, remainder = text.split("\n", 1)
        original = next(
            token for token in command_line.split()
            if token.endswith(f"/{row['name']}/{target_name}")
        )
        text = command_line.replace(
            original,
            f"/tmp/unbound/{row['name']}/{target_name}",
            1,
        ) + "\n" + remainder
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_compile_log(
                text,
                runner=runner,
                configuration=payload["configuration"],
                assertions=row["assertions"],
                label=f"mutation-{row['name']}",
                mutation_name=row["name"],
                mutated_sources=row["mutated_sources"],
            )

    def test_exit_simulation_invocation_requires_focused_plusarg(self) -> None:
        payload = self.tool.load_json(ROOT, self.tool.EXIT_CURRENT_PATH)
        runner = self.tool.load_module(
            self.tool.safe_file(ROOT, self.tool.EXIT_RUNNER_PATH),
            "historical_exit_invocation_plusarg_test",
        )
        row = payload["baselines"][0]
        compile_text = (ROOT / row["compile_log"]["path"]).read_text(
            encoding="utf-8"
        )
        image_path = self.tool.validate_exit_compile_log(
            compile_text,
            runner=runner,
            configuration=payload["configuration"],
            assertions=True,
            label="baseline-assert",
        )
        simulation_text = (ROOT / row["simulation_log"]["path"]).read_text(
            encoding="utf-8"
        ).replace("+V10D_ONLY", "+UNRELATED_MODE", 1)
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_exit_simulation_log(
                simulation_text,
                runner=runner,
                configuration=payload["configuration"],
                image_path=image_path,
                label="exit assert",
            )

    def test_ledger_receipt_pointer_drift_is_rejected(self) -> None:
        ledger = copy.deepcopy(self.closed_ledger)
        ledger["entries"][0]["current_evidence"][0]["sha256"] = "0" * 64
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_ledger_payload(ROOT, ledger, self.receipt)

    def test_ledger_requires_current_design_basis_for_every_defect(self) -> None:
        ledger = copy.deepcopy(self.closed_ledger)
        ledger["entries"][0]["depth_basis"] = ["historical evidence only"]
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_ledger_payload(ROOT, ledger, self.receipt)

    def test_architecture_or_ppa_promotion_overclaim_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["promotion"]["whole_architecture"] = "GREEN"
        with self.assertRaises(self.tool.HistoricalCurrentError):
            self.tool.validate_ledger_payload(
                ROOT, self.closed_ledger, receipt
            )

    def test_retained_six_defect_receipt_matches_closed_ledger_view(self) -> None:
        self.tool.validate_ledger_payload(
            ROOT, self.closed_ledger, self.receipt
        )

    def test_reuse_contract_only_authorizes_targeted_exit_replay(self) -> None:
        contract = self.receipt["evidence_reuse_contract"]
        self.assertFalse(contract["full_system_rerun"])
        self.assertEqual(
            contract["replay_state"],
            "ONLY_TARGETED_HISTORICAL_RTL_AND_ORACLE_REPLAYS",
        )
        self.assertEqual(
            contract["artifact_state"],
            "TOP_LEVEL_RECEIPTS_PATH_SHA256_SIZE_BOUND_AND_RETAINED_LOGS_SHA256_BOUND",
        )
        self.assertEqual(
            contract["shared_system_dependency"],
            "LAYERED_SIGNOFF_AND_CURRENT_CHECKER_CONTRACT_REQUIRED",
        )
        self.assertEqual(
            contract["compile_sidefile_state"],
            "REMOVED_ZERO_RC_HASH_RECEIPT_CROSSCHECKED_WITH_RETAINED_TB_LOG",
        )
        self.assertEqual(
            self.receipt["metrics"]["HIST-EXIT-ACTIVE-MEM-EARLY-TERMINAL"]
            ["intermediate_products_retained"],
            0,
        )


if __name__ == "__main__":
    unittest.main()
