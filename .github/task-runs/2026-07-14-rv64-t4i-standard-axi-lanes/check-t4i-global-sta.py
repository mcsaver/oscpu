#!/usr/bin/env python3
"""Run the frozen global-STA checker with T4I's exact top-level closure."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path


TASK_RUNS = Path(__file__).resolve().parents[1]
TASK_DIR = Path(__file__).resolve().parent
SETUP_MANIFEST = TASK_DIR / "t4i-setup-members.json"
CANONICAL_SYNTH_AUDIT = TASK_DIR / "evidence/synthesis/summary.json"
SYNTH_FREEZE_STATUS = (
    TASK_RUNS.parent.parent
    / "tmp/2026-07-14-rv64-t4i-standard-axi-lanes/synth-input-hash-cmp.txt"
)
BASE_CHECKER = (
    TASK_RUNS
    / "2026-07-13-rv64-t3l-branch-target-split"
    / "check-t3l-global-sta.py"
)
SPEC = importlib.util.spec_from_file_location("t3l_global_sta_checker", BASE_CHECKER)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load base checker: {BASE_CHECKER}")
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)
ORIGINAL_READ_UNIQUE_KV = CHECKER.read_unique_kv


def load_setup_manifest() -> dict[str, object]:
    if not SETUP_MANIFEST.is_file() or SETUP_MANIFEST.is_symlink():
        CHECKER.fail(f"missing or non-regular setup member manifest: {SETUP_MANIFEST}")
    try:
        manifest = json.loads(SETUP_MANIFEST.read_text())
    except json.JSONDecodeError as error:
        CHECKER.fail(f"invalid setup member manifest: {error}")
    if manifest.get("schema") != "t4i-opensta-setup-members-v1":
        CHECKER.fail("setup member manifest schema drifted")
    base = Path(str(manifest.get("base_setup", "")))
    if not base.is_absolute():
        base = TASK_RUNS.parent.parent / base
    if not base.is_file() or base.is_symlink():
        CHECKER.fail(f"invalid frozen T4D setup source: {base}")
    if manifest.get("base_setup_sha256") != CHECKER.sha256(base):
        CHECKER.fail("frozen T4D setup source hash drifted")
    return manifest


SETUP_MEMBERS = load_setup_manifest()


def parse_t4i_setup_warning_closure(text: str) -> dict[str, int]:
    """Require every setup warning class and member at the frozen T4I width."""

    expected = (
        ("missing_input_delay", 303, "input ports missing set_input_delay"),
        ("missing_output_delay", 1873, "output ports missing set_output_delay"),
        ("unconstrained_endpoints", 1875, "unconstrained endpoints"),
    )
    lines = text.splitlines()
    cursor = 0
    result: dict[str, int] = {}
    for key, expected_count, expected_label in expected:
        if cursor >= len(lines):
            CHECKER.fail(f"check_setup ended before warning class {expected_label}")
        match = re.fullmatch(r"Warning: There are (\d+) (.+)\.", lines[cursor])
        if match is None:
            CHECKER.fail(f"malformed/out-of-order setup warning: {lines[cursor]!r}")
        actual = (int(match.group(1)), match.group(2))
        if actual != (expected_count, expected_label):
            CHECKER.fail(
                f"check_setup closure drifted: actual={actual} "
                f"expected={(expected_count, expected_label)}"
            )
        cursor += 1
        members = lines[cursor : cursor + expected_count]
        if len(members) != expected_count:
            CHECKER.fail(f"truncated setup member list: {expected_label}")
        normalized: list[str] = []
        for member in members:
            if not member.startswith("  ") or member[2:] != member[2:].strip():
                CHECKER.fail(f"malformed setup member: {member!r}")
            normalized.append(member[2:])
        if len(normalized) != len(set(normalized)):
            CHECKER.fail(f"duplicate setup member: {expected_label}")
        classes = SETUP_MEMBERS.get("classes")
        if not isinstance(classes, dict) or key not in classes:
            CHECKER.fail(f"setup member manifest lacks class: {key}")
        expected_class = classes[key]
        if not isinstance(expected_class, dict):
            CHECKER.fail(f"malformed setup member class: {key}")
        if expected_class.get("label") != expected_label:
            CHECKER.fail(f"setup member label drifted in manifest: {key}")
        expected_members = expected_class.get("members")
        if not isinstance(expected_members, list) or sorted(normalized) != expected_members:
            CHECKER.fail(f"setup member set drifted: {key}")
        cursor += expected_count
        result[key] = expected_count
    if cursor != len(lines):
        CHECKER.fail(
            f"unexpected fourth setup warning/trailing diagnostic: {lines[cursor]!r}"
        )
    return result


def read_t4i_unique_kv(path: Path) -> dict[str, str]:
    marker = ORIGINAL_READ_UNIQUE_KV(path)
    if path.name != "opensta-current-complete.txt":
        return marker
    out_dir = path.parent
    synth_binding = out_dir / "synth-binding.pre.json"
    for required in (CANONICAL_SYNTH_AUDIT, SYNTH_FREEZE_STATUS, synth_binding):
        CHECKER.require_regular(required)
    try:
        audit = json.loads(CANONICAL_SYNTH_AUDIT.read_text())
    except json.JSONDecodeError as error:
        CHECKER.fail(f"invalid canonical synthesis audit: {error}")
    extras = {
        "synth_audit_summary": str(CANONICAL_SYNTH_AUDIT.resolve()),
        "synth_audit_summary_sha256": CHECKER.sha256(CANONICAL_SYNTH_AUDIT),
        "synth_audit_netlist_sha256": str(audit.get("netlist_sha256", "")),
        "synth_freeze_status_sha256": CHECKER.sha256(SYNTH_FREEZE_STATUS),
        "synth_binding_sha256": CHECKER.sha256(synth_binding),
    }
    for key, expected_value in extras.items():
        actual = marker.pop(key, None)
        if actual != expected_value:
            CHECKER.fail(
                f"completion synthesis binding {key}={actual!r}, expected={expected_value!r}"
            )
    return marker


def argument_value(name: str) -> Path:
    try:
        return Path(sys.argv[sys.argv.index(name) + 1]).resolve()
    except (ValueError, IndexError):
        CHECKER.fail(f"checker invocation lacks {name}")
        raise AssertionError("unreachable")


def main() -> None:
    CHECKER.PREFIX = "T4I-GLOBAL-STA"
    CHECKER.parse_setup_warning_closure = parse_t4i_setup_warning_closure
    CHECKER.read_unique_kv = read_t4i_unique_kv
    CHECKER.main()

    out_dir = Path(sys.argv[1]).resolve()
    summary_path = argument_value("--json-out")
    top = (out_dir / "opensta-current-top40.rpt").read_text()
    states = re.findall(
        r"^\s*-?\d+\.\d+\s+slack\s+\((VIOLATED|MET)\)$", top, re.MULTILINE
    )
    if len(states) != 40:
        CHECKER.fail(f"path state cardinality={len(states)}, expected 40")
    violated_path_count = states.count("VIOLATED")
    summary = json.loads(summary_path.read_text())
    worst = float(summary["worst_path_slack_ns"])
    wns = float(summary["wns_ns"])
    tns = float(summary["tns_ns"])
    if worst < 0.0 and abs(worst - wns) > 1.0e-8:
        CHECKER.fail(f"nine-digit worst slack {worst} disagrees with WNS {wns}")
    if violated_path_count == 0 and (worst < 0.0 or wns != 0.0 or tns != 0.0):
        CHECKER.fail("MET path states disagree with worst slack or WNS/TNS")
    if violated_path_count != 0 and worst >= 0.0:
        CHECKER.fail("VIOLATED path state has non-negative worst slack")
    timing_paths_met = (
        violated_path_count == 0 and worst >= 0.0 and wns == 0.0 and tns == 0.0
    )
    summary.update(
        {
            "violated_path_count": violated_path_count,
            "setup_member_set_match": True,
            "setup_members_manifest_sha256": CHECKER.sha256(SETUP_MANIFEST),
            "synth_pre_binding_match": True,
            "synth_binding_match": False,
            "opensta_freeze_match": False,
            "setup_derivation_match": False,
            "synth_audit_summary_sha256": CHECKER.sha256(CANONICAL_SYNTH_AUDIT),
            "synth_freeze_status_sha256": CHECKER.sha256(SYNTH_FREEZE_STATUS),
            "timing_paths_met": timing_paths_met,
            "target_200mhz_met": False,
        }
    )
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(
        f"[T4I-GLOBAL-STA-HARDENED] PASS: violated={violated_path_count} "
        f"worst={worst:.9f}ns timing_paths_met={timing_paths_met}"
    )


if __name__ == "__main__":
    main()
