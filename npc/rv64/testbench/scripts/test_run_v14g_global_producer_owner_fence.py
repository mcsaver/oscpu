#!/usr/bin/env python3
"""Unit tests for the V14G global ProducerId owner-fence runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v14g_global_producer_owner_fence as runner


class V14gGlobalOwnerFenceRunnerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]

    def test_every_mutation_anchor_is_unique_and_changes_source(self) -> None:
        names: set[str] = set()
        for mutation in runner.MUTATIONS:
            self.assertNotIn(mutation.name, names)
            names.add(mutation.name)
            source = (self.repo_root / mutation.target).read_text(
                encoding="utf-8"
            )
            mutated, receipt = runner.apply_mutation(source, mutation)
            self.assertNotEqual(mutated, source)
            self.assertEqual(receipt["anchor_count"], 1)
            self.assertNotEqual(
                receipt["mutated_source_sha256"],
                runner.sha256_bytes(source.encode("utf-8")),
            )

    def test_mutations_cover_union_lanes_generation_and_edges(self) -> None:
        names = {item.name for item in runner.MUTATIONS}
        self.assertEqual(len(names), 11)
        self.assertEqual(
            names,
            {
                "int-iq-mask-drops-on-fire",
                "dispatch-drops-external-union",
                "backend-drops-load-queue-union",
                "backend-drops-reservation-union",
                "backend-drops-memory-owner-union",
                "backend-lane6-corrupts-reservation-token",
                "backend-drops-pending-system-union",
                "dispatch-lane0-truncates-generation",
                "dispatch-mandatory-lane1-truncates-generation",
                "dispatch-optional-lane1-truncates-generation",
                "tracker-clears-producer-on-death-edge",
            },
        )
        stages = {item.expected_stage for item in runner.MUTATIONS}
        self.assertTrue(
            {
                "birth-edge-old",
                "memory-capture-int-iq-holder",
                "birth-owner-only",
                "load-queue-union",
                "reservation-union",
                "collector-pending-owner-only",
                "terminal-lane6-ingress",
                "pending-system-union",
                "lane1-mandatory",
                "lane1-optional",
                "death-edge-old",
            }
            <= stages
        )

    def test_profile_inventory_is_two_widths_assert_release_and_mutations(self) -> None:
        profiles = runner.build_profiles()
        baseline = [item for item in profiles if item.kind == "baseline"]
        mutation = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(len(baseline), 4)
        self.assertEqual(len(mutation), 2 * len(runner.MUTATIONS))
        self.assertEqual(
            {
                (item.generation_width, item.assertions)
                for item in baseline
            },
            {(4, True), (4, False), (1, True), (1, False)},
        )
        self.assertTrue(all(not item.assertions for item in mutation))

    def test_baseline_requires_each_marker_exactly_once(self) -> None:
        profile = runner.Profile(
            "gen4-production-release", 4, False, "baseline"
        )
        log = "\n".join(runner.BASELINE_MARKERS)
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
        for changed in (
            log.replace(runner.BASELINE_MARKERS[0], "", 1),
            log + "\n" + runner.BASELINE_MARKERS[0],
            log + "\n" + runner.ORACLE_FAIL + " stage=unexpected",
        ):
            rejected, _ = runner.evaluate_profile(
                profile,
                compile_rc=0,
                compile_timeout=False,
                sim_rc=0,
                sim_timeout=False,
                log_text=changed,
                artifact_exists=True,
            )
            self.assertFalse(rejected)

    def test_mutation_requires_compile_success_and_exact_oracle_stage(self) -> None:
        profile = runner.Profile(
            "gen1-tracker-release",
            1,
            False,
            "mutation",
            mutation="tracker-clears-producer-on-death-edge",
            expected_stage="death-edge-old",
        )
        exact = runner.ORACLE_FAIL + " stage=death-edge-old gen_w=1"
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
        for crc, compile_timeout, src, sim_timeout, log, exists in (
            (1, False, None, False, exact, False),
            (0, True, None, False, exact, True),
            (0, False, 0, False, exact, True),
            (0, False, 1, True, exact, True),
            (
                0,
                False,
                1,
                False,
                runner.ORACLE_FAIL + " stage=birth-edge-old",
                True,
            ),
            (0, False, 1, False, exact + "\n" + exact, True),
            (0, False, 1, False, exact + "\n" + runner.GLOBAL_PASS, True),
        ):
            rejected, _ = runner.evaluate_profile(
                profile,
                compile_rc=crc,
                compile_timeout=compile_timeout,
                sim_rc=src,
                sim_timeout=sim_timeout,
                log_text=log,
                artifact_exists=exists,
            )
            self.assertFalse(rejected)

    def test_make_context_binds_tb_and_all_mutation_targets(self) -> None:
        testbench_dir = self.repo_root / "npc" / "rv64" / "testbench"
        include_dir, sources = runner.load_make_context(testbench_dir)
        relative = {
            item.relative_to(self.repo_root).as_posix() for item in sources
        }
        self.assertIn(
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv", relative
        )
        self.assertEqual(
            include_dir.relative_to(self.repo_root).as_posix(),
            "npc/rv64/vsrc/include",
        )
        for mutation in runner.MUTATIONS:
            self.assertIn(mutation.target, relative)

    def test_overlay_injection_keeps_base_immutable_and_binds_three_sites(self) -> None:
        base_path = self.repo_root / runner.BASE_TB_REL
        overlay_path = self.repo_root / runner.OVERLAY_REL
        base = base_path.read_text(encoding="utf-8")
        overlay = overlay_path.read_text(encoding="utf-8")

        generated, receipts = runner.inject_overlay(base, overlay)

        self.assertEqual(runner.sha256_bytes(base.encode("utf-8")),
                         runner.sha256_file(base_path))
        self.assertEqual(len(receipts), 3)
        self.assertTrue(all(item["anchor_count"] == 1 for item in receipts))
        task_signature = "task run_v14g_global_producer_owner_fence;"
        self.assertEqual(generated.count(task_signature), 1)
        self.assertEqual(
            generated.count("`elsif V14G_GLOBAL_OWNER_FENCE_FOCUSED"),
            2,
        )
        self.assertEqual(
            generated.count(
                'tb_finish("tb_ooo_int_backend_v14g_global_owner_fence")'
            ),
            1,
        )
        self.assertLess(
            generated.index("`elsif V14G_GLOBAL_OWNER_FENCE_FOCUSED"),
            generated.index("`elsif V8P_PAIR_MATRIX_FOCUSED"),
        )
        self.assertNotIn(
            task_signature, base
        )

    def test_bounded_log_keeps_tail_and_marks_truncation(self) -> None:
        original = "head\n" + ("x" * 200) + "\nTAIL"
        bounded = runner.bounded_text(original, 96)
        self.assertLessEqual(len(bounded.encode("utf-8")), 96)
        self.assertIn("[V14G-LOG-TRUNCATED]", bounded)
        self.assertTrue(bounded.endswith("TAIL"))


if __name__ == "__main__":
    unittest.main()
