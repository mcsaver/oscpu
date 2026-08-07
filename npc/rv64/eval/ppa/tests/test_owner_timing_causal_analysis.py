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
TOOL = ROOT / "npc/rv64/eval/ppa/tools/owner_timing_causal_analysis.py"
OWNER = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-owner-timing-current-337-a2/"
    "evidence/owner-timing-workload-ab/result.json")
PROBE = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-owner-timing-causal-analysis-current-337-a1/"
    "evidence/causal-probe/logs/tb_ooo_owner_timing_causal_probe.log")


class OwnerTimingCausalAnalysisTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="owner-causal-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.result = self.work / "result.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def relative(path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def run_tool(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(TOOL), *arguments],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def build(
        self, *, owner: pathlib.Path = OWNER, probe: pathlib.Path = PROBE,
    ) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--owner-receipt", self.relative(owner),
            "--probe-log", self.relative(probe),
            "--output", self.relative(self.result),
        )

    def mutate_probe(self, old: str, new: str) -> pathlib.Path:
        path = self.work / "probe.log"
        text = PROBE.read_text(encoding="utf-8")
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
        return path

    def test_build_and_verify_research_required_receipt(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "RESEARCH_REQUIRED")
        self.assertEqual(
            value["decision"]["causal_status"], "H1_H2_COUPLED")
        self.assertEqual(
            value["decision"]["causal_hypothesis"], "UNRESOLVED")
        self.assertFalse(value["authorization"]["causal_selection_authorized"])
        self.assertEqual(
            value["decision"]["next_measurement"],
            "measure.owner-b-latency-sensitivity",
        )
        self.assertEqual(
            value["workload_observations"]["coremark"]
            ["b_response_cycles_per_terminal"],
            "4.000000000000",
        )
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 0, verified.stdout)

    def test_missing_probe_case_is_rejected(self) -> None:
        probe = self.mutate_probe(
            "[OWNER-TIMING-CAUSAL-PROBE] b_delay=2 peer=1",
            "[REMOVED-OWNER-TIMING-CAUSAL-PROBE] b_delay=2 peer=1",
        )
        built = self.build(probe=probe)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("case matrix mismatch", built.stdout)

    def test_nonunit_peer_slope_is_rejected(self) -> None:
        probe = self.mutate_probe(
            "b_delay=2 peer=1 store_terminal_cycles=4 "
            "peer_admission_cycles=6",
            "b_delay=2 peer=1 store_terminal_cycles=4 "
            "peer_admission_cycles=7",
        )
        built = self.build(probe=probe)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("peer admission B-delay slope is not one", built.stdout)

    def test_early_peer_admission_is_rejected(self) -> None:
        probe = self.mutate_probe(
            "peer_blocked_b_cycles=3 early_peer_admission=0",
            "peer_blocked_b_cycles=3 early_peer_admission=1",
        )
        built = self.build(probe=probe)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("peer request crossed", built.stdout)

    def test_noncanonical_owner_receipt_is_rejected(self) -> None:
        value = json.loads(OWNER.read_text(encoding="utf-8"))
        value["design_id"] = "sha256:" + "0" * 64
        owner = self.work / "owner.json"
        owner.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        built = self.build(owner=owner)
        self.assertEqual(built.returncode, 2, built.stdout)
        self.assertIn("owner timing receipt is not canonical", built.stdout)

    def test_tampered_authorization_is_not_canonical(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        value["authorization"]["causal_selection_authorized"] = True
        self.result.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("not canonical", verified.stdout)

    def test_bound_rtl_hash_mismatch_is_rejected(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        value["inputs"]["arbiter_rtl"]["sha256"] = "0" * 64
        self.result.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("arbiter_rtl sha256 mismatch", verified.stdout)


if __name__ == "__main__":
    unittest.main()
