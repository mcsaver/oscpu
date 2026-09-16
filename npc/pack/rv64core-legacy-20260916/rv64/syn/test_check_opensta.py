#!/usr/bin/env python3
"""Reject incomplete/error STA and negative hold despite positive setup."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

CHECKER = Path(__file__).with_name("check_opensta.py")


class OpenStaDecision(unittest.TestCase):
    def run_case(self, setup=0.10, hold=0.01, *, missing=None,
                 uncertainty=True, warning=False, global_setup=None, check_type="check"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rows = []
            for kind, value in [("max", setup), ("min", hold)]:
                if kind == missing:
                    continue
                rows.append(dict(type=check_type, path_type=kind, slack=value * 1e-9,
                                 data_arrival_time=1e-9, required_time=1e-9,
                                 endpoint="ff/D", startpoint="input",
                                 path_group="core_clock"))
            (root/"paths.json").write_text(json.dumps(dict(checks=rows)))
            (root/"report.rpt").write_text(
                "  -0.0500 0.9500 clock uncertainty\n"
                "  0.0500 0.0500 clock uncertainty\n" if uncertainty else "")
            (root/"log").write_text(
                ("Warning 1: no clock\n" if warning else "") +
                f"worst slack max {setup if global_setup is None else global_setup:.9f}\n"
                f"worst slack min {hold:.9f}\n")
            result = root/"result.json"
            run = subprocess.run([sys.executable, str(CHECKER),
                                  "--paths", str(root/"paths.json"),
                                  "--report", str(root/"report.rpt"),
                                  "--log", str(root/"log"),
                                  "--output", str(result)],
                                 capture_output=True, text=True)
            return run.returncode, json.loads(result.read_text()) if result.exists() else None

    def test_both_nonnegative(self):
        code, result = self.run_case(hold=0)
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "PASS")

    def test_output_and_gate_paths_remain_in_decision(self):
        for kind in ("output_delay", "gated_clk", "latch_check"):
            code, result = self.run_case(setup=-0.3276, check_type=kind)
            self.assertNotEqual(code, 0)
            self.assertEqual(result["worst_setup"]["check_type"], kind)
            self.assertEqual(result["status"], "FAIL")
        code, result = self.run_case(check_type="unconstrained")
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)

    def test_negative_setup_and_hold(self):
        for args in [dict(setup=-0.001), dict(hold=-0.0367)]:
            code, result = self.run_case(**args)
            self.assertNotEqual(code, 0)
            self.assertEqual(result["status"], "FAIL")

    def test_incomplete_or_nonfinite_rejected(self):
        for args in [dict(missing="max"), dict(missing="min"), dict(setup=float("nan"))]:
            code, result = self.run_case(**args)
            self.assertNotEqual(code, 0)
            self.assertIsNone(result)

    def test_ineffective_uncertainty_rejected(self):
        code, result = self.run_case(uncertainty=False)
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)

    def test_engine_problem_rejected(self):
        code, result = self.run_case(warning=True)
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)

    def test_scientific_json_rounding_is_not_a_slack_waiver(self):
        code, result = self.run_case(setup=-3.012, global_setup=-3.0122)
        self.assertNotEqual(code, 0)
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["global_setup_slack_ns"], -3.0122)
        # A real negative engine result cannot pass as a rounded JSON zero.
        code, result = self.run_case(setup=0, global_setup=-0.00001)
        self.assertNotEqual(code, 0)
        self.assertTrue(result is None or result["status"] == "FAIL")
        # An omitted path beyond the known print interval remains invalid.
        code, result = self.run_case(setup=-3.012, global_setup=-3.014)
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)

    def test_omitted_worst_path_rejected(self):
        code, result = self.run_case(global_setup=-0.05)
        self.assertNotEqual(code, 0)
        self.assertIsNone(result)


if __name__ == "__main__":
    unittest.main()
