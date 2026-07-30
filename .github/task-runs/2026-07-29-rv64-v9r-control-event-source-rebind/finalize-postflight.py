#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
EVIDENCE = RUN_DIR / "evidence"
PREFLIGHT = EVIDENCE / "preflight.json"
OUTPUT = EVIDENCE / "postflight.json"
LOG_DIR = EVIDENCE / "debt-rebind-logs"
ARCH_STABLE_TESTS = "arch-stable-currentness-tests"
HISTORICAL_TESTS = "historical-defect-backfill-tests"
TASK_LOCAL_TESTS = "task-local-workflow-tests"
V9O_INDEX_VERIFY = "v9o-index-final-verify"
SERIALIZE_VERIFY = "serialize-g1-final-verify"
ARCH_STABLE_EXPECTED_TESTS = 48
HISTORICAL_EXPECTED_TESTS = 4
TASK_LOCAL_EXPECTED_TESTS = 20


def sha(relative: str) -> str:
    return hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()


def parse_unittest_receipt(
    *,
    name: str,
    log_text: str,
    rc_text: str,
    expected_tests: int,
) -> int:
    if rc_text.strip() != "0":
        raise RuntimeError(f"{name} receipt rc is not zero")
    matches = re.findall(
        r"(?m)^Ran ([0-9]+) tests? in [0-9.]+s$",
        log_text,
    )
    if len(matches) != 1:
        raise RuntimeError(f"{name} receipt has no unique unittest count")
    actual_tests = int(matches[0])
    if actual_tests != expected_tests:
        raise RuntimeError(
            f"{name} test count drifted: "
            f"expected={expected_tests} actual={actual_tests}"
        )
    if (
        re.search(r"(?m)^(FAILED|ERROR)\b", log_text)
        or "Traceback (most recent call last)" in log_text
        or not re.search(r"(?m)^OK$", log_text)
    ):
        raise RuntimeError(f"{name} receipt lacks an unambiguous OK terminal")
    return actual_tests


def artifact_receipt(path: pathlib.Path) -> dict[str, Any]:
    resolved = path.resolve(strict=True)
    relative = resolved.relative_to(ROOT.resolve()).as_posix()
    return {
        "path": relative,
        "sha256": hashlib.sha256(resolved.read_bytes()).hexdigest(),
        "size_bytes": resolved.stat().st_size,
    }


def require_unittest_receipt(
    name: str,
    expected_tests: int,
) -> dict[str, Any]:
    log_path = LOG_DIR / f"{name}.log"
    rc_path = LOG_DIR / f"{name}.rc"
    actual_tests = parse_unittest_receipt(
        name=name,
        log_text=log_path.read_text(encoding="utf-8"),
        rc_text=rc_path.read_text(encoding="utf-8"),
        expected_tests=expected_tests,
    )
    return {
        "name": name,
        "result": "PASS",
        "tests": actual_tests,
        "log": artifact_receipt(log_path),
        "rc": artifact_receipt(rc_path),
    }


def require_marker_receipt(
    name: str,
    markers: tuple[str, ...],
) -> dict[str, Any]:
    log_path = LOG_DIR / f"{name}.log"
    rc_path = LOG_DIR / f"{name}.rc"
    if rc_path.read_text(encoding="utf-8").strip() != "0":
        raise RuntimeError(f"{name} receipt rc is not zero")
    log_text = log_path.read_text(encoding="utf-8")
    missing = [marker for marker in markers if marker not in log_text]
    if missing:
        raise RuntimeError(
            f"{name} receipt markers are missing: {missing}"
        )
    return {
        "name": name,
        "result": "PASS",
        "markers": list(markers),
        "log": artifact_receipt(log_path),
        "rc": artifact_receipt(rc_path),
    }


def main() -> int:
    OUTPUT.write_text(
        json.dumps(
            {
                "schema": "npc-rv64-control-event-source-rebind-receipt-v1",
                "phase": "postflight",
                "result": "GAP",
                "reason": "validation_not_completed",
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    preflight = json.loads(PREFLIGHT.read_text(encoding="utf-8"))
    arch_path = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
    spec = importlib.util.spec_from_file_location(
        "v9r_rebind_final_arch", arch_path
    )
    assert spec and spec.loader
    arch = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = arch
    spec.loader.exec_module(arch)
    rtl_sha, rtl_files = arch.rtl_binding(ROOT)
    design_id = f"sha256:{rtl_sha}"
    if design_id != preflight["design_id"]:
        raise RuntimeError(
            f"RTL design drifted: pre={preflight['design_id']} "
            f"post={design_id}"
        )

    currentness_path = (
        ROOT
        / ".github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay"
        / "closed-evidence-currentness.json"
    )
    currentness = json.loads(currentness_path.read_text(encoding="utf-8"))
    if currentness.get("status") != "PASS" or currentness.get("failures") != []:
        raise RuntimeError("closed-debt semantic currentness is not PASS")

    v9r_path = (
        ROOT
        / ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff"
        / "evidence/summary.json"
    )
    v9r = json.loads(v9r_path.read_text(encoding="utf-8"))
    if not (
        v9r.get("result") == "PASS"
        and v9r.get("design_id") == design_id
        and v9r.get("baseline", {}).get("passed") == 2
        and len(v9r.get("compile_success_rtl_variants", [])) == 3
        and all(
            row.get("result") == "REJECTED"
            for row in v9r["compile_success_rtl_variants"]
        )
    ):
        raise RuntimeError("V9R current-source evidence is incomplete")

    arch_tests = require_unittest_receipt(
        ARCH_STABLE_TESTS,
        ARCH_STABLE_EXPECTED_TESTS,
    )
    historical_tests = require_unittest_receipt(
        HISTORICAL_TESTS,
        HISTORICAL_EXPECTED_TESTS,
    )
    task_local_tests = require_unittest_receipt(
        TASK_LOCAL_TESTS,
        TASK_LOCAL_EXPECTED_TESTS,
    )
    index_verify = require_marker_receipt(
        V9O_INDEX_VERIFY,
        (
            "[V9O-EVIDENCE-INDEX-VERIFY]",
            f"design_id={design_id}",
            "artifacts=167",
            "status=PASS",
        ),
    )
    serialize_verify = require_marker_receipt(
        SERIALIZE_VERIFY,
        (
            "[SERIALIZE-G1-VERIFY]",
            f"design_id={design_id}",
            "a3=FAIL+execution_COMPLETE+oracle_INVALID",
            "arch_stable=GAP ppa=UNQUALIFIED PASS",
        ),
    )

    files = (
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
        "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
        ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence-index.json",
        ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/evidence/summary.json",
        ".github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/closed-evidence-currentness.json",
        "npc/rv64/design/arch/architecture-debt-ledger.json",
        "npc/rv64/design/arch/historical-defect-backfill-ledger.json",
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/arch-stable-currentness-tests.log"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/arch-stable-currentness-tests.rc"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/task-local-workflow-tests.log"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/task-local-workflow-tests.rc"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/historical-defect-backfill-tests.log"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/historical-defect-backfill-tests.rc"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/v9o-index-final-verify.log"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/v9o-index-final-verify.rc"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/serialize-g1-final-verify.log"
        ),
        (
            ".github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/"
            "evidence/debt-rebind-logs/serialize-g1-final-verify.rc"
        ),
    )
    payload = {
        "schema": "npc-rv64-control-event-source-rebind-receipt-v1",
        "phase": "postflight",
        "result": "PASS",
        "design_id": design_id,
        "rtl_file_count": len(rtl_files),
        "production_rtl_unchanged": all(
            preflight["files"][relative] == sha(relative)
            for relative in (
                "npc/rv64/vsrc/execute/OooIntBackend.v",
                "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
            )
        ),
        "v9r_baseline": "2/2",
        "v9r_compile_success_variants": "3/3 rejected",
        "validation_receipts": {
            "arch_stable_currentness": arch_tests,
            "historical_defect_backfill": historical_tests,
            "task_local_workflow": task_local_tests,
            "v9o_index_verify": index_verify,
            "serialize_g1_verify": serialize_verify,
        },
        "closed_debt_currentness": {
            "closed_count": currentness["closed_count"],
            "artifact_count": currentness["artifact_count"],
            "canonical_semantic_check_count": currentness[
                "canonical_semantic_check_count"
            ],
            "failures": 0,
        },
        "files": {relative: sha(relative) for relative in files},
    }
    if payload["production_rtl_unchanged"] is not True:
        raise RuntimeError("V9R production RTL changed during verification replay")
    OUTPUT.write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "[V9R-CURRENT-SOURCE-REBIND][PASS] "
        f"design_id={design_id} production_rtl_unchanged=true "
        f"closed={currentness['closed_count']} "
        f"artifacts={currentness['artifact_count']} failures=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
