#!/usr/bin/env python3
"""Prove the queue-head CSR raw C0/C1/C2 scoreboard rejects C2 replay."""

from __future__ import annotations

import hashlib
import json
import pathlib
import shlex
import shutil
import subprocess


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
RTL = ROOT / "npc/rv64/vsrc/control/OooControlEventApplySequencer.v"
CURRENT_TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
BASELINE_LOG = (
    RUN_DIR
    / "focused-release/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
)
OUT = RUN_DIR / "mutations/qh-csr-c2-replay-v2"
MUTATED_RTL = OUT / "rtl/OooControlEventApplySequencer.v"
PRE_SCOREBOARD_TB = OUT / "tb/tb_ooo_core_top_glue.pre-v10g.sv"
SUMMARY = OUT / "summary.json"


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new)


def materialize_mutation() -> None:
    original = RTL.read_text(encoding="utf-8")
    mutated = replace_once(
        original,
        "  reg [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_q;\n",
        "  reg [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_q;\n"
        "  reg csr_replay_valid_q;\n"
        "  reg [`OOO_ROB_INDEX_W-1:0] csr_replay_kill_idx_q;\n",
        "mutation-declarations",
    )
    mutated = replace_once(
        mutated,
        "      apply_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n",
        "      apply_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n"
        "      csr_replay_valid_q <= 1'b0;\n"
        "      csr_replay_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n",
        "mutation-reset",
    )
    mutated = replace_once(
        mutated,
        "    end else begin\n"
        "      apply_valid_q <= request_valid_i;\n",
        "    end else begin\n"
        "      apply_valid_q <= request_valid_i;\n"
        "      csr_replay_valid_q <=\n"
        "          apply_valid_q &&\n"
        "          (apply_reason_q == `REDIR_REASON_CSR_COMMIT);\n"
        "      if (apply_valid_q &&\n"
        "          (apply_reason_q == `REDIR_REASON_CSR_COMMIT))\n"
        "        csr_replay_kill_idx_q <= apply_kill_idx_q;\n",
        "mutation-replay-state",
    )
    mutated = replace_once(
        mutated,
        "  assign apply_valid_o = apply_valid_q;\n"
        "  assign apply_reason_o = apply_reason_q;\n"
        "  assign apply_kill_idx_o = apply_kill_idx_q;\n",
        "  assign apply_valid_o = apply_valid_q || csr_replay_valid_q;\n"
        "  assign apply_reason_o =\n"
        "      apply_valid_q ? apply_reason_q :\n"
        "      (csr_replay_valid_q ? `REDIR_REASON_CSR_COMMIT :\n"
        "       apply_reason_q);\n"
        "  assign apply_kill_idx_o =\n"
        "      apply_valid_q ? apply_kill_idx_q : csr_replay_kill_idx_q;\n",
        "mutation-output",
    )
    MUTATED_RTL.parent.mkdir(parents=True, exist_ok=True)
    MUTATED_RTL.write_text(mutated, encoding="utf-8")

    old_tb = subprocess.run(
        ["git", "show", "HEAD:npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    PRE_SCOREBOARD_TB.parent.mkdir(parents=True, exist_ok=True)
    PRE_SCOREBOARD_TB.write_bytes(old_tb)


def baseline_compile_command() -> list[str]:
    for line in BASELINE_LOG.read_text(encoding="utf-8").splitlines():
        if line.startswith("[COMPILE] "):
            return shlex.split(line.removeprefix("[COMPILE] "))
    raise RuntimeError(f"compile command missing: {BASELINE_LOG}")


def run_case(name: str, tb_path: pathlib.Path) -> dict[str, object]:
    case_dir = OUT / "runs" / name
    case_dir.mkdir(parents=True, exist_ok=True)
    output = case_dir / "tb.vvp"
    command = baseline_compile_command()
    command[command.index("-o") + 1] = str(output)
    compile_cwd = ROOT / "npc/rv64/testbench"

    def resolved_argument(arg: str) -> pathlib.Path:
        path = pathlib.Path(arg)
        return (
            path.resolve()
            if path.is_absolute()
            else (compile_cwd / path).resolve()
        )

    command = [
        str(MUTATED_RTL) if resolved_argument(arg) == RTL.resolve() else
        str(tb_path) if resolved_argument(arg) == CURRENT_TB.resolve() else arg
        for arg in command
    ]
    compile_result = subprocess.run(
        command,
        cwd=compile_cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    (case_dir / "compile.log").write_text(
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
        sim_rc = sim_result.returncode
        sim_text = sim_result.stdout
    else:
        sim_rc = None
        sim_text = ""
    (case_dir / "simulation.log").write_text(sim_text, encoding="utf-8")
    return {
        "name": name,
        "testbench": tb_path.relative_to(ROOT).as_posix(),
        "testbench_sha256": sha256(tb_path),
        "compile_returncode": compile_result.returncode,
        "simulation_returncode": sim_rc,
        "pass_marker": "[PASS] tb_ooo_core_top_glue_v9o_csr_qh" in sim_text,
        "scoreboard_reject_marker":
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR apply" in sim_text,
        "unowned_reject_marker":
            "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply" in sim_text,
        "compile_log": (case_dir / "compile.log").relative_to(ROOT).as_posix(),
        "simulation_log":
            (case_dir / "simulation.log").relative_to(ROOT).as_posix(),
    }


def main() -> int:
    if SUMMARY.exists():
        raise SystemExit(f"refusing to overwrite completed evidence: {SUMMARY}")
    materialize_mutation()
    old_case = run_case("pre-scoreboard-release", PRE_SCOREBOARD_TB)
    current_case = run_case("current-scoreboard-release", CURRENT_TB)
    passed = bool(
        old_case["compile_returncode"] == 0
        and old_case["simulation_returncode"] == 0
        and old_case["pass_marker"]
        and current_case["compile_returncode"] == 0
        and current_case["simulation_returncode"] not in (None, 0)
        and current_case["scoreboard_reject_marker"]
        and current_case["unowned_reject_marker"]
    )
    result = {
        "schema": "npc-rv64-v10g-qh-csr-raw-mutation-v1",
        "status": "PASS" if passed else "GAP",
        "design_id": (
            "sha256:"
            "5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
        ),
        "mutation": {
            "name": "duplicate-csr-apply-at-c2-when-no-successor",
            "production_path": RTL.relative_to(ROOT).as_posix(),
            "production_sha256": sha256(RTL),
            "mutated_path": MUTATED_RTL.relative_to(ROOT).as_posix(),
            "mutated_sha256": sha256(MUTATED_RTL),
            "compile_success": (
                old_case["compile_returncode"] == 0
                and current_case["compile_returncode"] == 0
            ),
        },
        "cases": [old_case, current_case],
        "oracle_claim": (
            "the pre-V10G sticky integration accepts the C2 replay while the "
            "owner-bound raw scoreboard rejects the same compile-success RTL"
        ),
    }
    SUMMARY.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-QH-CSR-MUTATION] "
        f"old_rc={old_case['simulation_returncode']} "
        f"current_rc={current_case['simulation_returncode']} "
        f"{result['status']}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
