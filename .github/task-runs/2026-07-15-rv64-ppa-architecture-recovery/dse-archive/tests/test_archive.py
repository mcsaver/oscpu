#!/usr/bin/env python3

from __future__ import annotations

import copy
import hashlib
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ARCHIVE_DIR = Path(__file__).resolve().parents[1]
REAL_ROOT = ARCHIVE_DIR.parents[3]
sys.path.insert(0, str(ARCHIVE_DIR))

from check_archive import Checker, EVALUATION_ORDER, GATES, event_sha, sha256_file  # noqa: E402


def dump_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


class ArchiveCheckerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / ".git").mkdir()
        self.registry = json.loads((ARCHIVE_DIR / "registry.json").read_text(encoding="utf-8"))
        # 生产 registry 会持续 append；focused tests 固定从显式空 archive 开始。
        self.registry.update(
            architecture_feasible_seed_id=None,
            canonical_design_id=None,
            ppa_champion_design_id=None,
            point_manifests=[],
            formal_promotions=[],
            scalar_ranking=[],
        )
        self.registry["pools"] = {name: [] for name in self.registry["pools"]}
        self.registry["engineering_proxy_archive"]["members"] = []
        refs = list(self.registry["bindings"])
        refs += [
            self.registry["required_test_inventory_contract"]["normative_policy"],
            self.registry["required_test_inventory_contract"]["development_makefile"],
        ]
        for ref in refs:
            source = REAL_ROOT / ref["path"]
            target = self.root / ref["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        self.ledger_path = self.root / "dse/ledger.jsonl"
        self.ledger_path.parent.mkdir(parents=True)
        shutil.copyfile(ARCHIVE_DIR / "tests/fixtures/initial-ledger.jsonl", self.ledger_path)
        self.registry["ledger"]["path"] = "dse/ledger.jsonl"
        self.registry_path = self.root / "dse/registry.json"
        self._sync_ledger_meta()
        self._write_registry()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _write_registry(self) -> None:
        dump_json(self.registry_path, self.registry)

    def _events(self) -> list[dict[str, object]]:
        return [json.loads(line) for line in self.ledger_path.read_text(encoding="utf-8").splitlines()]

    def _sync_ledger_meta(self) -> None:
        events = self._events()
        self.registry["ledger"].update(
            sha256=sha256_file(self.ledger_path),
            event_count=len(events),
            head_event_sha256=events[-1]["event_sha256"],
        )
        count = 0
        last_thaw = None
        for event in events:
            if event["event_type"] == "complete_point_evaluated":
                count += 1
            elif event["event_type"] == "global_thaw_opened":
                count = 0
                last_thaw = event["event_sha256"]
        self.registry["global_thaw"].update(
            completed_points_since_last_thaw=count,
            thaw_due=(count == 4),
            last_thaw_event_sha256=last_thaw,
        )

    def _append_event(self, event_type: str, design_id: str | None, payload: dict | None = None) -> str:
        events = self._events()
        event = {
            "event_schema": "rv64-dse-ledger-event-v1",
            "sequence": len(events),
            "timestamp_utc": f"2026-07-16T06:{len(events):02d}:00Z",
            "event_type": event_type,
            "actor": "unit-test",
            "design_id": design_id,
            "previous_event_sha256": events[-1]["event_sha256"],
            "payload": payload or {},
        }
        event["event_sha256"] = event_sha(event)
        with self.ledger_path.open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(event, sort_keys=True, separators=(",", ":")) + "\n")
        self._sync_ledger_meta()
        return event["event_sha256"]

    def _artifact(self, stem: str, content: bytes = b"evidence\n", addressed: bool = False) -> dict:
        digest = hashlib.sha256(content).hexdigest()
        name = f"{digest}.{stem}" if addressed else stem
        path = self.root / "dse/artifacts" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return {"path": str(path.relative_to(self.root)), "sha256": digest}

    def _register_point(self, point: dict, pools: tuple[str, ...] = ()) -> None:
        encoded = (json.dumps(point, indent=2, sort_keys=True) + "\n").encode()
        digest = hashlib.sha256(encoded).hexdigest()
        path = self.root / "dse/points" / f"{digest}.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(encoded)
        self.registry["point_manifests"].append(
            {"design_id": point["design_id"], "path": str(path.relative_to(self.root)), "sha256": digest}
        )
        for pool in pools:
            self.registry["pools"][pool].append(point["design_id"])

    def _intermediate(self, design_id: str = "s1-checkpoint") -> dict:
        event = self._append_event("checkpoint_recorded", design_id)
        return {
            "schema": "rv64-dse-design-point-v1",
            "design_id": design_id,
            "state": "intermediate_checkpoint",
            "role": "development_checkpoint",
            "architecture_feasible": False,
            "parent_seed_id": None,
            "completion_definition": {"completion_conditions": ["focused correctness"]},
            "hard_gates": {},
            "objectives": {
                axis: {"qualification": "unqualified", "value": None}
                for axis in ("performance", "area", "power")
            },
            "evidence": [],
            "next_compensation_experiment": "continue S2 owner/token/epoch recovery",
            "ledger_event_sha256": event,
        }

    def _complete(self, design_id: str | None = None, core_ratio: float = 1.0) -> dict:
        artifact = self._artifact("evidence.txt")
        snapshot = self._artifact("bundle", b"immutable source bundle\n", addressed=True)
        snapshot["immutable"] = True
        design_id = design_id or f"sha256:{snapshot['sha256']}"
        event = self._append_event("complete_point_evaluated", design_id)
        tests = {"schema": "rv64-required-test-inventory-v1", "tests": [f"tb_{i}" for i in range(103)]}
        inventory_bytes = (json.dumps(tests, sort_keys=True) + "\n").encode()
        inventory = self._artifact("json", inventory_bytes, addressed=True)
        inventory["derived_test_count"] = 103
        evidence = []
        for gate in GATES:
            evidence.append({"kind": f"hard_gate:{gate}", **artifact})
        evidence.extend(
            [
                {"kind": "workload:coremark", **artifact},
                {"kind": "workload:dhrystone_10000", **artifact},
            ]
        )
        minimum = min(core_ratio, 1.0)
        feasible = minimum >= 0.995
        return {
            "schema": "rv64-dse-design-point-v1",
            "design_id": design_id,
            "state": "complete_design_point",
            "role": "seed_candidate",
            "architecture_feasible": feasible,
            "parent_seed_id": None,
            "completion_definition": {"completion_conditions": ["all coordinated slices integrated"]},
            "evaluation_order": list(EVALUATION_ORDER),
            "immutable_source_snapshot": snapshot,
            "required_test_inventory": inventory,
            "hard_gates": {gate: "pass" for gate in GATES},
            "per_workload_metrics": {
                "coremark": {"throughput_ratio": core_ratio, "retired_instructions": 3183617},
                "dhrystone_10000": {"throughput_ratio": 1.0, "retired_instructions": 4250000},
            },
            "worst_workload": {"name": "coremark", "throughput_ratio": minimum},
            "objectives": {
                "performance": {
                    "qualification": "qualified",
                    "aggregation": "worst_case_min_ratio",
                    "value": minimum,
                },
                "area": {"qualification": "qualified", "scope": "logic_proxy", "value": 1600000.0},
                "power": {
                    "qualification": "unqualified",
                    "value": None,
                    "activity_coverage": 0.0,
                    "macro_model_complete": False,
                },
            },
            "evidence": evidence,
            "next_compensation_experiment": "none",
            "ledger_event_sha256": event,
        }

    def _check(self) -> list[str]:
        self._write_registry()
        checker = Checker(self.registry_path, self.root)
        checker.check_registry()
        return checker.errors

    def test_initial_registry_is_explicitly_empty_and_valid(self) -> None:
        self.assertEqual([], self._check())
        self.assertIsNone(self.registry["architecture_feasible_seed_id"])
        self.assertEqual([], self.registry["pools"]["feasible_pareto"])

    def test_shipped_schemas_are_parseable_json(self) -> None:
        schemas = sorted((ARCHIVE_DIR / "schemas").glob("*.json"))
        self.assertEqual(4, len(schemas))
        for schema in schemas:
            self.assertIsInstance(json.loads(schema.read_text(encoding="utf-8")), dict)

    def test_intermediate_cannot_enter_pareto(self) -> None:
        point = self._intermediate()
        self._register_point(point, ("development", "feasible_pareto"))
        errors = self._check()
        self.assertTrue(any("intermediate checkpoint cannot enter feasible_pareto" in error for error in errors))

    def test_unqualified_power_cannot_enter_formal_front(self) -> None:
        point = self._complete()
        self._register_point(point, ("feasible_pareto",))
        errors = self._check()
        self.assertTrue(any("qualified three-axis front" in error for error in errors))

    def test_worst_workload_cannot_be_hidden_by_average(self) -> None:
        point = self._complete(core_ratio=0.99)
        point["worst_workload"] = {"name": "dhrystone_10000", "throughput_ratio": 1.0}
        self._register_point(point, ("development",))
        errors = self._check()
        self.assertTrue(any("worst_workload must equal" in error for error in errors))

    def test_complete_point_requires_content_addressed_snapshot(self) -> None:
        point = self._complete()
        point["immutable_source_snapshot"] = None
        self._register_point(point)
        errors = self._check()
        self.assertTrue(any("requires immutable source snapshot" in error for error in errors))

    def test_complete_design_id_must_bind_snapshot_sha(self) -> None:
        point = self._complete()
        point["design_id"] = "forged-name"
        self._register_point(point)
        errors = self._check()
        self.assertTrue(any("complete design_id must equal sha256" in error for error in errors))

    def test_qualified_power_rejects_non_numeric_activity_coverage(self) -> None:
        point = self._complete()
        point["objectives"]["power"].update(
            qualification="qualified",
            value=0.1,
            activity_coverage=None,
            macro_model_complete=True,
        )
        self._register_point(point)
        errors = self._check()
        self.assertTrue(any("activity_coverage must be finite numeric" in error for error in errors))

    def test_intermediate_objective_branch_requires_common_seed(self) -> None:
        point = self._intermediate()
        point["role"] = "performance_branch"
        self._register_point(point, ("development",))
        errors = self._check()
        self.assertTrue(any("must bind the common feasible seed" in error for error in errors))

    def test_seed_transition_cannot_directly_be_champion(self) -> None:
        point = self._complete()
        point["role"] = "architecture_feasible_seed"
        self._register_point(point)
        self.registry["architecture_feasible_seed_id"] = point["design_id"]
        self.registry["ppa_champion_design_id"] = point["design_id"]
        errors = self._check()
        self.assertTrue(any("cannot be the one-time architecture-feasible seed" in error for error in errors))

    def test_four_complete_events_make_thaw_due_and_block_fifth_event(self) -> None:
        for index in range(4):
            self._append_event("complete_point_evaluated", f"p{index}")
        self.assertEqual([], self._check())
        self._append_event("checkpoint_recorded", "too-late-checkpoint")
        errors = self._check()
        self.assertTrue(any("global thaw is due before another ledger event" in error for error in errors))

    def test_ledger_tamper_is_detected(self) -> None:
        text = self.ledger_path.read_text(encoding="utf-8").replace("Initial fail-closed", "Tampered")
        self.ledger_path.write_text(text, encoding="utf-8")
        self._sync_ledger_meta()
        errors = self._check()
        self.assertTrue(any("event_sha256 mismatch" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
