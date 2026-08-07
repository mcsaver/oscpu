#!/usr/bin/env python3
"""Directed sensitivity tests for architecture-debt RTL delta rebinding."""

from __future__ import annotations

import copy
import hashlib
import importlib.util
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL_PATH = ROOT / "npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py"
SPEC = importlib.util.spec_from_file_location(
    "architecture_debt_delta_rebind_tested", TOOL_PATH
)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class ArchitectureDebtDeltaRebindTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.receipt = TOOL.build_receipt(ROOT)
        cls.layered = TOOL.load_json(ROOT, TOOL.LAYERED_SIGNOFF)
        _, _, _, current_manifest = TOOL.current_l0_inputs(
            ROOT, cls.layered
        )
        cls.baseline, cls.current = TOOL.manifests(ROOT, current_manifest)

    def test_manifest_derived_delta_and_current_identity(self) -> None:
        baseline = self.baseline["files"]
        current = self.current["groups"]["rtl"]
        expected_changed = {
            path for path in baseline if baseline[path] != current[path]
        }
        self.assertEqual(
            {row["path"] for row in self.receipt["rtl_delta"]["changed_files"]},
            expected_changed,
        )
        self.assertEqual(self.receipt["rtl_delta"]["file_count"], 146)
        self.assertRegex(
            self.receipt["current_design_id"], r"^sha256:[0-9a-f]{64}$"
        )

    def test_all_historical_items_are_classified(self) -> None:
        historical = self.receipt["historical_negative"]
        self.assertEqual(historical["total"], 175)
        self.assertEqual(
            historical["mode_counts"],
            {
                "CHANGED_RTL_REPLAY_REQUIRED": 19,
                "CHECKER_ONLY_REUSED": 3,
                "UNCHANGED_RTL_REUSED": 152,
                "VERIFICATION_SOURCE_REUSED": 1,
            },
        )

    def test_every_changed_source_item_has_one_current_replacement(self) -> None:
        items = self.receipt["historical_negative"]["items"]
        affected = {
            row["item_id"]: row
            for row in items
            if row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
        }
        replacements = self.receipt["current_changed_cone"]["replacements"]
        TOOL.validate_affected_replacements(affected, replacements)
        self.assertEqual(len(replacements), 19)

    def test_supplemental_replay_is_identity_helper_only(self) -> None:
        replay = self.receipt["current_changed_cone"][
            "supplemental_input_replay"
        ]
        self.assertEqual(replay["path"], TOOL.ARCH_BINDING_TOOL.as_posix())
        self.assertEqual(replay["classification"], "rtl_identity_helper_only")
        self.assertNotEqual(replay["recorded_sha256"], replay["current_sha256"])
        self.assertFalse(replay["production_rtl_reexecuted"])

    def test_supplemental_replay_rejects_non_identity_input_drift(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-delta-rebind-") as raw:
            root = pathlib.Path(raw)
            helper = root / TOOL.ARCH_BINDING_TOOL
            definitions = root / "definitions.py"
            runner = root / "runner.py"
            helper.parent.mkdir(parents=True)
            helper.write_text("current helper\n", encoding="utf-8")
            definitions.write_text("current definitions\n", encoding="utf-8")
            runner.write_text("current runner\n", encoding="utf-8")

            def record(path: pathlib.Path, payload: bytes | None = None) -> dict:
                content = path.read_bytes() if payload is None else payload
                return {
                    "path": path.relative_to(root).as_posix(),
                    "sha256": hashlib.sha256(content).hexdigest(),
                }

            inputs = {
                "architecture_binding": {
                    "path": TOOL.ARCH_BINDING_TOOL.as_posix(),
                    "sha256": hashlib.sha256(b"old helper\n").hexdigest(),
                },
                "control_variant_definitions": record(definitions),
                "runner": record(runner, b"old runner\n"),
            }
            with self.assertRaisesRegex(TOOL.DeltaRebindError, "runner hash"):
                TOOL.validate_supplemental_inputs(root, inputs)

    def test_dropped_changed_source_replacement_is_gap(self) -> None:
        items = self.receipt["historical_negative"]["items"]
        affected = {
            row["item_id"]: row
            for row in items
            if row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
        }
        replacements = copy.deepcopy(
            self.receipt["current_changed_cone"]["replacements"]
        )
        replacements.pop(next(iter(replacements)))
        with self.assertRaises(TOOL.DeltaRebindError):
            TOOL.validate_affected_replacements(affected, replacements)

    def test_replacement_cannot_point_to_another_rtl_source(self) -> None:
        items = self.receipt["historical_negative"]["items"]
        affected = {
            row["item_id"]: row
            for row in items
            if row["projection_mode"] == "CHANGED_RTL_REPLAY_REQUIRED"
        }
        replacements = copy.deepcopy(
            self.receipt["current_changed_cone"]["replacements"]
        )
        item_id = next(iter(replacements))
        replacements[item_id]["source"] = "npc/rv64/vsrc/sim/NpcSimTop.sv"
        with self.assertRaises(TOOL.DeltaRebindError):
            TOOL.validate_affected_replacements(affected, replacements)

    def test_manifest_membership_drop_is_gap(self) -> None:
        baseline = dict(self.baseline["files"])
        current = dict(self.current["groups"]["rtl"])
        current.pop(next(iter(current)))
        with self.assertRaises(TOOL.DeltaRebindError):
            TOOL.compare_manifests(baseline, current)

    def test_additional_unreferenced_rtl_delta_is_recorded(self) -> None:
        baseline = dict(self.baseline["files"])
        current = dict(self.current["groups"]["rtl"])
        historical_sources = {
            row["source"]
            for row in self.receipt["historical_negative"]["items"]
            if row.get("source") in baseline
        }
        already_changed = {
            row["path"] for row in self.receipt["rtl_delta"]["changed_files"]
        }
        unchanged = next(
            path for path in current
            if path not in already_changed and path not in historical_sources
        )
        current[unchanged] = "0" * 64
        delta = TOOL.compare_manifests(baseline, current)
        self.assertIn(
            unchanged, {row["path"] for row in delta["changed_files"]}
        )
        self.assertEqual(
            delta["changed_file_count"],
            self.receipt["rtl_delta"]["changed_file_count"] + 1,
        )

    def test_store_queue_legacy_anchor_has_explicit_current_contract_mapping(self) -> None:
        item_id = (
            "STORE-BRESP-G1:RTL_MUTATION:"
            "sq_clear_owner_valid_on_request_fire"
        )
        replacement = self.receipt["current_changed_cone"]["replacements"][item_id]
        self.assertEqual(
            replacement["replacement_kind"],
            "CURRENT_CONTRACT_SEMANTIC_REPLACEMENT",
        )
        self.assertEqual(
            replacement["name"],
            "sq-clear-owner-valid-on-authorized-request-fire",
        )

    def test_npc_sim_top_delta_requires_current_system_layers(self) -> None:
        changed_paths = {
            row["path"] for row in self.receipt["rtl_delta"]["changed_files"]
        }
        self.assertIn(
            "npc/rv64/vsrc/sim/NpcSimTop.sv", changed_paths
        )
        positive = self.receipt["current_positive"]
        self.assertEqual(positive["l2"], {"case": "all", "status": "PASS"})
        self.assertEqual(positive["l3"], {"case": "all", "status": "PASS"})
        self.assertEqual(positive["optional_ubuntu"], "NOT_RUN_OPTIONAL")

    def test_retained_changed_cone_is_exact_source_projected(self) -> None:
        projections = {
            row["evidence_design_projection"]["mode"]
            for row in self.receipt["current_changed_cone"][
                "replacements"
            ].values()
        }
        self.assertIn(
            "EXACT_CURRENT_SOURCE_PROJECTED_FROM_PRIOR_DESIGN", projections
        )
        for row in self.receipt["current_changed_cone"][
            "replacements"
        ].values():
            self.assertEqual(
                row["source_sha256"],
                self.current["groups"]["rtl"][row["source"]],
            )

    def test_promotion_boundary_remains_red_and_unpromoted(self) -> None:
        self.assertEqual(
            self.receipt["promotion"],
            {
                "architecture_debt_evidence": "CURRENT_DELTA_REBOUND",
                "whole_architecture": "RED",
                "system_recertification": "PASS_CURRENT_CONFIG",
                "ppa": "UNPROMOTED",
            },
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
