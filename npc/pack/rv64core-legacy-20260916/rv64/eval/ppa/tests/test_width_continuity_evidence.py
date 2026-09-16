#!/usr/bin/env python3
"""Fail-closed parser tests for local RV64 DI-2 evidence."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location(
    "width_continuity_evidence_under_test",
    TOOLS / "width_continuity_evidence.py",
)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = evidence
SPEC.loader.exec_module(evidence)


def metric_row(*, total: int = 128, dual: int = 64, ipc: int = 2000) -> str:
    fields = ["trace_cycles=64", f"independent_alu_ipc_milli={ipc}"]
    for boundary in evidence.BOUNDARIES:
        fields.extend((
            f"{boundary}_total={total}",
            f"{boundary}_peak=2",
            f"{boundary}_dual_cycles={dual}",
        ))
    return "[V9A-DI2-METRIC] " + " ".join(fields)


def trace_row(cycle: int, *, retire: int = 2) -> str:
    return (
        f"[V9A-DI2-TRACE] cycle={cycle} fetch=2 decode=2 rename=2 "
        f"dispatch=2 issue=2 execute=2 retire={retire} "
        "fetch_pc0=0000000080000000 fetch_pc1=0000000080000004 "
        "issue_pc0=0000000080000000 issue_pc1=0000000080000004 "
        "retire_pc0=0000000080000000 retire_pc1=0000000080000004 "
        "issue_pid0=10 issue_pid1=11 retire_pid0=10 retire_pid1=11"
    )


def width_log(*, total: int = 128, duplicate_metric: bool = False) -> str:
    rows = [evidence.ANCHOR_MARKER]
    rows.extend(trace_row(cycle) for cycle in range(64))
    rows.append(metric_row(total=total))
    if duplicate_metric:
        rows.append(metric_row(total=total))
    rows.extend((
        "[V9A-DI2-IDENTITY] fetched=178 decoded=178 renamed=178 "
        "dispatched=178 issued=178 executed=178 retired=178 active_pid=0 "
        "payload_mismatch=0 lifecycle_error=0 PASS",
        "[V9A-DI2-DRAIN] requests=89 responses=89 enqueues=89 fifo=0 "
        "rob=0 issue=0 ex0=0 ex1=0 free=32 active_pid=0 flush=0 PASS",
        "[PASS] tb_ooo_core_top_glue_v9a_width_continuity",
        "[RESULT] PASS",
    ))
    return "\n".join(rows) + "\n"


def stall_log() -> str:
    rows = [evidence.ANCHOR_MARKER]
    rows.extend(trace_row(cycle, retire=0 if cycle == 21 else 2)
                for cycle in range(64))
    rows.extend((
        "[V9A-WIDTH][FAIL] cycle=17 boundary=0 width=0 expected=2",
        metric_row(total=126, dual=63, ipc=1968),
        "[RESULT] FAIL status=1",
    ))
    return "\n".join(rows) + "\n"


class WidthContinuityEvidenceTests(unittest.TestCase):
    def test_task_run_paths_are_bounded_to_di2_evidence(self) -> None:
        task_run_id = "2026-08-02-rv64-v14a-di2-current-rebind-v1"
        self.assertEqual(
            evidence.task_run_evidence_rel(task_run_id, "di2-current"),
            pathlib.Path(".github/task-runs") / task_run_id
            / "evidence/di2-current",
        )
        with self.assertRaisesRegex(ValueError, "malformed"):
            evidence.task_run_evidence_rel("../outside", "di2-current")
        with self.assertRaisesRegex(ValueError, "unsupported"):
            evidence.task_run_evidence_rel(task_run_id, "../outside")

    def test_scoped_receipt_binds_task_run_and_write_scope(self) -> None:
        task_run_id = "2026-08-02-rv64-v14a-di2-current-rebind-v1"
        evidence_root = (
            pathlib.Path(".github/task-runs") / task_run_id / "evidence")
        with tempfile.TemporaryDirectory() as temporary:
            receipt = pathlib.Path(temporary) / "scoped-run.txt"
            receipt.write_text("\n".join((
                "schema=rv64-di2-scoped-run-v1",
                "mode=scoped",
                f"task_run_id={task_run_id}",
                f"evidence_root={evidence_root.as_posix()}",
                "canonical_manifest_write=0",
                "historical_evidence_write=0",
            )) + "\n", encoding="utf-8")
            parsed = evidence.validate_scope_receipt(
                receipt, task_run_id, evidence_root)
            self.assertEqual(parsed["historical_evidence_write"], "0")
            receipt.write_text(
                receipt.read_text(encoding="utf-8").replace(
                    "canonical_manifest_write=0",
                    "canonical_manifest_write=1"),
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
                "schema=rv64-di2-simulator-config-v1",
                "target=v9a-width-continuity",
                "assert_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon -DOOO_ASSERT",
                "release_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon",
                "stall_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon",
                "mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
                "-Icommon -DV9A_WIDTH_CONTINUITY_FOCUSED",
                f"iverilog {evidence.arch.digest(iverilog)} {iverilog}",
                f"vvp {evidence.arch.digest(vvp)} {vvp}",
            )) + "\n", encoding="utf-8")
            parsed = evidence.validate_simulator_config(receipt)
            self.assertEqual(parsed["target"], "v9a-width-continuity")
            vvp.write_bytes(b"changed local vvp\n")
            with self.assertRaisesRegex(ValueError, "digest is stale"):
                evidence.validate_simulator_config(receipt)

    def test_live_mutation_anchors_are_unique_and_non_noop(self) -> None:
        root = pathlib.Path(__file__).resolve().parents[5]
        for spec in evidence.mutation_model.MUTATIONS:
            reconstructed = evidence.reconstruct_mutant_hashes(root, spec)
            self.assertTrue(reconstructed, spec.name)
            for rel, digest in reconstructed.items():
                self.assertNotEqual(
                    digest,
                    evidence.arch.digest(evidence.arch.safe_artifact(root, rel)),
                    spec.name,
                )

    def test_exact_dual_trace_is_accepted(self) -> None:
        parsed = evidence.parse_width_text(width_log(), "synthetic")
        self.assertEqual(parsed["metrics"]["retire_total"], 128)
        self.assertEqual(len(parsed["trace_lines"]), 64)
        self.assertRegex(parsed["trace_sha256"], r"^[0-9a-f]{64}$")

    def test_126_uops_cannot_publish_as_exact_focused_evidence(self) -> None:
        with self.assertRaisesRegex(ValueError, "fetch aggregate"):
            evidence.parse_width_text(width_log(total=126), "synthetic")

    def test_duplicate_metric_marker_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "one metric"):
            evidence.parse_width_text(
                width_log(duplicate_metric=True), "synthetic")

    def test_fixed_window_stall_probe_must_expose_the_gap(self) -> None:
        parsed = evidence.parse_stall_probe_text(stall_log())
        self.assertEqual(parsed["retire_total"], 126)
        with self.assertRaisesRegex(ValueError, "unique marker"):
            evidence.parse_stall_probe_text(
                stall_log().replace("cycle=17 boundary=0", "cycle=18 boundary=0"))

    def test_mutation_dimension_mapping_is_exact(self) -> None:
        rows = [
            {"name": item.name, "dimensions": list(item.dimensions)}
            for item in evidence.mutation_model.MUTATIONS
        ]
        coverage = evidence.validate_mutation_dimension_coverage(rows)
        self.assertEqual(set(coverage), evidence.REQUIRED_DIMENSIONS)
        rows[-1]["dimensions"] = []
        with self.assertRaisesRegex(ValueError, "dimension mismatch"):
            evidence.validate_mutation_dimension_coverage(rows)

    def test_predecessor_receipts_preserve_execution_mode(self) -> None:
        design_id = "sha256:" + "e" * 64
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[V8Z-DI1-RUNNER][PASS] focused=2\n", design_id),
            "fresh_replay",
        )
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[ARCH-CURRENT-PREDECESSORS][PASS] "
                f"design_id={design_id} green=8 red=1 next=DI-2\n",
                design_id,
            ),
            "current_hard_gate_reuse",
        )

    def test_predecessor_receipt_rejects_malformed_inventory(self) -> None:
        design_id = "sha256:" + "e" * 64
        with self.assertRaisesRegex(ValueError, "ambiguous or malformed"):
            evidence.validate_predecessor_receipt(
                "[ARCH-CURRENT-PREDECESSORS][PASS] "
                f"design_id={design_id} green=7 red=2 next=DI-2\n",
                design_id,
            )


if __name__ == "__main__":
    unittest.main()
