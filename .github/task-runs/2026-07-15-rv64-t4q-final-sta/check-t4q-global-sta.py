#!/usr/bin/env python3
"""Harden T3L's global checker with T4Q exact-member and state closure."""

from __future__ import annotations

import importlib.util
import json
import math
import re
import sys
from pathlib import Path


TASK_RUNS = Path(__file__).resolve().parents[1]
BASE_CHECKER = TASK_RUNS / "2026-07-13-rv64-t3l-branch-target-split" / "check-t3l-global-sta.py"
SPEC = importlib.util.spec_from_file_location("t3l_global_sta_checker", BASE_CHECKER)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load base checker: {BASE_CHECKER}")
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)
ORIGINAL_READ_UNIQUE_KV = CHECKER.read_unique_kv
CUSTOM_FLAGS = (
    "--setup-manifest",
    "--synth-audit",
    "--synth-freeze-status",
    "--synth-binding",
)
CUSTOM_PATHS: dict[str, Path] = {}
SETUP_MANIFEST: dict[str, object] = {}


def fail(message: str) -> None:
    CHECKER.fail(message)


def sha256(path: Path) -> str:
    return CHECKER.sha256(path)


def require_regular(path: Path) -> None:
    CHECKER.require_regular(path)


def parse_custom_paths(argv: list[str]) -> list[str]:
    stripped = [argv[0]]
    index = 1
    while index < len(argv):
        token = argv[index]
        if token in CUSTOM_FLAGS:
            if index + 1 >= len(argv):
                fail(f"checker invocation lacks value for {token}")
            CUSTOM_PATHS[token] = Path(argv[index + 1]).resolve()
            index += 2
        else:
            stripped.append(token)
            index += 1
    missing = set(CUSTOM_FLAGS) - set(CUSTOM_PATHS)
    if missing:
        fail(f"checker invocation lacks custom flags: {sorted(missing)}")
    return stripped


def load_setup_manifest(path: Path) -> dict[str, object]:
    require_regular(path)
    try:
        manifest = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid setup member manifest: {error}")
    if manifest.get("schema") != "t4q-opensta-setup-members-v1":
        fail("setup member manifest schema drifted")
    classes = manifest.get("classes")
    expected_keys = {
        "missing_input_delay",
        "missing_output_delay",
        "unconstrained_endpoints",
    }
    if not isinstance(classes, dict) or set(classes) != expected_keys:
        fail("setup member manifest classes drifted")
    return manifest


def parse_t4q_setup_warning_closure(text: str, manifest: dict[str, object] | None = None) -> dict[str, int]:
    selected = SETUP_MANIFEST if manifest is None else manifest
    classes = selected.get("classes")
    if not isinstance(classes, dict):
        fail("setup member manifest lacks classes")
    order = (
        ("missing_input_delay", "input ports missing set_input_delay"),
        ("missing_output_delay", "output ports missing set_output_delay"),
        ("unconstrained_endpoints", "unconstrained endpoints"),
    )
    lines = text.splitlines()
    cursor = 0
    result: dict[str, int] = {}
    for key, label in order:
        expected_class = classes.get(key)
        if not isinstance(expected_class, dict):
            fail(f"malformed setup manifest class: {key}")
        expected_members = expected_class.get("members")
        expected_count = expected_class.get("count")
        if (
            expected_class.get("label") != label
            or not isinstance(expected_members, list)
            or not isinstance(expected_count, int)
            or expected_count != len(expected_members)
            or expected_members != sorted(expected_members)
            or len(expected_members) != len(set(expected_members))
        ):
            fail(f"invalid setup manifest class closure: {key}")
        if cursor >= len(lines):
            fail(f"check_setup ended before {label}")
        heading = re.fullmatch(r"Warning: There are ([1-9][0-9]*) (.+)\.", lines[cursor])
        if heading is None or (int(heading.group(1)), heading.group(2)) != (expected_count, label):
            fail(f"setup warning closure drifted at {label}: {lines[cursor]!r}")
        cursor += 1
        members = lines[cursor : cursor + expected_count]
        if len(members) != expected_count:
            fail(f"truncated setup member list: {label}")
        normalized = []
        for member in members:
            if not member.startswith("  ") or member[2:] != member[2:].strip():
                fail(f"malformed setup member: {member!r}")
            normalized.append(member[2:])
        if len(normalized) != len(set(normalized)):
            fail(f"duplicate setup member: {label}")
        if sorted(normalized) != expected_members:
            fail(f"setup member set drifted: {key}")
        cursor += expected_count
        result[key] = expected_count
    if cursor != len(lines):
        fail(f"unexpected fourth setup warning/trailing diagnostic: {lines[cursor]!r}")
    return result


def read_t4q_unique_kv(path: Path) -> dict[str, str]:
    marker = ORIGINAL_READ_UNIQUE_KV(path)
    if path.name != "opensta-current-complete.txt":
        return marker
    synth_audit = CUSTOM_PATHS["--synth-audit"]
    synth_freeze = CUSTOM_PATHS["--synth-freeze-status"]
    synth_binding = CUSTOM_PATHS["--synth-binding"]
    setup_manifest = CUSTOM_PATHS["--setup-manifest"]
    for required in (synth_audit, synth_freeze, synth_binding, setup_manifest):
        require_regular(required)
    try:
        audit = json.loads(synth_audit.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid synthesis audit: {error}")
    extras = {
        "synth_audit_summary": str(synth_audit),
        "synth_audit_summary_sha256": sha256(synth_audit),
        "synth_audit_netlist_sha256": str(audit.get("netlist_sha256", "")),
        "synth_freeze_status_sha256": sha256(synth_freeze),
        "synth_binding_sha256": sha256(synth_binding),
        "setup_members_manifest_sha256": sha256(setup_manifest),
    }
    for key, expected in extras.items():
        actual = marker.pop(key, None)
        if actual != expected:
            fail(f"completion binding {key}={actual!r}, expected={expected!r}")
    return marker


def is_negative_zero(value: float) -> bool:
    return value == 0.0 and math.copysign(1.0, value) < 0.0


def validate_path_state_closure(text: str, summary: dict[str, object]) -> tuple[int, bool]:
    states = re.findall(r"^\s*(-?\d+\.\d+)\s+slack\s+\((VIOLATED|MET)\)$", text, re.MULTILINE)
    if len(states) != 40:
        fail(f"path state cardinality={len(states)}, expected 40")
    slacks = [float(value) for value, _ in states]
    if any(is_negative_zero(value) for value in slacks):
        fail("path report contains negative-zero slack")
    violated = sum(state == "VIOLATED" for _, state in states)
    if any((state == "VIOLATED") != (value < 0.0) for (raw, state), value in zip(states, slacks, strict=True)):
        fail("path state disagrees with the signed nine-digit slack")
    worst = float(summary["worst_path_slack_ns"])
    wns = float(summary["wns_ns"])
    tns = float(summary["tns_ns"])
    if is_negative_zero(wns) or is_negative_zero(tns):
        fail("WNS/TNS contains negative zero")
    if violated == 0:
        if worst < 0.0 or wns != 0.0 or tns != 0.0:
            fail("MET path states disagree with worst slack or WNS/TNS")
        timing_met = True
    else:
        if worst >= 0.0 or wns >= 0.0 or tns >= 0.0:
            fail("VIOLATED path states disagree with worst slack or WNS/TNS")
        timing_met = False
    return violated, timing_met


def main() -> None:
    global SETUP_MANIFEST
    original_argv = sys.argv
    sys.argv = parse_custom_paths(original_argv)
    SETUP_MANIFEST = load_setup_manifest(CUSTOM_PATHS["--setup-manifest"])
    CHECKER.PREFIX = "T4Q-GLOBAL-STA"
    CHECKER.parse_setup_warning_closure = parse_t4q_setup_warning_closure
    CHECKER.read_unique_kv = read_t4q_unique_kv
    try:
        CHECKER.main()
    finally:
        sys.argv = original_argv

    out_dir = Path(sys.argv[1]).resolve()
    try:
        summary_index = sys.argv.index("--json-out") + 1
        summary_path = Path(sys.argv[summary_index]).resolve()
    except (ValueError, IndexError):
        fail("checker invocation lacks --json-out")
    summary = json.loads(summary_path.read_text())
    top = (out_dir / "opensta-current-top40.rpt").read_text()
    violated, timing_met = validate_path_state_closure(top, summary)
    summary.update({
        "violated_path_count": violated,
        "setup_member_set_match": True,
        "setup_members_manifest_sha256": sha256(CUSTOM_PATHS["--setup-manifest"]),
        "synth_pre_binding_match": True,
        "synth_binding_match": False,
        "opensta_freeze_match": False,
        "setup_probe_match": False,
        "hardening_mutations_passed": False,
        "timing_paths_met": timing_met,
        "target_200mhz_met": False,
    })
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(
        f"[T4Q-GLOBAL-STA-HARDENED] PASS: violated={violated} "
        f"worst={float(summary['worst_path_slack_ns']):.9f}ns timing_met={timing_met}"
    )


if __name__ == "__main__":
    main()
