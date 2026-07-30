#!/usr/bin/env python3
"""Build a fail-closed producer/holder semantic coverage ledger.

The census proves field and elaborated-instance inventory only.  This tool
joins that inventory with heterogeneous directed evidence without turning a
partial or historical candidate into semantic completion.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter, defaultdict
from typing import Any


SCHEMA = "rv64-producer-holder-semantic-coverage-v1"
POLICY_SCHEMA = "rv64-producer-holder-semantic-coverage-policy-v1"
V11B_TERMINAL_COLLECTOR_UNIT_IDS = frozenset(
    {
        "terminal-output0-token",
        "terminal-output1-token",
        "terminal-pending-set",
    }
)
V11C_MEMORY_TRACKER_UNIT_IDS = frozenset(
    {
        "memory-tracker-producer-map",
        "memory-tracker-live-set",
    }
)
V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS = frozenset(
    {"tracker-next-token-cursor"}
)
V11E_ROB_SLOT_GENERATION_UNIT_IDS = frozenset(
    {"rob-slot-generation"}
)
V11F_INT_IQ_PRODUCER_UNIT_IDS = frozenset(
    {"integer-iq-producers"}
)
V11G_STORE_QUEUE_HOLDER_UNIT_IDS = frozenset(
    {
        "store-queue-producers",
        "store-queue-owner-tokens",
    }
)
V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS = frozenset(
    {"load-queue-producers"}
)
V11H_REPLAY_SCHEMA = "rv64-v11h-load-queue-attempt4-checker-replay-v1"
V11H_REPLAY_STATUS = (
    "FAIL rc=1 stage=semantic-ledger-unit "
    "evidence_complete=0 cleanup_rc=0"
)
CENSUS_SCHEMA = "rv64-producer-holder-census-v1"
INSTANCE_SCHEMA = "rv64-producer-holder-instance-graph-v1"
UNIT_COLLECTIONS = (
    "direct_full_p_fields",
    "packed_full_p_stages",
    "token_q_fields",
    "token_set_holders",
    "generation_authorities",
)
CURRENT_BINDINGS = {
    "CURRENT_FULL_RTL_BOUND",
    "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
}
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
V11_SELECTED_BINDINGS = {
    "v11b_terminal_collector": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_terminal_collector.sv",
            "testbench",
        ),
    },
    "v11c_memory_tracker": {
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_tracker_semantic_checker.sv",
            "testbench",
        ),
    },
    "v11d_memory_tracker_cursor": {
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_tracker_cursor.sv",
            "testbench",
        ),
    },
    "v11e_rob_slot_generation": {
        ("npc/rv64/vsrc/writeback/OooRob.v", "rtl"),
        ("npc/rv64/vsrc/writeback/OooArchRegFile.v", "rtl"),
        ("npc/rv64/vsrc/control/OooCsrTrapRequestMux.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        ("npc/rv64/vsrc/filelist.mk", "rtl"),
        ("npc/rv64/testbench/tests/tb_ooo_rob.sv", "testbench"),
    },
    "v11f_int_iq_producer": {
        ("npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "rtl"),
        ("npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        ("npc/rv64/vsrc/filelist.mk", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
            "testbench",
        ),
    },
    "v11g_store_queue_holder": {
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        ("npc/rv64/vsrc/filelist.mk", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
            "testbench",
        ),
    },
}
V11H_REPLAY_CURRENT_FILES = {
    "semantic_checker": (
        "npc/rv64/eval/ppa/tools/"
        "producer_holder_semantic_coverage.py"
    ),
    "semantic_checker_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_producer_holder_semantic_coverage.py"
    ),
    "semantic_policy": (
        "npc/rv64/design/arch/"
        "producer-holder-semantic-coverage-policy.json"
    ),
    "load_queue_evidence_checker": (
        "npc/rv64/eval/ppa/tools/"
        "load_queue_producer_semantic_evidence.py"
    ),
    "load_queue_evidence_checker_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_load_queue_producer_semantic_evidence.py"
    ),
    "checker_replay_builder": (
        "npc/rv64/eval/ppa/tools/"
        "load_queue_producer_checker_replay.py"
    ),
    "checker_replay_builder_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_load_queue_producer_checker_replay.py"
    ),
    "checker_replay_runner": (
        ".github/task-runs/2026-07-30-rv64-v11h-"
        "load-queue-producer-semantic-coverage/"
        "run-attempt-4-checker-replay.sh"
    ),
    "producer_holder_census": (
        "npc/rv64/design/arch/producer-holder-census.json"
    ),
    "current_instance_graph_result": (
        ".github/task-runs/2026-07-30-rv64-v11h-"
        "load-queue-producer-semantic-coverage/evidence/"
        "current-instance-graph-v2/holder-instance-graph.json"
    ),
    "current_instance_graph_receipt": (
        ".github/task-runs/2026-07-30-rv64-v11h-"
        "load-queue-producer-semantic-coverage/evidence/"
        "current-instance-graph-v2/yosys-instance-graph-receipt.json"
    ),
    "current_instance_graph_status": (
        ".github/task-runs/2026-07-30-rv64-v11h-"
        "load-queue-producer-semantic-coverage/"
        "v11h-current-instance-graph-v2.status"
    ),
}


class CoverageError(RuntimeError):
    """Raised when an evidence or inventory contract is not auditable."""


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CoverageError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise CoverageError(f"JSON root must be an object: {path}")
    return payload


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(root).as_posix()
    except ValueError as exc:
        raise CoverageError(f"path escapes repository root: {path}") from exc


def resolve_repo_path(root: pathlib.Path, value: str) -> pathlib.Path:
    if not isinstance(value, str) or not value:
        raise CoverageError("repository path must be a non-empty string")
    path = (root / value).resolve()
    relative(root, path)
    return path


def artifact(root: pathlib.Path, value: str) -> dict[str, Any]:
    path = resolve_repo_path(root, value)
    if not path.is_file():
        raise CoverageError(f"evidence artifact is missing: {value}")
    return {
        "path": relative(root, path),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def current_design_id(root: pathlib.Path) -> str:
    tools = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def validate_snapshot(
    root: pathlib.Path,
    payload: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    if payload.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1":
        raise CoverageError("V8L RTL snapshot schema mismatch")
    if payload.get("design_id") != expected_design_id:
        raise CoverageError("V8L RTL snapshot design-id is stale")
    rtl_files = payload.get("rtl_files")
    if not isinstance(rtl_files, dict) or not rtl_files:
        raise CoverageError("V8L RTL snapshot has no source records")
    mismatches: list[str] = []
    for value, expected in sorted(rtl_files.items()):
        path = resolve_repo_path(root, value)
        if not path.is_file() or sha256_file(path) != expected:
            mismatches.append(value)
    return mismatches


def valid_design_id(value: Any) -> bool:
    return isinstance(value, str) and DESIGN_ID_RE.fullmatch(value) is not None


def parse_key_value_log(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def evaluate_v8l(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    pre_path = resolve_repo_path(root, spec["snapshot_pre"])
    post_path = resolve_repo_path(root, spec["snapshot_post"])
    lifecycle_path = resolve_repo_path(root, spec["lifecycle_log"])
    mutation_path = resolve_repo_path(root, spec["mutation_summary"])
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V8L pre/post full RTL snapshots differ")
    evidence_design_id = pre.get("design_id")
    if not valid_design_id(evidence_design_id):
        raise CoverageError("V8L evidence design-id is malformed")
    mismatches = validate_snapshot(root, pre, evidence_design_id)
    lifecycle = parse_key_value_log(lifecycle_path)
    required_lines = {
        "V8L-INTIQ-DEATH-EDGE PASS",
        "V8L-FINITE-GENERATION-WRAP PASS",
        "V8L-TRANSIENT-HOLDER-CENSUS PASS",
        "V8L-MEM-HANDOFF-BACKPRESSURE PASS",
        "V8L-MEM-INDIRECT-TRACKER PASS",
    }
    lifecycle_lines = set(
        lifecycle_path.read_text(encoding="utf-8").splitlines()
    )
    missing_markers = sorted(required_lines - lifecycle_lines)
    mutation = load_json(mutation_path)
    mutation_ok = (
        mutation.get("design_id") == evidence_design_id
        and mutation.get("compile_success") == 9
        and mutation.get("rejected") == 9
        and len(mutation.get("mutations", [])) == 9
        and all(
            item.get("compiled") is True and item.get("rejected") is True
            for item in mutation.get("mutations", [])
            if isinstance(item, dict)
        )
    )
    if (
        missing_markers
        or lifecycle.get("design_id") != evidence_design_id
        or lifecycle.get("source_binding_status") != "PASS"
        or not mutation_ok
    ):
        raise CoverageError(
            "V8L current evidence failed provenance validation: "
            f"rtl_mismatches={mismatches} missing_markers={missing_markers} "
            f"mutation_ok={mutation_ok}"
        )
    artifacts = [
        artifact(root, spec["snapshot_pre"]),
        artifact(root, spec["snapshot_post"]),
        artifact(root, spec["lifecycle_log"]),
        artifact(root, spec["mutation_summary"]),
    ]
    detail = {
        "rtl_file_count": len(pre["rtl_files"]),
        "marker_count": len(required_lines),
        "compile_success_mutations": 9,
        "rejected_mutations": 9,
        "evidence_design_id": evidence_design_id,
        "current_design_id": design_id,
        "live_rtl_mismatches": mismatches,
    }
    state = (
        "CURRENT_FULL_RTL_BOUND"
        if evidence_design_id == design_id and not mismatches
        else "HISTORICAL_FULL_RTL_BOUND"
    )
    return state, artifacts, detail


def evaluate_v9r(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    if not isinstance(source_binding, dict):
        raise CoverageError("V9R summary lacks source binding")
    files = source_binding.get("files")
    if not isinstance(files, dict) or not files:
        raise CoverageError("V9R source binding has no files")
    mismatches: list[str] = []
    for key, record in sorted(files.items()):
        if not isinstance(record, dict) or record.get("path") != key:
            raise CoverageError(f"V9R malformed source record: {key}")
        path = resolve_repo_path(root, key)
        if (
            not path.is_file()
            or sha256_file(path) != record.get("sha256")
            or path.stat().st_size != record.get("size_bytes")
        ):
            mismatches.append(key)
    variants = payload.get("compile_success_rtl_variants")
    baseline = payload.get("baseline")
    result_ok = (
        payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and isinstance(baseline, dict)
        and baseline.get("required") == 2
        and baseline.get("passed") == 2
        and isinstance(variants, list)
        and len(variants) == 3
        and all(item.get("result") == "REJECTED" for item in variants)
    )
    if not result_ok:
        raise CoverageError(
            "V9R current evidence failed provenance validation: "
            f"mismatches={mismatches} result_ok={result_ok}"
        )
    state = (
        "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"
        if not mismatches
        else "HISTORICAL_SELECTED_SOURCE_BOUND"
    )
    return (
        state,
        [artifact(root, spec["summary"])],
        {
            "source_file_count": len(files),
            "baseline_passed": 2,
            "compile_success_variants_rejected": 3,
            "evidence_design_id": payload.get("design_id"),
            "current_design_id": design_id,
            "live_source_mismatches": mismatches,
        },
    )


def parse_sha_manifest(
    root: pathlib.Path, path: pathlib.Path
) -> dict[str, str]:
    result: dict[str, str] = {}
    for lineno, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        if not line.strip():
            continue
        try:
            digest, raw_path = line.split(None, 1)
        except ValueError as exc:
            raise CoverageError(
                f"malformed sha256 manifest line {path}:{lineno}"
            ) from exc
        candidate = pathlib.Path(raw_path.strip())
        if not candidate.is_absolute():
            candidate = root / candidate
        key = relative(root, candidate)
        if key in result:
            raise CoverageError(f"duplicate sha256 manifest path: {key}")
        result[key] = digest
    return result


def classify_binding_records(
    records: list[dict[str, Any]],
) -> str:
    rtl = [record for record in records if record["role"] == "rtl"]
    non_rtl = [record for record in records if record["role"] != "rtl"]
    rtl_match = all(record["matches_live"] for record in rtl)
    non_rtl_match = all(record["matches_live"] for record in non_rtl)
    if not rtl_match:
        return "STALE_RTL_SOURCE"
    if not non_rtl_match:
        return "RTL_SOURCE_MATCH_TESTBENCH_DRIFT"
    return "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"


def evaluate_sha_manifest(
    root: pathlib.Path,
    spec: dict[str, Any],
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    pre_path = resolve_repo_path(root, spec["manifest_pre"])
    post_path = resolve_repo_path(root, spec["manifest_post"])
    pre = parse_sha_manifest(root, pre_path)
    post = parse_sha_manifest(root, post_path)
    if pre != post:
        raise CoverageError(
            f"historical pre/post source manifests differ: {spec['id']}"
        )
    records: list[dict[str, Any]] = []
    for binding in spec.get("required_bindings", []):
        value = binding.get("path")
        role = binding.get("role")
        if role not in {"rtl", "testbench", "tool", "spec"}:
            raise CoverageError(f"unsupported evidence binding role: {role}")
        path = resolve_repo_path(root, value)
        if value not in pre:
            raise CoverageError(
                f"required path missing from evidence manifest: {value}"
            )
        live = sha256_file(path) if path.is_file() else None
        records.append(
            {
                "path": value,
                "role": role,
                "evidence_sha256": pre[value],
                "live_sha256": live,
                "matches_live": live == pre[value],
            }
        )
    state = classify_binding_records(records)
    return (
        state,
        [artifact(root, spec["manifest_pre"]),
         artifact(root, spec["manifest_post"])],
        {"bindings": records},
    )


def json_value(payload: dict[str, Any], segments: list[str]) -> Any:
    value: Any = payload
    for segment in segments:
        if not isinstance(value, dict) or segment not in value:
            raise CoverageError(
                f"JSON binding path does not exist: {segments}"
            )
        value = value[segment]
    return value


def evaluate_json_declared(
    root: pathlib.Path,
    spec: dict[str, Any],
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    records: list[dict[str, Any]] = []
    for binding in spec.get("required_bindings", []):
        value = binding.get("path")
        role = binding.get("role")
        segments = binding.get("json_path")
        if not isinstance(segments, list) or not all(
            isinstance(segment, str) for segment in segments
        ):
            raise CoverageError("json_path must be a list of strings")
        expected = json_value(payload, segments)
        path = resolve_repo_path(root, value)
        live = sha256_file(path) if path.is_file() else None
        records.append(
            {
                "path": value,
                "role": role,
                "evidence_sha256": expected,
                "live_sha256": live,
                "matches_live": live == expected,
            }
        )
    state = classify_binding_records(records)
    return (
        state,
        [artifact(root, spec["summary"])],
        {"bindings": records},
    )


def verify_artifact_record(
    root: pathlib.Path, record: Any, label: str
) -> pathlib.Path:
    if not isinstance(record, dict):
        raise CoverageError(f"{label} artifact record is not an object")
    value = record.get("path")
    path = resolve_repo_path(root, value)
    if (
        not path.is_file()
        or sha256_file(path) != record.get("sha256")
        or path.stat().st_size != record.get("size_bytes")
    ):
        raise CoverageError(f"{label} artifact hash/size mismatch")
    return path


def validate_current_selected_binding(
    root: pathlib.Path,
    spec: dict[str, Any],
    snapshot: dict[str, Any],
    evidence_design_id: str,
    current_design_id_value: str,
    manifest_pre_path: pathlib.Path,
    manifest_post_path: pathlib.Path,
) -> tuple[str, list[dict[str, Any]]]:
    kind = spec.get("binding_kind")
    expected = V11_SELECTED_BINDINGS.get(kind)
    if expected is None:
        raise CoverageError(
            f"selected-source compatibility is unsupported for {kind}"
        )
    declared = spec.get("current_selected_bindings")
    if not isinstance(declared, list):
        raise CoverageError(
            f"{kind} current_selected_bindings must be a list"
        )
    normalized: set[tuple[str, str]] = set()
    for index, binding in enumerate(declared):
        if not isinstance(binding, dict) or set(binding) != {"path", "role"}:
            raise CoverageError(
                f"{kind} selected binding {index} must contain path/role"
            )
        path_value = binding.get("path")
        role = binding.get("role")
        if (
            not isinstance(path_value, str)
            or role not in {"rtl", "testbench"}
            or (path_value, role) in normalized
        ):
            raise CoverageError(
                f"{kind} selected binding {index} is invalid or duplicated"
            )
        normalized.add((path_value, role))
    if normalized != expected:
        raise CoverageError(
            f"{kind} current selected RTL/TB binding set is incomplete"
        )

    if snapshot.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1":
        raise CoverageError(f"{kind} full RTL snapshot schema mismatch")
    if snapshot.get("design_id") != evidence_design_id:
        raise CoverageError(
            f"{kind} summary and full RTL snapshot design-id differ"
        )
    snapshot_files = snapshot.get("rtl_files")
    if not isinstance(snapshot_files, dict) or not snapshot_files:
        raise CoverageError(f"{kind} full RTL snapshot has no source records")

    manifest_pre = parse_sha_manifest(root, manifest_pre_path)
    manifest_post = parse_sha_manifest(root, manifest_post_path)
    if manifest_pre != manifest_post:
        raise CoverageError(f"{kind} focused pre/post manifests differ")

    records: list[dict[str, Any]] = []
    for path_value, role in sorted(expected):
        if path_value not in manifest_pre:
            raise CoverageError(
                f"{kind} selected path is missing from focused manifest: "
                f"{path_value}"
            )
        evidence_sha = manifest_pre[path_value]
        if (
            path_value in snapshot_files
            and snapshot_files[path_value] != evidence_sha
        ):
            raise CoverageError(
                f"{kind} selected RTL hash differs between focused and "
                f"full-snapshot evidence: {path_value}"
            )
        live_path = resolve_repo_path(root, path_value)
        live_sha = sha256_file(live_path) if live_path.is_file() else None
        records.append(
            {
                "path": path_value,
                "role": role,
                "evidence_sha256": evidence_sha,
                "live_sha256": live_sha,
                "matches_live": live_sha == evidence_sha,
            }
        )

    selected_state = classify_binding_records(records)
    if evidence_design_id == current_design_id_value:
        mismatches = validate_snapshot(
            root, snapshot, current_design_id_value
        )
        if mismatches:
            raise CoverageError(
                f"{kind} current full RTL snapshot drift: {mismatches}"
            )
        return "CURRENT_FULL_RTL_BOUND", records
    if selected_state != "CURRENT_SELECTED_SOURCE_AND_TB_BOUND":
        raise CoverageError(
            f"{kind} selected RTL/TB source closure is stale: "
            f"{selected_state}"
        )
    return selected_state, records


def validate_v11h_checker_replay(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[dict[str, Any], dict[str, Any]]:
    receipt_value = spec.get("checker_replay_receipt")
    receipt_path = resolve_repo_path(root, receipt_value)
    receipt = load_json(receipt_path)
    expected_top_keys = {
        "schema",
        "status",
        "design_id",
        "current_design_id_at_replay",
        "original_design_is_current",
        "original_attempt",
        "original_failure",
        "frozen_simulation_evidence",
        "replacement_checker_sources",
        "replay_contract",
        "claim_boundary",
    }
    if (
        set(receipt) != expected_top_keys
        or receipt.get("schema") != V11H_REPLAY_SCHEMA
        or receipt.get("status") != "PASS"
        or receipt.get("design_id") != design_id
        or receipt.get("current_design_id_at_replay") != design_id
        or receipt.get("original_design_is_current") is not True
        or receipt.get("original_attempt") != 4
    ):
        raise CoverageError("V11H checker-replay receipt is incomplete")

    failure = receipt.get("original_failure")
    if (
        not isinstance(failure, dict)
        or set(failure)
        != {"stage", "status_line", "status_artifact", "semantic_log"}
        or failure.get("stage") != "semantic-ledger-unit"
        or failure.get("status_line") != V11H_REPLAY_STATUS
    ):
        raise CoverageError(
            "V11H checker replay does not preserve the original FAIL"
        )
    status_path = verify_artifact_record(
        root, failure.get("status_artifact"), "V11H original status"
    )
    if status_path.read_text(encoding="utf-8").strip() != V11H_REPLAY_STATUS:
        raise CoverageError("V11H original attempt status was rewritten")
    semantic_log_path = verify_artifact_record(
        root, failure.get("semantic_log"), "V11H original semantic log"
    )
    semantic_log = semantic_log_path.read_text(encoding="utf-8")
    if (
        "NameError: name 'assertion_probe' is not defined"
        not in semantic_log
        or "FAILED (errors=4)" not in semantic_log
    ):
        raise CoverageError(
            "V11H original semantic-ledger failure reason drifted"
        )

    frozen = receipt.get("frozen_simulation_evidence")
    expected_frozen_keys = {
        "summary",
        "focused_sources_pre",
        "focused_sources_post",
        "full_rtl_pre",
        "full_rtl_post",
        "evidence_checker_unit_log",
        "positive_profiles",
        "raw_q_knownness_assertion_probes",
        "mutation_cases",
        "mutation_simulations",
    }
    if (
        not isinstance(frozen, dict)
        or set(frozen) != expected_frozen_keys
        or frozen.get("positive_profiles") != 4
        or frozen.get("raw_q_knownness_assertion_probes") != 1
        or frozen.get("mutation_cases") != 31
        or frozen.get("mutation_simulations") != 62
    ):
        raise CoverageError("V11H frozen checker-replay inputs are incomplete")
    summary_path = verify_artifact_record(
        root, frozen.get("summary"), "V11H frozen summary"
    )
    if relative(root, summary_path) != spec.get("summary"):
        raise CoverageError(
            "V11H checker replay is bound to a different RTL summary"
        )
    focused_pre = verify_artifact_record(
        root, frozen.get("focused_sources_pre"),
        "V11H frozen focused pre",
    )
    focused_post = verify_artifact_record(
        root, frozen.get("focused_sources_post"),
        "V11H frozen focused post",
    )
    rtl_pre = verify_artifact_record(
        root, frozen.get("full_rtl_pre"), "V11H frozen RTL pre"
    )
    rtl_post = verify_artifact_record(
        root, frozen.get("full_rtl_post"), "V11H frozen RTL post"
    )
    if (
        focused_pre.read_bytes() != focused_post.read_bytes()
        or rtl_pre.read_bytes() != rtl_post.read_bytes()
    ):
        raise CoverageError(
            "V11H checker replay pre/post source bindings differ"
        )
    verify_artifact_record(
        root,
        frozen.get("evidence_checker_unit_log"),
        "V11H frozen evidence-checker unit log",
    )

    checker_sources = receipt.get("replacement_checker_sources")
    if (
        not isinstance(checker_sources, dict)
        or set(checker_sources) != set(V11H_REPLAY_CURRENT_FILES)
    ):
        raise CoverageError(
            "V11H checker replay replacement source set is incomplete"
        )
    for name, expected_path in V11H_REPLAY_CURRENT_FILES.items():
        current_path = verify_artifact_record(
            root,
            checker_sources.get(name),
            f"V11H replacement checker {name}",
        )
        if relative(root, current_path) != expected_path:
            raise CoverageError(
                f"V11H replacement checker path drifted: {name}"
            )

    contract = receipt.get("replay_contract")
    expected_contract = {
        "original_fail_preserved": True,
        "rtl_simulation_reexecuted": False,
        "full_rtl_pre_post_identical": True,
        "focused_sources_pre_post_identical": True,
        "system_rerun_required_before_system_promotion": True,
        "system_rerun_executed": False,
        "replacement_checker_must_run_positive_and_negative_units": True,
    }
    if contract != expected_contract:
        raise CoverageError("V11H checker-replay contract was weakened")
    if not isinstance(receipt.get("claim_boundary"), str):
        raise CoverageError("V11H checker-replay claim boundary is missing")
    return artifact(root, receipt_value), {
        "status": "PASS",
        "original_attempt": 4,
        "original_fail_preserved": True,
        "rtl_simulation_reexecuted": False,
        "frozen_positive_profiles": 4,
        "frozen_raw_q_knownness_assertion_probes": 1,
        "frozen_mutation_simulations": 62,
        "system_rerun_required_before_system_promotion": True,
        "system_rerun_executed": False,
    }


def evaluate_v11b_terminal_collector(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    lane = payload.get("static_lane_contract")
    mutations = payload.get("compile_success_mutations")
    result_ok = (
        payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and payload.get("positive_profile_count") == 2
        and payload.get("mutation_count") == 3
        and payload.get("rejected_mutation_count") == 3
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(lane, dict)
        and lane.get("ingress_lanes") == 12
        and lane.get("tracker_free_lanes") == 2
        and lane.get("accepted_transfer_only") is True
        and lane.get("duplicate_ingress_merged") is False
        and isinstance(mutations, list)
        and len(mutations) == 3
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError("V11B terminal collector summary is not complete")
    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11B RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11B RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11B terminal collector RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11B runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11B runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    verify_artifact_record(
        root, lane.get("artifact"), "V11B lane contract"
    )
    for profile, record in payload.get("positive_profiles", {}).items():
        verify_artifact_record(root, record, f"V11B profile {profile}")
    verify_artifact_record(
        root, payload.get("raw_unknown_negative"), "V11B unknown negative"
    )
    for item in mutations:
        verify_artifact_record(
            root, item.get("receipt"), f"V11B {item.get('case')} receipt"
        )
        verify_artifact_record(
            root, item.get("log"), f"V11B {item.get('case')} log"
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11B {item.get('case')} image",
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "ingress_lanes": 12,
            "tracker_free_lanes": 2,
            "positive_profiles": 2,
            "compile_success_mutations_rejected": 3,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11c_memory_tracker(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    cycle = payload.get("cycle_contract")
    positives = payload.get("positive_profiles")
    negatives = payload.get("unknown_negatives")
    mutations = payload.get("compile_success_mutations")
    expected_negative_cases = {
        "alloc-pid-unknown",
        "release-mask-unknown",
        "live-map-unknown",
        "live-set-unknown",
    }
    expected_mutation_cases = {
        "live-mask-output-zero",
        "drop-live-birth",
        "drop-live-death",
        "wrong-producer-map-birth0",
        "drop-producer-live-birth",
        "wrong-producer-clear",
        "same-edge-exact-token-reuse",
        "same-edge-bulk-token-reuse",
        "allow-dual-duplicate-pid",
    }
    result_ok = (
        payload.get("schema_version")
        == "rv64-v11c-memory-tracker-semantic-evidence-v1"
        and payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", [])) == V11C_MEMORY_TRACKER_UNIT_IDS
        and payload.get("production_rtl_modified") is False
        and payload.get("positive_profile_count") == 2
        and payload.get("unknown_negative_count") == 4
        and payload.get("mutation_count") == 9
        and payload.get("rejected_mutation_count") == 9
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(cycle, dict)
        and cycle.get("allocation_scans_edge_old_live_set") is True
        and cycle.get("birth_and_death_are_disjoint") is True
        and cycle.get("exact_death_same_edge_reuse_rejected") is True
        and cycle.get("bulk_death_same_edge_reuse_rejected") is True
        and cycle.get("next_cycle_reuse_observed") is True
        and cycle.get("token_to_producer_map_checked_each_observed_edge")
        is True
        and cycle.get("next_token_cursor_closed") is False
        and isinstance(positives, dict)
        and set(positives) == {"assert", "release"}
        and isinstance(negatives, list)
        and {
            item.get("case") for item in negatives if isinstance(item, dict)
        }
        == expected_negative_cases
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in negatives
            if isinstance(item, dict)
        )
        and isinstance(mutations, list)
        and {
            item.get("case") for item in mutations if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError("V11C memory tracker summary is not complete")

    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11C RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11C RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11C memory tracker RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11C runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11C runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(root, record, f"V11C profile {profile}")
    for item in negatives:
        verify_artifact_record(
            root, item.get("log"), f"V11C negative {item.get('case')} log"
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11C negative {item.get('case')} image",
        )
    for item in mutations:
        verify_artifact_record(
            root,
            item.get("receipt"),
            f"V11C mutation {item.get('case')} receipt",
        )
        verify_artifact_record(
            root,
            item.get("log"),
            f"V11C mutation {item.get('case')} log",
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11C mutation {item.get('case')} image",
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 2,
            "unknown_negatives_rejected": 4,
            "compile_success_mutations_rejected": 9,
            "next_token_cursor_closed": False,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11d_memory_tracker_cursor(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    cycle = payload.get("cycle_contract")
    positives = payload.get("positive_profiles")
    mutations = payload.get("compile_success_mutations")
    expected_profiles = {
        "assert-t4": (4, True),
        "release-t4": (4, False),
        "assert-t32": (32, True),
        "release-t32": (32, False),
    }
    expected_mutation_cases = {
        "reset-to-one",
        "fixed-scan-base",
        "advance-step-two",
        "dual-advance-lane0",
        "advance-on-ready",
        "idle-increment",
        "lane1-does-not-exclude-lane0",
        "lane1-excludes-unclaimed-lane0",
        "truncate-scan-four",
    }
    cycle_keys = {
        "reference_model_uses_stimulus_and_edge_old_state",
        "dut_token_not_reused_as_expected_token",
        "lane0_only_checked",
        "lane1_only_checked",
        "dual_birth_last_lane_advance_checked",
        "blocked_lane_checked",
        "atomic_single_credit_zero_fire_hold_checked",
        "idle_and_full_hold_checked",
        "exact_and_bulk_death_edge_old_visibility_checked",
        "wraparound_checked",
        "production_32_token_full_scan_checked",
        "next_token_cursor_closed",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("token_count") == token_count
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (token_count, assertions_enabled)
            in expected_profiles.items()
        )
    )
    result_ok = (
        payload.get("schema_version")
        == "rv64-v11d-memory-tracker-cursor-semantic-evidence-v1"
        and payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS
        and payload.get("production_rtl_modified") is False
        and payload.get("positive_profile_count") == 4
        and payload.get("mutation_count") == 9
        and payload.get("rejected_mutation_count") == 9
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(cycle, dict)
        and all(cycle.get(key) is True for key in cycle_keys)
        and profile_shape_ok
        and isinstance(mutations, list)
        and {
            item.get("case") for item in mutations if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            item.get("token_count") == 32
            and item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            and isinstance(item.get("make_rc"), int)
            and item.get("make_rc") != 0
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError(
            "V11D memory tracker cursor summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11D RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11D RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11D memory tracker RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11D runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11D runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("log"), f"V11D profile {profile} log"
        )
        verify_artifact_record(
            root,
            record.get("compiled_image"),
            f"V11D profile {profile} image",
        )
    for item in mutations:
        label = f"V11D mutation {item.get('case')}"
        verify_artifact_record(root, item.get("receipt"), f"{label} receipt")
        verify_artifact_record(
            root, item.get("mutant_rtl"), f"{label} RTL"
        )
        verify_artifact_record(root, item.get("log"), f"{label} log")
        verify_artifact_record(
            root, item.get("compiled_image"), f"{label} image"
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "compile_success_mutations_rejected": 9,
            "token_counts": [4, 32],
            "next_token_cursor_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11e_rob_slot_generation(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "reset-seed-zero",
        "flush-resets-generation",
        "candidate-no-increment",
        "candidate-step-two",
        "lane1-uses-lane0-generation",
        "pair-uses-actual-lane1-slot",
        "lane0-write-on-valid",
        "lane1-write-lane0-slot",
        "commit-advances-generation",
        "recovery-resets-generation",
        "full-borrows-commit-slot",
        "head-carrier-zero-generation",
        "commit-carrier-zero-generation",
        "walk-carrier-zero-generation",
        "current-query-ignore-generation",
        "completion-query-ignore-generation",
        "resolve-query-ignore-generation",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11e-rob-slot-generation-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11E_ROB_SLOT_GENERATION_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("checks_every_edge") is True
        and oracle.get("checks_all_slots") is True
        and oracle.get("checks_all_generation_bits") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 17
        and counts.get("mutation_simulations") == 34
        and counts.get("rejected_mutation_simulations") == 34
    )
    if not result_ok:
        raise CoverageError(
            "V11E ROB slot-generation summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11E RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11E RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11E ROB slot-generation RTL snapshots differ")
    verify_artifact_record(
        root, production.get("rtl"), "V11E production ROB"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11E directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11E focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11E focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11E profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11E profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11E profile {profile} image",
        )
    for item in mutations:
        label = f"V11E mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 17,
            "mutation_simulations_rejected": 34,
            "rob_slot_generation_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11f_int_iq_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "dispatch0-generation-zero",
        "dispatch1-uses-lane0-pid",
        "compaction-uses-write-index-pid",
        "compaction-generation-zero",
        "issue0-generation-zero",
        "issue1-generation-zero",
        "issue0-raw-index-entry0",
        "issue1-raw-index-issue0",
        "issue0-fire-not-removed",
        "issue1-fire-not-removed",
        "pair-pop-only-entry0",
        "kill-boundary-inclusive",
        "flush-ignored",
        "reset-ignored",
        "regular-fire-dies-early-mask",
        "pair-fire-dies-early-mask",
        "mask-raw-rob-index",
        "dispatch0-pid-x",
        "dispatch1-pid-x",
        "compaction-pid-x",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11f-int-iq-producer-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11F_INT_IQ_PRODUCER_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_identity_knownness") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 20
        and counts.get("mutation_simulations") == 40
        and counts.get("rejected_mutation_simulations") == 40
    )
    if not result_ok:
        raise CoverageError(
            "V11F integer-IQ ProducerId summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11F RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11F RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError(
            "V11F integer-IQ ProducerId RTL snapshots differ"
        )
    verify_artifact_record(
        root, production.get("rtl"), "V11F production integer IQ"
    )
    verify_artifact_record(
        root, production.get("selector"), "V11F production IQ selector"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11F directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11F focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11F focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11F profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11F profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11F profile {profile} image",
        )
    for item in mutations:
        label = f"V11F mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 20,
            "mutation_simulations_rejected": 40,
            "raw_identity_knownness_closed": True,
            "integer_iq_producer_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11g_store_queue_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "alloc0-generation-zero",
        "alloc1-uses-alloc0-pid",
        "alloc0-pid-x",
        "alloc1-pid-x",
        "slot-reuse-keeps-old-pid",
        "request-full-pid-raw-only",
        "release-full-pid-raw-only",
        "request-clears-valid",
        "terminal-clears-valid",
        "release-keeps-valid",
        "flush-keeps-valid",
        "selective-kills-boundary",
        "global-kills-request-sent",
        "bind1-uses-bind0-tuple",
        "bind0-kind-x",
        "bind0-token-x",
        "bind0-epoch-x",
        "owner-valid-dies-on-request",
        "owner-valid-dies-on-terminal",
        "release-keeps-owner-valid",
        "flush-keeps-owner-valid",
        "release-mask-uses-rob-index",
        "bind-terminal-bypass-removed",
        "release-mask-bind-bypass-removed",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11g-store-queue-holder-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11G_STORE_QUEUE_HOLDER_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("stimulus_owned_four_entry_model") is True
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_producer_id_knownness") is True
        and oracle.get("checks_raw_owner_tuple_knownness") is True
        and oracle.get("uses_asymmetric_token_epoch") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 24
        and counts.get("mutation_simulations") == 48
        and counts.get("rejected_mutation_simulations") == 48
    )
    if not result_ok:
        raise CoverageError(
            "V11G StoreQueue holder summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11G RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11G RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11G StoreQueue holder RTL snapshots differ")
    verify_artifact_record(
        root, production.get("rtl"), "V11G production StoreQueue"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11G directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11G focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11G focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11G profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11G profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11G profile {profile} image",
        )
    for item in mutations:
        label = f"V11G mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 24,
            "mutation_simulations_rejected": 48,
            "raw_producer_identity_knownness_closed": True,
            "raw_owner_tuple_knownness_closed": True,
            "store_queue_producer_closed": True,
            "store_queue_owner_token_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11h_load_queue_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    pre_fix = payload.get("pre_fix_reproducer")
    root_cause = payload.get("root_cause")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    assertion_probe = payload.get("rtl_assertion_probe")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    scope = payload.get("scope")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "alloc0-generation-zero",
        "alloc1-uses-alloc0-pid",
        "alloc0-pid-x",
        "alloc1-pid-x",
        "slot-reuse-keeps-old-pid",
        "issue-full-pid-index-only",
        "launch-full-pid-index-only",
        "query-full-pid-index-only",
        "response-full-pid-index-only",
        "completion-full-pid-index-only",
        "terminal-full-pid-index-only",
        "release-full-pid-index-only",
        "terminal-not-recorded",
        "terminal-seen-x",
        "recovery-ignores-prior-terminal",
        "normal-terminal-clears-valid",
        "killed-terminal-keeps-valid",
        "release-keeps-valid",
        "launched-recovery-drops-entry",
        "recovery-keeps-cleared-entry",
        "selective-includes-boundary",
        "same-edge-launch-ignored",
        "same-edge-completion-ignored",
        "same-edge-terminal-ignored",
        "dual-alloc-same-slot",
        "dual-query-same-pid-bypass",
        "issue-terminal-gate-removed",
        "query-terminal-gate-removed",
        "response-terminal-gate-removed",
        "release-before-completion",
        "alloc-borrows-same-edge-release",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            and positives[profile].get("compile_rc") == 0
            and positives[profile].get("simulation_rc") == 0
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and item["runs"][profile].get(
                    "negative_stimulus_enabled"
                )
                is True
                and item["runs"][profile].get("compile_rc") == 0
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    expected_scope = {
        "semantic_unit": "load-queue-producers",
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_rerun": {
            "required_for_local_closure": False,
            "required_before_system_promotion": True,
            "run": False,
        },
    }
    assertion_probe_ok = (
        isinstance(assertion_probe, dict)
        and assertion_probe.get("generation_width") == 4
        and assertion_probe.get("assertions_enabled") is True
        and assertion_probe.get("unknown_generation_injected") is True
        and assertion_probe.get("compile_rc") == 0
        and isinstance(assertion_probe.get("simulation_rc"), int)
        and assertion_probe["simulation_rc"] != 0
        and assertion_probe.get("expected_marker")
        == "[V11H-LQ-PID-KNOWN]"
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11h-load-queue-producer-semantic-evidence-v2"
        and payload.get("status") == "PASS"
        and payload.get("classification") == "architecture"
        and payload.get("design_id") == design_id
        and set(payload.get("unit_ids", []))
        == V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS
        and isinstance(production, dict)
        and production.get("pre_fix_rtl_sha256")
        == "82b22c8bf873b26863676823dd677fa8389ca96465e5611ac19e991d92a9752e"
        and production.get("post_fix_rtl_sha256")
        == "4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427"
        and production.get("raw_q_producer_id_knownness_assertion") is True
        and production.get("raw_q_producer_id_knownness_marker")
        == "[V11H-LQ-PID-KNOWN]"
        and isinstance(pre_fix, dict)
        and pre_fix.get("assertions_enabled") is False
        and pre_fix.get("compile_rc") == 0
        and isinstance(pre_fix.get("simulation_rc"), int)
        and pre_fix["simulation_rc"] != 0
        and pre_fix.get("observed_first_bad_state")
        == {"count": 1, "producer_live": 1, "killed": 1}
        and isinstance(root_cause, dict)
        and root_cause.get("confirmed") is True
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("stimulus_owned_four_entry_model") is True
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_producer_id_knownness") is True
        and oracle.get("checks_raw_terminal_history") is True
        and oracle.get("dut_outputs_are_observations_only") is True
        and oracle.get("mutation_assertions_enabled") is False
        and profile_shape_ok
        and assertion_probe_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("raw_q_knownness_assertion_probes") == 1
        and counts.get("compile_success_mutation_cases") == 31
        and counts.get("mutation_simulations") == 62
        and counts.get("rejected_mutation_simulations") == 62
        and scope == expected_scope
    )
    if not result_ok:
        raise CoverageError(
            "V11H LoadQueue producer summary is not complete"
        )
    if spec.get("checker_replay_receipt") is None:
        raise CoverageError(
            "current V11H closure requires the attempt-4 checker replay"
        )
    replay_artifact, replay_detail = validate_v11h_checker_replay(
        root, spec, design_id
    )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11H RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11H RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11H LoadQueue RTL snapshots differ")
    mismatches = validate_snapshot(root, pre, design_id)
    if mismatches:
        raise CoverageError(
            f"V11H LoadQueue live RTL drift: {mismatches}"
        )
    verify_artifact_record(
        root, production.get("rtl"), "V11H production LoadQueue"
    )
    verify_artifact_record(
        root,
        production.get("semantic_testbench"),
        "V11H semantic testbench",
    )
    verify_artifact_record(
        root,
        production.get("ordinary_regression_testbench"),
        "V11H ordinary testbench",
    )
    for key in ("source_manifest", "compile_log", "simulation_log"):
        verify_artifact_record(
            root, pre_fix.get(key), f"V11H pre-fix {key}"
        )
    verify_artifact_record(
        root, focused.get("pre"), "V11H focused source pre"
    )
    verify_artifact_record(
        root, focused.get("post"), "V11H focused source post"
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11H profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11H profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11H profile {profile} image",
        )
    for key, label in (
        ("compile_log", "compile log"),
        ("simulation_log", "simulation log"),
        ("compiled_image", "image"),
    ):
        verify_artifact_record(
            root,
            assertion_probe.get(key),
            f"V11H raw-Q PID knownness assertion probe {label}",
        )
    for item in mutations:
        label = f"V11H mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    detail = {
        "rtl_file_count": len(pre["rtl_files"]),
        "positive_profiles": 4,
        "generation_widths": [1, 4],
        "raw_q_knownness_assertion_probes": 1,
        "compile_success_mutation_cases_rejected": 31,
        "mutation_simulations_rejected": 62,
        "pre_fix_reproducer_rejected": True,
        "raw_producer_identity_knownness_closed": True,
        "raw_q_producer_identity_knownness_assertion_closed": True,
        "terminal_history_lifecycle_closed": True,
        "load_queue_producer_closed": True,
        "system_rerun": scope["system_rerun"],
        "checker_replay": replay_detail,
    }
    return (
        "CURRENT_FULL_RTL_BOUND",
        [artifact(root, spec["summary"]), replay_artifact],
        detail,
    )


def evaluate_evidence_set(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    kind = spec.get("binding_kind")
    if kind == "v8l_full_rtl_snapshot":
        state, artifacts, detail = evaluate_v8l(root, spec, design_id)
    elif kind == "v9r_json_source_binding":
        state, artifacts, detail = evaluate_v9r(root, spec, design_id)
    elif kind == "sha256_manifest_subset":
        state, artifacts, detail = evaluate_sha_manifest(root, spec)
    elif kind == "json_declared_bindings":
        state, artifacts, detail = evaluate_json_declared(root, spec)
    elif kind == "v11b_terminal_collector":
        if set(spec.get("unit_ids", [])) != V11B_TERMINAL_COLLECTOR_UNIT_IDS:
            raise CoverageError(
                "V11B terminal collector evidence must bind the exact "
                "collector unit set"
            )
        state, artifacts, detail = evaluate_v11b_terminal_collector(
            root, spec, design_id
        )
    elif kind == "v11c_memory_tracker":
        if set(spec.get("unit_ids", [])) != V11C_MEMORY_TRACKER_UNIT_IDS:
            raise CoverageError(
                "V11C memory tracker evidence must bind the exact map/live-set "
                "unit set"
            )
        state, artifacts, detail = evaluate_v11c_memory_tracker(
            root, spec, design_id
        )
    elif kind == "v11d_memory_tracker_cursor":
        if (
            set(spec.get("unit_ids", []))
            != V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS
        ):
            raise CoverageError(
                "V11D memory tracker cursor evidence must bind only "
                "tracker-next-token-cursor"
            )
        state, artifacts, detail = evaluate_v11d_memory_tracker_cursor(
            root, spec, design_id
        )
    elif kind == "v11e_rob_slot_generation":
        if (
            set(spec.get("unit_ids", []))
            != V11E_ROB_SLOT_GENERATION_UNIT_IDS
        ):
            raise CoverageError(
                "V11E ROB slot-generation evidence must bind only "
                "rob-slot-generation"
            )
        state, artifacts, detail = evaluate_v11e_rob_slot_generation(
            root, spec, design_id
        )
    elif kind == "v11f_int_iq_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11F_INT_IQ_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11F integer-IQ evidence must bind only "
                "integer-iq-producers"
            )
        state, artifacts, detail = evaluate_v11f_int_iq_producer(
            root, spec, design_id
        )
    elif kind == "v11g_store_queue_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11G_STORE_QUEUE_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11G StoreQueue evidence must bind exactly "
                "store-queue-producers and store-queue-owner-tokens"
            )
        state, artifacts, detail = evaluate_v11g_store_queue_holder(
            root, spec, design_id
        )
    elif kind == "v11h_load_queue_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11H LoadQueue evidence must bind only "
                "load-queue-producers"
            )
        state, artifacts, detail = evaluate_v11h_load_queue_producer(
            root, spec, design_id
        )
    else:
        raise CoverageError(f"unsupported binding kind: {kind}")
    return {
        "id": spec["id"],
        "binding_kind": kind,
        "binding_state": state,
        "scope": spec.get("scope"),
        "semantic_closure": spec.get("semantic_closure") is True,
        "unit_ids": sorted(spec.get("unit_ids", [])),
        "gap_classifications": sorted(
            set(spec.get("gap_classifications", []))
        ),
        "artifacts": artifacts,
        "detail": detail,
    }


def flatten_units(census: dict[str, Any]) -> list[dict[str, Any]]:
    units: list[dict[str, Any]] = []
    for collection in UNIT_COLLECTIONS:
        values = census.get(collection)
        if not isinstance(values, list):
            raise CoverageError(f"census collection is not a list: {collection}")
        category = {
            "direct_full_p_fields": "DIRECT_OR_ALIAS_FIELD",
            "packed_full_p_stages": "PACKED_STAGE",
            "token_q_fields": "TOKEN_FIELD",
            "token_set_holders": "TOKEN_SET",
            "generation_authorities": "GENERATION_AUTHORITY",
        }[collection]
        for value in values:
            if not isinstance(value, dict):
                raise CoverageError(f"census unit is not an object: {collection}")
            record = copy.deepcopy(value)
            record["category"] = category
            units.append(record)
    ids = [record.get("id") for record in units]
    if len(ids) != len(set(ids)) or not all(
        isinstance(value, str) and value for value in ids
    ):
        raise CoverageError("census semantic unit IDs are missing or duplicate")
    return sorted(units, key=lambda item: item["id"])


def gap_classes(
    unit: dict[str, Any],
    evidence: list[dict[str, Any]],
    instance_count: int,
) -> list[str]:
    gaps = {"SEMANTIC_LIFECYCLE_NOT_CLOSED"}
    if not evidence:
        gaps.update(
            {
                "NO_DYNAMIC_EVIDENCE_CANDIDATE",
                "RAW_IDENTITY_NEGATIVE_COVERAGE_GAP",
            }
        )
    for item in evidence:
        gaps.update(item["gap_classifications"])
        state = item["binding_state"]
        if state == "STALE_RTL_SOURCE":
            gaps.add("CANDIDATE_RTL_SOURCE_DRIFT")
        elif state == "RTL_SOURCE_MATCH_TESTBENCH_DRIFT":
            gaps.add("CANDIDATE_TESTBENCH_SOURCE_DRIFT")
        elif state == "CURRENT_SELECTED_SOURCE_AND_TB_BOUND":
            gaps.add("CURRENT_FULL_DESIGN_REPLAY_GAP")
    if instance_count > 1:
        gaps.add("PRODUCT_INSTANCE_DISTINGUISHABILITY_GAP")
    if unit["category"] == "TOKEN_FIELD":
        gaps.add("RAW_TOKEN_TUPLE_KNOWN_NEGATIVE_COVERAGE_GAP")
    elif unit["category"] == "TOKEN_SET":
        gaps.add("TOKEN_SET_MEMBERSHIP_NEGATIVE_COVERAGE_GAP")
    elif unit["category"] == "GENERATION_AUTHORITY":
        gaps.add("CURRENT_PRODUCT_GEN_W1_WRAP_PATH_GAP")
    else:
        gaps.add("RAW_PRODUCER_ID_KNOWN_NEGATIVE_COVERAGE_GAP")
    return sorted(gaps)


def unit_is_closed(
    evidence: list[dict[str, Any]], instance_count: int
) -> bool:
    closing = [
        item
        for item in evidence
        if item.get("semantic_closure") is True
    ]
    if not closing:
        return False
    if instance_count != 1:
        raise CoverageError(
            "semantic closure for a duplicated module requires explicit "
            "per-instance evidence"
        )
    for item in closing:
        if (
            item.get("scope") != "COMPLETE"
            or item.get("binding_state") not in CURRENT_BINDINGS
            or item.get("gap_classifications")
        ):
            raise CoverageError(
                f"invalid semantic closure evidence set: {item.get('id')}"
            )
    return True


def build_ledger(
    root: pathlib.Path,
    census_path: pathlib.Path,
    graph_path: pathlib.Path,
    policy_path: pathlib.Path,
) -> dict[str, Any]:
    design_id = current_design_id(root)
    census = load_json(census_path)
    graph = load_json(graph_path)
    policy = load_json(policy_path)
    if census.get("schema_version") != CENSUS_SCHEMA:
        raise CoverageError("producer/holder census schema mismatch")
    if graph.get("schema_version") != INSTANCE_SCHEMA:
        raise CoverageError("holder instance graph schema mismatch")
    if policy.get("schema_version") != POLICY_SCHEMA:
        raise CoverageError("semantic coverage policy schema mismatch")
    if census.get("design_id") != design_id:
        raise CoverageError("producer/holder census is not current-design")
    if graph.get("design_id") != design_id or graph.get("status") != "PASS":
        raise CoverageError("holder instance graph is not current PASS evidence")
    if policy.get("semantic_complete") is not False:
        raise CoverageError(
            "policy cannot claim semantic completion before per-unit closure"
        )

    units = flatten_units(census)
    if len(units) != 44:
        raise CoverageError(f"expected 44 semantic units, found {len(units)}")
    holder_instances = graph.get("graph", {}).get("holder_instances")
    if not isinstance(holder_instances, list):
        raise CoverageError("holder instance graph lacks holder_instances")
    instance_paths = [item.get("path") for item in holder_instances]
    if (
        len(holder_instances) != 17
        or len(instance_paths) != len(set(instance_paths))
    ):
        raise CoverageError(
            "expected 17 unique elaborated holder instance paths"
        )
    by_module: dict[str, list[str]] = defaultdict(list)
    for item in holder_instances:
        module = item.get("module")
        path = item.get("path")
        if not isinstance(module, str) or not isinstance(path, str):
            raise CoverageError("malformed holder instance record")
        by_module[module].append(path)

    known_ids = {unit["id"] for unit in units}
    evidence_specs = policy.get("evidence_sets")
    if not isinstance(evidence_specs, list):
        raise CoverageError("policy evidence_sets must be a list")
    evidence_results: list[dict[str, Any]] = []
    evidence_by_unit: dict[str, list[dict[str, Any]]] = defaultdict(list)
    evidence_ids: set[str] = set()
    for spec in evidence_specs:
        if not isinstance(spec, dict):
            raise CoverageError("evidence set must be an object")
        evidence_id = spec.get("id")
        if not isinstance(evidence_id, str) or evidence_id in evidence_ids:
            raise CoverageError("evidence set ID is missing or duplicate")
        evidence_ids.add(evidence_id)
        unit_ids = spec.get("unit_ids")
        if (
            not isinstance(unit_ids, list)
            or len(unit_ids) != len(set(unit_ids))
            or not set(unit_ids) <= known_ids
        ):
            raise CoverageError(f"evidence set has invalid unit IDs: {evidence_id}")
        result = evaluate_evidence_set(root, spec, design_id)
        evidence_results.append(result)
        for unit_id in unit_ids:
            evidence_by_unit[unit_id].append(result)

    output_units: list[dict[str, Any]] = []
    flat_bindings: list[dict[str, Any]] = []
    all_unit_modules: set[str] = set()
    for unit in units:
        module = unit.get("module")
        if not isinstance(module, str) or module not in by_module:
            raise CoverageError(
                f"census unit has no elaborated product instance: {unit['id']}"
            )
        all_unit_modules.add(module)
        paths = sorted(by_module[module])
        evidence = sorted(
            evidence_by_unit.get(unit["id"], []),
            key=lambda item: item["id"],
        )
        closed = unit_is_closed(evidence, len(paths))
        gaps = [] if closed else gap_classes(unit, evidence, len(paths))
        source_path = resolve_repo_path(root, unit["path"])
        if not source_path.is_file():
            raise CoverageError(f"census source file is missing: {unit['path']}")
        unit_record = {
            "id": unit["id"],
            "category": unit["category"],
            "classification": unit.get("classification"),
            "module": module,
            "source": {
                "path": unit["path"],
                "sha256": sha256_file(source_path),
            },
            "symbol": unit.get("symbol"),
            "stage_instance": unit.get("instance"),
            "instance_paths": paths,
            "instance_count": len(paths),
            "candidate_evidence": [
                {
                    "id": item["id"],
                    "binding_state": item["binding_state"],
                    "scope": item["scope"],
                }
                for item in evidence
            ],
            "semantic_status": "PASS" if closed else "GAP",
            "gap_classifications": gaps,
        }
        output_units.append(unit_record)
        for path in paths:
            binding_gaps = list(gaps)
            flat_bindings.append(
                {
                    "unit_id": unit["id"],
                    "module": module,
                    "instance_path": path,
                    "semantic_status": "PASS" if closed else "GAP",
                    "gap_classifications": binding_gaps,
                }
            )
    missing_modules = sorted(set(by_module) - all_unit_modules)
    if missing_modules:
        raise CoverageError(
            f"elaborated holder modules lack census units: {missing_modules}"
        )

    state_counts = Counter(
        result["binding_state"] for result in evidence_results
    )
    units_with_candidates = sum(
        bool(unit["candidate_evidence"]) for unit in output_units
    )
    duplicate_modules = sorted(
        module for module, paths in by_module.items() if len(paths) > 1
    )
    units_semantic_pass = sum(
        unit["semantic_status"] == "PASS" for unit in output_units
    )
    return {
        "schema_version": SCHEMA,
        "status": "GAP",
        "design_id": design_id,
        "inputs": {
            "census": artifact(root, relative(root, census_path)),
            "instance_graph": artifact(root, relative(root, graph_path)),
            "policy": artifact(root, relative(root, policy_path)),
        },
        "counts": {
            "semantic_units": len(output_units),
            "holder_instances": len(holder_instances),
            "unit_instance_bindings": len(flat_bindings),
            "units_semantic_pass": units_semantic_pass,
            "units_semantic_gap": len(output_units) - units_semantic_pass,
            "units_with_candidate_evidence": units_with_candidates,
            "units_without_candidate_evidence": len(output_units)
            - units_with_candidates,
            "ledger_only_units": 0,
            "evidence_binding_states": dict(sorted(state_counts.items())),
        },
        "duplicate_instance_modules": duplicate_modules,
        "evidence_sets": sorted(evidence_results, key=lambda item: item["id"]),
        "units": output_units,
        "unit_instance_bindings": sorted(
            flat_bindings,
            key=lambda item: (item["unit_id"], item["instance_path"]),
        ),
        "claim_boundary": policy["claim_boundary"],
        "promotion": {
            "global_no_live_reuse": "SEMANTIC_COVERAGE_REQUIRED",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
        },
    }


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--root", type=pathlib.Path, default=pathlib.Path.cwd())
    result.add_argument(
        "--census",
        default="npc/rv64/design/arch/producer-holder-census.json",
    )
    result.add_argument(
        "--instance-graph",
        default=(
            ".github/task-runs/2026-07-30-rv64-v11h-"
            "load-queue-producer-semantic-coverage/evidence/"
            "current-instance-graph-v2/"
            "holder-instance-graph.json"
        ),
    )
    result.add_argument(
        "--policy",
        default=(
            "npc/rv64/design/arch/"
            "producer-holder-semantic-coverage-policy.json"
        ),
    )
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    expected = build_ledger(
        root,
        resolve_repo_path(root, args.census),
        resolve_repo_path(root, args.instance_graph),
        resolve_repo_path(root, args.policy),
    )
    if args.command == "build":
        output = args.output
        if not output.is_absolute():
            output = root / output
        output = output.resolve()
        relative(root, output)
        write_json(output, expected)
    else:
        input_path = args.input
        if not input_path.is_absolute():
            input_path = root / input_path
        actual = load_json(input_path.resolve())
        if actual != expected:
            raise CoverageError(
                "semantic coverage ledger differs from current inputs"
            )
    counts = expected["counts"]
    print(
        "[PRODUCER-HOLDER-SEMANTIC-COVERAGE][GAP] "
        f"design_id={expected['design_id']} "
        f"units={counts['semantic_units']} "
        f"instances={counts['holder_instances']} "
        f"bindings={counts['unit_instance_bindings']} "
        f"candidate={counts['units_with_candidate_evidence']} "
        f"no_candidate={counts['units_without_candidate_evidence']} "
        f"ledger_only=0 semantic_pass={counts['units_semantic_pass']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CoverageError as exc:
        print(
            f"[PRODUCER-HOLDER-SEMANTIC-COVERAGE][FAIL] {exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
