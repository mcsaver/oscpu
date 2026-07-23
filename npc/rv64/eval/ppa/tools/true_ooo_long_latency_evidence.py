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
MUTATIONS = {
    "serial_issue1",
    "miq_issue1_freeze",
    "muldiv_issue1_freeze",
    "retire_before_head_done",
    "load_owner_pid_truncate",
    "muldiv_owner_pid_truncate",
    "muldiv_resp_pid_truncate",
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
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    logs = (
        args.release_log.resolve(strict=True),
        args.assert_log.resolve(strict=True),
    )
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

    mutation_path = args.mutation_summary.resolve(strict=True)
    mutation_text = mutation_path.read_text(encoding="utf-8")
    observed_mutations = set(re.findall(
        r"^\[V8N-MUTATION\]\[PASS\] name=([a-z0-9_]+) "
        r"compile=PASS activation=PASS semantic_rejection=PASS$",
        mutation_text,
        flags=re.MULTILINE,
    ))
    if observed_mutations != MUTATIONS:
        raise ValueError(
            "mutation summary mismatch: "
            f"expected={sorted(MUTATIONS)} observed={sorted(observed_mutations)}"
        )

    pre_path = args.sources_pre.resolve(strict=True)
    post_path = args.sources_post.resolve(strict=True)
    if pre_path.read_bytes() != post_path.read_bytes():
        raise ValueError("canonical proof source hashes changed during mutations")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, rtl_files = arch.rtl_binding(root)
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.LONG_LATENCY_PROVENANCE_PATHS
    }
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in (*logs, mutation_path, pre_path)
        if path.is_relative_to(root)
    }

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "OOO-1 true long-latency directed evidence",
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
        },
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
