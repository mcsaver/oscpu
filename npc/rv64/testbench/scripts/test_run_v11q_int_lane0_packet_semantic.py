#!/usr/bin/env python3
"""Unit tests for the V11Q integer lane0 packet runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11q_int_lane0_packet_semantic as runner


class V11qIntLane0PacketRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.rtl_path = (
            cls.repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
        )
        cls.source = cls.rtl_path.read_text(encoding="utf-8")

    def test_all_mutation_anchors_are_unique_and_change_source(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 12)
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
        self.assertEqual(len(profiles), 28)
        baselines = [item for item in profiles if item.kind == "baseline"]
        mutations = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(len(baselines), 4)
        self.assertEqual(len(mutations), 24)
        self.assertEqual({item.gen_width for item in profiles}, {1, 4})
        self.assertTrue(all(not item.assertions for item in mutations))

    def test_baseline_requires_each_exact_marker(self) -> None:
        profile = runner.Profile(
            "production-g4-release", 4, False, "baseline"
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
        for marker in runner.BASELINE_MARKERS:
            passed, _ = runner.evaluate_profile(
                profile,
                compile_rc=0,
                compile_timeout=False,
                sim_rc=0,
                sim_timeout=False,
                log_text=log.replace(marker, "", 1),
                artifact_exists=True,
            )
            self.assertFalse(passed, marker)

    def test_mutation_requires_compile_success_and_exact_stage(self) -> None:
        profile = runner.Profile(
            "branch-coherence-index-only-g4-release",
            4,
            False,
            "mutation",
            mutation="branch-coherence-index-only",
            expected_stage="branch-wrong-generation-fence",
        )
        log = (
            f"{runner.ORACLE_FAIL} "
            "stage=branch-wrong-generation-fence @100\n"
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
            (1, "branch-wrong-generation-fence"),
            (0, "branch-down-pid"),
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
            f"{runner.ORACLE_FAIL} stage=alu-down-packet-pid @90\n"
            f"{runner.ORACLE_FAIL} stage=branch-flush-cut @120\n"
        )
        self.assertEqual(
            runner.oracle_failure_stages(text),
            ["alu-down-packet-pid", "branch-flush-cut"],
        )

    def test_mutations_cover_exact_bounded_units(self) -> None:
        self.assertEqual(
            set(runner.UNIT_IDS),
            {
                "integer-ex0-packed-alias",
                "integer-ex0-packet",
                "branch-resolve-packet",
            },
        )
        covered = {
            unit
            for mutation in runner.MUTATIONS
            for unit in mutation.unit_ids
        }
        self.assertEqual(covered, set(runner.UNIT_IDS))
        self.assertTrue(
            all(
                set(mutation.unit_ids).issubset(set(runner.UNIT_IDS))
                for mutation in runner.MUTATIONS
            )
        )


if __name__ == "__main__":
    unittest.main()
