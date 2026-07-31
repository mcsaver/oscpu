#!/usr/bin/env python3
"""Build the bounded V11I layered RV64 regression receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


TESTS = (
    "tb_ooo_mem_owner_terminal_collector",
    "tb_ooo_mem_owner_tracker",
    "tb_ooo_load_queue",
    "tb_ooo_int_backend",
    "tb_ooo_mem_axi_bridge",
    "tb_ooo_dual_mem_bridge_wrapper",
    "tb_ooo_int_backend_v8x_backend_bridge_recovery",
)
FORBIDDEN = (
    "[RESULT] FAIL",
    "[V9Y-HOLDER-TERMINAL-NEXT]",
    "[V11H-LQ-DUP-TERMINAL]",
    "[V11H-LQ-PID-KNOWN]",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--design-id", required=True)
    args = parser.parse_args()

    root = args.repo_root.resolve()
    evidence_dir = args.evidence_dir.resolve()
    if not args.design_id.startswith("sha256:") or len(args.design_id) != 71:
        print("invalid design identity", file=sys.stderr)
        return 2

    results = []
    for test in TESTS:
        log = evidence_dir / "result" / "logs" / f"{test}.log"
        if not log.is_file() or log.is_symlink():
            print(f"missing regression log: {log}", file=sys.stderr)
            return 1
        text = log.read_text(encoding="utf-8")
        pass_line = f"[PASS] {test}"
        marker = f"[RTL-DESIGN-ID] {args.design_id}"
        passed = (
            text.count(pass_line) == 1
            and text.count("[RESULT] PASS") == 1
            and text.count(marker) == 1
            and "-DOOO_ASSERT" in text
            and all(item not in text for item in FORBIDDEN)
        )
        results.append(
            {
                "test": test,
                "status": "PASS" if passed else "FAIL",
                "log": log.relative_to(root).as_posix(),
                "log_sha256": sha256(log),
                "exact_pass_count": text.count(pass_line),
                "result_pass_count": text.count("[RESULT] PASS"),
                "design_id_marker_count": text.count(marker),
                "assertions_enabled": "-DOOO_ASSERT" in text,
                "forbidden_marker_counts": {
                    item: text.count(item) for item in FORBIDDEN
                },
            }
        )

    status = "PASS" if all(item["status"] == "PASS" for item in results) else "FAIL"
    receipt = {
        "schema": "npc-rv64-v11i-layered-regression-v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "design_id": args.design_id,
        "tests": results,
        "summary": {
            "total": len(results),
            "passed": sum(item["status"] == "PASS" for item in results),
            "failed": sum(item["status"] != "PASS" for item in results),
        },
        "scope": {
            "objects": (
                "terminal collector, tracker, LQ, ordinary IntBackend, "
                "memory bridge, dual bridge wrapper, bridge recovery parent"
            ),
            "full_system_run_launched": False,
            "architecture_or_ppa_promoted": False,
        },
    }
    output = evidence_dir / "summary.json"
    output.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (evidence_dir / "runner.status").write_text(status + "\n", encoding="utf-8")
    print(
        "[V11I-LAYERED-REGRESSION] "
        f"passed={receipt['summary']['passed']}/{len(results)} {status}"
    )
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
