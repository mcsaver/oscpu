#!/usr/bin/env python3
"""Check OooFetchPacketCache macro/OOC placeholder contract.

This checker is intentionally narrow: it verifies that the fetch packet cache
dedicated spec and the four-blackbox macro-boundary table both carry the same
placeholder facts needed before STA work continues. It does not validate real
Liberty, LEF, OOC timing, or silicon area.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_SPEC_PATTERNS = {
    "section": r"##\s+8\.\s+Macro/OOC Contract v1",
    "lookup_read_latency": r"lookup read latency\s*\|\s*`1 cycle`",
    "physical_read_port": r"`lookup_read_en_i`[^\n]*(物理|physical)[^\n]*(SRAM|sram)",
    "accept_requires_read": r"lookup_en_i\s*->\s*lookup_read_en_i",
    "write_visibility": r"write visibility\s*\|\s*`next lookup issue`",
    "same_cycle_priority": r"same-cycle priority\s*\|\s*reset/clear > blind invalidate > non-blocked fill",
    "reset_model": r"reset\s*\|\s*valid-only clear",
    "read_ports": r"read ports\s*\|\s*one synchronous 1RW SRAM port",
    "entries": r"entries\s*\|\s*`4096`",
    "valid_bits": r"valid bits \(FF\)\s*\|\s*`4096`",
    "sram_macro_bits": r"SRAM macro bits \(`Sram4096x199`\)\s*\|\s*`4096 \* 199 = 815104`",
    "context_bits": r"context bits[^|]*\|\s*`4096 \* \(1 \+ 2 \+ 64\) = 274432`",
    "pc_bits": r"pc tag bits\s*\|\s*`4096 \* 64 = 262144`",
    "payload_bits": r"packet payload bits\s*\|\s*`4096 \* \(32 \+ 2 \+ 32 \+ 2\) = 278528`",
    "total_bits": r"total state bits\s*\|\s*`819200`",
    "not_signoff": r"not stdcell area|不是 stdcell area",
    "liberty_open": r"Liberty/LEF|OOC timing report",
}

REQUIRED_BOUNDARY_PATTERNS = {
    "fetch_row": r"\|\s*OooFetchPacketCache\s*\|",
    "sram_macro_v1": r"OooFetchPacketCache[^\n]*SRAM macro v1",
    "one_cycle": r"OooFetchPacketCache[^\n]*1-cycle sync lookup read",
    "read_accept_split": r"OooFetchPacketCache[^\n]*physical-read/semantic-accept split",
    "next_visibility": r"OooFetchPacketCache[^\n]*next-lookup-issue fill/invalidate visibility",
    "clear_valid": r"OooFetchPacketCache[^\n]*clear-valid-only",
    "state_bits": r"OooFetchPacketCache[^\n]*819200 state-bit",
    "liberty_open": r"OooFetchPacketCache[^\n]*Liberty/LEF/OOC timing still open",
    "real_model_task": r"OooFetchPacketCache[^\n]*real Liberty/LEF macro model|OooFetchPacketCache[^\n]*OOC timing report",
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
        "--fetch-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/ooo-fetch-packet-cache.md"),
    )
    parser.add_argument(
        "--macro-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/yosys-macro-boundary-contracts.md"),
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    check_patterns("fetch-spec", read_text(args.fetch_spec), REQUIRED_SPEC_PATTERNS)
    check_patterns("macro-boundary", read_text(args.macro_spec), REQUIRED_BOUNDARY_PATTERNS)
    print(
        "PASS fetch cache macro placeholder contract "
        f"fetch_spec={args.fetch_spec} macro_spec={args.macro_spec}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
