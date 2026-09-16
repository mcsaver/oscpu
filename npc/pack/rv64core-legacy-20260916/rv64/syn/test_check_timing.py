#!/usr/bin/env python3
"""Small qualification-parser tests: setup and hold failures are both terminal."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

CHECKER = Path(__file__).with_name("check_timing.py")


class TimingDecision(unittest.TestCase):
    def run_case(self, rows, uncertainty_rows=(), require_uncertainty=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = root / "synthetic-parser-fixture.rpt"
            result = root / "result.json"
            report.write_text("\n".join(
                f"| ff:D | core_clock | {kind} | 1.000r | 1.950 | 0.000 | {slack} | NA |"
                for kind, slack in rows) + "\n" + "\n".join(
                f"| clock uncertainty | | | | | | {value} | 0.0 |"
                for value in uncertainty_rows))
            run = subprocess.run([sys.executable, str(CHECKER), "--report", str(report),
                                  "--output", str(result)] +
                                 (["--uncertainty", "0.05"] if require_uncertainty else []),
                                 capture_output=True, text=True)
            return run.returncode, json.loads(result.read_text()) if result.exists() else None

    def test_nonnegative_both_pass(self):
        code, result = self.run_case([("max", 0.25), ("min", 0.0)])
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "PASS")

    def test_worst_setup_fails(self):
        code, result = self.run_case([("max", 0.25), ("max", -0.001), ("min", 0.03)])
        self.assertNotEqual(code, 0)
        self.assertEqual(result["worst_setup"]["slack_ns"], -0.001)

    def test_hold_fails_despite_setup_margin(self):
        code, result = self.run_case([("max", 0.35), ("min", -0.037)])
        self.assertNotEqual(code, 0)
        self.assertEqual(result["status"], "FAIL")

    def test_missing_summary_rejected(self):
        for rows in ([], [("max", 0.25)], [("min", 0.03)]):
            code, result = self.run_case(rows)
            self.assertNotEqual(code, 0)
            self.assertIsNone(result)

    def test_nonfinite_slack_rejected(self):
        code, result = self.run_case([("max", "nan"), ("min", 0.03)])
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)

    def test_effective_uncertainty_required(self):
        rows = [("max", 0.1), ("min", 0.01)]
        for values in [(), (0.0, -0.0), (-0.05,), (0.05,)]:
            code, result = self.run_case(rows, values, True)
            self.assertNotEqual(code, 0)
            self.assertIsNone(result)
        code, result = self.run_case(rows, (-0.05, 0.05), True)
        self.assertEqual(code, 0)
        self.assertEqual(result["required_uncertainty_ns"], 0.05)


if __name__ == "__main__":
    unittest.main()
