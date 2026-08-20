#!/usr/bin/env python3
"""Compile and reject OooFpArithGate production-child contract mutations.

The runner never overwrites production RTL.  It first audits the unique numeric
state owners and zero-register child boundaries, then builds every exact-source
variant with Icarus and requires one directed dynamic or structural rejection.
The before/after dependency hashes cover the complete focused/mutation input
set, including helper includes, testbench, checker, Makefile and filelist.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Sequence


@dataclass(frozen=True)
class Replacement:
    old: str
    new: str


@dataclass(frozen=True)
class Mutation:
    mutation_id: str
    target: str
    rtl_effect: str
    replacements: tuple[Replacement, ...]
    expected_marker: str | None
    expected_structure_error: str | None = None
    require_duplicate_owner_audit: bool = False


MUTATIONS = (
    Mutation(
        "missing-stage5-cycle",
        "wrapper",
        "out_valid 错误读取 resident S4，launch→out 少一拍",
        (
            Replacement(
                "  assign out_valid_o = meta_valid_q[5] &&\n",
                "  assign out_valid_o = meta_valid_q[4] &&\n",
            ),
        ),
        "[FP-ARITH-LATENCY-5-STAGE]",
    ),
    Mutation(
        "extra-output-cycle",
        "wrapper",
        "out_valid 错误增加一个寄存级，launch→out 多一拍",
        (
            Replacement(
                """\
  assign out_valid_o = meta_valid_q[5] &&
      !(kill_valid_i && fp_meta_younger(
          meta_producer_id_q[5][ROB_INDEX_W-1:0],
          kill_rob_idx_i, rob_head_idx_i));
""",
                """\
  reg extra_out_valid_q;
  always @(posedge clk) begin
    if (rst || flush_i) extra_out_valid_q <= 1'b0;
    else extra_out_valid_q <= meta_valid_q[5] &&
        !(kill_valid_i && fp_meta_younger(
            meta_producer_id_q[5][ROB_INDEX_W-1:0],
            kill_rob_idx_i, rob_head_idx_i));
  end
  assign out_valid_o = extra_out_valid_q;
""",
            ),
        ),
        "[FP-ARITH-LATENCY-5-STAGE]",
    ),
    Mutation(
        "current-double-selection",
        "wrapper",
        "AddSub S4 对齐错误读取 current double_i，而非 resident S3 meta",
        (
            Replacement(
                "      addsub_s4_result_q <= meta_double_q[3] ?\n",
                "      addsub_s4_result_q <= double_i ?\n",
            ),
        ),
        "[CHECK-FAIL] atomic flags add NX val",
    ),
    Mutation(
        "current-kind-selection",
        "wrapper",
        "S5 value/fflags mux 错误读取 current launch_kind_i",
        (
            Replacement(
                """\
  assign selected_s5_result_w =
      (meta_kind_q[5] == 2'd2) ? fma_s5_result_w :
      (meta_kind_q[5] == 2'd1) ? mul_s5_result_q :
                                 addsub_s5_result_q;
""",
                """\
  assign selected_s5_result_w =
      (launch_kind_i == 2'd2) ? fma_s5_result_w :
      (launch_kind_i == 2'd1) ? mul_s5_result_q :
                                addsub_s5_result_q;
""",
            ),
        ),
        "[CHECK-FAIL] atomic flags mul invalid val",
    ),
    Mutation(
        "value-fflags-split",
        "wrapper",
        "out_fflags 脱离选中 value 的 69-bit 原子 bundle",
        (
            Replacement(
                "  assign out_fflags_o = selected_s5_result_w[68:64];\n",
                "  assign out_fflags_o = addsub_s5_result_q[68:64];\n",
            ),
        ),
        "[CHECK-FAIL] atomic flags mul invalid ff",
    ),
    Mutation(
        "addsub-s4-s5-misalignment",
        "wrapper",
        "AddSub final mux 错误旁路 S4，value/identity 错一拍",
        (
            Replacement(
                "                                 addsub_s5_result_q;\n",
                "                                 addsub_s4_result_q;\n",
            ),
        ),
        "[CHECK-FAIL] launch mixed fadd.s out val",
    ),
    Mutation(
        "mul-s4-s5-misalignment",
        "wrapper",
        "Mul final mux 错误旁路 S4，resident kind/value 错一拍",
        (
            Replacement(
                "      (meta_kind_q[5] == 2'd1) ? mul_s5_result_q :\n",
                "      (meta_kind_q[5] == 2'd1) ? mul_s4_result_q :\n",
            ),
        ),
        "[CHECK-FAIL] launch mixed fmul.d out val",
    ),
    Mutation(
        "same-cycle-launch-kill-dropped",
        "wrapper",
        "S1 meta 接纳错误忽略 same-cycle ROB-age kill",
        (
            Replacement(
                """\
      meta_valid_q[1] <= launch_valid_i &&
          !(kill_valid_i && fp_meta_younger(
              launch_producer_id_i[ROB_INDEX_W-1:0],
              kill_rob_idx_i, rob_head_idx_i));
""",
                """\
      meta_valid_q[1] <= launch_valid_i;
""",
            ),
        ),
        "[FP-ARITH-SAME-CYCLE-LAUNCH-KILL] killed launch owns S1",
    ),
    Mutation(
        "resident-stage-kill-dropped",
        "wrapper",
        "S2-S5 meta 推进错误忽略 resident ROB-age kill",
        (
            Replacement(
                """\
        meta_valid_q[mi] <= meta_valid_q[mi-1] &&
            !(kill_valid_i && fp_meta_younger(
                meta_producer_id_q[mi-1][ROB_INDEX_W-1:0],
                kill_rob_idx_i, rob_head_idx_i));
""",
                """\
        meta_valid_q[mi] <= meta_valid_q[mi-1];
""",
            ),
        ),
        "[FP-ARITH-KILL-STAGE-1] delayed completion leaked",
    ),
    Mutation(
        "s5-combinational-kill-dropped",
        "wrapper",
        "S5 output window 错误忽略无时钟 ROB-age kill",
        (
            Replacement(
                """\
  assign out_valid_o = meta_valid_q[5] &&
      !(kill_valid_i && fp_meta_younger(
          meta_producer_id_q[5][ROB_INDEX_W-1:0],
          kill_rob_idx_i, rob_head_idx_i));
""",
                """\
  assign out_valid_o = meta_valid_q[5];
""",
            ),
        ),
        "[FP-ARITH-KILL-STAGE-5] S5 combinational kill leaked",
    ),
    Mutation(
        "round-sticky-dropped",
        "addsub",
        "AddSub double S3 错误丢弃 sticky，破坏 round helper/fflags",
        (
            Replacement(
                """\
      mant53 = sig_norm[55:3];
      guard = sig_norm[2];
      sticky = sig_norm[1] | sig_norm[0];
""",
                """\
      mant53 = sig_norm[55:3];
      guard = sig_norm[2];
      sticky = 1'b0;
""",
            ),
        ),
        "[CHECK-FAIL] round sticky add NX ff",
    ),
    Mutation(
        "fma-special-invalid-dropped",
        "fma_align",
        "FMA double special path 错误丢弃 invalid fflags",
        (
            Replacement(
                "      fma_d_s1_spff_c = nv ? `FP_FLAG_NV : 5'b00000;\n",
                "      fma_d_s1_spff_c = 5'b00000;\n",
            ),
        ),
        "[CHECK-FAIL] special fma inf zero ff",
    ),
    Mutation(
        "fma-jam-dropped",
        "fma_align",
        "FMA double product alignment 错误用 plain shift 丢弃 mag[0] jam",
        (
            Replacement(
                """\
      prod_field = fp_shift_right_jam_128(
          {22'b0, fma_d_s2_product_q}, negsh[7:0]);
""",
                """\
      prod_field = {22'b0, fma_d_s2_product_q} >> negsh[7:0];
""",
            ),
        ),
        "[CHECK-FAIL] fma alignment jam NX ff",
    ),
    Mutation(
        "fma-intermediate-product-truncated",
        "fma_align",
        "FMA double product 在 align/add 前错误截断低 53 bit，破坏 fused single-round",
        (
            Replacement(
                "    fma_d_s1_product_c = sig_a * sig_b;\n",
                """\
    fma_d_s1_product_c = sig_a * sig_b;
    fma_d_s1_product_c[52:0] = 53'b0;
""",
            ),
        ),
        "[CHECK-FAIL] fused single-round cancellation val",
    ),
    Mutation(
        "duplicate-wrapper-numeric-owner",
        "wrapper",
        "wrapper 错误恢复第二份 AddSub S5 numeric state owner 并驱动 final mux",
        (
            Replacement(
                "  reg [68:0] addsub_s4_result_q, addsub_s5_result_q;\n",
                """\
  reg [68:0] addsub_s4_result_q, addsub_s5_result_q;
  reg [68:0] duplicate_addsub_s5_result_q;
""",
            ),
            Replacement(
                "      addsub_s5_result_q <= 69'b0;\n",
                """\
      addsub_s5_result_q <= 69'b0;
      duplicate_addsub_s5_result_q <= 69'b0;
""",
            ),
            Replacement(
                "      addsub_s5_result_q <= addsub_s4_result_q;\n",
                """\
      addsub_s5_result_q <= addsub_s4_result_q;
      duplicate_addsub_s5_result_q <= addsub_s5_result_q;
""",
            ),
            Replacement(
                "                                 addsub_s5_result_q;\n",
                "                                 duplicate_addsub_s5_result_q;\n",
            ),
        ),
        "[CHECK-FAIL] launch mixed fadd.s out val",
        require_duplicate_owner_audit=True,
    ),
    Mutation(
        "wrapper-helper-owner",
        "wrapper",
        "wrapper 错误恢复 predicate helper lexical ownership",
        (
            Replacement(
                ");\n\n  localparam integer FP_ARITH_LATENCY = 5;\n",
                ");\n\n  `include \"execute/OooFpPredicates.v\"\n\n"
                "  localparam integer FP_ARITH_LATENCY = 5;\n",
            ),
        ),
        None,
        expected_structure_error=(
            "wrapper regained numeric/helper ownership: "
            "`include \"execute/OooFpPredicates.v\""
        ),
    ),
    Mutation(
        "producer-id-corruption",
        "wrapper",
        "S5 completion 错误翻转 full ProducerId generation bits，raw ROB index 不变",
        (
            Replacement(
                "  assign out_producer_id_o = meta_producer_id_q[5];\n",
                "  assign out_producer_id_o = "
                "{~meta_producer_id_q[5][PRODUCER_ID_W-1:ROB_INDEX_W], "
                "meta_producer_id_q[5][ROB_INDEX_W-1:0]};\n",
            ),
        ),
        "[CHECK-FAIL] five-stage S5 identity/value/fflags PID",
    ),
)


SOURCE_RELATIVE_PATHS = {
    "wrapper": "npc/rv64/vsrc/execute/OooFpArithGate.v",
    "addsub": "npc/rv64/vsrc/execute/OooFpAddSubPipe.v",
    "mul_product": "npc/rv64/vsrc/execute/OooFpMulProductPipe.v",
    "mul_norm": "npc/rv64/vsrc/execute/OooFpMulNormRoundPipe.v",
    "fma_align": "npc/rv64/vsrc/execute/OooFpFmaAlignAddPipe.v",
    "fma_norm": "npc/rv64/vsrc/execute/OooFpFmaNormRoundPipe.v",
}

MAKE_OVERRIDES = {
    "wrapper": "RTL_OOO_FP_ARITH_GATE",
    "addsub": "RTL_OOO_FP_ADD_SUB_PIPE",
    "mul_product": "RTL_OOO_FP_MUL_PRODUCT_PIPE",
    "mul_norm": "RTL_OOO_FP_MUL_NORM_ROUND_PIPE",
    "fma_align": "RTL_OOO_FP_FMA_ALIGN_ADD_PIPE",
    "fma_norm": "RTL_OOO_FP_FMA_NORM_ROUND_PIPE",
}


# Complete deterministic input closure for the focused TB and all mutations.
# The four lexical/include dependencies are define.v, tb_common.svh,
# OooFpPredicates.v and OooFpRound.v.
DEPENDENCY_RELATIVE_PATHS = (
    "npc/rv64/vsrc/execute/OooFpArithGate.v",
    "npc/rv64/vsrc/execute/OooFpAddSubPipe.v",
    "npc/rv64/vsrc/execute/OooFpMulProductPipe.v",
    "npc/rv64/vsrc/execute/OooFpMulNormRoundPipe.v",
    "npc/rv64/vsrc/execute/OooFpFmaAlignAddPipe.v",
    "npc/rv64/vsrc/execute/OooFpFmaNormRoundPipe.v",
    "npc/rv64/vsrc/include/define.v",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/vsrc/execute/OooFpPredicates.v",
    "npc/rv64/vsrc/execute/OooFpRound.v",
    "npc/rv64/testbench/tests/tb_ooo_fp_arith_gate.sv",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/vsrc/filelist.mk",
    "npc/rv64/testbench/scripts/run_ooo_fp_arith_child_mutations.py",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def apply_mutation(source: str, mutation: Mutation) -> tuple[str, list[dict[str, object]]]:
    mutated = source
    receipts: list[dict[str, object]] = []
    for replacement in mutation.replacements:
        count = mutated.count(replacement.old)
        if count != 1:
            raise ValueError(
                f"{mutation.mutation_id}: expected one anchor, observed {count}"
            )
        mutated = mutated.replace(replacement.old, replacement.new, 1)
        receipts.append(
            {
                "anchor_count": count,
                "old_sha256": sha256_bytes(replacement.old.encode("utf-8")),
                "new_sha256": sha256_bytes(replacement.new.encode("utf-8")),
            }
        )
    return mutated, receipts


def audit_product_structure(sources: dict[str, str]) -> dict[str, object]:
    errors: list[str] = []
    wrapper = sources["wrapper"]
    module_names = {
        "wrapper": "OooFpArithGate",
        "addsub": "OooFpAddSubPipe",
        "mul_product": "OooFpMulProductPipe",
        "mul_norm": "OooFpMulNormRoundPipe",
        "fma_align": "OooFpFmaAlignAddPipe",
        "fma_norm": "OooFpFmaNormRoundPipe",
    }
    for key, module_name in module_names.items():
        if sources[key].count(f"module {module_name}") != 1:
            errors.append(f"{key}: module boundary {module_name} is not unique")

    for forbidden in (
        '`include "execute/OooFpPredicates.v"',
        '`include "execute/OooFpRound.v"',
        "as_d_s1_",
        "as_s_s1_",
        "mul_d_s1_",
        "mul_s_s1_",
        "fma_d_s1_",
        "fma_s_s1_",
        "fma_d_s3_mag_q",
        "fma_s_s3_mag_q",
    ):
        if forbidden in wrapper:
            errors.append(f"wrapper regained numeric/helper ownership: {forbidden}")

    required_wrapper = (
        "OooFpAddSubPipe u_addsub_pipe",
        "OooFpMulProductPipe u_mul_product_pipe",
        "OooFpMulNormRoundPipe u_mul_norm_round_pipe",
        "OooFpFmaAlignAddPipe u_fma_align_add_pipe",
        "OooFpFmaNormRoundPipe u_fma_norm_round_pipe",
        "reg meta_valid_q [1:5];",
        "reg meta_double_q [1:5];",
        "reg [1:0] meta_kind_q [1:5];",
        "reg [68:0] addsub_s4_result_q, addsub_s5_result_q;",
        "reg [68:0] mul_s4_result_q, mul_s5_result_q;",
        "addsub_s4_result_q <= meta_double_q[3] ?",
        "mul_s4_result_q <= meta_double_q[3] ?",
        "(meta_kind_q[5] == 2'd2)",
        "meta_double_q[5] ?",
    )
    for anchor in required_wrapper:
        if wrapper.count(anchor) != 1:
            errors.append(f"wrapper lacks unique owner/alignment anchor: {anchor}")

    expected_helpers = {
        "addsub": ("OooFpPredicates.v", "OooFpRound.v"),
        "mul_product": ("OooFpPredicates.v",),
        "mul_norm": ("OooFpRound.v",),
        "fma_align": ("OooFpPredicates.v", "OooFpRound.v"),
        "fma_norm": ("OooFpRound.v",),
    }
    child_keys = tuple(expected_helpers)
    for key in child_keys:
        child = sources[key]
        for helper in ("OooFpPredicates.v", "OooFpRound.v"):
            expected = 1 if helper in expected_helpers[key] else 0
            observed = child.count(helper)
            if observed != expected:
                errors.append(
                    f"{key}: helper lexical count {helper}={observed}, expected {expected}"
                )
        for forbidden in (
            "launch_valid_i",
            "kill_valid_i",
            "rob_head_idx_i",
            "meta_valid_q",
            "owner_valid_o",
            "commit_valid",
            "commit_i",
            "commit_o",
        ):
            if forbidden in child:
                errors.append(f"{key}: child regained transaction owner {forbidden}")

    stage_anchors = {
        "addsub": ("as_d_s1_", "as_d_s2_", "as_d_s3_", "as_s_s1_", "as_s_s2_", "as_s_s3_"),
        "mul_product": ("mul_d_special_q_o", "mul_d_product_q_o", "mul_s_product_q_o"),
        "mul_norm": ("mul_d_s2_", "mul_d_s3_", "mul_s_s2_", "mul_s_s3_"),
        "fma_align": ("fma_d_s1_", "fma_d_s2_", "fma_d_s3_", "fma_s_s1_", "fma_s_s2_", "fma_s_s3_"),
        "fma_norm": ("fma_d_s4_", "fma_d_s5_", "fma_s_s4_", "fma_s_s5_"),
    }
    for key, anchors in stage_anchors.items():
        for anchor in anchors:
            if anchor not in sources[key]:
                errors.append(f"{key}: missing frozen stage owner anchor {anchor}")

    if "mul_d_s2_" in sources["mul_product"]:
        errors.append("MulProduct regained S2 state")
    if "fma_d_s4_" in sources["fma_align"]:
        errors.append("FmaAlignAdd regained S4 state")
    for anchor in (
        "input  [105:0]         mul_d_product_q_i",
        "product_norm = mul_d_product_q_i",
        ".mul_d_product_q_i(mul_d_product_w)",
    ):
        haystack = (
            sources["mul_norm"]
            if anchor.startswith("input") or "product_norm" in anchor
            else wrapper
        )
        if anchor not in haystack:
            errors.append(f"Mul S1 Q->S2 comb boundary anchor missing: {anchor}")
    for anchor in (
        "output reg [127:0]      fma_d_mag_q_o",
        "output reg [127:0]      fma_s_mag_q_o",
        "input  [127:0]          fma_d_mag_q_i",
        "input  [127:0]          fma_s_mag_q_i",
        "mag = fma_d_mag_q_i;",
        ".fma_d_mag_q_i(fma_d_mag_w)",
    ):
        if "output" in anchor:
            haystack = sources["fma_align"]
        elif anchor.startswith("input") or anchor.startswith("mag ="):
            haystack = sources["fma_norm"]
        else:
            haystack = wrapper
        if anchor not in haystack:
            errors.append(f"FMA S3 Q->S4 comb/full-mag anchor missing: {anchor}")
    jam_call_count = sources["fma_align"].count("fp_shift_right_jam_128(")
    if jam_call_count != 4:
        errors.append(f"FmaAlignAdd jam call count={jam_call_count}, expected 4")
    if "sticky = |magn[73:0];" not in sources["fma_norm"]:
        errors.append("FmaNormRound no longer reduces full double mag tail into sticky")
    if "duplicate_addsub_s5_result_q" in wrapper:
        errors.append("wrapper duplicate numeric owner marker")

    return {"status": "FAIL" if errors else "PASS", "errors": errors}


def run_one(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    sources: dict[str, Path],
    source_text: dict[str, str],
    mutation: Mutation,
) -> dict[str, object]:
    variant_dir = result_dir / mutation.mutation_id
    rtl_dir = variant_dir / "rtl"
    build_dir = variant_dir / "build"
    run_dir = variant_dir / "run"
    rtl_dir.mkdir(parents=True, exist_ok=True)
    run_dir.mkdir(parents=True, exist_ok=True)

    mutated_text, receipts = apply_mutation(source_text[mutation.target], mutation)
    mutant_path = rtl_dir / sources[mutation.target].name
    mutant_path.write_text(mutated_text, encoding="utf-8")
    mutated_sources = dict(source_text)
    mutated_sources[mutation.target] = mutated_text
    mutated_audit = audit_product_structure(mutated_sources)

    log_path = run_dir / "logs" / "tb_ooo_fp_arith_gate.log"
    command = [
        "make",
        "-B",
        f"BUILD_DIR={build_dir}",
        f"RESULT_DIR={run_dir}",
        f"{MAKE_OVERRIDES[mutation.target]}={mutant_path}",
        str(log_path),
    ]
    completed = subprocess.run(
        command,
        cwd=testbench_dir,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    (variant_dir / "driver.stdout").write_text(completed.stdout, encoding="utf-8")
    (variant_dir / "driver.stderr").write_text(completed.stderr, encoding="utf-8")

    compile_artifact = build_dir / "tb_ooo_fp_arith_gate.vvp"
    compile_succeeded = compile_artifact.is_file() and compile_artifact.stat().st_size > 0
    log_bytes = log_path.read_bytes() if log_path.is_file() else b""
    log_text = log_bytes.decode("utf-8", errors="replace")
    expected_marker_count = (
        log_text.count(mutation.expected_marker)
        if mutation.expected_marker is not None
        else 0
    )
    result_fail_count = log_text.count("[RESULT] FAIL")
    result_pass_count = log_text.count("[RESULT] PASS")
    duplicate_owner_errors = mutated_audit["errors"].count(
        "wrapper duplicate numeric owner marker"
    )
    duplicate_owner_audit_ok = (
        duplicate_owner_errors == 1
        if mutation.require_duplicate_owner_audit
        else True
    )
    dynamic_oracle_rejected = (
        mutation.expected_marker is not None
        and compile_succeeded
        and completed.returncode != 0
        and expected_marker_count == 1
        and result_fail_count == 1
        and result_pass_count == 0
        and duplicate_owner_audit_ok
        and bool(log_bytes)
    )
    structure_errors = mutated_audit["errors"]
    expected_structure_error_count = (
        structure_errors.count(mutation.expected_structure_error)
        if mutation.expected_structure_error is not None
        else 0
    )
    structural_oracle_rejected = (
        mutation.expected_structure_error is not None
        and compile_succeeded
        and completed.returncode == 0
        and expected_structure_error_count == 1
        and len(structure_errors) == 1
        and result_fail_count == 0
        and result_pass_count == 1
        and bool(log_bytes)
    )
    rejected = dynamic_oracle_rejected or structural_oracle_rejected
    return {
        "mutation_id": mutation.mutation_id,
        "target": mutation.target,
        "rtl_effect": mutation.rtl_effect,
        "replacement_receipts": receipts,
        "mutant_path": mutant_path.relative_to(repo_root).as_posix(),
        "mutant_sha256": sha256_bytes(mutant_path.read_bytes()),
        "command": command,
        "driver_rc": completed.returncode,
        "compile_succeeded": compile_succeeded,
        "compile_artifact": compile_artifact.relative_to(repo_root).as_posix(),
        "expected_marker": mutation.expected_marker,
        "expected_marker_count": expected_marker_count,
        "expected_structure_error": mutation.expected_structure_error,
        "expected_structure_error_count": expected_structure_error_count,
        "oracle_mode": (
            "dynamic" if mutation.expected_marker is not None else "structure"
        ),
        "dynamic_oracle_rejected": dynamic_oracle_rejected,
        "structural_oracle_rejected": structural_oracle_rejected,
        "result_fail_count": result_fail_count,
        "result_pass_count": result_pass_count,
        "raw_log_sha256": sha256_bytes(log_bytes) if log_bytes else None,
        "raw_log_size_bytes": len(log_bytes),
        "duplicate_owner_audit_required": mutation.require_duplicate_owner_audit,
        "duplicate_owner_audit_count": duplicate_owner_errors,
        "mutated_structure_audit": mutated_audit,
        "rejected": rejected,
        "log_path": log_path.relative_to(repo_root).as_posix(),
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"result directory is not empty: {result_dir}", file=sys.stderr)
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)

    testbench_dir = repo_root / "npc/rv64/testbench"
    sources = {
        key: repo_root / relative
        for key, relative in SOURCE_RELATIVE_PATHS.items()
    }
    before = {key: path.read_bytes() for key, path in sources.items()}
    dependencies = {
        relative: repo_root / relative for relative in DEPENDENCY_RELATIVE_PATHS
    }
    dependency_before = {
        relative: path.read_bytes() for relative, path in dependencies.items()
    }
    source_text = {key: data.decode("utf-8") for key, data in before.items()}
    structure_audit = audit_product_structure(source_text)
    if structure_audit["status"] != "PASS":
        print(
            "[FP-ARITH-CHILD-STRUCTURE] FAIL "
            + "; ".join(str(error) for error in structure_audit["errors"]),
            file=sys.stderr,
        )
        return 2

    try:
        results = [
            run_one(
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                sources=sources,
                source_text=source_text,
                mutation=mutation,
            )
            for mutation in MUTATIONS
        ]
    except (OSError, UnicodeError, ValueError) as error:
        print(f"[FP-ARITH-CHILD-MUTATIONS] FAIL setup={error}", file=sys.stderr)
        return 2

    after = {key: path.read_bytes() for key, path in sources.items()}
    dependency_after = {
        relative: path.read_bytes() for relative, path in dependencies.items()
    }
    source_unchanged = before == after
    dependency_unchanged = dependency_before == dependency_after
    compile_count = sum(bool(row["compile_succeeded"]) for row in results)
    unique_marker_count = sum(
        row["oracle_mode"] == "dynamic" and row["expected_marker_count"] == 1
        for row in results
    )
    unique_oracle_count = sum(
        (row["oracle_mode"] == "dynamic" and row["expected_marker_count"] == 1)
        or (
            row["oracle_mode"] == "structure"
            and row["expected_structure_error_count"] == 1
        )
        for row in results
    )
    rejected_count = sum(bool(row["rejected"]) for row in results)
    passed = (
        structure_audit["status"] == "PASS"
        and source_unchanged
        and dependency_unchanged
        and rejected_count == len(MUTATIONS)
    )
    evidence = {
        "schema": "npc-rv64-fp-arith-production-child-mutation-evidence-v2",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "configuration": "iverilog-g2012-OOO_ASSERT",
        "testbench": "tb_ooo_fp_arith_gate",
        "structure_audit": structure_audit,
        "source_sha256_before": {
            key: sha256_bytes(data) for key, data in before.items()
        },
        "source_sha256_after": {
            key: sha256_bytes(data) for key, data in after.items()
        },
        "source_unchanged": source_unchanged,
        "dependency_sha256_before": {
            relative: sha256_bytes(data)
            for relative, data in dependency_before.items()
        },
        "dependency_sha256_after": {
            relative: sha256_bytes(data)
            for relative, data in dependency_after.items()
        },
        "dependency_set_sha256": sha256_bytes(
            "".join(
                f"{relative}\t{sha256_bytes(dependency_before[relative])}\n"
                for relative in sorted(dependency_before)
            ).encode("utf-8")
        ),
        "dependency_unchanged": dependency_unchanged,
        "mutations": results,
        "summary": {
            "total": len(MUTATIONS),
            "compile_succeeded": compile_count,
            "unique_expected_marker": unique_marker_count,
            "unique_expected_oracle": unique_oracle_count,
            "rejected": rejected_count,
            "all_rejected": passed,
        },
    }
    evidence_path = result_dir / "mutation-evidence.json"
    evidence_path.write_text(
        json.dumps(evidence, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[FP-ARITH-CHILD-MUTATIONS] "
        f"total={len(MUTATIONS)} compile_succeeded={compile_count} "
        f"unique_marker={unique_marker_count} rejected={rejected_count} "
        f"unique_oracle={unique_oracle_count} "
        f"source_unchanged={int(source_unchanged)} "
        f"dependency_unchanged={int(dependency_unchanged)} "
        f"{'PASS' if passed else 'FAIL'}"
    )
    print(
        "[FP-ARITH-CHILD-STRUCTURE] PASS "
        "wrapper-clean unique-stage-owner mul-s1q-s2comb "
        "fma-s3q-s4comb full-mag-jam"
    )
    print(evidence_path)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
