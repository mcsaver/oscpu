#!/usr/bin/env python3
"""Fail-closed tests for local RV64 DI-1 evidence parsing."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location(
    "frontend_ii1_evidence_under_test", TOOLS / "frontend_ii1_evidence.py")
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)


def frontend_log(*, drain: tuple[int, int, int, int] = (83, 83, 83, 83)) -> str:
    request, response, enqueue, dequeue = drain
    return "\n".join((
        evidence.FRONTEND_INTEGRATION_MARKER,
        evidence.FRONTEND_BACKPRESSURE_MARKER,
        "[V8Z-FRONTEND-II1-DRAIN] "
        f"requests={request} responses={response} enqueues={enqueue} "
        f"dequeues={dequeue} outstanding=0 fifo=0 rob=0 issue=0 "
        "ghosts=0 PASS",
        "[PASS] tb_ooo_core_top_glue_v8z_frontend_ii1",
        "[RESULT] PASS",
    )) + "\n"


def bridge_log(*, include_skid: bool = True) -> str:
    markers = [
        evidence.BRIDGE_MARKERS["bare_h1"],
        evidence.BRIDGE_MARKERS["paged_h1"],
        "[PASS] tb_ooo_fetch_axi_bridge",
        "[RESULT] PASS",
    ]
    if include_skid:
        markers.insert(2, evidence.BRIDGE_MARKERS["elastic_skid"])
    return "\n".join(markers) + "\n"


class FrontendIi1EvidenceTests(unittest.TestCase):
    def test_frontend_pc_backpressure_and_drain_are_accepted(self) -> None:
        result = evidence.parse_frontend_text(frontend_log(), "synthetic")
        self.assertTrue(result["steady_window"])
        self.assertTrue(result["pc_ledger"])
        self.assertTrue(result["backpressure_recovery"])
        self.assertTrue(result["final_conservation"])

    def test_drain_count_mismatch_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "mismatch"):
            evidence.parse_frontend_text(
                frontend_log(drain=(83, 82, 82, 82)), "synthetic")

    def test_bridge_skid_marker_is_required(self) -> None:
        with self.assertRaisesRegex(ValueError, "ELASTIC-SKID"):
            evidence.parse_bridge_text(
                bridge_log(include_skid=False), "synthetic bridge")

    def test_mutation_dimension_mapping_is_exact(self) -> None:
        rows = [
            {"name": name, "dimensions": list(dimensions)}
            for name, dimensions in
            evidence.REQUIRED_MUTATION_DIMENSIONS.items()
        ]
        evidence.validate_mutation_dimension_coverage(rows)
        rows[-1]["dimensions"] = []
        with self.assertRaisesRegex(ValueError, "dimension mismatch"):
            evidence.validate_mutation_dimension_coverage(rows)


if __name__ == "__main__":
    unittest.main()
