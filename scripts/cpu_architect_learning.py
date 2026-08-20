#!/usr/bin/env python3
"""Validate grounded self-improvement records for the CPU Architect Agent.

This intentionally does not train or update model weights.  It validates the
evidence-bearing records that may later be consolidated or exported for an
externally controlled training pipeline.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_ROOT = REPO_ROOT / ".github/ai-env/contracts"
DEFAULT_POLICY = CONTRACT_ROOT / "cpu-architect-learning-v1.json"
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]+$")
ERROR_CLASSES = {f"E{number}" for number in range(1, 11)}


class LearningContractError(ValueError):
    """A learning contract or record is invalid."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise LearningContractError(f"cannot load JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise LearningContractError(f"JSON root must be an object: {path}")
    return value


def _exact_keys(value: Any, expected: set[str], where: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise LearningContractError(f"{where} must be an object")
    actual = set(value)
    missing = sorted(expected - actual)
    unknown = sorted(actual - expected)
    if missing:
        raise LearningContractError(f"{where} missing fields: {', '.join(missing)}")
    if unknown:
        raise LearningContractError(f"{where} has unknown fields: {', '.join(unknown)}")
    return value


def _string(value: Any, where: str, *, allow_empty: bool = False) -> str:
    if not isinstance(value, str) or (not allow_empty and not value):
        raise LearningContractError(f"{where} must be a non-empty string")
    return value


def _identifier(value: Any, where: str) -> str:
    text = _string(value, where)
    if not ID_RE.fullmatch(text):
        raise LearningContractError(f"{where} is not a canonical identifier: {text!r}")
    return text


def _strings(
    value: Any, where: str, *, min_items: int = 0, unique: bool = False
) -> list[str]:
    if not isinstance(value, list) or len(value) < min_items:
        raise LearningContractError(f"{where} must contain at least {min_items} strings")
    if not all(isinstance(item, str) and item for item in value):
        raise LearningContractError(f"{where} must contain non-empty strings")
    if unique and len(value) != len(set(value)):
        raise LearningContractError(f"{where} contains duplicates")
    return value


def _number(
    value: Any,
    where: str,
    *,
    minimum: float | None = None,
    maximum: float | None = None,
    exclusive_minimum: bool = False,
) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise LearningContractError(f"{where} must be a number")
    result = float(value)
    if not math.isfinite(result):
        raise LearningContractError(f"{where} must be finite")
    if minimum is not None:
        invalid = result <= minimum if exclusive_minimum else result < minimum
        if invalid:
            relation = ">" if exclusive_minimum else ">="
            raise LearningContractError(f"{where} must be {relation} {minimum}")
    if maximum is not None and result > maximum:
        raise LearningContractError(f"{where} must be <= {maximum}")
    return result


def _optional_number(
    value: Any, where: str, *, minimum: float | None = None,
    maximum: float | None = None
) -> float | None:
    if value is None:
        return None
    return _number(value, where, minimum=minimum, maximum=maximum)


def _integer(value: Any, where: str, *, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise LearningContractError(f"{where} must be an integer >= {minimum}")
    return value


def _timestamp(value: Any, where: str, *, nullable: bool = False) -> datetime | None:
    if value is None and nullable:
        return None
    text = _string(value, where)
    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise LearningContractError(f"{where} must be an ISO-8601 timestamp") from exc
    if parsed.tzinfo is None:
        raise LearningContractError(f"{where} must include a timezone")
    return parsed


def validate_contracts(policy: dict[str, Any]) -> None:
    if policy.get("schema_version") != 1:
        raise LearningContractError("learning policy schema_version must be 1")
    taxonomy = policy.get("error_taxonomy")
    if not isinstance(taxonomy, dict) or set(taxonomy) != ERROR_CLASSES:
        raise LearningContractError("learning policy must define E1..E10 exactly")
    hierarchy = _strings(
        policy.get("ground_truth_hierarchy"), "ground_truth_hierarchy",
        min_items=8, unique=True)
    eligible = _strings(
        policy.get("training_eligible_ground_truth"),
        "training_eligible_ground_truth", min_items=1, unique=True)
    if not set(eligible).issubset(hierarchy):
        raise LearningContractError("training ground truth must be in the hierarchy")
    if {"human_review", "llm_opinion"}.intersection(eligible):
        raise LearningContractError("human/LLM opinion cannot make training data eligible")
    boundary = policy.get("training_boundary")
    if not isinstance(boundary, dict):
        raise LearningContractError("training_boundary must be an object")
    if boundary.get("autonomous_weight_update") is not False:
        raise LearningContractError("autonomous weight update must remain disabled")
    if boundary.get("generated_proposal_is_ground_truth") is not False:
        raise LearningContractError("generated proposals cannot be ground truth")
    if boundary.get("export_only") is not True:
        raise LearningContractError("training candidates must remain export-only")
    schemas = policy.get("schemas")
    expected_schema_keys = {"capability_graph", "experience_record", "knowledge_gap"}
    if not isinstance(schemas, dict) or set(schemas) != expected_schema_keys:
        raise LearningContractError("policy schemas must name the three core records")
    for kind, relative_path in schemas.items():
        schema = load_json(REPO_ROOT / _string(relative_path, f"schemas.{kind}"))
        if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            raise LearningContractError(f"{kind} is not a draft-2020-12 schema")
        if schema.get("type") != "object" or schema.get("additionalProperties") is not False:
            raise LearningContractError(f"{kind} schema must be a closed object")
        if schema.get("properties", {}).get("schema_version", {}).get("const") != 1:
            raise LearningContractError(f"{kind} schema_version must be const 1")


def validate_capability_graph(record: dict[str, Any], policy: dict[str, Any]) -> None:
    del policy
    _exact_keys(record, {"schema_version", "graph_id", "design_scope", "nodes", "updated_at"}, "CapabilityGraph")
    if record["schema_version"] != 1:
        raise LearningContractError("CapabilityGraph.schema_version must be 1")
    _identifier(record["graph_id"], "CapabilityGraph.graph_id")
    scope = _exact_keys(record["design_scope"], {"design_id", "source_manifest", "configuration"}, "CapabilityGraph.design_scope")
    for field in scope:
        _string(scope[field], f"CapabilityGraph.design_scope.{field}")
    _timestamp(record["updated_at"], "CapabilityGraph.updated_at")
    nodes = record["nodes"]
    if not isinstance(nodes, list):
        raise LearningContractError("CapabilityGraph.nodes must be an array")
    ids: list[str] = []
    allowed_domains = {
        "frontend", "rename_dispatch", "scheduler_issue", "execution_bypass",
        "memory_ordering", "cache_mmu_interconnect", "commit_trap_control",
        "performance_modeling", "physical_design", "experimental_method", "tooling",
    }
    allowed_status = {"unknown", "learning", "calibrating", "validated", "stale"}
    for index, raw_node in enumerate(nodes):
        where = f"CapabilityGraph.nodes[{index}]"
        node = _exact_keys(raw_node, {
            "capability_id", "domain", "applicability", "scores", "sample_counts",
            "calibration", "prerequisites", "status", "evidence_refs", "last_updated",
        }, where)
        capability_id = _identifier(node["capability_id"], f"{where}.capability_id")
        ids.append(capability_id)
        if node["domain"] not in allowed_domains:
            raise LearningContractError(f"{where}.domain is invalid")
        applicability = _exact_keys(node["applicability"], {"status", "workspace_claim", "evidence_refs"}, f"{where}.applicability")
        if applicability["status"] not in {"unknown", "candidate", "confirmed", "not_present"}:
            raise LearningContractError(f"{where}.applicability.status is invalid")
        _string(applicability["workspace_claim"], f"{where}.applicability.workspace_claim", allow_empty=True)
        app_evidence = _strings(applicability["evidence_refs"], f"{where}.applicability.evidence_refs", unique=True)
        if applicability["status"] in {"confirmed", "not_present"} and not app_evidence:
            raise LearningContractError(f"{where} confirmed applicability requires evidence")
        scores = _exact_keys(node["scores"], {"knowledge", "reasoning", "prediction_accuracy", "confidence_calibration"}, f"{where}.scores")
        for name, value in scores.items():
            _optional_number(value, f"{where}.scores.{name}", minimum=0, maximum=1)
        counts = _exact_keys(node["sample_counts"], {"experiments", "successes", "failures", "unseen_exams"}, f"{where}.sample_counts")
        for name, value in counts.items():
            _integer(value, f"{where}.sample_counts.{name}")
        if counts["successes"] + counts["failures"] > counts["experiments"]:
            raise LearningContractError(f"{where} successes+failures exceeds experiments")
        calibration = _exact_keys(node["calibration"], {"prediction_count", "interval_coverage", "mean_absolute_error"}, f"{where}.calibration")
        _integer(calibration["prediction_count"], f"{where}.calibration.prediction_count")
        coverage = _optional_number(calibration["interval_coverage"], f"{where}.calibration.interval_coverage", minimum=0, maximum=1)
        error = _optional_number(calibration["mean_absolute_error"], f"{where}.calibration.mean_absolute_error", minimum=0)
        if calibration["prediction_count"] > counts["experiments"]:
            raise LearningContractError(f"{where} prediction_count exceeds experiments")
        if calibration["prediction_count"] == 0 and (coverage is not None or error is not None):
            raise LearningContractError(f"{where} zero predictions require null calibration metrics")
        _strings(node["prerequisites"], f"{where}.prerequisites", unique=True)
        if node["status"] not in allowed_status:
            raise LearningContractError(f"{where}.status is invalid")
        evidence = _strings(node["evidence_refs"], f"{where}.evidence_refs", unique=True)
        _timestamp(node["last_updated"], f"{where}.last_updated")
        if node["status"] == "validated":
            if applicability["status"] != "confirmed" or not evidence:
                raise LearningContractError(f"{where} validated capability requires confirmed local evidence")
            if counts["unseen_exams"] < 1 or any(value is None for value in scores.values()):
                raise LearningContractError(f"{where} validated capability requires scored unseen exam evidence")
    if len(ids) != len(set(ids)):
        raise LearningContractError("CapabilityGraph capability_id values must be unique")
    known_ids = set(ids)
    for index, node in enumerate(nodes):
        unknown = sorted(set(node["prerequisites"]) - known_ids)
        if unknown:
            raise LearningContractError(f"CapabilityGraph.nodes[{index}] has unknown prerequisites: {', '.join(unknown)}")


def validate_experience_record(record: dict[str, Any], policy: dict[str, Any]) -> None:
    root_fields = {
        "schema_version", "experience_id", "state", "design_context", "objective",
        "observation", "hypothesis", "prediction", "proposal", "experiment", "result",
        "comparison", "meta_critic", "corrected_strategy", "training", "timestamps",
    }
    _exact_keys(record, root_fields, "ExperienceRecord")
    if record["schema_version"] != 1:
        raise LearningContractError("ExperienceRecord.schema_version must be 1")
    _identifier(record["experience_id"], "ExperienceRecord.experience_id")
    if record["state"] not in {"planned", "measured", "diagnosed", "consolidated"}:
        raise LearningContractError("ExperienceRecord.state is invalid")
    context = _exact_keys(record["design_context"], {"design_id", "source_manifest", "workload", "configuration", "toolchain"}, "ExperienceRecord.design_context")
    for field in context:
        _string(context[field], f"ExperienceRecord.design_context.{field}")
    objectives = _strings(record["objective"], "ExperienceRecord.objective", min_items=1, unique=True)
    if not set(objectives).issubset({"correctness", "cpi", "timing", "area", "power", "complexity"}):
        raise LearningContractError("ExperienceRecord.objective contains an unknown objective")
    observation = _exact_keys(record["observation"], {"claim", "evidence_refs"}, "ExperienceRecord.observation")
    _string(observation["claim"], "ExperienceRecord.observation.claim")
    _strings(observation["evidence_refs"], "ExperienceRecord.observation.evidence_refs", min_items=1, unique=True)
    hypothesis = _exact_keys(record["hypothesis"], {"claim", "mechanism_chain", "competing_explanations", "falsifier"}, "ExperienceRecord.hypothesis")
    _string(hypothesis["claim"], "ExperienceRecord.hypothesis.claim")
    _strings(hypothesis["mechanism_chain"], "ExperienceRecord.hypothesis.mechanism_chain", min_items=4)
    _strings(hypothesis["competing_explanations"], "ExperienceRecord.hypothesis.competing_explanations", min_items=1)
    _string(hypothesis["falsifier"], "ExperienceRecord.hypothesis.falsifier")
    prediction = _exact_keys(record["prediction"], {"metric", "expected", "lower", "upper", "unit", "confidence"}, "ExperienceRecord.prediction")
    _string(prediction["metric"], "ExperienceRecord.prediction.metric")
    lower = _number(prediction["lower"], "ExperienceRecord.prediction.lower")
    expected = _number(prediction["expected"], "ExperienceRecord.prediction.expected")
    upper = _number(prediction["upper"], "ExperienceRecord.prediction.upper")
    if not lower <= expected <= upper:
        raise LearningContractError("ExperienceRecord prediction must satisfy lower <= expected <= upper")
    _string(prediction["unit"], "ExperienceRecord.prediction.unit")
    _number(prediction["confidence"], "ExperienceRecord.prediction.confidence", minimum=0, maximum=1, exclusive_minimum=True)
    proposal = _exact_keys(record["proposal"], {"transform_id", "architectural_diff", "preserved_invariants", "rollback"}, "ExperienceRecord.proposal")
    _string(proposal["transform_id"], "ExperienceRecord.proposal.transform_id")
    _string(proposal["architectural_diff"], "ExperienceRecord.proposal.architectural_diff")
    _strings(proposal["preserved_invariants"], "ExperienceRecord.proposal.preserved_invariants", min_items=1)
    _string(proposal["rollback"], "ExperienceRecord.proposal.rollback")
    experiment = _exact_keys(record["experiment"], {"command", "input_refs", "determinism", "repeat_reason", "evidence_refs"}, "ExperienceRecord.experiment")
    _string(experiment["command"], "ExperienceRecord.experiment.command")
    _strings(experiment["input_refs"], "ExperienceRecord.experiment.input_refs", min_items=1, unique=True)
    determinism_values = {"deterministic", "concurrent", "flaky", "variable_ppa", "stochastic", "unknown"}
    if experiment["determinism"] not in determinism_values:
        raise LearningContractError("ExperienceRecord.experiment.determinism is invalid")
    if experiment["repeat_reason"] is not None:
        _string(experiment["repeat_reason"], "ExperienceRecord.experiment.repeat_reason")
    if experiment["determinism"] == "deterministic" and experiment["repeat_reason"]:
        raise LearningContractError("deterministic experiment must not request mechanical repetition")
    _strings(experiment["evidence_refs"], "ExperienceRecord.experiment.evidence_refs", unique=True)
    result = _exact_keys(record["result"], {"status", "actual", "unit", "evidence_refs"}, "ExperienceRecord.result")
    if result["status"] not in {"planned", "pass", "fail", "inconclusive", "tool_error"}:
        raise LearningContractError("ExperienceRecord.result.status is invalid")
    actual = _optional_number(result["actual"], "ExperienceRecord.result.actual")
    _string(result["unit"], "ExperienceRecord.result.unit")
    result_evidence = _strings(result["evidence_refs"], "ExperienceRecord.result.evidence_refs", unique=True)
    if result["unit"] != prediction["unit"]:
        raise LearningContractError("ExperienceRecord prediction/result units differ")
    if result["status"] == "planned" and actual is not None:
        raise LearningContractError("planned result cannot have an actual value")
    if result["status"] in {"pass", "fail", "inconclusive"} and (actual is None or not result_evidence):
        raise LearningContractError("measured result requires actual value and evidence")
    comparison = _exact_keys(record["comparison"], {"prediction_error", "interval_hit", "causal_conclusion"}, "ExperienceRecord.comparison")
    prediction_error = _optional_number(comparison["prediction_error"], "ExperienceRecord.comparison.prediction_error")
    if comparison["interval_hit"] is not None and type(comparison["interval_hit"]) is not bool:
        raise LearningContractError("ExperienceRecord.comparison.interval_hit must be boolean or null")
    _string(comparison["causal_conclusion"], "ExperienceRecord.comparison.causal_conclusion", allow_empty=True)
    if actual is not None:
        expected_error = actual - expected
        if prediction_error is None or not math.isclose(prediction_error, expected_error, rel_tol=1e-9, abs_tol=1e-9):
            raise LearningContractError("ExperienceRecord.prediction_error must equal actual - expected")
        expected_hit = lower <= actual <= upper
        if comparison["interval_hit"] is not expected_hit:
            raise LearningContractError("ExperienceRecord.interval_hit disagrees with the registered interval")
    critic = _exact_keys(record["meta_critic"], {"complete", "error_classes", "knowledge_gap_ids", "diagnosis"}, "ExperienceRecord.meta_critic")
    if type(critic["complete"]) is not bool:
        raise LearningContractError("ExperienceRecord.meta_critic.complete must be boolean")
    error_classes = _strings(critic["error_classes"], "ExperienceRecord.meta_critic.error_classes", unique=True)
    if not set(error_classes).issubset(ERROR_CLASSES):
        raise LearningContractError("ExperienceRecord.meta_critic has unknown error classes")
    _strings(critic["knowledge_gap_ids"], "ExperienceRecord.meta_critic.knowledge_gap_ids", unique=True)
    _string(critic["diagnosis"], "ExperienceRecord.meta_critic.diagnosis", allow_empty=True)
    strategy = _exact_keys(record["corrected_strategy"], {"action", "scope", "exceptions"}, "ExperienceRecord.corrected_strategy")
    _string(strategy["action"], "ExperienceRecord.corrected_strategy.action", allow_empty=True)
    _string(strategy["scope"], "ExperienceRecord.corrected_strategy.scope", allow_empty=True)
    _strings(strategy["exceptions"], "ExperienceRecord.corrected_strategy.exceptions")
    training = _exact_keys(record["training"], {"eligible", "ground_truth_level", "unseen_exam_passed", "reasons"}, "ExperienceRecord.training")
    if type(training["eligible"]) is not bool or type(training["unseen_exam_passed"]) is not bool:
        raise LearningContractError("ExperienceRecord.training eligibility/exam flags must be boolean")
    truth_levels = set(policy["ground_truth_hierarchy"])
    if training["ground_truth_level"] not in truth_levels:
        raise LearningContractError("ExperienceRecord.training.ground_truth_level is invalid")
    _strings(training["reasons"], "ExperienceRecord.training.reasons", min_items=1)
    timestamps = _exact_keys(record["timestamps"], {"predicted_at", "measured_at", "updated_at"}, "ExperienceRecord.timestamps")
    predicted_at = _timestamp(timestamps["predicted_at"], "ExperienceRecord.timestamps.predicted_at")
    measured_at = _timestamp(timestamps["measured_at"], "ExperienceRecord.timestamps.measured_at", nullable=True)
    updated_at = _timestamp(timestamps["updated_at"], "ExperienceRecord.timestamps.updated_at")
    if measured_at is not None and predicted_at is not None and measured_at < predicted_at:
        raise LearningContractError("prediction must be registered before measurement")
    if measured_at is not None and updated_at is not None and updated_at < measured_at:
        raise LearningContractError("updated_at cannot precede measured_at")
    if result["status"] != "planned" and measured_at is None:
        raise LearningContractError("non-planned result requires measured_at")
    if record["state"] in {"diagnosed", "consolidated"} and not critic["complete"]:
        raise LearningContractError("diagnosed/consolidated experience requires a complete meta-critic")
    if training["eligible"]:
        failures: list[str] = []
        if training["ground_truth_level"] not in set(policy["training_eligible_ground_truth"]):
            failures.append("ground truth is not objectively eligible")
        if not training["unseen_exam_passed"]:
            failures.append("unseen exam not passed")
        if not critic["complete"]:
            failures.append("meta-critic incomplete")
        if result["status"] not in {"pass", "fail", "inconclusive"} or not result_evidence:
            failures.append("objective measured evidence missing")
        if not strategy["scope"] or not strategy["exceptions"]:
            failures.append("scope or exceptions missing")
        if failures:
            raise LearningContractError("training candidate is not eligible: " + "; ".join(failures))


def validate_knowledge_gap(record: dict[str, Any], policy: dict[str, Any]) -> None:
    del policy
    root_fields = {
        "schema_version", "gap_id", "source_experience_ids", "trigger", "error_class",
        "failed_prediction", "missing_information", "falsifiable_question", "capability_ids",
        "acquisition_plan", "validation_plan", "priority", "status", "evidence_refs",
    }
    _exact_keys(record, root_fields, "KnowledgeGap")
    if record["schema_version"] != 1:
        raise LearningContractError("KnowledgeGap.schema_version must be 1")
    _identifier(record["gap_id"], "KnowledgeGap.gap_id")
    _strings(record["source_experience_ids"], "KnowledgeGap.source_experience_ids", min_items=1, unique=True)
    if record["trigger"] not in {"failure", "uncertainty", "calibration", "tool_error", "counterexample"}:
        raise LearningContractError("KnowledgeGap.trigger is invalid")
    if record["error_class"] not in ERROR_CLASSES:
        raise LearningContractError("KnowledgeGap.error_class is invalid")
    for name in ("failed_prediction", "missing_information", "falsifiable_question"):
        _string(record[name], f"KnowledgeGap.{name}")
    _strings(record["capability_ids"], "KnowledgeGap.capability_ids", min_items=1, unique=True)
    acquisition = _exact_keys(record["acquisition_plan"], {"level", "action", "source_refs"}, "KnowledgeGap.acquisition_plan")
    if acquisition["level"] not in {"context_acquisition", "knowledge_memory", "strategy_memory", "training_candidate"}:
        raise LearningContractError("KnowledgeGap.acquisition_plan.level is invalid")
    _string(acquisition["action"], "KnowledgeGap.acquisition_plan.action")
    source_refs = _strings(acquisition["source_refs"], "KnowledgeGap.acquisition_plan.source_refs", unique=True)
    if acquisition["level"] == "training_candidate" and not source_refs:
        raise LearningContractError("training_candidate acquisition requires external sources")
    validation = _exact_keys(record["validation_plan"], {"cheapest_discriminating_experiment", "expected_uncertainty_reduction", "experiment_cost", "voi", "success_criterion", "counterexample"}, "KnowledgeGap.validation_plan")
    _string(validation["cheapest_discriminating_experiment"], "KnowledgeGap.validation_plan.cheapest_discriminating_experiment")
    reduction = _number(validation["expected_uncertainty_reduction"], "KnowledgeGap.validation_plan.expected_uncertainty_reduction", minimum=0)
    cost = _number(validation["experiment_cost"], "KnowledgeGap.validation_plan.experiment_cost", minimum=0, exclusive_minimum=True)
    voi = _number(validation["voi"], "KnowledgeGap.validation_plan.voi", minimum=0)
    if not math.isclose(voi, reduction / cost, rel_tol=1e-9, abs_tol=1e-9):
        raise LearningContractError("KnowledgeGap.voi must equal expected_uncertainty_reduction / experiment_cost")
    _string(validation["success_criterion"], "KnowledgeGap.validation_plan.success_criterion")
    _string(validation["counterexample"], "KnowledgeGap.validation_plan.counterexample")
    priority = _exact_keys(record["priority"], {"impact", "frequency", "uncertainty", "learning_cost", "score"}, "KnowledgeGap.priority")
    impact = _number(priority["impact"], "KnowledgeGap.priority.impact", minimum=0)
    frequency = _number(priority["frequency"], "KnowledgeGap.priority.frequency", minimum=0)
    uncertainty = _number(priority["uncertainty"], "KnowledgeGap.priority.uncertainty", minimum=0)
    learning_cost = _number(priority["learning_cost"], "KnowledgeGap.priority.learning_cost", minimum=0, exclusive_minimum=True)
    score = _number(priority["score"], "KnowledgeGap.priority.score", minimum=0)
    expected_score = impact * frequency * uncertainty / learning_cost
    if not math.isclose(score, expected_score, rel_tol=1e-9, abs_tol=1e-9):
        raise LearningContractError("KnowledgeGap.priority.score does not match the policy formula")
    if record["status"] not in {"open", "learning", "exam_pending", "validated", "rejected"}:
        raise LearningContractError("KnowledgeGap.status is invalid")
    evidence = _strings(record["evidence_refs"], "KnowledgeGap.evidence_refs", unique=True)
    if record["status"] == "validated" and not evidence:
        raise LearningContractError("validated KnowledgeGap requires evidence")


def validate_record(kind: str, record: dict[str, Any], policy: dict[str, Any]) -> None:
    validate_contracts(policy)
    validators = {
        "capability": validate_capability_graph,
        "experience": validate_experience_record,
        "gap": validate_knowledge_gap,
    }
    validators[kind](record, policy)


def _valid_examples() -> dict[str, dict[str, Any]]:
    stamp = "2026-08-09T12:00:00+08:00"
    capability = {
        "schema_version": 1,
        "graph_id": "rv64-capability-demo",
        "design_scope": {"design_id": "sha256:demo", "source_manifest": "manifest.json", "configuration": "rv64-default"},
        "nodes": [{
            "capability_id": "experimental.causal-attribution",
            "domain": "experimental_method",
            "applicability": {"status": "candidate", "workspace_claim": "Candidate until local evidence closes the exam.", "evidence_refs": []},
            "scores": {"knowledge": None, "reasoning": None, "prediction_accuracy": None, "confidence_calibration": None},
            "sample_counts": {"experiments": 0, "successes": 0, "failures": 0, "unseen_exams": 0},
            "calibration": {"prediction_count": 0, "interval_coverage": None, "mean_absolute_error": None},
            "prerequisites": [], "status": "unknown", "evidence_refs": [], "last_updated": stamp,
        }],
        "updated_at": stamp,
    }
    experience = {
        "schema_version": 1, "experience_id": "owner-timing-demo", "state": "diagnosed",
        "design_context": {"design_id": "sha256:demo", "source_manifest": "manifest.json", "workload": "directed-owner-timing", "configuration": "rv64-default", "toolchain": "local-simulator"},
        "objective": ["correctness", "timing"],
        "observation": {"claim": "A local evidence path reports a timing observation.", "evidence_refs": ["evidence/owner-timing.log"]},
        "hypothesis": {"claim": "The owner lifecycle cone is causal.", "mechanism_chain": ["owner state", "terminal fanout", "critical cone", "timing metric"], "competing_explanations": ["measurement configuration drift"], "falsifier": "The cone is unchanged while timing moves under the same inputs."},
        "prediction": {"metric": "slack_delta", "expected": 0.1, "lower": 0.0, "upper": 0.2, "unit": "ns", "confidence": 0.7},
        "proposal": {"transform_id": "owner-terminal-split", "architectural_diff": "Split terminal observation from owner state update.", "preserved_invariants": ["unique owner"], "rollback": "Restore the original cone."},
        "experiment": {"command": "run-directed-owner-timing", "input_refs": ["manifest.json"], "determinism": "deterministic", "repeat_reason": None, "evidence_refs": ["evidence/owner-timing.log"]},
        "result": {"status": "pass", "actual": 0.08, "unit": "ns", "evidence_refs": ["evidence/owner-timing.log"]},
        "comparison": {"prediction_error": -0.02, "interval_hit": True, "causal_conclusion": "The result is compatible with the bounded hypothesis."},
        "meta_critic": {"complete": True, "error_classes": ["E4"], "knowledge_gap_ids": ["gap.owner-magnitude"], "diagnosis": "Magnitude was slightly overestimated."},
        "corrected_strategy": {"action": "Narrow the prediction interval after another distinct context.", "scope": "owner terminal cone under rv64-default", "exceptions": ["different physical corner"]},
        "training": {"eligible": False, "ground_truth_level": "eda_report", "unseen_exam_passed": False, "reasons": ["single context is insufficient"]},
        "timestamps": {"predicted_at": "2026-08-09T10:00:00+08:00", "measured_at": "2026-08-09T11:00:00+08:00", "updated_at": stamp},
    }
    gap = {
        "schema_version": 1, "gap_id": "gap.owner-magnitude", "source_experience_ids": ["owner-timing-demo"],
        "trigger": "calibration", "error_class": "E4", "failed_prediction": "The expected slack delta was high by 0.02 ns.",
        "missing_information": "Sensitivity across a distinct physical corner is unknown.",
        "falsifiable_question": "Does the same transform keep the interval hit at a distinct corner?",
        "capability_ids": ["experimental.causal-attribution"],
        "acquisition_plan": {"level": "context_acquisition", "action": "Use one distinct corner only if the candidate reaches physical promotion.", "source_refs": ["evidence/owner-timing.log"]},
        "validation_plan": {"cheapest_discriminating_experiment": "Run the promoted candidate at one distinct corner.", "expected_uncertainty_reduction": 0.6, "experiment_cost": 0.3, "voi": 2.0, "success_criterion": "Registered interval contains the distinct-corner result.", "counterexample": "The sign of slack delta reverses."},
        "priority": {"impact": 0.8, "frequency": 0.5, "uncertainty": 0.6, "learning_cost": 0.3, "score": 0.8},
        "status": "open", "evidence_refs": ["evidence/owner-timing.log"],
    }
    return {"capability": capability, "experience": experience, "gap": gap}


def run_self_test(policy: dict[str, Any]) -> None:
    validate_contracts(policy)
    examples = _valid_examples()
    for kind, record in examples.items():
        validate_record(kind, record, policy)
    invalid = copy.deepcopy(examples["experience"])
    invalid["training"]["eligible"] = True
    invalid["training"]["ground_truth_level"] = "llm_opinion"
    invalid["training"]["unseen_exam_passed"] = True
    try:
        validate_record("experience", invalid, policy)
    except LearningContractError:
        pass
    else:
        raise LearningContractError("self-test accepted LLM-grounded training data")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate-contracts")
    subparsers.add_parser("self-test")
    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("--kind", choices=("capability", "experience", "gap"), required=True)
    validate_parser.add_argument("--input", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        policy = load_json(args.policy.resolve())
        if args.command == "validate-contracts":
            validate_contracts(policy)
            print("[CPU-ARCH-LEARNING] PASS contracts")
        elif args.command == "self-test":
            run_self_test(policy)
            print("[CPU-ARCH-LEARNING] PASS grounded-experience-loop")
        else:
            record = load_json(args.input.resolve())
            validate_record(args.kind, record, policy)
            print(f"[CPU-ARCH-LEARNING] PASS kind={args.kind}")
    except LearningContractError as exc:
        print(f"[CPU-ARCH-LEARNING] FAIL {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
