#!/usr/bin/env python3
"""V12C queue-head CSR current runner 的定向单测。"""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


RUNNER = Path(__file__).with_name("run_v12c_serialize_qh_current.py")
SPEC = importlib.util.spec_from_file_location("v12c_serialize_qh_runner", RUNNER)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def positive_log() -> str:
    lines = []
    for label in MODULE.COMMITTED_LABELS:
        lines.append(
            f"[V10G-QH-CSR-RAW] {label} birth=1 lane1_fire=0 "
            "C0_commit=1 C0_barrier=1 CsrFile_request=1 "
            "C1_apply=1 C2_quiet=1 PASS"
        )
    for label in MODULE.KILLED_LABELS:
        lines.append(
            f"[V10G-QH-CSR-KILL] {label} birth=1 lane1_fire=0 "
            "selective_kill=1 C0=0 C1=0 PASS"
        )
    lines.append("[RESULT] PASS")
    return "\n".join(lines) + "\n"


class MarkerTests(unittest.TestCase):
    def test_positive_marker_contract(self) -> None:
        self.assertEqual(
            MODULE.validate_positive_markers(positive_log()),
            {"committed": 3, "selectively_killed": 2},
        )

    def test_positive_missing_c2_is_rejected(self) -> None:
        with self.assertRaises(MODULE.EvidenceError):
            MODULE.validate_positive_markers(
                positive_log().replace(" C2_quiet=1", " C2_quiet=0", 1)
            )

    def test_positive_check_fail_is_rejected(self) -> None:
        with self.assertRaises(MODULE.EvidenceError):
            MODULE.validate_positive_markers(
                positive_log() + "[CHECK-FAIL] unexpected repeated apply\n"
            )

    def test_typed_apply_negative_marker_contract(self) -> None:
        text = (
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply\n" * 3
            + "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply\n" * 3
            + "[RESULT] FAIL\n"
        )
        MODULE.validate_negative_markers(text, "typed-apply-c2-replay")

    def test_csrfile_negative_marker_contract(self) -> None:
        text = (
            "[CHECK-FAIL] V10G unowned/repeated CsrFile CSR request\n" * 3
            + "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply\n" * 3
            + "[RESULT] FAIL\n"
        )
        MODULE.validate_negative_markers(text, "csrfile-request-c2-replay")

    def test_negative_missing_rejection_is_rejected(self) -> None:
        with self.assertRaises(MODULE.EvidenceError):
            MODULE.validate_negative_markers(
                "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply\n"
                "[RESULT] FAIL\n",
                "typed-apply-c2-replay",
            )

    def test_rob_selection_negative_marker_contract(self) -> None:
        text = (
            "[CHECK-FAIL] V10G queue-head CSR C0 commit/barrier diverged\n"
            + "[RESULT] FAIL\n"
        )
        MODULE.validate_negative_markers(
            text, "rob-queue-head-selection-disabled"
        )


class MutationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.root = RUNNER.parents[4]

    def test_typed_apply_mutation_is_compile_source_delta(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            target = MODULE.materialize_typed_apply_mutation(self.root, output)
            self.assertNotEqual(
                MODULE.sha256_file(target),
                MODULE.sha256_file(self.root / MODULE.APPLY_REL),
            )
            self.assertIn("csr_replay_valid_q", target.read_text(encoding="utf-8"))

    def test_csrfile_mutation_replays_only_verification_request(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            target = MODULE.materialize_csrfile_request_mutation(self.root, output)
            text = target.read_text(encoding="utf-8")
            self.assertIn("tb_qh_csrfile_replay_c2_q", text)
            self.assertIn("tb_head0_csr_commit_w ||", text)

    def test_rob_selection_mutation_disables_queue_head_classification(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            target = MODULE.materialize_rob_queue_head_selection_mutation(
                self.root, output
            )
            text = target.read_text(encoding="utf-8")
            self.assertIn("wire head0_queue_csr_w =\n      1'b0;", text)
            self.assertNotEqual(
                MODULE.sha256_file(target),
                MODULE.sha256_file(self.root / MODULE.ROB_REL),
            )

    def test_replace_once_rejects_missing_anchor(self) -> None:
        with self.assertRaises(MODULE.EvidenceError):
            MODULE.replace_once("abc", "missing", "new", "unit")

    def test_failed_run_cleanup_preserves_logs(self) -> None:
        with tempfile.TemporaryDirectory(dir=self.root) as directory:
            output = Path(directory)
            vvp = output / "profiles/assert/build/test.vvp"
            dependency = output / "profiles/assert/dependencies/test.deps"
            log = output / "profiles/assert/logs/test.log"
            for path in (vvp, dependency, log):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("evidence\n", encoding="utf-8")
            result = MODULE.cleanup_failed_run(output)
            self.assertEqual(result["removed"], 2)
            self.assertFalse(vvp.exists())
            self.assertFalse(dependency.exists())
            self.assertTrue(log.exists())


if __name__ == "__main__":
    unittest.main()
