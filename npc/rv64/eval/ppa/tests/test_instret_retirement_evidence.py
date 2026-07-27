#!/usr/bin/env python3
"""Fail-closed tests for local RV64 INSTRET-G1 retirement evidence."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
REPO = TOOLS.parents[4]
sys.path.insert(0, str(TOOLS))

EVIDENCE_SPEC = importlib.util.spec_from_file_location(
    "instret_retirement_evidence_under_test",
    TOOLS / "instret_retirement_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "instret_arch_stable_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement"
PROGRAM_LOG = TASK / "evidence/module-aggregate/logs/tb_ooo_sv39_boot.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
MUTATION_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/instret-retirement-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/instret-retirement.log"


def synthetic_program_log(*, exception_lanes: int = 2, checks: int = 1052) -> str:
    return (
        f"[INSTRET-G1-PROGRAM] exception_lanes={exception_lanes} "
        "exception_zero_delta=2 mret=1 sret=6 sfence_vma=1 "
        f"control_exact=8 control_total=8 csr_delta_checks={checks} PASS\n"
        "[PASS] tb_ooo_sv39_boot\n"
        "[RESULT] PASS\n"
    )


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "instret_retirement_result",
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


class InstretRetirementEvidenceTests(unittest.TestCase):
    def test_exact_program_inventory_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "program.log"
            path.write_text(synthetic_program_log(), encoding="utf-8")
            parsed = evidence.parse_program_log(path)
        self.assertEqual(parsed["exception_zero_delta"], 2)
        self.assertEqual(parsed["control_exact"], 8)
        self.assertGreaterEqual(parsed["csr_delta_checks"], 1000)

    def test_program_event_or_edge_depth_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "program.log"
            path.write_text(
                synthetic_program_log(exception_lanes=1), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_program_log(path)
            path.write_text(synthetic_program_log(checks=999), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "too shallow"):
                evidence.parse_program_log(path)

    def test_live_rtl_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_mutations(REPO, MUTATION_SUMMARY)
        self.assertEqual(audit["compile_success"], 3)
        self.assertEqual(audit["dynamic_rejected"], 3)
        self.assertEqual(len(audit["variants"]), 3)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        required = len(evidence.required_module_tests(
            REPO / "npc/rv64/testbench/Makefile"))
        self.assertEqual(aggregate["required"], required)
        self.assertEqual(aggregate["passed"], required)
        self.assertEqual(aggregate["failed"], 0)

    def test_mutation_aggregate_cut_is_rejected(self) -> None:
        value = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        value["compile_success"] = 2
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "summary.json"
            write_json(path, value)
            with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
                evidence.validate_mutations(REPO, path)

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_instret_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_metric_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["exception_zero_delta"] = 1
        temp_parent = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=temp_parent, prefix=".instret-validator-metric-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_instret_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)

    def test_arch_stable_validator_rejects_variant_cut(self) -> None:
        result = json.loads(RESULT.read_text(encoding="utf-8"))
        mutation = json.loads(MUTATION_SUMMARY.read_text(encoding="utf-8"))
        mutation["results"][0]["compile_success"] = False
        temp_parent = REPO / ".github/task-runs"
        with tempfile.TemporaryDirectory(
            dir=temp_parent, prefix=".instret-validator-variant-",
        ) as temp_name:
            temp = pathlib.Path(temp_name)
            mutation_path = temp / "summary.json"
            result_path = temp / "result.json"
            write_json(mutation_path, mutation)
            for item in result["artifacts"]:
                if item["kind"] == "rtl_mutation_summary":
                    item["path"] = mutation_path.relative_to(REPO).as_posix()
                    item["sha256"] = freeze.sha256_file(mutation_path)
            write_json(result_path, result)
            entry, design_id = ledger_entry(result_path)
            errors = freeze.validate_instret_debt(REPO, entry, design_id)
        self.assertTrue(any("source variants" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
