#!/usr/bin/env python3
"""Fail-closed source/interface contract for the T3M EX sticky barrier."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
FILES = {
    "int_backend": ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v",
    "dispatch": ROOT / "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "iq": ROOT / "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "prf": ROOT / "npc/rv64/vsrc/regread_bypass/OooPhysRegFile.v",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"[T3M-SOURCE] FAIL: {message}")


def main() -> None:
    text = {name: path.read_text(encoding="utf-8") for name, path in FILES.items()}
    joined = "\n".join(text.values())

    forbidden = ("select_wakeup", "fast_wb", "bypass0_", "bypass1_")
    for token in forbidden:
        require(token not in joined, f"forbidden fast ABI remains: {token}")

    ib = text["int_backend"]
    db = text["dispatch"]
    iq = text["iq"]
    prf = text["prf"]

    for needle in (
        ".wb0_valid_i(wb0_valid_w)",
        ".wb1_valid_i(wb1_valid_w)",
        ".write0_valid_i(gpr_wb0_write_valid_w)",
        ".write1_valid_i(gpr_wb1_write_valid_w)",
    ):
        require(needle in ib, f"formal WB consumer missing in IntBackend: {needle}")

    for needle in (
        ".wakeup0_valid_i(wb0_valid_i)",
        ".wakeup0_pdest_i(wb0_pdest_i)",
        ".wakeup1_valid_i(wb1_valid_i)",
        ".wakeup1_pdest_i(wb1_pdest_i)",
    ):
        require(needle in db, f"formal WB -> IQ sticky connection missing: {needle}")

    require(
        "src1_ready_q[scan_i] &&\n                              src2_ready_q[scan_i]" in iq,
        "resident select is not exclusively sticky-ready",
    )
    int_wakeup_sites = len(re.findall(r"(?<!fp_)wakeup_match\(", iq))
    require(
        int_wakeup_sites == 8,
        f"expected 8 integer sticky capture sites, got {int_wakeup_sites}",
    )
    for owner in (
        "src1_ready_q[compact_i] ||",
        "src2_ready_q[compact_i] ||",
        "dispatch0_src1_ready_i ||",
        "dispatch0_src2_ready_i ||",
        "dispatch1_src1_ready_i ||",
        "dispatch1_src2_ready_i ||",
        "src1_ready_q[reset_i] ||",
        "src2_ready_q[reset_i] ||",
    ):
        require(owner in iq, f"sticky collision capture missing: {owner}")
    require("[IQ-INT-WAKE-STICKY-ONLY]" in iq, "IQ sticky assertion marker missing")

    for port in ("read0", "read1", "read2", "read3", "read8"):
        require(f"assign {port}_data_o" in prf, f"PRF {port} assignment missing")
        require(
            f"regs_q[{port}_addr_i]" in prf,
            f"PRF {port} no longer reads registered state",
        )
    require(
        "[PRF-INT-READ-STORED-ONLY]" in prf,
        "PRF stored-only assertion marker missing",
    )

    report = {
        "status": "PASS",
        "files": {name: str(path.relative_to(ROOT)) for name, path in FILES.items()},
        "forbidden_tokens_absent": list(forbidden),
        "iq_integer_wakeup_match_sites": int_wakeup_sites,
        "formal_wb_state_boundary": True,
        "iq_sticky_only": True,
        "prf_stored_only": True,
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
