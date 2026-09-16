#!/usr/bin/env python3
"""Unit tests for the V11M memory-reservation semantic runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11m_memory_reservation_holder_semantic as runner


class V11mMemoryReservationRunnerTest(unittest.TestCase):
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
        names: set[str] = set()
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

    def test_mutations_bind_only_the_four_reservation_units(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 37)
        bound = {
            unit
            for mutation in runner.MUTATIONS
            for unit in mutation.unit_ids
        }
        self.assertEqual(bound, set(runner.UNIT_IDS))
        self.assertTrue(
            all(
                set(mutation.unit_ids) <= set(runner.UNIT_IDS)
                for mutation in runner.MUTATIONS
            )
        )
        self.assertTrue(
            {
                "reservation0-producer-generation-truncate",
                "reservation1-producer-generation-truncate",
                "reservation0-token-high-truncate",
                "reservation1-token-high-truncate",
            }
            <= {mutation.name for mutation in runner.MUTATIONS}
        )

    def test_profile_inventory_has_assert_release_and_mutations(self) -> None:
        profiles = runner.build_profiles()
        self.assertEqual(len(profiles), 2 + len(runner.MUTATIONS))
        baseline = [item for item in profiles if item.kind == "baseline"]
        mutation = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(
            {(item.name, item.assertions) for item in baseline},
            {
                ("production-assert", True),
                ("production-release", False),
            },
        )
        self.assertTrue(all(not item.assertions for item in mutation))

    def test_baseline_requires_every_exact_marker_once(self) -> None:
        profile = runner.Profile(
            "production-release", False, "baseline"
        )
        log = "\n".join(
            [
                *runner.BASELINE_MARKERS,
                runner.MATRIX_PASS,
                runner.TB_PASS,
            ]
        )
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=0,
            sim_timeout=False,
            log_text=log,
            artifact_exists=True,
        )
        self.assertTrue(passed)
        missing, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=0,
            sim_timeout=False,
            log_text=log.replace(
                "[V11M-HOLD-TUPLE][PASS]", "", 1
            ),
            artifact_exists=True,
        )
        self.assertFalse(missing)
        duplicate, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=0,
            sim_timeout=False,
            log_text=log + "\n[V11M-HOLD-TUPLE][PASS]\n",
            artifact_exists=True,
        )
        self.assertFalse(duplicate)

    def test_mutation_requires_compile_success_and_exact_stage(self) -> None:
        profile = runner.Profile(
            "reservation0-token-x-release",
            False,
            "mutation",
            mutation="reservation0-token-x",
            expected_stage="reservation0-holder-tuple",
        )
        exact = (
            runner.ORACLE_FAIL
            + " stage=reservation0-holder-tuple\n"
        )
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=1,
            sim_timeout=False,
            log_text=exact,
            artifact_exists=True,
        )
        self.assertTrue(passed)
        for crc, src, log, exists in (
            (1, None, exact, False),
            (0, 0, exact, True),
            (0, 1, runner.ORACLE_FAIL + "\n", True),
            (
                0,
                1,
                runner.ORACLE_FAIL
                + " stage=reservation1-holder-tuple\n",
                True,
            ),
            (0, 1, exact + runner.MATRIX_PASS, True),
            (0, 1, exact + runner.TB_PASS, True),
        ):
            rejected, _ = runner.evaluate_profile(
                profile,
                compile_rc=crc,
                compile_timeout=False,
                sim_rc=src,
                sim_timeout=False,
                log_text=log,
                artifact_exists=exists,
            )
            self.assertFalse(rejected)

        for compile_timeout, sim_timeout in (
            (True, False),
            (False, True),
        ):
            rejected, _ = runner.evaluate_profile(
                profile,
                compile_rc=0,
                compile_timeout=compile_timeout,
                sim_rc=1,
                sim_timeout=sim_timeout,
                log_text=exact,
                artifact_exists=True,
            )
            self.assertFalse(rejected)

        prefix_only, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=1,
            sim_timeout=False,
            log_text=(
                runner.ORACLE_FAIL
                + " stage=reservation0-holder-tuple-extra\n"
            ),
            artifact_exists=True,
        )
        self.assertFalse(prefix_only)

    def test_product_instance_is_exact(self) -> None:
        self.assertEqual(
            runner.PRODUCT_INSTANCE,
            (
                "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
                "u_decode_backend.u_int_backend"
            ),
        )

    def test_make_context_binds_testbench_and_common_inputs(self) -> None:
        testbench_dir = (
            self.repo_root / "npc" / "rv64" / "testbench"
        )
        include_dir, sources = runner.load_make_context(testbench_dir)
        relative = {
            path.relative_to(self.repo_root).as_posix()
            for path in sources
        }
        self.assertIn(
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            relative,
        )
        self.assertEqual(
            include_dir.relative_to(self.repo_root).as_posix(),
            "npc/rv64/vsrc/include",
        )
        contexts = runner.load_regression_context(testbench_dir)
        self.assertEqual(set(contexts), set(runner.REGRESSIONS))
        for paths in contexts.values():
            common = {
                path.relative_to(self.repo_root).as_posix()
                for path in paths
            }
            self.assertIn("npc/rv64/testbench/Makefile", common)
            self.assertIn("npc/rv64/vsrc/include/define.v", common)


if __name__ == "__main__":
    unittest.main()
