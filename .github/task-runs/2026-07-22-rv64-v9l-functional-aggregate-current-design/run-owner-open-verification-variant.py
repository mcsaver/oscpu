#!/usr/bin/env python3
"""Run one compile-success local RTL verification variant for V9L SQ ownership."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design"
VARIANT = TASK / "owner-open-verification-variant"
SOURCE = ROOT / "npc/rv64/vsrc/memory/OooStoreQueue.v"
MUTATED = VARIANT / "OooStoreQueue.v"
RESULT = VARIANT / "result"
BUILD = VARIANT / "build"

OLD = """            ((!rob_head_valid_i) || (!rob_head_owner_open_i) ||
"""
NEW = """            ((!rob_head_valid_i) || (!rob_head_launch_open_i) ||
"""


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if VARIANT.exists():
        resolved = VARIANT.resolve()
        resolved.relative_to(TASK.resolve())
        shutil.rmtree(resolved)
    VARIANT.mkdir(parents=True)

    text = SOURCE.read_text(encoding="utf-8")
    if text.count(OLD) != 1:
        raise SystemExit("[V9L-OWNER-VARIANT][FAIL] expected one owner-open assertion anchor")
    MUTATED.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")

    command = [
        "make", "-B", "-C", str(ROOT / "npc/rv64/testbench"),
        "TESTS=tb_ooo_store_queue",
        f"RTL_OOO_STORE_QUEUE={MUTATED}",
        f"BUILD_DIR={BUILD}", f"RESULT_DIR={RESULT}", "run",
    ]
    completed = subprocess.run(
        command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, check=False)
    (VARIANT / "command.log").write_text(completed.stdout, encoding="utf-8")
    test_log = RESULT / "logs/tb_ooo_store_queue.log"
    log_text = test_log.read_text(encoding="utf-8") if test_log.is_file() else ""
    rejected = (
        completed.returncode != 0
        and "[COMPILE]" in log_text
        and "[V9L-SQ-POST-LAUNCH-OWNER]" in log_text
        and "[RESULT] FAIL" in log_text
    )
    summary = {
        "schema": "rv64-v9l-owner-open-verification-variant-v1",
        "scope": "local RV64 SystemVerilog Store Queue post-launch owner assertion",
        "variant": "replace post-launch owner-open check with first-launch admission check",
        "source_sha256": sha256(SOURCE),
        "variant_sha256": sha256(MUTATED),
        "compile_succeeded": "[COMPILE]" in log_text and "syntax error" not in log_text,
        "simulation_rejected_variant": rejected,
        "return_code": completed.returncode,
        "test_log": test_log.relative_to(ROOT).as_posix(),
    }
    (VARIANT / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    if not rejected:
        print("[V9L-OWNER-VARIANT][FAIL] verification variant was not rejected")
        return 1
    print("[V9L-OWNER-VARIANT][PASS] compile-success RTL verification variant rejected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
