#!/usr/bin/env python3
"""Compile-success local RV64 RTL mutations for the V9A DI-2 oracle."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
VSRCDIR = REPO / "npc/rv64/vsrc"
TBDIR = REPO / "npc/rv64/testbench"
EVIDENCE = HERE / "evidence/mutations"
TEST = "tb_ooo_core_top_glue_v9a_width_continuity"
TOP = "tb_ooo_core_top_glue"

FETCH_DECODE = VSRCDIR / "frontend/OooFetchPacketDecode.v"
DECODE_BACKEND = VSRCDIR / "decode/OooAluDecodeBackend.v"
DISPATCH_BACKEND = VSRCDIR / "rename_allocate/OooDispatchBackend.v"
INT_BACKEND = VSRCDIR / "execute/OooIntBackend.v"
ROB = VSRCDIR / "writeback/OooRob.v"
TESTBENCH = TBDIR / "tests/tb_ooo_core_top_glue.sv"


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
    dimensions: tuple[str, ...]


MUTATIONS = (
    Mutation(
        "fetch_lane1_payload_alias",
        (Edit(
            FETCH_DECODE,
            "  assign dec1_inst_o = (dec1_effective_resp_w != RESP_OK) ? "
            "32'h0000_0013 :\n"
            "                       dec1_compressed_w ? dec1_rvc_inst_w : "
            "dec1_raw32_w;",
            "  assign dec1_inst_o = (dec1_effective_resp_w != RESP_OK) ? "
            "32'h0000_0013 :\n"
            "                       dec1_compressed_w ? dec1_rvc_inst_w : "
            "dec0_inst_o;",
        ),),
        ("[V9A-IDENTITY][FAIL] boundary instruction payload mismatch",),
        ("fetch_identity", "payload_data"),
    ),
    Mutation(
        "decode_lane1_backend_cut",
        (Edit(
            DECODE_BACKEND,
            "  wire backend_dispatch1_valid_w =\n"
            "      dispatch1_valid_i &&",
            "  wire backend_dispatch1_valid_w =\n"
            "      1'b0 && dispatch1_valid_i &&",
        ),),
        ("decode acceptance disagrees with integer backend input",),
        ("decode_to_backend",),
    ),
    Mutation(
        "rename_lane1_sink_cut",
        (Edit(
            DISPATCH_BACKEND,
            ".rename1_valid_i(dispatch1_fire_w),",
            ".rename1_valid_i(1'b0),",
        ),),
        ("RenameMap sink fire disagrees with dispatch allocation",),
        ("rename_sink",),
    ),
    Mutation(
        "rob_lane1_sink_cut",
        (Edit(
            DISPATCH_BACKEND,
            ".dispatch1_valid_i(dispatch1_fire_w),",
            ".dispatch1_valid_i(1'b0),",
        ),),
        ("parent dispatch fire disagrees with ROB/IQ sink fire",),
        ("dispatch_width", "rob_sink"),
    ),
    Mutation(
        "iq_lane1_sink_cut",
        (Edit(
            DISPATCH_BACKEND,
            ".dispatch1_valid_i(dispatch1_fire_w && !dispatch1_fp_arith_w),",
            ".dispatch1_valid_i(1'b0 && !dispatch1_fp_arith_w),",
        ),),
        ("parent dispatch fire disagrees with ROB/IQ sink fire",),
        ("dispatch_width", "iq_sink"),
    ),
    Mutation(
        "issue_lane1_terminal_cut",
        (Edit(
            INT_BACKEND,
            "  assign issue1_exec_fire_w = issue1_fire_w &&\n"
            "                              !iq_issue1_plain_mem_class_w;",
            "  assign issue1_exec_fire_w = 1'b0 && issue1_fire_w &&\n"
            "                              !iq_issue1_plain_mem_class_w;",
        ),),
        ("IQ issue disagrees with physical ALU terminal acceptance",),
        ("issue_width",),
    ),
    Mutation(
        "ex1_stage_capture_cut",
        (Edit(
            INT_BACKEND,
            ".up_valid_i(ex1_up_valid_w),",
            ".up_valid_i(1'b0),",
        ),),
        ("ALU issue fire disagrees with EX stage capture",),
        ("ex_stage_capture", "execute_width"),
    ),
    Mutation(
        "ex1_stage_payload_alias",
        (Edit(
            INT_BACKEND,
            ".up_payload_i(ex1_up_payload_w),",
            ".up_payload_i(ex0_up_payload_w),",
        ),),
        ("EX1 next-cycle full ProducerId or payload mismatch",),
        ("ex_stage_payload", "payload_data", "pid_lifecycle"),
    ),
    Mutation(
        "wb1_rob_sink_cut",
        (Edit(
            INT_BACKEND,
            ".wb1_valid_i(wb1_valid_w),",
            ".wb1_valid_i(1'b0),",
        ),),
        ("authorized WB event disagrees with ROB completion sink",),
        ("wb_sink", "pid_lifecycle"),
    ),
    Mutation(
        "retire_lane1_event_cut",
        (Edit(
            ROB,
            "  assign commit1_valid_o = commit1_fire_w;",
            "  assign commit1_valid_o = 1'b0;",
        ),),
        ("ROB commit fire disagrees with retirement event",),
        ("retire_width", "pid_lifecycle"),
    ),
    Mutation(
        "lane1_immediate_alias",
        (Edit(
            DECODE_BACKEND,
            ".dispatch1_imm_i(fp_dispatch1_imm_w),",
            ".dispatch1_imm_i(fp_dispatch0_imm_w),",
        ),),
        ("execute result does not match PC-derived immediate",),
        ("payload_data",),
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def discover_sources() -> tuple[Path, ...]:
    variable = f"TB_SRCS_{TEST}"
    fragment = (
        "include Makefile\n"
        ".PHONY: print-v9a-sources\n"
        "print-v9a-sources:\n"
        f"\t@for source in $(sort $({variable})); do "
        "printf '%s\\n' \"$$source\"; done\n"
    )
    result = subprocess.run(
        ("make", "--no-print-directory", "-s", "-f", "-",
         "print-v9a-sources"),
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


def paired_tools() -> tuple[str, str]:
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    paired = str(Path(iverilog).with_name("vvp"))
    vvp = paired if Path(paired).exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("matching vvp not found")
    return iverilog, str(vvp)


def build_mutants(mutation: Mutation, case_dir: Path) -> dict[Path, Path]:
    texts: dict[Path, str] = {}
    for edit in mutation.edits:
        if edit.old == edit.new:
            raise RuntimeError(f"{mutation.name}: byte-identical edit")
        texts.setdefault(edit.target, edit.target.read_text(encoding="utf-8"))
        count = texts[edit.target].count(edit.old)
        if count != 1:
            raise RuntimeError(
                f"{mutation.name}: {edit.target.name} anchor count={count}")
        texts[edit.target] = texts[edit.target].replace(edit.old, edit.new, 1)
    replacements: dict[Path, Path] = {}
    for target, content in texts.items():
        mutant = case_dir / target.relative_to(VSRCDIR)
        mutant.parent.mkdir(parents=True, exist_ok=True)
        mutant.write_text(content, encoding="utf-8")
        if mutant.read_bytes() == target.read_bytes():
            raise RuntimeError(f"{mutation.name}: mutant is byte-identical")
        replacements[target.resolve()] = mutant
    return replacements


def run_mutation(
    mutation: Mutation,
    sources: tuple[Path, ...],
    iverilog: str,
    vvp: str,
    suite_run_id: str,
    work: Path,
) -> dict[str, object]:
    case_dir = work / mutation.name
    case_dir.mkdir(parents=True, exist_ok=True)
    replacements = build_mutants(mutation, case_dir)
    source_set = {path.resolve() for path in sources}
    if set(replacements) - source_set:
        raise RuntimeError(f"{mutation.name}: mutated RTL absent from source set")
    image = case_dir / f"{TEST}.vvp"
    compile_sources = tuple(
        replacements.get(path.resolve(), path) for path in sources)
    flags = (
        "-g2012", "-Wall", f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}", f"-I{TBDIR / 'common'}",
        "-DV9A_WIDTH_CONTINUITY_FOCUSED",
    )
    command = (
        iverilog, *flags, "-s", TOP, "-o", str(image),
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
    clean_pass = f"[PASS] {TEST}" in sim_text or "[RESULT] PASS" in sim_text
    rejected = (
        compiled.returncode == 0 and sim_rc not in (None, 0)
        and bool(witness) and not clean_pass
    )
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    log = EVIDENCE / f"{mutation.name}.log"
    log.write_text(
        f"[COMPILE] {shlex.join(command)}\n" +
        compiled.stdout + compiled.stderr +
        f"[RUN] {shlex.join((vvp, str(image)))}\n" + sim_text,
        encoding="utf-8",
    )
    targets = sorted({edit.target for edit in mutation.edits})
    original_hashes = {
        target.relative_to(REPO).as_posix(): sha256(target.read_bytes())
        for target in targets
    }
    mutant_hashes = {
        target.relative_to(REPO).as_posix():
            sha256(replacements[target.resolve()].read_bytes())
        for target in targets
    }
    result: dict[str, object] = {
        "name": mutation.name,
        "suite_run_id": suite_run_id,
        "test": TEST,
        "dimensions": list(mutation.dimensions),
        "targets": sorted(original_hashes),
        "original_sha256": original_hashes,
        "mutant_sha256": mutant_hashes,
        "mutant_nonidentical": all(
            original_hashes[path] != mutant_hashes[path]
            for path in original_hashes
        ),
        "compile_success": compiled.returncode == 0,
        "compile_rc": compiled.returncode,
        "sim_rc": sim_rc,
        "witness": witness,
        "dynamic_rejected": rejected,
        "log": log.relative_to(REPO).as_posix(),
    }
    print(
        f"[V9A-MUTATION][{'PASS' if rejected else 'FAIL'}] "
        f"name={mutation.name} compile_rc={compiled.returncode} "
        f"sim_rc={sim_rc} witness={witness}"
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite-run-id", required=True)
    args = parser.parse_args()
    if not re.fullmatch(
        r"v9a-di2-[0-9]{8}T[0-9]{6}Z-[0-9]+", args.suite_run_id
    ):
        raise ValueError("malformed local RV64 V9A suite run id")

    EVIDENCE.mkdir(parents=True, exist_ok=True)
    for path in EVIDENCE.glob("*.log"):
        path.unlink()
    summary_path = EVIDENCE / "summary.json"
    if summary_path.exists():
        summary_path.unlink()

    work = Path(tempfile.mkdtemp(prefix="rv64-v9a-width-mutations-"))
    try:
        iverilog, vvp = paired_tools()
        sources = discover_sources()
        production_paths = sorted({
            edit.target for mutation in MUTATIONS for edit in mutation.edits
        })
        before = {
            path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
            for path in production_paths
        }
        results = [
            run_mutation(
                mutation, sources, iverilog, vvp, args.suite_run_id, work)
            for mutation in MUTATIONS
        ]
        after = {
            path.relative_to(REPO).as_posix(): sha256(path.read_bytes())
            for path in production_paths
        }
    finally:
        if work.parent == Path(tempfile.gettempdir()) and work.name.startswith(
            "rv64-v9a-width-mutations-"
        ):
            shutil.rmtree(work)

    summary = {
        "schema": "v9a-width-continuity-mutations-v1",
        "suite_run_id": args.suite_run_id,
        "required": len(MUTATIONS),
        "compile_success": sum(
            bool(item["compile_success"]) for item in results),
        "dynamic_rejected": sum(
            bool(item["dynamic_rejected"]) for item in results),
        "source_sha256_before": before,
        "source_sha256_after": after,
        "source_unchanged": before == after,
        "testbench_sha256": sha256(TESTBENCH.read_bytes()),
        "results": results,
    }
    summary_path.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if not summary["source_unchanged"] or not all(
        item["dynamic_rejected"] for item in results
    ):
        return 1
    print(
        f"[V9A-MUTATIONS] compile_success={len(results)}/{len(results)} "
        f"dynamic_rejected={len(results)}/{len(results)} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
