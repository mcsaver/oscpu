#!/usr/bin/env python3
"""Replay RV64 debt checkers from frozen module and RTL-variant evidence."""

from __future__ import annotations

import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[3]
RUN_DIR = pathlib.Path(__file__).resolve().parent
OUT_DIR = RUN_DIR / "checker-bound-evidence-replay"
LOG_DIR = OUT_DIR / "logs"
SUMMARY = OUT_DIR / "summary.json"
EXPECTED_DESIGN_ID = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact(relative: str) -> dict[str, Any]:
    path = (ROOT / relative).resolve(strict=True)
    path.relative_to(ROOT.resolve())
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"not a regular RV64 evidence file: {relative}")
    return {
        "path": relative,
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def design_id() -> str:
    sys.path.insert(0, str(ROOT / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture

    value, files = architecture.rtl_binding(ROOT)
    if not files:
        raise RuntimeError("RV64 RTL source set is empty")
    return f"sha256:{value}"


def command(tool: str, *arguments: str) -> list[str]:
    return [
        "python3",
        str(ROOT / "npc/rv64/eval/ppa/tools" / tool),
        "--root",
        str(ROOT),
        *arguments,
    ]


STAGES: tuple[dict[str, Any], ...] = (
    {
        "id": "fdg-arch-trap",
        "inputs": (
            ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
            "evidence/module-aggregate/logs/"
            "tb_ooo_fp_legality_dispatch_path.log",
            ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
            "evidence/module-aggregate/logs/tb_ooo_priv_system.log",
            ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json",
            "npc/rv64/eval/ppa/evidence/fdg-arch-trap.log",
        ),
        "command": command(
            "fdg_arch_trap_evidence.py",
            "--focused-log",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
                "evidence/module-aggregate/logs/"
                "tb_ooo_fp_legality_dispatch_path.log"
            ),
            "--program-log",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
                "evidence/module-aggregate/logs/tb_ooo_priv_system.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--mutation-summary",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(ROOT / "npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json"),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/fdg-arch-trap.log"),
        ),
    },
    {
        "id": "xret-current-mode",
        "inputs": (
            ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
            "evidence/module-aggregate/logs/"
            "tb_ooo_fetch_head_classify_gate.log",
            ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
            "evidence/module-aggregate/logs/tb_ooo_priv_system.log",
            ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/xret-current-mode-current.json",
            "npc/rv64/eval/ppa/evidence/xret-current-mode.log",
        ),
        "command": command(
            "xret_current_mode_evidence.py",
            "--focused-log",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
                "evidence/module-aggregate/logs/"
                "tb_ooo_fetch_head_classify_gate.log"
            ),
            "--program-log",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
                "evidence/module-aggregate/logs/tb_ooo_priv_system.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--mutation-summary",
            str(
                ROOT
                / ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "xret-current-mode-current.json"
            ),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/xret-current-mode.log"),
        ),
    },
    {
        "id": "memory-issue-lifecycle",
        "inputs": (
            ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/"
            "evidence/focused/mem-issue/logs/tb_ooo_int_backend.log",
            ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/"
            "evidence/focused/miq-flush/logs/"
            "tb_ooo_mem_inflight_queue.log",
            ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/"
            "memory-issue-lifecycle-current.json",
            "npc/rv64/eval/ppa/evidence/memory-issue-lifecycle.log",
        ),
        "command": command(
            "memory_issue_lifecycle_evidence.py",
            "--mem-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9f-memory-issue-lifecycle/"
                "evidence/focused/mem-issue/logs/tb_ooo_int_backend.log"
            ),
            "--miq-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9f-memory-issue-lifecycle/"
                "evidence/focused/miq-flush/logs/"
                "tb_ooo_mem_inflight_queue.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9f-memory-issue-lifecycle/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--mutation-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9f-memory-issue-lifecycle/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "memory-issue-lifecycle-current.json"
            ),
            "--raw-log",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "memory-issue-lifecycle.log"
            ),
        ),
    },
    {
        "id": "ifu-axi-flush-drain",
        "inputs": (
            ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_axi_bridge.log",
            ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_axi_bridge_xbar.log",
            ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
            "evidence/focused/logs/tb_axi_xbar.log",
            ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/"
            "ifu-axi-flush-drain-current.json",
            "npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log",
        ),
        "command": command(
            "ifu_axi_flush_drain_evidence.py",
            "--bridge-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9g-ifu-axi-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_axi_bridge.log"
            ),
            "--xbar-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9g-ifu-axi-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_axi_bridge_xbar.log"
            ),
            "--generic-xbar-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9g-ifu-axi-current-design/"
                "evidence/focused/logs/tb_axi_xbar.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9g-ifu-axi-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9g-ifu-axi-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "ifu-axi-flush-drain-current.json"
            ),
            "--raw-log",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "ifu-axi-flush-drain.log"
            ),
        ),
    },
    {
        "id": "ifu-fetch-provenance",
        "inputs": (
            ".github/task-runs/"
            "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_packet_decode.log",
            ".github/task-runs/"
            "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_page_end_fault.log",
            ".github/task-runs/"
            "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/"
            "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/"
            "ifu-fetch-provenance-current.json",
            "npc/rv64/eval/ppa/evidence/ifu-fetch-provenance.log",
        ),
        "command": command(
            "ifu_fetch_provenance_evidence.py",
            "--decode-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_packet_decode.log"
            ),
            "--page-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_page_end_fault.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "ifu-fetch-provenance-current.json"
            ),
            "--raw-log",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "ifu-fetch-provenance.log"
            ),
        ),
    },
    {
        "id": "ifu-access",
        "inputs": (
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_access_footprint.log",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_axi_access_attrs.log",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/focused/logs/tb_axi_exec_firewall.log",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/sized-dpi/run.log",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/ifu-access-current.json",
            "npc/rv64/eval/ppa/evidence/ifu-access.log",
        ),
        "command": command(
            "ifu_access_evidence.py",
            "--footprint-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_access_footprint.log"
            ),
            "--attrs-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_axi_access_attrs.log"
            ),
            "--firewall-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/focused/logs/tb_axi_exec_firewall.log"
            ),
            "--lane-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log"
            ),
            "--dpi-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/sized-dpi/run.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9i-ifu-access-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ifu-access-current.json"),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ifu-access.log"),
        ),
    },
    {
        "id": "ifu-tval",
        "inputs": (
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_packet_decode.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_page_end_fault.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_packet_fifo.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_pending_lane1_capture_gate.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_pending_dispatch_arbiter.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_pending_trap_exit_sequencer.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_csr_trap_request_mux.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/ifu-tval-current.json",
            "npc/rv64/eval/ppa/evidence/ifu-tval.log",
        ),
        "command": command(
            "ifu_tval_evidence.py",
            "--decoder-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_packet_decode.log"
            ),
            "--page-end-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_page_end_fault.log"
            ),
            "--fifo-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_packet_fifo.log"
            ),
            "--capture-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/"
                "tb_ooo_pending_lane1_capture_gate.log"
            ),
            "--arbiter-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/"
                "tb_ooo_pending_dispatch_arbiter.log"
            ),
            "--pending-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/"
                "tb_ooo_pending_trap_exit_sequencer.log"
            ),
            "--csr-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/tb_ooo_csr_trap_request_mux.log"
            ),
            "--lifecycle-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9j-ifu-tval-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ifu-tval-current.json"),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ifu-tval.log"),
        ),
    },
    {
        "id": "ptw-pmp",
        "inputs": (
            ".github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/"
            "evidence/focused/logs/tb_ooo_fetch_axi_bridge.log",
            ".github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/"
            "evidence/focused/logs/tb_ooo_mem_axi_bridge.log",
            ".github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/"
            "evidence/mutations/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json",
            "npc/rv64/eval/ppa/evidence/ptw-pmp.log",
        ),
        "command": command(
            "ptw_pmp_evidence.py",
            "--ifu-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9k-ptw-pmp-current-design/"
                "evidence/focused/logs/tb_ooo_fetch_axi_bridge.log"
            ),
            "--lsu-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9k-ptw-pmp-current-design/"
                "evidence/focused/logs/tb_ooo_mem_axi_bridge.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9k-ptw-pmp-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-22-rv64-v9k-ptw-pmp-current-design/"
                "evidence/mutations/summary.json"
            ),
            "--output",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json"),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/ptw-pmp.log"),
        ),
    },
    {
        "id": "fence-ordering",
        "inputs": (
            ".github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/"
            "evidence/focused/logs/tb_ooo_priv_system.log",
            ".github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/"
            "evidence/focused/logs/tb_ooo_pending_drain_resolve_gate.log",
            ".github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/"
            "evidence/module-aggregate/summary.txt",
            ".github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/"
            "evidence/rtl-variants/summary.json",
        ),
        "outputs": (
            "npc/rv64/eval/ppa/evidence/fence-ordering-current.json",
            "npc/rv64/eval/ppa/evidence/fence-ordering.log",
        ),
        "command": command(
            "fence_ordering_evidence.py",
            "--program-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-23-rv64-v9m-fence-ordering-current-design/"
                "evidence/focused/logs/tb_ooo_priv_system.log"
            ),
            "--drain-gate-log",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-23-rv64-v9m-fence-ordering-current-design/"
                "evidence/focused/logs/"
                "tb_ooo_pending_drain_resolve_gate.log"
            ),
            "--module-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-23-rv64-v9m-fence-ordering-current-design/"
                "evidence/module-aggregate/summary.txt"
            ),
            "--variant-summary",
            str(
                ROOT
                / ".github/task-runs/"
                "2026-07-23-rv64-v9m-fence-ordering-current-design/"
                "evidence/rtl-variants/summary.json"
            ),
            "--output",
            str(
                ROOT
                / "npc/rv64/eval/ppa/evidence/"
                "fence-ordering-current.json"
            ),
            "--raw-log",
            str(ROOT / "npc/rv64/eval/ppa/evidence/fence-ordering.log"),
        ),
    },
)


def write_summary(payload: dict[str, Any]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    SUMMARY.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    design_before = design_id()
    if design_before != EXPECTED_DESIGN_ID:
        raise RuntimeError(
            f"unexpected RV64 design id: {design_before}")

    input_paths = sorted({
        relative for stage in STAGES for relative in stage["inputs"]
    })
    before = {relative: artifact(relative) for relative in input_paths}
    stage_results: list[dict[str, Any]] = []

    try:
        for stage in STAGES:
            log_path = LOG_DIR / f"{stage['id']}.log"
            with log_path.open("wb") as log:
                completed = subprocess.run(
                    stage["command"],
                    cwd=ROOT,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
            result = {
                "id": stage["id"],
                "returncode": completed.returncode,
                "log": artifact(
                    log_path.relative_to(ROOT).as_posix()),
            }
            stage_results.append(result)
            if completed.returncode != 0:
                raise RuntimeError(
                    f"{stage['id']} checker replay returned "
                    f"{completed.returncode}")

        after = {relative: artifact(relative) for relative in input_paths}
        design_after = design_id()
        inputs_unchanged = before == after
        outputs = {
            relative: artifact(relative)
            for stage in STAGES
            for relative in stage["outputs"]
        }
        status = (
            "PASS"
            if (
                inputs_unchanged
                and design_after == design_before
                and len(stage_results) == len(STAGES)
                and all(row["returncode"] == 0 for row in stage_results)
            )
            else "GAP"
        )
        payload = {
            "schema": "npc-rv64-v10g-checker-bound-evidence-replay-v1",
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": status,
            "design_id_before": design_before,
            "design_id_after": design_after,
            "frozen_inputs_unchanged": inputs_unchanged,
            "stages_required": len(STAGES),
            "stages_passed": sum(
                row["returncode"] == 0 for row in stage_results),
            "stage_results": stage_results,
            "frozen_inputs": before,
            "derived_outputs": outputs,
            "claim_boundary": {
                "production_rtl_semantics_changed": False,
                "module_simulation_rerun": False,
                "system_simulation_rerun": False,
                "architecture_freeze": "GAP",
                "ppa": "UNQUALIFIED",
            },
        }
        write_summary(payload)
        print(
            "[V10G-CHECKER-REPLAY] "
            f"design_id={design_after} "
            f"stages={payload['stages_passed']}/{len(STAGES)} "
            f"inputs_unchanged={str(inputs_unchanged).lower()} "
            f"status={status}"
        )
        return 0 if status == "PASS" else 1
    except Exception as exc:
        write_summary({
            "schema": "npc-rv64-v10g-checker-bound-evidence-replay-v1",
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": "GAP",
            "design_id_before": design_before,
            "stages_required": len(STAGES),
            "stages_completed": len(stage_results),
            "stage_results": stage_results,
            "error": str(exc),
        })
        raise


if __name__ == "__main__":
    raise SystemExit(main())
