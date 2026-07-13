#!/usr/bin/env python3
"""Fail closed on T3I legacy/fresh focused OpenSTA evidence."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-OPENSTA-FOCUSED] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_counts(path: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for line in path.read_text().splitlines():
        key, value = line.split("=", 1)
        if key in result:
            fail(f"duplicate count key: {key}")
        result[key] = int(value)
    return result


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_objects(path: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    current: str | None = None
    for line in path.read_text().splitlines():
        if line.startswith("["):
            label, count_text = line[1:].split("] count=", 1)
            if label in result:
                fail(f"duplicate object label: {label}")
            current = label
            result[current] = []
            result[f"{current}.__expected_count"] = [count_text]
        elif current is not None and line:
            result[current].append(line)
    for key in tuple(result):
        if key.endswith(".__expected_count"):
            continue
        expected = int(result[f"{key}.__expected_count"][0])
        if len(result[key]) != expected:
            fail(f"object manifest count mismatch for {key}")
    return result


def read_queries(path: Path) -> dict[str, dict[str, str | list[str]]]:
    result: dict[str, dict[str, str | list[str]]] = {}
    current: dict[str, str | list[str]] | None = None
    for line in path.read_text().splitlines():
        if not line:
            current = None
            continue
        if line.startswith("[") and line.endswith("]"):
            name = line[1:-1]
            if name in result:
                fail(f"duplicate query binding: {name}")
            current = {"source_object": [], "target_object": []}
            result[name] = current
            continue
        if current is None:
            fail(f"query binding field outside a section: {line!r}")
        key, value = line.split("=", 1)
        if key in ("source_object", "target_object"):
            objects = current[key]
            assert isinstance(objects, list)
            objects.append(value)
        else:
            if key in current:
                fail(f"duplicate query field: {key}")
            current[key] = value
    return result


def read_fanout(path: Path) -> dict[str, str | list[str]]:
    result: dict[str, str | list[str]] = {
        "source_object": [],
        "endpoint_object": [],
    }
    for line in path.read_text().splitlines():
        key, value = line.split("=", 1)
        if key in ("source_object", "endpoint_object"):
            objects = result[key]
            assert isinstance(objects, list)
            objects.append(value)
        else:
            if key in result:
                fail(f"duplicate fanout field: {key}")
            result[key] = value
    return result


def require_path(path: Path, target_token: str) -> None:
    text = path.read_text()
    if "EMPTY_COLLECTION" in text or "NO_TIMING_PATH" in text:
        fail(f"invalid path status in {path.name}")
    blocks = re.split(r"(?=^Startpoint:)", text, flags=re.MULTILINE)
    if blocks and not blocks[0].strip():
        blocks = blocks[1:]
    if not blocks:
        fail(f"missing timing path in {path.name}")
    slack_pattern = re.compile(
        r"^\s*-?\d+\.\d+\s+slack\s+\((?:VIOLATED|MET)\)$", re.MULTILINE
    )
    for index, block in enumerate(blocks, start=1):
        if len(re.findall(r"^Startpoint:", block, re.MULTILINE)) != 1:
            fail(f"bad Startpoint cardinality in {path.name} block {index}")
        if len(re.findall(r"^Endpoint:", block, re.MULTILINE)) != 1:
            fail(f"bad Endpoint cardinality in {path.name} block {index}")
        if len(slack_pattern.findall(block)) != 1:
            fail(f"bad slack cardinality in {path.name} block {index}")
        if target_token not in block:
            fail(
                f"wrong target family in {path.name} block {index}: "
                f"target={target_token}"
            )


def require_removed(path: Path, target_count: int) -> None:
    expected = (
        "status=REMOVED_THROUGH_PORT source_count=0 "
        f"target_count={target_count}"
    )
    if path.read_text().strip() != expected:
        fail(f"expected exact removed-port marker in {path.name}")


def require_query(
    queries: dict[str, dict[str, str | list[str]]],
    objects: dict[str, list[str]],
    name: str,
    report: str,
    selector: str,
    status: str,
    source_label: str,
    target_label: str,
) -> None:
    actual = queries.get(name)
    if actual is None:
        fail(f"missing query binding: {name}")
    expected: dict[str, str | list[str]] = {
        "report": report,
        "selector": selector,
        "status": status,
        "source_label": source_label,
        "source_count": str(len(objects[source_label])),
        "source_object": objects[source_label],
        "target_label": target_label,
        "target_count": str(len(objects[target_label])),
        "target_object": objects[target_label],
    }
    if actual != expected:
        fail(f"bad query binding {name}: actual={actual} expected={expected}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("present", "absent"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("out_dir", type=Path)
    args = parser.parse_args()
    out = args.out_dir

    console_path = out / "opensta-console.log"
    if not console_path.is_file() or console_path.stat().st_size == 0:
        fail("focused OpenSTA console is missing or empty")
    console = console_path.read_text()
    if re.search(r"^\s*Error:", console, re.MULTILINE):
        fail("focused OpenSTA console contains an Error diagnostic")
    if re.search(
        r"^Warning 198:.*module .* not found\. Creating black box",
        console,
        re.MULTILINE,
    ):
        fail("focused OpenSTA linked an unknown module as a black box")

    marker: dict[str, str] = {}
    for line in (out / "opensta-t3i-focused-complete.txt").read_text().splitlines():
        key, value = line.split("=", 1)
        if key in marker:
            fail(f"duplicate completion key: {key}")
        marker[key] = value
    expected_netlist = args.expected_netlist.resolve()
    expected_marker = {
        "status": "COMPLETE",
        "expect": args.expect,
        "period_ns": "5.0",
        "netlist": str(expected_netlist),
        "netlist_sha256": sha256(expected_netlist),
    }
    if marker != expected_marker:
        fail(f"bad completion provenance: actual={marker} expected={expected_marker}")
    counts = read_counts(out / "opensta-t3i-focused-counts.txt")
    objects = read_objects(out / "opensta-t3i-focused-objects.txt")
    queries = read_queries(out / "opensta-t3i-focused-queries.txt")
    fanout = read_fanout(out / "opensta-t3i-retire-fanout-endpoints.txt")
    expected_common = {
        "gate_cells": 1,
        "trap_parent_cells": 1,
        "retire_producer_cells": 1,
        "retire_producer_pins": 2,
        "rob_count_pins": 5,
        "issue_count_pins": 4,
        "backend_drained_pins": 1,
        "fetch_payload_en": 1,
        "pending_trap_d": 137,
    }
    expected_count_keys = set(expected_common) | {"retire_pins"}
    if set(counts) != expected_count_keys:
        fail(f"unexpected count keys: {sorted(set(counts) ^ expected_count_keys)}")
    for key, value in expected_common.items():
        if counts.get(key) != value:
            fail(f"{key}={counts.get(key)}, expected {value}")
    for key, value in counts.items():
        if key not in objects or len(objects[key]) != value:
            fail(f"objects/counts disagree for {key}")
    if not objects["gate_cells"][0].endswith("/u_pending_drain_resolve_gate"):
        fail("wrong drain gate instance")
    if not objects["trap_parent_cells"][0].endswith(
        "/u_pending_trap_exit_sequencer"
    ):
        fail("wrong pending-trap parent instance")
    if not objects["retire_producer_cells"][0].endswith(
        "/u_execute_backend/u_core_slice"
    ):
        fail("wrong canonical retire producer instance")
    retire_parent = objects["retire_producer_cells"][0]
    if any(
        name.rsplit("/", 1)[0] != retire_parent
        for name in objects["retire_producer_pins"]
    ):
        fail("canonical retire pins do not share the canonical producer parent")
    if {name.rsplit("/", 1)[-1] for name in objects["retire_producer_pins"]} != {
        "retire_count_o_0_",
        "retire_count_o_1_",
    }:
        fail("canonical retire producer pin set drifted")
    if {name.rsplit("/", 1)[-1] for name in objects["rob_count_pins"]} != {
        f"rob_count_i_{bit}_" for bit in range(5)
    }:
        fail("ROB-count drain pin set drifted")
    if {name.rsplit("/", 1)[-1] for name in objects["issue_count_pins"]} != {
        f"issue_count_i_{bit}_" for bit in range(4)
    }:
        fail("issue-count drain pin set drifted")
    if not objects["backend_drained_pins"][0].endswith("/backend_drained_o"):
        fail("wrong backend-drained target")
    gate_parent = objects["gate_cells"][0]
    for label in (
        "retire_pins",
        "rob_count_pins",
        "issue_count_pins",
        "backend_drained_pins",
    ):
        if any(name.rsplit("/", 1)[0] != gate_parent for name in objects[label]):
            fail(f"{label} does not belong to the unique drain gate")
    if not objects["fetch_payload_en"][0].endswith(
        "/u_fetch_packet_cache/u_payload_sram/en_i"
    ):
        fail("wrong fetch payload SRAM endpoint")
    if any(
        not name.startswith(objects["trap_parent_cells"][0] + "/")
        or not name.endswith("/D")
        for name in objects["pending_trap_d"]
    ):
        fail("pending-trap endpoint set contains a non-sequential/non-owner D pin")

    expected_query_status = {
        "retire_to_fetch": (
            "opensta-t3i-retire-to-fetch.rpt",
            "through" if args.expect == "present" else "removed",
            "PATHS_PRESENT" if args.expect == "present" else "REMOVED_THROUGH_PORT",
            "retire_pins",
            "fetch_payload_en",
        ),
        "retire_to_pending_trap": (
            "opensta-t3i-retire-to-pending-trap.rpt",
            "through" if args.expect == "present" else "removed",
            "PATHS_PRESENT" if args.expect == "present" else "REMOVED_THROUGH_PORT",
            "retire_pins",
            "pending_trap_d",
        ),
        "rob_count_to_fetch": (
            "opensta-t3i-rob-count-to-fetch.rpt",
            "through",
            "PATHS_PRESENT",
            "rob_count_pins",
            "fetch_payload_en",
        ),
        "rob_count_to_pending_trap": (
            "opensta-t3i-rob-count-to-pending-trap.rpt",
            "through",
            "PATHS_PRESENT",
            "rob_count_pins",
            "pending_trap_d",
        ),
    }
    if set(queries) != set(expected_query_status):
        fail(f"query set drifted: {sorted(set(queries) ^ set(expected_query_status))}")
    for name, binding in expected_query_status.items():
        require_query(queries, objects, name, *binding)

    expected_fanout_source = objects["retire_producer_pins"]
    if fanout.get("source_label") != "retire_producer_pins":
        fail("fanout manifest is bound to the wrong source label")
    if fanout.get("source_count") != str(len(expected_fanout_source)):
        fail("fanout manifest source count drifted")
    if fanout.get("source_object") != expected_fanout_source:
        fail("fanout manifest source objects drifted")
    endpoint_objects = fanout.get("endpoint_object")
    if not isinstance(endpoint_objects, list):
        fail("fanout endpoint list is malformed")
    if fanout.get("endpoint_count") != str(len(endpoint_objects)):
        fail("fanout endpoint count drifted")
    if not endpoint_objects or len(endpoint_objects) != len(set(endpoint_objects)):
        fail("canonical retire fanout endpoints are empty or duplicated")
    endpoint_set = set(endpoint_objects)
    fetch_hits = endpoint_set & set(objects["fetch_payload_en"])
    trap_hits = endpoint_set & set(objects["pending_trap_d"])
    if args.expect == "present":
        if fetch_hits != set(objects["fetch_payload_en"]) or not trap_hits:
            fail(
                "legacy canonical-retire fanout lacks focused drain consumers: "
                f"fetch_hits={len(fetch_hits)} trap_hits={len(trap_hits)}"
            )
    elif fetch_hits or trap_hits:
        fail(
            "fresh canonical-retire fanout still reaches the drain domain: "
            f"fetch_hits={len(fetch_hits)} trap_hits={len(trap_hits)}"
        )

    retire_reports = (
        out / "opensta-t3i-retire-to-fetch.rpt",
        out / "opensta-t3i-retire-to-pending-trap.rpt",
    )
    if args.expect == "present":
        if counts.get("retire_pins") != 2:
            fail(f"legacy retire_pins={counts.get('retire_pins')}, expected 2")
        if {name.rsplit("/", 1)[-1] for name in objects["retire_pins"]} != {
            "core_retire_count_i_0_",
            "core_retire_count_i_1_",
        }:
            fail("legacy gate retire pin set drifted")
        require_path(retire_reports[0], "u_payload_sram")
        require_path(retire_reports[1], "u_pending_trap_exit_sequencer")
    else:
        if counts.get("retire_pins") != 0:
            fail(f"fresh retire_pins={counts.get('retire_pins')}, expected 0")
        require_removed(retire_reports[0], 1)
        require_removed(retire_reports[1], 137)

    require_path(
        out / "opensta-t3i-rob-count-to-fetch.rpt",
        "u_payload_sram",
    )
    require_path(
        out / "opensta-t3i-rob-count-to-pending-trap.rpt",
        "u_pending_trap_exit_sequencer",
    )
    print(
        "[T3I-OPENSTA-FOCUSED] PASS: "
        f"expect={args.expect} retire_pins={counts['retire_pins']} "
        f"pending_trap_d={counts['pending_trap_d']}"
    )


if __name__ == "__main__":
    main()
