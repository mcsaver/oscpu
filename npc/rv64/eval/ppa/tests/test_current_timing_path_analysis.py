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
    ".github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-ppa-a1/"
    "evidence/traceable-f72e-a1/opensta-top40.rpt")
RUN2_TOP40 = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15x-current-reference-ppa-f72e-a2/"
    "evidence/current-fresh-f72e-a2/opensta-top40.rpt")
CURRENT_REFERENCE = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/current-reference-ppa/result.json")
SELECTOR = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/selector-current-ppa-v3.json")
REVIEW = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "subagent-contracts/v15z-serialized-drain-boundary-review-f72e-v1.result.md")
TRACEABILITY = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-ppa-a1/"
    "evidence/traceable-f72e-a1/traceability.txt")


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
            "--traceability", self.relative(TRACEABILITY),
            "--output", self.relative(self.output),
        )

    def test_exact_reports_define_one_traceable_gap(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool("verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(
            value["status"],
            "GAP_NO_SAFE_SERIALIZED_DRAIN_BOUNDARY")
        paths = value["path_analysis"]
        self.assertEqual(paths["path_count"], 40)
        self.assertEqual(paths["unique_startpoint_count"], 1)
        self.assertEqual(paths["unique_endpoint_count"], 40)
        self.assertEqual(paths["dominant_family"]["path_count"], 40)
        self.assertGreaterEqual(paths["common_raw_prefix_cell_count"], 200)
        self.assertEqual(paths["endpoint_class_counts"], {
            "jalr_prefetch_hit_available": 34,
            "redirect_valid": 5,
            "pending_branch_misaligned": 1,
        })
        self.assertTrue(all(
            count == 40
            for count in paths["shared_cone_token_path_counts"].values()))
        self.assertEqual(
            paths["rtl_traceability"]["status"],
            "TRACEABLE_NAMES_PRESENT")
        self.assertEqual(
            paths["rtl_traceability"]["rtl_owner"]
            ["dominant_control_segment"]["coverage"], "40/40")
        self.assertEqual(
            value["candidate_decision"]["id"],
            "NONE_OWNER_LIFETIME_UNPROVEN")
        self.assertEqual(
            value["candidate_decision"]["rejected_candidate_id"],
            "serialized-mem-terminal-readiness-register-v1")
        self.assertEqual(value["candidate_decision"]["status"], "GAP")
        self.assertFalse(
            value["candidate_decision"]["production_rtl_change_authorized"])
        self.assertEqual(
            value["next_action"],
            "analyze.serialized-drain-owner-lifetime")

    def test_non_exact_second_report_is_rejected(self) -> None:
        mutated = self.work / "mutated-top40.rpt"
        text = RUN2_TOP40.read_text(encoding="utf-8")
        mutated.write_text(text.replace("csr_mtvec_q_63__", "csr_mtvec_q_62__", 1),
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
