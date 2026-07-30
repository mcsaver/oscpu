#!/usr/bin/env python3
"""Directed unit tests for the stop-hold matrix source transforms/oracle."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
MODULE_PATH = RUN_DIR / "run-stop-hold-matrix.py"
SPEC = importlib.util.spec_from_file_location("stop_hold_matrix", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {MODULE_PATH}")
MATRIX = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MATRIX
SPEC.loader.exec_module(MATRIX)
ROOT = RUN_DIR.parents[2]


class SourceTransformTests(unittest.TestCase):
    def test_drop_stop_hold_is_exact_and_preserves_assertion(self) -> None:
        source = (
            ROOT / "npc/rv64/vsrc/control/OooStopPendingSequencer.v"
        ).read_text(encoding="utf-8")
        changed = MATRIX.replace_exact_once(
            source,
            MATRIX.STOP_HOLD_ANCHOR,
            "",
            "test.stop-hold",
        )
        self.assertNotEqual(source, changed)
        self.assertNotIn(MATRIX.STOP_HOLD_ANCHOR, changed)
        self.assertEqual(source.count(MATRIX.QCSR_ASSERT), 1)
        self.assertEqual(changed.count(MATRIX.QCSR_ASSERT), 1)
        self.assertIn("input wire head0_csr_inflight_i", changed)

    def test_drop_run_gate_owner_is_exact_and_keeps_interface(self) -> None:
        source = (
            ROOT / "npc/rv64/vsrc/frontend/OooFrontendRunGate.v"
        ).read_text(encoding="utf-8")
        changed = MATRIX.replace_exact_once(
            source,
            MATRIX.RUN_GATE_OWNER_ANCHOR,
            MATRIX.RUN_GATE_OWNER_REMOVED,
            "test.run-gate-owner",
        )
        self.assertNotEqual(source, changed)
        self.assertNotIn(MATRIX.RUN_GATE_OWNER_ANCHOR, changed)
        self.assertEqual(
            changed.count(MATRIX.RUN_GATE_OWNER_REMOVED),
            1,
        )
        self.assertIn("input head0_csr_inflight_i", changed)

    def test_replace_exact_once_rejects_missing_anchor(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "observed 0"):
            MATRIX.replace_exact_once("abc", "missing", "", "test")


class OracleTests(unittest.TestCase):
    def validate(
        self,
        semantic_name: str,
        assertions: bool,
        driver_rc: int,
        text: str,
    ) -> tuple[bool, list[str]]:
        semantic = next(
            item for item in MATRIX.SEMANTICS if item.name == semantic_name
        )
        passed, _markers, errors = MATRIX.validate_case(
            semantic=semantic,
            assertions=assertions,
            driver_rc=driver_rc,
            log_text="[COMPILE] iverilog\n" + text,
            image_exists=True,
        )
        return passed, errors

    def test_positive_accepts_exact_raw_pass(self) -> None:
        passed, errors = self.validate(
            "current",
            True,
            0,
            f"{MATRIX.RAW_PASS}\n[RESULT] PASS\n",
        )
        self.assertTrue(passed, errors)

    def test_run_gate_owner_drop_requires_real_overlap(self) -> None:
        text = (
            f"{MATRIX.OWNER_GAP}\n"
            f"{MATRIX.INFLIGHT_RUN}\n"
            f"{MATRIX.LANE1_OVERLAP}\n"
            f"{MATRIX.RUN_GATE_ASSERT}\n"
            "[RESULT] FAIL\n"
        )
        passed, errors = self.validate(
            "drop_run_gate_owner", True, 2, text
        )
        self.assertTrue(passed, errors)
        passed_without_overlap, errors_without_overlap = self.validate(
            "drop_run_gate_owner",
            True,
            2,
            text.replace(f"{MATRIX.LANE1_OVERLAP}\n", ""),
        )
        self.assertFalse(passed_without_overlap)
        self.assertIn(
            "RunGate owner-drop missed real lane1 overlap",
            errors_without_overlap,
        )

    def test_historical_assert_off_requires_stop_drop_and_overlap(self) -> None:
        text = (
            f"{MATRIX.OWNER_GAP}\n"
            f"{MATRIX.STOP_DROP}\n"
            f"{MATRIX.INFLIGHT_RUN}\n"
            f"{MATRIX.LANE1_OVERLAP}\n"
            "[RESULT] FAIL\n"
        )
        passed, errors = self.validate(
            "historical_pre_t3u", False, 2, text
        )
        self.assertTrue(passed, errors)

    def test_historical_assert_on_requires_existing_qcsr_assertion(self) -> None:
        text = (
            f"{MATRIX.OWNER_GAP}\n"
            f"{MATRIX.STOP_DROP}\n"
            f"{MATRIX.INFLIGHT_RUN}\n"
            f"{MATRIX.QCSR_ASSERT}\n"
            "[RESULT] FAIL\n"
        )
        passed, errors = self.validate(
            "historical_pre_t3u", True, 2, text
        )
        self.assertTrue(passed, errors)


if __name__ == "__main__":
    unittest.main(verbosity=2)
