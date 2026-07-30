#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[3]
FINALIZER = (
    ROOT
    / ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind"
    / "finalize-postflight.py"
)
SPEC = importlib.util.spec_from_file_location(
    "testable_v9r_rebind_finalizer", FINALIZER
)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class PostflightReceiptTests(unittest.TestCase):
    def passing_log(self, count: int = 20) -> str:
        return (
            "." * count
            + "\n"
            + "-" * 70
            + f"\nRan {count} tests in 0.250s\n\nOK\n"
        )

    def test_accepts_exact_zero_rc_unittest_receipt(self) -> None:
        self.assertEqual(
            MODULE.parse_unittest_receipt(
                name="task-local",
                log_text=self.passing_log(),
                rc_text="0\n",
                expected_tests=20,
            ),
            20,
        )

    def test_rejects_nonzero_rc_even_with_ok_marker(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "rc is not zero"):
            MODULE.parse_unittest_receipt(
                name="task-local",
                log_text=self.passing_log(),
                rc_text="1\n",
                expected_tests=20,
            )

    def test_rejects_test_count_drift(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "test count drifted"):
            MODULE.parse_unittest_receipt(
                name="task-local",
                log_text=self.passing_log(count=19),
                rc_text="0\n",
                expected_tests=20,
            )

    def test_rejects_failed_log_even_if_ok_is_appended(self) -> None:
        failed = (
            "Ran 20 tests in 0.250s\n\n"
            "FAILED (failures=1)\n"
            "OK\n"
        )
        with self.assertRaisesRegex(RuntimeError, "unambiguous OK"):
            MODULE.parse_unittest_receipt(
                name="task-local",
                log_text=failed,
                rc_text="0\n",
                expected_tests=20,
            )


if __name__ == "__main__":
    unittest.main()
