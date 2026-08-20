#!/usr/bin/env python3
"""Deterministic semantic router for the project CPU Architect Agent."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_POLICY = (
    REPO_ROOT / ".github/ai-env/contracts/cpu-architect-routing-v1.json"
)


class RouteContractError(ValueError):
    """The routing policy or task packet is structurally invalid."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RouteContractError(f"cannot load JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RouteContractError(f"JSON root must be an object: {path}")
    return value


def validate_policy(policy: dict[str, Any]) -> None:
    if policy.get("schema_version") != 1:
        raise RouteContractError("policy schema_version must be 1")
    required_fields = policy.get("required_fields")
    enums = policy.get("enums")
    routes = policy.get("routes")
    hard_gates = policy.get("architect_hard_gates")
    verification = policy.get("verification_policy")
    examples = policy.get("examples")
    if not isinstance(required_fields, list) or not all(
            isinstance(item, str) and item for item in required_fields):
        raise RouteContractError("policy required_fields must be non-empty strings")
    if len(required_fields) != len(set(required_fields)):
        raise RouteContractError("policy required_fields contains duplicates")
    if not isinstance(enums, dict):
        raise RouteContractError("policy enums must be an object")
    for name in ("domain", "intent", "design_choice", "root_cause",
                 "semantic_depth", "objective", "risk", "determinism"):
        values = enums.get(name)
        if not isinstance(values, list) or not values or not all(
                isinstance(item, str) and item for item in values):
            raise RouteContractError(f"policy enum {name} is invalid")
        if len(values) != len(set(values)):
            raise RouteContractError(f"policy enum {name} contains duplicates")
    expected_routes = {
        "ARCHITECT", "EXPLORER", "WORKER", "REVIEWER", "CLARIFY", "NON_ARCH"
    }
    if not isinstance(routes, list) or set(routes) != expected_routes:
        raise RouteContractError("policy routes do not match the canonical route set")
    if not isinstance(hard_gates, dict):
        raise RouteContractError("policy architect_hard_gates must be an object")
    if not isinstance(verification, dict):
        raise RouteContractError("policy verification_policy must be an object")
    if verification.get("default_execution_count") != 1:
        raise RouteContractError("deterministic default_execution_count must be 1")
    repeat_modes = verification.get("repeat_determinism")
    if not isinstance(repeat_modes, list) or "deterministic" in repeat_modes:
        raise RouteContractError("deterministic work must not require repetition")
    if not isinstance(examples, list) or not examples:
        raise RouteContractError("policy examples must be a non-empty array")


def validate_packet(packet: dict[str, Any], policy: dict[str, Any]) -> None:
    required = set(policy["required_fields"])
    actual = set(packet)
    missing = sorted(required - actual)
    unknown = sorted(actual - required)
    if missing:
        raise RouteContractError(f"task packet missing fields: {', '.join(missing)}")
    if unknown:
        raise RouteContractError(f"task packet has unknown fields: {', '.join(unknown)}")

    enums = policy["enums"]
    for field in ("domain", "intent", "design_choice", "root_cause",
                  "semantic_depth", "risk", "determinism"):
        if packet[field] not in enums[field]:
            raise RouteContractError(f"invalid {field}: {packet[field]!r}")
    objectives = packet["objectives"]
    if (not isinstance(objectives, list) or not objectives
            or not all(isinstance(item, str) for item in objectives)):
        raise RouteContractError("objectives must be a non-empty string array")
    unknown_objectives = sorted(set(objectives) - set(enums["objective"]))
    if unknown_objectives:
        raise RouteContractError(
            f"unknown objectives: {', '.join(unknown_objectives)}")
    if len(objectives) != len(set(objectives)):
        raise RouteContractError("objectives contains duplicates")
    for field in ("baseline_ready", "evidence_paths_ready", "candidate_exists",
                  "architecture_change_authorized", "known_machine_instability",
                  "repeat_requested"):
        if type(packet[field]) is not bool:
            raise RouteContractError(f"{field} must be a boolean")


def classify_route(packet: dict[str, Any], policy: dict[str, Any]) -> tuple[str, list[str]]:
    reasons: list[str] = []
    domain = packet["domain"]
    intent = packet["intent"]

    if domain != "local_rv64_cpu":
        return "NON_ARCH", ["DOMAIN_OUTSIDE_LOCAL_RV64_CPU"]
    if intent == "report":
        return "NON_ARCH", ["REPORT_OR_EXPLANATION_ONLY"]
    if intent == "verify":
        if packet["candidate_exists"]:
            return "REVIEWER", ["EXISTING_CANDIDATE_REQUIRES_JUDGMENT"]
        return "WORKER", ["VERIFICATION_EXECUTION_WITHOUT_DESIGN_CHOICE"]
    if intent == "implement_fixed" or packet["design_choice"] == "fixed":
        return "WORKER", ["DESIGN_CHOICE_ALREADY_FIXED"]

    if intent in {"redesign", "trade_study"} and not packet[
            "architecture_change_authorized"]:
        return "CLARIFY", ["ARCHITECTURE_CHANGE_AUTHORITY_MISSING"]

    hard = policy["architect_hard_gates"]
    if packet["design_choice"] != hard["design_choice"]:
        return "EXPLORER", ["OPEN_DESIGN_CHOICE_NOT_ESTABLISHED"]
    if intent not in hard["intents"]:
        return "EXPLORER", ["CAUSAL_DIAGNOSIS_REQUIRED_BEFORE_DESIGN"]
    if packet["semantic_depth"] not in hard["semantic_depth"]:
        return "WORKER", ["SEMANTIC_DEPTH_IS_LOCAL_OR_MECHANICAL"]
    if packet["root_cause"] not in hard["root_cause"]:
        reasons.append("CAUSAL_ROOT_CAUSE_NOT_READY")
    if not packet["baseline_ready"]:
        reasons.append("BASELINE_NOT_READY")
    if not packet["evidence_paths_ready"]:
        reasons.append("EVIDENCE_PATHS_NOT_READY")

    objectives = set(packet["objectives"])
    if hard["required_objective"] not in objectives:
        reasons.append("CORRECTNESS_OBJECTIVE_MISSING")
    if not objectives.intersection(hard["required_tradeoff_objectives"]):
        reasons.append("MEASURABLE_TRADEOFF_OBJECTIVE_MISSING")
    if reasons:
        return "EXPLORER", reasons
    return "ARCHITECT", [
        "LOCAL_RV64_OPEN_STRUCTURAL_DECISION",
        "CAUSAL_BASELINE_AND_EVIDENCE_READY",
        "CORRECTNESS_AND_TRADEOFF_OBJECTIVES_PRESENT",
    ]


def verification_disposition(
        packet: dict[str, Any], policy: dict[str, Any], route: str
) -> tuple[str, str, list[str]]:
    verification = policy["verification_policy"]
    repeat_reasons: list[str] = []
    if packet["determinism"] in verification["repeat_determinism"]:
        repeat_reasons.append(f"NON_DETERMINISTIC_MODE:{packet['determinism']}")
    if packet["known_machine_instability"]:
        repeat_reasons.append("KNOWN_MACHINE_INSTABILITY")
    if packet["repeat_requested"]:
        repeat_reasons.append("USER_EXPLICIT_REPEAT_REQUEST")
    execution = "REPEAT_WITH_REASON" if repeat_reasons else "SINGLE_PASS"

    independent = (
        packet["risk"] in verification["independent_review_risks"]
        or route == "REVIEWER"
    )
    review = "INDEPENDENT" if independent else "SELF_CRITIC"
    return execution, review, repeat_reasons


def classify(packet: dict[str, Any], policy: dict[str, Any]) -> dict[str, Any]:
    validate_policy(policy)
    validate_packet(packet, policy)
    route, reason_codes = classify_route(packet, policy)
    execution, review, repeat_reasons = verification_disposition(
        packet, policy, route)
    return {
        "schema_version": 1,
        "router_id": policy["router_id"],
        "route": route,
        "reason_codes": reason_codes,
        "verification": {
            "execution": execution,
            "default_execution_count": 1,
            "repeat_reasons": repeat_reasons,
            "review": review,
            "distinct_evidence_is_not_repetition": True,
        },
    }


def run_self_test(policy: dict[str, Any]) -> None:
    validate_policy(policy)
    failures: list[str] = []
    for example in policy["examples"]:
        example_id = example.get("id", "<missing-id>")
        packet = example.get("packet")
        expected = example.get("expected")
        if not isinstance(packet, dict) or not isinstance(expected, dict):
            failures.append(f"{example_id}: packet/expected must be objects")
            continue
        try:
            actual = classify(packet, policy)
        except RouteContractError as exc:
            failures.append(f"{example_id}: {exc}")
            continue
        actual_triplet = {
            "route": actual["route"],
            "execution": actual["verification"]["execution"],
            "review": actual["verification"]["review"],
        }
        if actual_triplet != expected:
            failures.append(
                f"{example_id}: expected={expected} actual={actual_triplet}")
    if failures:
        raise RouteContractError("self-test failed:\n" + "\n".join(failures))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    subparsers = parser.add_subparsers(dest="command", required=True)
    classify_parser = subparsers.add_parser("classify")
    classify_parser.add_argument("--input", type=Path, required=True)
    subparsers.add_parser("validate-policy")
    subparsers.add_parser("self-test")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        policy = load_json(args.policy.resolve())
        if args.command == "validate-policy":
            validate_policy(policy)
            print("[CPU-ARCH-ROUTER] PASS policy")
        elif args.command == "self-test":
            run_self_test(policy)
            print(f"[CPU-ARCH-ROUTER] PASS examples={len(policy['examples'])}")
        else:
            packet = load_json(args.input.resolve())
            print(json.dumps(classify(packet, policy), ensure_ascii=False,
                             indent=2, sort_keys=True))
    except RouteContractError as exc:
        print(f"[CPU-ARCH-ROUTER] FAIL {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
