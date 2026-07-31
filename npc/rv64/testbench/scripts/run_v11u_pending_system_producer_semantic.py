#!/usr/bin/env python3
"""Run current-source pending-system ProducerId lifecycle evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v11u-pending-system-producer-semantic-evidence-v1"
UNIT_IDS = ("pending-system-producer",)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_control_plane."
    "u_pending_system_sequencer"
)
GEN_WIDTHS = (1, 4)
BASE_IVFLAGS = "-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"

SEQUENCER = "npc/rv64/vsrc/control/OooPendingSystemSequencer.v"
CSR_MUX = "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v"
INT_BACKEND = "npc/rv64/vsrc/execute/OooIntBackend.v"
DEFINE = "npc/rv64/vsrc/include/define.v"
TB_SEQUENCER = "npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv"
TB_LEASE_PROBE = (
    "npc/rv64/testbench/tests/tb_ooo_pending_system_lease_probe.sv"
)
TB_CSR_MUX = "npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv"
TB_INT_BACKEND = "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
MAKEFILE = "npc/rv64/testbench/Makefile"

TEST_SEQUENCER = "tb_ooo_pending_system_sequencer"
TEST_LEASE_PROBE = "tb_ooo_pending_system_lease_probe"
TEST_CSR_MUX = "tb_ooo_csr_access_request_mux"
TEST_INT_BACKEND = "tb_ooo_int_backend"

REGRESSIONS = (
    TEST_SEQUENCER,
    TEST_CSR_MUX,
    "tb_ooo_pending_system_admission_cancel_gate",
    "tb_ooo_pending_drain_resolve_gate",
)


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    source: str
    override: str
    test: str
    expected_marker: str
    replacements: tuple[Replacement, ...]
    widths: tuple[int, ...] = (4,)
    extra_defines: tuple[str, ...] = ()


@dataclass(frozen=True)
class Profile:
    name: str
    kind: str
    tests: tuple[str, ...]
    gen_width: int
    assertions: bool = False
    extra_defines: tuple[str, ...] = ()
    required_markers: tuple[tuple[str, str, int], ...] = ()
    expected_failure_marker: str | None = None
    mutation: str | None = None


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


DISPATCH_BIRTH = """\
  wire dispatch_birth_w =
      dispatch_fire_i && valid_q && (kind_q == SERIAL_KIND_CSR) && !dispatched_q &&
      !producer_valid_q && !clear_i;
"""
PENDING_MASK_UNION = """\
      clmul_owner_producer_live_mask_w |
      fp_producer_live_mask_w |
      pending_system_producer_live_mask_w |
      transient_producer_live_mask_w;
"""


MUTATIONS = (
    Mutation(
        "lease-output-metadata-gated",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-PARTIAL-METADATA]",
        (
            replacement(
                "  assign producer_valid_o = producer_valid_q;\n",
                "  assign producer_valid_o = producer_valid_q && valid_q &&\n"
                "      (kind_q == SERIAL_KIND_CSR) && dispatched_q;\n",
                "gate the raw lease output with mutable metadata",
            ),
        ),
        extra_defines=("-DV8K_PROBE_PARTIAL_METADATA",),
    ),
    Mutation(
        "ordinary-clear-kills-live",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-LIVE-CLEAR]",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (producer_death_i || clear_i) begin\n",
                "allow an ordinary pending clear to kill a live lease",
            ),
        ),
        extra_defines=("-DV8K_PROBE_LIVE_CLEAR",),
    ),
    Mutation(
        "clear-dispatched-kills-live",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-LIVE-CDISP]",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (producer_death_i || clear_dispatched_i) begin\n",
                "allow orphan cleanup to cut a live lease",
            ),
        ),
        extra_defines=("-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",),
    ),
    Mutation(
        "birth-drops-generation",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_SEQUENCER,
        "FAIL head0 lease pid",
        (
            replacement(
                "      producer_id_q <= dispatch_producer_id_i;\n",
                "      producer_id_q <= {{PRODUCER_GEN_W{1'b0}},\n"
                "          dispatch_producer_id_i[ROB_INDEX_W-1:0]};\n",
                "drop the generation at the exact ROB allocation edge",
            ),
        ),
        widths=GEN_WIDTHS,
    ),
    Mutation(
        "noncsr-dispatch-birth-widened",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V11U-PROBE-NONCSR-DISPATCH]",
        (
            replacement(
                DISPATCH_BIRTH,
                DISPATCH_BIRTH.replace(
                    "(kind_q == SERIAL_KIND_CSR)",
                    "(kind_q != SERIAL_KIND_NONE)",
                ),
                "allow a non-CSR serialized kind to birth a ProducerId",
            ),
        ),
        extra_defines=("-DV11U_PROBE_NONCSR_DISPATCH",),
    ),
    Mutation(
        "exact-death-disabled",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_SEQUENCER,
        "ordinary clear cross dispatched",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (1'b0 && producer_death_i) begin\n",
                "disconnect exact pending-CSR death",
            ),
        ),
    ),
    Mutation(
        "claim-seal-ignores-raw",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_claim_seal_w =\n"
                "      pending_system_producer_valid_i || "
                "pending_system_csr_logical_claim_w;\n",
                "  wire pending_system_csr_claim_seal_w =\n"
                "      pending_system_csr_logical_claim_w;\n",
                "let a raw-only lease reopen queue-head CSR fallback",
            ),
        ),
        extra_defines=("-DOOO_CSR_QUEUE_HEAD=1",),
    ),
    Mutation(
        "pid-match-ignores-generation",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_pid_match_w =\n"
                "      core_commit0_producer_id_i == "
                "pending_system_producer_id_i;\n",
                "  wire pending_system_csr_pid_match_w =\n"
                "      core_commit0_producer_id_i[ROB_INDEX_W-1:0] ==\n"
                "      pending_system_producer_id_i[ROB_INDEX_W-1:0];\n",
                "authorize commit with a raw ROB index only",
            ),
        ),
        widths=GEN_WIDTHS,
    ),
    Mutation(
        "pc-coherence-removed",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_pc_match_w =\n"
                "      core_commit0_pc_i == pending_system_pc_i;\n",
                "  wire pending_system_csr_pc_match_w = 1'b1;\n",
                "remove the independent commit PC coherence check",
            ),
        ),
    ),
    Mutation(
        "pending-live-mask-removed",
        INT_BACKEND,
        "RTL_OOO_INT_BACKEND",
        TEST_INT_BACKEND,
        "v8k pending lease reaches full holder census",
        (
            replacement(
                PENDING_MASK_UNION,
                PENDING_MASK_UNION.replace(
                    "      pending_system_producer_live_mask_w |\n", ""
                ),
                "remove the pending CSR lease from the global live mask",
            ),
        ),
        widths=(4,),
        extra_defines=("-DV8K_PENDING_CSR_LEASE_FOCUSED",),
    ),
)


def positive_profiles() -> tuple[Profile, ...]:
    profiles: list[Profile] = []
    for width in GEN_WIDTHS:
        for mode, assertions in (("release", False), ("assert", True)):
            profiles.append(
                Profile(
                    f"sequencer-mux-g{width}-{mode}",
                    "positive",
                    (TEST_SEQUENCER, TEST_CSR_MUX),
                    width,
                    assertions=assertions,
                    required_markers=(
                        (
                            TEST_SEQUENCER,
                            "[V9W-SERIAL-KIND-MATRIX]",
                            1,
                        ),
                    ),
                )
            )
        if width == 4:
            profiles.append(
                Profile(
                    "int-live-mask-g4-release",
                    "positive",
                    (TEST_INT_BACKEND,),
                    width,
                    extra_defines=(
                        "-DV8K_PENDING_CSR_LEASE_FOCUSED",
                    ),
                    required_markers=(
                        (
                            TEST_INT_BACKEND,
                            "[V8K-PENDING-CSR-LEASE]",
                            1,
                        ),
                    ),
                )
            )
    profiles.extend(
        (
            Profile(
                "raw-lease-partial-metadata-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_PARTIAL_METADATA",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-PARTIAL-METADATA][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "raw-lease-ordinary-clear-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_LIVE_CLEAR",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-ORDINARY-CLEAR-HOLD][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "raw-lease-clear-dispatched-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-CDISP-HOLD][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "noncsr-dispatch-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV11U_PROBE_NONCSR_DISPATCH",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-PROBE-NONCSR-DISPATCH] PASS",
                        1,
                    ),
                ),
            ),
        )
    )
    return tuple(profiles)


def assertion_profiles() -> tuple[Profile, ...]:
    return (
        Profile(
            "assert-partial-metadata-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV8K_ASSERT_PARTIAL_METADATA",),
            expected_failure_marker="[V8K-PENDING-CSR-LEASE-SHAPE]",
        ),
        Profile(
            "assert-live-clear-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV8K_ASSERT_LIVE_CLEAR",),
            expected_failure_marker="[V8K-PENDING-CSR-NO-RECAPTURE]",
        ),
        Profile(
            "assert-noncsr-dispatch-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV11U_ASSERT_NONCSR_DISPATCH",),
            expected_failure_marker="[V8K-PENDING-CSR-DISPATCH-BIRTH]",
        ),
    )


def mutation_profiles() -> tuple[Profile, ...]:
    return tuple(
        Profile(
            f"mutation-{mutation.name}-g{width}-release",
            "mutation",
            (mutation.test,),
            width,
            extra_defines=mutation.extra_defines,
            expected_failure_marker=mutation.expected_marker,
            mutation=mutation.name,
        )
        for mutation in MUTATIONS
        for width in mutation.widths
    )


def build_profiles() -> tuple[Profile, ...]:
    return positive_profiles() + assertion_profiles() + mutation_profiles()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_path(path: Path, repo_root: Path) -> str:
    return path.resolve().relative_to(repo_root.resolve()).as_posix()


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def artifact_record(path: Path, repo_root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, repo_root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def atomic_status(path: Path, value: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    temporary.replace(path)


def source_manifest(
    paths: Sequence[Path], repo_root: Path
) -> dict[str, str]:
    return {
        repo_path(path, repo_root): sha256_file(path)
        for path in sorted(set(path.resolve() for path in paths))
    }


def write_manifest(path: Path, manifest: dict[str, str]) -> None:
    path.write_text(
        "".join(f"{digest}  {name}\n" for name, digest in sorted(manifest.items())),
        encoding="utf-8",
    )


def current_design_id(repo_root: Path) -> str:
    tools_dir = repo_root / "npc" / "rv64" / "eval" / "ppa" / "tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(repo_root)
    return f"sha256:{digest}"


def apply_mutation(
    source: str, replacements: Sequence[Replacement]
) -> tuple[str, list[dict[str, object]]]:
    result = source
    receipts: list[dict[str, object]] = []
    for item in replacements:
        count = result.count(item.anchor)
        if count != 1:
            raise ValueError(
                f"mutation anchor count must be 1, got {count}: "
                f"{item.purpose}"
            )
        result = result.replace(item.anchor, item.replacement, 1)
        receipts.append(
            {
                "purpose": item.purpose,
                "anchor_count": count,
                "anchor_sha256": hashlib.sha256(
                    item.anchor.encode("utf-8")
                ).hexdigest(),
                "replacement_sha256": hashlib.sha256(
                    item.replacement.encode("utf-8")
                ).hexdigest(),
            }
        )
    return result, receipts


def profile_defines(profile: Profile) -> tuple[str, ...]:
    values = [f"-DOOO_PRODUCER_GEN_W={profile.gen_width}"]
    if profile.assertions:
        values.append("-DOOO_ASSERT")
    values.extend(profile.extra_defines)
    return tuple(values)


COMPILE_FAILURE_MARKERS = (
    "compile returned nonzero",
    "syntax error",
    "error(s) during elaboration",
    "Unable to open input file",
)


def evaluate_profile(
    profile: Profile,
    *,
    make_rc: int,
    timed_out: bool,
    logs: dict[str, str],
    artifacts_exist: bool,
) -> bool:
    compile_ok = (
        not timed_out
        and artifacts_exist
        and set(logs) == set(profile.tests)
        and all("[COMPILE]" in text for text in logs.values())
        and not any(
            marker in text
            for text in logs.values()
            for marker in COMPILE_FAILURE_MARKERS
        )
    )
    if not compile_ok:
        return False
    if profile.kind in {"positive", "regression"}:
        return (
            make_rc == 0
            and all(text.count("[RESULT] PASS") == 1 for text in logs.values())
            and all("[RESULT] FAIL" not in text for text in logs.values())
            and all(
                logs[test].count(marker) == count
                for test, marker, count in profile.required_markers
            )
        )
    marker = profile.expected_failure_marker
    return (
        make_rc != 0
        and len(profile.tests) == 1
        and marker is not None
        and logs[profile.tests[0]].count("[RESULT] FAIL") == 1
        and "[RESULT] PASS" not in logs[profile.tests[0]]
        and marker in logs[profile.tests[0]]
    )


def run_command(
    command: Sequence[str], *, cwd: Path, timeout_seconds: int
) -> tuple[int, str, str, float, bool]:
    start = time.monotonic()
    try:
        completed = subprocess.run(
            list(command),
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
            check=False,
        )
        return (
            completed.returncode,
            completed.stdout,
            completed.stderr,
            time.monotonic() - start,
            False,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        return 124, stdout, stderr, time.monotonic() - start, True


def build_variants(
    *, repo_root: Path, result_dir: Path
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    variant_dir = result_dir / "variants"
    variant_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        source_path = repo_root / mutation.source
        source = source_path.read_text(encoding="utf-8")
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = variant_dir / f"{mutation.name}-{source_path.name}"
        variant.write_text(mutated, encoding="utf-8")
        paths[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_ids": list(UNIT_IDS),
                "target": mutation.source,
                "target_sha256": sha256_file(source_path),
                "variant": repo_path(variant, repo_root),
                "variant_sha256": sha256_file(variant),
                "override": mutation.override,
                "test": mutation.test,
                "widths": list(mutation.widths),
                "extra_defines": list(mutation.extra_defines),
                "expected_marker": mutation.expected_marker,
                "compile_success_required": True,
                "assertions": False,
                "receipts": receipts,
            }
        )
    return paths, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    variants: dict[str, Path],
    timeout_seconds: int,
    bucket: str = "profiles",
) -> tuple[dict[str, object], list[Path]]:
    profile_dir = result_dir / bucket / profile.name
    result_path = profile_dir / "results"
    build_path = profile_dir / "build"
    profile_dir.mkdir(parents=True, exist_ok=False)
    flags = " ".join((BASE_IVFLAGS, *profile_defines(profile)))
    command = [
        "make",
        "-B",
        "-C",
        str(testbench_dir),
        f"TESTS={' '.join(profile.tests)}",
        f"BUILD_DIR={build_path}",
        f"RESULT_DIR={result_path}",
        f"IVFLAGS={flags}",
    ]
    if profile.mutation:
        mutation = next(item for item in MUTATIONS if item.name == profile.mutation)
        command.append(f"{mutation.override}={variants[mutation.name]}")
    command.append("run")
    rc, stdout, stderr, elapsed, timed_out = run_command(
        command, cwd=repo_root, timeout_seconds=timeout_seconds
    )
    (profile_dir / "make.stdout").write_text(stdout, encoding="utf-8")
    (profile_dir / "make.stderr").write_text(stderr, encoding="utf-8")
    logs: dict[str, str] = {}
    log_records: dict[str, object] = {}
    image_paths: list[Path] = []
    image_records: list[dict[str, object]] = []
    for test in profile.tests:
        log_path = result_path / "logs" / f"{test}.log"
        image_path = build_path / f"{test}.vvp"
        if log_path.is_file():
            logs[test] = log_path.read_text(
                encoding="utf-8", errors="replace"
            )
            log_records[test] = artifact_record(log_path, repo_root)
        if image_path.is_file() and image_path.stat().st_size > 0:
            image_paths.append(image_path)
            image_records.append(artifact_record(image_path, repo_root))
    passed = evaluate_profile(
        profile,
        make_rc=rc,
        timed_out=timed_out,
        logs=logs,
        artifacts_exist=len(image_paths) == len(profile.tests),
    )
    record: dict[str, object] = {
        "profile": profile.name,
        "status": "PASS" if passed else "FAIL",
        "kind": profile.kind,
        "tests": list(profile.tests),
        "producer_gen_width": profile.gen_width,
        "assertions": profile.assertions,
        "defines": list(profile_defines(profile)),
        "mutation": profile.mutation,
        "expected_failure_marker": profile.expected_failure_marker,
        "required_markers": [list(item) for item in profile.required_markers],
        "command": command,
        "make_rc": rc,
        "timeout": timed_out,
        "elapsed_seconds": round(elapsed, 6),
        "logs": log_records,
        "compile_artifacts": image_records,
    }
    write_json(profile_dir / "profile.json", record)
    return record, image_paths


def cleanup_artifacts(
    *,
    repo_root: Path,
    result_dir: Path,
    compile_images: Sequence[tuple[Path, str]],
    variants: Sequence[Path],
) -> dict[str, object]:
    removed: list[dict[str, object]] = []
    seen: set[Path] = set()
    for path, kind in (
        *compile_images,
        *((path, "generated-negative-rtl") for path in variants),
    ):
        resolved = path.resolve()
        resolved.relative_to(result_dir.resolve())
        if resolved in seen or not resolved.is_file():
            raise RuntimeError(f"cleanup artifact is missing or duplicate: {resolved}")
        seen.add(resolved)
        record = artifact_record(resolved, repo_root)
        record.update({"kind": kind, "removed_after_validation": True})
        removed.append(record)
        resolved.unlink()
    for directory in sorted(
        (path for path in result_dir.rglob("build") if path.is_dir()),
        reverse=True,
    ):
        shutil.rmtree(directory)
    variants_dir = result_dir / "variants"
    if variants_dir.is_dir() and not any(variants_dir.iterdir()):
        variants_dir.rmdir()
    return {
        "status": "PASS",
        "policy": "retain-results-logs-hashes-and-summary-only",
        "removed_count": len(removed),
        "removed": sorted(removed, key=lambda item: str(item["path"])),
    }


def resolve_tool(name: str) -> Path:
    value = shutil.which(name)
    if not value:
        raise RuntimeError(f"required tool was not found: {name}")
    return Path(value).resolve()


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=300)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    result_dir.relative_to(repo_root / ".github" / "task-runs")
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"result directory is not empty: {result_dir}")
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)
    status_path = result_dir / "runner.status"
    atomic_status(status_path, "RUNNING")
    stage = "initialization"
    compile_images: list[tuple[Path, str]] = []
    variant_paths: dict[str, Path] = {}
    try:
        stage = "tool-resolution"
        tools = {
            name: resolve_tool(name) for name in ("make", "iverilog", "vvp")
        }
        runner_test = Path(__file__).with_name(
            "test_run_v11u_pending_system_producer_semantic.py"
        ).resolve()
        inputs = [
            repo_root / path
            for path in (
                SEQUENCER,
                CSR_MUX,
                INT_BACKEND,
                DEFINE,
                TB_SEQUENCER,
                TB_LEASE_PROBE,
                TB_CSR_MUX,
                TB_INT_BACKEND,
                MAKEFILE,
            )
        ] + [Path(__file__).resolve(), runner_test]
        stage = "source-binding-pre"
        before = source_manifest(inputs, repo_root)
        before_path = result_dir / "source-before.sha256"
        write_manifest(before_path, before)
        design_id = current_design_id(repo_root)

        stage = "variant-generation"
        variant_paths, variant_records = build_variants(
            repo_root=repo_root, result_dir=result_dir
        )

        stage = "focused-profiles"
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            record, images = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                variants=variant_paths,
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            compile_images.extend(
                (path, "focused-compile-image") for path in images
            )
            print(f"{profile.name}: {record['status']}")

        stage = "regressions"
        regression_profile = Profile(
            "current-regressions",
            "regression",
            REGRESSIONS,
            4,
        )
        regression_record, regression_images = run_profile(
            regression_profile,
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            variants=variant_paths,
            timeout_seconds=args.timeout_seconds,
            bucket="regressions",
        )
        compile_images.extend(
            (path, "regression-compile-image")
            for path in regression_images
        )

        stage = "source-binding-post"
        after = source_manifest(inputs, repo_root)
        after_path = result_dir / "source-after.sha256"
        write_manifest(after_path, after)
        if before != after or current_design_id(repo_root) != design_id:
            raise RuntimeError("current source or design identity drifted")
        if any(record["status"] != "PASS" for record in profile_records):
            raise RuntimeError("one or more focused profiles failed")
        if regression_record["status"] != "PASS":
            raise RuntimeError("current regression profile failed")

        stage = "artifact-cleanup"
        cleanup = cleanup_artifacts(
            repo_root=repo_root,
            result_dir=result_dir,
            compile_images=compile_images,
            variants=list(variant_paths.values()),
        )
        cleanup_path = result_dir / "artifact-cleanup.json"
        write_json(cleanup_path, cleanup)

        stage = "summary"
        positive_count = len(positive_profiles())
        assertion_count = len(assertion_profiles())
        mutation_profile_count = len(mutation_profiles())
        summary = {
            "schema": SCHEMA,
            "status": "PASS",
            "classification": "verification",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "design_id": design_id,
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "producer_gen_widths": list(GEN_WIDTHS),
                "positive_profile_count": positive_count,
                "assertion_negative_profile_count": assertion_count,
                "mutation_count": len(MUTATIONS),
                "mutation_profile_count": mutation_profile_count,
                "profile_count": len(profile_records),
                "regression_count": len(REGRESSIONS),
                "assert_and_release_baseline": True,
                "mutations_release_mode": True,
                "full_system_run": False,
            },
            "independent_oracle": {
                "full_producer_id_four_state_comparison": True,
                "nonzero_generation_width_one_and_four": True,
                "pre_rob_has_no_lease": True,
                "csr_only_birth": True,
                "birth_hold_exact_death": True,
                "backend_global_flush_death": True,
                "ordinary_clear_holds_live_lease": True,
                "clear_dispatched_holds_live_lease": True,
                "raw_lease_is_metadata_independent": True,
                "exact_commit_requires_full_pid_and_pc": True,
                "raw_or_logical_claim_seals_fallback": True,
                "int_backend_live_mask_and_reuse_fence": True,
                "assertion_negative_rejection": True,
                "compile_success_release_mutation_rejection": True,
            },
            "production": {
                "product_instances": [PRODUCT_INSTANCE],
                "sequencer_rtl": SEQUENCER,
                "sequencer_rtl_sha256": before[SEQUENCER],
                "csr_mux_rtl": CSR_MUX,
                "csr_mux_rtl_sha256": before[CSR_MUX],
                "int_backend_rtl": INT_BACKEND,
                "int_backend_rtl_sha256": before[INT_BACKEND],
                "sequencer_testbench": TB_SEQUENCER,
                "sequencer_testbench_sha256": before[TB_SEQUENCER],
                "lease_probe_testbench": TB_LEASE_PROBE,
                "lease_probe_testbench_sha256": before[TB_LEASE_PROBE],
                "csr_mux_testbench": TB_CSR_MUX,
                "csr_mux_testbench_sha256": before[TB_CSR_MUX],
                "int_backend_testbench": TB_INT_BACKEND,
                "int_backend_testbench_sha256": before[TB_INT_BACKEND],
            },
            "binding": {
                "source_before": artifact_record(before_path, repo_root),
                "source_after": artifact_record(after_path, repo_root),
                "pre_post_match": True,
            },
            "tools": {
                name: str(path)
                for name, path in tools.items()
            }
            | {
                f"{name}_sha256": sha256_file(path)
                for name, path in tools.items()
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": sum(
                    record["status"] == "PASS" for record in profile_records
                ),
                "positive_profiles_total": positive_count,
                "assertion_negative_profiles_total": assertion_count,
                "mutations_total": len(MUTATIONS),
                "mutation_profiles_total": mutation_profile_count,
                "regressions_total": len(REGRESSIONS),
                "regressions_pass": len(REGRESSIONS),
                "retired_artifacts": cleanup["removed_count"],
            },
            "profiles": profile_records,
            "variants": variant_records,
            "regressions": regression_record,
            "artifact_cleanup": cleanup,
            "scope": {
                "mechanism": "pending-system-producer-lifecycle",
                "semantic_units": list(UNIT_IDS),
                "source_paths": [
                    "pre-rob-csr-holder",
                    "rob-allocation-birth",
                    "raw-q-lease-hold",
                    "exact-commit-and-flush-death",
                    "global-live-mask-reuse-fence",
                ],
                "excluded_units": ["floating-point-producer-paths"],
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_execution_state": "COMPLETE",
                "a3_terminal_state": "COMPLETE",
                "a3_oracle_state": "OLD_ORACLE_INVALID",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11u": False,
                    "run": False,
                    "required_for_current_scope": False,
                },
            },
            "promotion": {
                "semantic_unit": "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        summary_path = result_dir / "summary.json"
        write_json(summary_path, summary)
        atomic_status(
            status_path,
            "PASS rc=0 stage=complete evidence_complete=1 cleanup_rc=0",
        )
        print(
            "[V11U-PENDING-SYSTEM-PRODUCER] PASS "
            f"profiles={len(profile_records)} mutations={len(MUTATIONS)} "
            f"regressions={len(REGRESSIONS)}"
        )
        return 0
    except Exception as exc:  # fail-closed evidence status
        cleanup_rc = 0
        try:
            for path, _kind in compile_images:
                if path.is_file() and result_dir in path.resolve().parents:
                    path.unlink()
            for path in variant_paths.values():
                if path.is_file() and result_dir in path.resolve().parents:
                    path.unlink()
        except OSError:
            cleanup_rc = 1
        (result_dir / "error.txt").write_text(
            f"stage={stage}\nerror={exc}\n", encoding="utf-8"
        )
        atomic_status(
            status_path,
            f"FAIL rc=1 stage={stage} evidence_complete=0 "
            f"cleanup_rc={cleanup_rc}",
        )
        print(f"[V11U-PENDING-SYSTEM-PRODUCER] FAIL stage={stage}: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
