#!/usr/bin/env python3
"""Fail-closed comparison of the two fresh R4-S0 synthesis runs.

Yosys may emit independent continuous assignments/instances in a different
textual order.  Therefore the audit records both the raw SHA256 (which must be
reported honestly) and an LC_ALL=C sorted-line multiset SHA256.  Equality of
the latter is an order-only textual reproducibility result, not a formal
sequential-equivalence proof.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from itertools import zip_longest
from typing import Any


SCHEMA = "npc-rv64-r4-s0-synth-reproducibility-v1"
SUMMARY_SCHEMA = "t4q-synthesis-audit-v1"
EXPECTED_TOP = "NpcTop"
EXPECTED_MODULE_COUNT = 119
EXPECTED_VSRC_COUNT = 140
EXPECTED_ABC_DONE = 226

CROSS_RUN_IDENTICAL = (
    "synth-evidence-inputs.pre.sha256",
    "synth-flow-inputs.pre.sha256",
    "synth-liberty-inputs.pre.sha256",
    "synth-rtl-inputs.pre.sha256",
    "synth-tool-binaries.pre.sha256",
    "synth-tool-versions.pre.kv",
    "synth-vsrc-tree.pre.sha256",
    "synth-input-hash-cmp.txt",
    "synth-exit-status.txt",
)

INTRA_RUN_FREEZE = (
    ("synth-evidence-inputs.pre.sha256", "synth-evidence-inputs.post.sha256"),
    ("synth-flow-inputs.pre.sha256", "synth-flow-inputs.post.sha256"),
    ("synth-liberty-inputs.pre.sha256", "synth-liberty-inputs.post.sha256"),
    ("synth-parameters.pre.kv", "synth-parameters.post.kv"),
    ("synth-rtl-inputs.pre.sha256", "synth-rtl-inputs.post.sha256"),
    ("synth-tool-binaries.pre.sha256", "synth-tool-binaries.post.sha256"),
    ("synth-tool-versions.pre.kv", "synth-tool-versions.post.kv"),
    ("synth-vsrc-tree.pre.sha256", "synth-vsrc-tree.post.sha256"),
)


class AuditError(RuntimeError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def sorted_line_sha256(path: Path) -> str:
    env = os.environ.copy()
    env["LC_ALL"] = "C"
    proc = subprocess.Popen(
        ["sort", str(path)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env
    )
    assert proc.stdout is not None
    digest = hashlib.sha256()
    for block in iter(lambda: proc.stdout.read(1024 * 1024), b""):
        digest.update(block)
    stderr = proc.stderr.read().decode("utf-8", errors="replace") if proc.stderr else ""
    rc = proc.wait()
    if rc != 0:
        raise AuditError(f"sort failed for {path}: rc={rc}: {stderr.strip()}")
    if stderr.strip():
        raise AuditError(f"sort emitted stderr for {path}: {stderr.strip()}")
    return digest.hexdigest()


def structural_statement_multisets(path: Path) -> dict[str, Counter[str]]:
    """Parse a Yosys structural netlist into per-module statement multisets.

    This intentionally rejects behavioural constructs.  Splitting statements
    at semicolons is valid only for the declaration/assign/cell-instance form
    emitted by this mapped flow.
    """
    text = path.read_text(encoding="utf-8", errors="ignore")
    if re.search(r"(?m)^\s*(always|initial|generate|function|task)\b", text):
        raise AuditError(f"{path}: behavioural construct prevents structural comparison")
    modules: dict[str, Counter[str]] = {}
    for part in text.split("\nmodule ")[1:]:
        if "\nendmodule" not in part:
            raise AuditError(f"{path}: unterminated module fragment")
        body = "module " + part.split("\nendmodule", 1)[0] + "\nendmodule"
        tokens = body.split()
        if len(tokens) < 2:
            raise AuditError(f"{path}: malformed module declaration")
        name = tokens[1]
        if name in modules:
            raise AuditError(f"{path}: duplicate module {name}")
        clean = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
        statements = Counter()
        for raw in clean.split(";"):
            statement = re.sub(r"\s+", " ", raw).strip()
            if statement:
                statements[statement] += 1
        modules[name] = statements
    if not modules:
        raise AuditError(f"{path}: no modules parsed")
    return modules


def structural_statement_sha256(modules: dict[str, Counter[str]]) -> str:
    digest = hashlib.sha256()
    for name in sorted(modules):
        digest.update(name.encode("utf-8") + b"\0")
        for statement, count in sorted(modules[name].items()):
            digest.update(str(count).encode("ascii") + b": ")
            digest.update(statement.encode("utf-8") + b"\n")
    return digest.hexdigest()


def physical_line_mismatches(left: Path, right: Path) -> int:
    with left.open("rb") as lhs, right.open("rb") as rhs:
        return sum(a != b for a, b in zip_longest(lhs, rhs, fillvalue=None))


def require_file(path: Path) -> Path:
    if not path.is_file():
        raise AuditError(f"missing file: {path}")
    return path


def load_summary(evidence_root: Path) -> dict[str, Any]:
    path = require_file(evidence_root / "evidence/synthesis/summary.json")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise AuditError(f"invalid summary {path}: {exc}") from exc
    expected = {
        "schema": SUMMARY_SCHEMA,
        "top": EXPECTED_TOP,
        "module_count": EXPECTED_MODULE_COUNT,
        "vsrc_count": EXPECTED_VSRC_COUNT,
        "abc_done": EXPECTED_ABC_DONE,
    }
    for key, value in expected.items():
        if data.get(key) != value:
            raise AuditError(f"{path}: {key}={data.get(key)!r}, expected {value!r}")
    if not isinstance(data.get("area"), (int, float)) or data["area"] <= 0:
        raise AuditError(f"{path}: invalid area")
    if not isinstance(data.get("sequential_area"), (int, float)) or data["sequential_area"] <= 0:
        raise AuditError(f"{path}: invalid sequential_area")
    return data


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    rel = Path("2026-07-15-rv64-ppa-architecture-recovery/evidence/r4-s0-correctness-checkpoint")
    evidence_base = repo / ".github/task-runs" / rel
    tmp_base = repo / "tmp" / rel

    errors: list[str] = []
    result: dict[str, Any] = {
        "schema": SCHEMA,
        "status": "FAIL",
        "interpretation": (
            "order-only textual reproducibility; not formal sequential equivalence"
        ),
        "runs": {},
        "cross_run": {},
        "errors": errors,
    }

    try:
        summaries: dict[str, dict[str, Any]] = {}
        raw_hashes: dict[str, str] = {}
        normalized_hashes: dict[str, str] = {}
        statement_hashes: dict[str, str] = {}
        statement_sets: dict[str, dict[str, Counter[str]]] = {}
        netlists: dict[str, Path] = {}
        for run in ("run1", "run2"):
            evidence_root = evidence_base / f"fresh-synth-{run}"
            tmp_root = tmp_base / f"fresh-synth-{run}"
            summary = load_summary(evidence_root)
            netlist = require_file(tmp_root / "sta-build/NpcTop-200MHz/NpcTop.netlist.v")
            raw_hash = sha256_file(netlist)
            normalized_hash = sorted_line_sha256(netlist)
            statements = structural_statement_multisets(netlist)
            statement_hash = structural_statement_sha256(statements)
            if raw_hash != summary.get("netlist_sha256"):
                raise AuditError(
                    f"{run}: netlist SHA {raw_hash} != summary {summary.get('netlist_sha256')}"
                )
            if netlist.stat().st_size != summary.get("netlist_bytes"):
                raise AuditError(f"{run}: netlist byte count disagrees with summary")

            freeze: dict[str, bool] = {}
            for pre_name, post_name in INTRA_RUN_FREEZE:
                pre = require_file(tmp_root / pre_name)
                post = require_file(tmp_root / post_name)
                freeze[f"{pre_name}=={post_name}"] = pre.read_bytes() == post.read_bytes()
            if not all(freeze.values()):
                raise AuditError(f"{run}: one or more pre/post input freezes changed")
            if require_file(tmp_root / "synth-exit-status.txt").read_text().strip() != "0":
                raise AuditError(f"{run}: synthesis exit status is not exactly 0")

            summaries[run] = summary
            raw_hashes[run] = raw_hash
            normalized_hashes[run] = normalized_hash
            statement_hashes[run] = statement_hash
            statement_sets[run] = statements
            netlists[run] = netlist
            result["runs"][run] = {
                "summary": summary,
                "netlist_path": str(netlist.relative_to(repo)),
                "netlist_raw_sha256": raw_hash,
                "netlist_sorted_line_multiset_sha256": normalized_hash,
                "netlist_structural_module_count": len(statements),
                "netlist_structural_statement_multiset_sha256": statement_hash,
                "input_freeze": freeze,
            }

        metric_keys = (
            "area",
            "sequential_area",
            "sequential_percent",
            "sequential_percent_derived",
            "module_count",
            "abc_done",
            "netlist_bytes",
            "vsrc_count",
            "top",
            "tool_versions",
            "provenance_head",
        )
        metric_identity = {
            key: summaries["run1"].get(key) == summaries["run2"].get(key)
            for key in metric_keys
        }
        if not all(metric_identity.values()):
            raise AuditError("cross-run audited metrics differ")

        manifest_identity: dict[str, bool] = {}
        for name in CROSS_RUN_IDENTICAL:
            left = require_file(tmp_base / "fresh-synth-run1" / name)
            right = require_file(tmp_base / "fresh-synth-run2" / name)
            manifest_identity[name] = left.read_bytes() == right.read_bytes()
        if not all(manifest_identity.values()):
            raise AuditError("cross-run frozen inputs/tool identity differs")

        raw_identical = raw_hashes["run1"] == raw_hashes["run2"]
        normalized_identical = normalized_hashes["run1"] == normalized_hashes["run2"]
        if not normalized_identical:
            raise AuditError("netlists differ beyond independent line ordering")
        if set(statement_sets["run1"]) != set(statement_sets["run2"]):
            raise AuditError("mapped module-name sets differ")
        differing_modules = sorted(
            name
            for name in statement_sets["run1"]
            if statement_sets["run1"][name] != statement_sets["run2"][name]
        )
        statement_equivalent = not differing_modules
        if not statement_equivalent or statement_hashes["run1"] != statement_hashes["run2"]:
            raise AuditError(
                "mapped structural statement multisets differ: "
                + ", ".join(differing_modules[:8])
            )

        result["cross_run"] = {
            "metric_identity": metric_identity,
            "input_manifest_identity": manifest_identity,
            "netlist_raw_byte_identical": raw_identical,
            "netlist_sorted_line_multiset_identical": normalized_identical,
            "netlist_structural_statement_equivalent": statement_equivalent,
            "netlist_structural_statement_different_modules": differing_modules,
            "netlist_physical_line_mismatches": physical_line_mismatches(
                netlists["run1"], netlists["run2"]
            ),
            "verdict": (
                "PASS_BYTE_IDENTICAL"
                if raw_identical
                else "PASS_STRUCTURAL_STATEMENTS_WITH_SERIALIZATION_ORDER_VARIANCE"
            ),
        }
        result["status"] = "PASS"
    except AuditError as exc:
        errors.append(str(exc))

    output = args.output
    if not output.is_absolute():
        output = repo / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"[R4-S0-SYNTH-REPRO] {result['status']}: {output}")
    if result["cross_run"]:
        print(f"[R4-S0-SYNTH-REPRO] {result['cross_run'].get('verdict')}")
    for error in errors:
        print(f"[R4-S0-SYNTH-REPRO] ERROR: {error}", file=sys.stderr)
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
