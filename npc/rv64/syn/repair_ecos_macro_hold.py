#!/usr/bin/env python3
"""Delay reported negative hold branches at explicitly selected ECOS SRAM input pins.

This is a mapped-netlist experiment, never a constraint or RTL repair. All original
cell/pin connections must match bit for bit after contracting only the new positive
delay cells. Rerun mapped check/stat and full STA with the original libraries/SDC.
The older repair_input_hold.py keeps its independent, input-only launch contract.
"""
import argparse
import hashlib
import json
import math
import re
from collections import Counter
from pathlib import Path

from repair_input_hold import PIN, blocks, parse_cells, require

IDENT = r"(?:\\[^\s]+|[A-Za-z_$][\w$]*)"
DECL = re.compile(r"^[ \t]*(?:input|output|inout|wire)\s+(?:wire\s+)?"
                  r"(?:signed\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?(" + IDENT + r")\s*;", re.M)
PREFIX = "r64_ecos_data_hold_"
MACRO_PINS = ("D", "A", "WEB", "GWEB", "CEB")


def attribute(body, name):
    match = re.search(r"\b" + name + r"\s*:\s*(?:\"([^\"]*)\"|([^;]+))\s*;", body)
    require(match, "Missing Liberty attribute " + name)
    return (match[1] if match[1] is not None else match[2]).strip()


def indices(left, right):
    return list(range(left, right + (1 if right >= left else -1), 1 if right >= left else -1))


def declarations(source):
    result = {}
    for match in DECL.finditer(source):
        name = match[3]
        bounds = None if match[1] is None else (int(match[1]), int(match[2]))
        require(name not in result or result[name] == bounds, "Conflicting net declaration " + name)
        result[name] = bounds
    require(result, "No Verilog net declarations")
    return result


def expand(expression, nets):
    """Return MSB-to-LSB renderable scalar atoms; reject implicit width coercion."""
    expression = expression.strip()
    if expression.startswith("{"):
        require(expression.endswith("}"), "Unclosed concatenation")
        inner, depth, start, pieces = expression[1:-1], 0, 0, []
        for pos, char in enumerate(inner):
            depth += (char == "{") - (char == "}")
            require(depth >= 0, "Unbalanced concatenation")
            if char == "," and depth == 0:
                pieces.append(inner[start:pos])
                start = pos + 1
        require(depth == 0, "Unbalanced concatenation")
        pieces.append(inner[start:])
        require(all(x.strip() for x in pieces), "Empty concatenation element")
        return [bit for piece in pieces for bit in expand(piece, nets)]
    constant = re.fullmatch(r"(\d+)'([bBdDhH])([0-9a-fA-FxXzZ_]+)", expression)
    if constant:
        width, radix, value = int(constant[1]), constant[2].lower(), constant[3].lower().replace("_", "")
        require(0 < width <= 65536, "Invalid constant width")
        if set(value) <= {"x"} or set(value) <= {"z"}:
            bits = value[0] * width
        else:
            require(not (set(value) & {"x", "z"}), "Mixed unknown constants unsupported")
            base = {"b": 2, "d": 10, "h": 16}[radix]
            number = int(value, base)
            require(number.bit_length() <= width, "Truncated constant unsupported")
            bits = format(number, "0" + str(width) + "b")
        return ["1'b" + bit for bit in bits]
    signal = re.fullmatch(r"(" + IDENT + r")\s*(?:\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\])?", expression)
    require(signal, "Unsupported mapped pin expression: " + expression[:120])
    name = signal[1]
    require(name in nets, "Undeclared mapped net " + name)
    bounds = nets[name]
    rendered = name + (" " if name.startswith("\\") else "")
    if signal[2] is not None:
        require(bounds is not None, "Bit select on scalar " + name)
        left = int(signal[2])
        right = left if signal[3] is None else int(signal[3])
        selected = indices(left, right)
        legal = indices(*bounds)
        require(all(bit in legal for bit in selected), "Net bit out of range " + expression)
        require(len(selected) == 1 or (left < right) == (bounds[0] < bounds[1]),
                "Reversed part select " + expression)
        return [rendered + "[" + str(bit) + "]" for bit in selected]
    return [rendered] if bounds is None else [rendered + "[" + str(bit) + "]" for bit in indices(*bounds)]


def library_model(libraries):
    cells = {}
    for text in libraries:
        types = dict(blocks(text, "type"))
        for name, body in blocks(text, "cell"):
            require(name not in cells, "Duplicate Liberty cell " + name)
            ports = {}
            for pin, pin_body in blocks(body, "pin"):
                if "[" not in pin:
                    ports[pin] = {"bits": None, "direction": attribute(pin_body, "direction"),
                                  "body": pin_body}
            for bus, bus_body in blocks(body, "bus"):
                typename = attribute(bus_body, "bus_type")
                require(typename in types, "Unknown Liberty bus type " + typename)
                typ = types[typename]
                left, right = int(attribute(typ, "bit_from")), int(attribute(typ, "bit_to"))
                bits = indices(left, right)
                require(int(attribute(typ, "bit_width")) == len(bits), "Liberty bus width mismatch")
                require(attribute(typ, "downto") == ("true" if left > right else "false"),
                        "Liberty bus direction mismatch")
                require(bus not in ports, "Duplicate Liberty port " + bus)
                ports[bus] = {"bits": bits, "direction": attribute(bus_body, "direction"),
                              "body": bus_body}
            area = float(attribute(body, "area"))
            require(math.isfinite(area) and area > 0, "Invalid mapped cell area")
            cells[name] = {"body": body, "ports": ports, "area": area,
                           "ff": bool(list(blocks(body, "ff"))),
                           "latch": bool(list(blocks(body, "latch")))}
    return cells


def macro_hold_bits(pin, port):
    """Return actual scalar/bus bits with a Liberty hold check against CLK."""
    require(port["direction"] == "input" and not re.search(
        r"\b(?:clock|clock_gate_clock_pin)\s*:\s*true\b", port["body"]),
        "Selected macro pin must be a non-clock input: " + pin)
    def has_hold(body):
        return any(attribute(timing, "timing_type") in ("hold_rising", "hold_falling") and
                   attribute(timing, "related_pin") == "CLK"
                   for _, timing in blocks(body, "timing"))
    if port["bits"] is None:
        return {None} if has_hold(port["body"]) else set()
    covered = set()
    for name, body in blocks(port["body"], "pin"):
        selection = re.fullmatch(re.escape(pin) + r"\[(\d+)(?::(\d+))?\]", name)
        require(selection, "Unsupported Liberty bus member " + name)
        left = int(selection[1])
        bits = indices(left, left if selection[2] is None else int(selection[2]))
        require(set(bits) <= set(port["bits"]), "Liberty member outside bus " + name)
        if has_hold(body):
            covered.update(bits)
    return covered


def expanded_pins(match, pins, nets, model):
    require(match[1] in model, "Mapped cell absent from actual Liberty: " + match[1])
    ports = model[match[1]]["ports"]
    # Optional power pins are absent in this logical mapped view. Every actual
    # connection, including all non-target vector/control/output pins, is checked.
    require(set(pins) <= set(ports), "Unknown mapped pin on " + match[2])
    require(not PIN.sub("", match[3]).replace(",", "").strip(), "Unparsed cell connection " + match[2])
    result = {}
    for pin, expression in pins.items():
        bits = expand(expression, nets)
        expected = 1 if ports[pin]["bits"] is None else len(ports[pin]["bits"])
        require(len(bits) == expected, "Pin width mismatch: " + match[2] + "/" + pin)
        result[pin] = bits
    return result


def net_key(atom):
    return atom.lstrip("\\").strip()


def report_pin(node, cells, nets, model):
    endpoint = node.get("pin", "")
    parts = endpoint.rsplit("/", 1)
    require(len(parts) == 2 and parts[0] in cells, "Unknown report cell/pin " + endpoint)
    instance, target = parts
    match, pins = cells[instance]
    require(node.get("instance") == instance and node.get("cell") == match[1],
            "Report cell identity mismatch at " + endpoint)
    selection = re.fullmatch(r"(\w+)(?:\[(\d+)\])?", target)
    require(selection and selection[1] in pins, "Unknown report pin " + endpoint)
    pin = selection[1]
    spec = model[match[1]]["ports"][pin]
    bits = expand(pins[pin], nets)
    if selection[2] is None:
        require(spec["bits"] is None and len(bits) == 1, "Report bus bit missing at " + endpoint)
        atom = bits[0]
    else:
        bit = int(selection[2])
        require(spec["bits"] is not None and bit in spec["bits"], "Report bit out of range at " + endpoint)
        require(len(bits) == len(spec["bits"]), "Report target width mismatch")
        atom = bits[spec["bits"].index(bit)]
    require(node.get("net") == net_key(atom), "Report net mismatch at " + endpoint)
    return instance, pin, spec, atom


def verify(source, output, model, buffer, manifest, edits, added):
    """Full original graph comparison, not merely selected endpoint substitution."""
    recovered = output.replace(added, "", 1) if added else output
    for old, new in edits:
        require(recovered.count(new) == 1, "Ambiguous modified cell recovery")
        recovered = recovered.replace(new, old, 1)
    require(recovered == source, "Non-target netlist text changed")
    before, after = parse_cells(source), parse_cells(output)
    old_nets, new_nets = declarations(source), declarations(output)
    inserted = {item["cell"]: item for entry in manifest for item in entry["chain"]}
    require(len(inserted) == sum(len(entry["chain"]) for entry in manifest), "Duplicate added cell")
    require(set(after) == set(before) | set(inserted), "Unexpected cell addition/removal")
    aliases = {item["y"]: item["a"] for item in inserted.values()}
    require(len(aliases) == len(inserted), "Multiply driven added net")
    require(set(new_nets) == set(old_nets) | set(aliases), "Unexpected net declaration change")
    require(all(net not in old_nets for net in aliases), "Added net aliases an old net")
    def resolve(atom):
        seen = set()
        while atom in aliases:
            require(atom not in seen, "Inserted delay cycle")
            seen.add(atom)
            atom = aliases[atom]
        return atom
    selected = {}
    for entry in manifest:
        instance, target = entry["endpoint"].rsplit("/", 1)
        require(entry["endpoint"] not in selected, "Duplicate manifest endpoint")
        selected[entry["endpoint"]] = entry
    count = 0
    for name, (old, old_pins) in before.items():
        new, new_pins = after[name]
        require(old[1] == new[1], "Original cell type changed at " + name)
        old_bits = expanded_pins(old, old_pins, old_nets, model)
        new_bits = expanded_pins(new, new_pins, new_nets, model)
        require(old_bits == {pin: [resolve(bit) for bit in bits] for pin, bits in new_bits.items()},
                "Original cell/pin connectivity changed at " + name)
        # Contracted equivalence alone could permit delaying an unselected
        # branch of the same net. Also compare exact original sink attachments.
        for pin, bits in old_bits.items():
            expected_bits = list(bits)
            port_bits = model[old[1]]["ports"][pin]["bits"]
            for offset, atom in enumerate(bits):
                endpoint = name + "/" + pin
                if port_bits is not None:
                    endpoint += "[" + str(port_bits[offset]) + "]"
                if endpoint in selected:
                    entry = selected[endpoint]
                    require(entry["original"] == atom, "Manifest original sink mismatch")
                    expected_bits[offset] = entry["chain"][-1]["y"]
                    del selected[endpoint]
            require(new_bits[pin] == expected_bits, "Non-target sink changed at " + name + "/" + pin)
        count += sum(map(len, old_bits.values()))
    require(not selected, "Manifest endpoint missing from original graph")
    for name, expected in inserted.items():
        match, pins = after[name]
        require(match[1] == buffer and pins == {"A": expected["a"], "Y": expected["y"]},
                "Unverified inserted delay " + name)
        expanded_pins(match, pins, new_nets, model)
        resolve(expected["y"])
    for entry in manifest:
        chain = entry["chain"]
        require(entry["stages"] == len(chain), "Manifest stages differ from actual chain")
        require(chain[0]["a"] == entry["original"] and all(
            chain[i]["a"] == chain[i-1]["y"] for i in range(1, len(chain))), "Broken delay chain")
    return count



def delay_stage_counts(macro_pins, stages, pin_stages=None):
    """Validate explicit per-pin overrides and retain the default for other pins."""
    require(isinstance(stages, int) and not isinstance(stages, bool) and 1 <= stages <= 8,
            "Delay stages must be an integer in 1..8")
    require(macro_pins and set(macro_pins) <= set(MACRO_PINS),
            "Macro pins must be explicitly selected from D, A, WEB, GWEB, CEB; never CLK or outputs")
    overrides = {}
    for value in pin_stages or []:
        match = re.fullmatch(r"([A-Za-z_][A-Za-z_0-9]*)=([0-9]+)", value)
        require(match, "Pin stages must use PIN=N with N in 1..8")
        pin, count = match[1], int(match[2])
        require(pin in macro_pins, "Pin stage override is not a selected macro pin: " + pin)
        require(1 <= count <= 8, "Pin stage override must be 1..8")
        require(pin not in overrides or overrides[pin] == count,
                "Conflicting pin stage overrides: " + pin)
        overrides[pin] = count
    return dict(sorted(overrides.items())), {
        pin: overrides.get(pin, stages) for pin in sorted(macro_pins)}


def repair(source, checks, libraries, macro_cells, buffer="DLY4X2H7L", stages=3,
           macro_pins=None, pin_stages=None):
    macro_pins = {"D"} if macro_pins is None else set(macro_pins)
    overrides, effective_stages = delay_stage_counts(macro_pins, stages, pin_stages)
    require(macro_cells and all(re.fullmatch(r"ics55_ecos_sram_\w+", name) for name in macro_cells),
            "Explicit ECOS macro cell selection required")
    require(len(re.findall(r"^module\s", source, re.M)) == 1 and
            len(re.findall(r"^endmodule\s*$", source, re.M)) == 1, "Expected one flattened module")
    require(PREFIX not in source, "Delay names already exist; choose an unmodified mapped parent")
    cells, nets, model = parse_cells(source), declarations(source), library_model(libraries)
    top = re.search(r"^module\s+(\S+)\s*\(", source, re.M)[1]
    input_atoms = {}
    for declaration in DECL.finditer(source):
        if re.match(r"\s*input\b", declaration[0]):
            for atom in expand(declaration[3], nets):
                require(net_key(atom) not in input_atoms, "Ambiguous top input bit")
                input_atoms[net_key(atom)] = atom
    require(buffer in model, "Delay cell absent from actual Liberty")
    delay = model[buffer]
    require(set(delay["ports"]) == {"A", "Y"} and not delay["ff"] and not delay["latch"] and
            delay["ports"]["A"]["direction"] == "input" and
            delay["ports"]["Y"]["direction"] == "output" and
            attribute(delay["ports"]["Y"]["body"], "function") == "A",
            "Delay must be an exact two-pin, non-inverting combinational cell")
    eligible = {}
    for name in macro_cells:
        require(name in model, "Selected ECOS macro absent from Liberty: " + name)
        ports = model[name]["ports"]
        require("CLK" in ports and ports["CLK"]["direction"] == "input" and
                ports["CLK"]["bits"] is None, "ECOS macro must have a scalar CLK input")
        eligible[name] = {}
        for pin in sorted(macro_pins & set(ports)):
            port = ports[pin]
            if pin == "D":
                writes = list(blocks(port["body"], "memory_write"))
                require(port["bits"] is not None and len(writes) == 1 and
                        attribute(writes[0][1], "clocked_on") == "CLK",
                        "Selected D must be a CLK-clocked memory_write input bus")
            covered = macro_hold_bits(pin, port)
            require(covered, "Selected macro input lacks hold timing related to CLK: " + name + "/" + pin)
            eligible[name][pin] = covered
    # ECOS whole-word and bit-write macros are heterogeneous: WEB exists only on
    # the latter. Missing ports are not candidates; an actual report naming one
    # still fails closed during endpoint validation.
    require(all(any(pin in ports for ports in eligible.values()) for pin in macro_pins),
            "Requested macro pin absent from all selected Liberty macros")
    original_area = 0.0
    for match, pins in cells.values():
        expanded_pins(match, pins, nets, model)
        original_area += model[match[1]]["area"]
    targets, skipped, path_atoms = {}, [], set()
    for path in checks["checks"]:
        if path.get("path_type") != "min" or path.get("slack", 0) >= 0:
            continue
        endpoint = path["endpoint"]
        parts = endpoint.rsplit("/", 1)
        reported = path.get("source_path", [])
        declared_target = reported[-1].get("cell") if reported else None
        if len(parts) != 2 or parts[0] not in cells:
            require(declared_target not in macro_cells, "Reported ECOS endpoint absent from current netlist")
            skipped.append({"endpoint": endpoint, "reason": "not a selected ECOS input endpoint"})
            continue
        match, pins = cells[parts[0]]
        selection = re.match(r"(\w+)", parts[1])
        if match[1] not in macro_cells or not selection or selection[1] not in macro_pins:
            require(declared_target not in macro_cells or match[1] in macro_cells, "Report target cell mismatch")
            skipped.append({"endpoint": endpoint, "reason": "not a selected ECOS input endpoint"})
            continue
        selection = re.fullmatch(r"(\w+)(?:\[(\d+)\])?", parts[1])
        require(selection, "Malformed ECOS input endpoint")
        require(selection[1] in eligible[match[1]], "Reported macro pin absent from its actual Liberty")
        target_bit = None if selection[2] is None else int(selection[2])
        require(target_bit in eligible[match[1]][selection[1]],
                "Endpoint bit lacks actual CLK-related hold timing")
        require(len(reported) >= 2 and reported[0].get("pin") == path.get("startpoint") and
                reported[-1].get("pin") == endpoint, "Report path start/end mismatch")
        previous = None
        for node in reported:
            if previous is None and node.get("instance") == "":
                require(node.get("cell") == top and node.get("pin") in input_atoms,
                        "Unknown top input report launch")
                atom = input_atoms[node["pin"]]
                require("net" not in node or node["net"] == net_key(atom),
                        "Top input report net mismatch")
                current = ("", node["pin"], {"direction": "output"}, atom)
            else:
                current = report_pin(node, cells, nets, model)
            instance, pin, spec, atom = current
            path_atoms.add(atom)
            if previous:
                old_instance, old_pin, old_spec, old_atom = previous
                if instance == old_instance:
                    kind = model[cells[instance][0][1]]
                    require(not kind["ff"] and not kind["latch"] and
                            old_spec["direction"] == "input" and spec["direction"] == "output",
                            "Invalid report combinational arc")
                else:
                    require(old_spec["direction"] == "output" and spec["direction"] == "input" and
                            old_atom == atom, "Report wire connection mismatch")
            else:
                require((instance == "" or model[cells[instance][0][1]]["ff"]) and
                        spec["direction"] == "output",
                        "Macro input repair requires a current FF or verified top input launch")
            previous = current
        instance, pin, spec, atom = previous
        require(pin in macro_pins, "Not a selected macro input pin")
        bit = target_bit
        target = (instance, pin, bit, atom)
        require(endpoint not in targets or targets[endpoint] == target, "Conflicting duplicate endpoint")
        targets[endpoint] = target
    # Every reported data-path net must have one actual driver or top input. No new shared
    # drivers are introduced; each new net name is fresh and has exactly one Y.
    source_atoms = path_atoms
    drivers = Counter(atom for atom in input_atoms.values() if atom in source_atoms)
    for match, pins in cells.values():
        ports = model[match[1]]["ports"]
        for pin, expression in pins.items():
            if ports[pin]["direction"] == "output":
                drivers.update(bit for bit in expand(expression, nets) if bit in source_atoms)
    require(all(drivers[atom] == 1 for atom in source_atoms), "Selected path net has missing/multiple drivers")
    changed, manifest, declarations_out, instances_out = {}, [], [], []
    for index, (endpoint, (instance, pin, bit, atom)) in enumerate(sorted(targets.items())):
        signal, chain = atom, []
        count = effective_stages[pin]
        for stage in range(count):
            net, name = f"{PREFIX}net_{index}_{stage}", f"{PREFIX}buf_{index}_{stage}"
            declarations_out.append("  wire " + net + ";")
            instances_out.append(f"  {buffer} {name} (\n    .A({signal}),\n    .Y({net})\n  );")
            chain.append({"cell": name, "a": signal, "y": net})
            signal = net
        if instance not in changed:
            changed[instance] = {}
        if pin not in changed[instance]:
            match, pins = cells[instance]
            changed[instance][pin] = expand(pins[pin], nets)
        port_bits = model[cells[instance][0][1]]["ports"][pin]["bits"]
        changed[instance][pin][0 if bit is None else port_bits.index(bit)] = signal
        manifest.append({"endpoint": endpoint, "pin": pin, "stages": count, "original": atom, "chain": chain})
    edits = []
    output = source
    for instance, pin_bits in changed.items():
        match, pins = cells[instance]
        old = new = match[0]
        for pin, bits in pin_bits.items():
            expression = bits[0] if len(bits) == 1 else "{ " + ", ".join(bits) + " }"
            connection = "." + pin + "(" + pins[pin] + ")"
            require(new.count(connection) == 1, "Ambiguous macro pin substitution")
            new = new.replace(connection, "." + pin + "(" + expression + ")", 1)
        require(old != new, "Macro input substitution failed")
        edits.append((match.start(), match.end(), old, new))
    for start, end, old, new in sorted(edits, reverse=True):
        output = output[:start] + new + output[end:]
    added = "\n".join(declarations_out + instances_out) + ("\n" if instances_out else "")
    output = output.replace("endmodule", added + "endmodule")
    count = verify(source, output, model, buffer, manifest, [(old, new) for _, _, old, new in edits], added)
    num = sum(len(entry["chain"]) for entry in manifest)
    return output, {
        "scope": "Explicit ECOS non-clock input sink branches with CLK-related Liberty hold timing from actual negative FF/top-input paths",
        "equivalence": "Every original cell type and every pin bit identical after contracting only verified new positive delay cells; other source text identical",
        "checked_original_pin_bits": count, "macro_cells": sorted(macro_cells), "macro_pins": sorted(macro_pins),
        "buffer_cell": buffer, "stages": stages, "pin_stages": overrides,
        "effective_pin_stages": effective_stages, "buffer_count": num,
        "original_cell_area_um2": original_area, "extra_cell_area_um2": num * delay["area"],
        "repaired_cell_area_um2": original_area + num * delay["area"],
        "endpoints": manifest, "unhandled_negative_checks": skipped,
        "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
        "repaired_sha256": hashlib.sha256(output.encode()).hexdigest(),
        "limitations": "Connectivity proof is not timed equivalence or STA closure. Full original setup/hold/pulse/period and electrical checks remain required; no clock/SDC/RTL changes.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--netlist", required=True, type=Path)
    parser.add_argument("--checks", required=True, type=Path, action="append")
    parser.add_argument("--liberty", required=True, type=Path, action="append")
    parser.add_argument("--macro-cell", required=True, action="append")
    parser.add_argument("--macro-pin", action="append", choices=MACRO_PINS,
                        help="Repeat to select exact non-clock input pins; default: D")
    parser.add_argument("--buffer", default="DLY4X2H7L")
    parser.add_argument("--stages", type=int, default=3)
    parser.add_argument("--pin-stages", action="append", metavar="PIN=N",
                        help="Repeat to override 1..8 stages for selected macro pins")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()
    require(args.netlist.resolve() != args.output.resolve(), "Do not overwrite the mapped parent")
    require(not args.output.exists() and not args.manifest.exists(), "Preserve existing output/manifest")
    checks = {"checks": [item for path in args.checks for item in json.loads(path.read_text())["checks"]]}
    output, info = repair(args.netlist.read_text(), checks, [p.read_text() for p in args.liberty],
                          args.macro_cell, args.buffer, args.stages, args.macro_pin, args.pin_stages)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output)
    args.manifest.write_text(json.dumps(info, indent=2) + "\n")
    print(f"Connectivity PASS: {info['buffer_count']} real delay cells, +{info['extra_cell_area_um2']:.2f} um^2; rerun full STA")


if __name__ == "__main__":
    main()
