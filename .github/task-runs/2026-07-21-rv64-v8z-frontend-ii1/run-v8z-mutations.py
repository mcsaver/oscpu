#!/usr/bin/env python3
"""Compile-success RTL source mutations for the local RV64 DI-1 suite."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
VSRCDIR = REPO / "npc/rv64/vsrc"
TBDIR = REPO / "npc/rv64/testbench"
WORK = Path("/tmp/rv64-v8z-frontend-ii1-mutations")
EVIDENCE = HERE / "evidence/mutations"

BRIDGE = VSRCDIR / "frontend/OooFetchAxiBridge.v"
FLOW = VSRCDIR / "frontend/OooFetchFlowControl.v"
SEQUENCER = VSRCDIR / "frontend/OooFetchPcOutstandingSequencer.v"
ACTION = VSRCDIR / "frontend/OooFrontendActionGate.v"
REQUEST_MUX = VSRCDIR / "frontend/OooFetchRequestMux.v"
BRIDGE_TB = TBDIR / "tests/tb_ooo_fetch_axi_bridge.sv"
FRONTEND_TB = TBDIR / "tests/tb_ooo_core_top_glue.sv"


@dataclass(frozen=True)
class Edit:
    target: Path
    old: str
    new: str


@dataclass(frozen=True)
class Mutation:
    name: str
    test: str
    top: str
    define: str | None
    edits: tuple[Edit, ...]
    witnesses: tuple[str, ...]
    dimensions: tuple[str, ...]


MUTATIONS = (
    Mutation(
        "bridge_h1_ready_cut",
        "tb_ooo_fetch_axi_bridge",
        "tb_ooo_fetch_axi_bridge",
        None,
        (Edit(
            BRIDGE,
            "                              (cache_hit_resp_w && fetch_rsp_ready_i));",
            "                              1'b0);",
        ),),
        ("II1 burst accepts successor every cycle",),
        ("accepted_packets", "produced_packets", "max_initiation_interval"),
    ),
    Mutation(
        "bridge_h1_state_turnover_cut",
        "tb_ooo_fetch_axi_bridge",
        "tb_ooo_fetch_axi_bridge",
        None,
        (Edit(
            BRIDGE,
            "              state_q <= fetch_req_fire_w ? S_CACHE_READ : S_IDLE;",
            "              state_q <= S_IDLE;",
        ),),
        ("II1 burst remains in H1 result state",),
        ("produced_packets", "max_initiation_interval"),
    ),
    Mutation(
        "bridge_semantic_lookup_cut",
        "tb_ooo_fetch_axi_bridge",
        "tb_ooo_fetch_axi_bridge",
        None,
        (Edit(
            BRIDGE,
            "  wire fetch_cache_lookup_issue_w = fetch_req_fire_w;",
            "  wire fetch_cache_lookup_issue_w = 1'b0;",
        ),),
        ("II1 seed fire is semantic cache issue",),
        ("produced_packets",),
    ),
    Mutation(
        "flow_outstanding_turnover_cut",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (Edit(
            FLOW,
            "                               (!outstanding_valid_i || fetch_rsp_fire_o);",
            "                               !outstanding_valid_i;",
        ),),
        ("V8Z successor request fires every required turnover cycle",),
        ("accepted_packets", "max_initiation_interval"),
    ),
    Mutation(
        "flow_enqueue_credit_cut",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (Edit(
            FLOW,
            "  assign fetch_rsp_can_enqueue_o = can_run_i && outstanding_valid_i &&\n"
            "                                   fifo_can_accept_rsp_o;",
            "  assign fetch_rsp_can_enqueue_o = can_run_i && !outstanding_valid_i &&\n"
            "                                   fifo_can_accept_rsp_o;",
        ),),
        ("V8Z response ready every required turnover cycle",),
        ("produced_packets", "max_initiation_interval"),
    ),
    Mutation(
        "sequencer_replacement_clear",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (Edit(
            SEQUENCER,
            "      if (fetch_rsp_fire_i && !fetch_req_fire_i) begin\n"
            "        outstanding_valid_q <= 1'b0;\n"
            "      end else if (fetch_req_fire_i) begin\n"
            "        outstanding_valid_q <= 1'b1;\n"
            "      end",
            "      if (fetch_rsp_fire_i) begin\n"
            "        outstanding_valid_q <= 1'b0;\n"
            "      end else if (fetch_req_fire_i) begin\n"
            "        outstanding_valid_q <= 1'b1;\n"
            "      end",
        ),),
        ("V8Z frontend retains one outstanding owner",),
        ("accepted_packets", "produced_packets"),
    ),
    Mutation(
        "sink_dequeue_cut",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (Edit(
            ACTION,
            "  assign fifo_pop_o =\n"
            "      !control_full_flush_barrier_i &&\n"
            "      (dispatch_fire_i ||",
            "  assign fifo_pop_o =\n"
            "      !control_full_flush_barrier_i &&\n"
            "      (1'b0 ||",
        ),),
        ("V8Z FIFO sink consumes one packet",),
        ("produced_packets",),
    ),
    Mutation(
        "successor_pc_old_owner",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (Edit(
            REQUEST_MUX,
            "      fetch_rsp_packet_next_pc_i : next_fetch_pc_i;",
            "      next_fetch_pc_i : next_fetch_pc_i;",
        ),),
        ("[V8Z-PC-LEDGER][FAIL] request successor",),
        ("pc_ledger",),
    ),
    Mutation(
        "blocked_response_tail_ghost",
        "tb_ooo_core_top_glue_v8z_frontend_ii1",
        "tb_ooo_core_top_glue",
        "V8Z_FRONTEND_II1_FOCUSED",
        (
            Edit(
                SEQUENCER,
                "  reg discard_fetch_rsp_q;",
                "  reg discard_fetch_rsp_q;\n  reg v8z_block_seen_q;",
            ),
            Edit(
                SEQUENCER,
                "      discard_fetch_rsp_q <= 1'b0;\n    end else begin",
                "      discard_fetch_rsp_q <= 1'b0;\n"
                "      v8z_block_seen_q <= 1'b0;\n"
                "    end else begin\n"
                "      if (outstanding_valid_q && !fetch_rsp_fire_i)\n"
                "        v8z_block_seen_q <= 1'b1;",
            ),
            Edit(
                SEQUENCER,
                "      if (fetch_rsp_fire_i && !fetch_req_fire_i) begin",
                "      if (fetch_rsp_fire_i && !fetch_req_fire_i &&\n"
                "          !v8z_block_seen_q) begin",
            ),
        ),
        ("V8Z final outstanding owner is empty",),
        ("backpressure_recovery", "final_conservation"),
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def discover_sources(test: str) -> tuple[Path, ...]:
    variable = f"TB_SRCS_{test}"
    fragment = (
        "include Makefile\n"
        f".PHONY: print-{test}-sources\n"
        f"print-{test}-sources:\n"
        f"\t@for source in $(sort $({variable})); do printf '%s\\n' \"$$source\"; done\n"
    )
    result = subprocess.run(
        ("make", "--no-print-directory", "-s", "-f", "-",
         f"print-{test}-sources"),
        cwd=TBDIR,
        input=fragment,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return tuple(
        path if path.is_absolute() else TBDIR / path
        for path in map(Path, result.stdout.splitlines())
    )


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
    for target, content in texts.items():
        mutant = case_dir / target.name
        mutant.write_text(content, encoding="utf-8")
        replacements[target.resolve()] = mutant
    return replacements


def paired_tools() -> tuple[str, str]:
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    paired = str(Path(iverilog).with_name("vvp"))
    vvp = paired if Path(paired).exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("matching vvp not found")
    return iverilog, str(vvp)


def run_mutation(
    mutation: Mutation,
    sources: tuple[Path, ...],
    iverilog: str,
    vvp: str,
    suite_run_id: str,
) -> dict[str, object]:
    case_dir = WORK / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    replacements = build_mutants(mutation, case_dir)
    source_set = {path.resolve() for path in sources}
    missing = set(replacements) - source_set
    if missing:
        raise RuntimeError(f"{mutation.name}: source discovery missing {missing}")
    image = case_dir / f"{mutation.test}.vvp"
    compile_sources = tuple(
        replacements.get(path.resolve(), path) for path in sources)
    flags = [
        "-g2012", "-Wall", f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}", f"-I{TBDIR / 'common'}",
        "-DOOO_ASSERT",
    ]
    if mutation.define:
        flags.append(f"-D{mutation.define}")
    command = (
        iverilog, *flags, "-s", mutation.top, "-o", str(image),
        *(str(path) for path in compile_sources),
    )
    compiled = subprocess.run(
        command, cwd=TBDIR, text=True, capture_output=True, check=False)
    sim_rc: int | None = None
    sim_text = ""
    if compiled.returncode == 0:
        simulated = subprocess.run(
            (vvp, str(image)), cwd=TBDIR, text=True,
            capture_output=True, check=False, timeout=120)
        sim_rc = simulated.returncode
        sim_text = simulated.stdout + simulated.stderr
    witness = next(
        (item for item in mutation.witnesses if item in sim_text), "")
    clean_pass = f"[PASS] {mutation.test}" in sim_text
    rejected = (
        compiled.returncode == 0 and sim_rc not in (None, 0)
        and bool(witness) and not clean_pass
    )
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    log = EVIDENCE / f"{mutation.name}.log"
    log.write_text(
        "[COMPILE] " + " ".join(command) + "\n" +
        compiled.stdout + compiled.stderr +
        "[RUN] " + vvp + " " + str(image) + "\n" + sim_text,
        encoding="utf-8",
    )
    targets = sorted({edit.target for edit in mutation.edits})
    mutant_hashes = {
        target.relative_to(REPO).as_posix():
            sha256(replacements[target.resolve()].read_bytes())
        for target in targets
    }
    result: dict[str, object] = {
        "name": mutation.name,
        "suite_run_id": suite_run_id,
        "test": mutation.test,
        "dimensions": list(mutation.dimensions),
        "targets": sorted(mutant_hashes),
        "mutant_sha256": mutant_hashes,
        "compile_success": compiled.returncode == 0,
        "compile_rc": compiled.returncode,
        "sim_rc": sim_rc,
        "witness": witness,
        "dynamic_rejected": rejected,
        "log": log.relative_to(REPO).as_posix(),
    }
    print(
        f"[V8Z-MUTATION][{'PASS' if rejected else 'FAIL'}] "
        f"name={mutation.name} compile_rc={compiled.returncode} "
        f"sim_rc={sim_rc} witness={witness}"
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite-run-id", required=True)
    args = parser.parse_args()
    if not re.fullmatch(
        r"v8z-di1-[0-9]{8}T[0-9]{6}Z-[0-9]+", args.suite_run_id
    ):
        raise ValueError("malformed local RV64 V8Z suite run id")

    if WORK.exists():
        shutil.rmtree(WORK)
    WORK.mkdir(parents=True)
    if EVIDENCE.exists():
        shutil.rmtree(EVIDENCE)
    EVIDENCE.mkdir(parents=True)

    iverilog, vvp = paired_tools()
    source_cache = {
        test: discover_sources(test)
        for test in sorted({item.test for item in MUTATIONS})
    }
    production_paths = sorted({
        edit.target for mutation in MUTATIONS for edit in mutation.edits
    })
    before = {
        path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
        for path in production_paths
    }
    results = [
        run_mutation(
            mutation, source_cache[mutation.test], iverilog, vvp,
            args.suite_run_id,
        )
        for mutation in MUTATIONS
    ]
    after = {
        path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
        for path in production_paths
    }
    summary = {
        "schema": "v8z-frontend-ii1-mutations-v1",
        "suite_run_id": args.suite_run_id,
        "required": len(MUTATIONS),
        "compile_success": sum(
            bool(item["compile_success"]) for item in results),
        "dynamic_rejected": sum(
            bool(item["dynamic_rejected"]) for item in results),
        "source_sha256_before": before,
        "source_sha256_after": after,
        "source_unchanged": before == after,
        "bridge_testbench_sha256": sha256(BRIDGE_TB.read_bytes()),
        "frontend_testbench_sha256": sha256(FRONTEND_TB.read_bytes()),
        "results": results,
    }
    (EVIDENCE / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if not summary["source_unchanged"] or not all(
        item["dynamic_rejected"] for item in results
    ):
        return 1
    print(
        f"[V8Z-MUTATIONS] compile_success={len(results)}/{len(results)} "
        f"dynamic_rejected={len(results)}/{len(results)} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
