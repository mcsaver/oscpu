#!/usr/bin/env python3
"""Build hash-bound DI-4 no-static-lane-semantics directed evidence."""

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

RUN_ID = "2026-07-20-rv64-v8o-no-static-lane-semantics"
TASK_CONTRACT = pathlib.PurePosixPath(
    ".github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/"
    "subagent-contracts/v8o-no-static-lane-contract-review.json"
)
PASS_MARKER = (
    "[V8O-NO-STATIC-LANE-SEMANTICS] "
    "accepted-package/resident/capability/full-PID/canonical-fire PASS"
)
METRIC_PATTERN = re.compile(
    r"^\[V8O-NO-STATIC-LANE-METRICS\] "
    r"mode=(release|assert) permutations=([0-9]+) "
    r"static_lane_role_violations=([0-9]+) "
    r"same_cycle_pair_fires=([0-9]+) "
    r"exact_full_pid_matches=([0-9]+) accepted=([0-9]+) fired=([0-9]+)$",
    flags=re.MULTILINE,
)
WITNESS_PATTERN = re.compile(
    r"^\[V8O-SLOT-WITNESS\] class=([0-5]) slot=slot([01]) "
    r"accepted_same_edge=1 resident_full_cycle=1 pair_fire=1 "
    r"universal_pid_match=1 alu_pid_match=1 role_match=1 drain=1 "
    r"fire_time=([0-9]+)$",
    flags=re.MULTILINE,
)
MUTATIONS = {
    "disable_pair_swap",
    "static_entry_capability",
    "slot1_capability_capture",
    "muldiv_as_alu",
    "serialize_second_terminal",
    "corrupt_full_pid",
}
CLASS_NAMES = ("branch", "jal", "jalr", "load", "store", "muldiv")


def read_clean_log(path: pathlib.Path, expected_mode: str) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    if text.count(PASS_MARKER) != 1:
        raise ValueError(f"{path}: expected exactly one terminal marker")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for forbidden in ("[CHECK-FAIL]", "[RESULT] FAIL", "FATAL:"):
        if forbidden in text:
            raise ValueError(f"{path}: unexpected failure marker {forbidden}")
    if text.count("[V8O-SPLIT-ACCEPT-NEGATIVE] ") != 1:
        raise ValueError(f"{path}: split-accept negative is missing or repeated")
    metrics = METRIC_PATTERN.findall(text)
    if len(metrics) != 1 or metrics[0][0] != expected_mode:
        raise ValueError(f"{path}: unique {expected_mode} metrics missing")
    values = tuple(map(int, metrics[0][1:]))
    if values != (12, 0, 12, 24, 24, 24):
        raise ValueError(f"{path}: unexpected metric vector {values}")
    witnesses = WITNESS_PATTERN.findall(text)
    observed = {(int(kind), int(slot)) for kind, slot, _ in witnesses}
    expected = {(kind, slot) for kind in range(6) for slot in range(2)}
    if len(witnesses) != 12 or observed != expected:
        raise ValueError(f"{path}: class/slot witness matrix mismatch")
    times = [int(item[2]) for item in witnesses]
    if len(set(times)) != 12 or times != sorted(times):
        raise ValueError(f"{path}: fire timestamps are not unique/increasing")
    return {
        "permutations": values[0],
        "static_lane_role_violations": values[1],
        "same_cycle_pair_fires": values[2],
        "exact_full_pid_matches": values[3],
        "accepted": values[4],
        "fired": values[5],
    }


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
    parser.add_argument("--run-id", default=RUN_ID)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    release_log = args.release_log.resolve(strict=True)
    assert_log = args.assert_log.resolve(strict=True)
    release = read_clean_log(release_log, "release")
    asserted = read_clean_log(assert_log, "assert")
    if release != asserted:
        raise ValueError("release/assert metric vectors differ")

    mutation_path = args.mutation_summary.resolve(strict=True)
    mutation_text = mutation_path.read_text(encoding="utf-8")
    rows = re.findall(
        r"^\[V8O-MUTATION\]\[PASS\] name=([a-z0-9_]+) "
        r"source_sha256=([0-9a-f]{64}) image_sha256=([0-9a-f]{64}) "
        r"compile=PASS elaboration=PASS activation=PASS "
        r"semantic_rejection=PASS$",
        mutation_text,
        flags=re.MULTILINE,
    )
    observed_mutations = {row[0] for row in rows}
    if len(rows) != len(MUTATIONS) or observed_mutations != MUTATIONS:
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
        for rel in arch.NO_STATIC_LANE_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    task_contract_path = arch.safe_artifact(root, TASK_CONTRACT.as_posix())
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in (release_log, assert_log, mutation_path, pre_path)
        if path.is_relative_to(root)
    }

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "DI-4 no-static-lane-semantics directed evidence",
        f"run_id={args.run_id}",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        f"task_contract_json_sha256={arch.digest(task_contract_path)}",
        "task_contract_hash_scope=json-only-not-rtl-or-design-contract",
        "profiles=release,assert independently complete",
        "program_slot_permutations=12",
        "static_lane_role_violations=0",
        "same_cycle_pair_fires=12",
        "exact_full_pid_matches=24",
        "accepted_transactions=24",
        "fired_transactions=24",
        f"mutation_count={len(rows)}",
    ]
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] no_static_lane_semantics PASS "
        f"run_id={args.run_id} design_id=sha256:{source_sha} "
        f"provenance_sha256={provenance_sha}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    metrics = {
        "program_slot_permutation": {
            kind: {"slot0": True, "slot1": True}
            for kind in CLASS_NAMES
        },
        "static_lane_role_violations": 0,
        "same_cycle_pair_fires": release["same_cycle_pair_fires"],
        "exact_full_pid_matches": release["exact_full_pid_matches"],
    }
    record = {
        "command": arch.NO_STATIC_LANE_EVIDENCE_COMMAND,
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
            "integer-IQ accepted package positions and same-edge issue fires; "
            "not architectural completion, DI-3, DI-5, OOO-3, recovery or PPA"
        ),
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="no_static_lane_semantics",
        record=record,
    )
    print(
        "[V8O-EVIDENCE][PASS] no_static_lane_semantics "
        f"design_id=sha256:{source_sha} mutations={len(rows)}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnicodeDecodeError, ValueError) as exc:
        print(f"[V8O-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
