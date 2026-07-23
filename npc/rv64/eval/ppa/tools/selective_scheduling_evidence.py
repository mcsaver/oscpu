#!/usr/bin/env python3
"""Build hash-bound OOO-2 selective-scheduling directed evidence."""

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

BACKEND_MARKER = (
    "[V8M-SELECTIVE-SCHEDULING] real owner/dependent/same-resource/"
    "independent identity PASS"
)
LEAF_MARKER = "[R3P1-REGISTERED-OWNER-SOLE-ALU] PASS"
METRIC_PATTERN = re.compile(
    r"^\[V8M-SELECTIVE-METRICS\] "
    r"blocked_dependents_only=1 "
    r"younger_independent_issued=1 "
    r"different_resource_issued=1 "
    r"global_freeze_cycles=0 "
    r"target_pid=([0-9]+)$",
    flags=re.MULTILINE,
)
MUTATIONS = {
    "backend_owner_binding",
    "dispatch_owner_forwarding",
    "selector_owner_to_alu",
    "iq_issue1_owner_mask",
    "backend_issue1_ready_mask",
}


def read_clean_log(path: pathlib.Path, marker: str) -> str:
    text = path.read_text(encoding="utf-8")
    if text.count(marker) != 1:
        raise ValueError(f"{path}: expected exactly one marker: {marker}")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for forbidden in ("[CHECK-FAIL]", "[RESULT] FAIL", "FATAL:"):
        if forbidden in text:
            raise ValueError(f"{path}: unexpected failure marker {forbidden}")
    return text


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
    parser.add_argument("--backend-release-log", required=True, type=pathlib.Path)
    parser.add_argument("--backend-assert-log", required=True, type=pathlib.Path)
    parser.add_argument("--leaf-release-log", required=True, type=pathlib.Path)
    parser.add_argument("--leaf-assert-log", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    parser.add_argument("--sources-pre", required=True, type=pathlib.Path)
    parser.add_argument("--sources-post", required=True, type=pathlib.Path)
    parser.add_argument("--gate-log", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    backend_logs = (
        args.backend_release_log.resolve(strict=True),
        args.backend_assert_log.resolve(strict=True),
    )
    leaf_logs = (
        args.leaf_release_log.resolve(strict=True),
        args.leaf_assert_log.resolve(strict=True),
    )
    target_pids: list[int] = []
    for path in backend_logs:
        text = read_clean_log(path, BACKEND_MARKER)
        metric_match = METRIC_PATTERN.findall(text)
        if len(metric_match) != 1:
            raise ValueError(f"{path}: selective metric record is not unique")
        target_pids.append(int(metric_match[0]))
    for path in leaf_logs:
        read_clean_log(path, LEAF_MARKER)

    mutation_text = args.mutation_summary.resolve(
        strict=True).read_text(encoding="utf-8")
    observed_mutations = set(re.findall(
        r"^\[V8M-MUTATION\]\[PASS\] name=([a-z0-9_]+) "
        r"compile=PASS semantic_rejection=PASS$",
        mutation_text,
        flags=re.MULTILINE,
    ))
    if observed_mutations != MUTATIONS:
        raise ValueError(
            "mutation summary mismatch: "
            f"expected={sorted(MUTATIONS)} observed={sorted(observed_mutations)}"
        )

    pre = args.sources_pre.resolve(strict=True).read_bytes()
    post = args.sources_post.resolve(strict=True).read_bytes()
    if pre != post:
        raise ValueError("canonical proof source hashes changed during mutations")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, _ = arch.rtl_binding(root)
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.SELECTIVE_PROVENANCE_PATHS
    }
    evidence_hashes = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in (*backend_logs, *leaf_logs)
        if path.is_relative_to(root)
    }
    evidence_hashes[
        args.mutation_summary.resolve(strict=True).relative_to(root).as_posix()
    ] = arch.digest(args.mutation_summary.resolve(strict=True))
    evidence_hashes[
        args.sources_pre.resolve(strict=True).relative_to(root).as_posix()
    ] = arch.digest(args.sources_pre.resolve(strict=True))

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "OOO-2 selective-scheduling directed evidence",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        "backend_profiles=release,assert",
        "leaf_profiles=release,assert",
        f"target_producer_ids={','.join(str(value) for value in target_pids)}",
        "blocked_dependents_only=true",
        "younger_independent_issued=true",
        "different_resource_issued=true",
        "global_freeze_cycles=0",
        f"mutation_count={len(observed_mutations)}",
    ]
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}" for path, sha in sorted(
            evidence_hashes.items())
    )
    gate_lines.append("[ARCH-GATE] selective_scheduling PASS")
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "command": arch.SELECTIVE_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": {
            "blocked_dependents_only": True,
            "different_resource_issued": True,
            "global_freeze_cycles": 0,
            "younger_independent_issued": True,
        },
        "provenance": {
            "files": provenance_files,
            "sha256": arch.canonical_digest(provenance_files),
        },
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="selective_scheduling",
        record=record,
    )
    print(
        "[V8M-EVIDENCE][PASS] selective_scheduling "
        f"design_id=sha256:{source_sha} mutations={len(observed_mutations)}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError) as exc:
        print(f"[V8M-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
