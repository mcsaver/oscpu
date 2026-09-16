#!/usr/bin/env python3
"""Build hash-bound local RV64 RTL OOO-4 recovery evidence."""

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
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

RUN_ID = "2026-07-21-rv64-v8y-speculation-recovery"
MUTATOR_REL = pathlib.Path(
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "run-v8y-mutations.py"
)
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
SIMULATOR_CONFIG_REL = pathlib.Path(
    f".github/task-runs/{RUN_ID}/evidence/final-run/static/"
    "simulator-config.txt"
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


def validate_predecessor_receipt(text: str, design_id: str) -> str:
    fresh_marker = "[V8V-OOO3-RUNNER][PASS]"
    reuse_prefix = "[ARCH-CURRENT-PREDECESSORS][PASS]"
    reuse_matches = re.findall(
        r"^\[ARCH-CURRENT-PREDECESSORS\]\[PASS\] "
        r"design_id=(sha256:[0-9a-f]{64}) green=6 red=3 next=OOO-4$",
        text,
        flags=re.MULTILINE,
    )
    fresh_count = text.count(fresh_marker)
    if fresh_count > 1 or text.count(reuse_prefix) != len(reuse_matches):
        raise ValueError("same-design predecessor receipt is ambiguous or malformed")
    if (
        "[V8V-OOO3-RUNNER][FAIL]" in text
        or "[ARCH-CURRENT-PREDECESSORS][FAIL]" in text
    ):
        raise ValueError("same-design predecessor refresh emitted a failure marker")
    modes = []
    if fresh_count == 1:
        modes.append("fresh_replay")
    if len(reuse_matches) == 1:
        if reuse_matches[0] != design_id:
            raise ValueError("reused predecessor receipt has a stale RTL design id")
        modes.append("current_hard_gate_reuse")
    if len(modes) != 1:
        raise ValueError("expected exactly one valid same-design predecessor receipt")
    return modes[0]


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
    mutation_log_rels: dict[str, pathlib.Path],
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
        expected_log_rel = mutation_log_rels[name]
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


def validate_reconstructed_mutations(
    root: pathlib.Path, payload: dict[str, Any],
) -> int:
    """Rebuild every declared mutant digest from one unique live RTL anchor."""
    mutator_path = arch.safe_artifact(root, MUTATOR_REL.as_posix())
    spec = importlib.util.spec_from_file_location(
        "v8y_speculation_recovery_mutator", mutator_path)
    if spec is None or spec.loader is None:
        raise ValueError("V8Y mutation runner cannot be loaded")
    mutator = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mutator
    spec.loader.exec_module(mutator)
    mutations = getattr(mutator, "MUTATIONS", ())
    by_name = {
        item.get("name"): item
        for item in payload.get("results", ())
        if isinstance(item, dict)
    }
    if {item.name for item in mutations} != set(REQUIRED_MUTATION_METRICS):
        raise ValueError("V8Y live mutation identity set mismatch")
    for mutation in mutations:
        texts: dict[pathlib.Path, str] = {}
        for edit in mutation.edits:
            target = edit.target.resolve(strict=True)
            if not target.is_relative_to(root):
                raise ValueError(f"{mutation.name}: mutation target escapes workspace")
            texts.setdefault(target, target.read_text(encoding="utf-8"))
            count = texts[target].count(edit.old)
            if count != 1:
                raise ValueError(
                    f"{mutation.name}: live RTL anchor count={count} for "
                    f"{target.relative_to(root).as_posix()}")
            mutated = texts[target].replace(edit.old, edit.new, 1)
            if mutated == texts[target]:
                raise ValueError(f"{mutation.name}: byte-identical mutation")
            texts[target] = mutated
        reconstructed = {
            target.relative_to(root).as_posix():
                hashlib.sha256(text.encode("utf-8")).hexdigest()
            for target, text in texts.items()
        }
        if by_name[mutation.name].get("mutant_sha256") != reconstructed:
            raise ValueError(
                f"{mutation.name}: mutant digest is not reproducible from live RTL")
    return len(mutations)


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


def task_run_evidence_rel(task_run_id: str, suffix: str) -> pathlib.Path:
    if not re.fullmatch(
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}-rv64-[a-z0-9][a-z0-9._-]*",
        task_run_id,
    ):
        raise ValueError("malformed local RV64 OOO-4 task-run id")
    return pathlib.Path(".github/task-runs") / task_run_id / "evidence" / suffix


def validate_simulator_config(path: pathlib.Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    expected_prefix = [
        "schema=rv64-ooo4-simulator-config-v1",
        "target=v8y-speculation-recovery",
        "focused_assert_ivflags="
        "-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT",
        "focused_release_ivflags="
        "-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon",
        "mutation_defines=-DOOO_ASSERT,"
        "-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED,"
        "-DV8Y_SPECULATION_RECOVERY_FOCUSED",
    ]
    if len(lines) != 7 or lines[:5] != expected_prefix:
        raise ValueError("OOO-4 simulator/config receipt is malformed")
    result = {
        "schema": "rv64-ooo4-simulator-config-v1",
        "target": "v8y-speculation-recovery",
        "focused_assert_ivflags": expected_prefix[2].split("=", 1)[1],
        "focused_release_ivflags": expected_prefix[3].split("=", 1)[1],
        "mutation_defines": expected_prefix[4].split("=", 1)[1],
    }
    for expected_role, line in zip(("iverilog", "vvp"), lines[5:]):
        fields = line.split(maxsplit=2)
        if (
            len(fields) != 3
            or fields[0] != expected_role
            or not arch.is_sha256(fields[1])
        ):
            raise ValueError(f"OOO-4 {expected_role} receipt is malformed")
        binary = pathlib.Path(fields[2]).resolve(strict=True)
        if not binary.is_file() or arch.digest(binary) != fields[1]:
            raise ValueError(f"OOO-4 {expected_role} binary digest is stale")
        result[f"{expected_role}_path"] = binary.as_posix()
        result[f"{expected_role}_sha256"] = fields[1]
    return result


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
    task_run_mode = args.proof_mode == "task-run-v1"
    task_run_id = args.task_run_id if task_run_mode else RUN_ID
    if task_run_mode:
        evidence_rel = task_run_evidence_rel(task_run_id, "ooo4-current")
        mutation_rel = task_run_evidence_rel(task_run_id, "ooo4-mutations")
        focused_assert_rel = evidence_rel / (
            "focused/assert/logs/"
            "tb_ooo_int_backend_v8y_speculation_recovery.log")
        focused_release_rel = evidence_rel / (
            "focused/release/logs/"
            "tb_ooo_int_backend_v8y_speculation_recovery.log")
        mutation_summary_rel = mutation_rel / "summary.json"
        suite_run_id_rel = evidence_rel / "suite-run-id.txt"
        source_pre_rel = evidence_rel / "sources.pre.sha256"
        source_post_rel = evidence_rel / "sources.post.sha256"
        simulator_config_rel = evidence_rel / "static/simulator-config.txt"
        regression_rels = {
            name: evidence_rel / f"regressions/logs/{name}.log"
            for name in REGRESSION_NAMES
        }
        mutation_log_rels = {
            name: mutation_rel / f"{name}.log"
            for name in REQUIRED_MUTATION_METRICS
        }
        predecessor_rel = None
    else:
        focused_assert_rel = FOCUSED_ASSERT_REL
        focused_release_rel = FOCUSED_RELEASE_REL
        mutation_summary_rel = MUTATION_SUMMARY_REL
        suite_run_id_rel = SUITE_RUN_ID_REL
        source_pre_rel = SOURCE_PRE_REL
        source_post_rel = SOURCE_POST_REL
        simulator_config_rel = SIMULATOR_CONFIG_REL
        regression_rels = REGRESSION_RELS
        mutation_log_rels = {
            name: pathlib.Path(
                f".github/task-runs/{RUN_ID}/evidence/mutations/{name}.log")
            for name in REQUIRED_MUTATION_METRICS
        }
        predecessor_rel = PREDECESSOR_LOG_REL
    assert_log = resolve_exact_input(
        root, args.assert_log, focused_assert_rel)
    release_log = resolve_exact_input(
        root, args.release_log, focused_release_rel)
    mutation_summary = resolve_exact_input(
        root, args.mutation_summary, mutation_summary_rel)
    suite_run_id_path = resolve_exact_input(
        root, args.suite_run_id_file, suite_run_id_rel)
    sources_pre = resolve_exact_input(root, args.sources_pre, source_pre_rel)
    sources_post = resolve_exact_input(root, args.sources_post, source_post_rel)
    simulator_config_path = resolve_exact_input(
        root, args.simulator_config, simulator_config_rel)
    simulator_config = validate_simulator_config(simulator_config_path)
    predecessor_log = (
        arch.safe_artifact(root, predecessor_rel.as_posix())
        if predecessor_rel is not None else None
    )
    regression_logs = {
        name: resolve_exact_input(root, value, regression_rels[name])
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
    mutation_payload, mutation_coverage = read_mutations(
        root, mutation_summary, suite_run_id, mutation_log_rels)
    reconstructed_mutations = validate_reconstructed_mutations(
        root, mutation_payload)

    source_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    manifest = workspace_output(root, args.manifest)
    if task_run_mode:
        if manifest.exists():
            raise ValueError("scoped OOO-4 manifest must start absent")
        predecessor_mode = "not_required_scoped_gate"
        before_manifest: dict[str, Any] = {"tests": {}}
    else:
        if predecessor_log is None:
            raise ValueError("canonical predecessor receipt is missing")
        predecessor_text = predecessor_log.read_text(encoding="utf-8")
        predecessor_mode = validate_predecessor_receipt(
            predecessor_text, design_id)
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
    if not task_run_mode:
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

    provenance_paths = (
        arch.SPECULATION_RECOVERY_SOURCE_PATHS
        if task_run_mode else arch.SPECULATION_RECOVERY_PROVENANCE_PATHS
    )
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in provenance_paths
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    proof_paths = {
        "focused_assert": assert_log,
        "focused_release": release_log,
        "mutation_summary": mutation_summary,
        "suite_run_id": suite_run_id_path,
        "sources_pre": sources_pre,
        "sources_post": sources_post,
        "simulator_config": simulator_config_path,
        **{
            f"regression_{name.removeprefix('tb_ooo_')}": path
            for name, path in regression_logs.items()
        },
        **{
            f"mutation_{name}": arch.safe_artifact(root, rel.as_posix())
            for name, rel in mutation_log_rels.items()
        },
    }
    if predecessor_log is not None:
        proof_paths["predecessor_receipt"] = predecessor_log
    if task_run_mode and set(proof_paths) != set(
        arch.SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES
    ):
        raise ValueError("scoped OOO-4 proof role inventory mismatch")
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths.values()
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
    gate_log = workspace_output(root, args.gate_log)
    gate_lines = [
        "OOO-4 local RV64 speculation and recovery evidence",
        f"task_run_id={task_run_id}",
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
            "reconstructed_sha256": reconstructed_mutations,
            "non_noop": reconstructed_mutations,
            "production_sources_unchanged": True,
        },
        "simulator_config": simulator_config,
        "predecessor_tests": sorted(
            set(before_manifest["tests"]) - {"speculation_recovery"}),
        "predecessor_evidence_mode": predecessor_mode,
        "provenance": {
            **({
                "mode": "task-run-v1",
                "proof_files": proof_files,
                "proof_sha256": arch.canonical_digest(proof_digest_map),
            } if task_run_mode else {}),
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
        f"metrics={len(metrics)} mutations={len(REQUIRED_MUTATION_METRICS)} "
        f"proof_mode={args.proof_mode}"
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
    builder.add_argument("--simulator-config", required=True, type=pathlib.Path)
    builder.add_argument("--gate-log", required=True, type=pathlib.Path)
    builder.add_argument("--manifest", required=True, type=pathlib.Path)
    builder.add_argument(
        "--proof-mode", choices=("canonical-v8y", "task-run-v1"),
        default="canonical-v8y")
    builder.add_argument("--task-run-id", default=RUN_ID)
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
