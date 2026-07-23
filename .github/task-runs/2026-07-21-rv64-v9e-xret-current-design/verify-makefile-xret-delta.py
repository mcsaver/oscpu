#!/usr/bin/env python3
"""Prove the recorded Makefile hash delta is exactly the V9E XRET target."""

from __future__ import annotations

import datetime
import hashlib
import json
import os
from pathlib import Path


EXPECTED_BLOCK = b"""# V9E XRET-G1 local RV64 current-mode and precise-exception closure. The
# seven-case MRET/SRET matrix and four full-core program markers cover legal
# return controls, head0/lane1 illegal-instruction ownership, exact mepc/mtval,
# no illegal CsrFile request or commit, and older-lane retirement. Eight
# compile-success RTL verification variants and two observer probes must be
# dynamically rejected. PPA remains unqualified and unpromoted.
.PHONY: check-xret-current-mode
check-xret-current-mode:
\t@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9e-xret-current-design/run-focused.sh)

"""


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    root = Path(__file__).resolve().parents[3]
    makefile_rel = "npc/rv64/Makefile"
    first_audit_rel = (
        ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
        "evidence/architecture-provenance-rebind.json"
    )
    second_audit_rel = (
        ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
        "evidence/architecture-source-manifest-rebind.json"
    )
    output_rel = (
        ".github/task-runs/2026-07-21-rv64-v9e-xret-current-design/"
        "evidence/makefile-xret-delta-proof.json"
    )

    live = (root / makefile_rel).read_bytes()
    if live.count(EXPECTED_BLOCK) != 1:
        raise ValueError("the exact V9E XRET Makefile block must occur once")
    reconstructed = live.replace(EXPECTED_BLOCK, b"", 1)

    first = json.loads((root / first_audit_rel).read_text(encoding="utf-8"))
    second = json.loads((root / second_audit_rel).read_text(encoding="utf-8"))
    old_hashes = {
        section["old_file_sha256"]
        for record in first["records"].values()
        for section in (
            record.values()
            if "provenance" in record or "source_manifest" in record
            else (record,)
        )
    }
    old_hashes.update(
        section["old_file_sha256"]
        for record in second["records"].values()
        for section in record.values()
    )
    new_hashes = {
        section["new_file_sha256"]
        for record in first["records"].values()
        for section in (
            record.values()
            if "provenance" in record or "source_manifest" in record
            else (record,)
        )
    }
    new_hashes.update(
        section["new_file_sha256"]
        for record in second["records"].values()
        for section in record.values()
    )

    reconstructed_sha = sha256(reconstructed)
    live_sha = sha256(live)
    if old_hashes != {reconstructed_sha}:
        raise ValueError(f"recorded old hashes do not match reconstruction: {old_hashes}")
    if new_hashes != {live_sha}:
        raise ValueError(f"recorded new hashes do not match live Makefile: {new_hashes}")

    start_offset = live.index(EXPECTED_BLOCK)
    result = {
        "schema": "npc-rv64-v9e-makefile-xret-delta-proof-v1",
        "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "status": "PASS",
        "path": makefile_rel,
        "old_sha256": reconstructed_sha,
        "new_sha256": live_sha,
        "reconstructed_old_sha256": reconstructed_sha,
        "removed_block": {
            "sha256": sha256(EXPECTED_BLOCK),
            "byte_count": len(EXPECTED_BLOCK),
            "line_count": len(EXPECTED_BLOCK.splitlines()),
            "start_byte_offset": start_offset,
            "target": "check-xret-current-mode",
        },
        "source_audits": [first_audit_rel, second_audit_rel],
        "checks": {
            "exact_expected_block_occurs_once": True,
            "removing_only_expected_block_reconstructs_recorded_old_hash": True,
            "live_file_matches_all_recorded_new_hashes": True,
            "no_other_makefile_byte_change_between_recorded_hashes": True,
        },
        "claim": (
            "The Makefile provenance delta is exactly the independent local "
            "check-xret-current-mode target block; no other Makefile byte differs."
        ),
    }
    output = root / output_rel
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, output)
    print(
        "[MAKEFILE-XRET-DELTA] exact_block=1 old_hash_reconstructed=1 "
        "new_hash_bound=1 PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
