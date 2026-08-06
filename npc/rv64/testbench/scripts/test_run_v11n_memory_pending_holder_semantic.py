#!/usr/bin/env python3
"""Unit tests for the V11N AMO pending-holder semantic runner."""

from __future__ import annotations

import unittest
from tempfile import TemporaryDirectory
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
        self.assertEqual(len(runner.MUTATIONS), 16)
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
        self.assertEqual(len(profiles), 36)
        baselines = [item for item in profiles if item.kind == "baseline"]
        mutations = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(len(baselines), 4)
        self.assertEqual(len(mutations), 32)
        self.assertEqual({item.gen_width for item in profiles}, {1, 4})
        self.assertEqual(sum(item.assertions for item in mutations), 6)
        self.assertEqual(sum(not item.assertions for item in mutations), 26)

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

    def test_v14u_mutation_requires_exact_assertion_marker(self) -> None:
        profile = runner.Profile(
            "amo-read-aliases-reservation0-g4-assert",
            4,
            True,
            "mutation",
            mutation="amo-read-aliases-reservation0",
            expected_marker=runner.V14U_ASSERT_FAIL,
            expected_holder="res0",
        )
        passed, _ = runner.evaluate_profile(
            profile,
            compile_rc=0,
            compile_timeout=False,
            sim_rc=1,
            sim_timeout=False,
            log_text=(
                f"{runner.V14U_ASSERT_FAIL} overlap=10000000 "
                "amo=1/28 res0=1/28 res1=0/0 buffer=0/0 @134\n"
            ),
            artifact_exists=True,
        )
        self.assertTrue(passed)
        for log in (
            "",
            f"{runner.V14U_ASSERT_FAIL}\n{runner.V14U_ASSERT_FAIL}\n",
            f"{runner.ORACLE_FAIL} stage=read-hold\n",
            (
                f"{runner.V14U_ASSERT_FAIL} overlap=10000000 "
                "amo=1/28 res0=0/28 res1=1/28 buffer=0/0 @134\n"
            ),
        ):
            passed, _ = runner.evaluate_profile(
                profile,
                compile_rc=0,
                compile_timeout=False,
                sim_rc=1,
                sim_timeout=False,
                log_text=log,
                artifact_exists=True,
            )
            self.assertFalse(passed)

    def test_unit_ids_are_exact_pending_units(self) -> None:
        self.assertEqual(
            set(runner.UNIT_IDS),
            {
                "memory-pending-producer-cache",
                "memory-pending-token",
                "amo-transient-holder-disjoint",
            },
        )
        self.assertTrue(
            all(
                set(mutation.unit_ids).issubset(set(runner.UNIT_IDS))
                for mutation in runner.MUTATIONS
            )
        )

    def test_pass_cleanup_retains_logs_and_removes_only_intermediates(self) -> None:
        with TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            result_dir = repo_root / "result"
            profile_image = (
                result_dir / "profiles/p0" / f"{runner.TOP}.vvp"
            )
            regression_image = (
                result_dir / "regressions/build/r0.vvp"
            )
            variant = result_dir / "variants/m0/OooIntBackend.v"
            retained_log = result_dir / "profiles/p0/sim.log"
            for path in (
                profile_image, regression_image, variant, retained_log
            ):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(path.name.encode("utf-8"))

            cleanup = runner.cleanup_pass_artifacts(
                repo_root=repo_root,
                result_dir=result_dir,
                profile_records=[{"profile": "p0"}],
                regression_records=[{"test": "r0"}],
                variants={"m0": variant},
            )
            self.assertEqual(cleanup["status"], "PASS")
            self.assertEqual(cleanup["removed_count"], 3)
            self.assertEqual(cleanup["retained_compile_images"], 0)
            self.assertFalse(profile_image.exists())
            self.assertFalse(regression_image.exists())
            self.assertFalse(variant.exists())
            self.assertTrue(retained_log.is_file())
            self.assertTrue((result_dir / "artifact-cleanup.json").is_file())

    def test_cleanup_preflight_rejects_escape_without_partial_delete(self) -> None:
        with TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            result_dir = repo_root / "result"
            profile_image = (
                result_dir / "profiles/p0" / f"{runner.TOP}.vvp"
            )
            escaped_variant = repo_root / "outside/OooIntBackend.v"
            for path in (profile_image, escaped_variant):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture\n", encoding="utf-8")
            with self.assertRaisesRegex(
                RuntimeError, "escapes result directory"
            ):
                runner.cleanup_pass_artifacts(
                    repo_root=repo_root,
                    result_dir=result_dir,
                    profile_records=[{"profile": "p0"}],
                    regression_records=[],
                    variants={"escape": escaped_variant},
                )
            self.assertTrue(profile_image.is_file())
            self.assertTrue(escaped_variant.is_file())


if __name__ == "__main__":
    unittest.main()
