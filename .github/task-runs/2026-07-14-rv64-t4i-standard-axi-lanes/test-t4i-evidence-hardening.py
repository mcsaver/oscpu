#!/usr/bin/env python3
"""Negative mutations for target rounding and equal-count setup substitution."""

from __future__ import annotations

import importlib.util
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


GLOBAL = load("t4i_global_checker", "check-t4i-global-sta.py")
TARGET = load("t4i_target_checker", "check-t4i-target-200mhz.py")


negative_zero = {
    "violated_path_count": 1,
    "worst_path_slack_ns": -0.004,
    "wns_ns": -0.0,
    "tns_ns": -0.0,
    "setup_member_set_match": True,
    "synth_binding_match": True,
    "opensta_freeze_match": True,
    "setup_derivation_match": True,
}
if TARGET.compute_met(negative_zero):
    raise SystemExit("negative-zero VIOLATED mutation was incorrectly accepted")

positive = dict(negative_zero)
positive.update(
    {
        "violated_path_count": 0,
        "worst_path_slack_ns": 0.000000001,
        "wns_ns": 0.0,
        "tns_ns": 0.0,
    }
)
if not TARGET.compute_met(positive):
    raise SystemExit("positive exact-5ns control was incorrectly rejected")

class_order = (
    ("missing_input_delay", 303, "input ports missing set_input_delay"),
    ("missing_output_delay", 1873, "output ports missing set_output_delay"),
    ("unconstrained_endpoints", 1875, "unconstrained endpoints"),
)


def render_setup(*, mutate: bool) -> str:
    lines: list[str] = []
    for key, count, label in class_order:
        expected_class = GLOBAL.SETUP_MEMBERS["classes"][key]
        members = list(expected_class["members"])
        if mutate and key == "missing_output_delay":
            members[0] = "forged_equal_count_output_endpoint"
        lines.append(f"Warning: There are {count} {label}.")
        lines.extend(f"  {member}" for member in members)
    return "\n".join(lines) + "\n"


GLOBAL.parse_t4i_setup_warning_closure(render_setup(mutate=False))
try:
    GLOBAL.parse_t4i_setup_warning_closure(render_setup(mutate=True))
except SystemExit:
    pass
else:
    raise SystemExit("equal-count setup member substitution was incorrectly accepted")

print("[T4I-EVIDENCE-MUTATION] PASS: negative-zero and member-substitution rejected")
