#!/usr/bin/env python3
"""Compare model retirement cycles with an instruction-aligned imported RTL trace."""
import argparse
import csv
import json
from pathlib import Path
import struct


def timing_metrics(rtl, model):
    if not rtl or len(rtl) != len(model):
        raise ValueError("empty or unequal retirement streams")
    if any(b < a for a, b in zip(rtl, rtl[1:])) or any(b < a for a, b in zip(model, model[1:])):
        raise ValueError("retirement timestamps are not ordered")
    errors = sorted(abs((m-model[0])-(r-rtl[0])) for r, m in zip(rtl, model))
    matching = sum(rtl[i]-rtl[i-1] == model[i]-model[i-1] for i in range(1, len(rtl)))
    rspan, mspan = rtl[-1]-rtl[0]+1, model[-1]-model[0]+1
    mismatch = next((i for i, (r, m) in enumerate(zip(rtl, model)) if r != m), None)
    return {
        "cycle_exact": mismatch is None,
        "first_mismatch": None if mismatch is None else {
            "instruction": mismatch, "rtl_cycle": rtl[mismatch],
            "model_cycle": model[mismatch], "difference": model[mismatch]-rtl[mismatch]},
        "absolute_cycle_error_max": max(abs(m-r) for r, m in zip(rtl, model)),
        "instructions": len(rtl),
        "rtl_first_retire": rtl[0], "model_first_retire": model[0],
        "rtl_retirement_span": rspan, "model_retirement_span": mspan,
        "span_error_percent": 100*(mspan-rspan)/rspan,
        "interval_exact_percent": 100*matching/(len(rtl)-1) if len(rtl)>1 else None,
        "normalized_cycle_error_p50": errors[len(errors)//2],
        "normalized_cycle_error_p95": errors[min(len(errors)-1, int(len(errors)*.95))],
        "normalized_cycle_error_max": errors[-1],
    }


def compare(trace_path, cycles_path, stages_path):
    with trace_path.open("rb") as trace, cycles_path.open("rb") as cycles, stages_path.open() as stages:
        header = trace.read(24)
        if len(header) != 24:
            raise ValueError("truncated trace header")
        magic, count, flags = struct.unpack("<8sQQ", header)
        if magic != b"R64TRC1\0" or trace_path.stat().st_size != 24+count*48:
            raise ValueError("bad trace")
        if cycles_path.stat().st_size != count*8:
            raise ValueError("cycle sidecar does not match trace length")
        rtl_times, model_times = [], []
        reader = csv.DictReader(stages)
        for index in range(count):
            record = trace.read(48)
            row = next(reader, None)
            pc = struct.unpack_from("<Q", record)[0]
            if row is None or int(row["id"]) != index or int(row["pc"], 16) != pc:
                raise ValueError(f"architectural instruction mismatch at {index}")
            rtl_times.append(struct.unpack("<Q", cycles.read(8))[0])
            model_times.append(int(row["retire"]))
        if next(reader, None) is not None:
            raise ValueError("extra model instructions")
    result = timing_metrics(rtl_times, model_times)
    result["trace_natural_end"] = bool(flags & 1)
    result["trace_timing_inputs"] = bool(flags & 2)
    result["scope"] = "Same dynamic instruction stream; inclusive first-to-last retirement span."
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--trace", type=Path, required=True)
    p.add_argument("--rtl-cycles", type=Path, required=True)
    p.add_argument("--stages", type=Path, required=True)
    p.add_argument("--output", type=Path)
    p.add_argument("--require-exact", action="store_true",
                   help="fail unless every absolute retirement cycle matches and the program completed")
    p.add_argument("--allow-prefix", action="store_true",
                   help="permit a bounded prefix in strict comparison; never implies whole-program equality")
    args = p.parse_args()
    result = compare(args.trace, args.rtl_cycles, args.stages)
    result["acceptance"] = (
        "exact_complete_retirement_stream" if result["cycle_exact"] and result["trace_natural_end"]
        else "exact_bounded_prefix" if result["cycle_exact"]
        else "timing_mismatch")
    output = json.dumps(result, indent=2)+"\n"
    if args.output:
        args.output.write_text(output)
    print(output, end="")
    if args.require_exact and (not result["cycle_exact"] or
                               not (result["trace_natural_end"] or args.allow_prefix)):
        raise SystemExit(2)


if __name__ == "__main__":
    main()
