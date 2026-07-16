#!/usr/bin/env python3
"""Validate the T3L old/fresh branch-target focused OpenSTA evidence."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


PREFIX = "T3L-FOCUSED-STA"
COUNT_KEYS = (
    "frontend_cells",
    "decoder_cells",
    "target_cells",
    "dec0_bimm_pins",
    "dec1_bimm_pins",
    "dec0_sign_pins",
    "dec1_sign_pins",
    "dec0_wide_pins",
    "dec1_wide_pins",
    "target_bimm_pins",
    "target_sign_pins",
    "target_output_pins",
    "pc_outstanding_d_pins",
    "packet_fifo_d_pins",
)
QUERY_NAMES = (
    "decoder_sign_to_pc",
    "decoder_sign_to_fifo",
    "target_sign_to_pc",
    "target_output_to_pc",
    "target_output_to_fifo",
)


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular evidence: {path}")


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def parse_exact_kv(path: Path, expected_keys: tuple[str, ...]) -> dict[str, str]:
    require_regular(path)
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.count("=") != 1:
            fail(f"malformed KV line in {path}: {line!r}")
        key, value = line.split("=", 1)
        if not key or not value or key in result:
            fail(f"invalid or duplicate KV in {path}: {line!r}")
        result[key] = value
    if tuple(result) != expected_keys:
        fail(f"KV key/order mismatch in {path}: {tuple(result)}")
    return result


def parse_sections(path: Path) -> dict[str, dict[str, list[str]]]:
    require_regular(path)
    sections: dict[str, dict[str, list[str]]] = {}
    current: dict[str, list[str]] | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        header = re.fullmatch(r"\[([a-z0-9_]+)\](?: count=([0-9]+))?", line)
        if header:
            name, count = header.groups()
            if name in sections:
                fail(f"duplicate section in {path}: {name}")
            current = {}
            sections[name] = current
            if count is not None:
                current["declared_count"] = [count]
            continue
        if current is None:
            fail(f"content before section header in {path}: {line!r}")
        if "=" in line:
            key, value = line.split("=", 1)
            if not key or not value:
                fail(f"malformed section KV in {path}: {line!r}")
            current.setdefault(key, []).append(value)
        else:
            current.setdefault("object", []).append(line)
    return sections


def one(section: dict[str, list[str]], key: str, label: str) -> str:
    values = section.get(key, [])
    if len(values) != 1:
        fail(f"{label} expected one {key}, got {values}")
    return values[0]


def parse_integer(value: str, label: str) -> int:
    if re.fullmatch(r"[0-9]+", value) is None:
        fail(f"{label} is not a non-negative integer: {value!r}")
    return int(value)


def parse_intersection(path: Path) -> dict[str, list[str]]:
    require_regular(path)
    result: dict[str, list[str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.count("=") != 1:
            fail(f"malformed intersection line in {path}: {line!r}")
        key, value = line.split("=", 1)
        result.setdefault(key, []).append(value)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--expected-input-manifest", type=Path, required=True)
    parser.add_argument("--expected-parameters", type=Path, required=True)
    parser.add_argument("out_dir", type=Path)
    args = parser.parse_args()
    for path in (
        args.expected_netlist,
        args.expected_input_manifest,
        args.expected_parameters,
    ):
        require_regular(path)
    if not args.out_dir.is_dir() or args.out_dir.is_symlink():
        fail(f"missing or symlink output directory: {args.out_dir}")

    counts_path = args.out_dir / "opensta-t3l-focused-counts.txt"
    objects_path = args.out_dir / "opensta-t3l-focused-objects.txt"
    queries_path = args.out_dir / "opensta-t3l-focused-queries.txt"
    complete_path = args.out_dir / "opensta-t3l-focused-complete.txt"
    console_path = args.out_dir / "opensta-console.log"
    counts_raw = parse_exact_kv(counts_path, COUNT_KEYS)
    counts = {key: parse_integer(value, key) for key, value in counts_raw.items()}

    fixed = {
        "frontend_cells": 1,
        "decoder_cells": 1,
        "dec0_sign_pins": 1,
        "dec1_sign_pins": 1,
    }
    if args.expect == "old":
        fixed.update(
            {
                "target_cells": 0,
                "dec0_bimm_pins": 64,
                "dec1_bimm_pins": 64,
                "dec0_wide_pins": 51,
                "dec1_wide_pins": 51,
                "target_bimm_pins": 0,
                "target_sign_pins": 0,
                "target_output_pins": 0,
            }
        )
    else:
        fixed.update(
            {
                "target_cells": 2,
                "dec0_bimm_pins": 13,
                "dec1_bimm_pins": 13,
                "dec0_wide_pins": 0,
                "dec1_wide_pins": 0,
                "target_bimm_pins": 26,
                "target_sign_pins": 2,
                "target_output_pins": 128,
            }
        )
    for key, expected in fixed.items():
        if counts[key] != expected:
            fail(f"count mismatch {key}: {counts[key]} != {expected}")
    for key in ("pc_outstanding_d_pins", "packet_fifo_d_pins"):
        if counts[key] <= 0:
            fail(f"endpoint collection is empty: {key}")

    object_sections = parse_sections(objects_path)
    if tuple(object_sections) != COUNT_KEYS:
        fail(f"object section key/order mismatch: {tuple(object_sections)}")
    objects: dict[str, list[str]] = {}
    for key in COUNT_KEYS:
        section = object_sections[key]
        declared = parse_integer(one(section, "declared_count", key), key)
        entries = section.get("object", [])
        if declared != counts[key] or len(entries) != counts[key]:
            fail(
                f"object cardinality mismatch {key}: "
                f"declared={declared} entries={len(entries)} counts={counts[key]}"
            )
        if len(entries) != len(set(entries)):
            fail(f"duplicate objects in section: {key}")
        objects[key] = entries

    query_sections = parse_sections(queries_path)
    if tuple(query_sections) != QUERY_NAMES:
        fail(f"query key/order mismatch: {tuple(query_sections)}")
    expected_status = {
        "decoder_sign_to_pc": "PATHS_PRESENT",
        "decoder_sign_to_fifo": "PATHS_PRESENT",
        "target_sign_to_pc": "PATHS_PRESENT" if args.expect == "fresh" else "PORT_ABSENT",
        "target_output_to_pc": "PATHS_PRESENT" if args.expect == "fresh" else "PORT_ABSENT",
        "target_output_to_fifo": "PATHS_PRESENT" if args.expect == "fresh" else "PORT_ABSENT",
    }
    expected_cardinality = {
        "decoder_sign_to_pc": (2, counts["pc_outstanding_d_pins"]),
        "decoder_sign_to_fifo": (2, counts["packet_fifo_d_pins"]),
        "target_sign_to_pc": (
            counts["target_sign_pins"],
            counts["pc_outstanding_d_pins"] if args.expect == "fresh" else 0,
        ),
        "target_output_to_pc": (
            counts["target_output_pins"],
            counts["pc_outstanding_d_pins"] if args.expect == "fresh" else 0,
        ),
        "target_output_to_fifo": (
            counts["target_output_pins"],
            counts["packet_fifo_d_pins"] if args.expect == "fresh" else 0,
        ),
    }
    for name in QUERY_NAMES:
        section = query_sections[name]
        if one(section, "selector", name) != "through_to":
            fail(f"query selector mismatch: {name}")
        status = one(section, "status", name)
        if status != expected_status[name]:
            fail(f"query status mismatch {name}: {status} != {expected_status[name]}")
        source_count = parse_integer(one(section, "source_count", name), name)
        target_count = parse_integer(one(section, "target_count", name), name)
        if (source_count, target_count) != expected_cardinality[name]:
            fail(
                f"query cardinality mismatch {name}: "
                f"{(source_count, target_count)} != {expected_cardinality[name]}"
            )
        if len(section.get("source_object", [])) != source_count:
            fail(f"query source object count mismatch: {name}")
        if len(section.get("target_object", [])) != target_count:
            fail(f"query target object count mismatch: {name}")
        report_name = one(section, "report", name)
        if report_name != f"opensta-t3l-{name}.rpt":
            fail(f"query report filename mismatch: {name} -> {report_name}")
        report_path = args.out_dir / report_name
        require_regular(report_path)
        text = report_path.read_text(encoding="utf-8")
        if status == "PATHS_PRESENT":
            if "Startpoint:" not in text or "Endpoint:" not in text or "slack" not in text:
                fail(f"timing report lacks a complete path: {report_path}")
            if "No paths found." in text:
                fail(f"timing report contradicts PATHS_PRESENT: {report_path}")
        elif text.strip() != "status=PORT_ABSENT source_count=0 target_count=0":
            fail(f"non-canonical PORT_ABSENT report: {report_path}")

    intersection_specs = {
        "decoder-pc": (2, counts["pc_outstanding_d_pins"], True),
        "decoder-fifo": (2, counts["packet_fifo_d_pins"], True),
        "target-pc": (
            counts["target_output_pins"],
            counts["pc_outstanding_d_pins"] if args.expect == "fresh" else 0,
            args.expect == "fresh",
        ),
        "target-fifo": (
            counts["target_output_pins"],
            counts["packet_fifo_d_pins"] if args.expect == "fresh" else 0,
            args.expect == "fresh",
        ),
    }
    intersections: dict[str, int] = {}
    for name, (expected_source, expected_target, must_exist) in intersection_specs.items():
        path = args.out_dir / f"opensta-t3l-{name}-intersection.txt"
        values = parse_intersection(path)
        source_count = parse_integer(one(values, "source_count", name), name)
        target_count = parse_integer(one(values, "target_count", name), name)
        intersection_count = parse_integer(one(values, "intersection_count", name), name)
        if (source_count, target_count) != (expected_source, expected_target):
            fail(f"intersection cardinality mismatch {name}")
        entries = values.get("intersection_object", [])
        if len(entries) != intersection_count or len(entries) != len(set(entries)):
            fail(f"intersection object cardinality/uniqueness mismatch: {name}")
        if must_exist and intersection_count <= 0:
            fail(f"required fanout intersection is empty: {name}")
        if not must_exist:
            if one(values, "status", name) != "PORT_ABSENT" or intersection_count != 0:
                fail(f"old target intersection is not canonical PORT_ABSENT: {name}")
        intersections[name] = intersection_count

    complete_keys = (
        "status",
        "expect",
        "period_ns",
        "top",
        "netlist",
        "netlist_sha256",
        "input_manifest_sha256",
        "parameters_sha256",
    )
    complete = parse_exact_kv(complete_path, complete_keys)
    expected_complete = {
        "status": "COMPLETE",
        "expect": args.expect,
        "period_ns": "5.0",
        "top": "NpcTop",
        "netlist": str(args.expected_netlist.resolve()),
        "netlist_sha256": digest(args.expected_netlist),
        "input_manifest_sha256": digest(args.expected_input_manifest),
        "parameters_sha256": digest(args.expected_parameters),
    }
    if complete != expected_complete:
        fail(f"completion provenance mismatch: {complete} != {expected_complete}")
    require_regular(console_path)
    console = console_path.read_text(encoding="utf-8", errors="strict")
    if re.search(r"(^|\n)(Error:|can't read )", console):
        fail("OpenSTA console contains an error marker")

    print(
        f"[{PREFIX}] PASS expect={args.expect} "
        f"decoder_width={counts['dec0_bimm_pins']} "
        f"targets={counts['target_cells']} "
        f"decoder_pc_fanout={intersections['decoder-pc']} "
        f"decoder_fifo_fanout={intersections['decoder-fifo']}"
    )


if __name__ == "__main__":
    main()
