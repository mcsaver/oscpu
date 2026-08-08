#!/usr/bin/env python3
"""Replay the V15T public-name oracle from frozen e7da OpenSTA evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


RUN_ID = "2026-08-07-rv64-v15t-e7da-named-timing-path-a1"
EVIDENCE_LABEL = "traceable-e7da-a1"
EXPECTED_DESIGN_ID = (
    "sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308"
)
EXPECTED_ORIGINAL_STATUS = (
    "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0"
)
EXPECTED_PATHS = 40
START_PREFIX = "u_core_"
START_ANCHOR = "u_csr_file_csr_mtvec_q_63_"
END_PREFIX = "u_core_u_ooo_core_"
END_ANCHOR = "u_fetch_pc_outstanding_"
DFF_DESCRIPTION = "(rising edge-triggered flip-flop clocked by core_clock)"
OPAQUE_NAME_RE = re.compile(r"^_[0-9]+_")

PATH_TOKENS = (
    START_ANCHOR,
    "u_ooo_dual_mem_bridge_u_bridge1_effective_data_priv_func",
    "u_ooo_dual_mem_bridge_u_bridge1_translate_active_o",
    "u_ooo_dual_mem_bridge_u_bridge1_u_dtlb_lookup_context_hit_o",
    "u_ooo_dual_mem_bridge_u_bridge1_u_req_pmp_checker_fault_o",
    "u_ooo_dual_mem_bridge_u_bridge1_mem0_expected_effective_killed_i",
    "u_store_queue_query1_allow_o",
    "u_store_queue_query1_replay_o",
    "u_mem_owner_tracker_alloc1_ready_o",
    "u_mem_owner_tracker_free0_ready_o",
    "u_mem_owner_terminal_collector",
    "mem_owner_terminalized_o",
    "u_pending_drain_resolve_gate_backend_drained_q_i",
    "u_pending_drain_resolve_gate_pending_system_dispatched_i",
    "u_frontend_backend_dispatch_mux_system_csr_dispatch_valid_i",
    "u_frontend_dispatch_gate_frontend_dispatch_to_backend_valid_o",
    END_ANCHOR,
)
REQUIRED_ALL_PATH_TOKENS = (
    "u_ooo_dual_mem_bridge_u_bridge1_effective_data_priv_func",
    "u_mem_owner_terminal_collector",
    "u_pending_drain_resolve_gate_pending_system_dispatched_i",
    "u_frontend_dispatch_gate_frontend_dispatch_to_backend_valid_o",
)

START_RE = re.compile(
    rf"^Startpoint: (?P<name>\S+)\n\s+{re.escape(DFF_DESCRIPTION)}$",
    re.MULTILINE,
)
END_RE = re.compile(
    rf"^Endpoint: (?P<name>\S+)\n\s+{re.escape(DFF_DESCRIPTION)}$",
    re.MULTILINE,
)
BLOCK_RE = re.compile(r"(?ms)^Startpoint: .*?(?=^Startpoint: |\Z)")
SLACK_RE = re.compile(r"(?m)^\s*(-?\d+\.\d+)\s+slack \(VIOLATED\)\s*$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_key_values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if raw_line and "=" in raw_line:
            key, value = raw_line.split("=", 1)
            result[key] = value
    return result


def public_start(name: str) -> bool:
    return (
        name.startswith(START_PREFIX)
        and START_ANCHOR in name
        and "_DFF" in name
        and not OPAQUE_NAME_RE.match(name)
    )


def public_end(name: str) -> bool:
    return (
        name.startswith(END_PREFIX)
        and END_ANCHOR in name
        and "_DFF" in name
        and not OPAQUE_NAME_RE.match(name)
    )


def evaluate_report(text: str, expected_paths: int = EXPECTED_PATHS) -> dict[str, Any]:
    starts = [match.group("name") for match in START_RE.finditer(text)]
    ends = [match.group("name") for match in END_RE.finditer(text)]
    blocks = BLOCK_RE.findall(text)
    failures: list[str] = []

    for label, observed in (
        ("startpoint_count", len(starts)),
        ("endpoint_count", len(ends)),
        ("path_block_count", len(blocks)),
    ):
        if observed != expected_paths:
            failures.append(f"{label}={observed} expected={expected_paths}")

    public_starts = sum(public_start(name) for name in starts)
    public_ends = sum(public_end(name) for name in ends)
    if public_starts != expected_paths:
        failures.append(f"public_csr_startpoints={public_starts} expected={expected_paths}")
    if public_ends != expected_paths:
        failures.append(f"public_frontend_endpoints={public_ends} expected={expected_paths}")
    if len(set(starts)) != 1:
        failures.append(f"unique_startpoints={len(set(starts))} expected=1")
    if len(set(ends)) != expected_paths:
        failures.append(f"unique_endpoints={len(set(ends))} expected={expected_paths}")

    slacks: list[float] = []
    for index, block in enumerate(blocks):
        matches = SLACK_RE.findall(block)
        if len(matches) != 1:
            failures.append(f"path[{index}].violated_slack_count={len(matches)} expected=1")
        else:
            slacks.append(float(matches[0]))

    endpoint_classes = Counter(
        "jalr_prefetch_hit_available"
        if "jalr_prefetch_hit_available_i" in name
        else "redirect_valid"
        if "redirect_valid_i" in name
        else "other"
        for name in ends
    )
    expected_classes = Counter(
        {"jalr_prefetch_hit_available": 38, "redirect_valid": 2}
    )
    if endpoint_classes != expected_classes:
        failures.append(
            "endpoint_classes="
            + json.dumps(dict(sorted(endpoint_classes.items())), sort_keys=True)
        )

    token_counts = {
        token: sum(token in block for block in blocks) for token in PATH_TOKENS
    }
    for token in REQUIRED_ALL_PATH_TOKENS:
        if token_counts[token] != expected_paths:
            failures.append(
                f"required_token[{token}]={token_counts[token]} expected={expected_paths}"
            )

    return {
        "status": "PASS" if not failures else "FAIL",
        "failures": failures,
        "path_count": len(blocks),
        "startpoint_count": len(starts),
        "endpoint_count": len(ends),
        "unique_startpoints": len(set(starts)),
        "unique_endpoints": len(set(ends)),
        "public_csr_startpoints": public_starts,
        "public_frontend_endpoints": public_ends,
        "opaque_startpoints": sum(bool(OPAQUE_NAME_RE.match(name)) for name in starts),
        "opaque_endpoints": sum(bool(OPAQUE_NAME_RE.match(name)) for name in ends),
        "startpoint_anchor": START_ANCHOR,
        "endpoint_anchor": END_ANCHOR,
        "endpoint_classes": dict(sorted(endpoint_classes.items())),
        "path_token_counts": token_counts,
        "slack_ns": {
            "minimum": min(slacks) if slacks else None,
            "maximum": max(slacks) if slacks else None,
            "distinct": sorted(set(slacks)),
        },
    }


def iter_artifact_descriptors(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        if {"path", "path_scope", "sha256", "size_bytes"}.issubset(value):
            yield value
        for child in value.values():
            yield from iter_artifact_descriptors(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_artifact_descriptors(child)


def verify_summary_artifacts(repo_root: Path, summary: dict[str, Any]) -> dict[str, Any]:
    checked: list[dict[str, Any]] = []
    failures: list[str] = []
    seen: set[tuple[str, str]] = set()
    for descriptor in iter_artifact_descriptors(summary):
        key = (str(descriptor["path_scope"]), str(descriptor["path"]))
        if key in seen:
            continue
        seen.add(key)
        if descriptor["path_scope"] == "workspace_relative":
            path = repo_root / str(descriptor["path"])
        elif descriptor["path_scope"] == "external_absolute":
            path = Path(str(descriptor["path"]))
        else:
            failures.append(f"unsupported_path_scope={descriptor['path_scope']}")
            continue
        if not path.is_file() or path.is_symlink():
            failures.append(f"artifact_missing_or_symlink={path}")
            continue
        actual_size = path.stat().st_size
        actual_sha = sha256_file(path)
        if actual_size != int(descriptor["size_bytes"]):
            failures.append(f"artifact_size_drift={path}")
        if actual_sha != descriptor["sha256"]:
            failures.append(f"artifact_hash_drift={path}")
        checked.append(
            {
                "path": str(descriptor["path"]),
                "path_scope": str(descriptor["path_scope"]),
                "sha256": actual_sha,
                "size_bytes": actual_size,
            }
        )
    if not checked:
        failures.append("no_summary_artifacts_checked")
    return {
        "status": "PASS" if not failures else "FAIL",
        "checked_count": len(checked),
        "failures": failures,
        "artifacts": checked,
    }


def verify_pre_manifest(path: Path) -> dict[str, Any]:
    failures: list[str] = []
    checked = 0
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        match = re.fullmatch(r"([0-9a-f]{64})\s+(.+)", raw_line)
        if not match:
            failures.append(f"manifest_line[{line_number}]=invalid")
            continue
        expected_sha, raw_path = match.groups()
        candidate = Path(raw_path)
        if not candidate.is_file() or candidate.is_symlink():
            failures.append(f"manifest_file_missing_or_symlink={candidate}")
            continue
        checked += 1
        if sha256_file(candidate) != expected_sha:
            failures.append(f"manifest_hash_drift={candidate}")
    if checked == 0:
        failures.append("manifest_checked_count=0")
    return {
        "status": "PASS" if not failures else "FAIL",
        "checked_count": checked,
        "failures": failures,
        "manifest_sha256": sha256_file(path),
    }


def current_design_id(repo_root: Path) -> str:
    sys.path.insert(0, str(repo_root))
    from npc.rv64.eval.ppa.tools.architecture_hard_gates import rtl_binding

    return "sha256:" + rtl_binding(repo_root)[0]


def replay(output: Path) -> int:
    script_path = Path(__file__).resolve()
    repo_root = script_path.parents[4]
    run_dir = repo_root / ".github" / "task-runs" / RUN_ID
    evidence_dir = run_dir / "evidence" / EVIDENCE_LABEL
    report_path = evidence_dir / "opensta-top40.rpt"
    summary_path = evidence_dir / "summary.json"
    original_status_path = run_dir / f"{EVIDENCE_LABEL}.status"
    command_status_path = evidence_dir / "command-status.txt"
    traceability_path = evidence_dir / "traceability.txt"
    pre_manifest_path = evidence_dir / "production-manifest-before.sha256"
    runtime_base = (
        repo_root / ".github" / "runtime-artifacts" / "v15t-e7da-named-timing-path-a1"
    )

    failures: list[str] = []
    required_files = (
        report_path,
        summary_path,
        original_status_path,
        command_status_path,
        traceability_path,
        pre_manifest_path,
    )
    for path in required_files:
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            failures.append(f"required_file_missing_empty_or_symlink={path}")
    if failures:
        result = {"schema": 1, "status": "FAIL", "failures": failures}
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        return 1

    original_status = original_status_path.read_text(encoding="utf-8").strip()
    command_status = parse_key_values(command_status_path)
    original_traceability = parse_key_values(traceability_path)
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    report = evaluate_report(report_path.read_text(encoding="utf-8"))
    artifact_verification = verify_summary_artifacts(repo_root, summary)
    manifest_verification = verify_pre_manifest(pre_manifest_path)
    observed_design_id = current_design_id(repo_root)

    if original_status != EXPECTED_ORIGINAL_STATUS:
        failures.append(f"original_status={original_status!r}")
    expected_command_status = {
        "preflight_rc": "0",
        "manifest_rc": "0",
        "synth_rc": "0",
        "opensta_rc": "0",
        "parser_rc": "0",
        "trace_rc": "1",
        "cleanup_rc": "0",
        "runtime_bytes_deleted": "0",
    }
    if command_status != expected_command_status:
        failures.append("command_status_contract_mismatch")
    expected_traceability = {
        "status": "FAIL",
        "startpoints": "40",
        "endpoints": "40",
        "public_flat_startpoints": "0",
        "public_flat_endpoints": "40",
        "opaque_startpoints": "0",
        "opaque_endpoints": "0",
    }
    if original_traceability != expected_traceability:
        failures.append("original_traceability_contract_mismatch")
    if summary.get("status") != "PASS":
        failures.append(f"summary_status={summary.get('status')!r}")
    timing = summary.get("timing", {})
    expected_timing = {
        "wns_ns": -17.592411041,
        "tns_ns": -468716.46875,
        "top_path_count": EXPECTED_PATHS,
        "violated_path_count": EXPECTED_PATHS,
        "combinational_loops": 0,
    }
    for key, expected in expected_timing.items():
        if timing.get(key) != expected:
            failures.append(f"summary.timing.{key}={timing.get(key)!r} expected={expected!r}")
    area = summary.get("synthesis", {}).get("area", {})
    if area.get("logic_area_proxy_excluding_unknown_macros") != 2181644.08:
        failures.append("summary.area_proxy_mismatch")
    if area.get("total_cells_including_unknown_macros") != 929222:
        failures.append("summary.total_cells_mismatch")
    if report["status"] != "PASS":
        failures.extend(f"report:{item}" for item in report["failures"])
    if artifact_verification["status"] != "PASS":
        failures.extend(f"artifact:{item}" for item in artifact_verification["failures"])
    if manifest_verification["status"] != "PASS":
        failures.extend(f"manifest:{item}" for item in manifest_verification["failures"])
    if observed_design_id != EXPECTED_DESIGN_ID:
        failures.append(
            f"design_id expected={EXPECTED_DESIGN_ID} observed={observed_design_id}"
        )
    if runtime_base.exists():
        failures.append(f"runtime_base_retained={runtime_base}")

    result = {
        "schema": 1,
        "status": "PASS" if not failures else "FAIL",
        "classification": (
            "EDA_TRANSACTION_COMPLETE_ORIGINAL_START_PREFIX_ORACLE_FALSE_NEGATIVE"
            if not failures
            else "REPLAY_CONTRACT_FAILED"
        ),
        "failures": failures,
        "design": {"expected_id": EXPECTED_DESIGN_ID, "observed_id": observed_design_id},
        "original_run": {
            "status": original_status,
            "status_sha256": sha256_file(original_status_path),
            "command_status": command_status,
            "command_status_sha256": sha256_file(command_status_path),
            "traceability": original_traceability,
            "traceability_sha256": sha256_file(traceability_path),
        },
        "corrected_name_contract": {
            "policy": (
                "accept public flattened CSR launch names rooted at u_core_ and "
                "frontend endpoints rooted at u_core_u_ooo_core_; require RTL anchors, "
                "DFF endpoints, the observed 38/2 endpoint classes, and no opaque leading IDs"
            ),
            "report": report,
            "report_sha256": sha256_file(report_path),
        },
        "summary": {
            "sha256": sha256_file(summary_path),
            "status": summary.get("status"),
            "timing": timing,
            "area": area,
            "power": summary.get("power", {}),
        },
        "artifact_verification": artifact_verification,
        "production_manifest_replay": manifest_verification,
        "runtime_cleanup": {
            "status": "PASS" if not runtime_base.exists() else "FAIL",
            "runtime_base": str(runtime_base.relative_to(repo_root)),
            "netlist_retained": runtime_base.exists(),
        },
        "checker": {
            "path": str(script_path.relative_to(repo_root)),
            "sha256": sha256_file(script_path),
        },
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        f"[V15T-CSR-START-REPLAY][{result['status']}] "
        f"original=FAIL paths={report['path_count']} "
        f"unique_starts={report['unique_startpoints']} "
        f"unique_ends={report['unique_endpoints']} design_id={observed_design_id}"
    )
    return 0 if not failures else 1


def synthetic_report(
    *,
    path_count: int = EXPECTED_PATHS,
    start: str | None = None,
    endpoint_anchor: str = END_ANCHOR,
    include_required: bool = True,
    dff: bool = True,
) -> str:
    start_name = start or (
        START_PREFIX + START_ANCHOR + "DFFQX1H7L_Q_D_AOI21_Y_DFFQX1H7L_D"
    )
    descriptor = DFF_DESCRIPTION if dff else "(input port clocked by core_clock)"
    blocks = []
    for index in range(path_count):
        endpoint_class = (
            "jalr_prefetch_hit_available_i" if index < 38 else "redirect_valid_i"
        )
        end_name = (
            END_PREFIX
            + endpoint_anchor
            + endpoint_class
            + f"_MUX_{index}_Y_DFFQX1H7L_D"
        )
        path_tokens = list(REQUIRED_ALL_PATH_TOKENS) if include_required else []
        path_lines = "\n".join(f" 0.100000000 {token}" for token in path_tokens)
        blocks.append(
            f"Startpoint: {start_name}\n"
            f"            {descriptor}\n"
            f"Endpoint: {end_name}\n"
            f"          {descriptor}\n"
            "Path Group: core_clock\n"
            "Path Type: max\n\n"
            f"{path_lines}\n"
            " -1.000000000   slack (VIOLATED)\n"
        )
    return "\n".join(blocks)


def self_test() -> int:
    valid_start = START_PREFIX + START_ANCHOR + "DFFQ_Q_D_AOI21_Y_DFFQ_D"
    tests: list[tuple[str, str, str]] = [
        ("positive_public_csr_start", synthetic_report(start=valid_start), "PASS"),
        ("negative_path_count", synthetic_report(path_count=39, start=valid_start), "FAIL"),
        (
            "negative_non_core_prefix",
            synthetic_report(start="u_soc_" + START_ANCHOR + "DFFQ_D"),
            "FAIL",
        ),
        (
            "negative_start_anchor",
            synthetic_report(start=START_PREFIX + "u_csr_file_other_q_DFFQ_D"),
            "FAIL",
        ),
        (
            "negative_endpoint_anchor",
            synthetic_report(start=valid_start, endpoint_anchor="u_other_state_"),
            "FAIL",
        ),
        (
            "negative_missing_required_path_token",
            synthetic_report(start=valid_start, include_required=False),
            "FAIL",
        ),
        (
            "negative_non_dff_descriptor",
            synthetic_report(start=valid_start, dff=False),
            "FAIL",
        ),
        (
            "negative_opaque_start",
            synthetic_report(start="_337_" + START_ANCHOR + "_DFF_D"),
            "FAIL",
        ),
    ]
    failures = []
    for name, report, expected in tests:
        observed = evaluate_report(report)["status"]
        if observed != expected:
            failures.append(f"{name}: expected={expected} observed={observed}")
    if failures:
        for failure in failures:
            print(f"[V15T-CSR-START-SELFTEST][FAIL] {failure}", file=sys.stderr)
        return 1
    print(
        f"[V15T-CSR-START-SELFTEST][PASS] tests={len(tests)} positive=1 negative=7"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    replay_parser = subparsers.add_parser("replay")
    replay_parser.add_argument("--output", type=Path, required=True)
    subparsers.add_parser("self-test")
    args = parser.parse_args()
    if args.command == "self-test":
        return self_test()
    return replay(args.output.resolve())


if __name__ == "__main__":
    raise SystemExit(main())
