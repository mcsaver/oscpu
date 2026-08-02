#!/usr/bin/env python3
"""Unit tests for the V11V FP producer lifecycle runner."""

from __future__ import annotations

import unittest
from pathlib import Path

import run_v11v_fp_producer_semantic as runner


class V11vFpProducerRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[4]
        cls.rtl_path = (
            cls.repo_root / "npc/rv64/vsrc/execute/OooFpBackend.v"
        )
        cls.source = cls.rtl_path.read_text(encoding="utf-8")
        cls.base_tb_source = (
            cls.repo_root / runner.BASE_TESTBENCH
        ).read_text(encoding="utf-8")
        cls.focused_fragment = (
            cls.repo_root / runner.FOCUSED_FRAGMENT
        ).read_text(encoding="utf-8")

    def test_all_mutation_anchors_are_unique_and_change_source(self) -> None:
        self.assertEqual(len(runner.MUTATIONS), 14)
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
        self.assertEqual(len(profiles), 32)
        self.assertEqual(len(baselines), 4)
        self.assertEqual(len(mutations), 28)
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
            "exec1-packet-pid-x-g4-release",
            4,
            False,
            "mutation",
            mutation="exec1-packet-pid-x",
            expected_stage="exec1-stage",
        )
        log = f"{runner.ORACLE_FAIL} stage=exec1-stage @100\n"
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
        for compile_rc, stage in ((1, "exec1-stage"), (0, "long-birth")):
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
            f"{runner.ORACLE_FAIL} stage=arith-stage1 @90\n"
            f"{runner.ORACLE_FAIL} stage=long-terminal-release @120\n"
        )
        self.assertEqual(
            runner.oracle_failure_stages(text),
            ["arith-stage1", "long-terminal-release"],
        )

    def test_every_gap_unit_has_positive_and_negative_scope(self) -> None:
        covered = {
            unit_id
            for mutation in runner.MUTATIONS
            for unit_id in mutation.unit_ids
        }
        self.assertEqual(covered, set(runner.UNIT_IDS))
        self.assertEqual(len(runner.UNIT_IDS), 7)

    def test_raw_identity_knownness_mutations_cover_every_holder_class(
        self,
    ) -> None:
        names = {item.name for item in runner.MUTATIONS if "pid-x" in item.name}
        self.assertEqual(
            names,
            {
                "iq-dispatch-pid-x",
                "issue-packet-pid-x",
                "arith-launch-pid-x",
                "exec1-packet-pid-x",
                "long-capture-pid-x",
                "done-fifo-pid-x",
            },
        )

    def test_lifecycle_mutations_cover_residency_and_terminal_release(
        self,
    ) -> None:
        names = {item.name for item in runner.MUTATIONS}
        self.assertTrue(
            {
                "iq-live-union-omitted",
                "issue-live-mask-omitted",
                "arith-live-mask-omitted",
                "exec1-live-mask-omitted",
                "long-live-mask-omitted",
                "done-pending-mask-omitted",
                "done-terminal-release-blocked",
            }.issubset(names)
        )

    def test_regressions_include_leaf_and_integrated_paths(self) -> None:
        self.assertIn("tb_ooo_fp_issue_queue", runner.REGRESSIONS)
        self.assertIn("tb_ooo_fp_arith_gate", runner.REGRESSIONS)
        self.assertIn("tb_ooo_int_backend", runner.REGRESSIONS)
        self.assertIn(
            "tb_ooo_int_backend_v11i_terminal_lifecycle",
            runner.REGRESSIONS,
        )

    def test_make_context_rules_are_self_contained_and_read_only(
        self,
    ) -> None:
        self.assertIn("$(TB_SRCS_tb_ooo_int_backend)", runner.MAKE_CONTEXT_RULE)
        self.assertNotIn("tb_ooo_int_backend_v11v", runner.MAKE_CONTEXT_RULE)
        for test in runner.REGRESSIONS:
            self.assertIn(
                f"REGRESSION_SOURCE_{test}",
                runner.MAKE_REGRESSION_CONTEXT_RULE,
            )

    def test_focused_testbench_overlay_is_unique_and_auditable(self) -> None:
        self.assertNotIn("V11V_FP_PRODUCER_FOCUSED", self.base_tb_source)
        rendered, receipts = runner.render_focused_testbench(
            self.base_tb_source, self.focused_fragment
        )
        self.assertEqual(len(receipts), 3)
        self.assertTrue(
            all(item["anchor_count"] == 1 for item in receipts)
        )
        self.assertEqual(
            rendered.count("run_v11v_fp_producer_semantic();"), 1
        )
        self.assertEqual(
            rendered.count(
                'tb_finish("tb_ooo_int_backend_v11v_fp_producer")'
            ),
            1,
        )


if __name__ == "__main__":
    unittest.main()
