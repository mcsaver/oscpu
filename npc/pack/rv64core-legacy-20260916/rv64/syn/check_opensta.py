#!/usr/bin/env python3
"""Judge real OpenSTA path JSON; both min/max and effective uncertainty required."""
import argparse
import json
import math
from pathlib import Path
import re

p = argparse.ArgumentParser()
p.add_argument("--paths", type=Path, required=True)
p.add_argument("--report", type=Path, required=True)
p.add_argument("--log", type=Path, required=True)
p.add_argument("--output", type=Path, required=True)
p.add_argument("--uncertainty", type=float, default=0.05)
a = p.parse_args()
log = a.log.read_text()
if re.search(r"(?m)^(Error|Warning) ", log):
    raise SystemExit("OpenSTA reports errors or incomplete timing setup; inspect its log")
raw = json.loads(a.paths.read_text())["checks"]
paths = []
for row in raw:
    if row.get("type") not in ("check", "output_delay", "latch_check", "gated_clk", "data_check", "path_delay") or row.get("path_type") not in ("min", "max"):
        raise SystemExit("Unexpected/unconstrained timing path")
    for key in ("slack", "data_arrival_time", "required_time"):
        if not math.isfinite(row[key]):
            raise SystemExit("Non-finite timing result")
    paths.append(dict(endpoint=row["endpoint"], startpoint=row["startpoint"],
                      group=row["path_group"], check_type=row["type"], delay_type=row["path_type"],
                      slack_ns=row["slack"] * 1e9))
setup = [x for x in paths if x["delay_type"] == "max"]
hold = [x for x in paths if x["delay_type"] == "min"]
if not setup or not hold:
    raise SystemExit("Missing setup or hold paths")
if not math.isfinite(a.uncertainty) or a.uncertainty <= 0:
    raise SystemExit("Required uncertainty must be finite and positive")
values = [float(x) for x in re.findall(
    r"(?m)^\s*([-+\d.]+)\s+[-+\d.]+\s+clock uncertainty\s*$",
    a.report.read_text())]
for sign, kind in [(-1, "setup"), (1, "hold")]:
    if not any(math.isclose(v, sign * a.uncertainty, abs_tol=0.00005) for v in values):
        raise SystemExit(f"Missing effective {kind} uncertainty")
worst_setup = min(setup, key=lambda x: x["slack_ns"])
worst_hold = min(hold, key=lambda x: x["slack_ns"])
# ReportPath.cc emits JSON timing values with {:.3e}, irrespective of
# report_checks -digits. Compare the two independently rounded values using
# their actual print quanta; a large missing path still fails closed.
global_slack = {}
for kind, worst in [("max", worst_setup), ("min", worst_hold)]:
    matches = re.findall(r"(?m)^worst slack " + kind + r" ([-+\d.]+)$", log)
    if len(matches) != 1:
        raise SystemExit("Missing unique global worst slack")
    value = float(matches[0])
    if not math.isfinite(value):
        raise SystemExit("Non-finite global timing result")
    magnitude = abs(worst["slack_ns"])
    json_quantum = 10 ** (math.floor(math.log10(magnitude)) - 3) if magnitude else 0
    decimals = len(matches[0].partition(".")[2])
    text_quantum = 10 ** -decimals
    tolerance = (json_quantum + text_quantum) / 2 + 1e-12
    if abs(value - worst["slack_ns"]) > tolerance:
        raise SystemExit("Global worst slack disagrees with path report")
    global_slack[kind] = value
# Rounding tolerance only checks inventory consistency. It never grants
# slack: both engine values and the JSON paths must themselves be nonnegative.
passed = (worst_setup["slack_ns"] >= 0 and worst_hold["slack_ns"] >= 0
          and global_slack["max"] >= 0 and global_slack["min"] >= 0)
result = dict(status="PASS" if passed else "FAIL", engine="OpenSTA",
              worst_setup=worst_setup, worst_hold=worst_hold,
              required_uncertainty_ns=a.uncertainty,
              global_setup_slack_ns=global_slack["max"], global_hold_slack_ns=global_slack["min"],
              report=str(a.report.resolve()),
              scope="pre-layout mapped STA; real Liberty ICG checks included; no extracted interconnect")
a.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"[{result['status']}] mapped timing: setup {worst_setup['slack_ns']:+.4f} ns, hold {worst_hold['slack_ns']:+.4f} ns")
raise SystemExit(0 if passed else 1)
