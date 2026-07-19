#!/usr/bin/env python3
"""Fail closed until the S2-Q1 leaf is a single, registered, auditable target."""

from __future__ import annotations

import os
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]

RTL = REPO_ROOT / "npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
FILELIST = REPO_ROOT / "npc/rv64/vsrc/filelist.mk"
TB = REPO_ROOT / "npc/rv64/testbench/tests/tb_ooo_mmu_epoch_owner.sv"
TB_MAKEFILE = REPO_ROOT / "npc/rv64/testbench/Makefile"
SPEC = REPO_ROOT / "npc/rv64/design/specs/ooo-mmu-epoch-owner.md"
SPEC_INDEX = REPO_ROOT / "npc/rv64/design/specs/README.md"
DERIVATION = RUN_DIR / "s2-q1-mmu-epoch-owner-rtl-derivation.md"
CANONICAL_RUNNER = RUN_DIR / "run-s2-q1-mmu-epoch-owner-focused.sh"
V2_RUNNER = RUN_DIR / "run-s2-q1-mmu-epoch-owner-focused-v2.sh"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    rtl = read(RTL)
    filelist = read(FILELIST)
    tb = read(TB)
    makefile = read(TB_MAKEFILE)
    spec = read(SPEC)
    spec_index = read(SPEC_INDEX)
    derivation = read(DERIVATION)
    runner = read(CANONICAL_RUNNER)

    require(errors, rtl.startswith("`timescale 1ns/1ps\n"), "RTL lacks explicit timescale")
    require(errors, "if (full_quiet_w)" in rtl, "production FSM does not consume full_quiet_w")
    assert_pos = rtl.find("`ifdef OOO_ASSERT")
    state_legal_pos = rtl.find("wire state_legal_w")
    require(
        errors,
        assert_pos >= 0 and state_legal_pos > assert_pos,
        "state_legal_w is not scoped inside OOO_ASSERT",
    )

    require(
        errors,
        "mmu_epoch !== (expected_epoch - 2'b01)" in tb,
        "TB helper pre-increment epoch oracle is not exact",
    )
    require(
        errors,
        '$display("[PASS] tb_ooo_mmu_epoch_owner");' in tb,
        "TB lacks the shared module-harness exact PASS line",
    )

    require(
        errors,
        "RTL_OOO_MMU_EPOCH_OWNER := $(RTL_MEMORY_DIR)/OooMmuEpochOwner.v" in filelist,
        "shared filelist lacks the Q1 source variable",
    )
    require(
        errors,
        "$(RTL_OOO_MMU_EPOCH_OWNER) \\\n" in filelist,
        "RTL_CORE_SRCS lacks the Q1 source",
    )
    require(errors, "  tb_ooo_mmu_epoch_owner \\\n" in makefile, "module TESTS lacks Q1")
    require(
        errors,
        "TB_SRCS_tb_ooo_mmu_epoch_owner := tests/tb_ooo_mmu_epoch_owner.sv $(RTL_OOO_MMU_EPOCH_OWNER)"
        in makefile,
        "module source registry lacks Q1",
    )
    require(errors, "`ooo-mmu-epoch-owner`" in spec_index, "spec index lacks Q1")
    require(errors, "leaf implementation pending" not in spec, "spec status is still pending")
    require(errors, "pre_RTL" not in derivation, "derivation status is still pre_RTL")

    require(
        errors,
        "mmu_epoch_q + 2'b01;/mmu_epoch_q <= (\\\\&mmu_epoch_q)" in runner,
        "canonical runner still has the malformed saturating mutation",
    )
    require(errors, "mutation_markers=(" in runner, "runner lacks per-mutant exact oracles")
    exact_mutation_messages = (
        "first request did not block capture in its presentation cycle",
        "quiet-low request advanced to grant",
        "live token did not block epoch grant",
        "full quiet did not expose the held grant before epoch advance",
        "second request overwrote or bypassed backpressured grant A",
        "grant A did not hold for first backpressure cycle",
        "quiet helper grant did not consume exactly once and advance epoch",
    )
    for message in exact_mutation_messages:
        require(errors, message in runner, f"runner lacks exact mutation oracle: {message}")
    require(errors, "negative_tb_sha256=" in runner, "summary lacks negative-TB hash")
    require(errors, "runner_sha256=" in runner, "summary lacks runner hash")
    require(errors, "iverilog_version=" in runner, "summary lacks Icarus version")
    require(errors, "verilator_release_lint=PASS" in runner, "runner lacks release lint evidence")
    require(errors, "verilator_assert_lint=PASS" in runner, "runner lacks assert lint evidence")
    require(errors, "rtl_style=PASS" in runner, "runner lacks RTL style evidence")
    require(errors, "yosys_check=PASS" in runner, "runner lacks Yosys evidence")
    require(errors, os.access(CANONICAL_RUNNER, os.X_OK), "canonical runner is not executable")
    require(errors, not V2_RUNNER.exists(), "ambiguous v2 runner still exists")

    if errors:
        for error in errors:
            print(f"[S2-Q1-ADOPTION][RED] {error}")
        print(f"[S2-Q1-ADOPTION][FAIL] unresolved={len(errors)}")
        return 1

    print("[S2-Q1-ADOPTION][PASS] canonical/registry/oracle/lint evidence contract closed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
