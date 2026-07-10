#!/usr/bin/env python3
"""Check OooBranchDirectionPredictor macro/OOC placeholder contract.

This checker is intentionally narrow: it verifies that the BPU dedicated spec
and the four-blackbox macro-boundary table both carry the same placeholder facts
needed before STA work continues. It does not validate real Liberty, LEF, OOC
timing, predictor quality, or silicon area.
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
    "update_visibility": r"update visibility\s*\|\s*`two cycles`",
    "reset_clear": r"reset/clear\s*\|\s*valid-only table clear plus GHR zero",
    "update_source": r"update source\s*\|\s*issue-resolve only",
    "bht_valid_bits": r"gshare BHT valid bits\s*\|\s*`4096`",
    "bht_counter_bits": r"gshare BHT counter bits\s*\|\s*`4096 \* 2 = 8192`",
    "ghr_bits": r"GHR bits\s*\|\s*`12`",
    "local_hist_valid_bits": r"local history valid bits\s*\|\s*`256`",
    "local_hist_bits": r"local history bits\s*\|\s*`256 \* 8 = 2048`",
    "local_pht_valid_bits": r"local PHT valid bits\s*\|\s*`4096`",
    "local_pht_counter_bits": r"local PHT counter bits\s*\|\s*`4096 \* 2 = 8192`",
    "total_bits": r"total state bits\s*\|\s*`26892`",
    "not_signoff": r"not stdcell area|不是 stdcell area",
    "liberty_open": r"Liberty/LEF|OOC timing report",
}

REQUIRED_BOUNDARY_PATTERNS = {
    "bpu_row": r"\|\s*OooBranchDirectionPredictor\s*\|",
    "placeholder_v0": r"OooBranchDirectionPredictor[^\n]*Placeholder v0 defined",
    "zero_cycle": r"OooBranchDirectionPredictor[^\n]*0-cycle two-lookup read",
    "next_cycle": r"OooBranchDirectionPredictor[^\n]*next-cycle issue-resolve update visibility",
    "clear_ghr": r"OooBranchDirectionPredictor[^\n]*valid-only table clear plus GHR zero",
    "state_bits": r"OooBranchDirectionPredictor[^\n]*26892 state-bit",
    "liberty_open": r"OooBranchDirectionPredictor[^\n]*Liberty/LEF/OOC timing still open",
    "real_model_task": r"OooBranchDirectionPredictor[^\n]*real Liberty/LEF macro model|OooBranchDirectionPredictor[^\n]*OOC timing report",
}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise SystemExit(f"FAIL missing file: {path}")


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
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    check_patterns("bpu-spec", read_text(args.bpu_spec), REQUIRED_SPEC_PATTERNS)
    check_patterns("macro-boundary", read_text(args.macro_spec), REQUIRED_BOUNDARY_PATTERNS)
    print(
        "PASS bpu macro placeholder contract "
        f"bpu_spec={args.bpu_spec} macro_spec={args.macro_spec}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
