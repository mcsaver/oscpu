#!/usr/bin/env python3
"""Build hash-bound DI-5 sustained dual-memory issue evidence."""

from __future__ import annotations

import argparse
import datetime
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any

from directed_evidence_manifest import merge_directed_record


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

RUN_ID = "2026-07-20-rv64-v8u-dual-memory-sustained-issue"
MUTATIONS = {
    "backend_next_requires_response_fire",
    "backend_turnover_accepts_partial",
    "backend_peek_dequeue_without_capture",
    "bridge_station_query_requires_ready",
    "bridge_station_lookup_ignores_ready",
    "iq_pair_pop_only_entry0",
    "iq_pair_exposes_regular_issue1",
}
METRIC_RE = re.compile(
    r"^\[V8U-DI5-METRIC\] trace_cycles=(\d+) "
    r"memory_issue_ipc_milli=(\d+) dual_issue_cycles=(\d+) "
    r"agu_accepts=(\d+),(\d+) translation_accepts=(\d+),(\d+) "
    r"physical_lsq_queries=(\d+),(\d+) "
    r"cache_admissions=(\d+),(\d+) completions=(\d+),(\d+)$",
    flags=re.MULTILINE,
)
CYCLE_RE = re.compile(
    r"^\[V8U-DI5-CYCLE\] index=(\d+) agu=(\d\d) "
    r"translation=(\d\d) query=(\d\d) cache=(\d\d) "
    r"completion=(\d\d)$",
    flags=re.MULTILINE,
)
PIPE_RE = re.compile(
    r"^\[V8U-DI5-PIPE\] index=(\d+) fetch=1/1 dispatch=11/1 "
    r"iq=00 res=(\d\d) capture=(\d\d) consume=(\d\d) turnover=(\d)$",
    flags=re.MULTILINE,
)
GRANT_RE = re.compile(
    r"^\[V8U-DI5-GRANT\] index=(\d+) candidate=11 selected=11 "
    r"bank=10 slot=11 bridge_ready=(\d\d) grant=(\d\d) "
    r"miq_count=2,2 bridge_load=(\d\d)/(\d\d)$",
    flags=re.MULTILINE,
)


def clean_simulation(path: pathlib.Path) -> str:
    text = path.read_text(encoding="utf-8")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{path}: unexpected failure marker {marker}")
    return text


def exact_steady_rows(
    rows: list[tuple[str, ...]],
    *,
    expected_payload: tuple[str, ...],
    label: str,
) -> None:
    indices = [int(row[0]) for row in rows]
    if indices != list(range(64)):
        raise ValueError(f"{label}: cycle indices are not exactly 0..63")
    if any(tuple(row[1:]) != expected_payload for row in rows):
        raise ValueError(f"{label}: a steady-state face was not dual-active")


def read_system(path: pathlib.Path) -> dict[str, Any]:
    text = clean_simulation(path)
    metrics = METRIC_RE.findall(text)
    if len(metrics) != 1:
        raise ValueError(f"{path}: unique DI-5 metric row missing")
    values = [int(value) for value in metrics[0]]
    names = (
        "trace_cycles", "memory_issue_ipc_milli", "dual_issue_cycles",
        "agu0", "agu1", "translation0", "translation1",
        "physical0", "physical1", "cache0", "cache1",
        "completion0", "completion1",
    )
    raw = dict(zip(names, values, strict=True))
    expected = {
        "trace_cycles": 64,
        "memory_issue_ipc_milli": 2000,
        "dual_issue_cycles": 64,
        "agu0": 64,
        "agu1": 64,
        "translation0": 64,
        "translation1": 64,
        "physical0": 64,
        "physical1": 64,
        "cache0": 64,
        "cache1": 64,
        "completion0": 64,
        "completion1": 64,
    }
    if raw != expected:
        raise ValueError(f"{path}: exact steady-state metrics mismatch: {raw}")

    exact_steady_rows(
        CYCLE_RE.findall(text),
        expected_payload=("11", "11", "11", "11", "11"),
        label="cycle trace",
    )
    exact_steady_rows(
        PIPE_RE.findall(text),
        expected_payload=("11", "11", "11", "1"),
        label="pipeline trace",
    )
    exact_steady_rows(
        GRANT_RE.findall(text),
        expected_payload=("11", "11", "11", "11"),
        label="grant trace",
    )
    return {
        "trace_cycles": raw["trace_cycles"],
        "memory_issue_ipc": raw["memory_issue_ipc_milli"] / 1000.0,
        "dual_issue_cycles": raw["dual_issue_cycles"],
        "agu_accepts": [raw["agu0"], raw["agu1"]],
        "translation_accepts": [raw["translation0"], raw["translation1"]],
        "physical_lsq_queries": [raw["physical0"], raw["physical1"]],
        "cache_admissions": [raw["cache0"], raw["cache1"]],
        "completions": [raw["completion0"], raw["completion1"]],
        "steady_cycle_rows": 64,
        "steady_pipeline_rows": 64,
        "steady_grant_rows": 64,
    }


def require_marker(path: pathlib.Path, marker: str) -> None:
    text = clean_simulation(path)
    if text.count(marker) != 1:
        raise ValueError(f"{path}: expected unique marker {marker}")


def read_mutations(
    result_path: pathlib.Path,
    summary_path: pathlib.Path,
    baseline_path: pathlib.Path,
) -> None:
    result = result_path.read_text(encoding="utf-8")
    expected_result = (
        "[V8U-F4-MUTATION][PASS] compile_success=7 dynamic_rejections=7 "
        "feedback_scc_recreated=1 baseline_unoptflat=0"
    )
    if result.count(expected_result) != 1:
        raise ValueError("mutation aggregate PASS marker missing")
    baseline = baseline_path.read_text(encoding="utf-8")
    if baseline.strip() != (
        "[V8U-F4-CONE][PASS] baseline NpcCoreTop has no UNOPTFLAT"
    ):
        raise ValueError("baseline full-core combinational-cone proof missing")

    rows = []
    for line in summary_path.read_text(encoding="utf-8").splitlines():
        fields = line.split("|")
        if len(fields) != 8:
            raise ValueError(f"malformed mutation summary row: {line}")
        rows.append(fields)
    if len(rows) != len(MUTATIONS) or {row[0] for row in rows} != MUTATIONS:
        raise ValueError("mutation identity set mismatch")
    for row in rows:
        name, role, compile_status, rejection, cone, source_sha, image_sha, rc = row
        if role not in {"backend", "bridge", "iq"}:
            raise ValueError(f"{name}: unknown RTL mutation role")
        if compile_status != "compile_success" or rejection != "target_rejected":
            raise ValueError(f"{name}: compile/rejection status mismatch")
        expected_cone = (
            "unoptflat_recreated"
            if name == "backend_next_requires_response_fire"
            else "not_required"
        )
        if cone != expected_cone:
            raise ValueError(f"{name}: combinational-cone status mismatch")
        if not arch.is_sha256(source_sha) or not arch.is_sha256(image_sha):
            raise ValueError(f"{name}: source/image digest missing")
        if int(rc) == 0:
            raise ValueError(f"{name}: mutation oracle returned success")


def read_predecessor(path: pathlib.Path, stage: str) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("status") != "PASS":
        raise ValueError(f"{path}: predecessor status is not PASS")
    if payload.get("canonical_architecture_manifest_modified") is not False:
        raise ValueError(f"{path}: predecessor rewrote architecture manifest")
    expected_claim = {
        "F0": "dual_axi_miss_fabric_leaf_verified",
        "F1": "dual_bridge_cache_hit_leaf_verified",
        "F2": "architecture_checkpoint",
    }[stage]
    if payload.get("claim") != expected_claim:
        raise ValueError(f"{path}: predecessor claim mismatch")
    mutations = payload.get("mutations")
    expected_mutations = {"F0": 12, "F1": 10, "F2": 18}[stage]
    if not isinstance(mutations, dict) or mutations.get("detected") != expected_mutations:
        raise ValueError(f"{path}: predecessor mutation coverage mismatch")
    if stage == "F1" and (
        payload.get("canonical_stage") != "F2_PROMOTED"
        or payload.get("canonical_core_integration") is not True
    ):
        raise ValueError(f"{path}: F1-to-F2 handoff mismatch")
    if stage == "F2":
        handoff = payload.get("f1_permanent_target")
        if not isinstance(handoff, dict) or handoff.get("status") != "PASS":
            raise ValueError(f"{path}: F2 predecessor handoff missing")
    return payload


def workspace_output(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"output escapes repository: {value}")
    if path.exists() and path.is_symlink():
        raise ValueError(f"output traverses symlink: {value}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--system-log", required=True, type=pathlib.Path)
    parser.add_argument("--miq-log", required=True, type=pathlib.Path)
    parser.add_argument("--iq-log", required=True, type=pathlib.Path)
    parser.add_argument("--bridge-log", required=True, type=pathlib.Path)
    parser.add_argument("--backend-log", required=True, type=pathlib.Path)
    parser.add_argument("--backend-partial-log", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-result", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    parser.add_argument("--baseline-cone-result", required=True, type=pathlib.Path)
    parser.add_argument("--f0-result", required=True, type=pathlib.Path)
    parser.add_argument("--f1-result", required=True, type=pathlib.Path)
    parser.add_argument("--f2-result", required=True, type=pathlib.Path)
    parser.add_argument("--sources-pre", required=True, type=pathlib.Path)
    parser.add_argument("--sources-post", required=True, type=pathlib.Path)
    parser.add_argument("--gate-log", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    system_log = args.system_log.resolve(strict=True)
    miq_log = args.miq_log.resolve(strict=True)
    iq_log = args.iq_log.resolve(strict=True)
    bridge_log = args.bridge_log.resolve(strict=True)
    backend_log = args.backend_log.resolve(strict=True)
    backend_partial_log = args.backend_partial_log.resolve(strict=True)
    mutation_result = args.mutation_result.resolve(strict=True)
    mutation_summary = args.mutation_summary.resolve(strict=True)
    baseline_cone = args.baseline_cone_result.resolve(strict=True)
    f0_result = args.f0_result.resolve(strict=True)
    f1_result = args.f1_result.resolve(strict=True)
    f2_result = args.f2_result.resolve(strict=True)
    sources_pre = args.sources_pre.resolve(strict=True)
    sources_post = args.sources_post.resolve(strict=True)

    metrics = read_system(system_log)
    require_marker(
        miq_log,
        "[V8U-MIQ-NEXT-HEAD] exact current/next, wrap and effective-kill PASS",
    )
    require_marker(
        iq_log,
        "[V8U-IQ-PAIR-PEEK] q_only_payload/ready_hold/atomic_pop2/full_pid PASS",
    )
    require_marker(
        bridge_log,
        "[V8U-F4-BRIDGE-STREAM] A/B/C consecutive hot responses and lookups PASS",
    )
    require_marker(
        backend_partial_log,
        "[V8U-F4-PARTIAL-CONSUME] no_singleton_turnover=1 iq_pop2=0 "
        "old_pair_drains=2 new_pair_capture=1 PASS",
    )
    require_marker(
        backend_partial_log,
        "[V8U-F4-BACKEND-NEXT] no-pop/killed-current fail-closed + "
        "exact A-pop/B-allow PASS",
    )
    clean_simulation(backend_log)
    read_mutations(mutation_result, mutation_summary, baseline_cone)
    predecessors = {
        "F0": read_predecessor(f0_result, "F0"),
        "F1": read_predecessor(f1_result, "F1"),
        "F2": read_predecessor(f2_result, "F2"),
    }
    if sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical F4 proof sources changed during execution")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, rtl_files = arch.rtl_binding(root)
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.DUAL_MEMORY_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    artifact_paths = (
        system_log,
        miq_log,
        iq_log,
        bridge_log,
        backend_log,
        backend_partial_log,
        mutation_result,
        mutation_summary,
        baseline_cone,
        f0_result,
        f1_result,
        f2_result,
        sources_pre,
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in artifact_paths if path.is_relative_to(root)
    }

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "DI-5 sustained dual-memory issue evidence",
        f"run_id={RUN_ID}",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        "steady_trace_cycles=64",
        "memory_issue_ipc_milli=2000",
        "dual_issue_cycles=64",
        "per_bank_agu_translation_query_cache_completion=64,64",
        "reservation_turnover=atomic_pair_only",
        "held_response_query_visible_lookup_blocked=1",
        "baseline_unoptflat=0",
        "compile_success_mutations=7",
        "predecessors=F0_PASS,F1_PASS,F2_PASS",
    ]
    gate_lines.extend(
        f"predecessor_run_id {stage} {payload.get('run_id')}"
        for stage, payload in predecessors.items()
    )
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] dual_memory_issue PASS "
        f"run_id={RUN_ID} design_id=sha256:{source_sha} "
        f"provenance_sha256={provenance_sha}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "command": arch.DUAL_MEMORY_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": metrics,
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": provenance_sha,
        },
        "scope": (
            "DI-5 production NpcCoreTop steady dual-bank ordinary cached-load "
            "issue through AGU, translation, physical SQ query, cache admission "
            "and completion; not OOO-3, overall architecture or PPA promotion"
        ),
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="dual_memory_issue",
        record=record,
    )
    print(
        "[V8U-F4-EVIDENCE][PASS] dual_memory_issue "
        f"design_id=sha256:{source_sha} ipc=2.000 cycles=64 mutations=7"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V8U-F4-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
