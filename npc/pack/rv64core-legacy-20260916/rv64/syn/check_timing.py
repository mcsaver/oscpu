#!/usr/bin/env python3
"""Judge reported worst setup/hold paths, separately from iEDA execution success."""
import argparse
import json
import math
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--report", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--uncertainty", type=float, help="Require effective setup and hold uncertainty in path details (ns)")
args = parser.parse_args()
paths = []
uncertainties = []
for line in args.report.read_text().splitlines():
    fields = [f.strip() for f in line.split("|")[1:-1]]
    if fields and fields[0] == "clock uncertainty":
        try:
            uncertainties.append(float(fields[-2]))
        except (ValueError, IndexError):
            raise SystemExit("Invalid clock uncertainty in timing path")
    if len(fields) != 8 or fields[2] not in ("max", "min"):
        continue
    try:
        slack = float(fields[6])
    except ValueError:
        raise SystemExit("Non-numeric slack in timing summary: " + line)
    if not math.isfinite(slack):
        raise SystemExit("Non-finite slack in timing summary")
    paths.append(dict(endpoint=fields[0], group=fields[1],
                      delay_type=fields[2], slack_ns=slack))
setup = [p for p in paths if p["delay_type"] == "max"]
hold = [p for p in paths if p["delay_type"] == "min"]
if not setup or not hold:
    raise SystemExit("Missing setup or hold summary; timing is not qualified")
worst_setup = min(setup, key=lambda p: p["slack_ns"])
worst_hold = min(hold, key=lambda p: p["slack_ns"])
if args.uncertainty is not None:
    if any(p["group"] == "**clock_gating_default**" for p in paths):
        raise SystemExit("Bundled iEDA omits uncertainty on ICG checks; use sta-opensta for timing qualification")
    requested = args.uncertainty
    if not math.isfinite(requested) or requested <= 0:
        raise SystemExit("Required uncertainty must be finite and positive")
    for sign, kind in [(-1, "setup"), (1, "hold")]:
        if not any(math.isclose(v, sign * requested, abs_tol=0.0005)
                   for v in uncertainties):
            raise SystemExit(f"Missing effective {kind} uncertainty {requested} ns; timing is not qualified")
passed = worst_setup["slack_ns"] >= 0 and worst_hold["slack_ns"] >= 0
result = dict(report=str(args.report.resolve()), status="PASS" if passed else "FAIL",
              worst_setup=worst_setup, worst_hold=worst_hold,
              required_uncertainty_ns=args.uncertainty,
              scope="pre-layout mapped STA with the supplied clock and I/O constraints")
args.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"[{result['status']}] mapped timing: setup {worst_setup['slack_ns']:+.3f} ns, "
      f"hold {worst_hold['slack_ns']:+.3f} ns")
raise SystemExit(0 if passed else 1)
