#!/usr/bin/env python3
"""Fail-closed one-time transition from R3.6 to the first feasible design.

This transition deliberately does not weaken the normal Pareto promotion
rules.  It only creates an architecture-feasible seed because the R3.6
measurement anchor is architecture-infeasible and therefore cannot be a
meaningful dominance reference for the cost of restoring the required core.
"""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import subprocess
import sys
from typing import Any


POLICY_SCHEMA = "npc-rv64-ppa-policy-v1"
BASELINE_SCHEMA = "npc-rv64-ppa-baseline-v1"
INDEX_SCHEMA = "npc-rv64-ppa-baseline-index-v1"
SEED_TRANSITION_ID = "r3p6-infeasible-anchor-to-first-feasible-seed-v1"


def reject_json_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant is forbidden: {value}")


def load(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=reject_json_constant)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def repo_root(start: pathlib.Path) -> pathlib.Path:
    for path in (start, *start.parents):
        if (path / ".git").exists():
            return path
    raise RuntimeError("cannot locate repository root")


def finite_number(value: Any) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
    )


def positive_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def nonnegative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def benchmark_map(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    performance = manifest.get("performance")
    if not isinstance(performance, dict):
        return {}
    items = performance.get("benchmarks")
    if not isinstance(items, list):
        return {}
    result: dict[str, dict[str, Any]] = {}
    for item in items:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        if isinstance(name, str) and name and name not in result:
            result[name] = item
    return result


def _require_exact(
    errors: list[str], value: Any, expected: Any, label: str
) -> None:
    if value != expected:
        errors.append(f"{label} must be {expected!r}")


def validate_seed_policy(policy: dict[str, Any]) -> list[str]:
    """Validate both the exception and the post-seed ratchet."""
    errors: list[str] = []
    _require_exact(errors, policy.get("schema"), POLICY_SCHEMA, "policy schema")
    seed = policy.get("architecture_feasible_seed")
    if not isinstance(seed, dict):
        return errors + ["architecture_feasible_seed policy is missing"]
    _require_exact(
        errors, seed.get("transition_id"), SEED_TRANSITION_ID,
        "seed transition_id")
    _require_exact(errors, seed.get("one_time"), True, "seed one_time")
    _require_exact(
        errors, seed.get("candidate_role"), "architecture_feasible_seed",
        "seed candidate_role")
    _require_exact(
        errors, seed.get("required_candidate_status"), "candidate",
        "seed required_candidate_status")

    source = seed.get("source_anchor")
    if not isinstance(source, dict):
        errors.append("seed source_anchor must be an object")
    else:
        _require_exact(
            errors, source.get("path"),
            "npc/rv64/eval/ppa/baselines/r3p6-recovery-baseline.json",
            "seed source anchor path")
        _require_exact(
            errors, source.get("baseline_id"),
            "r3p6-onehot-prf-recovery-20260715",
            "seed source anchor baseline_id")
        _require_exact(
            errors, source.get("status"), "engineering_recovery_baseline",
            "seed source anchor status")
        _require_exact(
            errors, source.get("promotable"), False,
            "seed source anchor promotable")
        _require_exact(
            errors, source.get("architecture_feasible"), False,
            "seed source anchor architecture_feasible")
        _require_exact(
            errors, source.get("performance_counters"),
            {
                "coremark": {
                    "cycles": 4904511,
                    "retired_instructions": 3183617,
                },
                "dhrystone_10000": {
                    "cycles": 9481620,
                    "retired_instructions": 4250000,
                },
            },
            "seed source anchor performance counters")
        _require_exact(
            errors, source.get("logic_area"), 1605803.92,
            "seed source anchor logic area")

    gates = seed.get("hard_gates")
    if not isinstance(gates, dict):
        errors.append("seed hard_gates must be an object")
    else:
        for name in (
            "require_full_candidate_checker_audit",
            "require_all_nine_architecture_gates_green",
            "require_all_functional_gates_green",
        ):
            _require_exact(errors, gates.get(name), True, f"seed {name}")
        _require_exact(
            errors, gates.get("checker_target"), "proxy_champion",
            "seed checker_target")

    performance = seed.get("performance")
    if not isinstance(performance, dict):
        errors.append("seed performance policy must be an object")
    else:
        _require_exact(
            errors, performance.get("minimum_per_benchmark_ratio"), 0.995,
            "seed per-benchmark floor")
        _require_exact(
            errors,
            performance.get("require_fixed_image_retired_instruction_equality"),
            True,
            "seed fixed-image retired equality",
        )

    timing = seed.get("timing")
    expected_timing = {
        "tier": "rtl_proxy_partial_constraints",
        "period_ns": 5.0,
        "minimum_worst_slack_ns": 0.1,
        "required_tns_ns": 0.0,
        "maximum_violated_paths": 0,
        "maximum_combinational_loops": 0,
    }
    if not isinstance(timing, dict):
        errors.append("seed timing policy must be an object")
    else:
        for name, expected in expected_timing.items():
            _require_exact(errors, timing.get(name), expected, f"seed timing {name}")

    area = seed.get("area")
    if not isinstance(area, dict):
        errors.append("seed area policy must be an object")
    else:
        _require_exact(
            errors, area.get("metric_kind"),
            "logic_area_proxy_excluding_unknown_macros",
            "seed area metric_kind")
        _require_exact(
            errors, area.get("anchor_logic_area"), 1605803.92,
            "seed anchor logic area")
        _require_exact(
            errors, area.get("maximum_ratio_to_anchor"), 1.1,
            "seed maximum area ratio")
        _require_exact(
            errors, area.get("maximum_logic_area"), 1766384.312,
            "seed maximum logic area")
        _require_exact(
            errors,
            area.get("require_total_area_qualified_for_front_or_canonical"),
            True,
            "seed total-area front/canonical gate",
        )
        if (finite_number(area.get("anchor_logic_area"))
                and finite_number(area.get("maximum_ratio_to_anchor"))
                and finite_number(area.get("maximum_logic_area"))
                and not math.isclose(
                    area["anchor_logic_area"] * area["maximum_ratio_to_anchor"],
                    area["maximum_logic_area"], rel_tol=0.0, abs_tol=1e-9)):
            errors.append("seed area cap is not exactly derived from R3.6")

    exception = seed.get("exception")
    if not isinstance(exception, dict):
        errors.append("seed exception policy must be an object")
    else:
        _require_exact(
            errors, exception.get("require_candidate_dominates_anchor"),
            False, "seed dominance exception")
        _require_exact(
            errors, exception.get("apply_minimum_area_efficiency_ratio"),
            False, "seed area-efficiency exception")

    power = seed.get("power")
    if not isinstance(power, dict):
        errors.append("seed power policy must be an object")
    else:
        _require_exact(errors, power.get("qualified_preferred"), True,
                       "seed qualified power preference")
        _require_exact(
            errors, power.get("allow_unqualified_for_architecture_seed_only"),
            True, "seed unqualified-power scope")
        for name in (
            "unqualified_seed_front_accepted",
            "unqualified_seed_canonical",
            "unqualified_seed_ppa_champion",
        ):
            _require_exact(errors, power.get(name), False, f"seed power {name}")

    promotion = policy.get("promotion")
    post_seed = seed.get("post_seed")
    if not isinstance(promotion, dict) or not isinstance(post_seed, dict):
        errors.append("standard or post-seed promotion policy is missing")
    else:
        _require_exact(
            errors, post_seed.get("reject_second_seed_transition"), True,
            "post-seed second-transition ratchet")
        _require_exact(
            errors, post_seed.get("restore_standard_promotion_rules"), True,
            "post-seed standard-rule ratchet")
        _require_exact(
            errors,
            post_seed.get(
                "formal_front_requires_seed_power_and_total_area_qualified"),
            True,
            "post-seed formal-front qualification gate",
        )
        for name, expected in (
            ("require_candidate_dominates", True),
            ("minimum_area_efficiency_ratio", 0.999),
            ("minimum_per_benchmark_ratio", 0.995),
        ):
            _require_exact(errors, post_seed.get(name), expected,
                           f"post-seed {name}")
            _require_exact(errors, promotion.get(name), expected,
                           f"standard promotion {name}")
        _require_exact(
            errors, promotion.get("require_qualified_power_for_final_champion"),
            True, "standard final-champion power gate")
    return errors


def evaluate_seed_transition(
    *,
    anchor: dict[str, Any],
    candidate: dict[str, Any],
    policy: dict[str, Any],
    index: dict[str, Any],
    checker_audited: bool,
) -> dict[str, Any]:
    """Evaluate the exceptional transition without granting a champion claim."""
    errors = validate_seed_policy(policy)
    blockers: list[str] = []
    warnings: list[str] = []
    seed_value = policy.get("architecture_feasible_seed")
    seed = seed_value if isinstance(seed_value, dict) else {}
    source_value = seed.get("source_anchor")
    source = source_value if isinstance(source_value, dict) else {}

    if index.get("schema") != INDEX_SCHEMA:
        errors.append("unsupported baseline index schema")
    source_path = source.get("path")
    source_name = (
        pathlib.PurePosixPath(source_path).name
        if isinstance(source_path, str) else None
    )
    if index.get("engineering_recovery_baseline") != source_name:
        errors.append("baseline index does not select the policy source anchor")
    transition_index = index.get("architecture_feasible_seed_transition")
    if not isinstance(transition_index, dict):
        errors.append("baseline index seed transition is missing")
    else:
        _require_exact(
            errors, transition_index.get("transition_id"),
            SEED_TRANSITION_ID, "baseline index transition_id")
        _require_exact(
            errors, transition_index.get("one_time"), True,
            "baseline index one_time")
        _require_exact(
            errors, transition_index.get("second_transition_allowed"), False,
            "baseline index second transition")
        for name in (
            "unqualified_power_front_accepted",
            "unqualified_power_canonical",
            "unqualified_power_ppa_champion",
            "unqualified_total_area_front_accepted",
            "unqualified_total_area_canonical",
        ):
            _require_exact(errors, transition_index.get(name), False,
                           f"baseline index {name}")
    if index.get("architecture_feasible_seed") is not None:
        blockers.append("architecture-feasible seed already exists; second transition rejected")
    if index.get("canonical") is not None:
        blockers.append("canonical baseline already exists; seed transition is no longer applicable")

    if anchor.get("schema") != BASELINE_SCHEMA:
        errors.append("unsupported source-anchor schema")
    for name in ("baseline_id", "status", "promotable"):
        if anchor.get(name) != source.get(name):
            errors.append(f"source-anchor identity mismatch: {name}")
    if (anchor.get("policy")
            != "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
            or anchor.get("policy_id") != policy.get("policy_id")):
        errors.append("source-anchor policy binding mismatch")
    if anchor.get("transition_role") != "architecture_infeasible_measurement_anchor":
        errors.append("R3.6 is not marked as the architecture-infeasible anchor")
    anchor_arch = anchor.get("architecture_contract")
    if not isinstance(anchor_arch, dict):
        errors.append("source-anchor architecture contract is missing")
        anchor_arch = {}
    if anchor_arch.get("hard_gates_all_green") is not False:
        errors.append("source anchor must remain architecture-infeasible")
    architecture_policy_value = policy.get("architecture")
    architecture_policy = (
        architecture_policy_value
        if isinstance(architecture_policy_value, dict) else {}
    )
    required_gate_names = architecture_policy.get(
        "required_directed_evidence", [])
    if (not isinstance(required_gate_names, list)
            or len(required_gate_names) != 9
            or len(set(required_gate_names)) != 9):
        errors.append("policy must define exactly nine architecture hard gates")
        required_gate_names = []
    if set(anchor_arch.get("blocking_gates", [])) != set(required_gate_names):
        errors.append("source anchor architecture blockers no longer cover all nine gates")
    anchor_benchmarks = benchmark_map(anchor)
    expected_anchor_counters = source.get("performance_counters")
    if not isinstance(expected_anchor_counters, dict):
        errors.append("source-anchor performance contract is missing")
        expected_anchor_counters = {}
    anchor_benchmark_policy = policy.get("benchmarks")
    anchor_benchmark_names = (
        anchor_benchmark_policy
        if isinstance(anchor_benchmark_policy, dict) else {}
    )
    for name in anchor_benchmark_names:
        item = anchor_benchmarks.get(name)
        expected = expected_anchor_counters.get(name)
        observed = (
            {
                "cycles": item.get("cycles"),
                "retired_instructions": item.get("retired_instructions"),
            }
            if isinstance(item, dict) else None
        )
        if observed != expected:
            errors.append(f"source-anchor performance measurement drifted: {name}")
    anchor_area = anchor.get("area")
    if (not isinstance(anchor_area, dict)
            or anchor_area.get("logic_area") != source.get("logic_area")):
        errors.append("source-anchor logic area measurement drifted")

    if candidate.get("schema") != BASELINE_SCHEMA:
        errors.append("unsupported candidate schema")
    if candidate.get("status") != seed.get("required_candidate_status"):
        blockers.append("candidate status is not eligible for the seed transition")
    if candidate.get("policy_id") != policy.get("policy_id"):
        errors.append("candidate policy_id mismatch")
    if checker_audited is not True:
        blockers.append("full candidate checker audit did not pass")

    candidate_arch = candidate.get("architecture_contract")
    if not isinstance(candidate_arch, dict):
        errors.append("candidate architecture contract is missing")
        candidate_arch = {}
    directed = candidate_arch.get("directed_evidence")
    if not isinstance(directed, dict):
        errors.append("candidate directed evidence is missing")
        directed = {}
    for gate_name in required_gate_names:
        if directed.get(gate_name) is not True:
            blockers.append(f"architecture hard gate is not GREEN: {gate_name}")

    expected_functional_value = policy.get("functional")
    expected_functional = (
        expected_functional_value
        if isinstance(expected_functional_value, dict) else {}
    )
    functional = candidate.get("functional")
    if not isinstance(functional, dict):
        errors.append("candidate functional summary is missing")
        functional = {}
    for result_name, required_name in (
        ("module", "module_required"),
        ("official", "official_required"),
        ("am", "am_required"),
    ):
        result = functional.get(result_name)
        required = expected_functional.get(required_name)
        if not positive_int(required):
            errors.append(f"policy functional requirement is invalid: {required_name}")
            continue
        if not isinstance(result, dict):
            errors.append(f"candidate functional result is missing: {result_name}")
            continue
        if (result.get("passed") != required
                or result.get("required") != required
                or result.get("failed") != 0):
            blockers.append(f"functional gate failed: {result_name}")
    difftest = functional.get("difftest_mismatches")
    difftest_limit = expected_functional.get("difftest_max_mismatches")
    if not nonnegative_int(difftest_limit):
        errors.append("policy Difftest mismatch limit is invalid")
    if not nonnegative_int(difftest):
        errors.append("candidate Difftest mismatch count is invalid")
    elif nonnegative_int(difftest_limit) and difftest > difftest_limit:
        blockers.append("functional gate failed: difftest")
    coremark = functional.get("coremark")
    if not isinstance(coremark, dict):
        errors.append("candidate CoreMark semantic result is missing")
    elif not (
        coremark.get("pass") is True
        and coremark.get("iterations") == expected_functional.get("coremark_iterations")
        and coremark.get("crc") == expected_functional.get("coremark_crc")
        and coremark.get("good_trap_count") == 1
    ):
        blockers.append("functional gate failed: CoreMark")
    dhrystone = functional.get("dhrystone")
    if not isinstance(dhrystone, dict):
        errors.append("candidate Dhrystone semantic result is missing")
    elif not (
        dhrystone.get("pass") is True
        and dhrystone.get("runs") == expected_functional.get("dhrystone_runs")
        and dhrystone.get("good_trap_count") == 1
    ):
        blockers.append("functional gate failed: Dhrystone")

    candidate_benchmarks = benchmark_map(candidate)
    benchmark_policy = policy.get("benchmarks")
    if not isinstance(benchmark_policy, dict) or not benchmark_policy:
        errors.append("policy benchmark set is missing")
        benchmark_names: list[str] = []
    else:
        benchmark_names = list(benchmark_policy)
    per_benchmark_ratio: dict[str, float | None] = {}
    seed_performance_value = seed.get("performance")
    seed_performance = (
        seed_performance_value
        if isinstance(seed_performance_value, dict) else {}
    )
    floor = seed_performance.get("minimum_per_benchmark_ratio")
    policy_timing_value = policy.get("timing")
    policy_timing = (
        policy_timing_value if isinstance(policy_timing_value, dict) else {}
    )
    candidate_performance = candidate.get("performance")
    if (not isinstance(candidate_performance, dict)
            or candidate_performance.get("qualified_mhz")
            != policy_timing.get("qualified_mhz")):
        blockers.append("seed performance frequency does not match policy")
    for name in benchmark_names:
        anchor_item = anchor_benchmarks.get(name)
        candidate_item = candidate_benchmarks.get(name)
        if not isinstance(anchor_item, dict) or not isinstance(candidate_item, dict):
            errors.append(f"seed performance benchmark is missing: {name}")
            per_benchmark_ratio[name] = None
            continue
        values = (
            anchor_item.get("cycles"),
            anchor_item.get("retired_instructions"),
            candidate_item.get("cycles"),
            candidate_item.get("retired_instructions"),
        )
        if not all(positive_int(value) for value in values):
            errors.append(f"seed performance counters are invalid: {name}")
            per_benchmark_ratio[name] = None
            continue
        anchor_cycles, anchor_retired, candidate_cycles, candidate_retired = values
        if candidate_retired != anchor_retired:
            blockers.append(f"fixed-image retired-instruction mismatch: {name}")
        ratio = (candidate_retired / candidate_cycles) / (
            anchor_retired / anchor_cycles)
        per_benchmark_ratio[name] = ratio
        if not finite_number(floor) or ratio < floor:
            blockers.append(f"seed per-benchmark performance floor failed: {name}")

    timing_policy_value = seed.get("timing")
    timing_policy = (
        timing_policy_value if isinstance(timing_policy_value, dict) else {}
    )
    timing = candidate.get("timing")
    if not isinstance(timing, dict):
        errors.append("candidate timing summary is missing")
        timing = {}
    for name in ("tier", "period_ns"):
        if timing.get(name) != timing_policy.get(name):
            blockers.append(f"seed timing contract failed: {name}")
    if timing.get("qualified_mhz") != policy_timing.get("qualified_mhz"):
        blockers.append("seed timing contract failed: qualified_mhz")
    worst_slack = timing.get("worst_path_slack_ns")
    if (not finite_number(worst_slack)
            or worst_slack < timing_policy.get("minimum_worst_slack_ns", math.inf)):
        blockers.append("seed timing reserve is below +0.10 ns")
    wns = timing.get("wns_ns")
    if not finite_number(wns) or wns < 0:
        blockers.append("seed timing WNS is negative or invalid")
    for actual_name, policy_name in (
        ("tns_ns", "required_tns_ns"),
        ("violated_path_count", "maximum_violated_paths"),
        ("combinational_loops", "maximum_combinational_loops"),
    ):
        if timing.get(actual_name) != timing_policy.get(policy_name):
            blockers.append(f"seed timing contract failed: {actual_name}")

    area_policy_value = seed.get("area")
    area_policy = area_policy_value if isinstance(area_policy_value, dict) else {}
    area = candidate.get("area")
    if not isinstance(area, dict):
        errors.append("candidate area summary is missing")
        area = {}
    if area.get("metric_kind") != area_policy.get("metric_kind"):
        blockers.append("seed area metric kind drifted")
    logic_area = area.get("logic_area")
    if not finite_number(logic_area) or logic_area <= 0:
        errors.append("candidate logic area is invalid")
    elif logic_area > area_policy.get("maximum_logic_area", -math.inf):
        blockers.append("seed logic area exceeds 1.10x R3.6")

    power = candidate.get("power")
    if not isinstance(power, dict):
        errors.append("candidate power summary is missing")
        power = {}
    power_qualified = power.get("qualified_for_promotion")
    if not isinstance(power_qualified, bool):
        errors.append("candidate power qualification flag must be a boolean")
        power_qualified = False
    elif power_qualified is False:
        warnings.append(
            "power is unqualified: seed role only; front accepted, canonical, "
            "and PPA champion claims remain forbidden"
        )

    total_area_qualified = (
        area.get("macro_area_complete") is True
        and finite_number(area.get("total_area"))
        and area.get("total_area") > 0
    )
    if power_qualified is True and not total_area_qualified:
        warnings.append(
            "power is qualified but total area is not; front accepted and "
            "canonical claims remain forbidden"
        )

    errors = sorted(set(errors))
    blockers = sorted(set(blockers))
    seed_eligible = not errors and not blockers
    front_baseline_eligible = (
        seed_eligible
        and power_qualified is True
        and total_area_qualified
    )
    result = {
        "schema": "npc-rv64-architecture-feasible-seed-result-v1",
        "transition_id": SEED_TRANSITION_ID,
        "source_anchor": anchor.get("baseline_id"),
        "candidate": candidate.get("baseline_id"),
        "candidate_checker_audited": checker_audited,
        "architecture_feasible_seed_eligible": seed_eligible,
        "per_benchmark_performance_ratio": per_benchmark_ratio,
        "minimum_per_benchmark_ratio": floor,
        "candidate_logic_area": logic_area,
        "maximum_logic_area": area_policy.get("maximum_logic_area"),
        "dominance_required_for_this_transition": False,
        "minimum_area_efficiency_ratio_applied_to_this_transition": False,
        "power_qualified": power_qualified,
        "total_area_qualified": total_area_qualified,
        "eligible_for_front_accepted_baseline": front_baseline_eligible,
        "eligible_for_canonical": front_baseline_eligible,
        "eligible_for_ppa_champion": False,
        "unqualified_power_claim_scope": (
            None if power_qualified else "architecture_feasible_seed_only"
        ),
        "post_seed_standard_rules_restored": seed_eligible,
        "post_seed_formal_front_available": front_baseline_eligible,
        "post_seed_require_candidate_dominates": True,
        "post_seed_minimum_area_efficiency_ratio": 0.999,
        "second_seed_transition_allowed": False,
        "structural_errors": errors,
        "transition_blockers": blockers,
        "warnings": warnings,
    }
    return result


def transition_exit_code(
    result: dict[str, Any], *, report_only: bool, require_front_baseline: bool
) -> int:
    if result.get("structural_errors"):
        return 1
    if report_only:
        return 0
    if require_front_baseline:
        return 0 if result.get("eligible_for_front_accepted_baseline") is True else 1
    return 0 if result.get("architecture_feasible_seed_eligible") is True else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("anchor", type=pathlib.Path)
    parser.add_argument("candidate", type=pathlib.Path)
    parser.add_argument(
        "--index", type=pathlib.Path,
        default=pathlib.Path("npc/rv64/eval/ppa/baselines/index.json"))
    gate_mode = parser.add_mutually_exclusive_group()
    gate_mode.add_argument("--report-only", action="store_true")
    gate_mode.add_argument("--require-front-baseline", action="store_true")
    args = parser.parse_args()

    anchor_path = args.anchor.resolve()
    candidate_path = args.candidate.resolve()
    root = repo_root(anchor_path.parent)
    if repo_root(candidate_path.parent).resolve() != root.resolve():
        raise SystemExit("anchor and candidate must be in the same repository")
    index_path = args.index
    if not index_path.is_absolute():
        index_path = root / index_path
    index_path = index_path.resolve()
    if repo_root(index_path.parent).resolve() != root.resolve():
        raise SystemExit("baseline index must be in the same repository")

    anchor = load(anchor_path)
    candidate = load(candidate_path)
    index = load(index_path)
    policy_rel = candidate.get("policy")
    if not isinstance(policy_rel, str):
        raise SystemExit("candidate policy path is missing")
    policy_path = (root / policy_rel).resolve()
    if not policy_path.is_relative_to(root.resolve()) or not policy_path.is_file():
        raise SystemExit("candidate policy path escapes the repository")
    policy = load(policy_path)

    checker = pathlib.Path(__file__).resolve().with_name("check.py")
    checker_result = subprocess.run(
        [
            sys.executable,
            str(checker),
            str(candidate_path),
            "--require-promotable",
            "--target",
            "proxy_champion",
        ],
        text=True,
        capture_output=True,
        check=False,
        cwd=root,
    )
    result = evaluate_seed_transition(
        anchor=anchor,
        candidate=candidate,
        policy=policy,
        index=index,
        checker_audited=checker_result.returncode == 0,
    )
    result["candidate_checker_returncode"] = checker_result.returncode
    if checker_result.returncode != 0:
        result["candidate_checker_diagnostic"] = (
            checker_result.stdout + checker_result.stderr
        )[-8192:]
    print(json.dumps(result, indent=2, sort_keys=True))
    return transition_exit_code(
        result,
        report_only=args.report_only,
        require_front_baseline=args.require_front_baseline,
    )


if __name__ == "__main__":
    sys.exit(main())
