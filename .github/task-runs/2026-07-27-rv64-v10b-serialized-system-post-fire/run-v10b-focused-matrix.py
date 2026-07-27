#!/usr/bin/env python3
"""Run V10B assert/release baselines and compile-success RTL variants."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO = RUN_DIR.parents[2]
TB_DIR = REPO / "npc/rv64/testbench"
VSRCDIR = REPO / "npc/rv64/vsrc"
OUT = RUN_DIR / "evidence/v10b-focused-matrix-v1"
SUMMARY = OUT / "summary.json"
STATUS = OUT / "status.json"
WRAPPER = RUN_DIR / "iverilog-recording-wrapper.sh"
SCHEMA = "rv64-v10b-focused-matrix-v1"
MATRIX_TITLE = "V10B focused matrix v1"


@dataclass(frozen=True)
class Mutation:
    name: str
    module: str
    make_var: str
    old: str
    new: str
    test: str = "tb_ooo_priv_system"


MUTATIONS = (
    Mutation(
        "disconnect-satp-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_satp_write_commit_i("
        "pending_system_satp_write_commit_w),",
        ".pending_system_satp_write_commit_i(1'b0),",
    ),
    Mutation(
        "disconnect-sfence-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_sfence_commit_i("
        "pending_system_sfence_commit_w),",
        ".pending_system_sfence_commit_i(1'b0),",
    ),
    Mutation(
        "disconnect-fencei-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_fencei_commit_i("
        "pending_system_fencei_commit_w),",
        ".pending_system_fencei_commit_i(1'b0),",
    ),
    Mutation(
        "sfence-reason-to-serial",
        "frontend/OooFrontend.v",
        "RTL_OOO_FRONTEND",
        "commit_e6_system_sfence_w ? `REDIR_REASON_SFENCE :",
        "commit_e6_system_sfence_w ? `REDIR_REASON_SERIAL :",
    ),
    Mutation(
        "fencei-reason-to-serial",
        "frontend/OooFrontend.v",
        "RTL_OOO_FRONTEND",
        "commit_e6_system_fencei_w ? `REDIR_REASON_FENCEI :",
        "commit_e6_system_fencei_w ? `REDIR_REASON_SERIAL :",
    ),
    Mutation(
        "remove-fence-mem-idle",
        "control/OooPendingDrainResolveGate.v",
        "RTL_OOO_PENDING_DRAIN_RESOLVE_GATE",
        "wire pending_fence_mem_quiet_w =\n"
        "      !pending_system_fence_i || mem_idle_i;",
        "wire pending_fence_mem_quiet_w =\n"
        "      1'b1;",
    ),
    Mutation(
        "retain-noncsr-holder-after-terminal",
        "control/OooPendingSystemSequencer.v",
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "end else if (clear_i) begin",
        "end else if (clear_i && (kind_q == SERIAL_KIND_CSR)) begin",
    ),
    Mutation(
        "retain-stop-after-drain-terminal",
        "control/OooStopPendingSequencer.v",
        "RTL_OOO_STOP_PENDING_SEQUENCER",
        "stop_pending_o && drain_complete_i) begin",
        "stop_pending_o && drain_complete_i && 1'b0) begin",
    ),
    Mutation(
        "remove-csr-producerid-match",
        "control/OooCsrAccessRequestMux.v",
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "pending_system_csr_pid_match_w && "
        "pending_system_csr_pc_match_w;",
        "pending_system_csr_pc_match_w;",
        "tb_ooo_csr_access_request_mux",
    ),
    Mutation(
        "remove-csr-pc-match",
        "control/OooCsrAccessRequestMux.v",
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "pending_system_csr_pid_match_w && "
        "pending_system_csr_pc_match_w;",
        "pending_system_csr_pid_match_w;",
        "tb_ooo_csr_access_request_mux",
    ),
    Mutation(
        "remove-wfi-control-commit",
        "writeback/OooWriteback.v",
        "RTL_OOO_WRITEBACK",
        ".drain_pending_system_i(pending_system_q),",
        ".drain_pending_system_i(\n"
        "        pending_system_q &&\n"
        "        (pending_system_inst_q != 32'h1050_0073)),",
    ),
    Mutation(
        "add-mmu-action-to-every-drain",
        "memory/OooMemoryRequestGate.v",
        "RTL_OOO_MEMORY_REQUEST_GATE",
        "(pending_system_satp_write_commit_i || "
        "pending_system_sfence_commit_i ||\n"
        "         pending_system_fencei_commit_i);",
        "(pending_system_satp_write_commit_i || "
        "pending_system_sfence_commit_i ||\n"
        "         pending_system_fencei_commit_i ||\n"
        "         (stop_pending_i && backend_drained_i));",
    ),
    Mutation(
        "drop-sfence-inval-ir-classification",
        "decode/DecodeUnit.v",
        "RTL_DECODE_UNIT",
        "(rs2_idx_o == `SYSTEM_RS2_SFENCE_INVAL_IR))) begin",
        "(rs2_idx_o == 5'b11111))) begin",
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_status(completed: int, total: int, current: str) -> None:
    STATUS.parent.mkdir(parents=True, exist_ok=True)
    STATUS.write_text(
        json.dumps(
            {
                "state": "RUNNING",
                "completed": completed,
                "total": total,
                "current": current,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def simulation_failure_marker(log_text: str) -> bool:
    for line in log_text.splitlines():
        if line.startswith("[RESULT]"):
            continue
        if re.search(r"CHECK-FAIL|\[FAIL\]|\bFAIL\b|FATAL:", line):
            return True
    return False


def run_case(
    name: str,
    test: str,
    real_iverilog: str,
    real_vvp: str,
    overrides: dict[str, Path] | None = None,
    release: bool = False,
    expect_pass: bool = True,
) -> dict[str, object]:
    result_dir = OUT / "runs" / name
    build_dir = result_dir / "build"
    log = result_dir / "logs" / f"{test}.log"
    compile_rc_file = result_dir / "compile.rc"
    result_dir.mkdir(parents=True, exist_ok=True)

    command = [
        "make",
        "-C",
        str(TB_DIR),
        f"RESULT_DIR={result_dir}",
        f"BUILD_DIR={build_dir}",
        f"IVERILOG={WRAPPER}",
        f"VVP={real_vvp}",
    ]
    if release:
        command.append(
            "IVFLAGS="
            f"-g2012 -Wall -I{VSRCDIR} "
            f"-I{VSRCDIR / 'include'} -I{TB_DIR / 'common'}"
        )
    if overrides:
        command.extend(
            f"{key}={value}" for key, value in sorted(overrides.items())
        )
    command.append(str(log))

    env = os.environ.copy()
    env["V10B_REAL_IVERILOG"] = real_iverilog
    env["V10B_COMPILE_RC_FILE"] = str(compile_rc_file)
    completed = subprocess.run(
        command,
        cwd=REPO,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    make_log = result_dir / "make.log"
    make_log.write_text(completed.stdout, encoding="utf-8")
    log_text = log.read_text(encoding="utf-8") if log.exists() else ""
    compile_rc = (
        int(compile_rc_file.read_text(encoding="utf-8").strip())
        if compile_rc_file.exists()
        else None
    )
    result_pass = "[RESULT] PASS" in log_text
    result_fail = "[RESULT] FAIL" in log_text
    sim_rejected = simulation_failure_marker(log_text)
    passed = bool(
        compile_rc == 0
        and (
            (
                expect_pass
                and completed.returncode == 0
                and result_pass
            )
            or (
                not expect_pass
                and completed.returncode != 0
                and result_fail
                and sim_rejected
            )
        )
    )
    return {
        "name": name,
        "test": test,
        "release": release,
        "expect_pass": expect_pass,
        "command": command,
        "make_returncode": completed.returncode,
        "compile_returncode": compile_rc,
        "result_pass": result_pass,
        "result_fail": result_fail,
        "simulation_rejected": sim_rejected,
        "passed": passed,
        "result_log": str(log.relative_to(REPO)),
        "make_log": str(make_log.relative_to(REPO)),
    }


def materialize_mutation(mutation: Mutation) -> tuple[Path, dict[str, object]]:
    source = VSRCDIR / mutation.module
    original = source.read_text(encoding="utf-8")
    count = original.count(mutation.old)
    if count != 1:
        raise RuntimeError(
            f"{mutation.name}: expected one replacement anchor, found {count}"
        )
    mutated = OUT / "mutated" / mutation.name / source.name
    mutated.parent.mkdir(parents=True, exist_ok=True)
    mutated.write_text(
        original.replace(mutation.old, mutation.new),
        encoding="utf-8",
    )
    return mutated, {
        "name": mutation.name,
        "module": str(source.relative_to(REPO)),
        "make_var": mutation.make_var,
        "test": mutation.test,
        "source_sha256": sha256(source),
        "mutated_path": str(mutated.relative_to(REPO)),
        "mutated_sha256": sha256(mutated),
        "from": mutation.old,
        "to": mutation.new,
    }


def write_markdown(summary: dict[str, object]) -> None:
    rows = [
        f"# {MATRIX_TITLE}",
        "",
        "| case | test | compile | result | simulation | verdict |",
        "| --- | --- | ---: | --- | --- | --- |",
    ]
    for case in summary["cases"]:
        result = "PASS" if case["result_pass"] else "FAIL"
        simulation = (
            "accepted" if case["expect_pass"] else
            ("rejected" if case["simulation_rejected"] else "not-observed")
        )
        rows.append(
            f"| `{case['name']}` | `{case['test']}` | "
            f"{case['compile_returncode']} | {result} | {simulation} | "
            f"{'PASS' if case['passed'] else 'GAP'} |"
        )
    rows.extend(
        [
            "",
            f"- all_pass: `{str(summary['all_pass']).lower()}`",
            f"- compile_success_mutations: "
            f"`{summary['compile_success_mutations']}`",
            f"- dynamically_rejected_mutations: "
            f"`{summary['dynamically_rejected_mutations']}`",
            "",
        ]
    )
    (OUT / "summary.md").write_text("\n".join(rows), encoding="utf-8")


def main() -> int:
    if SUMMARY.exists():
        raise SystemExit(f"refusing to overwrite completed matrix: {SUMMARY}")
    real_iverilog = shutil.which("iverilog")
    real_vvp = shutil.which("vvp")
    if not real_iverilog or not real_vvp:
        raise SystemExit("iverilog/vvp not found")
    if not os.access(WRAPPER, os.X_OK):
        raise SystemExit(f"compile wrapper is not executable: {WRAPPER}")

    total = 3 + len(MUTATIONS)
    cases: list[dict[str, object]] = []
    mutation_records: list[dict[str, object]] = []

    baselines = (
        ("priv-system-assert", "tb_ooo_priv_system", False),
        ("priv-system-release", "tb_ooo_priv_system", True),
        ("csr-access-assert", "tb_ooo_csr_access_request_mux", False),
    )
    for name, test, release in baselines:
        write_status(len(cases), total, name)
        case = run_case(
            name,
            test,
            real_iverilog,
            real_vvp,
            release=release,
            expect_pass=True,
        )
        cases.append(case)

    for mutation in MUTATIONS:
        write_status(len(cases), total, mutation.name)
        mutated, record = materialize_mutation(mutation)
        case = run_case(
            mutation.name,
            mutation.test,
            real_iverilog,
            real_vvp,
            overrides={mutation.make_var: mutated},
            expect_pass=False,
        )
        record["case_passed"] = case["passed"]
        mutation_records.append(record)
        cases.append(case)

    compile_success_mutations = sum(
        case["compile_returncode"] == 0
        for case in cases[len(baselines) :]
    )
    dynamically_rejected_mutations = sum(
        bool(case["passed"]) for case in cases[len(baselines) :]
    )
    summary: dict[str, object] = {
        "schema": SCHEMA,
        "testbench": "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
        "testbench_sha256": sha256(
            TB_DIR / "tests/tb_ooo_priv_system.sv"
        ),
        "iverilog": real_iverilog,
        "vvp": real_vvp,
        "cases": cases,
        "mutations": mutation_records,
        "compile_success_mutations": compile_success_mutations,
        "dynamically_rejected_mutations": dynamically_rejected_mutations,
        "all_pass": all(bool(case["passed"]) for case in cases),
    }
    SUMMARY.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_markdown(summary)
    STATUS.write_text(
        json.dumps(
            {
                "state": "DONE",
                "completed": total,
                "total": total,
                "all_pass": summary["all_pass"],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V10B-FOCUSED-MATRIX] "
        f"baselines={len(baselines)}/{len(baselines)} "
        f"compile-success={compile_success_mutations}/{len(MUTATIONS)} "
        f"rejected={dynamically_rejected_mutations}/{len(MUTATIONS)} "
        f"{'PASS' if summary['all_pass'] else 'GAP'}"
    )
    return 0 if summary["all_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
