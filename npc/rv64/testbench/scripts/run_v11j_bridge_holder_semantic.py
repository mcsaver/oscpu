#!/usr/bin/env python3
"""Run the V11J dual OooMemAxiBridge holder semantic matrix."""

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


SCHEMA = "npc-rv64-v11j-bridge-holder-semantic-evidence-v1"
TOP = "tb_ooo_dual_mem_bridge_wrapper"
FOCUSED_DEFINE = "-DV11J_BRIDGE_HOLDER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_dual_mem_bridge_holder_semantic"
MATRIX_PASS = "[V11J-BRIDGE-HOLDER-MATRIX][PASS]"
ORACLE_FAIL = "[V11J-BRIDGE-HOLDER-ORACLE][FAIL]"
NEGATIVE_ESCAPED = "[V11J-TUPLE-NEGATIVE-ESCAPED][FAIL]"
TUPLE_MARKERS = (
    "[V11J-BRIDGE-STAGE-TUPLE-KNOWN]",
    "[V11J-BRIDGE-ACTIVE-TUPLE-KNOWN]",
    "[V11J-BRIDGE-RSP-TUPLE-KNOWN]",
    "[V11J-BRIDGE-VERIFIED-TUPLE-KNOWN]",
)
UNIT_IDS = (
    "bridge-active-token",
    "bridge-response-token",
    "bridge-stage-token",
    "bridge-verified-token-alias",
    "bridge-residency-set",
)
PRODUCT_INSTANCES = (
    "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge0",
    "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge1",
)
REGRESSIONS = (
    "tb_ooo_mem_axi_bridge",
    "tb_ooo_dual_mem_bridge_wrapper",
    "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0",
)


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    target: str
    replacements: tuple[Replacement, ...]
    debt_unit: str


@dataclass(frozen=True)
class Profile:
    name: str
    assertions: bool
    kind: str
    mutation: str | None = None
    stimulus_define: str | None = None
    expected_marker: str | None = None


MUTATIONS = (
    Mutation(
        "stage-capture-wrong-token",
        "bridge",
        (
            Replacement(
                "      stg_owner_token_q <= mem0_req_owner_token_i;\n",
                "      stg_owner_token_q <= mem0_req_owner_token_i ^ 5'b00001;\n",
                "capture a different station token",
            ),
        ),
        "bridge-stage-token",
    ),
    Mutation(
        "active-transfer-wrong-token",
        "bridge",
        (
            Replacement(
                "      active_owner_token_q <= stg_owner_token_q;\n",
                "      active_owner_token_q <= stg_owner_token_q ^ 5'b00001;\n",
                "transfer a different active token",
            ),
        ),
        "bridge-active-token",
    ),
    Mutation(
        "response-snapshot-wrong-token",
        "bridge",
        (
            Replacement(
                "      rsp_owner_token_q <= stg_owner_token_q;\n",
                "      rsp_owner_token_q <= stg_owner_token_q ^ 5'b00001;\n",
                "snapshot a different response token",
            ),
        ),
        "bridge-response-token",
    ),
    Mutation(
        "verified-alias-x-epoch",
        "bridge",
        (
            Replacement(
                "      verified_mmu_epoch_q <= mem0_station_expected_mmu_epoch_i;\n",
                "      verified_mmu_epoch_q <= 2'b0x;\n",
                "capture an X-bearing verified alias epoch",
            ),
        ),
        "bridge-verified-token-alias",
    ),
    Mutation(
        "active-response-stall-drift",
        "bridge",
        (
            Replacement(
                """\
    end else begin
      if (aw_fire_w || w_fire_w)
        write_escaped_q <= 1'b1;
""",
                """\
    end else begin
      if ((state_q == S_RESP) && !rsp_ready_w)
        active_owner_token_q <= active_owner_token_q ^ 5'b00001;
      if (aw_fire_w || w_fire_w)
        write_escaped_q <= 1'b1;
""",
                "drift the active token under response backpressure",
            ),
        ),
        "bridge-active-token",
    ),
    Mutation(
        "response-stall-drift",
        "bridge",
        (
            Replacement(
                """\
    end else begin
      if (aw_fire_w || w_fire_w)
        write_escaped_q <= 1'b1;
""",
                """\
    end else begin
      if ((state_q == S_RESP) && !rsp_ready_w)
        rsp_owner_token_q <= rsp_owner_token_q ^ 5'b00001;
      if (aw_fire_w || w_fire_w)
        write_escaped_q <= 1'b1;
""",
                "drift the response token under response backpressure",
            ),
        ),
        "bridge-response-token",
    ),
    Mutation(
        "residency-omit-stage",
        "bridge",
        (
            Replacement(
                """\
    if (stg_valid_q)
      owner_residency_mask_r[stg_owner_token_q] = 1'b1;
""",
                """\
    if (1'b0 && stg_valid_q)
      owner_residency_mask_r[stg_owner_token_q] = 1'b1;
""",
                "omit the live station from the residency set",
            ),
        ),
        "bridge-residency-set",
    ),
    Mutation(
        "residency-add-ghost",
        "bridge",
        (
            Replacement(
                "    owner_residency_mask_r = 32'b0;\n",
                """\
    owner_residency_mask_r = 32'b0;
    owner_residency_mask_r[31] = 1'b1;
""",
                "add an owner-31 ghost member",
            ),
        ),
        "bridge-residency-set",
    ),
    Mutation(
        "wrapper-crosswire-residency-lanes",
        "wrapper",
        (
            Replacement(
                "    .mem0_owner_residency_mask_o(lane0_owner_residency_mask_o),\n",
                "    .mem0_owner_residency_mask_o( lane1_owner_residency_mask_o),\n",
                "route bridge0 residency to lane1",
            ),
            Replacement(
                "    .mem0_owner_residency_mask_o(lane1_owner_residency_mask_o),\n",
                "    .mem0_owner_residency_mask_o(lane0_owner_residency_mask_o),\n",
                "route bridge1 residency to lane0",
            ),
        ),
        "bridge-residency-set",
    ),
    Mutation(
        "stage-kind-x-capture",
        "bridge",
        (
            Replacement(
                "      stg_owner_kind_q <= mem0_req_owner_kind_i;\n",
                "      stg_owner_kind_q <= 2'b0x;\n",
                "capture an X-bearing station kind",
            ),
        ),
        "bridge-stage-token",
    ),
    Mutation(
        "active-epoch-x-transfer",
        "bridge",
        (
            Replacement(
                "      active_mmu_epoch_q <= stg_mmu_epoch_q;\n",
                "      active_mmu_epoch_q <= 2'b0x;\n",
                "transfer an X-bearing active epoch",
            ),
        ),
        "bridge-active-token",
    ),
    Mutation(
        "response-kind-x-snapshot",
        "bridge",
        (
            Replacement(
                "      rsp_owner_kind_q <= stg_owner_kind_q;\n",
                "      rsp_owner_kind_q <= 2'b0x;\n",
                "snapshot an X-bearing response kind",
            ),
        ),
        "bridge-response-token",
    ),
    Mutation(
        "verified-token-x-capture",
        "bridge",
        (
            Replacement(
                "      verified_owner_token_q <= mem0_station_expected_owner_token_i;\n",
                "      verified_owner_token_q <= 5'bx;\n",
                "capture an X-bearing verified alias token",
            ),
        ),
        "bridge-verified-token-alias",
    ),
)

ASSERT_MARKER_PROBES = {
    "verified-alias-x-epoch": (
        "-DV11J_VERIFIED_X_MARKER_PROBE",
        TUPLE_MARKERS[3],
    ),
    "stage-kind-x-capture": (
        "-DV11J_STAGE_X_MARKER_PROBE",
        TUPLE_MARKERS[0],
    ),
    "active-epoch-x-transfer": (
        "-DV11J_ACTIVE_X_MARKER_PROBE",
        TUPLE_MARKERS[1],
    ),
    "response-kind-x-snapshot": (
        "-DV11J_RSP_X_MARKER_PROBE",
        TUPLE_MARKERS[2],
    ),
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(value + "\n", encoding="utf-8")
    temp.replace(path)


def repo_path(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def apply_mutation(
    source: str, replacements: Sequence[Replacement]
) -> tuple[str, list[dict[str, object]]]:
    result = source
    receipts: list[dict[str, object]] = []
    for item in replacements:
        count = result.count(item.anchor)
        if count != 1:
            raise ValueError(
                f"mutation anchor count must be 1, got {count}: {item.purpose}"
            )
        result = result.replace(item.anchor, item.replacement, 1)
        receipts.append(
            {
                "purpose": item.purpose,
                "anchor_sha256": hashlib.sha256(
                    item.anchor.encode("utf-8")
                ).hexdigest(),
                "replacement_sha256": hashlib.sha256(
                    item.replacement.encode("utf-8")
                ).hexdigest(),
                "anchor_count": count,
            }
        )
    return result, receipts


def build_profiles() -> tuple[Profile, ...]:
    profiles: list[Profile] = [
        Profile("production-assert", True, "baseline"),
        Profile("production-release", False, "baseline"),
        Profile(
            "kind-x-assert",
            True,
            "tuple-x",
            stimulus_define="-DV11J_KIND_X_NEGATIVE",
        ),
        Profile(
            "kind-x-release",
            False,
            "tuple-x",
            stimulus_define="-DV11J_KIND_X_NEGATIVE",
        ),
        Profile(
            "epoch-x-assert",
            True,
            "tuple-x",
            stimulus_define="-DV11J_EPOCH_X_NEGATIVE",
        ),
        Profile(
            "epoch-x-release",
            False,
            "tuple-x",
            stimulus_define="-DV11J_EPOCH_X_NEGATIVE",
        ),
    ]
    for mutation in MUTATIONS:
        marker_probe = ASSERT_MARKER_PROBES.get(mutation.name)
        profiles.append(
            Profile(
                f"{mutation.name}-assert",
                True,
                "mutation",
                mutation=mutation.name,
                stimulus_define=(
                    marker_probe[0] if marker_probe else None
                ),
                expected_marker=(
                    marker_probe[1] if marker_probe else None
                ),
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
    return tuple(profiles)


def marker_counts(text: str) -> dict[str, int]:
    counts = {
        "tb_pass": text.count(TB_PASS),
        "matrix_pass": text.count(MATRIX_PASS),
        "oracle_fail": text.count(ORACLE_FAIL),
        "negative_escaped": text.count(NEGATIVE_ESCAPED),
        "s2_g1_fail": text.count("[S2-G1-"),
    }
    for marker in TUPLE_MARKERS:
        key = (
            marker.strip("[]")
            .lower()
            .replace("-", "_")
        )
        counts[key] = text.count(marker)
    counts["tuple_marker_total"] = sum(
        text.count(marker) for marker in TUPLE_MARKERS
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
    counts = marker_counts(log_text)
    compile_ok = compile_rc == 0 and artifact_exists
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and counts["tb_pass"] == 1
            and counts["matrix_pass"] == 1
            and counts["oracle_fail"] == 0
            and counts["tuple_marker_total"] == 0
            and counts["negative_escaped"] == 0
        )
    elif profile.kind == "tuple-x" and profile.assertions:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and counts["v11j_bridge_stage_tuple_known"] >= 1
            and counts["tb_pass"] == 0
            and counts["negative_escaped"] == 0
        )
    elif profile.kind == "tuple-x":
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and counts["oracle_fail"] >= 1
            and counts["tb_pass"] == 0
            and counts["tuple_marker_total"] == 0
            and counts["negative_escaped"] == 0
        )
    elif profile.assertions and profile.expected_marker:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and log_text.count(profile.expected_marker) >= 1
            and counts["oracle_fail"] == 0
            and counts["tb_pass"] == 0
            and counts["negative_escaped"] == 0
        )
    elif profile.assertions:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and (
                counts["oracle_fail"]
                + counts["tuple_marker_total"]
                + counts["s2_g1_fail"]
            )
            >= 1
            and counts["tb_pass"] == 0
            and counts["negative_escaped"] == 0
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and counts["oracle_fail"] >= 1
            and counts["tb_pass"] == 0
            and counts["tuple_marker_total"] == 0
            and counts["negative_escaped"] == 0
        )
    return passed, counts


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
        return (
            124,
            stdout,
            stderr,
            time.monotonic() - start,
            True,
        )


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
        ["make", "-s", "print-v11j-bridge-holder-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "failed to load V11J Makefile context: "
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
        raise RuntimeError("V11J Makefile context is incomplete")
    if any(not path.is_file() for path in sources):
        raise RuntimeError("V11J Makefile context names a missing source")
    return include_dir, tuple(sources)


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
    bridge_path: Path,
    wrapper_path: Path,
    repo_root: Path,
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    sources = {
        "bridge": bridge_path.read_text(encoding="utf-8"),
        "wrapper": wrapper_path.read_text(encoding="utf-8"),
    }
    variants: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        mutated, receipts = apply_mutation(
            sources[mutation.target], mutation.replacements
        )
        original = (
            bridge_path if mutation.target == "bridge" else wrapper_path
        )
        variant_path = (
            result_dir
            / "variants"
            / mutation.name
            / original.name
        )
        variant_path.parent.mkdir(parents=True, exist_ok=True)
        variant_path.write_text(mutated, encoding="utf-8")
        variants[mutation.name] = variant_path
        records.append(
            {
                "name": mutation.name,
                "debt_unit": mutation.debt_unit,
                "target": repo_path(original, repo_root),
                "production_sha256": sha256_file(original),
                "variant": repo_path(variant_path, repo_root),
                "variant_sha256": sha256_file(variant_path),
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
    bridge_path: Path,
    wrapper_path: Path,
    variant_paths: dict[str, Path],
    mutation_map: dict[str, Mutation],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    build_dir = profile_dir / "build"
    profile_dir.mkdir(parents=True, exist_ok=True)
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{TOP}.vvp"

    sources = list(production_sources)
    if profile.mutation:
        mutation = mutation_map[profile.mutation]
        replaced = bridge_path if mutation.target == "bridge" else wrapper_path
        sources = [
            variant_paths[profile.mutation] if path == replaced else path
            for path in sources
        ]

    defines = [FOCUSED_DEFINE]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
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
        compile_out,
        compile_err,
        compile_seconds,
        compile_timeout,
    ) = run_command(
        compile_command,
        cwd=testbench_dir,
        timeout_seconds=timeout_seconds,
    )
    (profile_dir / "compile.stdout").write_text(
        compile_out, encoding="utf-8"
    )
    (profile_dir / "compile.stderr").write_text(
        compile_err, encoding="utf-8"
    )
    (profile_dir / "compile.rc").write_text(
        f"{compile_rc}\n", encoding="utf-8"
    )

    sim_rc: int | None = None
    sim_out = ""
    sim_err = ""
    sim_seconds = 0.0
    sim_timeout = False
    sim_command = [str(vvp), str(artifact)]
    if compile_rc == 0 and artifact.is_file():
        (
            sim_rc,
            sim_out,
            sim_err,
            sim_seconds,
            sim_timeout,
        ) = run_command(
            sim_command,
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    (profile_dir / "sim.stdout").write_text(sim_out, encoding="utf-8")
    (profile_dir / "sim.stderr").write_text(sim_err, encoding="utf-8")
    (profile_dir / "sim.log").write_text(
        sim_out + sim_err, encoding="utf-8"
    )
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if sim_rc is None else f"{sim_rc}\n",
        encoding="utf-8",
    )
    artifact_exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, counts = evaluate_profile(
        profile,
        compile_rc=compile_rc,
        sim_rc=sim_rc,
        log_text=sim_out + sim_err,
        artifact_exists=artifact_exists,
    )
    commands = {
        "compile": {
            "command": compile_command,
            "mode": (
                "local-rv64-iverilog-assert"
                if profile.assertions
                else "local-rv64-iverilog-release"
            ),
            "purpose": (
                "compile both OooMemAxiBridge product instances with the "
                "V11J holder oracle"
            ),
        },
        "simulate": {
            "command": sim_command,
            "mode": "local-rv64-vvp-cycle-simulation",
            "purpose": (
                "observe station/active/response/verified holder tuples and "
                "the exact residency set"
            ),
        },
    }
    write_json(profile_dir / "commands.json", commands)
    compile_manifest = source_manifest(sources, repo_root)
    write_sha256_manifest(
        profile_dir / "compile-sources.sha256", compile_manifest
    )
    return {
        "profile": profile.name,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "stimulus_define": profile.stimulus_define,
        "expected_marker": profile.expected_marker,
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
            "log": repo_path(profile_dir / "sim.log", repo_root),
            "log_sha256": sha256_file(profile_dir / "sim.log"),
        },
        "markers": counts,
        "compile_source_manifest": compile_manifest,
    }


def evaluate_regression_log(test: str, text: str) -> bool:
    return (
        text.count(f"[PASS] {test}") == 1
        and text.count("[RESULT] PASS") == 1
        and "[RESULT] FAIL" not in text
        and "[V11J-BRIDGE-HOLDER-ORACLE][FAIL]" not in text
        and "[V11J-TUPLE-NEGATIVE-ESCAPED][FAIL]" not in text
    )


def run_regressions(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    timeout_seconds: int,
) -> tuple[bool, list[dict[str, object]]]:
    regression_dir = result_dir / "regressions"
    build_dir = regression_dir / "build"
    log_dir = regression_dir / "logs"
    targets = [
        log_dir / f"{test}.log"
        for test in REGRESSIONS
    ]
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
    (regression_dir / "make.stdout").write_text(
        stdout, encoding="utf-8"
    )
    (regression_dir / "make.stderr").write_text(
        stderr, encoding="utf-8"
    )
    (regression_dir / "make.rc").write_text(
        f"{rc}\n", encoding="utf-8"
    )
    write_json(
        regression_dir / "commands.json",
        {
            "command": command,
            "mode": "local-rv64-iverilog-assert-regression",
            "purpose": (
                "replay the ordinary single bridge, dual wrapper and V9R "
                "retry-C0 regressions against the V11J production source"
            ),
        },
    )
    records: list[dict[str, object]] = []
    for test, log_path in zip(REGRESSIONS, targets):
        exists = log_path.is_file()
        text = (
            log_path.read_text(encoding="utf-8", errors="replace")
            if exists
            else ""
        )
        passed = rc == 0 and exists and evaluate_regression_log(test, text)
        records.append(
            {
                "test": test,
                "status": "PASS" if passed else "FAIL",
                "log": (
                    artifact_record(log_path, repo_root)
                    if exists
                    else None
                ),
            }
        )
    overall = (
        rc == 0
        and not timed_out
        and all(record["status"] == "PASS" for record in records)
    )
    write_json(
        regression_dir / "summary.json",
        {
            "status": "PASS" if overall else "FAIL",
            "command_rc": rc,
            "timeout": timed_out,
            "elapsed_seconds": round(elapsed, 6),
            "tests": records,
        },
    )
    return overall, records


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run assert/release dual OooMemAxiBridge holder lifecycle, "
            "tuple-X and compile-success sensitivity profiles"
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
    bridge_path = (
        repo_root / "npc" / "rv64" / "vsrc" / "memory"
        / "OooMemAxiBridge.v"
    ).resolve()
    wrapper_path = (
        repo_root / "npc" / "rv64" / "vsrc" / "memory"
        / "OooDualMemBridgeWrapper.v"
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
        design_id = current_design_id(repo_root)
        if bridge_path not in production_sources:
            raise RuntimeError("production OooMemAxiBridge.v is absent")
        if wrapper_path not in production_sources:
            raise RuntimeError("production OooDualMemBridgeWrapper.v is absent")

        runner_inputs = [
            *production_sources,
            repo_root / "npc" / "rv64" / "testbench" / "Makefile",
            testbench_dir / "common" / "tb_common.svh",
            testbench_dir / "tests" / "tb_ooo_mem_axi_bridge.sv",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11j_bridge_holder_semantic.py"
            ).resolve(),
        ]
        before = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-before.sha256", before)

        variant_paths, variant_records = build_variants(
            result_dir=result_dir,
            bridge_path=bridge_path,
            wrapper_path=wrapper_path,
            repo_root=repo_root,
        )
        mutation_map = {item.name: item for item in MUTATIONS}
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
                bridge_path=bridge_path,
                wrapper_path=wrapper_path,
                variant_paths=variant_paths,
                mutation_map=mutation_map,
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
            timeout_seconds=args.timeout_seconds,
        )
        after = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-after.sha256", after)
        binding_match = before == after
        passed_count = sum(
            record["status"] == "PASS" for record in profile_records
        )
        overall = (
            binding_match
            and passed_count == len(profile_records)
            and regression_ok
        )
        now = datetime.now(timezone.utc).isoformat()
        source_before_record = artifact_record(
            result_dir / "source-before.sha256", repo_root
        )
        source_after_record = artifact_record(
            result_dir / "source-after.sha256", repo_root
        )
        summary = {
            "schema": SCHEMA,
            "generated_at_utc": now,
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": design_id,
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "profile_count": len(profile_records),
                "mutation_count": len(MUTATIONS),
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
                "bridge": repo_path(bridge_path, repo_root),
                "bridge_sha256": sha256_file(bridge_path),
                "wrapper": repo_path(wrapper_path, repo_root),
                "wrapper_sha256": sha256_file(wrapper_path),
                "product_instances": list(PRODUCT_INSTANCES),
            },
            "binding": {
                "pre_post_match": binding_match,
                "source_before": source_before_record,
                "source_after": source_after_record,
            },
            "independent_oracle": {
                "stimulus_owned_tuple_schedule": True,
                "expected_tuple_uses_dut_query_or_raw_holder": False,
                "checks_both_product_instances": True,
                "checks_stage_active_response_verified": True,
                "checks_exact_32bit_residency_set": True,
                "checks_every_directed_edge": True,
                "checks_raw_owner_tuple_knownness": True,
                "checks_owner_kind_and_mmu_epoch_x": True,
                "assert_and_release_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": passed_count,
                "profiles_fail": len(profile_records) - passed_count,
                "mutations_total": len(MUTATIONS),
                "regressions_total": len(regression_records),
                "regressions_pass": sum(
                    record["status"] == "PASS"
                    for record in regression_records
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
                    "triggered_by_v11j": False,
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
            "# V11J dual bridge holder semantic evidence",
            "",
            f"- status: {summary['status']}",
            f"- profiles: {passed_count}/{len(profile_records)} PASS",
            f"- compile-success variants: {len(MUTATIONS)}",
            f"- ordinary regressions: {sum(record['status'] == 'PASS' for record in regression_records)}/{len(regression_records)} PASS",
            f"- production pre/post binding: {'MATCH' if binding_match else 'DRIFT'}",
            "- configurations: OOO_ASSERT enabled and disabled",
            "- tuple-X stimuli: owner_kind and mmu_epoch",
            "- observations: stage/active/response/verified raw tuple and exact 32-bit residency set",
            "- full-system run: not executed",
            "- architecture/PPA promotion: stopped",
            "",
            "## Profiles",
            "",
        ]
        lines.extend(
            f"- {record['profile']}: {record['status']}"
            for record in profile_records
        )
        lines.extend(
            [
                "",
                "## Ordinary regressions",
                "",
                *(
                    f"- {record['test']}: {record['status']}"
                    for record in regression_records
                ),
            ]
        )
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
        print(f"V11J runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
