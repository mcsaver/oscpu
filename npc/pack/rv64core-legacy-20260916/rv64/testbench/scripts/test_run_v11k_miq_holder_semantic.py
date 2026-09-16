#!/usr/bin/env python3
"""Unit tests for the V11K MIQ holder semantic runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11k_miq_holder_semantic as runner


class V11kMiqHolderRunnerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.miq_path = (
            cls.repo_root
            / "npc"
            / "rv64"
            / "vsrc"
            / "memory"
            / "OooMemInflightQueue.v"
        )
        cls.source = cls.miq_path.read_text(encoding="utf-8")

    def test_every_mutation_anchor_is_unique_and_changes_source(self) -> None:
        names = set()
        for mutation in runner.MUTATIONS:
            self.assertNotIn(mutation.name, names)
            names.add(mutation.name)
            mutated, receipts = runner.apply_mutation(
                self.source, mutation.replacements
            )
            self.assertNotEqual(mutated, self.source)
            self.assertEqual(len(receipts), len(mutation.replacements))
            self.assertTrue(
                all(item["anchor_count"] == 1 for item in receipts)
            )

    def test_profile_inventory_is_assert_release_complete(self) -> None:
        profiles = runner.build_profiles()
        expected = (
            2
            + 2 * len(runner.MUTATIONS)
            + 2 * len(runner.STIMULUS_PROBES)
        )
        self.assertEqual(len(profiles), expected)
        self.assertEqual(
            {item.name for item in profiles},
            {"production-assert", "production-release"}
            | {
                f"{mutation.name}-{configuration}"
                for mutation in runner.MUTATIONS
                for configuration in ("assert", "release")
            }
            | {
                f"{probe.name}-{configuration}"
                for probe in runner.STIMULUS_PROBES
                for configuration in ("assert", "release")
            },
        )
        by_name = {item.name: item for item in profiles}
        self.assertEqual(
            by_name["capture-token-z-assert"].expected_marker,
            "[V11K-MIQ-OWNER-TUPLE-KNOWN]",
        )
        self.assertEqual(
            by_name["idle-head-token-drift-assert"].expected_marker,
            "[V11K-MIQ-OWNER-TUPLE-STABLE]",
        )
        self.assertEqual(
            by_name["consume-without-exact-owner-assert"].expected_marker,
            "[MIQ-OWNER-MISMATCH]",
        )
        self.assertEqual(
            by_name["accepted-push-tuple-x-assert"].expected_marker,
            "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
        )
        self.assertEqual(
            by_name["valid-head-pop-tuple-z-assert"].expected_marker,
            "[V11K-MIQ-POP-TUPLE-KNOWN]",
        )

    def test_baseline_requires_exact_pass_markers(self) -> None:
        profile = runner.Profile(
            "production-release", False, "baseline"
        )
        passed, markers = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=(
                runner.MATRIX_PASS + "\n" + runner.TB_PASS + "\n"
            ),
            artifact_exists=True,
        )
        self.assertTrue(passed)
        self.assertEqual(markers["oracle_fail"], 0)
        escaped, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=(
                runner.MATRIX_PASS
                + "\n"
                + runner.TB_PASS
                + "\n"
                + runner.NEGATIVE_ESCAPED
            ),
            artifact_exists=True,
        )
        self.assertFalse(escaped)

    def test_negative_profiles_require_the_right_observer(self) -> None:
        assert_profile = runner.Profile(
            "capture-kind-x-assert",
            True,
            "mutation",
            mutation="capture-kind-x",
            expected_marker="[V11K-MIQ-OWNER-TUPLE-KNOWN]",
        )
        passed, _ = runner.evaluate_profile(
            assert_profile,
            compile_rc=0,
            sim_rc=1,
            log_text="[V11K-MIQ-OWNER-TUPLE-KNOWN]\n",
            artifact_exists=True,
        )
        self.assertTrue(passed)
        wrong_marker, _ = runner.evaluate_profile(
            assert_profile,
            compile_rc=0,
            sim_rc=1,
            log_text=runner.ORACLE_FAIL + "\n",
            artifact_exists=True,
        )
        self.assertFalse(wrong_marker)

        release_profile = runner.Profile(
            "capture-kind-x-release",
            False,
            "mutation",
            mutation="capture-kind-x",
        )
        passed, _ = runner.evaluate_profile(
            release_profile,
            compile_rc=0,
            sim_rc=1,
            log_text=runner.ORACLE_FAIL + "\n",
            artifact_exists=True,
        )
        self.assertTrue(passed)
        false_green, _ = runner.evaluate_profile(
            release_profile,
            compile_rc=0,
            sim_rc=1,
            log_text=runner.NEGATIVE_ESCAPED + "\n",
            artifact_exists=True,
        )
        self.assertFalse(false_green)

    def test_product_instance_contract_is_exact_and_distinct(self) -> None:
        self.assertEqual(len(runner.PRODUCT_INSTANCES), 2)
        self.assertEqual(len(set(runner.PRODUCT_INSTANCES)), 2)
        self.assertTrue(
            any(
                path.endswith(".u_mem_inflight_queue")
                for path in runner.PRODUCT_INSTANCES
            )
        )
        self.assertTrue(
            any(
                path.endswith(".u_mem1_inflight_queue")
                for path in runner.PRODUCT_INSTANCES
            )
        )

    def test_stimulus_probe_release_requires_fail_closed_observer(
        self,
    ) -> None:
        profile = runner.Profile(
            "valid-head-pop-tuple-x-release",
            False,
            "stimulus-probe",
            stimulus_define="-DV11K_POP_TUPLE_X_PROBE",
            release_fail_closed_marker=runner.POP_FAIL_CLOSED,
        )
        oracle_rejected, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=runner.ORACLE_FAIL + "\n",
            artifact_exists=True,
        )
        self.assertTrue(oracle_rejected)
        held_state, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=runner.POP_FAIL_CLOSED + "\n",
            artifact_exists=True,
        )
        self.assertTrue(held_state)
        escaped, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=runner.NEGATIVE_ESCAPED + "\n",
            artifact_exists=True,
        )
        self.assertFalse(escaped)

    def test_regression_context_binds_each_testbench_and_common_inputs(
        self,
    ) -> None:
        context = runner.load_regression_context(
            self.repo_root / "npc" / "rv64" / "testbench"
        )
        self.assertEqual(set(context), set(runner.REGRESSIONS))
        for test, paths in context.items():
            relative = {
                path.relative_to(self.repo_root).as_posix()
                for path in paths
            }
            self.assertIn(
                f"npc/rv64/testbench/tests/{test}.sv",
                relative,
            )
            self.assertIn("npc/rv64/testbench/Makefile", relative)
            self.assertIn(
                "npc/rv64/vsrc/include/define.v",
                relative,
            )


if __name__ == "__main__":
    unittest.main()
