#!/usr/bin/env python3
"""Focused checks for the current RV64 ARCH_STABLE candidate builder."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


TOOL_PATH = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "arch_stable_current_candidate.py")
SPEC = importlib.util.spec_from_file_location(
    "test_arch_stable_current_candidate_tool", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOL)
ROOT = TOOL_PATH.parents[5]
TOOLS_DIR = ROOT / "npc/rv64/eval/ppa/tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))
import arch_stable_freeze as FREEZE  # noqa: E402


class ArchStableCurrentCandidateTests(unittest.TestCase):
    def test_workflow_classification_is_closed_under_audit_schema(self) -> None:
        for path in FREEZE.WORKFLOW_BINDING_PATHS:
            self.assertIn(
                TOOL.workflow_kind(path), FREEZE.GROUP_KINDS["workflow"], path)

    def test_current_functional_inventory_is_exact(self) -> None:
        aggregate = TOOL.load_json(ROOT / (
            ".github/task-runs/"
            "2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
            "evidence/f0-run-2/functional/functional-aggregate.json"
        ))
        images, binaries = TOOL.collect_functional_artifacts(aggregate)
        self.assertEqual(len(images), 240)
        self.assertEqual(len(binaries), 2)
        self.assertEqual(len({item["path"] for item in images}), 240)
        self.assertEqual(
            {item["kind"] for item in binaries},
            {"simulator_binary", "reference_model_binary"},
        )

    def test_candidate_defaults_do_not_grant_ppa_promotion(self) -> None:
        self.assertEqual(TOOL.RUN_PARAMETERS["top"], "NpcTop")
        self.assertEqual(TOOL.RUN_PARAMETERS["clock_port"], "clk")
        self.assertEqual(TOOL.RUN_PARAMETERS["period_ns"], 5.0)
        self.assertEqual(TOOL.RUN_PARAMETERS["synthesis_seed"], 0)
        self.assertEqual(TOOL.RUN_PARAMETERS["threads"], 1)
        self.assertEqual(len(TOOL.MACRO_LIBERTIES), 4)
        self.assertEqual(len({name for name, _ in TOOL.MACRO_LIBERTIES}), 4)


if __name__ == "__main__":
    unittest.main()
