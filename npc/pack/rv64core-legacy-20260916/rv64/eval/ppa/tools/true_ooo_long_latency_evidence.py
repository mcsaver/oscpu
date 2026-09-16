#!/usr/bin/env python3
"""Build hash-bound OOO-1 true long-latency directed evidence."""

from __future__ import annotations

import argparse
import datetime
import importlib.util
import pathlib
import re
import sys

from directed_evidence_manifest import merge_directed_record


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

PASS_MARKER = (
    "[V8N-TRUE-OOO-LONG-LATENCY] load-miss/mul/div exact-PID "
    "completion and ordered-retire PASS"
)
METRIC_PATTERN = re.compile(
    r"^\[V8N-TRUE-OOO-METRICS\] "
    r"load_miss=([0-9]+) mul=([0-9]+) div=([0-9]+) "
    r"rob_peak=([0-9]+) retire_order_violations=([0-9]+)$",
    flags=re.MULTILINE,
)
BINDING_PATTERN = re.compile(
    r"^\[V8N-TRUE-OOO-BINDING\] "
    r"load_issue=([0-9]+) mul_issue=([0-9]+) div_issue=([0-9]+) "
    r"load_dual=([0-9]+) mul_dual=([0-9]+) div_dual=([0-9]+) "
    r"load_owner_live_wb=([0-9]+) mul_owner_live_wb=([0-9]+) "
    r"div_owner_live_wb=([0-9]+) rob_valid_peak=([0-9]+)$",
    flags=re.MULTILINE,
)
ACTIVATION_PATTERN = re.compile(
    r"^\[V8N-ACTIVATION\] scenario=(load_miss|v8n MUL|v8n DIVU) "
    r"owner_pid=([0-9]+) owner_live=1 issue_accept=([0-9]+) "
    r"dual_issue=([0-9]+) younger_wb=([0-9]+)$",
    flags=re.MULTILINE,
)
MUTATIONS = arch.LONG_LATENCY_MUTATION_NAMES
MUTATION_EXPECTATIONS = {
    "serial_issue1": ("load_miss", "v8n load four dual-issue accept cycles"),
    "miq_issue1_freeze": (
        "load_miss", "v8n load four dual-issue accept cycles"),
    "muldiv_issue1_freeze": (
        "v8n MUL", "v8n MUL four dual-issue accept cycles"),
    "retire_before_head_done": (
        "load_miss", "v8n load no retirement before old completion"),
    "load_owner_pid_truncate": (
        "load_miss", "v8n load completion identity prepared"),
    "muldiv_owner_pid_truncate": (
        "v8n MUL", "v8n MUL buffered owner exact ProducerId"),
    "muldiv_resp_pid_truncate": (
        "v8n MUL", "v8n MUL old WB exactly once"),
}
MUTATION_SOURCE_PATHS = {
    "serial_issue1": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "miq_issue1_freeze": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "muldiv_issue1_freeze": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "retire_before_head_done": "npc/rv64/vsrc/writeback/OooRob.v",
    "load_owner_pid_truncate": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "muldiv_owner_pid_truncate": "npc/rv64/vsrc/execute/OooMulDivUnit.v",
    "muldiv_resp_pid_truncate": "npc/rv64/vsrc/execute/OooMulDivUnit.v",
}


def read_clean_log(path: pathlib.Path) -> tuple[dict[str, int], dict[str, int]]:
    text = path.read_text(encoding="utf-8")
    if text.count(PASS_MARKER) != 1:
        raise ValueError(f"{path}: expected exactly one terminal marker")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for forbidden in ("[CHECK-FAIL]", "[RESULT] FAIL", "FATAL:"):
        if forbidden in text:
            raise ValueError(f"{path}: unexpected failure marker {forbidden}")
    metrics = METRIC_PATTERN.findall(text)
    bindings = BINDING_PATTERN.findall(text)
    activations = ACTIVATION_PATTERN.findall(text)
    if len(metrics) != 1 or len(bindings) != 1:
        raise ValueError(f"{path}: metric/binding record is not unique")
    if len(activations) != 3:
        raise ValueError(f"{path}: expected exactly three activation witnesses")
    activation_map = {name: tuple(map(int, values))
                      for name, *values in activations}
    if set(activation_map) != {"load_miss", "v8n MUL", "v8n DIVU"}:
        raise ValueError(f"{path}: activation scenario set mismatch")
    for name, (owner_pid, issued, dual, completed) in activation_map.items():
        if owner_pid < 16 or (issued, dual, completed) != (8, 4, 8):
            raise ValueError(
                f"{path}: invalid activation {name}: "
                f"pid={owner_pid} issue={issued} dual={dual} wb={completed}"
            )
    metric_values = tuple(map(int, metrics[0]))
    binding_values = tuple(map(int, bindings[0]))
    return ({
        "load_miss": metric_values[0],
        "mul": metric_values[1],
        "div": metric_values[2],
        "rob_peak": metric_values[3],
        "retire_order_violations": metric_values[4],
    }, {
        "load_issue": binding_values[0],
        "mul_issue": binding_values[1],
        "div_issue": binding_values[2],
        "load_dual": binding_values[3],
        "mul_dual": binding_values[4],
        "div_dual": binding_values[5],
        "load_owner_live_wb": binding_values[6],
        "mul_owner_live_wb": binding_values[7],
        "div_owner_live_wb": binding_values[8],
        "rob_valid_peak": binding_values[9],
    })


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
        raise ValueError("malformed local RV64 OOO-1 task-run id")
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
        "schema=rv64-ooo1-simulator-config-v1",
        "target=v8n-true-ooo-long-latency",
        "release_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon",
        "assert_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT",
        "mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon",
    ]
    if len(lines) != 7 or lines[:5] != expected_prefix:
        raise ValueError("OOO-1 simulator/config receipt is malformed")
    result = {
        "schema": "rv64-ooo1-simulator-config-v1",
        "target": "v8n-true-ooo-long-latency",
    }
    for expected_role, line in zip(("iverilog", "vvp"), lines[5:]):
        fields = line.split(maxsplit=2)
        if (
            len(fields) != 3
            or fields[0] != expected_role
            or not arch.is_sha256(fields[1])
        ):
            raise ValueError(f"OOO-1 {expected_role} receipt is malformed")
        binary = pathlib.Path(fields[2]).resolve(strict=True)
        if not binary.is_file() or arch.digest(binary) != fields[1]:
            raise ValueError(f"OOO-1 {expected_role} binary digest is stale")
        result[f"{expected_role}_path"] = binary.as_posix()
        result[f"{expected_role}_sha256"] = fields[1]
    return result


def validate_mutation_proof(
    root: pathlib.Path,
    name: str,
    mutator_log: pathlib.Path,
    simulation_log: pathlib.Path,
) -> None:
    mutator_text = mutator_log.read_text(encoding="utf-8")
    hash_pattern = re.compile(
        rf"^\[V8N-MUTATION-HASH\] name={re.escape(name)} "
        r"source_sha256=([0-9a-f]{64}) mutant_sha256=([0-9a-f]{64}) "
        r"image_sha256=([0-9a-f]{64})$",
        flags=re.MULTILINE,
    )
    matches = hash_pattern.findall(mutator_text)
    if len(matches) != 1:
        raise ValueError(f"{name}: mutation hash receipt is not unique")
    source_sha, mutant_sha, _image_sha = matches[0]
    live_source = arch.safe_artifact(root, MUTATION_SOURCE_PATHS[name])
    if source_sha != arch.digest(live_source) or source_sha == mutant_sha:
        raise ValueError(f"{name}: mutation source/hash binding is invalid")

    scenario, failure = MUTATION_EXPECTATIONS[name]
    simulation_text = simulation_log.read_text(encoding="utf-8")
    required = (
        f"[V8N-ACTIVATION] scenario={scenario}",
        f"[CHECK-FAIL] {failure}",
    )
    if any(simulation_text.count(marker) < 1 for marker in required):
        raise ValueError(f"{name}: dynamic rejection marker is missing")
    if (
        simulation_text.count("[RESULT] FAIL") != 1
        or "[RESULT] PASS" in simulation_text
    ):
        raise ValueError(f"{name}: mutation result is not a clean rejection")
    if name == "muldiv_issue1_freeze":
        for marker in (
            "[V8N-ACTIVATION] scenario=v8n DIVU",
            "[CHECK-FAIL] v8n DIVU four dual-issue accept cycles",
        ):
            if simulation_text.count(marker) < 1:
                raise ValueError(
                    "muldiv_issue1_freeze: DIVU sensitivity is missing")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--release-log", required=True, type=pathlib.Path)
    parser.add_argument("--assert-log", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    parser.add_argument("--sources-pre", required=True, type=pathlib.Path)
    parser.add_argument("--sources-post", required=True, type=pathlib.Path)
    parser.add_argument("--gate-log", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    parser.add_argument(
        "--proof-mode",
        choices=("canonical-v8n", "task-run-v1"),
        default="canonical-v8n",
    )
    parser.add_argument(
        "--task-run-id",
        default="2026-07-20-rv64-v8n-true-ooo-long-latency",
    )
    parser.add_argument("--simulator-config", type=pathlib.Path)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    task_run_mode = args.proof_mode == "task-run-v1"
    task_run_id = args.task_run_id
    mutator_logs: dict[str, pathlib.Path] = {}
    simulation_logs: dict[str, pathlib.Path] = {}
    simulator_config_path: pathlib.Path | None = None
    if task_run_mode:
        evidence_rel = task_run_evidence_rel(task_run_id, "ooo1-current")
        evidence_root_rel = evidence_rel.parent
        release_log = resolve_exact_input(
            root,
            args.release_log,
            evidence_rel / "baseline-release/logs/tb_ooo_int_backend.log",
        )
        assert_log = resolve_exact_input(
            root,
            args.assert_log,
            evidence_rel / "baseline-assert/logs/tb_ooo_int_backend.log",
        )
        mutation_path = resolve_exact_input(
            root, args.mutation_summary, evidence_rel / "mutation-summary.log")
        pre_path = resolve_exact_input(
            root, args.sources_pre, evidence_rel / "sources.pre.sha256")
        post_path = resolve_exact_input(
            root, args.sources_post, evidence_rel / "sources.post.sha256")
        if args.simulator_config is None:
            raise ValueError("task-run OOO-1 proof requires simulator config")
        simulator_config_path = resolve_exact_input(
            root,
            args.simulator_config,
            evidence_rel / "static/simulator-config.txt",
        )
        validate_simulator_config(simulator_config_path)
        for name in MUTATIONS:
            mutator_logs[name] = resolve_exact_input(
                root,
                evidence_rel / f"mutation-{name}.mutator.log",
                evidence_rel / f"mutation-{name}.mutator.log",
            )
            simulation_logs[name] = resolve_exact_input(
                root,
                evidence_rel / f"mutation-{name}/logs/tb_ooo_int_backend.log",
                evidence_rel / f"mutation-{name}/logs/tb_ooo_int_backend.log",
            )
            validate_mutation_proof(
                root, name, mutator_logs[name], simulation_logs[name])
        expected_manifest = (root / evidence_root_rel / "architecture-current.json").resolve()
        expected_gate_log = (
            root / evidence_root_rel / "true-ooo-long-latency.log").resolve()
        if workspace_output(root, args.manifest) != expected_manifest:
            raise ValueError("scoped OOO-1 manifest path mismatch")
        if workspace_output(root, args.gate_log) != expected_gate_log:
            raise ValueError("scoped OOO-1 gate-log path mismatch")
        if expected_manifest.exists():
            raise ValueError("scoped OOO-1 manifest must start absent")
    else:
        release_log = args.release_log.resolve(strict=True)
        assert_log = args.assert_log.resolve(strict=True)
        mutation_path = args.mutation_summary.resolve(strict=True)
        pre_path = args.sources_pre.resolve(strict=True)
        post_path = args.sources_post.resolve(strict=True)
    logs = (release_log, assert_log)
    parsed = [read_clean_log(path) for path in logs]
    if parsed[0] != parsed[1]:
        raise ValueError("release/assert machine metrics differ")
    core, binding = parsed[0]
    if ((core["load_miss"], core["mul"], core["div"],
         core["rob_peak"], core["retire_order_violations"])
            != (8, 8, 8, 9, 0)):
        raise ValueError(f"unexpected core metrics: {core}")
    if tuple(binding.values()) != (8, 8, 8, 4, 4, 4, 8, 8, 8, 9):
        raise ValueError(f"unexpected binding metrics: {binding}")

    mutation_text = mutation_path.read_text(encoding="utf-8")
    observed_mutations = set(re.findall(
        r"^\[V8N-MUTATION\]\[PASS\] name=([a-z0-9_]+) "
        r"compile=PASS activation=PASS semantic_rejection=PASS$",
        mutation_text,
        flags=re.MULTILINE,
    ))
    if observed_mutations != set(MUTATIONS):
        raise ValueError(
            "mutation summary mismatch: "
            f"expected={sorted(MUTATIONS)} observed={sorted(observed_mutations)}"
        )

    if pre_path.read_bytes() != post_path.read_bytes():
        raise ValueError("canonical proof source hashes changed during mutations")
    if task_run_mode:
        pre_sources = arch.validate_source_manifest(
            root, pre_path, arch.LONG_LATENCY_SOURCE_PATHS)
        post_sources = arch.validate_source_manifest(
            root, post_path, arch.LONG_LATENCY_SOURCE_PATHS)
        if pre_sources != post_sources:
            raise ValueError("current OOO-1 proof source maps differ")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, rtl_files = arch.rtl_binding(root)
    provenance_paths = (
        arch.LONG_LATENCY_SOURCE_PATHS
        if task_run_mode else arch.LONG_LATENCY_PROVENANCE_PATHS
    )
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in provenance_paths
    }
    proof_paths = {
        "baseline_release": release_log,
        "baseline_assert": assert_log,
        "mutation_summary": mutation_path,
        "sources_pre": pre_path,
        "sources_post": post_path,
    }
    if simulator_config_path is not None:
        proof_paths["simulator_config"] = simulator_config_path
    proof_paths.update({f"mutator_{name}": path
                        for name, path in mutator_logs.items()})
    proof_paths.update({f"simulation_{name}": path
                        for name, path in simulation_logs.items()})
    if task_run_mode and set(proof_paths) != set(
        arch.LONG_LATENCY_TASK_RUN_PROOF_ROLES
    ):
        raise ValueError("scoped OOO-1 proof role inventory mismatch")
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths.values()
        if path.is_relative_to(root)
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
        "OOO-1 true long-latency directed evidence",
        f"task_run_id={task_run_id}",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        f"rtl_file_count={len(rtl_files)}",
        "profiles=release,assert",
        "load_miss_younger_completed=8",
        "mul_younger_completed=8",
        "div_younger_completed=8",
        "dual_issue_cycles=load_miss:4,mul:4,div:4",
        "owner_live_younger_completions=load_miss:8,mul:8,div:8",
        "rob_peak=9",
        "rob_valid_entries_peak=9",
        "retire_order_violations=0",
        f"mutation_count={len(observed_mutations)}",
    ]
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append("[ARCH-GATE] true_ooo_long_latency PASS")
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "command": arch.LONG_LATENCY_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": {
            "dual_issue_cycles_under_owner": {
                "load_miss": binding["load_dual"],
                "mul": binding["mul_dual"],
                "div": binding["div_dual"],
            },
            "owner_live_younger_completions": {
                "load_miss": binding["load_owner_live_wb"],
                "mul": binding["mul_owner_live_wb"],
                "div": binding["div_owner_live_wb"],
            },
            "retire_order_violations": core["retire_order_violations"],
            "rob_peak": core["rob_peak"],
            "rob_valid_entries_peak": binding["rob_valid_peak"],
            "younger_completed_before_old": {
                "load_miss": core["load_miss"],
                "mul": core["mul"],
                "div": core["div"],
            },
            "younger_issue_accepted_under_owner": {
                "load_miss": binding["load_issue"],
                "mul": binding["mul_issue"],
                "div": binding["div_issue"],
            },
        },
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": arch.canonical_digest(provenance_files),
            **({
                "mode": "task-run-v1",
                "proof_files": proof_files,
                "proof_sha256": arch.canonical_digest(proof_digest_map),
            } if task_run_mode else {}),
        },
        "task_run_id": task_run_id,
        "scope": "cacheable-no-fault-no-store latency tolerance; not OOO-3",
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="true_ooo_long_latency",
        record=record,
    )
    print(
        "[V8N-EVIDENCE][PASS] true_ooo_long_latency "
        f"design_id=sha256:{source_sha} mutations={len(observed_mutations)}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnicodeDecodeError, ValueError) as exc:
        print(f"[V8N-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
