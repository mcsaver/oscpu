#!/usr/bin/env python3
"""Directed positive and negative tests for the current debt receipt."""

from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/architecture_debt_current.py"
SPEC = importlib.util.spec_from_file_location("architecture_debt_current_tested", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class ArchitectureDebtCurrentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.expected = TOOL.build_receipt(ROOT)
        cls.receipt = json.loads((ROOT / TOOL.RECEIPT_PATH).read_text(encoding="utf-8"))
        cls.ledger = json.loads((ROOT / TOOL.LEDGER_PATH).read_text(encoding="utf-8"))
        cls.v14c = json.loads((ROOT / TOOL.SOURCE_PATHS["v14c_p0"]).read_text(encoding="utf-8"))
        cls.v14d = json.loads((ROOT / TOOL.SOURCE_PATHS["v14d_p1_direct"]).read_text(encoding="utf-8"))
        cls.holder = json.loads((ROOT / TOOL.SOURCE_PATHS["v14h_holder"]).read_text(encoding="utf-8"))
        cls.delta = json.loads((ROOT / TOOL.SOURCE_PATHS["delta_rebind"]).read_text(encoding="utf-8"))

    def test_current_receipt_and_ledger_pass(self) -> None:
        TOOL.validate_receipt_payload(self.receipt, self.expected)
        TOOL.validate_ledger_payload(ROOT, self.ledger, self.receipt)

    def test_design_id_drift_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["design_id"] = "sha256:" + "0" * 64
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_receipt_payload(receipt, self.expected)

    def test_debt_support_drop_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["support"]["SERIALIZE-G1"] = ["v14e_serialize_fast"]
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_receipt_payload(receipt, self.expected)

    def test_whole_architecture_overclaim_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["promotion"]["whole_architecture"] = "GREEN"
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_receipt_payload(receipt, self.expected)

    def test_ppa_overclaim_is_rejected(self) -> None:
        receipt = copy.deepcopy(self.receipt)
        receipt["promotion"]["ppa"] = "PROMOTED"
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_receipt_payload(receipt, self.expected)

    def test_closed_entry_status_drift_is_rejected(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        next(item for item in ledger["entries"] if item["id"] == "F0-G1")["status"] = "STALE_EVIDENCE"
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_ledger_payload(ROOT, ledger, self.receipt)

    def test_receipt_pointer_drift_is_rejected(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        entry = next(item for item in ledger["entries"] if item["id"] == "CONTROL-EVENT-G1")
        entry["evidence"][0]["sha256"] = "0" * 64
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_ledger_payload(ROOT, ledger, self.receipt)

    def test_exclusion_hash_drift_is_rejected(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        entry = next(item for item in ledger["entries"] if item["id"] == "WFI-G1")
        entry["scope_contract"]["sha256"] = "0" * 64
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_ledger_payload(ROOT, ledger, self.receipt)

    def test_serialize_requires_fast_and_system_receipts(self) -> None:
        self.assertEqual(
            self.receipt["support"]["SERIALIZE-G1"],
            ["v14e_serialize_fast", "delta_rebind", "layered_system"],
        )
        self.assertEqual(
            self.receipt["prerequisites"]["system_recertification"]
            ["default_signoff_conjunction"],
            [
                "L0_DIRECTED_RTL",
                "L1_FULL_CORE_DIFFTEST",
                "L2_MINI_SYSTEM",
                "L3_LIGHTWEIGHT_LINUX",
            ],
        )

    def test_normative_cohort_design_id_drift_is_rejected(self) -> None:
        text = (ROOT / TOOL.COHORT_SCOPE_PATH).read_text(encoding="utf-8")
        stale = text.replace(self.receipt["design_id"], "sha256:" + "0" * 64, 1)
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_cohort_scope_text(stale, self.receipt["design_id"])

    def test_v14c_status_history_rewrite_is_rejected(self) -> None:
        payload = copy.deepcopy(self.v14c)
        payload["status_history"]["historical_status_rewritten"] = True
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_v14c(
                ROOT, payload, self.delta["baseline_design_id"],
                self.delta["rtl_delta"]["baseline_file_count"],
            )

    def test_v14d_status_history_rewrite_is_rejected(self) -> None:
        payload = copy.deepcopy(self.v14d)
        payload["historical_status_rewritten"] = True
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_v14d(
                ROOT, payload, self.delta["baseline_design_id"],
                self.delta["rtl_delta"]["baseline_file_count"],
            )

    def test_historical_receipt_cannot_be_relabelled_as_current(self) -> None:
        payload = copy.deepcopy(self.v14c)
        payload["current_design_id"] = self.receipt["design_id"]
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_v14c(
                ROOT, payload, self.delta["baseline_design_id"],
                self.delta["rtl_delta"]["baseline_file_count"],
            )

    def test_every_closed_debt_binds_delta_replay(self) -> None:
        for debt_id in TOOL.CLOSED_DEBTS:
            with self.subTest(debt_id=debt_id):
                self.assertIn("delta_rebind", self.receipt["support"][debt_id])

    def test_legacy_v14e_failed_predecessor_rewrite_is_rejected(self) -> None:
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_system_history("PASS rc=0", "PASS\n")

    def test_holder_a3_history_drop_is_rejected(self) -> None:
        payload = copy.deepcopy(self.holder)
        for evidence_set in payload["evidence_sets"]:
            detail = evidence_set.get("detail", {})
            if "a3_original_status" in detail:
                del detail["a3_original_status"]
                break
        with self.assertRaises(TOOL.DebtCurrentError):
            TOOL.validate_holder(ROOT, payload, self.receipt["design_id"])

    def test_receipt_binds_all_executable_validators(self) -> None:
        self.assertEqual(
            set(self.receipt["inputs"]),
            {
                "architecture_binding_tool",
                "cohort_scope",
                "delta_rebind",
                "delta_rebind_tool",
                "exclusion_a-coherence-g1",
                "exclusion_debug-trigger-g1",
                "exclusion_sfence-sinval-g1",
                "exclusion_wfi-g1",
                "global_holder_receipt",
                "global_holder_tool",
                "legacy_v14e_a1_status",
                "legacy_v14e_a2_status",
                "receipt_schema",
                "receipt_tool",
                "system_tool",
                "v14c_p0",
                "v14d_p1_direct",
                "v14e_f0",
                "v14e_fence",
                "v14e_serialize_fast",
                "v14e_vectored",
                "v14h_holder",
                "layered_system",
            },
        )


if __name__ == "__main__":
    unittest.main()
