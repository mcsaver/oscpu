#!/usr/bin/env python3
"""Run current-source FP ProducerId holder lifecycle semantics."""

from __future__ import annotations

import argparse
import hashlib
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common
import run_v11n_memory_pending_holder_semantic as matrix_engine
import run_v11s_muldiv_producer_semantic as context_loader


SCHEMA = "npc-rv64-v11v-fp-producer-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11V_FP_PRODUCER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11v_fp_producer"
MATRIX_PASS = "[V11V-FP-PRODUCER-MATRIX][PASS]"
ORACLE_FAIL = "[V11V-FP-PRODUCER-ORACLE][FAIL]"
UNIT_IDS = (
    "fp-arith-stage-producers",
    "fp-done-fifo-producers",
    "fp-exec1-packed-alias",
    "fp-exec1-packet",
    "fp-iq-producers",
    "fp-issue-packet",
    "fp-long-producer",
)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend.u_fp_backend"
)
REGRESSIONS = (
    "tb_ooo_fp_issue_queue",
    "tb_ooo_fp_arith_gate",
    "tb_ooo_int_backend",
    "tb_ooo_int_backend_v11i_terminal_lifecycle",
)
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11V-FP-IQ][PASS]": 3,
    "[V11V-FP-ISSUE][PASS]": 3,
    "[V11V-FP-ARITH][PASS]": 1,
    "[V11V-FP-EXEC1][PASS]": 1,
    "[V11V-FP-LONG][PASS]": 1,
    "[V11V-FP-DONE][PASS]": 3,
    "[V11V-FP-WRONG-GEN][PASS]": 3,
    "[V11V-FP-TERMINAL][PASS]": 3,
    "[V11V-FP-FLUSH][PASS]": 1,
}

Replacement = matrix_engine.Replacement
Mutation = matrix_engine.Mutation
Profile = matrix_engine.Profile


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


ISSUE_PACKET = """\
  wire [FP_ISSUE_PACKET_W-1:0] fp_issue_stage_up_payload_w =
      {iq_issue_producer_id_w, iq_issue_inst_w, iq_issue_double_w,
       iq_issue_pdest_w, iq_issue_dst_gpr_w, iq_issue_dst_en_w,
       iq_issue_fs1_preg_w, iq_issue_fs2_preg_w, iq_issue_fs3_preg_w,
       iq_issue_gpr_preg_w};
"""
ISSUE_LIVE_MASK = """\
  wire [(1 << PRODUCER_ID_W)-1:0] issue_stage_producer_live_mask_w =
      fp_issue_stage_valid_w ? fp_pid_onehot(issue_producer_id_w) :
      {(1 << PRODUCER_ID_W){1'b0}};
"""
ARITH_LIVE_MASK = """\
  always @(*) begin : fp_arith_live_mask_blk
    integer ak;
    arith_producer_live_mask_r = {(1 << PRODUCER_ID_W){1'b0}};
    for (ak = 0; ak < 5; ak = ak + 1) begin
      if (arith_owner_valid_w[ak])
        arith_producer_live_mask_r[
            arith_owner_producer_id_w[ak*PRODUCER_ID_W +: PRODUCER_ID_W]] =
            1'b1;
    end
  end
"""
EXEC1_PAYLOAD = """\
    .up_payload_i({issue_producer_id_w, issue_pdest_w, issue_dst_gpr_w,
                   issue_dst_en_w, comb_value_w, comb_fflags_w}),
"""
EXEC1_LIVE_MASK = """\
  wire [(1 << PRODUCER_ID_W)-1:0] exec1_producer_live_mask_w =
      exec1_valid_q ? fp_pid_onehot(exec1_producer_id_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
"""
LONG_LIVE_MASK = """\
  wire [(1 << PRODUCER_ID_W)-1:0] long_producer_live_mask_w =
      long_meta_valid_q ? fp_pid_onehot(long_producer_id_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
"""
FP_LIVE_UNION = """\
  assign producer_live_mask_o = fp_iq_producer_live_mask_w |
      issue_stage_producer_live_mask_w | arith_producer_live_mask_r |
      exec1_producer_live_mask_w | long_producer_live_mask_w |
      completion_pending_mask_r;
"""
DF_POP = """\
  wire df_pop_w = !df_empty_w && df_valid_q[df_head_q] &&
                  !control_full_flush_barrier_i &&
                  (df_head_killed_w || fpwb_ready_i);
"""


MUTATIONS = (
    Mutation(
        "iq-dispatch-pid-x",
        ("fp-iq-producers",),
        "arith-iq-birth",
        (
            replacement(
                "    .dispatch_producer_id_i(disp_producer_id_i),\n",
                "    .dispatch_producer_id_i({PRODUCER_ID_W{1'bx}}),\n",
                "drive an unknown full ProducerId into the accepted FP IQ entry",
            ),
        ),
    ),
    Mutation(
        "iq-dispatch-generation-truncated",
        ("fp-iq-producers",),
        "arith-iq-birth",
        (
            replacement(
                "    .dispatch_producer_id_i(disp_producer_id_i),\n",
                "    .dispatch_producer_id_i(\n"
                "        {{PRODUCER_GEN_W{1'b0}},\n"
                "         disp_producer_id_i[ROB_INDEX_W-1:0]}),\n",
                "drop generation at the lane0 FP IQ capture boundary",
            ),
        ),
    ),
    Mutation(
        "iq-live-union-omitted",
        ("fp-iq-producers",),
        "arith-iq-birth-live",
        (
            replacement(
                FP_LIVE_UNION,
                """\
  assign producer_live_mask_o =
      issue_stage_producer_live_mask_w | arith_producer_live_mask_r |
      exec1_producer_live_mask_w | long_producer_live_mask_w |
      completion_pending_mask_r;
""",
                "remove the resident FP IQ holder from the product live union",
            ),
        ),
    ),
    Mutation(
        "issue-packet-pid-x",
        ("fp-issue-packet",),
        "arith-issue-stage",
        (
            replacement(
                ISSUE_PACKET,
                """\
  wire [FP_ISSUE_PACKET_W-1:0] fp_issue_stage_up_payload_w =
      {{PRODUCER_ID_W{1'bx}}, iq_issue_inst_w, iq_issue_double_w,
       iq_issue_pdest_w, iq_issue_dst_gpr_w, iq_issue_dst_en_w,
       iq_issue_fs1_preg_w, iq_issue_fs2_preg_w, iq_issue_fs3_preg_w,
       iq_issue_gpr_preg_w};
""",
                "replace the accepted issue-packet ProducerId with X",
            ),
        ),
    ),
    Mutation(
        "issue-live-mask-omitted",
        ("fp-issue-packet",),
        "arith-issue-stage-live",
        (
            replacement(
                ISSUE_LIVE_MASK,
                """\
  wire [(1 << PRODUCER_ID_W)-1:0] issue_stage_producer_live_mask_w =
      {(1 << PRODUCER_ID_W){1'b0}};
""",
                "remove issue-packet residency from the FP live mask",
            ),
        ),
    ),
    Mutation(
        "arith-launch-pid-x",
        ("fp-arith-stage-producers",),
        "arith-stage1",
        (
            replacement(
                "    .launch_producer_id_i(issue_producer_id_w),\n",
                "    .launch_producer_id_i({PRODUCER_ID_W{1'bx}}),\n",
                "drive X into arithmetic metadata stage one",
            ),
        ),
    ),
    Mutation(
        "arith-live-mask-omitted",
        ("fp-arith-stage-producers",),
        "arith-stage1-live",
        (
            replacement(
                ARITH_LIVE_MASK,
                """\
  always @(*) begin : fp_arith_live_mask_blk
    integer ak;
    arith_producer_live_mask_r = {(1 << PRODUCER_ID_W){1'b0}};
    for (ak = 0; ak < 5; ak = ak + 1) begin
      if (arith_owner_valid_w[ak])
        arith_producer_live_mask_r[
            arith_owner_producer_id_w[ak*PRODUCER_ID_W +: PRODUCER_ID_W]] =
            1'b0;
    end
  end
""",
                "remove all five arithmetic metadata stages from residency",
            ),
        ),
    ),
    Mutation(
        "exec1-packet-pid-x",
        ("fp-exec1-packed-alias", "fp-exec1-packet"),
        "exec1-stage",
        (
            replacement(
                EXEC1_PAYLOAD,
                """\
    .up_payload_i({{PRODUCER_ID_W{1'bx}}, issue_pdest_w,
                   issue_dst_gpr_w, issue_dst_en_w,
                   comb_value_w, comb_fflags_w}),
""",
                "replace the exec1 packed ProducerId field with X",
            ),
        ),
    ),
    Mutation(
        "exec1-live-mask-omitted",
        ("fp-exec1-packed-alias", "fp-exec1-packet"),
        "exec1-stage-live",
        (
            replacement(
                EXEC1_LIVE_MASK,
                """\
  wire [(1 << PRODUCER_ID_W)-1:0] exec1_producer_live_mask_w =
      {(1 << PRODUCER_ID_W){1'b0}};
""",
                "remove the valid exec1 packet from FP residency",
            ),
        ),
    ),
    Mutation(
        "long-capture-pid-x",
        ("fp-long-producer",),
        "long-birth",
        (
            replacement(
                "        long_producer_id_q <= issue_producer_id_w;\n",
                "        long_producer_id_q <= {PRODUCER_ID_W{1'bx}};\n",
                "replace the accepted iterative FP ProducerId with X",
            ),
        ),
    ),
    Mutation(
        "long-live-mask-omitted",
        ("fp-long-producer",),
        "long-birth-live",
        (
            replacement(
                LONG_LIVE_MASK,
                """\
  wire [(1 << PRODUCER_ID_W)-1:0] long_producer_live_mask_w =
      {(1 << PRODUCER_ID_W){1'b0}};
""",
                "remove iterative FP metadata from the live mask",
            ),
        ),
    ),
    Mutation(
        "done-fifo-pid-x",
        ("fp-done-fifo-producers",),
        "arith-done-fifo",
        (
            replacement(
                "        df_producer_id_q[df_tail_q] <= "
                "done_in_producer_id_w;\n",
                "        df_producer_id_q[df_tail_q] <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "replace the accepted completion token identity with X",
            ),
        ),
    ),
    Mutation(
        "done-pending-mask-omitted",
        ("fp-done-fifo-producers",),
        "arith-done-fifo-live",
        (
            replacement(
                "        completion_pending_mask_r["
                "df_producer_id_q[pk]] = 1'b1;\n",
                "        completion_pending_mask_r["
                "df_producer_id_q[pk]] = 1'b0;\n",
                "hide an occupied completion token from pending residency",
            ),
        ),
    ),
    Mutation(
        "done-terminal-release-blocked",
        ("fp-done-fifo-producers",),
        "arith-terminal-release",
        (
            replacement(
                DF_POP,
                """\
  wire df_pop_w = 1'b0 && !df_empty_w && df_valid_q[df_head_q] &&
                  !control_full_flush_barrier_i &&
                  (df_head_killed_w || fpwb_ready_i);
""",
                "withhold the accepted formal terminal edge from the FIFO",
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
    runner_common.REGRESSIONS = REGRESSIONS


_configure_matrix_engine()
apply_mutation = matrix_engine.apply_mutation
build_profiles = matrix_engine.build_profiles
marker_counts = matrix_engine.marker_counts
oracle_failure_stages = matrix_engine.oracle_failure_stages
evaluate_profile = matrix_engine.evaluate_profile
build_variants = matrix_engine.build_variants
run_profile = matrix_engine.run_profile

MAKE_CONTEXT_RULE = context_loader.MAKE_CONTEXT_RULE
MAKE_REGRESSION_CONTEXT_TARGET = "__v11v_fp_producer_regression_context"
MAKE_REGRESSION_CONTEXT_RULE = (
    f"{MAKE_REGRESSION_CONTEXT_TARGET}:\n"
    "\t@printf '%s\\n' "
    "$(addprefix REGRESSION_SOURCE_tb_ooo_fp_issue_queue=,"
    "$(abspath $(sort $(TB_SRCS_tb_ooo_fp_issue_queue))))\n"
    "\t@printf '%s\\n' "
    "$(addprefix REGRESSION_SOURCE_tb_ooo_fp_arith_gate=,"
    "$(abspath $(sort $(TB_SRCS_tb_ooo_fp_arith_gate))))\n"
    "\t@printf '%s\\n' "
    "$(addprefix REGRESSION_SOURCE_tb_ooo_int_backend=,"
    "$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))\n"
    "\t@printf '%s\\n' "
    "$(addprefix "
    "REGRESSION_SOURCE_tb_ooo_int_backend_v11i_terminal_lifecycle=,"
    "$(abspath $(sort "
    "$(TB_SRCS_tb_ooo_int_backend_v11i_terminal_lifecycle))))\n"
    "\t@printf '%s\\n' "
    "$(addprefix REGRESSION_COMMON=,$(abspath "
    "common/tb_common.svh common/rv32_encode.svh "
    "$(TB_RESULT_CHECKER) Makefile $(RTL_INCLUDE_DIR)/define.v))\n"
)
BASE_TESTBENCH = Path("npc/rv64/testbench/tests/tb_ooo_int_backend.sv")
FOCUSED_FRAGMENT = Path(
    "npc/rv64/testbench/tests/tb_ooo_int_backend_v11v_fp_producer.svh"
)
TASK_INSERT_ANCHOR = "`ifdef V11Q_INT_LANE0_PACKET_FOCUSED\n"
INITIAL_INSERT_ANCHOR = (
    "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
    "    run_hist_ser_qh_younger_store_cycle();\n"
    "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
)
FINISH_INSERT_ANCHOR = (
    "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
    '        tb_finish("tb_ooo_int_backend_hist_ser_qh_younger_store");\n'
    "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
)


def _text_sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def render_focused_testbench(
    base_source: str,
    focused_fragment: str,
) -> tuple[str, list[dict[str, object]]]:
    replacements = (
        (
            "task-fragment",
            TASK_INSERT_ANCHOR,
            focused_fragment.rstrip() + "\n" + TASK_INSERT_ANCHOR,
        ),
        (
            "initial-dispatch",
            INITIAL_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "    run_hist_ser_qh_younger_store_cycle();\n"
                "`elsif V11V_FP_PRODUCER_FOCUSED\n"
                "    run_v11v_fp_producer_semantic();\n"
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
        (
            "finish-dispatch",
            FINISH_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_hist_ser_qh_younger_store");\n'
                "`elsif V11V_FP_PRODUCER_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_v11v_fp_producer");\n'
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
    )
    rendered = base_source
    receipts: list[dict[str, object]] = []
    for label, anchor, replacement_text in replacements:
        count = rendered.count(anchor)
        if count != 1:
            raise RuntimeError(
                f"focused testbench anchor is not unique: {label} "
                f"count={count}"
            )
        rendered = rendered.replace(anchor, replacement_text, 1)
        receipts.append(
            {
                "label": label,
                "anchor_count": count,
                "anchor_sha256": _text_sha256(anchor),
                "replacement_sha256": _text_sha256(replacement_text),
            }
        )
    return rendered, receipts


def build_focused_testbench(
    *, repo_root: Path, result_dir: Path
) -> tuple[Path, list[dict[str, object]]]:
    base_path = (repo_root / BASE_TESTBENCH).resolve()
    fragment_path = (repo_root / FOCUSED_FRAGMENT).resolve()
    rendered, receipts = render_focused_testbench(
        base_path.read_text(encoding="utf-8"),
        fragment_path.read_text(encoding="utf-8"),
    )
    output = result_dir / "generated/tb_ooo_int_backend_v11v_fp_producer.sv"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    return output, receipts


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "--no-print-directory",
            "--eval",
            MAKE_REGRESSION_CONTEXT_RULE,
            MAKE_REGRESSION_CONTEXT_TARGET,
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
        raise RuntimeError("V11V regression context is incomplete")
    return result


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parents[4]
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    return parser.parse_args(argv)


def _cleanup_pass_artifacts(
    *,
    repo_root: Path,
    result_dir: Path,
    profile_records: list[dict[str, object]],
    regression_records: list[dict[str, object]],
    variants: dict[str, Path],
    generated_testbench: Path,
) -> dict[str, object]:
    removed: list[dict[str, object]] = []

    def remove_recorded(path: Path, kind: str) -> None:
        if not path.is_file():
            return
        record = runner_common.artifact_record(path, repo_root)
        record["kind"] = kind
        path.unlink()
        record["removed_after_validation"] = True
        removed.append(record)

    for profile in profile_records:
        remove_recorded(
            result_dir / "profiles" / str(profile["profile"]) / f"{TOP}.vvp",
            "focused-compile-image",
        )
    for regression in regression_records:
        remove_recorded(
            result_dir
            / "regressions"
            / "build"
            / f"{regression['test']}.vvp",
            "regression-compile-image",
        )
    for variant in variants.values():
        remove_recorded(variant, "generated-negative-rtl")
    remove_recorded(generated_testbench, "generated-focused-testbench")
    cleanup = {
        "status": "PASS",
        "policy": "retain-results-logs-and-hashes-only",
        "removed_count": len(removed),
        "removed": removed,
    }
    runner_common.write_json(result_dir / "artifact-cleanup.json", cleanup)
    return cleanup


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc/rv64/testbench"
    rtl_path = (repo_root / "npc/rv64/vsrc/execute/OooFpBackend.v").resolve()
    iq_rtl_path = (
        repo_root / "npc/rv64/vsrc/scheduling/OooFpIssueQueue.v"
    ).resolve()
    arith_rtl_path = (
        repo_root / "npc/rv64/vsrc/execute/OooFpArithGate.v"
    ).resolve()
    status_path = result_dir / "runner.status"
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"result directory is not empty: {result_dir}")
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)
    runner_common.atomic_status(status_path, "RUNNING")
    try:
        _configure_matrix_engine()
        iverilog, vvp = runner_common.resolve_tools()
        include_dir, production_sources = context_loader.load_make_context(
            testbench_dir
        )
        regressions = load_regression_context(testbench_dir)
        base_testbench_path = (repo_root / BASE_TESTBENCH).resolve()
        focused_fragment_path = (repo_root / FOCUSED_FRAGMENT).resolve()
        for required in (
            rtl_path,
            iq_rtl_path,
            arith_rtl_path,
            base_testbench_path,
        ):
            if required not in production_sources:
                raise RuntimeError(f"production source is absent: {required}")
        generated_testbench, overlay_receipts = build_focused_testbench(
            repo_root=repo_root, result_dir=result_dir
        )
        focused_sources = tuple(
            generated_testbench if path == base_testbench_path else path
            for path in production_sources
        )
        runner_inputs = [
            *production_sources,
            focused_fragment_path,
            include_dir / "define.v",
            testbench_dir / "Makefile",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11v_fp_producer_semantic.py"
            ).resolve(),
            Path(matrix_engine.__file__).resolve(),
            Path(runner_common.__file__).resolve(),
            Path(context_loader.__file__).resolve(),
            *(path for test in REGRESSIONS for path in regressions[test]),
        ]
        before = runner_common.source_manifest(runner_inputs, repo_root)
        runner_common.write_sha256_manifest(
            result_dir / "source-before.sha256", before
        )
        variants, variant_records = build_variants(
            result_dir=result_dir, rtl_path=rtl_path, repo_root=repo_root
        )
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=focused_sources,
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
        generated_record = runner_common.artifact_record(
            generated_testbench, repo_root
        )
        summary: dict[str, Any] = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "architecture-verification",
            "design_id": runner_common.current_design_id(repo_root),
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "producer_gen_widths": list(GEN_WIDTHS),
                "profile_count": len(profile_records),
                "baseline_profile_count": len(GEN_WIDTHS) * 2,
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
                "fp_backend_rtl": runner_common.repo_path(
                    rtl_path, repo_root
                ),
                "fp_backend_rtl_sha256": runner_common.sha256_file(rtl_path),
                "fp_iq_rtl": runner_common.repo_path(iq_rtl_path, repo_root),
                "fp_iq_rtl_sha256": runner_common.sha256_file(iq_rtl_path),
                "fp_arith_rtl": runner_common.repo_path(
                    arith_rtl_path, repo_root
                ),
                "fp_arith_rtl_sha256": runner_common.sha256_file(
                    arith_rtl_path
                ),
                "focused_testbench": FOCUSED_FRAGMENT.as_posix(),
                "focused_testbench_sha256": runner_common.sha256_file(
                    focused_fragment_path
                ),
                "base_testbench": BASE_TESTBENCH.as_posix(),
                "base_testbench_sha256": runner_common.sha256_file(
                    base_testbench_path
                ),
                "generated_testbench": generated_record,
                "overlay_injection_receipts": overlay_receipts,
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
                "expected_pid_uses_fp_holder_state": False,
                "four_state_exact_comparison": True,
                "nonzero_generation_one_exercised": True,
                "producer_gen_width_one_and_four": True,
                "iq_birth_and_residency_checked": True,
                "issue_packet_capture_and_residency_checked": True,
                "arith_five_stage_residency_checked": True,
                "exec1_packet_and_packed_alias_checked": True,
                "long_iterative_residency_checked": True,
                "done_fifo_pending_residency_checked": True,
                "wrong_generation_authorization_rejected": True,
                "ordered_retirement_exactly_once_checked": True,
                "full_flush_death_checked": True,
                "release_mode_mutation_rejection": True,
                "raw_producer_identity_knownness_mutations": 6,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": profiles_pass,
                "profiles_fail": len(profile_records) - profiles_pass,
                "baseline_profiles_total": len(GEN_WIDTHS) * 2,
                "mutations_total": len(MUTATIONS),
                "mutation_profiles_total": len(MUTATIONS) * len(GEN_WIDTHS),
                "regressions_total": len(regression_records),
                "regressions_pass": regressions_pass,
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "mechanism": "fp-producer-holder-lifecycle",
                "semantic_units": list(UNIT_IDS),
                "production_rtl_change": False,
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "a3_original_status": "FAIL_RETAINED",
                "a3_execution_state": "COMPLETE",
                "a3_terminal_state": "COMPLETE",
                "a3_oracle_state": "OLD_ORACLE_INVALID",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11v": False,
                    "run": False,
                    "required_for_current_scope": False,
                },
            },
            "promotion": {
                "semantic_units": (
                    "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS"
                ),
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        runner_common.write_json(result_dir / "summary.json", summary)
        (result_dir / "summary.md").write_text(
            "\n".join(
                [
                    "# V11V FP producer-holder lifecycle evidence",
                    "",
                    f"- status: {summary['status']}",
                    f"- profiles: {profiles_pass}/{len(profile_records)} PASS",
                    (
                        "- compile-success mutations: "
                        f"{len(MUTATIONS)} cases x {len(GEN_WIDTHS)} widths"
                    ),
                    (
                        "- regressions: "
                        f"{regressions_pass}/{len(regression_records)} PASS"
                    ),
                    f"- source pre/post: {'MATCH' if binding_match else 'DRIFT'}",
                    "- production RTL change: none",
                    "- compile images and generated secondary sources: removed after validation",
                    "- A3 original FAIL retained; checker replay remains separate",
                    "- whole architecture: RED",
                    "- PPA: UNPROMOTED",
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        if overall:
            cleanup = _cleanup_pass_artifacts(
                repo_root=repo_root,
                result_dir=result_dir,
                profile_records=profile_records,
                regression_records=regression_records,
                variants=variants,
                generated_testbench=generated_testbench,
            )
            summary["artifact_cleanup"] = cleanup
            runner_common.write_json(result_dir / "summary.json", summary)
        runner_common.atomic_status(status_path, "PASS" if overall else "FAIL")
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
        print(f"V11V runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
