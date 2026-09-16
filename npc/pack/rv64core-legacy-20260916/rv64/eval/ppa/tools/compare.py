#!/usr/bin/env python3
"""Compare two already-audited manifests without hiding Pareto tradeoffs."""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import sys
import subprocess
from typing import Any


def load(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(
            handle,
            parse_constant=lambda value: (_ for _ in ()).throw(
                ValueError(f"non-finite JSON constant: {value}")),
        )

    if not isinstance(value, dict):
        raise SystemExit(f"{path}: top-level JSON must be an object")
    return value

def repo_root(start: pathlib.Path) -> pathlib.Path:
    for path in (start, *start.parents):
        if (path / ".git").exists():
            return path
    raise RuntimeError("cannot locate repository root")
def workspace_file(root: pathlib.Path, rel: Any) -> pathlib.Path:
    if (not isinstance(rel, str) or not rel or "\\" in rel or
            pathlib.PurePosixPath(rel).is_absolute() or
            ".." in pathlib.PurePosixPath(rel).parts):
        raise SystemExit(f"path is not workspace-relative: {rel!r}")
    path = (root / rel).resolve(strict=True)
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise SystemExit(f"path escapes workspace or is not a file: {rel}")
    return path


def audit(checker: pathlib.Path, manifest: pathlib.Path, target: str,
          require_accepted: bool) -> None:
    command = [sys.executable, str(checker), str(manifest), "--target", target,
               "--require-accepted" if require_accepted else "--require-promotable"]
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        role = "baseline" if require_accepted else "candidate"
        raise SystemExit(f"{role} checker rejected manifest:\n{result.stdout}{result.stderr}")




def benchmark_map(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {item["name"]: item for item in manifest["performance"]["benchmarks"]}


def artifact_sha_map(manifest: dict[str, Any]) -> dict[str, str]:
    result: dict[str, str] = {}
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list):
        raise SystemExit("artifacts must be a list")
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            raise SystemExit("artifact entry must be an object")
        kind = artifact.get("kind")
        sha256 = artifact.get("sha256")
        if not isinstance(kind, str) or kind in result:
            raise SystemExit(f"invalid or duplicate artifact kind: {kind!r}")
        if not isinstance(sha256, str):
            raise SystemExit(f"invalid artifact SHA: {kind}")
        result[kind] = sha256
    return result

def finite_positive_number(value: Any) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
        and value > 0
    )


def promotion_config(policy: dict[str, Any]) -> tuple[dict[str, Any], dict[str, float]]:
    promotion = policy.get("promotion")
    if not isinstance(promotion, dict):
        raise SystemExit("policy promotion section must be an object")
    for name in (
        "minimum_performance_ratio",
        "minimum_per_benchmark_ratio",
        "minimum_area_efficiency_ratio",
        "minimum_power_efficiency_ratio",
        "maximum_area_ratio",
        "minimum_balanced_score",
    ):
        if not finite_positive_number(promotion.get(name)):
            raise SystemExit(f"invalid promotion threshold: {name}")
    if promotion.get("require_candidate_dominates") is not True:
        raise SystemExit("policy must require candidate Pareto dominance")
    if promotion.get("require_qualified_power_for_final_champion") is not True:
        raise SystemExit("policy must require qualified power for final champion")

    eps = policy.get("pareto_epsilon")
    if not isinstance(eps, dict):
        raise SystemExit("policy pareto_epsilon must be an object")
    validated_eps: dict[str, float] = {}
    for name in ("performance_ratio", "area_ratio", "power_ratio"):
        value = eps.get(name)
        if (not isinstance(value, (int, float)) or isinstance(value, bool)
                or not math.isfinite(value) or value < 0 or value >= 1):
            raise SystemExit(f"invalid Pareto epsilon: {name}")
        validated_eps[name] = float(value)
    return promotion, validated_eps


def classify_pareto(
    performance_ratio: float,
    area_ratio: float,
    power_ratio: float | None,
    eps: dict[str, float],
) -> tuple[str, bool, bool, bool, bool]:
    candidate_no_worse = (
        performance_ratio >= 1.0 - eps["performance_ratio"]
        and area_ratio >= 1.0 - eps["area_ratio"]
        and (power_ratio is None
             or power_ratio >= 1.0 - eps["power_ratio"])
    )
    candidate_better = (
        performance_ratio > 1.0 + eps["performance_ratio"]
        or area_ratio > 1.0 + eps["area_ratio"]
        or (power_ratio is not None
            and power_ratio > 1.0 + eps["power_ratio"])
    )
    baseline_no_worse = (
        1.0 / performance_ratio >= 1.0 - eps["performance_ratio"]
        and 1.0 / area_ratio >= 1.0 - eps["area_ratio"]
        and (power_ratio is None
             or 1.0 / power_ratio >= 1.0 - eps["power_ratio"])
    )
    baseline_better = (
        1.0 / performance_ratio > 1.0 + eps["performance_ratio"]
        or 1.0 / area_ratio > 1.0 + eps["area_ratio"]
        or (power_ratio is not None
            and 1.0 / power_ratio > 1.0 + eps["power_ratio"])
    )
    if candidate_no_worse and candidate_better:
        relation = "candidate_dominates"
    elif baseline_no_worse and baseline_better:
        relation = "baseline_dominates"
    elif not candidate_better and not baseline_better:
        relation = "equivalent"
    else:
        relation = "tradeoff"
    return (
        relation,
        candidate_no_worse,
        candidate_better,
        baseline_no_worse,
        baseline_better,
    )


def evaluate_ratios(
    *,
    per_benchmark_ratio: dict[str, float],
    performance_ratio: float,
    area_ratio: float,
    power_ratio: float | None,
    timing_ok: bool,
    target: str,
    policy: dict[str, Any],
    checker_audited: bool,
) -> dict[str, Any]:
    if target not in {"proxy_champion", "final_champion"}:
        raise SystemExit(f"invalid comparison target: {target}")
    ratios_to_validate = list(per_benchmark_ratio.values())
    ratios_to_validate.extend((performance_ratio, area_ratio))
    if power_ratio is not None:
        ratios_to_validate.append(power_ratio)
    if (not per_benchmark_ratio
            or not all(finite_positive_number(value)
                       for value in ratios_to_validate)):
        raise SystemExit("comparison ratios must be finite and positive")
    if not isinstance(timing_ok, bool) or not isinstance(checker_audited, bool):
        raise SystemExit("comparison gates must be booleans")

    promotion, eps = promotion_config(policy)
    qualified_ratios = [performance_ratio, area_ratio]
    if power_ratio is not None:
        qualified_ratios.append(power_ratio)
    score = 100.0 * math.prod(qualified_ratios) ** (
        1.0 / len(qualified_ratios))
    (
        relation,
        candidate_no_worse,
        candidate_better,
        baseline_no_worse,
        baseline_better,
    ) = classify_pareto(
        performance_ratio, area_ratio, power_ratio, eps)

    per_benchmark_floor = promotion["minimum_per_benchmark_ratio"]
    per_benchmark_floor_ok = all(
        ratio >= per_benchmark_floor
        for ratio in per_benchmark_ratio.values()
    )
    performance_floor_ok = (
        performance_ratio >= promotion["minimum_performance_ratio"])
    area_floor_ok = (
        area_ratio >= promotion["minimum_area_efficiency_ratio"])
    power_floor_ok = (
        power_ratio is None
        or power_ratio >= promotion["minimum_power_efficiency_ratio"]
    )
    legacy_area_cap_ok = (
        1.0 / area_ratio <= promotion["maximum_area_ratio"])
    score_ok = score > promotion["minimum_balanced_score"]
    dominance_ok = relation == "candidate_dominates"
    target_axis_ok = target == "proxy_champion" or power_ratio is not None
    all_axis_floors_ok = (
        performance_floor_ok
        and area_floor_ok
        and power_floor_ok
        and target_axis_ok
    )
    numeric_promotion_ok = (
        per_benchmark_floor_ok
        and all_axis_floors_ok
        and legacy_area_cap_ok
        and score_ok
        and dominance_ok
        and timing_ok
    )
    pairwise_eligible = checker_audited and numeric_promotion_ok

    blockers: list[str] = []
    if not checker_audited:
        blockers.append("checker audit was bypassed")
    if not per_benchmark_floor_ok:
        blockers.append("per-benchmark performance floor failed")
    if not performance_floor_ok:
        blockers.append("aggregate performance floor failed")
    if not area_floor_ok:
        blockers.append("area efficiency floor failed")
    if not power_floor_ok:
        blockers.append("power efficiency floor failed")
    if not legacy_area_cap_ok:
        blockers.append("legacy maximum area ratio failed")
    if not score_ok:
        blockers.append("balanced score threshold failed")
    if not dominance_ok:
        blockers.append("candidate does not dominate baseline on all qualified axes")
    if not timing_ok:
        blockers.append("timing hard gate failed")
    if not target_axis_ok:
        blockers.append("target requires qualified power")

    return {
        "balanced_score": score,
        "pareto_relation_on_qualified_axes": relation,
        "candidate_no_worse_on_qualified_axes": candidate_no_worse,
        "candidate_better_on_qualified_axes": candidate_better,
        "baseline_no_worse_on_qualified_axes": baseline_no_worse,
        "baseline_better_on_qualified_axes": baseline_better,
        "per_benchmark_floor": per_benchmark_floor,
        "per_benchmark_floor_met": per_benchmark_floor_ok,
        "qualified_axis_floors": {
            "performance": promotion["minimum_performance_ratio"],
            "area_efficiency": promotion["minimum_area_efficiency_ratio"],
            "power_efficiency": (
                promotion["minimum_power_efficiency_ratio"]
                if power_ratio is not None else None
            ),
        },
        "all_qualified_axis_floors_met": all_axis_floors_ok,
        "balanced_score_threshold_met": score_ok,
        "candidate_dominance_required": True,
        "candidate_dominance_met": dominance_ok,
        "numeric_promotion_thresholds_met": numeric_promotion_ok,
        "pairwise_promotion_eligible": pairwise_eligible,
        "pairwise_promotion_blockers": blockers,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline", type=pathlib.Path)
    parser.add_argument("candidate", type=pathlib.Path)
    parser.add_argument("--allow-provisional-recovery", action="store_true")
    gate_mode = parser.add_mutually_exclusive_group()
    gate_mode.add_argument("--require-promotable", action="store_true")
    gate_mode.add_argument("--require-pairwise-eligible", action="store_true")
    parser.add_argument("--target", choices=("proxy_champion", "final_champion"),
                        default="proxy_champion")
    args = parser.parse_args()
    baseline_path = args.baseline.resolve()
    candidate_path = args.candidate.resolve()
    base = load(baseline_path)
    cand = load(candidate_path)
    root = repo_root(baseline_path.parent)
    candidate_root = repo_root(candidate_path.parent)
    if root.resolve() != candidate_root.resolve():
        raise SystemExit("baseline and candidate must be in the same repository")
    recovery_only = args.allow_provisional_recovery
    checker = pathlib.Path(__file__).resolve().with_name("check.py")
    if not recovery_only:
        audit(checker, baseline_path, args.target, require_accepted=True)
        audit(checker, candidate_path, args.target, require_accepted=False)
    if base.get("policy_id") != cand.get("policy_id"):
        raise SystemExit("policy mismatch")
    if base.get("cohort_id") != cand.get("cohort_id"):
        raise SystemExit("cohort mismatch")
    if base.get("claim_tier") != cand.get("claim_tier"):
        raise SystemExit("claim tier mismatch")
    if base.get("area", {}).get("metric_kind") != cand.get("area", {}).get("metric_kind"):
        raise SystemExit("area metric mismatch")
    if base.get("area", {}).get("unit") != cand.get("area", {}).get("unit"):
        raise SystemExit("area unit mismatch")
    if (base.get("area", {}).get("unknown_cell_types") !=
            cand.get("area", {}).get("unknown_cell_types")):
        raise SystemExit("area unknown-cell inventory mismatch")
    if base.get("policy") != cand.get("policy"):
        raise SystemExit("policy path mismatch")
    policy_path = workspace_file(root, base["policy"])
    policy = load(policy_path)
    if policy.get("schema") != "npc-rv64-ppa-policy-v1":
        raise SystemExit("unsupported policy schema")
    if policy.get("policy_id") != base.get("policy_id"):
        raise SystemExit("policy_id does not match policy file")
    base_artifacts = artifact_sha_map(base)
    cand_artifacts = artifact_sha_map(cand)
    shared_kinds = (
        "config_manifest",
        "required_test_manifest",
        "coremark_image",
        "dhrystone_image",
    )
    for kind in shared_kinds:
        base_sha = base_artifacts.get(kind)
        cand_sha = cand_artifacts.get(kind)
        if (not recovery_only and (base_sha is None or cand_sha is None or base_sha != cand_sha)):
            raise SystemExit(f"cohort artifact mismatch: {kind}")
    if (not recovery_only and (args.target == "final_champion"
            or (base.get("power", {}).get("qualified_for_promotion") is True
                and cand.get("power", {}).get(
                    "qualified_for_promotion") is True))):
        if (base_artifacts.get("power_workload_manifest") is None
                or base_artifacts.get("power_workload_manifest")
                != cand_artifacts.get("power_workload_manifest")):
            raise SystemExit("cohort artifact mismatch: power_workload_manifest")
    bmap = benchmark_map(base)
    cmap = benchmark_map(cand)
    required_benchmarks = set(policy["benchmarks"])
    if not required_benchmarks.issubset(bmap) or not required_benchmarks.issubset(cmap):
        raise SystemExit("required benchmark missing")
    weighted_log = 0.0
    weight_sum = 0.0
    per_benchmark_ratio: dict[str, float] = {}
    qualified_mhz = policy["timing"]["qualified_mhz"]
    for name, weight in policy["benchmarks"].items():
        base_cycles = bmap[name]["cycles"]
        base_retired = bmap[name]["retired_instructions"]
        cand_cycles = cmap[name]["cycles"]
        cand_retired = cmap[name]["retired_instructions"]
        if not all(isinstance(value, int) and not isinstance(value, bool) and value > 0
                   for value in (base_cycles, base_retired, cand_cycles, cand_retired)):
            raise SystemExit(f"invalid raw performance counters: {name}")
        if cand_retired != base_retired:
            raise SystemExit(f"retired-instruction mismatch for fixed-image A/B: {name}")
        base_q = qualified_mhz / (base_cycles / base_retired)
        cand_q = qualified_mhz / (cand_cycles / cand_retired)
        ratio = cand_q / base_q
        per_benchmark_ratio[name] = ratio
        weighted_log += float(weight) * math.log(ratio)
        weight_sum += float(weight)
    perf_ratio = math.exp(weighted_log / weight_sum)
    area_metric = (
        "total_area" if args.target == "final_champion" else "logic_area")
    base_area = base["area"].get(area_metric)
    cand_area = cand["area"].get(area_metric)
    if (not isinstance(base_area, (int, float))
            or isinstance(base_area, bool) or not math.isfinite(base_area)
            or base_area <= 0):
        raise SystemExit(f"invalid baseline {area_metric}")
    if (not isinstance(cand_area, (int, float))
            or isinstance(cand_area, bool) or not math.isfinite(cand_area)
            or cand_area <= 0):
        raise SystemExit(f"invalid candidate {area_metric}")
    area_ratio = base_area / cand_area
    power_ratio = None
    power_axis_reason = "proxy target scores performance and logic area only"
    if (args.target == "final_champion"
            and base["power"].get("qualified_for_promotion") is True
            and cand["power"].get("qualified_for_promotion") is True):
        base_power = base["power"].get("total_power_w")
        cand_power = cand["power"].get("total_power_w")
        if (not isinstance(base_power, (int, float))
                or isinstance(base_power, bool) or not math.isfinite(base_power)
                or base_power <= 0):
            raise SystemExit("invalid baseline total power")
        if (not isinstance(cand_power, (int, float))
                or isinstance(cand_power, bool) or not math.isfinite(cand_power)
                or cand_power <= 0):
            raise SystemExit("invalid candidate total power")
        power_ratio = base_power / cand_power
        power_axis_reason = "same-cohort qualified workload total power"
    elif args.target == "final_champion":
        power_axis_reason = "one or both manifests have unqualified total power"
    timing_ok = (cand["timing"].get("tier") == policy["claim_tier"] and
                 cand["timing"].get("period_ns") == policy["timing"]["period_ns"] and
                 cand["performance"].get("qualified_mhz") == policy["timing"]["qualified_mhz"] and
                 cand["timing"].get("qualified_mhz") == policy["timing"]["qualified_mhz"] and
                 cand["timing"].get("wns_ns", -math.inf) >= 0 and
                 cand["timing"]["worst_path_slack_ns"] >=
                 policy["timing"]["minimum_worst_slack_ns_for_promotion"] and
                 cand["timing"]["tns_ns"] ==
                 policy["timing"].get("required_tns_ns", 0.0) and
                 cand["timing"]["violated_path_count"] ==
                 policy["timing"].get("maximum_violated_paths", 0) and
                 cand["timing"]["combinational_loops"] ==
                 policy["timing"].get("maximum_combinational_loops", 0))
    checker_audited = not recovery_only
    evaluation = evaluate_ratios(
        per_benchmark_ratio=per_benchmark_ratio,
        performance_ratio=perf_ratio,
        area_ratio=area_ratio,
        power_ratio=power_ratio,
        timing_ok=timing_ok,
        target=args.target,
        policy=policy,
        checker_audited=checker_audited,
    )
    result = {
        "baseline": base["baseline_id"],
        "candidate": cand["baseline_id"],
        "target": args.target,
        "recovery_only": recovery_only,
        "checker_audited": checker_audited,
        "per_benchmark_performance_ratio": per_benchmark_ratio,
        "performance_ratio": perf_ratio,
        "area_metric": area_metric,
        "baseline_area": base_area,
        "candidate_area": cand_area,
        "area_ratio": area_ratio,
        "power_ratio": power_ratio,
        "power_axis": (
            "qualified"
            if power_ratio is not None
            else ("not_scored" if args.target == "proxy_champion"
                  else "unqualified")
        ),
        "power_axis_reason": power_axis_reason,
        "timing_hard_gate": timing_ok,
        **evaluation,
        "comparison_scope": "pairwise_only",
        "global_pareto_audited": False,
        "eligible_for_target_promotion": False,
        "global_promotion_blocker": (
            "pairwise comparison cannot prove global Pareto membership; "
            "use front.py"
        ),
        "full_three_axis_comparison_available": (
            args.target == "final_champion" and power_ratio is not None
        ),
        "final_three_axis_claim_allowed": False,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if args.require_promotable:
        print(
            "ERROR: pairwise comparison is not a global promotion gate; "
            "use front.py --require-winner",
            file=sys.stderr,
        )
        return 1
    if (args.require_pairwise_eligible
            and not evaluation["pairwise_promotion_eligible"]):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
