#!/usr/bin/env python3
"""Build hash-bound DI-3 pair-matrix directed evidence."""

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

RUN_ID = "2026-07-20-rv64-v8p-dual-memory-terminal-owners"
PASS_MARKER = "[V8P-PAIR-MATRIX] mask=7fff memory_pids=8 PASS"
METRIC_PATTERN = re.compile(
    r"^\[V8P-PAIR-METRICS\] mode=(release|assert) "
    r"pair_fires=15 memory_pair_fires=4 full_pids=8 "
    r"nonzero_generation_pids=8 dual_reservations=4 "
    r"distinct_token_pairs=4 dual_agu_matches=8 "
    r"store_store_exact_binds=2 special_exclusions=10 "
    r"raw_fallthrough_violations=0 bank1_age_bypass_violations=0 "
    r"owner_ghosts=0$",
    flags=re.MULTILINE,
)
MEMORY_PATTERN = re.compile(
    r"^\[V8P-MEMORY-PAIR\] bit=(1[1-4]) pid0=([0-9a-fA-F]+) "
    r"pid1=([0-9a-fA-F]+) addr0=([0-9a-fA-F]+) "
    r"addr1=([0-9a-fA-F]+) PASS$",
    flags=re.MULTILINE,
)
SPECIAL_PATTERN = re.compile(
    r"^\[V8P-SPECIAL-MEMORY-EXCLUSION\] kind=([0-4]) older=([01]) "
    r"resident=2 terminal1=0 PASS$",
    flags=re.MULTILINE,
)
MUTATIONS = {
    "serialize_memory_pair",
    "split_pair_ready",
    "bank1_tieoff",
    "owner1_tieoff",
    "alloc0_only_birth",
    "token_alias",
    "bank1_raw_fallthrough",
    "agu1_bank0_copy",
    "sq_bind1_lost",
    "sq_bind1_cross",
    "special_misadmission",
    "bank1_age_bypass",
    "pid1_truncation",
    "bank1_cancel_leak",
    "checker_vacuity",
}


def require_clean_result(path: pathlib.Path) -> str:
    text = path.read_text(encoding="utf-8")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for forbidden in ("[CHECK-FAIL]", "[RESULT] FAIL", "FATAL:"):
        if forbidden in text:
            raise ValueError(f"{path}: unexpected failure marker {forbidden}")
    return text


def read_backend(path: pathlib.Path, expected_mode: str) -> dict[str, int]:
    text = require_clean_result(path)
    if text.count(PASS_MARKER) != 1:
        raise ValueError(f"{path}: unique pair-matrix PASS marker missing")
    metrics = METRIC_PATTERN.findall(text)
    if metrics != [expected_mode]:
        raise ValueError(f"{path}: unique {expected_mode} metric row missing")

    matrix_rows = re.findall(
        r"^PAIR_MATRIX ([a-z_]+)=([01])$", text, flags=re.MULTILINE)
    if len(matrix_rows) != len(arch.PAIR_MATRIX):
        raise ValueError(f"{path}: pair-matrix row count is not fifteen")
    matrix = {name: value == "1" for name, value in matrix_rows}
    if (set(matrix) != set(arch.PAIR_MATRIX)
            or not all(matrix.values())
            or len({name for name, _ in matrix_rows}) != len(matrix_rows)):
        raise ValueError(f"{path}: pair-matrix exact key/value set mismatch")

    accept_bits = {
        int(value) for value in re.findall(
            r"^\[V8P-PAIR-ACCEPT\] bit=([0-9]+).*? PASS$",
            text,
            flags=re.MULTILINE,
        )
    }
    memory_rows = MEMORY_PATTERN.findall(text)
    memory_bits = {int(row[0]) for row in memory_rows}
    if len(memory_rows) != 4 or memory_bits != {11, 12, 13, 14}:
        raise ValueError(f"{path}: four real memory-pair witnesses missing")
    if accept_bits | memory_bits != set(range(15)):
        raise ValueError(f"{path}: actual-fire witness set is not 0..14")
    pids = [int(value, 16) for row in memory_rows for value in row[1:3]]
    if len(set(pids)) != 8 or any((pid >> 4) == 0 for pid in pids):
        raise ValueError(f"{path}: full-PID witnesses are not distinct/nonzero-gen")
    if any(int(row[3], 16) == int(row[4], 16) for row in memory_rows):
        raise ValueError(f"{path}: dual AGU addresses did not differ")

    special_rows = SPECIAL_PATTERN.findall(text)
    special = {(int(kind), int(order)) for kind, order in special_rows}
    if len(special_rows) != 10 or special != {
        (kind, order) for kind in range(5) for order in range(2)
    }:
        raise ValueError(f"{path}: special-memory exclusion matrix mismatch")
    return {
        "same_cycle_pair_fires": 15,
        "same_cycle_memory_pair_fires": 4,
        "distinct_nonzero_generation_memory_pids": 8,
        "dual_reservation_observations": 4,
        "distinct_owner_token_pairs": 4,
        "captured_agu_matches": 8,
        "store_store_exact_owner_binds": 2,
        "special_memory_exclusions": 10,
        "raw_fallthrough_violations": 0,
        "bank1_age_bypass_violations": 0,
        "owner_ghosts_after_cancel": 0,
    }


def read_tracker(path: pathlib.Path) -> None:
    text = require_clean_result(path)
    marker = (
        "[V8P-TRACKER-ATOMIC-SCARCITY] "
        "split ready causes zero owner births PASS"
    )
    if text.count(marker) != 1:
        raise ValueError(f"{path}: atomic scarcity witness missing")


def read_collector(path: pathlib.Path) -> None:
    text = require_clean_result(path)
    capture = re.findall(
        r"^\[V8P-TCOLL-12INGRESS-CAPTURE\] pending=12 mask=([0-9a-f]+) PASS$",
        text,
        flags=re.MULTILINE,
    )
    drain = re.findall(
        r"^\[V8P-TCOLL-12INGRESS-DRAIN\] seen=12 mask=([0-9a-f]+) PASS$",
        text,
        flags=re.MULTILINE,
    )
    if (
        len(capture) != 1
        or drain != capture
        or int(capture[0], 16).bit_count() != 12
    ):
        raise ValueError(f"{path}: twelve-ingress capture/drain witness mismatch")


def read_store_queue(path: pathlib.Path) -> None:
    text = require_clean_result(path)
    marker = "[V8P-SQ-DUAL-BIND] two exact STORE owners bound on one edge PASS"
    if text.count(marker) != 1:
        raise ValueError(f"{path}: exact dual SQ bind witness missing")


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
    parser.add_argument("--tracker-release-log", required=True, type=pathlib.Path)
    parser.add_argument("--tracker-assert-log", required=True, type=pathlib.Path)
    parser.add_argument("--collector-release-log", required=True, type=pathlib.Path)
    parser.add_argument("--collector-assert-log", required=True, type=pathlib.Path)
    parser.add_argument("--sq-release-log", required=True, type=pathlib.Path)
    parser.add_argument("--sq-assert-log", required=True, type=pathlib.Path)
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
    metrics_release = read_backend(backend_logs[0], "release")
    metrics_assert = read_backend(backend_logs[1], "assert")
    if metrics_release != metrics_assert:
        raise ValueError("release/assert pair metrics differ")

    tracker_logs = (
        args.tracker_release_log.resolve(strict=True),
        args.tracker_assert_log.resolve(strict=True),
    )
    collector_logs = (
        args.collector_release_log.resolve(strict=True),
        args.collector_assert_log.resolve(strict=True),
    )
    sq_logs = (
        args.sq_release_log.resolve(strict=True),
        args.sq_assert_log.resolve(strict=True),
    )
    for path in tracker_logs:
        read_tracker(path)
    for path in collector_logs:
        read_collector(path)
    for path in sq_logs:
        read_store_queue(path)

    mutation_path = args.mutation_summary.resolve(strict=True)
    rows = re.findall(
        r"^\[V8P-MUTATION\]\[PASS\] name=([a-z0-9_]+) "
        r"source_sha256=([0-9a-f]{64}) image_sha256=([0-9a-f]{64}) "
        r"compile=PASS elaboration=PASS activation=PASS rejection=PASS "
        r"oracle=(simulation|source_checker)$",
        mutation_path.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    observed = {row[0] for row in rows}
    if len(rows) != len(MUTATIONS) or observed != MUTATIONS:
        raise ValueError(
            "mutation summary mismatch: "
            f"expected={sorted(MUTATIONS)} observed={sorted(observed)}"
        )
    oracle = {row[0]: row[3] for row in rows}
    if oracle.get("checker_vacuity") != "source_checker" or any(
        value != "simulation" for name, value in oracle.items()
        if name != "checker_vacuity"
    ):
        raise ValueError("mutation rejection oracle assignment mismatch")

    pre_path = args.sources_pre.resolve(strict=True)
    post_path = args.sources_post.resolve(strict=True)
    if pre_path.read_bytes() != post_path.read_bytes():
        raise ValueError("canonical proof sources changed during mutations")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, rtl_files = arch.rtl_binding(root)
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.PAIR_MATRIX_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)
    artifact_paths = (
        *backend_logs, *tracker_logs, *collector_logs, *sq_logs,
        mutation_path, pre_path,
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in artifact_paths if path.is_relative_to(root)
    }

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "DI-3 dual-memory terminal-owner pair-matrix evidence",
        f"run_id={RUN_ID}",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        "profiles=release,assert independently complete",
        "pair_matrix_keys=15",
        "same_cycle_memory_pair_fires=4",
        "distinct_nonzero_generation_memory_pids=8",
        "special_memory_exclusions=10",
        "atomic_scarcity_zero_births=1",
        "collector_ingress_peak=12",
        f"mutation_count={len(rows)}",
    ]
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] pair_matrix PASS "
        f"run_id={RUN_ID} design_id=sha256:{source_sha} "
        f"provenance_sha256={provenance_sha}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    metrics = {
        "pair_matrix": {name: True for name in arch.PAIR_MATRIX},
        **metrics_release,
        "atomic_scarcity_zero_births": 1,
        "collector_ingress_peak": 12,
        "collector_exact_drains": 12,
    }
    record = {
        "command": arch.PAIR_MATRIX_EVIDENCE_COMMAND,
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
            "DI-3 pair formation through two registered ordinary-integer "
            "memory terminal owners; serialized downstream memory service; "
            "not DI-5, OOO-3, overall architecture or PPA"
        ),
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="pair_matrix",
        record=record,
    )
    print(
        "[V8P-EVIDENCE][PASS] pair_matrix "
        f"design_id=sha256:{source_sha} mutations={len(rows)}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnicodeDecodeError, ValueError) as exc:
        print(f"[V8P-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
