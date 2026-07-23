#!/usr/bin/env python3
"""Build fail-closed local RV64 DI-2 width-continuity evidence."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any

from directed_evidence_manifest import merge_directed_record


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

RUN_ID = "2026-07-21-rv64-v9a-width-continuity"
REPO = pathlib.Path(__file__).resolve().parents[5]
MUTATION_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-v9a-mutations.py"
MUTATION_SPEC = importlib.util.spec_from_file_location(
    "v9a_width_mutations", MUTATION_RUNNER)
assert MUTATION_SPEC is not None and MUTATION_SPEC.loader is not None
mutation_model = importlib.util.module_from_spec(MUTATION_SPEC)
sys.modules[MUTATION_SPEC.name] = mutation_model
MUTATION_SPEC.loader.exec_module(mutation_model)

BASE = pathlib.Path(f".github/task-runs/{RUN_ID}/evidence/final-run")
SUITE_RUN_ID_REL = BASE / "suite-run-id.txt"
SOURCE_PRE_REL = BASE / "sources.pre.sha256"
SOURCE_POST_REL = BASE / "sources.post.sha256"
PREDECESSOR_LOG_REL = BASE / "static/same-design-predecessors.log"
MUTATION_SUMMARY_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json")
WIDTH_LOG_RELS = {
    profile: BASE / f"focused/{profile}/logs/"
                    "tb_ooo_core_top_glue_v9a_width_continuity.log"
    for profile in ("assert", "release")
}
STALL_LOG_REL = BASE / "stall-probe/logs/"
STALL_LOG_REL /= "tb_ooo_core_top_glue_v9a_width_stall_probe.log"
REGRESSION_NAMES = arch.WIDTH_CONTINUITY_REGRESSION_NAMES
REGRESSION_RELS = {
    name: BASE / f"regressions/logs/{name}.log"
    for name in REGRESSION_NAMES
}
BOUNDARIES = arch.WIDTH_BOUNDARIES
TRACE_KEYS = (
    "cycle", *BOUNDARIES,
    "fetch_pc0", "fetch_pc1", "issue_pc0", "issue_pc1",
    "retire_pc0", "retire_pc1",
    "issue_pid0", "issue_pid1", "retire_pid0", "retire_pid1",
)
METRIC_KEYS = (
    "trace_cycles", "independent_alu_ipc_milli",
    *(key for boundary in BOUNDARIES for key in (
        f"{boundary}_total", f"{boundary}_peak",
        f"{boundary}_dual_cycles",
    )),
)
REQUIRED_DIMENSIONS = {
    "fetch_identity", "decode_to_backend", "rename_sink",
    "dispatch_width", "rob_sink", "iq_sink", "issue_width",
    "ex_stage_capture", "ex_stage_payload", "execute_width", "wb_sink", "retire_width",
    "payload_data", "pid_lifecycle",
}
ANCHOR_MARKER = (
    "[V9A-DI2-ANCHOR] first_fetch_request_fire warmup_cycles=24")
IDENTITY_RE = re.compile(
    r"^\[V9A-DI2-IDENTITY\] fetched=(\d+) decoded=(\d+) "
    r"renamed=(\d+) dispatched=(\d+) issued=(\d+) executed=(\d+) "
    r"retired=(\d+) active_pid=0 payload_mismatch=0 lifecycle_error=0 PASS$",
    re.MULTILINE,
)
DRAIN_RE = re.compile(
    r"^\[V9A-DI2-DRAIN\] requests=(\d+) responses=(\d+) enqueues=(\d+) "
    r"fifo=0 rob=0 issue=0 ex0=0 ex1=0 free=32 active_pid=0 "
    r"flush=0 PASS$",
    re.MULTILINE,
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def require_once(text: str, marker: str, label: str) -> None:
    if text.count(marker) != 1:
        raise ValueError(f"{label}: expected unique marker {marker}")


def parse_key_value_line(
    line: str, prefix: str, expected_keys: tuple[str, ...], label: str,
) -> dict[str, str]:
    if not line.startswith(prefix + " "):
        raise ValueError(f"{label}: malformed {prefix} line")
    values: dict[str, str] = {}
    for token in line[len(prefix) + 1:].split():
        if token.count("=") != 1:
            raise ValueError(f"{label}: malformed token {token}")
        key, value = token.split("=", 1)
        if key in values:
            raise ValueError(f"{label}: duplicate key {key}")
        values[key] = value
    if tuple(values) != expected_keys:
        raise ValueError(
            f"{label}: key inventory mismatch: {tuple(values)}")
    return values


def metric_line(text: str, label: str) -> dict[str, int]:
    rows = [
        line for line in text.splitlines()
        if line.startswith("[V9A-DI2-METRIC] ")
    ]
    if len(rows) != 1:
        raise ValueError(f"{label}: expected one metric row")
    raw = parse_key_value_line(
        rows[0], "[V9A-DI2-METRIC]", METRIC_KEYS, label)
    try:
        return {key: int(value, 10) for key, value in raw.items()}
    except ValueError as exc:
        raise ValueError(f"{label}: non-integer metric") from exc


def parse_width_text(text: str, label: str) -> dict[str, Any]:
    require_once(text, ANCHOR_MARKER, label)
    require_once(
        text, "[PASS] tb_ooo_core_top_glue_v9a_width_continuity", label)
    require_once(text, "[RESULT] PASS", label)
    for marker in (
        "[RESULT] FAIL", "[V9A-WIDTH][FAIL]", "[V9A-IDENTITY][FAIL]",
        "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:",
    ):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")

    trace_lines = [
        line for line in text.splitlines()
        if line.startswith("[V9A-DI2-TRACE] ")
    ]
    if len(trace_lines) != 64:
        raise ValueError(f"{label}: expected exactly 64 trace rows")
    for cycle, line in enumerate(trace_lines):
        values = parse_key_value_line(
            line, "[V9A-DI2-TRACE]", TRACE_KEYS, label)
        if int(values["cycle"], 10) != cycle:
            raise ValueError(f"{label}: non-canonical trace cycle")
        if any(int(values[name], 10) != 2 for name in BOUNDARIES):
            raise ValueError(f"{label}: trace contains a non-dual boundary")
        for key in TRACE_KEYS[8:]:
            if not re.fullmatch(r"[0-9a-f]+", values[key]):
                raise ValueError(f"{label}: malformed hexadecimal identity {key}")

    metrics = metric_line(text, label)
    if metrics["trace_cycles"] != 64:
        raise ValueError(f"{label}: trace length is not 64")
    if metrics["independent_alu_ipc_milli"] != 2000:
        raise ValueError(f"{label}: independent ALU IPC is not exactly 2.000")
    for boundary in BOUNDARIES:
        if (
            metrics[f"{boundary}_total"] != 128
            or metrics[f"{boundary}_peak"] != 2
            or metrics[f"{boundary}_dual_cycles"] != 64
        ):
            raise ValueError(f"{label}: {boundary} aggregate is not exact dual")

    identities = list(IDENTITY_RE.finditer(text))
    if len(identities) != 1:
        raise ValueError(f"{label}: expected one identity closure row")
    identity_counts = tuple(int(item) for item in identities[0].groups())
    if len(set(identity_counts)) != 1 or identity_counts[0] < 176:
        raise ValueError(f"{label}: full-run boundary identity mismatch")
    drains = list(DRAIN_RE.finditer(text))
    if len(drains) != 1:
        raise ValueError(f"{label}: expected one natural-drain row")
    drain_counts = tuple(int(item) for item in drains[0].groups())
    if len(set(drain_counts)) != 1 or drain_counts[0] < 88:
        raise ValueError(f"{label}: fetch conservation mismatch")
    canonical = "\n".join(trace_lines) + "\n"
    return {
        "metrics": metrics,
        "trace_lines": trace_lines,
        "trace_sha256": sha256_bytes(canonical.encode("utf-8")),
        "full_run_uops": identity_counts[0],
        "fetch_packets": drain_counts[0],
    }


def parse_stall_probe_text(text: str) -> dict[str, int]:
    label = "fixed-window stall probe"
    require_once(text, ANCHOR_MARKER, label)
    require_once(text, "[RESULT] FAIL status=1", label)
    require_once(
        text,
        "[V9A-WIDTH][FAIL] cycle=17 boundary=0 width=0 expected=2",
        label,
    )
    if (
        "compile returned nonzero" in text
        or "[PASS] tb_ooo_core_top_glue_v9a_width_stall_probe" in text
        or "[PASS] tb_ooo_core_top_glue_v9a_width_continuity" in text
    ):
        raise ValueError(f"{label}: probe did not compile and reject dynamically")
    metrics = metric_line(text, label)
    if (
        metrics["trace_cycles"] != 64
        or metrics["independent_alu_ipc_milli"] != 1968
    ):
        raise ValueError(f"{label}: fixed trace window moved")
    for boundary in BOUNDARIES:
        if (
            metrics[f"{boundary}_total"] != 126
            or metrics[f"{boundary}_peak"] != 2
            or metrics[f"{boundary}_dual_cycles"] != 63
        ):
            raise ValueError(f"{label}: {boundary} did not expose one gap")
    return metrics


def validate_mutation_dimension_coverage(
    rows: list[dict[str, Any]],
) -> dict[str, list[str]]:
    by_name = {
        item.get("name"): item for item in rows if isinstance(item, dict)
    }
    specs = {item.name: item for item in mutation_model.MUTATIONS}
    if set(by_name) != set(specs):
        raise ValueError("RTL verification mutation identity set mismatch")
    coverage = {name: [] for name in REQUIRED_DIMENSIONS}
    for name, spec in specs.items():
        if by_name[name].get("dimensions") != list(spec.dimensions):
            raise ValueError(f"{name}: exact verification dimension mismatch")
        for dimension in spec.dimensions:
            if dimension not in coverage:
                raise ValueError(f"{name}: unknown verification dimension")
            coverage[dimension].append(name)
    missing = sorted(name for name, owners in coverage.items() if not owners)
    if missing:
        raise ValueError(f"verification dimension coverage missing: {missing}")
    return {name: sorted(owners) for name, owners in sorted(coverage.items())}


def reconstruct_mutant_hashes(root: pathlib.Path, spec: Any) -> dict[str, str]:
    texts: dict[pathlib.Path, str] = {}
    for edit in spec.edits:
        target = edit.target.resolve(strict=True)
        if not target.is_relative_to(root):
            raise ValueError(f"{spec.name}: mutation target escapes repository")
        texts.setdefault(target, target.read_text(encoding="utf-8"))
        if texts[target].count(edit.old) != 1 or edit.old == edit.new:
            raise ValueError(f"{spec.name}: live mutation anchor is not unique")
        texts[target] = texts[target].replace(edit.old, edit.new, 1)
    result = {
        target.relative_to(root).as_posix():
            sha256_bytes(content.encode("utf-8"))
        for target, content in texts.items()
    }
    for rel, digest in result.items():
        if digest == arch.digest(arch.safe_artifact(root, rel)):
            raise ValueError(f"{spec.name}: reconstructed mutation is a no-op")
    return result


def read_mutations(
    root: pathlib.Path, path: pathlib.Path, suite_run_id: str,
) -> tuple[dict[str, Any], dict[str, list[str]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    results = payload.get("results")
    expected = len(mutation_model.MUTATIONS)
    if (
        payload.get("schema") != "v9a-width-continuity-mutations-v1"
        or payload.get("suite_run_id") != suite_run_id
        or payload.get("required") != expected
        or payload.get("compile_success") != expected
        or payload.get("dynamic_rejected") != expected
        or payload.get("source_unchanged") is not True
        or not isinstance(results, list)
        or len(results) != expected
    ):
        raise ValueError("V9A RTL mutation aggregate is incomplete")
    coverage = validate_mutation_dimension_coverage(results)
    before = payload.get("source_sha256_before")
    after = payload.get("source_sha256_after")
    expected_paths = {
        edit.target.relative_to(root).as_posix()
        for spec in mutation_model.MUTATIONS for edit in spec.edits
    }
    if (
        not isinstance(before, dict) or before != after
        or set(before) != expected_paths
    ):
        raise ValueError("V9A production RTL digest inventory changed")
    for rel, digest in before.items():
        if not arch.is_sha256(digest) or arch.digest(
            arch.safe_artifact(root, rel)
        ) != digest:
            raise ValueError(f"stale V9A production RTL binding: {rel}")
    if payload.get("testbench_sha256") != arch.digest(
        arch.safe_artifact(root, "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv")
    ):
        raise ValueError("V9A testbench digest is stale")

    specs = {item.name: item for item in mutation_model.MUTATIONS}
    for item in results:
        name = item["name"]
        spec = specs[name]
        expected_rel = pathlib.Path(
            f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log")
        reconstructed = reconstruct_mutant_hashes(root, spec)
        original = {
            rel: arch.digest(arch.safe_artifact(root, rel))
            for rel in reconstructed
        }
        if (
            item.get("suite_run_id") != suite_run_id
            or item.get("test") != mutation_model.TEST
            or item.get("log") != expected_rel.as_posix()
            or item.get("targets") != sorted(reconstructed)
            or item.get("original_sha256") != original
            or item.get("mutant_sha256") != reconstructed
            or item.get("mutant_nonidentical") is not True
            or item.get("compile_success") is not True
            or item.get("compile_rc") != 0
            or item.get("dynamic_rejected") is not True
            or not isinstance(item.get("sim_rc"), int)
            or item["sim_rc"] == 0
            or item.get("witness") not in spec.witnesses
        ):
            raise ValueError(f"{name}: compile-success mutation did not reject")
        log = arch.safe_artifact(root, expected_rel.as_posix())
        text = log.read_text(encoding="utf-8")
        if (
            text.count("[COMPILE] ") != 1
            or text.count("[RUN] ") != 1
            or item["witness"] not in text
            or f"[PASS] {mutation_model.TEST}" in text
        ):
            raise ValueError(f"{name}: mutation log is incomplete")
    return payload, coverage


def clean_regression_text(text: str, label: str) -> None:
    require_once(text, f"[PASS] {label}", label)
    require_once(text, "[RESULT] PASS", label)
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


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


def workspace_output(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"output escapes repository: {value}")
    if path.exists() and path.is_symlink():
        raise ValueError(f"output traverses symlink: {value}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def read_suite_run_id(path: pathlib.Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not re.fullmatch(
        r"v9a-di2-[0-9]{8}T[0-9]{6}Z-[0-9]+", lines[0]
    ):
        raise ValueError("V9A suite run id is malformed")
    return lines[0]


def snapshot_sources(root: pathlib.Path, output: pathlib.Path) -> None:
    paths = arch.WIDTH_CONTINUITY_SOURCE_PATHS
    if len(set(paths)) != len(paths):
        raise ValueError("DI-2 source inventory contains duplicate paths")
    lines = [
        f"{arch.digest(arch.safe_artifact(root, rel))}  {rel}"
        for rel in paths
    ]
    workspace_output(root, output).write_text(
        "\n".join(lines) + "\n", encoding="utf-8")


def reset_record(manifest: pathlib.Path) -> None:
    if not manifest.is_file():
        return
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    tests = payload.get("tests")
    if isinstance(tests, dict) and tests.pop("width_continuity", None) is not None:
        temporary = manifest.with_suffix(manifest.suffix + ".tmp")
        temporary.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        temporary.replace(manifest)


def validate_same_design_predecessors(
    manifest: pathlib.Path, design_id: str,
) -> dict[str, Any]:
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    required = {
        "frontend_ii1", "pair_matrix", "no_static_lane_semantics",
        "dual_memory_issue", "true_ooo_long_latency", "selective_scheduling",
        "memory_ordering", "speculation_recovery",
    }
    tests = payload.get("tests")
    if (
        payload.get("schema") != arch.EVIDENCE_SCHEMA
        or payload.get("design_id") != design_id
        or not isinstance(tests, dict)
        or set(tests) not in (required, required | {"width_continuity"})
        or any(
            not isinstance(tests[name], dict)
            or tests[name].get("status") != "PASS"
            for name in required
        )
    ):
        raise ValueError("same-design architecture predecessor evidence incomplete")
    return payload


def build(args: argparse.Namespace) -> None:
    root = args.repo_root.resolve(strict=True)
    suite_path = resolve_exact_input(
        root, args.suite_run_id_file, SUITE_RUN_ID_REL)
    sources_pre = resolve_exact_input(root, args.sources_pre, SOURCE_PRE_REL)
    sources_post = resolve_exact_input(root, args.sources_post, SOURCE_POST_REL)
    mutation_path = resolve_exact_input(
        root, args.mutation_summary, MUTATION_SUMMARY_REL)
    predecessor_log = arch.safe_artifact(root, PREDECESSOR_LOG_REL.as_posix())
    width_logs = {
        profile: resolve_exact_input(root, value, WIDTH_LOG_RELS[profile])
        for profile, value in (
            ("assert", args.width_assert_log),
            ("release", args.width_release_log),
        )
    }
    stall_log = resolve_exact_input(root, args.stall_log, STALL_LOG_REL)
    regression_logs = {
        name: resolve_exact_input(root, value, REGRESSION_RELS[name])
        for name, value in zip(REGRESSION_NAMES, args.regression_log)
    }

    pre_sources = arch.validate_source_manifest(
        root, sources_pre, arch.WIDTH_CONTINUITY_SOURCE_PATHS)
    post_sources = arch.validate_source_manifest(
        root, sources_post, arch.WIDTH_CONTINUITY_SOURCE_PATHS)
    if pre_sources != post_sources or sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical DI-2 proof sources changed during execution")

    suite_run_id = read_suite_run_id(suite_path)
    observations = {
        profile: parse_width_text(path.read_text(encoding="utf-8"), profile)
        for profile, path in width_logs.items()
    }
    if observations["assert"]["trace_lines"] != observations["release"][
        "trace_lines"
    ]:
        raise ValueError("assert/release canonical cycle traces differ")
    stall_metrics = parse_stall_probe_text(
        stall_log.read_text(encoding="utf-8"))
    for name, path in regression_logs.items():
        clean_regression_text(path.read_text(encoding="utf-8"), name)
    predecessor_text = predecessor_log.read_text(encoding="utf-8")
    require_once(
        predecessor_text, "[V8Z-DI1-RUNNER][PASS]", "same-design predecessors")
    if "[V8Z-DI1-RUNNER][FAIL]" in predecessor_text:
        raise ValueError("same-design predecessor refresh emitted failure")
    mutation_payload, mutation_coverage = read_mutations(
        root, mutation_path, suite_run_id)

    source_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    manifest = workspace_output(root, args.manifest)
    before_manifest = validate_same_design_predecessors(manifest, design_id)
    metrics = {
        "trace_cycles": 64,
        "independent_alu_ipc": 2.0,
        "boundary_activity": {
            boundary: {
                "peak_uops_per_cycle": 2,
                "total_uops": 128,
                "dual_uop_cycles": 64,
            }
            for boundary in BOUNDARIES
        },
    }
    failures = [
        item.check_id for item in arch.metric_checks("width_continuity", metrics)
        if not item.passed
    ]
    if failures:
        raise ValueError(f"DI-2 metric mapping rejected: {failures}")

    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.WIDTH_CONTINUITY_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    proof_paths = (
        suite_path, sources_pre, sources_post, mutation_path, predecessor_log,
        stall_log, *width_logs.values(), *regression_logs.values(),
        *(arch.safe_artifact(
            root, f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log",
        ) for name in arch.WIDTH_CONTINUITY_MUTATION_NAMES),
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths
    }
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_log = workspace_output(root, args.gate_log)
    gate_lines = [
        "DI-2 local RV64 seven-boundary width-continuity evidence",
        f"task_run_id={RUN_ID}",
        f"suite_run_id={suite_run_id}",
        f"generated_at_utc={generated_at}",
        f"design_id={design_id}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        f"source_manifest_sha256={arch.canonical_digest(pre_sources)}",
        f"trace_sha256={observations['assert']['trace_sha256']}",
        "focused_profiles=assert,release",
        f"compile_success_rtl_mutations={len(mutation_model.MUTATIONS)}",
        f"adjacent_regressions={len(regression_logs)}",
        "fixed_window_stall_probe=dynamic_reject",
    ]
    gate_lines.extend(
        f"boundary {boundary} total=128 peak=2 dual_cycles=64"
        for boundary in BOUNDARIES
    )
    gate_lines.extend(
        f"dimension {name} {','.join(owners)}"
        for name, owners in sorted(mutation_coverage.items())
    )
    gate_lines.extend(
        f"artifact_sha256 {path} {digest}"
        for path, digest in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] width_continuity PASS "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"trace_sha256={observations['assert']['trace_sha256']} "
        f"mutations={len(mutation_model.MUTATIONS)}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "artifacts": artifacts,
        "command": arch.WIDTH_CONTINUITY_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": metrics,
        "metric_basis": {
            "fixed_window": [
                "assert.trace", "release.trace", "stall_probe.dynamic_reject"],
            "boundary_identity": [
                "assert.identity", "release.identity", "mutation.payload_data",
                "mutation.pid_lifecycle",
            ],
            "independent_sinks": [
                "mutation.rename_sink", "mutation.rob_sink",
                "mutation.iq_sink", "mutation.ex_stage_capture",
                "mutation.wb_sink",
            ],
            "natural_drain": ["assert.drain", "release.drain"],
        },
        "mutation_audit": {
            "compile_success": mutation_payload["compile_success"],
            "dynamic_rejected": mutation_payload["dynamic_rejected"],
            "dimension_coverage": mutation_coverage,
            "production_sources_unchanged": True,
            "reconstructed_non_noop": len(mutation_model.MUTATIONS),
        },
        "predecessor_tests": sorted(before_manifest["tests"]),
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": provenance_sha,
        },
        "scope": (
            "DI-2 local RV64 independent integer ADDI stream across fetch, "
            "decode, rename, dispatch, issue, execute and retire; fixed "
            "24-cycle warmup plus 64-cycle trace, full ProducerId/payload "
            "lifecycle, independent ROB/IQ/EX/WB sinks and natural drain; "
            "not workload IPC, overall PPA or physical timing closure"
        ),
        "source_manifest": {
            "files": pre_sources,
            "sha256": arch.canonical_digest(pre_sources),
        },
        "status": "PASS",
        "suite_run_id": suite_run_id,
        "trace_sha256": observations["assert"]["trace_sha256"],
        "stall_probe": {
            "trace_cycles": stall_metrics["trace_cycles"],
            "retire_total": stall_metrics["retire_total"],
            "dynamic_rejected": True,
        },
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=design_id,
        generated_at_utc=generated_at,
        test_id="width_continuity",
        record=record,
    )
    print(
        "[V9A-DI2-EVIDENCE][PASS] width_continuity "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"boundaries=7 mutations={len(mutation_model.MUTATIONS)}"
    )


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser()
    subparsers = value.add_subparsers(dest="action", required=True)
    snapshot = subparsers.add_parser("snapshot")
    snapshot.add_argument("--repo-root", required=True, type=pathlib.Path)
    snapshot.add_argument("--output", required=True, type=pathlib.Path)
    reset = subparsers.add_parser("reset-record")
    reset.add_argument("--manifest", required=True, type=pathlib.Path)
    builder = subparsers.add_parser("build")
    builder.add_argument("--repo-root", required=True, type=pathlib.Path)
    builder.add_argument("--suite-run-id-file", required=True, type=pathlib.Path)
    builder.add_argument("--width-assert-log", required=True, type=pathlib.Path)
    builder.add_argument("--width-release-log", required=True, type=pathlib.Path)
    builder.add_argument("--stall-log", required=True, type=pathlib.Path)
    builder.add_argument(
        "--regression-log", required=True, type=pathlib.Path,
        action="append", help="repeat in REGRESSION_NAMES order")
    builder.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    builder.add_argument("--sources-pre", required=True, type=pathlib.Path)
    builder.add_argument("--sources-post", required=True, type=pathlib.Path)
    builder.add_argument("--gate-log", required=True, type=pathlib.Path)
    builder.add_argument("--manifest", required=True, type=pathlib.Path)
    return value


def main() -> int:
    args = parser().parse_args()
    if args.action == "reset-record":
        reset_record(args.manifest.resolve())
        print("[V9A-DI2-RESET][PASS]")
    else:
        root = args.repo_root.resolve(strict=True)
        if args.action == "snapshot":
            snapshot_sources(root, args.output)
            print(f"[V9A-DI2-SNAPSHOT][PASS] output={args.output}")
        else:
            if len(args.regression_log) != len(REGRESSION_NAMES):
                raise ValueError("exact adjacent regression log count mismatch")
            build(args)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        OSError, RuntimeError, UnicodeDecodeError, ValueError,
        json.JSONDecodeError,
    ) as exc:
        print(f"[V9A-DI2-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
