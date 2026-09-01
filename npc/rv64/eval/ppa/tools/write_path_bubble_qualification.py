#!/usr/bin/env python3
"""Fail-closed parser for the diagnostic write-path bubble observer."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from typing import Dict, Iterable, Mapping


SCHEMA = "npc-rv64-write-path-bubble-v1"
RECEIPT_SCHEMA = "npc-rv64-write-path-bubble-qualification-v1"
MARKER = "WRITE_PATH_BUBBLE_FINAL "
REGION_MARKER = "FINAL schema=npc-rv64-region-final-v1 "
COUNTER_MARKER = "COUNTERS_FINAL schema=npc-rv64-performance-counter-v4 "
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
UINT_RE = re.compile(r"[0-9]+")


COUNTER_FIELDS = {
    "complete", "available", "overflow", "invalid", "cycles",
    "arb_events", "arb_source11", "arb_source10", "arb_source01",
    "arb_source00", "arb_ready11", "arb_ready10", "arb_ready01",
    "arb_ready00", "arb_lane0", "arb_lane1", "arb_contention",
    "arb_strict", "xbar_grant_cycles", "xbar_grants", "xbar_ready11",
    "xbar_ready10", "xbar_ready01", "xbar_ready00", "xbar_master0",
    "xbar_master1", "xbar_grant_bvalid", "xbar_head0_wr_rsp",
    "xbar_head1_wr_rsp", "xbar_head_any_wr_rsp", "xbar_strict",
    *(f"xbar_target{index}" for index in range(16)),
    "live_pairs", "live_master0", "live_master1",
    "live_target_inactive", "live_target_active", "live_older_holder",
    "live_same_target_conflict", "live_narrow_eligible",
    "arb_conservation", "xbar_ready_conservation",
    "xbar_master_conservation", "xbar_target_conservation",
    "live_conservation",
}
REQUIRED_FIELDS = {"schema", *COUNTER_FIELDS}


class EvidenceError(ValueError):
    """Raised when a log cannot be accepted as qualification evidence."""


def clean_lines(text: str) -> list[str]:
    return [ANSI_RE.sub("", line).strip() for line in text.splitlines()]


def unique_containing(lines: Iterable[str], needle: str, label: str) -> str:
    matches = [line for line in lines if needle in line]
    if len(matches) != 1:
        raise EvidenceError(f"expected exactly one {label}, found {len(matches)}")
    return matches[0]


def parse_key_values(fragment: str, label: str) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for token in fragment.split():
        if "=" not in token:
            raise EvidenceError(f"{label}: malformed token {token!r}")
        key, value = token.split("=", 1)
        if not key or not value:
            raise EvidenceError(f"{label}: malformed token {token!r}")
        if key in result:
            raise EvidenceError(f"{label}: duplicate field {key}")
        result[key] = value
    return result


def parse_marker_text(text: str) -> Dict[str, int]:
    lines = clean_lines(text)
    marker_line = unique_containing(lines, MARKER, "write-path marker")
    start = marker_line.index(MARKER) + len(MARKER)
    raw = parse_key_values(marker_line[start:], "write-path marker")
    keys = set(raw)
    if keys != REQUIRED_FIELDS:
        missing = sorted(REQUIRED_FIELDS - keys)
        extra = sorted(keys - REQUIRED_FIELDS)
        raise EvidenceError(
            f"write-path marker field mismatch: missing={missing} extra={extra}")
    if raw["schema"] != SCHEMA:
        raise EvidenceError(f"write-path marker schema mismatch: {raw['schema']}")

    values: Dict[str, int] = {}
    for key in sorted(COUNTER_FIELDS):
        value = raw[key]
        if not UINT_RE.fullmatch(value):
            raise EvidenceError(f"write-path marker {key} is not an unsigned integer")
        values[key] = int(value, 10)
    validate_marker(values)
    return values


def require_equal(actual: int, expected: int, label: str) -> None:
    if actual != expected:
        raise EvidenceError(f"{label}: expected {expected}, got {actual}")


def validate_marker(value: Mapping[str, int]) -> None:
    require_equal(value["complete"], 1, "probe complete")
    require_equal(value["available"], 1, "probe available")
    require_equal(value["overflow"], 0, "probe overflow")
    require_equal(value["invalid"], 0, "probe invalid")
    if value["cycles"] <= 0:
        raise EvidenceError("probe cycles must be positive")

    require_equal(
        value["arb_events"],
        sum(value[f"arb_source{matrix}"] for matrix in ("11", "10", "01", "00")),
        "arbiter source-matrix conservation")
    require_equal(
        value["arb_events"],
        sum(value[f"arb_ready{matrix}"] for matrix in ("11", "10", "01", "00")),
        "arbiter ready-matrix conservation")
    require_equal(
        value["arb_events"], value["arb_lane0"] + value["arb_lane1"],
        "arbiter lane conservation")
    if value["arb_strict"] > min(value["arb_source11"], value["arb_ready11"]):
        raise EvidenceError("arbiter strict opportunity exceeds its qualifying sets")

    require_equal(
        value["xbar_grants"],
        sum(value[f"xbar_ready{matrix}"] for matrix in ("11", "10", "01", "00")),
        "crossbar ready-matrix conservation")
    require_equal(
        value["xbar_grants"], value["xbar_master0"] + value["xbar_master1"],
        "crossbar master conservation")
    require_equal(
        value["xbar_grants"],
        sum(value[f"xbar_target{index}"] for index in range(16)),
        "crossbar target conservation")
    if value["xbar_grant_cycles"] > value["xbar_grants"]:
        raise EvidenceError("crossbar grant cycles exceed grant events")
    if value["xbar_strict"] > value["xbar_ready11"]:
        raise EvidenceError("crossbar strict opportunity exceeds READY=11 grants")
    if value["xbar_grant_bvalid"] > value["xbar_grants"]:
        raise EvidenceError("crossbar BVALID count exceeds grants")
    for field in (
        "xbar_head0_wr_rsp", "xbar_head1_wr_rsp", "xbar_head_any_wr_rsp"):
        if value[field] > value["xbar_grants"]:
            raise EvidenceError(f"{field} exceeds grant events")

    require_equal(
        value["live_pairs"], value["live_master0"] + value["live_master1"],
        "live-pair master conservation")
    require_equal(
        value["live_pairs"],
        value["live_target_inactive"] + value["live_target_active"],
        "live-pair target-state conservation")
    for field in (
        "live_older_holder", "live_same_target_conflict", "live_narrow_eligible"):
        if value[field] > value["live_pairs"]:
            raise EvidenceError(f"{field} exceeds live pairs")
    if value["live_narrow_eligible"] > value["live_target_inactive"]:
        raise EvidenceError("narrow live eligibility exceeds inactive-target pairs")

    for field in (
        "arb_conservation", "xbar_ready_conservation",
        "xbar_master_conservation", "xbar_target_conservation",
        "live_conservation"):
        require_equal(value[field], 1, field)


def parse_region_line(lines: Iterable[str]) -> Dict[str, int | str]:
    line = unique_containing(lines, REGION_MARKER, "region final marker")
    raw = parse_key_values(line[line.index("FINAL ") + len("FINAL "):], "region final")
    if raw.get("schema") != "npc-rv64-region-final-v1":
        raise EvidenceError("region schema mismatch")
    required = {"complete", "termination_rc", "cycles", "retired"}
    if not required.issubset(raw):
        raise EvidenceError(f"region final missing fields {sorted(required - set(raw))}")
    result: Dict[str, int | str] = {"schema": raw["schema"]}
    for key in required:
        token = raw[key]
        if key == "termination_rc" and token.startswith("-"):
            digits = token[1:]
        else:
            digits = token
        if not UINT_RE.fullmatch(digits):
            raise EvidenceError(f"region {key} is malformed")
        result[key] = int(token, 10)
    return result


def parse_counter_line(lines: Iterable[str]) -> Dict[str, int | str]:
    line = unique_containing(lines, COUNTER_MARKER, "performance counter marker")
    raw = parse_key_values(
        line[line.index("COUNTERS_FINAL ") + len("COUNTERS_FINAL "):],
        "performance counters")
    if raw.get("schema") != "npc-rv64-performance-counter-v4":
        raise EvidenceError("performance counter schema mismatch")
    keys = {"complete", "available", "overflow", "invalid_events",
            "cycles", "retired_slots", "conservation"}
    if not keys.issubset(raw):
        raise EvidenceError(f"performance counters missing fields {sorted(keys - set(raw))}")
    result: Dict[str, int | str] = {"schema": raw["schema"]}
    for key in keys:
        if not UINT_RE.fullmatch(raw[key]):
            raise EvidenceError(f"performance counter {key} is malformed")
        result[key] = int(raw[key], 10)
    return result


def build_receipt(
    text: str,
    workload: str,
    expected_cycles: int,
    expected_retired: int,
) -> Dict[str, object]:
    lines = clean_lines(text)
    probe = parse_marker_text(text)
    region = parse_region_line(lines)
    counters = parse_counter_line(lines)

    require_equal(int(region["complete"]), 1, "region complete")
    require_equal(int(region["termination_rc"]), 0, "termination rc")
    require_equal(int(region["cycles"]), expected_cycles, "region cycles")
    require_equal(int(region["retired"]), expected_retired, "region retired")
    require_equal(probe["cycles"], expected_cycles, "probe/region cycles")
    require_equal(int(counters["complete"]), 1, "counter complete")
    require_equal(int(counters["available"]), 1, "counter available")
    require_equal(int(counters["overflow"]), 0, "counter overflow")
    require_equal(int(counters["invalid_events"]), 0, "counter invalid events")
    require_equal(int(counters["conservation"]), 1, "counter conservation")
    require_equal(int(counters["cycles"]), expected_cycles, "counter cycles")
    require_equal(int(counters["retired_slots"]), expected_retired,
                  "counter retired slots")

    if not any("GOOD TRAP" in line for line in lines):
        raise EvidenceError("GOOD TRAP marker is absent")
    if not any("Difftest: ON" in line for line in lines):
        raise EvidenceError("DiffTest ON marker is absent")

    return {
        "schema": RECEIPT_SCHEMA,
        "status": "WRITE_PATH_BUBBLE_QUALIFIED",
        "workload": workload,
        "functional": {
            "good_trap": True,
            "difftest": "ON",
            "termination_rc": 0,
        },
        "region": region,
        "performance_counters": counters,
        "probe": dict(sorted(probe.items())),
    }


def write_json(path: pathlib.Path, value: Mapping[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")


def command_parse(args: argparse.Namespace) -> int:
    text = args.log.read_text(encoding="utf-8", errors="strict")
    receipt = build_receipt(
        text, args.workload, args.expected_cycles, args.expected_retired)
    write_json(args.output, receipt)
    print(
        "[WRITE-PATH-BUBBLE][PASS] "
        f"workload={args.workload} cycles={receipt['region']['cycles']} "
        f"arb_strict={receipt['probe']['arb_strict']} "
        f"xbar_grants={receipt['probe']['xbar_grants']} "
        f"xbar_ready11={receipt['probe']['xbar_ready11']} "
        f"live_narrow={receipt['probe']['live_narrow_eligible']}")
    return 0


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    parse = subparsers.add_parser("parse")
    parse.add_argument("--log", type=pathlib.Path, required=True)
    parse.add_argument("--workload", required=True)
    parse.add_argument("--expected-cycles", type=int, required=True)
    parse.add_argument("--expected-retired", type=int, required=True)
    parse.add_argument("--output", type=pathlib.Path, required=True)
    parse.set_defaults(function=command_parse)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = make_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.function(args))
    except (EvidenceError, OSError, UnicodeError) as error:
        print(f"[WRITE-PATH-BUBBLE][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
