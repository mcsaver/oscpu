#!/usr/bin/env python3
"""Run the queue-head CSR stop-lifetime historical reconstruction matrix.

The production RTL is never edited by this runner.  It materializes three
compile-success source versions under the owned tmp directory:

* ``drop_stop_hold`` removes only the explicit inflight state-hold arm;
* ``drop_run_gate_owner`` removes only the later T3U RunGate owner term;
* ``historical_pre_t3u`` removes both, reconstructing the historical root cone.

All four semantics use the same product ``OooCoreTopGlue`` instruction program
and raw cycle/event scoreboard with RTL assertions enabled and disabled.
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


RUN_ID = "2026-07-29-rv64-hist-ser-qh-stop-hold-drop"
TARGET = "tb_ooo_core_top_glue_hist_ser_qh_stop_hold"
CURRENT_DESIGN_ID = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)

STOP_HOLD_ANCHOR = """    end else if (head0_csr_inflight_i && !head0_csr_owner_kill_i) begin
      // Queue-head CSR remains the owner through C0; exact older-control kill
      // or C1 reset releases it with the frontend inflight register.
      stop_pending_o <= 1'b1;
"""

RUN_GATE_OWNER_ANCHOR = """      branch_spec_checkpoint_pending_i ||
      branch_spec_active_i ||
      // T3U：queue-head CSR 离开 fetch head 后仍在 ROB 内执行，inflight 是
      // stop 的真实 owner；宏关闭时门控为 0，保持 flag0 逐位等价。
      (`OOO_CSR_QUEUE_HEAD && head0_csr_inflight_i);
"""

RUN_GATE_OWNER_REMOVED = """      branch_spec_checkpoint_pending_i ||
      branch_spec_active_i;
"""

RAW_PASS = "[HIST-SER-QH-STOP-HOLD][RAW-PASS]"
OWNER_GAP = "[HIST-SER-QH-STOP-HOLD][ORPHAN-OWNER-GAP]"
STOP_DROP = "[HIST-SER-QH-STOP-DROP][FAIL]"
INFLIGHT_RUN = "[HIST-SER-QH-INFLIGHT-RUN][FAIL]"
LANE1_OVERLAP = "[HIST-SER-QH-LANE1-OVERLAP][FAIL]"
QCSR_ASSERT = "[V9X-STOP-QCSR-HOLD]"
RUN_GATE_ASSERT = "[T3U-CSR-STOP-OWNER]"
VVP_POINTER_ID_RE = re.compile(rb"(?<=[A-Za-z_])0x[0-9a-fA-F]+")


@dataclass(frozen=True)
class SemanticCase:
    name: str
    stop_key: str
    run_gate_key: str
    expected: str


SEMANTICS = (
    SemanticCase("current", "production", "production", "pass"),
    SemanticCase(
        "drop_stop_hold",
        "drop_stop_hold",
        "production",
        "pass_successor_owner",
    ),
    SemanticCase(
        "drop_run_gate_owner",
        "production",
        "drop_run_gate_owner",
        "reject_owner_gap",
    ),
    SemanticCase(
        "historical_pre_t3u",
        "drop_stop_hold",
        "drop_run_gate_owner",
        "reject_historical_root",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def normalized_vvp_sha256(path: Path) -> str:
    return sha256_bytes(VVP_POINTER_ID_RE.sub(b"0xPTR", path.read_bytes()))


def replace_exact_once(text: str, old: str, new: str, label: str) -> str:
    observed = text.count(old)
    if observed != 1:
        raise RuntimeError(
            f"{label}: expected exactly one source anchor, observed {observed}"
        )
    changed = text.replace(old, new, 1)
    if changed == text:
        raise RuntimeError(f"{label}: source bytes did not change")
    return changed


def checked_remove(path: Path, owned_parent: Path) -> None:
    resolved = path.resolve()
    parent = owned_parent.resolve()
    if not resolved.is_relative_to(parent) or resolved == parent:
        raise RuntimeError(f"refusing to remove non-owned path: {path}")
    if resolved.exists():
        shutil.rmtree(resolved)


def relative(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def write_variant(
    *,
    production_path: Path,
    variant_path: Path,
    variant_text: str,
    evidence_diff: Path,
    repo_root: Path,
) -> dict[str, object]:
    production_text = production_path.read_text(encoding="utf-8")
    variant_path.parent.mkdir(parents=True, exist_ok=True)
    variant_path.write_text(variant_text, encoding="utf-8")
    diff = "".join(
        difflib.unified_diff(
            production_text.splitlines(keepends=True),
            variant_text.splitlines(keepends=True),
            fromfile=relative(production_path, repo_root),
            tofile=relative(variant_path, repo_root),
        )
    )
    if not diff:
        raise RuntimeError(f"empty source diff for {variant_path}")
    evidence_diff.parent.mkdir(parents=True, exist_ok=True)
    evidence_diff.write_text(diff, encoding="utf-8")
    return {
        "production_path": relative(production_path, repo_root),
        "production_sha256": sha256_file(production_path),
        "variant_path": relative(variant_path, repo_root),
        "variant_sha256": sha256_file(variant_path),
        "diff_path": relative(evidence_diff, repo_root),
        "diff_sha256": sha256_file(evidence_diff),
    }


def materialize_variants(
    repo_root: Path, work_root: Path, evidence_root: Path
) -> tuple[dict[str, Path], dict[str, Path], dict[str, object]]:
    stop_source = repo_root / "npc/rv64/vsrc/control/OooStopPendingSequencer.v"
    run_gate_source = (
        repo_root / "npc/rv64/vsrc/frontend/OooFrontendRunGate.v"
    )
    stop_text = stop_source.read_text(encoding="utf-8")
    run_gate_text = run_gate_source.read_text(encoding="utf-8")
    stop_variant_text = replace_exact_once(
        stop_text,
        STOP_HOLD_ANCHOR,
        "",
        "OooStopPendingSequencer.drop_stop_hold",
    )
    run_gate_variant_text = replace_exact_once(
        run_gate_text,
        RUN_GATE_OWNER_ANCHOR,
        RUN_GATE_OWNER_REMOVED,
        "OooFrontendRunGate.drop_inflight_owner",
    )

    stop_variant = (
        work_root / "rtl/drop_stop_hold/OooStopPendingSequencer.v"
    )
    run_gate_variant = (
        work_root / "rtl/drop_run_gate_owner/OooFrontendRunGate.v"
    )
    stop_meta = write_variant(
        production_path=stop_source,
        variant_path=stop_variant,
        variant_text=stop_variant_text,
        evidence_diff=evidence_root / "variants/drop_stop_hold/source.diff",
        repo_root=repo_root,
    )
    run_gate_meta = write_variant(
        production_path=run_gate_source,
        variant_path=run_gate_variant,
        variant_text=run_gate_variant_text,
        evidence_diff=(
            evidence_root / "variants/drop_run_gate_owner/source.diff"
        ),
        repo_root=repo_root,
    )
    stop_paths = {
        "production": stop_source,
        "drop_stop_hold": stop_variant,
    }
    run_gate_paths = {
        "production": run_gate_source,
        "drop_run_gate_owner": run_gate_variant,
    }
    return stop_paths, run_gate_paths, {
        "stop_pending": stop_meta,
        "frontend_run_gate": run_gate_meta,
    }


def count_marker(text: str, marker: str) -> int:
    return text.count(marker)


def validate_case(
    *,
    semantic: SemanticCase,
    assertions: bool,
    driver_rc: int,
    log_text: str,
    image_exists: bool,
) -> tuple[bool, dict[str, int], list[str]]:
    markers = {
        "raw_pass": count_marker(log_text, RAW_PASS),
        "owner_gap": count_marker(log_text, OWNER_GAP),
        "stop_drop": count_marker(log_text, STOP_DROP),
        "inflight_run": count_marker(log_text, INFLIGHT_RUN),
        "lane1_overlap": count_marker(log_text, LANE1_OVERLAP),
        "qcsr_assert": count_marker(log_text, QCSR_ASSERT),
        "run_gate_assert": count_marker(log_text, RUN_GATE_ASSERT),
        "result_pass": count_marker(log_text, "[RESULT] PASS"),
        "result_fail": count_marker(log_text, "[RESULT] FAIL"),
    }
    errors: list[str] = []
    if not image_exists:
        errors.append("compile image missing")
    if "[COMPILE]" not in log_text:
        errors.append("compile command marker missing")

    if semantic.expected in {"pass", "pass_successor_owner"}:
        if driver_rc != 0:
            errors.append(f"positive driver rc={driver_rc}, expected 0")
        if markers["raw_pass"] != 1:
            errors.append(
                f"RAW-PASS count={markers['raw_pass']}, expected 1"
            )
        for name in (
            "owner_gap",
            "stop_drop",
            "inflight_run",
            "lane1_overlap",
            "qcsr_assert",
            "run_gate_assert",
            "result_fail",
        ):
            if markers[name] != 0:
                errors.append(
                    f"positive marker {name} count={markers[name]}, expected 0"
                )
        if markers["result_pass"] != 1:
            errors.append(
                f"RESULT PASS count={markers['result_pass']}, expected 1"
            )
    else:
        if driver_rc == 0:
            errors.append("negative version unexpectedly returned rc=0")
        if markers["owner_gap"] <= 0:
            errors.append("negative version missed raw owner-gap cycles")
        if markers["inflight_run"] <= 0:
            errors.append("negative version missed raw inflight can-run cycles")
        if semantic.expected == "reject_owner_gap":
            if markers["lane1_overlap"] <= 0:
                errors.append("RunGate owner-drop missed real lane1 overlap")
            if markers["stop_drop"] != 0:
                errors.append("RunGate-only version unexpectedly dropped stop")
            if assertions and markers["run_gate_assert"] <= 0:
                errors.append("assertion-on RunGate version missed T3U assertion")
        elif semantic.expected == "reject_historical_root":
            if markers["stop_drop"] <= 0:
                errors.append("historical root missed raw stop-drop cycle")
            if assertions:
                if markers["qcsr_assert"] <= 0:
                    errors.append(
                        "assertion-on historical root missed V9X assertion"
                    )
            elif markers["lane1_overlap"] <= 0:
                errors.append(
                    "assertion-off historical root missed real lane1 overlap"
                )
        if markers["result_pass"] != 0:
            errors.append("negative version emitted RESULT PASS")

    return not errors, markers, errors


def run_case(
    *,
    repo_root: Path,
    testbench_dir: Path,
    work_root: Path,
    evidence_root: Path,
    semantic: SemanticCase,
    assertions: bool,
    stop_path: Path,
    run_gate_path: Path,
) -> dict[str, object]:
    config = "assert-on" if assertions else "assert-off"
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
    if assertions:
        include_flags += " -DOOO_ASSERT"
    combined_source_sha = sha256_bytes(
        (
            sha256_file(stop_path)
            + sha256_file(run_gate_path)
            + sha256_file(
                repo_root
                / "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
            )
        ).encode("ascii")
    )
    log_path = result_dir / "logs" / f"{TARGET}.log"
    image_path = build_dir / f"{TARGET}.vvp"
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"BUILD_DIR={build_dir}",
        f"RESULT_DIR={result_dir}",
        f"RTL_OOO_STOP_PENDING_SEQUENCER={stop_path}",
        f"RTL_OOO_FRONTEND_RUN_GATE={run_gate_path}",
        f"RTL_EVIDENCE_SHA={combined_source_sha}",
        f"IVFLAGS={include_flags}",
        str(log_path),
    ]
    completed = subprocess.run(
        command,
        cwd=repo_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=180,
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
    log_text = (
        log_path.read_text(encoding="utf-8", errors="replace")
        if log_path.exists()
        else ""
    )
    passed, markers, errors = validate_case(
        semantic=semantic,
        assertions=assertions,
        driver_rc=completed.returncode,
        log_text=log_text,
        image_exists=image_path.exists(),
    )
    receipt = {
        "schema": "npc-rv64-iverilog-image-receipt-v1",
        "path": relative(image_path, repo_root),
        "exists": image_path.exists(),
        "size_bytes": image_path.stat().st_size if image_path.exists() else 0,
        "raw_sha256": sha256_file(image_path) if image_path.exists() else None,
        "normalized_sha256": (
            normalized_vvp_sha256(image_path) if image_path.exists() else None
        ),
    }
    receipt_path = case_dir / "compile-image-receipt.json"
    receipt_path.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return {
        "case": case_name,
        "semantic": semantic.name,
        "expected": semantic.expected,
        "assertions": assertions,
        "passed": passed,
        "errors": errors,
        "driver_returncode": completed.returncode,
        "stop_source": relative(stop_path, repo_root),
        "stop_source_sha256": sha256_file(stop_path),
        "run_gate_source": relative(run_gate_path, repo_root),
        "run_gate_source_sha256": sha256_file(run_gate_path),
        "markers": markers,
        "log_path": relative(log_path, repo_root),
        "log_sha256": sha256_file(log_path) if log_path.exists() else None,
        "image_receipt": relative(receipt_path, repo_root),
        "compile_success": image_path.exists(),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="replace only this runner's owned matrix evidence and tmp roots",
    )
    args = parser.parse_args(argv)

    run_dir = Path(__file__).resolve().parent
    repo_root = run_dir.parents[2]
    if repo_root.name != "ysyx-workbench":
        raise RuntimeError(f"unexpected repository root: {repo_root}")
    work_parent = repo_root / "tmp" / RUN_ID
    work_root = work_parent / "stop-hold-matrix"
    evidence_parent = run_dir / "evidence"
    evidence_root = evidence_parent / "stop-hold-matrix"
    summary_path = evidence_root / "summary.json"
    if args.refresh:
        checked_remove(work_root, work_parent)
        checked_remove(evidence_root, evidence_parent)
    elif summary_path.exists():
        raise RuntimeError(
            f"refusing to overwrite evidence without --refresh: {summary_path}"
        )
    work_root.mkdir(parents=True, exist_ok=True)
    evidence_root.mkdir(parents=True, exist_ok=True)

    stop_paths, run_gate_paths, variants = materialize_variants(
        repo_root, work_root, evidence_root
    )
    cases: list[dict[str, object]] = []
    for semantic in SEMANTICS:
        for assertions in (True, False):
            cases.append(
                run_case(
                    repo_root=repo_root,
                    testbench_dir=repo_root / "npc/rv64/testbench",
                    work_root=work_root,
                    evidence_root=evidence_root,
                    semantic=semantic,
                    assertions=assertions,
                    stop_path=stop_paths[semantic.stop_key],
                    run_gate_path=run_gate_paths[semantic.run_gate_key],
                )
            )
    passed = all(bool(case["passed"]) for case in cases)
    production_stop = (
        repo_root / "npc/rv64/vsrc/control/OooStopPendingSequencer.v"
    )
    production_run_gate = (
        repo_root / "npc/rv64/vsrc/frontend/OooFrontendRunGate.v"
    )
    testbench = (
        repo_root / "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
    )
    makefile = repo_root / "npc/rv64/testbench/Makefile"
    result = {
        "schema": "npc-rv64-hist-ser-qh-stop-hold-matrix/v1",
        "status": "PASS" if passed else "GAP",
        "run_id": RUN_ID,
        "design_id": CURRENT_DESIGN_ID,
        "production_sources": {
            relative(production_stop, repo_root): sha256_file(production_stop),
            relative(production_run_gate, repo_root): sha256_file(
                production_run_gate
            ),
            relative(testbench, repo_root): sha256_file(testbench),
            relative(makefile, repo_root): sha256_file(makefile),
        },
        "variants": variants,
        "cases": cases,
        "coverage": {
            "compile_success": (
                f"{sum(bool(case['compile_success']) for case in cases)}/"
                f"{len(cases)}"
            ),
            "assertion_on_off": True,
            "raw_cycle_counts": True,
            "real_frontend_lane1_capture_required": True,
            "stop_hold_only_survival_expected": True,
            "historical_pre_t3u_root_rejected": True,
            "event_deduplication": False,
        },
    }
    summary_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    summary_md = evidence_root / "summary.md"
    lines = [
        "# HIST-SER-QH-STOP-HOLD-DROP matrix",
        "",
        f"- status: `{result['status']}`",
        f"- design-id: `{CURRENT_DESIGN_ID}`",
        f"- compile-success: `{result['coverage']['compile_success']}`",
        "",
        "| semantic | assertions | expected | observed |",
        "| --- | --- | --- | --- |",
    ]
    for case in cases:
        lines.append(
            f"| {case['semantic']} | "
            f"{'on' if case['assertions'] else 'off'} | "
            f"{case['expected']} | "
            f"{'PASS' if case['passed'] else 'GAP'} |"
        )
    summary_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        "[HIST-SER-QH-STOP-HOLD-MATRIX] "
        f"cases={sum(bool(case['passed']) for case in cases)}/{len(cases)} "
        f"compile={result['coverage']['compile_success']} "
        f"{result['status']}"
    )
    if not passed:
        for case in cases:
            if not case["passed"]:
                print(
                    f"[CASE-GAP] {case['case']}: "
                    + "; ".join(str(item) for item in case["errors"]),
                    file=sys.stderr,
                )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
