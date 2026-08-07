#!/usr/bin/env python3
"""Validate exact-5 ns mapped STA evidence for the V15P RTL A/B."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import pathlib
import re
import sys
from typing import Any


ROOT = pathlib.Path("/home/lyg/PA/ysyx-workbench").resolve()
ADAPTER_KEY = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
EXPECTED_ADAPTER_SHA = {
    "parent": "3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6",
    "candidate": "6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22",
}
EXPECTED_UNKNOWN_MACROS = {
    "Sram4096x199",
    "Sram4096x113",
    "OooFpArithGate",
    "OooBranchDirectionPredictor",
}


class EvidenceError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, Any]:
    path = path.resolve()
    require(path.is_file() and not path.is_symlink() and path.stat().st_size > 0,
            f"invalid artifact: {path}")
    try:
        recorded_path = path.relative_to(ROOT).as_posix()
        path_scope = "workspace_relative"
    except ValueError:
        recorded_path = str(path)
        path_scope = "external_absolute"
    return {
        "path": recorded_path,
        "path_scope": path_scope,
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def read_unique_kv(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        require(line.count("=") == 1, f"malformed KV line {path}:{number}")
        key, value = line.split("=", 1)
        require(bool(key) and key not in result, f"duplicate/empty KV key: {key!r}")
        result[key] = value
    return result


def parse_source_manifest(path: pathlib.Path, mode: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = re.fullmatch(r"([0-9a-f]{64})\s+(.+)", line)
        require(match is not None, f"malformed source manifest line {number}")
        digest, raw_path = match.groups()
        source = pathlib.Path(raw_path).resolve()
        require(source.is_file() and sha256(source) == digest,
                f"synthesis source drifted: {source}")
        if source.name == "OooLsuAxiLaneAdapter.v":
            key = ADAPTER_KEY
        else:
            key = source.relative_to(ROOT).as_posix()
        require(key not in result, f"duplicate synthesis source key: {key}")
        result[key] = digest
    require(len(result) >= 120 and ADAPTER_KEY in result,
            f"incomplete synthesis source manifest: {len(result)}")
    require(result[ADAPTER_KEY] == EXPECTED_ADAPTER_SHA[mode],
            f"{mode} adapter source hash mismatch")
    return dict(sorted(result.items()))


def parse_setup(path: pathlib.Path, include_loop_blocks: bool = False) -> dict[str, Any]:
    expected = (
        ("missing_input_delay", "input ports missing set_input_delay"),
        ("missing_output_delay", "output ports missing set_output_delay"),
        ("unconstrained_endpoints", "unconstrained endpoints"),
    )
    lines = path.read_text(encoding="utf-8").splitlines()
    cursor = 0
    result: dict[str, Any] = {}
    for key, label in expected:
        require(cursor < len(lines), f"check_setup ended before {label}")
        heading = re.fullmatch(r"Warning: There are ([1-9][0-9]*) (.+)\.", lines[cursor])
        require(heading is not None and heading.group(2) == label,
                f"unexpected setup warning at {label}: {lines[cursor]!r}")
        count = int(heading.group(1))
        cursor += 1
        members = lines[cursor:cursor + count]
        require(len(members) == count, f"truncated setup warning members: {label}")
        normalized: list[str] = []
        for member in members:
            require(member.startswith("  ") and member[2:] == member[2:].strip(),
                    f"malformed setup member: {member!r}")
            normalized.append(member[2:])
        require(len(normalized) == len(set(normalized)),
                f"duplicate setup member: {label}")
        cursor += count
        result[key] = {
            "count": count,
            "members_sha256": hashlib.sha256(
                ("\n".join(sorted(normalized)) + "\n").encode("utf-8")
            ).hexdigest(),
        }
    loops: list[list[str]] = []
    if cursor < len(lines):
        loop_heading = re.fullmatch(
            r"Warning: There (?:is 1|are ((?:[2-9]|[1-9][0-9]+))) combinational "
            r"loop(?:s)? in the design\.", lines[cursor])
        require(loop_heading is not None,
                f"unexpected fourth setup warning/trailing text: {lines[cursor:cursor + 1]}")
        loop_count = int(loop_heading.group(1) or "1")
        cursor += 1
        block: list[str] = []
        while cursor < len(lines):
            line = lines[cursor]
            cursor += 1
            if line == "  --------------------------------":
                require(bool(block), "empty combinational-loop member block")
                loops.append(block)
                block = []
            else:
                require(line.startswith("  ") and line[2:] == line[2:].strip(),
                        f"malformed combinational-loop member: {line!r}")
                block.append(line[2:])
        require(not block and len(loops) == loop_count,
                f"combinational-loop block count mismatch: {len(loops)} != {loop_count}")
        for index, members in enumerate(loops, 1):
            require(members.count("| loop cut point") == 1 and len(members) >= 4,
                    f"malformed combinational-loop block {index}")
            pins = [member for member in members if member != "| loop cut point"]
            require(pins[0] == pins[-1], f"loop {index} does not close at one pin")
    loop_result: dict[str, Any] = {
        "count": len(loops),
        "block_member_counts": [len(block) - 1 for block in loops],
        "blocks_sha256": hashlib.sha256(
            json.dumps(loops, separators=(",", ":"), ensure_ascii=True).encode("ascii")
        ).hexdigest(),
    }
    if include_loop_blocks:
        loop_result["blocks"] = loops
    result["combinational_loops"] = loop_result
    return result


def split_path_blocks(text: str) -> list[str]:
    starts = [match.start() for match in re.finditer(r"^Startpoint:", text, re.MULTILINE)]
    require(bool(starts) and not text[:starts[0]].strip(),
            "top40 report lacks a clean first path block")
    blocks = [
        text[start:starts[index + 1] if index + 1 < len(starts) else len(text)]
        for index, start in enumerate(starts)
    ]
    for index, block in enumerate(blocks, 1):
        for label in ("Startpoint:", "Endpoint:", "Path Group:", "Path Type:"):
            require(len(re.findall(rf"^{re.escape(label)}", block, re.MULTILINE)) == 1,
                    f"bad {label} cardinality in path {index}")
        require(len(re.findall(
            r"^\s*-?\d+\.\d+\s+slack\s+\((?:VIOLATED|MET)\)$",
            block, re.MULTILINE)) == 1,
            f"bad slack cardinality in path {index}")
    return blocks


def parse_area(synth_stat: pathlib.Path) -> dict[str, Any]:
    text = synth_stat.read_text(encoding="utf-8", errors="strict")
    marker = "=== design hierarchy ==="
    require(text.count(marker) == 1,
            "mapped synthesis stat must contain one design-hierarchy summary")
    hierarchy = text.split(marker, 1)[1]

    cell_rows = list(re.finditer(
        r"^\s*(\d+)\s+\S+\s+cells\s*$", hierarchy, re.MULTILINE))
    require(len(cell_rows) == 1, "global mapped-cell summary cardinality mismatch")
    total_cells = int(cell_rows[0].group(1))
    top_rows = re.findall(
        r"^\s*(\d+)\s+\S+\s+NpcTop\s*$", hierarchy, re.MULTILINE)
    require(len(top_rows) == 1 and int(top_rows[0]) == total_cells,
            "NpcTop hierarchy count disagrees with global mapped-cell count")

    inventory_tail = hierarchy[cell_rows[0].end():]
    submodule_rows = list(re.finditer(
        r"^\s*\d+\s+\S+\s+submodules\s*$", inventory_tail, re.MULTILINE))
    require(len(submodule_rows) == 1, "global submodule summary cardinality mismatch")
    cell_inventory = inventory_tail[:submodule_rows[0].start()]
    unknown: dict[str, int] = {}
    for raw_count, name in re.findall(
            r"^\s*(\d+)\s+-\s+(\S+)\s*$", cell_inventory, re.MULTILINE):
        require(name not in unknown and int(raw_count) > 0,
                f"duplicate/invalid unknown mapped cell: {name}={raw_count}")
        unknown[name] = int(raw_count)
    require(set(unknown) == EXPECTED_UNKNOWN_MACROS,
            f"unknown mapped-cell inventory drifted: {unknown}")

    unknown_notices = set(re.findall(
        r"^\s*Area for cell type \\(\S+) is unknown!\s*$",
        hierarchy, re.MULTILINE))
    require(unknown_notices == EXPECTED_UNKNOWN_MACROS,
            f"unknown-area notice inventory drifted: {sorted(unknown_notices)}")
    area_rows = re.findall(
        r"^\s*Chip area for top module '\\NpcTop': ([0-9]+(?:\.[0-9]+)?)\s*$",
        hierarchy, re.MULTILINE)
    sequential_rows = re.findall(
        r"^\s*of which used for sequential elements: "
        r"([0-9]+(?:\.[0-9]+)?) \([0-9]+(?:\.[0-9]+)?%\)\s*$",
        hierarchy, re.MULTILINE)
    require(len(area_rows) == 1 and len(sequential_rows) == 1,
            "NpcTop mapped area summary cardinality mismatch")
    logic_area = float(area_rows[0])
    sequential_area = float(sequential_rows[0])
    known_cells = total_cells - sum(unknown.values())
    require(known_cells > 100_000 and logic_area > 100_000.0,
            f"implausible full-core mapped proxy: cells={known_cells} area={logic_area}")
    require(math.isfinite(logic_area) and math.isfinite(sequential_area)
            and 0.0 <= sequential_area <= logic_area,
            "invalid mapped area values")
    return {
        "source": "yosys_recursive_design_hierarchy",
        "logic_area_proxy_excluding_unknown_macros": logic_area,
        "sequential_area": sequential_area,
        "known_standard_cells": known_cells,
        "total_cells_including_unknown_macros": total_cells,
        "unknown_macro_instances": dict(sorted(unknown.items())),
    }


def parse_variant(args: argparse.Namespace) -> None:
    mode = args.mode
    require(mode in EXPECTED_ADAPTER_SHA, f"unsupported mode: {mode}")
    out_dir = args.out_dir.resolve()
    paths = {
        "setup": out_dir / "opensta-check-setup.txt",
        "top40": out_dir / "opensta-top40.rpt",
        "power": out_dir / "opensta-power.rpt",
        "console": out_dir / "opensta-console.log",
        "complete": out_dir / "opensta-complete.txt",
    }
    sta_export_check = out_dir / "sta_export_check.txt"
    sta_netlist_compatibility = out_dir / "sta-netlist-compatibility.txt"
    for path in (*paths.values(), args.netlist, args.input_manifest, args.parameters,
                 args.source_manifest, args.synth_check, args.synth_stat,
                 sta_export_check, sta_netlist_compatibility,
                 args.std_lib, args.opensta_binary):
        require(path.resolve().is_file() and not path.resolve().is_symlink()
                and path.resolve().stat().st_size > 0,
                f"missing/empty/symlink evidence: {path}")

    marker = read_unique_kv(paths["complete"])
    expected_marker = {
        "status": "COMPLETE",
        "mode": mode,
        "period_ns": "5.0",
        "top": "NpcTop",
        "clock_port": "clk",
        "clock_name": "core_clock",
        "netlist": str(args.netlist.resolve()),
        "netlist_sha256": sha256(args.netlist.resolve()),
        "std_lib": str(args.std_lib.resolve()),
        "macro_lib_count": "4",
        "input_manifest_sha256": sha256(args.input_manifest.resolve()),
        "parameters_sha256": sha256(args.parameters.resolve()),
        "opensta_binary": str(args.opensta_binary.resolve()),
        "opensta_binary_sha256": sha256(args.opensta_binary.resolve()),
    }
    require(marker == expected_marker,
            f"OpenSTA completion provenance mismatch: {marker}")
    require("Found and reported 0 problems." in args.synth_check.read_text(encoding="utf-8"),
            "mapped synthesis check is not clean")
    require("Found and reported 0 problems." in sta_export_check.read_text(encoding="utf-8"),
            "flat STA-export netlist check is not clean")
    require(sta_netlist_compatibility.read_text(encoding="utf-8") ==
            "status=PASS\n"
            "forbidden_patterns=paramod,wire_signed,instance_parameter_override\n",
            "STA-export netlist compatibility marker mismatch")

    console = paths["console"].read_text(encoding="utf-8", errors="replace")
    require(re.search(r"\b(?:Error|Warning)\s+[0-9]+:", console) is None,
            "OpenSTA console contains a diagnostic")
    require(re.search(r"Creating black box|combinational\s+loop", console, re.IGNORECASE) is None,
            "OpenSTA created a black box or found a loop")
    setup = parse_setup(paths["setup"])
    top = paths["top40"].read_text(encoding="utf-8")
    require(re.search(r"combinational\s+loop", top, re.IGNORECASE) is None,
            "timing report contains a combinational loop")
    blocks = split_path_blocks(top)
    require(len(blocks) == 40, f"top path count={len(blocks)}, expected 40")
    states = re.findall(
        r"^\s*(-?\d+\.\d+)\s+slack\s+\((VIOLATED|MET)\)$",
        top, re.MULTILINE)
    require(len(states) == 40, "top path slack inventory mismatch")
    slacks = [float(value) for value, _ in states]
    require(all(math.isfinite(value) for value in slacks), "non-finite path slack")
    require(all(not (value == 0.0 and math.copysign(1.0, value) < 0.0)
                for value in slacks), "path report contains negative-zero slack")
    require(all((state == "VIOLATED") == (value < 0.0)
                for value, (_, state) in zip(slacks, states, strict=True)),
            "path state disagrees with signed slack")
    violated = sum(state == "VIOLATED" for _, state in states)
    wns_match = re.findall(r"^wns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    tns_match = re.findall(r"^tns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    require(len(wns_match) == 1 and len(tns_match) == 1,
            "WNS/TNS marker cardinality mismatch")
    wns = float(wns_match[0])
    tns = float(tns_match[0])
    worst = min(slacks)
    if violated:
        require(worst < 0.0 and wns < 0.0 and tns < 0.0
                and abs(worst - wns) <= 0.011,
                "violated paths disagree with WNS/TNS")
    else:
        require(worst >= 0.0 and wns == 0.0 and tns == 0.0,
                "met paths disagree with clipped WNS/TNS")

    power_text = paths["power"].read_text(encoding="utf-8")
    power_match = re.search(
        r"^Total\s+\S+\s+\S+\s+\S+\s+(\S+)\s+100\.0%",
        power_text, re.MULTILINE)
    require(power_match is not None, "OpenSTA total-power row missing")
    total_power = float(power_match.group(1))
    require(math.isfinite(total_power) and total_power >= 0.0,
            f"invalid vectorless power: {total_power}")

    sources = parse_source_manifest(args.source_manifest.resolve(), mode)
    area = parse_area(args.synth_stat.resolve())
    loop_count = setup["combinational_loops"]["count"]
    result = {
        "schema": "npc-rv64-v15p-mapped-sta-variant-v1",
        "status": "PASS",
        "mode": mode,
        "period_ns": 5.0,
        "source_manifest": artifact(args.source_manifest),
        "actual_synthesis_source_sha256": sources,
        "netlist": {
            "sha256": sha256(args.netlist.resolve()),
            "size_bytes": args.netlist.resolve().stat().st_size,
            "runtime_retention": "DELETE_AFTER_EVIDENCE_CAPTURE",
        },
        "synthesis": {
            "check_problems": 0,
            "area": area,
            "synth_check": artifact(args.synth_check),
            "synth_stat": artifact(args.synth_stat),
            "sta_export_check": artifact(sta_export_check),
            "sta_netlist_compatibility": artifact(sta_netlist_compatibility),
        },
        "timing": {
            "worst_path_slack_ns": worst,
            "wns_ns": wns,
            "tns_ns": tns,
            "violated_path_count": violated,
            "combinational_loops": loop_count,
            "top_path_count": 40,
            "target_200mhz_met": loop_count == 0 and violated == 0 and worst >= 0.0,
            "minimum_promotion_margin_0p1ns_met": (
                loop_count == 0 and violated == 0 and worst >= 0.1),
            "adapter_tokens_in_top40": sum(
                "LsuAxiLaneAdapter" in block or "lsu_axi_adapter" in block
                for block in blocks),
        },
        "setup_warning_closure": setup,
        "power": {
            "total_vectorless_w": total_power,
            "qualification": "RELATIVE_ONLY_FIXED_TOGGLE_0P1",
        },
        "artifacts": {name: artifact(path) for name, path in paths.items()},
        "inputs": {
            "manifest": artifact(args.input_manifest),
            "parameters": artifact(args.parameters),
            "std_lib": artifact(args.std_lib),
            "opensta_binary": artifact(args.opensta_binary),
        },
    }
    write_json(args.output, result)
    print(
        f"[V15P-MAPPED-STA-{mode.upper()}][PASS] "
        f"worst={worst:.9f}ns wns={wns:.9f}ns tns={tns:.9f}ns "
        f"violated={violated} loops={loop_count} "
        f"area={area['logic_area_proxy_excluding_unknown_macros']:.2f}"
    )


def setup_receipt(args: argparse.Namespace) -> None:
    result = {
        "schema": "npc-rv64-v15p-opensta-setup-receipt-v1",
        "status": "CAPTURED",
        "setup": parse_setup(args.input.resolve()),
        "artifact": artifact(args.input),
    }
    write_json(args.output, result)
    print(
        "[V15P-OPENSTA-SETUP][CAPTURED] "
        f"loops={result['setup']['combinational_loops']['count']}"
    )


CELL_HEAD_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+([A-Za-z_][A-Za-z0-9_$]*)\s*\(\s*$")
PORT_CONNECTION_RE = re.compile(
    r"^\s*\.([A-Za-z_][A-Za-z0-9_$]*)\((.*)\),?\s*$")


def parse_target_mapped_cells(
        path: pathlib.Path, targets: set[str]) -> dict[str, dict[str, Any]]:
    found: dict[str, dict[str, Any]] = {}
    active: dict[str, Any] | None = None
    with path.open("r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, 1):
            if active is None:
                match = CELL_HEAD_RE.fullmatch(line.rstrip("\n"))
                if match is not None and match.group(2) in targets:
                    cell_type, instance = match.groups()
                    require(instance not in found, f"duplicate mapped instance: {instance}")
                    active = {
                        "instance": instance,
                        "cell_type": cell_type,
                        "line": line_number,
                        "ports": {},
                    }
                continue
            if line.strip() == ");":
                require(bool(active["ports"]),
                        f"mapped instance has no ports: {active['instance']}")
                found[active["instance"]] = active
                active = None
                continue
            port = PORT_CONNECTION_RE.fullmatch(line.rstrip("\n"))
            require(port is not None,
                    f"unsupported mapped port syntax at {path}:{line_number}")
            pin, expression = port.groups()
            require(pin not in active["ports"],
                    f"duplicate mapped port: {active['instance']}/{pin}")
            active["ports"][pin] = expression.strip()
    require(active is None, "truncated mapped-cell instance")
    missing = sorted(targets - set(found))
    require(not missing, f"loop cells missing from mapped netlist: {missing}")
    return found


def find_loop_net_neighbors(
        path: pathlib.Path, loop_nets: set[str]) -> list[dict[str, Any]]:
    neighbors: list[dict[str, Any]] = []
    active: dict[str, Any] | None = None
    with path.open("r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, 1):
            if active is None:
                match = CELL_HEAD_RE.fullmatch(line.rstrip("\n"))
                if match is not None and match.group(1) != "module":
                    active = {
                        "cell_type": match.group(1),
                        "instance": match.group(2),
                        "line": line_number,
                        "pins": [],
                    }
                continue
            if line.strip() == ");":
                if active["pins"]:
                    neighbors.append(active)
                active = None
                continue
            port = PORT_CONNECTION_RE.fullmatch(line.rstrip("\n"))
            require(port is not None,
                    f"unsupported mapped port syntax at {path}:{line_number}")
            pin, expression = port.groups()
            expression = expression.strip()
            if expression in loop_nets:
                active["pins"].append({"pin": pin, "net": expression})
    require(active is None, "truncated mapped-cell instance during neighbor scan")
    return neighbors


def extract_liberty_cell_blocks(
        path: pathlib.Path, targets: set[str]) -> dict[str, str]:
    found: dict[str, str] = {}
    active_name: str | None = None
    active_lines: list[str] = []
    depth = 0
    heading = re.compile(r"^\s*cell\s*\(([^)]+)\)\s*\{")
    with path.open("r", encoding="utf-8") as stream:
        for line in stream:
            if active_name is None:
                match = heading.fullmatch(line.rstrip("\n"))
                if match is None or match.group(1) not in targets:
                    continue
                active_name = match.group(1)
                active_lines = [line]
                depth = line.count("{") - line.count("}")
            else:
                active_lines.append(line)
                depth += line.count("{") - line.count("}")
            if active_name is not None and depth == 0:
                require(active_name not in found,
                        f"duplicate Liberty cell: {active_name}")
                found[active_name] = "".join(active_lines)
                active_name = None
                active_lines = []
    require(active_name is None, "truncated Liberty cell block")
    missing = sorted(targets - set(found))
    require(not missing, f"loop cell types missing from Liberty: {missing}")
    return found


def extract_named_groups(text: str, group: str) -> list[tuple[str, str]]:
    heading = re.compile(rf"^\s*{re.escape(group)}\s*\(([^)]*)\)\s*\{{")
    result: list[tuple[str, str]] = []
    active_name: str | None = None
    active_lines: list[str] = []
    depth = 0
    for line in text.splitlines(keepends=True):
        if active_name is None:
            match = heading.fullmatch(line.rstrip("\n"))
            if match is None:
                continue
            active_name = match.group(1).strip()
            active_lines = [line]
            depth = line.count("{") - line.count("}")
        else:
            active_lines.append(line)
            depth += line.count("{") - line.count("}")
        if active_name is not None and depth == 0:
            result.append((active_name, "".join(active_lines)))
            active_name = None
            active_lines = []
    require(active_name is None, f"truncated Liberty {group} group")
    return result


def audit_liberty_loop_arcs(
        std_lib: pathlib.Path, cells: dict[str, dict[str, Any]],
        internal_arcs: list[dict[str, str]]) -> list[dict[str, Any]]:
    cell_types = {cell["cell_type"] for cell in cells.values()}
    blocks = extract_liberty_cell_blocks(std_lib, cell_types)
    pin_blocks: dict[str, dict[str, str]] = {}
    for cell_type, block in blocks.items():
        pins = dict(extract_named_groups(block, "pin"))
        require(bool(pins), f"Liberty cell has no signal pins: {cell_type}")
        pin_blocks[cell_type] = pins

    result: list[dict[str, Any]] = []
    for arc in internal_arcs:
        instance = arc["instance"]
        input_pin = arc["input_pin"]
        output_pin = arc["output_pin"]
        cell_type = cells[instance]["cell_type"]
        pins = pin_blocks[cell_type]
        require(input_pin in pins and output_pin in pins,
                f"Liberty loop pins missing: {cell_type} {input_pin}->{output_pin}")
        input_block = pins[input_pin]
        output_block = pins[output_pin]
        input_direction = re.search(r"^\s*direction\s*:\s*([^;]+);",
                                    input_block, re.MULTILINE)
        output_direction = re.search(r"^\s*direction\s*:\s*([^;]+);",
                                     output_block, re.MULTILINE)
        function = re.search(r'^\s*function\s*:\s*"([^"]+)";',
                             output_block, re.MULTILINE)
        require(input_direction is not None and input_direction.group(1).strip() == "input",
                f"Liberty input direction mismatch: {cell_type}/{input_pin}")
        require(output_direction is not None and output_direction.group(1).strip() == "output",
                f"Liberty output direction mismatch: {cell_type}/{output_pin}")
        require(function is not None, f"Liberty output lacks function: {cell_type}/{output_pin}")
        expression = function.group(1)
        token = rf"(?<![A-Za-z0-9_]){re.escape(input_pin)}(?![A-Za-z0-9_])"
        self_token = rf"(?<![A-Za-z0-9_]){re.escape(output_pin)}(?![A-Za-z0-9_])"
        require(re.search(token, expression) is not None,
                f"Liberty function omits loop input: {cell_type} {input_pin}->{output_pin}")
        require(re.search(self_token, expression) is None,
                f"Liberty function self-references output: {cell_type}/{output_pin}")
        matching_timing_groups = 0
        for _, timing_block in extract_named_groups(output_block, "timing"):
            related = re.search(r'^\s*related_pin\s*:\s*"?([^";]+)"?\s*;',
                                timing_block, re.MULTILINE)
            timing_type = re.search(r"^\s*timing_type\s*:\s*([^;]+);",
                                    timing_block, re.MULTILINE)
            if (related is not None and related.group(1).strip() == input_pin and
                    timing_type is not None and
                    timing_type.group(1).strip().startswith("combinational")):
                matching_timing_groups += 1
        require(matching_timing_groups > 0,
                f"Liberty combinational arc missing: {cell_type} {input_pin}->{output_pin}")
        result.append({
            "instance": instance,
            "cell_type": cell_type,
            "input_pin": input_pin,
            "output_pin": output_pin,
            "function": expression,
            "matching_timing_groups": matching_timing_groups,
        })
    return result


def parse_top40_cell_types(path: pathlib.Path, targets: set[str]) -> dict[str, str]:
    result: dict[str, str] = {}
    pattern = re.compile(
        r"\s([A-Za-z_][A-Za-z0-9_$]*)/[A-Za-z_][A-Za-z0-9_$]* "
        r"\(([A-Za-z_][A-Za-z0-9_$]*)\)\s*$")
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.search(line)
        if match is None or match.group(1) not in targets:
            continue
        instance, cell_type = match.groups()
        require(instance not in result or result[instance] == cell_type,
                f"top40 cell type changed across paths: {instance}")
        result[instance] = cell_type
    return result


def localize_combinational_loops(args: argparse.Namespace) -> None:
    setup = parse_setup(args.setup.resolve(), include_loop_blocks=True)
    blocks = setup["combinational_loops"]["blocks"]
    require(bool(blocks), "setup evidence contains no combinational loop")
    loop_instances: set[str] = set()
    normalized_blocks: list[list[str]] = []
    for block in blocks:
        require(block.count("| loop cut point") == 1,
                "loop block cut-point count mismatch")
        pins = [member for member in block if member != "| loop cut point"]
        require(len(pins) % 2 == 1 and pins[0] == pins[-1],
                "loop pin sequence does not alternate and close")
        normalized_blocks.append(pins)
        for pin in pins[:-1]:
            require("/" in pin, f"loop member lacks instance/pin form: {pin}")
            loop_instances.add(pin.rsplit("/", 1)[0])

    cells = parse_target_mapped_cells(args.netlist.resolve(), loop_instances)
    top40_types = parse_top40_cell_types(args.top40.resolve(), loop_instances)
    for instance, cell_type in top40_types.items():
        require(cells[instance]["cell_type"] == cell_type,
                f"top40/netlist cell-type mismatch: {instance}")

    block_results: list[dict[str, Any]] = []
    all_internal_arcs: list[dict[str, str]] = []
    all_loop_nets: set[str] = set()
    for pins in normalized_blocks:
        pin_records: list[dict[str, str]] = []
        for index, full_pin in enumerate(pins):
            instance, pin = full_pin.rsplit("/", 1)
            require(instance in cells and pin in cells[instance]["ports"],
                    f"loop pin absent from mapped cell: {full_pin}")
            pin_records.append({
                "role": "output" if index % 2 == 0 else "input",
                "instance": instance,
                "pin": pin,
                "cell_type": cells[instance]["cell_type"],
                "net": cells[instance]["ports"][pin],
            })
        intercell_edges: list[dict[str, str]] = []
        internal_arcs: list[dict[str, str]] = []
        for index in range(len(pin_records) - 1):
            left = pin_records[index]
            right = pin_records[index + 1]
            if index % 2 == 0:
                require(left["instance"] != right["instance"],
                        "inter-cell loop edge stays in one instance")
                require(left["net"] == right["net"],
                        f"loop edge net mismatch: {left} -> {right}")
                all_loop_nets.add(left["net"])
                intercell_edges.append({
                    "driver": f"{left['instance']}/{left['pin']}",
                    "load": f"{right['instance']}/{right['pin']}",
                    "net": left["net"],
                })
            else:
                require(left["instance"] == right["instance"],
                        "intra-cell timing arc crosses instances")
                arc = {
                    "instance": left["instance"],
                    "input_pin": left["pin"],
                    "output_pin": right["pin"],
                }
                internal_arcs.append(arc)
                all_internal_arcs.append(arc)
        block_results.append({
            "pin_sequence": pin_records,
            "intercell_edges": intercell_edges,
            "internal_arcs": internal_arcs,
        })

    liberty_arcs = audit_liberty_loop_arcs(
        args.std_lib.resolve(), cells, all_internal_arcs)
    neighbors = find_loop_net_neighbors(args.netlist.resolve(), all_loop_nets)
    net_ref_counts = {net: 0 for net in all_loop_nets}
    for neighbor in neighbors:
        for pin in neighbor["pins"]:
            net_ref_counts[pin["net"]] += 1
    require(all(count >= 2 for count in net_ref_counts.values()),
            "a loop net lacks at least one driver/load connection")

    loop_pin_names = {
        f"{record['instance']}/{record['pin']}"
        for block in block_results for record in block["pin_sequence"]
    }
    external_ports: list[dict[str, str]] = []
    for instance in sorted(cells):
        for pin, net in sorted(cells[instance]["ports"].items()):
            if f"{instance}/{pin}" not in loop_pin_names:
                external_ports.append({
                    "instance": instance,
                    "cell_type": cells[instance]["cell_type"],
                    "pin": pin,
                    "net": net,
                })

    result = {
        "schema": "npc-rv64-v15p-mapped-loop-localization-v1",
        "status": "PASS",
        "setup_summary": {
            key: value for key, value in setup.items()
            if key != "combinational_loops"
        },
        "loop_summary": {
            key: value for key, value in setup["combinational_loops"].items()
            if key != "blocks"
        },
        "target_instance_count": len(loop_instances),
        "target_cell_type_histogram": {
            cell_type: sum(cell["cell_type"] == cell_type for cell in cells.values())
            for cell_type in sorted({cell["cell_type"] for cell in cells.values()})
        },
        "top40_cell_type_coverage": {
            "covered_instances": len(top40_types),
            "total_loop_instances": len(loop_instances),
        },
        "blocks": block_results,
        "external_loop_cell_ports": external_ports,
        "loop_net_neighbors": neighbors,
        "loop_net_reference_counts": dict(sorted(net_ref_counts.items())),
        "liberty_arc_audit": {
            "status": "PASS",
            "arc_count": len(liberty_arcs),
            "arcs": liberty_arcs,
        },
        "artifacts": {
            "setup": artifact(args.setup),
            "top40": artifact(args.top40),
            "std_lib": artifact(args.std_lib),
            "ephemeral_netlist_before_cleanup": artifact(args.netlist),
        },
    }
    write_json(args.output, result)
    print(
        "[V15P-MAPPED-LOOP-LOCALIZE][PASS] "
        f"loops={len(blocks)} cells={len(loop_instances)} "
        f"nets={len(all_loop_nets)} liberty_arcs={len(liberty_arcs)}"
    )


def qualify_variant(args: argparse.Namespace) -> None:
    value = load_variant(args.input.resolve(), args.mode)
    loops = value["timing"]["combinational_loops"]
    require(loops == 0, f"{args.mode} timing graph contains {loops} combinational loop(s)")
    print(f"[V15P-MAPPED-STA-{args.mode.upper()}-GRAPH][PASS] loops=0")


def load_variant(path: pathlib.Path, expected_mode: str) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(value.get("schema") == "npc-rv64-v15p-mapped-sta-variant-v1",
            f"{expected_mode} summary schema mismatch")
    require(value.get("status") == "PASS" and value.get("mode") == expected_mode,
            f"{expected_mode} summary status/mode mismatch")
    return value


def compare(args: argparse.Namespace) -> None:
    parent = load_variant(args.parent.resolve(), "parent")
    candidate = load_variant(args.candidate.resolve(), "candidate")
    performance = json.loads(args.performance.read_text(encoding="utf-8"))
    policy = json.loads(args.policy.read_text(encoding="utf-8"))
    require(performance.get("schema") == "npc-rv64-v15p-performance-ab-result-v1"
            and performance.get("status") == "PASS",
            "performance A/B receipt is invalid")
    require(performance.get("decision") == "ADVANCE_TO_200MHZ_MAPPED_STA",
            "performance A/B did not authorize mapped STA")

    parent_sources = parent["actual_synthesis_source_sha256"]
    candidate_sources = candidate["actual_synthesis_source_sha256"]
    require(set(parent_sources) == set(candidate_sources),
            "parent/candidate synthesis source-key sets differ")
    source_diff = sorted(
        key for key in parent_sources
        if parent_sources[key] != candidate_sources[key])
    require(source_diff == [ADAPTER_KEY],
            f"mapped A/B is not a single-source experiment: {source_diff}")
    require(parent["setup_warning_closure"] == candidate["setup_warning_closure"],
            "parent/candidate constraint member closure differs")
    require(parent["netlist"]["sha256"] != candidate["netlist"]["sha256"],
            "parent/candidate mapped netlists are unexpectedly identical")

    parent_area = parent["synthesis"]["area"]["logic_area_proxy_excluding_unknown_macros"]
    candidate_area = candidate["synthesis"]["area"]["logic_area_proxy_excluding_unknown_macros"]
    parent_power = parent["power"]["total_vectorless_w"]
    candidate_power = candidate["power"]["total_vectorless_w"]
    area_ratio = candidate_area / parent_area
    power_ratio = candidate_power / parent_power if parent_power > 0.0 else None
    timing_policy = policy["timing"]
    candidate_timing = candidate["timing"]
    timing_hard_gate = (
        candidate_timing["worst_path_slack_ns"]
        >= timing_policy["minimum_worst_slack_ns_for_promotion"]
        and candidate_timing["tns_ns"] == timing_policy["required_tns_ns"]
        and candidate_timing["violated_path_count"]
        == timing_policy["maximum_violated_paths"]
        and candidate_timing["combinational_loops"]
        == timing_policy["maximum_combinational_loops"]
    )
    area_gate = area_ratio <= policy["promotion"]["maximum_area_ratio"]
    performance_gain = all(
        performance["workloads"][name]["delta_candidate_minus_parent"]["cycles"] < 0
        for name in ("coremark", "dhrystone_10000"))
    if timing_hard_gate and area_gate and performance_gain:
        decision = "PROXY_PPA_HARD_GATES_PASS_POWER_QUALIFICATION_PENDING"
    elif not timing_hard_gate:
        decision = "TIMING_HARD_GATE_FAIL_REWORK_OR_ROLLBACK"
    elif not area_gate:
        decision = "AREA_HARD_GATE_FAIL_ROLLBACK"
    else:
        decision = "PERFORMANCE_DIRECTION_FAIL_ROLLBACK"

    result = {
        "schema": "npc-rv64-v15p-mapped-sta-ab-result-v1",
        "status": "PASS",
        "mechanism": "lsu_axi_adapter_final_b_fallthrough",
        "single_mechanism_source_difference": source_diff,
        "parent": artifact(args.parent),
        "candidate": artifact(args.candidate),
        "performance": artifact(args.performance),
        "policy": artifact(args.policy),
        "delta_candidate_minus_parent": {
            "logic_area_proxy": candidate_area - parent_area,
            "logic_area_ratio": area_ratio,
            "known_standard_cells": (
                candidate["synthesis"]["area"]["known_standard_cells"]
                - parent["synthesis"]["area"]["known_standard_cells"]),
            "worst_path_slack_ns": (
                candidate_timing["worst_path_slack_ns"]
                - parent["timing"]["worst_path_slack_ns"]),
            "tns_ns": candidate_timing["tns_ns"] - parent["timing"]["tns_ns"],
            "vectorless_power_w": candidate_power - parent_power,
            "vectorless_power_ratio": power_ratio,
        },
        "hard_gates": {
            "performance_directional_gain": performance_gain,
            "candidate_200mhz_timing_margin": timing_hard_gate,
            "candidate_area_ratio": area_gate,
            "candidate_synthesis_check": True,
            "constraint_member_closure_equal": True,
        },
        "decision": decision,
        "promotion_state": (
            "PROXY_PPA_ACCEPTED_FINAL_POWER_AND_SYSTEM_SIGNOFF_PENDING"
            if timing_hard_gate and area_gate and performance_gain
            else "NOT_PROMOTABLE"
        ),
        "claim_boundary": {
            "timing": "exact 5ns ideal-clock stdcell-plus-placeholder-macro proxy",
            "area": "known standard-cell liberty area; four placeholder macro areas excluded",
            "power": "fixed-toggle vectorless comparison only; not qualified workload activity power",
            "system": "L0/L1 complete; L2/L3 and optional Ubuntu not run in this slice",
        },
    }
    write_json(args.output, result)
    print(
        "[V15P-MAPPED-STA-AB][PASS] "
        f"decision={decision} area_ratio={area_ratio:.9f} "
        f"candidate_worst={candidate_timing['worst_path_slack_ns']:.9f}ns"
    )


def verify(args: argparse.Namespace) -> None:
    value = json.loads(args.input.read_text(encoding="utf-8"))
    require(value.get("schema") == "npc-rv64-v15p-mapped-sta-ab-result-v1",
            "comparison schema mismatch")
    require(value.get("status") == "PASS", "comparison status mismatch")
    require(value.get("single_mechanism_source_difference") == [ADAPTER_KEY],
            "comparison source-difference mismatch")
    for key in ("parent", "candidate", "performance", "policy"):
        record = value[key]
        path = pathlib.Path(record["path"])
        if not path.is_absolute():
            path = ROOT / path
        require(path.is_file() and sha256(path) == record["sha256"],
                f"comparison artifact drifted: {key}")
    print(f"[V15P-MAPPED-STA-AB-VERIFY][PASS] decision={value['decision']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    variant = subparsers.add_parser("variant")
    variant.add_argument("--mode", choices=("parent", "candidate"), required=True)
    variant.add_argument("--out-dir", type=pathlib.Path, required=True)
    variant.add_argument("--netlist", type=pathlib.Path, required=True)
    variant.add_argument("--input-manifest", type=pathlib.Path, required=True)
    variant.add_argument("--parameters", type=pathlib.Path, required=True)
    variant.add_argument("--source-manifest", type=pathlib.Path, required=True)
    variant.add_argument("--synth-check", type=pathlib.Path, required=True)
    variant.add_argument("--synth-stat", type=pathlib.Path, required=True)
    variant.add_argument("--std-lib", type=pathlib.Path, required=True)
    variant.add_argument("--opensta-binary", type=pathlib.Path, required=True)
    variant.add_argument("--output", type=pathlib.Path, required=True)
    comparison = subparsers.add_parser("compare")
    comparison.add_argument("--parent", type=pathlib.Path, required=True)
    comparison.add_argument("--candidate", type=pathlib.Path, required=True)
    comparison.add_argument("--performance", type=pathlib.Path, required=True)
    comparison.add_argument("--policy", type=pathlib.Path, required=True)
    comparison.add_argument("--output", type=pathlib.Path, required=True)
    checker = subparsers.add_parser("verify")
    checker.add_argument("--input", type=pathlib.Path, required=True)
    setup_parser = subparsers.add_parser("setup")
    setup_parser.add_argument("--input", type=pathlib.Path, required=True)
    setup_parser.add_argument("--output", type=pathlib.Path, required=True)
    localizer = subparsers.add_parser("loop-localize")
    localizer.add_argument("--setup", type=pathlib.Path, required=True)
    localizer.add_argument("--top40", type=pathlib.Path, required=True)
    localizer.add_argument("--netlist", type=pathlib.Path, required=True)
    localizer.add_argument("--std-lib", type=pathlib.Path, required=True)
    localizer.add_argument("--output", type=pathlib.Path, required=True)
    qualifier = subparsers.add_parser("qualify")
    qualifier.add_argument("--input", type=pathlib.Path, required=True)
    qualifier.add_argument("--mode", choices=("parent", "candidate"), required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.command == "variant":
            parse_variant(args)
        elif args.command == "compare":
            compare(args)
        elif args.command == "verify":
            verify(args)
        elif args.command == "setup":
            setup_receipt(args)
        elif args.command == "loop-localize":
            localize_combinational_loops(args)
        else:
            qualify_variant(args)
    except (EvidenceError, OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"[V15P-MAPPED-STA][FAIL] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
