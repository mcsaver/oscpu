#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/traceable_timing_replay.py"
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import traceable_timing_replay as replay  # noqa: E402


TRACE_RUN = ROOT / replay.TRACE_RUN_REL
PATH_ANALYSIS = ROOT / replay.PATH_ANALYSIS_REL
NAMED_TOP40 = ROOT / replay.TRACE_EVIDENCE_REL / "opensta-top40.rpt"
NUMERIC_TOP40 = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-current-reference-ppa-337-a1/"
    "evidence/current-fresh-a1/opensta-top40.rpt"
)


class TraceableTimingReplayTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="traceable-timing-replay-", dir=runtime)
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

    def build(self) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--trace-run", self.relative(TRACE_RUN),
            "--path-analysis", self.relative(PATH_ANALYSIS),
            "--output", self.relative(self.output),
        )

    def test_frozen_fail_replays_without_eda_and_resolves_rtl_owners(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool("verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], replay.STATUS)
        self.assertEqual(value["original_execution"]["status"], "FAIL")
        self.assertFalse(value["checker_replay"]["eda_rerun"])
        self.assertTrue(value["checker_replay"]["runtime_absent"])
        self.assertEqual(value["path_equivalence"]["path_count"], 40)
        self.assertEqual(
            value["path_equivalence"]["combinational_cells_per_path"], 263)
        self.assertEqual(
            value["rtl_traceability"]["launch"]["register"],
            "next_token_q[0]")
        self.assertEqual(
            value["rtl_traceability"]["capture"]["module"],
            "OooFetchPcOutstandingSequencer")
        self.assertIsNone(
            value["rtl_traceability"]["capture"]["exact_rtl_register"])
        self.assertFalse(
            value["candidate_decision"]["production_rtl_change_authorized"])

    def test_numeric_only_report_is_rejected_as_traceable_mapping(self) -> None:
        paths = replay.parse_report(NUMERIC_TOP40)
        with self.assertRaisesRegex(
                replay.ReplayError, "launch hierarchy/register prefix mismatch"):
            replay.traceable_mapping(paths)

    def test_malformed_underscore_hierarchy_is_rejected(self) -> None:
        paths = copy.deepcopy(replay.parse_report(NAMED_TOP40))
        for path in paths:
            path["startpoint"] = path["startpoint"].replace(
                "u_mem_owner_tracker", "u_mem_owner_trackeX", 1)
        with self.assertRaisesRegex(
                replay.ReplayError, "launch hierarchy/register prefix mismatch"):
            replay.traceable_mapping(paths)

    def test_original_status_rewrite_is_rejected(self) -> None:
        changed = self.work / "status.txt"
        changed.write_text(
            "PASS rc=0 stage=evidence-complete evidence_complete=1 cleanup_rc=0\n",
            encoding="utf-8")
        with self.assertRaisesRegex(
                replay.ReplayError, "original status is not"):
            replay.parse_original_status(changed)

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
        self.assertIn("differs from canonical rebuild", verified.stdout)


if __name__ == "__main__":
    unittest.main()
