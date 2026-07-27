#!/usr/bin/env python3
"""Fail-closed tests for local RV64 PTW-PMP-G1 evidence."""

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

SPEC = importlib.util.spec_from_file_location(
    "ptw_pmp_evidence_under_test", TOOLS / "ptw_pmp_evidence.py")
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = evidence
SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "ptw_pmp_freeze_under_test", TOOLS / "arch_stable_freeze.py")
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
FOCUSED = TASK / "evidence/focused/logs"
IFU_LOG = FOCUSED / "tb_ooo_fetch_axi_bridge.log"
LSU_LOG = FOCUSED / "tb_ooo_mem_axi_bridge.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/ptw-pmp.log"


def ledger_entry(result_path: pathlib.Path = RESULT) -> tuple[dict, str]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    return ({
        "canonical_command": evidence.CANONICAL_COMMAND,
        "evidence": [
            {
                "kind": "ptw_pmp_result",
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


class PtwPmpEvidenceTests(unittest.TestCase):
    def test_live_focused_logs_are_exact(self) -> None:
        ifu = evidence.parse_ifu_log(IFU_LOG)
        lsu = evidence.parse_lsu_log(LSU_LOG)
        self.assertEqual(
            ifu["frontier_manifest"], evidence.EXPECTED_IFU_FRONTIERS)
        self.assertEqual(lsu["deny_manifest"], evidence.EXPECTED_LSU_DENIES)
        self.assertEqual(lsu["allow_manifest"], evidence.EXPECTED_LSU_ALLOWS)

    def test_ifu_frontier_cut_is_rejected(self) -> None:
        text = IFU_LOG.read_text(encoding="utf-8").replace(
            "frontier=6 read=allow write=deny prefix=6",
            "frontier=6 read=allow write=deny prefix=4", 1)
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "ifu.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "F2/F4/F6"):
                evidence.parse_ifu_log(path)

    def test_lsu_owner_cut_is_rejected(self) -> None:
        text = LSU_LOG.read_text(encoding="utf-8").replace(
            "access-fault aw=0 w=0 owner=stable",
            "access-fault aw=0 w=0 owner=live", 1)
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lsu.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "deny manifest"):
                evidence.parse_lsu_log(path)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 28)
        self.assertEqual(audit["compile_success"], 28)
        self.assertEqual(audit["dynamic_rejected"], 28)
        self.assertEqual(set(audit["by_source"]), {
            "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        })

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], aggregate["passed"])

    def test_live_static_contract_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertTrue(audit)
        self.assertTrue(all(audit.values()))

    def test_lsu_response_delay_sweep_cut_is_rejected(self) -> None:
        text = LSU_LOG.read_text(encoding="utf-8").replace(
            "response-delay=5 awready=1 wready=1",
            "response-delay=4 awready=1 wready=1", 1)
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lsu.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "deny manifest"):
                evidence.parse_lsu_log(path)

    def test_lsu_deny_temporal_monitor_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertTrue(audit["lsu_tb_tracks_deny_until_response_terminal"])
        self.assertTrue(audit["lsu_tb_asserts_pending_deny_aw_w_quiet"])
        self.assertTrue(audit["lsu_tb_keeps_awready_wready_high"])

    def test_lsu_unbounded_deny_quiet_structure_is_fail_closed(self) -> None:
        path = REPO / "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
        text = path.read_text(encoding="utf-8")
        certificate = evidence.validate_lsu_unbounded_deny_quiet_structure(text)
        self.assertEqual(certificate["cycle_bound"], "unbounded_by_state_decode")
        self.assertFalse(certificate["response_state_in_awvalid_decode"])
        self.assertTrue(certificate["c0_barrier_holds_queued_advance"])
        mutant = text.replace(
            evidence.LSU_AW_VALID_ASSIGN,
            evidence.LSU_AW_VALID_ASSIGN[:-1]
            + " ||\n      (state_q == S_RESP);",
            1,
        )
        with self.assertRaisesRegex(ValueError, "unbounded deny-quiet"):
            evidence.validate_lsu_unbounded_deny_quiet_structure(mutant)

    def test_lsu_split_order_cut_is_rejected(self) -> None:
        text = LSU_LOG.read_text(encoding="utf-8").replace(
            "op=load read=allow write=allow checker=grant ad_update=1 "
            "awaddr=checked aw=once w=once awsize=3 split=w-first",
            "op=load read=allow write=allow checker=grant ad_update=1 "
            "awaddr=checked aw=once w=once awsize=3 split=aw-first", 1)
        with tempfile.TemporaryDirectory() as temp_name:
            path = pathlib.Path(temp_name) / "lsu.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "allow manifest"):
                evidence.parse_lsu_log(path)

    def test_normalizer_replaces_exact_transient_root(self) -> None:
        runner = evidence.variant_model
        with tempfile.TemporaryDirectory(
            prefix="rv64-ptw-pmp-v9k.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = runner.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(runner.TRANSIENT_DIR_TOKEN), 1)

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_ptw_pmp_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_frontier_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["ifu"]["deny_frontier_rows"] = 2
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".ptw-pmp-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            path.write_text(
                json.dumps(value, indent=2, sort_keys=True) + "\n",
                encoding="utf-8")
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_ptw_pmp_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
