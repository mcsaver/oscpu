#!/usr/bin/env python3
"""Directed non-simulator tests for the architecture-delta mutation wheel."""

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[4]
TOOL_PATH = ROOT / "npc/rv64/testbench/scripts/run_architecture_delta_mutations.py"
SPEC = importlib.util.spec_from_file_location(
    "run_architecture_delta_mutations_tested", TOOL_PATH
)
assert SPEC is not None and SPEC.loader is not None
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class ArchitectureDeltaMutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.variants = TOOL.variants(ROOT)

    def test_variant_ids_and_historical_replacements_are_unique(self) -> None:
        names = [item.name for item in self.variants]
        replacements = [
            item
            for variant in self.variants
            for item in variant.replaces_historical_items
        ]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(len(replacements), len(set(replacements)))
        self.assertEqual(len(self.variants), 9)

    def test_every_live_rtl_anchor_is_exact_and_non_noop(self) -> None:
        for variant in self.variants:
            with self.subTest(variant=variant.name):
                original, mutated = TOOL.reconstruct(ROOT, variant)
                self.assertNotEqual(original, mutated)
                self.assertEqual(original.decode().count(variant.old), 1)
                self.assertEqual(mutated.decode().count(variant.new), 1)

    def test_store_owner_variant_uses_current_authorized_fire_contract(self) -> None:
        variant = next(
            item
            for item in self.variants
            if item.name == "sq-clear-owner-valid-on-authorized-request-fire"
        )
        self.assertIn("req_fire_authorized_w", variant.old)
        self.assertIn("owner_valid_q[head_q] <= 1'b0", variant.new)
        self.assertEqual(
            variant.replaces_historical_items,
            (
                "STORE-BRESP-G1:RTL_MUTATION:"
                "sq_clear_owner_valid_on_request_fire",
            ),
        )

    def test_log_oracle_accepts_only_compile_success_exact_rejection(self) -> None:
        marker = "[CHECK-FAIL] exact owner tuple"
        text = "\n".join(("[COMPILE] iverilog ...", marker, "[RESULT] FAIL status=1"))
        compiled, rejected, counts = TOOL.evaluate_log(
            text, 2, True, (marker,)
        )
        self.assertTrue(compiled)
        self.assertTrue(rejected)
        self.assertEqual(counts, {marker: 1})

        for changed in (
            text + "\n" + marker,
            text + "\n[RESULT] PASS",
            text.replace(marker, ""),
        ):
            with self.subTest(changed=changed):
                _, rejected, _ = TOOL.evaluate_log(
                    changed, 2, True, (marker,)
                )
                self.assertFalse(rejected)

    def test_zero_returncode_cannot_be_a_rejected_mutation(self) -> None:
        marker = "[CHECK-FAIL] exact owner tuple"
        text = "\n".join(("[COMPILE] iverilog ...", marker, "[RESULT] FAIL"))
        _, rejected, _ = TOOL.evaluate_log(text, 0, True, (marker,))
        self.assertFalse(rejected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
