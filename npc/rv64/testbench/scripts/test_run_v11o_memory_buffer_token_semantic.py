#!/usr/bin/env python3

from __future__ import annotations

import unittest

import run_v11o_memory_buffer_token_semantic as runner


class V11OMemoryBufferTokenRunnerTest(unittest.TestCase):
    def test_profile_inventory(self) -> None:
        profiles = runner.build_profiles()
        self.assertEqual(len(profiles), 20)
        self.assertEqual(
            sum(profile.kind == "baseline" for profile in profiles), 4
        )
        self.assertEqual(
            sum(profile.kind == "mutation" for profile in profiles), 16
        )
        self.assertEqual(
            {profile.gen_width for profile in profiles}, {1, 4}
        )

    def test_every_mutation_changes_one_exact_anchor(self) -> None:
        rtl = (
            runner.Path(__file__).resolve().parents[2]
            / "vsrc/execute/OooIntBackend.v"
        ).read_text(encoding="utf-8")
        for mutation in runner.MUTATIONS:
            mutated, receipts = runner.apply_mutation(
                rtl, mutation.replacements
            )
            self.assertNotEqual(mutated, rtl, mutation.name)
            self.assertEqual(
                len(receipts), len(mutation.replacements), mutation.name
            )
            self.assertTrue(
                all(item["anchor_count"] == 1 for item in receipts),
                mutation.name,
            )

    def test_baseline_requires_exact_markers(self) -> None:
        profile = runner.Profile(
            "production-g4-assert", 4, True, "baseline"
        )
        log = "\n".join(
            [
                runner.TB_PASS,
                runner.MATRIX_PASS,
                *(
                    marker
                    for marker, count in runner.BASELINE_MARKERS.items()
                    for _ in range(count)
                ),
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
                "[V11O-LEGACY-TRANSFER-SQ-DEATH][PASS]", ""
            ),
            artifact_exists=True,
        )
        self.assertFalse(passed)

    def test_mutation_requires_exact_failure_stage(self) -> None:
        profile = runner.Profile(
            "lane1-g4-release",
            4,
            False,
            "mutation",
            mutation="lane1-capture-token-high-truncate",
            expected_stage="lane1-buffer-birth",
        )
        log = (
            runner.ORACLE_FAIL
            + " stage=lane1-buffer-birth @123\n"
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
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=1,
            sim_timeout=False,
            log_text=log.replace(
                "lane1-buffer-birth", "buffer-transfer-request"
            ),
            artifact_exists=True,
        )
        self.assertFalse(passed)


if __name__ == "__main__":
    unittest.main()
