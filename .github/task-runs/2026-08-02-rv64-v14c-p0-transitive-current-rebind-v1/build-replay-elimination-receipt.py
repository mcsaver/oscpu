#!/usr/bin/env python3
"""Validate current dynamic IFU-AXI/FETCH evidence and retire replay reliance."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
MODULE_DIR = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1/evidence/p0-direct-rebind-1/module-aggregate"
)
V14B_SOURCE = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1/evidence/p0-direct-rebind-checker-replay-1/"
    "source-post-result.json"
)


def load(path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return payload


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid RV64 evidence artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def verify_result(payload: dict[str, Any], schema: str, gate_id: str) -> None:
    if (
        payload.get("schema") != schema
        or payload.get("status") != "PASS"
        or payload.get("design_id") != CURRENT_DESIGN_ID
    ):
        raise ValueError(f"{gate_id}: current dynamic result mismatch")


def verify_mutation(payload: dict[str, Any], gate_id: str, required: int) -> None:
    if (
        payload.get("required") != required
        or payload.get("compile_success") != required
        or payload.get("dynamic_rejected") != required
        or payload.get("source_unchanged") is not True
    ):
        raise ValueError(f"{gate_id}: current RTL counterexample gap")


def warning_audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    warning_lines: list[str] = []
    for path in logs:
        warning_lines.extend(
            line for line in path.read_text(encoding="utf-8").splitlines()
            if "warning:" in line.lower()
        )
    pmp_allowed = re.compile(
        r"/PmpChecker\.v:(?:105|108|109|116|125|126|129|131): warning: "
        r"(?:returning 'bx for out of bounds array access entry_addr_w\[-1\]\.|"
        r"@\* is sensitive to all 16 words in array '(?:entry_cfg_w|entry_addr_w)'\.)$"
    )
    pmp_cfg_tail = re.compile(
        r"/PmpChecker\.v:163: warning: @\* is sensitive to all 16 words "
        r"in array 'entry_cfg_w'\.$"
    )
    xbar_sites = {
        350: "rd_resp_data_q", 351: "rd_resp_resp_q", 352: "rd_resp_id_q",
        360: "rd_rr_q", 361: "artarget_decode_r", 365: "artarget_decode_r",
        371: "artarget_decode_r", 375: "artarget_decode_r", 398: "rd_addr_q",
        399: "rd_size_q", 400: "rd_prot_q", 404: "rd_owner_q",
        425: "wr_rr_q", 427: "wr_awtarget_q", 431: "wr_awtarget_q",
        437: "wr_awtarget_q", 441: "wr_awtarget_q", 463: "wr_addr_q",
        464: "wr_size_q", 469: "wr_data_q", 470: "wr_strb_q",
        474: "wr_owner_q", 477: "wr_id_q",
    }
    xbar_pattern = re.compile(
        r"/AxiCrossbar\.v:(\d+): warning: @\* is sensitive to all ([123]) "
        r"words in array '([^']+)'\.$"
    )

    def explained(line: str) -> bool:
        if pmp_allowed.search(line) is not None or pmp_cfg_tail.search(line) is not None:
            return True
        match = xbar_pattern.search(line)
        if match is None:
            return False
        return xbar_sites.get(int(match.group(1))) == match.group(3)

    unexpected = [line for line in warning_lines if not explained(line)]
    if unexpected:
        raise ValueError(f"unexpected IFU compile warning: {unexpected[0]}")
    return {
        "status": "EXPLAINED",
        "count": len(warning_lines),
        "unique_lines": sorted(set(warning_lines)),
        "classification": "ICARUS_ARRAY_SENSITIVITY_AND_CONSTANT_UNSELECTED_GENVAR_BRANCH",
        "rtl_sites": [
            "npc/rv64/vsrc/memory/PmpChecker.v:105",
            "npc/rv64/vsrc/bus/AxiCrossbar.v:350",
        ],
        "explanation": (
            "entry_gen_idx is a generate-time constant; for entry 0 the ternary "
            "selects the all-zero lower bound, while Icarus still diagnoses the "
            "unselected entry_addr_w[-1] expression. Icarus @* sensitivity diagnostics "
            "state that every word of the PmpChecker and AxiCrossbar combinational "
            "arrays is included; they do not report an omitted signal. Current directed "
            "logs terminate PASS."
        ),
        "assertion_failure_observed": False,
        "unexplained_warning_count": 0,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence-dir", required=True, type=pathlib.Path)
    parser.add_argument("--post-result", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence_dir = args.evidence_dir.resolve(strict=True)
    output = args.output.resolve()
    if not evidence_dir.is_relative_to(HERE / "evidence"):
        raise ValueError("evidence directory escaped V14C task-run")
    output_local = output.parent == evidence_dir
    output_replay = (
        output.parent.is_relative_to(HERE / "evidence")
        and output.parent.name.startswith(
            "p0-replay-elimination-checker-replay-"
        )
    )
    if (not output_local and not output_replay) or output.name != "receipt.json":
        raise ValueError("receipt must be task-local or checker-replay local")
    if output.exists():
        raise ValueError("refusing to replace replay-elimination receipt")

    axi_result_path = evidence_dir / "results/ifu-axi-current.json"
    fetch_result_path = evidence_dir / "results/ifu-fetch-current.json"
    axi_mutation_path = evidence_dir / "mutations/ifu-axi/summary.json"
    fetch_mutation_path = evidence_dir / "mutations/ifu-fetch/summary.json"
    axi_result = load(axi_result_path)
    fetch_result = load(fetch_result_path)
    axi_mutation = load(axi_mutation_path)
    fetch_mutation = load(fetch_mutation_path)
    verify_result(
        axi_result, "npc-rv64-ifu-axi-flush-drain-evidence-v1", "IFU-AXI-G1"
    )
    verify_result(
        fetch_result,
        "npc-rv64-ifu-fetch-provenance-evidence-v1",
        "IFU-FETCH-G2",
    )
    verify_mutation(axi_mutation, "IFU-AXI-G1", 18)
    verify_mutation(fetch_mutation, "IFU-FETCH-G2", 16)

    summary_text = (MODULE_DIR / "summary.txt").read_text(encoding="utf-8")
    for marker in ("- total: 113", "- passed: 113", "- failed: 0"):
        if marker not in summary_text:
            raise ValueError("shared current module aggregate is incomplete")
    positive_logs = [
        MODULE_DIR / "logs/tb_ooo_fetch_axi_bridge.log",
        MODULE_DIR / "logs/tb_ooo_fetch_axi_bridge_xbar.log",
        MODULE_DIR / "logs/tb_axi_xbar.log",
        MODULE_DIR / "logs/tb_ooo_fetch_packet_decode.log",
        MODULE_DIR / "logs/tb_ooo_fetch_page_end_fault.log",
    ]
    for path in positive_logs:
        text = path.read_text(encoding="utf-8")
        if "[RESULT] PASS" not in text or "[RESULT] FAIL" in text:
            raise ValueError(f"current positive IFU log is not PASS: {path}")
    warnings = warning_audit(positive_logs)

    post_path = (
        args.post_result.resolve(strict=True)
        if args.post_result is not None
        else evidence_dir / "source-post-result.json"
    )
    post = load(post_path)
    before = load(V14B_SOURCE)
    source_set = post.get("rtl_source_set", {})
    if (
        post.get("overall_status") != "GREEN"
        or post.get("exit_code") != 0
        or source_set.get("design_id") != CURRENT_DESIGN_ID
        or source_set.get("file_count") != 146
        or source_set.get("files") != before.get("rtl_source_set", {}).get("files")
    ):
        raise ValueError("production RTL source map changed during replay elimination")

    negative_rows: list[dict[str, str]] = []

    def reject(case_id: str, action: Any) -> None:
        try:
            action()
        except ValueError as exc:
            negative_rows.append(
                {"case_id": case_id, "status": "REJECTED", "reason": str(exc)}
            )
            return
        raise ValueError(f"negative fixture accepted: {case_id}")

    wrong_design = copy.deepcopy(axi_result)
    wrong_design["design_id"] = "sha256:" + "0" * 64
    reject(
        "result-design-id-drift",
        lambda: verify_result(
            wrong_design,
            "npc-rv64-ifu-axi-flush-drain-evidence-v1",
            "IFU-AXI-G1",
        ),
    )
    incomplete = copy.deepcopy(axi_mutation)
    incomplete["dynamic_rejected"] = 17
    reject(
        "rtl-counterexample-not-rejected",
        lambda: verify_mutation(incomplete, "IFU-AXI-G1", 18),
    )

    source_run_status_path = HERE / f"{evidence_dir.name}.status"
    source_run_status = source_run_status_path.read_text(encoding="utf-8").strip()
    source_run = {
        "status": source_run_status,
        "status_path": source_run_status_path.relative_to(ROOT).as_posix(),
        "accepted_as_delivery": output_local and source_run_status == "PASS",
        "historical_status_rewritten": False,
    }
    if output_replay:
        source_run.update(
            {
                "accepted_as_delivery": False,
                "failure_classification": "WARNING_EXPLANATION_SET_INCOMPLETE",
                "semantic_rtl_results_reused": True,
            }
        )

    receipt = {
        "schema": "rv64-v14c-p0-replay-elimination-receipt-v1",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(),
        "status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope": ["IFU-AXI-G1", "IFU-FETCH-G2"],
        "scope_status": {
            "IFU-AXI-G1": "CURRENT_DYNAMIC_PASS",
            "IFU-FETCH-G2": "CURRENT_DYNAMIC_PASS",
        },
        "replay_dependency_for_delivery": False,
        "source_run": source_run,
        "positive_current_rtl": {
            path.stem: artifact(path) for path in positive_logs
        },
        "shared_current_module_aggregate": {
            "required": 113,
            "passed": 113,
            "summary": artifact(MODULE_DIR / "summary.txt"),
        },
        "compile_success_rtl_counterexamples": {
            "IFU-AXI-G1": {
                "required": 18,
                "detected": 18,
                "summary": artifact(axi_mutation_path),
            },
            "IFU-FETCH-G2": {
                "required": 16,
                "detected": 16,
                "summary": artifact(fetch_mutation_path),
            },
        },
        "positive_results": {
            "IFU-AXI-G1": artifact(axi_result_path),
            "IFU-FETCH-G2": artifact(fetch_result_path),
        },
        "warning_audit": warnings,
        "checker_negative_fixtures": {
            "required": 2,
            "detected": len(negative_rows),
            "cases": negative_rows,
        },
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "post_checker": artifact(post_path),
        },
        "supersedes_method_only": artifact(
            HERE / "evidence/current-bind-checker-replay-2/receipt.json"
        ),
        "publication": {
            "task_local_only": True,
            "canonical_write": False,
            "architecture_gate_state": "RED",
            "arch_stable": False,
            "ppa_state": "BLOCKED_BY_ARCHITECTURE",
        },
    }
    output.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14C-P0-REPLAY-ELIMINATION][PASS] "
        f"design_id={CURRENT_DESIGN_ID} current_positive=5/5 "
        "counterexamples=34/34 replay_dependency=0 source_pre_post=equal "
        f"unexplained_warnings={warnings['unexplained_warning_count']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-P0-REPLAY-ELIMINATION][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
