#!/usr/bin/env python3
"""Run V11Q integer lane0 completion/resolve packet semantics."""

from __future__ import annotations

import argparse
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common
import run_v11n_memory_pending_holder_semantic as matrix_engine


SCHEMA = "npc-rv64-v11q-int-lane0-packet-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11Q_INT_LANE0_PACKET_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11q_int_lane0_packet"
MATRIX_PASS = "[V11Q-INT-LANE0-PACKET-MATRIX][PASS]"
ORACLE_FAIL = "[V11Q-INT-LANE0-PACKET-ORACLE][FAIL]"
EX0_ALIAS = "integer-ex0-packed-alias"
EX0_PACKET = "integer-ex0-packet"
BRANCH_PACKET = "branch-resolve-packet"
UNIT_IDS = (EX0_ALIAS, EX0_PACKET, BRANCH_PACKET)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = runner_common.REGRESSIONS
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11Q-EX0-PACKET][PASS]": 1,
    "[V11Q-BRANCH-PAIR][PASS]": 1,
    "[V11Q-DEATH-EDGES][PASS]": 1,
}

Replacement = matrix_engine.Replacement
Mutation = matrix_engine.Mutation
Profile = matrix_engine.Profile


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


EX0_UP_VALID = """\
  assign ex0_up_valid_w =
      (issue0_fire_w && !issue0_is_muldiv_w && !issue0_is_clmul_w) ||
      mem_issue_res_local_complete_w;
"""
EX0_UP_PAYLOAD = """\
  assign ex0_up_payload_w =
      {ex0_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup0_valid_w && !ex0_up_from_mem_w,
       ex0_up_producer_id_w[ROB_INDEX_W-1:0],
       ex0_up_from_mem_w ? mem_issue_res_pdest_q : issue0_pdest_w,
       ex0_up_result_w,
       ex0_up_exception_w, ex0_up_cause_w, ex0_up_tval_w};
"""
EX0_ALIAS_ASSIGN = """\
  assign ex0_producer_id_q =
      {ex0_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       ex0_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
"""
EX0_PREAUTH = """\
  assign ex0_pre_auth_valid_w = ex0_valid_q && !ex0_kill_now_w &&
                                !rst && !flush_i &&
                                !checkpoint_restore_apply_w;
"""
BRANCH_UP_PAYLOAD = """\
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      issue0_pc_w,
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      iq_issue0_producer_id_w,
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };
"""
BRANCH_CANDIDATE = """\
  wire branch_resolve_candidate_valid_w =
      branch_resolve_stage_valid_w && !rst && !flush_i &&
      !checkpoint_restore_hold_w;
"""
BRANCH_COHERENCE = """\
  wire branch_resolve_raw_ex0_coherent_w =
      ex0_valid_q &&
      (branch_resolve_payload_producer_id_w == ex0_producer_id_q);
"""


MUTATIONS = (
    Mutation(
        "ex0-pack-generation-zero",
        (EX0_PACKET,),
        "alu-down-packet-pid",
        (
            replacement(
                EX0_UP_PAYLOAD,
                """\
  assign ex0_up_payload_w =
      {{PRODUCER_GEN_W{1'b0}},
       early_wakeup0_valid_w && !ex0_up_from_mem_w,
       ex0_up_producer_id_w[ROB_INDEX_W-1:0],
       ex0_up_from_mem_w ? mem_issue_res_pdest_q : issue0_pdest_w,
       ex0_up_result_w,
       ex0_up_exception_w, ex0_up_cause_w, ex0_up_tval_w};
""",
                "truncate the generation field while packing EX0",
            ),
        ),
    ),
    Mutation(
        "ex0-pack-index-zero",
        (EX0_PACKET,),
        "alu-down-packet-pid",
        (
            replacement(
                EX0_UP_PAYLOAD,
                """\
  assign ex0_up_payload_w =
      {ex0_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup0_valid_w && !ex0_up_from_mem_w,
       {ROB_INDEX_W{1'b0}},
       ex0_up_from_mem_w ? mem_issue_res_pdest_q : issue0_pdest_w,
       ex0_up_result_w,
       ex0_up_exception_w, ex0_up_cause_w, ex0_up_tval_w};
""",
                "zero the nonzero ROB index while packing EX0",
            ),
        ),
    ),
    Mutation(
        "ex0-pack-result-zero",
        (EX0_PACKET,),
        "alu-down-result",
        (
            replacement(
                EX0_UP_PAYLOAD,
                """\
  assign ex0_up_payload_w =
      {ex0_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup0_valid_w && !ex0_up_from_mem_w,
       ex0_up_producer_id_w[ROB_INDEX_W-1:0],
       ex0_up_from_mem_w ? mem_issue_res_pdest_q : issue0_pdest_w,
       {`XLEN{1'b0}},
       ex0_up_exception_w, ex0_up_cause_w, ex0_up_tval_w};
""",
                "corrupt the semantic result field in the EX0 packet",
            ),
        ),
    ),
    Mutation(
        "ex0-alias-generation-zero",
        (EX0_ALIAS,),
        "alu-down-alias-pid",
        (
            replacement(
                EX0_ALIAS_ASSIGN,
                """\
  assign ex0_producer_id_q =
      {{PRODUCER_GEN_W{1'b0}},
       ex0_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
""",
                "truncate generation only in the EX0 packed alias",
            ),
        ),
    ),
    Mutation(
        "ex0-alias-index-zero",
        (EX0_ALIAS,),
        "alu-down-alias-pid",
        (
            replacement(
                EX0_ALIAS_ASSIGN,
                """\
  assign ex0_producer_id_q =
      {ex0_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       {ROB_INDEX_W{1'b0}}};
""",
                "zero the nonzero ROB index only in the EX0 alias",
            ),
        ),
    ),
    Mutation(
        "ex0-capture-suppressed",
        (EX0_PACKET,),
        "alu-up-packet",
        (
            replacement(
                EX0_UP_VALID,
                """\
  assign ex0_up_valid_w =
      1'b0 && ((issue0_fire_w &&
                !issue0_is_muldiv_w && !issue0_is_clmul_w) ||
               mem_issue_res_local_complete_w);
""",
                "suppress the registered EX0 packet birth",
            ),
        ),
    ),
    Mutation(
        "ex0-preauth-omits-flush",
        (EX0_PACKET,),
        "ex0-flush-cut",
        (
            replacement(
                EX0_PREAUTH,
                """\
  assign ex0_pre_auth_valid_w = ex0_valid_q && !ex0_kill_now_w &&
                                !rst &&
                                !checkpoint_restore_apply_w;
""",
                "remove the same-cycle flush cut from EX0 completion",
            ),
        ),
    ),
    Mutation(
        "branch-pack-generation-zero",
        (BRANCH_PACKET,),
        "branch-down-pid",
        (
            replacement(
                BRANCH_UP_PAYLOAD,
                """\
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      issue0_pc_w,
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      {{PRODUCER_GEN_W{1'b0}},
       iq_issue0_producer_id_w[ROB_INDEX_W-1:0]},
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };
""",
                "truncate generation in the branch-resolve packet",
            ),
        ),
    ),
    Mutation(
        "branch-pack-index-zero",
        (BRANCH_PACKET,),
        "branch-down-pid",
        (
            replacement(
                BRANCH_UP_PAYLOAD,
                """\
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      issue0_pc_w,
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      {iq_issue0_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       {ROB_INDEX_W{1'b0}}},
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };
""",
                "zero the nonzero ROB index in the resolve packet",
            ),
        ),
    ),
    Mutation(
        "branch-pack-pc-zero",
        (BRANCH_PACKET,),
        "branch-down-payload",
        (
            replacement(
                BRANCH_UP_PAYLOAD,
                """\
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      {`XLEN{1'b0}},
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      iq_issue0_producer_id_w,
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };
""",
                "corrupt the branch-resolve PC field",
            ),
        ),
    ),
    Mutation(
        "branch-coherence-index-only",
        (BRANCH_PACKET,),
        "branch-wrong-generation-fence",
        (
            replacement(
                BRANCH_COHERENCE,
                """\
  wire branch_resolve_raw_ex0_coherent_w =
      ex0_valid_q &&
      (branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0] ==
       ex0_producer_id_q[ROB_INDEX_W-1:0]);
""",
                "drop generation from raw EX0/resolve coherence",
            ),
        ),
    ),
    Mutation(
        "branch-candidate-omits-flush",
        (BRANCH_PACKET,),
        "branch-flush-cut",
        (
            replacement(
                BRANCH_CANDIDATE,
                """\
  wire branch_resolve_candidate_valid_w =
      branch_resolve_stage_valid_w && !rst &&
      !checkpoint_restore_hold_w;
""",
                "remove the same-cycle flush mask from resolve",
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
        ["make", "-s", "print-v11q-int-lane0-packet-context"],
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
        raise RuntimeError("V11Q Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "print-v11q-int-lane0-packet-regression-context",
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
        raise RuntimeError("V11Q regression context is incomplete")
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
                "test_run_v11q_int_lane0_packet_semantic.py"
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
                "expected_pid_uses_packet_dut_state": False,
                "four_state_exact_comparison": True,
                "producer_generation_one_exercised": True,
                "nonzero_rob_index_two_exercised": True,
                "producer_gen_width_one_and_four": True,
                "raw_ex0_packet_slice_checked": True,
                "ex0_alias_checked_separately": True,
                "branch_packet_payload_checked": True,
                "raw_ex0_resolve_coherence_checked": True,
                "wrong_generation_rejected": True,
                "same_cycle_flush_cut_checked": True,
                "next_cycle_stage_empty_checked": True,
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
                "mechanism": (
                    "integer-lane0-completion-resolve-paired-packet"
                ),
                "semantic_units": list(UNIT_IDS),
                "excluded_units": [
                    "integer-ex1-packed-alias",
                    "integer-ex1-packet",
                ],
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11q": False,
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
                    "# V11Q integer lane0 packet evidence",
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
        print(f"V11Q runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
