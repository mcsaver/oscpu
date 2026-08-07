from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/system_recertification_current.py"
RECEIPT = ROOT / "npc/rv64/eval/ppa/evidence/system-recertification-current.json"
SPEC = importlib.util.spec_from_file_location("system_recertification_current", TOOL_PATH)
assert SPEC and SPEC.loader
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class CurrentWorkspaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.receipt = TOOL.build_core_receipt(ROOT)

    def validate_mutation(self, payload: dict) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "receipt.json"
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaises(TOOL.RecertificationError):
                TOOL.validate_receipt(ROOT, path)

    def test_current_default_layered_signoff_is_bounded_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "receipt.json"
            path.write_text(json.dumps(self.receipt), encoding="utf-8")
            result = TOOL.validate_receipt(ROOT, path)
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["design_id"], self.receipt["design_id"])
        self.assertEqual(
            result["default_signoff_conjunction"], TOOL.DEFAULT_CONJUNCTION
        )
        self.assertEqual((result["l0_passed"], result["l0_required"]), (113, 113))
        self.assertEqual(
            (result["l1_official_passed"], result["l1_official_required"]),
            (177, 177),
        )
        self.assertEqual(
            (result["l1_am_passed"], result["l1_am_required"]), (61, 61)
        )
        self.assertEqual(result["l2_case"], "all")
        self.assertEqual(result["l3_case"], "all")
        self.assertEqual(result["rtl_assertion_failures"], 0)
        self.assertEqual(result["optional_ubuntu"], "NOT_RUN_OPTIONAL")
        self.assertEqual(result["whole_architecture"], "RED")
        self.assertEqual(result["ppa"], "UNPROMOTED")

    def test_canonical_receipt_is_current(self) -> None:
        result = TOOL.validate_receipt(ROOT, RECEIPT)
        self.assertEqual(result["system_recertification"], "PASS_CURRENT_CONFIG")

    def test_rejects_design_identity_drift(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["design_id"] = "sha256:" + "0" * 64
        self.validate_mutation(candidate)

    def test_rejects_default_conjunction_drift(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["default_signoff_conjunction"].append("UBUNTU_2204")
        self.validate_mutation(candidate)

    def test_rejects_l0_count_drift(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layers"]["L0_DIRECTED_RTL"]["tests"]["passed"] = 112
        self.validate_mutation(candidate)

    def test_rejects_l1_count_drift(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layers"]["L1_FULL_CORE_DIFFTEST"]["official_passed"] = 176
        self.validate_mutation(candidate)

    def test_rejects_directed_l2_case_as_full_layer(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layers"]["L2_MINI_SYSTEM"]["case"] = "sv39"
        self.validate_mutation(candidate)

    def test_rejects_l3_failure(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layers"]["L3_LIGHTWEIGHT_LINUX"]["status"] = "FAIL"
        self.validate_mutation(candidate)

    def test_rejects_assertion_overclaim(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layers"]["L3_LIGHTWEIGHT_LINUX"]["rtl_assertion_failures"] = 1
        self.validate_mutation(candidate)

    def test_optional_ubuntu_cannot_block_default_signoff(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["optional_full_ubuntu"]["blocks_default_signoff"] = True
        self.validate_mutation(candidate)

    def test_rejects_layered_receipt_hash_drift(self) -> None:
        candidate = copy.deepcopy(self.receipt)
        candidate["layered_signoff_receipt"]["sha256"] = "0" * 64
        self.validate_mutation(candidate)

    def test_rejects_architecture_or_ppa_overpromotion(self) -> None:
        for key, value in (("whole_architecture", "GREEN"), ("ppa", "PROMOTED")):
            with self.subTest(key=key):
                candidate = copy.deepcopy(self.receipt)
                candidate["promotion"][key] = value
                self.validate_mutation(candidate)


if __name__ == "__main__":
    unittest.main()
