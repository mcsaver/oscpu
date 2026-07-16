#!/usr/bin/env python3
"""Fail-closed audit for the T3O fresh 200 MHz synthesis snapshot."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


PREFIX = "T3O-SYNTH-AUDIT"
EXPECTED_FREEZE = (
    "rtl_inputs=PASS",
    "vsrc_tree=PASS",
    "flow_inputs=PASS",
    "liberty_inputs=PASS",
    "evidence_inputs=PASS",
    "tool_binaries=PASS",
    "parameters=PASS",
    "tool_versions=PASS",
)
MANIFEST_STEMS = {
    "rtl": ("rtl-inputs", 111),
    "flow": ("flow-inputs", 14),
    "liberty": ("liberty-inputs", 5),
    "evidence": ("evidence-inputs", 6),
    "tool_binary": ("tool-binaries", 6),
}


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


def parse_manifest(path: Path) -> list[tuple[str, Path]]:
    require_regular(path)
    rows: list[tuple[str, Path]] = []
    seen: set[Path] = set()
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            fail(f"malformed manifest line {path.name}:{number}")
        expected, raw = match.groups()
        current = Path(raw)
        if current in seen:
            fail(f"duplicate manifest path: {current}")
        seen.add(current)
        require_regular(current, nonempty=False)
        if current.resolve() != current:
            fail(f"non-canonical manifest path: {current}")
        actual = sha256(current)
        if actual != expected:
            fail(f"current hash drifted for {current}: expected={expected} actual={actual}")
        rows.append((expected, current))
    return rows


def verify_manifest_pair(tmp_dir: Path, stem: str, expected_count: int) -> list[tuple[str, Path]]:
    pre = tmp_dir / f"synth-{stem}.pre.sha256"
    post = tmp_dir / f"synth-{stem}.post.sha256"
    require_regular(pre)
    require_regular(post)
    if pre.read_bytes() != post.read_bytes():
        fail(f"pre/post manifest differs: {stem}")
    rows = parse_manifest(pre)
    if len(rows) != expected_count:
        fail(f"manifest count {stem}={len(rows)}, expected {expected_count}")
    return rows


def read_kv(path: Path) -> dict[str, str]:
    require_regular(path)
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if line.count("=") != 1:
            fail(f"malformed KV {path.name}:{number}: {line!r}")
        key, value = line.split("=", 1)
        if not key or key in result:
            fail(f"empty or duplicate KV key {path.name}:{number}")
        result[key] = value
    return result


def scan_log(path: Path) -> dict[str, int]:
    text = path.read_text(errors="replace")
    if re.search(r"^\s*ERROR:", text, re.MULTILINE):
        fail(f"synthesis log contains ERROR: {path}")
    for marker in (
        "[INFO]: USING STRATEGY DELAY-4",
        "[INFO]: ABC DELAY TARGET 5000.0ps (injected through {D})",
        "[INFO]: SKIPPING SAT resource sharing passes",
        "[INFO]: SKIPPING public net autoname",
        "[INFO]: SKIPPING DFF/cell autoname",
    ):
        if text.count(marker) != 1:
            fail(f"marker cardinality drifted in {path.name}: {marker!r}")
    result = {
        "abc_done": text.count("YOSYS_ABC_DONE"),
        "end_of_script": text.count("End of script"),
        "zero_problem_checks": text.count("Found and reported 0 problems."),
    }
    if result["abc_done"] < 200:
        fail(f"too few mapped ABC modules: {result['abc_done']}")
    if result["end_of_script"] != 1 or result["zero_problem_checks"] != 3:
        fail(f"incomplete synthesis log {path.name}: {result}")
    return result


def count_modules(path: Path) -> tuple[int, int]:
    modules = endmodules = 0
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
    repo_root = tmp_dir.parents[1]
    build_dir = tmp_dir / "sta-build/NpcTop-200MHz"
    files = {
        "exit": tmp_dir / "synth-exit-status.txt",
        "freeze": tmp_dir / "synth-input-hash-cmp.txt",
        "provenance": tmp_dir / "synth-provenance.pre.kv",
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
    for path in files.values():
        require_regular(path)
    if files["exit"].read_text().strip() != "0":
        fail("synthesis exit status is not zero")
    if tuple(files["freeze"].read_text().splitlines()) != EXPECTED_FREEZE:
        fail("input freeze status is not exact PASS")

    for _, (stem, count) in MANIFEST_STEMS.items():
        verify_manifest_pair(tmp_dir, stem, count)
    vsrc_pre = tmp_dir / "synth-vsrc-tree.pre.sha256"
    vsrc_post = tmp_dir / "synth-vsrc-tree.post.sha256"
    if vsrc_pre.read_bytes() != vsrc_post.read_bytes():
        fail("vsrc pre/post tree manifest differs")
    vsrc_rows = parse_manifest(vsrc_pre)
    if not vsrc_rows:
        fail("empty vsrc manifest")

    provenance = read_kv(files["provenance"])
    expected_counts = {
        "rtl_count": "111",
        "vsrc_count": str(len(vsrc_rows)),
        "flow_count": "14",
        "liberty_count": "5",
        "evidence_count": "6",
        "tool_binary_count": "6",
    }
    for key, expected in expected_counts.items():
        if provenance.get(key) != expected:
            fail(f"provenance {key}={provenance.get(key)!r}, expected {expected}")
    head = provenance.get("head", "")
    if re.fullmatch(r"[0-9a-f]{40}", head) is None:
        fail("invalid provenance HEAD")
    probe = subprocess.run(
        ["git", "-C", str(repo_root), "cat-file", "-t", head],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if probe.returncode or probe.stdout.strip() != "commit":
        fail("provenance HEAD is not an available commit")

    if files["parameters_pre"].read_bytes() != files["parameters_post"].read_bytes():
        fail("synthesis parameter KV drifted")
    parameters = read_kv(files["parameters_pre"])
    for key, expected in {
        "synth_design": "NpcTop",
        "synth_pdk": "icsprout55",
        "synth_clk_port": "clk",
        "synth_clk_freq_mhz": "200",
        "synth_result_root": str(tmp_dir / "sta-build"),
        "synth_flatten": "0",
        "synth_share": "0",
        "synth_stop_after_coarse": "0",
        "synth_public_autoname": "0",
        "synth_dff_autoname": "0",
        "opensta_period_ns": "5.0",
        "opensta_top": "NpcTop",
        "opensta_clock_port": "clk",
        "opensta_clock_name": "core_clock",
    }.items():
        if parameters.get(key) != expected:
            fail(f"parameter {key}={parameters.get(key)!r}, expected={expected!r}")
    if files["versions_pre"].read_bytes() != files["versions_post"].read_bytes():
        fail("tool version KV drifted")
    versions = read_kv(files["versions_pre"])
    if set(versions) != {"yosys", "abc", "opensta"}:
        fail("tool version identity set drifted")

    console_scan = scan_log(files["console"])
    yosys_scan = scan_log(files["yosys"])
    if console_scan != yosys_scan:
        fail(f"console/yosys completion counters disagree: {console_scan} {yosys_scan}")
    if files["check"].read_text().count("Found and reported 0 problems.") != 1:
        fail("synth_check lacks exactly one zero-problem marker")
    if files["abc_sdc"].read_bytes() != b"set_driving_cell BUFX0P5H7L\nset_load 1.6\n":
        fail("abc.sdc driver/load contract drifted")

    net_counts = count_modules(files["netlist"])
    sim_counts = count_modules(files["sim_netlist"])
    if net_counts != (112, 112) or sim_counts != (112, 112):
        fail(f"netlist module counts drifted: net={net_counts} sim={sim_counts}")
    resolve_paramod = r"\$paramod\PipeStageReg\WIDTH=s32'00000000000000000000000010010011"
    if files["netlist"].read_text().count(f"module {resolve_paramod} ") != 1:
        fail("147-bit resolve PipeStageReg paramod missing or duplicated")
    old_netlist = repo_root / "tmp/2026-07-13-rv64-t3n-resolve-boundary/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
    require_regular(old_netlist)
    net_hash = sha256(files["netlist"])
    old_hash = sha256(old_netlist)
    if net_hash == old_hash:
        fail("T3O netlist is byte-identical to T3N")

    stat = files["stat"].read_text()
    area_match = re.search(r"Chip area for top module '\\NpcTop':\s*([0-9.]+)", stat)
    sequential_match = re.search(
        r"used for sequential elements:\s*([0-9.]+)\s*\(([0-9.]+)%\)", stat
    )
    if area_match is None or sequential_match is None:
        fail("area or sequential-area summary missing")
    result = {
        "netlist_sha256": net_hash,
        "old_t3n_netlist_sha256": old_hash,
        "netlist_bytes": files["netlist"].stat().st_size,
        "module_count": net_counts[0],
        "area": float(area_match.group(1)),
        "sequential_area": float(sequential_match.group(1)),
        "sequential_percent": float(sequential_match.group(2)),
        "abc_done": yosys_scan["abc_done"],
        "provenance_head": head,
        "vsrc_count": len(vsrc_rows),
        "tool_versions": versions,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        f"[{PREFIX}] PASS: netlist_sha256={net_hash} area={result['area']:.2f} "
        f"modules={result['module_count']} abc_done={result['abc_done']}"
    )


if __name__ == "__main__":
    main()
