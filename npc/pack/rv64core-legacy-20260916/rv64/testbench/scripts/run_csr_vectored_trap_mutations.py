#!/usr/bin/env python3
"""Run compile-success negative RTL variants for the CsrFile vector contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Sequence


@dataclass(frozen=True)
class Mutation:
    mutation_id: str
    rtl_effect: str
    old: str
    new: str
    required_assertions: tuple[str, ...]


MUTATIONS = (
    Mutation(
        mutation_id="direct_only_target",
        rtl_effect="强制所有陷阱跳转到 tvec BASE，移除中断向量偏移",
        old="""\
  assign trap_target_o =
      trap_selected_tvec_base_w +
      (trap_selected_vectored_w ? trap_selected_vector_offset_w :
                                  {`XLEN{1'b0}});
""",
        new="""\
  assign trap_target_o = trap_selected_tvec_base_w;
""",
        required_assertions=("[VECTORED-TRAP-A2-TARGET]",),
    ),
    Mutation(
        mutation_id="vector_sync_exception",
        rtl_effect="在 MODE=1 时错误地给同步异常也施加 4×cause 偏移",
        old="""\
  wire trap_selected_vectored_w =
      trap_selected_valid_w && trap_selected_is_irq_w &&
      (trap_selected_tvec_w[1:0] == 2'b01);
""",
        new="""\
  wire trap_selected_vectored_w =
      trap_selected_valid_w &&
      (trap_selected_tvec_w[1:0] == 2'b01);
""",
        required_assertions=("[VECTORED-TRAP-A2-TARGET]",),
    ),
    Mutation(
        mutation_id="force_machine_tvec",
        rtl_effect="忽略选中陷阱的委托级别并强制使用 mtvec",
        old="""\
  wire [`XLEN-1:0] trap_selected_tvec_w =
      trap_selected_to_s_w ? csr_stvec_q : csr_mtvec_q;
""",
        new="""\
  wire [`XLEN-1:0] trap_selected_tvec_w = csr_mtvec_q;
""",
        required_assertions=("[VECTORED-TRAP-A2-TARGET]",),
    ),
    Mutation(
        mutation_id="reserved_mode_passthrough",
        rtl_effect="保留 mtvec/stvec 的保留 MODE=2/3，而不执行 WARL 钳位",
        old="""\
        default: tvec_warl_value = {value[`XLEN-1:2], 2'b00};
""",
        new="""\
        default: tvec_warl_value = value;
""",
        required_assertions=(
            "[VECTORED-TRAP-A3-MTVEC-MODE]",
            "[VECTORED-TRAP-A4-STVEC-MODE]",
        ),
    ),
    Mutation(
        mutation_id="exception_over_memory_priority",
        rtl_effect="把同时到达的 trap 源优先级从 mem>ex>irq 改为 ex>mem>irq",
        old="""\
  wire trap_selected_mem_w = trap_mem_valid_i;
  wire trap_selected_ex_w = !trap_mem_valid_i && trap_ex_valid_i;
  wire trap_selected_irq_w =
      !trap_mem_valid_i && !trap_ex_valid_i && trap_irq_valid_i;
""",
        new="""\
  wire trap_selected_mem_w = !trap_ex_valid_i && trap_mem_valid_i;
  wire trap_selected_ex_w = trap_ex_valid_i;
  wire trap_selected_irq_w =
      !trap_mem_valid_i && !trap_ex_valid_i && trap_irq_valid_i;
""",
        required_assertions=("[VECTORED-TRAP-A1-SELECTED-RECORD]",),
    ),
    Mutation(
        mutation_id="vector_offset_plus_four",
        rtl_effect="把中断向量偏移从 4×cause 改为 4×cause+4",
        old="""\
  wire [`XLEN-1:0] trap_selected_vector_offset_w =
      {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_selected_cause_w} << 2;
""",
        new="""\
  wire [`XLEN-1:0] trap_selected_vector_offset_w =
      ({{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_selected_cause_w} << 2) +
      64'd4;
""",
        required_assertions=("[VECTORED-TRAP-A2-TARGET]",),
    ),
    Mutation(
        mutation_id="drop_nondelegated_supervisor_irq",
        rtl_effect=(
            "从 M 级候选集合移除未委托的 SSIP/STIP/SEIP，重现 "
            "mtvec MODE=1 软件中断等待无进展"
        ),
        old="""\
  wire [`XLEN-1:0] m_irq_enabled_pending_w =
      routed_machine_irq_enabled_pending_w |
      (supervisor_irq_enabled_pending_w & ~delegated_s_irq_mask_w);
""",
        new="""\
  wire [`XLEN-1:0] m_irq_enabled_pending_w =
      routed_machine_irq_enabled_pending_w;
""",
        required_assertions=("[VECTORED-TRAP-A5-IRQ-ROUTING]",),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def rtl_binding(repo_root: Path) -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (repo_root / "npc" / "rv64" / "vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    if not files:
        raise ValueError("local RV64 RTL source set is empty")
    entries = {
        path.relative_to(repo_root).as_posix(): sha256_bytes(path.read_bytes())
        for path in files
    }
    canonical = json.dumps(
        entries,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return sha256_bytes(canonical), entries


def apply_exact_once(source: str, mutation: Mutation) -> str:
    count = source.count(mutation.old)
    if count != 1:
        raise ValueError(
            f"{mutation.mutation_id}: expected one RTL anchor, observed {count}"
        )
    return source.replace(mutation.old, mutation.new, 1)


def tool_first_line(command: Sequence[str]) -> str:
    result = subprocess.run(
        command,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return result.stdout.splitlines()[0] if result.stdout.splitlines() else ""


def run_mutation(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    source_text: str,
    mutation: Mutation,
) -> dict[str, object]:
    mutation_dir = result_dir / mutation.mutation_id
    rtl_dir = mutation_dir / "rtl"
    build_dir = mutation_dir / "build"
    run_dir = mutation_dir / "run"
    log_path = run_dir / "logs" / "tb_csr_file_vectored_trap.log"
    rtl_dir.mkdir(parents=True, exist_ok=True)
    run_dir.mkdir(parents=True, exist_ok=True)

    mutated_text = apply_exact_once(source_text, mutation)
    mutant_path = rtl_dir / "CsrFile.v"
    mutant_path.write_text(mutated_text, encoding="utf-8")

    command = [
        "make",
        "-B",
        f"BUILD_DIR={build_dir}",
        f"RESULT_DIR={run_dir}",
        f"RTL_CSR_FILE={mutant_path}",
        str(log_path),
    ]
    completed = subprocess.run(
        command,
        cwd=testbench_dir,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    (mutation_dir / "driver.stdout").write_text(completed.stdout, encoding="utf-8")
    (mutation_dir / "driver.stderr").write_text(completed.stderr, encoding="utf-8")

    vvp_path = build_dir / "tb_csr_file_vectored_trap.vvp"
    compile_succeeded = vvp_path.is_file() and vvp_path.stat().st_size > 0
    log_text = log_path.read_text(encoding="utf-8") if log_path.is_file() else ""
    assertion_counts = {
        marker: log_text.count(marker) for marker in mutation.required_assertions
    }
    required_assertions_seen = all(count > 0 for count in assertion_counts.values())
    functional_fail_marker_count = sum(
        line.startswith("[VECTORED-TRAP-G1-CSR-FILE] ")
        and line.endswith(" FAIL")
        for line in log_text.splitlines()
    )
    functional_check_fail_count = log_text.count("[CHECK-FAIL]")
    result_fail_count = log_text.count("[RESULT] FAIL")
    exact_test_pass_count = sum(
        line == "[PASS] tb_csr_file_vectored_trap"
        for line in log_text.splitlines()
    )
    result_pass_count = log_text.count("[RESULT] PASS")
    rejected = (
        completed.returncode != 0
        and compile_succeeded
        and required_assertions_seen
        and functional_fail_marker_count == 1
        and functional_check_fail_count > 0
        and result_fail_count == 1
        and exact_test_pass_count == 0
        and result_pass_count == 0
    )

    return {
        "mutation_id": mutation.mutation_id,
        "rtl_effect": mutation.rtl_effect,
        "mutant_path": str(mutant_path.relative_to(repo_root)),
        "mutant_sha256": sha256_bytes(mutant_path.read_bytes()),
        "execution": {
            "command": command,
            "mode": "local-rv64-iverilog-negative",
            "purpose": "编译并运行 CsrFile 向量陷阱负向 RTL 版本",
            "cwd": str(testbench_dir.relative_to(repo_root)),
        },
        "driver_rc": completed.returncode,
        "compile_succeeded": compile_succeeded,
        "compile_artifact": str(vvp_path.relative_to(repo_root)),
        "compile_artifact_sha256": (
            sha256_bytes(vvp_path.read_bytes()) if compile_succeeded else None
        ),
        "log_path": str(log_path.relative_to(repo_root)),
        "required_assertion_counts": assertion_counts,
        "functional_fail_marker_count": functional_fail_marker_count,
        "functional_check_fail_count": functional_check_fail_count,
        "result_fail_count": result_fail_count,
        "exact_test_pass_count": exact_test_pass_count,
        "result_pass_count": result_pass_count,
        "rejected": rejected,
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build and reject compile-success CsrFile vector-contract RTL variants"
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument(
        "--reuse-result-dir",
        action="store_true",
        help="overwrite the bounded mutation evidence paths in an existing directory",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    source_path = repo_root / "npc" / "rv64" / "vsrc" / "core" / "CsrFile.v"

    if (
        result_dir.exists()
        and any(result_dir.iterdir())
        and not args.reuse_result_dir
    ):
        print(f"result directory is not empty: {result_dir}", file=sys.stderr)
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)

    source_bytes_before = source_path.read_bytes()
    source_text = source_bytes_before.decode("utf-8")
    source_sha_before = sha256_bytes(source_bytes_before)
    design_sha_before, rtl_files_before = rtl_binding(repo_root)

    try:
        results = [
            run_mutation(
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                source_text=source_text,
                mutation=mutation,
            )
            for mutation in MUTATIONS
        ]
    except (OSError, UnicodeError, ValueError) as error:
        print(f"mutation run failed: {error}", file=sys.stderr)
        return 2

    source_sha_after = sha256_bytes(source_path.read_bytes())
    design_sha_after, rtl_files_after = rtl_binding(repo_root)
    all_rejected = all(bool(item["rejected"]) for item in results)
    manifest = {
        "schema_version": 1,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract": {
            "rtl_object": str(source_path.relative_to(repo_root)),
            "testbench": "npc/rv64/testbench/tests/tb_csr_file_vectored_trap.sv",
            "cycle_observation": (
                "IRQ routing, raw trap request, selected target, WARL readback, "
                "exact PASS/FAIL"
            ),
            "compile_configuration": "iverilog -g2012 -Wall -DOOO_ASSERT",
        },
        "tools": {
            "python": sys.version.splitlines()[0],
            "iverilog": tool_first_line(["iverilog", "-V"]),
            "make": tool_first_line(["make", "--version"]),
        },
        "source_sha256_before": source_sha_before,
        "source_sha256_after": source_sha_after,
        "source_unchanged": source_sha_before == source_sha_after,
        "rtl_design_id_before": f"sha256:{design_sha_before}",
        "rtl_design_id_after": f"sha256:{design_sha_after}",
        "rtl_source_set": {
            "design_id": f"sha256:{design_sha_before}",
            "sha256": design_sha_before,
            "file_count": len(rtl_files_before),
            "files": rtl_files_before,
        },
        "rtl_source_set_unchanged": (
            design_sha_before == design_sha_after
            and rtl_files_before == rtl_files_after
        ),
        "mutations": results,
        "summary": {
            "total": len(results),
            "compile_succeeded": sum(
                bool(item["compile_succeeded"]) for item in results
            ),
            "rejected": sum(bool(item["rejected"]) for item in results),
            "all_rejected": all_rejected,
        },
    }
    manifest_path = result_dir / "mutation-evidence.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(
        "[VECTORED-TRAP-G5-MUTATIONS] "
        f"total={len(results)} "
        f"compile_succeeded={manifest['summary']['compile_succeeded']} "
        f"rejected={manifest['summary']['rejected']} "
        f"source_unchanged={int(manifest['source_unchanged'])} "
        f"rtl_source_set_unchanged={int(manifest['rtl_source_set_unchanged'])} "
        f"{'PASS' if all_rejected and manifest['source_unchanged'] and manifest['rtl_source_set_unchanged'] else 'FAIL'}"
    )
    print(manifest_path)
    return (
        0
        if (
            all_rejected
            and source_sha_before == source_sha_after
            and design_sha_before == design_sha_after
            and rtl_files_before == rtl_files_after
        )
        else 1
    )


if __name__ == "__main__":
    raise SystemExit(main())
