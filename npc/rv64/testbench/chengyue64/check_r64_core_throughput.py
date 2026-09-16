#!/usr/bin/env python3
"""Check the real full-core retirement stream for sustained dual retirement."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def analyze(trace, symbols):
    addresses = {
        fields[-1]: int(fields[0], 16)
        for line in symbols.splitlines()
        if len(fields := line.split()) >= 3
    }
    begin, end = addresses["hot_body"], addresses["hot_end"]
    if end - begin != 4096:
        raise ValueError("throughput body must contain 1024 uncompressed instructions")
    if "[PASS] r64_core_program" not in trace:
        raise ValueError("full NEMU comparison did not reach a passing terminal")
    rounds, current = [], []
    for line in trace.splitlines():
        match = re.match(r"C (\d+) pc=([0-9a-f]+)", line)
        if not match:
            continue
        cycle, pc = int(match[1]), int(match[2], 16)
        if begin <= pc < end:
            if pc == begin and current:
                rounds.append(current)
                current = []
            current.append((pc, cycle))
    if current:
        rounds.append(current)
    if len(rounds) != 8:
        raise ValueError("missing or extra loop iteration")
    result = []
    for index, entries in enumerate(rounds):
        if [pc for pc, _ in entries] != list(range(begin, end, 4)):
            raise ValueError("missing, duplicate or out-of-order body instruction")
        # Exclude entry/exit overlap; every selected instruction still undergoes
        # the unchanged instruction and complete architectural-state DiffTest.
        cycles = [cycle for _, cycle in entries[128:896]]
        histogram = {}
        for cycle in cycles:
            histogram[cycle] = histogram.get(cycle, 0) + 1
        span = cycles[-1] - cycles[0] + 1
        sustained = span == 384 and len(histogram) == 384 and all(
            count == 2 for count in histogram.values()
        )
        if index and not sustained:
            raise ValueError(f"hot iteration {index} lost sustained dual retirement")
        result.append({
            "iteration": index,
            "body_instructions": 1024,
            "body_cycles": entries[-1][1] - entries[0][1] + 1,
            "steady_instructions": 768,
            "steady_cycles": span,
            "steady_cpi": span / 768,
            "sustained_dual_retirement": sustained,
        })
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sim", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--elf", required=True)
    parser.add_argument("--ref", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    output = Path(args.out)
    output.mkdir(parents=True, exist_ok=True)
    command = [
        str(Path(args.sim).resolve()), str(Path(args.image).resolve()),
        str(Path(args.ref).resolve()), "--verbose", "--maxcycles=20000",
    ]
    (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
    with (output / "trace.log").open("w") as log:
        run = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=180)
    if run.returncode:
        raise RuntimeError(f"full-core simulation failed: {output / 'trace.log'}")
    symbols = subprocess.check_output(
        ["riscv64-linux-gnu-nm", "-n", args.elf], text=True,
    )
    (output / "symbols.txt").write_text(symbols)
    rounds = analyze((output / "trace.log").read_text(), symbols)
    (output / "result.json").write_text(json.dumps({
        "scope": "Real full SystemTop, full NEMU comparison; hot independent ALU body.",
        "rounds": rounds,
    }, indent=2) + "\n")
    print("[PASS] full-core throughput: 7 hot windows, each 768 instructions / 384 cycles, CPI=0.5")


if __name__ == "__main__":
    main()
