#!/usr/bin/env python3
"""Run V11R integer lane1 completion-packet semantics."""

from __future__ import annotations

import argparse
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common
import run_v11n_memory_pending_holder_semantic as matrix_engine


SCHEMA = "npc-rv64-v11r-int-lane1-packet-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11R_INT_LANE1_PACKET_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11r_int_lane1_packet"
MATRIX_PASS = "[V11R-INT-LANE1-PACKET-MATRIX][PASS]"
ORACLE_FAIL = "[V11R-INT-LANE1-PACKET-ORACLE][FAIL]"
EX1_ALIAS = "integer-ex1-packed-alias"
EX1_PACKET = "integer-ex1-packet"
UNIT_IDS = (EX1_ALIAS, EX1_PACKET)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = runner_common.REGRESSIONS
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11R-EX1-ALU-PACKET][PASS]": 1,
    "[V11R-EX1-LOCAL-PACKET][PASS]": 1,
    "[V11R-EX1-AUTH-EDGES][PASS]": 1,
    "[V11R-EX1-DEATH-EDGES][PASS]": 1,
}

Replacement = matrix_engine.Replacement
Mutation = matrix_engine.Mutation
Profile = matrix_engine.Profile


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


EX1_UP_VALID = """\
  assign ex1_up_valid_w = issue1_exec_fire_w ||
                          mem_issue1_res_local_complete_w;
"""
EX1_UP_EXCEPTION = """\
  wire ex1_up_exception_w = ex1_up_from_mem_w && issue1_is_mem_w &&
                            !issue1_sq_fwd_w && issue1_mem_exception_w;
"""
EX1_UP_TVAL = """\
  wire [`XLEN-1:0] ex1_up_tval_w = ex1_up_exception_w ?
      mem_issue1_res_eff_addr_w : {`XLEN{1'b0}};
"""
EX1_UP_PRODUCER = """\
  wire [PRODUCER_ID_W-1:0] ex1_up_producer_id_w = ex1_up_from_mem_w ?
      mem_issue1_res_producer_id_q : issue1_producer_id_w;
"""
EX1_UP_PAYLOAD = """\
  assign ex1_up_payload_w =
      {ex1_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       ex1_up_producer_id_w[ROB_INDEX_W-1:0],
       ex1_up_from_mem_w ? mem_issue1_res_pdest_q : issue1_pdest_w,
       ex1_up_result_w,
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};
"""
EX1_ALIAS_ASSIGN = """\
  assign ex1_producer_id_q =
      {ex1_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       ex1_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
"""
EX1_PREAUTH = """\
  assign ex1_pre_auth_valid_w = ex1_valid_q && !ex1_kill_now_w &&
                                !rst && !flush_i &&
                                !checkpoint_restore_apply_w;
"""
EX1_SAME_EDGE = """\
  wire ex1_same_edge_claimed_w = ex0_wb_valid_w &&
      (ex0_producer_id_q == ex1_producer_id_q);
"""
EX1_WB_VALID = """\
  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w &&
                          !ex1_fp_pending_owned_w &&
                          !ex1_same_edge_claimed_w;
"""


MUTATIONS = (
    Mutation(
        "ex1-pack-generation-zero",
        (EX1_PACKET,),
        "alu-down-packet-pid",
        (
            replacement(
                EX1_UP_PAYLOAD,
                """\
  assign ex1_up_payload_w =
      {{PRODUCER_GEN_W{1'b0}},
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       ex1_up_producer_id_w[ROB_INDEX_W-1:0],
       ex1_up_from_mem_w ? mem_issue1_res_pdest_q : issue1_pdest_w,
       ex1_up_result_w,
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};
""",
                "zero the EX1 packet generation field",
            ),
        ),
    ),
    Mutation(
        "ex1-pack-index-zero",
        (EX1_PACKET,),
        "alu-down-packet-pid",
        (
            replacement(
                EX1_UP_PAYLOAD,
                """\
  assign ex1_up_payload_w =
      {ex1_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       {ROB_INDEX_W{1'b0}},
       ex1_up_from_mem_w ? mem_issue1_res_pdest_q : issue1_pdest_w,
       ex1_up_result_w,
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};
""",
                "zero the nonzero EX1 packet ROB index",
            ),
        ),
    ),
    Mutation(
        "ex1-pack-result-zero",
        (EX1_PACKET,),
        "alu-down-payload",
        (
            replacement(
                EX1_UP_PAYLOAD,
                """\
  assign ex1_up_payload_w =
      {ex1_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       ex1_up_producer_id_w[ROB_INDEX_W-1:0],
       ex1_up_from_mem_w ? mem_issue1_res_pdest_q : issue1_pdest_w,
       {`XLEN{1'b0}},
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};
""",
                "zero the EX1 ALU result field",
            ),
        ),
    ),
    Mutation(
        "ex1-pack-pdest-zero",
        (EX1_PACKET,),
        "alu-down-payload",
        (
            replacement(
                EX1_UP_PAYLOAD,
                """\
  assign ex1_up_payload_w =
      {ex1_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       ex1_up_producer_id_w[ROB_INDEX_W-1:0],
       {PHY_REG_ADDR_W{1'b0}},
       ex1_up_result_w,
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};
""",
                "zero the EX1 physical destination field",
            ),
        ),
    ),
    Mutation(
        "ex1-alias-generation-zero",
        (EX1_ALIAS,),
        "alu-down-alias-pid",
        (
            replacement(
                EX1_ALIAS_ASSIGN,
                """\
  assign ex1_producer_id_q =
      {{PRODUCER_GEN_W{1'b0}},
       ex1_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
""",
                "zero generation only in the EX1 packed alias",
            ),
        ),
    ),
    Mutation(
        "ex1-alias-index-zero",
        (EX1_ALIAS,),
        "alu-down-alias-pid",
        (
            replacement(
                EX1_ALIAS_ASSIGN,
                """\
  assign ex1_producer_id_q =
      {ex1_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       {ROB_INDEX_W{1'b0}}};
""",
                "zero the nonzero index only in the EX1 alias",
            ),
        ),
    ),
    Mutation(
        "ex1-capture-suppressed",
        (EX1_PACKET,),
        "alu-up-packet",
        (
            replacement(
                EX1_UP_VALID,
                """\
  assign ex1_up_valid_w =
      1'b0 && (issue1_exec_fire_w ||
               mem_issue1_res_local_complete_w);
""",
                "suppress every EX1 registered packet birth",
            ),
        ),
    ),
    Mutation(
        "ex1-local-capture-suppressed",
        (EX1_PACKET,),
        "local-up-packet",
        (
            replacement(
                EX1_UP_VALID,
                """\
  assign ex1_up_valid_w = issue1_exec_fire_w;
""",
                "remove the lane1 local-memory birth arm only",
            ),
        ),
    ),
    Mutation(
        "ex1-local-source-uses-iq-identity",
        (EX1_PACKET,),
        "local-up-packet",
        (
            replacement(
                EX1_UP_PRODUCER,
                """\
  wire [PRODUCER_ID_W-1:0] ex1_up_producer_id_w =
      issue1_producer_id_w;
""",
                "ignore the resident memory ProducerId at local completion",
            ),
        ),
    ),
    Mutation(
        "ex1-local-exception-suppressed",
        (EX1_PACKET,),
        "local-up-exception",
        (
            replacement(
                EX1_UP_EXCEPTION,
                """\
  wire ex1_up_exception_w =
      1'b0 && ex1_up_from_mem_w && issue1_is_mem_w &&
      !issue1_sq_fwd_w && issue1_mem_exception_w;
""",
                "suppress the lane1 local exception payload bit",
            ),
        ),
    ),
    Mutation(
        "ex1-local-tval-zero",
        (EX1_PACKET,),
        "local-up-tval",
        (
            replacement(
                EX1_UP_TVAL,
                """\
  wire [`XLEN-1:0] ex1_up_tval_w = {`XLEN{1'b0}};
""",
                "zero the lane1 local exception tval",
            ),
        ),
    ),
    Mutation(
        "ex1-preauth-omits-flush",
        (EX1_PACKET,),
        "ex1-flush-cut",
        (
            replacement(
                EX1_PREAUTH,
                """\
  assign ex1_pre_auth_valid_w = ex1_valid_q && !ex1_kill_now_w &&
                                !rst &&
                                !checkpoint_restore_apply_w;
""",
                "remove the same-cycle flush cut from EX1",
            ),
        ),
    ),
    Mutation(
        "ex1-completion-bypasses-exact-open",
        (EX1_PACKET,),
        "alu-wrong-generation-authorization",
        (
            replacement(
                EX1_WB_VALID,
                """\
  assign ex1_wb_valid_w = ex1_pre_auth_valid_w &&
                          !ex1_fp_pending_owned_w &&
                          !ex1_same_edge_claimed_w;
""",
                "remove exact ROB-open authorization from EX1",
            ),
        ),
    ),
    Mutation(
        "ex1-same-edge-claim-index-only",
        (EX1_PACKET,),
        "same-index-wrong-generation-fence",
        (
            replacement(
                EX1_SAME_EDGE,
                """\
  wire ex1_same_edge_claimed_w = ex0_wb_valid_w &&
      (ex0_producer_id_q[ROB_INDEX_W-1:0] ==
       ex1_producer_id_q[ROB_INDEX_W-1:0]);
""",
                "drop generation from EX0-to-EX1 same-edge arbitration",
            ),
        ),
    ),
)


def _configure_matrix_engine() -> None:
    matrix_engine.SCHEMA = SCHEMA
    matrix_engine.TOP = TOP
    matrix_engine.FOCUSED_DEFINE = FOCUSED_DEFINE
    matrix_engine.TB_PASS = TB_PASS
    matrix_engine.MATRIX_PASS = MATRIX_PASS
    matrix_engine.ORACLE_FAIL = ORACLE_FAIL
    matrix_engine.UNIT_IDS = UNIT_IDS
    matrix_engine.PRODUCT_INSTANCE = PRODUCT_INSTANCE
    matrix_engine.REGRESSIONS = REGRESSIONS
    matrix_engine.GEN_WIDTHS = GEN_WIDTHS
    matrix_engine.BASELINE_MARKERS = BASELINE_MARKERS
    matrix_engine.MUTATIONS = MUTATIONS


_configure_matrix_engine()
apply_mutation = matrix_engine.apply_mutation
build_profiles = matrix_engine.build_profiles
marker_counts = matrix_engine.marker_counts
oracle_failure_stages = matrix_engine.oracle_failure_stages
evaluate_profile = matrix_engine.evaluate_profile
build_variants = matrix_engine.build_variants
run_profile = matrix_engine.run_profile


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        ["make", "-s", "print-v11r-int-lane1-packet-context"],
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
        raise RuntimeError("V11R Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "print-v11r-int-lane1-packet-regression-context",
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
        raise RuntimeError("V11R regression context is incomplete")
    return result


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
                "test_run_v11r_int_lane1_packet_semantic.py"
            ).resolve(),
            Path(matrix_engine.__file__).resolve(),
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
        baseline_count = len(GEN_WIDTHS) * 2
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
                "enable_dual_mem": 1,
                "producer_gen_widths": list(GEN_WIDTHS),
                "profile_count": len(profile_records),
                "baseline_profile_count": baseline_count,
                "mutation_count": len(MUTATIONS),
                "mutation_profile_count": len(MUTATIONS)
                * len(GEN_WIDTHS),
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
                "pipe_stage_rtl": "npc/rv64/vsrc/pipeline/PipeStageReg.v",
                "pipe_stage_rtl_sha256": runner_common.sha256_file(
                    repo_root / "npc/rv64/vsrc/pipeline/PipeStageReg.v"
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
                "stimulus_owned_allocation_schedule": True,
                "expected_pid_uses_ex1_or_memory_holder_state": False,
                "four_state_exact_comparison": True,
                "producer_generation_one_exercised": True,
                "nonzero_rob_index_three_exercised": True,
                "producer_gen_width_one_and_four": True,
                "dual_dispatch_alu_source_checked": True,
                "lane1_local_memory_source_checked": True,
                "raw_ex1_packet_slice_checked": True,
                "ex1_alias_checked_separately": True,
                "result_and_pdest_checked": True,
                "exception_cause_tval_checked": True,
                "exact_rob_open_checked": True,
                "same_index_wrong_generation_not_claimed": True,
                "wrong_generation_rejected": True,
                "same_cycle_flush_cut_checked": True,
                "next_cycle_stage_empty_checked": True,
                "release_mode_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": profiles_pass,
                "profiles_fail": len(profile_records) - profiles_pass,
                "baseline_profiles_total": baseline_count,
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
                "mechanism": "integer-lane1-completion-packet",
                "semantic_units": list(UNIT_IDS),
                "source_paths": [
                    "lane1-fixed-latency-alu",
                    "lane1-local-memory-completion",
                ],
                "excluded_units": [
                    "floating-point-completion-paths",
                    "remote-memory-response-completion",
                ],
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_execution_state": "COMPLETE",
                "a3_terminal_state": "COMPLETE",
                "a3_oracle_state": "OLD_ORACLE_INVALID",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "a3_interpretation": (
                    "SYSTEM_TRANSACTION_COMPLETE_"
                    "LEGACY_ORACLE_FALSE_POSITIVE"
                ),
                "system_rerun": {
                    "triggered_by_v11r": False,
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
                    "# V11R integer lane1 packet evidence",
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
        print(f"V11R runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
