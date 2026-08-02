#!/usr/bin/env python3
"""Focused fail-closed tests for local RV64 OOO-4 evidence parsing."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
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
    def test_simulator_config_binds_tools_and_focused_flags(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            iverilog = root / "iverilog"
            vvp = root / "vvp"
            receipt = root / "simulator-config.txt"
            iverilog.write_bytes(b"iverilog-current\n")
            vvp.write_bytes(b"vvp-current\n")
            receipt.write_text(
                "schema=rv64-ooo4-simulator-config-v1\n"
                "target=v8y-speculation-recovery\n"
                "focused_assert_ivflags=-g2012 -Wall -I../vsrc "
                "-I../vsrc/include -Icommon -DOOO_ASSERT\n"
                "focused_release_ivflags=-g2012 -Wall -I../vsrc "
                "-I../vsrc/include -Icommon\n"
                "mutation_defines=-DOOO_ASSERT,"
                "-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED,"
                "-DV8Y_SPECULATION_RECOVERY_FOCUSED\n"
                f"iverilog {evidence.arch.digest(iverilog)}  {iverilog}\n"
                f"vvp {evidence.arch.digest(vvp)}  {vvp}\n",
                encoding="utf-8",
            )
            parsed = evidence.validate_simulator_config(receipt)
            self.assertEqual(parsed["iverilog_path"], iverilog.as_posix())
            self.assertIn("-DOOO_ASSERT", parsed["focused_assert_ivflags"])

            vvp.write_bytes(b"vvp-stale\n")
            with self.assertRaisesRegex(ValueError, "vvp binary digest is stale"):
                evidence.validate_simulator_config(receipt)

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

    def test_predecessor_receipts_preserve_execution_mode(self) -> None:
        design_id = "sha256:" + "a" * 64
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[V8V-OOO3-RUNNER][PASS] focused=2\n", design_id),
            "fresh_replay",
        )
        self.assertEqual(
            evidence.validate_predecessor_receipt(
                "[ARCH-CURRENT-PREDECESSORS][PASS] "
                f"design_id={design_id} green=6 red=3 next=OOO-4\n",
                design_id,
            ),
            "current_hard_gate_reuse",
        )

    def test_predecessor_receipt_rejects_stale_or_ambiguous_input(self) -> None:
        design_id = "sha256:" + "a" * 64
        stale = "sha256:" + "b" * 64
        reuse = (
            "[ARCH-CURRENT-PREDECESSORS][PASS] "
            f"design_id={stale} green=6 red=3 next=OOO-4\n"
        )
        with self.assertRaisesRegex(ValueError, "stale RTL design id"):
            evidence.validate_predecessor_receipt(reuse, design_id)
        with self.assertRaisesRegex(ValueError, "exactly one"):
            evidence.validate_predecessor_receipt(
                "[V8V-OOO3-RUNNER][PASS]\n" + reuse.replace(stale, design_id),
                design_id,
            )


if __name__ == "__main__":
    unittest.main()
