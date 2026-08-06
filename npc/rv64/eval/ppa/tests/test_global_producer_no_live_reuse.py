#!/usr/bin/env python3
"""Fail-closed tests for the bounded RV64 global ProducerId receipt."""

from __future__ import annotations

import copy
import gzip
import importlib.util
import json
import pathlib
import tempfile
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = (
    ROOT / "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py"
)
SPEC = importlib.util.spec_from_file_location(
    "global_producer_no_live_reuse", TOOL_PATH
)
assert SPEC and SPEC.loader
GLOBAL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = GLOBAL
SPEC.loader.exec_module(GLOBAL)

LEDGER_PATH = ROOT / GLOBAL.DEFAULT_LEDGER
RECEIPT_PATH = ROOT / GLOBAL.DEFAULT_RECEIPT
YOSYS_PATH = ROOT / GLOBAL.DEFAULT_YOSYS_JSON


class CurrentReceiptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.ledger = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
        cls.receipt = json.loads(RECEIPT_PATH.read_text(encoding="utf-8"))
        cls.design_id = GLOBAL.current_design_id(ROOT)

    def validate(
        self,
        receipt: dict | None = None,
        ledger: dict | None = None,
    ) -> dict:
        return GLOBAL.validate_receipt_data(
            ROOT,
            self.receipt if receipt is None else receipt,
            self.ledger if ledger is None else ledger,
            self.design_id,
        )

    def test_current_receipt_promotes_only_bounded_global_claim(self) -> None:
        result = self.validate()
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["semantic_units"], 46)
        self.assertEqual(result["unit_instance_bindings"], 52)
        self.assertEqual(result["v14g_baselines"], 4)
        self.assertEqual(
            result["v14g_compile_success_mutations_rejected"], 22
        )
        self.assertEqual(
            result["optional_lane1_product_configuration"],
            "PRODUCT_INACTIVE_CONSTANT_LOW",
        )
        self.assertEqual(result["global_no_live_reuse"], "GREEN")
        self.assertEqual(result["whole_architecture"], "RED")
        self.assertEqual(result["system_recertification"], "REQUIRED")
        self.assertEqual(result["ppa"], "UNPROMOTED")

    def test_compact_receipt_does_not_require_origin_summary_directory(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["v14g_dynamic_fence"]["origin"]["result_dir"] = (
            ".github/runtime-artifacts/retired-v14g-payload"
        )
        receipt["v14g_dynamic_fence"]["origin"]["artifacts"] = []
        self.assertEqual(self.validate(receipt)["status"], "PASS")

    def test_whole_architecture_overclaim_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["promotion"]["whole_architecture"] = "GREEN"
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "promotion boundary drifted"
        ):
            self.validate(receipt)

    def test_system_recertification_overclaim_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["promotion"]["system_recertification"] = "PASS"
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "promotion boundary drifted"
        ):
            self.validate(receipt)

    def test_missing_v14g_baseline_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["v14g_dynamic_fence"]["baselines"].pop()
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "baseline matrix is incomplete"
        ):
            self.validate(receipt)

    def test_v14g_mutation_stage_drift_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        mutation = receipt["v14g_dynamic_fence"]["mutations"][0]
        mutation["expected_stage"] = "wrong-owner-stage"
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "mutation result drifted"
        ):
            self.validate(receipt)

    def test_v14g_observed_oracle_stage_drift_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        mutation = receipt["v14g_dynamic_fence"]["mutations"][0]
        mutation["oracle_stages"] = ["wrong-observed-owner-stage"]
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "mutation result drifted"
        ):
            self.validate(receipt)

    def test_v14g_compact_log_binding_is_fail_closed(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        baseline = receipt["v14g_dynamic_fence"]["baselines"][0]
        baseline["log"]["sha256"] = "not-a-sha256"
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "compact log binding drifted"
        ):
            self.validate(receipt)

    def test_missing_v14g_compact_log_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        baseline = receipt["v14g_dynamic_fence"]["baselines"][0]
        baseline["log"]["origin_path"] = (
            ".github/runtime-artifacts/missing-v14g-evidence.log"
        )
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "compact log is missing"
        ):
            self.validate(receipt)

    def test_tampered_v14g_compact_log_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        baseline = receipt["v14g_dynamic_fence"]["baselines"][0]
        runtime_root = ROOT / ".github/runtime-artifacts"
        with tempfile.TemporaryDirectory(
            prefix="v14g-log-negative-", dir=runtime_root
        ) as temporary:
            log_path = pathlib.Path(temporary) / "tampered.log"
            log_path.write_text("tampered V14G transcript\n", encoding="utf-8")
            baseline["log"]["origin_path"] = log_path.relative_to(ROOT).as_posix()
            baseline["log"]["size_bytes"] = log_path.stat().st_size
            with self.assertRaisesRegex(
                GLOBAL.ClosureError, "compact log digest drifted"
            ):
                self.validate(receipt)

    def test_repointed_v14g_compact_log_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        baselines = receipt["v14g_dynamic_fence"]["baselines"]
        baselines[0]["log"]["origin_path"] = baselines[1]["log"]["origin_path"]
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "compact log (size|digest) drifted"
        ):
            self.validate(receipt)

    def test_v14g_log_archive_copies_only_bound_transcript(self) -> None:
        baseline = self.receipt["v14g_dynamic_fence"]["baselines"][0]
        source = baseline["log"]
        runtime_root = ROOT / ".github/runtime-artifacts"
        with tempfile.TemporaryDirectory(
            prefix="v14g-log-archive-", dir=runtime_root
        ) as temporary:
            archive_dir = pathlib.Path(temporary) / "retained-logs"
            binding = GLOBAL.profile_log(
                ROOT,
                {
                    "log": source["origin_path"],
                    "log_sha256": source["sha256"],
                },
                archive_dir,
            )
            archived = ROOT / binding["origin_path"]
            self.assertTrue(archived.is_file())
            self.assertEqual(binding["sha256"], source["sha256"])
            self.assertEqual(binding["size_bytes"], source["size_bytes"])

    def test_current_v14g_source_drift_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        source = next(
            item
            for item in receipt["v14g_dynamic_fence"]["source_bindings"]
            if item["current_required"]
        )
        source["sha256"] = "0" * 64
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "current source binding drifted"
        ):
            self.validate(receipt)

    def test_current_simulator_identity_drift_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["v14g_dynamic_fence"]["tools"]["vvp"]["sha256"] = (
            "0" * 64
        )
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "simulator identity drifted"
        ):
            self.validate(receipt)

    def test_v11m_lane_pair_support_cannot_be_weakened(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        evidence = next(
            item
            for item in ledger["evidence_sets"]
            if item["id"]
            == "v11m-memory-reservation-holder-current-closure"
        )
        evidence["detail"]["pair_credit_and_turnover_atomicity_closed"] = (
            False
        )
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "pair_credit_and_turnover_atomicity_closed"
        ):
            self.validate(ledger=ledger)

    def test_v11m_lane7_support_cannot_be_weakened(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        evidence = next(
            item
            for item in ledger["evidence_sets"]
            if item["id"]
            == "v11m-memory-reservation-holder-current-closure"
        )
        evidence["detail"]["lane6_lane7_accepted_terminal_closed"] = False
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "lane6_lane7_accepted_terminal_closed"
        ):
            self.validate(ledger=ledger)

    def test_optional_lane1_constant_source_is_checked_from_yosys(self) -> None:
        with gzip.open(YOSYS_PATH, "rt", encoding="utf-8") as stream:
            payload = json.load(stream)
        branch_name = next(
            name
            for name in payload["modules"]
            if GLOBAL.module_matches(name, "OooBranchAppendDispatchGate")
        )
        payload["modules"][branch_name]["ports"][
            "dispatch1_optional_o"
        ]["bits"] = [1]
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "not elaborated constant zero"
        ):
            GLOBAL.optional_chain_from_yosys(payload)

    def test_optional_lane1_product_connection_cut_is_rejected(self) -> None:
        with gzip.open(YOSYS_PATH, "rt", encoding="utf-8") as stream:
            payload = json.load(stream)
        core_name = next(
            name
            for name in payload["modules"]
            if GLOBAL.module_matches(name, "OooCoreTopGlue")
        )
        payload["modules"][core_name]["cells"]["u_execute_backend"][
            "connections"
        ]["dispatch1_optional_w"] = [999999]
        with self.assertRaisesRegex(
            GLOBAL.ClosureError, "not point-to-point"
        ):
            GLOBAL.optional_chain_from_yosys(payload)


if __name__ == "__main__":
    unittest.main(verbosity=2)
