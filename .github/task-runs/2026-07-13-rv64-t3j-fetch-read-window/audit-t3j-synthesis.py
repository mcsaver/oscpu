#!/usr/bin/env python3
"""Fail-closed audit for the fresh T3J 200 MHz synthesis artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


AUDIT_PREFIX = "T3J-SYNTH-AUDIT"
BLACKBOX_MODULES = (
    "Sram4096x199",
    "Sram4096x113",
    "OooFpArithGate",
    "OooBranchDirectionPredictor",
)
KEEP_HIERARCHY_MODULES = (
    "OooIntBackend",
    "OooFpBackend",
    "OooFrontend",
    "OooFetchAxiBridge",
    "OooMemAxiBridge",
    "OooRob",
    "OooIntIssueQueue",
)
EXACT_FLOW_RELATIVE_PATHS = (
    "npc/rv64/.config",
    "npc/rv64/Makefile",
    "npc/rv64/vsrc/filelist.mk",
    "yosys-sta/scripts/yosys.tcl",
    "yosys-sta/scripts/default.sdc",
)
EXACT_LOG_MARKERS = (
    "[INFO]: USING STRATEGY DELAY-4",
    "[INFO]: ABC DELAY TARGET 5000.0ps (injected through {D})",
    "[INFO]: SKIPPING SAT resource sharing passes",
    "[INFO]: SKIPPING public net autoname",
    "[INFO]: SKIPPING DFF/cell autoname",
    *(
        f"[INFO]: MARKING module {module} as synthesis blackbox boundary"
        for module in BLACKBOX_MODULES
    ),
    *(
        f"[INFO]: KEEPING hierarchy of module {module} through flatten"
        for module in KEEP_HIERARCHY_MODULES
    ),
)
PROVENANCE_KEYS = (
    "start",
    "head",
    "yosys",
    "rtl_count",
    "vsrc_count",
    "flow_count",
    "rtl_manifest_sha256",
    "vsrc_manifest_sha256",
    "flow_manifest_sha256",
)


def fail(message: str) -> None:
    print(f"[{AUDIT_PREFIX}] FAIL: {message}", file=sys.stderr)
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


def require_nonempty(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, or non-regular artifact: {path}")


def parse_provenance(path: Path) -> dict[str, str]:
    require_nonempty(path)
    fields: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if "=" not in line:
            fail(f"malformed provenance line {path.name}:{number}")
        key, value = line.split("=", 1)
        if key in fields:
            fail(f"duplicate provenance key: {key}")
        if not key or not value:
            fail(f"empty provenance key/value at {path.name}:{number}")
        fields[key] = value
    if tuple(fields) != PROVENANCE_KEYS:
        fail(
            "provenance keys/order mismatch: "
            f"actual={tuple(fields)} expected={PROVENANCE_KEYS}"
        )

    try:
        started = datetime.fromisoformat(fields["start"])
    except ValueError:
        fail(f"invalid provenance start timestamp: {fields['start']!r}")
    if started.tzinfo is None:
        fail("provenance start timestamp has no UTC offset")
    if re.fullmatch(r"[0-9a-f]{40}", fields["head"]) is None:
        fail(f"invalid provenance HEAD: {fields['head']!r}")
    if re.fullmatch(r"Yosys \S+ \(git sha1 [0-9a-f]+, .+\)", fields["yosys"]) is None:
        fail(f"invalid provenance Yosys identity: {fields['yosys']!r}")
    for key in ("rtl_count", "vsrc_count", "flow_count"):
        if re.fullmatch(r"[1-9][0-9]*", fields[key]) is None:
            fail(f"invalid provenance count {key}={fields[key]!r}")
    for key in (
        "rtl_manifest_sha256",
        "vsrc_manifest_sha256",
        "flow_manifest_sha256",
    ):
        if re.fullmatch(r"[0-9a-f]{64}", fields[key]) is None:
            fail(f"invalid provenance digest {key}={fields[key]!r}")
    return fields


def parse_and_verify_manifest(
    path: Path, sha_cache: dict[Path, str]
) -> list[tuple[str, Path]]:
    lines = path.read_text().splitlines()
    if not lines:
        fail(f"empty input manifest: {path.name}")
    entries: list[tuple[str, Path]] = []
    seen_paths: set[Path] = set()
    for number, line in enumerate(lines, start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            fail(f"malformed checksum manifest line {path.name}:{number}")
        expected_sha, path_text = match.groups()
        current_file = Path(path_text)
        if current_file in seen_paths:
            fail(f"duplicate manifest path {path.name}:{number}: {current_file}")
        seen_paths.add(current_file)
        if (
            not current_file.is_file()
            or current_file.is_symlink()
            or current_file.resolve() != current_file
        ):
            fail(
                f"manifest path is missing, non-canonical, symlink, or non-file: "
                f"{current_file}"
            )
        # Recompute for both the pre and post manifests. The cache records the
        # unique verified-file set for reporting; it is not a substitute for
        # either current-file verification pass.
        actual_sha = file_sha256(current_file)
        sha_cache[current_file] = actual_sha
        if actual_sha != expected_sha:
            fail(
                f"current-file checksum mismatch {path.name}:{number}: "
                f"path={current_file} expected={expected_sha} actual={actual_sha}"
            )
        entries.append((expected_sha, current_file))
    return entries


def require_frozen_pair(
    pre: Path,
    post: Path,
    sha_cache: dict[Path, str],
    expected_lines: int,
) -> list[tuple[str, Path]]:
    require_nonempty(pre)
    require_nonempty(post)
    pre_bytes = pre.read_bytes()
    if pre_bytes != post.read_bytes():
        fail(f"input manifest changed during synthesis: {pre.name}")
    pre_entries = parse_and_verify_manifest(pre, sha_cache)
    post_entries = parse_and_verify_manifest(post, sha_cache)
    if pre_entries != post_entries:
        fail(f"parsed input manifests differ: {pre.name} vs {post.name}")
    if len(pre_entries) != expected_lines:
        fail(
            f"manifest {pre.name} has {len(pre_entries)} lines, "
            f"expected {expected_lines}"
        )
    return pre_entries


def verify_git_commit(repo_root: Path, head: str) -> None:
    completed = subprocess.run(
        ["git", "-C", str(repo_root), "cat-file", "-t", head],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode != 0 or completed.stdout.strip() != "commit":
        fail(
            "provenance HEAD is not an available commit object: "
            f"head={head} stderr={completed.stderr.strip()!r}"
        )


def scan_log(path: Path, yosys_identity: str) -> dict[str, object]:
    marker_counts = {marker: 0 for marker in EXACT_LOG_MARKERS}
    counters = {
        "abc_candidates": 0,
        "abc_empty": 0,
        "abc_results": 0,
        "abc_done": 0,
        "end_of_script": 0,
        "zero_problem_checks": 0,
        "error_lines": 0,
    }
    command_lines: list[str] = []
    mkdir_lines: list[str] = []
    blackbox_total = 0
    keep_hierarchy_total = 0
    skip_total = 0
    yosys_identity_count = 0
    final_stats = ""
    with path.open(encoding="utf-8", errors="replace") as stream:
        for raw_line in stream:
            line = raw_line.rstrip("\r\n")
            if line in marker_counts:
                marker_counts[line] += 1
            blackbox_total += bool(
                re.fullmatch(
                    r"\[INFO\]: MARKING module \S+ as synthesis blackbox boundary",
                    line,
                )
            )
            keep_hierarchy_total += bool(
                re.fullmatch(
                    r"\[INFO\]: KEEPING hierarchy of module \S+ through flatten",
                    line,
                )
            )
            skip_total += line.startswith("[INFO]: SKIPPING ")
            yosys_identity_count += line == yosys_identity
            if line.startswith("echo tcl "):
                command_lines.append(line)
            if line.startswith("mkdir -p "):
                mkdir_lines.append(line)
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
            counters["error_lines"] += bool(re.match(r"^\s*ERROR:", line))
            if "End of script. Logfile hash:" in line:
                final_stats = line.strip()

    bad_markers = {
        marker: count for marker, count in marker_counts.items() if count != 1
    }
    if bad_markers:
        fail(f"exact marker mismatch in {path.name}: {bad_markers}")
    if blackbox_total != len(BLACKBOX_MODULES):
        fail(
            f"blackbox marker total mismatch in {path.name}: "
            f"actual={blackbox_total} expected={len(BLACKBOX_MODULES)}"
        )
    if keep_hierarchy_total != len(KEEP_HIERARCHY_MODULES):
        fail(
            f"keep-hierarchy marker total mismatch in {path.name}: "
            f"actual={keep_hierarchy_total} expected={len(KEEP_HIERARCHY_MODULES)}"
        )
    if skip_total != 3:
        fail(f"skip marker total mismatch in {path.name}: actual={skip_total} expected=3")
    if yosys_identity_count != 1:
        fail(
            f"provenance Yosys identity count mismatch in {path.name}: "
            f"actual={yosys_identity_count} expected=1"
        )
    return {
        "counters": counters,
        "command_lines": command_lines,
        "mkdir_lines": mkdir_lines,
        "final_stats": final_stats,
    }


def verify_console_command(
    command_lines: list[str],
    mkdir_lines: list[str],
    repo_root: Path,
    build_dir: Path,
    rtl_entries: list[tuple[str, Path]],
) -> None:
    expected_mkdir = f"mkdir -p {build_dir}"
    if mkdir_lines != [expected_mkdir]:
        fail(
            "synthesis output-directory command mismatch: "
            f"actual={mkdir_lines} expected={[expected_mkdir]}"
        )
    if len(command_lines) != 1:
        fail(f"expected exactly one synthesis command, got {len(command_lines)}")
    command_match = re.fullmatch(
        r"echo tcl (?P<script>\S+) NpcTop icsprout55 "
        r'\\"(?P<rtl>[^\"]+)\\" (?P<netlist>\S+) '
        r'\\"(?P<includes>[^\"]+)\\" \\"\\" \| yosys -g -l '
        r"(?P<yosys_log>\S+) -s -",
        command_lines[0],
    )
    if command_match is None:
        fail("synthesis command is not exactly bound to NpcTop/icsprout55")
    expected_paths = {
        "script": repo_root / "yosys-sta/scripts/yosys.tcl",
        "netlist": build_dir / "NpcTop.netlist.v",
        "yosys_log": build_dir / "yosys.log",
    }
    for field, expected_path in expected_paths.items():
        if Path(command_match.group(field)) != expected_path:
            fail(
                f"synthesis command {field} mismatch: "
                f"actual={command_match.group(field)} expected={expected_path}"
            )
    command_rtl = command_match.group("rtl").split()
    manifest_rtl = [str(path) for _, path in rtl_entries]
    if command_rtl != manifest_rtl:
        fail("synthesis command RTL list differs from frozen RTL manifest")
    expected_includes = [
        str(repo_root / "npc/rv64/vsrc"),
        str(repo_root / "npc/rv64/vsrc/include"),
    ]
    if command_match.group("includes").split() != expected_includes:
        fail(
            "synthesis include-directory binding mismatch: "
            f"actual={command_match.group('includes').split()} "
            f"expected={expected_includes}"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tmp_dir", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    tmp_dir = args.tmp_dir.resolve()
    build_dir = tmp_dir / "sta-build/NpcTop-200MHz"
    provenance_path = tmp_dir / "synth-provenance.pre.txt"
    console_log = tmp_dir / "synth-console.log"
    yosys_log = build_dir / "yosys.log"
    netlist = build_dir / "NpcTop.netlist.v"
    sim_netlist = build_dir / "NpcTop.netlist.v.sim"
    synth_check = build_dir / "synth_check.txt"
    synth_stat = build_dir / "synth_stat.txt"
    abc_sdc = build_dir / "abc.sdc"

    for path in (
        provenance_path,
        console_log,
        yosys_log,
        netlist,
        sim_netlist,
        synth_check,
        synth_stat,
        abc_sdc,
    ):
        require_nonempty(path)
    exit_status = tmp_dir / "synth-exit-status.txt"
    freeze_status = tmp_dir / "synth-input-hash-cmp.txt"
    require_nonempty(exit_status)
    require_nonempty(freeze_status)
    if exit_status.read_text().strip() != "0":
        fail("synthesis exit status is not zero")
    freeze = freeze_status.read_text().splitlines()
    if freeze != ["rtl_inputs=PASS", "vsrc_tree=PASS", "flow_inputs=PASS"]:
        fail(f"input freeze mismatch: {freeze}")

    provenance = parse_provenance(provenance_path)
    provenance_counts = {
        name: int(provenance[f"{name}_count"])
        for name in ("rtl", "vsrc", "flow")
    }
    if provenance_counts["rtl"] != 110:
        fail(f"provenance RTL count is not 110: {provenance_counts['rtl']}")
    if provenance_counts["flow"] != 5:
        fail(
            "limited flow-input freeze must contain exactly five inputs: "
            f"actual={provenance_counts['flow']}"
        )

    sha_cache: dict[Path, str] = {}
    manifest_paths = {
        name: (
            tmp_dir / f"synth-{manifest_name}-inputs.pre.sha256",
            tmp_dir / f"synth-{manifest_name}-inputs.post.sha256",
        )
        for name, manifest_name in (("rtl", "rtl"), ("flow", "flow"))
    }
    manifest_paths["vsrc"] = (
        tmp_dir / "synth-vsrc-tree.pre.sha256",
        tmp_dir / "synth-vsrc-tree.post.sha256",
    )
    manifest_entries: dict[str, list[tuple[str, Path]]] = {}
    for name in ("rtl", "vsrc", "flow"):
        pre, post = manifest_paths[name]
        manifest_entries[name] = require_frozen_pair(
            pre,
            post,
            sha_cache,
            expected_lines=provenance_counts[name],
        )
        manifest_sha = file_sha256(pre)
        expected_manifest_sha = provenance[f"{name}_manifest_sha256"]
        if manifest_sha != expected_manifest_sha:
            fail(
                f"provenance {name} manifest digest mismatch: "
                f"expected={expected_manifest_sha} actual={manifest_sha}"
            )

    flow_paths = [path for _, path in manifest_entries["flow"]]
    first_flow_suffix = Path(EXACT_FLOW_RELATIVE_PATHS[0])
    first_flow = flow_paths[0]
    if tuple(first_flow.parts[-len(first_flow_suffix.parts) :]) != first_flow_suffix.parts:
        fail(f"cannot infer repository root from flow manifest: {first_flow}")
    repo_root = first_flow.parents[len(first_flow_suffix.parts) - 1]
    expected_flow_paths = [repo_root / relative for relative in EXACT_FLOW_RELATIVE_PATHS]
    if flow_paths != expected_flow_paths:
        fail(
            "limited flow-input freeze scope mismatch: "
            f"actual={flow_paths} expected={expected_flow_paths}"
        )
    verify_git_commit(repo_root, provenance["head"])

    vsrc_root = repo_root / "npc/rv64/vsrc"
    vsrc_paths = [path for _, path in manifest_entries["vsrc"]]
    if vsrc_paths != sorted(vsrc_paths, key=str):
        fail("vsrc manifest is not deterministically path-sorted")
    for path in vsrc_paths:
        try:
            path.relative_to(vsrc_root)
        except ValueError:
            fail(f"vsrc manifest path escapes vsrc tree: {path}")
    current_vsrc_paths = sorted(
        (
            path.resolve()
            for path in vsrc_root.rglob("*")
            if path.is_file() and not path.is_symlink()
        ),
        key=str,
    )
    if vsrc_paths != current_vsrc_paths:
        fail("vsrc manifest path set differs from the current regular-file tree")

    expected_abc_sdc = b"set_driving_cell BUFX0P5H7L\nset_load 1.6\n"
    if abc_sdc.read_bytes() != expected_abc_sdc:
        fail(
            "abc.sdc mismatch: expected exact BUFX0P5H7L driver and 1.6 load "
            "in the generated two-line format"
        )

    yosys_scan = scan_log(yosys_log, provenance["yosys"])
    console_scan = scan_log(console_log, provenance["yosys"])
    counters = yosys_scan["counters"]
    console_counters = console_scan["counters"]
    assert isinstance(counters, dict)
    assert isinstance(console_counters, dict)

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
    if console_counters != expected:
        fail(
            f"console counter mismatch: actual={console_counters} expected={expected}"
        )
    command_lines = console_scan["command_lines"]
    mkdir_lines = console_scan["mkdir_lines"]
    assert isinstance(command_lines, list)
    assert isinstance(mkdir_lines, list)
    verify_console_command(
        command_lines,
        mkdir_lines,
        repo_root,
        build_dir,
        manifest_entries["rtl"],
    )
    if synth_check.read_text().count("Found and reported 0 problems.") != 1:
        fail("synth_check.txt does not contain exactly one zero-problem marker")

    net_modules = verilog_module_counts(netlist)
    sim_modules = verilog_module_counts(sim_netlist)
    if net_modules != (110, 110) or sim_modules != (110, 110):
        fail(f"module counts netlist={net_modules} sim={sim_modules}")

    stat_text = synth_stat.read_text()
    area_match = re.search(r"Chip area for top module '\\NpcTop':\s*([0-9.]+)", stat_text)
    sequential_match = re.search(
        r"used for sequential elements:\s*([0-9.]+)\s*\(([0-9.]+)%\)", stat_text
    )
    if area_match is None or sequential_match is None:
        fail("area summary missing")
    final_stats = yosys_scan["final_stats"]
    assert isinstance(final_stats, str)
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
        "provenance_head": provenance["head"],
        "provenance_yosys": provenance["yosys"],
        "rtl_input_count": provenance_counts["rtl"],
        "vsrc_tree_count": provenance_counts["vsrc"],
        "limited_freeze_inputs": provenance_counts["flow"],
        "rtl_manifest_sha256": provenance["rtl_manifest_sha256"],
        "vsrc_manifest_sha256": provenance["vsrc_manifest_sha256"],
        "flow_manifest_sha256": provenance["flow_manifest_sha256"],
        "current_manifest_files_verified": len(sha_cache),
        "abc_sdc_driver": "BUFX0P5H7L",
        "abc_sdc_load": 1.6,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{AUDIT_PREFIX}] PASS: "
        f"netlist_sha256={result['netlist_sha256']} area={result['area']:.2f} "
        f"runtime={result['runtime_seconds']:.2f}s peak={result['peak_memory_mb']:.2f}MB "
        f"limited_freeze_inputs={result['limited_freeze_inputs']}"
    )


if __name__ == "__main__":
    main()
