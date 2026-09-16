#!/usr/bin/env python3
"""SERIALIZE-G1 当前性判定器的定向单测。"""

from __future__ import annotations

import copy
import importlib.util
import sys
import unittest
from pathlib import Path


CHECKER = Path(__file__).with_name("check_serialize_current_evidence.py")
sys.path.insert(0, str(CHECKER.parent))
SPEC = importlib.util.spec_from_file_location("serialize_current_checker", CHECKER)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

ROOT = CHECKER.parents[4]
RUN = ROOT / ".github/task-runs/2026-08-01-rv64-v13h-serialize-fast-rebind-current"
QH = RUN / "evidence/qh-current/summary.json"
SYSTEM = RUN / "evidence/system-current/summary.json"
FUNCTIONAL = RUN / "evidence/functional-current/run-result.json"
LEGACY_FUNCTIONAL = ROOT / (
    ".github/task-runs/2026-08-01-rv64-v11y-full-core-current-cohort/"
    "evidence/functional-attempt-3-checker-replay-final/replay-result.json"
)
A3_RUN = ROOT / (
    ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
)
A3_STATUS = A3_RUN / "rootfs-c1b531-systemd-strict-6b-a3.status"
A3_BINDING = A3_RUN / "rootfs-c1b531-systemd-strict-6b-a3/binding.txt"
A3_TRANSACTION = A3_RUN / (
    "rootfs-c1b531-systemd-strict-6b-a3/systemd-transaction-evidence.json"
)
A3_REPLAY = ROOT / (
    ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/"
    "checker-replay-v2-evidence.json"
)


class CurrentEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.design_id = MODULE.common.current_design_id(ROOT)
        cls.queue_head = MODULE.load_object(QH)
        cls.system = MODULE.load_object(SYSTEM)
        cls.functional = MODULE.load_object(FUNCTIONAL)

    def test_queue_head_current_contract(self) -> None:
        MODULE.validate_queue_head(self.queue_head, self.design_id)

    def test_pending_system_current_contract(self) -> None:
        MODULE.validate_system(self.system, self.design_id)

    def test_queue_head_tb_wiring_class_is_bound(self) -> None:
        value = copy.deepcopy(self.queue_head)
        mutation = value["mutations"]["csrfile-request-c2-replay"]
        old_path = mutation["mutated"]["path"]
        new_path = old_path.rsplit("/", 1)[0] + "/OooRob.v"
        mutation["mutated"]["path"] = new_path
        profile = next(
            item for item in value["profiles"]
            if item["name"] == "mutation-csrfile-request-c2-replay"
        )
        dependency = next(
            item for item in profile["compile_input"]["dependencies"]
            if item["path"] == old_path
        )
        dependency["path"] = new_path
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_queue_head(value, self.design_id)

    def test_functional_current_contract(self) -> None:
        MODULE.validate_functional(
            self.functional,
            self.design_id,
            root=ROOT,
            summary_path=FUNCTIONAL,
        )

    def test_legacy_functional_replay_remains_accepted(self) -> None:
        legacy = MODULE.load_object(LEGACY_FUNCTIONAL)
        MODULE.validate_functional(legacy, legacy["design_id"])

    def test_direct_functional_input_drift_is_rejected(self) -> None:
        value = copy.deepcopy(self.functional)
        value["inputs"]["post"]["sha256"] = "0" * 64
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_functional(
                value, self.design_id, root=ROOT, summary_path=FUNCTIONAL
            )

    def test_direct_functional_retained_object_is_rejected(self) -> None:
        value = copy.deepcopy(self.functional)
        value["retention"]["compiled_intermediates_retained"] = 1
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_functional(
                value, self.design_id, root=ROOT, summary_path=FUNCTIONAL
            )

    def test_direct_functional_aggregate_hash_drift_is_rejected(self) -> None:
        value = copy.deepcopy(self.functional)
        value["artifacts"]["aggregate"]["sha256"] = "0" * 64
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_functional(
                value, self.design_id, root=ROOT, summary_path=FUNCTIONAL
            )

    def test_system_missing_mutation_is_rejected(self) -> None:
        value = copy.deepcopy(self.system)
        value["counts"]["dynamically_rejected_mutations"] = 13
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_system(value, self.design_id)

    def test_cleanup_copy_mismatch_is_rejected(self) -> None:
        value = copy.deepcopy(self.queue_head)
        value["cleanup"]["removed"] = 18
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_physical_receipts(ROOT, QH, value)

    def test_retained_log_hash_drift_is_rejected(self) -> None:
        value = copy.deepcopy(self.queue_head)
        value["profiles"][0]["result_log"]["sha256"] = "0" * 64
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_physical_receipts(ROOT, QH, value)

    def test_mutation_dependency_rebind_is_rejected(self) -> None:
        value = copy.deepcopy(self.system)
        mutation_profile = next(
            item for item in value["profiles"]
            if item["name"] == "disconnect-satp-mmu"
        )
        mutated_path = next(
            item["mutated"]["path"] for item in value["mutations"]
            if item["name"] == "disconnect-satp-mmu"
        )
        dependency = next(
            item for item in mutation_profile["compile_input"]["dependencies"]
            if item["path"] == mutated_path
        )
        dependency["sha256"] = "0" * 64
        with self.assertRaises(MODULE.DecisionError):
            MODULE.validate_system(value, self.design_id)

    def test_a3_original_fail_and_replay_contract(self) -> None:
        design_id = MODULE.validate_a3(
            status_path=A3_STATUS,
            binding_path=A3_BINDING,
            transaction=MODULE.load_object(A3_TRANSACTION),
            replay=MODULE.load_object(A3_REPLAY),
        )
        self.assertNotEqual(design_id, self.design_id)

    def test_decision_keeps_full_system_gap(self) -> None:
        decision = MODULE.build_decision(
            root=ROOT,
            queue_head_path=QH,
            system_path=SYSTEM,
            functional_path=FUNCTIONAL,
            a3_status_path=A3_STATUS,
            a3_binding_path=A3_BINDING,
            a3_transaction_path=A3_TRANSACTION,
            a3_replay_path=A3_REPLAY,
        )
        self.assertEqual(decision["ledger_status"], "STALE_EVIDENCE")
        self.assertTrue(decision["full_system_recertification"]["required"])
        self.assertFalse(
            decision["architecture_boundary"]["serialize_g1_current_design_bound"]
        )
        MODULE.validate_ledger_boundary(
            root=ROOT,
            ledger_path=ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json",
            decision_path=RUN / "currentness-decision.json",
            queue_head_path=QH,
            system_path=SYSTEM,
            decision=decision,
        )


if __name__ == "__main__":
    unittest.main()
