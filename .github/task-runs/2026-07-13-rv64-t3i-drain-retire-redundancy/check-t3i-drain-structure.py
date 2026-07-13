#!/usr/bin/env python3
"""Fail closed unless the redundant retire-count drain dependency is absent."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-DRAIN-STRUCTURE] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check-t3i-drain-structure.py REPO_ROOT")
    root = Path(sys.argv[1]).resolve()
    gate_path = root / "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v"
    plane_path = root / "npc/rv64/vsrc/control/OooControlPlane.v"
    core_path = root / "npc/rv64/vsrc/execute/OooAluCoreSlice.v"
    gate = gate_path.read_text()
    plane = plane_path.read_text()
    core = core_path.read_text()

    if re.search(r"\bcore_retire_count_i\b", gate):
        fail("OooPendingDrainResolveGate still exposes core_retire_count_i")
    if re.search(r"\bcore_retire_count_w\b", plane):
        fail("OooControlPlane still imports core_retire_count_w")

    drained_match = re.search(
        r"assign\s+backend_drained_o\s*=\s*(.*?);", gate, re.DOTALL
    )
    if drained_match is None:
        fail("backend_drained_o assignment missing")
    drained = drained_match.group(1)
    required_terms = (
        (r"\(\s*rob_count_i\s*==\s*\{ROB_COUNT_W\{1'b0\}\}\s*\)",
         "exact-zero ROB count"),
        (r"\(\s*issue_count_i\s*==\s*\{ISSUE_COUNT_W\{1'b0\}\}\s*\)",
         "exact-zero issue count"),
        (r"!\s*synth_lane1_ret_pending_i\b", "cleared synthetic retire"),
        (r"!\s*synth_lane1_branch_drop_pending_i\b",
         "cleared synthetic branch drop"),
        (r"\bmem_retire_quiet_i\b", "memory-retire quiet"),
    )
    for pattern, label in required_terms:
        if re.search(pattern, drained) is None:
            fail(f"backend drain safety term missing or wrong polarity: {label}")
    if drained.count("&&") != 4 or "||" in drained or "?" in drained:
        fail("backend drain formula is no longer the exact five-term conjunction")
    if re.search(r"\bcore_retire|\bretire_count", drained):
        fail("a core-retire-count term still feeds backend_drained_o")

    marker = "[CORE-RETIRE-REQUIRES-ROB]"
    if core.count(marker) != 1:
        fail(f"theorem assertion marker count is {core.count(marker)}, expected 1")
    assertion_pattern = (
        r"`ifdef\s+OOO_ASSERT.*?always\s*@\(posedge\s+clk\).*?"
        r"rob_count_o\s*===\s*\{ROB_COUNT_W\{1'b0\}\}.*?"
        r"retire_count_o\s*!==\s*2'b00.*?"
        r"\$error\(\"\[CORE-RETIRE-REQUIRES-ROB\]"
    )
    if re.search(assertion_pattern, core, re.DOTALL) is None:
        fail("theorem assertion condition/body is missing or weakened")

    print(
        "[T3I-DRAIN-STRUCTURE] PASS: retire dependency removed; "
        "drain safety terms preserved; theorem assertion present"
    )


if __name__ == "__main__":
    main()
