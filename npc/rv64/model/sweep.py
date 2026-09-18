#!/usr/bin/env python3
"""Replay one fixed functional trace over a Cartesian product of timing parameters."""
import argparse
import csv
import itertools
import json
from pathlib import Path
import subprocess
import time

MODEL = Path(__file__).resolve().parent


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("trace", type=Path)
    p.add_argument("--vary", action="append", required=True, help="e.g. iq=8,16,32 (repeat for another dimension)")
    p.add_argument("--set", action="append", default=[], help="fixed key=value override")
    p.add_argument("--config", type=Path, default=MODEL/"configs/chengyue64-v1.cfg")
    p.add_argument("--model", type=Path, default=MODEL.parent/"build/perf-model/r64-model")
    p.add_argument("--roi", help="zero-based START:COUNT; simulate the prefix for warmup")
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    dimensions = []
    for item in args.vary:
        key, sep, values = item.partition("=")
        choices = values.split(",")
        if not sep or not key or any(not v for v in choices):
            p.error("--vary requires key=value,value")
        if key in [k for k, _ in dimensions]:
            p.error("duplicate sweep dimension")
        dimensions.append((key, choices))
    args.out.mkdir(parents=True, exist_ok=True)
    rows = []
    for index, values in enumerate(itertools.product(*(v for _, v in dimensions))):
        params = dict(zip((k for k, _ in dimensions), values))
        report_path = args.out/f"run-{index:04d}.json"
        cmd = [str(args.model), str(args.trace), "--config", str(args.config), "--output", str(report_path)]
        for override in args.set+[f"{k}={v}" for k, v in params.items()]:
            cmd += ["--set", override]
        if args.roi:
            cmd += ["--roi", args.roi]
        start = time.perf_counter()
        subprocess.run(cmd, check=True)
        seconds = time.perf_counter()-start
        report = json.loads(report_path.read_text())
        roi = report.get("roi")
        row = {
            **params, "instructions": report["instructions"], "cycles": report["cycles"],
            "cpi": report["cpi"], "process_seconds": seconds,
            "roi_cycles": roi["inclusive_retirement_span"] if roi else "",
            "report": str(report_path),
        }
        rows.append(row)
        print(" ".join(f"{k}={v}" for k, v in params.items())+
              f" cycles={report['cycles']} CPI={report['cpi']:.6f} wall={seconds:.3f}s", flush=True)
    with (args.out/"summary.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
