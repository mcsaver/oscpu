#!/usr/bin/env python3
"""Fail-closed tests for local RV64 IFU-FETCH-G2 evidence."""

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
    "ifu_fetch_provenance_evidence_under_test",
    TOOLS / "ifu_fetch_provenance_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "ifu_fetch_provenance_freeze_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
DECODE_LOG = TASK / "evidence/focused/logs/tb_ooo_fetch_packet_decode.log"
PAGE_LOG = TASK / "evidence/focused/logs/tb_ooo_fetch_page_end_fault.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/ifu-fetch-provenance-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/ifu-fetch-provenance.log"
RUNNER = evidence.variant_model


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
                "kind": "ifu_fetch_provenance_result",
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


class IfuFetchProvenanceEvidenceTests(unittest.TestCase):
    def test_live_focused_logs_are_exact(self) -> None:
        self.assertEqual(evidence.parse_page_log(PAGE_LOG), evidence.PAGE_METRICS)
        self.assertEqual(
            evidence.parse_decode_log(DECODE_LOG), evidence.DECODE_METRICS)

    def test_page_summary_cut_is_rejected(self) -> None:
        text = PAGE_LOG.read_text(encoding="utf-8").replace(
            "[G2-CURRENT-DESIGN] matrix_rows=13",
            "[G2-CURRENT-DESIGN] matrix_rows=12",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "page.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "inventory drifted"):
                evidence.parse_page_log(path)

    def test_positive_control_cut_is_rejected(self) -> None:
        text = PAGE_LOG.read_text(encoding="utf-8").replace(
            "[G2-POSITIVE-CONTROL] instruction_ar=4 cache_fill=1",
            "[G2-POSITIVE-CONTROL] instruction_ar=4 cache_fill=0",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "page.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "positive control"):
                evidence.parse_page_log(path)

    def test_decode_f0_cut_is_rejected(self) -> None:
        text = DECODE_LOG.read_text(encoding="utf-8").replace(
            "[G2-DECODE-F0] split=0 resp=2/2",
            "[G2-DECODE-F0] split=0 resp=0/2",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "decode.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "decode F0"):
                evidence.parse_decode_log(path)

    def test_normalizer_replaces_exact_transient_root(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix="rv64-ifu-fetch-v9h.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = RUNNER.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(RUNNER.TRANSIENT_DIR_TOKEN), 1)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 16)
        self.assertEqual(audit["compile_success"], 16)
        self.assertEqual(audit["dynamic_rejected"], 16)
        self.assertEqual(
            audit["by_source"],
            {
                "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v": {
                    "required": 8,
                    "compile_success": 8,
                    "dynamic_rejected": 8,
                },
                "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v": {
                    "required": 8,
                    "compile_success": 8,
                    "dynamic_rejected": 8,
                },
            },
        )

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])

    def test_live_static_contract_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertEqual(audit, evidence.validate_static_contract(REPO))
        self.assertTrue(audit["page_tb_independent_frontier_reference"])
        self.assertTrue(audit["page_tb_positive_monitor_is_non_vacuous"])

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_ifu_fetch_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_fault_row_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["page_end"]["fault_rows"] = 8
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".ifu-fetch-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_ifu_fetch_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
