#!/usr/bin/env python3
"""Check OooDataWordCache macro/OOC placeholder contract.

This checker is intentionally narrow: it verifies that the D-cache dedicated
spec and the four-blackbox macro-boundary table both carry the same placeholder
facts needed before STA work continues. It does not validate real Liberty,
LEF, OOC timing, or silicon area.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_SPEC_PATTERNS = {
    "section": r"##\s+8\.\s+Macro/OOC Contract v1",
    "lookup_read_latency": r"lookup read latency\s*\|\s*`1 cycle`",
    "addr_attribute_latency": r"addr-attribute latency\s*\|\s*`0 cycle`",
    "write_visibility": r"write visibility\s*\|\s*`next cycle`",
    "rw_conflict": r"read/write conflict\s*\|\s*禁止\(1RW\)",
    "reset_model": r"reset\s*\|\s*valid-only clear",
    "read_ports": r"read ports\s*\|\s*one synchronous read port",
    "entries": r"entries\s*\|\s*`4096`",
    "sram_macro_bits": r"SRAM macro bits\s*\|\s*`4096 \* 113 = 462848`",
    "data_bits": r"data bits\s*\|\s*`4096 \* 64 = 262144`",
    "tag_bits": r"tag bits\s*\|\s*`4096 \* \(64 - 3 - 12\) = 200704`",
    "valid_bits": r"valid bits \(FF\)\s*\|\s*`4096`",
    "total_bits": r"total state bits\s*\|\s*`466944`",
    "not_signoff": r"not stdcell area|不是 stdcell area",
    "liberty_open": r"Liberty/LEF|OOC timing report",
}

REQUIRED_BOUNDARY_PATTERNS = {
    "dcache_row": r"\|\s*OooDataWordCache\s*\|",
    "sram_macro_v1": r"OooDataWordCache[^\n]*SRAM macro v1",
    "one_cycle": r"OooDataWordCache[^\n]*1-cycle sync lookup read",
    "next_cycle": r"OooDataWordCache[^\n]*next-cycle write visibility",
    "store_invalidate": r"OooDataWordCache[^\n]*unconditional store invalidate",
    "state_bits": r"OooDataWordCache[^\n]*466944 state-bit",
    "liberty_open": r"OooDataWordCache[^\n]*Liberty/LEF/OOC timing still open",
    "real_model_task": r"OooDataWordCache[^\n]*real Liberty/LEF macro model|OooDataWordCache[^\n]*OOC timing report",
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
        "--dcache-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/ooo-data-word-cache.md"),
    )
    parser.add_argument(
        "--macro-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/yosys-macro-boundary-contracts.md"),
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    check_patterns("dcache-spec", read_text(args.dcache_spec), REQUIRED_SPEC_PATTERNS)
    check_patterns("macro-boundary", read_text(args.macro_spec), REQUIRED_BOUNDARY_PATTERNS)
    print(
        "PASS dcache macro placeholder contract "
        f"dcache_spec={args.dcache_spec} macro_spec={args.macro_spec}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
