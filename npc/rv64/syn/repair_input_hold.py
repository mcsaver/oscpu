#!/usr/bin/env python3
"""Insert real positive buffers on reported direct input-to-D hold branches.

This transforms scalar, flattened Yosys/OpenROAD cell netlists, not RTL or constraints.
By default only negative direct paths are eligible; --through-logic also handles
input paths containing combinational cells. --source-branches instead shares
buffers at the first load of each reported input path, before unrelated data
cones merge. --output-branches additionally permits data output endpoints while
rejecting clock-network input roots. --clock-enable additionally permits
Liberty-identified integrated clock-gate enable pins, never clock pins. Other violations
remain for STA to reject. The caller must rerun full setup AND hold analysis on
the output with the original Liberty, SDC and loads.
"""
import argparse
import hashlib
import json
import math
import re
from collections import defaultdict
from pathlib import Path

CELL = re.compile(r"^[ \t]+(\S+)[ \t]+(\S+)[ \t]*\(\s*(.*?)\s*\);", re.M | re.S)
PIN = re.compile(r"\.(\w+)\(([^)]+)\)")


def require(value, message):
    if not value:
        raise ValueError(message)


def blocks(text, kind):
    for match in re.finditer(r"\b" + kind + r"\s*\(\s*([^)]*)\s*\)\s*\{", text):
        depth, end = 1, match.end()
        while depth and end < len(text):
            depth += (text[end] == "{") - (text[end] == "}")
            end += 1
        require(depth == 0, "Unclosed Liberty block")
        yield match[1].strip(), text[match.end():end - 1]


def parse_cells(text):
    result = {}
    for match in CELL.finditer(text):
        name = match[2].lstrip("\\")
        require(name not in result, "Duplicate cell instance " + name)
        pins = PIN.findall(match[3])
        require(len(dict(pins)) == len(pins), "Duplicate cell pin " + name)
        result[name] = (match, dict(pins))
    require(result, "No scalar mapped cells")
    return result


def repair(source, checks, libraries, buffer, stages, through_logic=False, clock_enable=False,
           source_branches=False, source_fanout=8, output_branches=False, output_stages=None):
    require(1 <= stages <= 8, "Buffer stages must be 1..8")
    require(1 <= source_fanout <= 64, "Source fanout must be 1..64")
    require(not output_branches or source_branches, "Output branches require source-branch buffering")
    if output_stages is not None:
        require(output_branches, "Output stages require output-branch buffering")
        require(1 <= output_stages <= 8, "Output buffer stages must be 1..8")
    through_logic = through_logic or source_branches
    require(len(re.findall(r"^module\s", source, re.M)) == 1 and
            len(re.findall(r"^endmodule\s*$", source, re.M)) == 1,
            "Expected one flattened module")
    cells = parse_cells(source)
    liberty = {}
    for text in libraries:
        for name, body in blocks(text, "cell"):
            require(name not in liberty, "Duplicate Liberty cell " + name)
            liberty[name] = body
    require(buffer in liberty, "Buffer absent from actual Liberty")
    buf = liberty[buffer]
    pins = dict(blocks(buf, "pin"))
    require(set(pins) == {"A", "Y"} and
            re.search(r'direction\s*:\s*input', pins["A"]) and
            re.search(r'direction\s*:\s*output', pins["Y"]) and
            re.search(r'function\s*:\s*"A"\s*;', pins["Y"]) and
            not list(blocks(buf, "ff")) and not list(blocks(buf, "latch")),
            "Buffer must be a two-pin, non-inverting combinational cell")
    area_re = r"\barea\s*:\s*([\d.eE+-]+)\s*;"
    area = float(re.search(area_re, buf)[1])
    require(math.isfinite(area) and area > 0, "Invalid buffer area")
    original_area = 0.0
    for match, _ in cells.values():
        require(match[1] in liberty, "Mapped cell absent from actual Liberty: " + match[1])
        original_area += float(re.search(area_re, liberty[match[1]])[1])
    used_types = {match[1] for match, _ in cells.values()}
    # Cell timing tables are large; parse each used Liberty type once.
    lib_pins = {name: dict(blocks(liberty[name], "pin")) for name in used_types}
    lib_ff = {name: list(blocks(liberty[name], "ff")) for name in used_types}
    lib_latch = {name: list(blocks(liberty[name], "latch")) for name in used_types}
    inputs = set(re.findall(r"^[ \t]+input\s+(\S+)\s*;", source, re.M))
    outputs = {n.lstrip(chr(92)) for n in re.findall(r"^[ \t]+output\s+(\S+)\s*;", source, re.M)}
    # Find clock-network input roots conservatively. Even an ordinary BUF
    # before a Liberty clock pin must never become an input hold target.
    drivers, clock_nets = {}, set()
    for match, cp in cells.values():
        body = liberty[match[1]]
        lp = lib_pins[match[1]]
        clock_names = set(re.findall(r'clocked_on\s*:\s*"([\w]+)"', body))
        clock_names.update(pin for pin, pb in lp.items()
                           if re.search(r"(clock_gate_clock_pin|clock)\s*:\s*true", pb))
        clock_nets.update(cp[pin].strip() for pin in clock_names if pin in cp)
        cin = [cp[pin].strip() for pin, pb in lp.items() if pin in cp and
               re.search(r"direction\s*:\s*input", pb)]
        for pin, pb in lp.items():
            if pin in cp and re.search(r"direction\s*:\s*output", pb):
                drivers[cp[pin].strip()] = (cin, bool(
                    lib_ff[match[1]] or lib_latch[match[1]] or
                    "clock_gating_integrated_cell" in body))
    pending = list(clock_nets)
    while pending:
        net = pending.pop()
        incoming, sequential = drivers.get(net, ([], True))
        if not sequential:
            for signal in incoming:
                if signal not in clock_nets:
                    clock_nets.add(signal)
                    pending.append(signal)
    clock_roots = {n.lstrip(chr(92)) for n in clock_nets if n in inputs}
    prefix = "r64_input_hold_"
    require(prefix not in source, "Output names already exist; start from the original mapping")
    targets, skipped, sinks = {}, [], defaultdict(set)
    for path in checks["checks"]:
        if path["path_type"] != "min" or path["slack"] >= 0:
            continue
        endpoint = path["endpoint"]
        parts = endpoint.rsplit("/", 1)
        reason = ""
        if output_branches and endpoint in outputs:
            if (path["startpoint"] not in {n.lstrip(chr(92)) for n in inputs} or
                    path["startpoint"] in clock_roots or
                    len(path["source_path"]) < 3 or
                    path["source_path"][-1].get("pin") != endpoint):
                reason = "not a reported non-clock input-to-output path"
        elif len(parts) != 2 or parts[0] not in cells or (parts[1] != "D" and not clock_enable):
            reason = "not a known register D endpoint"
        elif len(path["source_path"]) < 2 or (len(path["source_path"]) != 2 and not through_logic):
            reason = "not a direct input path"
        else:
            match, cp = cells[parts[0]]
            pin = parts[1]
            signal = cp.get(pin, "").strip()
            body = liberty[match[1]]
            ff = lib_ff[match[1]]
            lib_pin = lib_pins[match[1]].get(pin, "")
            data_pin = pin == "D" and len(ff) == 1 and bool(re.search(r'next_state\s*:\s*"D"\s*;', ff[0][1]))
            gate_enable = clock_enable and bool(
                re.search(r"clock_gating_integrated_cell\s*:", body) and
                re.search(r"direction\s*:\s*input", lib_pin) and
                re.search(r"clock_gate_enable_pin\s*:\s*true", lib_pin) and
                not re.search(r"clock_gate_clock_pin\s*:\s*true", lib_pin))
            if ((not through_logic and (signal not in inputs or signal.lstrip("\\") != path["startpoint"])) or
                    (through_logic and path["startpoint"] not in {n.lstrip("\\") for n in inputs})):
                reason = "Pin does not connect directly to the reported input"
            elif not (data_pin or gate_enable):
                reason = "not an ordinary D flip-flop or explicitly enabled Liberty clock-gate enable"
        target = endpoint
        if not reason and source_branches:
            # Endpoint eligibility above still excludes internal launches and
            # clock pins. Trace back only to the actual input's first load.
            target = path["source_path"][1].get("pin", "")
            branch = target.rsplit("/", 1)
            if len(branch) != 2 or branch[0] not in cells:
                reason = "Missing known first input-load pin"
            else:
                bm, bp = cells[branch[0]]
                body = liberty[bm[1]]
                pb = lib_pins[bm[1]].get(branch[1], "")
                branch_signal = bp.get(branch[1], "").strip()
                clock_names = re.findall(r'clocked_on\s*:\s*"([\w]+)"', body)
                if (path["startpoint"] in clock_roots or
                        branch_signal.lstrip(chr(92)) != path["startpoint"] or
                        branch_signal not in inputs or
                        not re.search(r"direction\s*:\s*input", pb) or
                        re.search(r"clock_gate_clock_pin\s*:\s*true", pb) or
                        re.search(r"clock\s*:\s*true", pb) or
                        (not clock_enable and
                         re.search(r"clock_gate_enable_pin\s*:\s*true", pb)) or
                        branch[1] in clock_names):
                    reason = "First path load is not a matching non-clock input pin"
                else:
                    parts, signal = branch, branch_signal
        if reason:
            skipped.append({"endpoint": endpoint, "reason": reason})
        else:
            targets[target] = (parts[0], parts[1], signal)
            sinks[target].add(endpoint)
    plans = []
    if source_branches:
        by_signal = defaultdict(list)
        for target, (name, pin, signal) in sorted(targets.items()):
            # Different endpoint classes can have different setup budgets.
            # A branch feeding both classes uses the larger chain; never split
            # a shared logic pin into inconsistent independently owned paths.
            counts = [output_stages if endpoint in outputs and output_stages is not None
                      else stages for endpoint in sinks[target]]
            by_signal[(signal, max(counts))].append((target, name, pin))
        for (signal, count), loads in sorted(by_signal.items()):
            for start in range(0, len(loads), source_fanout):
                plans.append((signal, loads[start:start + source_fanout], count))
    else:
        for target, (name, pin, signal) in sorted(targets.items()):
            plans.append((signal, [(target, name, pin)], stages))
    declarations, instances, edited_cells, manifest = [], [], {}, []
    for index, (original, loads, count) in enumerate(plans):
        signal = original
        chain = []
        for stage in range(count):
            net = f"{prefix}net_{index}_{stage}"
            instance = f"{prefix}buf_{index}_{stage}"
            declarations.append(f"  wire {net};")
            instances.append(f"  {buffer} {instance} (\n    .A({signal}),\n    .Y({net})\n  );")
            chain.append({"cell": instance, "a": signal, "y": net})
            signal = net
        endpoints = []
        for target, name, pin in loads:
            match, cp = cells[name]
            old = edited_cells.get(name, match[0])
            new = old.replace("." + pin + "(" + cp[pin] + ")", "." + pin + "(" + signal + ")")
            require(new != old, "Pin substitution failed")
            edited_cells[name] = new
            endpoints.extend(sorted(sinks[target]))
        manifest.append({"endpoint": endpoints[0], "endpoints": sorted(set(endpoints)),
                         "branches": [target for target, _, _ in loads],
                         "original": original, "chain": chain})
    edits = [(cells[name][0].start(), cells[name][0].end(), cells[name][0][0], new)
             for name, new in edited_cells.items()]
    output = source
    for start, end, old, new in sorted(edits, reverse=True):
        output = output[:start] + new + output[end:]
    added = "\n".join(declarations + instances) + ("\n" if instances else "")
    output = output.replace("endmodule", added + "endmodule")
    # Prove all unmodified text is identical; then separately parse and contract
    # ONLY the verified new positive buffers in every original cell/pin graph.
    recovered = output.replace(added, "", 1) if added else output
    for _, _, old, new in edits:
        recovered = recovered.replace(new, old, 1)
    require(recovered == source, "Non-target netlist text changed")
    after = parse_cells(output)
    inserted = {item["cell"]: item for entry in manifest for item in entry["chain"]}
    aliases = {item["y"]: item["a"] for item in inserted.values()}
    require(len(after) == len(cells) + len(inserted), "Unexpected cell additions")
    def resolve(net):
        seen = set()
        while net in aliases:
            require(net not in seen, "Inserted buffer cycle")
            seen.add(net)
            net = aliases[net]
        return net
    for name, (old, old_pins) in cells.items():
        new, new_pins = after[name]
        require(old[1] == new[1] and
                {p: v.strip() for p, v in old_pins.items()} ==
                {p: resolve(v.strip()) for p, v in new_pins.items()},
                "Original cell/pin connectivity changed at " + name)
    for name, expected in inserted.items():
        match, cp = after[name]
        require(match[1] == buffer and cp == {"A": expected["a"], "Y": expected["y"]},
                "Unverified added cell " + name)
    return output, {
        "equivalence": "Original cell types and contracted pin graph identical; all other source text identical",
        "scope": "Input branches to data registers/explicit outputs or gate enables; full post-repair setup and hold STA required",
        "clock_enable": clock_enable,
        "through_logic": through_logic,
        "source_branches": source_branches, "source_fanout": source_fanout,
        "output_branches": output_branches, "output_stages": output_stages,
        "buffer_cell": buffer, "buffer_count": len(inserted),
        "original_cell_area_um2": original_area,
        "extra_cell_area_um2": len(inserted) * area,
        "repaired_cell_area_um2": original_area + len(inserted) * area,
        "endpoints": manifest, "unhandled_negative_checks": skipped,
        "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
        "repaired_sha256": hashlib.sha256(output.encode()).hexdigest(),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--checks", type=Path, action="append", required=True,
                        help="One or more full STA min-path reports from the same original logical graph")
    parser.add_argument("--liberty", type=Path, action="append", required=True)
    parser.add_argument("--buffer", required=True)
    parser.add_argument("--stages", type=int, default=2)
    parser.add_argument("--through-logic", action="store_true",
                        help="Also buffer negative input-to-D paths through combinational cells; never register-to-register or clock pins")
    parser.add_argument("--clock-enable", action="store_true",
                        help="Also repair Liberty-identified integrated clock-gate enable pins, never clock pins")
    parser.add_argument("--source-branches", action="store_true",
                        help="Share buffers at each reported input's first load, before other data paths merge")
    parser.add_argument("--output-branches", action="store_true",
                        help="Also repair input-to-top-output hold via first-load branches; requires --source-branches")
    parser.add_argument("--output-stages", type=int,
                        help="Separate buffer count for output-only source branches (1..8); shared register branches use the larger count")
    parser.add_argument("--source-fanout", type=int, default=8,
                        help="Maximum first-load pins sharing a source buffer chain (1..64)")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    require(args.netlist.resolve() != args.output.resolve(), "Do not overwrite the baseline")
    checks = {"checks": [check for report in args.checks
                         for check in json.loads(report.read_text())["checks"]]}
    output, manifest = repair(args.netlist.read_text(), checks,
                              [p.read_text() for p in args.liberty], args.buffer, args.stages,
                              args.through_logic, args.clock_enable,
                              args.source_branches, args.source_fanout, args.output_branches, args.output_stages)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output)
    args.manifest.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Connectivity PASS: {manifest['buffer_count']} real buffers, "
          f"+{manifest['extra_cell_area_um2']:.2f} um^2; rerun full STA")


if __name__ == "__main__":
    main()
