#!/usr/bin/env python3
"""Focused fail-closed tests for local RV64 OOO-4 evidence parsing."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location(
    "speculation_recovery_evidence_under_test",
    TOOLS / "speculation_recovery_evidence.py",
)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)


def focused_log(*, include_wrap: bool = True) -> str:
    markers = [
        evidence.LINEAR_MARKER,
        evidence.LEDGER_MARKER,
        evidence.EX_KILL_MARKER,
        evidence.EX_MATRIX_MARKER,
        evidence.AXI_DRAIN_MARKER,
        evidence.INTEGRATED_MARKER,
        "[PASS] tb_ooo_int_backend_v8y_speculation_recovery",
        "[RESULT] PASS",
    ]
    if include_wrap:
        markers.insert(1, evidence.WRAP_MARKER)
    return "\n".join(markers) + "\n"


def mutation_rows() -> list[dict[str, object]]:
    return [
        {"name": name, "metrics": list(metrics)}
        for name, metrics in evidence.REQUIRED_MUTATION_METRICS.items()
    ]


class SpeculationRecoveryEvidenceTests(unittest.TestCase):
    def test_exact_linear_and_wrap_markers_are_accepted(self) -> None:
        observations = evidence.parse_focused_text(
            focused_log(), "synthetic focused")
        self.assertTrue(observations["linear_control_order"])
        self.assertTrue(observations["wrap_control_order"])
        self.assertTrue(observations["full_pid_ledger"])

    def test_missing_wrap_marker_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "mode=wrap"):
            evidence.parse_focused_text(
                focused_log(include_wrap=False), "synthetic focused")

    def test_missing_exactly_once_metric_mapping_is_rejected(self) -> None:
        rows = mutation_rows()
        for row in rows:
            if row["name"] == "completion_replay_one_cycle":
                row["metrics"] = []
        with self.assertRaisesRegex(ValueError, "metric mapping mismatch"):
            evidence.validate_mutation_metric_coverage(rows)


if __name__ == "__main__":
    unittest.main()
