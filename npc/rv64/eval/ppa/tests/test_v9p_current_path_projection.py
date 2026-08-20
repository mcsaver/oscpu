#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/v9p_current_path_projection.py"


def load_tool():
    spec = importlib.util.spec_from_file_location(
        "v9p_current_path_projection_tested", TOOL_PATH
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class V9pCurrentPathProjectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()
        cls.direct_review = cls.tool.load_json(ROOT, cls.tool.DIRECT_REVIEW_PATH)
        cls.direct_module = cls.tool.load_json(
            ROOT, cls.tool.DIRECT_REVIEW_MODULE_PATH
        )
        cls.current_module = cls.tool.load_json(ROOT, cls.tool.CURRENT_MODULE_PATH)
        cls.layered = cls.tool.load_json(ROOT, cls.tool.LAYERED_PATH)
        cls.system = cls.tool.load_json(ROOT, cls.tool.SYSTEM_PATH)
        cls.act4 = cls.tool.load_json(ROOT, cls.tool.ACT4_PATH)
        cls.report_text = cls.tool.safe_file(
            ROOT, cls.tool.PROJECTION_REPORT_PATH
        ).read_text(encoding="utf-8")

    def test_exact_current_projection_builds(self) -> None:
        receipt = self.tool.build_receipt(ROOT)
        self.assertEqual(receipt["status"], "PASS")
        self.assertFalse(receipt["aggregates"]["module_receipts_byte_identical"])
        self.assertTrue(receipt["aggregates"]["test_inventory_equal"])
        self.assertEqual(receipt["aggregates"]["test_count"], 114)
        self.assertTrue(receipt["target_logs"]["adapter"]["byte_identical"])
        self.assertTrue(receipt["target_logs"]["collector"]["byte_identical"])
        self.assertFalse(receipt["claim_boundary"]["direct_review_retagged"])
        self.assertFalse(
            receipt["claim_boundary"]["simulation_launched_for_projection"]
        )

    def test_direct_review_cannot_be_retagged_to_current_module(self) -> None:
        review = copy.deepcopy(self.direct_review)
        review["reviewed_inputs"]["current_module"]["path"] = (
            self.tool.CURRENT_MODULE_PATH.as_posix()
        )
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"direct_review": review})

    def test_current_module_inventory_drift_is_rejected(self) -> None:
        current = copy.deepcopy(self.current_module)
        current["tests"]["inventory"].pop()
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"current_module": current})

    def test_current_target_log_single_byte_identity_drift_is_rejected(self) -> None:
        current = copy.deepcopy(self.current_module)
        current["tests"]["logs"]["tb_ooo_lsu_axi_lane_adapter"]["sha256"] = (
            "0" * 64
        )
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"current_module": current})

    def test_current_module_design_id_drift_is_rejected(self) -> None:
        current = copy.deepcopy(self.current_module)
        current["design_id"] = "sha256:" + "0" * 64
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"current_module": current})

    def test_layered_cannot_point_back_to_direct_review_module(self) -> None:
        layered = copy.deepcopy(self.layered)
        record = layered["layers"]["L0_DIRECTED_RTL"]["result"]
        record["path"] = self.tool.DIRECT_REVIEW_MODULE_PATH.as_posix()
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"layered": layered})

    def test_system_layered_sha_drift_is_rejected(self) -> None:
        system = copy.deepcopy(self.system)
        system["layered_signoff_receipt"]["sha256"] = "0" * 64
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"system": system})

    def test_act4_case_shortfall_is_rejected(self) -> None:
        act4 = copy.deepcopy(self.act4)
        act4["counts"]["passed"] = 99
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"act4": act4})

    def test_review_approval_marker_is_required_once(self) -> None:
        report = self.report_text.replace(
            "[V9P-CURRENT-PATH-PROJECTION][APPROVE]",
            "[V9P-CURRENT-PATH-PROJECTION][GAP]",
            1,
        )
        with self.assertRaises(self.tool.ProjectionError):
            self.tool.build_receipt(ROOT, {"report_text": report})


if __name__ == "__main__":
    unittest.main()
