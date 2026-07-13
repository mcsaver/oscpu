#!/usr/bin/env python3
"""Fail-closed audit for the expanded-freeze T3K 200 MHz synthesis."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


PREFIX = "T3K-SYNTH-AUDIT"
BLACKBOX_MODULES = (
    "Sram4096x199",
    "Sram4096x113",
    "OooFpArithGate",
    "OooBranchDirectionPredictor",
)
KEEP_MODULES = (
    "OooIntBackend",
    "OooFpBackend",
    "OooFrontend",
    "OooFetchAxiBridge",
    "OooMemAxiBridge",
    "OooRob",
    "OooIntIssueQueue",
)
FLOW_RELATIVE_PATHS = (
    "Makefile",
    "npc/rv64/Makefile",
    "yosys-sta/Makefile",
    "npc/rv64/.config",
    "npc/rv64/include/config/auto.conf",
    "npc/rv64/include/config/auto.conf.cmd",
    "npc/rv64/scripts/config.mk",
    "npc/rv64/vsrc/filelist.mk",
    "scripts/agent-env.sh",
    "yosys-sta/scripts/yosys.tcl",
    "yosys-sta/scripts/common.tcl",
    "yosys-sta/scripts/pdk/icsprout55.tcl",
    "yosys-sta/scripts/default.sdc",
    "yosys-sta/scripts/opensta-fullcore.tcl",
)
EVIDENCE_FILENAMES = (
    "run-fresh-synthesis.sh",
    "audit-t3k-synthesis.py",
    "check-t3k-netlist-structure.py",
    "opensta-t3k-current-5ns.tcl",
    "opensta-t3k-csr-focused.tcl",
    "check-t3k-global-sta.py",
    "check-t3k-focused-sta.py",
    "check-t3k-target-200mhz.py",
    "run-opensta-evidence.sh",
)
PROVENANCE_KEYS = (
    "start",
    "head",
    "rtl_count",
    "vsrc_count",
    "flow_count",
    "liberty_count",
    "evidence_count",
    "tool_binary_count",
    "rtl_manifest_sha256",
    "vsrc_manifest_sha256",
    "flow_manifest_sha256",
    "liberty_manifest_sha256",
    "evidence_manifest_sha256",
    "tool_binary_manifest_sha256",
    "parameters_sha256",
    "tool_versions_sha256",
)
FREEZE_STATUS = (
    "rtl_inputs=PASS",
    "vsrc_tree=PASS",
    "flow_inputs=PASS",
    "liberty_inputs=PASS",
    "evidence_inputs=PASS",
    "tool_binaries=PASS",
    "parameters=PASS",
    "tool_versions=PASS",
)


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_regular(path: Path, *, nonempty: bool = True) -> None:
    if not path.is_file() or path.is_symlink():
        fail(f"missing, symlink, or non-regular file: {path}")
    if nonempty and path.stat().st_size == 0:
        fail(f"empty file: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_exact_kv(path: Path, expected_keys: tuple[str, ...] | None = None) -> dict[str, str]:
    require_regular(path)
    fields: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed key/value line {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in fields:
            fail(f"empty or duplicate key {path.name}:{number}: {key!r}")
        fields[key] = value
    if expected_keys is not None and tuple(fields) != expected_keys:
        fail(
            f"key order/set mismatch in {path.name}: "
            f"actual={tuple(fields)} expected={expected_keys}"
        )
    return fields


def parse_provenance(path: Path) -> dict[str, str]:
    fields = read_exact_kv(path, PROVENANCE_KEYS)
    try:
        started = datetime.fromisoformat(fields["start"])
    except ValueError:
        fail(f"invalid provenance timestamp: {fields['start']!r}")
    if started.tzinfo is None:
        fail("provenance timestamp lacks a UTC offset")
    if re.fullmatch(r"[0-9a-f]{40}", fields["head"]) is None:
        fail(f"invalid provenance HEAD: {fields['head']!r}")
    for key in PROVENANCE_KEYS[2:8]:
        if re.fullmatch(r"[1-9][0-9]*", fields[key]) is None:
            fail(f"invalid provenance count {key}={fields[key]!r}")
    for key in PROVENANCE_KEYS[8:]:
        if re.fullmatch(r"[0-9a-f]{64}", fields[key]) is None:
            fail(f"invalid provenance hash {key}={fields[key]!r}")
    return fields


def parse_manifest(path: Path) -> list[tuple[str, Path]]:
    require_regular(path)
    result: list[tuple[str, Path]] = []
    seen: set[Path] = set()
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            fail(f"malformed manifest line {path.name}:{number}")
        expected, raw_path = match.groups()
        current = Path(raw_path)
        if current in seen:
            fail(f"duplicate manifest path {path.name}:{number}: {current}")
        seen.add(current)
        require_regular(current, nonempty=False)
        if current.resolve() != current:
            fail(f"non-canonical manifest path: {current}")
        actual = sha256(current)
        if actual != expected:
            fail(
                f"current-file hash mismatch {path.name}:{number}: "
                f"path={current} expected={expected} actual={actual}"
            )
        result.append((expected, current))
    if not result:
        fail(f"empty manifest: {path}")
    return result


def verify_manifest_pair(
    tmp_dir: Path,
    stem: str,
    expected_count: int,
) -> tuple[Path, list[tuple[str, Path]]]:
    pre = tmp_dir / f"synth-{stem}.pre.sha256"
    post = tmp_dir / f"synth-{stem}.post.sha256"
    require_regular(pre)
    require_regular(post)
    if pre.read_bytes() != post.read_bytes():
        fail(f"pre/post manifest bytes differ: {stem}")
    pre_entries = parse_manifest(pre)
    post_entries = parse_manifest(post)
    if pre_entries != post_entries:
        fail(f"parsed pre/post manifests differ: {stem}")
    if len(pre_entries) != expected_count:
        fail(
            f"manifest count mismatch {stem}: "
            f"actual={len(pre_entries)} expected={expected_count}"
        )
    return pre, pre_entries


def module_counts(path: Path) -> tuple[int, int]:
    modules = 0
    endmodules = 0
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            modules += line.startswith("module ")
            endmodules += line.startswith("endmodule")
    return modules, endmodules


def verify_commit(repo_root: Path, head: str) -> None:
    completed = subprocess.run(
        ["git", "-C", str(repo_root), "cat-file", "-t", head],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode != 0 or completed.stdout.strip() != "commit":
        fail(f"provenance HEAD is not an available commit: {head}")


def expected_parameters(repo_root: Path, tmp_dir: Path) -> dict[str, str]:
    macro_paths = [
        repo_root / "npc/rv64/syn/macro-lib/Sram4096x199.lib",
        repo_root / "npc/rv64/syn/macro-lib/Sram4096x113.lib",
        repo_root / "npc/rv64/syn/macro-lib/OooFpArithGate.lib",
        repo_root / "npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib",
    ]
    std_lib = repo_root / (
        "yosys-sta/pdk/icsprout55/IP/STD_cell/"
        "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
        "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
    )
    return {
        "synth_design": "NpcTop",
        "synth_pdk": "icsprout55",
        "synth_clk_port": "clk",
        "synth_clk_freq_mhz": "200",
        "synth_sdc": str(repo_root / "yosys-sta/scripts/default.sdc"),
        "synth_result_root": str(tmp_dir / "sta-build"),
        "synth_verilog_include_dirs": (
            f"{repo_root / 'npc/rv64/vsrc'} "
            f"{repo_root / 'npc/rv64/vsrc/include'}"
        ),
        "synth_verilog_defines": "",
        "synth_flatten": "0",
        "synth_share": "0",
        "synth_stop_after_coarse": "0",
        "synth_public_autoname": "0",
        "synth_dff_autoname": "0",
        "synth_blackbox_modules": " ".join(BLACKBOX_MODULES),
        "synth_keep_hierarchy_modules": " ".join(KEEP_MODULES),
        "synth_extra_lib_files": " ".join(map(str, macro_paths)),
        "opensta_period_ns": "5.0",
        "opensta_top": "NpcTop",
        "opensta_clock_port": "clk",
        "opensta_clock_name": "core_clock",
        "opensta_std_lib": str(std_lib),
        "opensta_macro_libs": ":".join(map(str, macro_paths)),
        "opensta_binary": "/home/lyg/tools/OpenSTA/build/sta",
        "freeze_dynamic_libraries": "NOT_INCLUDED",
        "freeze_tool_support_tree": "NOT_INCLUDED",
    }


def scan_synth_log(path: Path, tool_versions: dict[str, str]) -> dict[str, object]:
    exact_markers = (
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
            for module in KEEP_MODULES
        ),
    )
    marker_counts = {marker: 0 for marker in exact_markers}
    counters = {
        "abc_candidates": 0,
        "abc_empty": 0,
        "abc_results": 0,
        "abc_done": 0,
        "end_of_script": 0,
        "zero_problem_checks": 0,
        "error_lines": 0,
    }
    commands: list[str] = []
    mkdirs: list[str] = []
    yosys_versions = 0
    abc_versions = 0
    blackbox_total = 0
    keep_total = 0
    skip_total = 0
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
            keep_total += bool(
                re.fullmatch(
                    r"\[INFO\]: KEEPING hierarchy of module \S+ through flatten",
                    line,
                )
            )
            skip_total += line.startswith("[INFO]: SKIPPING ")
            yosys_versions += line == tool_versions["yosys"]
            abc_versions += line == f"ABC: {tool_versions['abc']}"
            if line.startswith("echo tcl "):
                commands.append(line)
            if line.startswith("mkdir -p "):
                mkdirs.append(line)
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
    if (blackbox_total, keep_total, skip_total) != (4, 7, 3):
        fail(
            f"marker-family totals drifted in {path.name}: "
            f"blackbox={blackbox_total} keep={keep_total} skip={skip_total}"
        )
    if yosys_versions != 1 or abc_versions != 210:
        fail(
            f"tool identity count mismatch in {path.name}: "
            f"yosys={yosys_versions} abc={abc_versions}"
        )
    return {
        "counters": counters,
        "commands": commands,
        "mkdirs": mkdirs,
        "final_stats": final_stats,
    }


def verify_console_command(
    scan: dict[str, object],
    repo_root: Path,
    build_dir: Path,
    rtl_entries: list[tuple[str, Path]],
) -> None:
    commands = scan["commands"]
    mkdirs = scan["mkdirs"]
    if mkdirs != [f"mkdir -p {build_dir}"]:
        fail(f"synthesis mkdir binding mismatch: {mkdirs}")
    if not isinstance(commands, list) or len(commands) != 1:
        fail(f"synthesis command cardinality mismatch: {commands}")
    match = re.fullmatch(
        r"echo tcl (?P<script>\S+) NpcTop icsprout55 "
        r'\\"(?P<rtl>[^\"]+)\\" (?P<netlist>\S+) '
        r'\\"(?P<includes>[^\"]+)\\" \\"\\" \| yosys -g -l '
        r"(?P<log>\S+) -s -",
        commands[0],
    )
    if match is None:
        fail("console command is not exactly bound to NpcTop/icsprout55")
    expected_paths = {
        "script": repo_root / "yosys-sta/scripts/yosys.tcl",
        "netlist": build_dir / "NpcTop.netlist.v",
        "log": build_dir / "yosys.log",
    }
    for field, expected in expected_paths.items():
        if Path(match.group(field)) != expected:
            fail(f"console command {field} mismatch")
    if match.group("rtl").split() != [str(path) for _, path in rtl_entries]:
        fail("console RTL list differs from the frozen RTL manifest")
    expected_includes = [
        str(repo_root / "npc/rv64/vsrc"),
        str(repo_root / "npc/rv64/vsrc/include"),
    ]
    if match.group("includes").split() != expected_includes:
        fail("console include-directory binding mismatch")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tmp_dir", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    tmp_dir = args.tmp_dir.resolve()
    build_dir = tmp_dir / "sta-build/NpcTop-200MHz"
    paths = {
        "provenance": tmp_dir / "synth-provenance.pre.kv",
        "status": tmp_dir / "synth-input-hash-cmp.txt",
        "exit": tmp_dir / "synth-exit-status.txt",
        "parameters_pre": tmp_dir / "synth-parameters.pre.kv",
        "parameters_post": tmp_dir / "synth-parameters.post.kv",
        "versions_pre": tmp_dir / "synth-tool-versions.pre.kv",
        "versions_post": tmp_dir / "synth-tool-versions.post.kv",
        "console": tmp_dir / "synth-console.log",
        "yosys": build_dir / "yosys.log",
        "netlist": build_dir / "NpcTop.netlist.v",
        "sim_netlist": build_dir / "NpcTop.netlist.v.sim",
        "check": build_dir / "synth_check.txt",
        "stat": build_dir / "synth_stat.txt",
        "abc_sdc": build_dir / "abc.sdc",
    }
    for path in paths.values():
        require_regular(path)
    if paths["exit"].read_text().strip() != "0":
        fail("synthesis exit status is not zero")
    if tuple(paths["status"].read_text().splitlines()) != FREEZE_STATUS:
        fail(f"freeze status mismatch: {paths['status'].read_text().splitlines()}")

    provenance = parse_provenance(paths["provenance"])
    counts = {
        name: int(provenance[f"{name}_count"])
        for name in ("rtl", "vsrc", "flow", "liberty", "evidence", "tool_binary")
    }
    expected_fixed_counts = {
        "rtl": 110,
        "flow": len(FLOW_RELATIVE_PATHS),
        "liberty": 5,
        "evidence": len(EVIDENCE_FILENAMES),
        "tool_binary": 6,
    }
    for name, expected in expected_fixed_counts.items():
        if counts[name] != expected:
            fail(f"provenance count mismatch {name}: {counts[name]} != {expected}")

    stems = {
        "rtl": "rtl-inputs",
        "vsrc": "vsrc-tree",
        "flow": "flow-inputs",
        "liberty": "liberty-inputs",
        "evidence": "evidence-inputs",
        "tool_binary": "tool-binaries",
    }
    manifests: dict[str, list[tuple[str, Path]]] = {}
    for name, stem in stems.items():
        pre, entries = verify_manifest_pair(tmp_dir, stem, counts[name])
        if sha256(pre) != provenance[f"{name}_manifest_sha256"]:
            fail(f"provenance manifest digest mismatch: {name}")
        manifests[name] = entries

    flow_paths = [path for _, path in manifests["flow"]]
    root_makefile = flow_paths[0]
    if root_makefile.name != "Makefile":
        fail("cannot infer repository root from flow manifest")
    repo_root = root_makefile.parent
    expected_flow = [repo_root / relative for relative in FLOW_RELATIVE_PATHS]
    if flow_paths != expected_flow:
        fail(f"expanded flow manifest path set/order mismatch: {flow_paths}")
    verify_commit(repo_root, provenance["head"])

    expected_evidence = [
        repo_root / ".github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation" / name
        for name in EVIDENCE_FILENAMES
    ]
    if [path for _, path in manifests["evidence"]] != expected_evidence:
        fail("evidence wrapper/checker/Tcl manifest mismatch")
    expected_tools = [
        repo_root / "oss-cad-suite/bin/yosys",
        repo_root / "oss-cad-suite/libexec/yosys",
        repo_root / "oss-cad-suite/bin/yosys-abc",
        repo_root / "oss-cad-suite/libexec/yosys-abc",
        repo_root / "oss-cad-suite/lib/ld-linux-x86-64.so.2",
        Path("/home/lyg/tools/OpenSTA/build/sta"),
    ]
    if [path for _, path in manifests["tool_binary"]] != expected_tools:
        fail("Yosys/ABC/OpenSTA binary manifest mismatch")

    std_lib = repo_root / (
        "yosys-sta/pdk/icsprout55/IP/STD_cell/"
        "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
        "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
    )
    expected_libs = [
        std_lib,
        repo_root / "npc/rv64/syn/macro-lib/Sram4096x199.lib",
        repo_root / "npc/rv64/syn/macro-lib/Sram4096x113.lib",
        repo_root / "npc/rv64/syn/macro-lib/OooFpArithGate.lib",
        repo_root / "npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib",
    ]
    if [path for _, path in manifests["liberty"]] != expected_libs:
        fail("H7CL plus four-macro liberty manifest mismatch")

    vsrc_root = repo_root / "npc/rv64/vsrc"
    vsrc_paths = [path for _, path in manifests["vsrc"]]
    current_vsrc = sorted(
        (
            path.resolve()
            for path in vsrc_root.rglob("*")
            if path.is_file() and not path.is_symlink()
        ),
        key=str,
    )
    if vsrc_paths != current_vsrc:
        fail("vsrc manifest does not cover the exact current regular-file tree")

    if paths["parameters_pre"].read_bytes() != paths["parameters_post"].read_bytes():
        fail("pre/post exact parameter KV differs")
    parameters = read_exact_kv(paths["parameters_pre"])
    if parameters != expected_parameters(repo_root, tmp_dir):
        fail("exact synthesis/OpenSTA parameter KV mismatch")
    if sha256(paths["parameters_pre"]) != provenance["parameters_sha256"]:
        fail("provenance parameter-KV hash mismatch")
    if paths["versions_pre"].read_bytes() != paths["versions_post"].read_bytes():
        fail("pre/post tool versions differ")
    versions = read_exact_kv(paths["versions_pre"], ("yosys", "abc", "opensta"))
    if re.fullmatch(r"Yosys \S+ \(git sha1 [0-9a-f]+, .+\)", versions["yosys"]) is None:
        fail(f"malformed Yosys identity: {versions['yosys']!r}")
    if re.fullmatch(r"UC Berkeley, ABC \S+ \(compiled .+\)", versions["abc"]) is None:
        fail(f"malformed ABC identity: {versions['abc']!r}")
    if re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", versions["opensta"]) is None:
        fail(f"malformed OpenSTA identity: {versions['opensta']!r}")
    if sha256(paths["versions_pre"]) != provenance["tool_versions_sha256"]:
        fail("provenance tool-version hash mismatch")

    if paths["abc_sdc"].read_bytes() != (
        b"set_driving_cell BUFX0P5H7L\nset_load 1.6\n"
    ):
        fail("abc.sdc is not exact BUFX0P5H7L/1.6 two-line content")
    expected_counters = {
        "abc_candidates": 220,
        "abc_empty": 10,
        "abc_results": 210,
        "abc_done": 210,
        "end_of_script": 1,
        "zero_problem_checks": 3,
        "error_lines": 0,
    }
    yosys_scan = scan_synth_log(paths["yosys"], versions)
    console_scan = scan_synth_log(paths["console"], versions)
    if yosys_scan["counters"] != expected_counters:
        fail(f"Yosys counter mismatch: {yosys_scan['counters']}")
    if console_scan["counters"] != expected_counters:
        fail(f"console counter mismatch: {console_scan['counters']}")
    verify_console_command(console_scan, repo_root, build_dir, manifests["rtl"])
    if paths["check"].read_text().count("Found and reported 0 problems.") != 1:
        fail("synth_check zero-problem marker cardinality mismatch")

    net_counts = module_counts(paths["netlist"])
    sim_counts = module_counts(paths["sim_netlist"])
    if net_counts != (110, 110) or sim_counts != (110, 110):
        fail(f"netlist module count mismatch net={net_counts} sim={sim_counts}")
    stat = paths["stat"].read_text()
    area_match = re.search(r"Chip area for top module '\\NpcTop':\s*([0-9.]+)", stat)
    sequential_match = re.search(
        r"used for sequential elements:\s*([0-9.]+)\s*\(([0-9.]+)%\)", stat
    )
    final_stats = yosys_scan["final_stats"]
    if not isinstance(final_stats, str):
        fail("internal Yosys final-stat type mismatch")
    runtime_match = re.search(
        r"time:\s*([0-9.]+)s.*MEM:\s*([0-9.]+) MB peak", final_stats
    )
    if area_match is None or sequential_match is None or runtime_match is None:
        fail("area/sequential/runtime synthesis summary missing")

    result = {
        **expected_counters,
        "netlist_bytes": paths["netlist"].stat().st_size,
        "netlist_sha256": sha256(paths["netlist"]),
        "yosys_log_bytes": paths["yosys"].stat().st_size,
        "yosys_log_sha256": sha256(paths["yosys"]),
        "module_count": net_counts[0],
        "area": float(area_match.group(1)),
        "sequential_area": float(sequential_match.group(1)),
        "sequential_percent": float(sequential_match.group(2)),
        "runtime_seconds": float(runtime_match.group(1)),
        "peak_memory_mb": float(runtime_match.group(2)),
        "provenance_head": provenance["head"],
        "input_counts": counts,
        "tool_versions": versions,
        "expanded_flow_freeze_inputs": counts["flow"],
        "liberty_freeze_inputs": counts["liberty"],
        "evidence_freeze_inputs": counts["evidence"],
        "tool_binary_freeze_inputs": counts["tool_binary"],
        "dynamic_libraries_frozen": False,
        "tool_support_tree_frozen": False,
        "abc_sdc_driver": "BUFX0P5H7L",
        "abc_sdc_load": 1.6,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{PREFIX}] PASS: netlist_sha256={result['netlist_sha256']} "
        f"area={result['area']:.2f} runtime={result['runtime_seconds']:.2f}s "
        f"flow={counts['flow']} liberty={counts['liberty']} "
        f"evidence={counts['evidence']} tool_binaries={counts['tool_binary']} "
        "dynamic_libraries_frozen=false tool_support_tree_frozen=false"
    )


if __name__ == "__main__":
    main()
