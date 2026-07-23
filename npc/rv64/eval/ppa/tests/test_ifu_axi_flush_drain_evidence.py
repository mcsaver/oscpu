#!/usr/bin/env python3
"""Fail-closed tests for local RV64 IFU AXI flush/drain evidence."""

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
    "ifu_axi_flush_drain_evidence_under_test",
    TOOLS / "ifu_axi_flush_drain_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "ifu_axi_flush_drain_freeze_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / f".github/task-runs/{evidence.RUN_ID}"
BRIDGE_LOG = TASK / "evidence/focused/logs/tb_ooo_fetch_axi_bridge.log"
XBAR_LOG = TASK / "evidence/focused/logs/tb_ooo_fetch_axi_bridge_xbar.log"
GENERIC_XBAR_LOG = TASK / "evidence/focused/logs/tb_axi_xbar.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log"
RUNNER = evidence.variant_model


def synthetic_bridge_log(*, all_fire: int = 1) -> str:
    return (
        "[IFU-AXI-G1-FOCUSED] aw_first=1 w_first=1 "
        "first_aw_with_flush=1 first_w_with_flush=1 "
        "last_aw_b_with_flush=1 last_w_b_with_flush=1 "
        f"all_aw_w_b_with_flush={all_fire} both_done_flush_b_error=1 "
        "both_stalled_flush_cycles=2 dropped_bresp_error=1 "
        "normal_bresp_error=1 payload_stability=1 drop_quiet=1 PASS\n"
        "[PASS] tb_ooo_fetch_axi_bridge\n"
        "[RESULT] PASS\n"
    )


def synthetic_xbar_integration_log(*, progress: int = 1) -> str:
    return (
        "[IFU-AXI-G1-XBAR] ifu_b_owner_release=1 "
        f"later_master_progress={progress} later_master_payload=1 "
        "later_master_b=1 PASS\n"
        "[PASS] tb_ooo_fetch_axi_bridge_xbar\n"
        "[RESULT] PASS\n"
    )


def synthetic_xbar_backpressure_log(*, early_release: int = 0) -> str:
    return (
        "[IFU-AXI-G1-XBAR-BACKPRESSURE] bvalid_hold_cycles=2 "
        f"early_release={early_release} aw_first=1 w_first=1 "
        "payload_stability=1 PASS\n"
        "[PASS] tb_axi_xbar\n"
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
                "kind": "ifu_axi_flush_drain_result",
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


class IfuAxiFlushDrainEvidenceTests(unittest.TestCase):
    def test_exact_focused_markers_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            bridge = temp / "bridge.log"
            xbar = temp / "xbar.log"
            generic = temp / "generic.log"
            bridge.write_text(synthetic_bridge_log(), encoding="utf-8")
            xbar.write_text(
                synthetic_xbar_integration_log(), encoding="utf-8")
            generic.write_text(
                synthetic_xbar_backpressure_log(), encoding="utf-8")
            self.assertEqual(evidence.parse_bridge_log(bridge),
                             evidence.BRIDGE_METRICS)
            self.assertEqual(evidence.parse_xbar_integration_log(xbar),
                             evidence.XBAR_INTEGRATION_METRICS)
            self.assertEqual(evidence.parse_xbar_backpressure_log(generic),
                             evidence.XBAR_BACKPRESSURE_METRICS)

    def test_focused_semantic_cuts_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            bridge = temp / "bridge.log"
            xbar = temp / "xbar.log"
            generic = temp / "generic.log"
            bridge.write_text(
                synthetic_bridge_log(all_fire=0), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_bridge_log(bridge)
            xbar.write_text(
                synthetic_xbar_integration_log(progress=0), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_xbar_integration_log(xbar)
            generic.write_text(
                synthetic_xbar_backpressure_log(early_release=1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_xbar_backpressure_log(generic)

    def test_normalizer_replaces_exact_transient_root(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix="rv64-ifu-axi-v9g.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = RUNNER.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(RUNNER.TRANSIENT_DIR_TOKEN), 1)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 18)
        self.assertEqual(audit["compile_success"], 18)
        self.assertEqual(audit["dynamic_rejected"], 18)
        self.assertEqual(
            sum(row["required"] for row in audit["by_source"].values()), 18)

    def test_live_module_aggregate_is_exact(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])

    def test_live_static_contract_is_bound(self) -> None:
        audit = evidence.validate_static_contract(REPO)
        self.assertTrue(audit["bridge_completion_uses_both_accepted_next_values"])
        self.assertTrue(audit["xbar_release_requires_exact_b_fire"])

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_ifu_axi_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_all_fire_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["bridge"]["all_aw_w_b_with_flush"] = 0
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".ifu-axi-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_ifu_axi_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
