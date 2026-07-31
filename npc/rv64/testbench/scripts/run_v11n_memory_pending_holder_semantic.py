#!/usr/bin/env python3
"""Run V11N AMO singleton pending-holder semantic evidence."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common


SCHEMA = "npc-rv64-v11n-memory-pending-holder-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11N_MEMORY_PENDING_HOLDER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11n_memory_pending_holder"
MATRIX_PASS = "[V11N-MEM-PENDING-HOLDER-MATRIX][PASS]"
ORACLE_FAIL = "[V11N-MEM-PENDING-HOLDER-ORACLE][FAIL]"
UNIT_IDS = (
    "memory-pending-producer-cache",
    "memory-pending-token",
)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = runner_common.REGRESSIONS
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11N-LANE0-FULL-WIDTH-BIRTH][PASS]": 2,
    "[V11N-DISPATCH1-TO-TERMINAL0][PASS]": 1,
    "[V11N-READ-WRITE-HOLD][PASS]": 1,
    "[V11N-FINAL-LANE0-DEATH][PASS]": 1,
    "[V11N-INTERPHASE-LANE9-DEATH][PASS]": 1,
    "[V11N-READ-FAULT-LANE0][PASS]": 1,
}


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    unit_ids: tuple[str, ...]
    expected_stage: str
    replacements: tuple[Replacement, ...]


@dataclass(frozen=True)
class Profile:
    name: str
    gen_width: int
    assertions: bool
    kind: str
    mutation: str | None = None
    expected_stage: str | None = None


PENDING_PRODUCER = "memory-pending-producer-cache"
PENDING_TOKEN = "memory-pending-token"


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


ISSUE0_OWNER_CAPTURE = """\
        mem_owner_kind_q <= mem_issue_res_owner_kind_q;
        mem_owner_token_q <= mem_issue_res_owner_token_q;
        mem_mmu_epoch_q <= mem_issue_res_mmu_epoch_q;
"""
READ_PHASE_ENTRY = """\
      if (mem_amo_read_rsp_w) begin
        mem_amo_write_phase_q <= 1'b1;
"""
WRITE_FIRE_ENTRY = """\
      if (push_amo_write_w) begin
        mem_amo_write_sent_q <= 1'b1;
"""
FINAL_PENDING_CLEAR = """\
        end
        mem_pending_q <= 1'b0;
        mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
"""
LANE9_TOKEN_PACK = """\
      mem_retry0_owner_token_q,
      mem_owner_token_q,
      mem_buffer_owner_token_q,
"""


MUTATIONS = (
    Mutation(
        "capture-producer-generation-truncate",
        (PENDING_PRODUCER,),
        "amo-read-pending-birth",
        (
            replacement(
                "        mem_producer_id_q <= "
                "mem_issue_res_producer_id_q;\n",
                "        mem_producer_id_q <= "
                "{{PRODUCER_GEN_W{1'b0}}, "
                "mem_issue_res_producer_id_q[ROB_INDEX_W-1:0]};\n",
                "truncate the AMO singleton cached ProducerId generation",
            ),
        ),
    ),
    Mutation(
        "capture-producer-cross-lane",
        (PENDING_PRODUCER,),
        "amo-read-pending-birth",
        (
            replacement(
                "        mem_producer_id_q <= "
                "mem_issue_res_producer_id_q;\n",
                "        mem_producer_id_q <= "
                "mem_issue1_res_producer_id_q;\n",
                "cross-connect the terminal1 ProducerId into AMO singleton",
            ),
        ),
    ),
    Mutation(
        "capture-producer-x",
        (PENDING_PRODUCER,),
        "amo-read-pending-birth",
        (
            replacement(
                "        mem_producer_id_q <= "
                "mem_issue_res_producer_id_q;\n",
                "        mem_producer_id_q <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "drive unknown ProducerId into the AMO singleton cache",
            ),
        ),
    ),
    Mutation(
        "capture-token-high-truncate",
        (PENDING_TOKEN,),
        "amo-read-pending-birth",
        (
            replacement(
                ISSUE0_OWNER_CAPTURE,
                """\
        mem_owner_kind_q <= mem_issue_res_owner_kind_q;
        mem_owner_token_q <=
            {3'b000, mem_issue_res_owner_token_q[1:0]};
        mem_mmu_epoch_q <= mem_issue_res_mmu_epoch_q;
""",
                "truncate owner token high bits at AMO singleton birth",
            ),
        ),
    ),
    Mutation(
        "capture-token-z",
        (PENDING_TOKEN,),
        "amo-read-pending-birth",
        (
            replacement(
                ISSUE0_OWNER_CAPTURE,
                """\
        mem_owner_kind_q <= mem_issue_res_owner_kind_q;
        mem_owner_token_q <= {5{1'bz}};
        mem_mmu_epoch_q <= mem_issue_res_mmu_epoch_q;
""",
                "drive high impedance into the AMO singleton owner token",
            ),
        ),
    ),
    Mutation(
        "read-phase-producer-generation-truncate",
        (PENDING_PRODUCER,),
        "successful-read-write-phase",
        (
            replacement(
                READ_PHASE_ENTRY,
                """\
      if (mem_amo_read_rsp_w) begin
        mem_producer_id_q <=
            {{PRODUCER_GEN_W{1'b0}},
             mem_producer_id_q[ROB_INDEX_W-1:0]};
        mem_amo_write_phase_q <= 1'b1;
""",
                "corrupt cached ProducerId on AMO read-to-write transition",
            ),
        ),
    ),
    Mutation(
        "read-phase-token-high-truncate",
        (PENDING_TOKEN,),
        "successful-read-write-phase",
        (
            replacement(
                READ_PHASE_ENTRY,
                """\
      if (mem_amo_read_rsp_w) begin
        mem_owner_token_q <= {3'b000, mem_owner_token_q[1:0]};
        mem_amo_write_phase_q <= 1'b1;
""",
                "corrupt owner token on AMO read-to-write transition",
            ),
        ),
    ),
    Mutation(
        "read-phase-clears-pending",
        UNIT_IDS,
        "successful-read-write-phase",
        (
            replacement(
                READ_PHASE_ENTRY,
                """\
      if (mem_amo_read_rsp_w) begin
        mem_pending_q <= 1'b0;
        mem_amo_write_phase_q <= 1'b1;
""",
                "clear singleton residency on the nonterminal read response",
            ),
        ),
    ),
    Mutation(
        "write-fire-producer-generation-truncate",
        (PENDING_PRODUCER,),
        "post-write-hold",
        (
            replacement(
                WRITE_FIRE_ENTRY,
                """\
      if (push_amo_write_w) begin
        mem_producer_id_q <=
            {{PRODUCER_GEN_W{1'b0}},
             mem_producer_id_q[ROB_INDEX_W-1:0]};
        mem_amo_write_sent_q <= 1'b1;
""",
                "corrupt cached ProducerId on physical AMO write fire",
            ),
        ),
    ),
    Mutation(
        "write-fire-token-high-truncate",
        (PENDING_TOKEN,),
        "post-write-hold",
        (
            replacement(
                WRITE_FIRE_ENTRY,
                """\
      if (push_amo_write_w) begin
        mem_owner_token_q <= {3'b000, mem_owner_token_q[1:0]};
        mem_amo_write_sent_q <= 1'b1;
""",
                "corrupt cached owner token on physical AMO write fire",
            ),
        ),
    ),
    Mutation(
        "final-response-keeps-pending",
        UNIT_IDS,
        "amo-final-next-cycle-clear",
        (
            replacement(
                FINAL_PENDING_CLEAR,
                """\
        end
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
""",
                "retain singleton valid after the exact final response",
            ),
        ),
    ),
    Mutation(
        "interphase-cancel-suppressed",
        (PENDING_TOKEN,),
        "amo-interphase-cancel",
        (
            replacement(
                """\
  wire mem_amo_interphase_cancel_w =
      mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
""",
                """\
  wire mem_amo_interphase_cancel_w =
      1'b0 && mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
""",
                "suppress the AMO interphase collector terminal",
            ),
        ),
    ),
    Mutation(
        "interphase-lane9-token-high-truncate",
        (PENDING_TOKEN,),
        "amo-interphase-lane9",
        (
            replacement(
                LANE9_TOKEN_PACK,
                """\
      mem_retry0_owner_token_q,
      {3'b000, mem_owner_token_q[1:0]},
      mem_buffer_owner_token_q,
""",
                "truncate the owner token carried by collector lane9",
            ),
        ),
    ),
)


def apply_mutation(
    source: str, replacements: Sequence[Replacement]
) -> tuple[str, list[dict[str, object]]]:
    common_replacements = tuple(
        runner_common.Replacement(item.anchor, item.replacement, item.purpose)
        for item in replacements
    )
    return runner_common.apply_mutation(source, common_replacements)


def build_profiles() -> tuple[Profile, ...]:
    baselines = tuple(
        Profile(
            f"production-g{gen_width}-"
            f"{'assert' if assertions else 'release'}",
            gen_width,
            assertions,
            "baseline",
        )
        for gen_width in GEN_WIDTHS
        for assertions in (True, False)
    )
    mutations = tuple(
        Profile(
            f"{mutation.name}-g{gen_width}-release",
            gen_width,
            False,
            "mutation",
            mutation=mutation.name,
            expected_stage=mutation.expected_stage,
        )
        for mutation in MUTATIONS
        for gen_width in GEN_WIDTHS
    )
    return baselines + mutations


def marker_counts(text: str) -> dict[str, int]:
    result = {
        "tb_pass": text.count(TB_PASS),
        "matrix_pass": text.count(MATRIX_PASS),
        "oracle_fail": text.count(ORACLE_FAIL),
    }
    for marker in BASELINE_MARKERS:
        result[marker] = text.count(marker)
    return result


def oracle_failure_stages(text: str) -> list[str]:
    return re.findall(
        re.escape(ORACLE_FAIL)
        + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
        text,
    )


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    compile_timeout: bool,
    sim_rc: int | None,
    sim_timeout: bool,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    markers = marker_counts(log_text)
    stages = oracle_failure_stages(log_text)
    compile_ok = (
        compile_rc == 0 and not compile_timeout and artifact_exists
    )
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and not sim_timeout
            and markers["tb_pass"] == 1
            and markers["matrix_pass"] == 1
            and markers["oracle_fail"] == 0
            and not stages
            and all(
                markers[marker] == count
                for marker, count in BASELINE_MARKERS.items()
            )
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and not sim_timeout
            and markers["oracle_fail"] == 1
            and stages == [profile.expected_stage]
            and markers["tb_pass"] == 0
            and markers["matrix_pass"] == 0
        )
    return passed, markers


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        ["make", "-s", "print-v11n-memory-pending-holder-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.split("=", 1)[1]).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.split("=", 1)[1]).resolve())
    if include_dir is None or not sources:
        raise RuntimeError("V11N Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "print-v11n-memory-pending-holder-regression-context",
        ],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    common: list[Path] = []
    sources = {test: [] for test in REGRESSIONS}
    prefix = "REGRESSION_SOURCE_"
    for line in completed.stdout.splitlines():
        if line.startswith("REGRESSION_COMMON="):
            common.append(Path(line.split("=", 1)[1]).resolve())
        elif line.startswith(prefix):
            key, raw = line.split("=", 1)
            test = key[len(prefix):]
            if test not in sources:
                raise RuntimeError(f"unknown regression context: {test}")
            sources[test].append(Path(raw).resolve())
    result = {
        test: tuple(sorted({*paths, *common}))
        for test, paths in sources.items()
    }
    if not common or any(not paths for paths in result.values()):
        raise RuntimeError("V11N regression context is incomplete")
    return result


def build_variants(
    *,
    result_dir: Path,
    rtl_path: Path,
    repo_root: Path,
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    source = rtl_path.read_text(encoding="utf-8")
    variants: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = result_dir / "variants" / mutation.name / rtl_path.name
        variant.parent.mkdir(parents=True, exist_ok=True)
        variant.write_text(mutated, encoding="utf-8")
        variants[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_ids": list(mutation.unit_ids),
                "expected_stage": mutation.expected_stage,
                "target": runner_common.repo_path(rtl_path, repo_root),
                "production_sha256": runner_common.sha256_file(rtl_path),
                "variant": runner_common.repo_path(variant, repo_root),
                "variant_sha256": runner_common.sha256_file(variant),
                "compile_success_required": True,
                "assertions": False,
                "receipts": receipts,
            }
        )
    runner_common.write_json(result_dir / "variants/manifest.json", records)
    return variants, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    rtl_path: Path,
    variants: dict[str, Path],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    profile_dir.mkdir(parents=True, exist_ok=True)
    artifact = profile_dir / f"{TOP}.vvp"
    sources = [
        variants[profile.mutation]
        if profile.mutation and path == rtl_path
        else path
        for path in production_sources
    ]
    defines = [
        FOCUSED_DEFINE,
        f"-DOOO_PRODUCER_GEN_W={profile.gen_width}",
    ]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    compile_command = [
        str(iverilog),
        "-g2012",
        "-Wall",
        f"-I{repo_root / 'npc/rv64/vsrc'}",
        f"-I{include_dir}",
        f"-I{testbench_dir / 'common'}",
        *defines,
        "-s",
        TOP,
        "-o",
        str(artifact),
        *(str(path) for path in sources),
    ]
    crc, cout, cerr, cseconds, ctimeout = runner_common.run_command(
        compile_command,
        cwd=testbench_dir,
        timeout_seconds=timeout_seconds,
    )
    (profile_dir / "compile.stdout").write_text(cout, encoding="utf-8")
    (profile_dir / "compile.stderr").write_text(cerr, encoding="utf-8")
    (profile_dir / "compile.rc").write_text(f"{crc}\n", encoding="utf-8")
    src, sout, serr, sseconds, stimeout = (
        None,
        "",
        "",
        0.0,
        False,
    )
    if crc == 0 and artifact.is_file():
        src, sout, serr, sseconds, stimeout = runner_common.run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    log = profile_dir / "sim.log"
    log.write_text(sout + serr, encoding="utf-8")
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if src is None else f"{src}\n",
        encoding="utf-8",
    )
    exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, markers = evaluate_profile(
        profile,
        compile_rc=crc,
        compile_timeout=ctimeout,
        sim_rc=src,
        sim_timeout=stimeout,
        log_text=sout + serr,
        artifact_exists=exists,
    )
    record = {
        "profile": profile.name,
        "producer_gen_width": profile.gen_width,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "expected_stage": profile.expected_stage,
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": crc,
            "timeout": ctimeout,
            "elapsed_seconds": round(cseconds, 6),
            "command": compile_command,
            "defines": defines,
            "artifact": runner_common.repo_path(artifact, repo_root),
            "artifact_exists": exists,
            "artifact_sha256": (
                runner_common.sha256_file(artifact) if exists else None
            ),
        },
        "simulation": {
            "rc": src,
            "timeout": stimeout,
            "elapsed_seconds": round(sseconds, 6),
            "log": runner_common.repo_path(log, repo_root),
            "log_sha256": runner_common.sha256_file(log),
        },
        "markers": markers,
        "compile_source_manifest": runner_common.source_manifest(
            sources, repo_root
        ),
    }
    runner_common.write_json(profile_dir / "profile.json", record)
    return record


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
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
    testbench_dir = repo_root / "npc/rv64/testbench"
    rtl_path = (
        repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
    ).resolve()
    status_path = result_dir / "runner.status"
    if result_dir.exists() and any(result_dir.iterdir()):
        if not args.overwrite:
            print(f"result directory is not empty: {result_dir}")
            return 2
        shutil.rmtree(result_dir)
    result_dir.mkdir(parents=True, exist_ok=True)
    runner_common.atomic_status(status_path, "RUNNING")
    try:
        iverilog, vvp = runner_common.resolve_tools()
        include_dir, production_sources = load_make_context(testbench_dir)
        regressions = load_regression_context(testbench_dir)
        if rtl_path not in production_sources:
            raise RuntimeError("production OooIntBackend.v is absent")
        runner_inputs = [
            *production_sources,
            include_dir / "define.v",
            testbench_dir / "Makefile",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11n_memory_pending_holder_semantic.py"
            ).resolve(),
            Path(runner_common.__file__).resolve(),
            *(
                path
                for test in REGRESSIONS
                for path in regressions[test]
            ),
        ]
        before = runner_common.source_manifest(runner_inputs, repo_root)
        runner_common.write_sha256_manifest(
            result_dir / "source-before.sha256", before
        )
        variants, variant_records = build_variants(
            result_dir=result_dir,
            rtl_path=rtl_path,
            repo_root=repo_root,
        )
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                rtl_path=rtl_path,
                variants=variants,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            print(f"{profile.name}: {record['status']}")
        regression_ok, regression_records = runner_common.run_regressions(
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            contexts=regressions,
            timeout_seconds=args.timeout_seconds,
        )
        after = runner_common.source_manifest(runner_inputs, repo_root)
        runner_common.write_sha256_manifest(
            result_dir / "source-after.sha256", after
        )
        binding_match = before == after
        profiles_pass = sum(
            item["status"] == "PASS" for item in profile_records
        )
        regressions_pass = sum(
            item["status"] == "PASS" for item in regression_records
        )
        overall = (
            binding_match
            and profiles_pass == len(profile_records)
            and regression_ok
        )
        summary: dict[str, Any] = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": runner_common.current_design_id(repo_root),
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "producer_gen_widths": list(GEN_WIDTHS),
                "profile_count": len(profile_records),
                "baseline_profile_count": 4,
                "mutation_count": len(MUTATIONS),
                "mutation_profile_count": len(MUTATIONS) * len(GEN_WIDTHS),
                "regression_count": len(REGRESSIONS),
                "baseline_assert_and_release": True,
                "mutations_release_mode": True,
                "full_system_run": False,
            },
            "tools": {
                "iverilog": str(iverilog),
                "iverilog_sha256": runner_common.sha256_file(iverilog),
                "vvp": str(vvp),
                "vvp_sha256": runner_common.sha256_file(vvp),
            },
            "production": {
                "rtl": runner_common.repo_path(rtl_path, repo_root),
                "rtl_sha256": runner_common.sha256_file(rtl_path),
                "focused_testbench": runner_common.repo_path(
                    testbench_dir / "tests/tb_ooo_int_backend.sv",
                    repo_root,
                ),
                "focused_testbench_sha256": runner_common.sha256_file(
                    testbench_dir / "tests/tb_ooo_int_backend.sv"
                ),
                "product_instances": [PRODUCT_INSTANCE],
            },
            "binding": {
                "pre_post_match": binding_match,
                "source_before": runner_common.artifact_record(
                    result_dir / "source-before.sha256", repo_root
                ),
                "source_after": runner_common.artifact_record(
                    result_dir / "source-after.sha256", repo_root
                ),
            },
            "independent_oracle": {
                "stimulus_owned_reset_allocation_schedule": True,
                "expected_pid_uses_pending_dut_state": False,
                "expected_token_uses_pending_dut_state": False,
                "four_state_exact_comparison": True,
                "producer_generation_one_exercised": True,
                "producer_gen_width_one_and_four": True,
                "owner_token_28_high_bits_exercised": True,
                "dispatch_lane1_routes_to_execution_terminal0": True,
                "read_pending_hold": True,
                "read_to_write_phase_hold": True,
                "write_grant_stall_hold": True,
                "post_write_hold": True,
                "collector_lane0_final_acceptance": True,
                "collector_lane9_cancel_acceptance": True,
                "read_fault_lane0_no_lane9_duplicate": True,
                "tracker_terminal_death": True,
                "release_mode_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": profiles_pass,
                "profiles_fail": len(profile_records) - profiles_pass,
                "baseline_profiles_total": 4,
                "mutations_total": len(MUTATIONS),
                "mutation_profiles_total": len(MUTATIONS)
                * len(GEN_WIDTHS),
                "regressions_total": len(regression_records),
                "regressions_pass": regressions_pass,
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "semantic_units": list(UNIT_IDS),
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11n": False,
                    "run": False,
                    "current_whole_design_recertification": (
                        "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                        "PRODUCTION_RTL_DELTA"
                    ),
                },
            },
            "promotion": {
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        runner_common.write_json(result_dir / "summary.json", summary)
        (result_dir / "summary.md").write_text(
            "\n".join(
                [
                    "# V11N AMO singleton pending-holder evidence",
                    "",
                    f"- status: {summary['status']}",
                    (
                        "- profiles: "
                        f"{profiles_pass}/{len(profile_records)} PASS"
                    ),
                    (
                        "- compile-success mutations: "
                        f"{len(MUTATIONS)} cases × {len(GEN_WIDTHS)} widths"
                    ),
                    (
                        "- regressions: "
                        f"{regressions_pass}/{len(regression_records)} PASS"
                    ),
                    (
                        "- source pre/post: "
                        f"{'MATCH' if binding_match else 'DRIFT'}"
                    ),
                    "- production RTL change: none",
                    "- A3 original FAIL retained; checker replay remains separate",
                    "- current whole-design system recert: still required before promotion",
                    "- whole architecture: RED",
                    "- PPA: UNPROMOTED",
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        runner_common.atomic_status(
            status_path, "PASS" if overall else "FAIL"
        )
        return 0 if overall else 1
    except Exception as exc:
        runner_common.write_json(
            result_dir / "runner-error.json",
            {
                "schema": SCHEMA,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        )
        runner_common.atomic_status(status_path, "FAIL")
        print(f"V11N runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
