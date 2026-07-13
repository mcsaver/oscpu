#!/usr/bin/env python3
"""Fail-closed validation for the T3J old/fresh focused OpenSTA proof."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3J-OPENSTA-FOCUSED] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_unique_kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed key/value line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in result:
            fail(f"duplicate/empty key in {path.name}:{number}: {key!r}")
        result[key] = value
    return result


def read_counts(path: Path) -> dict[str, int]:
    return {key: int(value) for key, value in read_unique_kv(path).items()}


def read_objects(path: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    expected: dict[str, int] = {}
    current: str | None = None
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        header = re.fullmatch(r"\[([^]]+)] count=(\d+)", line)
        if header:
            current = header.group(1)
            if current in result:
                fail(f"duplicate object section in {path.name}: {current}")
            result[current] = []
            expected[current] = int(header.group(2))
        elif current is None or not line:
            fail(f"malformed object manifest line {path.name}:{number}: {line!r}")
        else:
            result[current].append(line)
    if set(result) != set(expected):
        fail("internal object manifest parser mismatch")
    for label, objects in result.items():
        if len(objects) != expected[label]:
            fail(
                f"object count mismatch for {label}: "
                f"actual={len(objects)} expected={expected[label]}"
            )
        if len(objects) != len(set(objects)):
            fail(f"duplicate objects in section: {label}")
    return result


def read_queries(path: Path) -> dict[str, dict[str, str | list[str]]]:
    result: dict[str, dict[str, str | list[str]]] = {}
    current: dict[str, str | list[str]] | None = None
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if not line:
            current = None
            continue
        section = re.fullmatch(r"\[([^]]+)]", line)
        if section:
            name = section.group(1)
            if name in result:
                fail(f"duplicate query section: {name}")
            current = {"source_object": [], "target_object": []}
            result[name] = current
            continue
        if current is None or line.count("=") != 1:
            fail(f"malformed query manifest line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if key in ("source_object", "target_object"):
            field = current[key]
            assert isinstance(field, list)
            field.append(value)
        elif key in current or not key:
            fail(f"duplicate/empty query key at {path.name}:{number}: {key!r}")
        else:
            current[key] = value
    return result


def read_fanout(path: Path) -> dict[str, str | list[str]]:
    result: dict[str, str | list[str]] = {
        "source_object": [],
        "endpoint_object": [],
    }
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed fanout line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if key in ("source_object", "endpoint_object"):
            field = result[key]
            assert isinstance(field, list)
            field.append(value)
        elif key in result or not key:
            fail(f"duplicate/empty fanout key at {path.name}:{number}: {key!r}")
        else:
            result[key] = value
    return result


def read_startpoint_provenance(
    path: Path,
) -> tuple[dict[str, str], list[dict[str, str]]]:
    raw = read_unique_kv(path)
    required_base = {"status", "source_label", "source_count", "startpoint_count"}
    if not required_base <= raw.keys():
        fail(f"startpoint provenance lacks base keys: {path.name}")
    try:
        source_count = int(raw["source_count"])
        startpoint_count = int(raw["startpoint_count"])
    except ValueError:
        fail(f"non-integer startpoint provenance count: {path.name}")
    if source_count < 0 or startpoint_count < 0:
        fail(f"negative startpoint provenance count: {path.name}")

    expected_keys = set(required_base)
    for index in range(source_count):
        expected_keys.add(f"source.{index}.object")
    records: list[dict[str, str]] = []
    for index in range(startpoint_count):
        prefix = f"startpoint.{index}"
        fixed = {
            f"{prefix}.object",
            f"{prefix}.cell_count",
            f"{prefix}.net_count",
            f"{prefix}.q_pin_count",
            f"{prefix}.q_net_count",
        }
        expected_keys.update(fixed)
        if not fixed <= raw.keys():
            fail(f"startpoint record {index} lacks fixed keys: {path.name}")
        try:
            cell_count = int(raw[f"{prefix}.cell_count"])
            net_count = int(raw[f"{prefix}.net_count"])
            q_pin_count = int(raw[f"{prefix}.q_pin_count"])
            q_net_count = int(raw[f"{prefix}.q_net_count"])
        except ValueError:
            fail(f"non-integer object count in startpoint record {index}")
        if min(cell_count, net_count, q_pin_count, q_net_count) < 0:
            fail(f"negative object count in startpoint record {index}")
        for cell_index in range(cell_count):
            expected_keys.add(f"{prefix}.cell.{cell_index}")
        for net_index in range(net_count):
            expected_keys.add(f"{prefix}.net.{net_index}")
        for q_pin_index in range(q_pin_count):
            expected_keys.add(f"{prefix}.q_pin.{q_pin_index}")
        for q_net_index in range(q_net_count):
            expected_keys.add(f"{prefix}.q_net.{q_net_index}")
        records.append(
            {
                "object": raw[f"{prefix}.object"],
                "cell_count": str(cell_count),
                "cell": raw.get(f"{prefix}.cell.0", ""),
                "net_count": str(net_count),
                "net": raw.get(f"{prefix}.net.0", ""),
                "q_pin_count": str(q_pin_count),
                "q_pin": raw.get(f"{prefix}.q_pin.0", ""),
                "q_net_count": str(q_net_count),
                "q_net": raw.get(f"{prefix}.q_net.0", ""),
            }
        )
    if set(raw) != expected_keys:
        fail(
            "startpoint provenance key set drifted: "
            f"missing={sorted(expected_keys - set(raw))} "
            f"extra={sorted(set(raw) - expected_keys)}"
        )
    return raw, records


def require_clean_console(path: Path) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        fail("focused OpenSTA console is missing or empty")
    text = path.read_text(errors="replace")
    if re.search(r"^\s*(?:Error:|ERROR:)", text, re.MULTILINE):
        fail("focused OpenSTA console contains an error diagnostic")
    if re.search(
        r"Warning 198:.*module .* not found\. Creating black box",
        text,
        re.IGNORECASE,
    ) or re.search(r"Creating black box", text, re.IGNORECASE):
        fail("focused OpenSTA linked an unknown module as a black box")


def path_blocks(path: Path, target_pin_token: str) -> list[str]:
    text = path.read_text()
    if "EMPTY_COLLECTION" in text or "NO_TIMING_PATH" in text:
        fail(f"expected timing paths but found a status marker: {path.name}")
    starts = [match.start() for match in re.finditer(r"^Startpoint:", text, re.MULTILINE)]
    if not starts or text[: starts[0]].strip():
        fail(f"missing paths or unexpected report prefix: {path.name}")
    blocks = [
        text[start : starts[index + 1] if index + 1 < len(starts) else len(text)]
        for index, start in enumerate(starts)
    ]
    slack_pattern = re.compile(
        r"^\s*-?\d+\.\d+\s+slack\s+\((?:VIOLATED|MET)\)$", re.MULTILINE
    )
    for index, block in enumerate(blocks, start=1):
        for label in ("Startpoint:", "Endpoint:", "Path Group:", "Path Type:"):
            if len(re.findall(rf"^{re.escape(label)}", block, re.MULTILINE)) != 1:
                fail(f"bad {label} cardinality in {path.name} block {index}")
        if len(slack_pattern.findall(block)) != 1:
            fail(f"bad slack cardinality in {path.name} block {index}")
        if target_pin_token not in block:
            fail(
                f"wrong endpoint pin family in {path.name} block {index}: "
                f"expected token={target_pin_token}"
            )
    return blocks


def require_no_timing_path(path: Path, through_count: int, to_count: int) -> None:
    expected = (
        f"status=NO_TIMING_PATH through_count={through_count} to_count={to_count}"
    )
    if path.read_text().strip() != expected:
        fail(f"expected exact no-path marker in {path.name}")


def require_query(
    queries: dict[str, dict[str, str | list[str]]],
    objects: dict[str, list[str]],
    name: str,
    report: str,
    status: str,
    source_label: str,
    target_label: str,
) -> None:
    expected: dict[str, str | list[str]] = {
        "report": report,
        "selector": "through",
        "status": status,
        "source_label": source_label,
        "source_count": str(len(objects[source_label])),
        "source_object": objects[source_label],
        "target_label": target_label,
        "target_count": str(len(objects[target_label])),
        "target_object": objects[target_label],
    }
    if queries.get(name) != expected:
        fail(
            f"query binding mismatch for {name}: "
            f"actual={queries.get(name)} expected={expected}"
        )


def require_fanout_binding(
    fanout: dict[str, str | list[str]],
    label: str,
    sources: list[str],
) -> set[str]:
    if fanout.get("source_label") != label:
        fail(f"fanout source label mismatch: expected={label}")
    if fanout.get("source_count") != str(len(sources)):
        fail(f"fanout source count mismatch: expected={len(sources)}")
    if fanout.get("source_object") != sources:
        fail(f"fanout source objects mismatch: expected label={label}")
    endpoints = fanout.get("endpoint_object")
    if not isinstance(endpoints, list):
        fail(f"malformed fanout endpoint list: {label}")
    if fanout.get("endpoint_count") != str(len(endpoints)):
        fail(f"fanout endpoint count mismatch: {label}")
    if not endpoints or len(endpoints) != len(set(endpoints)):
        fail(f"fanout endpoints are empty or duplicated: {label}")
    return set(endpoints)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("out_dir", type=Path)
    args = parser.parse_args()
    out = args.out_dir.resolve()
    expected_netlist = args.expected_netlist.resolve()

    require_clean_console(out / "opensta-console.log")
    marker = read_unique_kv(out / "opensta-t3j-focused-complete.txt")
    expected_marker = {
        "status": "COMPLETE",
        "expect": args.expect,
        "period_ns": "5.0",
        "netlist": str(expected_netlist),
        "netlist_sha256": file_sha256(expected_netlist),
    }
    if marker != expected_marker:
        fail(f"completion provenance mismatch: actual={marker} expected={expected_marker}")

    counts = read_counts(out / "opensta-t3j-focused-counts.txt")
    objects = read_objects(out / "opensta-t3j-focused-objects.txt")
    expected_counts = {
        "bridge_cells": 1,
        "fpc_cells": 1,
        "payload_cells": 1,
        "accept_pins": 1,
        "read_window_pins": 0 if args.expect == "old" else 1,
        "lookup_pc_pins": 64,
        "payload_en_pins": 1,
        "payload_addr_pins": 12,
    }
    if counts != expected_counts:
        fail(f"focused object counts drifted: actual={counts} expected={expected_counts}")
    if set(objects) != set(expected_counts):
        fail(f"object manifest labels drifted: {sorted(set(objects) ^ set(expected_counts))}")
    for label, expected_count in expected_counts.items():
        if len(objects[label]) != expected_count:
            fail(f"objects/counts mismatch for {label}")

    bridge = objects["bridge_cells"][0]
    fpc = objects["fpc_cells"][0]
    payload = objects["payload_cells"][0]
    if not bridge.endswith("/u_ooo_fetch_bridge"):
        fail("wrong bridge instance")
    if fpc != bridge + "/u_fetch_packet_cache":
        fail("FPC is not the unique bridge child")
    if payload != fpc + "/u_payload_sram":
        fail("payload SRAM is not the unique FPC child")
    if objects["accept_pins"] != [fpc + "/lookup_en_i"]:
        fail("semantic accept pin drifted")
    if args.expect == "fresh" and objects["read_window_pins"] != [
        fpc + "/lookup_read_en_i"
    ]:
        fail("physical read-window pin drifted")
    if objects["payload_en_pins"] != [payload + "/en_i"]:
        fail("payload SRAM enable pin drifted")
    if {item.rsplit("/", 1)[-1] for item in objects["lookup_pc_pins"]} != {
        f"lookup_pc_i_{bit}_" for bit in range(64)
    }:
        fail("FPC lookup PC pin set drifted")
    if any(item.rsplit("/", 1)[0] != fpc for item in objects["lookup_pc_pins"]):
        fail("lookup PC pin escaped the unique FPC")
    if {item.rsplit("/", 1)[-1] for item in objects["payload_addr_pins"]} != {
        f"addr_i[{bit}]" for bit in range(12)
    }:
        fail("payload SRAM address pin set drifted")
    if any(
        item.rsplit("/", 1)[0] != payload for item in objects["payload_addr_pins"]
    ):
        fail("payload address pin escaped the unique SRAM")

    queries = read_queries(out / "opensta-t3j-focused-queries.txt")
    expected_query_names = {"accept_to_payload_en", "pc_to_payload_addr"}
    if args.expect == "fresh":
        expected_query_names.add("read_window_to_payload_en")
    if set(queries) != expected_query_names:
        fail(f"directed query set drifted: {sorted(set(queries) ^ expected_query_names)}")
    require_query(
        queries,
        objects,
        "accept_to_payload_en",
        "opensta-t3j-accept-to-payload-en.rpt",
        "PATHS_PRESENT" if args.expect == "old" else "NO_TIMING_PATH",
        "accept_pins",
        "payload_en_pins",
    )
    require_query(
        queries,
        objects,
        "pc_to_payload_addr",
        "opensta-t3j-pc-to-payload-addr.rpt",
        "PATHS_PRESENT",
        "lookup_pc_pins",
        "payload_addr_pins",
    )
    if args.expect == "fresh":
        require_query(
            queries,
            objects,
            "read_window_to_payload_en",
            "opensta-t3j-read-window-to-payload-en.rpt",
            "PATHS_PRESENT",
            "read_window_pins",
            "payload_en_pins",
        )

    accept_report = out / "opensta-t3j-accept-to-payload-en.rpt"
    if args.expect == "old":
        path_blocks(accept_report, payload + "/en_i")
    else:
        require_no_timing_path(accept_report, 1, 1)
    path_blocks(out / "opensta-t3j-pc-to-payload-addr.rpt", payload + "/addr_i[")
    read_report = out / "opensta-t3j-read-window-to-payload-en.rpt"
    if args.expect == "fresh":
        path_blocks(read_report, payload + "/en_i")
    elif read_report.read_text().strip() != "status=PORT_ABSENT source_count=0 target_count=1":
        fail("old read-window report lacks the exact PORT_ABSENT marker")

    accept_endpoints = require_fanout_binding(
        read_fanout(out / "opensta-t3j-accept-fanout-endpoints.txt"),
        "accept_pins",
        objects["accept_pins"],
    )
    accept_en_hits = accept_endpoints & set(objects["payload_en_pins"])
    if args.expect == "old" and accept_en_hits != set(objects["payload_en_pins"]):
        fail("old semantic accept fanout does not reach payload SRAM en")
    if args.expect == "fresh" and accept_en_hits:
        fail("fresh semantic accept fanout still reaches payload SRAM en")

    address_endpoints = require_fanout_binding(
        read_fanout(out / "opensta-t3j-address-fanout-endpoints.txt"),
        "lookup_pc_pins",
        objects["lookup_pc_pins"],
    )
    address_hits = address_endpoints & set(objects["payload_addr_pins"])
    if address_hits != set(objects["payload_addr_pins"]):
        fail(
            "FPC PC-to-SRAM-address residual is incomplete: "
            f"hits={len(address_hits)} expected=12"
        )

    read_fanout_path = out / "opensta-t3j-read-window-fanout-endpoints.txt"
    if args.expect == "fresh":
        read_endpoints = require_fanout_binding(
            read_fanout(read_fanout_path),
            "read_window_pins",
            objects["read_window_pins"],
        )
        if read_endpoints & set(objects["payload_en_pins"]) != set(
            objects["payload_en_pins"]
        ):
            fail("fresh physical read-window fanout does not own payload SRAM en")
    elif read_fanout_path.read_text().strip() != "status=PORT_ABSENT source_count=0":
        fail("old read-window fanout lacks the exact PORT_ABSENT marker")

    startpoint_path = out / "opensta-t3j-read-window-startpoints.txt"
    startpoint_raw, startpoint_records = read_startpoint_provenance(startpoint_path)
    if args.expect == "old":
        expected_absent = {
            "status": "PORT_ABSENT",
            "source_label": "read_window_pins",
            "source_count": "0",
            "startpoint_count": "0",
        }
        if startpoint_raw != expected_absent or startpoint_records:
            fail("old read-window startpoint manifest lacks exact PORT_ABSENT closure")
    else:
        if startpoint_raw.get("status") != "STARTPOINTS_PRESENT":
            fail("fresh read-window startpoint manifest is not complete")
        if startpoint_raw.get("source_label") != "read_window_pins":
            fail("fresh read-window startpoint source label drifted")
        if startpoint_raw.get("source_count") != "1" or startpoint_raw.get(
            "source.0.object"
        ) != objects["read_window_pins"][0]:
            fail("fresh read-window startpoint sink is not the unique physical port")
        if len(startpoint_records) != 3:
            fail(
                "fresh physical read window must have the three optimized "
                f"state-decode startpoints, got {len(startpoint_records)}"
            )

        startpoint_names: set[str] = set()
        startpoint_cells: set[str] = set()
        startpoint_nets: set[str] = set()
        forbidden_alias = re.compile(
            r"fetch_req|lookup_(?:pc|en|read)|(?:^|[/_])(?:valid|ready|fire|pc)(?:[/_]|$)",
            re.IGNORECASE,
        )
        state_net = re.compile(rf"^{re.escape(bridge)}/state_q_[0-9]+_$")
        direct_synth_cell = re.compile(rf"^{re.escape(bridge)}/_[0-9]+_$")
        expected_state_nets = {
            f"{bridge}/state_q_0_",
            f"{bridge}/state_q_6_",
            f"{bridge}/state_q_8_",
        }
        for index, record in enumerate(startpoint_records):
            if (
                record["cell_count"] != "1"
                or record["net_count"] != "1"
                or record["q_pin_count"] != "1"
                or record["q_net_count"] != "1"
            ):
                fail(
                    f"read-window startpoint {index} is not one CK/cell/Q/net binding: "
                    f"cell_count={record['cell_count']} net_count={record['net_count']} "
                    f"q_pin_count={record['q_pin_count']} "
                    f"q_net_count={record['q_net_count']}"
                )
            pin, cell, net = record["object"], record["cell"], record["net"]
            q_pin, q_net = record["q_pin"], record["q_net"]
            if forbidden_alias.search("\n".join((pin, cell, net, q_pin, q_net))):
                fail(f"request/semantic alias reached read-window startpoint {index}")
            if not direct_synth_cell.fullmatch(cell) or pin != cell + "/CK":
                fail(
                    f"read-window startpoint {index} is not a direct bridge state flop CK: "
                    f"pin={pin} cell={cell}"
                )
            if net != bridge + "/clk":
                fail(f"read-window flop CK {index} is not driven by bridge clk: {net}")
            if q_pin != cell + "/Q" or not state_net.fullmatch(q_net):
                fail(
                    f"read-window startpoint {index} Q escaped bridge state_q family: "
                    f"q_pin={q_pin} q_net={q_net}"
                )
            startpoint_names.add(pin)
            startpoint_cells.add(cell)
            startpoint_nets.add(q_net)
        if len(startpoint_names) != len(startpoint_records):
            fail("duplicate read-window timing startpoint pins")
        if len(startpoint_cells) != len(startpoint_records):
            fail("multiple read-window startpoint records alias one flop")
        if len(startpoint_nets) != len(startpoint_records):
            fail("multiple read-window startpoint records alias one state_q net")
        if startpoint_nets != expected_state_nets:
            fail(
                "optimized read-window decode state_q set drifted: "
                f"actual={sorted(startpoint_nets)} expected={sorted(expected_state_nets)}"
            )

    print(
        "[T3J-OPENSTA-FOCUSED] PASS: "
        f"expect={args.expect} accept_to_en="
        f"{'present' if args.expect == 'old' else 'absent'} "
        f"address_residual={len(address_hits)}/12 "
        f"read_window_startpoints="
        f"{'absent' if args.expect == 'old' else 'state_q_0_6_8_only:' + str(len(startpoint_records))}"
    )


if __name__ == "__main__":
    main()
