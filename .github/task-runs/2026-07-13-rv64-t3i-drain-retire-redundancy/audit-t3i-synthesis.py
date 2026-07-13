#!/usr/bin/env python3
"""Fail-closed audit for the fresh T3I 200 MHz synthesis artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-SYNTH-AUDIT] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verilog_module_counts(path: Path) -> tuple[int, int]:
    modules = 0
    endmodules = 0
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            modules += line.startswith("module ")
            endmodules += line.startswith("endmodule")
    return modules, endmodules


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tmp_dir", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    tmp_dir = args.tmp_dir.resolve()
    build_dir = tmp_dir / "sta-build/NpcTop-200MHz"
    yosys_log = build_dir / "yosys.log"
    netlist = build_dir / "NpcTop.netlist.v"
    sim_netlist = build_dir / "NpcTop.netlist.v.sim"
    synth_check = build_dir / "synth_check.txt"
    synth_stat = build_dir / "synth_stat.txt"

    required = (yosys_log, netlist, sim_netlist, synth_check, synth_stat)
    for path in required:
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"missing or empty artifact: {path}")
    if (tmp_dir / "synth-exit-status.txt").read_text().strip() != "0":
        fail("synthesis exit status is not zero")
    freeze = (tmp_dir / "synth-input-hash-cmp.txt").read_text().splitlines()
    if freeze != ["rtl_inputs=PASS", "vsrc_tree=PASS", "flow_inputs=PASS"]:
        fail(f"input freeze mismatch: {freeze}")

    counters = {
        "abc_candidates": 0,
        "abc_empty": 0,
        "abc_results": 0,
        "abc_done": 0,
        "end_of_script": 0,
        "zero_problem_checks": 0,
        "error_lines": 0,
    }
    final_stats = ""
    with yosys_log.open(encoding="utf-8", errors="replace") as stream:
        for line in stream:
            counters["abc_candidates"] += "Extracting gate netlist of module" in line
            counters["abc_empty"] += "nothing to map" in line
            counters["abc_results"] += (
                "ABC RESULTS:" in line and "internal signals:" in line
            )
            counters["abc_done"] += "YOSYS_ABC_DONE" in line
            counters["end_of_script"] += "End of script" in line
            counters["zero_problem_checks"] += (
                "Found and reported 0 problems." in line
            )
            counters["error_lines"] += line.startswith("ERROR:")
            if "End of script. Logfile hash:" in line:
                final_stats = line.strip()

    expected = {
        "abc_candidates": 220,
        "abc_empty": 10,
        "abc_results": 210,
        "abc_done": 210,
        "end_of_script": 1,
        "zero_problem_checks": 3,
        "error_lines": 0,
    }
    if counters != expected:
        fail(f"Yosys counter mismatch: actual={counters} expected={expected}")
    if "Found and reported 0 problems." not in synth_check.read_text():
        fail("synth_check.txt is not zero-problem")

    net_modules = verilog_module_counts(netlist)
    sim_modules = verilog_module_counts(sim_netlist)
    if net_modules != (110, 110) or sim_modules != (110, 110):
        fail(f"module counts netlist={net_modules} sim={sim_modules}")

    stat_text = synth_stat.read_text()
    area_match = re.search(
        r"Chip area for top module '\\NpcTop':\s*([0-9.]+)", stat_text
    )
    sequential_match = re.search(
        r"used for sequential elements:\s*([0-9.]+)\s*\(([0-9.]+)%\)",
        stat_text,
    )
    if area_match is None or sequential_match is None:
        fail("area summary missing")
    runtime_match = re.search(r"time:\s*([0-9.]+)s.*MEM:\s*([0-9.]+) MB peak", final_stats)
    if runtime_match is None:
        fail(f"runtime/peak-memory summary missing: {final_stats!r}")

    result = {
        **counters,
        "netlist_bytes": netlist.stat().st_size,
        "netlist_sha256": file_sha256(netlist),
        "yosys_log_bytes": yosys_log.stat().st_size,
        "yosys_log_sha256": file_sha256(yosys_log),
        "module_count": net_modules[0],
        "area": float(area_match.group(1)),
        "sequential_area": float(sequential_match.group(1)),
        "sequential_percent": float(sequential_match.group(2)),
        "runtime_seconds": float(runtime_match.group(1)),
        "peak_memory_mb": float(runtime_match.group(2)),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[T3I-SYNTH-AUDIT] PASS: "
        f"netlist_sha256={result['netlist_sha256']} area={result['area']:.2f} "
        f"runtime={result['runtime_seconds']:.2f}s peak={result['peak_memory_mb']:.2f}MB"
    )


if __name__ == "__main__":
    main()
