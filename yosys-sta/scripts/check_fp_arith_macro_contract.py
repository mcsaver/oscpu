#!/usr/bin/env python3
"""Check OooFpArithGate macro/OOC decision-placeholder contract.

This checker is intentionally narrow: it verifies that the FP arithmetic
dedicated spec and the four-blackbox macro-boundary table both carry the same
decision facts needed before STA work continues. It does not validate real
Liberty, LEF, OOC timing, arithmetic equivalence, or silicon area.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_SPEC_PATTERNS = {
    "section": r"##\s+7\.\s+Macro/OOC Contract v0",
    "semantic_boundary": r"production.*OooFpArithGate.*FP_ARITH_LATENCY=5|生产语义边界.*OooFpArithGate.*FP_ARITH_LATENCY=5",
    "pending_latency": r"pending latency\s*\|\s*`5 cycles`",
    "bfp_latency": r"B-FP launch/out latency\s*\|\s*`5 cycles`",
    "launch_throughput": r"launch throughput\s*\|\s*`1 op/cycle`",
    "flush_reset": r"flush/reset\s*\|\s*clears latency counter plus meta/data valid chain",
    "kill_visibility": r"kill visibility\s*\|\s*same-cycle launch gate plus pipeline meta squash",
    "value_fflags_alignment": r"value/fflags alignment\s*\|\s*same pipeline stage",
    "valid_launch_kinds": r"valid launch kinds\s*\|\s*`0/1/2`",
    "ooc_status": r"OOC evidence status\s*\|\s*coarse PASS; full stdcell open",
    "ooc_coarse": r"OOC coarse\s*\|\s*PASS",
    "full_module_open": r"full module stdcell\s*\|\s*open",
    "addsub_full": r"AddSub cone\s*\|\s*full PASS",
    "internal_full": r"internal standalone cones\s*\|\s*all full PASS",
    "not_signoff": r"non-signoff|不是.*STA-ready",
    "common_facts": r"`vsrc/common` facts",
    "debug_checker": r"`vsrc/debug` checker",
    "remaining_task": r"production child split|full module OOC timing report",
}

REQUIRED_BOUNDARY_PATTERNS = {
    "fp_row": r"\|\s*OooFpArithGate\s*\|",
    "decision_v0": r"OooFpArithGate[^\n]*Decision placeholder v0 defined",
    "five_cycle": r"OooFpArithGate[^\n]*5-cycle `OooFpArithGate`",
    "non_signoff": r"OooFpArithGate[^\n]*module-level blackbox only non-signoff OOC boundary",
    "ooc_open": r"OooFpArithGate[^\n]*OOC coarse PASS but full stdcell still open",
    "timing_open": r"OooFpArithGate[^\n]*Liberty/LEF/OOC timing still open",
    "semantic_audit": r"OooFpArithGate[^\n]*no common/debug facts required while boundary remains local",
    "real_model_task": r"OooFpArithGate[^\n]*full-module OOC timing report|OooFpArithGate[^\n]*production child split",
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
        "--fp-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/ooo-fp-arith-gate.md"),
    )
    parser.add_argument(
        "--macro-spec",
        type=Path,
        default=Path("npc/rv64/design/specs/yosys-macro-boundary-contracts.md"),
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    check_patterns("fp-arith-spec", read_text(args.fp_spec), REQUIRED_SPEC_PATTERNS)
    check_patterns("macro-boundary", read_text(args.macro_spec), REQUIRED_BOUNDARY_PATTERNS)
    print(
        "PASS fp-arith macro decision contract "
        f"fp_spec={args.fp_spec} macro_spec={args.macro_spec}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
