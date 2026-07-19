#!/usr/bin/env python3
"""Fail-closed structural contract for the disabled Q1A abort-priority leaf."""

from __future__ import annotations

import os
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
RTL = REPO_ROOT / "npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
TB = REPO_ROOT / "npc/rv64/testbench/tests/tb_ooo_mmu_epoch_owner.sv"
NEGATIVE_TB = RUN_DIR / "tb_q1a_abort_assert_negative.sv"
MUTATOR = RUN_DIR / "mutate_q1a.py"
RUNNER = RUN_DIR / "run-q1a-abort-priority.sh"
SPEC = REPO_ROOT / "npc/rv64/design/specs/ooo-mmu-epoch-owner.md"
MAKEFILE = REPO_ROOT / "npc/rv64/Makefile"
CONTRACT = RUN_DIR / "q1a-abort-priority-contract.md"
IDENTITY_REVIEW = RUN_DIR / "full-identity-reuse-counterexample-review.md"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    rtl = read(RTL)
    tb = read(TB)
    negative_tb = read(NEGATIVE_TB)
    mutator = read(MUTATOR)
    runner = read(RUNNER)
    spec = read(SPEC)
    makefile = read(MAKEFILE)
    contract = read(CONTRACT)
    identity_review = read(IDENTITY_REVIEW)

    require(errors, "input wire abort_valid_i," in rtl, "abort_valid_i is not an input port")
    require(
        errors,
        "assign capture_block_o = abort_valid_i || abort_rearm_q ||\n"
        "      ((state_q != ST_UNLOCKED) || request_valid_i);" in rtl,
        "capture block is not the exact abort/rearm/request/state look-ahead",
    )
    require(
        errors,
        "assign request_ready_o = parameter_shape_valid_w &&\n"
        "      (state_q == ST_UNLOCKED) && request_cause_valid_w &&\n"
        "      !abort_valid_i && !abort_rearm_q;" in rtl,
        "request ready does not contain the exact abort/rearm mask",
    )
    require(
        errors,
        "assign grant_valid_o = (state_q == ST_COMMIT) && !abort_valid_i;" in rtl,
        "grant valid does not contain the exact abort mask",
    )
    abort_pos = rtl.find("end else if (abort_valid_i) begin")
    case_pos = rtl.find("case (state_q)")
    require(errors, 0 <= abort_pos < case_pos, "abort branch does not dominate the state case")
    abort_end = rtl.find("end else begin", abort_pos + 1)
    require(errors, abort_end > abort_pos, "abort branch boundary is missing")
    if abort_end > abort_pos:
        abort_body = rtl[abort_pos:abort_end]
        require(errors, "state_q <= ST_UNLOCKED;" in abort_body, "abort does not clear state")
        require(errors, "held_cause_q <= {CAUSE_W{1'b0}};" in abort_body, "abort does not clear cause")
        require(errors, "held_payload_q <= {PAYLOAD_W{1'b0}};" in abort_body, "abort does not clear payload")
        require(errors, "abort_rearm_q <= request_valid_i;" in abort_body,
                "abort does not retain a continuous cancelled request until valid-low")
        require(errors, "mmu_epoch_q <=" not in abort_body, "abort writes epoch")

    require(errors, rtl.count("mmu_epoch_q <=") == 2,
            "epoch owner must have exactly reset and grant-fire sequential writes")
    inactive_instances = []
    for source in sorted((REPO_ROOT / "npc/rv64/vsrc").rglob("*.v")):
        if source != RTL and "OooMmuEpochOwner" in read(source):
            inactive_instances.append(str(source.relative_to(REPO_ROOT)))
    require(errors, not inactive_instances,
            "source-catalog leaf unexpectedly has a live RTL reference: " +
            ",".join(inactive_instances))

    for marker in (
        "[MMU-EPOCH-ABORT-MASK]",
        "[MMU-EPOCH-ABORT-REARM]",
        "[MMU-EPOCH-ABORT-CLEAR]",
    ):
        require(errors, marker in rtl, f"RTL lacks assertion marker {marker}")
    for oracle in (
        "idle abort did not immediately block capture",
        "abort and request raced into a visible handshake",
        "aborted request was recaptured without a valid-low rearm",
        "drain abort did not clear held bundle/state",
        "abort did not suppress a ready grant in its presentation cycle",
        "backpressure abort failed to clear without epoch advance",
    ):
        require(errors, oracle in tb, f"positive TB lacks abort oracle: {oracle}")
    require(
        errors,
        '[MMU-EPOCH-Q1A][PASS] abort-idle/drain/commit/backpressure/epoch-stable' in tb,
        "positive TB lacks the exact Q1A PASS marker",
    )
    require(
        errors,
        '[MMU-EPOCH-Q1A-REARM][PASS] continuous-valid-blocked-until-valid-low' in tb,
        "positive TB lacks the exact Q1A rearm PASS marker",
    )
    require(errors, "5: begin" in negative_tb, "negative TB lacks abort assertion case")
    require(errors, "force dut.request_ready_o = 1'b1;" in negative_tb, "abort assertion case is not non-vacuous")

    mutation_names = (
        "no-lookahead",
        "no-quiet",
        "no-live-empty",
        "ready-dependent-grant",
        "live-input-payload",
        "advance-before-consume",
        "saturating-epoch",
        "no-abort-lookahead",
        "no-abort-ready-mask",
        "no-abort-grant-mask",
        "low-abort-priority",
        "abort-advances-epoch",
        "no-abort-rearm",
    )
    for name in mutation_names:
        require(errors, f'"{name}"' in mutator, f"mutator lacks {name}")
        require(errors, name in runner, f"runner does not execute {name}")
    require(errors, "expected one source match" in mutator, "mutator is not exact-count fail closed")
    require(errors, "compile_success_mutations=13/13" in runner, "summary does not bind 13 mutations")
    require(errors, "assertion_negative=5/5" in runner, "summary does not bind 5 assertion negatives")

    require(errors, "abort > grant/normal > hold" in spec, "spec lacks abort priority")
    require(errors, "live integration RED" in spec, "spec overclaims live integration")
    require(errors, "shared registered event" in spec, "spec lacks shared abort ownership")
    require(errors, "Q1A abort-priority source-catalog GREEN / live integration RED" in contract,
            "scoped contract status is missing")
    require(errors, "abort 后若旧 request 连续保持 valid" in contract,
            "contract omits post-abort stale-request ownership")
    require(errors, "sticky/irrevocable completion" in contract,
            "contract does not freeze transaction-scoped quiet completion")
    require(errors, "禁止回灌本 request producer" in contract,
            "contract does not forbid a capture-block/request-valid combinational loop")
    require(errors, "F(k) = 1 + 2 * F(k - 1)" in identity_review,
            "identity review lacks the nested-recovery recurrence")
    require(errors, "PRF write" in identity_review and "wakeup" in identity_review,
            "identity review omits non-ROB stale-WB side effects")
    require(
        errors,
        ".PHONY: check-q1a-abort-priority" in makefile and
        "run-q1a-abort-priority.sh" in makefile,
        "Makefile lacks the canonical Q1A entry point",
    )
    require(errors, os.access(RUNNER, os.X_OK), "Q1A runner is not executable")
    require(errors, os.access(MUTATOR, os.X_OK), "Q1A mutator is not executable")

    if errors:
        for error in errors:
            print(f"[S2-Q1A-CONTRACT][RED] {error}")
        print(f"[S2-Q1A-CONTRACT][FAIL] unresolved={len(errors)}")
        return 1
    print("[S2-Q1A-CONTRACT][PASS] abort mask/priority/clear/oracles/workflow locked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
