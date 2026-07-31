#!/usr/bin/env python3
"""Unit tests for the V11N AMO pending-holder semantic runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11n_memory_pending_holder_semantic as runner


class V11nMemoryPendingHolderRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.rtl_path = (
            cls.repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
        )
        cls.source = cls.rtl_path.read_text(encoding="utf-8")

    def test_all_mutation_anchors_are_unique_and_change_source(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 13)
        for mutation in runner.MUTATIONS:
            mutated, receipts = runner.apply_mutation(
                self.source, mutation.replacements
            )
            self.assertNotEqual(mutated, self.source, mutation.name)
            self.assertTrue(receipts, mutation.name)
            self.assertTrue(
                all(item["anchor_count"] == 1 for item in receipts),
                mutation.name,
            )

    def test_profile_inventory_covers_two_widths(self) -> None:
        profiles = runner.build_profiles()
        self.assertEqual(len(profiles), 30)
        baselines = [item for item in profiles if item.kind == "baseline"]
        mutations = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(len(baselines), 4)
        self.assertEqual(len(mutations), 26)
        self.assertEqual({item.gen_width for item in profiles}, {1, 4})
        self.assertTrue(all(not item.assertions for item in mutations))

    def test_baseline_requires_exact_markers(self) -> None:
        profile = runner.Profile(
            "production-g4-release", 4, False, "baseline"
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
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=0,
            sim_timeout=False,
            log_text=log.replace(
                "[V11N-READ-WRITE-HOLD][PASS]", "", 1
            ),
            artifact_exists=True,
        )
        self.assertFalse(passed)

    def test_mutation_requires_compile_success_and_exact_stage(self) -> None:
        profile = runner.Profile(
            "capture-token-high-truncate-g4-release",
            4,
            False,
            "mutation",
            mutation="capture-token-high-truncate",
            expected_stage="amo-read-pending-birth",
        )
        log = (
            f"{runner.ORACLE_FAIL} "
            "stage=amo-read-pending-birth @100\n"
        )
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=1,
            sim_timeout=False,
            log_text=log,
            artifact_exists=True,
        )
        self.assertTrue(passed)
        for compile_rc, stage in (
            (1, "amo-read-pending-birth"),
            (0, "post-write-hold"),
        ):
            passed, _ = runner.evaluate_profile(
                profile,
                compile_rc=compile_rc,
                compile_timeout=False,
                sim_rc=1,
                sim_timeout=False,
                log_text=f"{runner.ORACLE_FAIL} stage={stage} @100\n",
                artifact_exists=True,
            )
            self.assertFalse(passed)

    def test_oracle_failure_parser_is_exact(self) -> None:
        text = (
            f"{runner.ORACLE_FAIL} stage=post-write-hold @90\n"
            f"{runner.ORACLE_FAIL} stage=amo-interphase-lane9 @120\n"
        )
        self.assertEqual(
            runner.oracle_failure_stages(text),
            ["post-write-hold", "amo-interphase-lane9"],
        )

    def test_unit_ids_are_exact_pending_units(self) -> None:
        self.assertEqual(
            set(runner.UNIT_IDS),
            {
                "memory-pending-producer-cache",
                "memory-pending-token",
            },
        )
        self.assertTrue(
            all(
                set(mutation.unit_ids).issubset(set(runner.UNIT_IDS))
                for mutation in runner.MUTATIONS
            )
        )


if __name__ == "__main__":
    unittest.main()
