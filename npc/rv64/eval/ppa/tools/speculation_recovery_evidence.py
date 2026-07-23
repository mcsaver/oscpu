#!/usr/bin/env python3
"""Build hash-bound local RV64 RTL OOO-4 recovery evidence."""

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

RUN_ID = "2026-07-21-rv64-v8y-speculation-recovery"
FOCUSED_ASSERT_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/focused/assert/logs/"
    "tb_ooo_int_backend_v8y_speculation_recovery.log"
)
FOCUSED_RELEASE_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/focused/release/logs/"
    "tb_ooo_int_backend_v8y_speculation_recovery.log"
)
MUTATION_SUMMARY_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json"
)
SUITE_RUN_ID_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/suite-run-id.txt"
)
SOURCE_PRE_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/sources.pre.sha256"
)
SOURCE_POST_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/sources.post.sha256"
)
PREDECESSOR_LOG_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/static/"
    "same-design-predecessors.log"
)
REGRESSION_NAMES = (
    "tb_ooo_int_backend",
    "tb_ooo_core_top_glue",
    "tb_ooo_redirect_arbiter",
    "tb_ooo_branch_bpu_update_gate",
    "tb_ooo_mem_axi_bridge",
    "tb_ooo_dual_mem_bridge_wrapper",
)
REGRESSION_RELS = {
    name: pathlib.Path(
        f".github/task-runs/{RUN_ID}/evidence/final-run/regressions/logs/"
        f"{name}.log"
    )
    for name in REGRESSION_NAMES
}

LINEAR_MARKER = (
    "[V8Y-CONTROL-RECOVERY] mode=linear rob=D0,A1,B2 controls=2 "
    "oldest=A resolves=1 younger_issue=0 younger_resolve=0 "
    "complete_survivors=2 wrong_complete=0 retire_survivors=2 "
    "wrong_retire=0 ghosts=0 PASS"
)
WRAP_MARKER = (
    "[V8Y-CONTROL-RECOVERY] mode=wrap rob=D14,A15,B0 controls=2 "
    "oldest=A resolves=1 younger_issue=0 younger_resolve=0 "
    "complete_survivors=2 wrong_complete=0 retire_survivors=2 "
    "wrong_retire=0 ghosts=0 PASS"
)
LEDGER_MARKER = (
    "[V8Y-CONTROL-RECOVERY-AGGREGATE] linear=1 wrap=1 "
    "full_pid_ledger=1 PASS"
)
EX_KILL_MARKER = (
    "[V8D-INT-EX-KILL-CUT] branch=0 younger=1 pdest=32 "
    "raw-before=1 raw-after=0"
)
EX_MATRIX_MARKER = "[V8D-INT-EX-KILL-AGE] checks=8192 failures=0"
AXI_DRAIN_MARKER = (
    "[V8X-BACKEND-BRIDGE-RECOVERY] A=0 B=1 ar=1 drop=2 pop=2 "
    "terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS"
)
INTEGRATED_MARKER = (
    "[V8Y-SPECULATION-RECOVERY] multi_control=1 oldest_branch=1 "
    "selective_ex=1 axi_drain=1 complete_violations=0 "
    "retire_violations=0 ghosts=0 PASS"
)
FOCUSED_MARKERS = {
    "linear_control_order": LINEAR_MARKER,
    "wrap_control_order": WRAP_MARKER,
    "full_pid_ledger": LEDGER_MARKER,
    "selective_ex_cut": EX_KILL_MARKER,
    "selective_ex_matrix": EX_MATRIX_MARKER,
    "axi_drain": AXI_DRAIN_MARKER,
    "integrated": INTEGRATED_MARKER,
}

REQUIRED_MUTATION_METRICS = {
    "control_admit_b": ("multiple_controls_inflight",),
    "youngest_control_select": (
        "oldest_mispredict_wins", "wrong_path_selective_squash"),
    "resolve_issue_close_bypass": (
        "oldest_mispredict_wins", "wrong_path_selective_squash",
        "ghost_after_recovery"),
    "rob_tail_boundary_off_by_one": (
        "wrong_path_selective_squash", "exactly_once_retire_violations",
        "ghost_after_recovery"),
    "completion_replay_one_cycle": (
        "exactly_once_complete_violations",),
    "retire1_owner_remap": ("exactly_once_retire_violations",),
    "iq_kill_holder_bypass": ("ghost_after_recovery",),
    "mask_active_recovery_while_station_valid": (
        "fired_axi_drained", "ghost_after_recovery"),
    "block_killed_station_promotion": (
        "fired_axi_drained", "ghost_after_recovery"),
}
REQUIRED_METRICS = {
    "multiple_controls_inflight",
    "oldest_mispredict_wins",
    "wrong_path_selective_squash",
    "fired_axi_drained",
    "exactly_once_complete_violations",
    "exactly_once_retire_violations",
    "ghost_after_recovery",
}


def require_once(text: str, marker: str, label: str) -> None:
    if text.count(marker) != 1:
        raise ValueError(f"{label}: expected unique marker {marker}")


def clean_simulation_text(text: str, label: str) -> None:
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected exactly one [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_focused_text(text: str, label: str) -> dict[str, bool]:
    """Parse one assert/release run of the same RV64 V8Y focused binary."""
    clean_simulation_text(text, label)
    observations: dict[str, bool] = {}
    for key, marker in FOCUSED_MARKERS.items():
        require_once(text, marker, label)
        observations[key] = True
    require_once(
        text, "[PASS] tb_ooo_int_backend_v8y_speculation_recovery", label)
    observations["testbench_pass"] = True
    return observations


def parse_clean_simulation(path: pathlib.Path, expected_test: str) -> str:
    text = path.read_text(encoding="utf-8")
    clean_simulation_text(text, str(path))
    require_once(text, f"[PASS] {expected_test}", str(path))
    return text


def validate_mutation_metric_coverage(
    results: list[dict[str, Any]],
) -> dict[str, list[str]]:
    by_name = {
        item.get("name"): item for item in results if isinstance(item, dict)
    }
    if set(by_name) != set(REQUIRED_MUTATION_METRICS):
        raise ValueError("RTL verification mutation identity set mismatch")
    coverage = {name: [] for name in REQUIRED_METRICS}
    for name, expected_metrics in REQUIRED_MUTATION_METRICS.items():
        metrics = by_name[name].get("metrics")
        if metrics != list(expected_metrics):
            raise ValueError(
                f"{name}: exact RTL verification metric mapping mismatch")
        for metric_name in metrics:
            if metric_name not in coverage:
                raise ValueError(f"{name}: unknown architecture metric {metric_name}")
            coverage[metric_name].append(name)
    missing = sorted(name for name, owners in coverage.items() if not owners)
    if missing:
        raise ValueError(f"RTL verification mutation metric coverage missing: {missing}")
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


def read_mutations(
    root: pathlib.Path, path: pathlib.Path, suite_run_id: str,
) -> tuple[dict[str, Any], dict[str, list[str]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    results = payload.get("results")
    expected_count = len(REQUIRED_MUTATION_METRICS)
    if (
        payload.get("schema") != "v8y-speculation-recovery-mutations-v1"
        or payload.get("suite_run_id") != suite_run_id
        or payload.get("required") != expected_count
        or payload.get("compile_success") != expected_count
        or payload.get("dynamic_rejected") != expected_count
        or payload.get("source_unchanged") is not True
        or not isinstance(results, list)
        or len(results) != expected_count
    ):
        raise ValueError("V8Y RTL verification mutation aggregate is incomplete")
    coverage = validate_mutation_metric_coverage(results)

    before = payload.get("source_sha256_before")
    after = payload.get("source_sha256_after")
    if not isinstance(before, dict) or before != after or not before:
        raise ValueError("V8Y production RTL source digest set changed")
    for rel, expected_sha in before.items():
        if not arch.is_sha256(expected_sha):
            raise ValueError(f"invalid production RTL digest: {rel}")
        if arch.digest(arch.safe_artifact(root, rel)) != expected_sha:
            raise ValueError(f"stale production RTL mutation binding: {rel}")
    tb = root / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
    adapter = root / (
        "npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh")
    if payload.get("testbench_sha256") != arch.digest(tb):
        raise ValueError("V8Y RTL testbench digest is stale")
    if payload.get("adapter_sha256") != arch.digest(adapter):
        raise ValueError("V8X memory-bridge adapter digest is stale")

    for item in results:
        name = item["name"]
        expected_log_rel = pathlib.Path(
            f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log")
        if item.get("log") != expected_log_rel.as_posix():
            raise ValueError(f"{name}: mutation log path mismatch")
        if (
            item.get("suite_run_id") != suite_run_id
            or item.get("compile_success") is not True
            or item.get("compile_rc") != 0
            or item.get("dynamic_rejected") is not True
            or not isinstance(item.get("sim_rc"), int)
            or item["sim_rc"] == 0
            or not isinstance(item.get("witness"), str)
            or not item["witness"]
        ):
            raise ValueError(f"{name}: compile-success RTL verification did not reject")
        targets = item.get("targets")
        mutant_sha = item.get("mutant_sha256")
        if (
            not isinstance(targets, list)
            or not isinstance(mutant_sha, dict)
            or set(targets) != set(mutant_sha)
            or not all(arch.is_sha256(value) for value in mutant_sha.values())
        ):
            raise ValueError(f"{name}: mutated RTL source digest audit is incomplete")
        mutation_log = arch.safe_artifact(root, expected_log_rel.as_posix())
        log_text = mutation_log.read_text(encoding="utf-8")
        if (
            log_text.count("[COMPILE] ") != 1
            or log_text.count("[RUN] ") != 1
            or item["witness"] not in log_text
            or "[PASS] tb_ooo_int_backend_v8y_speculation_recovery" in log_text
        ):
            raise ValueError(f"{name}: dynamic rejection log is incomplete")
    return payload, coverage


def read_suite_run_id(path: pathlib.Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not re.fullmatch(
        r"v8y-ooo4-[0-9]{8}T[0-9]{6}Z-[0-9]+", lines[0]
    ):
        raise ValueError("V8Y suite run id is malformed")
    return lines[0]


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
    if len(set(arch.SPECULATION_RECOVERY_SOURCE_PATHS)) != len(
        arch.SPECULATION_RECOVERY_SOURCE_PATHS
    ):
        raise ValueError("OOO-4 source inventory contains duplicate paths")
    lines = []
    for rel in arch.SPECULATION_RECOVERY_SOURCE_PATHS:
        path = arch.safe_artifact(root, rel)
        lines.append(f"{arch.digest(path)}  {rel}")
    workspace_output(root, output).write_text(
        "\n".join(lines) + "\n", encoding="utf-8")


def validate_same_design_predecessors(
    manifest: pathlib.Path, design_id: str,
) -> dict[str, Any]:
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    required = {
        "pair_matrix",
        "no_static_lane_semantics",
        "dual_memory_issue",
        "true_ooo_long_latency",
        "selective_scheduling",
        "memory_ordering",
    }
    tests = payload.get("tests")
    if (
        payload.get("schema") != arch.EVIDENCE_SCHEMA
        or payload.get("design_id") != design_id
        or not isinstance(tests, dict)
        or set(tests) not in (required, required | {"speculation_recovery"})
        or any(
            not isinstance(tests[name], dict)
            or tests[name].get("status") != "PASS"
            for name in required
        )
    ):
        raise ValueError("same-design DI-3/4/5 and OOO-1/2/3 evidence is incomplete")
    return payload


def build(args: argparse.Namespace) -> None:
    root = args.repo_root.resolve(strict=True)
    assert_log = resolve_exact_input(
        root, args.assert_log, FOCUSED_ASSERT_REL)
    release_log = resolve_exact_input(
        root, args.release_log, FOCUSED_RELEASE_REL)
    mutation_summary = resolve_exact_input(
        root, args.mutation_summary, MUTATION_SUMMARY_REL)
    suite_run_id_path = resolve_exact_input(
        root, args.suite_run_id_file, SUITE_RUN_ID_REL)
    sources_pre = resolve_exact_input(root, args.sources_pre, SOURCE_PRE_REL)
    sources_post = resolve_exact_input(root, args.sources_post, SOURCE_POST_REL)
    predecessor_log = arch.safe_artifact(root, PREDECESSOR_LOG_REL.as_posix())
    regression_logs = {
        name: resolve_exact_input(root, value, REGRESSION_RELS[name])
        for name, value in (
            ("tb_ooo_int_backend", args.backend_regression_log),
            ("tb_ooo_core_top_glue", args.glue_regression_log),
            ("tb_ooo_redirect_arbiter", args.redirect_regression_log),
            ("tb_ooo_branch_bpu_update_gate", args.bpu_regression_log),
            ("tb_ooo_mem_axi_bridge", args.bridge_regression_log),
            ("tb_ooo_dual_mem_bridge_wrapper", args.wrapper_regression_log),
        )
    }

    pre_sources = arch.validate_source_manifest(
        root, sources_pre, arch.SPECULATION_RECOVERY_SOURCE_PATHS)
    post_sources = arch.validate_source_manifest(
        root, sources_post, arch.SPECULATION_RECOVERY_SOURCE_PATHS)
    if pre_sources != post_sources or sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical OOO-4 proof sources changed during execution")

    suite_run_id = read_suite_run_id(suite_run_id_path)
    assert_observations = parse_focused_text(
        assert_log.read_text(encoding="utf-8"), "V8Y assert focused")
    release_observations = parse_focused_text(
        release_log.read_text(encoding="utf-8"), "V8Y release focused")
    for name, path in regression_logs.items():
        parse_clean_simulation(path, name)
    predecessor_text = predecessor_log.read_text(encoding="utf-8")
    require_once(
        predecessor_text, "[V8V-OOO3-RUNNER][PASS]", "same-design predecessors")
    if "[V8V-OOO3-RUNNER][FAIL]" in predecessor_text:
        raise ValueError("same-design predecessor refresh emitted a failure marker")
    mutation_payload, mutation_coverage = read_mutations(
        root, mutation_summary, suite_run_id)

    source_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    manifest = workspace_output(root, args.manifest)
    if not manifest.is_file():
        raise ValueError("same-design architecture evidence manifest is missing")
    before_manifest = validate_same_design_predecessors(manifest, design_id)

    observations: dict[str, bool] = {}
    observations.update({f"assert.{key}": value
                         for key, value in assert_observations.items()})
    observations.update({f"release.{key}": value
                         for key, value in release_observations.items()})
    observations.update({f"regression.{name}": True
                         for name in regression_logs})
    observations["predecessors.same_design"] = True
    observations.update({f"mutation.{name}": bool(owners)
                         for name, owners in mutation_coverage.items()})
    metric_basis = {
        "multiple_controls_inflight": (
            "assert.linear_control_order", "assert.wrap_control_order",
            "release.linear_control_order", "release.wrap_control_order",
            "mutation.multiple_controls_inflight"),
        "oldest_mispredict_wins": (
            "assert.integrated", "release.integrated",
            "mutation.oldest_mispredict_wins"),
        "wrong_path_selective_squash": (
            "assert.selective_ex_cut", "assert.selective_ex_matrix",
            "release.selective_ex_cut", "release.selective_ex_matrix",
            "mutation.wrong_path_selective_squash",
            "regression.tb_ooo_redirect_arbiter",
            "regression.tb_ooo_branch_bpu_update_gate"),
        "fired_axi_drained": (
            "assert.axi_drain", "release.axi_drain",
            "mutation.fired_axi_drained",
            "regression.tb_ooo_mem_axi_bridge",
            "regression.tb_ooo_dual_mem_bridge_wrapper"),
        "exactly_once_complete_violations": (
            "assert.full_pid_ledger", "release.full_pid_ledger",
            "mutation.exactly_once_complete_violations",
            "regression.tb_ooo_int_backend"),
        "exactly_once_retire_violations": (
            "assert.full_pid_ledger", "release.full_pid_ledger",
            "mutation.exactly_once_retire_violations",
            "regression.tb_ooo_core_top_glue"),
        "ghost_after_recovery": (
            "assert.integrated", "release.integrated",
            "mutation.ghost_after_recovery",
            "regression.tb_ooo_int_backend",
            "regression.tb_ooo_core_top_glue"),
    }
    metric_pass = {
        name: all(observations.get(item, False) for item in basis)
        for name, basis in metric_basis.items()
    }
    metrics = {
        "multiple_controls_inflight": metric_pass[
            "multiple_controls_inflight"],
        "oldest_mispredict_wins": metric_pass["oldest_mispredict_wins"],
        "wrong_path_selective_squash": metric_pass[
            "wrong_path_selective_squash"],
        "fired_axi_drained": metric_pass["fired_axi_drained"],
        "exactly_once_complete_violations": (
            0 if metric_pass["exactly_once_complete_violations"] else 1),
        "exactly_once_retire_violations": (
            0 if metric_pass["exactly_once_retire_violations"] else 1),
        "ghost_after_recovery": (
            0 if metric_pass["ghost_after_recovery"] else 1),
    }
    failed_metrics = [
        item.check_id
        for item in arch.metric_checks("speculation_recovery", metrics)
        if not item.passed
    ]
    if failed_metrics:
        raise ValueError(f"OOO-4 metric mapping rejected: {failed_metrics}")

    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.SPECULATION_RECOVERY_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    proof_paths = (
        assert_log,
        release_log,
        mutation_summary,
        suite_run_id_path,
        sources_pre,
        sources_post,
        predecessor_log,
        *regression_logs.values(),
        *(arch.safe_artifact(
            root,
            f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log",
        ) for name in REQUIRED_MUTATION_METRICS),
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths
    }
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_log = workspace_output(root, args.gate_log)
    gate_lines = [
        "OOO-4 local RV64 speculation and recovery evidence",
        f"task_run_id={RUN_ID}",
        f"suite_run_id={suite_run_id}",
        f"generated_at_utc={generated_at}",
        f"design_id={design_id}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        f"source_manifest_sha256={arch.canonical_digest(pre_sources)}",
        "focused_profiles=assert,release",
        f"compile_success_rtl_verification_mutations={len(REQUIRED_MUTATION_METRICS)}",
        f"adjacent_regressions={len(regression_logs)}",
    ]
    gate_lines.extend(
        f"basis {name} {','.join(basis)}"
        for name, basis in sorted(metric_basis.items())
    )
    gate_lines.extend(
        f"metric {name} {json.dumps(value)}"
        for name, value in sorted(metrics.items())
    )
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] speculation_recovery PASS "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"mutations={len(REQUIRED_MUTATION_METRICS)}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "artifacts": artifacts,
        "command": arch.SPECULATION_RECOVERY_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": metrics,
        "metric_basis": {
            name: list(basis) for name, basis in sorted(metric_basis.items())
        },
        "mutation_audit": {
            "compile_success": mutation_payload["compile_success"],
            "dynamic_rejected": mutation_payload["dynamic_rejected"],
            "metric_coverage": mutation_coverage,
            "production_sources_unchanged": True,
        },
        "predecessor_tests": sorted(
            set(before_manifest["tests"]) - {"speculation_recovery"}),
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": provenance_sha,
        },
        "scope": (
            "OOO-4 local RV64 control-flow in-flight ordering, oldest branch "
            "mispredict recovery, strictly-younger pipeline-state removal, "
            "full-ProducerId completion/retirement ledgers, and already-fired "
            "AXI transaction drain; not DI-1, DI-2, overall architecture or "
            "PPA promotion"
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
        test_id="speculation_recovery",
        record=record,
    )
    print(
        "[V8Y-OOO4-EVIDENCE][PASS] speculation_recovery "
        f"suite_run_id={suite_run_id} design_id={design_id} "
        f"metrics={len(metrics)} mutations={len(REQUIRED_MUTATION_METRICS)}"
    )


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser()
    subparsers = value.add_subparsers(dest="action", required=True)
    snapshot = subparsers.add_parser("snapshot")
    snapshot.add_argument("--repo-root", required=True, type=pathlib.Path)
    snapshot.add_argument("--output", required=True, type=pathlib.Path)

    builder = subparsers.add_parser("build")
    builder.add_argument("--repo-root", required=True, type=pathlib.Path)
    builder.add_argument("--assert-log", required=True, type=pathlib.Path)
    builder.add_argument("--release-log", required=True, type=pathlib.Path)
    builder.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    builder.add_argument("--suite-run-id-file", required=True, type=pathlib.Path)
    builder.add_argument("--backend-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--glue-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--redirect-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--bpu-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--bridge-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--wrapper-regression-log", required=True, type=pathlib.Path)
    builder.add_argument("--sources-pre", required=True, type=pathlib.Path)
    builder.add_argument("--sources-post", required=True, type=pathlib.Path)
    builder.add_argument("--gate-log", required=True, type=pathlib.Path)
    builder.add_argument("--manifest", required=True, type=pathlib.Path)
    return value


def main() -> int:
    args = parser().parse_args()
    root = args.repo_root.resolve(strict=True)
    if args.action == "snapshot":
        snapshot_sources(root, args.output)
        print(f"[V8Y-OOO4-SNAPSHOT][PASS] output={args.output}")
    else:
        build(args)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        OSError, RuntimeError, UnicodeDecodeError, ValueError,
        json.JSONDecodeError,
    ) as exc:
        print(f"[V8Y-OOO4-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
