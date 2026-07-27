#!/usr/bin/env python3
"""Build fail-closed evidence for the local RV64 vectored-trap contract."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import sys
from datetime import datetime, timezone
from typing import Any, Sequence


SCHEMA = "npc-rv64-vectored-trap-evidence-v1"
RUN_ID = "2026-07-26-rv64-v9u-vectored-trap-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-vectored-trap"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_PATH = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_vectored_trap", ARCH_PATH
)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

MUTATION_RUNNER = (
    REPO / "npc/rv64/testbench/scripts/run_csr_vectored_trap_mutations.py"
)
MUTATION_SPEC = importlib.util.spec_from_file_location(
    "vectored_trap_mutation_model", MUTATION_RUNNER
)
assert MUTATION_SPEC is not None and MUTATION_SPEC.loader is not None
mutation_model = importlib.util.module_from_spec(MUTATION_SPEC)
sys.modules[MUTATION_SPEC.name] = mutation_model
MUTATION_SPEC.loader.exec_module(mutation_model)

FOCUSED_MARKER = (
    "[VECTORED-TRAP-G1-CSR-FILE] cases=13 warl=3 irq_routing=3 "
    "m_irq=2 m_sync=1 source_priority=2 s_irq=1 s_sync=1 PASS"
)
PROGRAM_MARKERS = {
    "m_irq": (
        "[VECTORED-TRAP-G2-M-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 "
        "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
        "wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
        "cause=7 handler_body=1 backend_drained=1 PASS"
    ),
    "s_irq": (
        "[VECTORED-TRAP-G3-S-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 "
        "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
        "wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
        "cause=9 handler_body=1 backend_drained=1 PASS"
    ),
    "m_sync": (
        "[VECTORED-TRAP-G4-M-SYNC] trap_mem=0 trap_ex=1 trap_irq=0 "
        "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
        "wrong_vector_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
        "cause=11 handler_body=1 backend_drained=1 PASS"
    ),
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_file(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {resolved}")
    if path.is_symlink() or not resolved.is_file():
        raise ValueError(f"artifact is not a regular non-symlink file: {path}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    resolved = safe_file(root, path)
    return {
        "kind": kind,
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256_file(resolved),
    }


def require_exact_line(text: str, marker: str, label: str) -> None:
    if text.splitlines().count(marker) != 1:
        raise ValueError(f"{label}: expected one exact marker {marker}")


def require_pass_log(
    path: pathlib.Path,
    test_name: str,
    design_id: str,
) -> str:
    text = path.read_text(encoding="utf-8")
    require_exact_line(text, f"[PASS] {test_name}", test_name)
    require_exact_line(text, "[RESULT] PASS", test_name)
    require_exact_line(text, f"[RTL-DESIGN-ID] {design_id}", test_name)
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:"):
        if marker in text:
            raise ValueError(f"{test_name}: unexpected failure marker {marker}")
    return text


def validate_mutations(
    root: pathlib.Path,
    path: pathlib.Path,
    design_id: str,
    rtl_files: dict[str, str],
) -> tuple[dict[str, int], list[dict[str, str]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    expected_top_keys = {
        "schema_version",
        "generated_at_utc",
        "contract",
        "tools",
        "source_sha256_before",
        "source_sha256_after",
        "source_unchanged",
        "rtl_design_id_before",
        "rtl_design_id_after",
        "rtl_source_set",
        "rtl_source_set_unchanged",
        "mutations",
        "summary",
    }
    if set(payload) != expected_top_keys or payload.get("schema_version") != 1:
        raise ValueError("mutation manifest schema or key set drifted")

    csr_path = root / "npc/rv64/vsrc/core/CsrFile.v"
    csr_sha = sha256_file(csr_path)
    expected_source_set = {
        "design_id": design_id,
        "sha256": design_id.removeprefix("sha256:"),
        "file_count": len(rtl_files),
        "files": rtl_files,
    }
    if not (
        payload.get("source_sha256_before") == csr_sha
        and payload.get("source_sha256_after") == csr_sha
        and payload.get("source_unchanged") is True
        and payload.get("rtl_design_id_before") == design_id
        and payload.get("rtl_design_id_after") == design_id
        and payload.get("rtl_source_set") == expected_source_set
        and payload.get("rtl_source_set_unchanged") is True
    ):
        raise ValueError("mutation manifest production RTL binding is stale")

    rows = payload.get("mutations")
    if not isinstance(rows, list):
        raise ValueError("mutation rows are missing")
    by_id = {
        row.get("mutation_id"): row for row in rows if isinstance(row, dict)
    }
    specs = {
        mutation.mutation_id: mutation for mutation in mutation_model.MUTATIONS
    }
    if len(rows) != len(specs) or set(by_id) != set(specs):
        raise ValueError("mutation inventory is not exact")

    source_text = csr_path.read_text(encoding="utf-8")
    log_artifacts: list[dict[str, str]] = []
    for mutation_id, spec in specs.items():
        row = by_id[mutation_id]
        mutant_path = safe_file(root, root / row.get("mutant_path", ""))
        reconstructed = mutation_model.apply_exact_once(source_text, spec)
        if (
            sha256_bytes(reconstructed.encode("utf-8"))
            != row.get("mutant_sha256")
            or sha256_file(mutant_path) != row.get("mutant_sha256")
        ):
            raise ValueError(f"{mutation_id}: mutant does not reconstruct")

        vvp_path = safe_file(root, root / row.get("compile_artifact", ""))
        if not (
            row.get("compile_succeeded") is True
            and row.get("driver_rc") != 0
            and row.get("rejected") is True
            and row.get("compile_artifact_sha256") == sha256_file(vvp_path)
            and row.get("functional_fail_marker_count") == 1
            and isinstance(row.get("functional_check_fail_count"), int)
            and row.get("functional_check_fail_count") > 0
            and row.get("result_fail_count") == 1
            and row.get("exact_test_pass_count") == 0
            and row.get("result_pass_count") == 0
        ):
            raise ValueError(f"{mutation_id}: rejection accounting is incomplete")

        assertion_counts = row.get("required_assertion_counts")
        if not (
            isinstance(assertion_counts, dict)
            and set(assertion_counts) == set(spec.required_assertions)
            and all(
                isinstance(count, int) and count > 0
                for count in assertion_counts.values()
            )
        ):
            raise ValueError(f"{mutation_id}: assertion rejection is incomplete")

        log_path = safe_file(root, root / row.get("log_path", ""))
        log_text = log_path.read_text(encoding="utf-8")
        if not (
            log_text.splitlines().count("[RESULT] FAIL status=1") == 1
            and log_text.count("[VECTORED-TRAP-G1-CSR-FILE]") == 1
            and any(
                line.startswith("[VECTORED-TRAP-G1-CSR-FILE] ")
                and line.endswith(" FAIL")
                for line in log_text.splitlines()
            )
            and "[RESULT] PASS" not in log_text
            and "[PASS] tb_csr_file_vectored_trap" not in log_text
            and all(marker in log_text for marker in spec.required_assertions)
        ):
            raise ValueError(f"{mutation_id}: dynamic rejection log drifted")
        log_artifacts.append(artifact(root, log_path, f"mutation_log:{mutation_id}"))

    summary = payload.get("summary")
    if summary != {
        "all_rejected": True,
        "compile_succeeded": len(specs),
        "rejected": len(specs),
        "total": len(specs),
    }:
        raise ValueError("mutation aggregate is incomplete")
    return {
        "required": len(specs),
        "compile_succeeded": len(specs),
        "dynamic_rejected": len(specs),
    }, log_artifacts


def build_evidence(
    *,
    root: pathlib.Path,
    focused_log: pathlib.Path,
    program_log: pathlib.Path,
    regression_log: pathlib.Path,
    mutation_manifest: pathlib.Path,
) -> tuple[dict[str, Any], str]:
    rtl_sha, rtl_files = arch.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"

    focused_text = require_pass_log(
        focused_log, "tb_csr_file_vectored_trap", design_id
    )
    require_exact_line(focused_text, FOCUSED_MARKER, "focused CsrFile")
    program_text = require_pass_log(program_log, "tb_ooo_priv_system", design_id)
    for name, marker in PROGRAM_MARKERS.items():
        require_exact_line(program_text, marker, f"full-core {name}")
    require_pass_log(regression_log, "tb_csr_file", design_id)

    mutation_metrics, mutation_logs = validate_mutations(
        root, mutation_manifest, design_id, rtl_files
    )
    artifacts = [
        artifact(root, focused_log, "focused_csr_log"),
        artifact(root, program_log, "full_core_program_log"),
        artifact(root, regression_log, "csr_regression_log"),
        artifact(root, mutation_manifest, "mutation_manifest"),
        *mutation_logs,
    ]
    result = {
        "schema": SCHEMA,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "run_id": RUN_ID,
        "status": "PASS",
        "design_id": design_id,
        "canonical_command": CANONICAL_COMMAND,
        "rtl_source_set": {
            "design_id": design_id,
            "sha256": rtl_sha,
            "file_count": len(rtl_files),
            "files": rtl_files,
        },
        "metrics": {
            "focused": {
                "cases": 13,
                "warl_cases": 3,
                "irq_routing_cases": 3,
                "m_irq_cases": 2,
                "m_sync_cases": 1,
                "source_priority_cases": 2,
                "s_irq_cases": 1,
                "s_sync_cases": 1,
            },
            "full_core": {
                "m_irq_exact": 1,
                "s_irq_exact": 1,
                "m_sync_exact": 1,
                "raw_duplicate_terminal_events": 0,
                "wrong_target_fetches": 0,
                "xret_requests": 3,
                "xret_commits": 3,
                "return_commits": 3,
            },
            "mutations": mutation_metrics,
            "csr_regression_passed": 1,
        },
        "invariants": {
            "tvec_modes_0_1_preserved": True,
            "tvec_modes_2_3_clamped_direct": True,
            "interrupt_target_is_base_plus_four_cause": True,
            "synchronous_target_is_base": True,
            "trap_source_priority_mem_ex_irq": True,
            "state_and_redirect_share_selected_record": True,
            "nondelegated_supervisor_interrupts_route_to_m": True,
            "assertions_enabled": True,
        },
        "artifacts": artifacts,
        "claim": {
            "scope": "local RV64 CsrFile and full OoO trap/return control path",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }
    raw_lines = [
        f"schema={SCHEMA}",
        f"design_id={design_id}",
        f"canonical_command={CANONICAL_COMMAND}",
        "focused_cases=13/13",
        "full_core_paths=3/3",
        "raw_duplicate_terminal_events=0",
        f"compile_success_rtl_mutations={mutation_metrics['compile_succeeded']}",
        f"dynamic_rejected_rtl_mutations={mutation_metrics['dynamic_rejected']}",
        "csr_regression=1/1",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[VECTORED-TRAP-GATE] PASS",
    ]
    return result, "\n".join(raw_lines) + "\n"


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate and publish current local RV64 vectored-trap evidence"
    )
    parser.add_argument("--root", type=pathlib.Path, default=REPO)
    parser.add_argument("--focused-log", type=pathlib.Path, required=True)
    parser.add_argument("--program-log", type=pathlib.Path, required=True)
    parser.add_argument("--regression-log", type=pathlib.Path, required=True)
    parser.add_argument("--mutation-manifest", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        root = args.root.resolve(strict=True)
        result, raw_text = build_evidence(
            root=root,
            focused_log=safe_file(root, args.focused_log),
            program_log=safe_file(root, args.program_log),
            regression_log=safe_file(root, args.regression_log),
            mutation_manifest=safe_file(root, args.mutation_manifest),
        )
        output = args.output.resolve()
        raw_log = args.raw_log.resolve()
        if not output.is_relative_to(root) or not raw_log.is_relative_to(root):
            raise ValueError("output artifact escapes repository")
        output.parent.mkdir(parents=True, exist_ok=True)
        raw_log.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        raw_log.write_text(raw_text, encoding="utf-8")
    except (OSError, UnicodeError, ValueError, json.JSONDecodeError) as error:
        print(f"vectored-trap evidence rejected: {error}", file=sys.stderr)
        return 2
    print(raw_text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
