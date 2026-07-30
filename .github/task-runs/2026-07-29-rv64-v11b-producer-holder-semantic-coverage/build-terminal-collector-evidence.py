#!/usr/bin/env python3
"""Validate and publish current-design V11B terminal-collector evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


TEST = "tb_ooo_mem_owner_terminal_collector"
POSITIVE_MARKERS = (
    "[V9Y-TCOLL-ACCEPT-NEGATIVE] tuple=0 duplicate=0 PASS",
    "[V8P-TCOLL-12INGRESS-CAPTURE]",
    "[V9Y-TCOLL-SAME-EDGE-REENQUEUE] accept=0 PASS",
    "[V11B-TCOLL-LANE1-TURNOVER] lane0_hold=1 pending=11 PASS",
    "[V11B-TCOLL-LANE0-TURNOVER] lane1_hold=1 pending=10 PASS",
    "[V8P-TCOLL-12INGRESS-DRAIN]",
    "[PASS] tb_ooo_mem_owner_terminal_collector",
    "[RESULT] PASS",
)
MUTATIONS = {
    "drop-ingress-known-assertion":
        "[V11B-TCOLL-UNKNOWN-NEGATIVE][FAIL]",
    "lane1-reuses-lane0-grant":
        "two registered outputs did not select distinct pending terminals",
    "same-edge-accept-cut":
        "same-edge dequeue/re-enqueue raw ingress was marked accepted",
}


class EvidenceError(RuntimeError):
    """Raised when the focused evidence is incomplete or source-stale."""


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise EvidenceError(f"JSON root is not an object: {path}")
    return payload


def entry(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    return {
        "path": path.resolve().relative_to(root).as_posix(),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def require_once(text: str, marker: str, label: str) -> None:
    count = text.count(marker)
    if count != 1:
        raise EvidenceError(
            f"{label} marker count mismatch: {marker!r} count={count}"
        )


def parse_manifest(root: pathlib.Path, path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        digest, raw = line.split(None, 1)
        source = pathlib.Path(raw.strip())
        if not source.is_absolute():
            source = root / source
        key = source.resolve().relative_to(root).as_posix()
        result[key] = digest
    return result


def current_design_id(root: pathlib.Path) -> str:
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--evidence-dir", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    evidence = args.evidence_dir.resolve()
    design_id = current_design_id(root)

    rtl_pre_path = evidence / "rtl-source-binding.pre.json"
    rtl_post_path = evidence / "rtl-source-binding.post.json"
    rtl_pre = load_json(rtl_pre_path)
    rtl_post = load_json(rtl_post_path)
    if rtl_pre != rtl_post or rtl_pre.get("design_id") != design_id:
        raise EvidenceError("full RTL pre/post/current design binding mismatch")
    for value, expected in rtl_pre.get("rtl_files", {}).items():
        path = root / value
        if not path.is_file() or sha256(path) != expected:
            raise EvidenceError(f"live RTL differs from snapshot: {value}")

    source_pre_path = evidence / "sources.pre.sha256"
    source_post_path = evidence / "sources.post.sha256"
    source_pre = parse_manifest(root, source_pre_path)
    source_post = parse_manifest(root, source_post_path)
    if source_pre != source_post:
        raise EvidenceError("focused runner sources changed during execution")
    for value, expected in source_pre.items():
        path = root / value
        if not path.is_file() or sha256(path) != expected:
            raise EvidenceError(f"live focused source differs: {value}")

    positive: dict[str, Any] = {}
    for profile in ("assert", "release"):
        path = evidence / profile / "result/logs" / f"{TEST}.log"
        text = path.read_text(encoding="utf-8")
        for marker in POSITIVE_MARKERS:
            require_once(text, marker, f"{profile} positive")
        if "[V8P-TCOLL-12INGRESS][FAIL]" in text:
            raise EvidenceError(f"{profile} positive emitted a failure marker")
        compile_line = next(
            line for line in text.splitlines() if line.startswith("[COMPILE]")
        )
        if profile == "assert" and "-DOOO_ASSERT" not in compile_line:
            raise EvidenceError("assert profile did not enable OOO_ASSERT")
        if profile == "release" and "-DOOO_ASSERT" in compile_line:
            raise EvidenceError("release profile unexpectedly enabled OOO_ASSERT")
        positive[profile] = entry(root, path)

    unknown_path = (
        evidence / "unknown-negative/result/logs" / f"{TEST}.log"
    )
    unknown_text = unknown_path.read_text(encoding="utf-8")
    require_once(
        unknown_text,
        "[V11B-TCOLL-INGRESS-TUPLE-KNOWN]",
        "unknown-negative",
    )
    require_once(unknown_text, "[RESULT] FAIL", "unknown-negative")
    if "[V11B-TCOLL-UNKNOWN-NEGATIVE][FAIL]" in unknown_text:
        raise EvidenceError("unknown-negative escaped the RTL assertion")

    mutation_records: list[dict[str, Any]] = []
    for case, expected in MUTATIONS.items():
        case_dir = evidence / "mutations" / case
        receipt_path = case_dir / "mutator.json"
        receipt = load_json(receipt_path)
        if (
            receipt.get("case") != case
            or receipt.get("changed") is not True
        ):
            raise EvidenceError(f"mutation receipt mismatch: {case}")
        log_path = case_dir / "result/logs" / f"{TEST}.log"
        text = log_path.read_text(encoding="utf-8")
        require_once(text, expected, f"mutation {case}")
        require_once(text, "[RESULT] FAIL", f"mutation {case}")
        if case == "drop-ingress-known-assertion" and (
            "[V11B-TCOLL-INGRESS-TUPLE-KNOWN]" in text
        ):
            raise EvidenceError("known-guard mutant retained the RTL marker")
        image_path = case_dir / "build" / f"{TEST}.vvp"
        if not image_path.is_file() or image_path.stat().st_size == 0:
            raise EvidenceError(f"mutation did not compile: {case}")
        mutation_records.append(
            {
                "case": case,
                "compile_success": True,
                "dynamically_rejected": True,
                "expected_marker": expected,
                "receipt": entry(root, receipt_path),
                "log": entry(root, log_path),
                "compiled_image": entry(root, image_path),
            }
        )

    lane_path = evidence / "terminal-collector-lane-contract.json"
    lane = load_json(lane_path)
    if (
        lane.get("status") != "PASS"
        or lane.get("design_id") != design_id
        or len(lane.get("lanes", [])) != 12
        or len(lane.get("tracker_free_lanes", [])) != 2
        or lane.get("raw_ingress_is_transfer_authority") is not False
        or lane.get("duplicate_ingress_is_merged") is not False
    ):
        raise EvidenceError("static lane-pair contract is not current PASS")

    output = {
        "schema_version": "rv64-v11b-terminal-collector-evidence-v1",
        "result": "PASS",
        "design_id": design_id,
        "source_binding": {
            "rtl_pre": entry(root, rtl_pre_path),
            "rtl_post": entry(root, rtl_post_path),
            "runner_pre": entry(root, source_pre_path),
            "runner_post": entry(root, source_post_path),
            "rtl_file_count": len(rtl_pre["rtl_files"]),
            "runner_file_count": len(source_pre),
        },
        "static_lane_contract": {
            "ingress_lanes": 12,
            "tracker_free_lanes": 2,
            "accepted_transfer_only": True,
            "duplicate_ingress_merged": False,
            "artifact": entry(root, lane_path),
        },
        "positive_profiles": positive,
        "positive_profile_count": 2,
        "raw_unknown_negative": entry(root, unknown_path),
        "compile_success_mutations": mutation_records,
        "mutation_count": len(mutation_records),
        "rejected_mutation_count": len(mutation_records),
        "claim_boundary": (
            "Closes the terminal collector's twelve ingress tuple mapping, "
            "two raw dequeue lanes, accepted-only handoff, valid-input "
            "identity-known assertion and asymmetric lane turnover. It does "
            "not close the other producer/holder census units, whole "
            "architecture, Linux replay, synthesis/STA/power or PPA."
        ),
    }
    args.output.write_text(
        json.dumps(output, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V11B-TCOLL-EVIDENCE][PASS] "
        f"design_id={design_id} ingress=12 free=2 profiles=2 "
        f"mutations={len(mutation_records)}/{len(MUTATIONS)}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except EvidenceError as exc:
        print(f"[V11B-TCOLL-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
