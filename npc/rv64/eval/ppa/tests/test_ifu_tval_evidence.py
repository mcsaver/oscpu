#!/usr/bin/env python3
"""Fail-closed tests for local RV64 IFU-TVAL-G1 evidence."""

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
    "ifu_tval_evidence_under_test", TOOLS / "ifu_tval_evidence.py")
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "ifu_tval_freeze_under_test", TOOLS / "arch_stable_freeze.py")
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
FOCUSED = TASK / "evidence/focused/logs"
DECODER_LOG = FOCUSED / "tb_ooo_fetch_packet_decode.log"
PAGE_END_LOG = FOCUSED / "tb_ooo_fetch_page_end_fault.log"
FIFO_LOG = FOCUSED / "tb_ooo_fetch_packet_fifo.log"
CAPTURE_LOG = FOCUSED / "tb_ooo_pending_lane1_capture_gate.log"
ARBITER_LOG = FOCUSED / "tb_ooo_pending_dispatch_arbiter.log"
PENDING_LOG = FOCUSED / "tb_ooo_pending_trap_exit_sequencer.log"
CSR_LOG = FOCUSED / "tb_ooo_csr_trap_request_mux.log"
LIFECYCLE_LOG = FOCUSED / "tb_ooo_ifu_lane1_fault_owner.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/ifu-tval-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/ifu-tval.log"
RUNNER = evidence.variant_model


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "ifu_tval_result",
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


class IfuTvalEvidenceTests(unittest.TestCase):
    def test_live_focused_logs_are_exact(self) -> None:
        self.assertEqual(
            evidence.parse_decoder_log(DECODER_LOG), evidence.DECODER_METRICS)
        self.assertEqual(
            evidence.parse_page_end_log(PAGE_END_LOG), evidence.PAGE_END_METRICS)
        self.assertEqual(evidence.parse_fifo_log(FIFO_LOG), evidence.FIFO_METRICS)
        self.assertEqual(
            evidence.parse_stage_logs(
                CAPTURE_LOG, ARBITER_LOG, PENDING_LOG, CSR_LOG),
            evidence.STAGE_METRICS,
        )
        lifecycle = evidence.parse_lifecycle_log(LIFECYCLE_LOG)
        self.assertEqual(lifecycle["fault_matrix"], evidence.LIFECYCLE_METRICS)
        self.assertEqual(
            lifecycle["compressed_control"], evidence.CONTROL_METRICS)
        self.assertEqual(
            lifecycle["dispatch_stall"], evidence.DISPATCH_STALL_METRICS)
        self.assertEqual(
            lifecycle["lifecycle_manifest"],
            evidence.EXPECTED_LIFECYCLE_MANIFEST)

    def test_lifecycle_row_cut_is_rejected(self) -> None:
        text = LIFECYCLE_LOG.read_text(encoding="utf-8").replace(
            "[TVAL-G1-LIFECYCLE] rows=24",
            "[TVAL-G1-LIFECYCLE] rows=23",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lifecycle.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "lifecycle aggregate"):
                evidence.parse_lifecycle_log(path)

    def test_compressed_control_cut_is_rejected(self) -> None:
        text = LIFECYCLE_LOG.read_text(encoding="utf-8").replace(
            "[TVAL-G1-COMPRESSED-CONTROL] rows=6",
            "[TVAL-G1-COMPRESSED-CONTROL] rows=5",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lifecycle.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "compressed-control aggregate"):
                evidence.parse_lifecycle_log(path)

    def test_lifecycle_joint_manifest_cut_is_rejected(self) -> None:
        text = LIFECYCLE_LOG.read_text(encoding="utf-8").replace(
            "PF U/U F6 F=6 cause=PF owner=L1",
            "PF U/U F6 F=6 cause=PF owner=L0",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lifecycle.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "joint manifest"):
                evidence.parse_lifecycle_log(path)

    def test_dispatch_stall_cut_is_rejected(self) -> None:
        text = LIFECYCLE_LOG.read_text(encoding="utf-8").replace(
            "[TVAL-G1-DISPATCH-STALL] rows=1 blocked=1",
            "[TVAL-G1-DISPATCH-STALL] rows=1 blocked=0",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lifecycle.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "dispatch-stall aggregate"):
                evidence.parse_lifecycle_log(path)

    def test_fifo_offset_cut_is_rejected(self) -> None:
        text = FIFO_LOG.read_text(encoding="utf-8").replace(
            "[TVAL-G1-FIFO-OFFSETS] F2=1 F4=1 F6=1",
            "[TVAL-G1-FIFO-OFFSETS] F2=1 F4=1 F6=0",
            1,
        )
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "fifo.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "FIFO offset aggregate"):
                evidence.parse_fifo_log(path)

    def test_normalizer_replaces_exact_transient_root(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix="rv64-ifu-tval-v9j.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = RUNNER.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(RUNNER.TRANSIENT_DIR_TOKEN), 1)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 12)
        self.assertEqual(audit["compile_success"], 12)
        self.assertEqual(audit["dynamic_rejected"], 12)
        self.assertEqual(
            sum(row["required"] for row in audit["by_source"].values()), 12)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])

    def test_live_static_contract_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertTrue(audit["decoder_computes_packet_frontier"])
        self.assertTrue(audit["frontend_projects_fifo_frontier"])
        self.assertTrue(audit["dispatch_barrier_fire_requires_head_acceptance"])
        self.assertTrue(audit["stop_has_no_fault_payload_ports"])
        self.assertTrue(audit["csr_request_selects_pending_tval"])

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_ifu_tval_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_lifecycle_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["fault_matrix"]["rows"] = 23
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".ifu-tval-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_ifu_tval_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
