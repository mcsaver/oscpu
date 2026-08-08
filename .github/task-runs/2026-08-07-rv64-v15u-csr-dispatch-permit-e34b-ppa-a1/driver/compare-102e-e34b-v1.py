#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


REPO = Path(__file__).resolve().parents[4]
BASE_DIR = REPO / ".github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1/evidence/traceable-102e-a1"
NEW_DIR = REPO / ".github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1/evidence/traceable-e34b-a1"
BASE_DESIGN_ID = "sha256:102e2f600d396b63f41172597c43011da1b3c8b28947f88e14f0cf4d8f37e90d"
NEW_DESIGN_ID = "sha256:e34bcf47cf2e69976190cff4a13cf21b4f8f3e18495858b3256e9d5205bec6ce"


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
    "mem_owner_terminalized",
    "mem_owner_terminal_collector",
    "mem_owner_tracker",
    "pending_system_csr_commit",
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


def build_result() -> dict:
    base_summary_path = BASE_DIR / "summary.json"
    new_summary_path = NEW_DIR / "summary.json"
    base_top40_path = BASE_DIR / "opensta-top40.rpt"
    new_top40_path = NEW_DIR / "opensta-top40.rpt"
    for path in (base_summary_path, new_summary_path,
                 base_top40_path, new_top40_path):
        require(path.is_file() and not path.is_symlink() and path.stat().st_size,
                f"missing or unsafe evidence: {path}")

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
    require(base_paths["endpoint_classes"] ==
            new_paths["endpoint_classes"] == {
                "jalr_prefetch_hit_available": 38,
                "redirect_valid": 2,
            }, "Top40 endpoint-class mismatch")
    require(base_paths["token_path_counts"]["mem_owner_terminalized"] == 40,
            "102e owner-terminalized token is not present in all Top40 paths")
    require(new_paths["token_path_counts"]["mem_owner_terminalized"] == 0,
            "e34b owner-terminalized token remains in Top40")
    require(new_paths["token_path_counts"]["mem_owner_terminal_collector"] == 0,
            "e34b collector token remains in Top40")
    require(new_paths["token_path_counts"]["mem_owner_tracker"] == 0,
            "e34b owner-tracker token remains in Top40")
    require(new_paths["token_path_counts"]["pending_system_csr_commit"] == 40,
            "e34b replacement commit/cancel cluster is not present in all paths")
    require(new_paths["token_path_counts"]["system_csr_dispatch_cancel"] == 40,
            "e34b dispatch-cancel token is not present in all paths")

    delta = {key: new_metrics[key] - base_metrics[key] for key in
             ("wns_ns", "tns_ns", "logic_area_proxy", "sequential_area",
              "total_cells", "power_w")}
    require(delta["wns_ns"] > 0.1, "WNS improvement is below 0.1 ns")
    require(delta["tns_ns"] > 0.0, "TNS did not improve")
    require(delta["logic_area_proxy"] <= 0.0, "logic area proxy regressed")
    require(delta["total_cells"] <= 0, "cell count regressed")

    return {
        "schema": "npc-rv64-v15u-ppa-delta-path-cluster-v1",
        "status": "PASS",
        "baseline_design_id": BASE_DESIGN_ID,
        "candidate_design_id": NEW_DESIGN_ID,
        "configuration": {
            "period_ns": 5.0,
            "mode": "candidate",
            "normalized_parameters_equal": True,
            "power_qualification": new_metrics["power_qualification"],
        },
        "baseline": base_metrics,
        "candidate": new_metrics,
        "delta_candidate_minus_baseline": delta,
        "top40": {
            "baseline": base_paths,
            "candidate": new_paths,
            "conclusion": (
                "V15U removes the memory-owner terminal/collector/tracker "
                "segment from all mapped Top40 paths. The replacement Top40 "
                "cluster is pending_system_csr_commit -> dispatch_cancel -> "
                "CSR injection mux -> backend ready -> frontend/fetch."
            ),
        },
        "evidence": {
            "baseline_summary": {
                "path": str(base_summary_path.relative_to(REPO)),
                "sha256": sha256_file(base_summary_path),
            },
            "candidate_summary": {
                "path": str(new_summary_path.relative_to(REPO)),
                "sha256": sha256_file(new_summary_path),
            },
            "baseline_top40": {
                "path": str(base_top40_path.relative_to(REPO)),
                "sha256": sha256_file(base_top40_path),
            },
            "candidate_top40": {
                "path": str(new_top40_path.relative_to(REPO)),
                "sha256": sha256_file(new_top40_path),
            },
        },
        "decision": "ENGINEERING_CANDIDATE_RETAIN",
        "gap": "5NS_TARGET_NOT_MET",
    }


def self_test() -> None:
    section = """Startpoint: launch\n (clocked)\nEndpoint: endpoint_jalr_prefetch_hit_available\n mem_owner_terminalized\n"""
    synthetic = section * 40
    profile = path_profile(synthetic)
    require(profile["path_count"] == 40, "positive path split failed")
    require(profile["token_path_counts"]["mem_owner_terminalized"] == 40,
            "positive token count failed")
    negative_count = 0
    for bad in (synthetic.replace("Startpoint:", "Broken:", 1),
                synthetic.replace("mem_owner_terminalized", "owner", 1)):
        try:
            profile = path_profile(bad)
            require(profile["token_path_counts"]["mem_owner_terminalized"] == 40,
                    "token mutation was not rejected")
        except ValueError:
            negative_count += 1
    require(negative_count == 2, "negative self-test coverage failed")
    print("[V15U-PPA-COMPARE-SELF-TEST][PASS] positive=1 negative=2")


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
    print("[V15U-PPA-COMPARE][PASS] "
          f"wns_delta_ns={delta['wns_ns']:.9f} "
          f"tns_delta_ns={delta['tns_ns']:.5f} "
          f"area_delta={delta['logic_area_proxy']:.2f} "
          f"cells_delta={delta['total_cells']} owner_top40=40->0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
