#!/usr/bin/env python3
"""Assemble current-design V8L holder-lifecycle evidence from raw RTL runs."""

from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
EVIDENCE = RUN_DIR / "evidence/focused"
BACKEND = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
GATE_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
RTL_BINDING_PRE = EVIDENCE / "rtl-source-binding.pre.json"
RTL_BINDING_POST = EVIDENCE / "rtl-source-binding.post.json"
RUNNER_SOURCES_PRE = EVIDENCE / "sources.pre.sha256"
RUNNER_SOURCES_POST = EVIDENCE / "sources.post.sha256"
RTL_BINDING_SCHEMA = "npc-rv64-v8l-rtl-source-binding-v1"

SPEC = importlib.util.spec_from_file_location("v8l_current_rtl_binding", GATE_TOOL)
assert SPEC is not None and SPEC.loader is not None
gate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = gate
SPEC.loader.exec_module(gate)


MUTATIONS = {
    "dispatch_drop_int_iq_union":
        "FAIL v8l complete mask differs from independent raw IQ scan",
    "dispatch_lane0_raw_index":
        "[CHECK-FAIL] v8g lane0 live PID stalls dispatch0",
    "int_iq_fire_dies_early":
        "[CHECK-FAIL] v8l resident IQ P blocks exact candidate",
    "backend_drop_mem_res_holder":
        "[CHECK-FAIL] v8l memory reservation reaches complete mask",
    "backend_drop_ex0_holder":
        "[CHECK-FAIL] v8l EX0 handoff keeps complete lease",
    "backend_drop_ex1_holder":
        "[CHECK-FAIL] v8l EX1 reaches complete mask",
    "backend_drop_branch_holder":
        "[CHECK-FAIL] v8l branch packet reaches complete mask",
    "backend_capture_ignores_tracker_ready":
        "[CHECK-FAIL] v8l tracker-backpressure blocks capture",
    "backend_iq_pop_ignores_tracker_ready":
        "[CHECK-FAIL] v8l tracker-backpressure blocks IQ pop",
}


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_rtl_snapshot() -> dict[str, Any]:
    rtl_sha, rtl_files = gate.rtl_binding(ROOT)
    if not rtl_files:
        raise RuntimeError("canonical RTL source set is empty")
    return {
        "schema": RTL_BINDING_SCHEMA,
        "design_id": f"sha256:{rtl_sha}",
        "rtl_files": rtl_files,
    }


def validate_snapshot_shape(
    value: Any, *, label: str
) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != {
        "schema", "design_id", "rtl_files"
    }:
        raise RuntimeError(f"{label} RTL source binding has invalid keys")
    if value.get("schema") != RTL_BINDING_SCHEMA:
        raise RuntimeError(f"{label} RTL source binding schema mismatch")
    design_id = value.get("design_id")
    if not isinstance(design_id, str) or re.fullmatch(
        r"sha256:[0-9a-f]{64}", design_id
    ) is None:
        raise RuntimeError(f"{label} RTL source binding design_id is invalid")
    rtl_files = value.get("rtl_files")
    if not isinstance(rtl_files, dict) or not rtl_files:
        raise RuntimeError(f"{label} RTL source binding file set is empty")
    for path, digest in rtl_files.items():
        if not isinstance(path, str) or not path or re.fullmatch(
            r"[0-9a-f]{64}", digest if isinstance(digest, str) else ""
        ) is None:
            raise RuntimeError(
                f"{label} RTL source binding contains an invalid entry"
            )
    return value


def validate_rtl_snapshots(
    pre_value: Any, post_value: Any, live_value: Any
) -> dict[str, Any]:
    pre = validate_snapshot_shape(pre_value, label="pre")
    post = validate_snapshot_shape(post_value, label="post")
    live = validate_snapshot_shape(live_value, label="live")
    if pre != post:
        raise RuntimeError(
            "canonical RTL source binding drifted during the focused run"
        )
    if post != live:
        raise RuntimeError(
            "live canonical RTL differs from the focused-run source binding"
        )
    return copy.deepcopy(pre)


def load_json(path: pathlib.Path) -> Any:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"JSON evidence is not a regular file: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"invalid JSON evidence {path}: {exc}") from exc


def write_json(path: pathlib.Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            value,
            ensure_ascii=False,
            allow_nan=False,
            indent=2,
            sort_keys=True,
        ) + "\n",
        encoding="utf-8",
    )


def parse_sha256_manifest(
    manifest_path: pathlib.Path, root: pathlib.Path
) -> dict[str, str]:
    if manifest_path.is_symlink() or not manifest_path.is_file():
        raise RuntimeError(
            f"runner source manifest is not a regular file: {manifest_path}"
        )
    root_resolved = root.resolve()
    result: dict[str, str] = {}
    for line_number, line in enumerate(
        manifest_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if match is None:
            raise RuntimeError(
                f"invalid sha256 manifest row {manifest_path}:{line_number}"
            )
        recorded, raw_path = match.groups()
        candidate = pathlib.Path(raw_path)
        if not candidate.is_absolute():
            candidate = root / candidate
        if candidate.is_symlink() or not candidate.is_file():
            raise RuntimeError(
                f"runner source is not a regular file: {raw_path}"
            )
        resolved = candidate.resolve()
        try:
            relative_path = resolved.relative_to(root_resolved).as_posix()
        except ValueError as exc:
            raise RuntimeError(
                f"runner source escapes the repository: {raw_path}"
            ) from exc
        if relative_path in result:
            raise RuntimeError(
                f"duplicate runner source manifest entry: {relative_path}"
            )
        result[relative_path] = recorded
    if not result:
        raise RuntimeError("runner source manifest is empty")
    return result


def validate_runner_source_manifests(
    pre_path: pathlib.Path,
    post_path: pathlib.Path,
    root: pathlib.Path,
) -> dict[str, str]:
    pre = parse_sha256_manifest(pre_path, root)
    post = parse_sha256_manifest(post_path, root)
    if pre != post:
        raise RuntimeError("focused runner input hashes drifted during the run")
    for relative_path, recorded in pre.items():
        live_path = root / relative_path
        if sha256(live_path) != recorded:
            raise RuntimeError(
                f"live focused runner input differs from evidence: "
                f"{relative_path}"
            )
    return pre


def relative(path: pathlib.Path) -> str:
    return path.resolve(strict=True).relative_to(ROOT.resolve()).as_posix()


def require_marker(path: pathlib.Path, marker: str) -> None:
    text = path.read_text(encoding="utf-8")
    if marker not in text:
        raise RuntimeError(f"missing marker {marker!r} in {relative(path)}")


def raw_entry(path: pathlib.Path) -> dict[str, str]:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"raw evidence is not a regular file: {path}")
    return {"path": relative(path), "sha256": sha256(path)}


def normalized_entry(path: pathlib.Path, output: pathlib.Path) -> dict[str, str]:
    """Bind a log after replacing only the runner-owned random temp root."""
    text = path.read_text(encoding="utf-8")
    normalized = re.sub(
        r"/tmp/v8l-global-lease\.[A-Za-z0-9]+",
        "<V8L_TEMP>",
        text,
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(normalized, encoding="utf-8")
    return raw_entry(output)


def assemble_current_evidence() -> int:
    rtl_binding = validate_rtl_snapshots(
        load_json(RTL_BINDING_PRE),
        load_json(RTL_BINDING_POST),
        canonical_rtl_snapshot(),
    )
    runner_sources = validate_runner_source_manifests(
        RUNNER_SOURCES_PRE,
        RUNNER_SOURCES_POST,
        ROOT,
    )
    design_id = rtl_binding["design_id"]

    dispatch_log = EVIDENCE / (
        "baseline-release-dispatch-focus/logs/tb_ooo_dispatch_backend.log")
    backend_log = EVIDENCE / (
        "baseline-release-backend-focus/logs/tb_ooo_int_backend.log")
    legacy_log = EVIDENCE / (
        "baseline-release-legacy-v8g/logs/tb_ooo_int_backend.log")
    positive_requirements = (
        (dispatch_log, "[V8L-INTIQ-DEATH-EDGE]"),
        (dispatch_log, "[V8L-FINITE-GENERATION-WRAP]"),
        (backend_log, "[V8L-TRANSIENT-HOLDER-CENSUS]"),
        (backend_log, "[V8L-TRACKER-BACKPRESSURE]"),
        (legacy_log, "[V8G-MEM-TRACKER-QUARANTINE]"),
    )
    for path, marker in positive_requirements:
        require_marker(path, marker)
        require_marker(path, "[RESULT] PASS")

    backend_text = BACKEND.read_text(encoding="utf-8")
    for label in (
        "[V8L-MEM-HANDOFF-BACKPRESSURE]",
        "[V8L-MEM-INDIRECT-TRACKER]",
    ):
        if label not in backend_text:
            raise RuntimeError(f"production RTL assertion label is missing: {label}")

    summary_log = EVIDENCE / "mutation-summary.log"
    summary_text = summary_log.read_text(encoding="utf-8")
    mutation_records: list[dict[str, Any]] = []
    for name, consequence in MUTATIONS.items():
        expected = (
            f"[V8L-MUTATION][PASS] name={name} compile=PASS "
            f"consequence={consequence}")
        if summary_text.splitlines().count(expected) != 1:
            raise RuntimeError(f"mutation summary does not contain one exact row: {name}")
        mutator_log = EVIDENCE / f"mutation-{name}.mutator.log"
        make_log = EVIDENCE / f"mutation-{name}.make.log"
        require_marker(mutator_log, "[V8L-MUTATOR][PASS]")
        require_marker(make_log, "[MAKE-RC]")
        if "[MAKE-RC] 0" in make_log.read_text(encoding="utf-8"):
            raise RuntimeError(f"semantic mutation was not rejected: {name}")
        mutation_records.append({
            "name": name,
            "compiled": True,
            "rejected": True,
            "consequence": consequence,
            "raw_mutator_log": relative(mutator_log),
            "raw_simulation_log": relative(make_log),
            "mutator_log": normalized_entry(
                mutator_log,
                EVIDENCE / f"normalized/mutation-{name}.mutator.log",
            ),
            "simulation_log": normalized_entry(
                make_log,
                EVIDENCE / f"normalized/mutation-{name}.make.log",
            ),
        })

    mutation_value = {
        "schema": "npc-rv64-holder-lifecycle-mutations-v1",
        "design_id": design_id,
        "source_binding": {
            "rtl_pre": raw_entry(RTL_BINDING_PRE),
            "rtl_post": raw_entry(RTL_BINDING_POST),
            "runner_sources_pre": raw_entry(RUNNER_SOURCES_PRE),
            "runner_sources_post": raw_entry(RUNNER_SOURCES_POST),
        },
        "compile_success": len(mutation_records),
        "rejected": len(mutation_records),
        "mutations": mutation_records,
    }
    mutation_path = EVIDENCE / "mutation-summary.json"
    mutation_path.write_text(
        json.dumps(mutation_value, ensure_ascii=False, allow_nan=False, indent=2)
        + "\n",
        encoding="utf-8",
    )

    sources = {
        "dispatch": normalized_entry(
            dispatch_log, EVIDENCE / "normalized/baseline-release-dispatch.log"),
        "backend": normalized_entry(
            backend_log, EVIDENCE / "normalized/baseline-release-backend.log"),
        "legacy_memory": normalized_entry(
            legacy_log, EVIDENCE / "normalized/baseline-release-legacy-v8g.log"),
        "mutation_summary": raw_entry(mutation_path),
        "production_rtl": raw_entry(BACKEND),
        "rtl_source_binding_pre": raw_entry(RTL_BINDING_PRE),
        "rtl_source_binding_post": raw_entry(RTL_BINDING_POST),
        "runner_sources_pre": raw_entry(RUNNER_SOURCES_PRE),
        "runner_sources_post": raw_entry(RUNNER_SOURCES_POST),
    }
    lines = [
        "schema=npc-rv64-holder-lifecycle-log-v1",
        f"design_id={design_id}",
        "canonical_command=make -C npc/rv64 check-global-producer-no-live-reuse",
        "source_binding_status=PASS",
        f"rtl_source_count={len(rtl_binding['rtl_files'])}",
        f"runner_source_count={len(runner_sources)}",
        "V8L-INTIQ-DEATH-EDGE PASS",
        "V8L-FINITE-GENERATION-WRAP PASS",
        "V8L-TRANSIENT-HOLDER-CENSUS PASS",
        "V8L-MEM-HANDOFF-BACKPRESSURE PASS",
        "V8L-MEM-INDIRECT-TRACKER PASS",
        f"compile_success_mutations={len(mutation_records)}",
        f"rejected_mutations={len(mutation_records)}",
    ]
    for label, entry in sorted(sources.items()):
        lines.append(
            f"artifact.{label}.path={entry['path']} sha256={entry['sha256']}")
    lifecycle_path = EVIDENCE / "holder-lifecycle.log"
    lifecycle_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        "[V8L-CENSUS-EVIDENCE][PASS] "
        f"design_id={design_id} mutations={len(mutation_records)}/{len(MUTATIONS)}"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--snapshot-out",
        type=pathlib.Path,
        help=(
            "write the current canonical RTL binding and stop; the focused "
            "runner records one snapshot before and one after simulation"
        ),
    )
    args = parser.parse_args()
    if args.snapshot_out is not None:
        write_json(args.snapshot_out, canonical_rtl_snapshot())
        print(
            "[V8L-CENSUS-EVIDENCE][SNAPSHOT] "
            f"path={args.snapshot_out}"
        )
        return 0
    try:
        return assemble_current_evidence()
    except RuntimeError as exc:
        print(f"[V8L-CENSUS-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
