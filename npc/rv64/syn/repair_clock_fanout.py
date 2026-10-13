#!/usr/bin/env python3
"""Repair overloaded ICG clock outputs with actual Liberty positive buffer trees.

Only flattened mapped netlists are accepted. Original gates, controls, macros,
assignments and constraints are preserved. Loads are pin capacitances, without
wire parasitics; full setup/hold, pulse, slew and propagated-clock STA is still
required. This is a bounded pre-layout load experiment, not physical CTS.
"""
import argparse
import hashlib
import json
import math
import re
from collections import defaultdict
from pathlib import Path

from repair_input_hold import blocks, parse_cells, require

NUMBER = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"
NET = re.compile(r"(?:\\\S+|[A-Za-z_$][\w$]*(?:\[\d+\])?)\Z")
TOKEN = re.compile(r"\\\S+|[A-Za-z_$][\w$]*(?:\[\d+\])?")
PREFIX = "r64_clock_load_"


def scalar(value):
    value = value.strip()
    return value.lstrip("\\") if NET.fullmatch(value) else None


def attr(body, name):
    match = re.search(r"\b" + name + r"\s*:\s*(" + NUMBER + r")\s*;", body)
    if not match:
        return None
    value = float(match[1])
    require(math.isfinite(value) and value >= 0, "Invalid Liberty " + name)
    return value


def flagged(body, name):
    return bool(re.search(r"\b" + name + r"\s*:\s*true\s*;", body))


def direction(body):
    match = re.search(r"\bdirection\s*:\s*(\w+)\s*;", body)
    return match[1] if match else None


def pin_cap(body, scale):
    common = attr(body, "capacitance")
    rise, fall = attr(body, "rise_capacitance"), attr(body, "fall_capacitance")
    rise = common if rise is None else rise
    fall = common if fall is None else fall
    require(rise is not None and fall is not None and min(rise, fall) > 0,
            "Missing/zero actual rise or fall input capacitance")
    values = [rise, fall]
    for i, edge in enumerate(("rise", "fall")):
        match = re.search(r"\b" + edge + r"_capacitance_range\s*\(\s*([^)]*)\)", body)
        if match:
            bounds = [float(v.strip()) for v in match[1].split(",")]
            require(len(bounds) == 2 and all(math.isfinite(v) and v > 0 for v in bounds),
                    "Invalid pin capacitance range")
            values[i] = max(values[i], *bounds)
    return tuple(v * scale for v in values)


def read_libraries(texts):
    cells = {}
    for text in texts:
        cap = re.search(r'capacitive_load_unit\s*\(\s*(' + NUMBER + r')\s*,\s*(\w+)\s*\)', text)
        time = re.search(r'time_unit\s*:\s*"(' + NUMBER + r')(\w+)"', text)
        require(cap and cap[2] in {"pf", "ff"} and time and time[2] in {"ns", "ps"},
                "Expected explicit supported Liberty capacitance/time units")
        cs = float(cap[1]) * {"pf": 1.0, "ff": 0.001}[cap[2]]
        ts = float(time[1]) * {"ns": 1.0, "ps": 0.001}[time[2]]
        require(cs > 0 and ts > 0, "Invalid Liberty unit scale")
        templates = dict(blocks(text, "lu_table_template"))
        for name, body in blocks(text, "cell"):
            name = name.strip('"')
            require(name not in cells, "Duplicate Liberty cell " + name)
            cells[name] = {"body": body, "cap_scale": cs, "time_scale": ts,
                           "templates": templates}
    return cells


def output_limit(cell, pin):
    cached = cell.setdefault("output_limits", {})
    if pin in cached:
        return cached[pin]
    body = cell["pins"][pin]
    maximum = attr(body, "max_capacitance")
    require(maximum is not None and maximum > 0, "Missing output max_capacitance")
    limits, slews = [], []
    for kind in ("cell_rise", "cell_fall", "rise_transition", "fall_transition"):
        tables = list(blocks(body, kind))
        require(tables, "Missing output timing table " + kind)
        for template, table in tables:
            definition = cell["templates"].get(template, "")
            dims = dict(re.findall(r"variable_(\d+)\s*:\s*(\w+)\s*;", definition))
            require(set(dims.values()) == {"input_net_transition", "total_output_net_capacitance"},
                    "Unrecognized output timing table axes")
            for axis, variable in dims.items():
                match = re.search(r'index_' + axis + r'\s*\(\s*"([^"]+)"\s*\)', table)
                if not match:
                    match = re.search(r'index_' + axis + r'\s*\(\s*"([^"]+)"\s*\)', definition)
                require(match, "Missing output timing table index")
                vals = [float(v.strip()) for v in match[1].split(",")]
                require(vals and all(math.isfinite(v) and v >= 0 for v in vals) and
                        vals == sorted(set(vals)), "Invalid output timing table index")
                if variable == "total_output_net_capacitance":
                    limits.append(max(vals) * cell["cap_scale"])
                else:
                    slews.append(max(vals) * cell["time_scale"])
    result = {"max_capacitance_pf": maximum * cell["cap_scale"],
            "table_max_capacitance_pf": min(limits),
            "table_max_input_slew_ns": min(slews),
            "limit_pf": min(maximum * cell["cap_scale"], min(limits))}
    cached[pin] = result
    return result


def splice_spans(source, replacements):
    """Apply ordered non-overlapping replacements in one traversal.

    Return exact reverse spans in the resulting text, avoiding one full-string
    scan/copy per changed FF when repairing large flattened cores.
    """
    pieces, reverse, previous, length = [], [], 0, 0
    for start, end, replacement in replacements:
        require(previous <= start <= end <= len(source), "Overlapping/out-of-order edit spans")
        unchanged = source[previous:start]
        pieces.append(unchanged)
        pieces.append(replacement)
        length += len(unchanged)
        reverse.append((length, length + len(replacement), source[start:end]))
        length += len(replacement)
        previous = end
    pieces.append(source[previous:])
    return "".join(pieces), reverse


def repair(source, libraries, buffer="BUFX4H7L", load_fraction=0.25,
           max_load_pf=0.02, max_fanout=32, max_depth=8, max_buffers=100000):
    require(0 < load_fraction <= 1 and 0 < max_load_pf and math.isfinite(max_load_pf),
            "Invalid load budget")
    require(2 <= max_fanout <= 256 and 1 <= max_depth <= 8 and 1 <= max_buffers <= 1000000,
            "Invalid tree bound")
    require(len(re.findall(r"^module\s", source, re.M)) == 1 and
            len(re.findall(r"^endmodule\s*$", source, re.M)) == 1,
            "Expected one flattened mapped module")
    header = source[source.find("module"):source.find(";")]
    require(not re.search(r"\b(input|output|inout)\b", header),
            "Expected split scalar non-ANSI top port declarations")
    require(not re.search(r"^\s*(always|initial|generate|tran|tranif0|tranif1)\b", source, re.M),
            "Expected mapped cells without behavioral logic or switches")
    require(PREFIX not in source, "Names already present; start from original mapping")
    cells = parse_cells(source)
    remainder, end = [], 0
    for match, _ in cells.values():
        remainder.append(source[end:match.start()])
        end = match.end()
    remainder.append(source[end:])
    residue = "".join(remainder)
    residue = re.sub(r"/\*.*?\*/|//[^\n]*|\(\*.*?\*\)", "", residue, flags=re.S)
    residue = re.sub(r"\bmodule\b[^;]*;|\bendmodule\b", "", residue, flags=re.S)
    residue = re.sub(r"\b(?:input|output|inout|wire|assign)\b[^;]*;", "", residue, flags=re.S)
    require(not residue.strip(), "Unparsed mapped source statement: " + residue.strip()[:120])
    lib = read_libraries(libraries)
    used = {match[1] for match, _ in cells.values()} | {buffer}
    for name in used:
        require(name in lib, "Mapped cell absent from actual Liberty: " + name)
        lib[name]["pins"] = {p.strip('"'): b for p, b in blocks(lib[name]["body"], "pin")}
        area = attr(lib[name]["body"], "area")
        require(area is not None and area > 0, "Missing actual area for " + name)
        lib[name]["area"] = area
    buf = lib[buffer]
    bp = buf["pins"]
    require(set(bp) == {"A", "Y"} and direction(bp["A"]) == "input" and
            direction(bp["Y"]) == "output" and
            re.search(r'function\s*:\s*"A"\s*;', bp["Y"]) and
            not re.search(r"\bthree_state\s*:", bp["Y"]) and
            not list(blocks(buf["body"], "ff")) and not list(blocks(buf["body"], "latch")),
            "Buffer must be actual two-pin positive combinational A/Y cell")
    buffer_cap = pin_cap(bp["A"], buf["cap_scale"])
    buffer_limit = output_limit(buf, "Y")
    buffer_budget = min(max_load_pf, load_fraction * buffer_limit["limit_pf"])
    require(max(buffer_cap) * 2 <= buffer_budget, "Buffer budget cannot support a branching tree")

    # Collapse only explicit scalar wire aliases. Complex data expressions are
    # retained verbatim, but any contact with a target clock fails closed.
    parent = {}
    def canonical(net):
        if net not in parent:
            parent[net] = net
        root = net
        while parent[root] != root:
            root = parent[root]
        while parent[net] != net:
            old = parent[net]
            parent[net] = root
            net = old
        return root
    complex_connections = []
    for match in re.finditer(r"\bassign\s+([^;]+);", source):
        sides = match[1].split("=")
        require(len(sides) == 2, "Unsupported assignment syntax")
        a, b = map(scalar, sides)
        if a is not None and b is not None:
            parent[canonical(a)] = canonical(b)
        else:
            complex_connections.append(match[1])
    loads, drivers = defaultdict(list), defaultdict(list)
    for name, (match, cp) in cells.items():
        model = lib[match[1]]
        for pin, expression in cp.items():
            net = scalar(expression)
            if net is None:
                complex_connections.append(expression)
                continue
            pin_body = model["pins"].get(pin)
            # SRAM buses are left untouched; scalar clock pins are explicit.
            kind = direction(pin_body) if pin_body is not None else None
            if kind == "output":
                drivers[canonical(net)].append((name, pin))
            elif kind == "input":
                loads[canonical(net)].append((name, pin))
            else:
                complex_connections.append(expression)
    inputs, outputs = set(), set()
    for kind, expression in re.findall(r"^\s*(input|output|inout)\s+([^;]+);", source, re.M):
        net = scalar(expression)
        require(net is not None, "Expected scalar top port declaration")
        if kind == "input":
            inputs.add(canonical(net))
        else:
            outputs.add(canonical(net))
    opaque_nets = {canonical(tok.lstrip("\\")) for expression in complex_connections
                   for tok in TOKEN.findall(expression)}

    edits, inserted, manifests = {}, [], []
    census = {"icg_count": 0, "clock_sink_count": 0, "repaired_icg_count": 0,
              "original_max_load_pf": 0.0, "after_max_root_load_pf": 0.0}
    def is_clock(model, pin):
        body = model["pins"][pin]
        return flagged(body, "clock") or flagged(body, "clock_gate_clock_pin") or bool(
            re.search(r'clocked_on\s*:\s*"\!?' + re.escape(pin) + r'"', model["body"]))
    def total(items):
        return (sum(item["cap"][0] for item in items), sum(item["cap"][1] for item in items))
    def pack(items, budget):
        groups, current, cap = [], [], [0.0, 0.0]
        for item in items:
            require(max(item["cap"]) <= budget, "Single clock sink exceeds selected buffer budget")
            if current and (len(current) >= max_fanout or
                            max(cap[i] + item["cap"][i] for i in (0, 1)) > budget):
                groups.append(current)
                current, cap = [], [0.0, 0.0]
            current.append(item)
            cap = [cap[i] + item["cap"][i] for i in (0, 1)]
        if current:
            groups.append(current)
        return groups
    for name, (match, cp) in cells.items():
        model = lib[match[1]]
        if "clock_gating_integrated_cell" not in model["body"]:
            continue
        census["icg_count"] += 1
        outpins = [p for p, b in model["pins"].items() if flagged(b, "clock_gate_out_pin")]
        require(len(outpins) == 1 and outpins[0] in cp, "Ambiguous ICG clock output " + name)
        pin = outpins[0]
        root = scalar(cp[pin])
        require(root is not None, "Non-scalar ICG output " + name)
        root = canonical(root)
        require(drivers[root] == [(name, pin)] and root not in inputs and root not in outputs and
                root not in opaque_nets, "Unknown, exported or multiply driven ICG network " + name)
        leaves = []
        for sink, sp in loads[root]:
            sm, _ = cells[sink]
            sl = lib[sm[1]]
            require(is_clock(sl, sp), "Mixed/non-clock ICG load " + sink + "/" + sp)
            leaves.append({"sink": (sink, sp), "cap": pin_cap(sl["pins"][sp], sl["cap_scale"])})
        load = total(leaves)
        census["clock_sink_count"] += len(leaves)
        census["original_max_load_pf"] = max(census["original_max_load_pf"], max(load))
        limit = output_limit(model, pin)
        budget = min(max_load_pf, load_fraction * limit["limit_pf"])
        if max(load) <= budget and len(leaves) <= max_fanout:
            census["after_max_root_load_pf"] = max(census["after_max_root_load_pf"], max(load))
            continue
        require(max(buffer_cap) <= budget, "ICG cannot drive selected buffer within budget")
        level, pending, nodes = 0, leaves, []
        # Buffer all leaves at each stage, retaining equal stage count per gate.
        while max(total(pending)) > budget or len(pending) > max_fanout:
            level += 1
            require(level <= max_depth, "Maximum clock tree depth exceeded")
            next_level = []
            for group in pack(pending, buffer_budget):
                require(len(inserted) < max_buffers, "Maximum inserted buffer count exceeded")
                index = len(inserted)
                node = {"cell": PREFIX + "buf_" + str(index),
                        "net": PREFIX + "net_" + str(index), "children": group,
                        "cap": buffer_cap, "level": level, "a": None}
                for child in group:
                    if "sink" in child:
                        sink, sp = child["sink"]
                        old, oldpins = cells[sink]
                        current = edits.get(sink, old[0])
                        needle = "." + sp + "(" + oldpins[sp] + ")"
                        require(needle in current, "Clock pin substitution failed")
                        edits[sink] = current.replace(needle, "." + sp + "(" + node["net"] + ")", 1)
                    else:
                        child["a"] = node["net"]
                inserted.append(node)
                nodes.append(node)
                next_level.append(node)
            require(len(next_level) < len(pending) or level == 1,
                    "Clock tree does not reduce upstream load")
            pending = next_level
        for node in pending:
            require("cell" in node, "Internal incomplete clock tree")
            node["a"] = cp[pin].strip()
        after_load = total(pending)
        census["repaired_icg_count"] += 1
        census["after_max_root_load_pf"] = max(census["after_max_root_load_pf"], max(after_load))
        manifests.append({"icg": name, "cell_type": match[1], "pins": cp,
                          "clock_sinks": len(leaves), "original_load_pf": load,
                          "root_load_pf": after_load, "root_budget_pf": budget,
                          "root_liberty_limit": limit, "buffer_count": len(nodes),
                          "depth": level, "max_buffer_load_pf": max(max(total(n["children"])) for n in nodes),
                          "sample_sink": "/".join(leaves[0]["sink"]),
                          "sample_leaf_buffer": nodes[0]["cell"],
                          "root_buffers": [n["cell"] for n in pending]})

    declarations = ["  wire " + n["net"] + ";" for n in inserted]
    instances = ["  (* keep = 1 *)\n  " + buffer + " " + n["cell"] +
                 " (\n    .A(" + n["a"] + " ),\n    .Y(" + n["net"] + ")\n  );" for n in inserted]
    added = "\n".join(declarations + instances) + ("\n" if inserted else "")
    replacements = [(match.start(), match.end(), edits[name])
                    for name, (match, _) in cells.items() if name in edits]
    if added:
        module_end = re.search(r"^endmodule\s*$", source, re.M).start()
        replacements.append((module_end, module_end, added))
    output, reverse = splice_spans(source, replacements)

    # Exact unaffected-text recovery is also linear; never search/replace the
    # full netlist once per FF. Independently reparse and contract below.
    recovered, _ = splice_spans(output, reverse)
    require(recovered == source, "Non-target source text changed")
    del recovered, reverse, replacements
    after = parse_cells(output)
    require(set(after) == set(cells) | {n["cell"] for n in inserted}, "Unexpected cell additions/removals")
    aliases = {n["net"]: scalar(n["a"]) for n in inserted}
    require(len(aliases) == len(inserted), "Multiple new net drivers")
    def contract(expression):
        net = scalar(expression)
        if net is None:
            return expression.strip()
        seen = set()
        while net in aliases:
            require(net not in seen, "Clock buffer cycle")
            seen.add(net)
            net = aliases[net]
        return canonical(net)
    for name, (old, oldpins) in cells.items():
        new, newpins = after[name]
        require(old[1] == new[1] and {p: contract(v) for p, v in oldpins.items()} ==
                {p: contract(v) for p, v in newpins.items()}, "Contracted pin graph changed at " + name)
    for node in inserted:
        match, cp = after[node["cell"]]
        require(match[1] == buffer and set(cp) == {"A", "Y"} and
                scalar(cp["Y"]) == node["net"] and scalar(cp["A"]) == scalar(node["a"]),
                "Unexpected new buffer implementation")
        contract(cp["Y"])
        require(max(total(node["children"])) <= buffer_budget + 1e-12, "New driver over budget")
    original_area = sum(lib[match[1]]["area"] for match, _ in cells.values())
    extra_area = len(inserted) * buf["area"]
    return output, {
        "scope": "Real positive buffers on ICG clock output loads only; pre-layout pin-capacitance model",
        "equivalence": "PASS: unchanged source text, original cell types and all contracted pin connections",
        "post_sta_required": "Original constraints; setup/hold, ICG enable, min period/pulse, all clock slew/load; propagated clocks and physical parasitics are separate signoff",
        "buffer_cell": buffer, "buffer_count": len(inserted), "buffer_pin_cap_pf": buffer_cap,
        "buffer_liberty_limit": buffer_limit, "buffer_budget_pf": buffer_budget,
        "load_fraction": load_fraction, "max_load_pf": max_load_pf, "max_fanout": max_fanout,
        "original_cell_area_um2": original_area, "extra_cell_area_um2": extra_area,
        "repaired_cell_area_um2": original_area + extra_area,
        "census": census, "trees": manifests,
        "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
        "repaired_sha256": hashlib.sha256(output.encode()).hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--liberty", type=Path, action="append", required=True)
    parser.add_argument("--buffer", default="BUFX4H7L")
    parser.add_argument("--load-fraction", type=float, default=0.25)
    parser.add_argument("--max-load-pf", type=float, default=0.02)
    parser.add_argument("--max-fanout", type=int, default=32)
    parser.add_argument("--max-depth", type=int, default=8)
    parser.add_argument("--max-buffers", type=int, default=100000)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    require(args.netlist.resolve() != args.output.resolve(), "Do not overwrite original mapping")
    output, info = repair(args.netlist.read_text(), [p.read_text() for p in args.liberty],
                          args.buffer, args.load_fraction, args.max_load_pf,
                          args.max_fanout, args.max_depth, args.max_buffers)
    info["input_netlist"] = str(args.netlist)
    info["liberty_files"] = [str(p) for p in args.liberty]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output)
    args.manifest.write_text(json.dumps(info, indent=2) + "\n")
    print(f"Connectivity PASS: {info['buffer_count']} real clock buffers, "
          f"+{info['extra_cell_area_um2']:.2f} um^2; full STA required")


if __name__ == "__main__":
    main()
