#!/usr/bin/env python3
"""Focused fail-closed tests for current RV64 architecture provenance replay."""

from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import tempfile
import unittest


TOOL_PATH = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "architecture_provenance_replay.py")
SPEC = importlib.util.spec_from_file_location(
    "test_architecture_provenance_replay_tool", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class ArchitectureProvenanceReplayTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = TOOL_PATH.parents[5]
        cls.input_path = cls.root / (
            ".github/task-runs/"
            "2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/"
            "evidence/replay-1/current-directed-nine-gate-replay.json"
        )

    def test_current_makefile_only_replay_is_green(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".rv64-architecture-replay-test-", dir=self.root,
        ) as raw:
            output_dir = pathlib.Path(raw) / "evidence"
            receipt = TOOL.run_replay(
                root=self.root,
                input_path=self.input_path,
                output_dir=output_dir,
                rebind_paths={TOOL.MAKEFILE_PATH},
            )
            self.assertEqual(receipt["status"], "PASS")
            self.assertEqual(
                receipt["architecture_directed_gates"],
                {"status": "GREEN", "passed": 9, "required": 9},
            )
            self.assertEqual(receipt["negative_summary"]["detected"], 4)
            self.assertFalse(receipt["dut_rerun"])
            self.assertFalse(receipt["production_rtl_modified"])
            replay = TOOL.read_json(output_dir / "architecture-current-replay.json")
            current_makefile_sha = TOOL.sha256_file(
                self.root / TOOL.MAKEFILE_PATH)
            for record in replay["tests"].values():
                self.assertEqual(
                    record["provenance"]["files"][TOOL.MAKEFILE_PATH],
                    current_makefile_sha,
                )
                source_manifest = record.get("source_manifest")
                if isinstance(source_manifest, dict) and (
                    TOOL.MAKEFILE_PATH in source_manifest.get("files", {})
                ):
                    self.assertEqual(
                        source_manifest["files"][TOOL.MAKEFILE_PATH],
                        current_makefile_sha,
                    )

    def test_makefile_gate_recipe_or_phony_change_is_rejected(self) -> None:
        text = (self.root / TOOL.MAKEFILE_PATH).read_text(encoding="utf-8")
        changed_recipe = text.replace(
            TOOL.EXPECTED_MAKE_RECIPES["check-frontend-ii1"][0],
            "@bash /tmp/not-the-bound-runner.sh",
            1,
        )
        with self.assertRaisesRegex(TOOL.ReplayError, "gate recipe changed"):
            TOOL.validate_makefile_gate_projection(changed_recipe)
        changed_phony = text.replace(
            ".PHONY: check-frontend-ii1",
            ".PHONY: check-frontend-ii1-removed",
            1,
        )
        with self.assertRaisesRegex(TOOL.ReplayError, "PHONY binding"):
            TOOL.validate_makefile_gate_projection(changed_phony)

    def test_rtl_or_extra_rebind_path_is_rejected(self) -> None:
        with self.assertRaisesRegex(TOOL.ReplayError, "exact non-DUT replay path"):
            TOOL.validate_rebind_paths(
                self.root,
                {"npc/rv64/vsrc/core/NpcCoreTop.v"},
            )
        with self.assertRaisesRegex(TOOL.ReplayError, "exact non-DUT replay path"):
            TOOL.validate_rebind_paths(
                self.root,
                {TOOL.MAKEFILE_PATH, TOOL.ARCH_TOOL_PATH},
            )

    def test_additional_provenance_drift_is_rejected(self) -> None:
        manifest = TOOL.read_json(self.input_path)
        mutated = copy.deepcopy(manifest)
        mutated["tests"]["frontend_ii1"]["provenance"]["files"][
            TOOL.ARCH_TOOL_PATH
        ] = "0" * 64
        with tempfile.TemporaryDirectory(
            prefix=".rv64-architecture-replay-negative-", dir=self.root,
        ) as raw:
            path = pathlib.Path(raw) / "manifest.json"
            TOOL.write_json(path, mutated)
            arch = TOOL.load_architecture_tool(self.root)
            with self.assertRaisesRegex(
                TOOL.ReplayError, "drift is not exactly the allowlist",
            ):
                TOOL.validate_input_manifest(
                    root=self.root,
                    input_path=path,
                    manifest=mutated,
                    rebind_paths={TOOL.MAKEFILE_PATH},
                    arch=arch,
                )

    def test_gate_inventory_cannot_shrink(self) -> None:
        self.assertEqual(
            set(TOOL.TEST_TO_GATE),
            {
                "frontend_ii1", "width_continuity", "pair_matrix",
                "no_static_lane_semantics", "dual_memory_issue",
                "true_ooo_long_latency", "selective_scheduling",
                "memory_ordering", "speculation_recovery",
            },
        )
        self.assertEqual(
            set(TOOL.TEST_TO_MAKE_TARGET), set(TOOL.TEST_TO_GATE))
        self.assertEqual(
            set(TOOL.EXPECTED_MAKE_RECIPES),
            set(TOOL.TEST_TO_MAKE_TARGET.values()),
        )


if __name__ == "__main__":
    unittest.main()
