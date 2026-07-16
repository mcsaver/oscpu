#!/usr/bin/env python3
"""Check the OpenSTA load/slew report for the D-cache fill-control producer."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--macro-audit", required=True, type=Path)
    parser.add_argument("--json-out", required=True, type=Path)
    parser.add_argument("--max-cap-pf", type=float, default=0.05)
    parser.add_argument("--max-slew-ns", type=float, default=0.795659)
    args = parser.parse_args()

    report = args.report.read_text(encoding="utf-8")
    audit = json.loads(args.macro_audit.read_text(encoding="utf-8"))
    driver_pin = audit["driver_pin"]

    cap_match = re.search(
        r"Total capacitance:\s+([0-9.]+)(?:-([0-9.]+))?", report
    )
    load_match = re.search(r"Number of loads:\s+(\d+)", report)
    driver_count_match = re.search(r"Number of drivers:\s+(\d+)", report)
    if not cap_match or not load_match or not driver_count_match:
        raise SystemExit("incomplete report_net summary")
    cap_values = [float(cap_match.group(1))]
    if cap_match.group(2):
        cap_values.append(float(cap_match.group(2)))
    total_cap_pf_min = min(cap_values)
    total_cap_pf = max(cap_values)
    load_count = int(load_match.group(1))
    driver_count = int(driver_count_match.group(1))

    path_re = re.compile(
        rf"^\s*(\d+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+"
        rf"([0-9.]+)\s+([\^v])\s+{re.escape(driver_pin)}\s",
        flags=re.MULTILINE,
    )
    path_matches = list(path_re.finditer(report))
    if not path_matches:
        raise SystemExit(f"missing timed driver row for {driver_pin}")
    timed_rows = [
        {
            "fanout": int(match.group(1)),
            "cap_pf": float(match.group(2)),
            "slew_ns": float(match.group(3)),
            "delay_ns": float(match.group(4)),
            "transition": match.group(6),
        }
        for match in path_matches
    ]
    path_fanout = max(row["fanout"] for row in timed_rows)
    path_cap_pf = max(row["cap_pf"] for row in timed_rows)
    path_slew_ns = max(row["slew_ns"] for row in timed_rows)
    path_delay_ns = max(row["delay_ns"] for row in timed_rows)
    transitions = sorted({row["transition"] for row in timed_rows})

    forbidden = re.findall(
        r"^\s*(\S+/u_sram/(?:wdata_i\[80\]|"
        r"wmask_i\[(?:6[4-9]|[7-9][0-9]|10[0-9]|11[0-2])\]))\s+input",
        report,
        flags=re.MULTILINE,
    )
    errors: list[str] = []
    if driver_count != 1:
        errors.append(f"driver_count={driver_count}")
    if transitions != ["^", "v"]:
        errors.append(f"timed_transitions={transitions}, expected rise+fall")
    mismatched_fanout = [
        row["fanout"] for row in timed_rows if row["fanout"] != load_count
    ]
    if mismatched_fanout:
        errors.append(
            f"path_fanout={mismatched_fanout}, report_net_loads={load_count}"
        )
    cap_tolerance_pf = 1.0e-9
    out_of_range_caps = [
        row["cap_pf"]
        for row in timed_rows
        if row["cap_pf"] < total_cap_pf_min - cap_tolerance_pf
        or row["cap_pf"] > total_cap_pf + cap_tolerance_pf
    ]
    if out_of_range_caps:
        errors.append(
            "path_cap_pf outside report_net range "
            f"[{total_cap_pf_min}, {total_cap_pf}]: {out_of_range_caps}"
        )
    if forbidden:
        errors.append(f"forbidden_macro_loads={forbidden[:4]}")
    if total_cap_pf >= args.max_cap_pf:
        errors.append(f"total_cap_pf={total_cap_pf} >= {args.max_cap_pf}")
    if path_slew_ns > args.max_slew_ns:
        errors.append(f"path_slew_ns={path_slew_ns} > {args.max_slew_ns}")
    if errors:
        raise SystemExit("; ".join(errors))

    result = {
        "schema": "t4t-fill-control-opensta-v1",
        "driver_pin": driver_pin,
        "driver_count": driver_count,
        "load_count": load_count,
        "total_cap_pf_min": total_cap_pf_min,
        "total_cap_pf_max": total_cap_pf,
        "timed_row_count": len(timed_rows),
        "timed_transitions": transitions,
        "timed_rows": timed_rows,
        "path_fanout": path_fanout,
        "path_cap_pf": path_cap_pf,
        "path_slew_ns": path_slew_ns,
        "path_delay_ns": path_delay_ns,
        "max_cap_pf": args.max_cap_pf,
        "max_slew_ns": args.max_slew_ns,
        "forbidden_macro_loads": forbidden,
    }
    args.json_out.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[T4T-FILL-CONTROL-LOAD] PASS "
        f"loads={load_count} cap={total_cap_pf:.6f}pF "
        f"slew={path_slew_ns:.6f}ns delay={path_delay_ns:.6f}ns"
    )


if __name__ == "__main__":
    main()
