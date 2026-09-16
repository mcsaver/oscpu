#!/usr/bin/env python3
"""Fail-closed tests for local RV64 vectored-trap evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
REPO = TOOLS.parents[4]
SPEC = importlib.util.spec_from_file_location(
    "vectored_trap_evidence_under_test",
    TOOLS / "vectored_trap_evidence.py",
)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = evidence
SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "vectored_trap_arch_stable_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}/evidence"
FOCUSED = TASK / "current/logs/tb_csr_file_vectored_trap.log"
PROGRAM = TASK / "current/logs/tb_ooo_priv_system.log"
REGRESSION = TASK / "current/logs/tb_csr_file.log"
MUTATIONS = TASK / "mutations/mutation-evidence.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/vectored-trap-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/vectored-trap.log"


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "vectored_trap_result",
                "path": result_path.relative_to(REPO).as_posix(),
                "sha256": freeze.sha256_file(result_path),
            },
            {
                "kind": "raw_log",
                "path": RAW_LOG.relative_to(REPO).as_posix(),
                "sha256": freeze.sha256_file(RAW_LOG),
            },
        ],
    }, result["design_id"])


class VectoredTrapEvidenceTests(unittest.TestCase):
    def test_live_evidence_is_current_and_complete(self) -> None:
        result, raw = evidence.build_evidence(
            root=REPO,
            focused_log=FOCUSED,
            program_log=PROGRAM,
            regression_log=REGRESSION,
            mutation_manifest=MUTATIONS,
        )
        self.assertEqual(result["status"], "PASS")
        expected_mutations = len(evidence.mutation_model.MUTATIONS)
        self.assertEqual(
            result["metrics"]["mutations"]["compile_succeeded"],
            expected_mutations,
        )
        self.assertEqual(
            result["metrics"]["mutations"]["dynamic_rejected"],
            expected_mutations,
        )
        self.assertEqual(result["metrics"]["full_core"]["xret_commits"], 3)
        self.assertEqual(result["claim"]["ppa"], "UNQUALIFIED")
        self.assertIn("[VECTORED-TRAP-GATE] PASS", raw)

    def test_duplicate_focused_marker_is_rejected(self) -> None:
        text = f"{evidence.FOCUSED_MARKER}\n{evidence.FOCUSED_MARKER}\n"
        with self.assertRaisesRegex(ValueError, "expected one exact marker"):
            evidence.require_exact_line(
                text, evidence.FOCUSED_MARKER, "synthetic focused"
            )

    def test_program_metric_cut_is_rejected(self) -> None:
        marker = evidence.PROGRAM_MARKERS["m_irq"]
        text = marker.replace("trap_irq=1", "trap_irq=2") + "\n"
        with self.assertRaisesRegex(ValueError, "expected one exact marker"):
            evidence.require_exact_line(text, marker, "synthetic M IRQ")

    def test_mutation_aggregate_cut_is_rejected(self) -> None:
        payload = json.loads(MUTATIONS.read_text(encoding="utf-8"))
        payload["summary"]["rejected"] = 5
        task_root = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=task_root, prefix=".vectored-trap-test-"
        ) as temp_name:
            path = pathlib.Path(temp_name) / "mutation-evidence.json"
            path.write_text(
                json.dumps(payload, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            rtl_sha, rtl_files = evidence.arch.rtl_binding(REPO)
            with self.assertRaisesRegex(ValueError, "aggregate"):
                evidence.validate_mutations(
                    REPO, path, f"sha256:{rtl_sha}", rtl_files
                )

    def test_reserved_mode_variant_requires_both_warl_assertions(self) -> None:
        payload = json.loads(MUTATIONS.read_text(encoding="utf-8"))
        row = next(
            item
            for item in payload["mutations"]
            if item["mutation_id"] == "reserved_mode_passthrough"
        )
        row["required_assertion_counts"].pop(
            "[VECTORED-TRAP-A4-STVEC-MODE]"
        )
        task_root = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=task_root, prefix=".vectored-trap-test-"
        ) as temp_name:
            path = pathlib.Path(temp_name) / "mutation-evidence.json"
            path.write_text(
                json.dumps(payload, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            rtl_sha, rtl_files = evidence.arch.rtl_binding(REPO)
            with self.assertRaisesRegex(ValueError, "assertion rejection"):
                evidence.validate_mutations(
                    REPO, path, f"sha256:{rtl_sha}", rtl_files
                )

    def test_irq_routing_variant_requires_a5_assertion(self) -> None:
        payload = json.loads(MUTATIONS.read_text(encoding="utf-8"))
        row = next(
            item
            for item in payload["mutations"]
            if item["mutation_id"] == "drop_nondelegated_supervisor_irq"
        )
        row["required_assertion_counts"].pop(
            "[VECTORED-TRAP-A5-IRQ-ROUTING]"
        )
        task_root = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=task_root, prefix=".vectored-trap-test-"
        ) as temp_name:
            path = pathlib.Path(temp_name) / "mutation-evidence.json"
            path.write_text(
                json.dumps(payload, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            rtl_sha, rtl_files = evidence.arch.rtl_binding(REPO)
            with self.assertRaisesRegex(ValueError, "assertion rejection"):
                evidence.validate_mutations(
                    REPO, path, f"sha256:{rtl_sha}", rtl_files
                )

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_vectored_trap_debt(REPO, entry, design_id), []
        )

    def test_arch_stable_validator_rejects_duplicate_accounting_cut(self) -> None:
        payload = json.loads(RESULT.read_text(encoding="utf-8"))
        payload["metrics"]["full_core"]["raw_duplicate_terminal_events"] = 1
        task_root = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=task_root, prefix=".vectored-trap-validator-"
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            path.write_text(
                json.dumps(payload, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_vectored_trap_debt(
                REPO, entry, design_id
            )
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
