#!/usr/bin/env python3
"""Regression tests for fail-closed PPA policy gates."""

from __future__ import annotations

import copy
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import tempfile
import unittest

TEST_DIR = pathlib.Path(__file__).resolve().parent
PPA_DIR = TEST_DIR.parent
FIXTURE_DIR = TEST_DIR / "fixtures"
TOOLS_DIR = PPA_DIR / "tools"
sys.path.insert(0, str(TOOLS_DIR))

import check  # noqa: E402
import compare  # noqa: E402
import front  # noqa: E402
import architecture_seed  # noqa: E402


class PolicyGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy_path = (
            PPA_DIR / "policies" / "proxy-200mhz-v1.json")
        cls.policy = json.loads(cls.policy_path.read_text(encoding="utf-8"))
        cls.counterexamples = json.loads(
            (TEST_DIR / "counterexamples.json").read_text(encoding="utf-8")
        )["cases"]

    def test_architecture_policy_covers_all_nine_executable_gates(self) -> None:
        architecture = self.policy["architecture"]
        self.assertEqual(architecture["minimum_rob_peak"], 9)
        self.assertEqual(
            architecture["required_directed_evidence"],
            [
                "frontend_ii1",
                "width_continuity",
                "pair_matrix",
                "no_static_lane_semantics",
                "dual_memory_issue",
                "true_ooo_long_latency",
                "selective_scheduling",
                "memory_ordering",
                "speculation_recovery",
            ],
        )
        required = set(self.policy["required_artifact_kinds"])
        self.assertIn("architecture_directed_suite", required)
        self.assertIn("architecture_hard_gates_result", required)
        for evidence in architecture["required_directed_evidence"]:
            self.assertIn(f"architecture_{evidence}", required)

    def test_r3p6_is_explicit_nonpromotable_recovery_baseline(self) -> None:
        baseline_dir = PPA_DIR / "baselines"
        index = json.loads(
            (baseline_dir / "index.json").read_text(encoding="utf-8"))
        self.assertIsNone(index["canonical"])
        self.assertEqual(
            index["engineering_recovery_baseline"],
            "r3p6-recovery-baseline.json",
        )
        seed_transition = index["architecture_feasible_seed_transition"]
        self.assertFalse(seed_transition["second_transition_allowed"])
        self.assertFalse(
            seed_transition["unqualified_power_front_accepted"])
        self.assertFalse(seed_transition["unqualified_power_canonical"])
        self.assertFalse(
            seed_transition["unqualified_power_ppa_champion"])
        self.assertFalse(
            seed_transition["unqualified_total_area_front_accepted"])
        self.assertFalse(
            seed_transition["unqualified_total_area_canonical"])
        baseline = json.loads(
            (baseline_dir / index["engineering_recovery_baseline"])
            .read_text(encoding="utf-8"))
        self.assertEqual(
            baseline["status"], "engineering_recovery_baseline")
        self.assertFalse(baseline["promotable"])
        self.assertEqual(baseline["performance"]["repetitions"], 3)
        self.assertTrue(
            baseline["performance"]["bit_exact_repetition_counters"])
        self.assertEqual(
            baseline["architecture_contract"]["memory_issue_width"], 1)
        self.assertFalse(
            baseline["architecture_contract"]["hard_gates_all_green"])
        self.assertGreaterEqual(
            baseline["timing"]["worst_path_slack_ns"],
            baseline["timing"]["minimum_promotion_reserve_ns"],
        )
        self.assertFalse(baseline["power"]["qualified_for_promotion"])

    def test_r4_s0_is_only_an_implementation_correctness_checkpoint(self) -> None:
        baseline_dir = PPA_DIR / "baselines"
        index = json.loads(
            (baseline_dir / "index.json").read_text(encoding="utf-8"))
        self.assertIsNone(index["canonical"])
        self.assertIsNone(index["architecture_feasible_seed"])
        self.assertEqual(
            index["implementation_correctness_checkpoints"],
            [
                "r4-s0-correctness-checkpoint.json",
                "r4-p0a-timing-recovery-checkpoint.json",
            ],
        )
        checkpoint = json.loads(
            (baseline_dir / "r4-s0-correctness-checkpoint.json")
            .read_text(encoding="utf-8"))
        self.assertEqual(checkpoint["status"], "correctness_checkpoint")
        self.assertEqual(
            checkpoint["comparison_role"],
            "semantic_floor_not_pareto_baseline",
        )
        self.assertFalse(checkpoint["promotable"])
        self.assertFalse(
            checkpoint["architecture_contract"]["hard_gates_all_green"])
        self.assertEqual(
            checkpoint["architecture_contract"]["blocking_gates"],
            [
                "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
                "OOO-1", "OOO-2", "OOO-3", "OOO-4",
            ],
        )
        self.assertTrue(checkpoint["timing"]["target_200mhz_met"])
        self.assertFalse(checkpoint["timing"]["reserve_met"])
        self.assertFalse(checkpoint["power"]["qualified_for_promotion"])

    def test_r4_p0a_is_frozen_as_nonpromotable_timing_checkpoint(self) -> None:
        baseline_dir = PPA_DIR / "baselines"
        index = json.loads(
            (baseline_dir / "index.json").read_text(encoding="utf-8"))
        self.assertIsNone(index["canonical"])
        self.assertIsNone(index["architecture_feasible_seed"])
        self.assertEqual(
            index["engineering_recovery_baseline"],
            "r3p6-recovery-baseline.json",
        )
        checkpoint_name = "r4-p0a-timing-recovery-checkpoint.json"
        self.assertIn(
            checkpoint_name,
            index["implementation_correctness_checkpoints"],
        )
        checkpoint = json.loads(
            (baseline_dir / checkpoint_name).read_text(encoding="utf-8"))
        self.assertEqual(checkpoint["status"], "correctness_checkpoint")
        self.assertEqual(checkpoint["checkpoint_kind"], "timing_recovery")
        self.assertFalse(checkpoint["promotable"])
        self.assertEqual(
            checkpoint["comparison_role"],
            "timing_and_semantic_floor_not_seed_not_pareto_baseline",
        )
        self.assertEqual(
            set(checkpoint["forbidden_claims"]),
            {
                "architecture_feasible_seed",
                "pareto_front_member",
                "front_accepted_baseline",
                "canonical_baseline",
                "proxy_champion",
                "final_champion",
                "qualified_power_improvement",
            },
        )
        self.assertTrue(all(
            eligible is False
            for eligible in checkpoint["eligibility"].values()
        ))
        expected_gates = [
            "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
            "OOO-1", "OOO-2", "OOO-3", "OOO-4",
        ]
        architecture = checkpoint["architecture_contract"]
        self.assertFalse(architecture["hard_gates_all_green"])
        self.assertEqual(architecture["hard_gate_result"], "RED")
        self.assertEqual(architecture["blocking_gates"], expected_gates)
        self.assertEqual(
            architecture["gate_results"],
            {gate: "RED" for gate in expected_gates},
        )
        self.assertFalse(architecture["directed_evidence_present"])
        self.assertEqual(architecture["memory_issue_width"], 1)
        self.assertEqual(architecture["lq_entries"], 0)

        self.assertEqual(
            checkpoint["performance"]["interleaved_ab_sequence"],
            ["A", "B", "B", "A", "A", "B"],
        )
        self.assertTrue(
            checkpoint["performance"]
            ["runtime_images_in_every_pre_post_binding"]
        )
        self.assertEqual(
            [benchmark["throughput_ratio_vs_r3p6"]
             for benchmark in checkpoint["performance"]["benchmarks"]],
            [1.0, 1.0],
        )
        self.assertTrue(checkpoint["timing"]["target_200mhz_met"])
        self.assertTrue(checkpoint["timing"]["reserve_met"])
        self.assertAlmostEqual(
            checkpoint["timing"]["worst_path_slack_ns"],
            0.103599802,
            places=9,
        )
        self.assertAlmostEqual(
            checkpoint["area"]["logic_area"], 1606094.84, places=2)
        self.assertFalse(checkpoint["power"]["qualified_for_promotion"])
        self.assertFalse(checkpoint["power"]["eligible_for_power_claim"])
        self.assertIsNone(checkpoint["power"]["total_power_w"])
        normative_contract = checkpoint["provenance"][
            "normative_architecture_contract"
        ]
        self.assertEqual(normative_contract["version"], "v2")
        self.assertEqual(
            normative_contract["path"],
            "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
        )

        artifacts = checkpoint["artifacts"]
        self.assertEqual(len({item["kind"] for item in artifacts}),
                         len(artifacts))
        aggregate = next(
            item for item in artifacts
            if item["kind"] == "checkpoint_aggregate_audit_v2"
        )
        self.assertEqual(
            aggregate["sha256"],
            "2847ae2e1b075ba7743cc8affb1220f185eed4e0dbe176fda0fe2aac6ba54fb8",
        )
        workspace_root = PPA_DIR.parents[3]
        aggregate_result = json.loads(
            (workspace_root / aggregate["path"]).read_text(encoding="utf-8")
        )
        self.assertEqual(
            aggregate_result["schema"],
            "npc-rv64-r4-p0a-checkpoint-audit-v2",
        )
        self.assertEqual(aggregate_result["result"], "PASS")
        self.assertEqual(
            checkpoint["design_id"],
            aggregate_result["architecture"]["design_id"],
        )
        self.assertEqual(
            architecture["blocking_gates"],
            aggregate_result["architecture"]["blocking_gates"],
        )
        self.assertEqual(
            checkpoint["provenance"]
            ["synthesis_elaborated_rtl_input_count"],
            aggregate_result["area"]["live_rtl_manifest_entries"],
        )
        self.assertEqual(
            checkpoint["area"]["logic_area"],
            aggregate_result["area"]["logic_area"],
        )
        self.assertEqual(
            checkpoint["timing"]["worst_path_slack_ns"],
            aggregate_result["timing"]["worst_path_slack_ns"],
        )
        self.assertEqual(
            checkpoint["power"]["diagnostic_vectorless_logic_proxy_w"],
            aggregate_result["power"]
            ["diagnostic_vectorless_logic_proxy_w"],
        )
        self.assertEqual(
            [benchmark["cycles"]
             for benchmark in checkpoint["performance"]["benchmarks"]],
            [
                aggregate_result["performance"]["coremark"]["cycles"],
                aggregate_result["performance"]
                ["dhrystone_10000"]["cycles"],
            ],
        )
        for artifact in artifacts:
            with self.subTest(artifact=artifact["kind"]):
                path = workspace_root / artifact["path"]
                self.assertTrue(check.is_sha256(artifact["sha256"]))
                if artifact["kind"] == "normative_architecture_ppa_contract_v2":
                    # This is an intentionally live normative pointer.  The
                    # checkpoint keeps its historical digest, while later
                    # contract revisions must not rewrite the old record.
                    self.assertTrue(path.is_file(), artifact["path"])
                    continue
                if artifact["path"].startswith("tmp/"):
                    # Reproducible simulator/synthesis intermediates may be
                    # removed by retention.  If present, they must still match
                    # the frozen digest; their absence cannot promote this
                    # explicitly nonpromotable checkpoint.
                    if path.is_file():
                        self.assertEqual(
                            hashlib.sha256(path.read_bytes()).hexdigest(),
                            artifact["sha256"],
                        )
                    continue
                self.assertTrue(path.is_file(), artifact["path"])
                self.assertEqual(
                    hashlib.sha256(path.read_bytes()).hexdigest(),
                    artifact["sha256"],
                )

    def test_three_score_counterexamples_are_rejected(self) -> None:
        for case in self.counterexamples:
            with self.subTest(case=case["id"]):
                result = compare.evaluate_ratios(
                    per_benchmark_ratio=case["per_benchmark_ratio"],
                    performance_ratio=case["performance_ratio"],
                    area_ratio=case["area_ratio"],
                    power_ratio=case["power_ratio"],
                    timing_ok=True,
                    target=case["target"],
                    policy=self.policy,
                    checker_audited=True,
                )
                self.assertEqual(
                    result["pareto_relation_on_qualified_axes"],
                    case["expected_relation"],
                )
                self.assertFalse(result["pairwise_promotion_eligible"])
                self.assertIn(
                    case["expected_blocker"],
                    result["pairwise_promotion_blockers"],
                )

    def test_clean_three_axis_dominating_candidate_is_pairwise_eligible(
            self) -> None:
        result = compare.evaluate_ratios(
            per_benchmark_ratio={
                "coremark": 1.02,
                "dhrystone_10000": 1.02,
            },
            performance_ratio=1.02,
            area_ratio=1.01,
            power_ratio=1.01,
            timing_ok=True,
            target="final_champion",
            policy=self.policy,
            checker_audited=True,
        )
        self.assertEqual(
            result["pareto_relation_on_qualified_axes"],
            "candidate_dominates",
        )
        self.assertTrue(result["all_qualified_axis_floors_met"])
        self.assertTrue(result["pairwise_promotion_eligible"])

    def test_global_front_eliminates_candidate_dominated_by_third_design(
            self) -> None:
        objectives = [
            {
                "baseline_id": "accepted",
                "performance": 100.0,
                "area": 100.0,
                "power": None,
            },
            {
                "baseline_id": "candidate-a",
                "performance": 102.0,
                "area": 99.0,
                "power": None,
            },
            {
                "baseline_id": "candidate-b",
                "performance": 101.0,
                "area": 99.5,
                "power": None,
            },
        ]
        _, eps = compare.promotion_config(self.policy)
        pareto_front, dominated_by = front.global_pareto(objectives, eps)
        self.assertEqual(pareto_front, ["candidate-a"])
        self.assertIn("candidate-a", dominated_by["candidate-b"])

    def test_bool_is_not_an_integer_counter(self) -> None:
        self.assertFalse(check.strict_nonnegative_int(False))
        self.assertFalse(check.strict_positive_int(True))
        self.assertTrue(check.strict_nonnegative_int(0))
        self.assertTrue(check.strict_positive_int(1))

    def test_checker_exit_policy_is_strict_by_default(self) -> None:
        self.assertEqual(check.checker_exit_code([], ["blocked"], False), 1)
        self.assertEqual(check.checker_exit_code([], ["blocked"], True), 0)
        self.assertEqual(check.checker_exit_code(["broken"], [], True), 1)


    def test_global_front_exit_policy_is_strict_by_default(self) -> None:
        self.assertEqual(front.front_exit_code(None, None, False), 1)
        self.assertEqual(front.front_exit_code(None, None, True), 0)
        self.assertEqual(front.front_exit_code("a", "a", False), 0)
        self.assertEqual(front.front_exit_code("a", "b", False), 1)


class ArchitectureFeasibleSeedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        cls.anchor = json.loads(
            (PPA_DIR / "baselines" / "r3p6-recovery-baseline.json")
            .read_text(encoding="utf-8"))
        cls.index = json.loads(
            (PPA_DIR / "baselines" / "index.json").read_text(
                encoding="utf-8"))

    def make_candidate(self, *, power_qualified: bool = False) -> dict:
        architecture = self.policy["architecture"]
        anchor_benchmarks = self.anchor["performance"]["benchmarks"]
        return {
            "schema": "npc-rv64-ppa-baseline-v1",
            "baseline_id": "first-complete-architecture",
            "status": "candidate",
            "claim_tier": self.policy["claim_tier"],
            "policy": "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json",
            "policy_id": self.policy["policy_id"],
            "architecture_contract": {
                **architecture["fixed_contract"],
                **architecture["minimum_capacities"],
                "directed_evidence": {
                    name: True
                    for name in architecture["required_directed_evidence"]
                },
            },
            "functional": {
                "module": {"passed": 102, "required": 102, "failed": 0},
                "official": {"passed": 177, "required": 177, "failed": 0},
                "am": {"passed": 59, "required": 59, "failed": 0},
                "difftest_mismatches": 0,
                "coremark": {
                    "pass": True,
                    "iterations": 10,
                    "crc": "0xfcaf",
                    "good_trap_count": 1,
                },
                "dhrystone": {
                    "pass": True,
                    "runs": 10000,
                    "good_trap_count": 1,
                },
            },
            "performance": {
                "qualified_mhz": 200.0,
                "benchmarks": copy.deepcopy(anchor_benchmarks),
            },
            "timing": {
                "tier": "rtl_proxy_partial_constraints",
                "period_ns": 5.0,
                "qualified_mhz": 200.0,
                "wns_ns": 0.1,
                "tns_ns": 0.0,
                "worst_path_slack_ns": 0.1,
                "violated_path_count": 0,
                "combinational_loops": 0,
            },
            "area": {
                "metric_kind": "logic_area_proxy_excluding_unknown_macros",
                "logic_area": 1766384.312,
                "macro_area_complete": power_qualified,
                "total_area": 2000000.0 if power_qualified else None,
            },
            "power": {
                "qualified_for_promotion": power_qualified,
            },
        }

    def evaluate(
        self,
        candidate: dict,
        *,
        index: dict | None = None,
        checker_audited: bool = True,
    ) -> dict:
        return architecture_seed.evaluate_seed_transition(
            anchor=copy.deepcopy(self.anchor),
            candidate=candidate,
            policy=copy.deepcopy(self.policy),
            index=copy.deepcopy(self.index if index is None else index),
            checker_audited=checker_audited,
        )

    def test_policy_locks_one_time_exception_and_post_seed_ratchet(self) -> None:
        self.assertEqual(
            architecture_seed.validate_seed_policy(self.policy), [])
        result_schema = json.loads(
            (PPA_DIR / "schemas"
             / "architecture-feasible-seed-result-v1.schema.json")
            .read_text(encoding="utf-8"))
        self.assertEqual(
            result_schema["$id"],
            "npc-rv64-architecture-feasible-seed-result-v1",
        )
        self.assertIn(
            "eligible_for_front_accepted_baseline",
            result_schema["required"],
        )
        self.assertEqual(
            result_schema["properties"]["eligible_for_ppa_champion"]["const"],
            False,
        )
        seed = self.policy["architecture_feasible_seed"]
        self.assertFalse(
            seed["exception"]["require_candidate_dominates_anchor"])
        self.assertFalse(
            seed["exception"]["apply_minimum_area_efficiency_ratio"])
        self.assertEqual(seed["area"]["maximum_logic_area"], 1766384.312)
        self.assertAlmostEqual(
            seed["area"]["maximum_logic_area"],
            seed["area"]["anchor_logic_area"]
            * seed["area"]["maximum_ratio_to_anchor"],
            places=9,
        )
        self.assertTrue(seed["post_seed"]["require_candidate_dominates"])
        self.assertEqual(
            seed["post_seed"]["minimum_area_efficiency_ratio"], 0.999)
        self.assertTrue(seed["post_seed"]["reject_second_seed_transition"])

    def test_unqualified_power_is_seed_only_not_front_or_champion(self) -> None:
        result = self.evaluate(self.make_candidate(power_qualified=False))
        self.assertEqual(result["structural_errors"], [])
        self.assertEqual(result["transition_blockers"], [])
        self.assertTrue(result["architecture_feasible_seed_eligible"])
        self.assertFalse(result["eligible_for_front_accepted_baseline"])
        self.assertFalse(result["eligible_for_canonical"])
        self.assertFalse(result["eligible_for_ppa_champion"])
        self.assertFalse(result["post_seed_formal_front_available"])
        self.assertEqual(
            result["unqualified_power_claim_scope"],
            "architecture_feasible_seed_only",
        )
        self.assertEqual(
            architecture_seed.transition_exit_code(
                result, report_only=False, require_front_baseline=False),
            0,
        )
        self.assertEqual(
            architecture_seed.transition_exit_code(
                result, report_only=False, require_front_baseline=True),
            1,
        )

    def test_qualified_power_can_seed_a_front_but_is_not_itself_champion(self) -> None:
        result = self.evaluate(self.make_candidate(power_qualified=True))
        self.assertTrue(result["architecture_feasible_seed_eligible"])
        self.assertTrue(result["eligible_for_front_accepted_baseline"])
        self.assertTrue(result["eligible_for_canonical"])
        self.assertFalse(result["eligible_for_ppa_champion"])
        self.assertTrue(result["post_seed_formal_front_available"])

    def test_qualified_power_without_total_area_is_not_front_accepted(self) -> None:
        candidate = self.make_candidate(power_qualified=True)
        candidate["area"]["macro_area_complete"] = False
        candidate["area"]["total_area"] = None
        result = self.evaluate(candidate)
        self.assertTrue(result["architecture_feasible_seed_eligible"])
        self.assertTrue(result["power_qualified"])
        self.assertFalse(result["total_area_qualified"])
        self.assertFalse(result["eligible_for_front_accepted_baseline"])
        self.assertFalse(result["eligible_for_canonical"])

    def test_second_seed_transition_is_rejected(self) -> None:
        index = copy.deepcopy(self.index)
        index["architecture_feasible_seed"] = "first-seed.json"
        result = self.evaluate(self.make_candidate(), index=index)
        self.assertFalse(result["architecture_feasible_seed_eligible"])
        self.assertIn(
            "architecture-feasible seed already exists; second transition rejected",
            result["transition_blockers"],
        )

    def test_full_candidate_checker_audit_is_mandatory(self) -> None:
        result = self.evaluate(
            self.make_candidate(), checker_audited=False)
        self.assertFalse(result["architecture_feasible_seed_eligible"])
        self.assertIn(
            "full candidate checker audit did not pass",
            result["transition_blockers"],
        )

    def test_post_seed_dominance_ratchet_cannot_be_disabled(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["architecture_feasible_seed"]["post_seed"][
            "require_candidate_dominates"] = False
        errors = architecture_seed.validate_seed_policy(policy)
        self.assertIn(
            "post-seed require_candidate_dominates must be True", errors)

    def test_seed_thresholds_fail_closed_independently(self) -> None:
        cases = []

        gate = self.make_candidate()
        gate["architecture_contract"]["directed_evidence"][
            "dual_memory_issue"] = False
        cases.append((
            "architecture",
            gate,
            "architecture hard gate is not GREEN: dual_memory_issue",
        ))

        functional = self.make_candidate()
        functional["functional"]["module"]["passed"] = 101
        cases.append((
            "functional",
            functional,
            "functional gate failed: module",
        ))

        performance = self.make_candidate()
        performance["performance"]["benchmarks"][0]["cycles"] = 4930000
        cases.append((
            "performance",
            performance,
            "seed per-benchmark performance floor failed: coremark",
        ))

        timing = self.make_candidate()
        timing["timing"]["worst_path_slack_ns"] = 0.099999
        cases.append((
            "timing",
            timing,
            "seed timing reserve is below +0.10 ns",
        ))

        area = self.make_candidate()
        area["area"]["logic_area"] = 1766384.313
        cases.append((
            "area",
            area,
            "seed logic area exceeds 1.10x R3.6",
        ))

        for case_name, candidate, expected in cases:
            with self.subTest(case=case_name):
                result = self.evaluate(candidate)
                self.assertFalse(result["architecture_feasible_seed_eligible"])
                self.assertIn(expected, result["transition_blockers"])

    def test_seed_exception_does_not_weaken_normal_promotion(self) -> None:
        seed_result = self.evaluate(self.make_candidate())
        self.assertTrue(seed_result["architecture_feasible_seed_eligible"])
        normal_result = compare.evaluate_ratios(
            per_benchmark_ratio={
                "coremark": 1.01,
                "dhrystone_10000": 1.01,
            },
            performance_ratio=1.01,
            area_ratio=1.0 / 1.05,
            power_ratio=None,
            timing_ok=True,
            target="proxy_champion",
            policy=self.policy,
            checker_audited=True,
        )
        self.assertFalse(normal_result["pairwise_promotion_eligible"])
        self.assertIn(
            "area efficiency floor failed",
            normal_result["pairwise_promotion_blockers"],
        )
        self.assertIn(
            "candidate does not dominate baseline on all qualified axes",
            normal_result["pairwise_promotion_blockers"],
        )


class RawBenchmarkParserTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.counter_contract = json.loads(
            (PPA_DIR.parents[1]
             / "design/arch/performance-counter-schema-v4.json").read_text(
                 encoding="utf-8"))
        cls.v7_counter_contract = json.loads(
            (PPA_DIR.parents[1]
             / "design/arch/performance-counter-schema-v3.json").read_text(
                 encoding="utf-8"))
        cls.v6_counter_contract = json.loads(
            (PPA_DIR.parents[1]
             / "design/arch/performance-counter-schema-v2.json").read_text(
                 encoding="utf-8"))
        cls.v5_counter_contract = json.loads(
            (PPA_DIR.parents[1]
             / "design/arch/performance-counter-schema-v1.json").read_text(
                 encoding="utf-8"))

    def test_promotion_policy_selects_v8_fixed_regions(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        evidence = policy["performance_evidence"]
        self.assertEqual(
            evidence["schema"], "npc-rv64-performance-evidence-v8")
        self.assertEqual(
            evidence["counter_schema"]["id"],
            "npc-rv64-pcs-v4-request-detail-20260801",
        )
        contracts = evidence["benchmark_contracts"]
        self.assertEqual(
            contracts["coremark"],
            {
                "counter_scope": "pc_bounded_region_v1",
                "raw_log_artifact_kinds": [
                    "coremark_raw_log_rep1",
                    "coremark_raw_log_rep2",
                    "coremark_raw_log_rep3",
                ],
                "region": {
                    "start_pc": "0x00000000800017a8",
                    "stop_pc": "0x00000000800017b0",
                    "start_marker_semantics": "first_committed_hit",
                    "final_marker_semantics": "termination_time_total_hits",
                    "start_hits": 1,
                    "stop_hits": 1,
                },
            },
        )
        self.assertEqual(
            contracts["dhrystone_10000"]["region"],
            {
                "start_pc": "0x0000000080000334",
                "stop_pc": "0x000000008000047c",
                "start_marker_semantics": "first_committed_hit",
                "final_marker_semantics": "termination_time_total_hits",
                "start_hits": 10000,
                "stop_hits": 1,
            },
        )
        readme = (PPA_DIR / "README.md").read_text(encoding="utf-8")
        self.assertIn(
            "`design/arch/performance-counter-schema-v4.json`",
            readme,
        )
        self.assertIn(
            "`PARTIAL_CONSERVING_MEMORY_REQUEST_DETAIL_V4`",
            readme,
        )
        self.assertNotIn(
            "`design/arch/performance-counter-schema-v3.json` by canonical",
            readme,
        )

    def test_v8_reason_detail_and_bridge_encodings_match_rtl_and_host(
            self) -> None:
        rv64_dir = PPA_DIR.parents[1]
        schema = self.counter_contract
        sim_top = (rv64_dir / "vsrc/sim/NpcSimTop.sv").read_text(
            encoding="utf-8")
        cpu_exec = (rv64_dir / "csrc/cpu/cpu-exec.cpp").read_text(
            encoding="utf-8")
        reasons = schema["reason_encoding"]
        self.assertEqual(
            [item["code"] for item in reasons], list(range(16)))
        for item in reasons:
            symbol = item["name"].upper()
            self.assertRegex(
                sim_top,
                rf"SIM_RETIRE_REASON_{symbol}\s*=\s*4'd{item['code']};",
            )
            self.assertRegex(
                cpu_exec,
                rf"RETIRE_REASON_{symbol}\s*=\s*{item['code']},",
            )
        self.assertRegex(cpu_exec, r"RETIRE_REASON_COUNT\s*=\s*16,")

        details = schema["request_detail_encoding"]
        self.assertEqual(
            [item["code"] for item in details], list(range(8)))
        for item in details:
            symbol = item["name"].upper()
            self.assertRegex(
                sim_top,
                rf"SIM_MEM_REQUEST_DETAIL_{symbol}\s*=\s*3'd{item['code']};",
            )
            self.assertRegex(
                cpu_exec,
                rf"MEMORY_REQUEST_DETAIL_{symbol}\s*=\s*{item['code']},",
            )
        self.assertRegex(
            cpu_exec, r"MEMORY_REQUEST_DETAIL_COUNT\s*=\s*8,")

        bridge = (rv64_dir / "vsrc/memory/OooMemAxiBridge.v").read_text(
            encoding="utf-8")
        bridge_states = {
            "IDLE": 0,
            "WALK_AR": 1,
            "WALK_R": 2,
            "READ_ADDR": 3,
            "READ_DATA": 4,
            "WRITE_REQ": 5,
            "WRITE_RESP": 6,
            "RESP": 7,
            "AD_UPDATE": 8,
            "LOOKUP": 9,
            "DEVICE_WAIT": 10,
            "SQ_QUERY": 12,
        }
        for symbol, code in bridge_states.items():
            self.assertRegex(
                bridge,
                rf"S_{symbol}\s*=\s*4'd{code};",
            )
            self.assertRegex(
                sim_top,
                rf"SIM_MEM_BRIDGE_{symbol}\s*=\s*4'd{code};",
            )

    def test_valid_logs_parse_authoritative_fields(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        contracts = policy["performance_evidence"]["benchmark_contracts"]
        evidence_schema = policy["performance_evidence"]["schema"]
        coremark = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-valid.log",
            "coremark",
            "pc_bounded_region_v1",
            contracts["coremark"],
            evidence_schema,
            self.counter_contract,
        )
        dhrystone = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "dhrystone-valid.log",
            "dhrystone_10000",
            "pc_bounded_region_v1",
            contracts["dhrystone_10000"],
            evidence_schema,
            self.counter_contract,
        )
        self.assertTrue(coremark["pass"])
        self.assertEqual(coremark["good_trap_count"], 1)
        self.assertEqual(coremark["exit_code"], 0)
        self.assertEqual(
            coremark["counter_scope"], "pc_bounded_region_v1")
        self.assertEqual(coremark["cycles"], 100)
        self.assertEqual(coremark["retired_instructions"], 100)
        self.assertEqual(coremark["iterations"], 10)
        self.assertEqual(coremark["crc"], "0xfcaf")
        self.assertEqual(
            coremark["whole_program"],
            {"cycles": 150, "retired_instructions": 141},
        )
        self.assertEqual(
            coremark["post_region"],
            {"cycles": 40, "retired_instructions": 21},
        )
        self.assertEqual(coremark["region"]["start_hits"], 1)
        self.assertEqual(coremark["region"]["stop_hits"], 1)
        self.assertEqual(coremark["cpi_stack"]["useful"], 60)
        self.assertEqual(coremark["cpi_stack"]["dependency"], 8)
        self.assertEqual(coremark["cpi_stack"]["issue_terminal"], 4)
        self.assertEqual(coremark["cpi_stack"]["execution_latency"], 3)
        self.assertEqual(coremark["cpi_stack"]["memory_latency"], 5)
        self.assertEqual(
            coremark["cpi_stack"]["memory_lifecycle"],
            {
                "reservation_queue": 1,
                "translation_order": 1,
                "request_outstanding": 2,
                "response_terminal": 1,
                "retry": 0,
                "lifecycle_unknown": 0,
            },
        )
        self.assertEqual(
            coremark["cpi_stack"]["memory_request_detail"],
            {
                "cache_lookup": 1,
                "device_wait": 0,
                "axi_read_address": 0,
                "axi_read_data": 1,
                "axi_write_request": 0,
                "axi_write_response": 0,
                "detail_unknown": 0,
            },
        )
        self.assertEqual(
            coremark["cpi_stack"]["head_not_complete_aggregate"], 20)
        self.assertEqual(coremark["cpi_stack"]["unknown_ratio"], 0.0)
        self.assertEqual(
            coremark["retire_slots"],
            {
                "capacity": 200,
                "retired": 100,
                "unused": 100,
                "rob_empty": 20,
                "dependency": 18,
                "issue_terminal": 10,
                "execution_latency": 8,
                "memory_latency": 14,
                "head_lifecycle_unknown": 0,
                "exception_redirect": 8,
                "memory_commit": 15,
                "serialization": 7,
                "unknown": 0,
                "head_not_complete_aggregate": 50,
                "memory_lifecycle": {
                    "reservation_queue": 4,
                    "translation_order": 3,
                    "request_outstanding": 5,
                    "response_terminal": 2,
                    "retry": 0,
                    "lifecycle_unknown": 0,
                },
                "memory_request_detail": {
                    "cache_lookup": 2,
                    "device_wait": 0,
                    "axi_read_address": 1,
                    "axi_read_data": 2,
                    "axi_write_request": 0,
                    "axi_write_response": 0,
                    "detail_unknown": 0,
                },
            },
        )
        self.assertEqual(dhrystone["runs"], 10000)
        self.assertEqual(dhrystone["counter_scope"], "pc_bounded_region_v1")
        self.assertEqual(dhrystone["cycles"], 100)
        self.assertEqual(dhrystone["retired_instructions"], 100)
        self.assertEqual(
            dhrystone["whole_program"],
            {"cycles": 150, "retired_instructions": 141},
        )
        self.assertEqual(dhrystone["region"]["start_hits"], 10000)
        self.assertEqual(dhrystone["region"]["stop_hits"], 1)
        self.assertEqual(
            dhrystone["post_region"],
            {"cycles": 40, "retired_instructions": 21},
        )

    def test_v4_parser_remains_explicitly_compatible(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        parsed = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-valid.log",
            "coremark",
            "pc_bounded_region_v1",
            policy["performance_evidence"]["benchmark_contracts"]["coremark"],
            "npc-rv64-performance-evidence-v4",
        )
        self.assertEqual(parsed["cycles"], 100)
        self.assertNotIn("cpi_stack", parsed)

    def test_v8_zero_dependency_is_a_valid_observation(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        text = (FIXTURE_DIR / "coremark-valid.log").read_text(
            encoding="utf-8")
        text = (text
                .replace(" cycle_dependency=8", " cycle_dependency=0")
                .replace(
                    " cycle_issue_terminal=4", " cycle_issue_terminal=12")
                .replace(" slot_dependency=18", " slot_dependency=0")
                .replace(
                    " slot_issue_terminal=10", " slot_issue_terminal=28"))
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / "coremark-zero-dependency.log"
            path.write_text(text, encoding="utf-8")
            parsed = check.parse_raw_benchmark_log(
                path,
                "coremark",
                "pc_bounded_region_v1",
                policy["performance_evidence"]["benchmark_contracts"][
                    "coremark"],
                "npc-rv64-performance-evidence-v8",
                self.counter_contract,
            )
        self.assertEqual(parsed["cpi_stack"]["dependency"], 0)
        self.assertEqual(parsed["cpi_stack"]["issue_terminal"], 12)
        self.assertEqual(
            parsed["cpi_stack"]["head_not_complete_aggregate"], 20)

    def test_v8_counter_marker_fail_closed_mutations(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        contract = policy["performance_evidence"]["benchmark_contracts"][
            "coremark"]
        original = (FIXTURE_DIR / "coremark-valid.log").read_text(
            encoding="utf-8")
        counter_line = next(
            line for line in original.splitlines()
            if "COUNTERS_FINAL" in line)
        cases = {
            "missing": (
                original.replace(counter_line + "\n", ""),
                "expected exactly one CoreMark performance COUNTERS_FINAL"),
            "duplicate": (
                original + counter_line + "\n",
                "expected exactly one CoreMark performance COUNTERS_FINAL"),
            "phase": (
                original.replace("phase_aligned=1", "phase_aligned=0"),
                "boundary phase is not aligned"),
            "cycle_sum": (
                original.replace("cycle_useful=60", "cycle_useful=61"),
                "cycle conservation mismatch"),
            "slot_sum": (
                original.replace("slot_rob_empty=20", "slot_rob_empty=21"),
                "retire-slot conservation mismatch"),
            "cycle_head_aggregate": (
                original.replace(
                    "cycle_head_not_complete=20",
                    "cycle_head_not_complete=21"),
                "head lifecycle aggregate mismatch"),
            "slot_head_aggregate": (
                original.replace(
                    "slot_head_not_complete=50",
                    "slot_head_not_complete=51"),
                "head lifecycle aggregate mismatch"),
            "cycle_memory_aggregate": (
                original.replace(
                    "cycle_memory_reservation_queue=1",
                    "cycle_memory_reservation_queue=2"),
                "memory lifecycle aggregate mismatch"),
            "slot_memory_aggregate": (
                original.replace(
                    "slot_memory_reservation_queue=4",
                    "slot_memory_reservation_queue=5"),
                "memory lifecycle aggregate mismatch"),
            "cycle_request_detail_aggregate": (
                original.replace(
                    "cycle_memory_request_cache_lookup=1",
                    "cycle_memory_request_cache_lookup=2"),
                "memory request detail aggregate mismatch"),
            "slot_request_detail_aggregate": (
                original.replace(
                    "slot_memory_request_cache_lookup=2",
                    "slot_memory_request_cache_lookup=3"),
                "memory request detail aggregate mismatch"),
            "retired": (
                original.replace("retired_slots=100", "retired_slots=99"),
                "retired-slot binding mismatch"),
            "overflow": (
                original.replace("overflow=0", "overflow=1"),
                "counter overflow is nonzero"),
            "invalid": (
                original.replace("invalid_events=0", "invalid_events=1"),
                "counter invalid_events is nonzero"),
            "unknown_ratio": (
                original.replace("cycle_useful=60", "cycle_useful=58")
                        .replace(" cycle_unknown=0", " cycle_unknown=2"),
                "unknown cycle ratio exceeds limit"),
            "request_detail_unknown_ratio": (
                original.replace(
                    "cycle_memory_request_cache_lookup=1",
                    "cycle_memory_request_cache_lookup=0")
                        .replace(
                            "cycle_memory_request_axi_read_data=1",
                            "cycle_memory_request_axi_read_data=0")
                        .replace(
                            "cycle_memory_request_detail_unknown=0",
                            "cycle_memory_request_detail_unknown=2"),
                "unknown cycle ratio exceeds limit"),
        }
        for name, (text, expected) in cases.items():
            with self.subTest(case=name), tempfile.TemporaryDirectory() as temp:
                path = pathlib.Path(temp) / "coremark.log"
                path.write_text(text, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, expected):
                    check.parse_raw_benchmark_log(
                        path,
                        "coremark",
                        "pc_bounded_region_v1",
                        contract,
                        "npc-rv64-performance-evidence-v8",
                        self.counter_contract,
                    )

    def test_v7_counter_parser_remains_explicitly_compatible(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        parsed = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-v7-valid.log",
            "coremark",
            "pc_bounded_region_v1",
            policy["performance_evidence"]["benchmark_contracts"]["coremark"],
            "npc-rv64-performance-evidence-v7",
            self.v7_counter_contract,
        )
        self.assertEqual(parsed["cycles"], 100)
        self.assertEqual(
            parsed["performance_counter_schema"],
            "npc-rv64-performance-counter-v3")
        self.assertEqual(
            parsed["cpi_stack"]["memory_lifecycle"]["request_outstanding"],
            2)

    def test_v6_counter_parser_remains_explicitly_compatible(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        parsed = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-v6-valid.log",
            "coremark",
            "pc_bounded_region_v1",
            policy["performance_evidence"]["benchmark_contracts"]["coremark"],
            "npc-rv64-performance-evidence-v6",
            self.v6_counter_contract,
        )
        self.assertEqual(parsed["cycles"], 100)
        self.assertEqual(
            parsed["performance_counter_schema"],
            "npc-rv64-performance-counter-v2")
        self.assertEqual(parsed["cpi_stack"]["memory_latency"], 5)

    def test_v5_counter_parser_remains_explicitly_compatible(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        parsed = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-v5-valid.log",
            "coremark",
            "pc_bounded_region_v1",
            policy["performance_evidence"]["benchmark_contracts"]["coremark"],
            "npc-rv64-performance-evidence-v5",
            self.v5_counter_contract,
        )
        self.assertEqual(parsed["cycles"], 100)
        self.assertEqual(
            parsed["performance_counter_schema"],
            "npc-rv64-performance-counter-v1")
        self.assertEqual(parsed["cpi_stack"]["head_not_complete"], 20)

    def test_coremark_parser_remains_v2_whole_program_compatible(
            self) -> None:
        parsed = check.parse_raw_benchmark_log(
            FIXTURE_DIR / "coremark-valid.log",
            "coremark",
            "whole_program",
            {},
        )
        self.assertEqual(parsed["counter_scope"], "whole_program")
        self.assertEqual(parsed["cycles"], 150)
        self.assertEqual(parsed["retired_instructions"], 141)
        self.assertNotIn("region", parsed)
        self.assertNotIn("post_region", parsed)

    def test_r3p2_interleaved_abc_logs_remain_v3_compatible(self) -> None:
        policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8"))
        contracts = policy["performance_evidence"]["benchmark_contracts"]
        evidence_root = (
            PPA_DIR.parents[3]
            / ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
            / "evidence/ppa-r3p2-early-wake/region-abc"
        )
        cases = {
            "coremark": (
                "core-region-diagnostic/runs/*/coremark.raw.log",
                {
                    "a": (5384674, 3183617, 3218532, 20572),
                    "b": (5309268, 3183617, 3218532, 20572),
                    "c": (4904511, 3183617, 3218519, 20559),
                },
            ),
            "dhrystone_10000": (
                "dhr-runs/*/dhrystone-10000.raw.log",
                {
                    "a": (9581693, 4250000, 4260624, 6564),
                    "b": (9541651, 4250000, 4260624, 6564),
                    "c": (9481620, 4250000, 4260624, 6564),
                },
            ),
        }
        for benchmark, (pattern, expected) in cases.items():
            paths = sorted(evidence_root.glob(pattern))
            self.assertEqual(len(paths), 9, benchmark)
            observed = {"a": [], "b": [], "c": []}
            for path in paths:
                parsed = check.parse_raw_benchmark_log(
                    path,
                    benchmark,
                    "pc_bounded_region_v1",
                    contracts[benchmark],
                    "npc-rv64-performance-evidence-v3",
                )
                design = path.parent.name.rsplit("-", 1)[1]
                observed[design].append((
                    parsed["cycles"],
                    parsed["retired_instructions"],
                    parsed["whole_program"]["retired_instructions"],
                    parsed["post_region"]["retired_instructions"],
                ))
            for design, expected_tuple in expected.items():
                self.assertEqual(
                    observed[design], [expected_tuple] * 3,
                    f"{benchmark}:{design}",
                )

    def test_duplicate_good_trap_is_rejected(self) -> None:
        text = (FIXTURE_DIR / "coremark-valid.log").read_text(
            encoding="utf-8")
        duplicate = (
            "[cpu-exec.cpp:2006 cpu_exec] npc: HIT GOOD TRAP "
            "at pc = 0x0000000080002010\n"
        )
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / "duplicate.log"
            path.write_text(text + duplicate, encoding="utf-8")
            with self.assertRaisesRegex(
                    ValueError, "expected exactly one GOOD TRAP"):
                check.parse_raw_benchmark_log(path, "coremark")

    def test_malformed_counter_type_is_rejected(self) -> None:
        text = (FIXTURE_DIR / "coremark-valid.log").read_text(
            encoding="utf-8").replace("cycles=150", "cycles=true")
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / "malformed.log"
            path.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(
                    ValueError, "malformed authoritative exit record"):
                check.parse_raw_benchmark_log(path, "coremark")

    def test_workspace_path_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            with self.assertRaisesRegex(ValueError, "not workspace-relative"):
                check.workspace_file(root, "../outside.log", "artifact")

    def test_noncanonical_workspace_path_alias_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "raw.log").write_text("evidence", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "not workspace-relative"):
                check.workspace_file(root, "./raw.log", "artifact")


class CheckerCliTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = json.loads(
            (PPA_DIR / "policies" / "proxy-200mhz-v1.json").read_text(
                encoding="utf-8")
        )

    def make_fixture(
        self,
        root: pathlib.Path,
        *,
        difftest_mismatches: object = 0,
        evidence_schema: bool = True,
        repetitions: bool = True,
        raw_logs: bool = False,
    ) -> pathlib.Path:
        (root / ".git").mkdir()
        policy = copy.deepcopy(self.policy)
        performance_policy = policy["performance_evidence"]
        contract_source = (
            PPA_DIR.parents[1]
            / "design/arch/performance-measurement-contract-v1.json"
        )
        contract_destination = root / "performance-measurement-contract.json"
        contract_destination.write_bytes(contract_source.read_bytes())
        measurement_binding = performance_policy["measurement_contract"]
        measurement_binding["path"] = contract_destination.name
        measurement_binding["sha256"] = hashlib.sha256(
            contract_destination.read_bytes()).hexdigest()
        counter_source = (
            PPA_DIR.parents[1]
            / "design/arch/performance-counter-schema-v4.json"
        )
        counter_destination = root / "performance-counter-schema.json"
        counter_destination.write_bytes(counter_source.read_bytes())
        counter_binding = performance_policy["counter_schema"]
        counter_binding["path"] = counter_destination.name
        counter_binding["sha256"] = hashlib.sha256(
            counter_destination.read_bytes()).hexdigest()
        benchmark_contracts = performance_policy["benchmark_contracts"]
        raw_kind_set = {
            kind
            for contract in benchmark_contracts.values()
            for kind in contract["raw_log_artifact_kinds"]
        }
        policy["required_artifact_kinds"] = sorted(raw_kind_set)
        (root / "policy.json").write_text(
            json.dumps(policy), encoding="utf-8")

        architecture_policy = policy["architecture"]
        benchmark_entries = []
        for name in policy["benchmarks"]:
            contract = benchmark_contracts[name]
            repetition_list = [
                {
                    "cycles": 100,
                    "retired_instructions": 100,
                    "counter_scope": contract["counter_scope"],
                    "raw_log_artifact_kind": kind,
                    "raw_log_artifact_path": f"{kind}.log",
                }
                for kind in contract["raw_log_artifact_kinds"]
            ]
            item = {
                "name": name,
                "counter_scope": contract["counter_scope"],
                "cycles": 100,
                "retired_instructions": 100,
                "cpi": 1.0,
                "ipc": 1.0,
                "throughput_mips": 200.0,
            }
            if repetitions:
                item["repetitions"] = repetition_list
            benchmark_entries.append(item)

        performance = {
            "performance_measurement_contract_id":
                performance_policy["measurement_contract"]["id"],
            "performance_counter_schema_id":
                performance_policy["counter_schema"]["id"],
            "qualified_mhz": 200.0,
            "benchmarks": benchmark_entries,
            "weighted_throughput_mips": 200.0,
        }
        if evidence_schema:
            performance["evidence_schema"] = performance_policy["schema"]

        artifacts = []
        if raw_logs:
            source_names = {
                "coremark": "coremark-valid.log",
                "dhrystone_10000": "dhrystone-valid.log",
            }
            for name, contract in benchmark_contracts.items():
                for kind in contract["raw_log_artifact_kinds"]:
                    destination_name = f"{kind}.log"
                    destination = root / destination_name
                    destination.write_text(
                        (FIXTURE_DIR / source_names[name]).read_text(
                            encoding="utf-8"),
                        encoding="utf-8",
                    )
                    artifacts.append({
                        "kind": kind,
                        "path": destination_name,
                        "sha256": hashlib.sha256(
                            destination.read_bytes()).hexdigest(),
                    })

        manifest = {
            "schema": "npc-rv64-ppa-baseline-v1",
            "baseline_id": "fixture-provisional",
            "status": "provisional",
            "claim_tier": policy["claim_tier"],
            "policy": "policy.json",
            "policy_id": policy["policy_id"],
            "cohort_id": "unbound",
            "design_id": "unbound",
            "provenance": {
                "same_design_across_functional_performance_synthesis_sta": False
            },
            "architecture_contract": {
                **architecture_policy["fixed_contract"],
                **architecture_policy["minimum_capacities"],
                "directed_evidence": {
                    name: False
                    for name in architecture_policy[
                        "required_directed_evidence"]
                },
                "directed_metrics": {
                    "frontend_packets_observed": 64,
                    "frontend_max_initiation_interval": 1,
                    "independent_alu_ipc": 1.9,
                    "minimum_younger_completed_before_old": 8,
                    "rob_peak": 9,
                    "pair_matrix_passed": architecture_policy[
                        "required_pair_matrix"],
                    "true_ooo_passed": architecture_policy[
                        "required_true_ooo"],
                },
            },
            "functional": {
                "module": {"passed": 102, "required": 102, "failed": 0},
                "official": {"passed": 177, "required": 177, "failed": 0},
                "am": {"passed": 59, "required": 59, "failed": 0},
                "difftest_mismatches": difftest_mismatches,
                "coremark": {
                    "pass": True,
                    "iterations": 10,
                    "crc": "0xfcaf",
                    "good_trap_count": 1,
                },
                "dhrystone": {
                    "pass": True,
                    "runs": 10000,
                    "good_trap_count": 1,
                },
            },
            "performance": performance,
            "timing": {
                "tier": policy["claim_tier"],
                "period_ns": 5.0,
                "qualified_mhz": 200.0,
                "wns_ns": 0.1,
                "tns_ns": 0.0,
                "worst_path_slack_ns": 0.1,
                "violated_path_count": 0,
                "combinational_loops": 0,
                "ideal_clock": True,
                "macro_model_kind": "placeholder",
                "netlist_sha256": "0" * 64,
            },
            "area": {
                "metric_kind": policy["area_proxy"]["metric_kind"],
                "unit": policy["area_proxy"]["unit"],
                "logic_area": 100.0,
                "total_area": None,
                "macro_area_complete": False,
                "unknown_cell_types": policy["area_proxy"][
                    "unknown_cell_types"],
            },
            "power": {
                "metric_kind": "vectorless_logic_proxy",
                "total_power_w": None,
                "activity_coverage": None,
                "macro_power_complete": False,
                "qualified_for_promotion": False,
            },
            "artifacts": artifacts,
        }
        manifest_path = root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        return manifest_path

    def run_checker(
        self,
        manifest: pathlib.Path,
        *args: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(TOOLS_DIR / "check.py"),
             str(manifest), *args],
            text=True,
            capture_output=True,
            check=False,
        )

    def mutate_artifact(
        self,
        manifest: pathlib.Path,
        kind: str,
        transform,
    ) -> pathlib.Path:
        value = json.loads(manifest.read_text(encoding="utf-8"))
        artifact = next(
            item for item in value["artifacts"] if item["kind"] == kind)
        path = manifest.parent / artifact["path"]
        path.write_text(
            transform(path.read_text(encoding="utf-8")),
            encoding="utf-8",
        )
        artifact["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        manifest.write_text(json.dumps(value), encoding="utf-8")
        return path

    def test_default_blocker_exit_and_explicit_report_only(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(pathlib.Path(temp))
            strict = self.run_checker(manifest)
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(strict.returncode, 1)
        self.assertIn("STRUCTURAL PASS", strict.stdout)
        self.assertIn("PROMOTABLE NO", strict.stdout)
        self.assertIn(
            "raw benchmark log evidence is missing", strict.stdout)
        self.assertEqual(report.returncode, 0)

    def test_false_difftest_count_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), difftest_mismatches=False)
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "Difftest mismatch count must be a non-negative integer",
            report.stdout,
        )

    def test_missing_performance_schema_and_repetitions_block(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp),
                evidence_schema=False,
                repetitions=False,
            )
            strict = self.run_checker(manifest)
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(strict.returncode, 1)
        self.assertEqual(report.returncode, 0)
        self.assertIn("performance evidence schema is missing", report.stdout)
        self.assertIn("performance repetitions are missing", report.stdout)

    def test_non_string_policy_evidence_schema_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            manifest = self.make_fixture(root)
            policy_path = root / "policy.json"
            policy = json.loads(policy_path.read_text(encoding="utf-8"))
            policy["performance_evidence"]["schema"] = {}
            policy_path.write_text(json.dumps(policy), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "unsupported or missing performance evidence policy schema",
            report.stdout,
        )

    def test_boolean_region_hit_contract_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            manifest = self.make_fixture(root)
            policy_path = root / "policy.json"
            policy = json.loads(policy_path.read_text(encoding="utf-8"))
            policy["performance_evidence"]["benchmark_contracts"][
                "coremark"]["region"]["start_hits"] = True
            policy_path.write_text(json.dumps(policy), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "policy CoreMark region hit counts are invalid",
            report.stdout,
        )

    def test_raw_logs_bind_summary_and_repetitions(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 0, report.stdout)
        self.assertIn("STRUCTURAL PASS", report.stdout)
        self.assertNotIn("raw benchmark log evidence is missing", report.stdout)
        self.assertNotIn("raw benchmark counters mismatch", report.stdout)

    def test_dynamic_tail_may_vary_without_changing_v3_counters(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "coremark_raw_log_rep2",
                lambda text: text.replace(
                    "cycles=150, commits=141",
                    "cycles=151, commits=142",
                ),
            )
            self.mutate_artifact(
                manifest,
                "dhrystone_raw_log_rep3",
                lambda text: text.replace(
                    "cycles=150, commits=141",
                    "cycles=152, commits=143",
                ),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 0, report.stdout)
        self.assertNotIn("raw benchmark counters mismatch", report.stdout)

    def test_raw_counter_repetition_mismatch_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            value["performance"]["benchmarks"][0]["repetitions"][0][
                "cycles"] = 101
            manifest.write_text(json.dumps(value), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "raw benchmark counters mismatch repetition", report.stdout)

    def test_missing_one_repetition_raw_log_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            value["artifacts"] = [
                artifact for artifact in value["artifacts"]
                if artifact["kind"] != "dhrystone_raw_log_rep3"
            ]
            manifest.write_text(json.dumps(value), encoding="utf-8")
            strict = self.run_checker(manifest)
        self.assertEqual(strict.returncode, 1)
        self.assertIn(
            "required artifact kind missing: dhrystone_raw_log_rep3",
            strict.stdout,
        )
        self.assertIn(
            "raw benchmark log evidence is missing: dhrystone_10000[3]",
            strict.stdout,
        )

    def test_reused_repetition_artifact_kind_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            repetitions = value["performance"]["benchmarks"][0]["repetitions"]
            repetitions[1]["raw_log_artifact_kind"] = repetitions[0][
                "raw_log_artifact_kind"]
            manifest.write_text(json.dumps(value), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "performance raw-log artifact kind reused", report.stdout)

    def test_reused_repetition_artifact_path_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            repetitions = value["performance"]["benchmarks"][0]["repetitions"]
            repetitions[1]["raw_log_artifact_path"] = repetitions[0][
                "raw_log_artifact_path"]
            manifest.write_text(json.dumps(value), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "performance raw-log artifact path reused", report.stdout)

    def test_one_repetition_semantic_mismatch_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "coremark_raw_log_rep2",
                lambda text: text.replace(
                    "Iterations       : 10",
                    "Iterations       : 11",
                ),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn(
            "raw benchmark summary mismatch: coremark[2].iterations",
            report.stdout,
        )

    def test_one_repetition_region_mismatch_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "dhrystone_raw_log_rep2",
                lambda text: text.replace(
                    " end_retired=120 retired=100\n",
                    " end_retired=120 retired=99\n",
                ),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("region counter arithmetic mismatch", report.stdout)

    def test_coremark_region_tamper_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "coremark_raw_log_rep2",
                lambda text: text.replace(
                    " end_retired=120 retired=100\n",
                    " end_retired=120 retired=99\n",
                ),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("region counter arithmetic mismatch", report.stdout)

    def test_region_must_fit_in_whole_program_exit(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "coremark_raw_log_rep2",
                lambda text: text.replace(
                    "cycles=150, commits=141",
                    "cycles=109, commits=119",
                ),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("region escapes whole-program counters", report.stdout)

    def test_coremark_whole_counters_cannot_feed_v3_region(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            coremark = next(
                item for item in value["performance"]["benchmarks"]
                if item["name"] == "coremark")
            coremark["cycles"] = 150
            coremark["retired_instructions"] = 141
            for repetition in coremark["repetitions"]:
                repetition["cycles"] = 150
                repetition["retired_instructions"] = 141
            manifest.write_text(json.dumps(value), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("raw benchmark counters mismatch repetition", report.stdout)
        self.assertIn("raw benchmark counters mismatch summary", report.stdout)

    def test_nonzero_raw_exit_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            self.mutate_artifact(
                manifest,
                "coremark_raw_log_rep2",
                lambda text: text.replace("code=0", "code=1"),
            )
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("raw benchmark exit code is nonzero", report.stdout)

    def test_duplicate_or_missing_region_marker_is_structural_error(self) -> None:
        start_line = (
            "[cpu-exec.cpp:824 region_probe] BOUNDARY kind=start "
            "pc=0x0000000080000334 cycle=10 retired_before=20 "
            "lane=0 cycle_retire=1\n"
        )
        stop_line = (
            "[cpu-exec.cpp:842 region_probe] BOUNDARY kind=end "
            "pc=0x000000008000047c cycle=110 retired_before=120 "
            "lane=0 cycle_retire=1\n"
        )
        cases = (
            (
                "duplicate",
                lambda text: text.replace(
                    start_line, start_line + start_line, 1),
                "expected exactly one Dhrystone start boundary marker",
            ),
            (
                "missing",
                lambda text: text.replace(stop_line, "", 1),
                "expected exactly one Dhrystone stop boundary marker",
            ),
        )
        for case_name, transform, expected in cases:
            with self.subTest(case=case_name):
                with tempfile.TemporaryDirectory() as temp:
                    manifest = self.make_fixture(
                        pathlib.Path(temp), raw_logs=True)
                    self.mutate_artifact(
                        manifest,
                        "dhrystone_raw_log_rep2",
                        transform,
                    )
                    report = self.run_checker(
                        manifest, "--report-only")
                self.assertEqual(report.returncode, 1)
                self.assertIn(expected, report.stdout)

    def test_v4_final_marker_is_fail_closed(self) -> None:
        def rewrite_final(text: str, mode: str) -> str:
            lines = text.splitlines(keepends=True)
            final_index = next(
                index for index, line in enumerate(lines)
                if "region_probe] FINAL" in line)
            final_line = lines[final_index]
            if mode == "missing":
                del lines[final_index]
            elif mode == "duplicate":
                lines.insert(final_index, final_line)
            elif mode == "early_result_only":
                lines[final_index] = (
                    "[cpu-exec.cpp:900 region_probe] RESULT "
                    "start_hits=1 end_hits=1 start_cycle=10 end_cycle=110 "
                    "cycles=100 start_retired=20 end_retired=120 retired=100\n"
                )
            elif mode == "post_end_start_hit":
                lines[final_index] = final_line.replace(
                    "start_hits=1 end_hits=1",
                    "start_hits=2 end_hits=1",
                )
            elif mode == "incomplete":
                lines[final_index] = final_line.replace(
                    "complete=1", "complete=0")
            elif mode == "nonzero_termination":
                lines[final_index] = final_line.replace(
                    "termination_rc=0", "termination_rc=1")
            elif mode == "zero_cycle_region":
                lines = [
                    line.replace(
                        "cycle=110 retired_before=120",
                        "cycle=10 retired_before=120",
                    ) if "BOUNDARY kind=end" in line else line
                    for line in lines
                ]
                lines[final_index] = lines[final_index].replace(
                    "end_cycle=110 cycles=100",
                    "end_cycle=10 cycles=0",
                )
            else:
                self.fail(f"unknown FINAL mutation mode: {mode}")
            return "".join(lines)

        cases = (
            ("missing", "expected exactly one CoreMark region FINAL marker"),
            ("duplicate", "expected exactly one CoreMark region FINAL marker"),
            ("early_result_only", "expected exactly one CoreMark region FINAL marker"),
            ("post_end_start_hit", "region hit count mismatch"),
            ("incomplete", "region FINAL is incomplete"),
            ("nonzero_termination", "region FINAL termination_rc is nonzero"),
            ("zero_cycle_region", "region cycle count must be positive"),
        )
        for mode, expected in cases:
            with self.subTest(mode=mode):
                with tempfile.TemporaryDirectory() as temp:
                    manifest = self.make_fixture(
                        pathlib.Path(temp), raw_logs=True)
                    self.mutate_artifact(
                        manifest,
                        "coremark_raw_log_rep2",
                        lambda text, selected=mode: rewrite_final(
                            text, selected),
                    )
                    report = self.run_checker(manifest, "--report-only")
                self.assertEqual(report.returncode, 1)
                self.assertIn(expected, report.stdout)

    def test_v6_measurement_contract_false_eligibility_blocks_strict(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(pathlib.Path(temp), raw_logs=True)
            strict = self.run_checker(manifest)
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(strict.returncode, 1)
        self.assertIn(
            "performance measurement contract is not baseline eligible",
            strict.stdout,
        )
        self.assertEqual(report.returncode, 0)
        self.assertIn("STRUCTURAL PASS", report.stdout)

    def test_v6_measurement_contract_binding_mutations_fail_closed(self) -> None:
        cases = ("missing_manifest_id", "flipped_manifest_id",
                 "flipped_contract_without_policy_rebind",
                 "missing_policy_binding", "missing_eligibility")
        for case_name in cases:
            with self.subTest(case=case_name):
                with tempfile.TemporaryDirectory() as temp:
                    root = pathlib.Path(temp)
                    manifest = self.make_fixture(root, raw_logs=True)
                    manifest_value = json.loads(
                        manifest.read_text(encoding="utf-8"))
                    policy_path = root / "policy.json"
                    policy_value = json.loads(
                        policy_path.read_text(encoding="utf-8"))
                    binding = policy_value["performance_evidence"][
                        "measurement_contract"]
                    contract_path = root / binding["path"]

                    if case_name == "missing_manifest_id":
                        manifest_value["performance"].pop(
                            "performance_measurement_contract_id")
                        manifest.write_text(
                            json.dumps(manifest_value), encoding="utf-8")
                    elif case_name == "flipped_manifest_id":
                        manifest_value["performance"][
                            "performance_measurement_contract_id"] = "wrong"
                        manifest.write_text(
                            json.dumps(manifest_value), encoding="utf-8")
                    elif case_name == "flipped_contract_without_policy_rebind":
                        contract_value = json.loads(
                            contract_path.read_text(encoding="utf-8"))
                        contract_value["performance_baseline_eligible"] = True
                        contract_path.write_text(
                            json.dumps(contract_value), encoding="utf-8")
                    elif case_name == "missing_policy_binding":
                        policy_value["performance_evidence"].pop(
                            "measurement_contract")
                        policy_path.write_text(
                            json.dumps(policy_value), encoding="utf-8")
                    elif case_name == "missing_eligibility":
                        contract_value = json.loads(
                            contract_path.read_text(encoding="utf-8"))
                        contract_value.pop("performance_baseline_eligible")
                        contract_path.write_text(
                            json.dumps(contract_value), encoding="utf-8")
                        binding["sha256"] = hashlib.sha256(
                            contract_path.read_bytes()).hexdigest()
                        policy_path.write_text(
                            json.dumps(policy_value), encoding="utf-8")

                    report = self.run_checker(manifest, "--report-only")
                self.assertEqual(report.returncode, 1)
                if case_name in ("missing_manifest_id", "flipped_manifest_id"):
                    self.assertIn(
                        "performance measurement contract binding mismatch",
                        report.stdout,
                    )
                elif case_name == "flipped_contract_without_policy_rebind":
                    self.assertIn(
                        "performance measurement contract digest mismatch",
                        report.stdout,
                    )
                elif case_name == "missing_policy_binding":
                    self.assertIn(
                        "policy performance measurement contract is missing",
                        report.stdout,
                    )
                else:
                    self.assertIn(
                        "performance baseline eligibility must be boolean",
                        report.stdout,
                    )

    def test_v6_counter_schema_binding_mutations_fail_closed(self) -> None:
        cases = (
            "missing_manifest_id",
            "flipped_manifest_id",
            "flipped_contract_without_policy_rebind",
            "missing_policy_binding",
            "flipped_contract_id_with_digest_rebind",
        )
        for case_name in cases:
            with self.subTest(case=case_name):
                with tempfile.TemporaryDirectory() as temp:
                    root = pathlib.Path(temp)
                    manifest = self.make_fixture(root, raw_logs=True)
                    manifest_value = json.loads(
                        manifest.read_text(encoding="utf-8"))
                    policy_path = root / "policy.json"
                    policy_value = json.loads(
                        policy_path.read_text(encoding="utf-8"))
                    binding = policy_value["performance_evidence"][
                        "counter_schema"]
                    contract_path = root / binding["path"]

                    if case_name == "missing_manifest_id":
                        manifest_value["performance"].pop(
                            "performance_counter_schema_id")
                        manifest.write_text(
                            json.dumps(manifest_value), encoding="utf-8")
                    elif case_name == "flipped_manifest_id":
                        manifest_value["performance"][
                            "performance_counter_schema_id"] = "wrong"
                        manifest.write_text(
                            json.dumps(manifest_value), encoding="utf-8")
                    elif case_name == \
                            "flipped_contract_without_policy_rebind":
                        contract_value = json.loads(
                            contract_path.read_text(encoding="utf-8"))
                        contract_value["retire_width"] = 1
                        contract_path.write_text(
                            json.dumps(contract_value), encoding="utf-8")
                    elif case_name == "missing_policy_binding":
                        policy_value["performance_evidence"].pop(
                            "counter_schema")
                        policy_path.write_text(
                            json.dumps(policy_value), encoding="utf-8")
                    elif case_name == \
                            "flipped_contract_id_with_digest_rebind":
                        contract_value = json.loads(
                            contract_path.read_text(encoding="utf-8"))
                        contract_value[
                            "performance_counter_schema_id"] = "wrong"
                        contract_path.write_text(
                            json.dumps(contract_value), encoding="utf-8")
                        binding["sha256"] = hashlib.sha256(
                            contract_path.read_bytes()).hexdigest()
                        policy_path.write_text(
                            json.dumps(policy_value), encoding="utf-8")

                    report = self.run_checker(manifest, "--report-only")
                self.assertEqual(report.returncode, 1)
                if case_name in (
                        "missing_manifest_id", "flipped_manifest_id"):
                    self.assertIn(
                        "performance counter schema binding mismatch",
                        report.stdout,
                    )
                elif case_name == \
                        "flipped_contract_without_policy_rebind":
                    self.assertIn(
                        "performance counter schema digest mismatch",
                        report.stdout,
                    )
                elif case_name == "missing_policy_binding":
                    self.assertIn(
                        "policy performance counter schema is missing",
                        report.stdout,
                    )
                else:
                    self.assertIn(
                        "performance counter schema id mismatch",
                        report.stdout,
                    )

    def test_whole_program_region_scope_mix_is_structural_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            manifest = self.make_fixture(
                pathlib.Path(temp), raw_logs=True)
            value = json.loads(manifest.read_text(encoding="utf-8"))
            dhrystone = next(
                item for item in value["performance"]["benchmarks"]
                if item["name"] == "dhrystone_10000")
            dhrystone["counter_scope"] = "whole_program"
            dhrystone["repetitions"][0][
                "counter_scope"] = "whole_program"
            manifest.write_text(json.dumps(value), encoding="utf-8")
            report = self.run_checker(manifest, "--report-only")
        self.assertEqual(report.returncode, 1)
        self.assertIn("performance counter scope mismatch", report.stdout)
        self.assertIn(
            "performance repetition counter scope mismatch", report.stdout)


if __name__ == "__main__":
    unittest.main()
