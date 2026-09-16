#!/usr/bin/env python3
"""Unit tests for the V11L memory retry-holder semantic runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11l_memory_retry_holder_semantic as runner


class V11lMemoryRetryHolderRunnerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.rtl_path = (
            cls.repo_root
            / "npc"
            / "rv64"
            / "vsrc"
            / "execute"
            / "OooIntBackend.v"
        )
        cls.source = cls.rtl_path.read_text(encoding="utf-8")

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

    def test_mutation_inventory_binds_only_the_four_retry_units(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 32)
        self.assertEqual(len({item.name for item in runner.MUTATIONS}), 32)
        bound_units = {
            unit
            for mutation in runner.MUTATIONS
            for unit in mutation.unit_ids
        }
        self.assertEqual(bound_units, set(runner.UNIT_IDS))
        for mutation in runner.MUTATIONS:
            self.assertTrue(mutation.expected_stage)
            self.assertTrue(mutation.unit_ids)
            self.assertLessEqual(set(mutation.unit_ids), set(runner.UNIT_IDS))

    def test_profile_inventory_is_baseline_and_release_mutations(self) -> None:
        profiles = runner.build_profiles()
        self.assertEqual(len(profiles), 2 + len(runner.MUTATIONS))
        self.assertEqual(
            {item.name for item in profiles},
            {"production-assert", "production-release"}
            | {
                f"{mutation.name}-release"
                for mutation in runner.MUTATIONS
            },
        )
        baseline = [item for item in profiles if item.kind == "baseline"]
        mutations = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(
            {(item.name, item.assertions) for item in baseline},
            {
                ("production-assert", True),
                ("production-release", False),
            },
        )
        self.assertTrue(mutations)
        self.assertTrue(all(not item.assertions for item in mutations))
        self.assertTrue(all(item.expected_stage for item in mutations))

    def test_baseline_requires_each_exact_pass_marker_once(self) -> None:
        profile = runner.Profile(
            "production-release", False, "baseline"
        )
        log = "\n".join(
            [
                *(
                    marker
                    for marker, count in runner.BASELINE_MARKERS.items()
                    for _ in range(count)
                ),
                runner.MATRIX_PASS,
                runner.TB_PASS,
            ]
        )
        passed, markers = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=log,
            artifact_exists=True,
        )
        self.assertTrue(passed)
        self.assertEqual(markers["oracle_fail"], 0)

        missing, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=log.replace(
                "[V11L-RETRY-HOLD][PASS]", "", 1
            ),
            artifact_exists=True,
        )
        self.assertFalse(missing)

        duplicate, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=0,
            log_text=log + "\n[V11L-RETRY-HOLD][PASS]\n",
            artifact_exists=True,
        )
        self.assertFalse(duplicate)

    def test_mutation_requires_compile_success_and_exact_stage(self) -> None:
        profile = runner.Profile(
            "retry0-token-x-release",
            False,
            "mutation",
            mutation="retry0-token-x",
            expected_stage="retry0-holder-tuple",
        )
        exact_log = (
            runner.ORACLE_FAIL + " stage=retry0-holder-tuple\n"
        )
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            sim_rc=1,
            log_text=exact_log,
            artifact_exists=True,
        )
        self.assertTrue(passed)

        for compile_rc, sim_rc, log_text, artifact_exists in (
            (1, None, exact_log, False),
            (0, 0, exact_log, True),
            (0, 1, runner.ORACLE_FAIL + "\n", True),
            (
                0,
                1,
                runner.ORACLE_FAIL + " stage=retry1-holder-tuple\n",
                True,
            ),
            (0, 1, exact_log + runner.MATRIX_PASS, True),
            (0, 1, exact_log + runner.TB_PASS, True),
        ):
            rejected, _ = runner.evaluate_profile(
                profile,
                compile_rc=compile_rc,
                sim_rc=sim_rc,
                log_text=log_text,
                artifact_exists=artifact_exists,
            )
            self.assertFalse(rejected)

    def test_product_instance_contract_is_exact(self) -> None:
        self.assertEqual(
            runner.PRODUCT_INSTANCE,
            (
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ),
        )

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
                "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
                relative,
            )
            self.assertIn("npc/rv64/testbench/Makefile", relative)
            self.assertIn(
                "npc/rv64/vsrc/include/define.v",
                relative,
            )


if __name__ == "__main__":
    unittest.main()
