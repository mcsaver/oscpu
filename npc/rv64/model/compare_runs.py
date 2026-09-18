#!/usr/bin/env python3
"""Compare two independently executed, full-DiffTest RTL-derived runs exactly."""
import argparse
import json
from pathlib import Path
import re
import struct

HEADER = struct.Struct("<8sQQ")
RECORD = struct.Struct("<QQQQQII")


def metadata(directory):
    collection = json.loads((directory/"collection.json").read_text())
    with (directory/"functional.trace").open("rb") as stream:
        header = stream.read(HEADER.size)
    if len(header) != HEADER.size:
        raise ValueError(f"{directory}: incomplete trace header")
    magic, count, flags = HEADER.unpack(header)
    if magic != b"R64TRC1\0" or not count:
        raise ValueError(f"{directory}: invalid or empty trace")
    if (directory/"functional.trace").stat().st_size != HEADER.size+count*RECORD.size:
        raise ValueError(f"{directory}: trace length mismatch")
    if (directory/"rtl.cycles").stat().st_size != count*8:
        raise ValueError(f"{directory}: cycle length mismatch")
    if collection["collector_exit_code"] != 0:
        raise ValueError(f"{directory}: collector failed")
    terminal = None
    complete = bool(flags & 1)
    if complete:
        if collection["rtl_exit_code"] != 0:
            raise ValueError(f"{directory}: completed run has failed exit status")
        text = (directory/"rtl.log").read_text()
        lines = re.findall(r"\[PASS\] r64_core_program ([^\n]*)", text)
        if len(lines) != 1:
            raise ValueError(f"{directory}: missing or ambiguous successful terminal")
        values = dict(re.findall(r"(\w+)=(\d+)", lines[0]))
        if int(values["commits"]) != count:
            raise ValueError(f"{directory}: terminal retirement count mismatch")
        terminal = int(values["cycles"])
    elif collection["rtl_exit_code"] != 1:
        raise ValueError(f"{directory}: prefix lacks expected bounded-run status")
    return {"instructions": count, "natural_end": complete,
            "terminal_cycle_index": terminal, "host_seconds": collection["host_seconds"]}


def compare_runs(reference, candidate, allow_prefix=False):
    ref, model = metadata(reference), metadata(candidate)
    first_record = first_cycle = None
    cycle_mismatches = max_error = 0
    common = min(ref["instructions"], model["instructions"])
    previous = [-1, -1]
    with (reference/"functional.trace").open("rb") as a, \
         (candidate/"functional.trace").open("rb") as b, \
         (reference/"rtl.cycles").open("rb") as ac, \
         (candidate/"rtl.cycles").open("rb") as bc:
        a.seek(HEADER.size); b.seek(HEADER.size)
        for index in range(common):
            ra, rb = a.read(RECORD.size), b.read(RECORD.size)
            ca, cb = struct.unpack("<Q", ac.read(8))[0], struct.unpack("<Q", bc.read(8))[0]
            if ca < previous[0] or cb < previous[1]:
                raise ValueError("unordered retirement timestamps")
            previous = [ca, cb]
            if ra != rb and first_record is None:
                first_record = {"instruction": index,
                                "reference": list(RECORD.unpack(ra)),
                                "candidate": list(RECORD.unpack(rb))}
            if ca != cb:
                cycle_mismatches += 1
                max_error = max(max_error, abs(cb-ca))
                if first_cycle is None:
                    first_cycle = {"instruction": index, "pc": hex(RECORD.unpack(ra)[0]),
                                   "reference_cycle": ca, "candidate_cycle": cb,
                                   "difference": cb-ca}
    same_count = ref["instructions"] == model["instructions"]
    same_stream = same_count and first_record is None
    complete = ref["natural_end"] and model["natural_end"]
    same_end = ref["terminal_cycle_index"] == model["terminal_cycle_index"]
    accepted = (same_stream and not cycle_mismatches and same_end and
                (complete or (allow_prefix and not ref["natural_end"] and not model["natural_end"])))
    return {
        "accepted": accepted,
        "scope": "complete_program" if complete else "bounded_prefix",
        "reference": ref, "candidate": model,
        "same_instruction_stream": same_stream,
        "same_terminal_cycle": same_end,
        "retirement_cycle_mismatches": cycle_mismatches,
        "maximum_absolute_cycle_error": max_error,
        "first_instruction_mismatch": first_record,
        "first_cycle_mismatch": first_cycle,
        "execution_speedup": ref["host_seconds"]/model["host_seconds"]
                             if model["host_seconds"] else None,
        "cycle_convention": "Same harness: cycle 0 after reset; compare every absolute retirement timestamp and terminal cycle index.",
    }


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("reference", type=Path)
    p.add_argument("candidate", type=Path)
    p.add_argument("--allow-prefix", action="store_true")
    p.add_argument("--output", type=Path)
    args = p.parse_args()
    result = compare_runs(args.reference, args.candidate, args.allow_prefix)
    text = json.dumps(result, indent=2)+"\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")
    if not result["accepted"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
