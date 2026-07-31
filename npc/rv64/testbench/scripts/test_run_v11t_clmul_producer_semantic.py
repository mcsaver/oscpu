#!/usr/bin/env python3
"""Unit tests for the V11T CLMUL producer lifecycle runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11t_clmul_producer_semantic as runner


class V11tClmulProducerRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.rtl_path = (
            cls.repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
        )
        cls.source = cls.rtl_path.read_text(encoding="utf-8")
        cls.base_tb_source = (
            cls.repo_root / runner.BASE_TESTBENCH
        ).read_text(encoding="utf-8")
        cls.focused_fragment = (
            cls.repo_root / runner.FOCUSED_FRAGMENT
        ).read_text(encoding="utf-8")

    def test_all_mutation_anchors_are_unique_and_change_source(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 9)
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
        baselines = [item for item in profiles if item.kind == "baseline"]
        mutations = [item for item in profiles if item.kind == "mutation"]
        self.assertEqual(len(profiles), 22)
        self.assertEqual(len(baselines), 4)
        self.assertEqual(len(mutations), 18)
        self.assertEqual({item.gen_width for item in profiles}, {1, 4})
        self.assertTrue(all(not item.assertions for item in mutations))

    def test_baseline_requires_exact_marker_multiplicity(self) -> None:
        profile = runner.Profile(
            "production-g4-release", 4, False, "baseline"
        )
        lines: list[str] = []
        for marker, count in runner.BASELINE_MARKERS.items():
            lines.extend([marker] * count)
        lines.extend([runner.MATRIX_PASS, runner.TB_PASS])
        log = "\n".join(lines)
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
            "completion-bypasses-exact-open-g4-release",
            4,
            False,
            "mutation",
            mutation="completion-bypasses-exact-open",
            expected_stage="wrong-generation-authorization",
        )
        log = (
            f"{runner.ORACLE_FAIL} "
            "stage=wrong-generation-authorization @100\n"
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
            (1, "wrong-generation-authorization"),
            (0, "terminal-authorization"),
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
            f"{runner.ORACLE_FAIL} stage=request-buffer-birth @90\n"
            f"{runner.ORACLE_FAIL} stage=terminal-release @120\n"
        )
        self.assertEqual(
            runner.oracle_failure_stages(text),
            ["request-buffer-birth", "terminal-release"],
        )

    def test_mutations_cover_lifecycle_stages(self) -> None:
        stages = {item.expected_stage for item in runner.MUTATIONS}
        self.assertEqual(
            stages,
            {
                "request-buffer-birth",
                "iterative-hold-live-mask",
                "terminal-authorization",
                "wrong-generation-authorization",
                "terminal-release",
                "terminal-wb-identity",
                "flush-death",
            },
        )

    def test_scope_is_exactly_clmul_producer(self) -> None:
        self.assertEqual(runner.UNIT_IDS, ("clmul-producer",))
        self.assertTrue(
            all(item.unit_ids == runner.UNIT_IDS for item in runner.MUTATIONS)
        )
        self.assertTrue(runner.PRODUCT_INSTANCE.endswith(".u_clmul_unit"))

    def test_regressions_include_leaf_and_integrated_paths(self) -> None:
        self.assertIn("tb_ooo_clmul_unit", runner.REGRESSIONS)
        self.assertIn("tb_ooo_int_backend", runner.REGRESSIONS)
        self.assertIn(
            "tb_ooo_int_backend_v11r_int_lane1_packet",
            runner.REGRESSIONS,
        )

    def test_make_context_rules_are_self_contained_and_read_only(
        self,
    ) -> None:
        self.assertIn("$(TB_SRCS_tb_ooo_int_backend)", runner.MAKE_CONTEXT_RULE)
        self.assertNotIn(
            "tb_ooo_int_backend_v11t", runner.MAKE_CONTEXT_RULE
        )
        for test in runner.REGRESSIONS:
            self.assertIn(
                f"REGRESSION_SOURCE_{test}",
                runner.MAKE_REGRESSION_CONTEXT_RULE,
            )

    def test_focused_testbench_overlay_is_unique_and_auditable(
        self,
    ) -> None:
        self.assertNotIn(
            "V11T_CLMUL_PRODUCER_FOCUSED", self.base_tb_source
        )
        rendered, receipts = runner.render_focused_testbench(
            self.base_tb_source, self.focused_fragment
        )
        self.assertEqual(len(receipts), 3)
        self.assertTrue(
            all(item["anchor_count"] == 1 for item in receipts)
        )
        self.assertEqual(
            rendered.count("run_v11t_clmul_producer_semantic();"), 1
        )
        self.assertEqual(
            rendered.count(
                'tb_finish("tb_ooo_int_backend_v11t_clmul_producer")'
            ),
            1,
        )


if __name__ == "__main__":
    unittest.main()
