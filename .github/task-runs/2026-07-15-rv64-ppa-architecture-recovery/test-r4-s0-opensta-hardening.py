#!/usr/bin/env python3
"""R4-S0 STA 证据解析器的 fail-closed 负向自测。"""

from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import json
import tempfile
from pathlib import Path


TASK_DIR = Path(__file__).resolve().parent


def load(name: str, filename: str):
    path = TASK_DIR / filename
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CHECKER = load("r4_s0_opensta_checker", "check-r4-s0-opensta.py")
BINDING = load("r4_s0_synth_binding_test", "check-r4-s0-synth-binding.py")


def expect_reject(name: str, function, *args) -> None:
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            function(*args)
        except SystemExit:
            return
    raise SystemExit(f"{name} mutation was incorrectly accepted")


manifest = {
    "schema": "ppa-r4-s0-opensta-setup-members-v1",
    "netlist_sha256": "0" * 64,
    "setup_probe_sha256": "1" * 64,
    "classes": {
        "missing_input_delay": {
            "label": "input ports missing set_input_delay",
            "count": 2,
            "members": ["a", "b"],
        },
        "missing_output_delay": {
            "label": "output ports missing set_output_delay",
            "count": 2,
            "members": ["x", "y"],
        },
        "unconstrained_endpoints": {
            "label": "unconstrained endpoints",
            "count": 2,
            "members": ["x", "y"],
        },
    },
}


def render_setup(*, substitute: bool = False, trailing: str = "") -> str:
    lines: list[str] = []
    for key, _ in CHECKER.SETUP_KEYS:
        item = manifest["classes"][key]
        members = list(item["members"])
        if substitute and key == "missing_output_delay":
            members[0] = "forged_equal_count_member"
        lines.append(f"Warning: There are {item['count']} {item['label']}.")
        lines.extend(f"  {member}" for member in members)
    if trailing:
        lines.append(trailing)
    return "\n".join(lines) + "\n"


CHECKER.parse_setup_warning_closure(render_setup(), manifest)
expect_reject(
    "equal-count setup member substitution",
    CHECKER.parse_setup_warning_closure,
    render_setup(substitute=True),
    manifest,
)
expect_reject(
    "fourth setup warning",
    CHECKER.parse_setup_warning_closure,
    render_setup(trailing="Warning: There is 1 combinational loop."),
    manifest,
)
expect_reject(
    "trailing setup diagnostic",
    CHECKER.parse_setup_warning_closure,
    render_setup(trailing="unexpected trailing text"),
    manifest,
)


def render_timing(
    *,
    paths: int = 40,
    slack: str = "0.125000000",
    state: str = "MET",
    duplicate_slack: bool = False,
    wns: str = "0.000000000",
    tns: str = "0.000000000",
    trailing: str = "",
) -> str:
    blocks: list[str] = []
    for index in range(paths):
        lines = [
            f"Startpoint: start_{index}",
            f"Endpoint: end_{index}",
            "Path Group: core_clock",
            "Path Type: max",
            f"  {slack} slack ({state})",
        ]
        if duplicate_slack and index == 0:
            lines.append(f"  {slack} slack ({state})")
        blocks.append("\n".join(lines))
    result = "\n\n".join(blocks) + f"\n\ntns max {tns}\nwns max {wns}\n"
    if trailing:
        result += trailing + "\n"
    return result


positive = CHECKER.parse_timing_report(render_timing())
if positive["path_count"] != 40 or positive["timing_paths_met"] is not True:
    raise SystemExit("positive 40-path timing control was rejected")
negative = CHECKER.parse_timing_report(
    render_timing(
        slack="-0.100000000",
        state="VIOLATED",
        wns="-0.100000000",
        tns="-4.000000000",
    )
)
if negative["violated_path_count"] != 40 or negative["timing_paths_met"] is not False:
    raise SystemExit("negative 40-path timing control was rejected")
expect_reject("39 path blocks", CHECKER.parse_timing_report, render_timing(paths=39))
expect_reject(
    "two slack rows in one block",
    CHECKER.parse_timing_report,
    render_timing(duplicate_slack=True),
)
expect_reject(
    "slack/state mismatch",
    CHECKER.parse_timing_report,
    render_timing(
        slack="-0.100000000",
        state="MET",
        wns="-0.100000000",
        tns="-4.000000000",
    ),
)
expect_reject(
    "negative-zero path slack",
    CHECKER.parse_timing_report,
    render_timing(slack="-0.000000000"),
)
expect_reject(
    "MET with nonzero violation-only WNS",
    CHECKER.parse_timing_report,
    render_timing(wns="0.001000000"),
)
expect_reject(
    "negative TNS greater than WNS",
    CHECKER.parse_timing_report,
    render_timing(
        slack="-0.100000000",
        state="VIOLATED",
        wns="-0.100000000",
        tns="-0.050000000",
    ),
)
expect_reject(
    "trailing path diagnostic",
    CHECKER.parse_timing_report,
    render_timing(trailing="forged trailing PASS"),
)

for name, console in {
    "warning": "Warning: forged",
    "error": "Error: forged",
    "blackbox": "Creating black box for unknown module",
    "loop": "combinational loop found",
}.items():
    expect_reject(name + " console", CHECKER.require_clean_console, console, "mutation")


with tempfile.TemporaryDirectory(prefix="r4-s0-sta-hardening-") as temporary:
    root = Path(temporary)
    netlist = root / "NpcTop.netlist.v"
    netlist.write_text("module NpcTop(input clk); endmodule\n")
    netlist_sha = hashlib.sha256(netlist.read_bytes()).hexdigest()
    audit = {
        "schema": "t4q-synthesis-audit-v1",
        "top": "NpcTop",
        "top_stat_row_cardinality": 1,
        "module_count": 119,
        "netlist_bytes": netlist.stat().st_size,
        "netlist_sha256": netlist_sha,
        "area": 1000.0,
        "sequential_area": 250.0,
        "sequential_percent": 25.0,
        "sequential_percent_derived": 25.0,
        "top_stat_percent_tolerance": 0.0051,
        "abc_done": 1,
        "vsrc_count": 1,
        "provenance_head": "1" * 40,
    }
    BINDING.validate_audit(audit, netlist)
    mutated = dict(audit)
    mutated["module_count"] = 118
    expect_reject("module_count 118 binding", BINDING.validate_audit, mutated, netlist)
    mutated = dict(audit)
    mutated["netlist_sha256"] = "0" * 64
    expect_reject("forged netlist hash binding", BINDING.validate_audit, mutated, netlist)

print(
    "[R4-S0-OPENSTA-HARDENING] PASS: binding/module/hash, setup-member/fourth/trailing, "
    "40-block/one-slack/state/WNS/TNS/negative-zero/trailing, and console mutations closed"
)
