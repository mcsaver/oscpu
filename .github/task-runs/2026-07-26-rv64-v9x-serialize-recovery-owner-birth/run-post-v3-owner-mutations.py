#!/usr/bin/env python3
"""Run compile-success V9X owner-transition RTL variants."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile


RUN_DIR = pathlib.Path(__file__).resolve().parent
REPO_ROOT = pathlib.Path(
    subprocess.check_output(
        ["git", "-C", str(RUN_DIR), "rev-parse", "--show-toplevel"],
        text=True,
    ).strip()
)
SOURCE = REPO_ROOT / "npc/rv64/vsrc/control/OooControlPlane.v"
OUTPUT = RUN_DIR / "evidence/post-v3/owner-mutations"


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def mutate_exact(text: str, old: str, new: str, case: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{case}: expected one mutation site, found {count}")
    return text.replace(old, new, 1)


CASES = (
    {
        "name": "drop-trap-exit-c1-reset",
        "old": "    .rst(rst || flush_i || core_local_flush_w),",
        "new": "    .rst(rst || flush_i),",
        "expected_check": (
            "[CHECK-FAIL] V9X C1 clears pre-ROB exit holder"
        ),
    },
    {
        "name": "reconstruct-qcsr-birth-from-merged-fire",
        "old": """  wire v9x_head0_csr_owner_birth_w =
      head0_csr_dispatch_fire_w &&
      !v9x_head0_csr_owner_kill_w &&
      !core_local_flush_w &&
      !head0_csr_commit_w;""",
        "new": """  wire v9x_head0_csr_owner_birth_w =
      `OOO_CSR_QUEUE_HEAD &&
      core_dispatch0_fire_w &&
      dispatch0_facts_w[`OOO_SLOT_FACT_CSR] &&
      !head0_csr_illegal_w &&
      !v9x_head0_csr_owner_kill_w &&
      !core_local_flush_w &&
      !head0_csr_commit_w;""",
        "expected_check": (
            "[CHECK-FAIL] V9X merged fire cannot alias queue-head owner birth"
        ),
    },
)


def run_case(case: dict[str, str], production_sha: str) -> dict[str, object]:
    case_dir = OUTPUT / case["name"]
    case_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix=f"v9x-{case['name']}-") as tmp:
        mutant_root = pathlib.Path(tmp) / "npc/rv64"
        shutil.copytree(REPO_ROOT / "npc/rv64/vsrc", mutant_root / "vsrc")
        mutant_control = mutant_root / "vsrc/control/OooControlPlane.v"
        mutated = mutate_exact(
            mutant_control.read_text(encoding="utf-8"),
            case["old"],
            case["new"],
            case["name"],
        )
        mutant_control.write_text(mutated, encoding="utf-8")
        preserved_mutant = case_dir / "OooControlPlane.v"
        shutil.copy2(mutant_control, preserved_mutant)

        build_dir = case_dir / "build"
        result_dir = case_dir / "results"
        log_path = (
            result_dir / "logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
        )
        command = [
            "make",
            "-B",
            "-C",
            str(REPO_ROOT / "npc/rv64/testbench"),
            f"NPC_SINGLE_HOME={mutant_root}",
            f"BUILD_DIR={build_dir}",
            f"RESULT_DIR={result_dir}",
            str(log_path),
        ]
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        (case_dir / "driver.log").write_text(
            completed.stdout, encoding="utf-8"
        )

    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    checks = {
        "make_returned_nonzero": completed.returncode != 0,
        "compile_command_recorded": "[COMPILE]" in log_text,
        "simulation_reached_final_v9p_marker": (
            "[V9P-CSR-JALR-CALLBACK-CHAIN]" in log_text
        ),
        "directed_oracle_fired": case["expected_check"] in log_text,
        "result_rejected": "[RESULT] FAIL" in log_text,
        "production_source_unchanged": sha256(SOURCE) == production_sha,
    }
    return {
        "name": case["name"],
        "command": command,
        "returncode": completed.returncode,
        "expected_check": case["expected_check"],
        "mutant_source": str(preserved_mutant.relative_to(REPO_ROOT)),
        "mutant_source_sha256": sha256(preserved_mutant),
        "log": str(log_path.relative_to(REPO_ROOT)),
        "log_sha256": sha256(log_path),
        "checks": checks,
        "rejected": all(checks.values()),
    }


def main() -> int:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    production_sha = sha256(SOURCE)
    results = [run_case(case, production_sha) for case in CASES]
    payload = {
        "schema": "npc-rv64-v9x-owner-transition-mutations-v1",
        "production_source": str(SOURCE.relative_to(REPO_ROOT)),
        "production_source_sha256_before": production_sha,
        "production_source_sha256_after": sha256(SOURCE),
        "cases": results,
        "passed": sum(1 for result in results if result["rejected"]),
        "total": len(results),
    }
    summary = OUTPUT / "summary.json"
    summary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    for result in results:
        state = "PASS" if result["rejected"] else "FAIL"
        print(
            f"[V9X-OWNER-MUTATION][{state}] "
            f"case={result['name']} rc={result['returncode']}"
        )
    print(f"[V9X-OWNER-MUTATION] summary={summary.relative_to(REPO_ROOT)}")
    return 0 if payload["passed"] == payload["total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
