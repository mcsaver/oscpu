#!/usr/bin/env python3
"""Run V11O product reachability plus legacy memory-buffer token evidence."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence

import run_v11m_memory_reservation_holder_semantic as runner_common


SCHEMA = "npc-rv64-v11o-memory-buffer-token-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11O_MEMORY_BUFFER_TOKEN_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11o_memory_buffer_token"
MATRIX_PASS = "[V11O-MEMORY-BUFFER-TOKEN-MATRIX][PASS]"
ORACLE_FAIL = "[V11O-MEMORY-BUFFER-TOKEN-ORACLE][FAIL]"
UNIT_IDS = ("memory-buffer-token",)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = runner_common.REGRESSIONS
GEN_WIDTHS = (1, 4)
BASELINE_MARKERS = {
    "[V11O-LEGACY-BIRTH-HOLD][PASS]": 2,
    "[V11O-LEGACY-TRANSFER-SQ-DEATH][PASS]": 1,
    "[V11O-LEGACY-CANCEL-AUTHORITY-DEATH][PASS]": 1,
}


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    expected_stage: str
    replacements: tuple[Replacement, ...]


@dataclass(frozen=True)
class Profile:
    name: str
    gen_width: int
    assertions: bool
    kind: str
    mutation: str | None = None
    expected_stage: str | None = None


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


CLEAR_ENTRY = """\
      if (mem_buffer_req_fire_w || mem_buffer_kill_w) begin
        mem_buffer_valid_q <= 1'b0;
"""
CANCEL_MASK = """\
  wire [31:0] mem_buffer_store_authority_end_mask_w =
      mem_buffer_cancel_w &&
      (mem_buffer_owner_kind_q == MEM_OWNER_STORE) ?
      (32'b1 << mem_buffer_owner_token_q) : 32'b0;
"""


MUTATIONS = (
    Mutation(
        "lane0-capture-token-high-truncate",
        "lane0-buffer-birth",
        (
            replacement(
                "        mem_buffer_owner_token_q <= "
                "mem_issue_res_owner_token_q;\n",
                "        mem_buffer_owner_token_q <= "
                "{3'b000, mem_issue_res_owner_token_q[1:0]};\n",
                "truncate token[4:2] on lane0 reservation handoff",
            ),
        ),
    ),
    Mutation(
        "lane1-capture-token-high-truncate",
        "lane1-buffer-birth",
        (
            replacement(
                "        mem_buffer_owner_token_q <= "
                "mem_issue1_res_owner_token_q;\n",
                "        mem_buffer_owner_token_q <= "
                "{3'b000, mem_issue1_res_owner_token_q[1:0]};\n",
                "truncate token[4:2] on lane1 reservation handoff",
            ),
        ),
    ),
    Mutation(
        "lane1-capture-token-x",
        "lane1-buffer-birth",
        (
            replacement(
                "        mem_buffer_owner_token_q <= "
                "mem_issue1_res_owner_token_q;\n",
                "        mem_buffer_owner_token_q <= {5{1'bx}};\n",
                "drive an unknown token into the lane1 buffer capture",
            ),
        ),
    ),
    Mutation(
        "hold-token-high-truncate",
        "lane1-buffer-hold",
        (
            replacement(
                CLEAR_ENTRY,
                """\
      if (mem_buffer_valid_q)
        mem_buffer_owner_token_q <=
            {3'b000, mem_buffer_owner_token_q[1:0]};
      if (mem_buffer_req_fire_w || mem_buffer_kill_w) begin
        mem_buffer_valid_q <= 1'b0;
""",
                "corrupt the resident token on a backpressured hold edge",
            ),
        ),
    ),
    Mutation(
        "transfer-token-high-truncate",
        "buffer-transfer-request",
        (
            replacement(
                "      grant_buffer_w ? mem_buffer_owner_token_q :\n",
                "      grant_buffer_w ? "
                "{3'b000, mem_buffer_owner_token_q[1:0]} :\n",
                "truncate the token at the buffer-to-request mux",
            ),
        ),
    ),
    Mutation(
        "transfer-clear-suppressed",
        "buffer-transfer-next-cycle-clear",
        (
            replacement(
                CLEAR_ENTRY,
                """\
      if (mem_buffer_req_fire_w || mem_buffer_kill_w) begin
        mem_buffer_valid_q <= 1'b1;
""",
                "retain buffer residency after an exact request transfer",
            ),
        ),
    ),
    Mutation(
        "cancel-authority-token-high-truncate",
        "buffer-selective-cancel",
        (
            replacement(
                CANCEL_MASK,
                """\
  wire [31:0] mem_buffer_store_authority_end_mask_w =
      mem_buffer_cancel_w &&
      (mem_buffer_owner_kind_q == MEM_OWNER_STORE) ?
      (32'b1 << {3'b000, mem_buffer_owner_token_q[1:0]}) : 32'b0;
""",
                "truncate the buffer token at STORE authority end",
            ),
        ),
    ),
    Mutation(
        "cancel-suppressed",
        "buffer-selective-cancel",
        (
            replacement(
                "  wire mem_buffer_cancel_w = mem_buffer_valid_q &&\n",
                "  wire mem_buffer_cancel_w = "
                "1'b0 && mem_buffer_valid_q &&\n",
                "suppress the local buffer cancellation event",
            ),
        ),
    ),
)


def apply_mutation(
    source: str, replacements: Sequence[Replacement]
) -> tuple[str, list[dict[str, object]]]:
    common_replacements = tuple(
        runner_common.Replacement(item.anchor, item.replacement, item.purpose)
        for item in replacements
    )
    return runner_common.apply_mutation(source, common_replacements)


def build_profiles() -> tuple[Profile, ...]:
    baselines = tuple(
        Profile(
            f"production-g{width}-"
            f"{'assert' if assertions else 'release'}",
            width,
            assertions,
            "baseline",
        )
        for width in GEN_WIDTHS
        for assertions in (True, False)
    )
    mutations = tuple(
        Profile(
            f"{mutation.name}-g{width}-release",
            width,
            False,
            "mutation",
            mutation=mutation.name,
            expected_stage=mutation.expected_stage,
        )
        for mutation in MUTATIONS
        for width in GEN_WIDTHS
    )
    return baselines + mutations


def marker_counts(text: str) -> dict[str, int]:
    result = {
        "tb_pass": text.count(TB_PASS),
        "matrix_pass": text.count(MATRIX_PASS),
        "oracle_fail": text.count(ORACLE_FAIL),
    }
    for marker in BASELINE_MARKERS:
        result[marker] = text.count(marker)
    return result


def oracle_failure_stages(text: str) -> list[str]:
    return re.findall(
        re.escape(ORACLE_FAIL)
        + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
        text,
    )


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    compile_timeout: bool,
    sim_rc: int | None,
    sim_timeout: bool,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    markers = marker_counts(log_text)
    stages = oracle_failure_stages(log_text)
    compile_ok = (
        compile_rc == 0 and not compile_timeout and artifact_exists
    )
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and not sim_timeout
            and markers["tb_pass"] == 1
            and markers["matrix_pass"] == 1
            and markers["oracle_fail"] == 0
            and not stages
            and all(
                markers[marker] == count
                for marker, count in BASELINE_MARKERS.items()
            )
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and not sim_timeout
            and markers["oracle_fail"] == 1
            and stages == [profile.expected_stage]
            and markers["tb_pass"] == 0
            and markers["matrix_pass"] == 0
        )
    return passed, markers


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        ["make", "-s", "print-v11o-memory-buffer-token-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.split("=", 1)[1]).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.split("=", 1)[1]).resolve())
    if include_dir is None or not sources:
        raise RuntimeError("V11O Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = runner_common.subprocess.run(
        [
            "make",
            "-s",
            "print-v11o-memory-buffer-token-regression-context",
        ],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    common: list[Path] = []
    sources = {test: [] for test in REGRESSIONS}
    prefix = "REGRESSION_SOURCE_"
    for line in completed.stdout.splitlines():
        if line.startswith("REGRESSION_COMMON="):
            common.append(Path(line.split("=", 1)[1]).resolve())
        elif line.startswith(prefix):
            key, raw = line.split("=", 1)
            test = key[len(prefix):]
            if test not in sources:
                raise RuntimeError(f"unknown regression context: {test}")
            sources[test].append(Path(raw).resolve())
    result = {
        test: tuple(sorted({*paths, *common}))
        for test, paths in sources.items()
    }
    if not common or any(not paths for paths in result.values()):
        raise RuntimeError("V11O regression context is incomplete")
    return result


def build_variants(
    *,
    result_dir: Path,
    rtl_path: Path,
    repo_root: Path,
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    source = rtl_path.read_text(encoding="utf-8")
    variants: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = result_dir / "variants" / mutation.name / rtl_path.name
        variant.parent.mkdir(parents=True, exist_ok=True)
        variant.write_text(mutated, encoding="utf-8")
        variants[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_ids": list(UNIT_IDS),
                "expected_stage": mutation.expected_stage,
                "target": runner_common.repo_path(rtl_path, repo_root),
                "production_sha256": runner_common.sha256_file(rtl_path),
                "variant": runner_common.repo_path(variant, repo_root),
                "variant_sha256": runner_common.sha256_file(variant),
                "compile_success_required": True,
                "assertions": False,
                "receipts": receipts,
            }
        )
    runner_common.write_json(result_dir / "variants/manifest.json", records)
    return variants, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    rtl_path: Path,
    variants: dict[str, Path],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    profile_dir.mkdir(parents=True, exist_ok=True)
    artifact = profile_dir / f"{TOP}.vvp"
    sources = [
        variants[profile.mutation]
        if profile.mutation and path == rtl_path
        else path
        for path in production_sources
    ]
    defines = [
        FOCUSED_DEFINE,
        f"-DOOO_PRODUCER_GEN_W={profile.gen_width}",
    ]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    compile_command = [
        str(iverilog),
        "-g2012",
        "-Wall",
        f"-I{repo_root / 'npc/rv64/vsrc'}",
        f"-I{include_dir}",
        f"-I{testbench_dir / 'common'}",
        *defines,
        "-s",
        TOP,
        "-o",
        str(artifact),
        *(str(path) for path in sources),
    ]
    crc, cout, cerr, cseconds, ctimeout = runner_common.run_command(
        compile_command,
        cwd=testbench_dir,
        timeout_seconds=timeout_seconds,
    )
    (profile_dir / "compile.stdout").write_text(cout, encoding="utf-8")
    (profile_dir / "compile.stderr").write_text(cerr, encoding="utf-8")
    (profile_dir / "compile.rc").write_text(f"{crc}\n", encoding="utf-8")
    src, sout, serr, sseconds, stimeout = (
        None,
        "",
        "",
        0.0,
        False,
    )
    if crc == 0 and artifact.is_file():
        src, sout, serr, sseconds, stimeout = runner_common.run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    log = profile_dir / "sim.log"
    log.write_text(sout + serr, encoding="utf-8")
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if src is None else f"{src}\n",
        encoding="utf-8",
    )
    exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, markers = evaluate_profile(
        profile,
        compile_rc=crc,
        compile_timeout=ctimeout,
        sim_rc=src,
        sim_timeout=stimeout,
        log_text=sout + serr,
        artifact_exists=exists,
    )
    record = {
        "profile": profile.name,
        "producer_gen_width": profile.gen_width,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "expected_stage": profile.expected_stage,
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": crc,
            "timeout": ctimeout,
            "elapsed_seconds": round(cseconds, 6),
            "command": compile_command,
            "defines": defines,
            "artifact": runner_common.repo_path(artifact, repo_root),
            "artifact_exists": exists,
            "artifact_sha256": (
                runner_common.sha256_file(artifact) if exists else None
            ),
        },
        "simulation": {
            "rc": src,
            "timeout": stimeout,
            "elapsed_seconds": round(sseconds, 6),
            "log": runner_common.repo_path(log, repo_root),
            "log_sha256": runner_common.sha256_file(log),
        },
        "markers": markers,
        "compile_source_manifest": runner_common.source_manifest(
            sources, repo_root
        ),
    }
    runner_common.write_json(profile_dir / "profile.json", record)
    return record


def run_product_reachability(
    *,
    repo_root: Path,
    result_dir: Path,
    timeout_seconds: int,
) -> tuple[bool, dict[str, Any]]:
    graph_dir = result_dir / "product-reachability/current-instance-graph"
    graph_dir.mkdir(parents=True, exist_ok=True)
    instance_tool = (
        repo_root
        / "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
    )
    graph_result = graph_dir / "holder-instance-graph.json"
    graph_receipt = graph_dir / "yosys-instance-graph-receipt.json"
    full_graph = graph_dir / "yosys-instance-graph.full.json.gz"
    graph_script = graph_dir / "yosys-instance-graph.ys"
    graph_log = graph_dir / "yosys-instance-graph.log"
    graph_command = [
        sys.executable,
        str(instance_tool),
        "--repo-root",
        str(repo_root),
        "--elaborate",
        "--timeout-seconds",
        str(max(timeout_seconds, 180)),
        "--json-out",
        str(graph_result),
        "--receipt-out",
        str(graph_receipt),
        "--full-json-out",
        str(full_graph),
        "--script-out",
        str(graph_script),
        "--log-out",
        str(graph_log),
    ]
    grc, gout, gerr, gseconds, gtimeout = runner_common.run_command(
        graph_command,
        cwd=repo_root,
        timeout_seconds=max(timeout_seconds, 300),
    )
    (graph_dir / "command.stdout").write_text(gout, encoding="utf-8")
    (graph_dir / "command.stderr").write_text(gerr, encoding="utf-8")
    (graph_dir / "command.rc").write_text(f"{grc}\n", encoding="utf-8")

    checker = (
        repo_root
        / "npc/rv64/eval/ppa/tools/"
        "memory_buffer_product_reachability.py"
    )
    checker_test = (
        repo_root
        / "npc/rv64/eval/ppa/tests/"
        "test_memory_buffer_product_reachability.py"
    )
    test_dir = result_dir / "product-reachability/static-negative-tests"
    test_dir.mkdir(parents=True, exist_ok=True)
    trc, tout, terr, tseconds, ttimeout = runner_common.run_command(
        [sys.executable, str(checker_test), "-q"],
        cwd=repo_root,
        timeout_seconds=timeout_seconds,
    )
    (test_dir / "stdout.log").write_text(tout, encoding="utf-8")
    (test_dir / "stderr.log").write_text(terr, encoding="utf-8")
    (test_dir / "returncode.txt").write_text(f"{trc}\n", encoding="utf-8")

    reachability_receipt = (
        result_dir / "product-reachability/receipt.json"
    )
    checker_command = [
        sys.executable,
        str(checker),
        "--repo-root",
        str(repo_root),
        "--instance-graph-receipt",
        str(graph_receipt),
        "--full-yosys-json",
        str(full_graph),
        "--output",
        str(reachability_receipt),
    ]
    crc, cout, cerr, cseconds, ctimeout = runner_common.run_command(
        checker_command,
        cwd=repo_root,
        timeout_seconds=timeout_seconds,
    )
    checker_log_dir = result_dir / "product-reachability/checker"
    checker_log_dir.mkdir(parents=True, exist_ok=True)
    (checker_log_dir / "stdout.log").write_text(cout, encoding="utf-8")
    (checker_log_dir / "stderr.log").write_text(cerr, encoding="utf-8")
    (checker_log_dir / "returncode.txt").write_text(
        f"{crc}\n", encoding="utf-8"
    )
    payload = (
        json.loads(reachability_receipt.read_text(encoding="utf-8"))
        if reachability_receipt.is_file()
        else {}
    )
    passed = (
        grc == 0
        and not gtimeout
        and trc == 0
        and not ttimeout
        and crc == 0
        and not ctimeout
        and payload.get("status") == "PASS"
    )
    return passed, {
        "status": "PASS" if passed else "FAIL",
        "graph": {
            "command": graph_command,
            "rc": grc,
            "timeout": gtimeout,
            "elapsed_seconds": round(gseconds, 6),
            "result": runner_common.artifact_record(
                graph_result, repo_root
            ) if graph_result.is_file() else None,
            "receipt": runner_common.artifact_record(
                graph_receipt, repo_root
            ) if graph_receipt.is_file() else None,
            "full_json": runner_common.artifact_record(
                full_graph, repo_root
            ) if full_graph.is_file() else None,
        },
        "static_negative_tests": {
            "command": [sys.executable, str(checker_test), "-q"],
            "rc": trc,
            "timeout": ttimeout,
            "elapsed_seconds": round(tseconds, 6),
            "test_count": 8,
        },
        "checker": {
            "command": checker_command,
            "rc": crc,
            "timeout": ctimeout,
            "elapsed_seconds": round(cseconds, 6),
            "receipt": runner_common.artifact_record(
                reachability_receipt, repo_root
            ) if reachability_receipt.is_file() else None,
        },
        "receipt_payload": payload,
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc/rv64/testbench"
    rtl_path = (
        repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
    ).resolve()
    status_path = result_dir / "runner.status"
    if result_dir.exists() and any(result_dir.iterdir()):
        if not args.overwrite:
            print(f"result directory is not empty: {result_dir}")
            return 2
        shutil.rmtree(result_dir)
    result_dir.mkdir(parents=True, exist_ok=True)
    runner_common.atomic_status(status_path, "RUNNING")
    try:
        iverilog, vvp = runner_common.resolve_tools()
        include_dir, production_sources = load_make_context(testbench_dir)
        regressions = load_regression_context(testbench_dir)
        if rtl_path not in production_sources:
            raise RuntimeError("production OooIntBackend.v is absent")
        product_paths = [
            repo_root / relative
            for relative in (
                "npc/rv64/vsrc/core/NpcCoreTop.v",
                "npc/rv64/vsrc/core/OooCoreTopGlue.v",
                "npc/rv64/vsrc/execute/OooExecuteBackend.v",
                "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
                "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
            )
        ]
        runner_inputs = [
            *production_sources,
            *product_paths,
            include_dir / "define.v",
            testbench_dir / "Makefile",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11o_memory_buffer_token_semantic.py"
            ).resolve(),
            Path(runner_common.__file__).resolve(),
            repo_root
            / "npc/rv64/eval/ppa/tools/"
            "memory_buffer_product_reachability.py",
            repo_root
            / "npc/rv64/eval/ppa/tests/"
            "test_memory_buffer_product_reachability.py",
            repo_root
            / "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py",
            *(
                path
                for test in REGRESSIONS
                for path in regressions[test]
            ),
        ]
        before = runner_common.source_manifest(runner_inputs, repo_root)
        runner_common.write_sha256_manifest(
            result_dir / "source-before.sha256", before
        )
        product_ok, product_record = run_product_reachability(
            repo_root=repo_root,
            result_dir=result_dir,
            timeout_seconds=args.timeout_seconds,
        )
        variants, variant_records = build_variants(
            result_dir=result_dir,
            rtl_path=rtl_path,
            repo_root=repo_root,
        )
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                rtl_path=rtl_path,
                variants=variants,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            print(f"{profile.name}: {record['status']}")
        regression_ok, regression_records = runner_common.run_regressions(
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            contexts=regressions,
            timeout_seconds=args.timeout_seconds,
        )
        after = runner_common.source_manifest(runner_inputs, repo_root)
        runner_common.write_sha256_manifest(
            result_dir / "source-after.sha256", after
        )
        binding_match = before == after
        profiles_pass = sum(
            item["status"] == "PASS" for item in profile_records
        )
        regressions_pass = sum(
            item["status"] == "PASS" for item in regression_records
        )
        overall = (
            binding_match
            and product_ok
            and profiles_pass == len(profile_records)
            and regression_ok
        )
        summary: dict[str, Any] = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": runner_common.current_design_id(repo_root),
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "legacy_enable_dual_mem": 0,
                "product_enable_dual_mem": 1,
                "producer_gen_widths": list(GEN_WIDTHS),
                "profile_count": len(profile_records),
                "baseline_profile_count": 4,
                "mutation_count": len(MUTATIONS),
                "mutation_profile_count": len(MUTATIONS)
                * len(GEN_WIDTHS),
                "regression_count": len(REGRESSIONS),
                "full_system_run": False,
            },
            "tools": {
                "iverilog": str(iverilog),
                "iverilog_sha256": runner_common.sha256_file(iverilog),
                "vvp": str(vvp),
                "vvp_sha256": runner_common.sha256_file(vvp),
            },
            "production": {
                "rtl": runner_common.repo_path(rtl_path, repo_root),
                "rtl_sha256": runner_common.sha256_file(rtl_path),
                "focused_testbench": runner_common.repo_path(
                    testbench_dir / "tests/tb_ooo_int_backend.sv",
                    repo_root,
                ),
                "focused_testbench_sha256": runner_common.sha256_file(
                    testbench_dir / "tests/tb_ooo_int_backend.sv"
                ),
                "product_instances": [PRODUCT_INSTANCE],
            },
            "binding": {
                "pre_post_match": binding_match,
                "source_before": runner_common.artifact_record(
                    result_dir / "source-before.sha256", repo_root
                ),
                "source_after": runner_common.artifact_record(
                    result_dir / "source-after.sha256", repo_root
                ),
            },
            "product_reachability": product_record,
            "legacy_dynamic_oracle": {
                "stimulus_owned_token_28_29": True,
                "expected_token_uses_buffer_dut_state": False,
                "four_state_exact_comparison": True,
                "producer_gen_width_one_and_four": True,
                "lane0_birth": True,
                "lane1_birth": True,
                "three_cycle_hold_each": True,
                "buffer_to_miq_transfer": True,
                "sq_physical_write_b_commit_death": True,
                "selective_cancel_authority_end_death": True,
                "release_mode_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": profiles_pass,
                "profiles_fail": len(profile_records) - profiles_pass,
                "baseline_profiles_total": 4,
                "mutations_total": len(MUTATIONS),
                "mutation_profiles_total": len(MUTATIONS)
                * len(GEN_WIDTHS),
                "product_static_negative_tests": 8,
                "regressions_total": len(regression_records),
                "regressions_pass": regressions_pass,
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "semantic_units": list(UNIT_IDS),
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11o": False,
                    "run": False,
                    "current_whole_design_recertification": (
                        "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                        "PRODUCTION_RTL_DELTA"
                    ),
                },
            },
            "promotion": {
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        runner_common.write_json(result_dir / "summary.json", summary)
        (result_dir / "summary.md").write_text(
            "\n".join(
                [
                    "# V11O memory-buffer token semantic evidence",
                    "",
                    f"- status: {summary['status']}",
                    (
                        "- product reachability: "
                        f"{product_record['status']}"
                    ),
                    (
                        "- focused profiles: "
                        f"{profiles_pass}/{len(profile_records)} PASS"
                    ),
                    (
                        "- compile-success mutations: "
                        f"{len(MUTATIONS)} cases × {len(GEN_WIDTHS)} widths"
                    ),
                    (
                        "- regressions: "
                        f"{regressions_pass}/{len(regression_records)} PASS"
                    ),
                    (
                        "- source pre/post: "
                        f"{'MATCH' if binding_match else 'DRIFT'}"
                    ),
                    "- production RTL change: none",
                    "- A3 original FAIL retained; checker replay remains separate",
                    "- whole architecture: RED",
                    "- PPA: UNPROMOTED",
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        runner_common.atomic_status(
            status_path, "PASS" if overall else "FAIL"
        )
        return 0 if overall else 1
    except Exception as exc:
        runner_common.write_json(
            result_dir / "runner-error.json",
            {
                "schema": SCHEMA,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        )
        runner_common.atomic_status(status_path, "FAIL")
        print(f"V11O runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
