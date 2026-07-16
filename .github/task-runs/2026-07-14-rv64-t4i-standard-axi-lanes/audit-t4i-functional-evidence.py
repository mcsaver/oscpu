#!/usr/bin/env python3
"""Fail-closed post-run audit for T4I functional evidence and source binding."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def fail(message: str) -> None:
    raise SystemExit(f"[T4I-FUNCTIONAL-AUDIT] FAIL: {message}")


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        fail(f"missing, empty, symlink, or non-regular file: {path}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_manifest(path: Path) -> list[Path]:
    require_regular(path)
    files: list[Path] = []
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            fail(f"malformed vsrc manifest line {number}")
        expected, raw = match.groups()
        current = Path(raw)
        require_regular(current)
        if sha256(current) != expected:
            fail(f"vsrc drift after frozen synthesis: {current}")
        files.append(current)
    if len(files) != 137:
        fail(f"vsrc manifest count={len(files)}, expected 137")
    return files


def parse_riscv(path: Path) -> dict[str, int]:
    require_regular(path)
    counts = {
        "run_pass": 0,
        "run_fail": 0,
        "build_pass": 0,
        "build_fail": 0,
        "clean_pass": 0,
        "clean_fail": 0,
    }
    for raw_line in path.read_text(errors="replace").splitlines():
        fields = ANSI.sub("", raw_line).split()
        if not fields or fields[0] not in {"PASS", "FAIL"}:
            continue
        status = fields[0].lower()
        item = fields[1] if len(fields) > 1 else ""
        if item == "build":
            counts[f"build_{status}"] += 1
        elif item == "riscv-clean":
            counts[f"clean_{status}"] += 1
        else:
            counts[f"run_{status}"] += 1
    expected = {
        "run_pass": 177,
        "run_fail": 0,
        "build_pass": 177,
        "build_fail": 0,
        "clean_pass": 1,
        "clean_fail": 0,
    }
    if counts != expected:
        fail(f"riscv result counts={counts}, expected={expected}")
    return counts


def parse_am(path: Path) -> dict[str, float | int]:
    require_regular(path)
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if len(rows) != 59 or any(row["result"] != "PASS" for row in rows):
        fail("AM CPI table is not exactly 59/59 PASS")
    cycles = sum(int(row["cycles"]) for row in rows)
    commits = sum(int(row["commits"]) for row in rows)
    return {
        "passed": 59,
        "failed": 0,
        "cycles": cycles,
        "commits": commits,
        "weighted_cpi": cycles / commits,
    }


def parse_module(summary: Path, logs_dir: Path) -> dict[str, int]:
    require_regular(summary)
    text = summary.read_text()
    markers = {
        key: re.search(rf"^- {key}: (\d+)$", text, re.MULTILINE)
        for key in ("total", "passed", "failed")
    }
    if any(match is None for match in markers.values()):
        fail("module summary lacks total/passed/failed closure")
    values = {key: int(match.group(1)) for key, match in markers.items() if match}
    if values != {"total": 100, "passed": 100, "failed": 0}:
        fail(f"module summary drifted: {values}")
    logs = sorted(logs_dir.glob("*.log"))
    if len(logs) != 100:
        fail(f"module raw log count={len(logs)}, expected 100")
    for log in logs:
        require_regular(log)
        raw = log.read_text(errors="replace")
        if raw.count("[RESULT] PASS") != 1 or "[RESULT] FAIL" in raw or "$fatal" in raw:
            fail(f"module raw result is not exact PASS: {log}")
    return values


def parse_benchmark(path: Path, name: str, expected_cycles: int, expected_commits: int) -> dict[str, float | int]:
    require_regular(path)
    text = ANSI.sub("", path.read_text(errors="replace"))
    if f"{name} PASS" not in text or text.count("HIT GOOD TRAP") != 1:
        fail(f"{name} lacks PASS + exactly one GOOD TRAP")
    run = re.search(r"cycles=(\d+), commits=(\d+)", text)
    cpi = re.search(r"CPI \(cycles/instruction\) = ([0-9.]+)", text)
    if run is None or cpi is None:
        fail(f"{name} lacks cycles/commits/CPI")
    cycles, commits = map(int, run.groups())
    if (cycles, commits) != (expected_cycles, expected_commits):
        fail(f"{name} counters drifted: {(cycles, commits)}")
    return {"cycles": cycles, "commits": commits, "cpi": float(cpi.group(1))}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    root = args.repo.resolve()
    eval_full = root / "npc/rv64/eval/results/20260714-185943-t4i-standard-axi-lanes-v2"
    eval_bench = root / "npc/rv64/eval/results/20260714-192608-t4i-bench-complete-v3"
    module_dir = root / "npc/rv64/perf/results/20260714-t4i-full-module-v3/module-testbench"
    synth_vsrc = root / "tmp/2026-07-14-rv64-t4i-standard-axi-lanes/synth-vsrc-tree.post.sha256"
    binary = root / "npc/rv64/build/NpcSimTop"
    vsrc_files = parse_manifest(synth_vsrc)
    require_regular(binary)
    source_files = vsrc_files + sorted((root / "npc/rv64/csrc").rglob("*.[ch]")) + sorted(
        (root / "npc/rv64/csrc").rglob("*.cpp")
    )
    newer = [str(path) for path in source_files if path.stat().st_mtime_ns > binary.stat().st_mtime_ns]
    if newer:
        fail(f"vsrc/csrc newer than tested whole-system binary: {newer[:5]}")
    evidence_paths = {
        "riscv_log": eval_full / "riscv.log",
        "am_cpi": eval_full / "am-cpi.tsv",
        "whole_system_build_log": eval_full / "build.log",
        "coremark_log": eval_bench / "bench-coremark.log",
        "dhrystone_log": eval_bench / "bench-dhrystone.log",
        "module_summary": module_dir / "summary.txt",
    }
    result = {
        "schema": "t4i-functional-evidence-v1",
        "riscv": parse_riscv(evidence_paths["riscv_log"]),
        "am": parse_am(evidence_paths["am_cpi"]),
        "module": parse_module(evidence_paths["module_summary"], module_dir / "logs"),
        "coremark": parse_benchmark(
            evidence_paths["coremark_log"], "CoreMark", 6563047, 3218532
        ),
        "dhrystone_10000": parse_benchmark(
            evidence_paths["dhrystone_log"], "Dhrystone", 10802900, 4260665
        ),
        "tested_binary": str(binary),
        "tested_binary_sha256": sha256(binary),
        "tested_binary_mtime_ns": binary.stat().st_mtime_ns,
        "vsrc_matches_synthesis_post_manifest": True,
        "vsrc_count": len(vsrc_files),
        "no_vsrc_or_csrc_newer_than_tested_binary": True,
        "evidence_sha256": {
            key: sha256(path) for key, path in evidence_paths.items()
        },
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(
        "[T4I-FUNCTIONAL-AUDIT] PASS: riscv=177/177 am=59/59 "
        "module=100/100 coremark=PASS dhrystone10000=PASS"
    )


if __name__ == "__main__":
    main()
