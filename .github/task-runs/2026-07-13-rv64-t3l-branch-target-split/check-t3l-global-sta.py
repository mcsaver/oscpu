#!/usr/bin/env python3
"""Validate and summarize fresh T3L exact-5ns global OpenSTA evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path


PREFIX = "T3L-GLOBAL-STA"


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
            fail(f"malformed completion line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in result:
            fail(f"duplicate/empty completion key: {key!r}")
        result[key] = value
    return result


def require_clean_console(text: str) -> None:
    if re.search(r"\b(?:warning|error)(?:\s+\d+)?\s*:", text, re.IGNORECASE):
        fail("OpenSTA console contains a Warning/Error diagnostic")
    if re.search(r"Creating black box", text, re.IGNORECASE):
        fail("OpenSTA linked an unknown module as a black box")


def parse_setup_warning_closure(text: str) -> dict[str, int]:
    expected = (
        ("missing_input_delay", 303, "input ports missing set_input_delay"),
        ("missing_output_delay", 1861, "output ports missing set_output_delay"),
        ("unconstrained_endpoints", 1863, "unconstrained endpoints"),
    )
    lines = text.splitlines()
    cursor = 0
    result: dict[str, int] = {}
    for key, expected_count, expected_label in expected:
        if cursor >= len(lines):
            fail(f"check_setup ended before warning class {expected_label}")
        match = re.fullmatch(r"Warning: There are (\d+) (.+)\.", lines[cursor])
        if match is None:
            fail(f"malformed/out-of-order setup warning: {lines[cursor]!r}")
        actual = (int(match.group(1)), match.group(2))
        if actual != (expected_count, expected_label):
            fail(
                f"check_setup closure drifted: actual={actual} "
                f"expected={(expected_count, expected_label)}"
            )
        cursor += 1
        members = lines[cursor : cursor + expected_count]
        if len(members) != expected_count:
            fail(f"truncated setup member list: {expected_label}")
        normalized: list[str] = []
        for member in members:
            if not member.startswith("  ") or member[2:] != member[2:].strip():
                fail(f"malformed setup member: {member!r}")
            normalized.append(member[2:])
        if len(normalized) != len(set(normalized)):
            fail(f"duplicate setup member: {expected_label}")
        cursor += expected_count
        result[key] = expected_count
    if cursor != len(lines):
        fail(f"unexpected fourth setup warning/trailing diagnostic: {lines[cursor]!r}")
    return result


def split_path_blocks(text: str) -> list[str]:
    starts = [match.start() for match in re.finditer(r"^Startpoint:", text, re.MULTILINE)]
    if not starts or text[: starts[0]].strip():
        fail("top40 report lacks a clean first path block")
    blocks = [
        text[start : starts[index + 1] if index + 1 < len(starts) else len(text)]
        for index, start in enumerate(starts)
    ]
    slack_pattern = re.compile(
        r"^\s*(-?\d+\.\d+)\s+slack\s+\((?:VIOLATED|MET)\)$", re.MULTILINE
    )
    for index, block in enumerate(blocks, start=1):
        for label in ("Startpoint:", "Endpoint:", "Path Group:", "Path Type:"):
            if len(re.findall(rf"^{re.escape(label)}", block, re.MULTILINE)) != 1:
                fail(f"bad {label} cardinality in top40 block {index}")
        if len(slack_pattern.findall(block)) != 1:
            fail(f"bad slack cardinality in top40 block {index}")
    return blocks


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--expected-std-lib", type=Path, required=True)
    parser.add_argument("--expected-opensta-binary", type=Path, required=True)
    parser.add_argument("--expected-input-manifest", type=Path, required=True)
    parser.add_argument("--expected-parameters", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out_dir.resolve()
    report_paths = {
        "top": out / "opensta-current-top40.rpt",
        "setup": out / "opensta-current-check-setup.txt",
        "power": out / "opensta-current-power.rpt",
        "console": out / "opensta-console.log",
        "complete": out / "opensta-current-complete.txt",
    }
    for path in report_paths.values():
        require_regular(path)
    expected_netlist = args.expected_netlist.resolve()
    expected_std_lib = args.expected_std_lib.resolve()
    expected_opensta = args.expected_opensta_binary.resolve()
    expected_manifest = args.expected_input_manifest.resolve()
    expected_parameters = args.expected_parameters.resolve()
    for path in (
        expected_netlist,
        expected_std_lib,
        expected_opensta,
        expected_manifest,
        expected_parameters,
    ):
        require_regular(path)

    marker = read_unique_kv(report_paths["complete"])
    expected_marker = {
        "status": "COMPLETE",
        "period_ns": "5.0",
        "top": "NpcTop",
        "clock_port": "clk",
        "clock_name": "core_clock",
        "netlist": str(expected_netlist),
        "netlist_sha256": sha256(expected_netlist),
        "std_lib": str(expected_std_lib),
        "std_lib_sha256": sha256(expected_std_lib),
        "macro_lib_count": "4",
        "input_manifest_sha256": sha256(expected_manifest),
        "parameters_sha256": sha256(expected_parameters),
        "opensta_binary": str(expected_opensta),
        "opensta_binary_sha256": sha256(expected_opensta),
    }
    if marker != expected_marker:
        fail(f"completion provenance mismatch: actual={marker} expected={expected_marker}")

    top = report_paths["top"].read_text()
    setup = report_paths["setup"].read_text()
    power = report_paths["power"].read_text()
    console = report_paths["console"].read_text(errors="replace")
    require_clean_console(console)
    setup_counts = parse_setup_warning_closure(setup)
    blocks = split_path_blocks(top)
    if len(blocks) != 40:
        fail(f"top40 path block cardinality is {len(blocks)}, expected 40")
    endpoints = re.findall(r"^Endpoint:\s+([^\n]+)", top, re.MULTILINE)
    slacks = [
        float(value)
        for value in re.findall(
            r"^\s*(-?\d+\.\d+)\s+slack\s+\((?:VIOLATED|MET)\)",
            top,
            re.MULTILINE,
        )
    ]
    if len(endpoints) != 40 or len(slacks) != 40:
        fail(f"top40 cardinality endpoints={len(endpoints)} slacks={len(slacks)}")
    wns_matches = re.findall(r"^wns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    tns_matches = re.findall(r"^tns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    if len(wns_matches) != 1 or len(tns_matches) != 1:
        fail(f"WNS/TNS cardinality wns={wns_matches} tns={tns_matches}")
    wns = float(wns_matches[0])
    tns = float(tns_matches[0])
    if not math.isfinite(wns) or not math.isfinite(tns):
        fail("WNS/TNS is not finite")
    worst_path_slack = min(slacks)
    # OpenSTA report_wns is violation-only: it reports zero once every path is
    # met, while report_checks still exposes the smallest positive path slack.
    # Compare numeric values only in the violated case; in the met case require
    # the clipped WNS to be exactly zero and retain the positive margin below.
    if worst_path_slack < 0.0:
        if abs(worst_path_slack - wns) > 0.011:
            fail(f"worst path slack {worst_path_slack} disagrees with WNS {wns}")
    elif abs(wns) > 1.0e-12:
        fail(f"all top paths are met but violation-only WNS is {wns}, expected 0")
    if re.search(r"combinational\s+loop", console + setup + top, re.IGNORECASE):
        fail("OpenSTA reported a combinational loop")
    power_match = re.search(
        r"^Total\s+\S+\s+\S+\s+\S+\s+(\S+)\s+100\.0%",
        power,
        re.MULTILINE,
    )
    if power_match is None:
        fail("total power row missing")
    total_power = float(power_match.group(1))
    if not math.isfinite(total_power) or total_power < 0.0:
        fail(f"invalid total power: {total_power}")

    endpoint_classes = {
        "fetch_pc_outstanding": sum(
            "u_fetch_pc_outstanding" in endpoint for endpoint in endpoints
        ),
        "fetch_packet_fifo": sum(
            "u_fetch_packet_fifo" in endpoint for endpoint in endpoints
        ),
        "pending_trap_exit": sum(
            "u_pending_trap_exit_sequencer" in endpoint for endpoint in endpoints
        ),
        "other": 0,
    }
    endpoint_classes["other"] = 40 - sum(endpoint_classes.values())
    target_met = wns >= 0.0 and tns >= 0.0
    result = {
        "period_ns": 5.0,
        "path_count": 40,
        "wns_ns": wns,
        "tns_ns": tns,
        "worst_path_slack_ns": worst_path_slack,
        "total_power_w": total_power,
        "combinational_loops": 0,
        "target_200mhz_met": target_met,
        "setup_warning_counts": setup_counts,
        "endpoint_classes": endpoint_classes,
        "fetch_branch_target_tokens_in_top40": top.count("u_fetch_dec")
        + top.count("branch_target"),
        "fetch_packet_decode_tokens_in_top40": top.count("u_fetch_packet_decode"),
        "bimm_tokens_in_top40": top.count("bimm"),
        "fetch_bridge_tokens_in_top40": top.count("u_ooo_fetch_bridge"),
        "fetch_pc_outstanding_path_blocks": sum(
            "u_fetch_pc_outstanding" in block for block in blocks
        ),
        "fetch_packet_fifo_path_blocks": sum(
            "u_fetch_packet_fifo" in block for block in blocks
        ),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{PREFIX}] PASS: loops=0 paths=40 WNS={wns:.3f}ns "
        f"TNS={tns:.2f}ns power={total_power:.3f}W target_met={target_met}"
    )


if __name__ == "__main__":
    main()
