#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / (
    "npc/rv64/eval/ppa/tools/serialized_drain_owner_lifetime_analysis.py")
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import serialized_drain_owner_lifetime_analysis as analysis  # noqa: E402


CURRENT_TIMING = ROOT / (
    ".github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/"
    "evidence/mainline-rebind-f72e-v1/current-timing-path-analysis/result.json")
REVIEW = ROOT / (
    ".github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/"
    "subagent-contracts/serialized-drain-owner-lifetime-review-v1.result.md")
CLOSURE = ROOT / (
    ".github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/"
    "evidence/serialized-drain-owner-lifetime/closure.md")
SPEC = ROOT / "npc/rv64/design/specs/ooo-serialized-mem-terminal-permit.md"


class SerializedDrainOwnerLifetimeAnalysisTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="serialized-drain-owner-lifetime-", dir=runtime)
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

    def build(
        self, closure: pathlib.Path = CLOSURE,
    ) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--current-timing-path-analysis", self.relative(CURRENT_TIMING),
            "--independent-review", self.relative(REVIEW),
            "--owner-lifetime-closure", self.relative(closure),
            "--candidate-spec", self.relative(SPEC),
            "--output", self.relative(self.output),
        )

    def test_gap_closes_only_for_owner_bound_candidate(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool(
            "verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(
            value["status"],
            "TRACEABLE_SERIALIZED_OWNER_PERMIT_CANDIDATE_DEFINED")
        self.assertEqual(
            value["candidate_decision"]["id"],
            "serialized-owner-terminal-permit-v2")
        self.assertEqual(
            value["candidate_decision"]["rejected_candidate_id"],
            "serialized-mem-terminal-readiness-register-v1")
        self.assertTrue(
            value["candidate_decision"]
            ["bounded_production_rtl_experiment_authorized"])
        self.assertFalse(value["candidate_decision"]["promotion_eligible"])
        self.assertEqual(value["candidate_decision"]["ppa"], "UNQUALIFIED")
        self.assertEqual(len(value["source_snapshot"]), 9)
        self.assertTrue(value["claim_boundary"]
                        ["bare_one_bit_readiness_remains_rejected"])
        self.assertEqual(
            value["next_action"],
            "experiment.serialized-owner-terminal-permit")

    def test_missing_owner_identity_marker_is_rejected(self) -> None:
        mutated = self.work / "closure-without-owner-identity.md"
        mutated.write_text(
            CLOSURE.read_text(encoding="utf-8").replace(
                "owner_identity_required=true",
                "owner_identity_required=false", 1),
            encoding="utf-8")
        built = self.build(mutated)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("closure marker or claim boundary mismatch", built.stdout)

    def test_authorization_tamper_is_rejected(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.output.read_text(encoding="utf-8"))
        value["candidate_decision"]["promotion_eligible"] = True
        self.output.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
        verified = self.run_tool(
            "verify", "--input", self.relative(self.output))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("differs from rebuilt evidence", verified.stdout)

    def test_live_source_must_match_frozen_timing_manifest(self) -> None:
        receipt = json.loads(CURRENT_TIMING.read_text(encoding="utf-8"))
        _, _, manifest = analysis.verify_current_timing(CURRENT_TIMING)
        source = next(iter(analysis.SOURCE_CONTRACTS))
        self.assertEqual(receipt["design_id"].removeprefix("sha256:").__len__(), 64)
        manifest[source] = "0" * 64
        with self.assertRaisesRegex(
                analysis.EvidenceError, "live source differs from timing design"):
            analysis.source_snapshot(manifest, verify_live=True)


if __name__ == "__main__":
    unittest.main()
