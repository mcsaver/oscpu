#!/usr/bin/env python3
"""Export a self-contained, local-only topology/measurement snapshot for web consultation."""
from pathlib import Path
import argparse
import json
import re
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[3]
RV = ROOT / "npc/rv64"
DEFAULT = RV / "build/ai-web-context"
MEASURED_SOURCE = RV / "build/ai-cq-timing-20261008/baseline-vsrc"
TOPOLOGIES = ["vsrc/TOPOLOGY.md"] + [f"vsrc/{d}/TOPOLOGY.md" for d in
    ["frontend", "backend", "fp", "control", "memory", "lsu", "bus"]]
EVIDENCE = [
    "ai/tests/2026-10-08-round3-cq-value/RESULT.md",
    "ai/tests/2026-10-08-round3-cq-value/MECHANISM.md",
    "ai/tests/2026-10-08-round3-cq-value/VALIDATION.md",
    "ai/tests/2026-10-08-round3-cq-value/PHYSICAL.md",
    "results/ai-r3-20261008/BENCHMARK-COMPARISON.json",
    "ai/tests/2026-10-08-round3-cq-value/candidate-vs-baseline.patch",
    "ai/tests/2026-10-08-round2-architecture/RESULT.md",
    "results/ai-cq-timing-20261008/PHYSICAL-COMPARISON.md",
    "results/ai-cq-timing-20261008/paired-path-diagnostic/RESULT.md",
    "results/ai-cq-timing-20261008/paired-path-diagnostic/baseline-global-top32.csv",
    "results/ai-architecture-20261008/sta-diagnostics/candidate-recovered/cq_payload-register-max.rpt",
    "results/ai-architecture-20261008/sta-diagnostics/candidate-recovered/raw_control-register-max.rpt",
    "results/ai-architecture-20261008/sta-diagnostics/candidate-recovered/raw_payload-register-max.rpt",
]
# Small source excerpts expose the precise reset/capture contracts behind the measured paths.
# They are evidence, not a pre-selected architecture change; full RTL is available on request.
EXCERPTS = [
    ("vsrc/control/R64Commit.v", 90, 105),
    ("vsrc/control/R64Commit.v", 130, 175),
    ("vsrc/lsu/R64LsuCompletion.v", 1, 116),
    ("vsrc/lsu/R64Lsu.v", 1617, 1685),
    ("syn/chengyue64.sdc", 1, 100),
]

def section(rel):
    content = (RV / rel).read_text(encoding="utf-8")
    if rel.endswith(".rpt"):
        second = content.find("Startpoint:", content.find("Startpoint:") + 1)
        if second >= 0:
            content = content[:second] + "\n[Only the first complete path is included; the full local report remains available.]\n"
    return f"\n\n===== SOURCE: npc/rv64/{rel} =====\n{content}\n===== END SOURCE =====\n"

def measurement_source_status():
    current = sorted(p for p in (RV / "vsrc").rglob("*")
                     if p.is_file() and (p.suffix in {".v", ".sv", ".vh", ".svh"}
                                         or p.name == "filelist.mk"))
    if not MEASURED_SOURCE.is_dir():
        return {"status": "UNKNOWN", "reason": "Measured source snapshot is unavailable."}
    different = [str(p.relative_to(RV)) for p in current
                 if not (MEASURED_SOURCE / p.relative_to(RV / "vsrc")).is_file()
                 or p.read_bytes() != (MEASURED_SOURCE / p.relative_to(RV / "vsrc")).read_bytes()]
    return {"status": "MATCH" if not different else "DIFFERENT",
            "scope": "Current vsrc Verilog/header/filelist bytes vs measured baseline snapshot only; workloads, tools and constraints remain the historical report identity.",
            "checked_files": len(current), "different_files": different}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    compatibility = measurement_source_status()
    snapshot_note = ("EXPORT TIME: " + datetime.now(timezone.utc).isoformat() + "\n"
                     + "MEASURED SOURCE APPLICABILITY: " + json.dumps(compatibility, ensure_ascii=False) + "\n"
                     + "Topology prose is dated; this exporter does not re-audit it. If code differs, historical measurements are not current measurements.\n\n")
    topo = """RV64 CURRENT TOPOLOGY — 2026-10-08 handoff
This is a source-derived snapshot, not a new PPA result. Chinese text and Mermaid source follow.
The current-design reference is B, the retained round1 load-response bypass implementation.
Round2 fixed-slot CQ and round3 CQ-value-bypass + local-cancel-publication are rejected experiments,
not current topology. R3 produced real execution gains but missed its combined timing/performance
retention target. Check the byte applicability above before treating B measurements as current.
Files below label historical September measurements separately. Current source wins over old history.
Local source links are references for Codex to retrieve; the web model cannot open the local workspace.
All eight topology documents are included in full; do not infer latency just from arrows or queue depth.
The design-unit IDs are coordinates for proposals, not fixed architectural restrictions.
"""
    topo += section("ARCHITECTURE.md") + section("ai/topology-contract.md")
    topo += "".join(section(n) for n in TOPOLOGIES)
    evidence = """RV64 MEASUREMENTS AND CONTRACT EXCERPTS — 2026-10-08 handoff
This file contains existing measured evidence; exporting it did not run a new benchmark or STA.
Baseline B is the retained round1 response-bypass implementation and remains the current measurement
reference. Round2 candidate C and round3 joint R3 were not retained. Consult source applicability
above: only MATCH binds current RTL to B. Neither C's fixed slots nor R3's early CQ-value path and
local-cancel-publication may be treated as active current architecture from historical reports.
Global target: improve useful whole-core execution and make progress toward 1ns timing without
weakening correctness. Codex is not preselecting an architecture or a critical-path interpretation.

MEASURED BASELINE B (source applicability above):
CoreMark10: 8,968,518 cycles, 3,218,537 retired, CPI 2.7865200866.
Dhrystone10000: 14,267,505 cycles, 4,260,670 retired, CPI 3.3486529114.
R64SystemTop prelayout, real standard-cell arrays, icsprout55 TT/1.2V/25C, 1ns,
0.05ns uncertainty, max input delay 0.4ns including rst_i. Setup WNS -2.119304419ns,
hold WNS -0.036660694ns. FAIL. Not post-route Fmax; do not infer runtime from 1ns-WNS.
Known previous successful round: CoreMark 9,241,964 -> 8,968,518 cycles;
Dhrystone 14,568,135 -> 14,267,505 cycles. Normal eligible load response -> CQ=0,
response -> WB accepted=2 cycles in load_chain; neither is full load-to-use latency.

COMPLETED R3 EXPERIMENT (HISTORICAL CANDIDATE, NOT CURRENT B):
Web Pro selected CQ_VALUE_BYPASS + LOCAL_CANCEL_PUBLISH. Both full fixed programs passed NEMU and
R64_ASSERT with unchanged retired counts: CoreMark10 8,968,518 -> 8,657,378 cycles (-3.46925%);
Dhrystone10000 14,267,505 -> 13,937,006 cycles (-2.31645%). These are real whole-program gains,
not predicted savings or just early-wakeup event counts. The same frozen joint R3's 1ns setup WNS
was -2.127002716ns versus B -2.119304419ns, 0.007698297ns worse; it missed the predefined >=0.10ns
improvement. R3 was rejected against the combined retention objective, not because its execution
improvement was illusory. See its RESULT/PHYSICAL for the complete area/setup/hold/path evidence.
No independently fully validated half-candidate is promoted by this export.

Four configurations each passed all 14 directed whole-core tests. Both-off matched the actual old B;
cancel-only matched both-off; value-only matched joint R3; instrumented joint R3 matched the main
candidate, including cycles, shared CPI and load profile counters. In the B-equivalent both-off
probe build, 8,193 load_chain dependencies measured first eligible CQ front -> issue/read = 2/3
edges; value-only/joint R3 measured 1/2. One additional dependence was 5/6 -> 4/5. The normal
load_chain cycles were 114,849 -> 106,656. These consumers actually read PRF because WB had already
arrived by their earlier read edge; earlier issue still follows the qualified CQ wake.
load_shift also exercised actual CQ data sourcing: 32 ordinary and 172 backpressured operand reads,
with 327/603 actual WB sources respectively. Full-tag/preg-lifetime association and real read-value
checks reported zero identity/value errors. These directed counts are overlapping observations,
not additive lost-cycle estimates and not substitutes for the separate full benchmark results.

IMPORTANT FACTS / UNKNOWN:
Reset is synchronous state clear plus combinational interface suppression. rst_i gates full_flush
with !rst_i; it is not ORed into a runtime reset/flush event. event_before_q has direct synchronous
reset. CQ payload is not cleared on reset, but its hold/write logic still depends on reset/cancel.
The Q-only worst CQ/raw-control launch maps to Commit event_trap_q, a runtime event register,
not a reset synchronizer. Static path reachability is not a proof of functional sensitization.
Targeted full-tag CQ-front -> early -> consumer issue -> actual RR read/source is now measured
as described above; do not label that segment wholly UNKNOWN. The whole allocation/request/cache/
translation/response-to-dependent-execution latency decomposition across arbitrary workloads,
exact ROB-head wait causes, and branch loss decomposition remain UNKNOWN. The diagnostic front
sample is the first pre-edge visible CQ front, not the response/CQ capture edge. Existing occupancy/
stall counters overlap and cannot be added into lost cycles. The R3 evidence does not identify all
remaining bottlenecks or preselect a follow-up architecture.
Stores use DCache -> LSU store_done -> ROB, not the load completion/WB 9-to-2 result path.
Already present: ALU early wake/bypass, non-head store preparation, head-authorized store query,
real B-error completion, retained load response bypass. Do not propose these as absent features.
No choice of next candidate is implied by the facts above. You may request narrowly missing source
or measurements; no need to demand a new full observability framework before a useful design.

EXPERIMENT COST CONTEXT:
R3's full CoreMark/Dhrystone pair took about 53.1min host time (CoreMark 2031s, Dhrystone 3186s).
Standard full synthesis+STA took about 51-52min: the wrapper recorded 3049s and /usr/bin/time
recorded 51:46; these are different timing scopes, not contradictory CPU-performance metrics.
Maximum recorded RSS was 9,268,600KiB (about 8.84GiB). Expanded path diagnosis on the mapped
netlist takes several additional minutes. The older ~33s/version figure applied only to a small
paired-query set, not to comprehensive path/endpoint diagnostics.
These are host costs, not CPU performance. A concrete next proposal should justify its smallest
complete experiment and distinguish predicted gains, mechanism evidence and measured gains.
"""
    evidence += "".join(section(n) for n in EVIDENCE)
    for rel, lo, hi in EXCERPTS:
        lines = (RV / rel).read_text().splitlines()
        hi = min(hi, len(lines))
        evidence += f"\n\n===== SOURCE EXCERPT: npc/rv64/{rel}:{lo}-{hi} =====\n"
        evidence += "\n".join(f"{i}: {lines[i-1]}" for i in range(lo, hi+1)) + "\n===== END EXCERPT =====\n"
    outputs = {"rv64-current-topology.txt": snapshot_note + topo, "rv64-measurements.txt": snapshot_note + evidence}
    for name, content in outputs.items():
        (args.output / name).write_text(content, encoding="utf-8")
    # A short inspectable inventory only; this does not claim elaboration or physical verification.
    inventory = {
        "kind": "local topology and existing-evidence export; no network submission",
        "measured_source_applicability": compatibility,
        "topologies": TOPOLOGIES,
        "evidence": EVIDENCE,
        "excerpts": EXCERPTS,
        "outputs": {n: {"bytes": len(s.encode()), "characters": len(s)} for n, s in outputs.items()},
        "design_unit_ids": sorted(set(re.findall(r"\b(?:FE|BE|FP|CTL|MEM|LSU|BUS)-[0-9]+\b", topo))),
    }
    (args.output / "inventory.json").write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(inventory["outputs"], ensure_ascii=False, indent=2))
    print(f"Design unit IDs: {len(inventory['design_unit_ids'])}")
    print(f"Output: {args.output}")

if __name__ == "__main__":
    main()
