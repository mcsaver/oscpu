#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/owner_b_response_candidate_analysis.py"
TOOLS_DIR = TOOL.parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import owner_b_response_candidate_analysis as analysis  # noqa: E402


SELECTOR = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15w-owner-b-latency-sensitivity-ca37-a1/"
    "evidence/optimization-slice-sensitivity-ca37-a1.json")
SENSITIVITY = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15w-owner-b-latency-sensitivity-ca37-a1/"
    "evidence/owner-b-latency-sensitivity/result.json")
PRIOR = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15o-owner-b-response-candidate-analysis-f7a/"
    "evidence/owner-b-response-candidate-analysis/result.json")
CLOSURE = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/"
    "evidence/independent-review-closure-v2.txt")
DISPOSITION = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/"
    "evidence/slice-disposition-v1.txt")
PERFORMANCE = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/"
    "evidence/performance-ab-current-v2/result.json")
MAPPED_STA = ROOT / (
    ".github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/"
    "evidence/mapped-sta-current-v2/result.json")
INDEPENDENT_REVIEW = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15w-owner-b-response-candidate-analysis-ca37-a1/"
    "subagent-contracts/v15w-owner-b-path-current-review-v1.result.md")
INDEPENDENT_REVIEW_CONTRACT = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15w-owner-b-response-candidate-analysis-ca37-a1/"
    "subagent-contracts/v15w-owner-b-path-current-review-v1.json")


class OwnerBResponseCandidateAnalysisTests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="owner-b-candidate-", dir=runtime)
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

    def build(self) -> subprocess.CompletedProcess[str]:
        return self.run_tool(
            "build",
            "--selector", self.relative(SELECTOR),
            "--sensitivity", self.relative(SENSITIVITY),
            "--prior-analysis", self.relative(PRIOR),
            "--implementation-closure", self.relative(CLOSURE),
            "--slice-disposition", self.relative(DISPOSITION),
            "--performance-ab", self.relative(PERFORMANCE),
            "--mapped-sta", self.relative(MAPPED_STA),
            "--independent-review", self.relative(INDEPENDENT_REVIEW),
            "--independent-review-contract",
            self.relative(INDEPENDENT_REVIEW_CONTRACT),
            "--output", self.relative(self.result),
        )

    def source_texts(self) -> dict[str, str]:
        return {
            relative: (ROOT / relative).read_text(encoding="utf-8")
            for relative in analysis.SOURCE_PATHS
        }

    def test_current_path_builds_with_candidate_only_and_explicit_gap(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        verified = self.run_tool("verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 0, verified.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        self.assertEqual(value["status"], analysis.STATUS)
        self.assertEqual(value["next_action"], analysis.NEXT_ACTION)
        self.assertEqual(value["canonical_cycle_map"][-1]["edge"], "E4")
        remaining = value["remaining_latency"]
        self.assertEqual(
            remaining["disposition"], "CANDIDATE_DEFINED_UNQUALIFIED")
        self.assertEqual(remaining["low_risk_qualification"], "GAP")
        self.assertEqual(
            remaining["candidate"]["id"], analysis.NEXT_CANDIDATE)
        self.assertEqual(remaining["candidate"]["state"], "CANDIDATE_ONLY")
        self.assertEqual(
            remaining["candidate"]["ideal_no_backpressure_cycles"], 3)
        self.assertTrue(
            value["authorization"]["second_core_only_candidate_defined"])
        self.assertFalse(
            value["authorization"]["new_production_rtl_change_authorized"])

    def test_independent_review_candidate_marker_is_fail_closed(self) -> None:
        review = self.work / "review.md"
        review.write_text(
            INDEPENDENT_REVIEW.read_text(encoding="utf-8").replace(
                "candidate_cycles=3", "candidate_cycles=2", 1),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
                analysis.EvidenceError,
                "independent-review candidate marker"):
            analysis.verify_independent_review(
                review,
                INDEPENDENT_REVIEW_CONTRACT,
                "sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f",
                "sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968",
                "6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22",
            )

    def test_removing_adapter_fallthrough_is_rejected(self) -> None:
        texts = self.source_texts()
        path = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
        texts[path] = texts[path].replace(
            "wire final_b_fallthrough_w", "wire removed_final_b_fallthrough_w", 1)
        with self.assertRaisesRegex(
                analysis.EvidenceError, "adapter final-B fall-through"):
            analysis.analyze_source_texts(texts)

    def test_non_state_only_bready_is_rejected(self) -> None:
        texts = self.source_texts()
        path = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
        texts[path] = texts[path].replace(
            "assign d_axi_bready_o = (state_q == S_W_RESP);",
            "assign d_axi_bready_o = (state_q == S_W_RESP) && u_axi_bready_i;",
            1,
        )
        with self.assertRaisesRegex(
                analysis.EvidenceError, "state-only downstream BREADY"):
            analysis.analyze_source_texts(texts)

    def test_early_target_bvalid_is_rejected(self) -> None:
        texts = self.source_texts()
        path = "npc/rv64/vsrc/sim/AxiDpiSlave.sv"
        texts[path] = texts[path].replace(
            "if (write_complete_w) begin", "if (aw_valid_q) begin", 1)
        with self.assertRaisesRegex(
                analysis.EvidenceError, "target registered BVALID"):
            analysis.analyze_source_texts(texts)

    def test_tampered_authorization_is_not_canonical(self) -> None:
        built = self.build()
        self.assertEqual(built.returncode, 0, built.stdout)
        value = json.loads(self.result.read_text(encoding="utf-8"))
        value["authorization"]["new_production_rtl_change_authorized"] = True
        self.result.write_text(
            json.dumps(value, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        verified = self.run_tool("verify", "--input", self.relative(self.result))
        self.assertEqual(verified.returncode, 2, verified.stdout)
        self.assertIn("differs from rebuilt evidence", verified.stdout)

    def test_source_inventory_must_be_complete(self) -> None:
        texts = self.source_texts()
        texts.pop("npc/rv64/vsrc/bus/AxiCrossbar.v")
        with self.assertRaisesRegex(
                analysis.EvidenceError, "source text inventory is incomplete"):
            analysis.analyze_source_texts(texts)


if __name__ == "__main__":
    unittest.main()
