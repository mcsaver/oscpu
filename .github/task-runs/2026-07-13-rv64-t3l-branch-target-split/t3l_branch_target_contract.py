#!/usr/bin/env python3

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


FILES = {
    "target": Path("npc/rv64/vsrc/frontend/OooFetchBranchTarget.v"),
    "decoder": Path("npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"),
    "frontend": Path("npc/rv64/vsrc/frontend/OooFrontend.v"),
    "filelist": Path("npc/rv64/vsrc/filelist.mk"),
}


class ContractError(RuntimeError):
    def __init__(self, code: str, detail: str):
        super().__init__(f"{code}: {detail}")
        self.code = code
        self.detail = detail


@dataclass(frozen=True)
class ContractStats:
    decoder_bimm_ports: int
    frontend_bimm_wires: int
    target_instances: int
    target_named_connections: int
    filelist_references: int


def _flat(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _require_count(text: str, token: str, count: int, code: str) -> None:
    actual = text.count(token)
    if actual != count:
        raise ContractError(code, f"expected {count} occurrences of {token!r}, got {actual}")


def load_live(repo_root: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for key, rel in FILES.items():
        path = repo_root / rel
        if not path.is_file():
            raise ContractError("E_FILE", f"missing {rel}")
        result[key] = path.read_text()
    return result


def validate_sources(files: Mapping[str, str]) -> ContractStats:
    missing = set(FILES) - set(files)
    if missing:
        raise ContractError("E_FILE", f"missing source keys {sorted(missing)}")

    target = files["target"]
    decoder = files["decoder"]
    frontend = files["frontend"]
    filelist = files["filelist"]
    target_flat = _flat(target)
    decoder_flat = _flat(decoder)
    frontend_flat = _flat(frontend)

    _require_count(target, "module OooFetchBranchTarget (", 1, "E_TARGET_MODULE")
    _require_count(target, "input [12:0] bimm_i", 1, "E_TARGET_BIMM_PORT")
    _require_count(target, "wire [12:0] low_sum_w", 1, "E_TARGET_LOW_SUM")
    _require_count(target, "wire [`XLEN-13:0] high_sum_w", 1, "E_TARGET_HIGH_SUM")
    if "{1'b0, pc_i[11:0]} + {1'b0, bimm_i[11:0]}" not in target_flat:
        raise ContractError("E_TARGET_LOW_FORMULA", "low 4KiB sum/carry formula drifted")
    high_formula = (
        "pc_i[`XLEN-1:12] + {{(`XLEN-13){1'b0}}, low_sum_w[12]} - "
        "{{(`XLEN-13){1'b0}}, bimm_i[12]}"
    )
    if high_formula not in target_flat:
        raise ContractError("E_TARGET_HIGH_FORMULA", "page carry-sign formula drifted")
    _require_count(target, "assign target_o = {high_sum_w, low_sum_w[11:0]};", 1,
                   "E_TARGET_OUTPUT")
    _require_count(target, "[FETCH-BRANCH-TARGET-EQUIV]", 1, "E_TARGET_ASSERT")
    functional_target = target.split("`ifdef OOO_ASSERT", 1)[0]
    if "{bimm_i[12]}" in functional_target or "{{(`XLEN-13){bimm_i[12]}}" in functional_target:
        raise ContractError("E_TARGET_WIDE_SIGN", "functional datapath restored wide sign replication")

    if decoder.count("output [12:0] dec0_bimm_o") != 1 or decoder.count(
        "output [12:0] dec1_bimm_o"
    ) != 1:
        raise ContractError("E_DECODER_WIDTH", "decoder B-imm outputs are not exactly 13 bit")
    if re.search(r"output\s+\[`XLEN-1:0\]\s+dec[01]_bimm_o", decoder):
        raise ContractError("E_DECODER_WIDE", "decoder restored XLEN-wide B-imm")
    for lane in (0, 1):
        formula = (
            f"assign dec{lane}_bimm_o = dec{lane}_branch_o ? "
            f"{{dec{lane}_inst_o[31], dec{lane}_inst_o[7], dec{lane}_inst_o[30:25], "
            f"dec{lane}_inst_o[11:8], 1'b0}} : 13'b0;"
        )
        if formula not in decoder_flat:
            raise ContractError("E_DECODER_FORMULA", f"lane{lane} B-imm extraction drifted")

    for lane in (0, 1):
        _require_count(frontend, f"wire [12:0] fetch_dec{lane}_bimm_w;", 1,
                       "E_FRONTEND_WIDTH")
        _require_count(frontend, f"wire [`XLEN-1:0] fetch_dec{lane}_branch_target_w;", 1,
                       "E_FRONTEND_TARGET_WIRE")
        _require_count(frontend, f"OooFetchBranchTarget u_fetch_dec{lane}_branch_target (", 1,
                       "E_FRONTEND_TARGET_INSTANCE")
        _require_count(frontend, f".bimm_i(fetch_dec{lane}_bimm_w)", 1,
                       "E_FRONTEND_TARGET_BIMM")
        _require_count(frontend, f".pc_i(fetch_dec{lane}_pc_w)", 1,
                       "E_FRONTEND_TARGET_PC")
        _require_count(frontend, f".target_o(fetch_dec{lane}_branch_target_w)", 1,
                       "E_FRONTEND_TARGET_OUTPUT")
        _require_count(frontend, f".lookup{lane}_static_taken_i(fetch_dec{lane}_bimm_w[12])", 1,
                       "E_FRONTEND_STATIC_SIGN")
    if re.search(r"fetch_dec[01]_bimm_w\[`XLEN-1\]", frontend):
        raise ContractError("E_FRONTEND_WIDE_SIGN", "predictor still consumes XLEN sign bit")
    target_mux = (
        "assign fetch_pred_next_pc_w = fetch_pred0_taken_w ? fetch_dec0_branch_target_w : "
        "fetch_pred1_taken_w ? fetch_dec1_branch_target_w : fetch_rsp_packet_next_pc_w;"
    )
    if target_mux not in frontend_flat:
        raise ContractError("E_FRONTEND_TARGET_MUX", "lane priority/target mux drifted")
    if re.search(r"fetch_dec[01]_pc_w\s*\+\s*fetch_dec[01]_bimm_w", frontend):
        raise ContractError("E_FRONTEND_DIRECT_ADD", "wide direct PC+B-imm add restored")

    _require_count(filelist, "RTL_OOO_FETCH_BRANCH_TARGET :=", 1, "E_FILELIST_DEFINE")
    _require_count(filelist, "$(RTL_OOO_FETCH_BRANCH_TARGET)", 1, "E_FILELIST_USE")

    return ContractStats(
        decoder_bimm_ports=2,
        frontend_bimm_wires=2,
        target_instances=2,
        target_named_connections=10,
        filelist_references=2,
    )


MASK64 = (1 << 64) - 1
MASK52 = (1 << 52) - 1


def signed_bimm(bimm: int) -> int:
    bimm &= 0x1FFF
    return (bimm & 0xFFF) - (((bimm >> 12) & 1) << 12)


def split_target(pc: int, bimm: int) -> int:
    pc &= MASK64
    bimm &= 0x1FFF
    low_sum = (pc & 0xFFF) + (bimm & 0xFFF)
    high = ((pc >> 12) + (low_sum >> 12) - ((bimm >> 12) & 1)) & MASK52
    return ((high << 12) | (low_sum & 0xFFF)) & MASK64


def reference_target(pc: int, bimm: int) -> int:
    return (pc + signed_bimm(bimm)) & MASK64
