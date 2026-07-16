#!/usr/bin/env python3

from __future__ import annotations

import collections
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs/2026-07-15-rv64-t4s-pre-contract-netlist-compare"
EVIDENCE = TASK / "evidence"
NETLISTS = {
    "final": ROOT / "tmp/2026-07-15-rv64-t4s-final-200mhz/sta-build/NpcTop-200MHz/NpcTop.netlist.v",
    "pre_contract": ROOT / "tmp/2026-07-15-rv64-t4s-pre-contract-synthesis/sta-build/NpcTop-200MHz/NpcTop.netlist.v",
    "t4r": ROOT / "tmp/2026-07-15-rv64-t4r-xbar-registered-r/sta-build/NpcTop-200MHz/NpcTop.netlist.v",
}
SYNTH_SUMMARIES = {
    "final": ROOT / ".github/task-runs/2026-07-15-rv64-t4s-final-200mhz/evidence/synthesis/summary.json",
    "pre_contract": ROOT / ".github/task-runs/2026-07-15-rv64-t4s-final-200mhz/evidence/synthesis-pre-contract/summary.json",
    "t4r": ROOT / ".github/task-runs/2026-07-15-rv64-t4r-xbar-registered-r/evidence/synthesis/summary.json",
}
REPORTS = {
    "final": ROOT / ".github/task-runs/2026-07-15-rv64-t4s-final-200mhz/evidence/opensta-fresh-t4s-final/opensta-current-top40.rpt",
    "pre_contract": EVIDENCE / "opensta-exact5ns-pre-contract/opensta-current-top40.rpt",
    "t4r": ROOT / ".github/task-runs/2026-07-15-rv64-t4r-xbar-registered-r/evidence/opensta-exact5ns-diagnostic/opensta-current-top40.rpt",
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_shape(path: Path) -> tuple[int, int]:
    lines = 0
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            size += len(chunk)
            lines += chunk.count(b"\n")
    return size, lines


def iter_statements(path: Path):
    pending: list[str] = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            pending.append(line)
            while ";" in pending[-1]:
                joined = "".join(pending)
                head, tail = joined.split(";", 1)
                yield (head + ";").strip()
                pending = [tail] if tail else []
    trailing = "".join(pending).strip()
    if trailing:
        yield trailing


def statement_fingerprint(path: Path, temp_dir: Path) -> tuple[str, int, collections.Counter[str], dict[str, str]]:
    digest_path = temp_dir / f"{path.parent.parent.parent.parent.name}-{path.stat().st_ino}.digests"
    sorted_path = digest_path.with_suffix(".sorted")
    cell_counts: collections.Counter[str] = collections.Counter()
    selected_drivers: dict[str, str] = {}
    count = 0
    with digest_path.open("w", encoding="ascii") as digest_out:
        for statement in iter_statements(path):
            count += 1
            digest_out.write(hashlib.sha256(statement.encode()).hexdigest() + "\n")
            match = re.match(r"^([^\s]+)\s+([^\s]+)\s*\(", statement)
            if match and match.group(1) != "module":
                cell_counts[match.group(1)] += 1
                if ".Y(fill_we_w)" in statement:
                    selected_drivers["fill_we_w"] = f"{match.group(1)} {match.group(2)}"
    env = dict(os.environ, LC_ALL="C")
    with sorted_path.open("wb") as sorted_out:
        subprocess.run(["sort", str(digest_path)], check=True, env=env, stdout=sorted_out)
    fingerprint = sha256_file(sorted_path)
    return fingerprint, count, cell_counts, selected_drivers


def sorted_line_fingerprint(path: Path, temp_dir: Path) -> str:
    sorted_path = temp_dir / f"{path.name}-{path.stat().st_ino}.lines.sorted"
    env = dict(os.environ, LC_ALL="C")
    with sorted_path.open("wb") as sorted_out:
        subprocess.run(["sort", str(path)], check=True, env=env, stdout=sorted_out)
    return sha256_file(sorted_path)


def report_summary(path: Path, fill_driver: str) -> dict[str, object]:
    text = path.read_text()
    wns = float(re.search(r"^wns max ([+-]?[0-9.]+)$", text, re.M).group(1))
    tns = float(re.search(r"^tns max ([+-]?[0-9.]+)$", text, re.M).group(1))
    starts = re.findall(r"^Startpoint: (.+)$", text, re.M)
    endpoints = re.findall(r"^Endpoint: (.+)$", text, re.M)
    slacks = [float(value) for value in re.findall(r"^\s+([+-]?[0-9.]+)\s+slack \((?:VIOLATED|MET)\)$", text, re.M)]
    driver_instance = fill_driver.split()[-1]
    driver_line = re.search(
        rf"^\s+([+-]?[0-9.]+)\s+[+-]?[0-9.]+\s+[v^]\s+.+/u_dcache/{re.escape(driver_instance)}/Y \(([^)]+)\)$",
        text,
        re.M,
    )
    return {
        "report_sha256": sha256_file(path),
        "path_count": len(starts),
        "violated_path_count": text.count("slack (VIOLATED)"),
        "wns_ns": wns,
        "tns_ns": tns,
        "worst_startpoint": starts[0],
        "worst_endpoint": endpoints[0],
        "worst_slack_ns": slacks[0],
        "all_top40_same_startpoint": len(set(starts)) == 1,
        "all_top40_dcache_endpoints": all("/u_dcache/" in endpoint for endpoint in endpoints),
        "fill_we_driver_cell": fill_driver,
        "fill_we_driver_delay_ns_on_reported_path": float(driver_line.group(1)) if driver_line else None,
    }


def main() -> None:
    for path in (*NETLISTS.values(), *SYNTH_SUMMARIES.values(), *REPORTS.values()):
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            raise SystemExit(f"invalid input: {path}")

    comparison_out = EVIDENCE / "netlist-comparison.json"
    sta_out = EVIDENCE / "opensta-exact5ns-pre-contract/summary.json"
    for output in (comparison_out, sta_out):
        if output.exists():
            raise SystemExit(f"refusing stale output: {output}")

    metadata: dict[str, dict[str, object]] = {}
    statement_fingerprints: dict[str, str] = {}
    line_fingerprints: dict[str, str] = {}
    cell_counts: dict[str, collections.Counter[str]] = {}
    drivers: dict[str, dict[str, str]] = {}
    with tempfile.TemporaryDirectory(prefix="t4s-netlist-compare-", dir="/dev/shm") as temp:
        temp_dir = Path(temp)
        for role, path in NETLISTS.items():
            size, lines = file_shape(path)
            statement_fp, statement_count, role_cells, role_drivers = statement_fingerprint(path, temp_dir)
            metadata[role] = {
                "path": str(path),
                "sha256": sha256_file(path),
                "bytes": size,
                "lines": lines,
                "statement_count": statement_count,
            }
            statement_fingerprints[role] = statement_fp
            line_fingerprints[role] = sorted_line_fingerprint(path, temp_dir)
            cell_counts[role] = role_cells
            drivers[role] = role_drivers

    diff = subprocess.run(
        ["git", "diff", "--no-index", "--numstat", "--", str(NETLISTS["pre_contract"]), str(NETLISTS["final"])],
        check=False,
        capture_output=True,
        text=True,
    )
    added, deleted, _ = diff.stdout.strip().split("\t")
    synth = {role: json.loads(path.read_text()) for role, path in SYNTH_SUMMARIES.items()}
    timing = {
        role: report_summary(path, drivers[role]["fill_we_w"])
        for role, path in REPORTS.items()
    }
    all_cell_types = set().union(*(counts.keys() for counts in cell_counts.values()))
    t4r_to_final_cell_delta = {
        cell: cell_counts["final"][cell] - cell_counts["t4r"][cell]
        for cell in sorted(all_cell_types)
        if cell_counts["final"][cell] != cell_counts["t4r"][cell]
    }
    result = {
        "schema": "t4s-netlist-comparison-v1",
        "netlists": metadata,
        "synthesis": {
            role: {
                "area": summary["area"],
                "sequential_area": summary["sequential_area"],
                "module_count": summary["module_count"],
            }
            for role, summary in synth.items()
        },
        "final_vs_pre_contract": {
            "byte_identical": metadata["final"]["sha256"] == metadata["pre_contract"]["sha256"],
            "diff_added_lines": int(added),
            "diff_deleted_lines": int(deleted),
            "sorted_line_fingerprint": line_fingerprints["final"],
            "sorted_line_multiset_identical": line_fingerprints["final"] == line_fingerprints["pre_contract"],
            "sorted_statement_fingerprint": statement_fingerprints["final"],
            "statement_multiset_identical": statement_fingerprints["final"] == statement_fingerprints["pre_contract"],
            "primitive_and_module_instance_counts_identical": cell_counts["final"] == cell_counts["pre_contract"],
            "top40_timing_report_byte_identical": timing["final"]["report_sha256"] == timing["pre_contract"]["report_sha256"],
        },
        "t4r_vs_final": {
            "area_delta": synth["final"]["area"] - synth["t4r"]["area"],
            "sequential_area_delta": synth["final"]["sequential_area"] - synth["t4r"]["sequential_area"],
            "cell_type_count_delta_final_minus_t4r": t4r_to_final_cell_delta,
            "fill_we_driver_t4r": drivers["t4r"]["fill_we_w"],
            "fill_we_driver_final": drivers["final"]["fill_we_w"],
            "fill_we_driver_delay_delta_ns": (
                timing["final"]["fill_we_driver_delay_ns_on_reported_path"]
                - timing["t4r"]["fill_we_driver_delay_ns_on_reported_path"]
            ),
        },
        "timing": timing,
    }
    comparison_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    sta_out.write_text(json.dumps(timing["pre_contract"], indent=2, sort_keys=True) + "\n")
    print(json.dumps(result["final_vs_pre_contract"], sort_keys=True))
    print(json.dumps(result["t4r_vs_final"], sort_keys=True))
    print(json.dumps(timing["pre_contract"], sort_keys=True))


if __name__ == "__main__":
    main()
