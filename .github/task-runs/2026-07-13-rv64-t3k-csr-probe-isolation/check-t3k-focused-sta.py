#!/usr/bin/env python3
"""Validate the T3K CSR-probe isolation focused OpenSTA proof."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


PREFIX = "T3K-FOCUSED-STA"


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular file: {path}")


def read_unique_kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed key/value line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in result:
            fail(f"empty/duplicate key {path.name}:{number}: {key!r}")
        result[key] = value
    return result


def read_counts(path: Path) -> dict[str, int]:
    raw = read_unique_kv(path)
    try:
        return {key: int(value) for key, value in raw.items()}
    except ValueError:
        fail(f"non-integer count in {path}")


def read_objects(path: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    expected: dict[str, int] = {}
    current: str | None = None
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        header = re.fullmatch(r"\[([^]]+)] count=(\d+)", line)
        if header is not None:
            current = header.group(1)
            if current in result:
                fail(f"duplicate object section: {current}")
            result[current] = []
            expected[current] = int(header.group(2))
        elif current is None or not line:
            fail(f"malformed object line {path.name}:{number}: {line!r}")
        else:
            result[current].append(line)
    for label, objects in result.items():
        if len(objects) != expected[label] or len(objects) != len(set(objects)):
            fail(f"object cardinality/uniqueness mismatch: {label}")
    return result


def read_queries(path: Path) -> dict[str, dict[str, str | list[str]]]:
    result: dict[str, dict[str, str | list[str]]] = {}
    current: dict[str, str | list[str]] | None = None
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if not line:
            current = None
            continue
        section = re.fullmatch(r"\[([^]]+)]", line)
        if section is not None:
            name = section.group(1)
            if name in result:
                fail(f"duplicate query section: {name}")
            current = {"source_object": [], "target_object": []}
            result[name] = current
            continue
        if current is None or line.count("=") != 1:
            fail(f"malformed query line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if key in ("source_object", "target_object"):
            field = current[key]
            if not isinstance(field, list):
                fail(f"internal query parser type mismatch: {key}")
            field.append(value)
        elif not key or key in current:
            fail(f"empty/duplicate query key: {key!r}")
        else:
            current[key] = value
    return result


def read_intersection(path: Path) -> dict[str, str | list[str]]:
    result: dict[str, str | list[str]] = {
        "source_object": [],
        "intersection_object": [],
    }
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed intersection line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if key in ("source_object", "intersection_object"):
            field = result[key]
            if not isinstance(field, list):
                fail(f"internal intersection parser type mismatch: {key}")
            field.append(value)
        elif not key or key in result:
            fail(f"empty/duplicate intersection key: {key!r}")
        else:
            result[key] = value
    return result


def require_clean_console(path: Path) -> None:
    text = path.read_text(errors="replace")
    if re.search(r"\b(?:warning|error)(?:\s+\d+)?\s*:", text, re.IGNORECASE):
        fail("focused OpenSTA console contains a Warning/Error diagnostic")
    if re.search(r"Creating black box", text, re.IGNORECASE):
        fail("focused OpenSTA created an unknown black box")


def verify_report(path: Path, status: str) -> int:
    require_regular(path)
    text = path.read_text()
    if status == "NO_TIMING_PATH":
        if re.fullmatch(
            r"status=NO_TIMING_PATH through_count=\d+ to_count=\d+\n?", text
        ) is None:
            fail(f"NO_TIMING_PATH report has unexpected content: {path.name}")
        return 0
    if status == "PORT_ABSENT":
        if not text.startswith("status=PORT_ABSENT"):
            fail(f"PORT_ABSENT report has unexpected content: {path.name}")
        return 0
    if status != "PATHS_PRESENT":
        fail(f"unknown query status {status!r}: {path.name}")
    if "No paths found." in text or "status=NO_TIMING_PATH" in text:
        fail(f"PATHS_PRESENT report contains no-path marker: {path.name}")
    starts = len(re.findall(r"^Startpoint:", text, re.MULTILINE))
    endpoints = len(re.findall(r"^Endpoint:", text, re.MULTILINE))
    slacks = len(
        re.findall(
            r"^\s*-?\d+\.\d+\s+slack\s+\((?:VIOLATED|MET)\)$",
            text,
            re.MULTILINE,
        )
    )
    if starts == 0 or not (starts == endpoints == slacks) or starts > 20:
        fail(
            f"timing report path cardinality mismatch {path.name}: "
            f"start={starts} endpoint={endpoints} slack={slacks}"
        )
    return starts


def verify_intersection(
    path: Path,
    expected_sources: list[str],
    expected_target_count: int,
    expected_intersection_count: int,
) -> int:
    raw = read_intersection(path)
    source_objects = raw["source_object"]
    intersection_objects = raw["intersection_object"]
    if not isinstance(source_objects, list) or not isinstance(intersection_objects, list):
        fail(f"intersection list type mismatch: {path.name}")
    expected_keys = {
        "source_count",
        "source_object",
        "target_count",
        "intersection_count",
        "intersection_object",
    }
    if set(raw) != expected_keys:
        fail(f"intersection key set mismatch {path.name}: {set(raw)}")
    try:
        source_count = int(str(raw["source_count"]))
        target_count = int(str(raw["target_count"]))
        intersection_count = int(str(raw["intersection_count"]))
    except ValueError:
        fail(f"non-integer intersection count: {path.name}")
    if source_count != len(source_objects) or source_objects != expected_sources:
        fail(f"intersection source binding mismatch: {path.name}")
    if target_count != expected_target_count:
        fail(f"intersection target count mismatch: {path.name}")
    if intersection_count != len(intersection_objects):
        fail(f"intersection object count mismatch: {path.name}")
    if len(intersection_objects) != len(set(intersection_objects)):
        fail(f"duplicate intersection endpoint: {path.name}")
    if intersection_count != expected_intersection_count:
        fail(
            f"intersection count mismatch {path.name}: "
            f"count={intersection_count} expected={expected_intersection_count}"
        )
    return intersection_count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--expected-input-manifest", type=Path, required=True)
    parser.add_argument("--expected-parameters", type=Path, required=True)
    parser.add_argument("out_dir", type=Path)
    args = parser.parse_args()
    out = args.out_dir.resolve()
    console = out / "opensta-console.log"
    counts_path = out / "opensta-t3k-focused-counts.txt"
    objects_path = out / "opensta-t3k-focused-objects.txt"
    queries_path = out / "opensta-t3k-focused-queries.txt"
    complete_path = out / "opensta-t3k-focused-complete.txt"
    for path in (console, counts_path, objects_path, queries_path, complete_path):
        require_regular(path)
    expected_netlist = args.expected_netlist.resolve()
    expected_manifest = args.expected_input_manifest.resolve()
    expected_parameters = args.expected_parameters.resolve()
    for path in (expected_netlist, expected_manifest, expected_parameters):
        require_regular(path)
    require_clean_console(console)

    marker = read_unique_kv(complete_path)
    expected_marker = {
        "status": "COMPLETE",
        "expect": args.expect,
        "period_ns": "5.0",
        "top": "NpcTop",
        "netlist": str(expected_netlist),
        "netlist_sha256": sha256(expected_netlist),
        "input_manifest_sha256": sha256(expected_manifest),
        "parameters_sha256": sha256(expected_parameters),
    }
    if marker != expected_marker:
        fail(f"focused completion provenance mismatch: {marker}")

    counts = read_counts(counts_path)
    objects = read_objects(objects_path)
    if counts != {label: len(values) for label, values in objects.items()}:
        fail("count manifest differs from object manifest")
    expected_base_counts = {
        "mux_cells": 1,
        "csr_cells": 1,
        "pending_cells": 1,
        "commit_source_pins": 98,
        "pending_source_pins": 100,
        "head_source_pins": 69,
        "legacy_mux_output_pins": 21,
        "legacy_csr_input_pins": 21,
        "illegal_output_pins": 1,
        "state_priv_q_pins": 1,
        "state_mstatus_q_pins": 62,
        "state_mcounteren_q_pins": 3,
        "state_scounteren_q_pins": 3,
        "state_q_pins": 69,
        "pending_trap_d_pins": 133,
    }
    for label, expected in expected_base_counts.items():
        if counts.get(label) != expected:
            fail(f"focused object count mismatch {label}: {counts.get(label)} != {expected}")
    expected_probe_count = 0 if args.expect == "old" else 21
    for label in ("probe_mux_output_pins", "probe_csr_input_pins"):
        if counts.get(label) != expected_probe_count:
            fail(f"probe object count mismatch {label}: {counts.get(label)}")

    queries = read_queries(queries_path)
    expected_query_names = {
        "commit_to_illegal",
        "pending_to_illegal",
        "legacy_access_to_illegal",
        "legacy_access_to_pending",
        "head_to_illegal",
        "head_to_pending",
        "state_to_illegal",
        "state_to_pending",
        "illegal_to_pending",
        "probe_to_illegal",
        "probe_to_pending",
    }
    if set(queries) != expected_query_names:
        fail(f"focused query set mismatch: {set(queries)}")
    source_labels = {
        "commit_to_illegal": "commit_source_pins",
        "pending_to_illegal": "pending_source_pins",
        "legacy_access_to_illegal": "legacy_csr_input_pins",
        "legacy_access_to_pending": "legacy_csr_input_pins",
        "head_to_illegal": "head_source_pins",
        "head_to_pending": "head_source_pins",
        "state_to_illegal": "state_q_pins",
        "state_to_pending": "state_q_pins",
        "illegal_to_pending": "illegal_output_pins",
        "probe_to_illegal": "probe_csr_input_pins",
        "probe_to_pending": "probe_csr_input_pins",
    }
    target_labels = {
        "commit_to_illegal": "illegal_output_pins",
        "pending_to_illegal": "illegal_output_pins",
        "legacy_access_to_illegal": "illegal_output_pins",
        "legacy_access_to_pending": "pending_trap_d_pins",
        "head_to_illegal": "illegal_output_pins",
        "head_to_pending": "pending_trap_d_pins",
        "state_to_illegal": "illegal_output_pins",
        "state_to_pending": "pending_trap_d_pins",
        "illegal_to_pending": "pending_trap_d_pins",
        "probe_to_illegal": "illegal_output_pins",
        "probe_to_pending": "pending_trap_d_pins",
    }
    if args.expect == "old":
        expected_status = {
            "commit_to_illegal": "NO_TIMING_PATH",
            "pending_to_illegal": "NO_TIMING_PATH",
            "legacy_access_to_illegal": "NO_TIMING_PATH",
            "legacy_access_to_pending": "PATHS_PRESENT",
            "head_to_illegal": "NO_TIMING_PATH",
            "head_to_pending": "PATHS_PRESENT",
            "state_to_illegal": "NO_TIMING_PATH",
            "state_to_pending": "PATHS_PRESENT",
            "illegal_to_pending": "PATHS_PRESENT",
            "probe_to_illegal": "PORT_ABSENT",
            "probe_to_pending": "PORT_ABSENT",
        }
    else:
        expected_status = {
            "commit_to_illegal": "NO_TIMING_PATH",
            "pending_to_illegal": "NO_TIMING_PATH",
            "legacy_access_to_illegal": "NO_TIMING_PATH",
            "legacy_access_to_pending": "NO_TIMING_PATH",
            "head_to_illegal": "NO_TIMING_PATH",
            "head_to_pending": "PATHS_PRESENT",
            "state_to_illegal": "NO_TIMING_PATH",
            "state_to_pending": "PATHS_PRESENT",
            "illegal_to_pending": "PATHS_PRESENT",
            "probe_to_illegal": "NO_TIMING_PATH",
            "probe_to_pending": "PATHS_PRESENT",
        }
    total_report_paths = 0
    for name in sorted(expected_query_names):
        query = queries[name]
        expected_keys = {
            "report",
            "selector",
            "status",
            "source_count",
            "source_object",
            "target_count",
            "target_object",
        }
        if set(query) != expected_keys:
            fail(f"query key set mismatch {name}: {set(query)}")
        if query["selector"] != "through_to" or query["status"] != expected_status[name]:
            fail(f"query selector/status mismatch {name}: {query}")
        sources = query["source_object"]
        targets = query["target_object"]
        if not isinstance(sources, list) or not isinstance(targets, list):
            fail(f"query object-list type mismatch: {name}")
        if expected_status[name] == "PORT_ABSENT":
            if sources or targets or query["source_count"] != "0" or query["target_count"] != "0":
                fail(f"PORT_ABSENT query has bound objects: {name}")
        else:
            if sources != objects[source_labels[name]]:
                fail(f"query source binding mismatch: {name}")
            if targets != objects[target_labels[name]]:
                fail(f"query target binding mismatch: {name}")
            if int(str(query["source_count"])) != len(sources):
                fail(f"query source count mismatch: {name}")
            if int(str(query["target_count"])) != len(targets):
                fail(f"query target count mismatch: {name}")
        report_path = out / str(query["report"])
        if report_path.name != f"opensta-t3k-{name}.rpt":
            fail(f"query report binding mismatch: {name}")
        total_report_paths += verify_report(report_path, str(query["status"]))

    pending_count = counts["pending_trap_d_pins"]
    legacy_pending_intersection = verify_intersection(
        out / "opensta-t3k-legacy-pending-intersection.txt",
        objects["legacy_csr_input_pins"],
        pending_count,
        expected_intersection_count=(133 if args.expect == "old" else 0),
    )
    head_pending_intersection = verify_intersection(
        out / "opensta-t3k-head-pending-intersection.txt",
        objects["head_source_pins"],
        pending_count,
        expected_intersection_count=133,
    )
    state_pending_intersection = verify_intersection(
        out / "opensta-t3k-state-pending-intersection.txt",
        objects["state_q_pins"],
        pending_count,
        expected_intersection_count=133,
    )
    illegal_pending_intersection = verify_intersection(
        out / "opensta-t3k-illegal-pending-intersection.txt",
        objects["illegal_output_pins"],
        pending_count,
        expected_intersection_count=133,
    )
    probe_path = out / "opensta-t3k-probe-pending-intersection.txt"
    if args.expect == "old":
        old_probe = read_unique_kv(probe_path)
        if old_probe != {
            "status": "PORT_ABSENT",
            "source_count": "0",
            "target_count": "133",
            "intersection_count": "0",
        }:
            fail(f"old probe-intersection marker mismatch: {old_probe}")
        probe_intersection = 0
    else:
        probe_intersection = verify_intersection(
            probe_path,
            objects["probe_csr_input_pins"],
            pending_count,
            expected_intersection_count=133,
        )

    print(
        f"[{PREFIX}] PASS: expect={args.expect} report_paths={total_report_paths} "
        f"pending(legacy/head/state/illegal/probe)="
        f"{legacy_pending_intersection}/{head_pending_intersection}/"
        f"{state_pending_intersection}/{illegal_pending_intersection}/"
        f"{probe_intersection}"
    )


if __name__ == "__main__":
    main()
