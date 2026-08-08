#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


REPO = Path(__file__).resolve().parents[4]
BASE_DIR = REPO / ".github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/traceable-e34b-a1"
NEW_DIR = REPO / ".github/task-runs/2026-08-07-rv64-v15v-csr-commit-dispatch-disjoint-ca37-ppa-a1/evidence/traceable-ca37-a1"
BASE_DESIGN_ID = "sha256:e34bcf47cf2e69976190cff4a13cf21b4f8f3e18495858b3256e9d5205bec6ce"
NEW_DESIGN_ID = "sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_summary(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(value.get("schema") == "npc-rv64-v15p-mapped-sta-variant-v1",
            f"unexpected summary schema: {path}")
    require(value.get("status") == "PASS", f"summary is not PASS: {path}")
    return value


def normalized_parameters(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    return [line for line in lines if not line.startswith("result_root=")]


def split_paths(text: str) -> list[str]:
    sections = ["Startpoint:" + item for item in text.split("Startpoint:")[1:]]
    require(len(sections) == 40, f"expected 40 paths, got {len(sections)}")
    return sections


TOKENS = (
    "pending_system_csr_commit",
    "head0_csr_commit",
    "system_csr_dispatch_cancel",
    "system_csr_dispatch_valid",
    "pending_system_inst",
)


def path_profile(text: str) -> dict:
    sections = split_paths(text)
    startpoints = [section.splitlines()[0].removeprefix("Startpoint: ")
                   for section in sections]
    endpoints = []
    for section in sections:
        endpoint_line = next(line for line in section.splitlines()
                             if line.startswith("Endpoint:"))
        endpoints.append(endpoint_line.removeprefix("Endpoint: "))
    endpoint_classes = {
        "jalr_prefetch_hit_available": sum(
            "jalr_prefetch_hit_available" in endpoint for endpoint in endpoints),
        "redirect_valid": sum("redirect_valid" in endpoint
                              for endpoint in endpoints),
    }
    lower_sections = [section.lower() for section in sections]
    return {
        "path_count": len(sections),
        "unique_startpoints": len(set(startpoints)),
        "startpoint": startpoints[0] if len(set(startpoints)) == 1 else None,
        "unique_endpoints": len(set(endpoints)),
        "endpoint_classes": endpoint_classes,
        "token_path_counts": {
            token: sum(token.lower() in section for section in lower_sections)
            for token in TOKENS
        },
    }


def validate_path_transition(base_paths: dict, new_paths: dict) -> None:
    expected_endpoints = {
        "jalr_prefetch_hit_available": 38,
        "redirect_valid": 2,
    }
    require(base_paths["endpoint_classes"] == expected_endpoints,
            "e34b Top40 endpoint-class mismatch")
    require(new_paths["endpoint_classes"] == expected_endpoints,
            "ca37 Top40 endpoint-class mismatch")
    base_tokens = base_paths["token_path_counts"]
    new_tokens = new_paths["token_path_counts"]
    require(base_tokens["pending_system_csr_commit"] == 40,
            "e34b pending CSR commit is not present in all Top40 paths")
    require(new_tokens["pending_system_csr_commit"] == 0,
            "ca37 still exposes exact pending CSR commit in Top40")
    for token in ("head0_csr_commit", "system_csr_dispatch_cancel",
                  "system_csr_dispatch_valid", "pending_system_inst"):
        require(base_tokens[token] == 40,
                f"e34b {token} is not present in all Top40 paths")
        require(new_tokens[token] == 40,
                f"ca37 {token} is not present in all Top40 paths")


def metric_view(summary: dict) -> dict:
    area = summary["synthesis"]["area"]
    return {
        "wns_ns": summary["timing"]["wns_ns"],
        "tns_ns": summary["timing"]["tns_ns"],
        "logic_area_proxy": area["logic_area_proxy_excluding_unknown_macros"],
        "sequential_area": area["sequential_area"],
        "total_cells": area["total_cells_including_unknown_macros"],
        "power_w": summary["power"]["total_vectorless_w"],
        "power_qualification": summary["power"]["qualification"],
        "combinational_loops": summary["timing"]["combinational_loops"],
        "target_200mhz_met": summary["timing"]["target_200mhz_met"],
    }


def evidence_file(path: Path) -> dict:
    return {
        "path": str(path.relative_to(REPO)),
        "sha256": sha256_file(path),
    }


def build_result() -> dict:
    base_summary_path = BASE_DIR / "summary.json"
    new_summary_path = NEW_DIR / "summary.json"
    base_top40_path = BASE_DIR / "opensta-top40.rpt"
    new_top40_path = NEW_DIR / "opensta-top40.rpt"
    base_manifest_before = BASE_DIR / "production-manifest-before.sha256"
    base_manifest_after = BASE_DIR / "production-manifest-after.sha256"
    new_manifest_before = NEW_DIR / "production-manifest-before.sha256"
    new_manifest_after = NEW_DIR / "production-manifest-after.sha256"
    required = (
        base_summary_path, new_summary_path, base_top40_path, new_top40_path,
        base_manifest_before, base_manifest_after,
        new_manifest_before, new_manifest_after,
    )
    for path in required:
        require(path.is_file() and not path.is_symlink() and path.stat().st_size,
                f"missing or unsafe evidence: {path}")
    require(base_manifest_before.read_bytes() == base_manifest_after.read_bytes(),
            "e34b production manifest drifted during PPA")
    require(new_manifest_before.read_bytes() == new_manifest_after.read_bytes(),
            "ca37 production manifest drifted during PPA")

    base_summary = load_summary(base_summary_path)
    new_summary = load_summary(new_summary_path)
    require(base_summary["period_ns"] == new_summary["period_ns"] == 5.0,
            "period mismatch")
    require(base_summary["mode"] == new_summary["mode"] == "candidate",
            "mode mismatch")
    require(normalized_parameters(BASE_DIR / "parameters.txt") ==
            normalized_parameters(NEW_DIR / "parameters.txt"),
            "normalized synthesis/STA parameters mismatch")

    base_metrics = metric_view(base_summary)
    new_metrics = metric_view(new_summary)
    require(base_metrics["combinational_loops"] == 0 and
            new_metrics["combinational_loops"] == 0,
            "combinational loop detected")
    require(base_metrics["power_qualification"] ==
            new_metrics["power_qualification"] ==
            "RELATIVE_ONLY_FIXED_TOGGLE_0P1", "power qualification mismatch")

    base_paths = path_profile(base_top40_path.read_text(encoding="utf-8"))
    new_paths = path_profile(new_top40_path.read_text(encoding="utf-8"))
    validate_path_transition(base_paths, new_paths)

    delta = {key: new_metrics[key] - base_metrics[key] for key in
             ("wns_ns", "tns_ns", "logic_area_proxy", "sequential_area",
              "total_cells", "power_w")}
    require(delta["wns_ns"] > 0.0, "WNS did not improve")
    require(delta["tns_ns"] > 0.0, "TNS did not improve")
    require(delta["logic_area_proxy"] <= 0.0, "logic area proxy regressed")
    require(delta["sequential_area"] == 0.0, "sequential area changed")
    require(delta["total_cells"] == 0, "cell count changed")
    require(delta["power_w"] == 0.0, "fixed-toggle relative power changed")
    require(not new_metrics["target_200mhz_met"],
            "comparison contract expected the 5 ns target to remain open")

    return {
        "schema": "npc-rv64-v15v-ppa-delta-path-cluster-v1",
        "status": "PASS",
        "baseline_design_id": BASE_DESIGN_ID,
        "candidate_design_id": NEW_DESIGN_ID,
        "configuration": {
            "period_ns": 5.0,
            "mode": "candidate",
            "normalized_parameters_equal": True,
            "production_manifests_stable": True,
            "power_qualification": new_metrics["power_qualification"],
        },
        "baseline": base_metrics,
        "candidate": new_metrics,
        "delta_candidate_minus_baseline": delta,
        "top40": {
            "baseline": base_paths,
            "candidate": new_paths,
            "conclusion": (
                "V15V removes exact pending_system_csr_commit from all mapped "
                "Top40 pre-ROB dispatch-cancel paths. The remaining 40/40 "
                "head0_csr_commit -> system_csr_dispatch_cancel segment is "
                "required to squash a younger lane1 pending SYSTEM owner."
            ),
        },
        "evidence": {
            "baseline_summary": evidence_file(base_summary_path),
            "candidate_summary": evidence_file(new_summary_path),
            "baseline_top40": evidence_file(base_top40_path),
            "candidate_top40": evidence_file(new_top40_path),
            "baseline_manifest_before": evidence_file(base_manifest_before),
            "baseline_manifest_after": evidence_file(base_manifest_after),
            "candidate_manifest_before": evidence_file(new_manifest_before),
            "candidate_manifest_after": evidence_file(new_manifest_after),
        },
        "decision": "ENGINEERING_CANDIDATE_RETAIN",
        "gap": "5NS_TARGET_NOT_MET",
    }


def synthetic_path(include_pending: bool = True,
                   include_head0: bool = True,
                   redirect: bool = False) -> str:
    endpoint = "redirect_valid" if redirect else "jalr_prefetch_hit_available"
    tokens = [
        "system_csr_dispatch_cancel",
        "system_csr_dispatch_valid",
        "pending_system_inst",
    ]
    if include_pending:
        tokens.append("pending_system_csr_commit")
    if include_head0:
        tokens.append("head0_csr_commit")
    return ("Startpoint: launch\nEndpoint: endpoint_" + endpoint + "\n" +
            "\n".join(tokens) + "\n")


def synthetic_report(include_pending: bool, include_head0: bool = True) -> str:
    return (synthetic_path(include_pending, include_head0) * 38 +
            synthetic_path(include_pending, include_head0, redirect=True) * 2)


def self_test() -> None:
    base = path_profile(synthetic_report(include_pending=True))
    candidate = path_profile(synthetic_report(include_pending=False))
    validate_path_transition(base, candidate)
    negative_count = 0
    bad_candidates = (
        synthetic_report(include_pending=True),
        synthetic_report(include_pending=False, include_head0=False),
        synthetic_report(include_pending=False).replace("Startpoint:",
                                                        "Broken:", 1),
    )
    for bad in bad_candidates:
        try:
            validate_path_transition(base, path_profile(bad))
        except (StopIteration, ValueError):
            negative_count += 1
    require(negative_count == 3, "negative self-test coverage failed")
    print("[V15V-PPA-COMPARE-SELF-TEST][PASS] positive=1 negative=3")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    require(args.output is not None, "--output is required")
    result = build_result()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8")
    delta = result["delta_candidate_minus_baseline"]
    print("[V15V-PPA-COMPARE][PASS] "
          f"wns_delta_ns={delta['wns_ns']:.9f} "
          f"tns_delta_ns={delta['tns_ns']:.5f} "
          f"area_delta={delta['logic_area_proxy']:.2f} "
          "pending_commit_top40=40->0 head0_commit_top40=40->40")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
