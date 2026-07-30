#!/usr/bin/env python3
"""Run queue-head CSR focused TB through the product RTL fallback, no define."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shlex
import shutil
import subprocess


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
SOURCE = RUN_DIR / "product-default-qh-v2"
OUT = RUN_DIR / "product-default-qh-fallback-v1"
SUMMARY = OUT / "summary.json"
DEFINE = ROOT / "npc/rv64/vsrc/include/define.v"
MANIFEST = ROOT / "npc/rv64/configs/product-rtl-defaults.mk"
CURRENT_ID = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def compile_command(mode: str) -> list[str]:
    log = (
        SOURCE
        / mode
        / "logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
    )
    for line in log.read_text(encoding="utf-8").splitlines():
        if line.startswith("[COMPILE] "):
            command = shlex.split(line.removeprefix("[COMPILE] "))
            return [
                arg
                for arg in command
                if arg != "-DOOO_CSR_QUEUE_HEAD=1"
            ]
    raise RuntimeError(f"compile command missing: {log}")


def validate_markers(text: str) -> dict[str, int]:
    if "[CHECK-FAIL]" in text:
        raise AssertionError("queue-head fallback run contains CHECK-FAIL")
    committed = (
        "ecall handler queue-head CSR",
        "older-store queue-head CSR",
        "CSR/JALR callback chain",
    )
    killed = (
        "branch-recovery wrong-path CSR",
        "JALR-recovery wrong-path CSR",
    )
    for label in committed:
        marker = (
            f"[V10G-QH-CSR-RAW] {label} "
            "birth=1 C0_commit=1 C0_barrier=1 CsrFile_request=1 "
            "C1_apply=1 C2_quiet=1 PASS"
        )
        if text.count(marker) != 1:
            raise AssertionError(f"committed marker count drift: {label}")
    for label in killed:
        marker = (
            f"[V10G-QH-CSR-KILL] {label} "
            "birth=1 selective_kill=1 C0=0 C1=0 PASS"
        )
        if text.count(marker) != 1:
            raise AssertionError(f"killed marker count drift: {label}")
    if text.count("[PASS] tb_ooo_core_top_glue_v9o_csr_qh") != 1:
        raise AssertionError("focused PASS marker count drift")
    return {"committed": len(committed), "selectively_killed": len(killed)}


def run_mode(mode: str) -> dict[str, object]:
    mode_dir = OUT / mode
    mode_dir.mkdir(parents=True, exist_ok=True)
    output = mode_dir / "tb.vvp"
    command = compile_command(mode)
    command[command.index("-o") + 1] = str(output)
    if any("OOO_CSR_QUEUE_HEAD" in arg for arg in command):
        raise AssertionError(f"{mode}: queue-head command define remains")
    compile_result = subprocess.run(
        command,
        cwd=ROOT / "npc/rv64/testbench",
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    (mode_dir / "compile-command.txt").write_text(
        shlex.join(command) + "\n", encoding="utf-8"
    )
    (mode_dir / "compile.log").write_text(
        compile_result.stdout, encoding="utf-8"
    )
    vvp = shutil.which("vvp")
    if vvp is None:
        raise RuntimeError("vvp not found")
    if compile_result.returncode == 0:
        simulation = subprocess.run(
            [vvp, str(output)],
            cwd=ROOT / "npc/rv64/testbench",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=180,
        )
        sim_rc: int | None = simulation.returncode
        sim_text = simulation.stdout
    else:
        sim_rc = None
        sim_text = ""
    (mode_dir / "simulation.log").write_text(
        sim_text, encoding="utf-8"
    )
    markers = validate_markers(sim_text) if sim_rc == 0 else {}
    passed = bool(
        compile_result.returncode == 0
        and sim_rc == 0
        and markers == {"committed": 3, "selectively_killed": 2}
    )
    return {
        "mode": mode,
        "assertions": mode == "assert",
        "compile_returncode": compile_result.returncode,
        "simulation_returncode": sim_rc,
        "queue_head_command_define_present": False,
        "fallback_value": 1,
        "markers": markers,
        "passed": passed,
        "compile_command":
            (mode_dir / "compile-command.txt").relative_to(ROOT).as_posix(),
        "compile_log": (mode_dir / "compile.log").relative_to(ROOT).as_posix(),
        "simulation_log":
            (mode_dir / "simulation.log").relative_to(ROOT).as_posix(),
    }


def main() -> int:
    if SUMMARY.exists():
        raise SystemExit(f"refusing to overwrite completed evidence: {SUMMARY}")
    define_text = DEFINE.read_text(encoding="utf-8")
    if define_text.count(
        "`ifndef OOO_CSR_QUEUE_HEAD\n"
        "`define OOO_CSR_QUEUE_HEAD 1'b1\n"
        "`endif"
    ) != 1:
        raise AssertionError("queue-head RTL fallback is not exactly 1")
    manifest_text = MANIFEST.read_text(encoding="utf-8")
    if manifest_text.count("OOO_CSR_QUEUE_HEAD ?= 1") != 1:
        raise AssertionError("product manifest queue-head value is not exactly 1")

    cases = [run_mode("assert"), run_mode("release")]
    passed = all(bool(case["passed"]) for case in cases)
    result = {
        "schema": "npc-rv64-v10g-product-default-qh-fallback/v1",
        "status": "PASS" if passed else "GAP",
        "design_id": CURRENT_ID,
        "product_config": {
            "manifest": MANIFEST.relative_to(ROOT).as_posix(),
            "manifest_sha256": sha256(MANIFEST),
            "rtl_fallback": DEFINE.relative_to(ROOT).as_posix(),
            "rtl_fallback_sha256": sha256(DEFINE),
            "OOO_CSR_QUEUE_HEAD": 1,
            "command_line_override": False,
        },
        "cases": cases,
        "coverage": {
            "assertions_on_off": "2/2",
            "committed_transactions_per_mode": 3,
            "selectively_killed_transactions_per_mode": 2,
            "raw_csrfile_request_counted": True,
            "c2_quiet_required": True,
        },
    }
    SUMMARY.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-PRODUCT-DEFAULT-QH-FALLBACK] "
        f"assert={cases[0]['passed']} release={cases[1]['passed']} "
        f"override=none {result['status']}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
