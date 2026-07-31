#!/usr/bin/env python3
"""Rebuild the current census declaration from the versioned semantic base.

The V11K source census has the same 44 semantic units as the V11J audit.  Only
the live RTL design ID, product-config binding and frozen instance-graph
artifact records are advanced here.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[4]
MANIFEST_REL = "npc/rv64/design/arch/producer-holder-census.json"
V11J_AUDIT = (
    ROOT
    / ".github/task-runs/2026-07-30-rv64-v11j-"
    "bridge-holder-semantic-coverage/evidence/current-census/"
    "producer-holder-census.json"
)
GRAPH_DIR = (
    ROOT
    / ".github/task-runs/2026-07-30-rv64-v11k-"
    "holder-semantic-next/evidence/current-instance-graph"
)
GRAPH_ARTIFACTS = {
    "result": (
        "holder_instance_graph_result",
        "holder-instance-graph.json",
    ),
    "receipt": (
        "holder_instance_graph_receipt",
        "yosys-instance-graph-receipt.json",
    ),
    "full": (
        "holder_instance_graph_yosys_canonical_full_json_gzip",
        "yosys-instance-graph.full.json.gz",
    ),
    "script": (
        "holder_instance_graph_yosys_script",
        "yosys-instance-graph.ys",
    ),
    "log": (
        "holder_instance_graph_yosys_log",
        "yosys-instance-graph.log",
    ),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git_base_manifest() -> dict:
    completed = subprocess.run(
        ["git", "show", f"HEAD:{MANIFEST_REL}"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    value = json.loads(completed.stdout)
    if not isinstance(value, dict):
        raise ValueError("versioned census root is not an object")
    return value


def declared_triplets(manifest: dict, collection: str) -> set[tuple[str, str, str]]:
    third_key = "instance" if collection == "packed_full_p_stages" else "symbol"
    return {
        (item["path"], item["module"], item[third_key])
        for item in manifest[collection]
    }


def audited_triplets(audit: dict, collection: str) -> set[tuple[str, str, str]]:
    return {
        tuple(item)
        for item in audit["discovered"][collection]
    }


def main() -> None:
    manifest = git_base_manifest()
    audit = json.loads(V11J_AUDIT.read_text(encoding="utf-8"))
    collections = (
        "combinational_full_p_regs",
        "direct_full_p_fields",
        "packed_full_p_stages",
        "token_q_fields",
        "generation_authorities",
    )
    for collection in collections:
        if declared_triplets(manifest, collection) != audited_triplets(
            audit, collection
        ):
            raise ValueError(
                f"versioned semantic declaration differs from V11J "
                f"frozen discovery: {collection}"
            )

    graph_path = GRAPH_DIR / "holder-instance-graph.json"
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    if (
        graph.get("status") != "PASS"
        or graph.get("counts", {}).get("holder_instances") != 17
        or graph.get("counts", {}).get("reachable_module_instances") != 194
    ):
        raise ValueError("V11K current instance graph is not the expected PASS")
    graph_rows = {
        (item["module"], item["path"])
        for item in graph["graph"]["holder_instances"]
    }
    declared_rows = {
        (item["module"], item["path"])
        for item in manifest["elaborated_instance_graph"]["instances"]
    }
    if graph_rows != declared_rows:
        raise ValueError("V11K holder-instance set differs from declaration")

    manifest["design_id"] = graph["design_id"]
    manifest["elaborated_instance_graph"]["product_config"] = graph[
        "bindings"
    ]["product_config"]
    evidence: dict[str, dict[str, str]] = {}
    for role, (kind, filename) in GRAPH_ARTIFACTS.items():
        path = GRAPH_DIR / filename
        evidence[role] = {
            "kind": kind,
            "path": path.relative_to(ROOT).as_posix(),
            "sha256": sha256(path),
        }
    manifest["elaborated_instance_graph"]["evidence"] = evidence

    destination = ROOT / MANIFEST_REL
    destination.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "[V11K-CENSUS-MANIFEST-RECOVERY] "
        f"design_id={manifest['design_id']} units=44 instances=17 PASS"
    )


if __name__ == "__main__":
    main()
