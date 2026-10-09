#!/usr/bin/env python3
"""Recompute archived evidence; this does not simulate or benchmark RTL."""
import hashlib
import json
from pathlib import Path

RV64 = Path(__file__).resolve().parents[3]
ARCHIVE = RV64 / "results/rv64-cpi-timing-20260916/held-ready"
EXPECTED = {
    "coremark": (9241964, 3218524),
    "dhrystone": (14568135, 4260670),
}
FIELDS = (
    "retire_zero", "rob_nonempty_notdone", "decode_iq_block",
    "decode_rob_block", "wb_backpressure", "recover", "store_b_owner",
)
report = {"kind": "archived-evidence-recalculation", "new_rtl_measurement": False, "benchmarks": {}}
for name, expected in EXPECTED.items():
    path = ARCHIVE / (name + "-metrics.json")
    raw = path.read_bytes()
    data = json.loads(raw)
    counters, profile = data["counters"], data["profile"]
    cycles, commits = counters["cycles"], counters["commits"]
    assert data["returncode"] == 0
    assert (cycles, commits) == expected
    assert profile["cycles"] == cycles + 1
    assert profile["retire_zero"] + profile["retire_one"] + profile["retire_two"] == profile["cycles"]
    assert profile["retire_one"] + 2 * profile["retire_two"] == commits
    assert abs(cycles / commits - data["cpi"]) < 1e-12
    report["benchmarks"][name] = {
        "source": str(path.relative_to(RV64)),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "cycles": cycles,
        "commits": commits,
        "cpi_recomputed": cycles / commits,
        "ipc_recomputed": commits / cycles,
        "profile_cycles": profile["cycles"],
        "profile_pct": {k: 100 * profile[k] / profile["cycles"] for k in FIELDS},
        "load_bus_command": profile["load_bus_command"],
        "store_b_owner_cycles": profile["store_b_owner"],
        "note": "Overlapping event counts do not identify recoverable cycles or causal speedup.",
    }
report["status"] = "PASS"
print(json.dumps(report, ensure_ascii=False, indent=2))
