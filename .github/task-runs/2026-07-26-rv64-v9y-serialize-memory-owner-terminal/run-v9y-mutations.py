#!/usr/bin/env python3
"""Compile-success RTL variants for the V9Y terminalized-owner boundary."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK_DIR = pathlib.Path(__file__).resolve().parent
RTL = ROOT / "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v"
TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv"
OUT_DIR = TASK_DIR / "evidence/mutations"
LOG_DIR = OUT_DIR / "logs"


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{name}: expected one source match, got {count}")
    return text.replace(old, new, 1)


def main() -> int:
    source = RTL.read_text(encoding="utf-8")
    mutations = {
        "drop-noncsr-terminal-gate": (
            replace_once(
                source,
                "wire pending_system_mem_terminal_w =\n"
                "      !pending_system_i || mem_owner_terminalized_i;",
                "wire pending_system_mem_terminal_w = 1'b1;",
                "drop-noncsr-terminal-gate",
            ),
            "[CHECK-FAIL] non-fence system blocks active memory holder",
        ),
        "drop-csr-terminal-gate": (
            replace_once(
                source,
                "!pending_system_dispatched_i && backend_drained_q_i &&\n"
                "      mem_owner_terminalized_i;",
                "!pending_system_dispatched_i && backend_drained_q_i;",
                "drop-csr-terminal-gate",
            ),
            "[CHECK-FAIL] CSR dispatch blocks active memory holder",
        ),
    }
    full_idle_source = replace_once(
        source,
        "!pending_system_dispatched_i && backend_drained_q_i &&\n"
        "      mem_owner_terminalized_i;",
        "!pending_system_dispatched_i && backend_drained_q_i &&\n"
        "      mem_idle_i;",
        "replace-with-full-mem-idle-csr",
    )
    full_idle_source = replace_once(
        full_idle_source,
        "wire pending_system_mem_terminal_w =\n"
        "      !pending_system_i || mem_owner_terminalized_i;",
        "wire pending_system_mem_terminal_w =\n"
        "      !pending_system_i || mem_idle_i;",
        "replace-with-full-mem-idle-drain",
    )
    mutations["replace-with-full-mem-idle"] = (
        full_idle_source,
        "[CHECK-FAIL] non-fence system admits terminal-pending-only owner",
    )

    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    vvp = str(pathlib.Path(iverilog).with_name("vvp"))
    if not pathlib.Path(vvp).exists():
        fallback = shutil.which("vvp")
        if not fallback:
            raise RuntimeError("vvp not found")
        vvp = fallback

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory(prefix="rv64-v9y-mutation-") as temp_name:
        temp = pathlib.Path(temp_name)
        for name, (mutant_text, expected_marker) in mutations.items():
            mutant = temp / f"{name}.v"
            binary = temp / f"{name}.vvp"
            mutant.write_text(mutant_text, encoding="utf-8")
            compile_run = subprocess.run(
                [
                    iverilog,
                    "-g2012",
                    "-Wall",
                    "-DOOO_ASSERT",
                    f"-I{ROOT / 'npc/rv64/vsrc'}",
                    f"-I{ROOT / 'npc/rv64/vsrc/include'}",
                    f"-I{ROOT / 'npc/rv64/testbench/common'}",
                    "-s",
                    "tb_ooo_pending_drain_resolve_gate",
                    "-o",
                    str(binary),
                    str(mutant),
                    str(TB),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            sim_run = None
            if compile_run.returncode == 0:
                sim_run = subprocess.run(
                    [vvp, str(binary)],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
            log_text = (
                f"[MUTATION] {name}\n"
                f"[COMPILE-RC] {compile_run.returncode}\n"
                f"{compile_run.stdout}"
            )
            if sim_run is not None:
                log_text += f"[SIM-RC] {sim_run.returncode}\n{sim_run.stdout}"
            log_path = LOG_DIR / f"{name}.log"
            log_path.write_text(log_text, encoding="utf-8")
            rejected = (
                compile_run.returncode == 0
                and sim_run is not None
                and sim_run.returncode != 0
                and expected_marker in sim_run.stdout
                and "[FAIL] tb_ooo_pending_drain_resolve_gate" in sim_run.stdout
            )
            records.append(
                {
                    "name": name,
                    "compile_rc": compile_run.returncode,
                    "sim_rc": None if sim_run is None else sim_run.returncode,
                    "expected_marker": expected_marker,
                    "rejected": rejected,
                    "log": str(log_path.relative_to(ROOT)),
                    "mutant_sha256": hashlib.sha256(
                        mutant_text.encode("utf-8")
                    ).hexdigest(),
                }
            )

    summary = {
        "schema_version": 1,
        "rtl": str(RTL.relative_to(ROOT)),
        "rtl_sha256": sha256(RTL),
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
        "[V9Y-MUTATIONS] "
        f"rejected={summary['rejected_count']}/{summary['mutation_count']} "
        f"pass={str(summary['pass']).lower()}"
    )
    return 0 if summary["pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())

