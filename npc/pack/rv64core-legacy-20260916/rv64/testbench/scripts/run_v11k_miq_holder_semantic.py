#!/usr/bin/env python3
"""Run the V11K dual OooMemInflightQueue owner-tuple semantic matrix."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v11k-miq-holder-semantic-evidence-v2"
TOP = "tb_ooo_dual_mem_inflight_queue_semantic"
FOCUSED_DEFINE = "-DV11K_MIQ_HOLDER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_dual_mem_inflight_queue_semantic"
MATRIX_PASS = "[V11K-MIQ-HOLDER-MATRIX][PASS]"
ORACLE_FAIL = "[V11K-MIQ-HOLDER-ORACLE][FAIL]"
NEGATIVE_ESCAPED = "[V11K-MIQ-NEGATIVE-ESCAPED][FAIL]"
UNIT_IDS = ("miq-owner-tokens",)
PRODUCT_INSTANCES = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend.u_mem1_inflight_queue",
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend.u_mem_inflight_queue",
)
REGRESSIONS = (
    "tb_ooo_mem_inflight_queue",
    "tb_ooo_dual_mem_inflight_queue_semantic",
    "tb_ooo_int_backend",
)
ASSERTION_MARKERS = (
    "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
    "[V11K-MIQ-POP-TUPLE-KNOWN]",
    "[V11K-MIQ-OWNER-TUPLE-KNOWN]",
    "[V11K-MIQ-OWNER-TUPLE-STABLE]",
    "[MIQ-OWNER-MISMATCH]",
)
PUSH_FAIL_CLOSED = "[V11K-MIQ-PUSH-TUPLE-FAIL-CLOSED][PASS]"
POP_FAIL_CLOSED = "[V11K-MIQ-POP-TUPLE-FAIL-CLOSED][PASS]"


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    replacements: tuple[Replacement, ...]


@dataclass(frozen=True)
class Profile:
    name: str
    assertions: bool
    kind: str
    mutation: str | None = None
    stimulus_define: str | None = None
    expected_marker: str | None = None
    release_fail_closed_marker: str | None = None


@dataclass(frozen=True)
class StimulusProbe:
    name: str
    define: str
    assertion_marker: str
    release_fail_closed_marker: str


MUTATIONS = (
    Mutation(
        "capture-kind-x",
        (
            Replacement(
                "        owner_kind_q[tail_q] <= push_owner_kind_i;\n",
                "        owner_kind_q[tail_q] <= 2'b0x;\n",
                "capture an X-bearing owner kind",
            ),
        ),
    ),
    Mutation(
        "capture-kind-z",
        (
            Replacement(
                "        owner_kind_q[tail_q] <= push_owner_kind_i;\n",
                "        owner_kind_q[tail_q] <= 2'b0z;\n",
                "capture a Z-bearing owner kind",
            ),
        ),
    ),
    Mutation(
        "capture-token-x",
        (
            Replacement(
                "        owner_token_q[tail_q] <= push_owner_token_i;\n",
                "        owner_token_q[tail_q] <= {OWNER_TOKEN_W{1'bx}};\n",
                "capture an X-bearing owner token",
            ),
        ),
    ),
    Mutation(
        "capture-token-z",
        (
            Replacement(
                "        owner_token_q[tail_q] <= push_owner_token_i;\n",
                "        owner_token_q[tail_q] <= {OWNER_TOKEN_W{1'bz}};\n",
                "capture a Z-bearing owner token",
            ),
        ),
    ),
    Mutation(
        "capture-epoch-x",
        (
            Replacement(
                "        mmu_epoch_q[tail_q] <= push_mmu_epoch_i;\n",
                "        mmu_epoch_q[tail_q] <= {MMU_EPOCH_W{1'bx}};\n",
                "capture an X-bearing MMU epoch",
            ),
        ),
    ),
    Mutation(
        "capture-epoch-z",
        (
            Replacement(
                "        mmu_epoch_q[tail_q] <= push_mmu_epoch_i;\n",
                "        mmu_epoch_q[tail_q] <= {MMU_EPOCH_W{1'bz}};\n",
                "capture a Z-bearing MMU epoch",
            ),
        ),
    ),
    Mutation(
        "idle-head-token-drift",
        (
            Replacement(
                """\
    end else begin
      if (push_fire_w) begin
""",
                """\
    end else begin
      if (!push_fire_w && !pop_fire_w && !flush_i && !kill_valid_i &&
          head_valid_o)
        owner_token_q[head_q] <= owner_token_q[head_q] ^ 5'b00001;
      if (push_fire_w) begin
""",
                "drift the resident head token without a queue event",
            ),
        ),
    ),
    Mutation(
        "consume-without-exact-owner",
        (
            Replacement(
                """\
  wire pop_fire_w = pop_valid_i && head_valid_o && pop_owner_match_o;
""",
                """\
  wire pop_fire_w = pop_valid_i && head_valid_o;
""",
                "consume a response without the complete owner identity",
            ),
        ),
    ),
    Mutation(
        "flush-drop-drain",
        (
            Replacement(
                """\
            (kind_q[src] == KIND_DRAIN) &&
            !(pop_fire_w && (rd == 0))) begin
""",
                """\
            1'b0 &&
            !(pop_fire_w && (rd == 0))) begin
""",
                "drop every DRAIN owner during global flush",
            ),
        ),
    ),
    Mutation(
        "flush-preserve-killable",
        (
            Replacement(
                """\
            (kind_q[src] == KIND_DRAIN) &&
            !(pop_fire_w && (rd == 0))) begin
""",
                """\
            (kind_q[src] != KIND_LEGACY) &&
            !(pop_fire_w && (rd == 0))) begin
""",
                "retain killable LOAD and PROBE owners during global flush",
            ),
        ),
    ),
    Mutation(
        "occupancy-omit-live",
        (
            Replacement(
                """\
      if (valid_q[live_i])
        live_token_mask_r[owner_token_q[live_i]] = 1'b1;
""",
                """\
      if (1'b0 && valid_q[live_i])
        live_token_mask_r[owner_token_q[live_i]] = 1'b1;
""",
                "omit all resident owners from the occupancy set",
            ),
        ),
    ),
    Mutation(
        "occupancy-add-ghost",
        (
            Replacement(
                """\
    live_token_mask_r = {(1 << OWNER_TOKEN_W){1'b0}};
""",
                """\
    live_token_mask_r = {(1 << OWNER_TOKEN_W){1'b0}};
    live_token_mask_r[31] = 1'b1;
""",
                "add a nonresident owner to the occupancy set",
            ),
        ),
    ),
)

STIMULUS_PROBES = (
    StimulusProbe(
        "accepted-push-tuple-x",
        "-DV11K_PUSH_TUPLE_X_PROBE",
        "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
        PUSH_FAIL_CLOSED,
    ),
    StimulusProbe(
        "accepted-push-tuple-z",
        "-DV11K_PUSH_TUPLE_Z_PROBE",
        "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
        PUSH_FAIL_CLOSED,
    ),
    StimulusProbe(
        "valid-head-pop-tuple-x",
        "-DV11K_POP_TUPLE_X_PROBE",
        "[V11K-MIQ-POP-TUPLE-KNOWN]",
        POP_FAIL_CLOSED,
    ),
    StimulusProbe(
        "valid-head-pop-tuple-z",
        "-DV11K_POP_TUPLE_Z_PROBE",
        "[V11K-MIQ-POP-TUPLE-KNOWN]",
        POP_FAIL_CLOSED,
    ),
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_path(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def artifact_record(path: Path, repo_root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, repo_root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def current_design_id(repo_root: Path) -> str:
    tools_dir = repo_root / "npc" / "rv64" / "eval" / "ppa" / "tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(repo_root)
    return f"sha256:{digest}"


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def atomic_status(path: Path, value: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    temporary.replace(path)


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


def build_profiles() -> tuple[Profile, ...]:
    profiles: list[Profile] = [
        Profile("production-assert", True, "baseline"),
        Profile("production-release", False, "baseline"),
    ]
    for mutation in MUTATIONS:
        stimulus_define = None
        expected_marker = None
        if mutation.name.startswith("capture-"):
            stimulus_define = "-DV11K_TUPLE_MARKER_PROBE"
            expected_marker = "[V11K-MIQ-OWNER-TUPLE-KNOWN]"
        elif mutation.name == "idle-head-token-drift":
            stimulus_define = "-DV11K_STABLE_MARKER_PROBE"
            expected_marker = "[V11K-MIQ-OWNER-TUPLE-STABLE]"
        elif mutation.name == "consume-without-exact-owner":
            stimulus_define = "-DV11K_ASSERT_CROSS_POP"
            expected_marker = "[MIQ-OWNER-MISMATCH]"
        profiles.append(
            Profile(
                f"{mutation.name}-assert",
                True,
                "mutation",
                mutation=mutation.name,
                stimulus_define=stimulus_define,
                expected_marker=expected_marker,
            )
        )
        profiles.append(
            Profile(
                f"{mutation.name}-release",
                False,
                "mutation",
                mutation=mutation.name,
            )
        )
    for probe in STIMULUS_PROBES:
        profiles.append(
            Profile(
                f"{probe.name}-assert",
                True,
                "stimulus-probe",
                stimulus_define=probe.define,
                expected_marker=probe.assertion_marker,
                release_fail_closed_marker=(
                    probe.release_fail_closed_marker
                ),
            )
        )
        profiles.append(
            Profile(
                f"{probe.name}-release",
                False,
                "stimulus-probe",
                stimulus_define=probe.define,
                release_fail_closed_marker=(
                    probe.release_fail_closed_marker
                ),
            )
        )
    return tuple(profiles)


def marker_counts(text: str) -> dict[str, int]:
    counts = {
        "tb_pass": text.count(TB_PASS),
        "matrix_pass": text.count(MATRIX_PASS),
        "oracle_fail": text.count(ORACLE_FAIL),
        "negative_escaped": text.count(NEGATIVE_ESCAPED),
        "push_fail_closed": text.count(PUSH_FAIL_CLOSED),
        "pop_fail_closed": text.count(POP_FAIL_CLOSED),
    }
    for marker in ASSERTION_MARKERS:
        key = marker.strip("[]").lower().replace("-", "_")
        counts[key] = text.count(marker)
    counts["assertion_marker_total"] = sum(
        text.count(marker) for marker in ASSERTION_MARKERS
    )
    return counts


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    sim_rc: int | None,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    markers = marker_counts(log_text)
    compile_ok = compile_rc == 0 and artifact_exists
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and markers["tb_pass"] == 1
            and markers["matrix_pass"] == 1
            and markers["oracle_fail"] == 0
            and markers["negative_escaped"] == 0
            and markers["assertion_marker_total"] == 0
        )
    elif profile.expected_marker is not None and profile.assertions:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and log_text.count(profile.expected_marker) >= 1
            and markers["tb_pass"] == 0
            and markers["negative_escaped"] == 0
        )
    elif profile.assertions:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and (
                markers["oracle_fail"] >= 1
                or markers["assertion_marker_total"] >= 1
            )
            and markers["tb_pass"] == 0
            and markers["negative_escaped"] == 0
        )
    elif profile.kind == "stimulus-probe":
        fail_closed = (
            sim_rc == 0
            and profile.release_fail_closed_marker is not None
            and log_text.count(profile.release_fail_closed_marker) == 1
            and markers["oracle_fail"] == 0
        )
        oracle_rejected = (
            sim_rc not in (None, 0)
            and markers["oracle_fail"] >= 1
        )
        passed = (
            compile_ok
            and (fail_closed or oracle_rejected)
            and markers["tb_pass"] == 0
            and markers["negative_escaped"] == 0
            and markers["assertion_marker_total"] == 0
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and markers["oracle_fail"] >= 1
            and markers["tb_pass"] == 0
            and markers["negative_escaped"] == 0
            and markers["assertion_marker_total"] == 0
        )
    return passed, markers


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


def resolve_tools() -> tuple[Path, Path]:
    iverilog_raw = shutil.which("iverilog")
    if not iverilog_raw:
        raise RuntimeError("iverilog was not found")
    iverilog = Path(iverilog_raw).resolve()
    sibling_vvp = iverilog.parent / "vvp"
    vvp_raw = (
        str(sibling_vvp)
        if sibling_vvp.is_file()
        else shutil.which("vvp")
    )
    if not vvp_raw:
        raise RuntimeError("vvp was not found")
    return iverilog, Path(vvp_raw).resolve()


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = subprocess.run(
        ["make", "-s", "print-v11k-miq-holder-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "failed to load V11K Makefile context: "
            + completed.stderr.strip()
        )
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.split("=", 1)[1]).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.split("=", 1)[1]).resolve())
    if include_dir is None or not sources:
        raise RuntimeError("V11K Makefile context is incomplete")
    if any(not path.is_file() for path in sources):
        raise RuntimeError("V11K Makefile context names a missing source")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = subprocess.run(
        ["make", "-s", "print-v11k-miq-holder-regression-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "failed to load V11K regression context: "
            + completed.stderr.strip()
        )
    common: list[Path] = []
    sources: dict[str, list[Path]] = {
        test: [] for test in REGRESSIONS
    }
    prefix = "REGRESSION_SOURCE_"
    for line in completed.stdout.splitlines():
        if line.startswith("REGRESSION_COMMON="):
            common.append(Path(line.split("=", 1)[1]).resolve())
        elif line.startswith(prefix):
            key, raw_path = line.split("=", 1)
            test = key[len(prefix):]
            if test not in sources:
                raise RuntimeError(
                    f"unknown V11K regression context: {test}"
                )
            sources[test].append(Path(raw_path).resolve())
    result = {
        test: tuple(sorted({*paths, *common}))
        for test, paths in sources.items()
    }
    if (
        not common
        or any(not paths for paths in result.values())
        or any(
            not path.is_file()
            for paths in result.values()
            for path in paths
        )
    ):
        raise RuntimeError("V11K regression context is incomplete")
    return result


def source_manifest(
    paths: Sequence[Path], repo_root: Path
) -> dict[str, str]:
    unique = sorted({path.resolve() for path in paths})
    if any(not path.is_file() for path in unique):
        raise ValueError("source manifest contains a missing file")
    return {
        repo_path(path, repo_root): sha256_file(path)
        for path in unique
    }


def write_sha256_manifest(path: Path, entries: dict[str, str]) -> None:
    path.write_text(
        "".join(
            f"{digest}  {name}\n"
            for name, digest in sorted(entries.items())
        ),
        encoding="utf-8",
    )


def build_variants(
    *,
    result_dir: Path,
    miq_path: Path,
    repo_root: Path,
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    source = miq_path.read_text(encoding="utf-8")
    variants: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = result_dir / "variants" / mutation.name / miq_path.name
        variant.parent.mkdir(parents=True, exist_ok=True)
        variant.write_text(mutated, encoding="utf-8")
        variants[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_id": UNIT_IDS[0],
                "target": repo_path(miq_path, repo_root),
                "production_sha256": sha256_file(miq_path),
                "variant": repo_path(variant, repo_root),
                "variant_sha256": sha256_file(variant),
                "compile_success_required": True,
                "receipts": receipts,
            }
        )
    write_json(result_dir / "variants" / "manifest.json", records)
    return variants, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    miq_path: Path,
    variant_paths: dict[str, Path],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    build_dir = profile_dir / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{TOP}.vvp"

    sources = list(production_sources)
    if profile.mutation:
        sources = [
            variant_paths[profile.mutation] if path == miq_path else path
            for path in sources
        ]
    defines = [FOCUSED_DEFINE]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    if profile.kind in {"mutation", "stimulus-probe"}:
        defines.append("-DV11K_NEGATIVE_PROFILE")
    if profile.stimulus_define:
        defines.append(profile.stimulus_define)
    compile_command = [
        str(iverilog),
        "-g2012",
        "-Wall",
        f"-I{repo_root / 'npc' / 'rv64' / 'vsrc'}",
        f"-I{include_dir}",
        f"-I{testbench_dir / 'common'}",
        *defines,
        "-s",
        TOP,
        "-o",
        str(artifact),
        *(str(path) for path in sources),
    ]
    (
        compile_rc,
        compile_stdout,
        compile_stderr,
        compile_seconds,
        compile_timeout,
    ) = run_command(
        compile_command,
        cwd=testbench_dir,
        timeout_seconds=timeout_seconds,
    )
    (profile_dir / "compile.stdout").write_text(
        compile_stdout, encoding="utf-8"
    )
    (profile_dir / "compile.stderr").write_text(
        compile_stderr, encoding="utf-8"
    )
    (profile_dir / "compile.rc").write_text(
        f"{compile_rc}\n", encoding="utf-8"
    )

    sim_rc: int | None = None
    sim_stdout = ""
    sim_stderr = ""
    sim_seconds = 0.0
    sim_timeout = False
    if compile_rc == 0 and artifact.is_file():
        (
            sim_rc,
            sim_stdout,
            sim_stderr,
            sim_seconds,
            sim_timeout,
        ) = run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    (profile_dir / "sim.stdout").write_text(
        sim_stdout, encoding="utf-8"
    )
    (profile_dir / "sim.stderr").write_text(
        sim_stderr, encoding="utf-8"
    )
    sim_log = profile_dir / "sim.log"
    sim_log.write_text(sim_stdout + sim_stderr, encoding="utf-8")
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if sim_rc is None else f"{sim_rc}\n",
        encoding="utf-8",
    )
    artifact_exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, markers = evaluate_profile(
        profile,
        compile_rc=compile_rc,
        sim_rc=sim_rc,
        log_text=sim_stdout + sim_stderr,
        artifact_exists=artifact_exists,
    )
    compile_manifest = {
        repo_path(path, repo_root): sha256_file(path)
        for path in sources
    }
    record = {
        "profile": profile.name,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "stimulus_define": profile.stimulus_define,
        "expected_marker": profile.expected_marker,
        "release_fail_closed_marker": (
            profile.release_fail_closed_marker
        ),
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": compile_rc,
            "timeout": compile_timeout,
            "elapsed_seconds": round(compile_seconds, 6),
            "artifact": repo_path(artifact, repo_root),
            "artifact_exists": artifact_exists,
            "artifact_sha256": (
                sha256_file(artifact) if artifact_exists else None
            ),
        },
        "simulation": {
            "rc": sim_rc,
            "timeout": sim_timeout,
            "elapsed_seconds": round(sim_seconds, 6),
            "log": repo_path(sim_log, repo_root),
            "log_sha256": sha256_file(sim_log),
        },
        "markers": markers,
        "compile_source_manifest": compile_manifest,
    }
    write_json(profile_dir / "profile.json", record)
    return record


def evaluate_regression_log(test: str, text: str) -> bool:
    return (
        text.count(f"[PASS] {test}") == 1
        and text.count("[RESULT] PASS") == 1
        and "[RESULT] FAIL" not in text
        and ORACLE_FAIL not in text
        and NEGATIVE_ESCAPED not in text
    )


def run_regressions(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    regression_sources: dict[str, tuple[Path, ...]],
    timeout_seconds: int,
) -> tuple[bool, list[dict[str, object]]]:
    regression_dir = result_dir / "regressions"
    build_dir = regression_dir / "build"
    log_dir = regression_dir / "logs"
    targets = [log_dir / f"{test}.log" for test in REGRESSIONS]
    source_before = {
        test: source_manifest(regression_sources[test], repo_root)
        for test in REGRESSIONS
    }
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"RESULT_DIR={regression_dir}",
        f"BUILD_DIR={build_dir}",
        *(str(target) for target in targets),
    ]
    rc, stdout, stderr, elapsed, timed_out = run_command(
        command,
        cwd=repo_root,
        timeout_seconds=timeout_seconds,
    )
    regression_dir.mkdir(parents=True, exist_ok=True)
    (regression_dir / "make.stdout").write_text(stdout, encoding="utf-8")
    (regression_dir / "make.stderr").write_text(stderr, encoding="utf-8")
    (regression_dir / "make.rc").write_text(f"{rc}\n", encoding="utf-8")
    write_json(
        regression_dir / "commands.json",
        {
            "command": command,
            "mode": "local-rv64-iverilog-assert-regression",
            "purpose": (
                "replay single MIQ, dual MIQ and OooIntBackend tests "
                "against the V11K assertion-only production delta"
            ),
        },
    )
    records: list[dict[str, object]] = []
    for test, log_path in zip(REGRESSIONS, targets):
        exists = log_path.is_file()
        compiled_image = build_dir / f"{test}.vvp"
        compiled_image_exists = (
            compiled_image.is_file()
            and compiled_image.stat().st_size > 0
        )
        source_after = source_manifest(
            regression_sources[test], repo_root
        )
        source_match = source_before[test] == source_after
        text = (
            log_path.read_text(encoding="utf-8", errors="replace")
            if exists
            else ""
        )
        passed = (
            rc == 0
            and exists
            and compiled_image_exists
            and source_match
            and evaluate_regression_log(test, text)
        )
        records.append(
            {
                "test": test,
                "status": "PASS" if passed else "FAIL",
                "log": (
                    artifact_record(log_path, repo_root)
                    if exists
                    else None
                ),
                "compile_artifact": (
                    artifact_record(compiled_image, repo_root)
                    if compiled_image_exists
                    else None
                ),
                "compile_source_manifest": source_before[test],
                "compile_source_post_manifest": source_after,
                "source_pre_post_match": source_match,
            }
        )
    overall = (
        rc == 0
        and not timed_out
        and all(item["status"] == "PASS" for item in records)
    )
    write_json(
        regression_dir / "summary.json",
        {
            "status": "PASS" if overall else "FAIL",
            "command_rc": rc,
            "timeout": timed_out,
            "elapsed_seconds": round(elapsed, 6),
            "all_source_pre_post_match": all(
                item["source_pre_post_match"] is True
                for item in records
            ),
            "tests": records,
        },
    )
    return overall, records


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run assert/release dual OooMemInflightQueue owner-tuple "
            "lifecycle and compile-success sensitivity profiles"
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    miq_path = (
        repo_root / "npc" / "rv64" / "vsrc" / "memory"
        / "OooMemInflightQueue.v"
    ).resolve()
    status_path = result_dir / "runner.status"

    if args.timeout_seconds <= 0:
        print("timeout must be positive", file=sys.stderr)
        return 2
    if result_dir.exists() and any(result_dir.iterdir()):
        if not args.overwrite:
            print(
                f"result directory is not empty: {result_dir}",
                file=sys.stderr,
            )
            return 2
        shutil.rmtree(result_dir)
    result_dir.mkdir(parents=True, exist_ok=True)
    atomic_status(status_path, "RUNNING")

    try:
        iverilog, vvp = resolve_tools()
        include_dir, production_sources = load_make_context(testbench_dir)
        regression_sources = load_regression_context(testbench_dir)
        if miq_path not in production_sources:
            raise RuntimeError("production OooMemInflightQueue.v is absent")
        design_id = current_design_id(repo_root)
        runner_inputs = [
            *production_sources,
            include_dir / "define.v",
            repo_root / "npc" / "rv64" / "vsrc" / "filelist.mk",
            repo_root / "npc" / "rv64" / "testbench" / "Makefile",
            testbench_dir / "tests" / "tb_ooo_mem_inflight_queue.sv",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11k_miq_holder_semantic.py"
            ).resolve(),
            *(
                path
                for test in REGRESSIONS
                for path in regression_sources[test]
            ),
        ]
        before = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-before.sha256", before)

        variants, variant_records = build_variants(
            result_dir=result_dir,
            miq_path=miq_path,
            repo_root=repo_root,
        )
        profiles = build_profiles()
        profile_records: list[dict[str, object]] = []
        for profile in profiles:
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                miq_path=miq_path,
                variant_paths=variants,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            print(f"{profile.name}: {record['status']}")

        regression_ok, regression_records = run_regressions(
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            regression_sources=regression_sources,
            timeout_seconds=args.timeout_seconds,
        )
        after = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-after.sha256", after)
        binding_match = before == after
        passed_count = sum(
            item["status"] == "PASS" for item in profile_records
        )
        overall = (
            binding_match
            and passed_count == len(profile_records)
            and regression_ok
        )
        summary = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": design_id,
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "profile_count": len(profile_records),
                "mutation_count": len(MUTATIONS),
                "stimulus_probe_count": len(STIMULUS_PROBES),
                "regression_count": len(REGRESSIONS),
                "assert_and_release": True,
                "full_system_run": False,
            },
            "tools": {
                "iverilog": str(iverilog),
                "iverilog_sha256": sha256_file(iverilog),
                "vvp": str(vvp),
                "vvp_sha256": sha256_file(vvp),
            },
            "production": {
                "miq": repo_path(miq_path, repo_root),
                "miq_sha256": sha256_file(miq_path),
                "focused_testbench": repo_path(
                    testbench_dir
                    / "tests"
                    / "tb_ooo_dual_mem_inflight_queue_semantic.sv",
                    repo_root,
                ),
                "focused_testbench_sha256": sha256_file(
                    testbench_dir
                    / "tests"
                    / "tb_ooo_dual_mem_inflight_queue_semantic.sv"
                ),
                "product_instances": list(PRODUCT_INSTANCES),
            },
            "binding": {
                "pre_post_match": binding_match,
                "source_before": artifact_record(
                    result_dir / "source-before.sha256", repo_root
                ),
                "source_after": artifact_record(
                    result_dir / "source-after.sha256", repo_root
                ),
            },
            "independent_oracle": {
                "stimulus_owned_fixed_tuple_schedule": True,
                "expected_tuple_uses_dut_state": False,
                "checks_both_product_instances": True,
                "checks_same_rob_distinct_owner": True,
                "checks_swapped_tuple_rejection": True,
                "checks_hold_flush_kill_exact_consume": True,
                "checks_exact_32bit_occupancy_set": True,
                "checks_full_tuple_x_and_z": True,
                "checks_push_pop_interface_x_and_z": True,
                "checks_release_invalid_tuple_state_fail_closed": True,
                "assert_and_release_mutation_rejection": True,
                "regressions_source_artifact_post_bound": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": passed_count,
                "profiles_fail": len(profile_records) - passed_count,
                "mutations_total": len(MUTATIONS),
                "stimulus_probes_total": len(STIMULUS_PROBES),
                "regressions_total": len(regression_records),
                "regressions_pass": sum(
                    item["status"] == "PASS"
                    for item in regression_records
                ),
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "semantic_units": list(UNIT_IDS),
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_rerun": {
                    "triggered_by_v11k": False,
                    "reason": "production delta is OOO_ASSERT-only",
                    "run": False,
                },
            },
            "promotion": {
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        write_json(result_dir / "summary.json", summary)
        lines = [
            "# V11K dual MIQ owner-tuple semantic evidence",
            "",
            f"- status: {summary['status']}",
            f"- profiles: {passed_count}/{len(profile_records)} PASS",
            f"- compile-success variants: {len(MUTATIONS)}",
            f"- interface X/Z probes: {len(STIMULUS_PROBES)}",
            (
                "- ordinary regressions: "
                f"{sum(item['status'] == 'PASS' for item in regression_records)}"
                f"/{len(regression_records)} PASS"
            ),
            (
                "- production pre/post binding: "
                f"{'MATCH' if binding_match else 'DRIFT'}"
            ),
            "- configurations: OOO_ASSERT enabled and disabled",
            "- tuple knownness: owner_kind, owner_token and mmu_epoch X/Z",
            "- lifecycle: capture, idle hold, cross reject, exact consume, flush and kill",
            "- full-system run: not executed",
            "- architecture/PPA promotion: stopped",
            "",
            "## Profiles",
            "",
            *(
                f"- {item['profile']}: {item['status']}"
                for item in profile_records
            ),
            "",
            "## Ordinary regressions",
            "",
            *(
                f"- {item['test']}: {item['status']}"
                for item in regression_records
            ),
        ]
        (result_dir / "summary.md").write_text(
            "\n".join(lines) + "\n", encoding="utf-8"
        )
        atomic_status(status_path, "PASS" if overall else "FAIL")
        return 0 if overall else 1
    except Exception as exc:
        write_json(
            result_dir / "runner-error.json",
            {
                "schema": SCHEMA,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        )
        atomic_status(status_path, "FAIL")
        print(f"V11K runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
