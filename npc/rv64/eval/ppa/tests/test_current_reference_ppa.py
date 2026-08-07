#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/current_reference_ppa.py"
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import current_reference_ppa as reference  # noqa: E402


SELECTOR = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-selector-state-reconciliation-337de8bf/"
    "evidence/optimization-slice-current-337-v4.json")
POLICY = ROOT / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
RUN1_ROOT = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a")
RUN1_EVIDENCE = RUN1_ROOT / "evidence/mapped-sta-current-v2"
RUN2_ROOT = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1")
RUN2_EVIDENCE = RUN2_ROOT / "evidence/current-fresh-a1"


class CurrentReferencePpaTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="current-reference-ppa-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.result = self.work / "result.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def relative(path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOL), *args],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def build(self, run2_summary: pathlib.Path | None = None) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--selector", self.relative(SELECTOR),
            "--policy", self.relative(POLICY),
            "--run1-summary", self.relative(
                RUN1_EVIDENCE / "candidate/summary.json"),
            "--run1-status", self.relative(
                RUN1_ROOT / "mapped-sta-current-v2.status"),
            "--run1-cleanup", self.relative(
                RUN1_EVIDENCE / "candidate/cleanup.txt"),
            "--run1-manifest-before", self.relative(
                RUN1_EVIDENCE / "production-manifest-before.sha256"),
            "--run1-manifest-after", self.relative(
                RUN1_EVIDENCE / "production-manifest-after.sha256"),
            "--run2-summary", self.relative(
                run2_summary or RUN2_EVIDENCE / "summary.json"),
            "--run2-status", self.relative(RUN2_ROOT / "current-fresh-a1.status"),
            "--run2-cleanup", self.relative(RUN2_EVIDENCE / "cleanup.txt"),
            "--run2-manifest-before", self.relative(
                RUN2_EVIDENCE / "production-manifest-before.sha256"),
            "--run2-manifest-after", self.relative(
                RUN2_EVIDENCE / "production-manifest-after.sha256"),
            "--output", self.relative(self.result),
        )

    def test_two_fresh_runs_build_repeatable_timing_fail_receipt(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool("verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(
            value["status"],
            "REPEATABLE_CURRENT_REFERENCE_TIMING_HARD_GATE_FAIL")
        self.assertEqual(value["repeatability"]["status"], "PASS")
        self.assertEqual(value["timing"]["hard_gate"], "FAIL")
        self.assertEqual(value["timing"]["wns_ns"], -18.121620178)
        self.assertEqual(
            value["area"]["logic_area_proxy_excluding_unknown_macros"],
            2181685.8)
        self.assertTrue(
            value["authorization"]["engineering_reference_available"])
        self.assertFalse(
            value["authorization"]["accepted_ppa_reference_available"])
        self.assertFalse(value["authorization"]["promotion_eligible"])

    def test_timing_difference_between_fresh_runs_is_rejected(self) -> None:
        value = json.loads(
            (RUN2_EVIDENCE / "summary.json").read_text(encoding="utf-8"))
        value["timing"]["wns_ns"] = -18.0
        path = self.work / "timing-drift.json"
        path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
        built = self.build(path)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("two fresh mapped runs differ at timing", built.stdout)

    def test_top40_artifact_tamper_is_rejected(self) -> None:
        value = json.loads(
            (RUN2_EVIDENCE / "summary.json").read_text(encoding="utf-8"))
        value["artifacts"]["top40"]["sha256"] = "0" * 64
        path = self.work / "top40-tamper.json"
        path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
        built = self.build(path)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("run2.artifacts.top40 artifact SHA-256 drift", built.stdout)

    def test_promotion_authorization_tamper_is_not_canonical(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        value["authorization"]["promotion_eligible"] = True
        self.result.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        verified = self.run_tool("verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("differs from rebuilt evidence", verified.stdout)


if __name__ == "__main__":
    unittest.main()
