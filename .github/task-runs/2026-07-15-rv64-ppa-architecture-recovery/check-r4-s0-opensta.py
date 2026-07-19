#!/usr/bin/env python3
"""Fail-closed 检查 R4-S0 exact-5ns OpenSTA 证据并生成 schema v2。"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import re
import sys
from pathlib import Path


PREFIX = "R4-S0-OPENSTA-CHECK"
TASK_DIR = Path(__file__).resolve().parent
BINDING_PATH = TASK_DIR / "check-r4-s0-synth-binding.py"
BINDING_SPEC = importlib.util.spec_from_file_location("r4_s0_synth_binding", BINDING_PATH)
if BINDING_SPEC is None or BINDING_SPEC.loader is None:
    raise SystemExit(f"[{PREFIX}] FAIL: cannot import {BINDING_PATH}")
BINDING = importlib.util.module_from_spec(BINDING_SPEC)
BINDING_SPEC.loader.exec_module(BINDING)

SETUP_KEYS = (
    ("missing_input_delay", "input ports missing set_input_delay"),
    ("missing_output_delay", "output ports missing set_output_delay"),
    ("unconstrained_endpoints", "unconstrained endpoints"),
)
LOCAL_INPUTS = (
    "run-ppa-r4-s0-opensta.sh",
    "check-r4-s0-synth-binding.py",
    "derive-r4-s0-setup-members.py",
    "check-r4-s0-opensta.py",
    "test-r4-s0-opensta-hardening.py",
    "opensta-r4-s0-setup-probe.tcl",
    "opensta-r4-s0-exact5ns.tcl",
    "r4-s0-opensta-hardening.md",
)


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


def read_unique_kv(path: Path) -> dict[str, str]:
    require_regular(path)
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed key/value line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or not value or key in result:
            fail(f"duplicate/empty key/value in {path.name}: {line!r}")
        result[key] = value
    return result


def require_exact_status(path: Path, expected: tuple[str, ...]) -> None:
    require_regular(path)
    if tuple(path.read_text().splitlines()) != expected:
        fail(f"status closure drifted: {path}")


def require_clean_console(text: str, label: str = "OpenSTA") -> None:
    if re.search(r"\b(?:warning|error)(?:\s+\d+)?\s*:", text, re.IGNORECASE):
        fail(f"{label} console contains a Warning/Error diagnostic")
    if re.search(r"Creating black box", text, re.IGNORECASE):
        fail(f"{label} linked an unknown module as a black box")
    if re.search(r"combinational\s+loop", text, re.IGNORECASE):
        fail(f"{label} reported a combinational loop")


def load_setup_manifest(path: Path) -> dict[str, object]:
    require_regular(path)
    try:
        manifest = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid setup member manifest: {error}")
    if not isinstance(manifest, dict):
        fail("setup member manifest root is not an object")
    if manifest.get("schema") != "ppa-r4-s0-opensta-setup-members-v1":
        fail("setup member manifest schema drifted")
    if manifest.get("netlist_sha256") is None or manifest.get("setup_probe_sha256") is None:
        fail("setup member manifest lacks frozen input hashes")
    classes = manifest.get("classes")
    if not isinstance(classes, dict) or set(classes) != {key for key, _ in SETUP_KEYS}:
        fail("setup member manifest classes drifted")
    for key, label in SETUP_KEYS:
        item = classes.get(key)
        if not isinstance(item, dict) or set(item) != {"label", "count", "members"}:
            fail(f"malformed setup manifest class: {key}")
        members = item.get("members")
        count = item.get("count")
        if (
            item.get("label") != label
            or not isinstance(count, int)
            or count <= 0
            or not isinstance(members, list)
            or count != len(members)
            or members != sorted(members)
            or len(members) != len(set(members))
            or any(not isinstance(member, str) or not member for member in members)
        ):
            fail(f"invalid setup member class closure: {key}")
    return manifest


def normalized_setup_manifest(manifest: dict[str, object]) -> dict[str, object]:
    normalized = dict(manifest)
    # pre/post probe 路径不同是预期的；其字节 SHA、网表和完整成员集合必须相同。
    normalized.pop("setup_probe", None)
    return normalized


def parse_setup_warning_closure(
    text: str, manifest: dict[str, object]
) -> dict[str, int]:
    classes = manifest["classes"]
    assert isinstance(classes, dict)
    lines = text.splitlines()
    cursor = 0
    result: dict[str, int] = {}
    for key, label in SETUP_KEYS:
        item = classes[key]
        assert isinstance(item, dict)
        expected_count = item["count"]
        expected_members = item["members"]
        assert isinstance(expected_count, int) and isinstance(expected_members, list)
        if cursor >= len(lines):
            fail(f"check_setup ended before {label}")
        heading = re.fullmatch(r"Warning: There are ([1-9][0-9]*) (.+)\.", lines[cursor])
        if heading is None or (int(heading.group(1)), heading.group(2)) != (
            expected_count,
            label,
        ):
            fail(f"setup warning closure drifted at {label}: {lines[cursor]!r}")
        cursor += 1
        raw_members = lines[cursor : cursor + expected_count]
        if len(raw_members) != expected_count:
            fail(f"truncated setup member list: {label}")
        members: list[str] = []
        for member in raw_members:
            if not member.startswith("  ") or member[2:] != member[2:].strip():
                fail(f"malformed setup member: {member!r}")
            members.append(member[2:])
        if len(members) != len(set(members)):
            fail(f"duplicate setup member: {label}")
        if sorted(members) != expected_members:
            fail(f"setup member set drifted: {key}")
        cursor += expected_count
        result[key] = expected_count
    if cursor != len(lines):
        fail(f"unexpected fourth setup warning/trailing diagnostic: {lines[cursor]!r}")
    return result


SLACK_PATTERN = re.compile(
    r"^\s*(-?\d+\.\d{9})\s+slack\s+\((VIOLATED|MET)\)\s*$", re.MULTILINE
)


def split_path_blocks(text: str) -> list[str]:
    starts = [match.start() for match in re.finditer(r"^Startpoint:", text, re.MULTILINE)]
    if not starts or text[: starts[0]].strip():
        fail("top40 report lacks a clean first path block")
    blocks = [
        text[start : starts[index + 1] if index + 1 < len(starts) else len(text)]
        for index, start in enumerate(starts)
    ]
    if len(blocks) != 40:
        fail(f"top40 path block cardinality={len(blocks)}, expected 40")
    for index, block in enumerate(blocks, start=1):
        for label in ("Startpoint:", "Endpoint:", "Path Group:", "Path Type:"):
            if len(re.findall(rf"^{re.escape(label)}", block, re.MULTILINE)) != 1:
                fail(f"bad {label} cardinality in top40 block {index}")
        if len(SLACK_PATTERN.findall(block)) != 1:
            fail(f"bad slack cardinality in top40 block {index}")
    return blocks


def is_negative_zero(value: float) -> bool:
    return value == 0.0 and math.copysign(1.0, value) < 0.0


def parse_timing_report(text: str) -> dict[str, object]:
    blocks = split_path_blocks(text)
    states = SLACK_PATTERN.findall(text)
    if len(states) != 40:
        fail(f"path slack/state cardinality={len(states)}, expected 40")
    values = [float(raw) for raw, _ in states]
    if any(not math.isfinite(value) or is_negative_zero(value) for value in values):
        fail("path report contains non-finite or negative-zero slack")
    for (raw, state), value in zip(states, values, strict=True):
        if (state == "VIOLATED") != (value < 0.0):
            fail(f"path state disagrees with signed slack: {raw} ({state})")

    wns_matches = re.findall(r"^wns max (-?\d+\.\d{9})$", text, re.MULTILINE)
    tns_matches = re.findall(r"^tns max (-?\d+\.\d{9})$", text, re.MULTILINE)
    if len(wns_matches) != 1 or len(tns_matches) != 1:
        fail(f"WNS/TNS cardinality drifted: wns={wns_matches} tns={tns_matches}")
    if not text.rstrip().endswith(f"wns max {wns_matches[0]}"):
        fail("top40 report contains trailing text after the unique WNS line")
    wns = float(wns_matches[0])
    tns = float(tns_matches[0])
    if any(not math.isfinite(value) or is_negative_zero(value) for value in (wns, tns)):
        fail("WNS/TNS contains non-finite or negative-zero value")
    violated = sum(state == "VIOLATED" for _, state in states)
    worst = min(values)
    if violated == 0:
        if worst < 0.0 or wns != 0.0 or tns != 0.0:
            fail("MET states disagree with worst slack or violation-only WNS/TNS")
        timing_met = True
    else:
        if worst >= 0.0 or wns >= 0.0 or tns >= 0.0:
            fail("VIOLATED states disagree with worst slack or WNS/TNS")
        if abs(worst - wns) > 1.0e-9:
            fail(f"worst path slack {worst} disagrees with WNS {wns}")
        if tns > wns + 1.0e-9:
            fail(f"negative TNS {tns} cannot be greater than WNS {wns}")
        timing_met = False
    return {
        "blocks": blocks,
        "path_count": len(blocks),
        "violated_path_count": violated,
        "worst_path_slack_ns": worst,
        "wns_ns": wns,
        "tns_ns": tns,
        "timing_paths_met": timing_met,
    }


def parse_sha_manifest(path: Path) -> dict[Path, str]:
    require_regular(path)
    result: dict[Path, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if match is None:
            fail(f"malformed SHA manifest line {path.name}:{number}")
        member = Path(match.group(2)).resolve()
        if member in result:
            fail(f"duplicate SHA manifest member: {member}")
        require_regular(member)
        if sha256(member) != match.group(1):
            fail(f"SHA manifest member drifted: {member}")
        result[member] = match.group(1)
    return result


def load_macro_manifest(path: Path) -> list[Path]:
    members = parse_sha_manifest(path)
    if len(members) != 4:
        fail(f"macro liberty manifest cardinality={len(members)}, expected 4")
    return list(members)


def validate_binding(
    path: Path,
    audit: Path,
    netlist: Path,
    synth_freeze: Path,
    synth_exit: Path,
) -> dict[str, object]:
    require_regular(path)
    try:
        actual = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        fail(f"invalid synthesis binding JSON: {error}")
    expected = BINDING.build_binding(audit, netlist, synth_freeze, synth_exit)
    if actual != expected:
        fail("synthesis binding content disagrees with an independent recomputation")
    return actual


def parse_power(text: str) -> float:
    match = re.search(
        r"^Total\s+\S+\s+\S+\s+\S+\s+(\S+)\s+100\.0%$",
        text,
        re.MULTILINE,
    )
    if match is None:
        fail("OpenSTA total power row is missing")
    try:
        total = float(match.group(1))
    except ValueError:
        fail("OpenSTA total power field is not numeric")
    if not math.isfinite(total) or total < 0.0:
        fail(f"invalid OpenSTA total power: {total}")
    return total


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--run-id", choices=("run1", "run2"), required=True)
    parser.add_argument("--expected-target", choices=("any", "met", "miss"), required=True)
    parser.add_argument("--expected-netlist", type=Path, required=True)
    parser.add_argument("--expected-std-lib", type=Path, required=True)
    parser.add_argument("--expected-macro-manifest", type=Path, required=True)
    parser.add_argument("--expected-opensta-binary", type=Path, required=True)
    parser.add_argument("--expected-input-manifest-pre", type=Path, required=True)
    parser.add_argument("--expected-input-manifest-post", type=Path, required=True)
    parser.add_argument("--expected-parameters-pre", type=Path, required=True)
    parser.add_argument("--expected-parameters-post", type=Path, required=True)
    parser.add_argument("--expected-tool-version-pre", type=Path, required=True)
    parser.add_argument("--expected-tool-version-post", type=Path, required=True)
    parser.add_argument("--synth-audit", type=Path, required=True)
    parser.add_argument("--synth-freeze-status", type=Path, required=True)
    parser.add_argument("--synth-exit-status", type=Path, required=True)
    parser.add_argument("--synth-binding-pre", type=Path, required=True)
    parser.add_argument("--synth-binding-post", type=Path, required=True)
    parser.add_argument("--setup-probe-pre", type=Path, required=True)
    parser.add_argument("--setup-probe-post", type=Path, required=True)
    parser.add_argument("--setup-manifest-pre", type=Path, required=True)
    parser.add_argument("--setup-manifest-post", type=Path, required=True)
    parser.add_argument("--setup-probe-console-pre", type=Path, required=True)
    parser.add_argument("--setup-probe-console-post", type=Path, required=True)
    parser.add_argument("--setup-probe-exit-pre", type=Path, required=True)
    parser.add_argument("--setup-probe-exit-post", type=Path, required=True)
    parser.add_argument("--opensta-exit-status", type=Path, required=True)
    parser.add_argument("--hardening-status", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()

    out = args.out_dir.resolve()
    reports = {
        "top": out / "opensta-current-top40.rpt",
        "setup": out / "opensta-current-check-setup.txt",
        "power": out / "opensta-current-power.rpt",
        "console": out / "opensta-console.log",
        "complete": out / "opensta-current-complete.txt",
    }
    path_args = [
        value.resolve()
        for key, value in vars(args).items()
        if isinstance(value, Path) and key not in {"out_dir", "json_out"}
    ]
    for path in [*reports.values(), *path_args]:
        require_regular(path)
    if args.json_out.exists():
        fail(f"refusing existing summary: {args.json_out}")

    netlist = args.expected_netlist.resolve()
    std_lib = args.expected_std_lib.resolve()
    opensta = args.expected_opensta_binary.resolve()
    synth_audit = args.synth_audit.resolve()
    synth_freeze = args.synth_freeze_status.resolve()
    synth_exit = args.synth_exit_status.resolve()
    macro_manifest = args.expected_macro_manifest.resolve()
    macro_libs = load_macro_manifest(macro_manifest)

    require_exact_status(args.setup_probe_exit_pre, ("0",))
    require_exact_status(args.setup_probe_exit_post, ("0",))
    require_exact_status(args.opensta_exit_status, ("0",))
    require_exact_status(args.hardening_status, ("mutations=PASS",))
    BINDING.validate_audit(json.loads(synth_audit.read_text()), netlist)
    binding_pre = validate_binding(
        args.synth_binding_pre.resolve(), synth_audit, netlist, synth_freeze, synth_exit
    )
    binding_post = validate_binding(
        args.synth_binding_post.resolve(), synth_audit, netlist, synth_freeze, synth_exit
    )
    if binding_pre != binding_post:
        fail("pre/post synthesis bindings differ")

    probe_pre = args.setup_probe_pre.resolve()
    probe_post = args.setup_probe_post.resolve()
    if probe_pre.read_bytes() != probe_post.read_bytes():
        fail("pre/post independent setup probes differ")
    setup_pre = load_setup_manifest(args.setup_manifest_pre.resolve())
    setup_post = load_setup_manifest(args.setup_manifest_post.resolve())
    if normalized_setup_manifest(setup_pre) != normalized_setup_manifest(setup_post):
        fail("pre/post setup member manifests differ semantically")
    if setup_pre.get("netlist_sha256") != sha256(netlist):
        fail("setup member manifest is not bound to the live netlist")
    if setup_pre.get("setup_probe_sha256") != sha256(probe_pre):
        fail("setup member manifest is not bound to the pre probe")
    if setup_post.get("setup_probe_sha256") != sha256(probe_post):
        fail("setup member manifest is not bound to the post probe")

    probe_console_pre = args.setup_probe_console_pre.read_text(errors="replace")
    probe_console_post = args.setup_probe_console_post.read_text(errors="replace")
    main_console = reports["console"].read_text(errors="replace")
    require_clean_console(probe_console_pre, "pre probe")
    require_clean_console(probe_console_post, "post probe")
    require_clean_console(main_console, "main STA")

    manifest_pre = args.expected_input_manifest_pre.resolve()
    manifest_post = args.expected_input_manifest_post.resolve()
    if manifest_pre.read_bytes() != manifest_post.read_bytes():
        fail("pre/post OpenSTA input manifests differ")
    frozen_inputs = parse_sha_manifest(manifest_pre)
    required_frozen = {
        netlist,
        std_lib,
        opensta,
        synth_audit,
        synth_freeze,
        synth_exit,
        macro_manifest,
        args.synth_binding_pre.resolve(),
        probe_pre,
        args.setup_manifest_pre.resolve(),
        args.hardening_status.resolve(),
        *(TASK_DIR / name for name in LOCAL_INPUTS),
        *macro_libs,
    }
    missing_frozen = required_frozen - set(frozen_inputs)
    if missing_frozen:
        fail(f"OpenSTA input manifest omits required inputs: {sorted(map(str, missing_frozen))}")

    parameters_pre = args.expected_parameters_pre.resolve()
    parameters_post = args.expected_parameters_post.resolve()
    if parameters_pre.read_bytes() != parameters_post.read_bytes():
        fail("pre/post OpenSTA parameter files differ")
    expected_parameters = {
        "period_ns": "5.0",
        "top": "NpcTop",
        "clock_port": "clk",
        "clock_name": "core_clock",
        "run_id": args.run_id,
        "target_expect": args.expected_target,
        "claim_tier": "rtl_proxy_partial_constraints",
        "netlist": str(netlist),
        "std_lib": str(std_lib),
        "macro_libs": ":".join(str(path) for path in macro_libs),
        "opensta_binary": str(opensta),
        "setup_manifest_sha256": sha256(args.setup_manifest_pre.resolve()),
        "synth_binding_sha256": sha256(args.synth_binding_pre.resolve()),
    }
    if read_unique_kv(parameters_pre) != expected_parameters:
        fail("OpenSTA parameter closure disagrees with the requested run")
    version_pre = args.expected_tool_version_pre.resolve()
    version_post = args.expected_tool_version_post.resolve()
    if version_pre.read_bytes() != version_post.read_bytes():
        fail("pre/post OpenSTA tool versions differ")

    marker = read_unique_kv(reports["complete"])
    expected_marker = {
        "status": "COMPLETE",
        "schema": "ppa-r4-s0-opensta-completion-v2",
        "run_id": args.run_id,
        "period_ns": "5.0",
        "top": "NpcTop",
        "clock_port": "clk",
        "clock_name": "core_clock",
        "netlist": str(netlist),
        "netlist_sha256": sha256(netlist),
        "std_lib": str(std_lib),
        "std_lib_sha256": sha256(std_lib),
        "macro_lib_count": "4",
        "macro_manifest_sha256": sha256(macro_manifest),
        "input_manifest_sha256": sha256(manifest_pre),
        "parameters_sha256": sha256(parameters_pre),
        "opensta_binary": str(opensta),
        "opensta_binary_sha256": sha256(opensta),
        "synth_audit_summary": str(synth_audit),
        "synth_audit_summary_sha256": sha256(synth_audit),
        "synth_audit_netlist_sha256": sha256(netlist),
        "synth_freeze_status_sha256": sha256(synth_freeze),
        "synth_exit_status_sha256": sha256(synth_exit),
        "synth_binding_sha256": sha256(args.synth_binding_pre.resolve()),
        "setup_members_manifest_sha256": sha256(args.setup_manifest_pre.resolve()),
    }
    if marker != expected_marker:
        fail(f"completion provenance mismatch: actual={marker} expected={expected_marker}")

    setup_text = reports["setup"].read_text()
    top_text = reports["top"].read_text()
    power_text = reports["power"].read_text()
    require_clean_console(top_text, "top40 report")
    require_clean_console(power_text, "power report")
    setup_counts = parse_setup_warning_closure(setup_text, setup_pre)
    timing = parse_timing_report(top_text)
    loop_diagnostics = re.findall(
        r"combinational\s+loop",
        probe_console_pre + probe_console_post + main_console + setup_text + top_text,
        re.IGNORECASE,
    )
    if loop_diagnostics:
        fail("OpenSTA reports contain a combinational-loop diagnostic")
    total_power = parse_power(power_text)
    timing_met = bool(timing["timing_paths_met"])
    reserve_threshold = 0.10
    reserve_met = timing_met and float(timing["worst_path_slack_ns"]) >= reserve_threshold

    result = {
        "schema": "ppa-r4-s0-opensta-exact5ns-v2",
        "run_id": args.run_id,
        "claim_tier": "rtl_proxy_partial_constraints",
        "period_ns": 5.0,
        "path_count": timing["path_count"],
        "violated_path_count": timing["violated_path_count"],
        "worst_path_slack_ns": timing["worst_path_slack_ns"],
        "wns_ns": timing["wns_ns"],
        "tns_ns": timing["tns_ns"],
        "combinational_loops": len(loop_diagnostics),
        "timing_paths_met": timing_met,
        "target_200mhz_met": timing_met,
        "reserve_threshold_ns": reserve_threshold,
        "reserve_met": reserve_met,
        "setup_warning_counts": setup_counts,
        "synthesis_binding_match": True,
        "setup_probe_match": True,
        "setup_member_set_match": True,
        "opensta_input_freeze_match": True,
        "completion_provenance_match": True,
        "console_clean": True,
        "path_report_cardinality_match": True,
        "wns_tns_state_match": True,
        "hardening_mutations_passed": True,
        "netlist_sha256": sha256(netlist),
        "synth_audit_summary_sha256": sha256(synth_audit),
        "synth_binding_sha256": sha256(args.synth_binding_pre.resolve()),
        "setup_members_manifest_sha256": sha256(args.setup_manifest_pre.resolve()),
        "input_manifest_sha256": sha256(manifest_pre),
        "parameters_sha256": sha256(parameters_pre),
        "diagnostic_vectorless_power_w": total_power,
        "power_qualified": False,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{PREFIX}] PASS: paths=40 violated={timing['violated_path_count']} "
        f"worst={float(timing['worst_path_slack_ns']):.9f}ns "
        f"target_200mhz_met={timing_met} reserve_met={reserve_met}"
    )


if __name__ == "__main__":
    main()
