#!/usr/bin/env python3
"""Print declared and current hashes for CLOSED architecture-debt evidence."""

from __future__ import annotations

import hashlib
import json
import pathlib


ROOT = pathlib.Path(__file__).resolve().parents[3]
LEDGER = ROOT / "npc/rv64/design/arch/architecture-debt-ledger.json"


def main() -> int:
    payload = json.loads(LEDGER.read_text(encoding="utf-8"))
    for entry in payload["entries"]:
        if entry.get("status") != "CLOSED":
            continue
        for item in entry.get("evidence", []):
            path = ROOT / item["path"]
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            state = "MATCH" if actual == item["sha256"] else "STALE"
            print(
                f"{state} {entry['id']} {item['kind']} "
                f"declared={item['sha256']} actual={actual} path={item['path']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

