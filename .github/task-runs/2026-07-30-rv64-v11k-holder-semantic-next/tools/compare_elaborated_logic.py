#!/usr/bin/env python3
"""Compare V11J/V11K full Yosys JSON after removing source locations."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]
V11J = (
    ROOT
    / ".github/task-runs/2026-07-30-rv64-v11j-"
    "bridge-holder-semantic-coverage/evidence/current-instance-graph/"
    "yosys-instance-graph.full.json.gz"
)
V11K = (
    ROOT
    / ".github/task-runs/2026-07-30-rv64-v11k-"
    "holder-semantic-next/evidence/current-instance-graph/"
    "yosys-instance-graph.full.json.gz"
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def without_source_locations(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: without_source_locations(item)
            for key, item in value.items()
            if key != "src"
        }
    if isinstance(value, list):
        return [without_source_locations(item) for item in value]
    return value


def load(path: Path) -> tuple[bytes, dict[str, Any], bytes]:
    compressed = path.read_bytes()
    raw = gzip.decompress(compressed)
    payload = json.loads(raw)
    normalized = json.dumps(
        without_source_locations(payload),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return compressed, payload, normalized


def count_cells(payload: dict[str, Any]) -> int:
    return sum(
        len(module.get("cells", {}))
        for module in payload.get("modules", {}).values()
        if isinstance(module, dict)
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    output = args.output
    if not output.is_absolute():
        output = (ROOT / output).resolve()
    output.relative_to(ROOT)

    v11j_compressed, v11j_payload, v11j_logic = load(V11J)
    v11k_compressed, v11k_payload, v11k_logic = load(V11K)
    status = "PASS" if v11j_logic == v11k_logic else "FAIL"
    result = {
        "schema": "npc-rv64-v11k-elaborated-logic-identity-v1",
        "status": status,
        "comparison": (
            "Canonical full Yosys JSON with only `src` source-location "
            "attributes removed; module, cell, net, port, parameter, "
            "connection and non-src attribute content remains bound."
        ),
        "v11j": {
            "path": V11J.relative_to(ROOT).as_posix(),
            "compressed_sha256": sha256(v11j_compressed),
            "module_count": len(v11j_payload.get("modules", {})),
            "cell_count": count_cells(v11j_payload),
            "logic_sha256": sha256(v11j_logic),
            "logic_size_bytes": len(v11j_logic),
        },
        "v11k": {
            "path": V11K.relative_to(ROOT).as_posix(),
            "compressed_sha256": sha256(v11k_compressed),
            "module_count": len(v11k_payload.get("modules", {})),
            "cell_count": count_cells(v11k_payload),
            "logic_sha256": sha256(v11k_logic),
            "logic_size_bytes": len(v11k_logic),
        },
        "production_elaborated_logic_changed": v11j_logic != v11k_logic,
        "system_rerun_triggered_by_v11k": False,
        "claim_boundary": (
            "This proves two-state elaborated RTL identity for the frozen "
            "product configuration. It does not promote whole architecture, "
            "PPA or system certification."
        ),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True)
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V11K-ELABORATED-LOGIC-IDENTITY] "
        f"modules={result['v11k']['module_count']} "
        f"cells={result['v11k']['cell_count']} "
        f"logic_sha256={result['v11k']['logic_sha256']} {status}"
    )
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
