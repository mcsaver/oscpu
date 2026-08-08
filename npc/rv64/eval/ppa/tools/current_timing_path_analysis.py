#!/usr/bin/env python3
"""Bind the exact-current RV64 mapped top-40 to one reversible RTL candidate."""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import pathlib
import re
import sys
import tempfile
from typing import Any


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
SCHEMA = "npc-rv64-current-timing-path-analysis-v2"
REFERENCE_SCHEMA = "npc-rv64-current-reference-ppa-v1"
SELECTOR_SCHEMA = "npc-rv64-optimization-slice-decision-v1"
SELECTED_SLICE = "analyze.current-timing-recovery-candidate"
EXPECTED_REFERENCE_STATUS = "REPEATABLE_CURRENT_REFERENCE_TIMING_HARD_GATE_FAIL"
PATH_CLUSTER_SCHEMA = "npc-rv64-v15v-ppa-delta-path-cluster-v1"
REVIEW_MARKER = "[V15W-HEAD0-CSR-FROZEN-REVIEW][PASS_CANDIDATE]"
STATUS = "TRACEABLE_HEAD0_CSR_DISPATCH_CANCEL_CANDIDATE_DEFINED"
CANDIDATE_ID = "head0-csr-inflight-permit-block-v1"
NEXT_ACTION = "validate.head0-csr-dispatch-disjointness"

START_RE = re.compile(r"^Startpoint:\s+(\S+)")
END_RE = re.compile(r"^Endpoint:\s+(\S+)")
SLACK_RE = re.compile(r"^\s+(-?\d+\.\d+)\s+slack \(VIOLATED\)\s*$")
ARRIVAL_RE = re.compile(r"^\s+(\d+\.\d+)\s+data arrival time\s*$")
POINT_RE = re.compile(
    r"^\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+[\^v]\s+"
    r"(.+)/(\S+)\s+\(([^)]+)\)\s*$"
)
NUMERIC_INSTANCE_RE = re.compile(r"^_(\d+)_$")


class EvidenceError(ValueError):
    """A path report or its exact evidence binding is invalid."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def relative(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path.resolve())


def resolve_workspace(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError as error:
        raise EvidenceError(f"workspace path escapes repository: {raw}") from error
    require(resolved.is_file() and not resolved.is_symlink(),
            f"missing or symlink artifact: {raw}")
    return resolved


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def digest_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def file_ref(path: pathlib.Path) -> dict[str, Any]:
    path = resolve_workspace(path)
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def load_json(path: pathlib.Path) -> dict[str, Any]:
    def pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in values:
            require(key not in result,
                    f"duplicate JSON key in {relative(path)}: {key}")
            result[key] = value
        return result

    try:
        value = json.loads(path.read_text(encoding="utf-8"),
                           object_pairs_hook=pairs)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise EvidenceError(f"cannot read JSON {relative(path)}: {error}") from error
    require(isinstance(value, dict), f"JSON root is not an object: {relative(path)}")
    return value


def verify_ref(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} reference is not an object")
    require(set(value) == {"path", "sha256", "size_bytes"},
            f"{label} reference key set mismatch")
    path = resolve_workspace(value.get("path", ""))
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size drift")
    return path


def verify_summary_artifact(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} artifact is not an object")
    require(set(value) == {"path", "path_scope", "sha256", "size_bytes"},
            f"{label} artifact key set mismatch")
    require(value.get("path_scope") == "workspace_relative",
            f"{label} must be workspace-relative")
    path = resolve_workspace(value.get("path", ""))
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size drift")
    return path


def common_prefix_length(values: list[list[str]]) -> int:
    if not values:
        return 0
    limit = min(len(value) for value in values)
    for index in range(limit):
        if len({value[index] for value in values}) != 1:
            return index
    return limit


def common_suffix_length(values: list[list[str]]) -> int:
    return common_prefix_length([list(reversed(value)) for value in values])


def histogram(values: list[str]) -> dict[str, int]:
    return dict(sorted(collections.Counter(values).items(),
                       key=lambda item: float(item[0])))


def parse_report(path: pathlib.Path) -> list[dict[str, Any]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise EvidenceError(f"cannot read top-40 report {relative(path)}: {error}") from error
    starts = [index for index, line in enumerate(lines) if line.startswith("Startpoint:")]
    require(len(starts) == 40,
            f"top-40 report must contain exactly 40 paths: {relative(path)}")
    starts.append(len(lines))
    paths: list[dict[str, Any]] = []
    for path_index in range(40):
        block = lines[starts[path_index]:starts[path_index + 1]]
        start_match = START_RE.match(block[0]) if block else None
        end_matches = [match for line in block
                       if (match := END_RE.match(line))]
        require(start_match is not None and len(end_matches) == 1,
                f"path {path_index} header is malformed")
        startpoint = start_match.group(1)
        endpoint = end_matches[0].group(1)
        slacks = [match.group(1) for line in block
                  if (match := SLACK_RE.match(line))]
        arrivals = [match.group(1) for line in block
                    if (match := ARRIVAL_RE.match(line))]
        require(len(slacks) == 1 and len(arrivals) == 1,
                f"path {path_index} timing footer is malformed")

        points: list[dict[str, Any]] = []
        for line in block:
            match = POINT_RE.match(line)
            if match:
                points.append({
                    "incremental_delay_ns": match.group(1),
                    "arrival_ns": match.group(2),
                    "instance": match.group(3),
                    "pin": match.group(4),
                    "cell_type": match.group(5),
                })
        q_indices = [index for index, point in enumerate(points)
                     if point["instance"] == startpoint and
                     point["pin"] in {"Q", "QN"}]
        d_indices = [index for index, point in enumerate(points)
                     if point["instance"] == endpoint and point["pin"] == "D"]
        require(len(q_indices) == 1 and len(d_indices) == 1 and
                q_indices[0] < d_indices[0],
                f"path {path_index} does not contain one start Q to endpoint D arc")
        combinational = points[q_indices[0] + 1:d_indices[0]]
        require(len(combinational) >= 2,
                f"path {path_index} combinational cone is implausibly short")
        raw_chain = [
            f'{point["instance"]}/{point["pin"]}:{point["cell_type"]}'
            for point in combinational
        ]
        type_chain = [point["cell_type"] for point in combinational]
        paths.append({
            "index": path_index,
            "startpoint": startpoint,
            "endpoint": endpoint,
            "slack_ns": slacks[0],
            "arrival_ns": arrivals[0],
            "start_cell_type": points[q_indices[0]]["cell_type"],
            "endpoint_cell_type": points[d_indices[0]]["cell_type"],
            "combinational": combinational,
            "raw_chain": raw_chain,
            "type_chain": type_chain,
            "raw_chain_sha256": digest_text("\n".join(raw_chain)),
            "type_chain_sha256": digest_text("\n".join(type_chain)),
        })
    return paths


def endpoint_bank(endpoints: list[str]) -> dict[str, Any]:
    numeric = [NUMERIC_INSTANCE_RE.fullmatch(value) for value in endpoints]
    if not all(numeric):
        return {"encoding": "traceable_or_mixed", "members": sorted(endpoints)}
    identifiers = sorted(int(match.group(1)) for match in numeric if match)
    present = set(identifiers)
    return {
        "encoding": "numeric_postmap",
        "id_min": identifiers[0],
        "id_max": identifiers[-1],
        "member_count": len(identifiers),
        "missing_ids_in_span": [
            value for value in range(identifiers[0], identifiers[-1] + 1)
            if value not in present
        ],
        "members": sorted(endpoints),
    }


def summarize_paths(paths: list[dict[str, Any]]) -> dict[str, Any]:
    raw_chains = [path["raw_chain"] for path in paths]
    type_chains = [path["type_chain"] for path in paths]
    starts = collections.Counter(path["startpoint"] for path in paths)
    endpoints = [path["endpoint"] for path in paths]

    grouped: dict[tuple[str, str], list[dict[str, Any]]] = collections.defaultdict(list)
    for path in paths:
        grouped[(path["startpoint"], path["type_chain_sha256"])].append(path)
    families: list[dict[str, Any]] = []
    ordered_groups = sorted(grouped.items(), key=lambda item: (-len(item[1]), item[0]))
    for family_index, ((startpoint, type_digest), members) in enumerate(ordered_groups):
        families.append({
            "id": f"F{family_index}",
            "path_count": len(members),
            "startpoint": startpoint,
            "endpoints": sorted(path["endpoint"] for path in members),
            "slack_histogram_ns": histogram([path["slack_ns"] for path in members]),
            "arrival_histogram_ns": histogram([path["arrival_ns"] for path in members]),
            "cell_type_chain_sha256": type_digest,
            "cell_type_count": len(members[0]["type_chain"]),
            "raw_chain_variant_count": len({path["raw_chain_sha256"] for path in members}),
        })

    shared_cells: dict[tuple[str, str], dict[str, Any]] = {}
    for path in paths:
        seen: set[tuple[str, str]] = set()
        for point in path["combinational"]:
            key = (point["instance"], point["cell_type"])
            if key in seen:
                continue
            seen.add(key)
            record = shared_cells.setdefault(key, {
                "instance": point["instance"],
                "cell_type": point["cell_type"],
                "path_count": 0,
                "max_incremental_delay_ns": point["incremental_delay_ns"],
            })
            record["path_count"] += 1
            if float(point["incremental_delay_ns"]) > float(record["max_incremental_delay_ns"]):
                record["max_incremental_delay_ns"] = point["incremental_delay_ns"]
    shared_hotspots = [record for record in shared_cells.values()
                       if record["path_count"] == len(paths)]
    shared_hotspots.sort(
        key=lambda value: (-float(value["max_incremental_delay_ns"]),
                           value["instance"])
    )

    numeric_names = all(NUMERIC_INSTANCE_RE.fullmatch(value)
                        for value in [*starts.keys(), *endpoints])
    dominant = families[0]
    return {
        "path_count": len(paths),
        "violated_path_count": len(paths),
        "unique_startpoint_count": len(starts),
        "startpoint_histogram": dict(sorted(starts.items())),
        "unique_endpoint_count": len(set(endpoints)),
        "endpoint_bank": endpoint_bank(endpoints),
        "slack_histogram_ns": histogram([path["slack_ns"] for path in paths]),
        "arrival_histogram_ns": histogram([path["arrival_ns"] for path in paths]),
        "raw_chain_variant_count": len({path["raw_chain_sha256"] for path in paths}),
        "cell_type_chain_variant_count": len(
            {path["type_chain_sha256"] for path in paths}),
        "common_raw_prefix_cell_count": common_prefix_length(raw_chains),
        "common_raw_suffix_cell_count": common_suffix_length(raw_chains),
        "minimum_combinational_cell_count": min(len(value) for value in raw_chains),
        "maximum_combinational_cell_count": max(len(value) for value in raw_chains),
        "families": families,
        "dominant_family": {
            "id": dominant["id"],
            "path_count": dominant["path_count"],
            "coverage_ratio": f'{dominant["path_count"] / len(paths):.12f}',
            "classification": "SHARED_STARTPOINT_AND_CELL_TYPE_CONE",
        },
        "top_shared_incremental_delay_cells": shared_hotspots[:12],
        "rtl_traceability": {
            "status": "GAP_NUMERIC_POSTMAP_NAMES" if numeric_names else "TRACEABLE_NAMES_PRESENT",
            "start_and_endpoint_names_numeric_only": numeric_names,
            "rtl_owner": None,
        },
    }


def verify_selector(path: pathlib.Path, design_id: str) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == SELECTOR_SCHEMA, "selector schema mismatch")
    require(value.get("decision") == "SELECT" and
            value.get("next_action") == "CAUSAL_MEASUREMENT",
            "selector does not authorize causal measurement")
    require(value.get("live_design_id") == design_id,
            "selector design-id mismatch")
    require(value.get("selected_slice", {}).get("id") == SELECTED_SLICE,
            "selector did not select current timing-path analysis")
    state = value.get("state", {})
    require(state.get("ppa_engineering_reference_available") is True and
            state.get("ppa_reference_available") is False and
            state.get("ppa_timing_hard_gate") == "FAIL",
            "selector PPA boundary mismatch")
    return value


def verify_reference(
        path: pathlib.Path,
        run1_top40: pathlib.Path,
        run2_top40: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == REFERENCE_SCHEMA and
            value.get("status") == EXPECTED_REFERENCE_STATUS,
            "current-reference PPA receipt status mismatch")
    repeatability = value.get("repeatability", {})
    require(repeatability.get("status") == "PASS",
            "current-reference repeatability is not PASS")
    expected_top40 = repeatability.get("top40_path_members_sha256")
    require(isinstance(expected_top40, str) and len(expected_top40) == 64,
            "current-reference top-40 digest is invalid")
    timing = value.get("timing", {})
    require(timing.get("hard_gate") == "FAIL" and
            timing.get("top_path_count") == 40 and
            timing.get("violated_path_count") == 40,
            "current-reference timing boundary mismatch")
    authorization = value.get("authorization", {})
    require(authorization.get("engineering_reference_available") is True and
            authorization.get("accepted_ppa_reference_available") is False and
            authorization.get("new_production_rtl_change_authorized") is False and
            authorization.get("promotion_eligible") is False,
            "current-reference authorization boundary mismatch")

    summary_paths: list[pathlib.Path] = []
    for label in ("run1_summary", "run2_summary"):
        summary_path = verify_ref(value.get("inputs", {}).get(label), label)
        summary = load_json(summary_path)
        summary_paths.append(verify_summary_artifact(
            summary.get("artifacts", {}).get("top40"), f"{label}.top40"))
    require(summary_paths == [run1_top40, run2_top40],
            "explicit top-40 paths do not match current-reference summaries")
    require(sha256(run1_top40) == expected_top40 and
            sha256(run2_top40) == expected_top40 and
            run1_top40.read_bytes() == run2_top40.read_bytes(),
            "two-run top-40 reports are not exact and bit-identical")
    return value


def verify_traceability(path: pathlib.Path) -> dict[str, int | str]:
    pairs: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise EvidenceError(
            f"cannot read traceability receipt {relative(path)}: {error}") from error
    for line in lines:
        require(line.count("=") == 1,
                f"malformed traceability line in {relative(path)}")
        key, value = line.split("=", 1)
        require(key and key not in pairs,
                f"duplicate traceability key in {relative(path)}: {key}")
        pairs[key] = value
    require(set(pairs) == {
        "status", "startpoints", "endpoints", "public_flat_startpoints",
        "public_flat_endpoints", "opaque_startpoints", "opaque_endpoints",
    }, "traceability receipt key set mismatch")
    require(pairs["status"] == "PASS", "traceability receipt is not PASS")
    numeric = {
        key: int(value) for key, value in pairs.items() if key != "status"
    }
    require(numeric == {
        "startpoints": 40,
        "endpoints": 40,
        "public_flat_startpoints": 40,
        "public_flat_endpoints": 40,
        "opaque_startpoints": 0,
        "opaque_endpoints": 0,
    }, "traceability coverage is not exact 40/40 public-flat")
    return {"status": "PASS", **numeric}


def verify_path_cluster(
        path: pathlib.Path,
        run1_top40: pathlib.Path,
        path_analysis: dict[str, Any]) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == PATH_CLUSTER_SCHEMA and
            value.get("status") == "PASS" and
            value.get("decision") == "ENGINEERING_CANDIDATE_RETAIN" and
            value.get("gap") == "5NS_TARGET_NOT_MET",
            "ca37 path-cluster boundary mismatch")
    candidate = value.get("top40", {}).get("candidate", {})
    startpoints = path_analysis.get("startpoint_histogram", {})
    require(
        candidate.get("path_count") == 40
        and candidate.get("unique_startpoints") == 1
        and candidate.get("unique_endpoints") == 40
        and candidate.get("startpoint") in startpoints
        and candidate.get("endpoint_classes") == {
            "jalr_prefetch_hit_available": 38,
            "redirect_valid": 2,
        },
        "ca37 path-cluster member classification mismatch",
    )
    tokens = candidate.get("token_path_counts", {})
    require(
        tokens.get("head0_csr_commit") == 40
        and tokens.get("system_csr_dispatch_cancel") == 40
        and tokens.get("system_csr_dispatch_valid") == 40
        and tokens.get("pending_system_inst") == 40
        and tokens.get("pending_system_csr_commit") == 0,
        "ca37 path-cluster control-token census mismatch",
    )
    top40_ref = value.get("evidence", {}).get("candidate_top40", {})
    require(isinstance(top40_ref, dict) and
            set(top40_ref) == {"path", "sha256"},
            "ca37 candidate top-40 reference key set mismatch")
    bound_top40 = resolve_workspace(top40_ref.get("path", ""))
    require(bound_top40 == run1_top40 and
            top40_ref.get("sha256") == sha256(run1_top40),
            "ca37 path cluster does not bind the current top-40 report")
    return value


def build_payload(
        current_reference_path: pathlib.Path,
        selector_path: pathlib.Path,
        review_path: pathlib.Path,
        run1_top40_path: pathlib.Path,
        run2_top40_path: pathlib.Path,
        traceability_path: pathlib.Path,
        path_cluster_path: pathlib.Path) -> dict[str, Any]:
    current_reference_path = resolve_workspace(current_reference_path)
    selector_path = resolve_workspace(selector_path)
    review_path = resolve_workspace(review_path)
    run1_top40_path = resolve_workspace(run1_top40_path)
    run2_top40_path = resolve_workspace(run2_top40_path)
    traceability_path = resolve_workspace(traceability_path)
    path_cluster_path = resolve_workspace(path_cluster_path)
    reference = verify_reference(
        current_reference_path, run1_top40_path, run2_top40_path)
    design_id = reference.get("design_id")
    require(isinstance(design_id, str) and design_id.startswith("sha256:"),
            "current-reference design-id is invalid")
    selector = verify_selector(selector_path, design_id)
    review_text = review_path.read_text(encoding="utf-8")
    require(REVIEW_MARKER in review_text and
            f"design_id={design_id}" in review_text and
            "candidate-only" in review_text and
            "production_rtl_change_authorized=false" in review_text and
            "PPA=UNQUALIFIED" in review_text and
            "promotion_eligible=false" in review_text,
            "independent-review marker or claim boundary mismatch")

    run1_paths = parse_report(run1_top40_path)
    run2_paths = parse_report(run2_top40_path)
    require([
        (path["startpoint"], path["endpoint"], path["slack_ns"],
         path["arrival_ns"], path["raw_chain_sha256"])
        for path in run1_paths
    ] == [
        (path["startpoint"], path["endpoint"], path["slack_ns"],
         path["arrival_ns"], path["raw_chain_sha256"])
        for path in run2_paths
    ], "parsed top-40 path members differ between runs")
    path_analysis = summarize_paths(run2_paths)
    require(path_analysis["dominant_family"]["path_count"] >= 20,
            "no dominant physical-proxy path family was identified")
    require(path_analysis["rtl_traceability"]["status"] ==
            "TRACEABLE_NAMES_PRESENT",
            "current top-40 does not contain traceable public-flat names")
    traceability = verify_traceability(traceability_path)
    cluster = verify_path_cluster(
        path_cluster_path, run1_top40_path, path_analysis)
    cluster_candidate = cluster["top40"]["candidate"]
    path_analysis["rtl_traceability"]["rtl_owner"] = {
        "launch": {
            "module": "CsrFile",
            "state": "csr_mtvec_q[63]",
            "hierarchy_evidence": next(iter(
                path_analysis["startpoint_histogram"])),
            "resolution": "EXACT_PUBLIC_FLAT_STATE",
        },
        "capture": {
            "module": "OooFetchPcOutstandingSequencer",
            "endpoint_classes": cluster_candidate["endpoint_classes"],
            "resolution": "PUBLIC_FLAT_MODULE_AND_INPUT_ALIAS",
            "exact_rtl_register_bit": "NOT_CLAIMED_FROM_AUTONAME_ALIAS",
        },
        "dominant_control_segment": {
            "modules": [
                "OooCsrAccessRequestMux",
                "OooPendingSystemAdmissionCancelGate",
                "OooFrontendBackendDispatchMux",
            ],
            "signals": [
                "head0_csr_commit_w",
                "system_csr_dispatch_cancel_w",
                "system_csr_dispatch_valid_w",
                "pending_system_inst_q",
            ],
            "coverage": "40/40",
        },
    }
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "design_id": design_id,
        "configuration": {
            "top": "NpcTop",
            "period_ns": 5.0,
            "frequency_mhz": 200.0,
            "timing_tier": "rtl_proxy_partial_constraints",
            "report_count": 2,
            "paths_per_report": 40,
        },
        "inputs": {
            "current_reference": file_ref(current_reference_path),
            "selector": file_ref(selector_path),
            "independent_review": file_ref(review_path),
            "run1_top40": file_ref(run1_top40_path),
            "run2_top40": file_ref(run2_top40_path),
            "traceability": file_ref(traceability_path),
            "ca37_path_cluster": file_ref(path_cluster_path),
            "builder": file_ref(pathlib.Path(__file__)),
        },
        "repeatability": {
            "status": "PASS",
            "reports_bit_identical": True,
            "top40_sha256": sha256(run1_top40_path),
            "parsed_members_identical": True,
        },
        "path_analysis": path_analysis,
        "candidate_decision": {
            "status": "CANDIDATE_ONLY",
            "id": CANDIDATE_ID,
            "rtl_owner_resolved": True,
            "production_rtl_change_authorized": False,
            "promotion_eligible": False,
            "ppa": "UNQUALIFIED",
            "reason": (
                "Both current reports and the ca37 cluster place head0 CSR "
                "commit cancellation in all 40 violating paths.  The reversible "
                "candidate first blocks pending-CSR permit arm/hold with the "
                "registered head0 CSR inflight owner, then keeps commit as an "
                "admission clear while removing it only from pre-ROB dispatch "
                "cancel.  This receipt defines that topology but does not prove "
                "the cross-owner disjointness or authorize an RTL edit."
            ),
            "current_top40_control_token_counts":
                cluster_candidate["token_path_counts"],
        },
        "candidate_definition": {
            "id": CANDIDATE_ID,
            "state": "CANDIDATE_ONLY",
            "rtl_objective": (
                "Use head0_csr_inflight_q as a registered blocker for "
                "dispatch_permit_q arm/hold, then remove head0_csr_commit_i "
                "only from system_csr_dispatch_cancel_o while retaining its "
                "pending-owner admission clear and serial-flush effects."
            ),
            "intended_scope": [
                "npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v",
                "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
                "npc/rv64/vsrc/control/OooControlPlane.v",
                "npc/rv64/vsrc/frontend/OooFrontend.v",
            ],
            "pipeline_state_added": 0,
            "interface_state_source": "existing head0_csr_inflight_q",
            "reversible": True,
        },
        "next_measurement": {
            "id": NEXT_ACTION,
            "purpose": (
                "Prove or reject the registered-inflight/pre-ROB pending-CSR "
                "disjointness before any production RTL edit."
            ),
            "must_hold": [
                "queue-head CSR dispatch fire cannot capture a lane1 pending SYSTEM owner",
                "head0_csr_commit implies the edge-old head0_csr_inflight owner",
                "head0_csr_inflight blocks pending CSR permit arm and clears any held permit",
                "commit-cycle dispatch fire remains false for dispatch0_ready 0 and 1",
                "reset, local/global/serial flush and older-control recovery clear both owners",
                "post-dispatch ProducerId lease is cleared only by exact producer death",
            ],
            "required_counterexamples": [
                "same-cycle queue-head CSR lane0 fire plus lane1 SYSTEM capture",
                "permit held under backend ready stall when head0 CSR commits",
                "head0 CSR commit with inflight owner absent",
                "older-control kill or serial flush colliding with permit arm/fire",
                "pending CSR producer lease colliding with queue-head CSR commit",
            ],
        },
        "candidate_invariants_if_owner_is_resolved": [
            "no CPI regression on the frozen CoreMark and Dhrystone committed-PC workloads",
            "owner/holder lifetime and exact terminal-event conservation remain unchanged",
            "ready/valid backpressure and payload stability remain unchanged",
            "flush/replay, precise exception and memory-order behavior remain unchanged",
            "fresh exact 5 ns mapped STA is required; a negative WNS cannot become an accepted baseline",
        ],
        "claim_boundary": {
            "one_dominant_physical_proxy_family_identified": True,
            "traceable_public_flat_names_40_of_40":
                traceability["public_flat_startpoints"] == 40 and
                traceability["public_flat_endpoints"] == 40,
            "control_segment_owner_resolved": True,
            "capture_register_bit_not_inferred_from_autoname_alias": True,
            "adapter_not_attributed_from_zero_top40_tokens":
                reference.get("timing", {}).get("adapter_tokens_in_top40") == 0,
            "accepted_ppa_reference_not_claimed": True,
            "production_rtl_unchanged": True,
            "ubuntu_full_system_not_run": True,
        },
        "next_action": NEXT_ACTION,
    }


def atomic_write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(value, indent=2, sort_keys=True) + "\n"
    with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent,
            prefix=f".{path.name}.", delete=False) as stream:
        temporary = pathlib.Path(stream.name)
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def rebuild_receipt(actual: dict[str, Any]) -> dict[str, Any]:
    require(actual.get("schema") == SCHEMA, "analysis receipt schema mismatch")
    inputs = actual.get("inputs", {})
    for label in ("current_reference", "selector", "independent_review",
                  "run1_top40", "run2_top40", "traceability",
                  "ca37_path_cluster", "builder"):
        verify_ref(inputs.get(label), label)
    return build_payload(
        pathlib.Path(inputs["current_reference"]["path"]),
        pathlib.Path(inputs["selector"]["path"]),
        pathlib.Path(inputs["independent_review"]["path"]),
        pathlib.Path(inputs["run1_top40"]["path"]),
        pathlib.Path(inputs["run2_top40"]["path"]),
        pathlib.Path(inputs["traceability"]["path"]),
        pathlib.Path(inputs["ca37_path_cluster"]["path"]),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    build = subparsers.add_parser("build")
    build.add_argument("--current-reference", required=True)
    build.add_argument("--selector", required=True)
    build.add_argument("--independent-review", required=True)
    build.add_argument("--run1-top40", required=True)
    build.add_argument("--run2-top40", required=True)
    build.add_argument("--traceability", required=True)
    build.add_argument("--path-cluster", required=True)
    build.add_argument("--output", required=True)
    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            output = pathlib.Path(args.output)
            if not output.is_absolute():
                output = REPO_ROOT / output
            output = output.resolve()
            try:
                output.relative_to(REPO_ROOT)
            except ValueError as error:
                raise EvidenceError("output path escapes repository") from error
            value = build_payload(
                pathlib.Path(args.current_reference), pathlib.Path(args.selector),
                pathlib.Path(args.independent_review), pathlib.Path(args.run1_top40),
                pathlib.Path(args.run2_top40), pathlib.Path(args.traceability),
                pathlib.Path(args.path_cluster))
            atomic_write_json(output, value)
            design_id = value["design_id"]
        else:
            input_path = resolve_workspace(args.input)
            actual = load_json(input_path)
            expected = rebuild_receipt(actual)
            require(actual == expected, "analysis receipt differs from rebuilt evidence")
            design_id = actual["design_id"]
        print(
            "[CURRENT-TIMING-PATH-ANALYSIS][PASS_CANDIDATE_ONLY] "
            f"design_id={design_id} paths=40 dominant_shared_cone=1 "
            f"candidate={CANDIDATE_ID} production_rtl_authorized=false"
        )
        return 0
    except (EvidenceError, OSError, UnicodeError, KeyError) as error:
        print(f"[CURRENT-TIMING-PATH-ANALYSIS][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
