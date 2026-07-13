#!/usr/bin/env python3
"""Validate and summarize the fresh T3I exact-5ns OpenSTA reports."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-GLOBAL-STA] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out_dir
    top_path = out / "opensta-current-top40.rpt"
    setup_path = out / "opensta-current-check-setup.txt"
    power_path = out / "opensta-current-power.rpt"
    console_path = out / "opensta-console.log"
    complete_path = out / "opensta-current-complete.txt"
    for path in (top_path, setup_path, power_path, console_path, complete_path):
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"missing or empty report: {path}")

    expected_netlist = args.expected_netlist.resolve()
    marker = dict(
        line.split("=", 1) for line in complete_path.read_text().splitlines()
    )
    expected_marker = {
        "status": "COMPLETE",
        "period_ns": "5.0",
        "netlist": str(expected_netlist),
        "netlist_sha256": sha256(expected_netlist),
    }
    if marker != expected_marker:
        fail(f"bad completion provenance: actual={marker} expected={expected_marker}")

    top = top_path.read_text()
    setup = setup_path.read_text()
    power = power_path.read_text()
    console = console_path.read_text()
    path_count = len(re.findall(r"^Startpoint:", top, re.MULTILINE))
    endpoints = re.findall(r"^Endpoint:\s+([^\n]+)", top, re.MULTILINE)
    slacks = [
        float(value)
        for value in re.findall(
            r"^\s*(-?\d+\.\d+)\s+slack\s+\((?:VIOLATED|MET)\)",
            top,
            re.MULTILINE,
        )
    ]
    wns_matches = re.findall(r"^wns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    tns_matches = re.findall(r"^tns max\s+(-?\d+(?:\.\d+)?)$", top, re.MULTILINE)
    if path_count != 40 or len(endpoints) != 40 or len(slacks) != 40:
        fail(
            f"top40 cardinality paths={path_count} endpoints={len(endpoints)} "
            f"slacks={len(slacks)}"
        )
    if len(wns_matches) != 1 or len(tns_matches) != 1:
        fail(f"WNS/TNS cardinality wns={wns_matches} tns={tns_matches}")
    wns = float(wns_matches[0])
    tns = float(tns_matches[0])
    if abs(min(slacks) - wns) > 0.011:
        fail(f"worst path slack {min(slacks)} disagrees with WNS {wns}")
    if re.search(r"combinational\s+loop", console + setup, re.IGNORECASE):
        fail("OpenSTA reported a combinational loop")
    if re.search(r"^Error:", console, re.MULTILINE):
        fail("OpenSTA console contains an Error diagnostic")
    if re.search(
        r"^Warning 198:.*module .* not found\. Creating black box",
        console,
        re.MULTILINE,
    ):
        fail("OpenSTA linked an unknown module as a black box")
    if "missing set_input_delay" not in setup:
        fail("expected non-signoff IO-delay boundary is not explicit")
    power_match = re.search(
        r"^Total\s+\S+\s+\S+\s+\S+\s+(\S+)\s+100\.0%",
        power,
        re.MULTILINE,
    )
    if power_match is None:
        fail("total power row missing")
    total_power = float(power_match.group(1))

    endpoint_classes = {
        "fetch_payload_sram": sum("u_payload_sram" in item for item in endpoints),
        "pending_trap_exit": sum(
            "u_pending_trap_exit_sequencer" in item for item in endpoints
        ),
        "fetch_outstanding": sum(
            "u_fetch_pc_outstanding" in item for item in endpoints
        ),
        "csr_file": sum("u_csr_file" in item for item in endpoints),
        "other": 0,
    }
    endpoint_classes["other"] = 40 - sum(endpoint_classes.values())
    result = {
        "period_ns": 5.0,
        "path_count": path_count,
        "wns_ns": wns,
        "tns_ns": tns,
        "total_power_w": total_power,
        "combinational_loops": 0,
        "target_200mhz_met": wns >= 0.0,
        "endpoint_classes": endpoint_classes,
        "retire_port_tokens_in_top40": top.count("core_retire_count_i"),
        "drain_gate_tokens_in_top40": top.count("u_pending_drain_resolve_gate"),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[T3I-GLOBAL-STA] PASS: "
        f"loops=0 paths=40 WNS={wns:.3f}ns TNS={tns:.2f}ns "
        f"power={total_power:.3f}W target_met={result['target_200mhz_met']}"
    )


if __name__ == "__main__":
    main()
