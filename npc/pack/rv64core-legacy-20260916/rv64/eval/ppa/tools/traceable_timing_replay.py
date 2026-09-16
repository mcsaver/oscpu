#!/usr/bin/env python3
"""Replay the frozen V15R traceable-name STA evidence without rerunning EDA."""

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
TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import current_timing_path_analysis as timing_paths  # noqa: E402


SCHEMA = "npc-rv64-traceable-timing-checker-replay-v1"
STATUS = "CHECKER_REPLAY_PASS_ORIGINAL_RUN_FAIL_PRESERVED"
PASS_MARKER = "[TRACEABLE-TIMING-CHECKER-REPLAY][PASS_ORIGINAL_FAIL_PRESERVED]"
TRACE_RUN_REL = (
    ".github/task-runs/2026-08-07-rv64-v15r-current-timing-trace-337-a1"
)
TRACE_EVIDENCE_REL = f"{TRACE_RUN_REL}/evidence/traceable-names-a1"
PATH_ANALYSIS_REL = (
    ".github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-"
    "337de8bf/evidence/current-timing-path-analysis-337-a1.json"
)
RUNTIME_REL = ".github/runtime-artifacts/v15r-current-timing-trace-337-a1"
EXPECTED_DESIGN_ID = (
    "sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968"
)

# 这些摘要冻结原始 FAIL 运行的输入，replay 只能解释它们，不能回写历史状态。
FROZEN_SHA256 = {
    "status": "f923a8ae87f26025bdec54301bf96013c31c323228a3c04f266705cfb5a4fe5e",
    "driver": "9d98f740a4b839a4d47bc9e8b8aeabe2a73e4f816afeab6c18caf46c6e41bbd7",
    "command_status": "4eefd85ee0bd97764437b04b2a7243c98269808f090b136453e9177e51b1eafc",
    "old_traceability": "5acf48a9a6c1d411c355d72d856ab4ec073eca8adcfca8f9d1bfbbd21b1b2b92",
    "named_summary": "e6055328c9692a7ae743cca0a4da28e20a7ac8de5ed1dc232007dce96d3263e0",
    "named_top40": "3fd2839210c3d70d5e33ef5de39d0af46003c1f9b4ed3f118843ef4c2919a80c",
    "production_manifest_before": (
        "38eba19c8abbb9dd6fda70409f10f73f8596318958daafd15689201b10b2d7a2"
    ),
    "synthesis_sources": (
        "90e43ab71f0a7a3e8bb148b271acf627bc989cc7aa98ecc7c96015e01cbe9baa"
    ),
    "parameters": "ef92b056f9daa911a81804473850725f05b91405560996a1bfcc73850e18f979",
    "netlist_hash_record": (
        "3ef65b7ffa8c23bf77f7d11131fe5e3f0d0d4e6f6d8a9a7e9b23d05f472a1961"
    ),
    "netlist_size_record": (
        "e18d735e0580b796fcfacd9721f897f0b27129d5ab03c0be209353f47c6970e9"
    ),
}

LAUNCH_PREFIX = (
    "u_core_u_ooo_core_u_execute_backend_u_core_slice_u_decode_backend_"
    "u_int_backend_u_mem_owner_tracker_next_token_q_0__"
)
CAPTURE_PREFIX = "u_core_u_ooo_core_u_frontend_u_fetch_pc_outstanding_"
MAPPED_DFF_SUFFIX = "_DFFQX1H7L_D"
NAME_RE = re.compile(r"[A-Za-z0-9_]+")
STATUS_RE = re.compile(
    r"FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0\n?"
)
START_RE = re.compile(r"^Startpoint:\s+(\S+)")
END_RE = re.compile(r"^Endpoint:\s+(\S+)")


class ReplayError(ValueError):
    """The frozen trace evidence or replay receipt is inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReplayError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_sha256(value: Any) -> str:
    data = json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        separators=(",", ":"), sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(data).hexdigest()


def relative(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path.resolve())


def resolve_workspace_file(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError as error:
        raise ReplayError(f"workspace path escapes repository: {raw}") from error
    require(resolved.is_file() and not resolved.is_symlink(),
            f"missing or symlink artifact: {raw}")
    return resolved


def resolve_workspace_dir(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError as error:
        raise ReplayError(f"workspace directory escapes repository: {raw}") from error
    require(resolved.is_dir() and not resolved.is_symlink(),
            f"missing or symlink directory: {raw}")
    return resolved


def strict_json(path: pathlib.Path) -> dict[str, Any]:
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
        raise ReplayError(f"cannot read JSON {relative(path)}: {error}") from error
    require(isinstance(value, dict), f"JSON root is not an object: {relative(path)}")
    return value


def file_ref(path: pathlib.Path) -> dict[str, Any]:
    path = resolve_workspace_file(path)
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def verify_ref(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} reference is not an object")
    require(set(value) == {"path", "sha256", "size_bytes"},
            f"{label} reference key set mismatch")
    path = resolve_workspace_file(value.get("path", ""))
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size drift")
    return path


def verify_artifact_ref(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} artifact is not an object")
    require(set(value) == {"path", "path_scope", "sha256", "size_bytes"},
            f"{label} artifact key set mismatch")
    scope = value.get("path_scope")
    raw = value.get("path", "")
    if scope == "workspace_relative":
        path = resolve_workspace_file(raw)
    elif scope == "external_absolute":
        path = pathlib.Path(raw)
        require(path.is_absolute() and path.is_file() and not path.is_symlink(),
                f"{label} external artifact is missing or a symlink")
    else:
        raise ReplayError(f"{label} path scope is invalid")
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size drift")
    return path


def require_frozen(path: pathlib.Path, label: str) -> None:
    expected = FROZEN_SHA256[label]
    require(sha256(path) == expected, f"frozen {label} SHA-256 drift")


def parse_key_values(path: pathlib.Path, expected_keys: set[str]) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        require("=" in line, f"malformed key/value line in {relative(path)}")
        key, value = line.split("=", 1)
        require(key and key not in result,
                f"duplicate or empty key in {relative(path)}: {key}")
        result[key] = value
    require(set(result) == expected_keys,
            f"key set mismatch in {relative(path)}")
    return result


def parse_original_status(path: pathlib.Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    require(STATUS_RE.fullmatch(text) is not None,
            "original status is not the frozen evidence-complete FAIL")
    return {
        "status": "FAIL",
        "rc": 1,
        "stage": "evidence-complete",
        "evidence_complete": False,
        "cleanup_rc": 0,
    }


def parse_manifest(path: pathlib.Path) -> tuple[dict[str, str], int, list[str]]:
    entries: dict[str, str] = {}
    line_count = 0
    duplicate_paths: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line_count += 1
        fields = line.split(maxsplit=1)
        require(len(fields) == 2 and re.fullmatch(r"[0-9a-f]{64}", fields[0]) is not None,
                "production manifest line is malformed")
        raw_path = fields[1].lstrip("*")
        manifest_path = pathlib.Path(raw_path)
        if not manifest_path.is_absolute():
            require(raw_path == f"{TRACE_RUN_REL}/driver/run-traceable-names-a1.sh",
                    "unexpected relative production manifest path")
            manifest_path = REPO_ROOT / manifest_path
        key = str(manifest_path)
        if key in entries:
            require(entries[key] == fields[0],
                    f"conflicting production manifest duplicate: {key}")
            duplicate_paths.append(key)
            continue
        entries[key] = fields[0]
    expected_duplicate = str(REPO_ROOT / "npc/rv64/vsrc/filelist.mk")
    require(line_count == 206 and len(entries) == 205 and
            duplicate_paths == [expected_duplicate],
            "production manifest line/unique/duplicate census drifted")
    return entries, line_count, duplicate_paths


def verify_manifest_live(
        entries: dict[str, str], line_count: int,
        duplicate_paths: list[str]) -> dict[str, Any]:
    for raw_path, expected in entries.items():
        path = pathlib.Path(raw_path)
        require(path.is_file(), f"production manifest input is missing: {raw_path}")
        require(sha256(path) == expected,
                f"production manifest input SHA-256 drift: {raw_path}")
    return {
        "status": "PASS",
        "line_count": line_count,
        "unique_path_count": len(entries),
        "duplicate_path_count": len(duplicate_paths),
        "duplicate_paths": [
            pathlib.Path(path).relative_to(REPO_ROOT).as_posix()
            for path in duplicate_paths
        ],
        "all_frozen_entries_match_live_bytes": True,
        "entry_map_sha256": canonical_sha256(entries),
    }


def parse_report(path: pathlib.Path) -> list[dict[str, Any]]:
    """Parse both compact numeric headers and wrapped public-autoname headers."""
    lines = path.read_text(encoding="utf-8").splitlines()
    starts = [index for index, line in enumerate(lines)
              if line.startswith("Startpoint:")]
    require(len(starts) == 40,
            f"top-40 report must contain exactly 40 paths: {relative(path)}")
    starts.append(len(lines))
    paths: list[dict[str, Any]] = []
    for path_index in range(40):
        block = lines[starts[path_index]:starts[path_index + 1]]
        start_match = START_RE.match(block[0]) if block else None
        endpoint_matches = [END_RE.match(line) for line in block
                            if line.startswith("Endpoint:")]
        require(start_match is not None and len(endpoint_matches) == 1 and
                endpoint_matches[0] is not None,
                f"path {path_index} header is malformed")
        startpoint = start_match.group(1)
        endpoint = endpoint_matches[0].group(1)  # type: ignore[union-attr]
        slacks = [match.group(1) for line in block
                  if (match := timing_paths.SLACK_RE.match(line))]
        arrivals = [match.group(1) for line in block
                    if (match := timing_paths.ARRIVAL_RE.match(line))]
        require(len(slacks) == 1 and len(arrivals) == 1,
                f"path {path_index} timing footer is malformed")

        points: list[dict[str, str]] = []
        for line in block:
            match = timing_paths.POINT_RE.match(line)
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
        type_chain = [point["cell_type"] for point in combinational]
        raw_chain = [
            f'{point["instance"]}/{point["pin"]}:{point["cell_type"]}'
            for point in combinational
        ]
        paths.append({
            "index": path_index,
            "startpoint": startpoint,
            "endpoint": endpoint,
            "slack_ns": slacks[0],
            "arrival_ns": arrivals[0],
            "start_cell_type": points[q_indices[0]]["cell_type"],
            "endpoint_cell_type": points[d_indices[0]]["cell_type"],
            "combinational": combinational,
            "type_chain": type_chain,
            "raw_chain": raw_chain,
            "type_chain_sha256": canonical_sha256(type_chain),
            "raw_chain_sha256": canonical_sha256(raw_chain),
        })
    return paths


def traceable_mapping(paths: list[dict[str, Any]]) -> dict[str, Any]:
    starts = sorted({path["startpoint"] for path in paths})
    endpoints = sorted({path["endpoint"] for path in paths})
    require(len(starts) == 1 and len(endpoints) == 40,
            "traceable report launch/capture cardinality mismatch")
    require(NAME_RE.fullmatch(starts[0]) is not None and "/" not in starts[0],
            "traceable launch name is not underscore-encoded public autoname")
    require(starts[0].startswith(LAUNCH_PREFIX) and
            starts[0].endswith(MAPPED_DFF_SUFFIX),
            "traceable launch hierarchy/register prefix mismatch")
    for endpoint in endpoints:
        require(NAME_RE.fullmatch(endpoint) is not None and "/" not in endpoint,
                "traceable capture name is not underscore-encoded public autoname")
        require(endpoint.startswith(CAPTURE_PREFIX) and
                endpoint.endswith(MAPPED_DFF_SUFFIX),
                "traceable capture hierarchy prefix mismatch")
    alias_counts = {
        "jalr_prefetch_hit_available_i": sum(
            "jalr_prefetch_hit_available_i" in value for value in endpoints),
        "redirect_valid_i": sum("redirect_valid_i" in value for value in endpoints),
    }
    require(alias_counts == {
        "jalr_prefetch_hit_available_i": 38,
        "redirect_valid_i": 2,
    }, "traceable capture alias-token census mismatch")
    require({path["start_cell_type"] for path in paths} == {"DFFQX1H7L"} and
            {path["endpoint_cell_type"] for path in paths} == {"DFFQX1H7L"},
            "traceable launch/capture cell type mismatch")
    return {
        "status": "PASS_UNDERSCORE_ENCODED_PUBLIC_AUTONAME",
        "encoding": "yosys_rename_unescape_underscore_hierarchy",
        "slash_delimited_hierarchy_required": False,
        "launch": {
            "hierarchy": (
                "u_core/u_ooo_core/u_execute_backend/u_core_slice/"
                "u_decode_backend/u_int_backend/u_mem_owner_tracker"
            ),
            "module": "OooMemOwnerTracker",
            "register": "next_token_q[0]",
            "mapped_name": starts[0],
        },
        "capture": {
            "hierarchy": "u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding",
            "module": "OooFetchPcOutstandingSequencer",
            "endpoint_count": len(endpoints),
            "endpoint_name_set_sha256": canonical_sha256(endpoints),
            "alias_token_counts": alias_counts,
            "exact_rtl_register": None,
            "register_inference": "next_fetch_pc_q bank",
            "register_inference_status": "GAP_NOT_FORMALLY_MAPPED_PER_BIT",
        },
    }


def verify_path_analysis(path: pathlib.Path) -> tuple[dict[str, Any], dict[str, Any]]:
    actual = strict_json(path)
    require(actual.get("schema") == timing_paths.SCHEMA,
            "path-analysis schema mismatch")
    inputs = actual.get("inputs", {})
    input_paths = {
        label: verify_ref(inputs.get(label), f"path_analysis.{label}")
        for label in (
            "current_reference", "selector", "independent_review",
            "run1_top40", "run2_top40", "builder",
        )
    }
    try:
        expected = timing_paths.build_payload(
            input_paths["current_reference"], input_paths["selector"],
            input_paths["independent_review"], input_paths["run1_top40"],
            input_paths["run2_top40"],
        )
    except timing_paths.EvidenceError as error:
        raise ReplayError(f"path-analysis canonical rebuild failed: {error}") from error
    require(actual == expected, "path-analysis receipt differs from canonical rebuild")
    return actual, input_paths


def verify_named_summary(path: pathlib.Path, named_top40: pathlib.Path) -> dict[str, Any]:
    value = strict_json(path)
    require(value.get("schema") == "npc-rv64-v15p-mapped-sta-variant-v1" and
            value.get("status") == "PASS" and value.get("mode") == "candidate" and
            value.get("period_ns") == 5.0,
            "named synthesis/STA summary boundary mismatch")
    artifacts = value.get("artifacts", {})
    artifact_paths = {
        label: verify_artifact_ref(artifacts.get(label), f"named_summary.{label}")
        for label in ("complete", "console", "power", "setup", "top40")
    }
    require(artifact_paths["top40"] == named_top40,
            "named summary top-40 path mismatch")
    verify_artifact_ref(value.get("source_manifest"), "named_summary.source_manifest")
    synthesis = value.get("synthesis", {})
    for label in ("sta_export_check", "sta_netlist_compatibility",
                  "synth_check", "synth_stat"):
        verify_artifact_ref(synthesis.get(label), f"named_summary.synthesis.{label}")
    inputs = value.get("inputs", {})
    for label in ("manifest", "opensta_binary", "parameters", "std_lib"):
        verify_artifact_ref(inputs.get(label), f"named_summary.inputs.{label}")
    complete = parse_key_values(artifact_paths["complete"], {
        "status", "mode", "period_ns", "top", "clock_port", "clock_name",
        "netlist", "netlist_sha256", "std_lib", "macro_lib_count",
        "input_manifest_sha256", "parameters_sha256", "opensta_binary",
        "opensta_binary_sha256",
    })
    require(complete["status"] == "COMPLETE" and complete["mode"] == "candidate" and
            complete["period_ns"] == "5.0" and complete["top"] == "NpcTop" and
            complete["netlist_sha256"] == value.get("netlist", {}).get("sha256"),
            "OpenSTA completion marker mismatch")
    return value


def timing_projection(value: dict[str, Any]) -> dict[str, Any]:
    return {
        "actual_synthesis_source_sha256": value.get("actual_synthesis_source_sha256"),
        "mode": value.get("mode"),
        "period_ns": value.get("period_ns"),
        "synthesis_area": value.get("synthesis", {}).get("area"),
        "synthesis_check_problems": value.get("synthesis", {}).get("check_problems"),
        "timing": value.get("timing"),
        "power": value.get("power"),
        "setup_warning_closure": value.get("setup_warning_closure"),
    }


def path_equivalence(
        numeric_paths: list[dict[str, Any]],
        named_paths: list[dict[str, Any]]) -> dict[str, Any]:
    require(len(numeric_paths) == len(named_paths) == 40,
            "numeric/named path count mismatch")
    numeric_signature = [
        (path["slack_ns"], path["arrival_ns"], path["start_cell_type"],
         path["endpoint_cell_type"], path["type_chain"])
        for path in numeric_paths
    ]
    named_signature = [
        (path["slack_ns"], path["arrival_ns"], path["start_cell_type"],
         path["endpoint_cell_type"], path["type_chain"])
        for path in named_paths
    ]
    require(numeric_signature == named_signature,
            "numeric and named timing/cell-type path signatures differ")
    counts = sorted({len(path["type_chain"]) for path in named_paths})
    require(counts == [263], "named path combinational cell count drifted")
    chain_hashes = {path["type_chain_sha256"] for path in named_paths}
    require(len(chain_hashes) == 1,
            "named report no longer has one shared cell-type path family")
    slack_histogram = dict(sorted(collections.Counter(
        path["slack_ns"] for path in named_paths).items(),
        key=lambda item: float(item[0])))
    arrival_histogram = dict(sorted(collections.Counter(
        path["arrival_ns"] for path in named_paths).items(),
        key=lambda item: float(item[0])))
    return {
        "status": "PASS_EXACT_TIMING_AND_CELL_TYPE_CHAIN",
        "path_count": 40,
        "combinational_cells_per_path": 263,
        "cell_type_chain_family_count": 1,
        "cell_type_chain_sha256": next(iter(chain_hashes)),
        "slack_histogram_ns": slack_histogram,
        "arrival_histogram_ns": arrival_histogram,
        "numeric_named_timing_order_identical": True,
        "numeric_named_cell_type_chain_identical": True,
    }


def verify_rtl_markers(paths: dict[str, pathlib.Path]) -> None:
    owner = paths["owner_tracker"].read_text(encoding="utf-8")
    backend = paths["int_backend"].read_text(encoding="utf-8")
    sequencer = paths["fetch_sequencer"].read_text(encoding="utf-8")
    frontend = paths["frontend"].read_text(encoding="utf-8")
    require("reg [TOKEN_W-1:0] next_token_q;" in owner,
            "next_token_q declaration is missing")
    require("OooMemOwnerTracker" in backend and "u_mem_owner_tracker" in backend,
            "owner-tracker hierarchy marker is missing")
    require("reg [`XLEN-1:0] next_fetch_pc_q;" in sequencer,
            "next_fetch_pc_q declaration is missing")
    require("OooFetchPcOutstandingSequencer u_fetch_pc_outstanding" in frontend,
            "fetch-PC sequencer hierarchy marker is missing")


def build_payload(trace_run: pathlib.Path, path_analysis_path: pathlib.Path) -> dict[str, Any]:
    trace_run = resolve_workspace_dir(trace_run)
    require(relative(trace_run) == TRACE_RUN_REL,
            "checker replay only accepts the frozen V15R trace run")
    evidence = resolve_workspace_dir(trace_run / "evidence/traceable-names-a1")
    status_path = resolve_workspace_file(trace_run / "traceable-names-a1.status")
    driver_path = resolve_workspace_file(trace_run / "driver/run-traceable-names-a1.sh")
    command_status_path = resolve_workspace_file(evidence / "command-status.txt")
    old_traceability_path = resolve_workspace_file(evidence / "traceability.txt")
    named_summary_path = resolve_workspace_file(evidence / "summary.json")
    named_top40_path = resolve_workspace_file(evidence / "opensta-top40.rpt")
    manifest_path = resolve_workspace_file(evidence / "production-manifest-before.sha256")
    synthesis_sources_path = resolve_workspace_file(evidence / "synthesis-sources.sha256")
    parameters_path = resolve_workspace_file(evidence / "parameters.txt")
    netlist_hash_path = resolve_workspace_file(evidence / "netlist.sha256")
    netlist_size_path = resolve_workspace_file(evidence / "netlist.size")
    frozen_paths = {
        "status": status_path,
        "driver": driver_path,
        "command_status": command_status_path,
        "old_traceability": old_traceability_path,
        "named_summary": named_summary_path,
        "named_top40": named_top40_path,
        "production_manifest_before": manifest_path,
        "synthesis_sources": synthesis_sources_path,
        "parameters": parameters_path,
        "netlist_hash_record": netlist_hash_path,
        "netlist_size_record": netlist_size_path,
    }
    for label, path in frozen_paths.items():
        require_frozen(path, label)

    original_status = parse_original_status(status_path)
    command_status = parse_key_values(command_status_path, {
        "preflight_rc", "manifest_rc", "synth_rc", "opensta_rc", "parser_rc",
        "trace_rc", "cleanup_rc", "runtime_bytes_deleted",
    })
    require(command_status == {
        "preflight_rc": "0", "manifest_rc": "0", "synth_rc": "0",
        "opensta_rc": "0", "parser_rc": "0", "trace_rc": "1",
        "cleanup_rc": "0", "runtime_bytes_deleted": "0",
    }, "original command-status boundary mismatch")
    old_traceability = parse_key_values(old_traceability_path, {
        "status", "startpoints", "endpoints", "hierarchical_startpoints",
        "hierarchical_endpoints",
    })
    require(old_traceability == {
        "status": "FAIL", "startpoints": "40", "endpoints": "40",
        "hierarchical_startpoints": "0", "hierarchical_endpoints": "0",
    }, "old slash-delimited traceability oracle boundary mismatch")
    require(not (evidence / "production-manifest-after.sha256").exists() and
            not (evidence / "cleanup.txt").exists(),
            "original early oracle failure boundary was rewritten")
    runtime_path = REPO_ROOT / RUNTIME_REL
    require(not runtime_path.exists(), "traceable synthesis runtime still exists")

    path_analysis_path = resolve_workspace_file(path_analysis_path)
    path_analysis, analysis_inputs = verify_path_analysis(path_analysis_path)
    require(path_analysis.get("design_id") == EXPECTED_DESIGN_ID,
            "path-analysis design-id mismatch")
    current_reference_path = analysis_inputs["current_reference"]
    current_reference = strict_json(current_reference_path)
    require(current_reference.get("design_id") == EXPECTED_DESIGN_ID and
            current_reference.get("status") ==
            timing_paths.EXPECTED_REFERENCE_STATUS,
            "current-reference identity/status mismatch")
    reference_inputs = current_reference.get("inputs", {})
    numeric_summary_path = verify_ref(reference_inputs.get("run2_summary"),
                                      "current_reference.run2_summary")
    numeric_summary = strict_json(numeric_summary_path)
    numeric_top40_path = verify_artifact_ref(
        numeric_summary.get("artifacts", {}).get("top40"),
        "numeric_summary.top40")
    require(numeric_top40_path == analysis_inputs["run2_top40"],
            "numeric report differs from path-analysis input")

    named_summary = verify_named_summary(named_summary_path, named_top40_path)
    require(timing_projection(named_summary) == timing_projection(numeric_summary),
            "named diagnostic synthesis/STA projection differs from numeric reference")
    require(named_summary.get("source_manifest", {}).get("sha256") ==
            current_reference.get("repeatability", {}).get("source_manifest_sha256") ==
            FROZEN_SHA256["synthesis_sources"],
            "synthesis source-manifest identity mismatch")
    require(named_summary.get("netlist", {}).get("sha256") !=
            current_reference.get("repeatability", {}).get("netlist_sha256"),
            "diagnostic autoname netlist unexpectedly equals numeric netlist")

    design_hex, rtl_entries = architecture.rtl_binding(REPO_ROOT)
    design_id = f"sha256:{design_hex}"
    require(design_id == EXPECTED_DESIGN_ID == current_reference.get("design_id"),
            "live production RTL design-id drifted")
    synth_sources = named_summary.get("actual_synthesis_source_sha256")
    require(isinstance(synth_sources, dict) and len(synth_sources) == 127,
            "actual synthesis source map cardinality drifted")
    require(all(rtl_entries.get(path) == digest
                for path, digest in synth_sources.items()),
            "actual synthesis source map differs from live RTL")

    manifest_entries, manifest_line_count, duplicate_paths = parse_manifest(
        manifest_path)
    manifest_replay = verify_manifest_live(
        manifest_entries, manifest_line_count, duplicate_paths)
    named_paths = parse_report(named_top40_path)
    numeric_paths = parse_report(numeric_top40_path)
    mapping = traceable_mapping(named_paths)
    equivalence = path_equivalence(numeric_paths, named_paths)

    rtl_paths = {
        "owner_tracker": resolve_workspace_file(
            "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"),
        "int_backend": resolve_workspace_file(
            "npc/rv64/vsrc/execute/OooIntBackend.v"),
        "fetch_sequencer": resolve_workspace_file(
            "npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v"),
        "frontend": resolve_workspace_file(
            "npc/rv64/vsrc/frontend/OooFrontend.v"),
    }
    verify_rtl_markers(rtl_paths)
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "marker": PASS_MARKER,
        "design_id": design_id,
        "configuration": {
            "top": "NpcTop",
            "period_ns": 5.0,
            "frequency_mhz": 200.0,
            "timing_tier": "rtl_proxy_partial_constraints",
            "public_autoname": True,
            "dff_autoname": False,
        },
        "original_execution": {
            **original_status,
            "run_directory": relative(trace_run),
            "eda_stage_rc": {
                "preflight": 0,
                "production_manifest_before": 0,
                "mapped_synthesis": 0,
                "opensta_exact_5ns": 0,
                "evidence_parser": 0,
                "old_traceability_oracle": 1,
            },
            "original_status_preserved": True,
            "original_post_manifest_present": False,
            "original_explicit_cleanup_receipt_present": False,
        },
        "checker_replay": {
            "status": "PASS",
            "eda_rerun": False,
            "frozen_input_replay": True,
            "runtime_absent": True,
            "live_post_manifest_replay": manifest_replay,
            "old_oracle_root_cause": (
                "The original checker required '/' in Startpoint/Endpoint names, "
                "while Yosys rename -unescape emitted the exact hierarchy as "
                "underscore-encoded public autonames."
            ),
        },
        "path_equivalence": equivalence,
        "rtl_traceability": mapping,
        "ppa_observation": {
            "area": current_reference.get("area"),
            "timing": current_reference.get("timing"),
            "power": current_reference.get("power"),
            "named_netlist_sha256": named_summary.get("netlist", {}).get("sha256"),
            "named_netlist_size_bytes": named_summary.get("netlist", {}).get("size_bytes"),
            "numeric_reference_netlist_sha256":
                current_reference.get("repeatability", {}).get("netlist_sha256"),
            "named_netlist_not_retained": True,
        },
        "inputs": {
            "path_analysis": file_ref(path_analysis_path),
            "current_reference": file_ref(current_reference_path),
            "numeric_summary": file_ref(numeric_summary_path),
            "numeric_top40": file_ref(numeric_top40_path),
            "original_status": file_ref(status_path),
            "original_driver": file_ref(driver_path),
            "command_status": file_ref(command_status_path),
            "old_traceability": file_ref(old_traceability_path),
            "named_summary": file_ref(named_summary_path),
            "named_top40": file_ref(named_top40_path),
            "production_manifest_before": file_ref(manifest_path),
            "synthesis_sources": file_ref(synthesis_sources_path),
            "parameters": file_ref(parameters_path),
            "netlist_hash_record": file_ref(netlist_hash_path),
            "netlist_size_record": file_ref(netlist_size_path),
            "builder": file_ref(pathlib.Path(__file__)),
            "numeric_path_parser": file_ref(pathlib.Path(timing_paths.__file__)),
            "rtl_identity_builder": file_ref(pathlib.Path(architecture.__file__)),
            "rtl_sources": {label: file_ref(path) for label, path in rtl_paths.items()},
        },
        "candidate_decision": {
            "status": "GAP_SAFE_RTL_CUT_NOT_YET_PROVEN",
            "launch_owner_resolved": True,
            "capture_module_resolved": True,
            "capture_register_exactly_resolved": False,
            "production_rtl_change_authorized": False,
            "accepted_ppa_reference_available": False,
            "canonical_baseline_eligible": False,
            "promotion_eligible": False,
            "ppa": "UNQUALIFIED",
        },
        "claim_boundary": {
            "original_fail_not_rewritten": True,
            "checker_replay_is_not_eda_execution": True,
            "named_run_is_diagnostic_not_canonical_ppa": True,
            "alias_tokens_are_not_claimed_as_causal_rtl_dependencies": True,
            "production_rtl_unchanged": True,
            "ubuntu_full_system_not_run": True,
        },
        "next_action": "analyze.global-quiescence-dispatch-frontend-path",
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


def output_path(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved_parent = path.parent.resolve()
    try:
        resolved_parent.relative_to(REPO_ROOT)
    except ValueError as error:
        raise ReplayError("output path escapes repository") from error
    require(not path.exists() or (path.is_file() and not path.is_symlink()),
            "output exists but is not a regular non-symlink file")
    return resolved_parent / path.name


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    build = subparsers.add_parser("build")
    build.add_argument("--trace-run", default=TRACE_RUN_REL)
    build.add_argument("--path-analysis", default=PATH_ANALYSIS_REL)
    build.add_argument("--output", required=True)
    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            value = build_payload(pathlib.Path(args.trace_run),
                                  pathlib.Path(args.path_analysis))
            atomic_write_json(output_path(args.output), value)
        else:
            receipt_path = resolve_workspace_file(args.input)
            actual = strict_json(receipt_path)
            require(actual.get("schema") == SCHEMA,
                    "checker-replay receipt schema mismatch")
            inputs = actual.get("inputs", {})
            for label in (
                    "path_analysis", "current_reference", "numeric_summary",
                    "numeric_top40", "original_status", "original_driver",
                    "command_status", "old_traceability", "named_summary",
                    "named_top40", "production_manifest_before",
                    "synthesis_sources", "parameters", "netlist_hash_record",
                    "netlist_size_record", "builder", "numeric_path_parser",
                    "rtl_identity_builder"):
                verify_ref(inputs.get(label), label)
            rtl_sources = inputs.get("rtl_sources", {})
            require(set(rtl_sources) == {
                "owner_tracker", "int_backend", "fetch_sequencer", "frontend",
            }, "RTL source reference set mismatch")
            for label, value in rtl_sources.items():
                verify_ref(value, f"rtl_sources.{label}")
            expected = build_payload(
                pathlib.Path(actual.get("original_execution", {}).get(
                    "run_directory", "")),
                pathlib.Path(inputs["path_analysis"]["path"]),
            )
            require(actual == expected,
                    "checker-replay receipt differs from canonical rebuild")
            value = actual
        print(
            f"{PASS_MARKER} design_id={value['design_id']} "
            "original_status=FAIL eda_rerun=false paths=40 "
            "launch=OooMemOwnerTracker.next_token_q[0] "
            "capture=OooFetchPcOutstandingSequencer ppa=UNQUALIFIED "
            "production_rtl_authorized=false"
        )
        return 0
    except (
            ReplayError, timing_paths.EvidenceError, OSError, UnicodeError,
            KeyError, TypeError, ValueError) as error:
        print(f"[TRACEABLE-TIMING-CHECKER-REPLAY][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
