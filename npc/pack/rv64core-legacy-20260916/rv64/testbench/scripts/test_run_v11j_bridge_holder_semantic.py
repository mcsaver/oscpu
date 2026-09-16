#!/usr/bin/env python3
"""Self-tests for the V11J bridge-holder evidence runner."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name(
    "run_v11j_bridge_holder_semantic.py"
)
SPEC = importlib.util.spec_from_file_location("v11j_runner", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class MutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        repo_root = Path(__file__).resolve().parents[4]
        cls.sources = {
            "bridge": (
                repo_root
                / "npc"
                / "rv64"
                / "vsrc"
                / "memory"
                / "OooMemAxiBridge.v"
            ).read_text(encoding="utf-8"),
            "wrapper": (
                repo_root
                / "npc"
                / "rv64"
                / "vsrc"
                / "memory"
                / "OooDualMemBridgeWrapper.v"
            ).read_text(encoding="utf-8"),
        }

    def test_mutation_names_are_unique(self) -> None:
        names = [item.name for item in RUNNER.MUTATIONS]
        self.assertEqual(len(names), 13)
        self.assertEqual(len(names), len(set(names)))

    def test_every_mutation_anchor_binds_once(self) -> None:
        for mutation in RUNNER.MUTATIONS:
            with self.subTest(mutation=mutation.name):
                source = self.sources[mutation.target]
                mutated, receipts = RUNNER.apply_mutation(
                    source, mutation.replacements
                )
                self.assertNotEqual(mutated, source)
                self.assertEqual(
                    len(receipts), len(mutation.replacements)
                )
                self.assertTrue(
                    all(item["anchor_count"] == 1 for item in receipts)
                )

    def test_missing_anchor_is_rejected(self) -> None:
        replacement = RUNNER.Replacement(
            "absent-anchor", "replacement", "negative unit test"
        )
        with self.assertRaisesRegex(ValueError, "anchor count"):
            RUNNER.apply_mutation("source", (replacement,))


class ProfileTests(unittest.TestCase):
    def test_profile_matrix_is_complete_and_unique(self) -> None:
        profiles = RUNNER.build_profiles()
        names = [item.name for item in profiles]
        self.assertEqual(len(profiles), 32)
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(
            sum(item.kind == "baseline" for item in profiles), 2
        )
        self.assertEqual(
            sum(item.kind == "tuple-x" for item in profiles), 4
        )
        self.assertEqual(
            sum(item.kind == "mutation" for item in profiles), 26
        )
        marker_profiles = [
            item
            for item in profiles
            if item.kind == "mutation" and item.expected_marker
        ]
        self.assertEqual(len(marker_profiles), 4)
        self.assertTrue(all(item.assertions for item in marker_profiles))

    def test_baseline_requires_both_pass_markers(self) -> None:
        profile = RUNNER.Profile(
            "production-assert", True, "baseline"
        )
        passed, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=RUNNER.TB_PASS + "\n" + RUNNER.MATRIX_PASS,
            artifact_exists=True,
        )
        self.assertTrue(passed)
        missing, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=RUNNER.TB_PASS,
            artifact_exists=True,
        )
        self.assertFalse(missing)

    def test_tuple_x_assert_requires_new_stage_marker(self) -> None:
        profile = RUNNER.Profile(
            "kind-x-assert",
            True,
            "tuple-x",
            stimulus_define="-DV11J_KIND_X_NEGATIVE",
        )
        passed, counts = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.TUPLE_MARKERS[0],
            artifact_exists=True,
        )
        self.assertTrue(passed)
        self.assertEqual(counts["tuple_marker_total"], 1)

    def test_tuple_x_release_requires_oracle(self) -> None:
        profile = RUNNER.Profile(
            "epoch-x-release",
            False,
            "tuple-x",
            stimulus_define="-DV11J_EPOCH_X_NEGATIVE",
        )
        passed, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.ORACLE_FAIL,
            artifact_exists=True,
        )
        self.assertTrue(passed)

    def test_mutation_assert_accepts_assertion_or_oracle_rejection(self) -> None:
        profile = RUNNER.Profile(
            "mutation-assert",
            True,
            "mutation",
            mutation="active-transfer-wrong-token",
        )
        assertion_pass, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text="[S2-G1-BRG-ACTIVE-RSP-ECHO]",
            artifact_exists=True,
        )
        oracle_pass, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.ORACLE_FAIL,
            artifact_exists=True,
        )
        self.assertTrue(assertion_pass)
        self.assertTrue(oracle_pass)

    def test_mutation_release_cannot_use_assertion_marker(self) -> None:
        profile = RUNNER.Profile(
            "mutation-release",
            False,
            "mutation",
            mutation="active-transfer-wrong-token",
        )
        escaped, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text="[S2-G1-BRG-ACTIVE-RSP-ECHO]",
            artifact_exists=True,
        )
        rejected, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.ORACLE_FAIL,
            artifact_exists=True,
        )
        self.assertFalse(escaped)
        self.assertTrue(rejected)

    def test_marker_probe_requires_its_exact_holder_marker(self) -> None:
        profile = RUNNER.Profile(
            "active-epoch-x-transfer-assert",
            True,
            "mutation",
            mutation="active-epoch-x-transfer",
            stimulus_define="-DV11J_ACTIVE_X_MARKER_PROBE",
            expected_marker=RUNNER.TUPLE_MARKERS[1],
        )
        passed, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.TUPLE_MARKERS[1],
            artifact_exists=True,
        )
        wrong, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=RUNNER.TUPLE_MARKERS[0],
            artifact_exists=True,
        )
        self.assertTrue(passed)
        self.assertFalse(wrong)

    def test_compile_failure_is_never_negative_evidence(self) -> None:
        profile = RUNNER.Profile(
            "mutation-release",
            False,
            "mutation",
            mutation="residency-add-ghost",
        )
        passed, _ = RUNNER.evaluate_profile(
            profile,
            compile_rc=1,
            sim_rc=None,
            log_text=RUNNER.ORACLE_FAIL,
            artifact_exists=False,
        )
        self.assertFalse(passed)

    def test_regression_log_requires_exact_pass_and_result(self) -> None:
        text = (
            "[PASS] tb_ooo_mem_axi_bridge\n"
            "[RESULT] PASS\n"
        )
        self.assertTrue(
            RUNNER.evaluate_regression_log(
                "tb_ooo_mem_axi_bridge", text
            )
        )
        self.assertFalse(
            RUNNER.evaluate_regression_log(
                "tb_ooo_mem_axi_bridge",
                text + "[RESULT] FAIL status=1\n",
            )
        )


if __name__ == "__main__":
    unittest.main()
