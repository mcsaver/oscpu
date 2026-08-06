#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/performance_bottleneck_census.py"
BASELINE = ROOT / "npc/rv64/eval/ppa/evidence/performance-baseline-current.json"


class PerformanceBottleneckCensusTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="performance-census-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.result = self.work / "census.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def relative(self, path: pathlib.Path) -> str:
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

    def build(self, source: pathlib.Path = BASELINE) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--baseline", self.relative(source),
            "--output", self.relative(self.result),
        )

    def test_build_and_verify_current_census(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], "CPI_BOTTLENECK_CENSUS")
        self.assertFalse(value["optimization_candidate_authorized"])
        self.assertEqual(value["ppa"], "UNQUALIFIED")

    def test_cross_workload_residency_hierarchy_is_exact(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        expected = {
            "cycle_residency": "memory_latency",
            "memory_lifecycle": "request_outstanding",
            "memory_request_detail": "axi_write_response",
        }
        self.assertEqual(
            value["cross_workload_observation"][
                "dominant_residency_hierarchy"]["coremark"], expected)
        self.assertEqual(
            value["cross_workload_observation"][
                "dominant_residency_hierarchy"]["dhrystone_10000"], expected)

    def test_key_ratios_are_deterministic(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(
            value["workloads"]["coremark"]["key_ratios"][
                "memory_latency_cycles"], "0.471431907")
        self.assertEqual(
            value["workloads"]["dhrystone_10000"]["key_ratios"][
                "memory_latency_cycles"], "0.688591040")

    def test_rank_vectors_are_complete_and_conserved(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        expected_cycle = {
            "useful", "rob_empty", "dependency", "issue_terminal",
            "execution_latency", "memory_latency", "head_lifecycle_unknown",
            "exception_redirect", "memory_commit", "serialization", "unknown",
        }
        expected_memory = {
            "reservation_queue", "translation_order", "request_outstanding",
            "response_terminal", "retry", "lifecycle_unknown",
        }
        expected_request = {
            "cache_lookup", "axi_read_address", "axi_read_data",
            "axi_write_request", "axi_write_response", "device_wait",
            "detail_unknown",
        }
        for workload in value["workloads"].values():
            cycle_rank = workload["cycle_residency_rank"]
            memory_rank = workload["memory_lifecycle_rank"]
            request_rank = workload["memory_request_detail_rank"]
            self.assertEqual({item["name"] for item in cycle_rank}, expected_cycle)
            self.assertEqual({item["name"] for item in memory_rank}, expected_memory)
            self.assertEqual({item["name"] for item in request_rank}, expected_request)
            self.assertEqual(
                sum(item["cycles_or_slots"] for item in cycle_rank),
                workload["cycles"],
            )
            memory_total = next(
                item["cycles_or_slots"] for item in cycle_rank
                if item["name"] == "memory_latency")
            self.assertEqual(
                sum(item["cycles_or_slots"] for item in memory_rank), memory_total)
            request_total = next(
                item["cycles_or_slots"] for item in memory_rank
                if item["name"] == "request_outstanding")
            self.assertEqual(
                sum(item["cycles_or_slots"] for item in request_rank), request_total)

    def test_discriminator_plan_covers_h1_through_h4(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        plan = value["next_discriminating_measurement"]
        self.assertEqual(plan["schema"], "npc-rv64-cpi-discriminator-plan-v1")
        self.assertEqual(
            set(plan["channels"]),
            {"owner_transaction", "bridge_timing", "pre_request_pipeline"},
        )
        self.assertEqual(
            set(plan["hypothesis_discrimination_matrix"]),
            {
                "H1_B_RESPONSE_LATENCY", "H2_WRITE_CONCURRENCY",
                "H3_HEAD_RESIDENCY_WEIGHTING", "H4_PRE_REQUEST_PIPELINE",
            },
        )
        self.assertIn(
            "reservation-queue entry/exit count and duration histogram",
            plan["channels"]["pre_request_pipeline"]["observations"],
        )
        self.assertFalse(value["optimization_candidate_authorized"])
        self.assertEqual(value["ppa"], "UNQUALIFIED")

    def test_tampered_baseline_after_build_is_rejected(self) -> None:
        copied = self.work / "baseline.json"
        shutil.copyfile(BASELINE, copied)
        built = self.build(copied)
        self.assertEqual(built.returncode, 0, built.stdout)
        copied.write_text(
            copied.read_text(encoding="utf-8").replace(
                '"memory_latency": 2542049', '"memory_latency": 2542050', 1),
            encoding="utf-8",
        )
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertNotEqual(verified.returncode, 0)
        self.assertIn("performance baseline sha256 mismatch", verified.stdout)

    def test_candidate_authorization_tamper_is_rejected(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        value["optimization_candidate_authorized"] = True
        self.result.write_text(json.dumps(value), encoding="utf-8")
        verified = self.run_tool(
            "verify", "--input", self.relative(self.result))
        self.assertNotEqual(verified.returncode, 0)
        self.assertIn("not canonical", verified.stdout)


if __name__ == "__main__":
    unittest.main()
