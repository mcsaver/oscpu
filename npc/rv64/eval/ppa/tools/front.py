#!/usr/bin/env python3
"""Audit a complete candidate set and select a global Pareto winner."""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import sys
from typing import Any

from compare import (
    artifact_sha_map,
    audit,
    classify_pareto,
    evaluate_ratios,
    finite_positive_number,
    load,
    promotion_config,
    repo_root,
    workspace_file,
)


def benchmark_objectives(
    manifest: dict[str, Any],
    policy: dict[str, Any],
) -> tuple[float, dict[str, float], dict[str, int]]:
    performance = manifest.get("performance")
    if not isinstance(performance, dict):
        raise SystemExit("performance must be an object")
    items = performance.get("benchmarks")
    if not isinstance(items, list):
        raise SystemExit("performance benchmarks must be a list")
    by_name = {
        item.get("name"): item
        for item in items
        if isinstance(item, dict) and isinstance(item.get("name"), str)
    }
    weights = policy.get("benchmarks")
    if not isinstance(weights, dict) or not weights:
        raise SystemExit("benchmark weights are missing")

    qualified_mhz = policy.get("timing", {}).get("qualified_mhz")
    if not finite_positive_number(qualified_mhz):
        raise SystemExit("qualified frequency is invalid")
    weighted_log = 0.0
    weight_sum = 0.0
    per_benchmark: dict[str, float] = {}
    retired_by_benchmark: dict[str, int] = {}
    for name, weight in weights.items():
        item = by_name.get(name)
        if not isinstance(item, dict):
            raise SystemExit(f"required benchmark missing: {name}")
        cycles = item.get("cycles")
        retired = item.get("retired_instructions")
        if (not isinstance(cycles, int) or isinstance(cycles, bool)
                or cycles <= 0 or not isinstance(retired, int)
                or isinstance(retired, bool) or retired <= 0):
            raise SystemExit(f"invalid benchmark counters: {name}")
        if not finite_positive_number(weight):
            raise SystemExit(f"invalid benchmark weight: {name}")
        throughput = qualified_mhz / (cycles / retired)
        per_benchmark[name] = throughput
        retired_by_benchmark[name] = retired
        weighted_log += float(weight) * math.log(throughput)
        weight_sum += float(weight)
    return (
        math.exp(weighted_log / weight_sum),
        per_benchmark,
        retired_by_benchmark,
    )


def objective_record(
    manifest: dict[str, Any],
    policy: dict[str, Any],
    target: str,
) -> dict[str, Any]:
    performance, per_benchmark, retired = benchmark_objectives(
        manifest, policy)
    area_metric = (
        "total_area" if target == "final_champion" else "logic_area")
    area = manifest.get("area", {}).get(area_metric)
    if not finite_positive_number(area):
        raise SystemExit(f"invalid objective: {area_metric}")
    power: float | None = None
    if target == "final_champion":
        if manifest.get("power", {}).get("qualified_for_promotion") is not True:
            raise SystemExit("final champion record has unqualified power")
        value = manifest.get("power", {}).get("total_power_w")
        if not finite_positive_number(value):
            raise SystemExit("final champion record has invalid total power")
        power = float(value)
    return {
        "baseline_id": manifest.get("baseline_id"),
        "performance": performance,
        "per_benchmark": per_benchmark,
        "retired": retired,
        "area": float(area),
        "power": power,
    }


def timing_gate(manifest: dict[str, Any], policy: dict[str, Any]) -> bool:
    timing = manifest.get("timing", {})
    timing_policy = policy.get("timing", {})
    performance = manifest.get("performance", {})
    try:
        return bool(
            timing.get("tier") == policy.get("claim_tier")
            and timing.get("period_ns") == timing_policy.get("period_ns")
            and performance.get("qualified_mhz")
            == timing_policy.get("qualified_mhz")
            and timing.get("qualified_mhz")
            == timing_policy.get("qualified_mhz")
            and timing.get("wns_ns", -math.inf) >= 0
            and timing.get("worst_path_slack_ns", -math.inf)
            >= timing_policy.get(
                "minimum_worst_slack_ns_for_promotion", math.inf)
            and timing.get("tns_ns")
            == timing_policy.get("required_tns_ns", 0.0)
            and timing.get("violated_path_count")
            == timing_policy.get("maximum_violated_paths", 0)
            and timing.get("combinational_loops")
            == timing_policy.get("maximum_combinational_loops", 0)
        )
    except TypeError:
        return False


def validate_collection(
    manifests: list[dict[str, Any]],
    policy: dict[str, Any],
    target: str,
) -> None:
    reference = manifests[0]
    reference_artifacts = artifact_sha_map(reference)
    shared_kinds = (
        "config_manifest",
        "required_test_manifest",
        "coremark_image",
        "dhrystone_image",
    )
    if target == "final_champion":
        shared_kinds += ("power_workload_manifest",)
    for manifest in manifests[1:]:
        for field in ("policy", "policy_id", "cohort_id", "claim_tier"):
            if manifest.get(field) != reference.get(field):
                raise SystemExit(f"candidate collection mismatch: {field}")
        for field in ("metric_kind", "unit", "unknown_cell_types"):
            if (manifest.get("area", {}).get(field)
                    != reference.get("area", {}).get(field)):
                raise SystemExit(f"candidate collection area mismatch: {field}")
        artifacts = artifact_sha_map(manifest)
        for kind in shared_kinds:
            if (reference_artifacts.get(kind) is None
                    or artifacts.get(kind) != reference_artifacts.get(kind)):
                raise SystemExit(
                    f"candidate collection artifact mismatch: {kind}")
    promotion_config(policy)


def pair_evaluation(
    candidate: dict[str, Any],
    baseline_objective: dict[str, Any],
    candidate_objective: dict[str, Any],
    policy: dict[str, Any],
    target: str,
) -> dict[str, Any]:
    if candidate_objective["retired"] != baseline_objective["retired"]:
        raise SystemExit("retired-instruction mismatch for fixed-image A/B")
    per_benchmark_ratio = {
        name: candidate_objective["per_benchmark"][name] / value
        for name, value in baseline_objective["per_benchmark"].items()
    }
    performance_ratio = (
        candidate_objective["performance"]
        / baseline_objective["performance"]
    )
    area_ratio = baseline_objective["area"] / candidate_objective["area"]
    power_ratio = None
    if target == "final_champion":
        power_ratio = (
            baseline_objective["power"] / candidate_objective["power"])
    evaluation = evaluate_ratios(
        per_benchmark_ratio=per_benchmark_ratio,
        performance_ratio=performance_ratio,
        area_ratio=area_ratio,
        power_ratio=power_ratio,
        timing_ok=timing_gate(candidate, policy),
        target=target,
        policy=policy,
        checker_audited=True,
    )
    return {
        "per_benchmark_performance_ratio": per_benchmark_ratio,
        "performance_ratio": performance_ratio,
        "area_ratio": area_ratio,
        "power_ratio": power_ratio,
        **evaluation,
    }


def global_pareto(
    objectives: list[dict[str, Any]],
    eps: dict[str, float],
) -> tuple[list[str], dict[str, list[str]]]:
    dominated_by: dict[str, list[str]] = {
        objective["baseline_id"]: [] for objective in objectives
    }
    for candidate in objectives:
        candidate_id = candidate["baseline_id"]
        for challenger in objectives:
            challenger_id = challenger["baseline_id"]
            if challenger_id == candidate_id:
                continue
            relation, *_ = classify_pareto(
                challenger["performance"] / candidate["performance"],
                candidate["area"] / challenger["area"],
                (
                    None if candidate["power"] is None
                    else candidate["power"] / challenger["power"]
                ),
                eps,
            )
            if relation == "candidate_dominates":
                dominated_by[candidate_id].append(challenger_id)
        dominated_by[candidate_id].sort()
    front = sorted(
        baseline_id for baseline_id, dominators in dominated_by.items()
        if not dominators
    )
    return front, dominated_by


def front_exit_code(
    winner: str | None,
    required_winner: str | None,
    report_only: bool,
) -> int:
    if required_winner is not None:
        return 0 if winner == required_winner else 1
    if winner is None and not report_only:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifests", nargs="+", type=pathlib.Path)
    parser.add_argument("--target", choices=("proxy_champion", "final_champion"),
                        default="proxy_champion")
    gate_mode = parser.add_mutually_exclusive_group()
    gate_mode.add_argument("--require-winner")
    gate_mode.add_argument("--report-only", action="store_true")
    args = parser.parse_args()
    paths = [path.resolve() for path in args.manifests]
    if len(paths) < 2 or len(paths) != len(set(paths)):
        raise SystemExit("candidate set must contain at least two unique manifests")
    root = repo_root(paths[0].parent)
    if any(repo_root(path.parent).resolve() != root.resolve() for path in paths):
        raise SystemExit("all manifests must be in the same repository")

    manifests = [load(path) for path in paths]
    baseline_ids = [manifest.get("baseline_id") for manifest in manifests]
    if (any(not isinstance(value, str) or not value for value in baseline_ids)
            or len(baseline_ids) != len(set(baseline_ids))):
        raise SystemExit("candidate set baseline_id values must be unique strings")
    accepted = [
        index for index, manifest in enumerate(manifests)
        if manifest.get("status") == "accepted"
    ]
    candidates = [
        index for index, manifest in enumerate(manifests)
        if manifest.get("status") == "candidate"
    ]
    if len(accepted) != 1 or len(candidates) != len(manifests) - 1:
        raise SystemExit(
            "candidate set requires exactly one accepted baseline and "
            "one or more candidate manifests")

    checker = pathlib.Path(__file__).resolve().with_name("check.py")
    baseline_index = accepted[0]
    for index, path in enumerate(paths):
        audit(
            checker,
            path,
            args.target,
            require_accepted=index == baseline_index,
        )

    baseline = manifests[baseline_index]
    policy_path = workspace_file(root, baseline["policy"])
    policy = load(policy_path)
    if policy.get("policy_id") != baseline.get("policy_id"):
        raise SystemExit("policy_id does not match policy file")
    validate_collection(manifests, policy, args.target)
    _, eps = promotion_config(policy)

    objectives = [
        objective_record(manifest, policy, args.target)
        for manifest in manifests
    ]
    front, dominated_by = global_pareto(objectives, eps)
    baseline_objective = objectives[baseline_index]
    candidate_results: list[dict[str, Any]] = []
    for index in candidates:
        candidate_id = manifests[index]["baseline_id"]
        pair = pair_evaluation(
            manifests[index],
            baseline_objective,
            objectives[index],
            policy,
            args.target,
        )
        front_member = candidate_id in front
        eligible = pair["pairwise_promotion_eligible"] and front_member
        candidate_results.append({
            "baseline_id": candidate_id,
            "global_front_member": front_member,
            "dominated_by": dominated_by[candidate_id],
            "eligible_for_global_promotion": eligible,
            **pair,
        })

    eligible_results = [
        result for result in candidate_results
        if result["eligible_for_global_promotion"]
    ]
    eligible_results.sort(
        key=lambda result: (
            -result["balanced_score"],
            result["baseline_id"],
        )
    )
    winner = (
        eligible_results[0]["baseline_id"] if eligible_results else None)
    for result in candidate_results:
        result["selected_as_winner"] = result["baseline_id"] == winner

    output = {
        "schema": "npc-rv64-ppa-global-front-v1",
        "target": args.target,
        "accepted_baseline": baseline["baseline_id"],
        "collection_size": len(manifests),
        "qualified_axes": (
            ["performance", "total_area", "total_power"]
            if args.target == "final_champion"
            else ["performance", "logic_area"]
        ),
        "global_pareto_front": front,
        "dominated_by": dominated_by,
        "candidates": sorted(
            candidate_results, key=lambda result: result["baseline_id"]),
        "recommended_winner": winner,
        "global_pareto_audited": True,
        "final_three_axis_claim_allowed": (
            winner is not None and args.target == "final_champion"
        ),
    }
    print(json.dumps(output, indent=2, sort_keys=True))
    return front_exit_code(winner, args.require_winner, args.report_only)


if __name__ == "__main__":
    sys.exit(main())
