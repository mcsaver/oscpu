#!/usr/bin/env python3
"""Compile-success RTL mutations for the V8W OOO-4 memory recovery slice."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
VSRCDIR = REPO / "npc/rv64/vsrc"
TBDIR = REPO / "npc/rv64/testbench"
RTL = VSRCDIR / "memory/OooMemAxiBridge.v"
TB = TBDIR / "tests/tb_ooo_mem_axi_bridge.sv"
BACKEND_RTL = VSRCDIR / "execute/OooIntBackend.v"
BACKEND_TB = TBDIR / "tests/tb_ooo_int_backend.sv"
WORK = HERE / "mutation-work"
EVIDENCE = HERE / "mutations"


@dataclass(frozen=True)
class Mutation:
    name: str
    focused_case: int
    old: str
    new: str
    witnesses: tuple[str, ...]


@dataclass(frozen=True)
class BackendMutation:
    name: str
    old: str
    new: str
    witnesses: tuple[str, ...]


SELECTIVE_BLOCK = """  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w &&
      active_tracker_identity_match_w &&
      active_sticky_identity_match_w;"""


MUTATIONS = (
    Mutation(
        "remove-selective-recovery-domain",
        9,
        "  assign cpu_kill_w = flush_i || drop_rsp_q || active_selective_recovery_w;",
        "  assign cpu_kill_w = flush_i || drop_rsp_q;",
        (
            "V8W exact killed SQ query is masked",
            "[V8T-SQ-QUERY-EXACT]",
        ),
    ),
    Mutation(
        "drop-terminal-global-only",
        9,
        """    if (cpu_kill_w && !nokill_busy_w) begin
      case (state_q)
        S_SQ_QUERY,""",
        """    if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin
      case (state_q)
        S_SQ_QUERY,""",
        (
            "V8W exact killed SQ query emits one terminal",
            "[V8W-RECOVERY-PREAXI]",
        ),
    ),
    Mutation(
        "fsm-recovery-global-only",
        10,
        "      end else if (cpu_kill_w && !nokill_busy_w) begin",
        "      end else if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin",
        (
            "[V8W-RECOVERY-R-NO-CONTINUE]",
            "V8W recovered PTW does not present next PTE AR",
        ),
    ),
    Mutation(
        "raw-effective-killed-authority",
        12,
        SELECTIVE_BLOCK,
        """  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q;""",
        ("V8W MIQ identity mismatch blocks selective recovery",),
    ),
    Mutation(
        "omit-tracker-identity-guard",
        12,
        SELECTIVE_BLOCK,
        """  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w &&
      active_sticky_identity_match_w;""",
        ("V8W tracker identity mismatch blocks selective recovery",),
    ),
    Mutation(
        "omit-sticky-identity-guard",
        12,
        SELECTIVE_BLOCK,
        """  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w &&
      active_tracker_identity_match_w;""",
        ("V8W sticky identity mismatch blocks selective recovery",),
    ),
    Mutation(
        "omit-sticky-delayed-r-drain",
        13,
        "  assign cpu_kill_w = flush_i || drop_rsp_q || active_selective_recovery_w;",
        "  assign cpu_kill_w = flush_i || active_selective_recovery_w;",
        (
            "V8W delayed PTW emits exact late terminal",
            "V8W delayed PTW never continues walk",
        ),
    ),
    Mutation(
        "ad-maintenance-authority-global-only",
        14,
        """  wire killed_write_maintenance_capture_w =
      mem0_expected_effective_killed_i && !nokill_q &&""",
        """  wire killed_write_maintenance_capture_w =
      flush_i && mem0_expected_effective_killed_i && !nokill_q &&""",
        ("V8W selective A/D captures maintenance authority",),
    ),
)


BACKEND_MUTATIONS = (
    BackendMutation(
        "disconnect-bank0-drop-from-miq-pop",
        """  assign miq_queue_pop_valid_w =
      miq_pop_transport_w || mem_sq_retry0_capture_w || miq_drop0_pop_w;""",
        """  assign miq_queue_pop_valid_w =
      miq_pop_transport_w || mem_sq_retry0_capture_w;""",
        ("V8W bank0 exact drop selects MIQ pop",),
    ),
    BackendMutation(
        "disconnect-bank1-drop-from-miq-pop",
        """  assign miq1_queue_pop_valid_w =
      miq1_pop_transport_w || mem_sq_retry1_capture_w || miq1_drop0_pop_w;""",
        """  assign miq1_queue_pop_valid_w =
      miq1_pop_transport_w || mem_sq_retry1_capture_w;""",
        ("V8W bank1 exact drop selects MIQ pop",),
    ),
    BackendMutation(
        "disconnect-bank0-drop-from-terminal-collector",
        """      mem_drop1_valid_i,
      mem_drop0_valid_i,
      mem1_terminal_rsp_valid_w,""",
        """      mem_drop1_valid_i,
      1'b0,
      mem1_terminal_rsp_valid_w,""",
        (
            "[V8W-DROP0-TERMINAL]",
            "V8W bank0 exact drop enters collector once",
        ),
    ),
    BackendMutation(
        "disconnect-bank1-drop-from-terminal-collector",
        """      mem_issue_res_tagged_terminal_w,
      mem1_drop1_valid_i,
      mem1_drop0_valid_i,
      mem_drop1_valid_i,""",
        """      mem_issue_res_tagged_terminal_w,
      mem1_drop1_valid_i,
      1'b0,
      mem_drop1_valid_i,""",
        (
            "[V8W-DROP0-TERMINAL]",
            "V8W bank1 exact drop enters collector once",
        ),
    ),
    BackendMutation(
        "omit-bank0-drop-tuple-guard",
        """  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_effective_killed_w && miq_head_tracker_exact_w;""",
        """  assign miq_drop0_pop_w = mem_drop0_valid_i && miq_head_valid_w &&
      miq_head_effective_killed_w && miq_head_tracker_exact_w;""",
        ("V8W bank0 killed head blocks wrong-tuple drop pop",),
    ),
    BackendMutation(
        "omit-bank0-drop-effective-kill-guard",
        """  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_effective_killed_w && miq_head_tracker_exact_w;""",
        """  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_tracker_exact_w;""",
        ("V8W bank0 live head blocks raw exact drop pop",),
    ),
    BackendMutation(
        "omit-bank0-drop-tracker-guard",
        """  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_effective_killed_w && miq_head_tracker_exact_w;""",
        """  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_effective_killed_w;""",
        ("V8W bank0 killed head blocks tracker-mismatch drop pop",),
    ),
    BackendMutation(
        "omit-bank1-drop-tuple-guard",
        """  assign miq1_drop0_pop_w = miq1_drop0_head_tuple_exact_w &&
      miq1_head_effective_killed_w && miq1_head_tracker_exact_w;""",
        """  assign miq1_drop0_pop_w = mem1_drop0_valid_i && miq1_head_valid_w &&
      miq1_head_effective_killed_w && miq1_head_tracker_exact_w;""",
        ("V8W bank1 killed head blocks wrong-tuple drop pop",),
    ),
    BackendMutation(
        "omit-bank1-drop-effective-kill-guard",
        """  assign miq1_drop0_pop_w = miq1_drop0_head_tuple_exact_w &&
      miq1_head_effective_killed_w && miq1_head_tracker_exact_w;""",
        """  assign miq1_drop0_pop_w = miq1_drop0_head_tuple_exact_w &&
      miq1_head_tracker_exact_w;""",
        ("V8W bank1 live head blocks raw exact drop pop",),
    ),
    BackendMutation(
        "omit-bank1-drop-tracker-guard",
        """  assign miq1_drop0_pop_w = miq1_drop0_head_tuple_exact_w &&
      miq1_head_effective_killed_w && miq1_head_tracker_exact_w;""",
        """  assign miq1_drop0_pop_w = miq1_drop0_head_tuple_exact_w &&
      miq1_head_effective_killed_w;""",
        ("V8W bank1 killed head blocks tracker-mismatch drop pop",),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def mutate_once(source: str, mutation: Mutation) -> str:
    count = source.count(mutation.old)
    if count != 1:
        raise RuntimeError(
            f"{mutation.name}: anchor count={count}, expected exactly one"
        )
    return source.replace(mutation.old, mutation.new, 1)


def run_mutation(
    mutation: Mutation,
    baseline: str,
    iverilog: str,
    vvp: str,
) -> dict[str, object]:
    case_dir = WORK / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    mutant_path = case_dir / "OooMemAxiBridge.v"
    mutant_text = mutate_once(baseline, mutation)
    mutant_path.write_text(mutant_text, encoding="utf-8")
    vvp_path = case_dir / "tb_ooo_mem_axi_bridge.vvp"

    sources = (
        VSRCDIR / "memory/PmpChecker.v",
        VSRCDIR / "memory/OooTypedPmaChecker.v",
        VSRCDIR / "memory/OooTypedMemoryClassifier.v",
        VSRCDIR / "memory/OooPmaChecker.v",
        VSRCDIR / "memory/OooPostTranslateMemoryClass.v",
        VSRCDIR / "cache/OooDataWordCache.v",
        VSRCDIR / "sram/Sram4096x113.v",
        VSRCDIR / "memory/OooSv39Tlb.v",
        mutant_path,
        TB,
    )
    compile_cmd = (
        iverilog,
        "-g2012",
        "-Wall",
        f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}",
        f"-I{TBDIR / 'common'}",
        "-DOOO_ASSERT",
        "-DS2_G1_BRIDGE_FOCUSED",
        f"-Ptb_ooo_mem_axi_bridge.S2_G1_CASE={mutation.focused_case}",
        "-s",
        "tb_ooo_mem_axi_bridge",
        "-o",
        str(vvp_path),
        *(str(path) for path in sources),
    )
    compiled = subprocess.run(
        compile_cmd, text=True, capture_output=True, check=False
    )
    simulated_rc: int | None = None
    simulation_output = ""
    if compiled.returncode == 0:
        simulated = subprocess.run(
            (vvp, str(vvp_path)), text=True, capture_output=True, check=False
        )
        simulated_rc = simulated.returncode
        simulation_output = simulated.stdout + simulated.stderr

    witness = next(
        (item for item in mutation.witnesses if item in simulation_output), ""
    )
    rejected = (
        compiled.returncode == 0
        and simulated_rc not in (None, 0)
        and bool(witness)
        and "[PASS] tb_ooo_mem_axi_bridge" not in simulation_output
    )
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    log_path = EVIDENCE / f"{mutation.name}.log"
    log_path.write_text(
        "[COMPILE] "
        + " ".join(compile_cmd)
        + "\n"
        + compiled.stdout
        + compiled.stderr
        + "[RUN] "
        + vvp
        + " "
        + str(vvp_path)
        + "\n"
        + simulation_output,
        encoding="utf-8",
    )
    result = {
        "name": mutation.name,
        "target": "bridge",
        "focused_case": mutation.focused_case,
        "compile_rc": compiled.returncode,
        "sim_rc": simulated_rc,
        "compile_success": compiled.returncode == 0,
        "witness": witness,
        "rejected": rejected,
        "mutant_sha256": sha256_bytes(mutant_text.encode("utf-8")),
        "log": str(log_path.relative_to(REPO)),
        "compile_command": list(compile_cmd),
        "run_command": [vvp, str(vvp_path)],
    }
    print(
        f"[{'PASS' if rejected else 'FAIL'}] {mutation.name}: "
        f"compile_rc={compiled.returncode} sim_rc={simulated_rc} "
        f"witness={witness!r}"
    )
    return result


def discover_backend_sources() -> tuple[Path, ...]:
    make_fragment = """include Makefile
.PHONY: print-int-backend-sources
print-int-backend-sources:
\t@for source in $(sort $(TB_SRCS_tb_ooo_int_backend)); do printf '%s\\n' "$$source"; done
"""
    discovered = subprocess.run(
        (
            "make",
            "--no-print-directory",
            "-s",
            "-f",
            "-",
            "print-int-backend-sources",
        ),
        cwd=TBDIR,
        input=make_fragment,
        text=True,
        capture_output=True,
        check=False,
    )
    if discovered.returncode != 0:
        raise RuntimeError(
            "backend source discovery failed:\n"
            + discovered.stdout
            + discovered.stderr
        )
    paths: list[Path] = []
    for item in discovered.stdout.splitlines():
        source = Path(item)
        paths.append(source if source.is_absolute() else TBDIR / source)
    if not paths:
        raise RuntimeError("backend source discovery returned no files")
    return tuple(paths)


def mutate_backend_once(source: str, mutation: BackendMutation) -> str:
    count = source.count(mutation.old)
    if count != 1:
        raise RuntimeError(
            f"{mutation.name}: anchor count={count}, expected exactly one"
        )
    return source.replace(mutation.old, mutation.new, 1)


def run_backend_mutation(
    mutation: BackendMutation,
    baseline: str,
    backend_sources: tuple[Path, ...],
    iverilog: str,
    vvp: str,
) -> dict[str, object]:
    case_dir = WORK / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    mutant_path = case_dir / "OooIntBackend.v"
    mutant_text = mutate_backend_once(baseline, mutation)
    mutant_path.write_text(mutant_text, encoding="utf-8")
    vvp_path = case_dir / "tb_ooo_int_backend.vvp"
    sources = tuple(
        mutant_path if path.resolve() == BACKEND_RTL.resolve() else path
        for path in backend_sources
    )
    if mutant_path not in sources:
        raise RuntimeError("backend source manifest did not contain OooIntBackend.v")

    compile_cmd = (
        iverilog,
        "-g2012",
        "-Wall",
        f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}",
        f"-I{TBDIR / 'common'}",
        "-DOOO_ASSERT",
        "-DV8W_MEMORY_RECOVERY_FOCUSED",
        "-s",
        "tb_ooo_int_backend",
        "-o",
        str(vvp_path),
        *(str(path) for path in sources),
    )
    compiled = subprocess.run(
        compile_cmd,
        cwd=TBDIR,
        text=True,
        capture_output=True,
        check=False,
    )
    simulated_rc: int | None = None
    simulation_output = ""
    if compiled.returncode == 0:
        simulated = subprocess.run(
            (vvp, str(vvp_path)), text=True, capture_output=True, check=False
        )
        simulated_rc = simulated.returncode
        simulation_output = simulated.stdout + simulated.stderr

    witness = next(
        (item for item in mutation.witnesses if item in simulation_output), ""
    )
    rejected = (
        compiled.returncode == 0
        and simulated_rc not in (None, 0)
        and bool(witness)
        and "[PASS] tb_ooo_int_backend" not in simulation_output
    )
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    log_path = EVIDENCE / f"{mutation.name}.log"
    log_path.write_text(
        "[COMPILE] "
        + " ".join(compile_cmd)
        + "\n"
        + compiled.stdout
        + compiled.stderr
        + "[RUN] "
        + vvp
        + " "
        + str(vvp_path)
        + "\n"
        + simulation_output,
        encoding="utf-8",
    )
    result = {
        "name": mutation.name,
        "target": "backend",
        "focused_case": "V8W_MEMORY_RECOVERY_FOCUSED",
        "compile_rc": compiled.returncode,
        "sim_rc": simulated_rc,
        "compile_success": compiled.returncode == 0,
        "witness": witness,
        "rejected": rejected,
        "mutant_sha256": sha256_bytes(mutant_text.encode("utf-8")),
        "log": str(log_path.relative_to(REPO)),
        "compile_command": list(compile_cmd),
        "run_command": [vvp, str(vvp_path)],
    }
    print(
        f"[{'PASS' if rejected else 'FAIL'}] {mutation.name}: "
        f"compile_rc={compiled.returncode} sim_rc={simulated_rc} "
        f"witness={witness!r}"
    )
    return result


def main() -> int:
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    candidate_vvp = str(Path(iverilog).with_name("vvp"))
    vvp = candidate_vvp if Path(candidate_vvp).exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("matching vvp not found")

    bridge_baseline = RTL.read_text(encoding="utf-8")
    backend_baseline = BACKEND_RTL.read_text(encoding="utf-8")
    backend_sources = discover_backend_sources()
    bridge_results = [
        run_mutation(mutation, bridge_baseline, iverilog, str(vvp))
        for mutation in MUTATIONS
    ]
    backend_results = [
        run_backend_mutation(
            mutation,
            backend_baseline,
            backend_sources,
            iverilog,
            str(vvp),
        )
        for mutation in BACKEND_MUTATIONS
    ]
    results = bridge_results + backend_results
    summary = {
        "schema": "v8w-ooo4-memory-recovery-mutations-v3",
        "rtl": str(RTL.relative_to(REPO)),
        "rtl_sha256": sha256_bytes(bridge_baseline.encode("utf-8")),
        "testbench": str(TB.relative_to(REPO)),
        "testbench_sha256": sha256_bytes(TB.read_bytes()),
        "backend_rtl": str(BACKEND_RTL.relative_to(REPO)),
        "backend_rtl_sha256": sha256_bytes(
            backend_baseline.encode("utf-8")
        ),
        "backend_testbench": str(BACKEND_TB.relative_to(REPO)),
        "backend_testbench_sha256": sha256_bytes(BACKEND_TB.read_bytes()),
        "total": len(results),
        "compile_success": sum(bool(item["compile_success"]) for item in results),
        "rejected": sum(bool(item["rejected"]) for item in results),
        "results": results,
    }
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    lines = [
        "# V8W OOO-4 compile-success RTL mutation results",
        "",
        f"- RTL SHA-256: `{summary['rtl_sha256']}`",
        f"- testbench SHA-256: `{summary['testbench_sha256']}`",
        f"- backend RTL SHA-256: `{summary['backend_rtl_sha256']}`",
        f"- backend testbench SHA-256: `{summary['backend_testbench_sha256']}`",
        f"- compile-success: {summary['compile_success']}/{summary['total']}",
        f"- rejected: {summary['rejected']}/{summary['total']}",
        "",
    ]
    for item in results:
        lines.append(
            f"- {'PASS' if item['rejected'] else 'FAIL'} "
            f"`{item['name']}`: target={item['target']}, "
            f"case={item['focused_case']}, "
            f"compile_rc={item['compile_rc']}, sim_rc={item['sim_rc']}, "
            f"witness=`{item['witness']}`"
        )
    (EVIDENCE / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if not all(bool(item["rejected"]) for item in results):
        return 1
    print(
        f"[PASS] V8W compile-success RTL mutations "
        f"{len(results)}/{len(results)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
