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

DEFAULT_RUN_ID = "2026-07-20-rv64-v8u-dual-memory-sustained-issue"
MUTATIONS = set(arch.DUAL_MEMORY_MUTATION_NAMES)
MUTATION_SOURCE_PATHS = {
    "backend_next_requires_response_fire":
        "npc/rv64/vsrc/execute/OooIntBackend.v",
    "backend_turnover_accepts_partial":
        "npc/rv64/vsrc/execute/OooIntBackend.v",
    "backend_peek_dequeue_without_capture":
        "npc/rv64/vsrc/execute/OooIntBackend.v",
    "bridge_station_query_requires_ready":
        "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "bridge_station_lookup_ignores_ready":
        "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "iq_pair_pop_only_entry0":
        "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "iq_pair_exposes_regular_issue1":
        "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
}
MUTATION_TESTS = {
    "backend_next_requires_response_fire": "tb_ooo_int_backend",
    "backend_turnover_accepts_partial": "tb_ooo_int_backend",
    "backend_peek_dequeue_without_capture": "tb_ooo_int_backend",
    "bridge_station_query_requires_ready": "tb_ooo_mem_axi_bridge",
    "bridge_station_lookup_ignores_ready": "tb_ooo_mem_axi_bridge",
    "iq_pair_pop_only_entry0": "tb_ooo_int_issue_queue",
    "iq_pair_exposes_regular_issue1": "tb_ooo_int_issue_queue",
}
MUTATION_ORACLES = {
    "backend_next_requires_response_fire":
        "V8U held response keeps B next-head exact",
    "backend_turnover_accepts_partial":
        "V8U partial consume forbids turnover",
    "backend_peek_dequeue_without_capture":
        "V8U partial consume withholds IQ pop2 ready",
    "bridge_station_query_requires_ready":
        "F4 stalled B station query remains valid",
    "bridge_station_lookup_ignores_ready":
        "[V8U-SQ-LOOKAHEAD-READY] station lookup fired without current "
        "response advance",
    "iq_pair_pop_only_entry0":
        "V8U pair peek atomically drains both entries",
    "iq_pair_exposes_regular_issue1":
        "V8U pair peek suppresses regular issue1",
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
) -> dict[str, dict[str, str]]:
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

    rows: list[list[str]] = []
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
    return {
        row[0]: {
            "role": row[1],
            "compile_status": row[2],
            "rejection": row[3],
            "cone": row[4],
            "source_sha256": row[5],
            "image_sha256": row[6],
            "dynamic_rc": row[7],
        }
        for row in rows
    }


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


def task_run_evidence_rel(task_run_id: str, suffix: str) -> pathlib.Path:
    if not re.fullmatch(
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}-rv64-[a-z0-9][a-z0-9._-]*",
        task_run_id,
    ):
        raise ValueError("malformed local RV64 DI-5 task-run id")
    return pathlib.Path(".github/task-runs") / task_run_id / "evidence" / suffix


def resolve_exact_input(
    root: pathlib.Path, value: pathlib.Path, expected_rel: pathlib.Path,
) -> pathlib.Path:
    expected = (root / expected_rel).resolve(strict=True)
    actual = value.resolve(strict=True)
    if actual != expected:
        raise ValueError(
            f"input path mismatch: expected {expected_rel.as_posix()}, got {value}")
    if not actual.is_relative_to(root) or not actual.is_file():
        raise ValueError(f"input is not a workspace file: {value}")
    return actual


def validate_simulator_config(path: pathlib.Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    expected_prefix = [
        "schema=rv64-di5-simulator-config-v1",
        "target=v8u-dual-memory-sustained-issue",
        "tb_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon "
        "-DOOO_ASSERT",
        "mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include "
        "-Icommon -DOOO_ASSERT",
        "verilator_flags=--lint-only --timing -Wall -Wno-fatal -DOOO_ASSERT",
    ]
    if len(lines) != 8 or lines[:5] != expected_prefix:
        raise ValueError("DI-5 simulator/config receipt is malformed")
    result = {
        "schema": "rv64-di5-simulator-config-v1",
        "target": "v8u-dual-memory-sustained-issue",
    }
    for expected_role, line in zip(("iverilog", "vvp", "verilator"), lines[5:]):
        fields = line.split(maxsplit=2)
        if (
            len(fields) != 3
            or fields[0] != expected_role
            or not arch.is_sha256(fields[1])
        ):
            raise ValueError(f"DI-5 {expected_role} receipt is malformed")
        binary = pathlib.Path(fields[2]).resolve(strict=True)
        if not binary.is_file() or arch.digest(binary) != fields[1]:
            raise ValueError(f"DI-5 {expected_role} binary digest is stale")
        result[f"{expected_role}_path"] = binary.as_posix()
        result[f"{expected_role}_sha256"] = fields[1]
    return result


def read_key_value_receipt(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, separator, value = line.partition("=")
        if not separator or not key or key in result:
            raise ValueError(f"{path}: malformed or duplicate receipt field")
        result[key] = value
    return result


def validate_task_run_mutations(
    root: pathlib.Path,
    mutation_rel: pathlib.Path,
    rows: dict[str, dict[str, str]],
) -> dict[str, pathlib.Path]:
    proof_paths: dict[str, pathlib.Path] = {}
    baseline_result = arch.safe_artifact(
        root, (mutation_rel / "baseline/result.log").as_posix())
    baseline_verilator = arch.safe_artifact(
        root, (mutation_rel / "baseline/verilator.log").as_posix())
    if "%Warning-UNOPTFLAT" in baseline_verilator.read_text(encoding="utf-8"):
        raise ValueError("task-run baseline recreated an UNOPTFLAT cone")
    feedback_verilator = arch.safe_artifact(
        root,
        (mutation_rel / "backend_next_requires_response_fire/verilator.log")
        .as_posix(),
    )
    if "%Warning-UNOPTFLAT" not in feedback_verilator.read_text(
        encoding="utf-8"
    ):
        raise ValueError("task-run feedback mutation did not recreate UNOPTFLAT")
    proof_paths.update({
        "baseline_cone_result": baseline_result,
        "baseline_verilator_log": baseline_verilator,
        "feedback_verilator_log": feedback_verilator,
    })

    expected_receipt_fields = {
        "schema", "name", "role", "test", "source_sha256",
        "mutant_sha256", "image_sha256", "compile_success",
        "elaborated", "dynamic_rc", "oracle", "cone",
    }
    for name in arch.DUAL_MEMORY_MUTATION_NAMES:
        base = mutation_rel / name
        activation = arch.safe_artifact(
            root, (base / "activation.json").as_posix())
        receipt_path = arch.safe_artifact(
            root, (base / "compile-receipt.txt").as_posix())
        mutator_log = arch.safe_artifact(
            root, (base / "mutator.log").as_posix())
        simulation = arch.safe_artifact(
            root,
            (base / "logs" / f"{MUTATION_TESTS[name]}.log").as_posix(),
        )
        payload = json.loads(activation.read_text(encoding="utf-8"))
        if payload != {
            "activated": True,
            "anchor_count": 1,
            "mutation": name,
            "schema_version": 1,
            "source_name": pathlib.PurePosixPath(
                MUTATION_SOURCE_PATHS[name]).name,
        }:
            raise ValueError(f"{name}: activation receipt mismatch")
        mutator_text = mutator_log.read_text(encoding="utf-8")
        if (
            mutator_text.count(
                f"[V8U-F4-MUTATOR][PASS] name={name} ") != 1
            or " anchors=1" not in mutator_text
        ):
            raise ValueError(f"{name}: mutator activation marker mismatch")

        receipt = read_key_value_receipt(receipt_path)
        if set(receipt) != expected_receipt_fields:
            raise ValueError(f"{name}: compile receipt inventory mismatch")
        row = rows[name]
        expected_cone = (
            "unoptflat_recreated"
            if name == "backend_next_requires_response_fire"
            else "not_required"
        )
        live_source = arch.safe_artifact(root, MUTATION_SOURCE_PATHS[name])
        if (
            receipt["schema"] != "rv64-di5-mutation-receipt-v1"
            or receipt["name"] != name
            or receipt["role"] != row["role"]
            or receipt["test"] != MUTATION_TESTS[name]
            or receipt["source_sha256"] != arch.digest(live_source)
            or receipt["source_sha256"] != row["source_sha256"]
            or not arch.is_sha256(receipt["mutant_sha256"])
            or receipt["mutant_sha256"] == receipt["source_sha256"]
            or receipt["image_sha256"] != row["image_sha256"]
            or receipt["compile_success"] != "1"
            or receipt["elaborated"] != "1"
            or receipt["dynamic_rc"] != row["dynamic_rc"]
            or int(receipt["dynamic_rc"]) == 0
            or receipt["oracle"] != MUTATION_ORACLES[name]
            or receipt["cone"] != expected_cone
        ):
            raise ValueError(f"{name}: compile/source/image receipt mismatch")
        simulation_text = simulation.read_text(encoding="utf-8")
        if (
            simulation_text.count(MUTATION_ORACLES[name]) < 1
            or simulation_text.count("[RESULT] FAIL") != 1
            or "[RESULT] PASS" in simulation_text
        ):
            raise ValueError(f"{name}: dynamic semantic rejection mismatch")
        proof_paths.update({
            f"activation_{name}": activation,
            f"receipt_{name}": receipt_path,
            f"mutator_{name}": mutator_log,
            f"simulation_{name}": simulation,
        })
    return proof_paths


def read_frozen_source_manifest(
    root: pathlib.Path,
    path: pathlib.Path,
    allowed_drift_paths: set[str],
) -> tuple[dict[str, str], set[str]]:
    entries: dict[str, str] = {}
    drift: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        fields = line.split(maxsplit=1)
        if len(fields) != 2 or not arch.is_sha256(fields[0]):
            raise ValueError(f"invalid frozen source record: {line!r}")
        expected_sha, raw_path = fields
        candidate = pathlib.Path(raw_path.lstrip("*"))
        candidate = candidate if candidate.is_absolute() else root / candidate
        resolved = candidate.resolve(strict=True)
        if not resolved.is_relative_to(root) or not resolved.is_file():
            raise ValueError(f"frozen source escapes workspace: {raw_path}")
        rel = resolved.relative_to(root).as_posix()
        previous = entries.get(rel)
        if previous is not None and previous != expected_sha:
            raise ValueError(f"conflicting frozen source hash: {rel}")
        entries[rel] = expected_sha
        if arch.digest(resolved) != expected_sha:
            if rel not in allowed_drift_paths:
                raise ValueError(
                    f"non-authorized F2 replay source drift: {rel}")
            drift.add(rel)
    if not entries:
        raise ValueError("frozen F2 source manifest is empty")
    return entries, drift


def validate_f2_replay(
    root: pathlib.Path,
    source_sha: str,
    origin_path: pathlib.Path,
    source_architecture_manifest: pathlib.Path,
    f1_current_result: pathlib.Path,
    f1_current_sources_pre: pathlib.Path,
    f1_current_sources_post: pathlib.Path,
    f1_current_mutation_summary: pathlib.Path,
    f1_current_profile_summary: pathlib.Path,
    f1_current_final: pathlib.Path,
    result_path: pathlib.Path,
    sources_pre: pathlib.Path,
    sources_post: pathlib.Path,
    mutation_summary: pathlib.Path,
) -> dict[str, Any]:
    origin = json.loads(origin_path.read_text(encoding="utf-8"))
    expected_artifacts = {
        "source_architecture_manifest": source_architecture_manifest,
        "f1_current_result": f1_current_result,
        "f1_current_sources_pre": f1_current_sources_pre,
        "f1_current_sources_post": f1_current_sources_post,
        "f1_current_mutation_summary": f1_current_mutation_summary,
        "f1_current_profile_summary": f1_current_profile_summary,
        "f1_current_final": f1_current_final,
        "result": result_path,
        "sources_pre": sources_pre,
        "sources_post": sources_post,
        "mutation_summary": mutation_summary,
    }
    source_task_run_id = origin.get("source_task_run_id")
    f1_current_task_run_id = origin.get("f1_current_task_run_id")
    allowed_drift = {
        ".github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/"
        "evidence/focused/result.json",
        "npc/rv64/Makefile",
        "npc/rv64/testbench/Makefile",
        "npc/rv64/design/arch/producer-holder-census.json",
        "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    }
    if (
        origin.get("schema") != "rv64-di5-f2-frozen-replay-v1"
        or not isinstance(source_task_run_id, str)
        or f1_current_task_run_id
        != "2026-07-20-rv64-v8r-dual-memory-bridge-wrapper"
        or origin.get("source_design_id") != f"sha256:{source_sha}"
        or set(origin.get("allowed_drift_paths", [])) != allowed_drift
        or set(origin.get("artifacts", {})) != set(expected_artifacts)
    ):
        raise ValueError("F2 replay origin contract mismatch")
    source_prefix = f".github/task-runs/{source_task_run_id}/evidence/"
    f1_prefix = (
        f".github/task-runs/{f1_current_task_run_id}/evidence/focused/"
    )
    for role, local_path in expected_artifacts.items():
        item = origin["artifacts"][role]
        expected_prefix = f1_prefix if role.startswith("f1_current_") else source_prefix
        if (
            not isinstance(item, dict)
            or not isinstance(item.get("path"), str)
            or not item["path"].startswith(expected_prefix)
            or not arch.is_sha256(item.get("sha256"))
            or arch.digest(local_path) != item["sha256"]
            or arch.digest(arch.safe_artifact(root, item["path"]))
            != item["sha256"]
        ):
            raise ValueError(f"F2 replay origin/hash mismatch: {role}")

    source_architecture = json.loads(
        source_architecture_manifest.read_text(encoding="utf-8"))
    if source_architecture.get("design_id") != f"sha256:{source_sha}":
        raise ValueError("F2 replay source architecture design-id is stale")
    if sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("frozen F2 source manifests differ")
    frozen_sources, drift = read_frozen_source_manifest(
        root, sources_pre, allowed_drift)
    if drift - allowed_drift:
        raise ValueError("F2 replay contains unauthorized source drift")

    if f1_current_sources_pre.read_bytes() != f1_current_sources_post.read_bytes():
        raise ValueError("current F1 source manifests differ")
    f1_allowed_drift = allowed_drift - {
        ".github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/"
        "evidence/focused/result.json",
    }
    _, f1_drift = read_frozen_source_manifest(
        root,
        f1_current_sources_pre,
        f1_allowed_drift,
    )
    if f1_drift - f1_allowed_drift:
        raise ValueError("current F1 replay contains unauthorized source drift")
    f1_result = read_predecessor(f1_current_result, "F1")
    if f1_result.get("source_closure_sha256") != arch.digest(
        f1_current_sources_pre
    ):
        raise ValueError("current F1 source-closure digest mismatch")
    f1_rtl = f1_result.get("rtl_sha256")
    expected_f1_rtl = {
        "bridge": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "dcache": "npc/rv64/vsrc/cache/OooDataWordCache.v",
        "wrapper": "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
    }
    if not isinstance(f1_rtl, dict) or any(
        f1_rtl.get(role) != arch.digest(arch.safe_artifact(root, rel))
        for role, rel in expected_f1_rtl.items()
    ):
        raise ValueError("current F1 selected RTL hashes are stale")
    f1_run_id = f1_result.get("run_id")
    f1_mutations = re.findall(
        r"^\[V8R-MUTATION\]\[PASS\] run_id=([^ ]+) name=([^ ]+) "
        r"compile_success=true elaborated=true activated=true "
        r"target_rejected=true ",
        f1_current_mutation_summary.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    if (
        len(f1_mutations) != 10
        or len({name for _, name in f1_mutations}) != 10
        or {run_id for run_id, _ in f1_mutations} != {f1_run_id}
    ):
        raise ValueError("current F1 mutation summary is incomplete")
    f1_profiles = re.findall(
        r"^\[V8R-PROFILE\]\[PASS\] run_id=([^ ]+) profile=([^ ]+) ",
        f1_current_profile_summary.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    expected_f1_profiles = {
        "wrapper-release", "wrapper-assert", "dcache-release",
        "dcache-assert", "bridge-release", "bridge-assert",
        "dcache-invalid-mask", "wrapper-mmu-nonidle",
    }
    if (
        len(f1_profiles) != len(expected_f1_profiles)
        or {profile for _, profile in f1_profiles} != expected_f1_profiles
        or {run_id for run_id, _ in f1_profiles} != {f1_run_id}
    ):
        raise ValueError("current F1 profile summary is incomplete")
    expected_f1_final = (
        f"[V8R-F1][PASS] run_id={f1_run_id} "
        "claim=dual_bridge_cache_hit_leaf_verified mutations=10 "
        "architecture=RED ppa=UNQUALIFIED canonical_stage=F2_PROMOTED "
        "canonical_core_integration=true"
    )
    if f1_current_final.read_text(encoding="utf-8").count(
        expected_f1_final
    ) != 1:
        raise ValueError("current F1 terminal marker is missing")

    result = read_predecessor(result_path, "F2")
    if result.get("source_closure_sha256") != arch.digest(sources_pre):
        raise ValueError("F2 replay source-closure digest mismatch")
    rtl_sha = result.get("rtl_sha256")
    expected_rtl = {
        "backend": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "canonical_core": "npc/rv64/vsrc/core/NpcCoreTop.v",
        "core_slice_control_gate":
            "npc/rv64/vsrc/control/OooCoreSliceControlGate.v",
    }
    if not isinstance(rtl_sha, dict) or any(
        rtl_sha.get(role) != arch.digest(arch.safe_artifact(root, rel))
        for role, rel in expected_rtl.items()
    ):
        raise ValueError("F2 replay selected RTL hashes are stale")
    if (
        result.get("tb_sha256") != arch.digest(arch.safe_artifact(
            root, "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"))
        or result.get("core_glue_tb_sha256") != arch.digest(
            arch.safe_artifact(
                root, "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"))
    ):
        raise ValueError("F2 replay testbench hashes are stale")
    mutation_text = mutation_summary.read_text(encoding="utf-8")
    mutation_rows = re.findall(
        r"^\[V8S-MUTATION\]\[PASS\] run_id=([^ ]+) name=([^ ]+) "
        r"compile_success=true elaborated=true activated=true "
        r"target_rejected=true ",
        mutation_text,
        flags=re.MULTILINE,
    )
    if (
        len(mutation_rows) != 18
        or len({name for _, name in mutation_rows}) != 18
        or {run_id for run_id, _ in mutation_rows} != {result.get("run_id")}
    ):
        raise ValueError("F2 replay mutation summary is incomplete")
    result["replay_source_entries"] = len(frozen_sources)
    result["replay_allowed_drift"] = sorted(drift)
    return result


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
    parser.add_argument("--f0-result", type=pathlib.Path)
    parser.add_argument("--f1-result", type=pathlib.Path)
    parser.add_argument("--f2-result", required=True, type=pathlib.Path)
    parser.add_argument("--sources-pre", required=True, type=pathlib.Path)
    parser.add_argument("--sources-post", required=True, type=pathlib.Path)
    parser.add_argument("--gate-log", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    parser.add_argument(
        "--proof-mode",
        choices=("canonical-v8u", "task-run-v1"),
        default="canonical-v8u",
    )
    parser.add_argument("--task-run-id", default=DEFAULT_RUN_ID)
    parser.add_argument("--simulator-config", type=pathlib.Path)
    parser.add_argument("--f2-replay-origin", type=pathlib.Path)
    parser.add_argument(
        "--f2-source-architecture-manifest", type=pathlib.Path)
    parser.add_argument("--f2-sources-pre", type=pathlib.Path)
    parser.add_argument("--f2-sources-post", type=pathlib.Path)
    parser.add_argument("--f2-mutation-summary", type=pathlib.Path)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    task_run_mode = args.proof_mode == "task-run-v1"
    task_run_id = args.task_run_id
    source_sha, rtl_files = arch.rtl_binding(root)
    simulator_config: pathlib.Path | None = None
    mutation_rel: pathlib.Path | None = None
    f2_replay_origin: pathlib.Path | None = None
    f2_source_architecture_manifest: pathlib.Path | None = None
    f1_current_result: pathlib.Path | None = None
    f1_current_sources_pre: pathlib.Path | None = None
    f1_current_sources_post: pathlib.Path | None = None
    f1_current_mutation_summary: pathlib.Path | None = None
    f1_current_profile_summary: pathlib.Path | None = None
    f1_current_final: pathlib.Path | None = None
    f2_sources_pre: pathlib.Path | None = None
    f2_sources_post: pathlib.Path | None = None
    f2_mutation_summary: pathlib.Path | None = None
    if task_run_mode:
        evidence_rel = task_run_evidence_rel(task_run_id, "di5-current")
        evidence_root_rel = evidence_rel.parent
        mutation_rel = evidence_root_rel / "di5-mutations"
        system_log = resolve_exact_input(
            root, args.system_log,
            evidence_rel / "system/logs/tb_ooo_dual_memory_sustained_issue.log")
        miq_log = resolve_exact_input(
            root, args.miq_log,
            evidence_rel / "leaf-miq/logs/tb_ooo_mem_inflight_queue.log")
        iq_log = resolve_exact_input(
            root, args.iq_log,
            evidence_rel / "leaf-iq/logs/tb_ooo_int_issue_queue.log")
        bridge_log = resolve_exact_input(
            root, args.bridge_log,
            evidence_rel / "leaf-bridge/logs/tb_ooo_mem_axi_bridge.log")
        backend_log = resolve_exact_input(
            root, args.backend_log,
            evidence_rel / "leaf-backend/logs/tb_ooo_int_backend.log")
        backend_partial_log = resolve_exact_input(
            root, args.backend_partial_log,
            evidence_rel / "backend-partial/logs/tb_ooo_int_backend.log")
        mutation_result = resolve_exact_input(
            root, args.mutation_result, mutation_rel / "result.log")
        mutation_summary = resolve_exact_input(
            root, args.mutation_summary,
            mutation_rel / "mutation-summary.tsv")
        baseline_cone = resolve_exact_input(
            root, args.baseline_cone_result,
            mutation_rel / "baseline/result.log")
        sources_pre = resolve_exact_input(
            root, args.sources_pre, evidence_rel / "sources.pre.sha256")
        sources_post = resolve_exact_input(
            root, args.sources_post, evidence_rel / "sources.post.sha256")
        if args.simulator_config is None:
            raise ValueError("task-run DI-5 proof requires simulator config")
        simulator_config = resolve_exact_input(
            root, args.simulator_config,
            evidence_rel / "static/simulator-config.txt")
        validate_simulator_config(simulator_config)
        replay_rel = evidence_root_rel / "f2-replay"
        replay_args = (
            args.f2_replay_origin,
            args.f2_source_architecture_manifest,
            args.f2_sources_pre,
            args.f2_sources_post,
            args.f2_mutation_summary,
        )
        if any(value is None for value in replay_args):
            raise ValueError("task-run DI-5 proof requires complete F2 replay")
        f2_replay_origin = resolve_exact_input(
            root, args.f2_replay_origin, replay_rel / "origin.json")
        f2_source_architecture_manifest = resolve_exact_input(
            root, args.f2_source_architecture_manifest,
            replay_rel / "source-architecture-current.json")
        f1_current_result = resolve_exact_input(
            root,
            replay_rel / "current-f1-result.json",
            replay_rel / "current-f1-result.json",
        )
        f1_current_sources_pre = resolve_exact_input(
            root,
            replay_rel / "current-f1-sources.pre.sha256",
            replay_rel / "current-f1-sources.pre.sha256",
        )
        f1_current_sources_post = resolve_exact_input(
            root,
            replay_rel / "current-f1-sources.post.sha256",
            replay_rel / "current-f1-sources.post.sha256",
        )
        f1_current_mutation_summary = resolve_exact_input(
            root,
            replay_rel / "current-f1-mutation-summary.log",
            replay_rel / "current-f1-mutation-summary.log",
        )
        f1_current_profile_summary = resolve_exact_input(
            root,
            replay_rel / "current-f1-profile-summary.log",
            replay_rel / "current-f1-profile-summary.log",
        )
        f1_current_final = resolve_exact_input(
            root,
            replay_rel / "current-f1-final.log",
            replay_rel / "current-f1-final.log",
        )
        f2_result = resolve_exact_input(
            root, args.f2_result, replay_rel / "result.json")
        f2_sources_pre = resolve_exact_input(
            root, args.f2_sources_pre, replay_rel / "sources.pre.sha256")
        f2_sources_post = resolve_exact_input(
            root, args.f2_sources_post, replay_rel / "sources.post.sha256")
        f2_mutation_summary = resolve_exact_input(
            root, args.f2_mutation_summary,
            replay_rel / "mutation-summary.log")
        expected_manifest = (
            root / evidence_root_rel / "architecture-current.json").resolve()
        expected_gate_log = (
            root / evidence_root_rel / "dual-memory-issue.log").resolve()
        if workspace_output(root, args.manifest) != expected_manifest:
            raise ValueError("scoped DI-5 manifest path mismatch")
        if workspace_output(root, args.gate_log) != expected_gate_log:
            raise ValueError("scoped DI-5 gate-log path mismatch")
        if expected_manifest.exists():
            raise ValueError("scoped DI-5 manifest must start absent")
        f0_result = None
        f1_result = None
    else:
        if args.f0_result is None or args.f1_result is None:
            raise ValueError("canonical DI-5 proof requires F0 and F1 results")
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
    mutation_rows = read_mutations(
        mutation_result, mutation_summary, baseline_cone)
    task_mutation_proofs: dict[str, pathlib.Path] = {}
    if task_run_mode:
        assert mutation_rel is not None
        task_mutation_proofs = validate_task_run_mutations(
            root, mutation_rel, mutation_rows)
        assert f2_replay_origin is not None
        assert f2_source_architecture_manifest is not None
        assert f1_current_result is not None
        assert f1_current_sources_pre is not None
        assert f1_current_sources_post is not None
        assert f1_current_mutation_summary is not None
        assert f1_current_profile_summary is not None
        assert f1_current_final is not None
        assert f2_sources_pre is not None
        assert f2_sources_post is not None
        assert f2_mutation_summary is not None
        predecessors = {
            "F2_REPLAY": validate_f2_replay(
                root,
                source_sha,
                f2_replay_origin,
                f2_source_architecture_manifest,
                f1_current_result,
                f1_current_sources_pre,
                f1_current_sources_post,
                f1_current_mutation_summary,
                f1_current_profile_summary,
                f1_current_final,
                f2_result,
                f2_sources_pre,
                f2_sources_post,
                f2_mutation_summary,
            ),
        }
    else:
        assert f0_result is not None and f1_result is not None
        predecessors = {
            "F0": read_predecessor(f0_result, "F0"),
            "F1": read_predecessor(f1_result, "F1"),
            "F2": read_predecessor(f2_result, "F2"),
        }
    if sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical F4 proof sources changed during execution")
    if task_run_mode:
        pre_sources = arch.validate_source_manifest(
            root, sources_pre, arch.DUAL_MEMORY_SOURCE_PATHS)
        post_sources = arch.validate_source_manifest(
            root, sources_post, arch.DUAL_MEMORY_SOURCE_PATHS)
        if pre_sources != post_sources:
            raise ValueError("current DI-5 proof source maps differ")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    provenance_paths = (
        arch.DUAL_MEMORY_SOURCE_PATHS
        if task_run_mode else arch.DUAL_MEMORY_PROVENANCE_PATHS
    )
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in provenance_paths
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    proof_paths: dict[str, pathlib.Path] = {
        "system": system_log,
        "miq": miq_log,
        "iq": iq_log,
        "bridge": bridge_log,
        "backend": backend_log,
        "backend_partial": backend_partial_log,
        "mutation_result": mutation_result,
        "mutation_summary": mutation_summary,
        "sources_pre": sources_pre,
        "sources_post": sources_post,
    }
    if task_run_mode:
        assert simulator_config is not None
        assert f2_replay_origin is not None
        assert f2_source_architecture_manifest is not None
        assert f1_current_result is not None
        assert f1_current_sources_pre is not None
        assert f1_current_sources_post is not None
        assert f1_current_mutation_summary is not None
        assert f1_current_profile_summary is not None
        assert f1_current_final is not None
        assert f2_sources_pre is not None
        assert f2_sources_post is not None
        assert f2_mutation_summary is not None
        proof_paths.update(task_mutation_proofs)
        proof_paths.update({
            "simulator_config": simulator_config,
            "f2_replay_origin": f2_replay_origin,
            "f2_source_architecture_manifest":
                f2_source_architecture_manifest,
            "f1_current_result": f1_current_result,
            "f1_current_sources_pre": f1_current_sources_pre,
            "f1_current_sources_post": f1_current_sources_post,
            "f1_current_mutation_summary": f1_current_mutation_summary,
            "f1_current_profile_summary": f1_current_profile_summary,
            "f1_current_final": f1_current_final,
            "f2_result": f2_result,
            "f2_sources_pre": f2_sources_pre,
            "f2_sources_post": f2_sources_post,
            "f2_mutation_summary": f2_mutation_summary,
        })
        if set(proof_paths) != set(arch.DUAL_MEMORY_TASK_RUN_PROOF_ROLES):
            raise ValueError("scoped DI-5 proof role inventory mismatch")
    else:
        assert f0_result is not None and f1_result is not None
        proof_paths.update({
            "baseline_cone_result": baseline_cone,
            "f0_result": f0_result,
            "f1_result": f1_result,
            "f2_result": f2_result,
        })
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths.values() if path.is_relative_to(root)
    }
    proof_files = {
        role: {
            "path": path.relative_to(root).as_posix(),
            "sha256": arch.digest(path),
        }
        for role, path in proof_paths.items()
    }
    proof_digest_map = {
        role: f"{item['path']}:{item['sha256']}"
        for role, item in proof_files.items()
    }

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "DI-5 sustained dual-memory issue evidence",
        f"task_run_id={task_run_id}",
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
        (
            "predecessors=F2_FROZEN_REPLAY_PASS,F1_EMBEDDED_PASS"
            if task_run_mode else "predecessors=F0_PASS,F1_PASS,F2_PASS"
        ),
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
        f"task_run_id={task_run_id} design_id=sha256:{source_sha} "
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
            **({
                "mode": "task-run-v1",
                "proof_files": proof_files,
                "proof_sha256": arch.canonical_digest(proof_digest_map),
            } if task_run_mode else {}),
        },
        "task_run_id": task_run_id,
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
