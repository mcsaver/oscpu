#!/usr/bin/env python3
"""Run V11P checkpoint irreversible-write ProducerId semantics."""

from __future__ import annotations

import argparse
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common
import run_v11n_memory_pending_holder_semantic as matrix_engine


SCHEMA = "npc-rv64-v11p-checkpoint-irrevocable-write-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11p_checkpoint_irrevocable_write"
MATRIX_PASS = "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-MATRIX][PASS]"
ORACLE_FAIL = "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-ORACLE][FAIL]"
UNIT_IDS = ("checkpoint-irrevocable-write-producer",)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = runner_common.REGRESSIONS
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11P-STORE-LIFECYCLE][PASS]": 1,
    "[V11P-AMO-LIFECYCLE][PASS]": 1,
    "[V11P-WRONG-GENERATION-RETIRE-GUARD][PASS]": 1,
}

Replacement = matrix_engine.Replacement
Mutation = matrix_engine.Mutation
Profile = matrix_engine.Profile


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


LAUNCH = """\
  wire checkpoint_irrevocable_write_launch_w =
      mem_req_fire_any_w && mem_req_write_o && !mem_req_probe_o;
"""
CAPTURE = """\
        checkpoint_irrevocable_write_pid_q <=
            checkpoint_irrevocable_write_launch_pid_w;
"""
TERMINAL_CLEAR_ENTRY = """\
    end else begin
      if (checkpoint_irrevocable_write_retire_w) begin
"""
LIVE_MASK = """\
  wire [(1 << PRODUCER_ID_W)-1:0]
      checkpoint_irrevocable_write_live_mask_w =
      checkpoint_irrevocable_write_q ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       checkpoint_irrevocable_write_pid_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
"""
RETIRE = """\
  wire checkpoint_irrevocable_write_retire_w =
      commit0_valid_o && checkpoint_irrevocable_write_q &&
      (rob_commit0_producer_id_w == checkpoint_irrevocable_write_pid_q);
"""
RESTORE_GATE = """\
  assign checkpoint_restore_apply_w =
      (checkpoint_restore_new_req_w || checkpoint_restore_pending_q) &&
      !checkpoint_irrevocable_write_q && sq_no_active_write_w &&
      !drain_inflight_q;
"""


MUTATIONS = (
    Mutation(
        "capture-pid-generation-truncate",
        UNIT_IDS,
        "store-holder-birth",
        (
            replacement(
                CAPTURE,
                """\
        checkpoint_irrevocable_write_pid_q <=
            {{PRODUCER_GEN_W{1'b0}},
             checkpoint_irrevocable_write_launch_pid_w[
                 ROB_INDEX_W-1:0]};
""",
                "truncate the captured physical-write ProducerId generation",
            ),
        ),
    ),
    Mutation(
        "capture-pid-x",
        UNIT_IDS,
        "store-holder-birth",
        (
            replacement(
                CAPTURE,
                """\
        checkpoint_irrevocable_write_pid_q <=
            {PRODUCER_ID_W{1'bx}};
""",
                "drive unknown bits into the captured physical-write PID",
            ),
        ),
    ),
    Mutation(
        "store-launch-suppressed",
        UNIT_IDS,
        "store-launch-edge",
        (
            replacement(
                LAUNCH,
                """\
  wire checkpoint_irrevocable_write_launch_w =
      mem_req_fire_any_w && mem_req_write_o && !mem_req_probe_o &&
      (mem_req_owner_kind_o == MEM_OWNER_ATOMIC);
""",
                "exclude STORE physical requests from holder birth",
            ),
        ),
    ),
    Mutation(
        "amo-launch-suppressed",
        UNIT_IDS,
        "amo-launch-edge",
        (
            replacement(
                LAUNCH,
                """\
  wire checkpoint_irrevocable_write_launch_w =
      mem_req_fire_any_w && mem_req_write_o && !mem_req_probe_o &&
      (mem_req_owner_kind_o == MEM_OWNER_STORE);
""",
                "exclude AMO physical-write requests from holder birth",
            ),
        ),
    ),
    Mutation(
        "terminal-clears-holder",
        UNIT_IDS,
        "store-post-terminal-holder",
        (
            replacement(
                TERMINAL_CLEAR_ENTRY,
                """\
    end else begin
      if (miq_drain_rsp_fire_w || mem_rsp_final_fire_w)
        checkpoint_irrevocable_write_q <= 1'b0;
      if (checkpoint_irrevocable_write_retire_w) begin
""",
                "clear irreversible residency on terminal response",
            ),
        ),
    ),
    Mutation(
        "terminal-corrupts-pid",
        UNIT_IDS,
        "store-post-terminal-holder",
        (
            replacement(
                TERMINAL_CLEAR_ENTRY,
                """\
    end else begin
      if (miq_drain_rsp_fire_w || mem_rsp_final_fire_w)
        checkpoint_irrevocable_write_pid_q <=
            {PRODUCER_ID_W{1'bx}};
      if (checkpoint_irrevocable_write_retire_w) begin
""",
                "corrupt the resident PID on terminal response",
            ),
        ),
    ),
    Mutation(
        "live-mask-omits-holder",
        UNIT_IDS,
        "store-holder-birth",
        (
            replacement(
                LIVE_MASK,
                """\
  wire [(1 << PRODUCER_ID_W)-1:0]
      checkpoint_irrevocable_write_live_mask_w =
      {(1 << PRODUCER_ID_W){1'b0}};
""",
                "remove the irreversible holder from the ProducerId fence",
            ),
        ),
    ),
    Mutation(
        "retire-suppressed",
        UNIT_IDS,
        "store-exact-retire-edge",
        (
            replacement(
                RETIRE,
                """\
  wire checkpoint_irrevocable_write_retire_w =
      1'b0 && commit0_valid_o && checkpoint_irrevocable_write_q &&
      (rob_commit0_producer_id_w == checkpoint_irrevocable_write_pid_q);
""",
                "suppress exact lane0 retirement of the holder",
            ),
        ),
    ),
    Mutation(
        "retire-compares-index-only",
        UNIT_IDS,
        "wrong-generation-retire-guard",
        (
            replacement(
                RETIRE,
                """\
  wire checkpoint_irrevocable_write_retire_w =
      commit0_valid_o && checkpoint_irrevocable_write_q &&
      (rob_commit0_producer_id_w[ROB_INDEX_W-1:0] ==
       checkpoint_irrevocable_write_pid_q[ROB_INDEX_W-1:0]);
""",
                "drop generation bits from the lane0 retirement comparison",
            ),
        ),
    ),
    Mutation(
        "restore-gate-omits-holder",
        UNIT_IDS,
        "amo-restore-gate",
        (
            replacement(
                RESTORE_GATE,
                """\
  assign checkpoint_restore_apply_w =
      (checkpoint_restore_new_req_w || checkpoint_restore_pending_q) &&
      sq_no_active_write_w && !drain_inflight_q;
""",
                "remove irreversible holder residency from restore gating",
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
        [
            "make",
            "-s",
            "print-v11p-checkpoint-irrevocable-write-context",
        ],
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
        raise RuntimeError("V11P Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "print-v11p-checkpoint-irrevocable-write-regression-context",
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
        raise RuntimeError("V11P regression context is incomplete")
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
                "test_run_v11p_checkpoint_irrevocable_write_semantic.py"
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
                "expected_pid_uses_holder_dut_state": False,
                "four_state_exact_comparison": True,
                "producer_generation_one_exercised": True,
                "producer_gen_width_one_and_four": True,
                "owner_token_28_high_bits_exercised": True,
                "store_physical_write_birth": True,
                "amo_physical_write_birth": True,
                "preterminal_hold": True,
                "postterminal_hold": True,
                "amo_tracker_death_before_retire": True,
                "checkpoint_live_mask_exact_onehot": True,
                "restore_blocked_until_exact_retire": True,
                "lane0_exact_retire": True,
                "wrong_generation_retire_rejected": True,
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
                    "triggered_by_v11p": False,
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
                    "# V11P checkpoint irreversible-write evidence",
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
        print(f"V11P runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
