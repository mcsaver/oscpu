#!/usr/bin/env python3
"""Fail-closed source audit for the T3W timing ownership boundaries."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


class AuditError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AuditError(message)


def strip_assertions(text: str) -> str:
    return re.sub(r"`ifdef OOO_ASSERT.*?`endif", "", text, flags=re.DOTALL)


def instance_body(text: str, module: str, name: str) -> str:
    match = re.search(
        rf"\b{re.escape(module)}\s+{re.escape(name)}\s*\((.*?)\);",
        text,
        flags=re.DOTALL,
    )
    require(match is not None, f"missing instance {module} {name}")
    return match.group(1)


def audit_ifu(text: str) -> None:
    core = strip_assertions(text)
    pmp0 = instance_body(core, "PmpChecker", "u_req_exec_pmp_checker")
    pmp1 = instance_body(core, "PmpChecker", "u_req_exec1_pmp_checker")
    require(
        re.search(r"\.paddr_i\s*\(\s*lookup_exec_paddr_q\s*\)", pmp0)
        is not None,
        "first fast PMP checker does not consume lookup_exec_paddr_q",
    )
    require(
        re.search(r"\.paddr_i\s*\(\s*req_exec1_paddr_w\s*\)", pmp1)
        is not None,
        "second fast PMP checker does not consume registered +4 owner",
    )
    require(
        re.search(
            r"wire\s+\[`XLEN-1:0\]\s+req_exec1_paddr_w\s*=\s*"
            r"lookup_exec_paddr_q\s*\+\s*64'd4\s*;",
            core,
        )
        is not None,
        "req_exec1_paddr_w is not lookup_exec_paddr_q + 4",
    )
    require(".paddr_i(req_exec_paddr_w)" not in pmp0,
            "live ITLB/PADDR cone re-entered first fast PMP checker")


FIFO_HEAD_OUTPUTS = {
    "head_pc0_o", "head_pc1_o", "head_next_pc0_o", "head_next_pc1_o",
    "head_packet_next_pc_o", "head_inst0_o", "head_inst1_o",
    "head_ctrl0_o", "head_ctrl1_o", "head_static_facts0_o",
    "head_static_facts1_o", "head_rs1_0_o", "head_rs2_0_o",
    "head_rd0_o", "head_imm0_o", "head_rs1_1_o", "head_rs2_1_o",
    "head_rd1_o", "head_imm1_o", "head_resp0_o", "head_resp1_o",
    "head_pred_taken0_o", "head_pred_taken1_o", "head_bht_idx0_o",
    "head_bht_idx1_o", "head_bht_valid0_o", "head_bht_valid1_o",
    "head_slot1_valid_o",
}


def audit_fifo(text: str) -> None:
    core = strip_assertions(text)
    packed = re.findall(
        r"assign\s*\{(.*?)\}\s*=\s*head_packet_q\s*;", core, re.DOTALL
    )
    require(len(packed) == 1, "head packet is not driven by one packed shadow")
    observed = set(re.findall(r"\bhead_[A-Za-z0-9_]+_o\b", packed[0]))
    require(observed == FIFO_HEAD_OUTPUTS,
            f"packed shadow output set drifted: {sorted(observed ^ FIFO_HEAD_OUTPUTS)}")
    require(re.search(r"\w+_q\s*\[\s*head_q\s*\]", core) is None,
            "production FIFO path still reads ring[head_q]")
    require(
        re.search(
            r"assign\s+head_valid_o\s*=\s*\(count_q\s*!=\s*FIFO_COUNT_ZERO\)\s*;",
            core,
        )
        is not None,
        "head_valid is not mechanically owned by count",
    )
    require("pop_i && (count_q > FIFO_COUNT_ONE)" in core,
            "multi-entry pop does not refresh the registered head")


def audit_rob(text: str) -> None:
    core = strip_assertions(text)
    for signal, owner in (
        ("head_done_w", "done_q[head_q]"),
        ("head_data_w", "data_q[head_q]"),
        ("head_exception_w", "exception_q[head_q]"),
        ("head_cause_w", "cause_q[head_q]"),
        ("head_tval_w", "tval_q[head_q]"),
        ("head_fflags_w", "fflags_q[head_q]"),
    ):
        require(
            re.search(
                rf"assign\s+{signal}\s*=\s*{re.escape(owner)}\s*;", core
            )
            is not None,
            f"{signal} is not Q-only",
        )
    require("[T3W-ROB-WB-OWNER-COLLISION]" in text,
            "dual-WB owner collision contract missing")


def audit_mem(text: str) -> None:
    core = strip_assertions(text)
    require(
        re.search(
            r"wire\s+req_read_lookup_issue_w\s*=\s*"
            r"stage_advance_w\s*&&\s*!req_write_w\s*;",
            core,
        )
        is not None,
        "D-cache speculative read is not stage-owned",
    )
    require(
        re.search(
            r"wire\s+req_lookup_payload_owner_w\s*=\s*"
            r"req_read_lookup_issue_w\s*;",
            core,
        )
        is not None,
        "D-cache lookup payload owner drifted",
    )


def expect_mutation_failure(name: str, callback) -> str:
    try:
        callback()
    except AuditError as error:
        return f"{name}:CAUGHT:{error}"
    raise AuditError(f"mutation escaped structural audit: {name}")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    repo = (args.repo_root or Path(__file__).resolve().parents[3]).resolve()
    paths = {
        "ifu": repo / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
        "fifo": repo / "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
        "rob": repo / "npc/rv64/vsrc/writeback/OooRob.v",
        "mem": repo / "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    }
    texts = {name: path.read_text() for name, path in paths.items()}
    audit_ifu(texts["ifu"])
    audit_fifo(texts["fifo"])
    audit_rob(texts["rob"])
    audit_mem(texts["mem"])

    mutations = [
        expect_mutation_failure(
            "ifu-live-paddr-to-pmp",
            lambda: audit_ifu(texts["ifu"].replace(
                ".paddr_i(lookup_exec_paddr_q)",
                ".paddr_i(req_exec_paddr_w)",
                1,
            )),
        ),
        expect_mutation_failure(
            "fifo-ring-head-production-read",
            lambda: audit_fifo(texts["fifo"].replace(
                "assign count_o = count_q;",
                "assign head_inst0_o = inst0_q[head_q];\n"
                "  assign count_o = count_q;",
                1,
            )),
        ),
        expect_mutation_failure(
            "rob-wb-retire-bypass",
            lambda: audit_rob(texts["rob"].replace(
                "assign head_data_w = data_q[head_q];",
                "assign head_data_w = wb0_data_i;",
                1,
            )),
        ),
    ]
    result = {
        "status": "PASS",
        "hashes": {name: digest(path) for name, path in paths.items()},
        "mutations": mutations,
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("[T3W-STRUCTURAL] PASS " + " ".join(mutations))


if __name__ == "__main__":
    try:
        main()
    except AuditError as error:
        raise SystemExit(f"[T3W-STRUCTURAL] FAIL: {error}")
