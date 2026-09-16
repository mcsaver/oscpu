#!/usr/bin/env python3
"""Fail-closed tests for local RV64 DI-1 evidence parsing."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
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
    def test_task_run_paths_are_bounded_to_di1_evidence(self) -> None:
        task_run_id = "2026-08-02-rv64-v13z-di1-current-rebind-v1"
        self.assertEqual(
            evidence.task_run_evidence_rel(task_run_id, "di1-current"),
            pathlib.Path(".github/task-runs") / task_run_id
            / "evidence/di1-current",
        )
        with self.assertRaisesRegex(ValueError, "malformed"):
            evidence.task_run_evidence_rel("../outside", "di1-current")
        with self.assertRaisesRegex(ValueError, "unsupported"):
            evidence.task_run_evidence_rel(task_run_id, "../outside")

    def test_scoped_receipt_binds_task_run_and_write_scope(self) -> None:
        task_run_id = "2026-08-02-rv64-v13z-di1-current-rebind-v1"
        evidence_root = (
            pathlib.Path(".github/task-runs") / task_run_id / "evidence")
        with tempfile.TemporaryDirectory() as temporary:
            receipt = pathlib.Path(temporary) / "scoped-run.txt"
            receipt.write_text("\n".join((
                "schema=rv64-di1-scoped-run-v1",
                "mode=scoped",
                f"task_run_id={task_run_id}",
                f"evidence_root={evidence_root.as_posix()}",
                "canonical_manifest_write=0",
                "historical_evidence_write=0",
            )) + "\n", encoding="utf-8")
            parsed = evidence.validate_scope_receipt(
                receipt, task_run_id, evidence_root)
            self.assertEqual(parsed["canonical_manifest_write"], "0")
            receipt.write_text(
                receipt.read_text(encoding="utf-8").replace(
                    "historical_evidence_write=0",
                    "historical_evidence_write=1"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "malformed"):
                evidence.validate_scope_receipt(
                    receipt, task_run_id, evidence_root)

    def test_simulator_receipt_rejects_stale_binary_hash(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            iverilog = root / "iverilog"
            vvp = root / "vvp"
            iverilog.write_bytes(b"local iverilog\n")
            vvp.write_bytes(b"local vvp\n")
            receipt = root / "simulator-config.txt"
            receipt.write_text("\n".join((
                "schema=rv64-di1-simulator-config-v1",
                "target=v8z-frontend-ii1",
                "assert_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon -DOOO_ASSERT",
                "release_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon",
                "mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon -DOOO_ASSERT",
                f"iverilog {evidence.arch.digest(iverilog)} {iverilog}",
                f"vvp {evidence.arch.digest(vvp)} {vvp}",
            )) + "\n", encoding="utf-8")
            parsed = evidence.validate_simulator_config(receipt)
            self.assertEqual(parsed["target"], "v8z-frontend-ii1")
            iverilog.write_bytes(b"changed local iverilog\n")
            with self.assertRaisesRegex(ValueError, "digest is stale"):
                evidence.validate_simulator_config(receipt)

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

    def test_predecessor_receipts_preserve_execution_mode(self) -> None:
        design_id = "sha256:" + "c" * 64
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[V8Y-OOO4-RUNNER][PASS] focused=2\n", design_id),
            "fresh_replay",
        )
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[ARCH-CURRENT-PREDECESSORS][PASS] "
                f"design_id={design_id} green=7 red=2 next=DI-1\n",
                design_id,
            ),
            "current_hard_gate_reuse",
        )

    def test_predecessor_receipt_rejects_stale_design(self) -> None:
        design_id = "sha256:" + "c" * 64
        stale = "sha256:" + "d" * 64
        with self.assertRaisesRegex(ValueError, "stale RTL design id"):
            evidence.validate_predecessor_receipt(
                "[ARCH-CURRENT-PREDECESSORS][PASS] "
                f"design_id={stale} green=7 red=2 next=DI-1\n",
                design_id,
            )


if __name__ == "__main__":
    unittest.main()
