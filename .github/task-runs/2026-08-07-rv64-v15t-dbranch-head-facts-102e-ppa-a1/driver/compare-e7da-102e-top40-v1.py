#!/usr/bin/env python3
"""Replay the V15T same-configuration mapped PPA and Top40 comparison."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[4]
OLD_RUN = REPO / ".github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1"
NEW_RUN = REPO / ".github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1"
OLD_EVIDENCE = OLD_RUN / "evidence/traceable-e7da-a1"
NEW_EVIDENCE = NEW_RUN / "evidence/traceable-102e-a1"
OUTPUT = NEW_RUN / "evidence/ppa-delta-and-path-cluster-v1.json"

OLD_DESIGN = "sha256:e7da70efa0317b96ec6bbd174c24ad8f9d1e0bda69fbc2e6723d6b1c424d7308"
NEW_DESIGN = "sha256:102e2f600d396b63f41172597c43011da1b3c8b28947f88e14f0cf4d8f37e90d"

TOKENS = (
    "dispatch0_unsupported_raw_o",
    "dispatch1_unsupported_raw_o",
    "dispatch0_unsupported_o",
    "dispatch1_unsupported_o",
    "u_frontend_dispatch_gate",
    "dbranch_dual_go",
    "system_csr_dispatch_valid",
    "pending_system_inst",
    "u_mem_owner_terminal_collector",
    "mem_owner_terminalized",
    "u_mem_owner_tracker",
    "u_store_queue_query1",
    "u_fetch_pc_outstanding",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_paths(text: str) -> list[dict[str, object]]:
    blocks = [
        block
        for block in re.split(r"(?=^Startpoint: )", text, flags=re.MULTILINE)
        if block.startswith("Startpoint: ")
    ]
    result: list[dict[str, object]] = []
    for index, block in enumerate(blocks, start=1):
        start_match = re.search(r"^Startpoint: (\S+)", block, re.MULTILINE)
        end_match = re.search(r"^Endpoint: (\S+)", block, re.MULTILINE)
        slack_match = re.search(
            r"^\s*(-?\d+(?:\.\d+)?)\s+slack \(VIOLATED\)\s*$",
            block,
            re.MULTILINE,
        )
        if not (start_match and end_match and slack_match):
            raise ValueError(f"path {index}: incomplete Startpoint/Endpoint/slack")
        endpoint = end_match.group(1)
        if "jalr_prefetch_hit_available" in endpoint:
            endpoint_class = "jalr_prefetch_hit_available"
        elif "redirect_valid" in endpoint:
            endpoint_class = "redirect_valid"
        else:
            endpoint_class = "other"
        result.append(
            {
                "startpoint": start_match.group(1),
                "endpoint": endpoint,
                "endpoint_class": endpoint_class,
                "slack_ns": float(slack_match.group(1)),
                "token_present": {token: token in block for token in TOKENS},
                "token_occurrences": {token: block.count(token) for token in TOKENS},
            }
        )
    return result


def cluster(paths: list[dict[str, object]]) -> dict[str, object]:
    starts = {str(path["startpoint"]) for path in paths}
    ends = {str(path["endpoint"]) for path in paths}
    endpoint_classes: dict[str, int] = {}
    for path in paths:
        key = str(path["endpoint_class"])
        endpoint_classes[key] = endpoint_classes.get(key, 0) + 1
    return {
        "path_count": len(paths),
        "unique_startpoints": len(starts),
        "startpoints": sorted(starts),
        "unique_endpoints": len(ends),
        "endpoint_classes": dict(sorted(endpoint_classes.items())),
        "slack_ns": {
            "minimum": min(float(path["slack_ns"]) for path in paths),
            "maximum": max(float(path["slack_ns"]) for path in paths),
            "distinct_count": len({float(path["slack_ns"]) for path in paths}),
        },
        "token_path_counts": {
            token: sum(bool(path["token_present"][token]) for path in paths)  # type: ignore[index]
            for token in TOKENS
        },
        "token_occurrence_counts": {
            token: sum(int(path["token_occurrences"][token]) for path in paths)  # type: ignore[index]
            for token in TOKENS
        },
    }


def load_summary(path: Path) -> dict[str, object]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def metrics(summary: dict[str, object]) -> dict[str, object]:
    timing = summary["timing"]  # type: ignore[index]
    area = summary["synthesis"]["area"]  # type: ignore[index]
    power = summary["power"]  # type: ignore[index]
    return {
        "period_ns": summary["period_ns"],
        "wns_ns": timing["wns_ns"],  # type: ignore[index]
        "tns_ns": timing["tns_ns"],  # type: ignore[index]
        "logic_area_proxy": area["logic_area_proxy_excluding_unknown_macros"],  # type: ignore[index]
        "known_standard_cells": area["known_standard_cells"],  # type: ignore[index]
        "total_cells": area["total_cells_including_unknown_macros"],  # type: ignore[index]
        "combinational_loops": timing["combinational_loops"],  # type: ignore[index]
        "power_total_vectorless_w": power["total_vectorless_w"],  # type: ignore[index]
        "power_qualification": power["qualification"],  # type: ignore[index]
    }


def verify_summary_artifacts(summary: dict[str, object]) -> tuple[int, list[str]]:
    checked = 0
    errors: list[str] = []
    groups = [summary["artifacts"], summary["inputs"]]  # type: ignore[index]
    groups.append({"source_manifest": summary["source_manifest"]})
    synth = summary["synthesis"]  # type: ignore[index]
    groups.append(
        {
            "sta_export_check": synth["sta_export_check"],  # type: ignore[index]
            "sta_netlist_compatibility": synth["sta_netlist_compatibility"],  # type: ignore[index]
            "synth_check": synth["synth_check"],  # type: ignore[index]
            "synth_stat": synth["synth_stat"],  # type: ignore[index]
        }
    )
    for group in groups:
        for name, descriptor in group.items():  # type: ignore[union-attr]
            scope = descriptor["path_scope"]
            path = Path(descriptor["path"])
            if scope == "workspace_relative":
                path = REPO / path
            if not path.is_file():
                errors.append(f"missing artifact {name}: {path}")
                continue
            checked += 1
            if path.stat().st_size != descriptor["size_bytes"]:
                errors.append(f"size mismatch {name}")
            if sha256(path) != descriptor["sha256"]:
                errors.append(f"sha256 mismatch {name}")
    return checked, errors


def close(left: float, right: float, tolerance: float = 1e-9) -> bool:
    return math.isclose(left, right, rel_tol=0.0, abs_tol=tolerance)


def self_test() -> dict[str, object]:
    base = """Startpoint: u_core_u_csr_file_csr_mtvec_q_63__DFF\nEndpoint: u_core_u_fetch_pc_outstanding_jalr_prefetch_hit_available_DFF\ndispatch0_unsupported_raw_o\n -1.250000000 slack (VIOLATED)\n"""
    positives = 0
    negatives = 0
    parsed = parse_paths(base)
    assert len(parsed) == 1
    assert parsed[0]["endpoint_class"] == "jalr_prefetch_hit_available"
    assert parsed[0]["token_present"]["dispatch0_unsupported_raw_o"]  # type: ignore[index]
    positives += 1
    for broken in (
        base.replace("Startpoint:", "Launch:"),
        base.replace("Endpoint:", "Capture:"),
        base.replace("slack (VIOLATED)", "slack (MET)"),
    ):
        try:
            rejected = len(parse_paths(broken)) != 1
        except ValueError:
            rejected = True
        if rejected:
            negatives += 1
    assert negatives == 3
    return {"status": "PASS", "positive_cases": positives, "negative_cases": negatives}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    if args.self_test:
        print(json.dumps(self_test(), indent=2, sort_keys=True))
        return 0

    errors: list[str] = []
    old_report = OLD_EVIDENCE / "opensta-top40.rpt"
    new_report = NEW_EVIDENCE / "opensta-top40.rpt"
    old_summary_path = OLD_EVIDENCE / "summary.json"
    new_summary_path = NEW_EVIDENCE / "summary.json"
    old_summary = load_summary(old_summary_path)
    new_summary = load_summary(new_summary_path)
    old_paths = parse_paths(old_report.read_text(encoding="utf-8"))
    new_paths = parse_paths(new_report.read_text(encoding="utf-8"))
    old_cluster = cluster(old_paths)
    new_cluster = cluster(new_paths)
    old_metrics = metrics(old_summary)
    new_metrics = metrics(new_summary)

    for label, summary in (("e7da", old_summary), ("102e", new_summary)):
        if summary.get("status") != "PASS":
            errors.append(f"{label} summary status is not PASS")
        if summary.get("period_ns") != 5.0:
            errors.append(f"{label} period is not 5.0ns")

    expected_endpoint_classes = {"jalr_prefetch_hit_available": 38, "redirect_valid": 2}
    for label, item in (("e7da", old_cluster), ("102e", new_cluster)):
        if item["path_count"] != 40:
            errors.append(f"{label}: expected 40 paths")
        if item["unique_startpoints"] != 1:
            errors.append(f"{label}: expected one launch register")
        if item["unique_endpoints"] != 40:
            errors.append(f"{label}: expected 40 unique endpoints")
        if item["endpoint_classes"] != expected_endpoint_classes:
            errors.append(f"{label}: endpoint cluster changed")

    old_raw_paths = old_cluster["token_path_counts"]["dispatch0_unsupported_raw_o"]  # type: ignore[index]
    new_raw_paths = new_cluster["token_path_counts"]["dispatch0_unsupported_raw_o"]  # type: ignore[index]
    if old_raw_paths != 40:
        errors.append(f"e7da: expected raw unsupported segment in 40 paths, got {old_raw_paths}")
    if new_raw_paths != 0:
        errors.append(f"102e: removed raw unsupported segment remains in {new_raw_paths} paths")

    delta = {
        "wns_improvement_ns": float(new_metrics["wns_ns"]) - float(old_metrics["wns_ns"]),
        "tns_improvement_ns": float(new_metrics["tns_ns"]) - float(old_metrics["tns_ns"]),
        "logic_area_proxy_delta": float(new_metrics["logic_area_proxy"]) - float(old_metrics["logic_area_proxy"]),
        "known_standard_cells_delta": int(new_metrics["known_standard_cells"]) - int(old_metrics["known_standard_cells"]),
        "total_cells_delta": int(new_metrics["total_cells"]) - int(old_metrics["total_cells"]),
        "power_total_vectorless_w_delta": float(new_metrics["power_total_vectorless_w"]) - float(old_metrics["power_total_vectorless_w"]),
    }
    if delta["wns_improvement_ns"] <= 0.0:
        errors.append("WNS did not improve")
    if delta["tns_improvement_ns"] <= 0.0:
        errors.append("TNS did not improve")
    if delta["logic_area_proxy_delta"] > 0.0:
        errors.append("logic area proxy regressed")
    if delta["total_cells_delta"] > 0:
        errors.append("total mapped cell count regressed")
    if not close(delta["power_total_vectorless_w_delta"], 0.0):
        errors.append("fixed-toggle relative power changed at report precision")

    checked, artifact_errors = verify_summary_artifacts(new_summary)
    errors.extend(artifact_errors)
    if checked != 14:
        errors.append(f"expected 14 checked 102e summary artifacts, got {checked}")

    new_status = (NEW_RUN / "traceable-102e-a1.status").read_text(encoding="utf-8").strip()
    cleanup = (NEW_EVIDENCE / "cleanup.txt").read_text(encoding="utf-8")
    before_manifest = NEW_EVIDENCE / "production-manifest-before.sha256"
    after_manifest = NEW_EVIDENCE / "production-manifest-after.sha256"
    if new_status != "PASS":
        errors.append(f"102e transaction status is {new_status!r}")
    if "runtime_deleted=PASS" not in cleanup or "netlist_retained=NO" not in cleanup:
        errors.append("102e cleanup contract is incomplete")
    if before_manifest.read_bytes() != after_manifest.read_bytes():
        errors.append("102e production manifest drifted")

    result = {
        "schema": 1,
        "status": "FAIL" if errors else "PASS",
        "classification": (
            "V15T_H1_CONFIRMED_RAW_UNSUPPORTED_SEGMENT_REMOVED_WITH_POSITIVE_PPA_DELTA"
            if not errors
            else "V15T_H1_REPLAY_CHECK_FAILED"
        ),
        "design_ids": {"baseline": OLD_DESIGN, "candidate": NEW_DESIGN},
        "configuration": {
            "period_ns": 5.0,
            "mapped_library_sha256": new_summary["inputs"]["std_lib"]["sha256"],  # type: ignore[index]
            "power_qualification": new_metrics["power_qualification"],
        },
        "source_evidence": {
            "baseline_top40": {"path": str(old_report.relative_to(REPO)), "sha256": sha256(old_report)},
            "candidate_top40": {"path": str(new_report.relative_to(REPO)), "sha256": sha256(new_report)},
            "baseline_summary": {"path": str(old_summary_path.relative_to(REPO)), "sha256": sha256(old_summary_path)},
            "candidate_summary": {"path": str(new_summary_path.relative_to(REPO)), "sha256": sha256(new_summary_path)},
            "candidate_artifacts_checked": checked,
            "candidate_production_manifest_sha256": sha256(before_manifest),
            "candidate_runtime_netlist_retained": False,
        },
        "baseline": {"metrics": old_metrics, "top40": old_cluster},
        "candidate": {"metrics": new_metrics, "top40": new_cluster},
        "delta_candidate_minus_baseline": delta,
        "hypothesis_result": {
            "id": "V15T-H1-POST-MUX-UNSUPPORTED-RAW-FEEDBACK",
            "result": "CONFIRMED" if not errors else "NOT_CONFIRMED",
            "raw_unsupported_path_count_before": old_raw_paths,
            "raw_unsupported_path_count_after": new_raw_paths,
            "scope": "same 5.0ns mapped configuration; fixed-toggle power is relative-only",
            "next_scope": "The remaining Top40 still crosses the memory bridge, store-queue, owner-terminal and frontend/fetch feedback chain; select the next RTL hypothesis from the 102e path, not the eliminated raw predicate.",
        },
        "self_test": self_test(),
        "errors": errors,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "output": str(args.output), "errors": errors}, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
