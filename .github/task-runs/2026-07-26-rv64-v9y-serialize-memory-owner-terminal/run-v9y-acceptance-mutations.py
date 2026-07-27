#!/usr/bin/env python3
"""Release-config mutations for the V9Y accepted terminal-transfer boundary."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK_DIR = pathlib.Path(__file__).resolve().parent
BACKEND = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
COLLECTOR = ROOT / "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v"
TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
TESTBENCH_DIR = ROOT / "npc/rv64/testbench"
OUT_DIR = TASK_DIR / "evidence/acceptance-mutations"
LOG_DIR = OUT_DIR / "logs"


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{name}: expected one source match, got {count}")
    return text.replace(old, new, 1)


def main() -> int:
    backend_source = BACKEND.read_text(encoding="utf-8")
    collector_source = COLLECTOR.read_text(encoding="utf-8")

    raw_transfer = replace_once(
        backend_source,
        "wire [31:0] v9y_terminal_transfer_mask_w =\n"
        "      mem_terminal_accept_mask_w | sq_owner_release_effective_mask_w;",
        "wire [31:0] v9y_terminal_transfer_mask_w =\n"
        "      mem_terminal_ingress_mask_w | sq_owner_release_effective_mask_w;",
        "raw-ingress-is-transfer-authority",
    )
    raw_accept = replace_once(
        collector_source,
        "assign ingress_accept_o = ingress_accept_r;",
        "assign ingress_accept_o = ingress_valid_i;",
        "collector-exports-raw-valid",
    )
    production_assignment = (
        "  assign mem_owner_terminalized_o =\n"
        "      (v9y_unterminalized_holder_mask_w == 32'b0) &&\n"
        "      (v9y_terminal_without_holder_mask_w == 32'b0) &&\n"
        "      (v9y_unaccounted_live_mask_w == 32'b0) &&\n"
        "      (v9y_pending_without_live_mask_w == 32'b0);"
    )
    assertion_only_assignment = (
        "`ifdef OOO_ASSERT\n"
        f"{production_assignment}\n"
        "`endif"
    )
    macro_guarded = replace_once(
        backend_source,
        production_assignment,
        assertion_only_assignment,
        "predicate-guarded-by-ooo-assert",
    )

    mutations = [
        {
            "name": "raw-ingress-is-transfer-authority",
            "backend": raw_transfer,
            "collector": None,
            "expected_marker": (
                "[CHECK-FAIL] V9Y wrong-epoch holder remains unterminated"
            ),
        },
        {
            "name": "collector-exports-raw-valid",
            "backend": None,
            "collector": raw_accept,
            "expected_marker": (
                "[CHECK-FAIL] V9Y wrong-epoch raw ingress is not accepted"
            ),
        },
        {
            "name": "predicate-guarded-by-ooo-assert",
            "backend": macro_guarded,
            "collector": None,
            "expected_marker": (
                "[CHECK-FAIL] V9Y bank0 active holder is not terminalized"
            ),
        },
    ]

    make = shutil.which("make")
    if not make:
        raise RuntimeError("make not found")
    release_ivflags = (
        f"-g2012 -Wall -I{ROOT / 'npc/rv64/vsrc'} "
        f"-I{ROOT / 'npc/rv64/vsrc/include'} -Icommon"
    )

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory(
        prefix="rv64-v9y-acceptance-mutation-"
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        for mutation in mutations:
            name = mutation["name"]
            mutation_dir = temp / name
            result_dir = mutation_dir / "result"
            build_dir = mutation_dir / "build"
            mutation_dir.mkdir(parents=True)
            target = (
                result_dir
                / "logs/tb_ooo_int_backend_v8w_memory_recovery.log"
            )
            command = [
                make,
                "-B",
                "-C",
                str(TESTBENCH_DIR),
                f"IVFLAGS={release_ivflags}",
                f"RESULT_DIR={result_dir}",
                f"BUILD_DIR={build_dir}",
            ]
            mutant_hashes: dict[str, str] = {}
            if mutation["backend"] is not None:
                mutant_backend = mutation_dir / "OooIntBackend.v"
                mutant_backend.write_text(
                    mutation["backend"], encoding="utf-8"
                )
                command.append(f"RTL_OOO_INT_BACKEND={mutant_backend}")
                mutant_hashes["OooIntBackend.v"] = hashlib.sha256(
                    mutation["backend"].encode("utf-8")
                ).hexdigest()
            if mutation["collector"] is not None:
                mutant_collector = (
                    mutation_dir / "OooMemOwnerTerminalCollector.v"
                )
                mutant_collector.write_text(
                    mutation["collector"], encoding="utf-8"
                )
                command.append(
                    "RTL_OOO_MEM_OWNER_TERMINAL_COLLECTOR="
                    f"{mutant_collector}"
                )
                mutant_hashes[
                    "OooMemOwnerTerminalCollector.v"
                ] = hashlib.sha256(
                    mutation["collector"].encode("utf-8")
                ).hexdigest()
            command.append(str(target))

            run = subprocess.run(
                command,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            test_log = (
                target.read_text(encoding="utf-8", errors="replace")
                if target.exists()
                else ""
            )
            combined_log = (
                f"[MUTATION] {name}\n"
                f"[MAKE-RC] {run.returncode}\n"
                f"[COMMAND] {' '.join(command)}\n"
                f"{run.stdout}\n"
                f"{test_log}"
            )
            log_path = LOG_DIR / f"{name}.log"
            log_path.write_text(combined_log, encoding="utf-8")
            expected_marker = mutation["expected_marker"]
            rejected = (
                run.returncode != 0
                and expected_marker in test_log
                and "[RESULT] FAIL" in test_log
            )
            records.append(
                {
                    "name": name,
                    "make_rc": run.returncode,
                    "compile_success": expected_marker in test_log,
                    "expected_marker": expected_marker,
                    "rejected": rejected,
                    "log": str(log_path.relative_to(ROOT)),
                    "mutant_sha256": mutant_hashes,
                }
            )

    summary = {
        "schema_version": 1,
        "configuration": {
            "ooo_assert": False,
            "focused_define": "V8W_MEMORY_RECOVERY_FOCUSED",
            "ivflags": release_ivflags,
        },
        "rtl": {
            str(BACKEND.relative_to(ROOT)): sha256(BACKEND),
            str(COLLECTOR.relative_to(ROOT)): sha256(COLLECTOR),
        },
        "testbench": str(TB.relative_to(ROOT)),
        "testbench_sha256": sha256(TB),
        "mutation_count": len(records),
        "rejected_count": sum(record["rejected"] for record in records),
        "pass": all(record["rejected"] for record in records),
        "mutations": records,
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V9Y-ACCEPTANCE-MUTATIONS] "
        f"rejected={summary['rejected_count']}/{summary['mutation_count']} "
        f"ooo_assert=0 pass={str(summary['pass']).lower()}"
    )
    return 0 if summary["pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
