#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/current_timing_path_analysis.py"
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import current_timing_path_analysis as analysis  # noqa: E402


RUN1_TOP40 = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/"
    "evidence/mapped-sta-current-v2/candidate/opensta-top40.rpt")
RUN2_TOP40 = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/"
    "evidence/current-fresh-a1/opensta-top40.rpt")
CURRENT_REFERENCE = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/"
    "evidence/current-reference-ppa-337-a1.json")
SELECTOR = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/"
    "evidence/optimization-slice-current-337-v5.json")
REVIEW = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/"
    "evidence/independent-review-v1.md")


class CurrentTimingPathAnalysisTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="current-timing-path-analysis-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.output = self.work / "result.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def relative(path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOL), *args], cwd=ROOT,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            check=False)

    def build(self, run2_top40: pathlib.Path = RUN2_TOP40) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--current-reference", self.relative(CURRENT_REFERENCE),
            "--selector", self.relative(SELECTOR),
            "--independent-review", self.relative(REVIEW),
            "--run1-top40", self.relative(RUN1_TOP40),
            "--run2-top40", self.relative(run2_top40),
            "--output", self.relative(self.output),
        )

    def test_exact_reports_form_one_dominant_numeric_path_family_gap(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool("verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "GAP_RTL_OWNER_TRACE_REQUIRED")
        paths = value["path_analysis"]
        self.assertEqual(paths["path_count"], 40)
        self.assertEqual(paths["unique_startpoint_count"], 1)
        self.assertEqual(paths["unique_endpoint_count"], 40)
        self.assertGreaterEqual(paths["dominant_family"]["path_count"], 20)
        self.assertEqual(
            paths["rtl_traceability"]["status"],
            "GAP_NUMERIC_POSTMAP_NAMES")
        self.assertFalse(
            value["candidate_decision"]["production_rtl_change_authorized"])
        self.assertEqual(
            value["next_action"], "measure.current-top40-traceable-names")

    def test_non_exact_second_report_is_rejected(self) -> None:
        mutated = self.work / "mutated-top40.rpt"
        text = RUN2_TOP40.read_text(encoding="utf-8")
        mutated.write_text(text.replace("_1135517_", "_1135999_", 1),
                           encoding="utf-8")
        built = self.build(mutated)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn(
            "explicit top-40 paths do not match current-reference summaries",
            built.stdout)

    def test_missing_path_is_rejected_by_parser(self) -> None:
        blocks = RUN2_TOP40.read_text(encoding="utf-8").split("Startpoint:")
        truncated = self.work / "top39.rpt"
        truncated.write_text(
            blocks[0] + "Startpoint:" + "Startpoint:".join(blocks[1:-1]),
            encoding="utf-8")
        with self.assertRaisesRegex(
                analysis.EvidenceError, "exactly 40 paths"):
            analysis.parse_report(truncated)

    def test_authorization_tamper_is_rejected(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        value["candidate_decision"]["production_rtl_change_authorized"] = True
        self.output.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
        verified = self.run_tool("verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("differs from rebuilt evidence", verified.stdout)


if __name__ == "__main__":
    unittest.main()
