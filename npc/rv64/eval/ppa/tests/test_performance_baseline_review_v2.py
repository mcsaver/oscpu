#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

import jsonschema


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/performance_baseline_current.py"
RUN_DIR = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-"
    "performance-baseline-current-337-a2")
EVIDENCE = RUN_DIR / "evidence/performance-baseline-current"
RESULT = EVIDENCE / "result.json"
MANIFEST = EVIDENCE / "run-manifest.json"
TASK_STATUS = RUN_DIR / "performance-baseline-current.status"
COMMAND_STATUS = EVIDENCE / "command-status.txt"
REVIEWER_CONTRACT = ROOT / (
    ".github/task-runs/2026-08-07-rv64-v15q-"
    "performance-baseline-current-337-a2/subagent-contracts/"
    "v15q-performance-baseline-current-337-review-v1.json")
REVIEW_SCHEMA = ROOT / (
    "npc/rv64/eval/ppa/schemas/"
    "performance-baseline-independent-review-v2.schema.json")
WORKFLOW_PATHS = {
    "checker": "npc/rv64/eval/ppa/tools/performance_baseline_current.py",
    "checker_helper": "npc/rv64/eval/ppa/tools/check.py",
    "runner": "npc/rv64/eval/ppa/run-performance-baseline-current.sh",
    "status_helper": "scripts/task-run-status.sh",
    "current_tests": (
        "npc/rv64/eval/ppa/tests/test_performance_baseline_current.py"),
    "direct_tests": "npc/rv64/eval/ppa/tests/test_performance_baseline_v3.py",
    "review_tests": (
        "npc/rv64/eval/ppa/tests/test_performance_baseline_review_v2.py"),
    "result_schema": (
        "npc/rv64/eval/ppa/schemas/"
        "performance-baseline-current-v3.schema.json"),
    "review_schema": (
        "npc/rv64/eval/ppa/schemas/"
        "performance-baseline-independent-review-v2.schema.json"),
}


class PerformanceBaselineReviewV2Tests(unittest.TestCase):
    def setUp(self) -> None:
        runtime = ROOT / ".github/runtime-artifacts/tests"
        runtime.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(
            prefix="performance-review-v2-", dir=runtime)
        self.work = pathlib.Path(self.temporary.name)
        self.output = self.work / "published.json"
        self.review_path = self.work / "review.json"
        self.report = self.work / "independent-review.md"
        self.regression = self.work / "checker-regression.log"
        self.cleanup = self.work / "cleanup-receipt.json"
        self.result = json.loads(RESULT.read_text(encoding="utf-8"))
        self.result_sha = hashlib.sha256(RESULT.read_bytes()).hexdigest()
        self.approval_marker = (
            "[PERFORMANCE-BASELINE-INDEPENDENT-REVIEW]"
            "[APPROVE_PERF_BASELINE] "
            f"design_id={self.result['design_id']} "
            f"result_sha256={self.result_sha}")
        self.report.write_text(
            "# Independent RV64 performance review\n\n"
            f"{self.approval_marker}\n",
            encoding="utf-8")
        self.regression.write_text(
            "test_preflight_rejects_old_design_contract ... ok\n"
            "test_preflight_rejects_noncurrent_simulator_before_execution ... ok\n"
            "test_preflight_rejects_missing_workload_category ... ok\n"
            "test_direct_reused_raw_log_is_rejected ... ok\n"
            "test_direct_v2_review_publishes_current_result ... ok\n"
            "\nRan 30 tests in 1.000s\n\nOK\n",
            encoding="utf-8")
        self.write_cleanup()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def relative(self, path: pathlib.Path) -> str:
        return path.resolve().relative_to(ROOT).as_posix()

    def artifact_record(
        self, path: pathlib.Path, kind: str,
    ) -> dict[str, object]:
        payload = path.read_bytes()
        return {
            "kind": kind,
            "path": self.relative(path),
            "sha256": hashlib.sha256(payload).hexdigest(),
            "size_bytes": len(payload),
        }

    def write_json(self, path: pathlib.Path, value: dict[str, object]) -> None:
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")

    def write_cleanup(self, deleted_bytes: int = 230677810) -> None:
        self.write_json(self.cleanup, {
            "schema": "npc-rv64-performance-baseline-cleanup-receipt-v1",
            "status": "PASS",
            "run_directory": self.relative(RUN_DIR),
            "runtime_build_directory": (
                ".github/runtime-artifacts/rv64-performance-baseline-run/"
                "2026-08-07-rv64-v15q-performance-baseline-current-337-a2/"
                "stats-off-build"),
            "build_tree_absent": True,
            "deleted_bytes": deleted_bytes,
            "task_run_status": self.artifact_record(
                TASK_STATUS, "fail_closed_status"),
            "command_status": self.artifact_record(
                COMMAND_STATUS, "direct_stage_status"),
            "reviewer_contract": self.artifact_record(
                REVIEWER_CONTRACT, "rtl_task_contract"),
            "checked_at_utc": "2026-08-06T00:00:00Z",
        })

    def review(self) -> dict[str, object]:
        return {
            "schema": "npc-rv64-performance-baseline-independent-review-v2",
            "decision": "APPROVE_PERF_BASELINE",
            "design_id": self.result["design_id"],
            "result": self.artifact_record(
                RESULT, "performance_baseline_result"),
            "final_manifest": self.artifact_record(
                MANIFEST, "performance_baseline_final_manifest"),
            "reviewer_contract": self.artifact_record(
                REVIEWER_CONTRACT, "rtl_task_contract"),
            "review_report": self.artifact_record(
                self.report, "independent_review_report"),
            "task_run_status": self.artifact_record(
                TASK_STATUS, "fail_closed_status"),
            "command_status": self.artifact_record(
                COMMAND_STATUS, "direct_stage_status"),
            "checker_regression": self.artifact_record(
                self.regression, "bounded_checker_regression"),
            "cleanup_receipt": self.artifact_record(
                self.cleanup, "cleanup_receipt"),
            "workflow_artifacts": {
                key: self.artifact_record(ROOT / path, key)
                for key, path in WORKFLOW_PATHS.items()
            },
            "approval_marker": self.approval_marker,
            "review_scope": {
                "current_design_identity": "PASS",
                "input_preflight_before_first_simulation": "PASS",
                "committed_pc_boundaries": "PASS",
                "cycle_and_slot_conservation": "PASS",
                "bit_exact_repetitions": "PASS",
                "instrumentation_noninterference": "PASS",
                "fail_closed_status": "PASS",
                "cleanup_receipt": "PASS",
                "negative_mutations": "PASS",
                "historical_result_non_rebinding": "PASS",
                "canonical_build_and_verify": "PASS",
                "scoped_workloads": ["coremark", "dhrystone_10000"],
                "global_workload_representativeness": False,
                "full_causal_cpi_stack": False,
                "ppa": "UNQUALIFIED",
                "promotion_eligible": False,
            },
            "open_blockers": [],
            "unknowns": [
                "Global integer/FP issue-slot and region occupancy remain outside the scoped baseline."
            ],
            "reviewed_at_utc": "2026-08-06T00:00:00Z",
        }

    def run_publish(
        self, review: dict[str, object],
    ) -> subprocess.CompletedProcess[str]:
        self.write_json(self.review_path, review)
        return subprocess.run(
            [sys.executable, str(TOOL), "publish",
             "--review", self.relative(self.review_path),
             "--output", self.relative(self.output)],
            cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, check=False)

    def test_direct_v2_review_publishes_current_result(self) -> None:
        completed = self.run_publish(self.review())
        self.assertEqual(completed.returncode, 0, completed.stdout)
        self.assertEqual(
            json.loads(self.output.read_text(encoding="utf-8")), self.result)

    def test_direct_v2_review_schema_is_valid(self) -> None:
        schema = json.loads(REVIEW_SCHEMA.read_text(encoding="utf-8"))
        review = self.review()
        jsonschema.Draft202012Validator.check_schema(schema)
        jsonschema.validate(review, schema)

    def test_direct_v2_review_rejects_scope_expansion(self) -> None:
        review = self.review()
        review["review_scope"]["global_workload_representativeness"] = True
        completed = self.run_publish(review)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("performance claim boundary mismatch", completed.stdout)

    def test_direct_v2_review_rejects_cleanup_mismatch(self) -> None:
        self.write_cleanup(deleted_bytes=1)
        review = self.review()
        completed = self.run_publish(review)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("cleanup receipt byte count mismatch", completed.stdout)

    def test_direct_v2_review_rejects_workflow_path_substitution(self) -> None:
        review = self.review()
        review["workflow_artifacts"]["checker_helper"] = (
            review["workflow_artifacts"]["checker"])
        completed = self.run_publish(review)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("checker_helper path mismatch", completed.stdout)


if __name__ == "__main__":
    unittest.main()
