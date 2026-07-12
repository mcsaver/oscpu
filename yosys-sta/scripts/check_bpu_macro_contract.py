#!/usr/bin/env python3
"""Check OooBranchDirectionPredictor macro/OOC placeholder contract.

This checker verifies that the BPU dedicated spec, four-blackbox table, active
RTL/frontend ABI, placeholder generator and generated Liberty all carry the same
scalar static-fallback contract. It does not validate real Liberty arcs, LEF,
OOC timing, predictor quality, or silicon area.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_SPEC_PATTERNS = {
    "section": r"##\s+8\.\s+Macro/OOC Contract v0",
    "lookup_read_latency": r"lookup read latency\s*\|\s*`0 cycle`",
    "read_ports": r"read ports\s*\|\s*two combinational views",
    "scalar_fallback": r"lookup\*_static_taken_i[^\n]*each lane|每路 static fallback 仅 1 bit",
    "update_visibility": r"update visibility\s*\|\s*`two cycles`",
    "reset_clear": r"reset/clear\s*\|\s*valid-only table clear plus GHR zero",
    "update_source": r"update source\s*\|\s*issue-resolve only",
    "bht_valid_bits": r"gshare BHT valid bits\s*\|\s*`1024`",
    "bht_counter_bits": r"gshare BHT counter bits\s*\|\s*`1024 \* 2 = 2048`",
    "ghr_bits": r"GHR bits\s*\|\s*`10`",
    "local_hist_valid_bits": r"local history valid bits\s*\|\s*`256`",
    "local_hist_bits": r"local history bits\s*\|\s*`256 \* 8 = 2048`",
    "local_pht_valid_bits": r"local PHT valid bits\s*\|\s*`4096`",
    "local_pht_counter_bits": r"local PHT counter bits\s*\|\s*`4096 \* 2 = 8192`",
    "total_bits": r"total state bits\s*\|\s*`17674`",
    "not_signoff": r"not stdcell area|不是 stdcell area",
    "liberty_open": r"Liberty/LEF|OOC timing report",
}

REQUIRED_BOUNDARY_PATTERNS = {
    "bpu_row": r"\|\s*OooBranchDirectionPredictor\s*\|",
    "placeholder_v0": r"OooBranchDirectionPredictor[^\n]*Placeholder v0 defined",
    "zero_cycle": r"OooBranchDirectionPredictor[^\n]*0-cycle two-lookup read",
    "scalar_fallback": r"OooBranchDirectionPredictor[^\n]*one scalar static-fallback bit per lane",
    "two_cycle": r"OooBranchDirectionPredictor[^\n]*two-cycle issue-resolve table-update visibility",
    "clear_ghr": r"OooBranchDirectionPredictor[^\n]*valid-only table clear plus GHR zero",
    "state_bits": r"OooBranchDirectionPredictor[^\n]*17674 state-bit",
    "liberty_open": r"OooBranchDirectionPredictor[^\n]*Liberty/LEF/OOC timing still open",
    "real_model_task": r"OooBranchDirectionPredictor[^\n]*real Liberty/LEF macro model|OooBranchDirectionPredictor[^\n]*OOC timing report",
}

REQUIRED_RTL_PATTERNS = {
    "lookup0_scalar": r"input\s+(?:wire\s+)?lookup0_static_taken_i\b",
    "lookup1_scalar": r"input\s+(?:wire\s+)?lookup1_static_taken_i\b",
}

REQUIRED_DEBUG_PATTERNS = {
    "lookup0_scalar": r"input\s+wire\s+lookup0_static_taken_i\b",
    "lookup1_scalar": r"input\s+wire\s+lookup1_static_taken_i\b",
}

REQUIRED_FRONTEND_PATTERNS = {
    "lookup0_owner": r"\.lookup0_static_taken_i\s*\(\s*fetch_dec0_bimm_w\s*\[\s*`XLEN-1\s*\]\s*\)",
    "lookup1_owner": r"\.lookup1_static_taken_i\s*\(\s*fetch_dec1_bimm_w\s*\[\s*`XLEN-1\s*\]\s*\)",
}

REQUIRED_GENERATOR_PATTERNS = {
    "lookup0_scalar": r'\("lookup0_static_taken_i",\s*1,\s*"input"\)',
    "lookup1_scalar": r'\("lookup1_static_taken_i",\s*1,\s*"input"\)',
}

REQUIRED_LIBERTY_PATTERNS = {
    "lookup0_scalar": r"pin\s*\(lookup0_static_taken_i\)",
    "lookup1_scalar": r"pin\s*\(lookup1_static_taken_i\)",
}

FORBIDDEN_WIDE_ABI_PATTERN = r"lookup[01]_imm_i"


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise SystemExit(f"FAIL missing file: {path}")


def current_bpu_contract_section(text: str) -> str:
    start = re.search(r"(?m)^##\s+8\.\s+Macro/OOC Contract v0\s*$", text)
    if not start:
        raise SystemExit("FAIL bpu-spec missing current Macro/OOC Contract v0 section")
    end = re.search(r"(?m)^##\s+9\.", text[start.end():])
    end_pos = start.end() + end.start() if end else len(text)
    return text[start.start():end_pos]


def current_bpu_boundary_row(text: str) -> str:
    rows = [
        line for line in text.splitlines()
        if re.match(r"^\|\s*OooBranchDirectionPredictor\s*\|", line)
    ]
    if len(rows) != 1:
        raise SystemExit(
            f"FAIL macro-boundary expected one current BPU row, got {len(rows)}"
        )
    return rows[0]


def check_patterns(label: str, text: str, patterns: dict[str, str]) -> None:
    missing = [
        name
        for name, pattern in patterns.items()
        if not re.search(pattern, text, flags=re.IGNORECASE)
    ]
    if missing:
        raise SystemExit(
            f"FAIL {label} missing contract facts: " + ", ".join(missing)
        )
    print(f"PASS {label} facts={len(patterns)}")


def check_no_wide_abi(label: str, text: str) -> None:
    if re.search(FORBIDDEN_WIDE_ABI_PATTERN, text):
        raise SystemExit(f"FAIL {label} still exposes lookup*_imm_i wide ABI")
    print(f"PASS {label} no-wide-imm-abi")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--bpu-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/ooo-branch-direction-predictor.md"),
    )
    parser.add_argument(
        "--macro-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/yosys-macro-boundary-contracts.md"),
    )
    parser.add_argument(
        "--rtl",
        type=Path,
        default=Path("npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v"),
    )
    parser.add_argument(
        "--frontend",
        type=Path,
        default=Path("npc/rv64/vsrc/frontend/OooFrontend.v"),
    )
    parser.add_argument(
        "--debug-checker",
        type=Path,
        default=Path("npc/rv64/vsrc/debug/OooBranchDirectionPredictorChecker.sv"),
    )
    parser.add_argument(
        "--generator",
        type=Path,
        default=Path("npc/rv64/syn/macro-lib/gen_macro_libs.py"),
    )
    parser.add_argument(
        "--liberty",
        type=Path,
        default=Path("npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"),
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    check_patterns(
        "bpu-spec-current-section",
        current_bpu_contract_section(read_text(args.bpu_spec)),
        REQUIRED_SPEC_PATTERNS,
    )
    check_patterns(
        "macro-boundary-current-row",
        current_bpu_boundary_row(read_text(args.macro_spec)),
        REQUIRED_BOUNDARY_PATTERNS,
    )
    rtl_text = read_text(args.rtl)
    frontend_text = read_text(args.frontend)
    debug_text = read_text(args.debug_checker)
    generator_text = read_text(args.generator)
    liberty_text = read_text(args.liberty)
    check_patterns("bpu-rtl", rtl_text, REQUIRED_RTL_PATTERNS)
    check_patterns("frontend-owner", frontend_text, REQUIRED_FRONTEND_PATTERNS)
    check_patterns("debug-checker", debug_text, REQUIRED_DEBUG_PATTERNS)
    check_patterns("macro-generator", generator_text, REQUIRED_GENERATOR_PATTERNS)
    check_patterns("placeholder-liberty", liberty_text, REQUIRED_LIBERTY_PATTERNS)
    check_no_wide_abi("bpu-rtl", rtl_text)
    check_no_wide_abi("frontend-owner", frontend_text)
    check_no_wide_abi("debug-checker", debug_text)
    check_no_wide_abi("macro-generator", generator_text)
    check_no_wide_abi("placeholder-liberty", liberty_text)
    print(
        "PASS bpu macro placeholder contract "
        f"bpu_spec={args.bpu_spec} macro_spec={args.macro_spec}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
