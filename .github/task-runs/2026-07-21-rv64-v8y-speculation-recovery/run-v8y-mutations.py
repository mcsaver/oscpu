#!/usr/bin/env python3
"""Compile-success RTL verification mutations for the RV64 OOO-4 suite."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
VSRCDIR = REPO / "npc/rv64/vsrc"
TBDIR = REPO / "npc/rv64/testbench"
TB = TBDIR / "tests/tb_ooo_int_backend.sv"
ADAPTER = TBDIR / "tests/tb_ooo_int_backend_v8x_bridge.svh"
DEFAULT_EVIDENCE = HERE / "evidence/mutations"


def evidence_output_dir() -> Path:
    raw = os.environ.get("V8Y_MUTATION_OUTPUT_DIR")
    if not raw:
        return DEFAULT_EVIDENCE
    path = Path(raw).resolve()
    if path == DEFAULT_EVIDENCE.resolve():
        return path
    try:
        rel = path.relative_to(REPO)
    except ValueError as exc:
        raise RuntimeError(
            f"mutation output escapes the local RV64 workspace: {path}") from exc
    parts = rel.parts
    if (
        len(parts) != 5
        or parts[0:2] != (".github", "task-runs")
        or parts[3:] != ("evidence", "ooo4-mutations")
    ):
        raise RuntimeError(f"unsafe OOO-4 mutation output directory: {path}")
    return path


EVIDENCE = evidence_output_dir()

BACKEND = VSRCDIR / "execute/OooIntBackend.v"
DISPATCH = VSRCDIR / "rename_allocate/OooDispatchBackend.v"
SELECTOR = VSRCDIR / "scheduling/OooIntIssueSelect8.v"
IQ = VSRCDIR / "scheduling/OooIntIssueQueue.v"
ROB = VSRCDIR / "writeback/OooRob.v"
BRIDGE = VSRCDIR / "memory/OooMemAxiBridge.v"


@dataclass(frozen=True)
class Edit:
    target: Path
    old: str
    new: str


@dataclass(frozen=True)
class Mutation:
    name: str
    edits: tuple[Edit, ...]
    witnesses: tuple[str, ...]
    metrics: tuple[str, ...]


MUTATIONS = (
    Mutation(
        "control_admit_b",
        (Edit(
            DISPATCH,
            ".dispatch1_valid_i(dispatch1_fire_w && !dispatch1_fp_arith_w),",
            ".dispatch1_valid_i(dispatch1_fire_w && !dispatch1_fp_arith_w &&\n"
            "                       !dispatch1_ctrl_i[`CTRL_BRANCH_BIT]),",
        ),),
        ("V8Y two controls simultaneously resident",),
        ("multiple_controls_inflight",),
    ),
    Mutation(
        "youngest_control_select",
        (Edit(
            SELECTOR,
            "       (swap_w ? partner_onehot_w : first_req_onehot_w));",
            "       (swap_w ? partner_onehot_w :\n"
            "        (second_req_valid_w ? second_req_onehot_w :\n"
            "                              first_req_onehot_w)));",
        ),),
        ("V8Y oldest branch A issue PC", "V8Y oldest branch A issue PID"),
        ("oldest_mispredict_wins", "wrong_path_selective_squash"),
    ),
    Mutation(
        "resolve_issue_close_bypass",
        (
            Edit(
                IQ,
                "assign issue0_valid_o = issue0_found_w && !universal_owner_present_i &&\n"
                "                          !recover_active_i && !kill_valid_i;",
                "assign issue0_valid_o = issue0_found_w && !universal_owner_present_i &&\n"
                "                          !recover_active_i;",
            ),
            Edit(
                BACKEND,
                "assign iq_issue0_ready_w =\n"
                "      !branch_resolve_mispredict_w &&\n"
                "      (mem_issue_res_valid_q ? 1'b0 :",
                "assign iq_issue0_ready_w =\n"
                "      (mem_issue_res_valid_q ? 1'b0 :",
            ),
            Edit(
                BACKEND,
                "assign issue0_valid_w =\n"
                "      !branch_resolve_mispredict_w && iq_issue0_raw_exec_owner_w;",
                "assign issue0_valid_w = iq_issue0_raw_exec_owner_w;",
            ),
        ),
        ("V8Y recovery cycle closes younger issue valid",
         "V8Y recovery cycle closes younger control fire"),
        ("oldest_mispredict_wins", "wrong_path_selective_squash",
         "ghost_after_recovery"),
    ),
    Mutation(
        "rob_tail_boundary_off_by_one",
        (Edit(
            ROB,
            "wire [ROB_INDEX_W-1:0] kill_next_q_w = rob_ptr_add(kill_idx_q, 2'd1);",
            "wire [ROB_INDEX_W-1:0] kill_next_q_w = kill_idx_q;",
        ),),
        ("V8Y empty ROB head and tail agree",),
        ("wrong_path_selective_squash", "exactly_once_retire_violations",
         "ghost_after_recovery"),
    ),
    Mutation(
        "completion_replay_one_cycle",
        (Edit(
            BACKEND,
            "assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w &&\n"
            "                          !ex0_fp_pending_owned_w;",
            "reg v8y_ex0_wb_replay_q;\n"
            "always @(posedge clk) begin\n"
            "  if (rst || flush_i)\n"
            "    v8y_ex0_wb_replay_q <= 1'b0;\n"
            "  else\n"
            "    v8y_ex0_wb_replay_q <= ex0_pre_auth_valid_w &&\n"
            "                             ex0_producer_open_w &&\n"
            "                             !ex0_fp_pending_owned_w;\n"
            "end\n"
            "assign ex0_wb_valid_w =\n"
            "    (ex0_pre_auth_valid_w && ex0_producer_open_w &&\n"
            "     !ex0_fp_pending_owned_w) || v8y_ex0_wb_replay_q;",
        ),),
        ("V8Y survivor completion exactly once",
         "V8Y branch A completion exactly once"),
        ("exactly_once_complete_violations",),
    ),
    Mutation(
        "retire1_owner_remap",
        (Edit(
            ROB,
            "assign commit1_producer_id_o = {slot_generation_q[head1_w], head1_w};",
            "assign commit1_producer_id_o = {slot_generation_q[head_q], head_q};",
        ),),
        ("V8Y survivor retires exactly once",
         "V8Y branch A retires exactly once"),
        ("exactly_once_retire_violations",),
    ),
    Mutation(
        "iq_kill_holder_bypass",
        (Edit(
            DISPATCH,
            ".producer_live_mask_o(int_iq_producer_live_mask_w),\n"
            "    // B2 ROB-walk：暂行为中性（kill=0、recover=0）；Step B 接 ROB.recover_active + kill 源。\n"
            "    .kill_valid_i(rob_kill_valid_w),",
            ".producer_live_mask_o(int_iq_producer_live_mask_w),\n"
            "    // V8Y mutation: retain the IQ suffix across the recovery edge.\n"
            "    .kill_valid_i(1'b0),",
        ),),
        ("V8Y B IQ holder cleared after recovery",
         "V8Y B absent from global holder census"),
        ("ghost_after_recovery",),
    ),
    Mutation(
        "mask_active_recovery_while_station_valid",
        (Edit(
            BRIDGE,
            "  wire active_selective_recovery_w =\n"
            "      mem0_expected_effective_killed_i && !nokill_q &&\n"
            "      active_expected_identity_match_w &&\n"
            "      active_tracker_identity_match_w &&\n"
            "      active_sticky_identity_match_w;",
            "  wire active_selective_recovery_w =\n"
            "      mem0_expected_effective_killed_i && !nokill_q && !stg_valid_q &&\n"
            "      active_expected_identity_match_w &&\n"
            "      active_tracker_identity_match_w &&\n"
            "      active_sticky_identity_match_w;",
        ),),
        ("V8X active A exact selective authority",
         "V8X A late R becomes exact bridge drop"),
        ("fired_axi_drained", "ghost_after_recovery"),
    ),
    Mutation(
        "block_killed_station_promotion",
        (Edit(
            BRIDGE,
            "  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&\n"
            "                         ((state_q == S_IDLE) ||\n"
            "                          ((state_q == S_RESP) && rsp_ready_w) ||\n"
            "                          (lookup_hit_fusion_w && rsp_ready_w)) &&\n"
            "                         (!cpu_kill_w || stg_nokill_q) &&\n"
            "                         !control_full_flush_barrier_i;",
            "  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&\n"
            "                         ((state_q == S_IDLE) ||\n"
            "                          ((state_q == S_RESP) && rsp_ready_w) ||\n"
            "                          (lookup_hit_fusion_w && rsp_ready_w)) &&\n"
            "                         (!cpu_kill_w || stg_nokill_q) &&\n"
            "                         !control_full_flush_barrier_i &&\n"
            "                         !mem0_expected_effective_killed_i;",
        ),),
        ("V8X station B promotes to active B",
         "V8X promoted B drops before target request"),
        ("fired_axi_drained", "ghost_after_recovery"),
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def discover_sources() -> tuple[Path, ...]:
    fragment = """include Makefile
.PHONY: print-v8y-sources
print-v8y-sources:
\t@for source in $(sort $(TB_SRCS_tb_ooo_int_backend_v8y_speculation_recovery)); do printf '%s\\n' "$$source"; done
"""
    result = subprocess.run(
        ("make", "--no-print-directory", "-s", "-f", "-",
         "print-v8y-sources"), cwd=TBDIR, input=fragment, text=True,
        capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    sources = tuple(
        path if path.is_absolute() else TBDIR / path
        for path in map(Path, result.stdout.splitlines())
    )
    required = {edit.target.resolve() for mutation in MUTATIONS
                for edit in mutation.edits}
    observed = {path.resolve() for path in sources}
    if not required <= observed:
        raise RuntimeError(f"source discovery missing {sorted(required - observed)}")
    return sources


def build_mutants(mutation: Mutation, case_dir: Path) -> dict[Path, Path]:
    texts: dict[Path, str] = {}
    for edit in mutation.edits:
        texts.setdefault(edit.target, edit.target.read_text(encoding="utf-8"))
        count = texts[edit.target].count(edit.old)
        if count != 1:
            raise RuntimeError(
                f"{mutation.name}: {edit.target.name} anchor count={count}")
        texts[edit.target] = texts[edit.target].replace(edit.old, edit.new, 1)
    replacements: dict[Path, Path] = {}
    for target, text in texts.items():
        mutant = case_dir / target.name
        mutant.write_text(text, encoding="utf-8")
        replacements[target.resolve()] = mutant
    return replacements


def run_mutation(mutation: Mutation, sources: tuple[Path, ...],
                 iverilog: str, vvp: str,
                 suite_run_id: str, work: Path) -> dict[str, object]:
    case_dir = work / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    replacements = build_mutants(mutation, case_dir)
    image = case_dir / "tb_ooo_int_backend_v8y.vvp"
    compile_sources = tuple(
        replacements.get(path.resolve(), path) for path in sources)
    command = (
        iverilog, "-g2012", "-Wall", f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}", f"-I{TBDIR / 'common'}",
        "-DOOO_ASSERT", "-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED",
        "-DV8Y_SPECULATION_RECOVERY_FOCUSED", "-s", "tb_ooo_int_backend",
        "-o", str(image), *(str(path) for path in compile_sources),
    )
    compiled = subprocess.run(command, cwd=TBDIR, text=True,
                              capture_output=True, check=False)
    sim_rc = None
    sim_text = ""
    if compiled.returncode == 0:
        simulated = subprocess.run((vvp, str(image)), cwd=TBDIR, text=True,
                                   capture_output=True, check=False, timeout=90)
        sim_rc = simulated.returncode
        sim_text = simulated.stdout + simulated.stderr
    witness = next((item for item in mutation.witnesses if item in sim_text), "")
    rejected = (compiled.returncode == 0 and sim_rc not in (None, 0)
                and bool(witness)
                and "[PASS] tb_ooo_int_backend_v8y_speculation_recovery"
                not in sim_text)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    log = EVIDENCE / f"{mutation.name}.log"
    log.write_text(
        "[COMPILE] " + " ".join(command) + "\n" + compiled.stdout
        + compiled.stderr + "[RUN] " + vvp + " " + str(image) + "\n"
        + sim_text, encoding="utf-8")
    mutant_hashes = {
        path.relative_to(REPO).as_posix(): sha256(
            replacements[path.resolve()].read_bytes())
        for path in {edit.target for edit in mutation.edits}
    }
    result = {
        "name": mutation.name,
        "suite_run_id": suite_run_id,
        "metrics": list(mutation.metrics),
        "targets": sorted(mutant_hashes),
        "mutant_sha256": mutant_hashes,
        "compile_success": compiled.returncode == 0,
        "compile_rc": compiled.returncode,
        "sim_rc": sim_rc,
        "witness": witness,
        "dynamic_rejected": rejected,
        "log": log.relative_to(REPO).as_posix(),
    }
    print(f"[V8Y-MUTATION][{'PASS' if rejected else 'FAIL'}] "
          f"name={mutation.name} compile_rc={compiled.returncode} "
          f"sim_rc={sim_rc} witness={witness}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite-run-id", required=True)
    args = parser.parse_args()
    if not re.fullmatch(
            r"v8y-ooo4-[0-9]{8}T[0-9]{6}Z-[0-9]+",
            args.suite_run_id):
        raise ValueError("malformed local RV64 V8Y suite run id")
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    paired = str(Path(iverilog).with_name("vvp"))
    vvp = paired if Path(paired).exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("matching vvp not found")
    sources = discover_sources()
    production_paths = sorted({edit.target for mutation in MUTATIONS
                               for edit in mutation.edits})
    before = {path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
              for path in production_paths}
    if EVIDENCE.exists():
        shutil.rmtree(EVIDENCE)
    EVIDENCE.mkdir(parents=True)
    with tempfile.TemporaryDirectory(
        prefix="rv64-v8y-speculation-recovery-mutations."
    ) as temporary:
        work = Path(temporary)
        results = [run_mutation(
            item, sources, iverilog, str(vvp), args.suite_run_id, work)
                   for item in MUTATIONS]
    after = {path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
             for path in production_paths}
    summary = {
        "schema": "v8y-speculation-recovery-mutations-v1",
        "suite_run_id": args.suite_run_id,
        "required": len(MUTATIONS),
        "compile_success": sum(bool(item["compile_success"])
                               for item in results),
        "dynamic_rejected": sum(bool(item["dynamic_rejected"])
                                for item in results),
        "source_sha256_before": before,
        "source_sha256_after": after,
        "source_unchanged": before == after,
        "testbench_sha256": sha256(TB.read_bytes()),
        "adapter_sha256": sha256(ADAPTER.read_bytes()),
        "results": results,
    }
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    if not summary["source_unchanged"] or not all(
            item["dynamic_rejected"] for item in results):
        return 1
    print(f"[V8Y-MUTATIONS] compile_success={len(results)}/{len(results)} "
          f"dynamic_rejected={len(results)}/{len(results)} PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
