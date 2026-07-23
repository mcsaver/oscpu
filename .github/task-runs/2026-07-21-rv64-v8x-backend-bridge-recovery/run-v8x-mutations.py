#!/usr/bin/env python3
"""Compile-success RTL mutations for the V8X backend+bridge recovery trace."""

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
BRIDGE_RTL = VSRCDIR / "memory/OooMemAxiBridge.v"
TB = TBDIR / "tests/tb_ooo_int_backend.sv"
ADAPTER = TBDIR / "tests/tb_ooo_int_backend_v8x_bridge.svh"
WORK = HERE / "mutation-work"
EVIDENCE = HERE / "mutations"


@dataclass(frozen=True)
class Mutation:
    name: str
    old: str
    new: str
    witnesses: tuple[str, ...]


SELECTIVE_RECOVERY_BLOCK = """  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w &&
      active_tracker_identity_match_w &&
      active_sticky_identity_match_w;"""

STAGE_ADVANCE_BLOCK = """  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&
                         ((state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w) ||
                          (lookup_hit_fusion_w && rsp_ready_w)) &&
                         (!cpu_kill_w || stg_nokill_q);"""


MUTATIONS = (
    Mutation(
        name="mask-active-recovery-while-station-valid",
        old=SELECTIVE_RECOVERY_BLOCK,
        new="""  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q && !stg_valid_q &&
      active_expected_identity_match_w &&
      active_tracker_identity_match_w &&
      active_sticky_identity_match_w;""",
        witnesses=(
            "V8X active A exact selective authority",
            "V8X A late R becomes exact bridge drop",
        ),
    ),
    Mutation(
        name="block-killed-station-promotion",
        old=STAGE_ADVANCE_BLOCK,
        new="""  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&
                         ((state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w) ||
                          (lookup_hit_fusion_w && rsp_ready_w)) &&
                         (!cpu_kill_w || stg_nokill_q) &&
                         !mem0_expected_effective_killed_i;""",
        witnesses=(
            "V8X station B promotes to active B",
            "V8X promoted B drops before target request",
        ),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def discover_sources() -> tuple[Path, ...]:
    make_fragment = """include Makefile
.PHONY: print-v8x-sources
print-v8x-sources:
\t@for source in $(sort $(TB_SRCS_tb_ooo_int_backend_v8x_backend_bridge_recovery)); do printf '%s\\n' "$$source"; done
"""
    discovered = subprocess.run(
        ("make", "--no-print-directory", "-s", "-f", "-", "print-v8x-sources"),
        cwd=TBDIR,
        input=make_fragment,
        text=True,
        capture_output=True,
        check=False,
    )
    if discovered.returncode != 0:
        raise RuntimeError(
            "V8X source discovery failed:\n"
            + discovered.stdout
            + discovered.stderr
        )
    sources = tuple(
        path if path.is_absolute() else TBDIR / path
        for path in (Path(line) for line in discovered.stdout.splitlines())
    )
    if BRIDGE_RTL.resolve() not in {path.resolve() for path in sources}:
        raise RuntimeError("V8X source manifest omits OooMemAxiBridge.v")
    return sources


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
    sources: tuple[Path, ...],
    iverilog: str,
    vvp: str,
) -> dict[str, object]:
    case_dir = WORK / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    mutant_path = case_dir / "OooMemAxiBridge.v"
    mutant_text = mutate_once(baseline, mutation)
    mutant_path.write_text(mutant_text, encoding="utf-8")
    vvp_path = case_dir / "tb_ooo_int_backend_v8x.vvp"
    mutation_sources = tuple(
        mutant_path if path.resolve() == BRIDGE_RTL.resolve() else path
        for path in sources
    )

    compile_cmd = (
        iverilog,
        "-g2012",
        "-Wall",
        f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}",
        f"-I{TBDIR / 'common'}",
        "-DOOO_ASSERT",
        "-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED",
        "-s",
        "tb_ooo_int_backend",
        "-o",
        str(vvp_path),
        *(str(path) for path in mutation_sources),
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
            (vvp, str(vvp_path)),
            cwd=TBDIR,
            text=True,
            capture_output=True,
            check=False,
            timeout=60,
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
        and "[PASS] tb_ooo_int_backend_v8x_backend_bridge_recovery"
        not in simulation_output
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
        "target": str(BRIDGE_RTL.relative_to(REPO)),
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
    paired_vvp = str(Path(iverilog).with_name("vvp"))
    vvp = paired_vvp if Path(paired_vvp).exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("matching vvp not found")

    baseline_bytes = BRIDGE_RTL.read_bytes()
    baseline = baseline_bytes.decode("utf-8")
    sources = discover_sources()
    results = [
        run_mutation(mutation, baseline, sources, iverilog, str(vvp))
        for mutation in MUTATIONS
    ]
    post_bytes = BRIDGE_RTL.read_bytes()
    summary = {
        "schema": "v8x-backend-bridge-recovery-mutations-v1",
        "rtl": str(BRIDGE_RTL.relative_to(REPO)),
        "rtl_sha256_before": sha256_bytes(baseline_bytes),
        "rtl_sha256_after": sha256_bytes(post_bytes),
        "source_restored": baseline_bytes == post_bytes,
        "testbench": str(TB.relative_to(REPO)),
        "testbench_sha256": sha256_bytes(TB.read_bytes()),
        "adapter": str(ADAPTER.relative_to(REPO)),
        "adapter_sha256": sha256_bytes(ADAPTER.read_bytes()),
        "total": len(results),
        "compile_success": sum(bool(item["compile_success"]) for item in results),
        "rejected": sum(bool(item["rejected"]) for item in results),
        "results": results,
    }
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    lines = [
        "# V8X compile-success RTL mutation results",
        "",
        f"- RTL SHA-256 before: `{summary['rtl_sha256_before']}`",
        f"- RTL SHA-256 after: `{summary['rtl_sha256_after']}`",
        f"- source restored: `{summary['source_restored']}`",
        f"- testbench SHA-256: `{summary['testbench_sha256']}`",
        f"- adapter SHA-256: `{summary['adapter_sha256']}`",
        f"- compile-success: {summary['compile_success']}/{summary['total']}",
        f"- rejected: {summary['rejected']}/{summary['total']}",
        "",
    ]
    for item in results:
        lines.append(
            f"- {'PASS' if item['rejected'] else 'FAIL'} `{item['name']}`: "
            f"compile_rc={item['compile_rc']}, sim_rc={item['sim_rc']}, "
            f"witness=`{item['witness']}`"
        )
    (EVIDENCE / "summary.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )
    if not summary["source_restored"] or not all(
        bool(item["rejected"]) for item in results
    ):
        return 1
    print(f"[PASS] V8X compile-success RTL mutations {len(results)}/{len(results)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

