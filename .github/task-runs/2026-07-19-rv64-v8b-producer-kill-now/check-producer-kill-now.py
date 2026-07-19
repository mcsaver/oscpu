#!/usr/bin/env python3
"""Structural guard for the v8b-prep producer kill-now slice."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]

PATHS = {
    "clmul": REPO / "npc/rv64/vsrc/execute/OooClmulUnit.v",
    "fp": REPO / "npc/rv64/vsrc/execute/OooFpArithGate.v",
    "int_backend": REPO / "npc/rv64/vsrc/execute/OooIntBackend.v",
    "fp_backend": REPO / "npc/rv64/vsrc/execute/OooFpBackend.v",
    "dispatch": REPO / "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
}


def compact(text: str) -> str:
    return re.sub(r"\s+", " ", text)


def load_sources() -> dict[str, str]:
    return {name: path.read_text(encoding="utf-8") for name, path in PATHS.items()}


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def check_sources(src: dict[str, str]) -> list[str]:
    errors: list[str] = []
    clmul = src["clmul"]
    clmul_c = compact(clmul)
    fp = src["fp"]
    fp_c = compact(fp)
    intb = src["int_backend"]
    intb_c = compact(intb)
    fpb_c = compact(src["fp_backend"])
    dispatch_c = compact(src["dispatch"])

    require(errors, "function clmul_killed" not in clmul,
            "CLMUL reintroduced ambient clmul_killed function")
    for token in (
        "wire [ROB_INDEX_W-1:0] kill_age_thresh_w = kill_rob_idx_i - rob_head_idx_i;",
        "wire [ROB_INDEX_W-1:0] kill_age_resp_w = resp_rob_idx_q - rob_head_idx_i;",
        "wire [ROB_INDEX_W-1:0] kill_age_req_w = req_rob_idx_i - rob_head_idx_i;",
        "kill_valid_i && (kill_age_resp_w > kill_age_thresh_w)",
        "req_fire_w && kill_valid_i && (kill_age_req_w > kill_age_thresh_w)",
        "assign resp_valid_o = (state_q == STATE_RESP) && !kill_inflight_w;",
    ):
        require(errors, token in clmul_c, f"CLMUL exact dependency missing: {token}")

    reset_pos = clmul_c.find("if (rst || flush_i) begin")
    kill_pos = clmul_c.find("end else if (kill_inflight_w) begin")
    case_pos = clmul_c.find("case (state_q)")
    require(errors, -1 < reset_pos < kill_pos < case_pos,
            "CLMUL priority is not reset/flush > matching kill > normal state")
    if kill_pos >= 0 and case_pos > kill_pos:
        kill_block = clmul_c[kill_pos:case_pos]
        for token in (
            "state_q <= STATE_IDLE;",
            "resp_rob_idx_q <= {ROB_INDEX_W{1'b0}};",
            "resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};",
            "resp_data_q <= {`XLEN{1'b0}};",
        ):
            require(errors, token in kill_block,
                    f"CLMUL matching-kill block does not clear {token}")

    require(errors, "function fp_meta_killed" not in fp,
            "FP reintroduced ambient fp_meta_killed function")
    helper = re.search(
        r"function\s+fp_meta_younger\s*;(?P<body>.*?)endfunction", fp, re.S
    )
    require(errors, helper is not None, "FP pure fp_meta_younger helper missing")
    if helper:
        body = helper.group("body")
        formals = re.findall(r"\binput\b", body)
        require(errors, len(formals) == 3,
                f"FP helper must have exactly 3 explicit inputs, found {len(formals)}")
        for ambient in ("kill_valid_i", "kill_rob_idx_i", "rob_head_idx_i"):
            require(errors, ambient not in body,
                    f"FP helper illegally reads ambient {ambient}")
        require(errors,
                "(idx - head_idx) > (boundary_idx - head_idx)" in compact(body),
                "FP helper lost strict circular-age equation")

    for call in (
        "fp_meta_younger(launch_rob_idx_i, kill_rob_idx_i, rob_head_idx_i)",
        "fp_meta_younger(meta_rob_q[mi-1], kill_rob_idx_i, rob_head_idx_i)",
        "fp_meta_younger(meta_rob_q[5], kill_rob_idx_i, rob_head_idx_i)",
    ):
        require(errors, call in fp_c, f"FP explicit helper call missing: {call}")
    require(errors,
            "assign out_valid_o = meta_valid_q[5] && !(kill_valid_i && fp_meta_younger(meta_rob_q[5], kill_rob_idx_i, rob_head_idx_i));"
            in fp_c,
            "FP stage5 output is not masked by the current matching kill")

    # Production provenance: producer-local kill mask must remain before every
    # downstream completion consumer. These are structural facts, not a claim
    # that downstream has generation-safe identity acceptance.
    for token in (
        "OooClmulUnit #(",
        ".kill_valid_i(branch_resolve_mispredict_w)",
        ".kill_rob_idx_i(branch_resolve_rob_idx_o)",
        ".rob_head_idx_i(rob_head_idx_w)",
        ".resp_valid_o(clmul_resp_valid_w)",
        "clmul_resp_valid_w && !ex0_valid_q",
        "clmul_resp_valid_w && !clmul_rsp_to_wb0_w",
        ".wb0_valid_i(wb0_valid_w)",
        ".wb1_valid_i(wb1_valid_w)",
        ".write0_valid_i(gpr_wb0_write_valid_w)",
        ".write1_valid_i(gpr_wb1_write_valid_w)",
    ):
        require(errors, token in intb_c, f"CLMUL production callchain missing: {token}")
    for token in (
        ".wakeup0_valid_i(wb0_valid_i)",
        ".wakeup1_valid_i(wb1_valid_i)",
        ".wb0_valid_i(wb0_valid_i)",
        ".wb1_valid_i(wb1_valid_i)",
    ):
        require(errors, token in dispatch_c,
                f"shared WB consumer provenance missing: {token}")

    for token in (
        "OooFpArithGate u_fp_arith",
        ".kill_valid_i(kill_valid_i)",
        ".kill_rob_idx_i(kill_rob_idx_i)",
        ".rob_head_idx_i(rob_head_idx_i)",
        ".out_valid_o(arith_out_valid_w)",
        "assign fp_result_wb_valid_w = arith_out_valid_w || exec1_take_w || long_take_w;",
        "wire df_push_w = fp_result_wb_valid_w;",
        "wire fp_fpr_complete_w = fp_result_wb_valid_w && fp_result_wb_frd_w;",
    ):
        require(errors, token in fpb_c, f"FP production callchain missing: {token}")

    return errors


def run_self_test(src: dict[str, str]) -> int:
    base_errors = check_sources(src)
    if base_errors:
        for error in base_errors:
            print(f"[V8B-KILL-CHECKER][SELFTEST][FAIL] baseline: {error}")
        return 1

    mutations: list[tuple[str, dict[str, str]]] = []

    mutant = dict(src)
    mutant["clmul"] = mutant["clmul"].replace(
        "kill_valid_i && (kill_age_resp_w > kill_age_thresh_w)",
        "(kill_age_resp_w > kill_age_thresh_w)",
        1,
    )
    mutations.append(("clmul-no-kill-valid", mutant))

    mutant = dict(src)
    mutant["fp"] = mutant["fp"].replace(
        "(idx - head_idx) > (boundary_idx - head_idx)",
        "(idx - rob_head_idx_i) > (boundary_idx - rob_head_idx_i)",
        1,
    )
    mutations.append(("fp-ambient-head", mutant))

    mutant = dict(src)
    mutant["int_backend"] = mutant["int_backend"].replace(
        "clmul_resp_valid_w && !ex0_valid_q",
        "1'b1 && !ex0_valid_q",
        1,
    )
    mutations.append(("cut-clmul-provenance", mutant))

    for name, candidate in mutations:
        if not check_sources(candidate):
            print(f"[V8B-KILL-CHECKER][SELFTEST][FAIL] mutation survived: {name}")
            return 1
        print(f"[V8B-KILL-CHECKER][SELFTEST][PASS] {name}")
    print(f"[V8B-KILL-CHECKER][SELFTEST][PASS] mutations={len(mutations)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    src = load_sources()
    if args.self_test:
        return run_self_test(src)
    errors = check_sources(src)
    if errors:
        for error in errors:
            print(f"[V8B-KILL-CHECKER][FAIL] {error}")
        print(f"[V8B-KILL-CHECKER][FAIL] unresolved={len(errors)}")
        return 1
    print("[V8B-KILL-CHECKER][PASS] explicit kill dependencies and production provenance locked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
