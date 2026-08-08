#!/usr/bin/env python3
"""为 current RV64 design-id 选择下一次 CPI/PPA 工程切片。"""

from __future__ import annotations

import argparse
from decimal import Decimal
import hashlib
import json
import math
import os
import pathlib
import subprocess
import sys
import tempfile
from typing import Any

import jsonschema


TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import current_reference_ppa as current_reference  # noqa: E402
import current_timing_path_analysis as current_timing  # noqa: E402
import owner_b_latency_sensitivity as b_latency_sensitivity  # noqa: E402
import owner_b_response_candidate_analysis as b_response_candidate  # noqa: E402
import owner_timing_causal_analysis as causal_analysis  # noqa: E402
import owner_timing_workload_ab as owner_timing  # noqa: E402
import performance_bottleneck_census as census_tool  # noqa: E402


DECISION_SCHEMA = "npc-rv64-optimization-slice-decision-v1"
POLICY_SCHEMA = "npc-rv64-optimization-slice-selector-policy-v1"
CATALOG_SCHEMA = "npc-rv64-optimization-slice-catalog-v1"
RESEARCH_SCHEMA = "npc-rv64-optimization-research-state-v1"
DEFAULT_POLICY = (
    "npc/rv64/design/arch/optimization-slice-selector-policy-v1.json")
DEFAULT_CATALOG = "npc/rv64/eval/ppa/optimization-slices-current.json"
DEFAULT_DECISION = (
    "npc/rv64/eval/ppa/evidence/optimization-slice-current.json")
DEFAULT_DECISION_SCHEMA = (
    "npc/rv64/eval/ppa/schemas/optimization-slice-decision-v1.schema.json")
PPA_CHECKER = "npc/rv64/eval/ppa/tools/check.py"
OWNER_TIMING_VERIFIER = (
    "npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py")
CAUSAL_ANALYSIS_VERIFIER = (
    "npc/rv64/eval/ppa/tools/owner_timing_causal_analysis.py")
B_LATENCY_SENSITIVITY_VERIFIER = (
    "npc/rv64/eval/ppa/tools/owner_b_latency_sensitivity.py")
B_RESPONSE_CANDIDATE_VERIFIER = (
    "npc/rv64/eval/ppa/tools/owner_b_response_candidate_analysis.py")
CURRENT_REFERENCE_PPA_VERIFIER = (
    "npc/rv64/eval/ppa/tools/current_reference_ppa.py")
CURRENT_TIMING_PATH_ANALYSIS_VERIFIER = (
    "npc/rv64/eval/ppa/tools/current_timing_path_analysis.py")

INFO_MAXIMIZE = (
    "information_gain", "evidence_confidence", "reversibility")
INFO_MINIMIZE = (
    "execution_cost", "functional_risk", "scope_width")
INFO_METRICS = frozenset((*INFO_MAXIMIZE, *INFO_MINIMIZE))
INTERVAL_FIELDS = ("low", "nominal", "high")


class SelectorError(RuntimeError):
    """输入结构、路径或内容绑定不可信。"""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SelectorError(message)


def _strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise SelectorError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path: pathlib.Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_strict_object)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SelectorError(f"cannot read {label}: {exc}") from exc
    require(isinstance(value, dict), f"{label} must be a JSON object")
    return value


def decision_schema(
    root: pathlib.Path,
) -> tuple[pathlib.Path, dict[str, Any], jsonschema.Draft202012Validator]:
    path = workspace_path(root, DEFAULT_DECISION_SCHEMA, "decision schema")
    value = read_json(path, "decision schema")
    try:
        jsonschema.Draft202012Validator.check_schema(value)
        validator = jsonschema.Draft202012Validator(value)
    except jsonschema.SchemaError as exc:
        raise SelectorError(f"decision schema is invalid: {exc.message}") from exc
    return path, value, validator


def validate_decision(
    validator: jsonschema.Draft202012Validator, value: dict[str, Any],
) -> None:
    errors = sorted(
        validator.iter_errors(value),
        key=lambda item: tuple(str(part) for part in item.absolute_path),
    )
    if errors:
        path = ".".join(str(part) for part in errors[0].absolute_path)
        prefix = f" at {path}" if path else ""
        raise SelectorError(
            f"selector decision violates schema{prefix}: {errors[0].message}")


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            value.update(block)
    return value.hexdigest()


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value, sort_keys=True, separators=(",", ":"),
        ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _lexical_parts(value: str, label: str) -> tuple[str, ...]:
    require(isinstance(value, str) and value, f"{label} path is invalid")
    require("\\" not in value, f"{label} path must use workspace separators")
    pure = pathlib.PurePosixPath(value)
    require(not pure.is_absolute(), f"{label} path must be workspace relative")
    require(all(part not in ("", ".", "..") for part in pure.parts),
            f"{label} path contains an unsafe component")
    return pure.parts


def workspace_path(
    root: pathlib.Path, value: str, label: str, *, must_exist: bool = True,
) -> pathlib.Path:
    parts = _lexical_parts(value, label)
    current = root
    for part in parts:
        current = current / part
        if current.exists() or current.is_symlink():
            require(not current.is_symlink(), f"{label} path uses a symlink")
    resolved = (root.joinpath(*parts)).resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise SelectorError(f"{label} path escapes workspace") from exc
    if must_exist:
        require(resolved.is_file(), f"{label} file is missing: {value}")
    return resolved


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root).as_posix()


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    return {
        "path": relative(root, path),
        "sha256": digest(path),
        "size_bytes": path.stat().st_size,
    }


def verify_artifact_ref(
    root: pathlib.Path, value: Any, label: str,
) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} artifact must be an object")
    path = workspace_path(root, value.get("path"), label)
    require(value.get("sha256") == digest(path), f"{label} sha256 mismatch")
    if "size_bytes" in value:
        require(value.get("size_bytes") == path.stat().st_size,
                f"{label} size mismatch")
    return path


def validate_policy(
    root: pathlib.Path, path: pathlib.Path,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, dict[str, Any]]]:
    policy = read_json(path, "selector policy")
    require(policy.get("schema") == POLICY_SCHEMA,
            "selector policy schema mismatch")
    require(isinstance(policy.get("policy_id"), str)
            and policy["policy_id"], "selector policy_id is invalid")

    normative = policy.get("normative_inputs")
    require(isinstance(normative, dict) and set(normative) == {
        "architecture_ppa_contract", "maturity_stages", "ppa_policy"},
        "selector normative input set mismatch")
    normative_artifacts: dict[str, dict[str, Any]] = {}
    for name, reference in sorted(normative.items()):
        bound = verify_artifact_ref(root, reference, f"normative {name}")
        normative_artifacts[name] = artifact(root, bound)

    ppa_path = workspace_path(
        root, normative["ppa_policy"]["path"], "normative ppa policy")
    ppa_policy = read_json(ppa_path, "normative ppa policy")
    require(ppa_policy.get("schema") == "npc-rv64-ppa-policy-v1",
            "normative PPA policy schema mismatch")

    authorities = policy.get("authorities")
    require(isinstance(authorities, dict) and authorities,
            "selector authorities are missing")
    required_authorities = {
        "architecture_debt", "historical_defect", "architecture_stable",
        "performance_baseline", "layered_system", "cpi_census",
        "baseline_index",
    }
    require(set(authorities) == required_authorities,
            "selector authority set mismatch")
    for name, specification in authorities.items():
        require(isinstance(specification, dict),
                f"authority {name} must be an object")
        workspace_path(root, specification.get("path"), f"authority {name}")
        require(isinstance(specification.get("schema"), str),
                f"authority {name} schema is missing")

    maturity = policy.get("maturity_order")
    phases = policy.get("decision_class_order")
    require(isinstance(maturity, list) and len(maturity) == len(set(maturity)),
            "maturity order is invalid")
    require(isinstance(phases, list) and len(phases) == len(set(phases)),
            "decision class order is invalid")
    modes = policy.get("selection_modes")
    require(isinstance(modes, dict) and set(modes) == {
        "information", "multiobjective"}, "selection mode set mismatch")
    require(tuple(modes["information"].get("maximize", [])) == INFO_MAXIMIZE,
            "information maximize order mismatch")
    require(tuple(modes["information"].get("minimize", [])) == INFO_MINIMIZE,
            "information minimize order mismatch")
    require(modes["multiobjective"].get("scalarization_scope")
            == "same_measured_pareto_front_only",
            "multiobjective scalarization boundary mismatch")
    require(policy.get("uncertainty", {}).get(
        "predictions_authorize_promotion") is False,
        "predictions must not authorize promotion")
    require(policy.get("claim_boundary", {}).get(
        "front_py_remains_promotion_authority") is True,
        "front.py promotion authority must be preserved")
    research = policy.get("research_state", {})
    require(research.get("allowed_fact_overrides") == [],
            "research state must not override authority facts")
    require(research.get("allowed_evidence_receipts") == [
        "owner_timing", "causal_analysis", "b_latency_sensitivity",
        "b_response_candidate_analysis", "current_reference_ppa",
        "current_timing_path_analysis"],
            "research evidence receipt policy mismatch")
    require(research.get("candidate_observations_authorize_promotion") is False,
            "research observations must not authorize promotion")
    return policy, ppa_policy, normative_artifacts


def _require_string_list(value: Any, label: str) -> list[str]:
    require(isinstance(value, list) and value,
            f"{label} must be a non-empty list")
    require(all(isinstance(item, str) and item for item in value),
            f"{label} contains an invalid value")
    return value


def validate_catalog(
    root: pathlib.Path, path: pathlib.Path, policy: dict[str, Any],
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    catalog = read_json(path, "optimization slice catalog")
    require(catalog.get("schema") == CATALOG_SCHEMA,
            "optimization slice catalog schema mismatch")
    require(isinstance(catalog.get("catalog_id"), str)
            and catalog["catalog_id"], "catalog_id is invalid")
    slices = catalog.get("slices")
    require(isinstance(slices, list) and slices, "catalog slices are missing")
    phase_set = set(policy["decision_class_order"])
    seen: set[str] = set()
    for item in slices:
        require(isinstance(item, dict), "catalog slice must be an object")
        slice_id = item.get("id")
        require(isinstance(slice_id, str) and slice_id,
                "catalog slice id is invalid")
        require(slice_id not in seen, f"duplicate slice id: {slice_id}")
        seen.add(slice_id)
        require(item.get("class") in phase_set,
                f"slice {slice_id} has an unknown decision class")
        require(item.get("selection_mode") in ("information", "multiobjective"),
                f"slice {slice_id} has an unknown selection mode")
        for field in ("title", "domain", "action"):
            require(isinstance(item.get(field), str) and item[field],
                    f"slice {slice_id} {field} is missing")
        for raw in _require_string_list(item.get("scope"),
                                        f"slice {slice_id} scope"):
            workspace_path(root, raw, f"slice {slice_id} scope")
        prerequisites = item.get("prerequisites")
        require(isinstance(prerequisites, list) and prerequisites,
                f"slice {slice_id} prerequisites are missing")
        for predicate in prerequisites:
            require(isinstance(predicate, dict)
                    and isinstance(predicate.get("fact"), str),
                    f"slice {slice_id} prerequisite is invalid")
            require(predicate.get("op") in (
                "eq", "ne", "in", "not_in", "at_least"),
                f"slice {slice_id} prerequisite operator is invalid")
            require("value" in predicate,
                    f"slice {slice_id} prerequisite value is missing")
        metrics = item.get("selector_metrics")
        require(isinstance(metrics, dict) and set(metrics) == INFO_METRICS,
                f"slice {slice_id} selector metric set mismatch")
        for name, value in metrics.items():
            require(isinstance(value, int) and not isinstance(value, bool)
                    and 1 <= value <= 5,
                    f"slice {slice_id} metric {name} must be 1..5")
        for field in (
            "required_evidence", "success_conditions", "rollback_conditions",
            "forbidden_claims",
        ):
            _require_string_list(item.get(field), f"slice {slice_id} {field}")
    return catalog, sorted(slices, key=lambda item: item["id"])


def validate_research_state(
    root: pathlib.Path,
    path: pathlib.Path | None,
    policy: dict[str, Any],
    live_design_id: str,
) -> tuple[dict[str, Any] | None, dict[str, Any], dict[str, Any]]:
    if path is None:
        return None, {}, {}
    value = read_json(path, "optimization research state")
    require(value.get("schema") == RESEARCH_SCHEMA,
            "optimization research state schema mismatch")
    require(value.get("design_id") == live_design_id,
            "optimization research state design-id mismatch")
    sources = value.get("source_artifacts")
    require(isinstance(sources, list) and sources,
            "research state requires source artifacts")
    for index, reference in enumerate(sources):
        verify_artifact_ref(root, reference, f"research source {index}")
    supplied_facts = value.get("facts", {})
    require(isinstance(supplied_facts, dict),
            "research facts must be an object")
    require(not supplied_facts,
            "research state cannot override authority facts")

    receipts = value.get("evidence_receipts", {})
    require(isinstance(receipts, dict),
            "research evidence_receipts must be an object")
    allowed_receipts = set(
        policy["research_state"]["allowed_evidence_receipts"])
    require(set(receipts).issubset(allowed_receipts),
            "research state has an unsupported evidence receipt")
    facts: dict[str, Any] = {}
    owner_reference = receipts.get("owner_timing")
    if owner_reference is not None:
        require(owner_reference in sources,
                "owner timing receipt must be listed as a research source")
        owner_path = verify_artifact_ref(
            root, owner_reference, "research owner timing receipt")
        owner_receipt = read_json(owner_path, "research owner timing receipt")
        try:
            rebuilt = owner_timing.rebuild_receipt(owner_receipt)
        except (owner_timing.EvidenceError, OSError, KeyError, TypeError) as exc:
            raise SelectorError(
                f"owner timing receipt is not canonical: {exc}") from exc
        require(owner_receipt == rebuilt,
                "owner timing receipt is not canonical")
        require(owner_receipt.get("schema")
                == "npc-rv64-owner-timing-workload-ab-v1",
                "owner timing receipt schema mismatch")
        require(owner_receipt.get("status")
                == "OWNER_TIMING_WORKLOAD_MEASURED",
                "owner timing receipt status mismatch")
        require(owner_receipt.get("design_id") == live_design_id,
                "owner timing receipt design-id mismatch")
        checks = owner_receipt.get("checks", {})
        require(isinstance(checks, dict) and all(checks.get(name) is True for name in (
            "arch_stable_pre_post", "perf_baseline_pre_post",
            "reference_repetitions_bit_exact",
            "diagnostic_repetitions_bit_exact",
            "region_counter_noninterference", "owner_state_conservation",
            "owner_interval_conservation", "benchmark_terminal_markers",
            "runtime_cleanup",
        )), "owner timing receipt checks are incomplete")
        require(checks.get("owner_overflow") == 0
                and checks.get("owner_invalid_events") == 0,
                "owner timing receipt has overflow or invalid events")
        facts["owner_timing_measured"] = True
    causal_reference = receipts.get("causal_analysis")
    if causal_reference is not None:
        require(causal_reference in sources,
                "causal analysis receipt must be listed as a research source")
        causal_path = verify_artifact_ref(
            root, causal_reference, "research causal analysis receipt")
        causal_receipt = read_json(
            causal_path, "research causal analysis receipt")
        try:
            rebuilt = causal_analysis.rebuild_receipt(causal_receipt)
        except (causal_analysis.AnalysisError, OSError, KeyError,
                TypeError, ValueError) as exc:
            raise SelectorError(
                f"causal analysis receipt is not canonical: {exc}") from exc
        require(causal_receipt == rebuilt,
                "causal analysis receipt is not canonical")
        require(causal_receipt.get("schema")
                == "npc-rv64-owner-timing-causal-analysis-v1",
                "causal analysis receipt schema mismatch")
        require(causal_receipt.get("design_id") == live_design_id,
                "causal analysis receipt design-id mismatch")
        require(owner_reference is not None,
                "causal analysis requires the owner timing receipt")
        require(causal_receipt.get("inputs", {}).get("owner_timing_receipt")
                == owner_reference,
                "causal analysis owner receipt binding mismatch")
        authorization = causal_receipt.get("authorization", {})
        require(authorization.get("optimization_candidate_authorized") is False
                and authorization.get("ppa") == "UNQUALIFIED"
                and authorization.get("promotion_eligible") is False,
                "causal analysis exceeds its authorization boundary")
        decision = causal_receipt.get("decision", {})
        status = causal_receipt.get("status")
        require(status in ("RESEARCH_REQUIRED", "CAUSAL_HYPOTHESIS_SELECTED"),
                "causal analysis status mismatch")
        hypothesis = decision.get("causal_hypothesis")
        authorized = authorization.get("causal_selection_authorized") is True
        if status == "RESEARCH_REQUIRED":
            require(not authorized and hypothesis == "UNRESOLVED",
                    "research-required causal receipt cannot select a hypothesis")
        else:
            require(authorized and hypothesis in (
                "H1_B_RESPONSE_LATENCY", "H2_WRITE_CONCURRENCY",
                "H3_HEAD_RESIDENCY_WEIGHTING", "H4_PRE_REQUEST_PIPELINE"),
                "selected causal receipt has no authorized hypothesis")
        facts.update({
            "causal_analysis_completed": True,
            "causal_analysis_status": status,
            "causal_selection_authorized": authorized,
            "causal_hypothesis": hypothesis,
        })
    sensitivity_reference = receipts.get("b_latency_sensitivity")
    if sensitivity_reference is not None:
        require(sensitivity_reference in sources,
                "B-latency sensitivity receipt must be listed as a research source")
        sensitivity_path = verify_artifact_ref(
            root, sensitivity_reference, "research B-latency sensitivity receipt")
        sensitivity_receipt = read_json(
            sensitivity_path, "research B-latency sensitivity receipt")
        try:
            rebuilt = b_latency_sensitivity.rebuild_receipt(sensitivity_receipt)
        except (b_latency_sensitivity.EvidenceError, OSError, KeyError,
                TypeError, ValueError) as exc:
            raise SelectorError(
                f"B-latency sensitivity receipt is not canonical: {exc}") from exc
        require(sensitivity_receipt == rebuilt,
                "B-latency sensitivity receipt is not canonical")
        require(sensitivity_receipt.get("schema")
                == "npc-rv64-owner-b-latency-sensitivity-v1",
                "B-latency sensitivity receipt schema mismatch")
        require(sensitivity_receipt.get("design_id") == live_design_id,
                "B-latency sensitivity receipt design-id mismatch")
        require(owner_reference is not None and causal_reference is not None,
                "B-latency sensitivity requires owner and causal receipts")
        sensitivity_inputs = sensitivity_receipt.get("inputs", {})
        require(sensitivity_inputs.get("owner_timing_receipt") == owner_reference,
                "B-latency sensitivity owner receipt binding mismatch")
        require(sensitivity_inputs.get("causal_analysis_receipt") == causal_reference,
                "B-latency sensitivity causal receipt binding mismatch")
        checks = sensitivity_receipt.get("checks", {})
        require(isinstance(checks, dict) and all(checks.get(name) is True for name in (
            "delay0_a2_bit_exact", "three_repetitions_per_point",
            "architectural_terminal_unchanged", "retired_count_unchanged",
            "b_transaction_frequency_unchanged",
            "store_request_frequency_unchanged",
            "two_added_cycles_per_b_terminal", "owner_conservation",
            "runtime_cleanup",
        )), "B-latency sensitivity checks are incomplete")
        require(checks.get("rtl_assertion_markers") == 0,
                "B-latency sensitivity has RTL assertion markers")
        authorization = sensitivity_receipt.get("authorization", {})
        require(authorization.get("optimization_candidate_authorized") is False
                and authorization.get("production_rtl_change_authorized") is False
                and authorization.get("ppa") == "UNQUALIFIED"
                and authorization.get("promotion_eligible") is False,
                "B-latency sensitivity exceeds its authorization boundary")
        decision = sensitivity_receipt.get("causal_decision", {})
        status = sensitivity_receipt.get("status")
        require(status in (
            "H1_B_RESPONSE_LATENCY_SENSITIVE", "RESEARCH_REQUIRED"),
            "B-latency sensitivity status mismatch")
        require(decision.get("status") == status,
                "B-latency decision/status mismatch")
        hypothesis = decision.get("causal_hypothesis")
        authorized = authorization.get("causal_selection_authorized") is True
        if status == "H1_B_RESPONSE_LATENCY_SENSITIVE":
            require(authorized and hypothesis == "H1_B_RESPONSE_LATENCY",
                    "B-latency sensitivity did not authorize H1 exactly")
        else:
            require(not authorized and hypothesis == "UNRESOLVED",
                    "unresolved B-latency receipt cannot authorize a hypothesis")
        facts.update({
            "b_latency_sensitivity_completed": True,
            "b_latency_sensitivity_status": status,
            "causal_selection_authorized": authorized,
            "causal_hypothesis": hypothesis,
        })
    candidate_reference = receipts.get("b_response_candidate_analysis")
    if candidate_reference is not None:
        require(candidate_reference in sources,
                "B-response candidate receipt must be listed as a research source")
        candidate_path = verify_artifact_ref(
            root, candidate_reference, "research B-response candidate receipt")
        candidate_receipt = read_json(
            candidate_path, "research B-response candidate receipt")
        try:
            rebuilt = b_response_candidate.rebuild_receipt(candidate_receipt)
        except (b_response_candidate.EvidenceError, OSError, KeyError,
                TypeError, ValueError) as exc:
            raise SelectorError(
                f"B-response candidate receipt is not canonical: {exc}") from exc
        require(candidate_receipt == rebuilt,
                "B-response candidate receipt is not canonical")
        require(candidate_receipt.get("schema") == b_response_candidate.SCHEMA,
                "B-response candidate receipt schema mismatch")
        require(candidate_receipt.get("design_id") == live_design_id,
                "B-response candidate receipt design-id mismatch")
        require(owner_reference is not None and causal_reference is not None
                and sensitivity_reference is not None,
                "B-response candidate analysis requires owner, causal and sensitivity receipts")
        require(candidate_receipt.get("inputs", {}).get("b_latency_sensitivity")
                == sensitivity_reference,
                "B-response candidate sensitivity binding mismatch")
        authorization = candidate_receipt.get("authorization", {})
        require(
            authorization.get("candidate_analysis_completed") is True
            and authorization.get("new_production_rtl_change_authorized") is False
            and authorization.get("second_core_only_candidate_defined") is True
            and authorization.get("ppa") == "UNQUALIFIED"
            and authorization.get("promotion_eligible") is False,
            "B-response candidate receipt exceeds its authorization boundary",
        )
        require(candidate_receipt.get("status") == b_response_candidate.STATUS,
                "B-response candidate analysis status mismatch")
        require(candidate_receipt.get("next_action") ==
                "qualify.current-reference-ppa",
                "B-response candidate next action mismatch")
        remaining = candidate_receipt.get("remaining_latency", {})
        candidate = remaining.get("candidate", {})
        require(
            remaining.get("disposition") == "CANDIDATE_DEFINED_UNQUALIFIED"
            and remaining.get("low_risk_qualification") == "GAP"
            and candidate.get("id") == b_response_candidate.NEXT_CANDIDATE
            and candidate.get("state") == "CANDIDATE_ONLY"
            and candidate.get("current_cycles") == 4
            and candidate.get("ideal_no_backpressure_cycles") == 3,
            "B-response candidate receipt hides the candidate-only qualification GAP",
        )
        facts.update({
            "b_response_candidate_analysis_completed": True,
            "b_response_candidate_analysis_status": candidate_receipt["status"],
        })
    current_reference_record = receipts.get("current_reference_ppa")
    if current_reference_record is not None:
        require(current_reference_record in sources,
                "current-reference PPA receipt must be listed as a research source")
        reference_path = verify_artifact_ref(
            root, current_reference_record, "research current-reference PPA receipt")
        reference_receipt = read_json(
            reference_path, "research current-reference PPA receipt")
        try:
            rebuilt = current_reference.rebuild_receipt(reference_receipt)
        except (current_reference.EvidenceError, OSError, KeyError,
                TypeError, ValueError) as exc:
            raise SelectorError(
                f"current-reference PPA receipt is not canonical: {exc}") from exc
        require(reference_receipt == rebuilt,
                "current-reference PPA receipt is not canonical")
        require(reference_receipt.get("schema") == current_reference.SCHEMA,
                "current-reference PPA receipt schema mismatch")
        require(reference_receipt.get("design_id") == live_design_id,
                "current-reference PPA receipt design-id mismatch")
        require(candidate_reference is not None,
                "current-reference PPA receipt requires the B-response candidate receipt")
        authorization = reference_receipt.get("authorization", {})
        require(
            authorization.get("measurement_completed") is True
            and authorization.get("engineering_reference_available") is True
            and authorization.get("accepted_ppa_reference_available") is False
            and authorization.get("new_production_rtl_change_authorized") is False
            and authorization.get("promotion_eligible") is False
            and authorization.get("canonical_baseline_eligible") is False,
            "current-reference PPA receipt exceeds its authorization boundary",
        )
        timing_gate = reference_receipt.get("timing", {}).get("hard_gate")
        require(timing_gate in ("PASS", "FAIL"),
                "current-reference PPA timing hard-gate state is invalid")
        expected_status = (
            "REPEATABLE_CURRENT_REFERENCE_TIMING_QUALIFIED"
            if timing_gate == "PASS"
            else "REPEATABLE_CURRENT_REFERENCE_TIMING_HARD_GATE_FAIL"
        )
        require(reference_receipt.get("status") == expected_status,
                "current-reference PPA status/timing mismatch")
        facts.update({
            "ppa_reference_measurement_completed": True,
            "ppa_reference_measurement_status": reference_receipt["status"],
            "ppa_engineering_reference_available": True,
            "ppa_timing_hard_gate": timing_gate,
        })
    timing_analysis_record = receipts.get("current_timing_path_analysis")
    if timing_analysis_record is not None:
        require(timing_analysis_record in sources,
                "current timing-path analysis receipt must be listed as a research source")
        timing_analysis_path = verify_artifact_ref(
            root, timing_analysis_record,
            "research current timing-path analysis receipt")
        timing_analysis_receipt = read_json(
            timing_analysis_path, "research current timing-path analysis receipt")
        try:
            rebuilt = current_timing.rebuild_receipt(timing_analysis_receipt)
        except (current_timing.EvidenceError, OSError, KeyError,
                TypeError, ValueError) as exc:
            raise SelectorError(
                f"current timing-path analysis receipt is not canonical: {exc}") from exc
        require(timing_analysis_receipt == rebuilt,
                "current timing-path analysis receipt is not canonical")
        require(timing_analysis_receipt.get("schema") == current_timing.SCHEMA,
                "current timing-path analysis receipt schema mismatch")
        require(timing_analysis_receipt.get("design_id") == live_design_id,
                "current timing-path analysis receipt design-id mismatch")
        require(current_reference_record is not None,
                "current timing-path analysis requires current-reference PPA")
        require(
            timing_analysis_receipt.get("inputs", {}).get("current_reference")
            == current_reference_record,
            "current timing-path analysis current-reference binding mismatch",
        )
        candidate = timing_analysis_receipt.get("candidate_decision", {})
        definition = timing_analysis_receipt.get("candidate_definition", {})
        require(
            timing_analysis_receipt.get("status") == current_timing.STATUS
            and candidate.get("status") == "CANDIDATE_ONLY"
            and candidate.get("id") == current_timing.CANDIDATE_ID
            and candidate.get("production_rtl_change_authorized") is False
            and candidate.get("promotion_eligible") is False
            and candidate.get("ppa") == "UNQUALIFIED"
            and definition.get("id") == current_timing.CANDIDATE_ID
            and definition.get("state") == "CANDIDATE_ONLY"
            and timing_analysis_receipt.get("next_action")
            == current_timing.NEXT_ACTION,
            "current timing-path analysis exceeds its candidate-only boundary",
        )
        facts.update({
            "current_timing_path_analysis_completed": True,
            "current_timing_path_analysis_status":
                timing_analysis_receipt["status"],
            "current_timing_candidate_id": current_timing.CANDIDATE_ID,
        })
    observations = value.get("candidate_observations", {})
    require(isinstance(observations, dict),
            "candidate observations must be an object")
    return value, facts, observations


def _status_matches(value: dict[str, Any], specification: dict[str, Any]) -> bool:
    field = specification.get("status_field")
    return isinstance(field, str) and value.get(field) == specification.get(
        "pass_value")


def _baseline_floor(
    baseline: dict[str, Any], ppa_policy: dict[str, Any],
) -> tuple[dict[str, str], bool, float]:
    seed = ppa_policy.get("architecture_feasible_seed", {})
    anchor = seed.get("source_anchor", {}).get("performance_counters", {})
    floor = seed.get("performance", {}).get("minimum_per_benchmark_ratio")
    require(isinstance(floor, (int, float)) and not isinstance(floor, bool),
            "normative performance floor is invalid")
    ratios: dict[str, str] = {}
    benchmarks = baseline.get("benchmarks", {})
    for name in ("coremark", "dhrystone_10000"):
        current = benchmarks.get(name)
        reference = anchor.get(name)
        require(isinstance(current, dict) and isinstance(reference, dict),
                f"performance floor workload is missing: {name}")
        cycles = current.get("cycles")
        retired = current.get("retired_instructions")
        anchor_cycles = reference.get("cycles")
        anchor_retired = reference.get("retired_instructions")
        require(all(isinstance(item, int) and not isinstance(item, bool)
                    and item > 0 for item in (
                        cycles, retired, anchor_cycles, anchor_retired)),
                f"performance floor counters are invalid: {name}")
        require(retired == anchor_retired,
                f"fixed-image retired count mismatch: {name}")
        ratio = ((Decimal(retired) / Decimal(cycles)) /
                 (Decimal(anchor_retired) / Decimal(anchor_cycles)))
        ratios[name] = format(ratio, ".12f")
    return ratios, all(Decimal(value) >= Decimal(str(floor))
                       for value in ratios.values()), float(floor)


def collect_state(
    root: pathlib.Path,
    policy: dict[str, Any],
    ppa_policy: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any], list[dict[str, str]], list[str]]:
    raw_design_id, rtl_entries = architecture.rtl_binding(root)
    live_design_id = f"sha256:{raw_design_id}"
    values: dict[str, dict[str, Any]] = {}
    paths: dict[str, pathlib.Path] = {}
    input_artifacts: dict[str, Any] = {}
    status: dict[str, bool] = {}
    conflicts: list[str] = []
    stale_refs: list[dict[str, str]] = []

    for name, specification in sorted(policy["authorities"].items()):
        path = workspace_path(root, specification["path"], f"authority {name}")
        value = read_json(path, f"authority {name}")
        paths[name] = path
        values[name] = value
        input_artifacts[name] = artifact(root, path)
        schema_ok = value.get("schema") == specification["schema"]
        status[name] = _status_matches(value, specification)
        if not schema_ok and specification.get("required_for_consistent_state"):
            conflicts.append(f"{name}:SCHEMA_MISMATCH")
        design_field = specification.get("design_id_field")
        if isinstance(design_field, str):
            design_ok = value.get(design_field) == live_design_id
            if not design_ok:
                if specification.get("required_for_consistent_state"):
                    conflicts.append(f"{name}:DESIGN_ID_MISMATCH")
                else:
                    stale_refs.append({
                        "path": specification["path"],
                        "reason": "DESIGN_ID_MISMATCH",
                    })

    hard_blockers_closed = all(status.get(name, False) for name in (
        "architecture_debt", "historical_defect", "architecture_stable",
        "layered_system",
    ))
    performance_claim_current = bool(
        status.get("performance_baseline")
        and values["performance_baseline"].get("design_id") == live_design_id)
    performance_canonical = False
    if performance_claim_current:
        try:
            census_tool.validate_current_baseline(
                root, paths["performance_baseline"])
            performance_canonical = True
        except (census_tool.baseline.BaselineError, KeyError, OSError, ValueError):
            conflicts.append("performance_baseline:NONCANONICAL")
    performance_current = performance_claim_current and performance_canonical

    baseline_artifact = input_artifacts["performance_baseline"]
    census = values["cpi_census"]
    census_reference = census.get("performance_baseline")
    census_binding_current = bool(
        status.get("cpi_census")
        and census.get("schema") == policy["authorities"]["cpi_census"]["schema"]
        and census.get("design_id") == live_design_id
        and isinstance(census_reference, dict)
        and census_reference.get("path") == baseline_artifact["path"]
        and census_reference.get("sha256") == baseline_artifact["sha256"]
        and census_reference.get("size_bytes") == baseline_artifact["size_bytes"]
    )
    census_canonical = False
    if performance_current and census_binding_current:
        try:
            census_canonical = (
                census == census_tool.build_census(
                    root, paths["performance_baseline"]))
        except (census_tool.baseline.BaselineError, KeyError, OSError, ValueError):
            census_canonical = False
    census_current = census_binding_current and census_canonical
    if not census_current and not any(
            item["path"] == policy["authorities"]["cpi_census"]["path"]
            for item in stale_refs):
        stale_refs.append({
            "path": policy["authorities"]["cpi_census"]["path"],
            "reason": "BASELINE_BINDING_OR_STATUS_STALE",
        })

    maturity = "ARCH_DISCOVERY"
    if status.get("architecture_debt") and status.get("historical_defect"):
        maturity = "ARCH_CLOSED"
    if status.get("architecture_stable"):
        maturity = "ARCH_STABLE"
    if performance_current:
        reported = values["performance_baseline"].get("maturity_stage")
        maturity = reported if reported in policy["maturity_order"] else "PERF_BASELINE"

    ratios: dict[str, str] = {}
    floor_met = False
    floor = float(ppa_policy["promotion"]["minimum_per_benchmark_ratio"])
    if performance_current:
        ratios, floor_met, floor = _baseline_floor(
            values["performance_baseline"], ppa_policy)

    baseline_index = values["baseline_index"]
    require(
        baseline_index.get("schema")
        == policy["authorities"]["baseline_index"]["schema"],
        "baseline index schema mismatch",
    )
    canonical = baseline_index.get("canonical")
    ppa_reference_available = False
    ppa_qualified = False
    ppa_checker = workspace_path(root, PPA_CHECKER, "PPA checker")
    if isinstance(canonical, str) and canonical:
        canonical_path = workspace_path(
            root, f"npc/rv64/eval/ppa/baselines/{canonical}",
            "canonical PPA baseline")
        canonical_value = read_json(canonical_path, "canonical PPA baseline")
        input_artifacts["canonical_ppa_baseline"] = artifact(root, canonical_path)
        require(canonical_value.get("schema") == "npc-rv64-ppa-baseline-v1",
                "canonical PPA baseline schema mismatch")
        same_design = canonical_value.get("design_id") == live_design_id
        try:
            checked = subprocess.run(
                [
                    sys.executable, "-B", str(ppa_checker),
                    str(canonical_path), "--require-accepted",
                ],
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise SelectorError("canonical PPA checker timed out") from exc
        ppa_reference_available = same_design and checked.returncode == 0
        ppa_qualified = ppa_reference_available

    causal_status = "UNAVAILABLE"
    causal_selection_authorized = False
    if census_current:
        causal_status = census.get(
            "cross_workload_observation", {}).get(
                "causal_status", "UNAVAILABLE")
        causal_selection_authorized = bool(
            census.get("optimization_candidate_authorized") is True)

    facts = {
        "state_consistent": not conflicts,
        "hard_blockers_closed": hard_blockers_closed,
        "performance_baseline_current": performance_current,
        "cpi_census_current": census_current,
        "owner_timing_measured": False,
        "causal_analysis_completed": False,
        "causal_analysis_status": "UNAVAILABLE",
        "b_latency_sensitivity_completed": False,
        "b_latency_sensitivity_status": "UNAVAILABLE",
        "b_response_candidate_analysis_completed": False,
        "b_response_candidate_analysis_status": "UNAVAILABLE",
        "ppa_reference_measurement_completed": False,
        "ppa_reference_measurement_status": "UNAVAILABLE",
        "ppa_engineering_reference_available": False,
        "ppa_timing_hard_gate": "UNKNOWN",
        "current_timing_path_analysis_completed": False,
        "current_timing_path_analysis_status": "UNAVAILABLE",
        "current_timing_candidate_id": "UNAVAILABLE",
        "causal_selection_authorized": causal_selection_authorized,
        "causal_hypothesis": "UNRESOLVED",
        "ppa_reference_available": ppa_reference_available,
        "ppa_qualified": ppa_qualified,
        "maturity": maturity,
        "performance_anchor_floor_met": floor_met,
    }
    state = {
        "maturity": maturity,
        "authority_status": {
            name: {
                "status_matches": status[name],
                "schema": values[name].get("schema"),
            }
            for name in sorted(values)
        },
        "hard_blockers_closed": hard_blockers_closed,
        "performance_baseline_current": performance_current,
        "cpi_census_current": census_current,
        "causal_status": causal_status,
        "causal_selection_authorized": causal_selection_authorized,
        "owner_timing_measured": False,
        "causal_analysis_completed": False,
        "causal_analysis_status": "UNAVAILABLE",
        "b_latency_sensitivity_completed": False,
        "b_latency_sensitivity_status": "UNAVAILABLE",
        "current_timing_path_analysis_completed": False,
        "current_timing_path_analysis_status": "UNAVAILABLE",
        "current_timing_candidate_id": "UNAVAILABLE",
        "ppa_reference_available": ppa_reference_available,
        "ppa_qualified": ppa_qualified,
        "performance_anchor_floor": floor,
        "performance_anchor_ratios": ratios,
        "performance_anchor_floor_met": floor_met,
        "state_conflicts": sorted(conflicts),
        "production_rtl_file_count": len(rtl_entries),
    }
    return (
        {"live_design_id": live_design_id, "facts": facts, "state": state},
        input_artifacts,
        sorted(stale_refs, key=lambda item: (item["path"], item["reason"])),
        sorted(conflicts),
    )


def predicate_matches(
    predicate: dict[str, Any], facts: dict[str, Any], maturity: list[str],
) -> tuple[bool, str]:
    name = predicate["fact"]
    if name not in facts:
        return False, f"MISSING_FACT:{name}"
    actual = facts[name]
    expected = predicate["value"]
    operation = predicate["op"]
    if operation == "eq":
        matched = actual == expected
    elif operation == "ne":
        matched = actual != expected
    elif operation == "in":
        matched = isinstance(expected, list) and actual in expected
    elif operation == "not_in":
        matched = isinstance(expected, list) and actual not in expected
    else:
        if actual not in maturity or expected not in maturity:
            return False, f"INVALID_MATURITY:{name}"
        matched = maturity.index(actual) >= maturity.index(expected)
    return matched, "" if matched else (
        f"PREREQUISITE:{name}:{operation}:{json.dumps(expected, ensure_ascii=False)}")


def information_dominates(
    left: dict[str, Any], right: dict[str, Any],
) -> bool:
    a = left["selector_metrics"]
    b = right["selector_metrics"]
    no_worse = all(a[name] >= b[name] for name in INFO_MAXIMIZE)
    no_worse = no_worse and all(a[name] <= b[name] for name in INFO_MINIMIZE)
    strict = any(a[name] > b[name] for name in INFO_MAXIMIZE)
    strict = strict or any(a[name] < b[name] for name in INFO_MINIMIZE)
    return no_worse and strict


def interval(value: Any, label: str) -> dict[str, float]:
    require(isinstance(value, dict) and set(value) == set(INTERVAL_FIELDS),
            f"{label} interval field set mismatch")
    result: dict[str, float] = {}
    for name in INTERVAL_FIELDS:
        number = value[name]
        require(isinstance(number, (int, float)) and not isinstance(number, bool)
                and math.isfinite(float(number)), f"{label}.{name} is invalid")
        result[name] = float(number)
    require(result["low"] <= result["nominal"] <= result["high"],
            f"{label} interval ordering is invalid")
    return result


def validate_observation(
    value: Any,
    candidate: dict[str, Any],
    policy: dict[str, Any],
    ppa_policy: dict[str, Any],
    seed_exists: bool,
) -> tuple[dict[str, Any] | None, list[str]]:
    if not isinstance(value, dict):
        return None, ["OBJECTIVE_OBSERVATION_MISSING"]
    grade = value.get("evidence_grade")
    require(grade in policy["uncertainty"]["evidence_grade_order"],
            f"candidate {candidate['id']} evidence grade is invalid")
    stage = value.get("design_stage")
    require(stage in ("intermediate_checkpoint", "complete_design_point"),
            f"candidate {candidate['id']} design stage is invalid")
    require(value.get("uncertainty_kind") in (
        "empirical_range", "tool_bound", "calibrated_prediction",
        "expert_range"), f"candidate {candidate['id']} uncertainty kind is invalid")
    performance = interval(
        value.get("performance_ratio"),
        f"candidate {candidate['id']} performance_ratio")
    area = interval(
        value.get("area_efficiency_ratio"),
        f"candidate {candidate['id']} area_efficiency_ratio")
    timing = interval(
        value.get("timing_worst_slack_ns"),
        f"candidate {candidate['id']} timing_worst_slack_ns")
    per_workload = value.get("per_workload_performance_ratio")
    require(isinstance(per_workload, dict) and per_workload,
            f"candidate {candidate['id']} per-workload ratios are missing")
    workload_intervals = {
        name: interval(item, f"candidate {candidate['id']} workload {name}")
        for name, item in sorted(per_workload.items())
    }
    power_qualified = value.get("power_qualified")
    require(isinstance(power_qualified, bool),
            f"candidate {candidate['id']} power qualification is invalid")
    power = None
    if power_qualified:
        power = interval(
            value.get("qualified_power_efficiency_ratio"),
            f"candidate {candidate['id']} power efficiency")
    else:
        require(value.get("qualified_power_efficiency_ratio") is None,
                f"candidate {candidate['id']} unqualified power must be null")

    normalized = {
        "evidence_grade": grade,
        "design_stage": stage,
        "uncertainty_kind": value["uncertainty_kind"],
        "functional_and_architecture": value.get(
            "functional_and_architecture") is True,
        "performance_ratio": performance,
        "per_workload_performance_ratio": workload_intervals,
        "area_efficiency_ratio": area,
        "timing_worst_slack_ns": timing,
        "power_qualified": power_qualified,
        "qualified_power_efficiency_ratio": power,
    }
    blockers: list[str] = []
    minimum_slack = float(
        ppa_policy["timing"]["minimum_worst_slack_ns_for_promotion"])
    if timing["high"] < minimum_slack:
        blockers.append("TIMING_HARD_GATE_FAIL")
    elif timing["low"] < minimum_slack:
        blockers.append("TIMING_HARD_GATE_AMBIGUOUS")
    if stage == "complete_design_point":
        if grade != "MEASURED_SAME_DESIGN":
            blockers.append("COMPLETE_POINT_NOT_MEASURED_SAME_DESIGN")
        if not normalized["functional_and_architecture"]:
            blockers.append("FUNCTIONAL_OR_ARCHITECTURE_GATE_OPEN")
        promotion = ppa_policy["promotion"]
        if performance["low"] < float(promotion["minimum_performance_ratio"]):
            blockers.append("PERFORMANCE_FLOOR_FAIL")
        minimum_workload = float(promotion["minimum_per_benchmark_ratio"])
        if any(item["low"] < minimum_workload
               for item in workload_intervals.values()):
            blockers.append("PER_WORKLOAD_FLOOR_FAIL")
        area_floor = (
            float(promotion["minimum_area_efficiency_ratio"])
            if seed_exists else 1.0 / float(promotion["maximum_area_ratio"]))
        if area["low"] < area_floor:
            blockers.append("AREA_HARD_BOUND_FAIL")
        if value.get("claim_target") == "final_champion" and not power_qualified:
            blockers.append("QUALIFIED_POWER_MISSING")
    return normalized, sorted(set(blockers))


def robust_dominates(
    left: dict[str, Any],
    right: dict[str, Any],
    axes: list[str],
    epsilons: dict[str, float],
) -> bool:
    no_worse = True
    strict = False
    for name in axes:
        a = left[name]
        b = right[name]
        epsilon = epsilons[name]
        # 确定支配要求 left 的最坏情况不低于 right 的最好情况。
        # epsilon 只能抑制数值噪声带来的“严格改善”，不能把重叠区间
        # 变成确定 no-worse，否则会错误淘汰仍可能更优的候选。
        if a["low"] < b["high"]:
            no_worse = False
            break
        if a["low"] > b["high"] + epsilon:
            strict = True
    return no_worse and strict


def selected_payload(candidate: dict[str, Any]) -> dict[str, Any]:
    return {
        key: candidate[key] for key in (
            "id", "class", "selection_mode", "title", "domain", "action",
            "scope", "required_evidence", "success_conditions",
            "rollback_conditions", "forbidden_claims",
        )
    }


def decide(
    slices: list[dict[str, Any]],
    facts: dict[str, Any],
    policy: dict[str, Any],
    ppa_policy: dict[str, Any],
    observations: dict[str, Any],
    seed_exists: bool,
    conflicts: list[str],
) -> tuple[str, str, list[str], list[str], dict[str, Any] | None,
           list[dict[str, Any]], dict[str, Any]]:
    dispositions: list[dict[str, Any]] = []
    if conflicts:
        for candidate in slices:
            dispositions.append({
                "id": candidate["id"],
                "disposition": "INELIGIBLE_STATE_CONFLICT",
                "reasons": conflicts,
            })
        return (
            "STATE_CONFLICT", "STATE_RECONCILIATION",
            ["AUTHORITY_STATE_CONFLICT"], [], None, dispositions,
            {"active_mode": None, "front_status": "NOT_EVALUATED"},
        )

    eligible: list[tuple[dict[str, Any], dict[str, Any] | None]] = []
    timing_ambiguous: list[
        tuple[dict[str, Any], dict[str, Any] | None]
    ] = []
    phase_rank = {
        name: index for index, name in enumerate(policy["decision_class_order"])}
    for candidate in slices:
        reasons = []
        for predicate in candidate["prerequisites"]:
            matched, reason = predicate_matches(
                predicate, facts, policy["maturity_order"])
            if not matched:
                reasons.append(reason)
        normalized = None
        if not reasons and candidate["selection_mode"] == "multiobjective":
            normalized, blockers = validate_observation(
                observations.get(candidate["id"]), candidate, policy,
                ppa_policy, seed_exists)
            if blockers == ["TIMING_HARD_GATE_AMBIGUOUS"]:
                timing_ambiguous.append((candidate, normalized))
                dispositions.append({
                    "id": candidate["id"],
                    "disposition": "REQUIRES_GATE_REFINEMENT",
                    "reasons": blockers,
                })
                continue
            reasons.extend(blockers)
        if reasons:
            disposition = (
                "REJECTED_HARD_GATE" if any(
                    "FAIL" in reason or "AMBIGUOUS" in reason
                    for reason in reasons)
                else "DEFERRED_PREREQUISITE")
            dispositions.append({
                "id": candidate["id"],
                "disposition": disposition,
                "reasons": sorted(set(reasons)),
            })
        else:
            eligible.append((candidate, normalized))

    ranked = [*eligible, *timing_ambiguous]
    if not ranked:
        return (
            "NO_ELIGIBLE", "HOLD", ["NO_ELIGIBLE_SLICE"], [], None,
            sorted(dispositions, key=lambda item: item["id"]),
            {"active_mode": None, "front_status": "EMPTY"},
        )

    best_phase = min(phase_rank[item[0]["class"]] for item in ranked)
    active_ambiguous = [
        item for item in timing_ambiguous
        if phase_rank[item[0]["class"]] == best_phase
    ]
    if active_ambiguous:
        active_eligible = [
            item for item in eligible
            if phase_rank[item[0]["class"]] == best_phase
        ]
        active = [*active_eligible, *active_ambiguous]
        modes = {item[0]["selection_mode"] for item in active}
        require(len(modes) == 1,
                "active decision class mixes selection modes")
        for candidate, _ in active_eligible:
            dispositions.append({
                "id": candidate["id"],
                "disposition": "POSSIBLE_FRONT",
                "reasons": ["TIMING_PEER_REQUIRES_REFINEMENT"],
            })
        for candidate, _ in eligible:
            if phase_rank[candidate["class"]] != best_phase:
                dispositions.append({
                    "id": candidate["id"],
                    "disposition": "DEFERRED_LOWER_DECISION_CLASS",
                    "reasons": [
                        f"ACTIVE_CLASS:{policy['decision_class_order'][best_phase]}"
                    ],
                })
        front_ids = sorted(item[0]["id"] for item in active)
        return (
            "RESEARCH_REQUIRED", "RESEARCH_REQUIRED",
            ["TIMING_HARD_GATE_AMBIGUOUS"], front_ids, None,
            sorted(dispositions, key=lambda item: item["id"]),
            {
                "active_mode": next(iter(modes)),
                "active_class": policy["decision_class_order"][best_phase],
                "front_status": "TIMING_GATE_AMBIGUOUS",
                "scalarization_used": False,
                "timing_role": "HARD_GATE_REQUIRES_REFINEMENT",
                "qualified_axes": [],
            },
        )

    active = [item for item in eligible
              if phase_rank[item[0]["class"]] == best_phase]
    lower = [item for item in eligible
             if phase_rank[item[0]["class"]] != best_phase]
    for candidate, _ in lower:
        dispositions.append({
            "id": candidate["id"],
            "disposition": "DEFERRED_LOWER_DECISION_CLASS",
            "reasons": [f"ACTIVE_CLASS:{policy['decision_class_order'][best_phase]}"],
        })

    modes = {item[0]["selection_mode"] for item in active}
    require(len(modes) == 1, "active decision class mixes selection modes")
    mode = next(iter(modes))
    tradeoff: dict[str, Any] = {
        "active_mode": mode,
        "active_class": policy["decision_class_order"][best_phase],
        "front_status": "EVALUATED",
        "scalarization_used": False,
        "timing_role": "HARD_GATE_NOT_OBJECTIVE",
    }

    if mode == "information":
        front: list[tuple[dict[str, Any], dict[str, Any] | None]] = []
        for candidate in active:
            if not any(information_dominates(other[0], candidate[0])
                       for other in active if other[0]["id"] != candidate[0]["id"]):
                front.append(candidate)
        front_ids = sorted(item[0]["id"] for item in front)
        for candidate, _ in active:
            dispositions.append({
                "id": candidate["id"],
                "disposition": (
                    "POSSIBLE_FRONT" if candidate["id"] in front_ids
                    else "DOMINATED_SELECTOR_METRICS"),
                "reasons": [],
            })
        tradeoff["qualified_axes"] = [
            *INFO_MAXIMIZE, *INFO_MINIMIZE]
    else:
        power_qualification = {
            bool(observation["power_qualified"])
            for _, observation in active if observation is not None}
        if len(power_qualification) != 1:
            front_ids = sorted(item[0]["id"] for item in active)
            for candidate, _ in active:
                dispositions.append({
                    "id": candidate["id"],
                    "disposition": "POSSIBLE_FRONT",
                    "reasons": ["POWER_QUALIFICATION_INCOMPARABLE"],
                })
            tradeoff.update({
                "front_status": "INCOMPARABLE_QUALIFICATION",
                "qualified_axes": ["performance", "area"],
            })
            return (
                "RESEARCH_REQUIRED", "RESEARCH_REQUIRED",
                ["MULTIOBJECTIVE_EVIDENCE_INCOMPARABLE"], front_ids, None,
                sorted(dispositions, key=lambda item: item["id"]), tradeoff,
            )
        power_is_qualified = next(iter(power_qualification))
        axes = ["performance_ratio", "area_efficiency_ratio"]
        eps = {
            "performance_ratio": float(
                ppa_policy["pareto_epsilon"]["performance_ratio"]),
            "area_efficiency_ratio": float(
                ppa_policy["pareto_epsilon"]["area_ratio"]),
        }
        if power_is_qualified:
            axes.append("qualified_power_efficiency_ratio")
            eps["qualified_power_efficiency_ratio"] = float(
                ppa_policy["pareto_epsilon"]["power_ratio"])
        front = []
        for candidate in active:
            observation = candidate[1]
            assert observation is not None
            if not any(
                robust_dominates(other[1], observation, axes, eps)
                for other in active
                if other[0]["id"] != candidate[0]["id"]
                and other[1] is not None
            ):
                front.append(candidate)
        front_ids = sorted(item[0]["id"] for item in front)
        for candidate, _ in active:
            dispositions.append({
                "id": candidate["id"],
                "disposition": (
                    "POSSIBLE_FRONT" if candidate["id"] in front_ids
                    else "CERTAINLY_DOMINATED"),
                "reasons": [],
            })
        tradeoff["qualified_axes"] = [
            "performance", "area",
            *(("qualified_power",) if power_is_qualified else ()),
        ]
        tradeoff["interval_rule"] = "ROBUST_DOMINANCE"

    if len(front) != 1:
        tradeoff["front_status"] = "AMBIGUOUS"
        return (
            "RESEARCH_REQUIRED", "RESEARCH_REQUIRED",
            ["NONDOMINATED_FRONT_AMBIGUOUS"], front_ids, None,
            sorted(dispositions, key=lambda item: item["id"]), tradeoff,
        )

    winner = front[0][0]
    for item in dispositions:
        if item["id"] == winner["id"]:
            item["disposition"] = "SELECTED_NEXT_ACTION"
    next_action = {
        "correctness_closure": "CORRECTNESS_CLOSURE",
        "state_reconciliation": "STATE_RECONCILIATION",
        "causal_measurement": "CAUSAL_MEASUREMENT",
        "ppa_qualification": "PPA_QUALIFICATION",
        "rtl_experiment": "RTL_EXPERIMENT",
        "diversity_experiment": "DIVERSITY_EXPERIMENT",
    }[winner["class"]]
    tradeoff["front_status"] = "UNIQUE"
    return (
        "SELECT", next_action, ["UNIQUE_ELIGIBLE_FRONT"], front_ids,
        selected_payload(winner),
        sorted(dispositions, key=lambda item: item["id"]), tradeoff,
    )


def build_decision(
    root: pathlib.Path,
    policy_path: pathlib.Path,
    catalog_path: pathlib.Path,
    research_path: pathlib.Path | None = None,
) -> dict[str, Any]:
    policy, ppa_policy, normative = validate_policy(root, policy_path)
    schema_path, _, schema_validator = decision_schema(root)
    ppa_checker_path = workspace_path(root, PPA_CHECKER, "PPA checker")
    owner_verifier_path = workspace_path(
        root, OWNER_TIMING_VERIFIER, "owner timing verifier")
    causal_verifier_path = workspace_path(
        root, CAUSAL_ANALYSIS_VERIFIER, "causal analysis verifier")
    b_latency_verifier_path = workspace_path(
        root, B_LATENCY_SENSITIVITY_VERIFIER, "B-latency sensitivity verifier")
    b_response_candidate_verifier_path = workspace_path(
        root, B_RESPONSE_CANDIDATE_VERIFIER, "B-response candidate verifier")
    current_reference_verifier_path = workspace_path(
        root, CURRENT_REFERENCE_PPA_VERIFIER, "current-reference PPA verifier")
    current_timing_verifier_path = workspace_path(
        root, CURRENT_TIMING_PATH_ANALYSIS_VERIFIER,
        "current timing-path analysis verifier")
    catalog, slices = validate_catalog(root, catalog_path, policy)
    collected, authorities, stale_refs, conflicts = collect_state(
        root, policy, ppa_policy)
    live_design_id = collected["live_design_id"]
    research, overlays, observations = validate_research_state(
        root, research_path, policy, live_design_id)
    facts = dict(collected["facts"])
    facts.update(overlays)
    state = dict(collected["state"])
    for name in (
        "owner_timing_measured", "causal_analysis_completed",
        "causal_analysis_status", "b_latency_sensitivity_completed",
        "b_latency_sensitivity_status",
        "b_response_candidate_analysis_completed",
        "b_response_candidate_analysis_status", "causal_selection_authorized",
        "causal_hypothesis", "ppa_reference_measurement_completed",
        "ppa_reference_measurement_status", "ppa_engineering_reference_available",
        "ppa_timing_hard_gate", "ppa_reference_available",
        "current_timing_path_analysis_completed",
        "current_timing_path_analysis_status", "current_timing_candidate_id",
    ):
        if name in facts:
            state[name] = facts[name]

    inputs: dict[str, Any] = {
        "policy": artifact(root, policy_path),
        "catalog": artifact(root, catalog_path),
        "normative": normative,
        "authorities": authorities,
        "decision_schema": artifact(root, schema_path),
        "verification_tools": {
            "b_latency_sensitivity": artifact(root, b_latency_verifier_path),
            "b_response_candidate_analysis": artifact(
                root, b_response_candidate_verifier_path),
            "causal_analysis": artifact(root, causal_verifier_path),
            "current_reference_ppa": artifact(
                root, current_reference_verifier_path),
            "current_timing_path_analysis": artifact(
                root, current_timing_verifier_path),
            "owner_timing": artifact(root, owner_verifier_path),
            "ppa_checker": artifact(root, ppa_checker_path),
        },
        "research_state": (
            None if research_path is None else artifact(root, research_path)),
    }
    snapshot_key = "sha256:" + canonical_digest({
        "live_design_id": live_design_id,
        "inputs": inputs,
        "facts": facts,
    })
    index = read_json(
        workspace_path(
            root, policy["authorities"]["baseline_index"]["path"],
            "baseline index"),
        "baseline index")
    decision, next_action, reason_codes, front, selected, dispositions, tradeoff = decide(
        slices, facts, policy, ppa_policy, observations,
        index.get("architecture_feasible_seed") is not None, conflicts)

    if not conflicts:
        reason_codes = [
            "CURRENT_IDENTITY_COHERENT",
            *(("CORRECTNESS_BLOCKERS_CLOSED",)
              if state["hard_blockers_closed"] else ()),
            *(("PERF_BASELINE_CURRENT",)
              if state["performance_baseline_current"] else ()),
            *(("PERFORMANCE_ANCHOR_FLOOR_MET",)
              if state["performance_anchor_floor_met"] else (
                  "PERFORMANCE_ANCHOR_FLOOR_NOT_MET",)),
            *(("CPI_CAUSAL_SELECTION_OPEN",)
              if not state["causal_selection_authorized"] else ()),
            *(("PPA_UNQUALIFIED",)
              if not state["ppa_qualified"] else ()),
            *reason_codes,
        ]
    reason_codes = list(dict.fromkeys(reason_codes))
    result = {
        "schema": DECISION_SCHEMA,
        "decision": decision,
        "next_action": next_action,
        "reason_codes": reason_codes,
        "live_design_id": live_design_id,
        "snapshot_key": snapshot_key,
        "inputs": inputs,
        "state": state,
        "eligible_front": front,
        "selected_slice": selected,
        "candidate_dispositions": dispositions,
        "tradeoff_analysis": tradeoff,
        "deferred": [
            item for item in dispositions
            if item["disposition"] != "SELECTED_NEXT_ACTION"
        ],
        "stale_refs": stale_refs,
        "claim_boundary": {
            **policy["claim_boundary"],
            "current_decision_authorizes_only_next_action": True,
            "multiobjective_prediction_authorizes_promotion": False,
            "timing_is_a_hard_gate_not_a_soft_objective": True,
        },
    }
    validate_decision(schema_validator, result)
    return result


def write_json(root: pathlib.Path, path: pathlib.Path, value: dict[str, Any]) -> None:
    try:
        path.resolve(strict=False).relative_to(root)
    except ValueError as exc:
        raise SelectorError("output path escapes workspace") from exc
    require(not path.is_symlink(), "output path must not be a symlink")
    path.parent.mkdir(parents=True, exist_ok=True)
    current = root
    for part in path.relative_to(root).parts[:-1]:
        current = current / part
        require(not current.is_symlink(), "output parent must not be a symlink")
    payload = json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    descriptor, temporary = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def argument_relative(
    root: pathlib.Path, value: pathlib.Path, label: str,
) -> str:
    if value.is_absolute():
        try:
            relative_value = value.relative_to(root)
        except ValueError as exc:
            raise SelectorError(f"{label} escapes workspace") from exc
    else:
        relative_value = value
    raw = relative_value.as_posix()
    _lexical_parts(raw, label)
    return raw


def resolve_argument(root: pathlib.Path, value: pathlib.Path, label: str) -> pathlib.Path:
    return workspace_path(root, argument_relative(root, value, label), label)


def resolve_output_argument(
    root: pathlib.Path, value: pathlib.Path, label: str,
) -> pathlib.Path:
    path = workspace_path(
        root, argument_relative(root, value, label), label, must_exist=False)
    require(not path.exists() or path.is_file(),
            f"{label} must be a regular file path")
    return path


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5])
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--policy", type=pathlib.Path,
                       default=pathlib.Path(DEFAULT_POLICY))
    build.add_argument("--catalog", type=pathlib.Path,
                       default=pathlib.Path(DEFAULT_CATALOG))
    build.add_argument("--research-state", type=pathlib.Path)
    build.add_argument("--output", type=pathlib.Path, required=True)
    build.add_argument("--report-only", action="store_true")
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path,
                        default=pathlib.Path(DEFAULT_DECISION))
    verify.add_argument("--report-only", action="store_true")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == "build":
            policy_path = resolve_argument(root, args.policy, "selector policy")
            catalog_path = resolve_argument(root, args.catalog, "slice catalog")
            research_path = (
                None if args.research_state is None
                else resolve_argument(root, args.research_state, "research state"))
            result = build_decision(
                root, policy_path, catalog_path, research_path)
            output = resolve_output_argument(root, args.output, "selector output")
            write_json(root, output, result)
        else:
            input_path = resolve_argument(root, args.input, "selector decision")
            stored = read_json(input_path, "selector decision")
            require(stored.get("schema") == DECISION_SCHEMA,
                    "selector decision schema mismatch")
            policy_path = verify_artifact_ref(
                root, stored.get("inputs", {}).get("policy"), "decision policy")
            catalog_path = verify_artifact_ref(
                root, stored.get("inputs", {}).get("catalog"), "decision catalog")
            research_ref = stored.get("inputs", {}).get("research_state")
            research_path = (
                None if research_ref is None
                else verify_artifact_ref(root, research_ref, "decision research state"))
            result = build_decision(
                root, policy_path, catalog_path, research_path)
            require(stored == result, "stored selector decision is not canonical")
        print(
            "[RV64-OPTIMIZATION-SLICE-SELECTOR] "
            f"decision={result['decision']} next_action={result['next_action']} "
            f"design_id={result['live_design_id']} "
            f"selected={None if result['selected_slice'] is None else result['selected_slice']['id']}"
        )
        if result["decision"] != "SELECT" and not args.report_only:
            return 1
        return 0
    except (SelectorError, KeyError, OSError, ValueError) as exc:
        print(f"[RV64-OPTIMIZATION-SLICE-SELECTOR][FAIL] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
