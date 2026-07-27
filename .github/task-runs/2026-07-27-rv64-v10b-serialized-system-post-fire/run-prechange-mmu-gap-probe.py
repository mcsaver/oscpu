#!/usr/bin/env python3
"""Prove that the pre-V10B program TB does not observe the FENCE.I MMU pulse."""

from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO = RUN_DIR.parents[2]
TESTBENCH = REPO / "npc/rv64/testbench"
RTL = REPO / "npc/rv64/vsrc/memory/OooMemoryAccess.v"
TB = TESTBENCH / "tests/tb_ooo_priv_system.sv"
OUT = RUN_DIR / "evidence/prechange-mmu-observation-gap"
REPORT = OUT / "report.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_case(name: str, memory_access: Path | None) -> dict[str, object]:
    result_dir = OUT / name
    build_dir = result_dir / "build"
    log = result_dir / "logs/tb_ooo_priv_system.log"
    command = [
        "make",
        "-C",
        str(TESTBENCH),
        f"RESULT_DIR={result_dir}",
        f"BUILD_DIR={build_dir}",
    ]
    if memory_access is not None:
        command.append(f"RTL_OOO_MEMORY_ACCESS={memory_access}")
    command.append(str(log))
    completed = subprocess.run(
        command,
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    output_log = OUT / f"{name}-make.log"
    output_log.parent.mkdir(parents=True, exist_ok=True)
    output_log.write_text(completed.stdout, encoding="utf-8")
    log_text = log.read_text(encoding="utf-8") if log.exists() else ""
    return {
        "name": name,
        "command": command,
        "returncode": completed.returncode,
        "result_log": str(log.relative_to(REPO)),
        "make_log": str(output_log.relative_to(REPO)),
        "result_pass": "[RESULT] PASS" in log_text,
        "tb_pass": "PASS tb_ooo_priv_system" in log_text,
    }


def main() -> int:
    if REPORT.exists():
        raise SystemExit(
            f"refusing to overwrite immutable prechange evidence: {REPORT}"
        )

    OUT.mkdir(parents=True, exist_ok=True)
    original = RTL.read_text(encoding="utf-8")
    old = (
        ".pending_system_fencei_commit_i("
        "pending_system_fencei_commit_w),"
    )
    new = ".pending_system_fencei_commit_i(1'b0),"
    if original.count(old) != 1:
        raise SystemExit(
            "expected exactly one production FENCE.I MMU connection"
        )
    mutated_text = original.replace(old, new)
    mutated = OUT / "mutated/OooMemoryAccess.v"
    mutated.parent.mkdir(parents=True, exist_ok=True)
    mutated.write_text(mutated_text, encoding="utf-8")

    baseline = run_case("baseline", None)
    mutation = run_case("fencei-mmu-disconnected", mutated)
    report = {
        "schema": "rv64-v10b-prechange-mmu-observation-gap-v1",
        "purpose": (
            "Demonstrate that the pre-V10B production-glue program TB can "
            "remain GREEN after the FENCE.I MMU action is disconnected."
        ),
        "immutable_prechange": True,
        "production_rtl": str(RTL.relative_to(REPO)),
        "production_rtl_sha256": sha256(RTL),
        "testbench": str(TB.relative_to(REPO)),
        "testbench_sha256": sha256(TB),
        "mutated_rtl": str(mutated.relative_to(REPO)),
        "mutated_rtl_sha256": sha256(mutated),
        "mutation": {
            "from": old,
            "to": new,
            "compile_success_required": True,
            "prechange_expected_result": "PASS",
        },
        "baseline": baseline,
        "mutation_result": mutation,
        "gap_proven": bool(
            baseline["returncode"] == 0
            and baseline["result_pass"]
            and mutation["returncode"] == 0
            and mutation["result_pass"]
        ),
    }
    REPORT.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if not report["gap_proven"]:
        print("[V10B-PRECHANGE-MMU-OBSERVATION-GAP] FAIL")
        return 1
    print(
        "[V10B-PRECHANGE-MMU-OBSERVATION-GAP] "
        "baseline=PASS fencei-mmu-disconnected=PASS gap=PROVEN"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
