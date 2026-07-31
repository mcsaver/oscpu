#!/usr/bin/env python3
"""Unit tests for the V11U pending-system ProducerId runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11u_pending_system_producer_semantic as runner


class V11uPendingSystemProducerRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.sources = {
            path: (cls.repo_root / path).read_text(encoding="utf-8")
            for path in (runner.SEQUENCER, runner.CSR_MUX, runner.INT_BACKEND)
        }

    def test_all_mutation_anchors_are_unique_and_change_source(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 10)
        for mutation in runner.MUTATIONS:
            source = self.sources[mutation.source]
            mutated, receipts = runner.apply_mutation(
                source, mutation.replacements
            )
            self.assertNotEqual(mutated, source, mutation.name)
            self.assertTrue(receipts, mutation.name)
            self.assertTrue(
                all(item["anchor_count"] == 1 for item in receipts),
                mutation.name,
            )

    def test_profile_inventory_is_small_and_two_width_aware(self) -> None:
        profiles = runner.build_profiles()
        self.assertEqual(len(runner.positive_profiles()), 9)
        self.assertEqual(len(runner.assertion_profiles()), 3)
        self.assertEqual(len(runner.mutation_profiles()), 12)
        self.assertEqual(len(profiles), 24)
        self.assertEqual({item.gen_width for item in profiles}, {1, 4})
        self.assertTrue(
            all(not item.assertions for item in runner.mutation_profiles())
        )

    def test_positive_profile_requires_exact_result_and_marker(self) -> None:
        profile = next(
            item
            for item in runner.positive_profiles()
            if item.name == "sequencer-mux-g4-release"
        )
        logs = {
            runner.TEST_SEQUENCER: (
                "[COMPILE]\n[V9W-SERIAL-KIND-MATRIX]\n[RESULT] PASS\n"
            ),
            runner.TEST_CSR_MUX: "[COMPILE]\n[RESULT] PASS\n",
        }
        self.assertTrue(
            runner.evaluate_profile(
                profile,
                make_rc=0,
                timed_out=False,
                logs=logs,
                artifacts_exist=True,
            )
        )
        logs[runner.TEST_SEQUENCER] = logs[runner.TEST_SEQUENCER].replace(
            "[V9W-SERIAL-KIND-MATRIX]", ""
        )
        self.assertFalse(
            runner.evaluate_profile(
                profile,
                make_rc=0,
                timed_out=False,
                logs=logs,
                artifacts_exist=True,
            )
        )

    def test_mutation_requires_compile_success_and_semantic_failure(self) -> None:
        profile = next(
            item
            for item in runner.mutation_profiles()
            if item.name == "mutation-birth-drops-generation-g4-release"
        )
        logs = {
            runner.TEST_SEQUENCER: (
                "[COMPILE]\nFAIL head0 lease pid\n[RESULT] FAIL\n"
            )
        }
        self.assertTrue(
            runner.evaluate_profile(
                profile,
                make_rc=2,
                timed_out=False,
                logs=logs,
                artifacts_exist=True,
            )
        )
        for artifacts_exist, text in (
            (False, logs[runner.TEST_SEQUENCER]),
            (True, "[COMPILE]\ncompile returned nonzero\n[RESULT] FAIL\n"),
            (True, "[COMPILE]\n[RESULT] PASS\n"),
        ):
            self.assertFalse(
                runner.evaluate_profile(
                    profile,
                    make_rc=2,
                    timed_out=False,
                    logs={runner.TEST_SEQUENCER: text},
                    artifacts_exist=artifacts_exist,
                )
            )

    def test_assertion_probe_is_distinct_from_release_mutation(self) -> None:
        profile = next(
            item
            for item in runner.assertion_profiles()
            if item.name == "assert-noncsr-dispatch-g4"
        )
        self.assertTrue(profile.assertions)
        self.assertIsNone(profile.mutation)
        self.assertEqual(
            profile.expected_failure_marker,
            "[V8K-PENDING-CSR-DISPATCH-BIRTH]",
        )

    def test_generation_sensitive_mutations_cover_both_widths(self) -> None:
        by_name = {item.name: item for item in runner.MUTATIONS}
        for name in (
            "birth-drops-generation",
            "pid-match-ignores-generation",
        ):
            self.assertEqual(by_name[name].widths, runner.GEN_WIDTHS)
        self.assertEqual(
            by_name["pending-live-mask-removed"].widths,
            (4,),
        )

    def test_noncsr_probe_is_present_in_the_bound_testbench(self) -> None:
        source = (self.repo_root / runner.TB_LEASE_PROBE).read_text(
            encoding="utf-8"
        )
        self.assertIn("V11U_PROBE_NONCSR_DISPATCH", source)
        self.assertIn("V11U_ASSERT_NONCSR_DISPATCH", source)
        self.assertIn(".fence_o()", source)

    def test_scope_is_exactly_pending_system_producer(self) -> None:
        self.assertEqual(runner.UNIT_IDS, ("pending-system-producer",))
        self.assertTrue(
            runner.PRODUCT_INSTANCE.endswith(".u_pending_system_sequencer")
        )
        self.assertEqual(
            {item.source for item in runner.MUTATIONS},
            {runner.SEQUENCER, runner.CSR_MUX, runner.INT_BACKEND},
        )


if __name__ == "__main__":
    unittest.main()
