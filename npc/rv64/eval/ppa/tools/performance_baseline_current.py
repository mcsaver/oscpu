#!/usr/bin/env python3
"""Build and verify versioned RV64 performance-baseline receipts.

The receipt is intentionally separate from PPA promotion.  It binds one
ARCH_STABLE full-core simulator, two fixed bare-metal workloads, three
bit-exact counter runs per workload, and one stats-off non-interference run per
workload.  The v3 path first validates the current ARCH_STABLE identity and
all measurement inputs before the long-run driver may launch simulation.  This
tool never launches simulation or synthesis; it only validates immutable
artifacts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import sys
from typing import Any


TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import check  # noqa: E402


MANIFEST_SCHEMA = "npc-rv64-performance-baseline-run-manifest-v2"
DIRECT_MANIFEST_SCHEMA = "npc-rv64-performance-baseline-run-manifest-v3"
LEGACY_MANIFEST_SCHEMA = "npc-rv64-performance-baseline-run-manifest-v1"
SOURCE_MANIFEST_SCHEMA = LEGACY_MANIFEST_SCHEMA
RESULT_SCHEMA = "npc-rv64-performance-baseline-current-v2"
DIRECT_RESULT_SCHEMA = "npc-rv64-performance-baseline-current-v3"
LEGACY_RESULT_SCHEMA = "npc-rv64-performance-baseline-current-v1"
PRECHECK_SCHEMA = "npc-rv64-performance-baseline-precheck-v2"
DIRECT_PRECHECK_SCHEMA = "npc-rv64-performance-baseline-precheck-v3"
INPUT_PREFLIGHT_SCHEMA = "npc-rv64-performance-baseline-input-preflight-v1"
MEASUREMENT_CONTRACT_SCHEMA = "npc-rv64-performance-measurement-contract-v1"
DIRECT_MEASUREMENT_CONTRACT_SCHEMA = (
    "npc-rv64-performance-measurement-contract-v2")
CURRENT_BASELINE_CONTRACT_SCHEMA = "npc-rv64-performance-baseline-contract-v2"
DIRECT_BASELINE_CONTRACT_SCHEMA = "npc-rv64-performance-baseline-contract-v3"
LEGACY_BASELINE_CONTRACT_SCHEMA = "npc-rv64-performance-baseline-contract-v1"
BOUNDARY_AMENDMENT_SCHEMA = (
    "npc-rv64-performance-boundary-qualification-amendment-v1")
DIRECT_BOUNDARY_AMENDMENT_SCHEMA = (
    "npc-rv64-performance-boundary-qualification-amendment-v2")
WORKLOAD_MATRIX_SCHEMA = "npc-rv64-performance-workload-matrix-v1"
PERFORMANCE_SCHEMA = "npc-rv64-performance-evidence-v8"
INDEPENDENT_REVIEW_V1_SCHEMA = (
    "npc-rv64-performance-baseline-independent-review-v1")
INDEPENDENT_REVIEW_V2_SCHEMA = (
    "npc-rv64-performance-baseline-independent-review-v2")
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
KEY_VALUE_RE = re.compile(r"([a-zA-Z0-9_]+)=([^\s]+)")


class BaselineError(RuntimeError):
    """Raised when current performance evidence is not exact and complete."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BaselineError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_file(root: pathlib.Path, value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, str) and bool(value), f"{label} path is invalid")
    relative = pathlib.PurePosixPath(value)
    require(not relative.is_absolute(), f"{label} path must be repository-relative")
    candidate = root.joinpath(*relative.parts)
    try:
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(root)
    except (OSError, ValueError) as exc:
        raise BaselineError(f"{label} path escapes repository or is missing: {value}") from exc
    require(resolved.is_file(), f"{label} is not a file: {value}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    resolved = path.resolve(strict=True)
    try:
        relative = resolved.relative_to(root).as_posix()
    except ValueError as exc:
        raise BaselineError(f"artifact escapes repository: {path}") from exc
    return {
        "path": relative,
        "sha256": sha256(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def validate_artifact(
    root: pathlib.Path, record: Any, label: str,
) -> pathlib.Path:
    require(isinstance(record, dict), f"{label} artifact is invalid")
    path = safe_file(root, record.get("path"), label)
    expected_sha = record.get("sha256")
    expected_size = record.get("size_bytes")
    require(isinstance(expected_sha, str) and SHA256_RE.fullmatch(expected_sha) is not None,
            f"{label} sha256 is invalid")
    require(isinstance(expected_size, int) and expected_size > 0,
            f"{label} size is invalid")
    require(path.stat().st_size == expected_size, f"{label} size mismatch")
    require(sha256(path) == expected_sha, f"{label} sha256 mismatch")
    return path


def read_json(path: pathlib.Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise BaselineError(f"cannot read {label}: {exc}") from exc
    require(isinstance(value, dict), f"{label} root must be an object")
    return value


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def unique_line(lines: list[str], token: str, label: str) -> str:
    matches = [line for line in lines if token in line]
    require(len(matches) == 1, f"{label} expected exactly one {token} marker")
    return matches[0]


def marker_values(lines: list[str], token: str, label: str) -> dict[str, str]:
    return dict(KEY_VALUE_RE.findall(unique_line(lines, token, label)))


def counter_int(values: dict[str, str], key: str, label: str) -> int:
    try:
        text = values[key]
        require(re.fullmatch(r"[0-9]+", text) is not None,
                f"{label} {key} is not an unsigned integer")
        value = int(text, 10)
    except KeyError as exc:
        raise BaselineError(f"{label} {key} is missing") from exc
    require(0 <= value < (1 << 64), f"{label} {key} exceeds uint64")
    return value


def parse_stats_off_log(
    path: pathlib.Path,
    benchmark: str,
    contract: dict[str, Any],
) -> dict[str, Any]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise BaselineError(f"cannot read {benchmark} stats-off log: {exc}") from exc
    require(len(text.encode("utf-8")) <= check.MAX_RAW_LOG_BYTES,
            f"{benchmark} stats-off log exceeds size limit")
    clean = ANSI_RE.sub("", text)
    lines = clean.splitlines()
    require(sum("HIT GOOD TRAP" in line for line in lines) == 1,
            f"{benchmark} stats-off GOOD TRAP count mismatch")
    require(not re.search(r"\b(?:OOO_ASSERT|RTL_ASSERTION|Assertion failed|%Error|FATAL:)\b", clean),
            f"{benchmark} stats-off RTL assertion or fatal marker observed")
    report = unique_line(lines, "report_run_result]", f"{benchmark} stats-off")
    require(re.search(r"\bcode=0\b", report) is not None,
            f"{benchmark} stats-off exit code is nonzero")
    start = marker_values(
        lines, "BOUNDARY kind=start ", f"{benchmark} stats-off start")
    stop = marker_values(
        lines, "BOUNDARY kind=end ", f"{benchmark} stats-off stop")
    final = marker_values(
        lines, "region_probe] FINAL ", f"{benchmark} stats-off FINAL")
    region = contract.get("region")
    require(isinstance(region, dict),
            f"{benchmark} stats-off policy region is missing")
    require(start.get("pc") == region.get("start_pc")
            and stop.get("pc") == region.get("stop_pc"),
            f"{benchmark} stats-off boundary PC mismatch")
    require(counter_int(start, "cycle_retire", f"{benchmark} stats-off") in (1, 2)
            and counter_int(stop, "cycle_retire", f"{benchmark} stats-off") in (1, 2),
            f"{benchmark} stats-off boundary retirement marker mismatch")
    required_final = {
        "schema": "npc-rv64-region-final-v1",
        "counter_scope": "pc_bounded_region_v1",
        "complete": "1",
        "termination_rc": "0",
        "start_seen": "1",
        "end_seen": "1",
    }
    for key, expected in required_final.items():
        require(final.get(key) == expected,
                f"{benchmark} stats-off FINAL {key} mismatch")
    counters = marker_values(
        lines, "region_probe] COUNTERS_FINAL ", f"{benchmark} stats-off counters")
    require(counters.get("schema") == "npc-rv64-performance-counter-v4",
            f"{benchmark} stats-off counter schema mismatch")
    require(counters.get("complete") == "0" and counters.get("available") == "0",
            f"{benchmark} stats-off counter availability mismatch")
    start_cycle = counter_int(start, "cycle", f"{benchmark} stats-off")
    stop_cycle = counter_int(stop, "cycle", f"{benchmark} stats-off")
    start_retired = counter_int(
        start, "retired_before", f"{benchmark} stats-off")
    stop_retired = counter_int(
        stop, "retired_before", f"{benchmark} stats-off")
    start_lane = counter_int(start, "lane", f"{benchmark} stats-off")
    stop_lane = counter_int(stop, "lane", f"{benchmark} stats-off")
    require(start_lane in (0, 1) and stop_lane in (0, 1),
            f"{benchmark} stats-off boundary lane is invalid")
    cycles = counter_int(final, "cycles", f"{benchmark} stats-off")
    retired = counter_int(final, "retired", f"{benchmark} stats-off")
    start_hits = counter_int(final, "start_hits", f"{benchmark} stats-off")
    end_hits = counter_int(final, "end_hits", f"{benchmark} stats-off")
    require(cycles > 0 and retired > 0,
            f"{benchmark} stats-off region counters must be positive")
    require(stop_cycle - start_cycle == cycles,
            f"{benchmark} stats-off region cycle delta mismatch")
    require(stop_retired - start_retired == retired,
            f"{benchmark} stats-off region retired delta mismatch")
    for final_key, expected in (
        ("start_cycle", start_cycle), ("end_cycle", stop_cycle),
        ("start_retired", start_retired), ("end_retired", stop_retired),
        ("start_hits", region.get("start_hits")),
        ("end_hits", region.get("stop_hits")),
    ):
        require(counter_int(final, final_key, f"{benchmark} stats-off") == expected,
                f"{benchmark} stats-off FINAL {final_key} mismatch")
    require(counter_int(counters, "cycles", f"{benchmark} stats-off") == cycles,
            f"{benchmark} stats-off counter cycle mismatch")
    require(counter_int(counters, "start_lane", f"{benchmark} stats-off") == start_lane
            and counter_int(counters, "end_lane", f"{benchmark} stats-off") == stop_lane,
            f"{benchmark} stats-off counter boundary lane mismatch")
    require(counter_int(counters, "phase_aligned", f"{benchmark} stats-off")
            == int(start_lane == stop_lane),
            f"{benchmark} stats-off phase marker mismatch")
    require(counters.get("overflow") == "0"
            and counters.get("invalid_events") == "0"
            and counters.get("conservation") == "0",
            f"{benchmark} stats-off disabled-counter marker mismatch")
    zero_fields = [
        key for key in counters
        if key.startswith("cycle_") or key.startswith("slot_")
    ] + ["slot_capacity", "retired_slots", "unused_slots"]
    for key in zero_fields:
        require(counter_int(counters, key, f"{benchmark} stats-off") == 0,
                f"{benchmark} stats-off {key} must be zero")
    if benchmark == "coremark":
        require(start_hits == 1 and end_hits == 1,
                "CoreMark stats-off marker hit count mismatch")
        require(re.search(r"Iterations\s*:\s*10\b", clean) is not None,
                "CoreMark stats-off iteration count mismatch")
        require(re.search(r"crcfinal\s*:\s*0xfcaf\b", clean) is not None,
                "CoreMark stats-off CRC mismatch")
    else:
        require(start_hits == 10000 and end_hits == 1,
                "Dhrystone stats-off marker hit count mismatch")
        require("Trying 10000 runs through Dhrystone." in clean,
                "Dhrystone stats-off run count mismatch")
        require("Dhrystone PASS" in clean,
                "Dhrystone stats-off PASS marker is missing")
    return {
        "cycles": cycles,
        "retired_instructions": retired,
        "start_hits": start_hits,
        "end_hits": end_hits,
        "counter_available": False,
    }


def parse_endpoint_corrected_v8_log(
    path: pathlib.Path,
    benchmark: str,
    contract: dict[str, Any],
) -> dict[str, Any]:
    """Parse v8 counters while accepting the exact lane endpoint correction.

    The legacy promotion parser requires start_lane == end_lane.  The host
    counter contract already emits and conserves
    ``2 * cycles + end_lane - start_lane``; this parser validates that formula
    directly for the current PERF_BASELINE stage without weakening any other
    v8 invariant.
    """

    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise BaselineError(f"cannot read {benchmark} raw log: {exc}") from exc
    require(len(text.encode("utf-8")) <= check.MAX_RAW_LOG_BYTES,
            f"{benchmark} raw log exceeds size limit")
    clean = ANSI_RE.sub("", text)
    lines = clean.splitlines()
    require(sum("HIT GOOD TRAP" in line for line in lines) == 1,
            f"{benchmark} GOOD TRAP count mismatch")
    require(not re.search(r"\b(?:OOO_ASSERT|RTL_ASSERTION|Assertion failed|%Error|FATAL:)\b", clean),
            f"{benchmark} RTL assertion or fatal marker observed")
    report = unique_line(lines, "report_run_result]", benchmark)
    require(re.search(r"\bcode=0\b", report) is not None,
            f"{benchmark} exit code is nonzero")
    require("Trying 10000 runs through Dhrystone." in clean
            and sum("Dhrystone PASS" in line for line in lines) == 1,
            "Dhrystone semantic marker mismatch")

    start = marker_values(lines, "BOUNDARY kind=start ", f"{benchmark} start")
    stop = marker_values(lines, "BOUNDARY kind=end ", f"{benchmark} stop")
    final = marker_values(lines, "region_probe] FINAL ", f"{benchmark} FINAL")
    counters = marker_values(
        lines, "region_probe] COUNTERS_FINAL ", f"{benchmark} counters")
    region = contract.get("region")
    require(isinstance(region, dict), f"{benchmark} policy region is missing")
    require(start.get("pc") == region.get("start_pc")
            and stop.get("pc") == region.get("stop_pc"),
            f"{benchmark} boundary PC mismatch")
    required_final = {
        "schema": "npc-rv64-region-final-v1",
        "counter_scope": "pc_bounded_region_v1",
        "complete": "1",
        "termination_rc": "0",
        "start_seen": "1",
        "end_seen": "1",
    }
    for key, expected in required_final.items():
        require(final.get(key) == expected, f"{benchmark} FINAL {key} mismatch")
    required_counters = {
        "schema": "npc-rv64-performance-counter-v4",
        "complete": "1",
        "available": "1",
        "overflow": "0",
        "invalid_events": "0",
        "conservation": "1",
    }
    for key, expected in required_counters.items():
        require(counters.get(key) == expected,
                f"{benchmark} COUNTERS_FINAL {key} mismatch")

    start_cycle = counter_int(start, "cycle", benchmark)
    stop_cycle = counter_int(stop, "cycle", benchmark)
    start_retired = counter_int(start, "retired_before", benchmark)
    stop_retired = counter_int(stop, "retired_before", benchmark)
    start_lane = counter_int(start, "lane", benchmark)
    stop_lane = counter_int(stop, "lane", benchmark)
    require(start_lane in (0, 1) and stop_lane in (0, 1),
            f"{benchmark} boundary lane is invalid")
    cycles = counter_int(final, "cycles", benchmark)
    retired = counter_int(final, "retired", benchmark)
    require(cycles > 0 and retired > 0,
            f"{benchmark} region counters must be positive")
    require(stop_cycle - start_cycle == cycles,
            f"{benchmark} region cycle delta mismatch")
    require(stop_retired - start_retired == retired,
            f"{benchmark} region retired delta mismatch")
    for final_key, expected in (
        ("start_cycle", start_cycle), ("end_cycle", stop_cycle),
        ("start_retired", start_retired), ("end_retired", stop_retired),
        ("start_hits", region.get("start_hits")),
        ("end_hits", region.get("stop_hits")),
    ):
        require(counter_int(final, final_key, benchmark) == expected,
                f"{benchmark} FINAL {final_key} mismatch")

    counter_values = {
        key: counter_int(counters, key, benchmark)
        for key in counters
        if key not in {"schema"}
    }
    require(counter_values["start_lane"] == start_lane
            and counter_values["end_lane"] == stop_lane,
            f"{benchmark} counter boundary lane mismatch")
    expected_phase = int(start_lane == stop_lane)
    require(counter_values["phase_aligned"] == expected_phase,
            f"{benchmark} phase marker mismatch")
    require(counter_values["cycles"] == cycles,
            f"{benchmark} counter cycle mismatch")
    slot_capacity = 2 * cycles + stop_lane - start_lane
    require(counter_values["slot_capacity"] == slot_capacity,
            f"{benchmark} endpoint-corrected slot capacity mismatch")
    require(counter_values["retired_slots"] == retired,
            f"{benchmark} retired-slot count mismatch")
    require(counter_values["unused_slots"] == slot_capacity - retired,
            f"{benchmark} unused-slot count mismatch")

    cycle_primary = (
        "cycle_useful", "cycle_rob_empty", "cycle_dependency",
        "cycle_issue_terminal", "cycle_execution_latency",
        "cycle_memory_latency", "cycle_head_lifecycle_unknown",
        "cycle_exception_redirect", "cycle_memory_commit",
        "cycle_serialization", "cycle_unknown",
    )
    slot_primary = (
        "slot_rob_empty", "slot_dependency", "slot_issue_terminal",
        "slot_execution_latency", "slot_memory_latency",
        "slot_head_lifecycle_unknown", "slot_exception_redirect",
        "slot_memory_commit", "slot_serialization", "slot_unknown",
    )
    require(sum(counter_values[key] for key in cycle_primary) == cycles,
            f"{benchmark} cycle-reason conservation mismatch")
    require(sum(counter_values[key] for key in slot_primary)
            == counter_values["unused_slots"],
            f"{benchmark} slot-reason conservation mismatch")

    def require_aggregate(total: str, members: tuple[str, ...]) -> None:
        require(counter_values[total] == sum(counter_values[key] for key in members),
                f"{benchmark} {total} aggregate mismatch")

    require_aggregate("cycle_head_not_complete", (
        "cycle_dependency", "cycle_issue_terminal", "cycle_execution_latency",
        "cycle_memory_latency", "cycle_head_lifecycle_unknown"))
    require_aggregate("slot_head_not_complete", (
        "slot_dependency", "slot_issue_terminal", "slot_execution_latency",
        "slot_memory_latency", "slot_head_lifecycle_unknown"))
    require_aggregate("cycle_memory_latency", (
        "cycle_memory_reservation_queue", "cycle_memory_translation_order",
        "cycle_memory_request_outstanding", "cycle_memory_response_terminal",
        "cycle_memory_retry", "cycle_memory_lifecycle_unknown"))
    require_aggregate("slot_memory_latency", (
        "slot_memory_reservation_queue", "slot_memory_translation_order",
        "slot_memory_request_outstanding", "slot_memory_response_terminal",
        "slot_memory_retry", "slot_memory_lifecycle_unknown"))
    request_cycle_members = (
        "cycle_memory_request_cache_lookup", "cycle_memory_request_device_wait",
        "cycle_memory_request_axi_read_address",
        "cycle_memory_request_axi_read_data",
        "cycle_memory_request_axi_write_request",
        "cycle_memory_request_axi_write_response",
        "cycle_memory_request_detail_unknown",
    )
    request_slot_members = tuple(
        name.replace("cycle_", "slot_", 1) for name in request_cycle_members)
    require_aggregate("cycle_memory_request_outstanding", request_cycle_members)
    require_aggregate("slot_memory_request_outstanding", request_slot_members)
    unknown_cycles = sum(counter_values[key] for key in (
        "cycle_memory_request_detail_unknown",
        "cycle_memory_lifecycle_unknown",
        "cycle_head_lifecycle_unknown",
        "cycle_unknown",
    ))
    unknown_ratio = unknown_cycles / cycles
    require(unknown_ratio <= 0.01,
            f"{benchmark} unknown cycle ratio exceeds contract")

    cpi_stack = {
        "useful": counter_values["cycle_useful"],
        "rob_empty": counter_values["cycle_rob_empty"],
        "dependency": counter_values["cycle_dependency"],
        "issue_terminal": counter_values["cycle_issue_terminal"],
        "execution_latency": counter_values["cycle_execution_latency"],
        "memory_latency": counter_values["cycle_memory_latency"],
        "head_lifecycle_unknown": counter_values["cycle_head_lifecycle_unknown"],
        "exception_redirect": counter_values["cycle_exception_redirect"],
        "memory_commit": counter_values["cycle_memory_commit"],
        "serialization": counter_values["cycle_serialization"],
        "unknown": counter_values["cycle_unknown"],
        "head_not_complete_aggregate": counter_values["cycle_head_not_complete"],
        "memory_lifecycle": {
            "reservation_queue": counter_values["cycle_memory_reservation_queue"],
            "translation_order": counter_values["cycle_memory_translation_order"],
            "request_outstanding": counter_values["cycle_memory_request_outstanding"],
            "response_terminal": counter_values["cycle_memory_response_terminal"],
            "retry": counter_values["cycle_memory_retry"],
            "lifecycle_unknown": counter_values["cycle_memory_lifecycle_unknown"],
        },
        "memory_request_detail": {
            "cache_lookup": counter_values["cycle_memory_request_cache_lookup"],
            "device_wait": counter_values["cycle_memory_request_device_wait"],
            "axi_read_address": counter_values["cycle_memory_request_axi_read_address"],
            "axi_read_data": counter_values["cycle_memory_request_axi_read_data"],
            "axi_write_request": counter_values["cycle_memory_request_axi_write_request"],
            "axi_write_response": counter_values["cycle_memory_request_axi_write_response"],
            "detail_unknown": counter_values["cycle_memory_request_detail_unknown"],
        },
        "unknown_ratio": unknown_ratio,
    }
    retire_slots = {
        "capacity": slot_capacity,
        "retired": retired,
        "unused": counter_values["unused_slots"],
        "rob_empty": counter_values["slot_rob_empty"],
        "dependency": counter_values["slot_dependency"],
        "issue_terminal": counter_values["slot_issue_terminal"],
        "execution_latency": counter_values["slot_execution_latency"],
        "memory_latency": counter_values["slot_memory_latency"],
        "head_lifecycle_unknown": counter_values["slot_head_lifecycle_unknown"],
        "exception_redirect": counter_values["slot_exception_redirect"],
        "memory_commit": counter_values["slot_memory_commit"],
        "serialization": counter_values["slot_serialization"],
        "unknown": counter_values["slot_unknown"],
        "head_not_complete_aggregate": counter_values["slot_head_not_complete"],
        "memory_lifecycle": {
            "reservation_queue": counter_values["slot_memory_reservation_queue"],
            "translation_order": counter_values["slot_memory_translation_order"],
            "request_outstanding": counter_values["slot_memory_request_outstanding"],
            "response_terminal": counter_values["slot_memory_response_terminal"],
            "retry": counter_values["slot_memory_retry"],
            "lifecycle_unknown": counter_values["slot_memory_lifecycle_unknown"],
        },
        "memory_request_detail": {
            "cache_lookup": counter_values["slot_memory_request_cache_lookup"],
            "device_wait": counter_values["slot_memory_request_device_wait"],
            "axi_read_address": counter_values["slot_memory_request_axi_read_address"],
            "axi_read_data": counter_values["slot_memory_request_axi_read_data"],
            "axi_write_request": counter_values["slot_memory_request_axi_write_request"],
            "axi_write_response": counter_values["slot_memory_request_axi_write_response"],
            "detail_unknown": counter_values["slot_memory_request_detail_unknown"],
        },
    }
    return {
        "cycles": cycles,
        "retired_instructions": retired,
        "region": {
            "start_pc": start["pc"],
            "stop_pc": stop["pc"],
            "start_marker_semantics": "first_committed_hit",
            "start_hits": counter_int(final, "start_hits", benchmark),
            "stop_hits": counter_int(final, "end_hits", benchmark),
            "start_cycle": start_cycle,
            "stop_cycle": stop_cycle,
            "start_retired": start_retired,
            "stop_retired": stop_retired,
            "start_lane": start_lane,
            "stop_lane": stop_lane,
            "cycles": cycles,
            "retired_instructions": retired,
            "final_schema": final["schema"],
            "final_total_hits": True,
        },
        "cpi_stack": cpi_stack,
        "retire_slots": retire_slots,
    }


def stable_counter_signature(parsed: dict[str, Any]) -> dict[str, Any]:
    return {
        "cycles": parsed["cycles"],
        "retired_instructions": parsed["retired_instructions"],
        "region": {
            key: parsed["region"][key]
            for key in (
                "start_pc", "stop_pc", "start_marker_semantics",
                "start_hits", "stop_hits", "start_lane", "stop_lane",
                "cycles", "retired_instructions", "final_schema",
                "final_total_hits",
            )
        },
        "cpi_stack": parsed["cpi_stack"],
        "retire_slots": parsed["retire_slots"],
    }


def parse_workload(
    root: pathlib.Path,
    manifest: dict[str, Any],
    benchmark: str,
    policy: dict[str, Any],
    counter_contract: dict[str, Any],
    endpoint_amendment_active: bool,
) -> dict[str, Any]:
    workloads = manifest.get("workloads")
    require(isinstance(workloads, dict), "manifest workloads are missing")
    workload = workloads.get(benchmark)
    require(isinstance(workload, dict), f"{benchmark} manifest is missing")
    validate_artifact(root, workload.get("image"), f"{benchmark} image")
    logs = workload.get("logs")
    require(isinstance(logs, list) and len(logs) == 3,
            f"{benchmark} requires exactly three logs")
    contracts = policy["performance_evidence"]["benchmark_contracts"]
    contract = contracts[benchmark]
    parsed_runs: list[dict[str, Any]] = []
    seen_paths: set[str] = set()
    for index, record in enumerate(logs, start=1):
        path = validate_artifact(root, record, f"{benchmark} repetition {index}")
        relative = path.relative_to(root).as_posix()
        require(relative not in seen_paths, f"{benchmark} raw log path is reused")
        seen_paths.add(relative)
        try:
            if benchmark == "dhrystone_10000" and endpoint_amendment_active:
                parsed = parse_endpoint_corrected_v8_log(
                    path, benchmark, contract)
            else:
                parsed = check.parse_raw_benchmark_log(
                    path,
                    benchmark,
                    "pc_bounded_region_v1",
                    contract,
                    PERFORMANCE_SCHEMA,
                    counter_contract,
                )
        except (OSError, UnicodeDecodeError, ValueError) as exc:
            raise BaselineError(
                f"{benchmark} repetition {index} is invalid: {exc}") from exc
        parsed_runs.append(parsed)
    signatures = [stable_counter_signature(run) for run in parsed_runs]
    require(all(value == signatures[0] for value in signatures[1:]),
            f"{benchmark} repetition counters are not bit-exact")
    selected = parsed_runs[0]
    cycles = selected["cycles"]
    retired = selected["retired_instructions"]
    require(isinstance(cycles, int) and isinstance(retired, int)
            and cycles > 0 and retired > 0,
            f"{benchmark} selected counters are invalid")
    return {
        "repetitions": 3,
        "bit_exact": True,
        "cycles": cycles,
        "retired_instructions": retired,
        "cpi": format(cycles / retired, ".12f"),
        "ipc": format(retired / cycles, ".12f"),
        "counter_signature_sha256": hashlib.sha256(
            json.dumps(signatures[0], sort_keys=True, separators=(",", ":"))
            .encode("utf-8")
        ).hexdigest(),
        "cpi_stack": selected["cpi_stack"],
        "retire_slots": selected["retire_slots"],
        "logs": logs,
    }


def validate_arch_stable(
    root: pathlib.Path, manifest: dict[str, Any], design_id: str,
) -> dict[str, Any]:
    path = validate_artifact(
        root, manifest.get("arch_stable_result"), "ARCH_STABLE result")
    value = read_json(path, "ARCH_STABLE result")
    require(value.get("schema") == "npc-rv64-arch-stable-result-v1",
            "ARCH_STABLE result schema mismatch")
    require(value.get("architecture_freeze") == "ARCH_STABLE",
            "current architecture is not ARCH_STABLE")
    require(value.get("design_id") == design_id,
            "ARCH_STABLE design-id mismatch")
    require(value.get("blockers") == [], "ARCH_STABLE blockers are nonempty")
    require(value.get("ppa") == "UNQUALIFIED"
            and value.get("promotion_eligible") is False,
            "ARCH_STABLE PPA boundary mismatch")
    return value


def same_artifact_record(left: Any, right: Any) -> bool:
    if not isinstance(left, dict) or not isinstance(right, dict):
        return False
    return all(left.get(key) == right.get(key)
               for key in ("path", "sha256", "size_bytes"))


def validate_boundary_amendment(
    root: pathlib.Path,
    manifest: dict[str, Any],
    baseline: dict[str, Any],
    measurement: dict[str, Any],
    counter: dict[str, Any],
) -> dict[str, Any]:
    record = manifest.get("boundary_qualification_amendment")
    require(baseline.get("boundary_qualification_amendment") == record,
            "baseline boundary amendment binding mismatch")
    path = validate_artifact(root, record, "boundary qualification amendment")
    amendment = read_json(path, "boundary qualification amendment")
    measurement_schema = measurement.get("schema")
    expected_schema = (
        DIRECT_BOUNDARY_AMENDMENT_SCHEMA
        if measurement_schema == DIRECT_MEASUREMENT_CONTRACT_SCHEMA
        else BOUNDARY_AMENDMENT_SCHEMA
    )
    require(amendment.get("schema") == expected_schema,
            "boundary qualification amendment schema mismatch")
    require(amendment.get("state") == "NORMATIVE_ERRATUM",
            "boundary qualification amendment state mismatch")
    bound = amendment.get("bound_inputs")
    require(isinstance(bound, dict), "boundary amendment inputs are missing")
    require(bound.get("measurement_contract") == manifest.get("measurement_contract")
            and bound.get("counter_schema") == manifest.get("counter_schema"),
            "boundary amendment input binding mismatch")
    scope = amendment.get("scope")
    require(isinstance(scope, dict)
            and scope.get("counter_marker_schema")
            == "npc-rv64-performance-counter-v4"
            and scope.get("counter_scope") == "pc_bounded_region_v1",
            "boundary amendment scope mismatch")
    qualification = counter.get("qualification")
    require(isinstance(qualification, dict)
            and qualification.get("baseline_requires_phase_aligned_boundaries") is True,
            "bound v4 phase-alignment source clause mismatch")
    read_semantics = measurement.get("counter_read_semantics")
    retire_capacity = (
        read_semantics.get("retire_slot_capacity", "")
        if isinstance(read_semantics, dict) else ""
    )
    if measurement_schema == DIRECT_MEASUREMENT_CONTRACT_SCHEMA:
        require("2 * cycles + end_lane - start_lane" in retire_capacity
                and "does not require start_lane == end_lane" in retire_capacity,
                "bound direct measurement endpoint clause mismatch")
    else:
        require("baseline qualification requires start_lane == end_lane"
                in retire_capacity,
                "bound measurement phase-alignment source clause mismatch")
    precedence = amendment.get("normative_precedence")
    minimum_superseded = (
        1 if measurement_schema == DIRECT_MEASUREMENT_CONTRACT_SCHEMA else 2)
    require(isinstance(precedence, dict)
            and len(precedence.get("supersedes", [])) >= minimum_superseded,
            "boundary amendment precedence is incomplete")
    obligations = amendment.get("proof_obligations")
    require(isinstance(obligations, list) and len(obligations) >= 10,
            "boundary amendment proof obligations are incomplete")
    return amendment


def validate_source_execution(
    root: pathlib.Path,
    manifest: dict[str, Any],
    baseline: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    source = manifest.get("source_execution")
    expected = baseline.get("historical_execution_source")
    require(isinstance(source, dict) and isinstance(expected, dict),
            "historical execution source is missing")
    source_keys = (
        "a1_original_status", "a2_original_status",
        "a2_command_status", "a2_manifest",
    )
    for key in source_keys:
        require(source.get(key) == expected.get(key),
                f"historical execution {key} binding mismatch")
    a1_status = validate_artifact(
        root, source["a1_original_status"], "A1 original status")
    a2_status = validate_artifact(
        root, source["a2_original_status"], "A2 original status")
    command_status = validate_artifact(
        root, source["a2_command_status"], "A2 command status")
    source_manifest_path = validate_artifact(
        root, source["a2_manifest"], "A2 source manifest")
    expected_failure = (
        "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0")
    require(a1_status.read_text(encoding="utf-8").strip() == expected_failure,
            "A1 original FAIL status changed")
    require(a2_status.read_text(encoding="utf-8").strip() == expected_failure,
            "A2 original FAIL status changed")
    pairs: dict[str, str] = {}
    for line in command_status.read_text(encoding="utf-8").splitlines():
        require(line.count("=") == 1, "A2 command status line is invalid")
        key, value = line.split("=", 1)
        require(key not in pairs, "A2 command status key is duplicated")
        pairs[key] = value
    expected_pairs = {
        "preflight_rc": "0",
        "stats_on_rc": "0",
        "stats_off_build_rc": "0",
        "stats_off_rc": "0",
        "manifest_rc": "0",
        "audit_rc": "1",
        "postflight_rc": "1",
        "verify_rc": "1",
        "cleanup_rc": "0",
        "stats_off_build_bytes_deleted": "230259728",
    }
    require(pairs == expected_pairs, "A2 command status semantics changed")
    source_manifest = read_json(source_manifest_path, "A2 source manifest")
    require(source_manifest.get("schema") == SOURCE_MANIFEST_SCHEMA,
            "A2 source manifest schema mismatch")
    require(source_manifest.get("design_id") == design_id,
            "A2 source manifest design-id mismatch")
    for key in (
        "arch_stable_result", "measurement_contract", "counter_schema",
        "policy", "simulator", "config", "workloads",
        "instrumentation_noninterference",
    ):
        require(source_manifest.get(key) == manifest.get(key),
                f"A2 frozen execution {key} differs from replay manifest")
    return source


def validate_postflight(
    root: pathlib.Path, manifest: dict[str, Any], design_id: str,
) -> dict[str, Any]:
    record = manifest.get("postflight_arch_stable_verify")
    path = validate_artifact(root, record, "postflight ARCH_STABLE verify log")
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise BaselineError(f"cannot read postflight ARCH_STABLE log: {exc}") from exc
    require(len(text.encode("utf-8")) <= 1024 * 1024,
            "postflight ARCH_STABLE log exceeds size limit")
    markers = [line for line in text.splitlines()
               if line.startswith("[ARCH-STABLE] ")]
    require(markers == [
        "[ARCH-STABLE] status=ARCH_STABLE ppa=UNQUALIFIED "
        "promotion_eligible=false blockers=0"
    ], "postflight ARCH_STABLE PASS marker mismatch")
    require("ARCH-STABLE-GAP" not in text
            and "ARCH-STABLE-ERROR" not in text
            and "ARCH-STABLE-VERIFY-ERROR" not in text,
            "postflight ARCH_STABLE error marker observed")
    require(DESIGN_ID_RE.fullmatch(design_id) is not None,
            "postflight design-id binding is invalid")
    return record


def validate_direct_workload_matrix(
    root: pathlib.Path,
    manifest: dict[str, Any],
    baseline: dict[str, Any],
    measurement: dict[str, Any],
    policy: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    """Validate the explicit scope matrix for a fresh v3 baseline.

    The matrix grants only the two-workload deterministic baseline.  It must
    keep system, FP/vector, occupancy and global-representativeness gaps
    visible so a narrow CPI receipt cannot be read as a full performance or
    PPA claim.
    """

    record = manifest.get("workload_matrix")
    require(record == baseline.get("workload_matrix"),
            "baseline workload-matrix binding mismatch")
    require(record == measurement.get("workload_matrix"),
            "measurement workload-matrix binding mismatch")
    path = validate_artifact(root, record, "workload matrix")
    matrix = read_json(path, "workload matrix")
    require(matrix.get("schema") == WORKLOAD_MATRIX_SCHEMA,
            "workload matrix schema mismatch")
    require(matrix.get("state") == "FROZEN_SCOPED_BASELINE_MATRIX",
            "workload matrix is not frozen")
    require(matrix.get("design_id") == design_id,
            "workload matrix design-id mismatch")
    require(matrix.get("performance_baseline_eligible") is True
            and matrix.get("global_representativeness") is False,
            "workload matrix claim boundary mismatch")
    require(matrix.get("qualified_baseline_workloads")
            == ["coremark", "dhrystone_10000"],
            "workload matrix qualified cohort mismatch")

    categories = matrix.get("coverage_categories")
    required_categories = {
        "integer_control", "branch_control", "memory_locality",
        "floating_point_vector", "privilege_system",
    }
    require(isinstance(categories, dict)
            and set(categories) == required_categories,
            "workload matrix coverage categories mismatch")
    require(categories["integer_control"].get("status")
            == "QUALIFIED_SCOPED_BASELINE"
            and categories["branch_control"].get("status")
            == "QUALIFIED_SCOPED_BASELINE"
            and categories["memory_locality"].get("status")
            == "DIAGNOSTIC_WITHIN_SCOPED_BASELINE"
            and categories["floating_point_vector"].get("status")
            == "NOT_COVERED_BY_SCOPED_BASELINE"
            and categories["privilege_system"].get("status")
            == "FUNCTIONAL_ONLY_NOT_CPI_BASELINE",
            "workload matrix category status mismatch")
    representative = matrix.get("representative_sample_policy")
    require(isinstance(representative, dict)
            and representative.get("state") == "PENDING_FULL_CPI_CENSUS",
            "workload matrix representative-sample gap is missing")

    performance = policy.get("performance_evidence")
    require(isinstance(performance, dict),
            "policy performance evidence is missing")
    policy_binding = performance.get("workload_matrix")
    require(isinstance(policy_binding, dict)
            and policy_binding.get("path") == record.get("path")
            and policy_binding.get("sha256") == record.get("sha256")
            and policy_binding.get("id") == matrix.get("workload_matrix_id"),
            "policy workload-matrix binding mismatch")
    matrix_workloads = matrix.get("workloads")
    baseline_workloads = baseline.get("workloads")
    policy_workloads = performance.get("benchmark_contracts")
    require(all(isinstance(item, dict) for item in (
        matrix_workloads, baseline_workloads, policy_workloads)),
        "workload matrix contracts are incomplete")
    for benchmark in ("coremark", "dhrystone_10000"):
        matrix_workload = matrix_workloads.get(benchmark)
        baseline_workload = baseline_workloads.get(benchmark)
        policy_workload = policy_workloads.get(benchmark)
        manifest_workload = manifest.get("workloads", {}).get(benchmark)
        require(all(isinstance(item, dict) for item in (
            matrix_workload, baseline_workload, policy_workload,
            manifest_workload)), f"{benchmark} workload contract is missing")
        image = manifest_workload.get("image")
        require(matrix_workload.get("image_sha256") == image.get("sha256")
                and baseline_workload.get("image_sha256") == image.get("sha256"),
                f"{benchmark} workload-matrix image mismatch")
        matrix_region = matrix_workload.get("region")
        policy_region = policy_workload.get("region")
        require(isinstance(matrix_region, dict) and isinstance(policy_region, dict),
                f"{benchmark} workload region is missing")
        for key, matrix_key, baseline_key in (
            ("start_pc", "start_pc", "start_pc"),
            ("stop_pc", "stop_pc", "stop_pc"),
            ("start_hits", "start_hits", "required_start_hits"),
            ("stop_hits", "stop_hits", "required_stop_hits"),
        ):
            require(matrix_region.get(matrix_key) == policy_region.get(key)
                    and matrix_region.get(matrix_key)
                    == baseline_workload.get(baseline_key),
                    f"{benchmark} workload region binding mismatch")
    return matrix


def validate_direct_measurement_identity(
    root: pathlib.Path,
    manifest: dict[str, Any],
    baseline: dict[str, Any],
    measurement: dict[str, Any],
    design_id: str,
) -> None:
    require(measurement.get("performance_baseline_eligible") is True
            and measurement.get("contract_state")
            == "FROZEN_SCOPED_CURRENT_DESIGN_BASELINE",
            "direct measurement contract is not baseline eligible")
    current = measurement.get("current_identity")
    require(isinstance(current, dict) and current.get("design_id") == design_id,
            "direct measurement current identity mismatch")
    binding = baseline.get("current_arch_stable_binding")
    require(isinstance(binding, dict), "direct baseline identity is missing")
    require(current.get("arch_stable_result") == manifest.get("arch_stable_result")
            and current.get("arch_stable_candidate") == binding.get("candidate")
            and current.get("simulator") == manifest.get("simulator"),
            "direct measurement artifact identity mismatch")
    pre = validate_artifact(
        root, current.get("functional_inputs_pre"),
        "functional input manifest before")
    post = validate_artifact(
        root, current.get("functional_inputs_post"),
        "functional input manifest after")
    require(pre.read_bytes() == post.read_bytes(),
            "functional input manifests changed across execution")
    pre_value = read_json(pre, "functional input manifest before")
    require(pre_value.get("schema")
            == "npc-rv64-full-core-functional-input-binding-v2"
            and pre_value.get("design_id") == design_id,
            "functional input manifest identity mismatch")
    counter_binding = measurement.get("counter_schema_binding")
    require(isinstance(counter_binding, dict)
            and all(counter_binding.get(key)
                    == manifest.get("counter_schema", {}).get(key)
                    for key in ("path", "sha256", "size_bytes")),
            "direct measurement counter binding mismatch")


def validate_stats_on_preflight(
    root: pathlib.Path,
    manifest: dict[str, Any],
    arch_stable: dict[str, Any],
    baseline: dict[str, Any],
    measurement: dict[str, Any],
    policy: dict[str, Any],
    design_id: str,
) -> None:
    """Reject stale current-design inputs before the first simulation."""

    validate_functional_identity(root, manifest, arch_stable, measurement)
    validate_current_baseline_binding(
        root, manifest, arch_stable, baseline)
    validate_direct_measurement_identity(
        root, manifest, baseline, measurement, design_id)
    validate_direct_workload_matrix(
        root, manifest, baseline, measurement, policy, design_id)
    simulator = validate_artifact(root, manifest.get("simulator"), "simulator")
    marker_bytes = simulator.read_bytes()
    for marker in (b"COUNTERS_FINAL", b"npc-rv64-performance-counter-v4"):
        require(marker in marker_bytes,
                f"simulator counter marker is missing: {marker.decode()}")
    config = validate_artifact(root, manifest.get("config"), "configuration")
    config_text = config.read_text(encoding="utf-8")
    require("CONFIG_NPC_OOO_STATS=y" in config_text,
            "stats-on configuration is not enabled")


def validate_contracts(
    root: pathlib.Path, manifest: dict[str, Any], design_id: str,
) -> tuple[
    dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any],
    dict[str, Any] | None, str,
]:
    baseline_path = validate_artifact(
        root, manifest.get("baseline_contract"), "current baseline contract")
    measurement_path = validate_artifact(
        root, manifest.get("measurement_contract"), "measurement contract")
    counter_path = validate_artifact(
        root, manifest.get("counter_schema"), "counter schema")
    policy_path = validate_artifact(root, manifest.get("policy"), "PPA policy")
    baseline = read_json(baseline_path, "current baseline contract")
    measurement = read_json(measurement_path, "measurement contract")
    counter = read_json(counter_path, "counter schema")
    policy = read_json(policy_path, "PPA policy")
    baseline_schema = baseline.get("schema")
    require(baseline_schema in {
        LEGACY_BASELINE_CONTRACT_SCHEMA, CURRENT_BASELINE_CONTRACT_SCHEMA,
        DIRECT_BASELINE_CONTRACT_SCHEMA},
        "current baseline contract schema mismatch")
    require(baseline.get("performance_baseline_eligible") is True,
            "current baseline contract is not baseline eligible")
    expected_measurement_schema = (
        DIRECT_MEASUREMENT_CONTRACT_SCHEMA
        if baseline_schema == DIRECT_BASELINE_CONTRACT_SCHEMA
        else MEASUREMENT_CONTRACT_SCHEMA
    )
    require(measurement.get("schema") == expected_measurement_schema,
            "measurement contract schema mismatch")
    current_binding = baseline.get("current_arch_stable_binding")
    require(isinstance(current_binding, dict),
            "measurement contract current ARCH_STABLE binding is missing")
    require(current_binding.get("design_id") == design_id,
            "current baseline contract design-id mismatch")
    for key, manifest_key in (
        ("measurement_contract", "measurement_contract"),
        ("counter_schema", "counter_schema"),
        ("policy", "policy"),
    ):
        require(baseline.get(key) == manifest.get(manifest_key),
                f"current baseline contract {key} binding mismatch")
    performance = policy.get("performance_evidence")
    require(isinstance(performance, dict), "policy performance evidence is missing")
    contract_binding = performance.get("measurement_contract")
    counter_binding = performance.get("counter_schema")
    require(isinstance(contract_binding, dict) and isinstance(counter_binding, dict),
            "policy contract bindings are missing")
    require(contract_binding.get("id") == measurement.get(
        "performance_measurement_contract_id"),
        "policy measurement contract id mismatch")
    require(contract_binding.get("path") == manifest["measurement_contract"]["path"]
            and contract_binding.get("sha256") == manifest["measurement_contract"]["sha256"],
            "policy measurement contract artifact mismatch")
    require(counter_binding.get("id") == counter.get(
        "performance_counter_schema_id"),
            "policy counter schema id mismatch")
    require(counter_binding.get("path") == manifest["counter_schema"]["path"]
            and counter_binding.get("sha256") == manifest["counter_schema"]["sha256"],
            "policy counter schema artifact mismatch")
    require(performance.get("minimum_repetitions") == 3
            and performance.get("require_bit_exact_repetition_counters") is True,
            "policy repetition contract mismatch")
    amendment = None
    if baseline_schema == CURRENT_BASELINE_CONTRACT_SCHEMA:
        amendment = validate_boundary_amendment(
            root, manifest, baseline, measurement, counter)
        validate_source_execution(root, manifest, baseline, design_id)
    elif baseline_schema == DIRECT_BASELINE_CONTRACT_SCHEMA:
        require(manifest.get("schema") == DIRECT_MANIFEST_SCHEMA,
                "direct baseline requires a v3 manifest")
        amendment = validate_boundary_amendment(
            root, manifest, baseline, measurement, counter)
        require(manifest.get("source_execution") is None,
                "direct baseline cannot reuse historical execution")
        validate_direct_measurement_identity(
            root, manifest, baseline, measurement, design_id)
        validate_direct_workload_matrix(
            root, manifest, baseline, measurement, policy, design_id)
    else:
        require(manifest.get("schema") == LEGACY_MANIFEST_SCHEMA,
                "legacy baseline requires a v1 manifest")
        require(manifest.get("boundary_qualification_amendment") is None
                and manifest.get("source_execution") is None,
                "legacy baseline cannot carry composite replay evidence")
    return baseline, measurement, counter, policy, amendment, baseline_schema


def validate_functional_identity(
    root: pathlib.Path,
    manifest: dict[str, Any],
    arch_stable: dict[str, Any],
    measurement_contract: dict[str, Any],
) -> None:
    functional = arch_stable.get("observed", {}).get("functional")
    require(isinstance(functional, dict), "ARCH_STABLE functional identity is missing")
    simulator = manifest.get("simulator")
    config = manifest.get("config")
    simulator_path = validate_artifact(root, simulator, "simulator")
    validate_artifact(root, config, "configuration")
    with simulator_path.open("rb") as stream:
        simulator_elf_header = stream.read(4)
    require(os.access(simulator_path, os.X_OK)
            and simulator_elf_header == b"\x7fELF",
            "simulator is not an executable ELF image")

    require(same_artifact_record(simulator, functional.get("simulator")),
            "simulator does not match ARCH_STABLE functional identity")
    observed_config = functional.get("configuration")
    require(isinstance(observed_config, dict), "ARCH_STABLE configuration is missing")
    require(config.get("sha256") == observed_config.get("sha256"),
            "configuration does not match ARCH_STABLE identity")
    expected_images = measurement_contract.get("workload_binary_id")
    require(isinstance(expected_images, dict), "measurement workload hashes are missing")
    for benchmark, functional_name in (
        ("coremark", "coremark"),
        ("dhrystone_10000", "dhrystone"),
    ):
        record = manifest["workloads"][benchmark]["image"]
        observed = functional.get("benchmarks", {}).get(functional_name, {}).get("image")
        require(same_artifact_record(record, observed),
                f"{benchmark} image does not match ARCH_STABLE identity")
        expected_image = expected_images.get(benchmark)
        require(isinstance(expected_image, str)
                and expected_image == f"sha256:{record.get('sha256')}",
                f"{benchmark} image does not match measurement contract")


def validate_current_baseline_binding(
    root: pathlib.Path,
    manifest: dict[str, Any],
    arch_stable: dict[str, Any],
    baseline_contract: dict[str, Any],
) -> None:
    binding = baseline_contract["current_arch_stable_binding"]
    require(binding.get("result") == manifest.get("arch_stable_result"),
            "current baseline contract ARCH_STABLE result mismatch")
    candidate = binding.get("candidate")
    validate_artifact(root, candidate, "current baseline ARCH_STABLE candidate")
    observed_candidate = arch_stable.get("candidate")
    require(isinstance(observed_candidate, dict)
            and all(candidate.get(key) == observed_candidate.get(key)
                    for key in ("path", "sha256", "size_bytes")),
            "current baseline contract ARCH_STABLE candidate mismatch")
    require(binding.get("simulator_sha256") == manifest["simulator"].get("sha256"),
            "current baseline contract simulator mismatch")
    require(binding.get("config_sha256") == manifest["config"].get("sha256"),
            "current baseline contract configuration mismatch")
    workloads = baseline_contract.get("workloads")
    require(isinstance(workloads, dict), "current baseline workloads are missing")
    for benchmark in ("coremark", "dhrystone_10000"):
        expected = workloads.get(benchmark)
        require(isinstance(expected, dict),
                f"current baseline {benchmark} contract is missing")
        require(expected.get("image_sha256")
                == manifest["workloads"][benchmark]["image"].get("sha256"),
                f"current baseline {benchmark} image mismatch")
        if baseline_contract.get("schema") == DIRECT_BASELINE_CONTRACT_SCHEMA:
            require(expected.get("image")
                    == manifest["workloads"][benchmark]["image"],
                    f"direct baseline {benchmark} image artifact mismatch")
    execution = baseline_contract.get("execution_requirements")
    require(isinstance(execution, dict),
            "current baseline execution requirements are missing")
    require(execution.get("stats_on_repetitions_per_workload") == 3
            and execution.get("stats_off_repetitions_per_workload") == 1
            and execution.get("stats_off_builds") == 1
            and execution.get("outlier_removal") is False,
            "current baseline execution requirements mismatch")
    if baseline_contract.get("schema") == DIRECT_BASELINE_CONTRACT_SCHEMA:
        require(binding.get("simulator") == manifest.get("simulator"),
                "direct baseline simulator artifact mismatch")
        require(execution.get("mode") == "FRESH_CURRENT_DESIGN_DIRECT"
                and execution.get("historical_counter_reuse") is False,
                "direct baseline execution mode mismatch")
        claim = baseline_contract.get("claim_boundary")
        require(isinstance(claim, dict)
                and claim.get("maturity_stage") == "PERF_BASELINE"
                and claim.get("global_workload_representativeness") is False
                and claim.get("full_causal_cpi_stack") is False
                and claim.get("ppa") == "UNQUALIFIED"
                and claim.get("promotion_eligible") is False,
                "direct baseline claim boundary mismatch")


def build_result(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    *,
    require_postflight: bool = True,
) -> dict[str, Any]:
    manifest = read_json(manifest_path, "performance baseline manifest")
    require(manifest.get("schema") in {
        LEGACY_MANIFEST_SCHEMA, MANIFEST_SCHEMA, DIRECT_MANIFEST_SCHEMA},
            "manifest schema mismatch")
    design_id = manifest.get("design_id")
    require(isinstance(design_id, str) and DESIGN_ID_RE.fullmatch(design_id) is not None,
            "manifest design-id is invalid")
    arch_stable = validate_arch_stable(root, manifest, design_id)
    (baseline_contract, measurement_contract, counter, policy,
     amendment, baseline_schema) = validate_contracts(
         root, manifest, design_id)
    validate_functional_identity(
        root, manifest, arch_stable, measurement_contract)
    validate_current_baseline_binding(
        root, manifest, arch_stable, baseline_contract)
    benchmarks = {
        name: parse_workload(
            root, manifest, name, policy, counter, amendment is not None)
        for name in ("coremark", "dhrystone_10000")
    }
    noninterference = manifest.get("instrumentation_noninterference")
    require(isinstance(noninterference, dict),
            "instrumentation non-interference evidence is missing")
    require(noninterference.get("mode") == "CONFIG_NPC_OOO_STATS=n",
            "instrumentation non-interference mode mismatch")
    stats_off_simulator = validate_artifact(
        root, noninterference.get("stats_off_simulator"), "stats-off simulator")
    with stats_off_simulator.open("rb") as stream:
        stats_off_elf_header = stream.read(4)
    require(os.access(stats_off_simulator, os.X_OK)
            and stats_off_elf_header == b"\x7fELF",
            "stats-off simulator is not an executable ELF image")
    require(noninterference["stats_off_simulator"].get("sha256")
            != manifest["simulator"].get("sha256"),
            "stats-off simulator must differ from the stats-on simulator")
    off_logs = noninterference.get("logs")
    require(isinstance(off_logs, dict), "stats-off logs are missing")
    comparisons: dict[str, Any] = {}
    contracts = policy["performance_evidence"]["benchmark_contracts"]
    for benchmark in ("coremark", "dhrystone_10000"):
        path = validate_artifact(
            root, off_logs.get(benchmark), f"{benchmark} stats-off log")
        observed = parse_stats_off_log(path, benchmark, contracts[benchmark])
        expected = benchmarks[benchmark]
        require(observed["cycles"] == expected["cycles"],
                f"{benchmark} stats on/off cycle mismatch")
        require(observed["retired_instructions"] == expected["retired_instructions"],
                f"{benchmark} stats on/off retired mismatch")
        comparisons[benchmark] = {
            **observed,
            "matches_stats_on": True,
            "log": off_logs[benchmark],
        }
    composite_replay = baseline_schema == CURRENT_BASELINE_CONTRACT_SCHEMA
    direct_execution = baseline_schema == DIRECT_BASELINE_CONTRACT_SCHEMA
    versioned_current = composite_replay or direct_execution
    if versioned_current and require_postflight:
        postflight = validate_postflight(root, manifest, design_id)
        status = "PERF_BASELINE"
        result_schema = (
            DIRECT_RESULT_SCHEMA if direct_execution else RESULT_SCHEMA)
        blockers: list[str] = []
    elif versioned_current:
        require(manifest.get("postflight_arch_stable_verify") is None,
                "precheck manifest must not contain postflight evidence")
        postflight = None
        status = "PERF_BASELINE_PRECHECK"
        result_schema = (
            DIRECT_PRECHECK_SCHEMA if direct_execution else PRECHECK_SCHEMA)
        blockers = ["fresh postflight ARCH_STABLE verify and final binding pending"]
    else:
        postflight = None
        status = "PERF_BASELINE"
        result_schema = LEGACY_RESULT_SCHEMA
        blockers = []
    result = {
        "schema": result_schema,
        "status": status,
        "maturity_stage": status,
        "design_id": design_id,
        "arch_stable": manifest["arch_stable_result"],
        "manifest": artifact(root, manifest_path),
        "baseline_contract": manifest["baseline_contract"],
        "measurement_contract": manifest["measurement_contract"],
        "counter_schema": manifest["counter_schema"],
        "policy": manifest["policy"],
        "identity": {
            "simulator": manifest["simulator"],
            "configuration": manifest["config"],
            "stats_off_simulator": noninterference["stats_off_simulator"],
        },
        "benchmarks": benchmarks,
        "repeatability": {
            "repetitions_per_workload": 3,
            "bit_exact_cycles_retired_and_counter_stack": True,
            "outliers_removed": 0,
        },
        "instrumentation_noninterference": {
            "status": "PASS",
            "observer_mode": "stats-on baseline versus CONFIG_NPC_OOO_STATS=n",
            "comparisons": comparisons,
        },
        "blockers": blockers,
        "unknowns": [],
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
        "scope": (
            "current ARCH_STABLE simulator; deterministic CoreMark10 and "
            "Dhrystone10000 endpoint-corrected PC-bounded CPI/IPC only"
        ),
    }
    if direct_execution:
        result.update({
            "boundary_qualification_amendment": manifest[
                "boundary_qualification_amendment"],
            "workload_matrix": manifest["workload_matrix"],
            "execution_mode": "FRESH_CURRENT_DESIGN_DIRECT",
            "postflight_arch_stable_verify": postflight,
            "claim_boundary": baseline_contract["claim_boundary"],
        })
    elif composite_replay:
        result.update({
            "boundary_qualification_amendment": manifest[
                "boundary_qualification_amendment"],
            "source_execution": manifest["source_execution"],
            "postflight_arch_stable_verify": postflight,
        })
    return result


def build_manifest(root: pathlib.Path, args: argparse.Namespace) -> dict[str, Any]:
    arch_path = (root / args.arch_stable_result).resolve()
    arch = read_json(arch_path, "ARCH_STABLE result")
    design_id = arch.get("design_id")
    require(isinstance(design_id, str) and DESIGN_ID_RE.fullmatch(design_id) is not None,
            "ARCH_STABLE result design-id is invalid")

    def record(value: pathlib.Path) -> dict[str, Any]:
        path = value if value.is_absolute() else root / value
        return artifact(root, path)

    baseline_path = (
        args.baseline_contract if args.baseline_contract.is_absolute()
        else root / args.baseline_contract)
    baseline = read_json(baseline_path.resolve(), "baseline contract")
    baseline_schema = baseline.get("schema")
    require(baseline_schema in {
        LEGACY_BASELINE_CONTRACT_SCHEMA, CURRENT_BASELINE_CONTRACT_SCHEMA,
        DIRECT_BASELINE_CONTRACT_SCHEMA},
        "baseline contract schema mismatch")
    composite_replay = baseline_schema == CURRENT_BASELINE_CONTRACT_SCHEMA
    direct_execution = baseline_schema == DIRECT_BASELINE_CONTRACT_SCHEMA
    value = {
        "schema": (
            DIRECT_MANIFEST_SCHEMA if direct_execution
            else MANIFEST_SCHEMA if composite_replay
            else LEGACY_MANIFEST_SCHEMA),
        "design_id": design_id,
        "arch_stable_result": record(args.arch_stable_result),
        "baseline_contract": record(args.baseline_contract),
        "measurement_contract": record(args.measurement_contract),
        "counter_schema": record(args.counter_schema),
        "policy": record(args.policy),
        "simulator": record(args.simulator),
        "config": record(args.config),
        "workloads": {
            "coremark": {
                "image": record(args.coremark_image),
                "logs": [record(path) for path in args.coremark_log],
            },
            "dhrystone_10000": {
                "image": record(args.dhrystone_image),
                "logs": [record(path) for path in args.dhrystone_log],
            },
        },
        "instrumentation_noninterference": {
            "mode": "CONFIG_NPC_OOO_STATS=n",
            "stats_off_simulator": record(args.stats_off_simulator),
            "logs": {
                "coremark": record(args.coremark_stats_off_log),
                "dhrystone_10000": record(args.dhrystone_stats_off_log),
            },
        },
        "execution": {
            "simulator_reuse": "one immutable stats-on binary for six sequential runs",
            "stats_off_builds": 1,
            "production_rtl_modified": False,
            "simulation_synthesis_sta_power_claim": "simulation CPI only",
        },
    }
    composite_args = (
        args.boundary_qualification_amendment,
        args.source_a1_status,
        args.source_a2_status,
        args.source_a2_command_status,
        args.source_a2_manifest,
    )
    if composite_replay:
        require(all(item is not None for item in composite_args),
                "composite replay manifest arguments are incomplete")
        value.update({
            "boundary_qualification_amendment": record(
                args.boundary_qualification_amendment),
            "source_execution": {
                "a1_original_status": record(args.source_a1_status),
                "a2_original_status": record(args.source_a2_status),
                "a2_command_status": record(args.source_a2_command_status),
                "a2_manifest": record(args.source_a2_manifest),
            },
        })
        require(args.workload_matrix is None,
                "composite replay cannot bind a direct workload matrix")
    elif direct_execution:
        require(args.boundary_qualification_amendment is not None
                and args.workload_matrix is not None,
                "direct manifest contract arguments are incomplete")
        require(all(item is None for item in composite_args[1:]),
                "direct manifest cannot bind historical execution")
        value.update({
            "boundary_qualification_amendment": record(
                args.boundary_qualification_amendment),
            "workload_matrix": record(args.workload_matrix),
        })
    else:
        require(all(item is None for item in composite_args),
                "legacy manifest cannot bind composite replay arguments")
        require(args.workload_matrix is None,
                "legacy manifest cannot bind a direct workload matrix")
    return value


def build_input_preflight(
    root: pathlib.Path, args: argparse.Namespace,
) -> dict[str, Any]:
    """Validate every current-design input before the driver may run DUT."""

    def record(value: pathlib.Path) -> dict[str, Any]:
        path = value if value.is_absolute() else root / value
        return artifact(root, path)

    arch = read_json(
        (args.arch_stable_result if args.arch_stable_result.is_absolute()
         else root / args.arch_stable_result).resolve(),
        "ARCH_STABLE result")
    design_id = arch.get("design_id")
    require(isinstance(design_id, str)
            and DESIGN_ID_RE.fullmatch(design_id) is not None,
            "ARCH_STABLE result design-id is invalid")
    manifest = {
        "schema": DIRECT_MANIFEST_SCHEMA,
        "design_id": design_id,
        "arch_stable_result": record(args.arch_stable_result),
        "baseline_contract": record(args.baseline_contract),
        "measurement_contract": record(args.measurement_contract),
        "counter_schema": record(args.counter_schema),
        "boundary_qualification_amendment": record(
            args.boundary_qualification_amendment),
        "workload_matrix": record(args.workload_matrix),
        "policy": record(args.policy),
        "simulator": record(args.simulator),
        "config": record(args.config),
        "workloads": {
            "coremark": {"image": record(args.coremark_image)},
            "dhrystone_10000": {"image": record(args.dhrystone_image)},
        },
    }
    arch_stable = validate_arch_stable(root, manifest, design_id)
    (baseline, measurement, _counter, policy, _amendment,
     baseline_schema) = validate_contracts(root, manifest, design_id)
    require(baseline_schema == DIRECT_BASELINE_CONTRACT_SCHEMA,
            "input preflight requires a direct v3 baseline contract")
    validate_stats_on_preflight(
        root, manifest, arch_stable, baseline, measurement, policy, design_id)
    return {
        "schema": INPUT_PREFLIGHT_SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "arch_stable_result": manifest["arch_stable_result"],
        "baseline_contract": manifest["baseline_contract"],
        "measurement_contract": manifest["measurement_contract"],
        "counter_schema": manifest["counter_schema"],
        "boundary_qualification_amendment": manifest[
            "boundary_qualification_amendment"],
        "workload_matrix": manifest["workload_matrix"],
        "policy": manifest["policy"],
        "simulator": manifest["simulator"],
        "configuration": manifest["config"],
        "workloads": {
            name: value["image"] for name, value in manifest["workloads"].items()
        },
        "checks": {
            "arch_stable_current_identity": "PASS",
            "candidate_and_functional_inputs": "PASS",
            "simulator_elf_and_counter_markers": "PASS",
            "stats_on_configuration": "PASS",
            "workload_matrix_scope": "PASS",
            "contract_hashes": "PASS",
            "historical_counter_reuse": "REJECTED_BY_CONTRACT"
        },
        "claim_boundary": baseline["claim_boundary"],
    }


def bind_postflight(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    postflight_path: pathlib.Path,
) -> dict[str, Any]:
    manifest = read_json(manifest_path, "precheck manifest")
    require(manifest.get("schema") in {MANIFEST_SCHEMA, DIRECT_MANIFEST_SCHEMA},
            "precheck manifest schema mismatch")
    require(manifest.get("postflight_arch_stable_verify") is None,
            "precheck manifest already has postflight evidence")
    manifest["postflight_arch_stable_verify"] = artifact(root, postflight_path)
    return manifest


def build_replay_manifest(
    root: pathlib.Path,
    source_manifest_path: pathlib.Path,
    baseline_contract_path: pathlib.Path,
    amendment_path: pathlib.Path,
) -> dict[str, Any]:
    source = read_json(source_manifest_path, "A2 source manifest")
    require(source.get("schema") == LEGACY_MANIFEST_SCHEMA,
            "replay source manifest schema mismatch")
    baseline = read_json(baseline_contract_path, "composite baseline contract")
    require(baseline.get("schema") == CURRENT_BASELINE_CONTRACT_SCHEMA,
            "composite baseline contract schema mismatch")
    source_record = artifact(root, source_manifest_path)
    historical = baseline.get("historical_execution_source")
    require(isinstance(historical, dict)
            and historical.get("a2_manifest") == source_record,
            "replay source manifest does not match the composite contract")
    amendment_record = artifact(root, amendment_path)
    require(baseline.get("boundary_qualification_amendment") == amendment_record,
            "replay boundary amendment does not match the composite contract")
    value = {
        key: source[key]
        for key in (
            "design_id", "arch_stable_result", "measurement_contract",
            "counter_schema", "policy", "simulator", "config", "workloads",
            "instrumentation_noninterference", "execution",
        )
    }
    value.update({
        "schema": MANIFEST_SCHEMA,
        "baseline_contract": artifact(root, baseline_contract_path),
        "boundary_qualification_amendment": amendment_record,
        "source_execution": {
            key: historical[key]
            for key in (
                "a1_original_status", "a2_original_status",
                "a2_command_status", "a2_manifest",
            )
        },
    })
    value["execution"] = {
        **value["execution"],
        "evidence_reuse": "frozen A2 execution with versioned checker replay",
        "production_rtl_modified": False,
    }
    return value


def read_status_pairs(path: pathlib.Path, label: str) -> dict[str, str]:
    pairs: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        require(line.count("=") == 1, f"{label} line is invalid")
        key, value = line.split("=", 1)
        require(bool(key) and key not in pairs, f"{label} key is duplicated")
        pairs[key] = value
    return pairs


def validate_independent_review_v1(
    root: pathlib.Path, review: dict[str, Any],
) -> dict[str, Any]:
    require(review.get("decision") == "APPROVE_PERF_BASELINE",
            "independent review decision mismatch")
    design_id = review.get("design_id")
    require(isinstance(design_id, str)
            and DESIGN_ID_RE.fullmatch(design_id) is not None,
            "independent review design-id mismatch")
    require(review.get("open_blockers") == [],
            "independent review blockers are nonempty")
    scope = review.get("review_scope")
    require(isinstance(scope, dict), "independent review scope is missing")
    for key in (
        "legacy_v1_phase_rejection", "endpoint_amendment_precedence",
        "cycle_and_slot_conservation", "bit_exact_repetitions",
        "instrumentation_noninterference", "historical_fail_immutability",
        "fresh_arch_stable_postflight", "canonical_build_and_verify",
    ):
        require(scope.get(key) == "PASS",
                f"independent review {key} did not pass")
    require(scope.get("ppa") == "UNQUALIFIED"
            and scope.get("promotion_eligible") is False,
            "independent review PPA boundary mismatch")
    result_path = validate_artifact(
        root, review.get("result"), "independent review result")
    final_manifest = validate_artifact(
        root, review.get("final_manifest"), "independent review final manifest")
    validate_artifact(
        root, review.get("reviewer_contract"), "independent reviewer contract")
    validate_artifact(
        root, review.get("review_report"), "independent review report")
    task_status = validate_artifact(
        root, review.get("task_run_status"), "composite task-run status")
    command_status = validate_artifact(
        root, review.get("command_status"), "composite command status")
    regression = validate_artifact(
        root, review.get("checker_regression"), "checker regression")
    require(task_status.read_text(encoding="utf-8").strip() == "PASS",
            "composite task-run status is not PASS")
    command_pairs = read_status_pairs(command_status, "composite command status")
    require(command_pairs == {
        "manifest_rc": "0", "precheck_rc": "0", "postflight_rc": "0",
        "bind_rc": "0", "build_rc": "0", "verify_rc": "0",
    }, "composite command status is not all-zero")
    regression_text = regression.read_text(encoding="utf-8")
    require("Ran 72 tests" in regression_text
            and regression_text.rstrip().endswith("OK"),
            "checker regression PASS marker mismatch")
    stored = read_json(result_path, "reviewed performance baseline result")
    require(stored.get("schema") == RESULT_SCHEMA
            and stored.get("status") == "PERF_BASELINE"
            and stored.get("design_id") == design_id,
            "reviewed performance baseline result identity mismatch")
    require(same_artifact_record(stored.get("manifest"), review.get("final_manifest")),
            "reviewed result final-manifest binding mismatch")
    recomputed = build_result(root, final_manifest)
    require(stored == recomputed,
            "independent review result is not canonical")
    return stored


def validate_independent_review_v2(
    root: pathlib.Path, review: dict[str, Any],
) -> dict[str, Any]:
    require(review.get("decision") == "APPROVE_PERF_BASELINE",
            "independent review decision mismatch")
    design_id = review.get("design_id")
    require(isinstance(design_id, str)
            and DESIGN_ID_RE.fullmatch(design_id) is not None,
            "independent review design-id mismatch")
    require(review.get("open_blockers") == [],
            "independent review blockers are nonempty")

    scope = review.get("review_scope")
    require(isinstance(scope, dict), "independent review scope is missing")
    for key in (
        "current_design_identity", "input_preflight_before_first_simulation",
        "committed_pc_boundaries", "cycle_and_slot_conservation",
        "bit_exact_repetitions", "instrumentation_noninterference",
        "fail_closed_status", "cleanup_receipt", "negative_mutations",
        "historical_result_non_rebinding", "canonical_build_and_verify",
    ):
        require(scope.get(key) == "PASS",
                f"independent review {key} did not pass")
    require(scope.get("scoped_workloads")
            == ["coremark", "dhrystone_10000"],
            "independent review workload scope mismatch")
    require(scope.get("global_workload_representativeness") is False
            and scope.get("full_causal_cpi_stack") is False,
            "independent review performance claim boundary mismatch")
    require(scope.get("ppa") == "UNQUALIFIED"
            and scope.get("promotion_eligible") is False,
            "independent review PPA boundary mismatch")

    result_record = review.get("result")
    result_path = validate_artifact(
        root, result_record, "independent review result")
    final_manifest = validate_artifact(
        root, review.get("final_manifest"), "independent review final manifest")
    reviewer_contract = validate_artifact(
        root, review.get("reviewer_contract"), "independent reviewer contract")
    report = validate_artifact(
        root, review.get("review_report"), "independent review report")
    task_status = validate_artifact(
        root, review.get("task_run_status"), "direct task-run status")
    command_status = validate_artifact(
        root, review.get("command_status"), "direct command status")
    regression = validate_artifact(
        root, review.get("checker_regression"), "checker regression")
    cleanup_path = validate_artifact(
        root, review.get("cleanup_receipt"), "cleanup receipt")

    workflow = review.get("workflow_artifacts")
    require(isinstance(workflow, dict),
            "independent review workflow artifacts are missing")
    expected_workflow_paths = {
        "checker": "npc/rv64/eval/ppa/tools/performance_baseline_current.py",
        "checker_helper": "npc/rv64/eval/ppa/tools/check.py",
        "runner": "npc/rv64/eval/ppa/run-performance-baseline-current.sh",
        "status_helper": "scripts/task-run-status.sh",
        "current_tests": (
            "npc/rv64/eval/ppa/tests/test_performance_baseline_current.py"),
        "direct_tests": (
            "npc/rv64/eval/ppa/tests/test_performance_baseline_v3.py"),
        "review_tests": (
            "npc/rv64/eval/ppa/tests/test_performance_baseline_review_v2.py"),
        "result_schema": (
            "npc/rv64/eval/ppa/schemas/"
            "performance-baseline-current-v3.schema.json"),
        "review_schema": (
            "npc/rv64/eval/ppa/schemas/"
            "performance-baseline-independent-review-v2.schema.json"),
    }
    require(set(workflow) == set(expected_workflow_paths),
            "independent review workflow artifact set mismatch")
    for key, expected in expected_workflow_paths.items():
        path = validate_artifact(
            root, workflow.get(key), f"independent review workflow {key}")
        require(path == (root / expected).resolve(),
                f"independent review workflow {key} path mismatch")

    require(task_status.read_text(encoding="utf-8").strip() == "PASS",
            "direct task-run status is not PASS")
    command_pairs = read_status_pairs(command_status, "direct command status")
    zero_keys = {
        "preflight_rc", "stats_on_rc", "stats_off_build_rc", "stats_off_rc",
        "manifest_rc", "precheck_rc", "postflight_rc", "bind_rc",
        "build_rc", "verify_rc", "cleanup_rc",
    }
    require(set(command_pairs) == zero_keys | {"stats_off_build_bytes_deleted"},
            "direct command status key set mismatch")
    require(all(command_pairs[key] == "0" for key in zero_keys),
            "direct command status is not all-zero")
    deleted_text = command_pairs["stats_off_build_bytes_deleted"]
    require(re.fullmatch(r"[1-9][0-9]*", deleted_text) is not None,
            "direct command status cleanup byte count is invalid")
    deleted_bytes = int(deleted_text, 10)

    cleanup = read_json(cleanup_path, "performance baseline cleanup receipt")
    require(set(cleanup) == {
        "schema", "status", "run_directory", "runtime_build_directory",
        "build_tree_absent", "deleted_bytes", "task_run_status",
        "command_status", "reviewer_contract", "checked_at_utc",
    }, "cleanup receipt field set mismatch")
    require(cleanup.get("schema")
            == "npc-rv64-performance-baseline-cleanup-receipt-v1"
            and cleanup.get("status") == "PASS"
            and cleanup.get("build_tree_absent") is True,
            "cleanup receipt status mismatch")
    run_directory = cleanup.get("run_directory")
    require(isinstance(run_directory, str)
            and run_directory.startswith(".github/task-runs/")
            and bool(pathlib.PurePosixPath(run_directory).name),
            "cleanup receipt run directory is invalid")
    run_label = pathlib.PurePosixPath(run_directory).name
    expected_build_directory = (
        ".github/runtime-artifacts/rv64-performance-baseline-run/"
        f"{run_label}/stats-off-build")
    require(cleanup.get("runtime_build_directory")
            == expected_build_directory,
            "cleanup receipt runtime directory mismatch")
    require(result_record.get("path", "").startswith(run_directory + "/")
            and review.get("command_status", {}).get("path", "").startswith(
                run_directory + "/"),
            "cleanup receipt run binding mismatch")
    require(cleanup.get("deleted_bytes") == deleted_bytes,
            "cleanup receipt byte count mismatch")
    require(same_artifact_record(
                cleanup.get("task_run_status"), review.get("task_run_status"))
            and same_artifact_record(
                cleanup.get("command_status"), review.get("command_status"))
            and same_artifact_record(
                cleanup.get("reviewer_contract"), review.get("reviewer_contract")),
            "cleanup receipt artifact binding mismatch")
    require(isinstance(cleanup.get("checked_at_utc"), str)
            and cleanup["checked_at_utc"].endswith("Z"),
            "cleanup receipt timestamp mismatch")

    regression_text = regression.read_text(encoding="utf-8")
    for marker in (
        "test_preflight_rejects_old_design_contract",
        "test_preflight_rejects_noncurrent_simulator_before_execution",
        "test_preflight_rejects_missing_workload_category",
        "test_direct_reused_raw_log_is_rejected",
        "test_direct_v2_review_publishes_current_result",
    ):
        require(marker in regression_text,
                f"checker regression marker is missing: {marker}")
    require(re.search(r"Ran [1-9][0-9]* tests", regression_text) is not None
            and regression_text.rstrip().endswith("OK"),
            "checker regression PASS marker mismatch")

    require(isinstance(result_record, dict),
            "independent review result record is invalid")
    approval_marker = (
        "[PERFORMANCE-BASELINE-INDEPENDENT-REVIEW]"
        "[APPROVE_PERF_BASELINE] "
        f"design_id={design_id} result_sha256={result_record.get('sha256')}")
    require(review.get("approval_marker") == approval_marker,
            "independent review approval marker mismatch")
    report_text = report.read_text(encoding="utf-8")
    require(report_text.count(approval_marker) == 1,
            "independent review report approval marker count mismatch")

    contract = read_json(reviewer_contract, "independent reviewer contract")
    require(contract.get("schema_version") == 2
            and contract.get("task_kind") == "verification",
            "independent reviewer contract identity mismatch")
    stored = read_json(result_path, "reviewed performance baseline result")
    require(stored.get("schema") == DIRECT_RESULT_SCHEMA
            and stored.get("status") == "PERF_BASELINE"
            and stored.get("design_id") == design_id,
            "reviewed direct performance baseline result identity mismatch")
    require(stored.get("blockers") == []
            and stored.get("ppa") == "UNQUALIFIED"
            and stored.get("promotion_eligible") is False,
            "reviewed direct performance baseline status mismatch")
    claim = stored.get("claim_boundary")
    require(isinstance(claim, dict)
            and claim.get("global_workload_representativeness") is False
            and claim.get("full_causal_cpi_stack") is False
            and claim.get("ppa") == "UNQUALIFIED"
            and claim.get("promotion_eligible") is False,
            "reviewed direct performance claim boundary mismatch")
    require(same_artifact_record(stored.get("manifest"),
                                 review.get("final_manifest")),
            "reviewed result final-manifest binding mismatch")
    recomputed = build_result(root, final_manifest)
    require(stored == recomputed,
            "independent review direct result is not canonical")
    return stored


def validate_independent_review(
    root: pathlib.Path, review_path: pathlib.Path,
) -> dict[str, Any]:
    review = read_json(review_path, "performance baseline independent review")
    schema = review.get("schema")
    if schema == INDEPENDENT_REVIEW_V1_SCHEMA:
        return validate_independent_review_v1(root, review)
    if schema == INDEPENDENT_REVIEW_V2_SCHEMA:
        return validate_independent_review_v2(root, review)
    raise BaselineError("independent review schema mismatch")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5])
    sub = result.add_subparsers(dest="command", required=True)
    manifest = sub.add_parser("manifest")
    manifest.add_argument("--output", type=pathlib.Path, required=True)
    manifest.add_argument("--arch-stable-result", type=pathlib.Path, required=True)
    manifest.add_argument("--baseline-contract", type=pathlib.Path, required=True)
    manifest.add_argument("--measurement-contract", type=pathlib.Path, required=True)
    manifest.add_argument("--counter-schema", type=pathlib.Path, required=True)
    manifest.add_argument("--workload-matrix", type=pathlib.Path)
    manifest.add_argument(
        "--boundary-qualification-amendment", type=pathlib.Path)
    manifest.add_argument("--policy", type=pathlib.Path, required=True)
    manifest.add_argument("--simulator", type=pathlib.Path, required=True)
    manifest.add_argument("--config", type=pathlib.Path, required=True)
    manifest.add_argument("--coremark-image", type=pathlib.Path, required=True)
    manifest.add_argument("--dhrystone-image", type=pathlib.Path, required=True)
    manifest.add_argument("--coremark-log", type=pathlib.Path, action="append", required=True)
    manifest.add_argument("--dhrystone-log", type=pathlib.Path, action="append", required=True)
    manifest.add_argument("--stats-off-simulator", type=pathlib.Path, required=True)
    manifest.add_argument("--coremark-stats-off-log", type=pathlib.Path, required=True)
    manifest.add_argument("--dhrystone-stats-off-log", type=pathlib.Path, required=True)
    manifest.add_argument("--source-a1-status", type=pathlib.Path)
    manifest.add_argument("--source-a2-status", type=pathlib.Path)
    manifest.add_argument(
        "--source-a2-command-status", type=pathlib.Path)
    manifest.add_argument("--source-a2-manifest", type=pathlib.Path)
    preflight = sub.add_parser("preflight")
    preflight.add_argument("--output", type=pathlib.Path, required=True)
    preflight.add_argument(
        "--arch-stable-result", type=pathlib.Path, required=True)
    preflight.add_argument(
        "--baseline-contract", type=pathlib.Path, required=True)
    preflight.add_argument(
        "--measurement-contract", type=pathlib.Path, required=True)
    preflight.add_argument("--counter-schema", type=pathlib.Path, required=True)
    preflight.add_argument(
        "--boundary-qualification-amendment",
        type=pathlib.Path, required=True)
    preflight.add_argument("--workload-matrix", type=pathlib.Path, required=True)
    preflight.add_argument("--policy", type=pathlib.Path, required=True)
    preflight.add_argument("--simulator", type=pathlib.Path, required=True)
    preflight.add_argument("--config", type=pathlib.Path, required=True)
    preflight.add_argument("--coremark-image", type=pathlib.Path, required=True)
    preflight.add_argument(
        "--dhrystone-image", type=pathlib.Path, required=True)
    precheck = sub.add_parser("precheck")
    precheck.add_argument("--manifest", type=pathlib.Path, required=True)
    precheck.add_argument("--output", type=pathlib.Path, required=True)
    bind = sub.add_parser("bind-postflight")
    bind.add_argument("--manifest", type=pathlib.Path, required=True)
    bind.add_argument("--postflight-log", type=pathlib.Path, required=True)
    bind.add_argument("--output", type=pathlib.Path, required=True)
    replay_manifest = sub.add_parser("replay-manifest")
    replay_manifest.add_argument(
        "--source-manifest", type=pathlib.Path, required=True)
    replay_manifest.add_argument(
        "--baseline-contract", type=pathlib.Path, required=True)
    replay_manifest.add_argument(
        "--boundary-qualification-amendment", type=pathlib.Path, required=True)
    replay_manifest.add_argument("--output", type=pathlib.Path, required=True)
    publish = sub.add_parser("publish")
    publish.add_argument("--review", type=pathlib.Path, required=True)
    publish.add_argument("--output", type=pathlib.Path, required=True)
    build = sub.add_parser("build")
    build.add_argument("--manifest", type=pathlib.Path, required=True)
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    for command in (build, verify):
        command.add_argument("--require-baseline", action="store_true")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == "preflight":
            value = build_input_preflight(root, args)
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), value)
            print(
                "[PERFORMANCE-BASELINE-PREFLIGHT][PASS] "
                f"design_id={value['design_id']} simulator=current "
                "counter_markers=present workload_matrix=scoped")
            return 0
        if args.command == "manifest":
            require(len(args.coremark_log) == 3, "CoreMark requires three log arguments")
            require(len(args.dhrystone_log) == 3, "Dhrystone requires three log arguments")
            value = build_manifest(root, args)
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), value)
            print(
                "[PERFORMANCE-BASELINE-MANIFEST][PASS] "
                f"design_id={value['design_id']} coremark=3 dhrystone=3 stats_off=2")
            return 0
        if args.command == "replay-manifest":
            source_path = (
                args.source_manifest if args.source_manifest.is_absolute()
                else root / args.source_manifest)
            baseline_path = (
                args.baseline_contract if args.baseline_contract.is_absolute()
                else root / args.baseline_contract)
            amendment_path = (
                args.boundary_qualification_amendment
                if args.boundary_qualification_amendment.is_absolute()
                else root / args.boundary_qualification_amendment)
            value = build_replay_manifest(
                root, source_path.resolve(), baseline_path.resolve(),
                amendment_path.resolve())
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), value)
            print(
                "[PERFORMANCE-BASELINE-REPLAY-MANIFEST][PASS] "
                f"design_id={value['design_id']}")
            return 0
        if args.command == "publish":
            review_path = (
                args.review if args.review.is_absolute() else root / args.review)
            result = validate_independent_review(root, review_path.resolve())
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), result)
            print(
                "[PERFORMANCE-BASELINE-PUBLISH][PASS] "
                f"design_id={result['design_id']} ppa=UNQUALIFIED")
            return 0
        if args.command == "bind-postflight":
            manifest_path = (
                args.manifest if args.manifest.is_absolute()
                else root / args.manifest)
            postflight_path = (
                args.postflight_log if args.postflight_log.is_absolute()
                else root / args.postflight_log)
            value = bind_postflight(
                root, manifest_path.resolve(), postflight_path.resolve())
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), value)
            print(
                "[PERFORMANCE-BASELINE-POSTFLIGHT-BINDING][PASS] "
                f"design_id={value['design_id']}")
            return 0
        if args.command == "precheck":
            manifest_path = (
                args.manifest if args.manifest.is_absolute()
                else root / args.manifest)
            result = build_result(
                root, manifest_path.resolve(), require_postflight=False)
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), result)
            print(
                "[PERFORMANCE-BASELINE-PRECHECK][PASS] "
                f"design_id={result['design_id']} postflight=pending")
            return 0
        if args.command == "build":
            manifest_path = args.manifest if args.manifest.is_absolute() else root / args.manifest
            result = build_result(root, manifest_path.resolve())
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), result)
        else:
            input_path = args.input if args.input.is_absolute() else root / args.input
            stored = read_json(input_path.resolve(), "performance baseline result")
            manifest_record = stored.get("manifest")
            manifest_path = validate_artifact(root, manifest_record, "performance manifest")
            result = build_result(root, manifest_path)
            require(stored == result, "stored performance baseline result is not canonical")
        require(result.get("status") == "PERF_BASELINE",
                "performance baseline status is not PERF_BASELINE")
    except (BaselineError, KeyError, OSError, ValueError) as exc:
        print(f"[PERFORMANCE-BASELINE-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[PERFORMANCE-BASELINE-CURRENT][PASS] "
        f"design_id={result['design_id']} "
        f"coremark={result['benchmarks']['coremark']['cycles']}/"
        f"{result['benchmarks']['coremark']['retired_instructions']} "
        f"dhrystone={result['benchmarks']['dhrystone_10000']['cycles']}/"
        f"{result['benchmarks']['dhrystone_10000']['retired_instructions']} "
        "ppa=UNQUALIFIED promotion_eligible=false"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
