#!/usr/bin/env python3
"""Build a fail-closed macro projection receipt for selected RV64 RTL/TB.

The receipt permits an old dynamic evidence bundle to remain selected-source
current only when the changed ``define.v`` macros are outside that bundle's
consumer cone.  It is deliberately narrower than a general source waiver:
every non-define consumer remains byte-bound, both product and assertion
preprocessor projections must match, and a producer-width mutation must be
observed by the same projection mechanism.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Iterable


SCHEMA = "rv64-selected-binding-define-projection-v1"
TARGET = "npc/rv64/vsrc/include/define.v"
NEGATIVE_MACRO = "OOO_PRODUCER_GEN_W"
PROFILES = (
    ("product", ()),
    ("assertion", ("OOO_ASSERT",)),
)
DEFINE_RE = re.compile(
    r"^\s*`define\s+([A-Za-z_][A-Za-z0-9_$]*)"
    r"(?:\([^)]*\))?(?:\s+(.*))?$"
)
INCLUDE_RE = re.compile(r"`include\s+\"([^\"]+)\"")
MACRO_REF_RE = re.compile(r"`([A-Za-z_][A-Za-z0-9_$]*)")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
CLAIM_BOUNDARY = (
    "Only the selected producer/holder RTL and testbench consumers listed "
    "in this receipt are rebound. The receipt does not promote full-design, "
    "whole-architecture, system, or PPA status."
)


class ProjectionError(RuntimeError):
    pass


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_preprocessed(data: bytes) -> bytes:
    """Discard preprocessor location/blank-line artifacts, not RTL tokens."""

    lines = []
    for raw in data.decode("utf-8", errors="strict").splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("`line "):
            continue
        lines.append(raw.rstrip())
    return ("\n".join(lines) + "\n").encode()


def repo_relative(root: pathlib.Path, path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError as exc:
        raise ProjectionError(f"path escapes repository: {path}") from exc


def run_bytes(command: list[str], *, cwd: pathlib.Path) -> bytes:
    completed = subprocess.run(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        env={**os.environ, "LC_ALL": "C"},
    )
    if completed.returncode != 0:
        rendered = " ".join(command)
        stderr = completed.stderr.decode(errors="replace").strip()
        raise ProjectionError(
            f"command failed rc={completed.returncode}: {rendered}: {stderr}"
        )
    return completed.stdout


def git_bytes(root: pathlib.Path, *args: str) -> bytes:
    return run_bytes(["git", "-C", str(root), *args], cwd=root)


def logical_lines(text: str) -> Iterable[str]:
    pending = ""
    for raw in text.splitlines():
        line = raw.rstrip()
        pending = f"{pending} {line}".strip() if pending else line
        if line.endswith("\\"):
            pending = pending[:-1].rstrip()
            continue
        yield pending
        pending = ""
    if pending:
        yield pending


def macro_table(text: str) -> dict[str, str]:
    table: dict[str, str] = {}
    for line in logical_lines(text):
        match = DEFINE_RE.match(line)
        if match:
            table[match.group(1)] = " ".join((match.group(2) or "").split())
    return table


def macro_references(body: str) -> set[str]:
    return set(MACRO_REF_RE.findall(body))


def changed_and_affected_macros(
    baseline: dict[str, str], current: dict[str, str]
) -> tuple[list[str], list[str]]:
    changed = sorted(
        name
        for name in set(baseline) | set(current)
        if baseline.get(name) != current.get(name)
    )
    affected = set(changed)
    while True:
        previous = set(affected)
        for name in set(baseline) | set(current):
            bodies = (baseline.get(name, ""), current.get(name, ""))
            if any(macro_references(body) & affected for body in bodies):
                affected.add(name)
        if affected == previous:
            break
    return changed, sorted(affected)


def replace_simple_define(text: str, name: str, new_body: str) -> str:
    pattern = re.compile(
        rf"^(\s*`define\s+{re.escape(name)}\s+).*$", re.MULTILINE
    )
    replaced, count = pattern.subn(rf"\g<1>{new_body}", text)
    if count != 1:
        raise ProjectionError(
            f"negative probe requires one simple definition for {name}, "
            f"found {count}"
        )
    return replaced


def load_policy_bindings(
    root: pathlib.Path, policy_path: pathlib.Path
) -> tuple[dict[str, list[dict[str, str]]], dict[str, str]]:
    policy = json.loads(policy_path.read_text(encoding="utf-8"))
    bindings: dict[str, list[dict[str, str]]] = {}
    evidence_ids: dict[str, str] = {}
    for spec in policy.get("evidence_sets", []):
        selected = spec.get("current_selected_bindings")
        if spec.get("semantic_closure") is not True or not isinstance(
            selected, list
        ):
            continue
        if not any(item.get("path") == TARGET for item in selected):
            continue
        kind = spec.get("binding_kind")
        evidence_id = spec.get("id")
        if not isinstance(kind, str) or not isinstance(evidence_id, str):
            raise ProjectionError("define-bound evidence lacks kind or id")
        consumers = [
            {"path": item["path"], "role": item["role"]}
            for item in selected
            if item.get("path") != TARGET
        ]
        if not consumers or kind in bindings:
            raise ProjectionError(f"invalid or duplicate binding kind: {kind}")
        bindings[kind] = sorted(consumers, key=lambda item: item["path"])
        evidence_ids[kind] = evidence_id
    return dict(sorted(bindings.items())), dict(sorted(evidence_ids.items()))


def include_search_roots(root: pathlib.Path) -> tuple[pathlib.Path, ...]:
    rv64 = root / "npc/rv64"
    return (
        rv64 / "vsrc",
        rv64 / "vsrc/include",
        rv64 / "testbench/common",
        rv64 / "testbench/tests",
        rv64 / "testbench",
        root,
    )


def resolve_include(
    root: pathlib.Path, source: pathlib.Path, include: str
) -> pathlib.Path | None:
    if include in {"define.v", "include/define.v"}:
        return None
    candidates = (source.parent / include,) + tuple(
        base / include for base in include_search_roots(root)
    )
    for candidate in candidates:
        if candidate.is_file():
            repo_relative(root, candidate)
            return candidate.resolve()
    raise ProjectionError(
        f"unresolved include from {repo_relative(root, source)}: {include}"
    )


def include_closure(
    root: pathlib.Path, selected_paths: Iterable[str]
) -> list[pathlib.Path]:
    pending = [root / path for path in selected_paths]
    visited: set[pathlib.Path] = set()
    while pending:
        path = pending.pop().resolve()
        repo_relative(root, path)
        if path in visited:
            continue
        if not path.is_file():
            raise ProjectionError(f"selected source is missing: {path}")
        visited.add(path)
        text = path.read_text(encoding="utf-8", errors="replace")
        for include in INCLUDE_RE.findall(text):
            resolved = resolve_include(root, path, include)
            if resolved is not None and resolved not in visited:
                pending.append(resolved)
    return sorted(visited, key=lambda item: repo_relative(root, item))


def lexical_hits(
    root: pathlib.Path,
    closure: Iterable[pathlib.Path],
    affected: set[str],
) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    for path in closure:
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8", errors="replace").splitlines(),
            start=1,
        ):
            names = sorted(set(MACRO_REF_RE.findall(line)) & affected)
            for name in names:
                hits.append(
                    {
                        "path": repo_relative(root, path),
                        "line": line_number,
                        "macro": name,
                    }
                )
    return hits


def current_design_id(root: pathlib.Path) -> str:
    tools = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools))
    try:
        architecture = importlib.import_module("architecture_hard_gates")
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def write_override(temp: pathlib.Path, text: str) -> None:
    (temp / "include").mkdir(exist_ok=True)
    (temp / "define.v").write_text(text, encoding="utf-8")
    (temp / "include/define.v").write_text(text, encoding="utf-8")


def preprocess(
    root: pathlib.Path,
    iverilog: pathlib.Path,
    temp: pathlib.Path,
    source: pathlib.Path,
    define_text: str,
    defines: tuple[str, ...],
) -> bytes:
    write_override(temp, define_text)
    output = temp / "preprocessed.sv"
    command = [
        str(iverilog),
        "-E",
        "-g2012",
        f"-I{temp}",
        f"-I{root / 'npc/rv64/vsrc'}",
        f"-I{root / 'npc/rv64/vsrc/include'}",
        f"-I{root / 'npc/rv64/testbench/common'}",
        f"-I{root / 'npc/rv64/testbench/tests'}",
        f"-I{root / 'npc/rv64/testbench'}",
        *(f"-D{name}" for name in defines),
        "-o",
        str(output),
        str(source),
    ]
    run_bytes(command, cwd=root)
    return normalize_preprocessed(output.read_bytes())


def build_receipt(args: argparse.Namespace) -> dict[str, Any]:
    root = args.root.resolve()
    policy_path = (root / args.policy).resolve()
    target_path = (root / TARGET).resolve()
    bindings, evidence_ids = load_policy_bindings(root, policy_path)
    if len(bindings) != args.expect_binding_count:
        raise ProjectionError(
            f"expected {args.expect_binding_count} define-bound bindings, "
            f"found {len(bindings)}"
        )

    baseline_commit = git_bytes(
        root, "rev-parse", "--verify", f"{args.baseline_ref}^{{commit}}"
    ).decode().strip()
    baseline_blob = git_bytes(
        root, "rev-parse", "--verify", f"{args.baseline_ref}:{TARGET}"
    ).decode().strip()
    baseline_bytes = git_bytes(root, "show", f"{args.baseline_ref}:{TARGET}")
    baseline_sha = sha256_bytes(baseline_bytes)
    if baseline_sha != args.baseline_sha256:
        raise ProjectionError(
            f"baseline define hash mismatch: {baseline_sha}"
        )
    current_bytes = target_path.read_bytes()
    current_sha = sha256_bytes(current_bytes)
    if current_sha == baseline_sha:
        raise ProjectionError("baseline and current define.v are identical")

    baseline_text = baseline_bytes.decode("utf-8")
    current_text = current_bytes.decode("utf-8")
    baseline_macros = macro_table(baseline_text)
    current_macros = macro_table(current_text)
    changed, affected = changed_and_affected_macros(
        baseline_macros, current_macros
    )
    if not changed:
        raise ProjectionError("define.v changed without a parsed macro delta")

    path_roles: dict[str, str] = {}
    for consumers in bindings.values():
        for item in consumers:
            previous = path_roles.setdefault(item["path"], item["role"])
            if previous != item["role"]:
                raise ProjectionError(
                    f"consumer role conflict for {item['path']}"
                )
    selected_paths = sorted(path_roles)
    closure = include_closure(root, selected_paths)
    hits = lexical_hits(root, closure, set(affected))

    iverilog_text = shutil.which(args.iverilog)
    if not iverilog_text:
        raise ProjectionError(f"iverilog is unavailable: {args.iverilog}")
    iverilog = pathlib.Path(iverilog_text).resolve()
    version = run_bytes([str(iverilog), "-V"], cwd=root).decode(
        errors="replace"
    ).splitlines()[0]

    profiles: list[dict[str, Any]] = []
    negative_mismatches: list[dict[str, str]] = []
    negative_text = replace_simple_define(
        current_text, NEGATIVE_MACRO, args.negative_body
    )
    negative_macros = macro_table(negative_text)
    if negative_macros.get(NEGATIVE_MACRO) == current_macros.get(
        NEGATIVE_MACRO
    ):
        raise ProjectionError("negative macro mutation had no effect")

    with tempfile.TemporaryDirectory(prefix="rv64-define-projection-") as raw:
        temp = pathlib.Path(raw)
        for profile_name, defines in PROFILES:
            records: list[dict[str, Any]] = []
            for path_value in selected_paths:
                source = root / path_value
                baseline_output = preprocess(
                    root,
                    iverilog,
                    temp,
                    source,
                    baseline_text,
                    defines,
                )
                current_output = preprocess(
                    root,
                    iverilog,
                    temp,
                    source,
                    current_text,
                    defines,
                )
                negative_output = preprocess(
                    root,
                    iverilog,
                    temp,
                    source,
                    negative_text,
                    defines,
                )
                baseline_output_sha = sha256_bytes(baseline_output)
                current_output_sha = sha256_bytes(current_output)
                equivalent = baseline_output == current_output
                records.append(
                    {
                        "path": path_value,
                        "baseline_sha256": baseline_output_sha,
                        "current_sha256": current_output_sha,
                        "size_bytes": len(current_output),
                        "equivalent": equivalent,
                    }
                )
                if negative_output != current_output:
                    negative_mismatches.append(
                        {"profile": profile_name, "path": path_value}
                    )
            profiles.append(
                {
                    "name": profile_name,
                    "defines": list(defines),
                    "records": records,
                }
            )

    projection_equivalent = all(
        record["equivalent"]
        for profile in profiles
        for record in profile["records"]
    )
    negative_detected = bool(negative_mismatches)
    status = (
        "PASS"
        if projection_equivalent and not hits and negative_detected
        else "FAIL"
    )

    macro_delta = []
    for name in changed:
        macro_delta.append(
            {
                "name": name,
                "baseline_present": name in baseline_macros,
                "baseline_body": baseline_macros.get(name),
                "current_present": name in current_macros,
                "current_body": current_macros.get(name),
            }
        )

    consumer_sources = [
        {
            "path": path_value,
            "role": path_roles[path_value],
            "sha256": sha256_file(root / path_value),
            "size_bytes": (root / path_value).stat().st_size,
        }
        for path_value in selected_paths
    ]
    closure_records = [
        {
            "path": repo_relative(root, path),
            "sha256": sha256_file(path),
            "size_bytes": path.stat().st_size,
        }
        for path in closure
    ]

    return {
        "schema_version": SCHEMA,
        "status": status,
        "current_design_id": current_design_id(root),
        "target": {
            "path": TARGET,
            "baseline_sha256": baseline_sha,
            "current_sha256": current_sha,
            "baseline_git_ref": args.baseline_ref,
            "baseline_commit": baseline_commit,
            "baseline_blob": baseline_blob,
        },
        "macro_delta": macro_delta,
        "affected_macros": affected,
        "bindings": bindings,
        "evidence_ids": evidence_ids,
        "consumer_sources": consumer_sources,
        "lexical_dependency": {
            "all_includes_resolved": True,
            "include_closure": closure_records,
            "selected_reference_hits": hits,
        },
        "profiles": profiles,
        "negative_probe": {
            "macro": NEGATIVE_MACRO,
            "current_body": current_macros.get(NEGATIVE_MACRO),
            "mutated_body": args.negative_body,
            "detected": negative_detected,
            "mismatches": sorted(
                negative_mismatches,
                key=lambda item: (item["profile"], item["path"]),
            ),
        },
        "tool": {
            "path": str(iverilog),
            "sha256": sha256_file(iverilog),
            "version": version,
        },
        "claim_boundary": CLAIM_BOUNDARY,
    }


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    parser.add_argument(
        "--policy",
        default=(
            "npc/rv64/design/arch/"
            "producer-holder-semantic-coverage-policy.json"
        ),
    )
    parser.add_argument("--baseline-ref", required=True)
    parser.add_argument(
        "--baseline-sha256",
        required=True,
        type=lambda value: value if SHA256_RE.fullmatch(value) else None,
    )
    parser.add_argument("--expect-binding-count", type=int, default=15)
    parser.add_argument("--negative-body", default="5")
    parser.add_argument("--iverilog", default="iverilog")
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    if args.baseline_sha256 is None:
        parser.error("--baseline-sha256 must be 64 lowercase hex digits")
    return args


def main() -> int:
    args = parse_args()
    try:
        payload = build_receipt(args)
    except (OSError, ValueError, json.JSONDecodeError, ProjectionError) as exc:
        print(f"[RV64-DEFINE-PROJECTION] FAIL {exc}", file=sys.stderr)
        return 1
    output = args.output
    if not output.is_absolute():
        output = args.root.resolve() / output
    write_json(output, payload)
    print(
        "[RV64-DEFINE-PROJECTION] "
        f"{payload['status']} bindings={len(payload['bindings'])} "
        f"consumers={len(payload['consumer_sources'])} "
        f"changed_macros={len(payload['macro_delta'])} "
        f"negative_mismatches="
        f"{len(payload['negative_probe']['mismatches'])} "
        f"receipt={repo_relative(args.root.resolve(), output)}"
    )
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
