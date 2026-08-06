#!/usr/bin/env python3

"""校验 RV64 owner-timing workload A/B，并生成可重放的有界结果。"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
FAIL_MARKERS = (
    "[RESULT] FAIL",
    "[CHECK-FAIL]",
    "[TIMEOUT]",
    "FATAL:",
    "ABORT at pc",
    "difftest mismatch",
)
STAGES = (
    "admission_wait",
    "reservation",
    "translation",
    "write_request",
    "write_response",
    "aw_w_to_b",
    "sq_query",
)
CLASSES = ("load", "store", "atomic", "a_d_update", "unknown")
INVALID_REASONS = (
    "configuration",
    "illegal_state",
    "active_kind",
    "station_kind",
    "request_kind",
    "request_fire_without_valid",
    "stage_advance_without_station",
    "station_cancel_without_station",
    "active_drop_without_active",
    "stage_identity_change",
    "admission_identity_change",
    "write_occupancy",
    "boundary_order",
)


class EvidenceError(ValueError):
    """输入或证据违反量测合同。"""


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve_file(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    path = path.resolve(strict=True)
    try:
        path.relative_to(REPO_ROOT)
    except ValueError as error:
        raise EvidenceError(f"path escapes repository: {path}") from error
    if not path.is_file():
        raise EvidenceError(f"not a regular file: {path}")
    return path


def resolve_absent_path(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    path = path.resolve(strict=False)
    try:
        path.relative_to(REPO_ROOT)
    except ValueError as error:
        raise EvidenceError(f"path escapes repository: {path}") from error
    return path


def rel(path: pathlib.Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def file_ref(raw: str | pathlib.Path) -> dict[str, Any]:
    path = resolve_file(raw)
    return {
        "path": rel(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def verify_ref(value: Any, label: str) -> pathlib.Path:
    if not isinstance(value, dict):
        raise EvidenceError(f"{label} must be an object")
    if set(value) != {"path", "sha256", "size_bytes"}:
        raise EvidenceError(f"{label} has unexpected fields")
    path = resolve_file(value["path"])
    expected = file_ref(path)
    if value != expected:
        raise EvidenceError(f"{label} identity drift")
    return path


def load_json(raw: str | pathlib.Path) -> Any:
    path = resolve_file(raw)
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise EvidenceError(f"invalid JSON: {rel(path)}") from error


def atomic_write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def clean_lines(path: pathlib.Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise EvidenceError(f"non-UTF8 log: {rel(path)}") from error
    clean = ANSI_RE.sub("", text)
    for marker in FAIL_MARKERS:
        if marker.lower() in clean.lower():
            raise EvidenceError(f"forbidden marker {marker!r}: {rel(path)}")
    return clean.splitlines()


def unique_containing(lines: list[str], needle: str, label: str) -> str:
    matches = [line.strip() for line in lines if needle in line]
    if len(matches) != 1:
        raise EvidenceError(f"{label} expected once, got {len(matches)}")
    return matches[0]


def fields_after(line: str, anchor: str, label: str) -> dict[str, str]:
    offset = line.find(anchor)
    if offset < 0:
        raise EvidenceError(f"{label} anchor missing")
    tokens = line[offset:].split()
    fields: dict[str, str] = {}
    for token in tokens:
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        if key in fields:
            raise EvidenceError(f"{label} duplicate field {key}")
        fields[key] = value
    return fields


def require_uint(fields: dict[str, str], key: str, label: str) -> int:
    raw = fields.get(key)
    if raw is None or not re.fullmatch(r"[0-9]+", raw):
        raise EvidenceError(f"{label}.{key} is not an unsigned integer")
    return int(raw)


def require_value(fields: dict[str, str], key: str, expected: str, label: str) -> None:
    if fields.get(key) != expected:
        raise EvidenceError(
            f"{label}.{key} expected {expected!r}, got {fields.get(key)!r}"
        )


def parse_common_log(path: pathlib.Path, workload: str) -> dict[str, Any]:
    lines = clean_lines(path)
    pass_marker = "CoreMark PASS" if workload == "coremark" else "Dhrystone PASS"
    if sum(pass_marker in line for line in lines) != 1:
        raise EvidenceError(f"{workload} PASS marker is not unique")
    if sum("HIT GOOD TRAP" in line for line in lines) != 1:
        raise EvidenceError(f"{workload} GOOD TRAP marker is not unique")

    region_line = unique_containing(
        lines, "FINAL schema=npc-rv64-region-final-v1", "region final"
    )
    counter_line = unique_containing(
        lines,
        "COUNTERS_FINAL schema=npc-rv64-performance-counter-v4",
        "counter final",
    )
    region = fields_after(
        region_line, "FINAL schema=npc-rv64-region-final-v1", "region"
    )
    counter = fields_after(
        counter_line,
        "COUNTERS_FINAL schema=npc-rv64-performance-counter-v4",
        "counter",
    )
    require_value(region, "schema", "npc-rv64-region-final-v1", "region")
    require_value(region, "counter_scope", "pc_bounded_region_v1", "region")
    for key, expected in (
        ("complete", "1"),
        ("termination_rc", "0"),
        ("start_seen", "1"),
        ("end_seen", "1"),
    ):
        require_value(region, key, expected, "region")
    cycles = require_uint(region, "cycles", "region")
    retired = require_uint(region, "retired", "region")
    start_hits = require_uint(region, "start_hits", "region")
    end_hits = require_uint(region, "end_hits", "region")
    if cycles == 0 or retired == 0 or start_hits == 0 or end_hits == 0:
        raise EvidenceError("region boundary/cycle/retired count is zero")

    require_value(counter, "schema", "npc-rv64-performance-counter-v4", "counter")
    for key, expected in (
        ("complete", "1"),
        ("available", "1"),
        ("overflow", "0"),
        ("invalid_events", "0"),
        ("conservation", "1"),
    ):
        require_value(counter, key, expected, "counter")
    if require_uint(counter, "cycles", "counter") != cycles:
        raise EvidenceError("counter cycles disagree with region")
    if require_uint(counter, "retired_slots", "counter") != retired:
        raise EvidenceError("counter retired_slots disagree with region")
    start_lane = require_uint(counter, "start_lane", "counter")
    end_lane = require_uint(counter, "end_lane", "counter")
    if start_lane > 1 or end_lane > 1:
        raise EvidenceError("counter boundary lane is outside dual-issue width")
    capacity = require_uint(counter, "slot_capacity", "counter")
    if capacity != 2 * cycles + end_lane - start_lane:
        raise EvidenceError("counter slot capacity violates endpoint contract")

    return {
        "lines": lines,
        "cycles": cycles,
        "retired": retired,
        "start_hits": start_hits,
        "end_hits": end_hits,
        "start_lane": start_lane,
        "end_lane": end_lane,
        "region_fields": region,
        "counter_fields": counter,
        "region_payload": region_line[region_line.index("FINAL schema=") :],
        "counter_payload": counter_line[counter_line.index("COUNTERS_FINAL schema=") :],
    }


def parse_reference_log(path: pathlib.Path, workload: str) -> dict[str, Any]:
    parsed = parse_common_log(path, workload)
    if any(line.startswith("OWNER_TIMING_") for line in parsed["lines"]):
        raise EvidenceError("reference log unexpectedly contains owner timing payload")
    parsed.pop("lines")
    return parsed


def parse_diagnostic_log(path: pathlib.Path, workload: str) -> dict[str, Any]:
    parsed = parse_common_log(path, workload)
    lines = parsed["lines"]
    final_line = unique_containing(
        lines, "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1", "owner final"
    )
    final = fields_after(
        final_line, "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1", "owner"
    )
    require_value(final, "schema", "npc-rv64-owner-timing-v1", "owner")
    for key, expected in (
        ("complete", "1"),
        ("available", "1"),
        ("overflow", "0"),
        ("invalid_events", "0"),
        ("invalid_conservation", "1"),
        ("start_seen", "1"),
        ("end_seen", "1"),
        ("state_conservation", "1"),
        ("interval_conservation", "1"),
        ("candidate_authorized", "0"),
        ("promotion_eligible", "0"),
        ("ppa", "UNQUALIFIED"),
    ):
        require_value(final, key, expected, "owner")
    invalid_events = require_uint(final, "invalid_events", "owner")
    invalid_reason_total = sum(
        require_uint(final, f"invalid_{reason}", "owner")
        for reason in INVALID_REASONS
    )
    if invalid_reason_total != invalid_events:
        raise EvidenceError("owner invalid reason total disagrees with invalid_events")
    for key, expected in (
        ("cycles", parsed["cycles"]),
        ("start_hits", parsed["start_hits"]),
        ("end_hits", parsed["end_hits"]),
        ("start_lane", parsed["start_lane"]),
        ("end_lane", parsed["end_lane"]),
    ):
        if require_uint(final, key, "owner") != expected:
            raise EvidenceError(f"owner {key} disagrees with region/counter")

    occupancy_line = unique_containing(lines, "OWNER_TIMING_OCCUPANCY ", "occupancy")
    occupancy = fields_after(occupancy_line, "OWNER_TIMING_OCCUPANCY", "occupancy")
    require_value(occupancy, "conservation", "1", "occupancy")
    occupancy_values = [
        require_uint(occupancy, f"write_inflight_{index}", "occupancy")
        for index in range(3)
    ]
    if sum(occupancy_values) != parsed["cycles"]:
        raise EvidenceError("write-inflight occupancy does not conserve ROI cycles")

    state_rows: dict[str, list[int]] = {}
    for line in (line for line in lines if line.startswith("OWNER_TIMING_STATE ")):
        fields = fields_after(line, "OWNER_TIMING_STATE", "state")
        bridge = require_uint(fields, "bridge", "state")
        if bridge not in (0, 1) or str(bridge) in state_rows:
            raise EvidenceError("owner state bridge is duplicate or invalid")
        values = [require_uint(fields, f"s{index}", "state") for index in range(16)]
        if sum(values) != parsed["cycles"]:
            raise EvidenceError(f"bridge {bridge} state cycles do not conserve ROI")
        state_rows[str(bridge)] = values
    if set(state_rows) != {"0", "1"}:
        raise EvidenceError("owner state rows must cover both bridges")

    events: dict[tuple[int, str], dict[str, int]] = {}
    for line in (line for line in lines if line.startswith("OWNER_TIMING_EVENT ")):
        fields = fields_after(line, "OWNER_TIMING_EVENT", "event")
        bridge = require_uint(fields, "bridge", "event")
        operation = fields.get("class", "")
        key = (bridge, operation)
        if bridge not in (0, 1) or operation not in CLASSES or key in events:
            raise EvidenceError("owner event row is duplicate or invalid")
        events[key] = {
            "request_fire": require_uint(fields, "request_fire", "event"),
            "b_terminal": require_uint(fields, "b_terminal", "event"),
        }
    expected_events = {(bridge, operation) for bridge in range(2) for operation in CLASSES}
    if set(events) != expected_events:
        raise EvidenceError("owner event rows do not cover bridge/class product")

    stage_rows: dict[tuple[int, str, str], dict[str, Any]] = {}
    for line in (line for line in lines if line.startswith("OWNER_TIMING_STAGE ")):
        fields = fields_after(line, "OWNER_TIMING_STAGE", "stage")
        bridge = require_uint(fields, "bridge", "stage")
        stage = fields.get("stage", "")
        operation = fields.get("class", "")
        key = (bridge, stage, operation)
        if (
            bridge not in (0, 1)
            or stage not in STAGES
            or operation not in CLASSES
            or key in stage_rows
        ):
            raise EvidenceError("owner stage row is duplicate or invalid")
        numeric_keys = (
            "eligible_started",
            "completed",
            "right_censored",
            "cancelled",
            "left_censored",
            "left_completed",
            "left_right_censored",
            "observed_cycles",
            "completed_cycles",
            "rob_head_cycles",
            "peer_overlap_cycles",
        )
        row = {name: require_uint(fields, name, "stage") for name in numeric_keys}
        bins_text = fields.get("bins", "")
        if not re.fullmatch(r"[0-9]+(?:/[0-9]+){8}", bins_text):
            raise EvidenceError("stage bins must contain nine unsigned buckets")
        bins = [int(value) for value in bins_text.split("/")]
        row["bins"] = bins
        if row["eligible_started"] != (
            row["completed"] + row["right_censored"] + row["cancelled"]
        ):
            raise EvidenceError("eligible interval conservation failed")
        if row["left_censored"] != (
            row["left_completed"] + row["left_right_censored"]
        ):
            raise EvidenceError("left-censored interval conservation failed")
        if sum(bins) != row["completed"]:
            raise EvidenceError("completed histogram conservation failed")
        stage_rows[key] = row
    expected_stages = {
        (bridge, stage, operation)
        for bridge in range(2)
        for stage in STAGES
        for operation in CLASSES
    }
    if set(stage_rows) != expected_stages:
        raise EvidenceError("owner stage rows do not cover bridge/stage/class product")

    class_events: dict[str, dict[str, int]] = {}
    for operation in CLASSES:
        class_events[operation] = {
            name: sum(events[(bridge, operation)][name] for bridge in range(2))
            for name in ("request_fire", "b_terminal")
        }

    stage_totals: dict[str, dict[str, Any]] = {}
    numeric_keys = tuple(
        key for key in next(iter(stage_rows.values())) if key != "bins"
    )
    for stage in STAGES:
        rows = [
            stage_rows[(bridge, stage, operation)]
            for bridge in range(2)
            for operation in CLASSES
        ]
        stage_totals[stage] = {
            key: sum(row[key] for row in rows) for key in numeric_keys
        }
        stage_totals[stage]["bins"] = [
            sum(row["bins"][index] for row in rows) for index in range(9)
        ]

    owner_lines = [line.strip() for line in lines if line.startswith("OWNER_TIMING_")]
    if len(owner_lines) != 84:
        raise EvidenceError(f"owner payload expected 84 rows, got {len(owner_lines)}")
    owner_payload = "\n".join(owner_lines) + "\n"
    parsed.pop("lines")
    parsed.update(
        {
            "owner_final": final,
            "occupancy": occupancy_values,
            "state_cycles": state_rows,
            "class_events": class_events,
            "stage_totals": stage_totals,
            "owner_signature_sha256": hashlib.sha256(
                owner_payload.encode("utf-8")
            ).hexdigest(),
            "owner_line_count": len(owner_lines),
        }
    )
    return parsed


def parse_invalid_probe_log(path: pathlib.Path, workload: str) -> dict[str, Any]:
    """Parse a complete DUT run even when the owner collector rejects it.

    This mode is diagnostic-only: it preserves the failed qualification while
    requiring a complete benchmark/ROI/counter transaction and a conserved,
    uniquely classified invalid-event vector.
    """

    parsed = parse_common_log(path, workload)
    lines = parsed["lines"]
    final_line = unique_containing(
        lines, "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1", "owner final"
    )
    final = fields_after(
        final_line, "OWNER_TIMING_FINAL schema=npc-rv64-owner-timing-v1", "owner"
    )
    require_value(final, "schema", "npc-rv64-owner-timing-v1", "owner")
    for key, expected in (
        ("available", "1"),
        ("overflow", "0"),
        ("invalid_conservation", "1"),
        ("start_seen", "1"),
        ("end_seen", "1"),
        ("state_conservation", "1"),
        ("interval_conservation", "1"),
        ("candidate_authorized", "0"),
        ("promotion_eligible", "0"),
        ("ppa", "UNQUALIFIED"),
    ):
        require_value(final, key, expected, "owner")
    invalid_events = require_uint(final, "invalid_events", "owner")
    reason_counts = {
        reason: require_uint(final, f"invalid_{reason}", "owner")
        for reason in INVALID_REASONS
    }
    if sum(reason_counts.values()) != invalid_events:
        raise EvidenceError("owner invalid reason total disagrees with invalid_events")
    complete = require_uint(final, "complete", "owner")
    if complete not in (0, 1) or complete != (1 if invalid_events == 0 else 0):
        raise EvidenceError("owner complete/invalid_events relationship is inconsistent")
    for key, expected in (
        ("cycles", parsed["cycles"]),
        ("start_hits", parsed["start_hits"]),
        ("end_hits", parsed["end_hits"]),
        ("start_lane", parsed["start_lane"]),
        ("end_lane", parsed["end_lane"]),
    ):
        if require_uint(final, key, "owner") != expected:
            raise EvidenceError(f"owner {key} disagrees with region/counter")

    owner_lines = [line.strip() for line in lines if line.startswith("OWNER_TIMING_")]
    prefix_counts = {
        "final": sum(line.startswith("OWNER_TIMING_FINAL ") for line in owner_lines),
        "occupancy": sum(
            line.startswith("OWNER_TIMING_OCCUPANCY ") for line in owner_lines
        ),
        "state": sum(line.startswith("OWNER_TIMING_STATE ") for line in owner_lines),
        "event": sum(line.startswith("OWNER_TIMING_EVENT ") for line in owner_lines),
        "stage": sum(line.startswith("OWNER_TIMING_STAGE ") for line in owner_lines),
    }
    if prefix_counts != {
        "final": 1,
        "occupancy": 1,
        "state": 2,
        "event": 10,
        "stage": 70,
    } or len(owner_lines) != 84:
        raise EvidenceError("owner diagnostic inventory is incomplete or duplicated")

    stage_keys: set[tuple[int, str, str]] = set()
    cancelled_total = 0
    admission_cancelled = 0
    for line in (line for line in lines if line.startswith("OWNER_TIMING_STAGE ")):
        fields = fields_after(line, "OWNER_TIMING_STAGE", "stage")
        bridge = require_uint(fields, "bridge", "stage")
        stage = fields.get("stage", "")
        operation = fields.get("class", "")
        key = (bridge, stage, operation)
        if (
            bridge not in (0, 1)
            or stage not in STAGES
            or operation not in CLASSES
            or key in stage_keys
        ):
            raise EvidenceError("owner diagnostic stage row is duplicate or invalid")
        stage_keys.add(key)
        cancelled = require_uint(fields, "cancelled", "stage")
        cancelled_total += cancelled
        if stage == "admission_wait":
            admission_cancelled += cancelled
    expected_stage_keys = {
        (bridge, stage, operation)
        for bridge in range(2)
        for stage in STAGES
        for operation in CLASSES
    }
    if stage_keys != expected_stage_keys:
        raise EvidenceError("owner diagnostic stage rows do not cover the product")

    parsed.pop("lines")
    parsed.update(
        {
            "owner_final": final,
            "owner_line_count": len(owner_lines),
            "owner_signature_sha256": hashlib.sha256(
                ("\n".join(owner_lines) + "\n").encode("utf-8")
            ).hexdigest(),
            "collector_qualified": complete == 1,
            "invalid_events": invalid_events,
            "invalid_reason_counts": reason_counts,
            "cancelled_total": cancelled_total,
            "admission_cancelled": admission_cancelled,
        }
    )
    return parsed


def ratio(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "0.000000000000"
    return f"{numerator / denominator:.12f}"


def stage_summary(stage: dict[str, Any]) -> dict[str, Any]:
    return {
        "eligible_started": stage["eligible_started"],
        "completed": stage["completed"],
        "cancelled": stage["cancelled"],
        "right_censored": stage["right_censored"],
        "observed_cycles": stage["observed_cycles"],
        "completed_cycles": stage["completed_cycles"],
        "mean_completed_cycles": ratio(stage["completed_cycles"], stage["completed"]),
        "rob_head_cycles": stage["rob_head_cycles"],
        "rob_head_ratio": ratio(stage["rob_head_cycles"], stage["observed_cycles"]),
        "peer_overlap_cycles": stage["peer_overlap_cycles"],
        "long_tail_completed_ge17": sum(stage["bins"][6:]),
        "bins": stage["bins"],
    }


def hypothesis_channels(parsed: dict[str, Any]) -> dict[str, Any]:
    stages = parsed["stage_totals"]
    occupancy = parsed["occupancy"]
    cycles = parsed["cycles"]
    request_fire = sum(
        value["request_fire"] for value in parsed["class_events"].values()
    )
    b_terminal = sum(
        value["b_terminal"] for value in parsed["class_events"].values()
    )
    return {
        "H1_B_RESPONSE_LATENCY": {
            "aw_w_to_b": stage_summary(stages["aw_w_to_b"]),
            "write_response": stage_summary(stages["write_response"]),
        },
        "H2_WRITE_CONCURRENCY": {
            "admission_wait": stage_summary(stages["admission_wait"]),
            "write_inflight_0": occupancy[0],
            "write_inflight_1": occupancy[1],
            "write_inflight_2": occupancy[2],
            "write_inflight_2_ratio": ratio(occupancy[2], cycles),
        },
        "H3_HEAD_RESIDENCY_WEIGHTING": {
            "request_fire": request_fire,
            "b_terminal": b_terminal,
            "class_events": parsed["class_events"],
            "write_request": stage_summary(stages["write_request"]),
            "write_response": stage_summary(stages["write_response"]),
        },
        "H4_PRE_REQUEST_PIPELINE": {
            "reservation": stage_summary(stages["reservation"]),
            "translation": stage_summary(stages["translation"]),
            "sq_query": stage_summary(stages["sq_query"]),
        },
    }


def require_all_equal(values: list[Any], label: str) -> Any:
    if not values:
        raise EvidenceError(f"{label} is empty")
    if any(value != values[0] for value in values[1:]):
        raise EvidenceError(f"{label} repetitions are not bit-exact")
    return values[0]


def validate_static_inputs(
    baseline_path: pathlib.Path,
    contract_path: pathlib.Path,
    profile_path: pathlib.Path,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    baseline = load_json(baseline_path)
    contract = load_json(contract_path)
    profile = load_json(profile_path)
    if baseline.get("schema") != "npc-rv64-performance-baseline-current-v2":
        raise EvidenceError("baseline schema mismatch")
    if baseline.get("status") != "PERF_BASELINE":
        raise EvidenceError("baseline status is not PERF_BASELINE")
    if baseline.get("blockers") != [] or baseline.get("unknowns") != []:
        raise EvidenceError("baseline contains blockers or unknowns")
    if baseline.get("ppa") != "UNQUALIFIED" or baseline.get("promotion_eligible") is not False:
        raise EvidenceError("baseline PPA boundary drift")
    if contract.get("schema") != "npc-rv64-owner-timing-contract-v1":
        raise EvidenceError("owner timing contract schema mismatch")
    if profile.get("schema") != "npc-rv64-owner-timing-validation-profile-v1":
        raise EvidenceError("owner timing profile schema mismatch")
    if profile.get("binding", {}).get("design_id") != baseline.get("design_id"):
        raise EvidenceError("profile/baseline design-id mismatch")
    if profile.get("binding", {}).get("baseline_receipt") != rel(baseline_path):
        raise EvidenceError("profile baseline path mismatch")
    if profile.get("binding", {}).get("measurement_contract") != rel(contract_path):
        raise EvidenceError("profile contract path mismatch")
    if profile.get("required_configuration", {}).get("CONFIG_NPC_OOO_STATS") != "y":
        raise EvidenceError("owner timing requires CONFIG_NPC_OOO_STATS=y")
    for value in (contract.get("authorization"), profile.get("authorization")):
        if value != {
            "optimization_candidate_authorized": False,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }:
            raise EvidenceError("owner timing authorization boundary drift")
    if tuple(contract.get("stages", [])) != STAGES:
        raise EvidenceError("owner timing stage inventory drift")
    if {
        str(value).lower()
        for value in contract.get("operation_classes", {}).values()
    } != set(CLASSES):
        raise EvidenceError("owner timing class inventory drift")
    if "first observed start PC" not in contract.get("roi_contract", {}).get(
        "boundary_reentry", ""
    ):
        raise EvidenceError("boundary reentry contract is missing")
    return baseline, contract, profile


def validate_manifest(path: pathlib.Path) -> dict[str, Any]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 148 or len(set(lines)) != 148:
        raise EvidenceError("production manifest must contain 148 unique files")
    for line in lines:
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            raise EvidenceError("production manifest line format mismatch")
        source = resolve_file(match.group(2))
        if sha256(source) != match.group(1):
            raise EvidenceError(f"production source drift: {rel(source)}")
    return {
        **file_ref(path),
        "file_count": len(lines),
        "aggregate_sha256": sha256(path),
    }


def live_rtl_design_id() -> str:
    """Return the canonical current production-RTL source-set identity."""
    tools_dir = REPO_ROOT / "npc/rv64/eval/ppa/tools"
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    import architecture_hard_gates as architecture  # pylint: disable=import-outside-toplevel

    design_hex, _ = architecture.rtl_binding(REPO_ROOT)
    return f"sha256:{design_hex}"


def bind_invalid_probe_design(
    reference_design_id: str,
    production_design_id: str,
    current_design_diagnostic: bool,
) -> str:
    if not current_design_diagnostic and production_design_id != reference_design_id:
        raise EvidenceError("invalid probe production/reference design-id mismatch")
    return production_design_id


def enforce_invalid_probe_reference_match(
    region_match: bool,
    counter_match: bool,
    current_design_diagnostic: bool,
) -> None:
    if current_design_diagnostic:
        return
    if not region_match:
        raise EvidenceError("invalid probe region changed under diagnostic observer")
    if not counter_match:
        raise EvidenceError("invalid probe v4 counter stack changed under observer")


def validate_simulator_identity(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    if value.get("schema") != "npc-rv64-owner-timing-simulator-identity-v1":
        raise EvidenceError("diagnostic simulator identity schema mismatch")
    if value.get("build_rc") != 0 or value.get("CONFIG_NPC_OOO_STATS") != "y":
        raise EvidenceError("diagnostic simulator build/config mismatch")
    if value.get("CONFIG_NPC_OOO_OWNER_TIMING") != "y":
        raise EvidenceError("diagnostic owner timing define missing")
    if not re.fullmatch(r"[0-9a-f]{64}", str(value.get("sha256", ""))):
        raise EvidenceError("diagnostic simulator SHA is invalid")
    if not isinstance(value.get("size_bytes"), int) or value["size_bytes"] <= 0:
        raise EvidenceError("diagnostic simulator size is invalid")
    runtime_path = resolve_absent_path(value.get("path", ""))
    expected_prefix = REPO_ROOT / ".github/runtime-artifacts/owner-timing-workload-ab"
    try:
        runtime_path.relative_to(expected_prefix)
    except ValueError as error:
        raise EvidenceError("diagnostic simulator path is outside runtime root") from error
    return value


def validate_cleanup(path: pathlib.Path, simulator_identity: dict[str, Any]) -> dict[str, Any]:
    value = load_json(path)
    if value.get("schema") != "npc-rv64-owner-timing-cleanup-v1":
        raise EvidenceError("cleanup schema mismatch")
    if value.get("cleanup_rc") != 0 or value.get("runtime_absent") is not True:
        raise EvidenceError("runtime cleanup is not complete")
    runtime_path = resolve_absent_path(value.get("runtime_path", ""))
    simulator_path = resolve_absent_path(simulator_identity["path"])
    try:
        simulator_path.relative_to(runtime_path)
    except ValueError as error:
        raise EvidenceError("simulator was not below the cleaned runtime directory") from error
    if runtime_path.exists() or simulator_path.exists():
        raise EvidenceError("runtime build or simulator still exists")
    return value


def build_receipt(
    baseline_path: pathlib.Path,
    contract_path: pathlib.Path,
    profile_path: pathlib.Path,
    manifest_path: pathlib.Path,
    simulator_identity_path: pathlib.Path,
    cleanup_path: pathlib.Path,
    diagnostic_logs: dict[str, list[pathlib.Path]],
) -> dict[str, Any]:
    baseline, _, _ = validate_static_inputs(baseline_path, contract_path, profile_path)
    manifest = validate_manifest(manifest_path)
    simulator_identity = validate_simulator_identity(simulator_identity_path)
    cleanup = validate_cleanup(cleanup_path, simulator_identity)

    workloads: dict[str, Any] = {}
    baseline_keys = {"coremark": "coremark", "dhrystone_10000": "dhrystone_10000"}
    for result_key, baseline_key in baseline_keys.items():
        baseline_entry = baseline["benchmarks"][baseline_key]
        reference_refs = baseline_entry.get("logs", [])
        if len(reference_refs) != 3:
            raise EvidenceError(f"{result_key} baseline must have three logs")
        reference_logs: list[pathlib.Path] = []
        for index, reference in enumerate(reference_refs):
            reference_logs.append(verify_ref(reference, f"{result_key}.reference[{index}]"))
        references = [parse_reference_log(path, result_key) for path in reference_logs]
        reference_region = require_all_equal(
            [value["region_payload"] for value in references],
            f"{result_key} reference region",
        )
        reference_counter = require_all_equal(
            [value["counter_payload"] for value in references],
            f"{result_key} reference counter",
        )
        if references[0]["cycles"] != baseline_entry["cycles"]:
            raise EvidenceError(f"{result_key} baseline cycles mismatch")
        if references[0]["retired"] != baseline_entry["retired_instructions"]:
            raise EvidenceError(f"{result_key} baseline retired mismatch")

        paths = diagnostic_logs[result_key]
        if len(paths) != 3:
            raise EvidenceError(f"{result_key} diagnostic must have three logs")
        diagnostics = [parse_diagnostic_log(path, result_key) for path in paths]
        diagnostic_region = require_all_equal(
            [value["region_payload"] for value in diagnostics],
            f"{result_key} diagnostic region",
        )
        diagnostic_counter = require_all_equal(
            [value["counter_payload"] for value in diagnostics],
            f"{result_key} diagnostic counter",
        )
        owner_signature = require_all_equal(
            [value["owner_signature_sha256"] for value in diagnostics],
            f"{result_key} owner timing",
        )
        if diagnostic_region != reference_region:
            raise EvidenceError(f"{result_key} region changed under diagnostic observer")
        if diagnostic_counter != reference_counter:
            raise EvidenceError(f"{result_key} v4 counter stack changed under diagnostic observer")

        first = diagnostics[0]
        workloads[result_key] = {
            "cycles": first["cycles"],
            "retired_instructions": first["retired"],
            "cpi": baseline_entry["cpi"],
            "ipc": baseline_entry["ipc"],
            "start_hits": first["start_hits"],
            "end_hits": first["end_hits"],
            "start_lane": first["start_lane"],
            "end_lane": first["end_lane"],
            "reference": {
                "repetitions": 3,
                "logs": reference_refs,
                "region_counter_bit_exact": True,
            },
            "diagnostic": {
                "repetitions": 3,
                "logs": [file_ref(path) for path in paths],
                "region_counter_bit_exact": True,
                "owner_timing_bit_exact": True,
                "owner_signature_sha256": owner_signature,
                "owner_line_count": first["owner_line_count"],
            },
            "observer_noninterference": True,
            "occupancy": {
                "write_inflight_0": first["occupancy"][0],
                "write_inflight_1": first["occupancy"][1],
                "write_inflight_2": first["occupancy"][2],
            },
            "state_cycles": first["state_cycles"],
            "class_events": first["class_events"],
            "stage_totals": first["stage_totals"],
            "hypothesis_channels": hypothesis_channels(first),
        }

    return {
        "schema": "npc-rv64-owner-timing-workload-ab-v1",
        "status": "OWNER_TIMING_WORKLOAD_MEASURED",
        "design_id": baseline["design_id"],
        "scope": "CoreMark10 and Dhrystone10000 owner-correlated timing on the frozen PERF_BASELINE design",
        "inputs": {
            "baseline_receipt": file_ref(baseline_path),
            "owner_timing_contract": file_ref(contract_path),
            "validation_profile": file_ref(profile_path),
            "production_manifest": manifest,
            "diagnostic_simulator_identity": file_ref(simulator_identity_path),
            "runtime_cleanup": file_ref(cleanup_path),
        },
        "diagnostic_build": {
            "simulator_sha256": simulator_identity["sha256"],
            "simulator_size_bytes": simulator_identity["size_bytes"],
            "simulator_runtime_path": simulator_identity["path"],
            "CONFIG_NPC_OOO_STATS": "y",
            "CONFIG_NPC_OOO_OWNER_TIMING": "y",
            "production_filelist_modified": False,
            "runtime_retained": False,
        },
        "workloads": workloads,
        "checks": {
            "arch_stable_pre_post": True,
            "perf_baseline_pre_post": True,
            "reference_repetitions_bit_exact": True,
            "diagnostic_repetitions_bit_exact": True,
            "region_counter_noninterference": True,
            "owner_state_conservation": True,
            "owner_interval_conservation": True,
            "owner_overflow": 0,
            "owner_invalid_events": 0,
            "benchmark_terminal_markers": True,
            "runtime_cleanup": True,
        },
        "authorization": {
            "hypothesis_selection_authorized": False,
            "optimization_candidate_authorized": False,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
        "unknowns": [
            "owner correlation is diagnostic evidence and does not by itself prove a causal RTL optimization mechanism",
            "frequency area and power were not measured in this diagnostic run",
        ],
    }


def receipt_paths(data: dict[str, Any]) -> tuple[pathlib.Path, ...]:
    inputs = data.get("inputs", {})
    return tuple(
        resolve_file(inputs[name]["path"])
        for name in (
            "baseline_receipt",
            "owner_timing_contract",
            "validation_profile",
            "production_manifest",
            "diagnostic_simulator_identity",
            "runtime_cleanup",
        )
    )


def rebuild_receipt(data: dict[str, Any]) -> dict[str, Any]:
    if data.get("schema") != "npc-rv64-owner-timing-workload-ab-v1":
        raise EvidenceError("owner timing workload receipt schema mismatch")
    (
        baseline_path,
        contract_path,
        profile_path,
        manifest_path,
        simulator_identity_path,
        cleanup_path,
    ) = receipt_paths(data)
    logs: dict[str, list[pathlib.Path]] = {}
    for workload in ("coremark", "dhrystone_10000"):
        entries = data.get("workloads", {}).get(workload, {}).get("diagnostic", {}).get("logs", [])
        if len(entries) != 3:
            raise EvidenceError(f"{workload} receipt log inventory mismatch")
        logs[workload] = [verify_ref(entry, f"{workload}.diagnostic") for entry in entries]
    return build_receipt(
        baseline_path,
        contract_path,
        profile_path,
        manifest_path,
        simulator_identity_path,
        cleanup_path,
        logs,
    )


def build_invalid_probe_receipt(
    baseline_path: pathlib.Path,
    contract_path: pathlib.Path,
    profile_path: pathlib.Path,
    manifest_path: pathlib.Path,
    simulator_identity_path: pathlib.Path,
    cleanup_path: pathlib.Path,
    log_path: pathlib.Path,
    workload: str,
    current_design_diagnostic: bool = False,
) -> dict[str, Any]:
    if workload not in ("coremark", "dhrystone_10000"):
        raise EvidenceError("invalid probe workload is unsupported")
    baseline, _, _ = validate_static_inputs(baseline_path, contract_path, profile_path)
    manifest = validate_manifest(manifest_path)
    production_design_id = bind_invalid_probe_design(
        baseline["design_id"], live_rtl_design_id(), current_design_diagnostic
    )
    simulator_identity = validate_simulator_identity(simulator_identity_path)
    validate_cleanup(cleanup_path, simulator_identity)
    baseline_entry = baseline["benchmarks"][workload]
    reference_refs = baseline_entry.get("logs", [])
    if len(reference_refs) != 3:
        raise EvidenceError("invalid probe baseline must have three reference logs")
    references = [
        parse_reference_log(verify_ref(value, f"{workload}.reference"), workload)
        for value in reference_refs
    ]
    reference_region = require_all_equal(
        [value["region_payload"] for value in references],
        f"{workload} reference region",
    )
    reference_counter = require_all_equal(
        [value["counter_payload"] for value in references],
        f"{workload} reference counter",
    )
    diagnostic = parse_invalid_probe_log(log_path, workload)
    reference_region_match = diagnostic["region_payload"] == reference_region
    reference_counter_match = diagnostic["counter_payload"] == reference_counter
    enforce_invalid_probe_reference_match(
        reference_region_match,
        reference_counter_match,
        current_design_diagnostic,
    )
    reasons = [
        {"reason": reason, "count": count}
        for reason, count in diagnostic["invalid_reason_counts"].items()
        if count != 0
    ]
    reasons.sort(key=lambda value: (-value["count"], value["reason"]))
    receipt = {
        "schema": "npc-rv64-owner-timing-invalid-probe-v1",
        "status": "INVALID_EVENT_DIAGNOSTIC_CAPTURED",
        "design_id": production_design_id,
        "scope": "single workload run for owner collector invalid-event discrimination",
        "workload": workload,
        "inputs": {
            "baseline_receipt": file_ref(baseline_path),
            "owner_timing_contract": file_ref(contract_path),
            "validation_profile": file_ref(profile_path),
            "production_manifest": manifest,
            "diagnostic_simulator_identity": file_ref(simulator_identity_path),
            "runtime_cleanup": file_ref(cleanup_path),
            "diagnostic_log": file_ref(log_path),
        },
        "measurement": {
            "cycles": diagnostic["cycles"],
            "retired_instructions": diagnostic["retired"],
            "start_hits": diagnostic["start_hits"],
            "end_hits": diagnostic["end_hits"],
            "owner_line_count": diagnostic["owner_line_count"],
            "owner_signature_sha256": diagnostic["owner_signature_sha256"],
            "region_counter_noninterference": True,
        },
        "collector_result": {
            "qualified": diagnostic["collector_qualified"],
            "invalid_events": diagnostic["invalid_events"],
            "invalid_reason_conservation": True,
            "invalid_reasons_nonzero": reasons,
            "admission_cancelled": diagnostic["admission_cancelled"],
            "all_stage_cancelled": diagnostic["cancelled_total"],
        },
        "qualification_boundary": {
            "diagnostic_capture_complete": True,
            "workload_owner_timing_pass": diagnostic["collector_qualified"],
            "optimization_candidate_authorized": False,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }
    if current_design_diagnostic:
        receipt.update({
            "schema": "npc-rv64-owner-timing-invalid-probe-v2",
            "status": "CURRENT_DESIGN_INVALID_EVENT_DIAGNOSTIC_CAPTURED",
            "reference_design_id": baseline["design_id"],
            "design_relation": "CURRENT_RTL_AGAINST_FROZEN_COUNTER_REFERENCE",
            "scope": (
                "single current-RTL workload run compared only with a frozen "
                "counter reference; no ARCH_STABLE or PPA promotion claim"
            ),
        })
        receipt["qualification_boundary"].update({
            "architecture_stable_current_required": False,
            "frozen_baseline_is_reference_only": True,
            "observer_noninterference_qualified": False,
            "performance_comparison_authorized": False,
        })
        receipt["measurement"].pop("region_counter_noninterference")
        receipt["measurement"].update({
            "current_run_region_complete": True,
            "frozen_reference_region_match": reference_region_match,
            "frozen_reference_counter_match": reference_counter_match,
        })
    return receipt


def rebuild_invalid_probe_receipt(data: dict[str, Any]) -> dict[str, Any]:
    schema = data.get("schema")
    if schema not in {
        "npc-rv64-owner-timing-invalid-probe-v1",
        "npc-rv64-owner-timing-invalid-probe-v2",
    }:
        raise EvidenceError("owner timing invalid probe schema mismatch")
    inputs = data.get("inputs", {})
    paths = {
        name: verify_ref(inputs.get(name), f"invalid_probe.{name}")
        for name in (
            "baseline_receipt",
            "owner_timing_contract",
            "validation_profile",
            "diagnostic_simulator_identity",
            "runtime_cleanup",
            "diagnostic_log",
        )
    }
    manifest_input = inputs.get("production_manifest")
    if not isinstance(manifest_input, dict) or "path" not in manifest_input:
        raise EvidenceError("invalid_probe.production_manifest is malformed")
    paths["production_manifest"] = resolve_file(manifest_input["path"])
    return build_invalid_probe_receipt(
        paths["baseline_receipt"],
        paths["owner_timing_contract"],
        paths["validation_profile"],
        paths["production_manifest"],
        paths["diagnostic_simulator_identity"],
        paths["runtime_cleanup"],
        paths["diagnostic_log"],
        str(data.get("workload", "")),
        current_design_diagnostic=(
            schema == "npc-rv64-owner-timing-invalid-probe-v2"
        ),
    )


def command_capture_simulator(args: argparse.Namespace) -> int:
    simulator = resolve_file(args.simulator)
    value = {
        "schema": "npc-rv64-owner-timing-simulator-identity-v1",
        "path": rel(simulator),
        "sha256": sha256(simulator),
        "size_bytes": simulator.stat().st_size,
        "build_rc": 0,
        "CONFIG_NPC_OOO_STATS": "y",
        "CONFIG_NPC_OOO_OWNER_TIMING": "y",
        "make_fragment": file_ref(args.make_fragment),
    }
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write_json(output, value)
    print(
        f"[OWNER-TIMING-SIMULATOR][PASS] sha256={value['sha256']} size={value['size_bytes']}"
    )
    return 0


def command_capture_cleanup(args: argparse.Namespace) -> int:
    runtime_path = resolve_absent_path(args.runtime_dir)
    expected = REPO_ROOT / ".github/runtime-artifacts/owner-timing-workload-ab"
    try:
        runtime_path.relative_to(expected)
    except ValueError as error:
        raise EvidenceError("cleanup target is outside owner timing runtime root") from error
    if runtime_path.exists():
        raise EvidenceError("runtime directory still exists")
    value = {
        "schema": "npc-rv64-owner-timing-cleanup-v1",
        "runtime_path": rel(runtime_path),
        "runtime_absent": True,
        "cleanup_rc": 0,
    }
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write_json(output, value)
    print(f"[OWNER-TIMING-RUNTIME-CLEANUP][PASS] path={value['runtime_path']}")
    return 0


def command_build(args: argparse.Namespace) -> int:
    diagnostic_logs = {
        "coremark": [resolve_file(path) for path in args.coremark_log],
        "dhrystone_10000": [resolve_file(path) for path in args.dhrystone_log],
    }
    value = build_receipt(
        resolve_file(args.baseline),
        resolve_file(args.contract),
        resolve_file(args.profile),
        resolve_file(args.production_manifest),
        resolve_file(args.simulator_identity),
        resolve_file(args.cleanup),
        diagnostic_logs,
    )
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write_json(output, value)
    print(
        "[OWNER-TIMING-WORKLOAD][PASS] "
        f"design_id={value['design_id']} workloads=2 repetitions=3 "
        "observer_noninterference=1 candidate_authorized=0 ppa=UNQUALIFIED"
    )
    return 0


def command_verify(args: argparse.Namespace) -> int:
    path = resolve_file(args.input)
    data = load_json(path)
    expected = rebuild_receipt(data)
    if data != expected:
        raise EvidenceError("owner timing workload receipt differs from rebuilt evidence")
    print(
        "[OWNER-TIMING-WORKLOAD-VERIFY][PASS] "
        f"design_id={data['design_id']} workloads=2 repetitions=3 "
        "observer_noninterference=1 candidate_authorized=0 ppa=UNQUALIFIED"
    )
    return 0


def command_build_invalid_probe(args: argparse.Namespace) -> int:
    value = build_invalid_probe_receipt(
        resolve_file(args.baseline),
        resolve_file(args.contract),
        resolve_file(args.profile),
        resolve_file(args.production_manifest),
        resolve_file(args.simulator_identity),
        resolve_file(args.cleanup),
        resolve_file(args.log),
        args.workload,
        current_design_diagnostic=args.current_design_diagnostic,
    )
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write_json(output, value)
    result = value["collector_result"]
    print(
        "[OWNER-TIMING-INVALID-PROBE][PASS] "
        f"workload={value['workload']} invalid_events={result['invalid_events']} "
        f"qualified={int(result['qualified'])} diagnostic_capture=1 "
        "candidate_authorized=0 ppa=UNQUALIFIED"
    )
    return 0


def command_verify_invalid_probe(args: argparse.Namespace) -> int:
    path = resolve_file(args.input)
    data = load_json(path)
    expected = rebuild_invalid_probe_receipt(data)
    if data != expected:
        raise EvidenceError("owner timing invalid probe differs from rebuilt evidence")
    result = data["collector_result"]
    print(
        "[OWNER-TIMING-INVALID-PROBE-VERIFY][PASS] "
        f"workload={data['workload']} invalid_events={result['invalid_events']} "
        f"qualified={int(result['qualified'])} diagnostic_capture=1 "
        "candidate_authorized=0 ppa=UNQUALIFIED"
    )
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)

    capture_simulator = sub.add_parser("capture-simulator")
    capture_simulator.add_argument("--simulator", required=True)
    capture_simulator.add_argument("--make-fragment", required=True)
    capture_simulator.add_argument("--output", required=True)
    capture_simulator.set_defaults(func=command_capture_simulator)

    capture_cleanup = sub.add_parser("capture-cleanup")
    capture_cleanup.add_argument("--runtime-dir", required=True)
    capture_cleanup.add_argument("--output", required=True)
    capture_cleanup.set_defaults(func=command_capture_cleanup)

    build = sub.add_parser("build")
    build.add_argument("--baseline", required=True)
    build.add_argument("--contract", required=True)
    build.add_argument("--profile", required=True)
    build.add_argument("--production-manifest", required=True)
    build.add_argument("--simulator-identity", required=True)
    build.add_argument("--cleanup", required=True)
    build.add_argument("--coremark-log", action="append", required=True)
    build.add_argument("--dhrystone-log", action="append", required=True)
    build.add_argument("--output", required=True)
    build.set_defaults(func=command_build)

    verify = sub.add_parser("verify")
    verify.add_argument("--input", required=True)
    verify.set_defaults(func=command_verify)

    invalid_probe = sub.add_parser("build-invalid-probe")
    invalid_probe.add_argument("--baseline", required=True)
    invalid_probe.add_argument("--contract", required=True)
    invalid_probe.add_argument("--profile", required=True)
    invalid_probe.add_argument("--production-manifest", required=True)
    invalid_probe.add_argument("--simulator-identity", required=True)
    invalid_probe.add_argument("--cleanup", required=True)
    invalid_probe.add_argument(
        "--workload", choices=("coremark", "dhrystone_10000"), required=True
    )
    invalid_probe.add_argument("--log", required=True)
    invalid_probe.add_argument("--output", required=True)
    invalid_probe.add_argument(
        "--current-design-diagnostic",
        action="store_true",
        help=(
            "allow a current RTL design to use the frozen baseline only as a "
            "counter reference; the receipt remains diagnostic-only and PPA UNQUALIFIED"
        ),
    )
    invalid_probe.set_defaults(func=command_build_invalid_probe)

    invalid_probe_verify = sub.add_parser("verify-invalid-probe")
    invalid_probe_verify.add_argument("--input", required=True)
    invalid_probe_verify.set_defaults(func=command_verify_invalid_probe)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (EvidenceError, OSError, KeyError, TypeError) as error:
        print(f"[OWNER-TIMING-WORKLOAD][FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
