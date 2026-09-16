#!/usr/bin/env python3
"""Fail-closed tests for local RV64 memory-transaction lifecycle evidence."""

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
    "memory_issue_lifecycle_evidence_under_test",
    TOOLS / "memory_issue_lifecycle_evidence.py",
)
assert EVIDENCE_SPEC is not None and EVIDENCE_SPEC.loader is not None
evidence = importlib.util.module_from_spec(EVIDENCE_SPEC)
sys.modules[EVIDENCE_SPEC.name] = evidence
EVIDENCE_SPEC.loader.exec_module(evidence)

FREEZE_SPEC = importlib.util.spec_from_file_location(
    "memory_issue_lifecycle_freeze_under_test",
    TOOLS / "arch_stable_freeze.py",
)
assert FREEZE_SPEC is not None and FREEZE_SPEC.loader is not None
freeze = importlib.util.module_from_spec(FREEZE_SPEC)
sys.modules[FREEZE_SPEC.name] = freeze
FREEZE_SPEC.loader.exec_module(freeze)

TASK = REPO / ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle"
MEM_LOG = TASK / "evidence/focused/mem-issue/logs/tb_ooo_int_backend.log"
MIQ_LOG = TASK / "evidence/focused/miq-flush/logs/tb_ooo_mem_inflight_queue.log"
MODULE_SUMMARY = TASK / "evidence/module-aggregate/summary.txt"
VARIANT_SUMMARY = TASK / "evidence/mutations/summary.json"
RESULT = REPO / "npc/rv64/eval/ppa/evidence/memory-issue-lifecycle-current.json"
RAW_LOG = REPO / "npc/rv64/eval/ppa/evidence/memory-issue-lifecycle.log"
RUNNER = evidence.variant_model


def synthetic_mem_log(*, identity_fields: int = 15) -> str:
    return (
        "[MEM-ISSUE-G1-PHASE0] pair_capture=2 terminal0_local=1 "
        "terminal1_hold=1 request_fire=0 miq_birth=0\n"
        "[MEM-ISSUE-G1-PHASE1] terminal0_empty=1 "
        "terminal1_request_fire=1 terminal1_consume=1 "
        "request_mux_owner=1 miq_birth=1 identity_match=1 "
        f"identity_fields={identity_fields}\n"
        "[MEM-ISSUE-G1-POST-LAUNCH] terminal_cleared=1 "
        "repeated_request_fire=0 repeated_miq_birth=0 miq_resident=1 "
        "quiet_cycles=3\n"
        "[MEM-ISSUE-G1-OWNER-ARBITRATION] other_request_fire=1 "
        "terminal1_hold=1 terminal1_consume=0 terminal1_birth=0 "
        "other_identity_match=1 identity_fields=5 "
        "terminal1_release_fire=1 PASS\n"
        "[MEM-ISSUE-G1-BACKPRESSURE] valid_hold_cycles=2 "
        "request_fire_while_blocked=0 terminal_consume_while_blocked=0 "
        "miq_birth_while_blocked=0 release_fire=1\n"
        "[MEM-ISSUE-G1-FOCUSED] pair_capture=2 terminal0_local=1 "
        "terminal1_hold=1 request_fire=1 terminal1_consume=1 miq_birth=1 "
        "identity_match=1 identity_fields=15 backpressure_hold=2 "
        "owner_arbitration=1 no_repeat=1 quiet_cycles=3 PASS\n"
        "[PASS] tb_ooo_int_backend\n"
        "[RESULT] PASS\n"
    )


def synthetic_miq_log(*, wrapped_order: int = 1) -> str:
    return (
        "[MIQ-FLUSH-G1-FOCUSED] consumed_drain_removed=1 "
        "stalled_head_no_pop_preserved=1 "
        "unconsumed_drain_preserved=1 survivor_identity_match=1 "
        f"wrapped_order={wrapped_order} PASS\n"
        "[PASS] tb_ooo_mem_inflight_queue\n"
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
                "kind": "memory_issue_lifecycle_result",
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


class MemoryIssueLifecycleEvidenceTests(unittest.TestCase):
    def test_exact_focused_markers_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            mem = temp / "mem.log"
            miq = temp / "miq.log"
            mem.write_text(synthetic_mem_log(), encoding="utf-8")
            miq.write_text(synthetic_miq_log(), encoding="utf-8")
            self.assertEqual(
                evidence.parse_mem_focused_log(mem)["phase1"]["identity_fields"],
                15,
            )
            self.assertEqual(
                evidence.parse_miq_focused_log(miq)["wrapped_order"], 1)

    def test_focused_semantic_cuts_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_name:
            temp = pathlib.Path(temp_name)
            mem = temp / "mem.log"
            miq = temp / "miq.log"
            mem.write_text(
                synthetic_mem_log(identity_fields=14), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_mem_focused_log(mem)
            miq.write_text(
                synthetic_miq_log(wrapped_order=0), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "event inventory"):
                evidence.parse_miq_focused_log(miq)

    def test_normalizer_replaces_exact_transient_root_and_rejects_token(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix="rv64-memory-lifecycle-v9f.", dir="/tmp",
        ) as temp_name:
            transient = pathlib.Path(temp_name)
            raw = f"[COMPILE] {transient}/build/test.vvp\n"
            normalized = RUNNER.normalize_transient_paths(raw, transient)
            self.assertNotIn(str(transient), normalized)
            self.assertEqual(normalized.count(RUNNER.TRANSIENT_DIR_TOKEN), 1)
            with self.assertRaisesRegex(ValueError, "already contains"):
                RUNNER.normalize_transient_paths(
                    normalized + f"\n{transient}\n", transient)

    def test_live_variants_reconstruct_and_reject(self) -> None:
        audit = evidence.validate_variants(REPO, VARIANT_SUMMARY)
        self.assertEqual(audit["required"], 11)
        self.assertEqual(audit["compile_success"], 11)
        self.assertEqual(audit["dynamic_rejected"], 11)
        self.assertEqual(audit["by_debt"]["MEM-ISSUE-G1"]["required"], 8)
        self.assertEqual(audit["by_debt"]["MIQ-FLUSH-G1"]["required"], 3)

    def test_live_variant_logs_have_no_random_temp_suffix(self) -> None:
        value = json.loads(VARIANT_SUMMARY.read_text(encoding="utf-8"))
        for row in value["results"]:
            log = REPO / row["log"]["path"]
            text = log.read_text(encoding="utf-8")
            self.assertNotIn("/tmp/rv64-v9f-", text, log)
            self.assertIn(RUNNER.TRANSIENT_DIR_TOKEN, text, log)

    def test_live_module_aggregate_is_exact_and_deterministic(self) -> None:
        aggregate = evidence.parse_module_aggregate(REPO, MODULE_SUMMARY)
        self.assertEqual(aggregate["required"], len(aggregate["tests"]))
        self.assertEqual(aggregate["passed"], aggregate["required"])
        for record in aggregate["tests"].values():
            text = (REPO / record["path"]).read_text(encoding="utf-8")
            self.assertNotIn("/tmp/rv64-memory-lifecycle-v9f.", text)
            self.assertIn(RUNNER.TRANSIENT_DIR_TOKEN, text)

    def test_drain_birth_topology_is_bound_to_request_fire(self) -> None:
        audit = evidence.validate_drain_birth_topology(REPO)
        self.assertTrue(audit["drain_birth_uses_sq_request_fire"])
        self.assertTrue(audit["sq_request_requires_exact_rob_head_launch_open"])

    def test_arch_stable_validator_accepts_live_evidence(self) -> None:
        entry, design_id = ledger_entry()
        self.assertEqual(
            freeze.validate_mem_issue_debt(REPO, entry, design_id), [])
        self.assertEqual(
            freeze.validate_miq_flush_debt(REPO, entry, design_id), [])

    def test_arch_stable_validator_rejects_identity_cut(self) -> None:
        value = json.loads(RESULT.read_text(encoding="utf-8"))
        value["metrics"]["mem_issue"]["phase1"]["identity_match"] = 0
        with tempfile.TemporaryDirectory(
            dir=REPO / ".github/task-runs", prefix=".memory-validator-",
        ) as temp_name:
            path = pathlib.Path(temp_name) / "result.json"
            write_json(path, value)
            entry, design_id = ledger_entry(path)
            errors = freeze.validate_mem_issue_debt(REPO, entry, design_id)
        self.assertTrue(any("metrics" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
