#!/usr/bin/env python3
"""Replay the historical queue-head CSR / younger-SQ dependency.

The production RTL is never edited.  Two compile-success source variants are
materialized under the task-run work directory:

* historical_fixed: reconstructs the pre-owner-lifetime transport-idle cone.
* historical_cycle: adds the historical ``&& mem_retire_quiet_o`` ROB gate.

All three semantics use the same IntBackend stimulus and raw edge counters in
``tb_ooo_int_backend.sv``.  Each is compiled with OOO_ASSERT enabled and
disabled.  The historical-cycle cases must elaborate successfully and then
terminate only at the dedicated root-window marker.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


RUN_ID = "2026-07-29-rv64-hist-ser-qh-younger-store-cycle"
TARGET = "tb_ooo_int_backend_hist_ser_qh_younger_store"

MEM_IDLE_ANCHOR = """  assign mem_idle_o =
      miq_empty_w && (!ENABLE_DUAL_MEM || miq1_empty_w) &&
      !mem_pending_q && !mem_buffer_valid_q &&
      !mem_retry0_valid_q && !mem_retry1_valid_q &&
      !mem_issue_res_valid_q && !mem_issue1_res_valid_q &&
      (mem_owner_live_count_w == 6'd0) &&
      (mem_terminal_pending_count_w == 6'd0);
"""

HISTORICAL_TRANSPORT_IDLE = """  assign mem_idle_o =
      miq_empty_w && (!ENABLE_DUAL_MEM || miq1_empty_w) &&
      !mem_pending_q && !mem_buffer_valid_q &&
      !mem_retry0_valid_q && !mem_retry1_valid_q &&
      !mem_issue_res_valid_q && !mem_issue1_res_valid_q;
"""

MEM_QUIET_ANCHOR = "    .mem_quiet_i(mem_idle_o),\n"
HISTORICAL_CYCLE_GATE = (
    "    .mem_quiet_i(mem_idle_o && mem_retire_quiet_o),\n"
)

ROOT_MARKER = "[HIST-SER-QH-YOUNGER-STORE][ROOT]"
CURRENT_MARKER = (
    "[HIST-SER-QH-YOUNGER-STORE][CURRENT-OWNER-GUARD-PASS]"
)
FIXED_MARKER = (
    "[HIST-SER-QH-YOUNGER-STORE][HISTORICAL-FIXED-PASS]"
)
CYCLE_MARKER = "[HIST-SER-QH-YOUNGER-STORE][EXPECTED-FAIL]"
SETUP_FAIL_MARKER = "[HIST-SER-QH-YOUNGER-STORE][SETUP-FAIL]"
VVP_POINTER_ID_RE = re.compile(rb"(?<=[A-Za-z_])0x[0-9a-fA-F]+")


@dataclass(frozen=True)
class SemanticCase:
    name: str
    rtl_key: str
    mode_flag: str
    expected_marker: str
    expected_pass: bool
    root_fragment: str


SEMANTICS = (
    SemanticCase(
        name="current_owner_guard",
        rtl_key="production",
        mode_flag="-DHIST_SER_QH_CURRENT_GUARD",
        expected_marker=CURRENT_MARKER,
        expected_pass=True,
        root_fragment="mem_idle=0 mem_retire_quiet=0",
    ),
    SemanticCase(
        name="historical_fixed",
        rtl_key="historical_fixed",
        mode_flag="-DHIST_SER_QH_EXPECT_C0",
        expected_marker=FIXED_MARKER,
        expected_pass=True,
        root_fragment="mem_idle=1 mem_retire_quiet=0",
    ),
    SemanticCase(
        name="historical_cycle",
        rtl_key="historical_cycle",
        mode_flag="-DHIST_SER_QH_EXPECT_CYCLE",
        expected_marker=CYCLE_MARKER,
        expected_pass=False,
        root_fragment="mem_idle=1 mem_retire_quiet=0",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def normalized_vvp_sha256(path: Path) -> str:
    """Hash elaborated VVP semantics without allocator-derived symbol IDs.

    Icarus emits internal names such as ``S_0x5c...`` and ``v0x7f...``.
    Those pointer-like IDs vary across identical compilations and are used
    only as cross references inside the textual VVP image.  The raw digest is
    retained in a per-case receipt; the ledger-bound summary uses this
    normalization so an identical elaboration replays to a stable identity.
    """

    normalized = VVP_POINTER_ID_RE.sub(b"0xPTR", path.read_bytes())
    return sha256_bytes(normalized)


def replace_exact_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"{label}: expected exactly one source anchor, observed {count}"
        )
    result = text.replace(old, new, 1)
    if result == text:
        raise RuntimeError(f"{label}: replacement did not change source bytes")
    return result


def require_count(text: str, marker: str, expected: int, label: str) -> None:
    observed = text.count(marker)
    if observed != expected:
        raise RuntimeError(
            f"{label}: marker {marker!r} count={observed}, expected={expected}"
        )


def checked_remove(path: Path, allowed_parent: Path) -> None:
    resolved = path.resolve()
    parent = allowed_parent.resolve()
    if not resolved.is_relative_to(parent) or resolved == parent:
        raise RuntimeError(f"refusing to remove path outside owned root: {path}")
    if resolved.exists():
        shutil.rmtree(resolved)


def materialize_variants(
    source_path: Path, work_root: Path, evidence_root: Path
) -> tuple[dict[str, Path], dict[str, dict[str, object]]]:
    source_text = source_path.read_text(encoding="utf-8")
    fixed_text = replace_exact_once(
        source_text,
        MEM_IDLE_ANCHOR,
        HISTORICAL_TRANSPORT_IDLE,
        "historical_fixed.mem_idle",
    )
    cycle_text = replace_exact_once(
        fixed_text,
        MEM_QUIET_ANCHOR,
        HISTORICAL_CYCLE_GATE,
        "historical_cycle.mem_quiet",
    )

    paths: dict[str, Path] = {"production": source_path}
    metadata: dict[str, dict[str, object]] = {
        "production": {
            "path": str(source_path),
            "sha256": sha256_file(source_path),
            "semantic_scope": "current production owner-lifetime guard",
            "byte_identical_to_production": True,
        }
    }
    for key, text, scope in (
        (
            "historical_fixed",
            fixed_text,
            (
                "root-cone-equivalent reconstruction: current transient "
                "transport holders retained, owner-live and terminal-pending "
                "terms removed from mem_idle"
            ),
        ),
        (
            "historical_cycle",
            cycle_text,
            (
                "root-cone-equivalent reconstruction plus historical "
                "mem_idle && mem_retire_quiet ROB dependency"
            ),
        ),
    ):
        variant_dir = work_root / "rtl" / key
        variant_dir.mkdir(parents=True, exist_ok=True)
        variant_path = variant_dir / "OooIntBackend.v"
        variant_path.write_text(text, encoding="utf-8")
        diff_text = "".join(
            difflib.unified_diff(
                source_text.splitlines(keepends=True),
                text.splitlines(keepends=True),
                fromfile=str(source_path),
                tofile=str(variant_path),
            )
        )
        work_diff_path = variant_dir / "source.diff"
        work_diff_path.write_text(diff_text, encoding="utf-8")
        if not diff_text:
            raise RuntimeError(f"{key}: empty source diff")
        evidence_variant_dir = evidence_root / "variants" / key
        evidence_variant_dir.mkdir(parents=True, exist_ok=True)
        evidence_diff_path = evidence_variant_dir / "source.diff"
        evidence_diff_path.write_text(diff_text, encoding="utf-8")
        paths[key] = variant_path
        metadata[key] = {
            "path": str(variant_path),
            "sha256": sha256_file(variant_path),
            "diff_path": str(evidence_diff_path),
            "diff_sha256": sha256_file(evidence_diff_path),
            "semantic_scope": scope,
            "byte_identical_to_production": False,
        }
    if metadata["historical_fixed"]["sha256"] == metadata["production"]["sha256"]:
        raise RuntimeError("historical_fixed unexpectedly equals production")
    if metadata["historical_cycle"]["sha256"] in {
        metadata["production"]["sha256"],
        metadata["historical_fixed"]["sha256"],
    }:
        raise RuntimeError("historical_cycle does not have a unique source SHA")
    return paths, metadata


def run_one(
    repo_root: Path,
    testbench_dir: Path,
    evidence_root: Path,
    work_root: Path,
    semantic: SemanticCase,
    assert_enabled: bool,
    rtl_path: Path,
) -> dict[str, object]:
    config = "assert-on" if assert_enabled else "assert-off"
    case_name = f"{semantic.name}-{config}"
    case_dir = evidence_root / "cases" / case_name
    build_dir = work_root / "build" / case_name
    result_dir = case_dir / "result"
    case_dir.mkdir(parents=True, exist_ok=True)
    build_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)

    include_flags = (
        f"-g2012 -Wall "
        f"-I{repo_root / 'npc/rv64/vsrc'} "
        f"-I{repo_root / 'npc/rv64/vsrc/include'} "
        "-Icommon"
    )
    if assert_enabled:
        include_flags += " -DOOO_ASSERT"

    log_path = result_dir / "logs" / f"{TARGET}.log"
    image_path = build_dir / f"{TARGET}.vvp"
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"BUILD_DIR={build_dir}",
        f"RESULT_DIR={result_dir}",
        f"RTL_OOO_INT_BACKEND={rtl_path}",
        f"RTL_EVIDENCE_SHA={sha256_file(rtl_path)}",
        f"HIST_QH_MODE_FLAG={semantic.mode_flag}",
        f"IVFLAGS={include_flags}",
        str(log_path),
    ]
    completed = subprocess.run(
        command,
        cwd=repo_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=120,
        check=False,
    )
    (case_dir / "driver.stdout").write_text(
        completed.stdout, encoding="utf-8"
    )
    (case_dir / "driver.stderr").write_text(
        completed.stderr, encoding="utf-8"
    )
    (case_dir / "driver.rc").write_text(
        f"{completed.returncode}\n", encoding="utf-8"
    )

    if not log_path.is_file():
        raise RuntimeError(f"{case_name}: make did not produce {log_path}")
    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    if not image_path.is_file() or image_path.stat().st_size == 0:
        raise RuntimeError(f"{case_name}: compile-success image is missing")
    image_receipt_path = case_dir / "compile-image-receipt.json"
    image_receipt_path.write_text(
        json.dumps(
            {
                "schema": "npc-rv64-iverilog-image-receipt-v1",
                "path": str(
                    image_path.resolve().relative_to(repo_root.resolve())
                ),
                "size_bytes": image_path.stat().st_size,
                "raw_sha256": sha256_file(image_path),
                "normalized_sha256": normalized_vvp_sha256(image_path),
                "normalization": (
                    "replace allocator-derived VVP symbol fragments matching "
                    "(?<=[A-Za-z_])0x[0-9a-fA-F]+ with 0xPTR"
                ),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    require_count(log_text, ROOT_MARKER, 1, case_name)
    require_count(log_text, semantic.expected_marker, 1, case_name)
    require_count(log_text, SETUP_FAIL_MARKER, 0, case_name)
    require_count(log_text, "[CHECK-FAIL]", 0, case_name)
    require_count(log_text, "FATAL:", 0, case_name)

    if semantic.expected_pass:
        if completed.returncode != 0:
            raise RuntimeError(
                f"{case_name}: positive case returned {completed.returncode}"
            )
        require_count(log_text, f"[PASS] {TARGET}", 1, case_name)
        require_count(log_text, "[RESULT] PASS", 1, case_name)
    else:
        if completed.returncode == 0:
            raise RuntimeError(f"{case_name}: historical cycle unexpectedly passed")
        require_count(log_text, f"[PASS] {TARGET}", 0, case_name)
        require_count(log_text, "[RESULT] FAIL status=1", 1, case_name)

    marker_line = next(
        line
        for line in log_text.splitlines()
        if semantic.expected_marker in line
    )
    root_line = next(
        line for line in log_text.splitlines() if ROOT_MARKER in line
    )
    if semantic.root_fragment not in root_line:
        raise RuntimeError(
            f"{case_name}: root marker lacks {semantic.root_fragment!r}"
        )
    return {
        "case": case_name,
        "semantic": semantic.name,
        "assertions": "enabled" if assert_enabled else "disabled",
        "expected_pass": semantic.expected_pass,
        "driver_rc": completed.returncode,
        "rtl_path": str(rtl_path),
        "rtl_sha256": sha256_file(rtl_path),
        "image_path": str(image_path),
        "image_size_bytes": image_path.stat().st_size,
        "image_normalized_sha256": normalized_vvp_sha256(image_path),
        "image_receipt_path": str(image_receipt_path),
        "image_retention": (
            "ephemeral work artifact; raw SHA retained in the per-case "
            "receipt and allocator-normalized elaboration SHA retained here"
        ),
        "log_path": str(log_path),
        "log_sha256": sha256_file(log_path),
        "root_marker": root_line,
        "terminal_marker": marker_line,
        "compile_success": True,
        "oracle_result": (
            "PASS" if semantic.expected_pass else "EXPECTED_REJECTION"
        ),
    }


def relative_paths(value: object, repo_root: Path) -> object:
    if isinstance(value, dict):
        return {
            key: relative_paths(item, repo_root) for key, item in value.items()
        }
    if isinstance(value, list):
        return [relative_paths(item, repo_root) for item in value]
    if isinstance(value, str):
        try:
            path = Path(value)
            if path.is_absolute() and path.resolve().is_relative_to(
                repo_root.resolve()
            ):
                return str(path.resolve().relative_to(repo_root.resolve()))
        except (OSError, ValueError):
            pass
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="replace only this runner's deterministic evidence/work roots",
    )
    args = parser.parse_args()

    task_dir = Path(__file__).resolve().parent
    repo_root = task_dir.parents[2]
    testbench_dir = repo_root / "npc/rv64/testbench"
    source_path = repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v"
    tb_source_path = testbench_dir / "tests/tb_ooo_int_backend.sv"
    makefile_path = testbench_dir / "Makefile"
    evidence_root = task_dir / "evidence/historical-reconstruction"
    work_parent = repo_root / "tmp" / RUN_ID
    work_root = work_parent / "historical-reconstruction"

    if evidence_root.exists() or work_root.exists():
        if not args.refresh:
            raise RuntimeError(
                "owned output already exists; pass --refresh to replace it"
            )
        checked_remove(evidence_root, task_dir / "evidence")
        checked_remove(work_root, work_parent)
    evidence_root.mkdir(parents=True, exist_ok=True)
    work_root.mkdir(parents=True, exist_ok=True)

    production_before = sha256_file(source_path)
    verification_before = {
        str(tb_source_path): sha256_file(tb_source_path),
        str(makefile_path): sha256_file(makefile_path),
    }
    rtl_paths, variant_metadata = materialize_variants(
        source_path, work_root, evidence_root
    )
    records: list[dict[str, object]] = []
    for semantic in SEMANTICS:
        for assert_enabled in (True, False):
            records.append(
                run_one(
                    repo_root=repo_root,
                    testbench_dir=testbench_dir,
                    evidence_root=evidence_root,
                    work_root=work_root,
                    semantic=semantic,
                    assert_enabled=assert_enabled,
                    rtl_path=rtl_paths[semantic.rtl_key],
                )
            )

    production_after = sha256_file(source_path)
    if production_after != production_before:
        raise RuntimeError("production OooIntBackend.v changed during replay")
    verification_after = {
        str(tb_source_path): sha256_file(tb_source_path),
        str(makefile_path): sha256_file(makefile_path),
    }
    if verification_after != verification_before:
        raise RuntimeError("verification source changed during replay")

    summary = {
        "schema": "npc-rv64-historical-qh-younger-store-reconstruction-v2",
        "run_id": RUN_ID,
        "status": "PASS",
        "historical_defect_id": "HIST-SER-QH-YOUNGER-STORE-CYCLE",
        "original_fix_commit": "7f66f9d9d4badc08e0c51dc65c4db2b99683de46",
        "interpretation": (
            "current owner-lifetime semantics intentionally blocks the "
            "backend-only injected state; the reconstructed transport-idle "
            "fixed form reaches exactly one CSR C0/C1 with no younger STORE "
            "write; adding the historical SQ-retire dependency reproduces "
            "the exact bounded cyclic wait in both assertion configurations"
        ),
        "not_claimed": [
            "the reconstructed sources are not full historical snapshots",
            "the product frontend can dispatch a younger uop after queue-head CSR",
            "current production RTL requires a semantic change",
            "A3 system evidence is rebound to a changed design",
        ],
        "production_source": {
            "path": str(source_path),
            "sha256_before": production_before,
            "sha256_after": production_after,
            "no_drift": production_before == production_after,
        },
        "verification_sources": {
            "files": [
                {
                    "path": path,
                    "sha256_before": digest,
                    "sha256_after": verification_after[path],
                    "no_drift": digest == verification_after[path],
                }
                for path, digest in verification_before.items()
            ],
            "runner": {
                "path": str(Path(__file__).resolve()),
                "sha256": sha256_file(Path(__file__).resolve()),
            },
        },
        "variants": variant_metadata,
        "cases": records,
        "totals": {
            "cases": len(records),
            "compile_success": sum(
                1 for record in records if record["compile_success"]
            ),
            "positive_pass": sum(
                1
                for record in records
                if record["oracle_result"] == "PASS"
            ),
            "expected_rejection": sum(
                1
                for record in records
                if record["oracle_result"] == "EXPECTED_REJECTION"
            ),
        },
    }
    summary = relative_paths(summary, repo_root)
    summary_path = evidence_root / "summary.json"
    summary_path.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    markdown = [
        "# HIST-SER-QH-YOUNGER-STORE-CYCLE reconstruction",
        "",
        "- status: PASS",
        "- compile-success cases: 6/6",
        "- current owner guard: assertion-on/off 2/2 PASS",
        "- historical transport-idle fixed: assertion-on/off 2/2 PASS",
        "- historical `mem_idle && mem_retire_quiet`: assertion-on/off "
        "2/2 rejected at the dedicated root window",
        f"- production source SHA-256: `{production_before}`",
        "- production source drift: none",
        "- compile-image identity: raw SHA receipts plus stable "
        "allocator-normalized VVP SHA",
        "- scope: root-cone-equivalent historical reconstruction; not a full "
        "historical snapshot",
        "",
    ]
    (evidence_root / "summary.md").write_text(
        "\n".join(markdown), encoding="utf-8"
    )
    print(
        "[HIST-SER-QH-RECONSTRUCTION][PASS] "
        "compile_success=6/6 positive=4/4 expected_rejection=2/2 "
        f"production_sha={production_before}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(
            f"[HIST-SER-QH-RECONSTRUCTION][FAIL] {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
