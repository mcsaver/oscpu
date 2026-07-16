#!/usr/bin/env python3
"""Validate T3M focused STA with a T3L positive control."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


PREFIX = "T3M-FOCUSED-STA"


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular file: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_kv(path: Path) -> dict[str, str]:
    require_regular(path)
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed KV {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in result:
            fail(f"empty or duplicate KV key {path.name}:{number}")
        result[key] = value
    return result


def verify_report(path: Path, status: str) -> int:
    require_regular(path)
    text = path.read_text(errors="replace")
    starts = len(re.findall(r"^Startpoint:", text, re.MULTILINE))
    if status == "PATHS_PRESENT":
        if starts < 1 or "slack (" not in text:
            fail(f"expected timing paths are absent in {path.name}")
    elif status == "NO_TIMING_PATH":
        if starts != 0 or not text.startswith("status=NO_TIMING_PATH"):
            fail(f"NO_TIMING_PATH report is malformed: {path.name}")
    elif status == "PORT_ABSENT":
        if starts != 0 or not text.startswith("status=PORT_ABSENT"):
            fail(f"PORT_ABSENT report is malformed: {path.name}")
    else:
        fail(f"unsupported report status: {status}")
    return starts


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--expected-input-manifest", type=Path, required=True)
    parser.add_argument("--expected-parameters", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out_dir.resolve()
    netlist = args.expected_netlist.resolve()
    manifest = args.expected_input_manifest.resolve()
    parameters = args.expected_parameters.resolve()
    for path in (netlist, manifest, parameters):
        require_regular(path)
    paths = {
        "counts": out / "opensta-t3m-focused-counts.txt",
        "objects": out / "opensta-t3m-focused-objects.txt",
        "queries": out / "opensta-t3m-focused-queries.txt",
        "complete": out / "opensta-t3m-focused-complete.txt",
        "console": out / "opensta-console.log",
        "select": out / "opensta-t3m-select-to-ex.rpt",
        "bypass": out / "opensta-t3m-bypass-to-ex.rpt",
        "formal_iq": out / "opensta-t3m-formal-to-iq-d.rpt",
        "formal_ex": out / "opensta-t3m-formal-to-ex.rpt",
    }
    for path in paths.values():
        require_regular(path)
    console = paths["console"].read_text(errors="replace")
    if re.search(r"\b(?:warning|error)(?:\s+\d+)?\s*:", console, re.IGNORECASE):
        fail("OpenSTA console contains a Warning/Error diagnostic")
    if re.search(r"Creating black box", console, re.IGNORECASE):
        fail("OpenSTA created an unknown black box")

    counts_raw = read_kv(paths["counts"])
    expected_keys = (
        "expect",
        "iq_cells",
        "prf_cells",
        "select_wakeup_pins",
        "formal_wakeup_pins",
        "issue_output_pins",
        "prf_bypass_pins",
        "prf_write_pins",
        "prf_read_output_pins",
        "iq_d_pins",
        "ex_stage_d_pins",
    )
    if tuple(counts_raw) != expected_keys:
        fail(f"focused count key set/order drifted: {tuple(counts_raw)}")
    if counts_raw["expect"] != args.expect:
        fail("focused count expectation disagrees with checker")
    try:
        counts = {key: int(value) for key, value in counts_raw.items() if key != "expect"}
    except ValueError:
        fail("focused counts contain a non-integer")
    if counts["iq_cells"] != 1 or counts["prf_cells"] != 1:
        fail(f"IQ/PRF hierarchy cardinality drifted: {counts}")
    if counts["formal_wakeup_pins"] != 14:
        fail(f"formal wake ABI drifted: {counts['formal_wakeup_pins']}")
    if counts["prf_read_output_pins"] != 320:
        fail(f"stored PRF read ABI drifted: {counts['prf_read_output_pins']}")
    for key in ("issue_output_pins", "prf_write_pins", "iq_d_pins", "ex_stage_d_pins"):
        if counts[key] <= 0:
            fail(f"required nonempty focused collection {key}=0")
    if args.expect == "old":
        if counts["select_wakeup_pins"] != 14 or counts["prf_bypass_pins"] != 142:
            fail(f"T3L positive-control fast ABI drifted: {counts}")
        expected_query = {
            "select_to_ex": "PATHS_PRESENT",
            "bypass_to_ex": "PATHS_PRESENT",
            "formal_to_iq_d": "PATHS_PRESENT",
            "formal_to_ex": "NO_TIMING_PATH",
        }
    else:
        if counts["select_wakeup_pins"] != 0 or counts["prf_bypass_pins"] != 0:
            fail(f"T3M retired fast ABI remains: {counts}")
        expected_query = {
            "select_to_ex": "PORT_ABSENT",
            "bypass_to_ex": "PORT_ABSENT",
            "formal_to_iq_d": "PATHS_PRESENT",
            "formal_to_ex": "NO_TIMING_PATH",
        }
    queries = read_kv(paths["queries"])
    if queries != expected_query:
        fail(f"focused query result mismatch: actual={queries} expected={expected_query}")
    path_counts = {
        "select_to_ex": verify_report(paths["select"], queries["select_to_ex"]),
        "bypass_to_ex": verify_report(paths["bypass"], queries["bypass_to_ex"]),
        "formal_to_iq_d": verify_report(paths["formal_iq"], queries["formal_to_iq_d"]),
        "formal_to_ex": verify_report(paths["formal_ex"], queries["formal_to_ex"]),
    }

    complete = read_kv(paths["complete"])
    expected_complete = {
        "status": "COMPLETE",
        "expect": args.expect,
        "period_ns": "5.0",
        "top": "NpcTop",
        "netlist": str(netlist),
        "netlist_sha256": sha256(netlist),
        "input_manifest_sha256": sha256(manifest),
        "parameters_sha256": sha256(parameters),
    }
    if complete != expected_complete:
        fail(f"focused completion provenance mismatch: {complete}")
    objects = paths["objects"].read_text()
    for label, count in counts.items():
        if f"[{label}] count={count}\n" not in objects:
            fail(f"object inventory lacks exact header for {label}")

    result = {
        "expect": args.expect,
        "period_ns": 5.0,
        "netlist_sha256": sha256(netlist),
        "counts": counts,
        "queries": queries,
        "path_block_counts": path_counts,
        "barrier_proven": args.expect == "fresh",
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{PREFIX}] PASS: expect={args.expect} select={queries['select_to_ex']} "
        f"bypass={queries['bypass_to_ex']} formal_sticky={queries['formal_to_iq_d']}"
    )


if __name__ == "__main__":
    main()
