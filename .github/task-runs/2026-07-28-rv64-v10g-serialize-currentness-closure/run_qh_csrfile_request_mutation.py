#!/usr/bin/env python3
"""Inject one C2 CsrFile request replay and require raw-scoreboard rejection."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shlex
import shutil
import subprocess


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
TB_COMMON = ROOT / "npc/rv64/testbench/common"
CSR_GLUE = TB_COMMON / "tb_ooo_core_top_glue_csr.svh"
TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
NPC_CORE_TOP = ROOT / "npc/rv64/vsrc/core/NpcCoreTop.v"
IDENTITY = RUN_DIR / "product-default-identity.json"
BASELINE_LOG = (
    RUN_DIR
    / "product-default-qh-v2/release/logs/"
    "tb_ooo_core_top_glue_v9o_csr_qh.log"
)
OUT = RUN_DIR / "mutations/qh-csrfile-c2-replay-v1"
MUTATION_COMMON = OUT / "include"
MUTATED_CSR_GLUE = MUTATION_COMMON / CSR_GLUE.name
SUMMARY = OUT / "summary.json"


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new)


def materialize_mutation() -> None:
    original = CSR_GLUE.read_text(encoding="utf-8")
    mutated = replace_once(
        original,
        "  wire tb_csr_commit_w;\n",
        "  wire tb_csr_commit_w;\n"
        "  reg tb_qh_csrfile_replay_c1_q;\n"
        "  reg tb_qh_csrfile_replay_c2_q;\n",
        "mutation-state-declarations",
    )
    mutated = replace_once(
        mutated,
        "  assign tb_csr_commit_w =\n"
        "      tb_pending_system_csr_commit_w || tb_head0_csr_commit_w;\n",
        "  // Verification-only mutation: replay an accepted queue-head CSR\n"
        "  // request at C2 while the production head0 owner is already clear.\n"
        "  always @(posedge clk) begin\n"
        "    if (rst) begin\n"
        "      tb_qh_csrfile_replay_c1_q <= 1'b0;\n"
        "      tb_qh_csrfile_replay_c2_q <= 1'b0;\n"
        "    end else begin\n"
        "      tb_qh_csrfile_replay_c1_q <= tb_head0_csr_commit_w;\n"
        "      tb_qh_csrfile_replay_c2_q <= tb_qh_csrfile_replay_c1_q;\n"
        "    end\n"
        "  end\n"
        "\n"
        "  assign tb_csr_commit_w =\n"
        "      tb_pending_system_csr_commit_w || tb_head0_csr_commit_w ||\n"
        "      tb_qh_csrfile_replay_c2_q;\n",
        "mutation-request-replay",
    )
    MUTATED_CSR_GLUE.parent.mkdir(parents=True, exist_ok=True)
    MUTATED_CSR_GLUE.write_text(mutated, encoding="utf-8")


def baseline_compile_command() -> list[str]:
    for line in BASELINE_LOG.read_text(encoding="utf-8").splitlines():
        if line.startswith("[COMPILE] "):
            return shlex.split(line.removeprefix("[COMPILE] "))
    raise RuntimeError(f"compile command missing: {BASELINE_LOG}")


def compile_and_run() -> dict[str, object]:
    run_dir = OUT / "run"
    run_dir.mkdir(parents=True, exist_ok=True)
    output = run_dir / "tb.vvp"
    command = baseline_compile_command()
    command[command.index("-o") + 1] = str(output)
    original_include = f"-I{TB_COMMON}"
    include_index = command.index(original_include)
    command[include_index:include_index + 1] = [
        f"-I{MUTATION_COMMON}",
        original_include,
    ]
    compile_cwd = ROOT / "npc/rv64/testbench"
    compile_result = subprocess.run(
        command,
        cwd=compile_cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    (run_dir / "compile-command.txt").write_text(
        shlex.join(command) + "\n", encoding="utf-8"
    )
    (run_dir / "compile.log").write_text(
        compile_result.stdout, encoding="utf-8"
    )

    vvp = shutil.which("vvp")
    if vvp is None:
        raise RuntimeError("vvp not found")
    if compile_result.returncode == 0:
        sim_result = subprocess.run(
            [vvp, str(output)],
            cwd=compile_cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=180,
        )
        sim_rc: int | None = sim_result.returncode
        sim_text = sim_result.stdout
    else:
        sim_rc = None
        sim_text = ""
    (run_dir / "simulation.log").write_text(sim_text, encoding="utf-8")
    return {
        "compile_returncode": compile_result.returncode,
        "simulation_returncode": sim_rc,
        "baseline_pass_marker":
            "[PASS] tb_ooo_core_top_glue_v9o_csr_qh" in sim_text,
        "unowned_csrfile_request_rejected":
            "[CHECK-FAIL] V10G unowned/repeated CsrFile CSR request"
            in sim_text,
        "c2_request_apply_rejected":
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply"
            in sim_text,
        "compile_command":
            (run_dir / "compile-command.txt").relative_to(ROOT).as_posix(),
        "compile_log": (run_dir / "compile.log").relative_to(ROOT).as_posix(),
        "simulation_log":
            (run_dir / "simulation.log").relative_to(ROOT).as_posix(),
    }


def main() -> int:
    if SUMMARY.exists():
        raise SystemExit(f"refusing to overwrite completed evidence: {SUMMARY}")
    identity = json.loads(IDENTITY.read_text(encoding="utf-8"))
    if identity.get("status") != "PASS":
        raise RuntimeError("product-default identity is not PASS")
    core_text = NPC_CORE_TOP.read_text(encoding="utf-8")
    core_binding = (
        ".csr_commit_i(ooo_pending_system_csr_commit_w || "
        "ooo_head0_csr_commit_w),"
    )
    if core_text.count(core_binding) != 1:
        raise RuntimeError("NpcCoreTop CsrFile request binding is not exact")

    materialize_mutation()
    run = compile_and_run()
    passed = bool(
        run["compile_returncode"] == 0
        and run["simulation_returncode"] not in (None, 0)
        and not run["baseline_pass_marker"]
        and run["unowned_csrfile_request_rejected"]
        and run["c2_request_apply_rejected"]
    )
    result = {
        "schema": "npc-rv64-v10g-qh-csrfile-request-mutation/v1",
        "status": "PASS" if passed else "GAP",
        "design_id": identity["current_design_id"],
        "product_config": {
            "OOO_CSR_QUEUE_HEAD": 1,
            "command_line_override": False,
            "source": "npc/rv64/configs/product-rtl-defaults.mk",
        },
        "production_binding": {
            "path": NPC_CORE_TOP.relative_to(ROOT).as_posix(),
            "sha256": sha256(NPC_CORE_TOP),
            "csr_commit_i": core_binding,
            "exact_occurrences": 1,
        },
        "mutation": {
            "name": "duplicate-csrfile-request-at-c2",
            "scope": "verification wiring mirroring NpcCoreTop csr_commit_i",
            "source_path": CSR_GLUE.relative_to(ROOT).as_posix(),
            "source_sha256": sha256(CSR_GLUE),
            "mutated_path": MUTATED_CSR_GLUE.relative_to(ROOT).as_posix(),
            "mutated_sha256": sha256(MUTATED_CSR_GLUE),
            "compile_success": run["compile_returncode"] == 0,
        },
        "run": run,
        "oracle_claim": (
            "the owner-bound raw scoreboard rejects a compile-success C2 "
            "CsrFile request replay after the queue-head CSR owner cleared"
        ),
        "non_claims": [
            "production RTL mutation",
            "SERIALIZE-G1 closure before independent review",
            "architecture freeze",
            "PPA qualification",
        ],
    }
    SUMMARY.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-QH-CSRFILE-MUTATION] "
        f"compile_rc={run['compile_returncode']} "
        f"sim_rc={run['simulation_returncode']} {result['status']}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
