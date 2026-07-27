#!/usr/bin/env python3
"""Fail-closed tests for local RV64 FENCE-G1 ordering evidence."""

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
    "fence_ordering_evidence_under_test",
    TOOLS / "fence_ordering_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "fence_arch_stable_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
PROGRAM_LOG = TASK / "evidence/focused/logs/tb_ooo_priv_system.log"
DRAIN_GATE_LOG = (
    TASK / "evidence/focused/logs/tb_ooo_pending_drain_resolve_gate.log")
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/rtl-variants/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/fence-ordering-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/fence-ordering.log"


def synthetic_program_log(
    *, full_memory_wait: int = 1, early_device: int = 0,
) -> str:
    return (
        "[FENCE-G1-PROGRAM] exit=1 ebreak=1 trap=0 "
        f"lane1_capture=1 full_memory_wait={full_memory_wait} "
        "mem_idle_binding=1 "
        "fence_commit=1 store_probe=1 store_drain=1 device_read=1 "
        "fence_before_store=0 device_before_store=0 "
        f"device_before_fence={early_device} readback_match=1 "
        "backend_drained=1 PASS\n"
        "[PASS] tb_ooo_priv_system\n"
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
                "kind": "fence_ordering_result",
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


class FenceOrderingEvidenceTests(unittest.TestCase):
    def test_exact_program_inventory_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "program.log"
            path.write_text(synthetic_program_log(), encoding="utf-8")
            parsed = evidence.parse_program_log(path)
        self.assertEqual(parsed, evidence.PROGRAM_METRICS)

    def test_program_wait_or_ordering_cut_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "program.log"
            path.write_text(
                synthetic_program_log(full_memory_wait=0), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "ordering inventory"):
                evidence.parse_program_log(path)
            path.write_text(
                synthetic_program_log(early_device=1), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "ordering inventory"):
                evidence.parse_program_log(path)

    def test_live_rtl_variant_reconstructs_and_is_rejected(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["compile_success"], 2)
        self.assertEqual(audit["dynamic_rejected"], 2)
        self.assertEqual(len(audit["variants"]), 2)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        required = len(evidence.required_module_tests(
            REPO / "npc/rv64/testbench/Makefile"))
        self.assertEqual(aggregate["required"], required)
        self.assertEqual(aggregate["passed"], required)
        self.assertEqual(aggregate["failed"], 0)

    def test_variant_aggregate_cut_is_rejected(self) -> None:
        value = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        value["compile_success"] = 0
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "summary.json"
            write_json(path, value)
            with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
                evidence.validate_variants(REPO, path)

    def test_positive_log_requires_compile_and_runtime_design_id(self) -> None:
        text = (
            "[COMPILE] iverilog local-source-list\n"
            "[PASS] tb_ooo_priv_system\n"
            "[RESULT] PASS\n"
        )
        evidence.require_pass_log(
            text, "tb_ooo_priv_system", "synthetic", require_compile=True)
        with self.assertRaisesRegex(ValueError, "design-id marker"):
            evidence.require_design_marker(
                text, "sha256:" + "0" * 64, "synthetic")
        with self.assertRaisesRegex(ValueError, "COMPILE"):
            evidence.require_pass_log(
                text.replace("[COMPILE] iverilog local-source-list\n", ""),
                "tb_ooo_priv_system", "synthetic", require_compile=True)
        with self.assertRaisesRegex(ValueError, "CHECK-FAIL"):
            evidence.require_pass_log(
                text + "[CHECK-FAIL] unrelated got=1 expected=0\n",
                "tb_ooo_priv_system", "synthetic", require_compile=True)
        with self.assertRaisesRegex(ValueError, "ERROR"):
            evidence.require_pass_log(
                text + "ERROR: unrelated simulator diagnostic\n",
                "tb_ooo_priv_system", "synthetic", require_compile=True)

    def test_variant_log_without_compile_line_is_rejected(self) -> None:
        value = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        row = value["results"][0]
        original = REPO / row["log"]["path"]
        lines = [
            line for line in original.read_text(encoding="utf-8").splitlines()
            if not line.startswith("[COMPILE] ")]
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".fence-log-compile-",
        ) as temp_name:
            temp = pathlib.Path(temp_name)
            log_path = temp / "variant.log"
            log_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
            row["log"] = {
                "path": log_path.relative_to(REPO).as_posix(),
                "sha256": evidence.sha256_file(log_path),
            }
            summary = temp / "summary.json"
            write_json(summary, value)
            with self.assertRaisesRegex(ValueError, "stale or incomplete"):
                evidence.validate_variants(REPO, summary)

    def test_variant_log_with_extra_check_failure_is_rejected(self) -> None:
        value = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        row = value["results"][0]
        original = REPO / row["log"]["path"]
        text = original.read_text(encoding="utf-8")
        text += "[CHECK-FAIL] unrelated owner got=1 expected=0\n"
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".fence-log-extra-",
        ) as temp_name:
            temp = pathlib.Path(temp_name)
            log_path = temp / "variant.log"
            log_path.write_text(text, encoding="utf-8")
            row["log"] = {
                "path": log_path.relative_to(REPO).as_posix(),
                "sha256": evidence.sha256_file(log_path),
            }
            summary = temp / "summary.json"
            write_json(summary, value)
            with self.assertRaisesRegex(ValueError, "stale or incomplete"):
                evidence.validate_variants(REPO, summary)

    def test_variant_log_requires_exact_target_errors_and_status(self) -> None:
        base_variant = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        base_result = json.loads(RESULT.read_text(encoding="utf-8"))
        base_row = base_variant["results"][0]
        base_log = (
            REPO / base_row["log"]["path"]
        ).read_text(encoding="utf-8")
        cases = (
            (
                "target-tail",
                base_row["expected_marker"] + "\n",
                base_row["expected_marker"] + " unexpected-tail\n",
            ),
            (
                "errors-count",
                f"[FAIL] {base_row['test_name']} errors=1\n",
                f"[FAIL] {base_row['test_name']} errors=2\n",
            ),
            ("result-status", "[RESULT] FAIL status=1\n",
             "[RESULT] FAIL status=7\n"),
        )
        for case_name, old, new in cases:
            with self.subTest(case=case_name), tempfile.TemporaryDirectory(
                dir=REPO / ".github/task-runs",
                prefix=f".fence-log-exact-{case_name}-",
            ) as temp_name:
                self.assertEqual(base_log.count(old), 1)
                temp = pathlib.Path(temp_name)
                log_path = temp / "variant.log"
                log_path.write_text(
                    base_log.replace(old, new, 1), encoding="utf-8")

                variant = json.loads(json.dumps(base_variant))
                variant["results"][0]["log"] = {
                    "path": log_path.relative_to(REPO).as_posix(),
                    "sha256": evidence.sha256_file(log_path),
                }
                variant_path = temp / "summary.json"
                write_json(variant_path, variant)
                with self.assertRaisesRegex(ValueError, "stale or incomplete"):
                    evidence.validate_variants(REPO, variant_path)

                result = json.loads(json.dumps(base_result))
                for item in result["artifacts"]:
                    if item["kind"] == "rtl_variant_summary":
                        item["path"] = variant_path.relative_to(REPO).as_posix()
                        item["sha256"] = freeze.sha256_file(variant_path)
                result_path = temp / "result.json"
                write_json(result_path, result)
                entry, design_id = ledger_entry(result_path)
                errors = freeze.validate_fence_debt(REPO, entry, design_id)
                self.assertTrue(
                    any("RTL source variants" in error for error in errors),
                    errors,
                )

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(freeze.validate_fence_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_metric_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["full_memory_wait"] = 0
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".fence-validator-metric-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_fence_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)

    def test_arch_stable_validator_rejects_variant_cut(self) -> None:
        result = json.loads(RESULT.read_text(encoding="utf-8"))
        variant = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        variant["results"][0]["compile_success"] = False
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".fence-validator-variant-",
        ) as temp_name:
            temp = pathlib.Path(temp_name)
            variant_path = temp / "summary.json"
            result_path = temp / "result.json"
            write_json(variant_path, variant)
            for item in result["artifacts"]:
                if item["kind"] == "rtl_variant_summary":
                    item["path"] = variant_path.relative_to(REPO).as_posix()
                    item["sha256"] = freeze.sha256_file(variant_path)
            write_json(result_path, result)
            entry, design_id = ledger_entry(result_path)
            errors = freeze.validate_fence_debt(REPO, entry, design_id)
        self.assertTrue(any("RTL source variants" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
