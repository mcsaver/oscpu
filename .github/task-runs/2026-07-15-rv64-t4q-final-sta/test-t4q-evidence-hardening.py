#!/usr/bin/env python3
"""Negative mutations for T4Q timing, setup members, and top-stat parsing."""

from __future__ import annotations

import importlib.util
import contextlib
import io
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


AUDIT = load("t4q_audit", "audit-t4q-synthesis.py")
GLOBAL = load("t4q_global", "check-t4q-global-sta.py")
TARGET = load("t4q_target", "check-t4q-target-200mhz.py")


positive = {
    "violated_path_count": 0,
    "worst_path_slack_ns": 0.000000001,
    "wns_ns": 0.0,
    "tns_ns": 0.0,
    "setup_member_set_match": True,
    "synth_binding_match": True,
    "opensta_freeze_match": True,
    "setup_probe_match": True,
    "hardening_mutations_passed": True,
}
if not TARGET.compute_met(positive):
    raise SystemExit("positive exact-5ns control was incorrectly rejected")

mutations = {
    "VIOLATED": {"violated_path_count": 1, "worst_path_slack_ns": -0.1, "wns_ns": -0.1, "tns_ns": -0.1},
    "negative-worst": {"worst_path_slack_ns": -0.000000001},
    "negative-zero-wns": {"wns_ns": -0.0},
    "negative-zero-tns": {"tns_ns": -0.0},
}
for name, delta in mutations.items():
    candidate = dict(positive)
    candidate.update(delta)
    if TARGET.compute_met(candidate):
        raise SystemExit(f"{name} mutation was incorrectly accepted")

manifest = {
    "schema": "t4q-opensta-setup-members-v1",
    "classes": {
        "missing_input_delay": {
            "label": "input ports missing set_input_delay", "count": 2, "members": ["a", "b"]
        },
        "missing_output_delay": {
            "label": "output ports missing set_output_delay", "count": 2, "members": ["x", "y"]
        },
        "unconstrained_endpoints": {
            "label": "unconstrained endpoints", "count": 2, "members": ["x", "y"]
        },
    },
}


def render_setup(substitute: bool = False) -> str:
    lines: list[str] = []
    for key in ("missing_input_delay", "missing_output_delay", "unconstrained_endpoints"):
        item = manifest["classes"][key]
        members = list(item["members"])
        if substitute and key == "missing_output_delay":
            members[0] = "forged_equal_count_member"
        lines.append(f"Warning: There are {item['count']} {item['label']}.")
        lines.extend(f"  {member}" for member in members)
    return "\n".join(lines) + "\n"


GLOBAL.parse_t4q_setup_warning_closure(render_setup(), manifest)
with contextlib.redirect_stderr(io.StringIO()):
    try:
        GLOBAL.parse_t4q_setup_warning_closure(render_setup(substitute=True), manifest)
    except SystemExit:
        pass
    else:
        raise SystemExit("equal-count member substitution was incorrectly accepted")

child_first = """
   Chip area for module '\\AxiPlic': 8793.680000
     of which used for sequential elements: 2279.200000 (25.92%)
   Chip area for top module '\\NpcTop': 1000.000000
     of which used for sequential elements: 250.000000 (25.00%)
"""
top = AUDIT.parse_npc_top_stat(child_first)
if top["area"] != 1000.0 or top["sequential_area"] != 250.0:
    raise SystemExit("child-first control selected a child sequential row")


def expect_top_reject(name: str, text: str) -> None:
    try:
        AUDIT.parse_npc_top_stat(text)
    except SystemExit:
        return
    raise SystemExit(f"{name} top-stat mutation was incorrectly accepted")


top_row = """   Chip area for top module '\\NpcTop': 1000.000000
     of which used for sequential elements: 250.000000 (25.00%)
"""
expect_top_reject("missing-top", "Chip area for module '\\AxiPlic': 1.0\n")
expect_top_reject("duplicate-top", top_row + top_row)
expect_top_reject(
    "sequential-over-area",
    """   Chip area for top module '\\NpcTop': 100.000000
     of which used for sequential elements: 101.000000 (101.00%)
""",
)
expect_top_reject(
    "percent-mismatch",
    """   Chip area for top module '\\NpcTop': 100.000000
     of which used for sequential elements: 25.000000 (24.00%)
""",
)

print(
    "[T4Q-EVIDENCE-HARDENING] PASS: VIOLATED/negative/negative-zero/member-substitution/"
    "child-first/dup/missing/bounds/percent mutations closed"
)
