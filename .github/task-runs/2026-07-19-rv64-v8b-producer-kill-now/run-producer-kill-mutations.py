#!/usr/bin/env python3
"""Compile-success semantic mutations for producer kill-now behavior."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
VSRCDIR = REPO / "npc/rv64/vsrc"
TBDIR = REPO / "npc/rv64/testbench"


@dataclass(frozen=True)
class Mutation:
    name: str
    source: Path
    test: Path
    top: str
    replacements: tuple[tuple[str, str], ...]
    witness: str


CLMUL = VSRCDIR / "execute/OooClmulUnit.v"
CLMUL_TB = TBDIR / "tests/tb_ooo_clmul_unit.sv"
FP = VSRCDIR / "execute/OooFpArithGate.v"
FP_TB = TBDIR / "tests/tb_ooo_fp_arith_gate.sv"

CLMUL_EXPLICIT_BLOCK = """  wire [ROB_INDEX_W-1:0] kill_age_thresh_w =
      kill_rob_idx_i - rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] kill_age_resp_w =
      resp_rob_idx_q - rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] kill_age_req_w =
      req_rob_idx_i - rob_head_idx_i;
  wire kill_inflight_w =
      ((state_q == STATE_RUN) || (state_q == STATE_RESP)) &&
      kill_valid_i && (kill_age_resp_w > kill_age_thresh_w);
  wire kill_new_req_w =
      req_fire_w && kill_valid_i && (kill_age_req_w > kill_age_thresh_w);"""

CLMUL_AMBIENT_BLOCK = """  function clmul_killed;
    input [ROB_INDEX_W-1:0] idx;
    clmul_killed = kill_valid_i &&
        ((idx - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i));
  endfunction
  wire kill_inflight_w =
      ((state_q == STATE_RUN) || (state_q == STATE_RESP)) &&
      clmul_killed(resp_rob_idx_q);
  wire kill_new_req_w = req_fire_w && clmul_killed(req_rob_idx_i);"""

FP_PURE_FUNCTION = """  function fp_meta_younger;
    input [`OOO_ROB_INDEX_W-1:0] idx;
    input [`OOO_ROB_INDEX_W-1:0] boundary_idx;
    input [`OOO_ROB_INDEX_W-1:0] head_idx;
    begin
      fp_meta_younger =
          (idx - head_idx) > (boundary_idx - head_idx);
    end
  endfunction"""

FP_AMBIENT_FUNCTION = """  function fp_meta_killed;
    input [`OOO_ROB_INDEX_W-1:0] idx;
    begin
      fp_meta_killed = kill_valid_i &&
          ((idx - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i));
    end
  endfunction"""


MUTATIONS = (
    Mutation(
        "clmul-ambient-function",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        ((CLMUL_EXPLICIT_BLOCK, CLMUL_AMBIENT_BLOCK),),
        "kill-valid/cut/head only-toggle",
    ),
    Mutation(
        "clmul-no-new-kill-valid",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("req_fire_w && kill_valid_i && (kill_age_req_w > kill_age_thresh_w);",
          "req_fire_w && (kill_age_req_w > kill_age_thresh_w);"),),
        "kill-valid low request",
    ),
    Mutation(
        "clmul-no-inflight-kill-valid",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("kill_valid_i && (kill_age_resp_w > kill_age_thresh_w);",
          "(kill_age_resp_w > kill_age_thresh_w);"),),
        "nonmatching/kill-low survivor",
    ),
    Mutation(
        "clmul-inclusive-boundary",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("(kill_age_req_w > kill_age_thresh_w)",
          "(kill_age_req_w >= kill_age_thresh_w)"),),
        "4096 age sweep equal boundary",
    ),
    Mutation(
        "clmul-raw-index-age",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("(kill_age_req_w > kill_age_thresh_w)",
          "(req_rob_idx_i > kill_rob_idx_i)"),),
        "4096 age sweep wrap",
    ),
    Mutation(
        "clmul-no-new-request-kill",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("if (req_fire_w && !kill_new_req_w) begin",
          "if (req_fire_w) begin"),),
        "same-cycle killed request stays idle",
    ),
    Mutation(
        "clmul-no-response-mask",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("assign resp_valid_o = (state_q == STATE_RESP) && !kill_inflight_w;",
          "assign resp_valid_o = (state_q == STATE_RESP);"),),
        "backpressured RESP same-cycle mask",
    ),
    Mutation(
        "clmul-no-holder-clear",
        CLMUL,
        CLMUL_TB,
        "tb_ooo_clmul_unit",
        (("end else if (kill_inflight_w) begin",
          "end else if (1'b0) begin"),),
        "RUN/RESP kill state clear and reissue",
    ),
    Mutation(
        "fp-ambient-function",
        FP,
        FP_TB,
        "tb_ooo_fp_arith_gate",
        (
            (FP_PURE_FUNCTION, FP_AMBIENT_FUNCTION),
            ("fp_meta_younger(launch_rob_idx_i,\n"
             "                                           kill_rob_idx_i,\n"
             "                                           rob_head_idx_i)",
             "fp_meta_killed(launch_rob_idx_i)"),
            ("fp_meta_younger(meta_rob_q[mi-1],\n"
             "                                              kill_rob_idx_i,\n"
             "                                              rob_head_idx_i)",
             "fp_meta_killed(meta_rob_q[mi-1])"),
            ("fp_meta_younger(meta_rob_q[5],\n"
             "                                        kill_rob_idx_i,\n"
             "                                        rob_head_idx_i)",
             "fp_meta_killed(meta_rob_q[5])"),
            ("kill_valid_i && fp_meta_killed", "fp_meta_killed"),
        ),
        "FP cut/kill/head only-toggle",
    ),
    Mutation(
        "fp-raw-index-age",
        FP,
        FP_TB,
        "tb_ooo_fp_arith_gate",
        (("(idx - head_idx) > (boundary_idx - head_idx)",
          "idx > boundary_idx"),),
        "FP head-only wrap",
    ),
    Mutation(
        "fp-reversed-age",
        FP,
        FP_TB,
        "tb_ooo_fp_arith_gate",
        (("(idx - head_idx) > (boundary_idx - head_idx)",
          "(idx - head_idx) < (boundary_idx - head_idx)"),),
        "FP survivor/victim polarity",
    ),
    Mutation(
        "fp-no-output-mask",
        FP,
        FP_TB,
        "tb_ooo_fp_arith_gate",
        (("assign out_valid_o =\n"
          "      meta_valid_q[5] &&\n"
          "      !(kill_valid_i && fp_meta_younger(meta_rob_q[5],\n"
          "                                        kill_rob_idx_i,\n"
          "                                        rob_head_idx_i));",
          "assign out_valid_o = meta_valid_q[5];"),),
        "FP stage5 same-cycle mask",
    ),
    Mutation(
        "fp-no-propagation-kill",
        FP,
        FP_TB,
        "tb_ooo_fp_arith_gate",
        (("meta_valid_q[mi] <= meta_valid_q[mi-1] &&\n"
          "                            !(kill_valid_i &&\n"
          "                              fp_meta_younger(meta_rob_q[mi-1],\n"
          "                                              kill_rob_idx_i,\n"
          "                                              rob_head_idx_i));",
          "meta_valid_q[mi] <= meta_valid_q[mi-1];"),),
        "FP in-flight younger meta delayed pulse",
    ),
)


def apply_mutation(mutation: Mutation) -> str:
    text = mutation.source.read_text(encoding="utf-8")
    for old, new in mutation.replacements:
        count = text.count(old)
        if count != 1:
            raise RuntimeError(
                f"{mutation.name}: replacement must match exactly once, found {count}"
            )
        text = text.replace(old, new, 1)
    return text


def run_one(
    mutation: Mutation,
    iverilog: str,
    vvp: str,
    output_dir: Path,
) -> tuple[bool, str]:
    with tempfile.TemporaryDirectory(prefix=f"v8b-{mutation.name}-") as tmp_name:
        tmp = Path(tmp_name)
        mutated = tmp / mutation.source.name
        mutated.write_text(apply_mutation(mutation), encoding="utf-8")
        image = tmp / f"{mutation.top}.vvp"
        compile_cmd = [
            iverilog,
            "-g2012",
            "-Wall",
            f"-I{VSRCDIR}",
            f"-I{VSRCDIR / 'include'}",
            f"-I{TBDIR / 'common'}",
            "-DOOO_ASSERT",
            "-s",
            mutation.top,
            "-o",
            str(image),
            str(mutated),
            str(mutation.test),
        ]
        compiled = subprocess.run(
            compile_cmd, text=True, capture_output=True, timeout=60, check=False
        )
        log_parts = [
            f"mutation={mutation.name}",
            f"witness={mutation.witness}",
            f"compile_rc={compiled.returncode}",
            compiled.stdout,
            compiled.stderr,
        ]
        if compiled.returncode != 0:
            log = "\n".join(log_parts)
            (output_dir / f"{mutation.name}.log").write_text(log, encoding="utf-8")
            return False, "mutation did not compile"

        simulated = subprocess.run(
            [vvp, str(image)], text=True, capture_output=True, timeout=60, check=False
        )
        log_parts.extend(
            [
                f"sim_rc={simulated.returncode}",
                simulated.stdout,
                simulated.stderr,
            ]
        )
        log = "\n".join(log_parts)
        (output_dir / f"{mutation.name}.log").write_text(log, encoding="utf-8")
        semantic_failure = (
            simulated.returncode != 0
            and "[CHECK-FAIL]" in log
            and "[FAIL]" in log
        )
        if not semantic_failure:
            return False, "compile-success mutation escaped semantic oracle"
        return True, ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()

    if args.list:
        for mutation in MUTATIONS:
            print(f"{mutation.name}\t{mutation.witness}")
        return 0

    args.output_dir.mkdir(parents=True, exist_ok=True)
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise SystemExit("iverilog not found")
    adjacent_vvp = Path(iverilog).with_name("vvp")
    vvp = str(adjacent_vvp) if adjacent_vvp.exists() else shutil.which("vvp")
    if not vvp:
        raise SystemExit("vvp not found")

    failures: list[str] = []
    for mutation in MUTATIONS:
        try:
            passed, reason = run_one(
                mutation, iverilog, vvp, args.output_dir
            )
        except (RuntimeError, subprocess.TimeoutExpired) as error:
            passed, reason = False, str(error)
        if passed:
            print(f"[V8B-KILL-MUTATION][PASS] {mutation.name}: {mutation.witness}")
        else:
            failures.append(f"{mutation.name}: {reason}")
            print(f"[V8B-KILL-MUTATION][FAIL] {mutation.name}: {reason}")

    summary = [
        f"mutations={len(MUTATIONS)}",
        f"passed={len(MUTATIONS) - len(failures)}",
        f"failed={len(failures)}",
    ]
    if failures:
        summary.extend(f"failure={failure}" for failure in failures)
    (args.output_dir / "summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    if failures:
        return 1
    print(f"[V8B-KILL-MUTATION][PASS] mutations={len(MUTATIONS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
