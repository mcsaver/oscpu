#!/usr/bin/env python3

import hashlib
import json
from pathlib import Path


root = Path(__file__).resolve().parents[3]
source = root / "npc/rv64/syn/macro-lib/Sram4096x113.lib"
out_dir = root / ".github/task-runs/2026-07-15-rv64-t4s-pre-contract-netlist-compare/evidence/sensitivity-inputs"
output = out_dir / "Sram4096x113-tag-wmask-cap0-nonsignoff.lib"
metadata = out_dir / "metadata.json"
if output.exists() or metadata.exists():
    raise SystemExit("refusing stale sensitivity output")

text = source.read_text()
bus_marker = "    bus (wmask_i) {"
bus_start = text.index(bus_marker)
cap_marker = "      capacitance : 0.010;"
cap_start = text.index(cap_marker, bus_start)
modified = text[:cap_start] + "      capacitance : 0.000;" + text[cap_start + len(cap_marker):]
if modified.count("capacitance : 0.000;") != 1:
    raise SystemExit("sensitivity mutation cardinality mismatch")

out_dir.mkdir(parents=True, exist_ok=True)
output.write_text(modified)
record = {
    "schema": "t4s-tag-wmask-cap0-sensitivity-input-v1",
    "warning": "NON-SIGNOFF sensitivity model; only wmask_i bus pin capacitance changed 0.010pf -> 0",
    "source": str(source),
    "source_sha256": hashlib.sha256(text.encode()).hexdigest(),
    "output": str(output),
    "output_sha256": hashlib.sha256(modified.encode()).hexdigest(),
    "removed_capacitance_per_tag_pin_pf": 0.010,
    "tag_pin_count": 49,
    "removed_fill_we_capacitance_pf": 0.490,
}
metadata.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
print(json.dumps(record, sort_keys=True))
