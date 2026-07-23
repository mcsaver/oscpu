#!/usr/bin/env python3
"""Build hash-bound local RV64 DI-1 frontend initiation evidence."""

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

RUN_ID = "2026-07-21-rv64-v8z-frontend-ii1"
BASE = pathlib.Path(f".github/task-runs/{RUN_ID}/evidence/final-run")
SUITE_RUN_ID_REL = BASE / "suite-run-id.txt"
SOURCE_PRE_REL = BASE / "sources.pre.sha256"
SOURCE_POST_REL = BASE / "sources.post.sha256"
PREDECESSOR_LOG_REL = BASE / "static/same-design-predecessors.log"
MUTATION_SUMMARY_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json")
FRONTEND_LOG_RELS = {
    profile: BASE / f"focused/{profile}/frontend/logs/"
                    "tb_ooo_core_top_glue_v8z_frontend_ii1.log"
    for profile in ("assert", "release")
}
BRIDGE_LOG_RELS = {
    profile: BASE / f"focused/{profile}/bridge/logs/"
                    "tb_ooo_fetch_axi_bridge.log"
    for profile in ("assert", "release")
}
REGRESSION_NAMES = (
    "tb_ooo_core_top_glue",
    "tb_ooo_fetch_flow_control",
    "tb_ooo_fetch_pc_outstanding_sequencer",
    "tb_ooo_fetch_packet_fifo",
    "tb_ooo_fetch_request_mux",
    "tb_ooo_frontend_action_gate",
)
REGRESSION_RELS = {
    name: BASE / f"regressions/logs/{name}.log"
    for name in REGRESSION_NAMES
}

FRONTEND_INTEGRATION_MARKER = (
    "[V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 "
    "packets_observed=64 accepted=64 responses=64 enqueues=64 "
    "produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS"
)
FRONTEND_BACKPRESSURE_MARKER = (
    "[V8Z-FRONTEND-II1-BACKPRESSURE] source=run_gate held_cycles=4 "
    "resume_turnovers=16 payload_stable=1 owner_stable=1 "
    "duplicate_enqueue=0 PASS"
)
FRONTEND_DRAIN_RE = re.compile(
    r"^\[V8Z-FRONTEND-II1-DRAIN\] requests=(\d+) responses=(\d+) "
    r"enqueues=(\d+) dequeues=(\d+) outstanding=0 fifo=0 rob=0 "
    r"issue=0 ghosts=0 PASS$",
    re.MULTILINE,
)
BRIDGE_MARKERS = {
    "bare_h1": (
        "[II1-IFU-HIT-TURNOVER] 64 consecutive response+request "
        "turnovers passed"
    ),
    "paged_h1": (
        "[II1-PAGING-CONTEXT] 64 U/ASID0 <-> S/ASID1 turnovers passed"
    ),
    "elastic_skid": (
        "[II1-IFU-ELASTIC-SKID] fast stall -> S_RESP -> replacement passed"
    ),
}

REQUIRED_MUTATION_DIMENSIONS = {
    "bridge_h1_ready_cut": (
        "accepted_packets", "produced_packets", "max_initiation_interval"),
    "bridge_h1_state_turnover_cut": (
        "produced_packets", "max_initiation_interval"),
    "bridge_semantic_lookup_cut": ("produced_packets",),
    "flow_outstanding_turnover_cut": (
        "accepted_packets", "max_initiation_interval"),
    "flow_enqueue_credit_cut": (
        "produced_packets", "max_initiation_interval"),
    "sequencer_replacement_clear": (
        "accepted_packets", "produced_packets"),
    "sink_dequeue_cut": ("produced_packets",),
    "successor_pc_old_owner": ("pc_ledger",),
    "blocked_response_tail_ghost": (
        "backpressure_recovery", "final_conservation"),
}
REQUIRED_DIMENSIONS = {
    "accepted_packets",
    "produced_packets",
    "max_initiation_interval",
    "pc_ledger",
    "backpressure_recovery",
    "final_conservation",
}


def require_once(text: str, marker: str, label: str) -> None:
    if text.count(marker) != 1:
        raise ValueError(f"{label}: expected unique marker {marker}")


def clean_simulation_text(text: str, label: str, expected_test: str) -> None:
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected exactly one [RESULT] PASS")
    require_once(text, f"[PASS] {expected_test}", label)
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_frontend_text(text: str, label: str) -> dict[str, Any]:
    clean_simulation_text(
        text, label, "tb_ooo_core_top_glue_v8z_frontend_ii1")
    require_once(text, FRONTEND_INTEGRATION_MARKER, label)
    require_once(text, FRONTEND_BACKPRESSURE_MARKER, label)
    drain = list(FRONTEND_DRAIN_RE.finditer(text))
    if len(drain) != 1:
        raise ValueError(f"{label}: expected one exact drain marker")
    values = tuple(int(item) for item in drain[0].groups())
    if len(set(values)) != 1 or values[0] < 81:
        raise ValueError(f"{label}: request/response/enqueue/dequeue mismatch")
    return {
        "steady_window": True,
        "pc_ledger": True,
        "backpressure_recovery": True,
        "final_conservation": True,
        "transactions": values[0],
    }


def parse_bridge_text(text: str, label: str) -> dict[str, bool]:
    clean_simulation_text(text, label, "tb_ooo_fetch_axi_bridge")
    result: dict[str, bool] = {}
    for name, marker in BRIDGE_MARKERS.items():
        require_once(text, marker, label)
        result[name] = True
    return result


def validate_mutation_dimension_coverage(
    rows: list[dict[str, Any]],
) -> dict[str, list[str]]:
    by_name = {
        item.get("name"): item for item in rows if isinstance(item, dict)
    }
    if set(by_name) != set(REQUIRED_MUTATION_DIMENSIONS):
        raise ValueError("RTL verification mutation identity set mismatch")
    coverage = {name: [] for name in REQUIRED_DIMENSIONS}
    for name, expected in REQUIRED_MUTATION_DIMENSIONS.items():
        if by_name[name].get("dimensions") != list(expected):
            raise ValueError(f"{name}: exact verification dimension mismatch")
        for dimension in expected:
            if dimension not in coverage:
                raise ValueError(f"{name}: unknown verification dimension")
            coverage[dimension].append(name)
    missing = sorted(name for name, owners in coverage.items() if not owners)
    if missing:
        raise ValueError(f"verification dimension coverage missing: {missing}")
    return {name: sorted(owners) for name, owners in sorted(coverage.items())}


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


def read_suite_run_id(path: pathlib.Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not re.fullmatch(
        r"v8z-di1-[0-9]{8}T[0-9]{6}Z-[0-9]+", lines[0]
    ):
        raise ValueError("V8Z suite run id is malformed")
    return lines[0]


def read_mutations(
    root: pathlib.Path, path: pathlib.Path, suite_run_id: str,
) -> tuple[dict[str, Any], dict[str, list[str]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    results = payload.get("results")
    expected_count = len(REQUIRED_MUTATION_DIMENSIONS)
    if (
        payload.get("schema") != "v8z-frontend-ii1-mutations-v1"
        or payload.get("suite_run_id") != suite_run_id
        or payload.get("required") != expected_count
        or payload.get("compile_success") != expected_count
        or payload.get("dynamic_rejected") != expected_count
        or payload.get("source_unchanged") is not True
        or not isinstance(results, list)
        or len(results) != expected_count
    ):
        raise ValueError("V8Z RTL source mutation aggregate is incomplete")
    coverage = validate_mutation_dimension_coverage(results)
    before = payload.get("source_sha256_before")
    after = payload.get("source_sha256_after")
    if not isinstance(before, dict) or not before or before != after:
        raise ValueError("V8Z production RTL source digest set changed")
    for rel, expected_sha in before.items():
        if not arch.is_sha256(expected_sha):
            raise ValueError(f"invalid production RTL digest: {rel}")
        if arch.digest(arch.safe_artifact(root, rel)) != expected_sha:
            raise ValueError(f"stale RTL mutation binding: {rel}")
    for item in results:
        name = item["name"]
        expected_rel = pathlib.Path(
            f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log")
        if (
            item.get("suite_run_id") != suite_run_id
            or item.get("log") != expected_rel.as_posix()
            or item.get("compile_success") is not True
            or item.get("compile_rc") != 0
            or item.get("dynamic_rejected") is not True
            or not isinstance(item.get("sim_rc"), int)
            or item["sim_rc"] == 0
            or not isinstance(item.get("witness"), str)
            or not item["witness"]
        ):
            raise ValueError(f"{name}: compile-success RTL mutation did not reject")
        log = arch.safe_artifact(root, expected_rel.as_posix())
        text = log.read_text(encoding="utf-8")
        if (
            text.count("[COMPILE] ") != 1
            or text.count("[RUN] ") != 1
            or item["witness"] not in text
            or f"[PASS] {item['test']}" in text
        ):
            raise ValueError(f"{name}: mutation log is incomplete")
    return payload, coverage


def workspace_output(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"output escapes repository: {value}")
    if path.exists() and path.is_symlink():
        raise ValueError(f"output traverses symlink: {value}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def snapshot_sources(root: pathlib.Path, output: pathlib.Path) -> None:
    if len(set(arch.FRONTEND_II1_SOURCE_PATHS)) != len(
        arch.FRONTEND_II1_SOURCE_PATHS
    ):
        raise ValueError("DI-1 source inventory contains duplicate paths")
    lines = [
        f"{arch.digest(arch.safe_artifact(root, rel))}  {rel}"
        for rel in arch.FRONTEND_II1_SOURCE_PATHS
    ]
    workspace_output(root, output).write_text(
        "\n".join(lines) + "\n", encoding="utf-8")


def reset_record(manifest: pathlib.Path) -> None:
    if not manifest.is_file():
        return
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    tests = payload.get("tests")
    if isinstance(tests, dict) and tests.pop("frontend_ii1", None) is not None:
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
        "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
        "true_ooo_long_latency", "selective_scheduling", "memory_ordering",
        "speculation_recovery",
    }
    tests = payload.get("tests")
    if (
        payload.get("schema") != arch.EVIDENCE_SCHEMA
        or payload.get("design_id") != design_id
        or not isinstance(tests, dict)
        or set(tests) not in (required, required | {"frontend_ii1"})
        or any(
            not isinstance(tests[name], dict)
            or tests[name].get("status") != "PASS"
            for name in required
        )
    ):
        raise ValueError("same-design DI-3/4/5 and OOO-1/2/3/4 evidence is incomplete")
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
    frontend_logs = {
        profile: resolve_exact_input(root, value, FRONTEND_LOG_RELS[profile])
        for profile, value in (
            ("assert", args.frontend_assert_log),
            ("release", args.frontend_release_log),
        )
    }
    bridge_logs = {
        profile: resolve_exact_input(root, value, BRIDGE_LOG_RELS[profile])
        for profile, value in (
            ("assert", args.bridge_assert_log),
            ("release", args.bridge_release_log),
        )
    }
    regression_logs = {
        name: resolve_exact_input(root, value, REGRESSION_RELS[name])
        for name, value in zip(REGRESSION_NAMES, args.regression_log)
    }

    pre_sources = arch.validate_source_manifest(
        root, sources_pre, arch.FRONTEND_II1_SOURCE_PATHS)
    post_sources = arch.validate_source_manifest(
        root, sources_post, arch.FRONTEND_II1_SOURCE_PATHS)
    if pre_sources != post_sources or sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical DI-1 proof sources changed during execution")

    suite_run_id = read_suite_run_id(suite_path)
    frontend_observations = {
        profile: parse_frontend_text(path.read_text(encoding="utf-8"), profile)
        for profile, path in frontend_logs.items()
    }
    bridge_observations = {
        profile: parse_bridge_text(path.read_text(encoding="utf-8"), profile)
        for profile, path in bridge_logs.items()
    }
    for name, path in regression_logs.items():
        clean_simulation_text(path.read_text(encoding="utf-8"), name, name)
    predecessor_text = predecessor_log.read_text(encoding="utf-8")
    require_once(
        predecessor_text, "[V8Y-OOO4-RUNNER][PASS]", "same-design predecessors")
    if "[V8Y-OOO4-RUNNER][FAIL]" in predecessor_text:
        raise ValueError("same-design predecessor refresh emitted a failure marker")
    mutation_payload, mutation_coverage = read_mutations(
        root, mutation_path, suite_run_id)

    source_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    manifest = workspace_output(root, args.manifest)
    before_manifest = validate_same_design_predecessors(manifest, design_id)

    metrics = {
        "packets_observed": 64,
        "preheated_cycles": 64,
        "accepted_packets": 64,
        "produced_packets": 64,
        "max_initiation_interval": 1,
        "response_packets": 64,
        "enqueue_packets": 64,
        "sink_dequeue_packets": 64,
        "sequential_packets": 64,
        "redirect_cycles": 0,
        "stall_cycles": 0,
        "backpressure_held_cycles": 4,
        "backpressure_resume_turnovers": 16,
        "final_conservation_errors": 0,
    }
    failed_metrics = [
        item.check_id
        for item in arch.metric_checks("frontend_ii1", metrics)
        if not item.passed
    ]
    if failed_metrics:
        raise ValueError(f"DI-1 metric mapping rejected: {failed_metrics}")
    if not all(
        item["steady_window"] and item["pc_ledger"]
        and item["backpressure_recovery"] and item["final_conservation"]
        for item in frontend_observations.values()
    ) or not all(all(item.values()) for item in bridge_observations.values()):
        raise ValueError("DI-1 focused observation mapping is incomplete")

    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.FRONTEND_II1_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    proof_paths = (
        suite_path, sources_pre, sources_post, mutation_path, predecessor_log,
        *frontend_logs.values(), *bridge_logs.values(),
        *regression_logs.values(),
        *(arch.safe_artifact(
            root,
            f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log",
        ) for name in REQUIRED_MUTATION_DIMENSIONS),
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths
    }
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_log = workspace_output(root, args.gate_log)
    gate_lines = [
        "DI-1 local RV64 frontend initiation-interval evidence",
        f"task_run_id={RUN_ID}",
        f"suite_run_id={suite_run_id}",
        f"generated_at_utc={generated_at}",
        f"design_id={design_id}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        f"source_manifest_sha256={arch.canonical_digest(pre_sources)}",
        "focused_profiles=assert,release",
        f"compile_success_rtl_source_mutations={len(REQUIRED_MUTATION_DIMENSIONS)}",
        f"adjacent_regressions={len(regression_logs)}",
    ]
    gate_lines.extend(
        f"metric {name} {json.dumps(value)}"
        for name, value in sorted(metrics.items())
    )
    gate_lines.extend(
        f"dimension {name} {','.join(owners)}"
        for name, owners in sorted(mutation_coverage.items())
    )
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] frontend_ii1 PASS "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"mutations={len(REQUIRED_MUTATION_DIMENSIONS)}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "artifacts": artifacts,
        "command": arch.FRONTEND_II1_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": metrics,
        "metric_basis": {
            "steady_window": [
                "assert.frontend", "release.frontend",
                "assert.bridge.bare_h1", "release.bridge.bare_h1",
            ],
            "sink_and_pc": [
                "assert.frontend.pc_ledger", "release.frontend.pc_ledger",
                "mutation.pc_ledger", "mutation.produced_packets",
            ],
            "backpressure_and_drain": [
                "assert.frontend.backpressure_recovery",
                "release.frontend.backpressure_recovery",
                "assert.frontend.final_conservation",
                "release.frontend.final_conservation",
                "mutation.backpressure_recovery",
                "mutation.final_conservation",
            ],
        },
        "mutation_audit": {
            "compile_success": mutation_payload["compile_success"],
            "dynamic_rejected": mutation_payload["dynamic_rejected"],
            "dimension_coverage": mutation_coverage,
            "production_sources_unchanged": True,
        },
        "predecessor_tests": sorted(before_manifest["tests"]),
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": provenance_sha,
        },
        "scope": (
            "DI-1 local RV64 Bridge H1 and complete OooFrontend request, "
            "response, outstanding, FIFO-credit and sink turnover; includes "
            "PC identity, finite run-gate response backpressure and final "
            "owner conservation; not DI-2, overall architecture or PPA"
        ),
        "source_manifest": {
            "files": pre_sources,
            "sha256": arch.canonical_digest(pre_sources),
        },
        "status": "PASS",
        "suite_run_id": suite_run_id,
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=design_id,
        generated_at_utc=generated_at,
        test_id="frontend_ii1",
        record=record,
    )
    print(
        "[V8Z-DI1-EVIDENCE][PASS] frontend_ii1 "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"metrics=5 mutations={len(REQUIRED_MUTATION_DIMENSIONS)}"
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
    builder.add_argument("--frontend-assert-log", required=True, type=pathlib.Path)
    builder.add_argument("--frontend-release-log", required=True, type=pathlib.Path)
    builder.add_argument("--bridge-assert-log", required=True, type=pathlib.Path)
    builder.add_argument("--bridge-release-log", required=True, type=pathlib.Path)
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
        print("[V8Z-DI1-RESET][PASS]")
    else:
        root = args.repo_root.resolve(strict=True)
        if args.action == "snapshot":
            snapshot_sources(root, args.output)
            print(f"[V8Z-DI1-SNAPSHOT][PASS] output={args.output}")
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
        print(f"[V8Z-DI1-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
