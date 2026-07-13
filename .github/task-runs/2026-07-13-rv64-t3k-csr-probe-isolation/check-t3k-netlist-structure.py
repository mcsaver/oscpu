#!/usr/bin/env python3
"""Check the T3K main-access/current-head-probe ABI in a hierarchical netlist."""

from __future__ import annotations

import argparse
from collections import defaultdict
import re
import sys
from pathlib import Path


PREFIX = "T3K-NETLIST-STRUCTURE"


def fail(message: str) -> None:
    print(f"[{PREFIX}] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def module_identifier_matches(identifier: str, exact_name: str) -> bool:
    """Match one logical module, including Yosys' exact hashed paramod spelling."""
    if identifier == exact_name:
        return True
    return re.fullmatch(
        rf"\\\$paramod\$[0-9a-f]{{40}}\\{re.escape(exact_name)}",
        identifier,
    ) is not None


def module_blocks(path: Path, exact_name: str) -> list[str]:
    blocks: list[str] = []
    selected = False
    lines: list[str] = []
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            if line.startswith("module "):
                declaration = re.match(
                    r"^module\s+(?P<identifier>\\\S+|[^\s(]+)\s*\(", line
                )
                selected = bool(
                    declaration
                    and module_identifier_matches(
                        declaration.group("identifier"), exact_name
                    )
                )
                lines = [line] if selected else []
                continue
            if selected:
                lines.append(line)
                if line.startswith("endmodule"):
                    blocks.append("".join(lines))
                    selected = False
                    lines = []
    return blocks


def parse_cell_instances(block: str) -> list[tuple[str, str, dict[str, str]]]:
    instances: list[tuple[str, str, dict[str, str]]] = []
    lines = block.splitlines()
    index = 0
    while index < len(lines):
        start = re.fullmatch(r"  (\S+) (\S+) \(", lines[index])
        if start is None:
            index += 1
            continue
        cell_type, instance_name = start.groups()
        connections: dict[str, str] = {}
        index += 1
        while index < len(lines) and lines[index] != "  );":
            connection = re.fullmatch(r"    \.([^()]+)\(([^()]+)\),?", lines[index])
            if connection is None:
                fail(
                    f"malformed scalar cell connection {cell_type} "
                    f"{instance_name}: {lines[index]!r}"
                )
            pin, net = connection.groups()
            if pin in connections:
                fail(f"duplicate cell pin {cell_type} {instance_name}.{pin}")
            connections[pin] = net
            index += 1
        if index >= len(lines):
            fail(f"unterminated cell instance {cell_type} {instance_name}")
        if not connections:
            fail(f"empty cell instance {cell_type} {instance_name}")
        instances.append((cell_type, instance_name, connections))
        index += 1
    return instances


def parse_liberty_cells(
    path: Path, required_cells: set[str]
) -> tuple[dict[str, dict[str, str]], set[str]]:
    directions: dict[str, dict[str, str]] = {}
    sequential: set[str] = set()
    depth = 0
    cell_name: str | None = None
    cell_depth = 0
    pin_name: str | None = None
    pin_depth = 0
    with path.open(encoding="utf-8", errors="strict") as stream:
        for line in stream:
            if cell_name is None:
                cell_match = re.match(
                    r'^\s*cell\s*\(\s*"?([^"\s)]+)"?\s*\)\s*\{', line
                )
                if cell_match is not None and cell_match.group(1) in required_cells:
                    cell_name = cell_match.group(1)
                    cell_depth = depth + line.count("{")
                    directions[cell_name] = {}
            elif pin_name is None:
                if re.match(r"^\s*(?:ff|latch)\s*\(", line):
                    sequential.add(cell_name)
                pin_match = re.match(
                    r'^\s*pin\s*\(\s*"?([^"\s)]+)"?\s*\)\s*\{', line
                )
                if pin_match is not None:
                    pin_name = pin_match.group(1)
                    pin_depth = depth + line.count("{")
            else:
                direction_match = re.match(
                    r"^\s*direction\s*:\s*(input|output|inout|internal)\s*;",
                    line,
                )
                if direction_match is not None:
                    directions[cell_name][pin_name] = direction_match.group(1)

            depth += line.count("{") - line.count("}")
            if pin_name is not None and depth < pin_depth:
                pin_name = None
            if cell_name is not None and depth < cell_depth:
                cell_name = None
                pin_name = None

    missing = required_cells - set(directions)
    if missing:
        fail(f"standard-cell liberty is missing netlist cells: {sorted(missing)}")
    for cell in sorted(required_cells):
        if not directions[cell]:
            fail(f"standard-cell liberty has no pin directions for {cell}")
    return directions, sequential


def is_constant(expression: str) -> bool:
    return re.fullmatch(r"\d+'[bdho][0-9a-fxz]+", expression, re.IGNORECASE) is not None


def combinational_input_cone(
    block: str,
    targets: set[str],
    directions: dict[str, dict[str, str]],
    sequential: set[str],
) -> set[str]:
    reverse_edges: dict[str, set[str]] = defaultdict(set)
    instances = parse_cell_instances(block)
    for cell_type, instance_name, connections in instances:
        if cell_type not in directions:
            fail(f"missing direction model for {cell_type} {instance_name}")
        unknown_pins = set(connections) - set(directions[cell_type])
        if unknown_pins:
            fail(
                f"liberty pin model mismatch {cell_type} {instance_name}: "
                f"{sorted(unknown_pins)}"
            )
        if cell_type in sequential:
            continue
        input_nets = {
            net
            for pin, net in connections.items()
            if directions[cell_type][pin] in ("input", "inout")
            and not is_constant(net)
        }
        output_nets = {
            net
            for pin, net in connections.items()
            if directions[cell_type][pin] in ("output", "inout")
            and not is_constant(net)
        }
        for output_net in output_nets:
            reverse_edges[output_net].update(input_nets)

    for destination, expression in re.findall(
        r"^  assign (\S+) = (\S+);$", block, re.MULTILINE
    ):
        if not is_constant(expression):
            reverse_edges[destination].add(expression)

    missing_targets = targets - set(reverse_edges)
    if missing_targets:
        fail(f"combinational cone targets have no modeled driver: {sorted(missing_targets)}")
    cone = set(targets)
    worklist = list(targets)
    while worklist:
        net = worklist.pop()
        for predecessor in reverse_edges.get(net, ()):
            if predecessor not in cone:
                cone.add(predecessor)
                worklist.append(predecessor)
    return cone


def scalar_ports(stem: str, width: int) -> set[str]:
    return {f"{stem}_{bit}_" for bit in range(width)}


def scalar_decl_count(block: str, direction: str, name: str) -> int:
    return len(re.findall(rf"^  {direction} {re.escape(name)};$", block, re.MULTILINE))


def vector_decl_count(block: str, direction: str, stem: str) -> int:
    return len(
        re.findall(rf"^  {direction} {re.escape(stem)}_\d+_;$", block, re.MULTILINE)
    )


def scalar_connection(block: str, port: str) -> list[str]:
    return re.findall(rf"\.{re.escape(port)}\(([^)]+)\),", block)


def vector_connections(block: str, port_stem: str) -> list[tuple[int, str]]:
    result = [
        (int(bit), net)
        for bit, net in re.findall(
            rf"\.{re.escape(port_stem)}_(\d+)_\(([^)]+)\),", block
        )
    ]
    return sorted(result)


def require_vector_binding(
    block: str,
    port_stem: str,
    net_stem: str,
    width: int,
) -> None:
    expected = [(bit, f"{net_stem}_{bit}_") for bit in range(width)]
    actual = vector_connections(block, port_stem)
    if actual != expected:
        fail(
            f"vector binding mismatch {port_stem}: "
            f"actual={actual} expected={expected}"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect", choices=("old", "fresh"), required=True)
    parser.add_argument("--std-lib", type=Path, required=True)
    parser.add_argument("netlist", type=Path)
    args = parser.parse_args()
    if not args.netlist.is_file() or args.netlist.is_symlink():
        fail(f"missing or non-regular netlist: {args.netlist}")
    if args.netlist.stat().st_size == 0:
        fail(f"empty netlist: {args.netlist}")
    if (
        not args.std_lib.is_file()
        or args.std_lib.is_symlink()
        or args.std_lib.stat().st_size == 0
    ):
        fail(f"missing, empty, symlink, or non-regular std liberty: {args.std_lib}")

    module_names = (
        "OooCsrAccessRequestMux",
        "OooControlPlane",
        "OooCoreTopGlue",
        "NpcCoreTop",
        "CsrFile",
    )
    blocks: dict[str, str] = {}
    for name in module_names:
        found = module_blocks(args.netlist, name)
        if len(found) != 1:
            fail(f"module {name} cardinality is {len(found)}, expected 1")
        blocks[name] = found[0]

    mux = blocks["OooCsrAccessRequestMux"]
    plane = blocks["OooControlPlane"]
    glue = blocks["OooCoreTopGlue"]
    core = blocks["NpcCoreTop"]
    csr = blocks["CsrFile"]
    required_cells = {
        cell_type
        for block in (mux, csr)
        for cell_type, _instance, _connections in parse_cell_instances(block)
    }
    directions, sequential = parse_liberty_cells(args.std_lib, required_cells)
    legacy_legality_ports = (
        {"csr_valid_i", "csr_funct3_i_1_"}
        | scalar_ports("csr_addr_i", 12)
        | scalar_ports("csr_rs1_idx_i", 5)
    )
    probe_legality_ports = (
        {"csr_probe_valid_i", "csr_probe_funct3_i_1_"}
        | scalar_ports("csr_probe_addr_i", 12)
        | scalar_ports("csr_probe_rs1_idx_i", 5)
    )
    csr_input_ports = set(re.findall(r"^  input (\S+);$", csr, re.MULTILINE))
    csr_illegal_cone = combinational_input_cone(
        csr, {"csr_illegal_o"}, directions, sequential
    )
    csr_illegal_dependencies = csr_illegal_cone & csr_input_ports
    if plane.count("OooCsrAccessRequestMux u_csr_access_request_mux (") != 1:
        fail("control plane does not contain exactly one CSR request mux")
    if core.count("CsrFile u_csr_file (") != 1:
        fail("NpcCoreTop does not contain exactly one CsrFile")

    legacy_decl_counts = {
        "csr_valid_i": scalar_decl_count(csr, "input", "csr_valid_i"),
        "csr_addr_i": vector_decl_count(csr, "input", "csr_addr_i"),
        "csr_funct3_i": vector_decl_count(csr, "input", "csr_funct3_i"),
        "csr_rs1_idx_i": vector_decl_count(csr, "input", "csr_rs1_idx_i"),
    }
    expected_legacy = {
        "csr_valid_i": 1,
        "csr_addr_i": 12,
        "csr_funct3_i": 3,
        "csr_rs1_idx_i": 5,
    }
    if legacy_decl_counts != expected_legacy:
        fail(f"legacy CSR main-access ABI drifted: {legacy_decl_counts}")
    require_vector_binding(core, "csr_addr_i", "ooo_csr_access_addr_w", 12)
    require_vector_binding(core, "csr_funct3_i", "ooo_csr_access_funct3_w", 3)
    require_vector_binding(core, "csr_rs1_idx_i", "ooo_csr_access_rs1_idx_w", 5)
    if scalar_connection(core, "csr_valid_i") != ["ooo_csr_access_valid_w"]:
        fail("CsrFile main-access valid binding drifted")

    dedicated_probe_stems = (
        "csr_probe_valid",
        "csr_probe_addr",
        "csr_probe_funct3",
        "csr_probe_rs1_idx",
    )
    probe_tokens = {
        name: {stem: block.count(stem) for stem in dedicated_probe_stems}
        for name, block in blocks.items()
    }
    if args.expect == "old":
        if any(
            count
            for module_counts in probe_tokens.values()
            for count in module_counts.values()
        ):
            fail(f"old netlist unexpectedly contains T3K probe ABI: {probe_tokens}")
        if csr_illegal_dependencies != legacy_legality_ports:
            fail(
                "old CsrFile illegal cone is not exactly legacy CSR access: "
                f"{sorted(csr_illegal_dependencies)}"
            )
        print(
            f"[{PREFIX}] PASS: expect=old probe_tokens=0 "
            "legacy_access=1/12/3/5 csr_illegal_cone=legacy:19"
        )
        return

    probe_decl_counts = {
        "mux_valid": scalar_decl_count(mux, "output", "csr_probe_valid_o"),
        "mux_addr": vector_decl_count(mux, "output", "csr_probe_addr_o"),
        "mux_funct3": vector_decl_count(mux, "output", "csr_probe_funct3_o"),
        "mux_rs1": vector_decl_count(mux, "output", "csr_probe_rs1_idx_o"),
        "csr_valid": scalar_decl_count(csr, "input", "csr_probe_valid_i"),
        "csr_addr": vector_decl_count(csr, "input", "csr_probe_addr_i"),
        "csr_funct3": vector_decl_count(csr, "input", "csr_probe_funct3_i"),
        "csr_rs1": vector_decl_count(csr, "input", "csr_probe_rs1_idx_i"),
    }
    expected_probe = {
        "mux_valid": 1,
        "mux_addr": 12,
        "mux_funct3": 3,
        "mux_rs1": 5,
        "csr_valid": 1,
        "csr_addr": 12,
        "csr_funct3": 3,
        "csr_rs1": 5,
    }
    if probe_decl_counts != expected_probe:
        fail(f"fresh CSR probe ABI width/cardinality mismatch: {probe_decl_counts}")

    if scalar_connection(plane, "csr_probe_valid_o") != ["csr_probe_valid_w"]:
        fail("request-mux probe-valid output binding drifted")
    require_vector_binding(plane, "csr_probe_addr_o", "csr_probe_addr_w", 12)
    require_vector_binding(plane, "csr_probe_funct3_o", "csr_probe_funct3_w", 3)
    require_vector_binding(plane, "csr_probe_rs1_idx_o", "csr_probe_rs1_idx_w", 5)

    if scalar_connection(core, "csr_probe_valid_i") != ["ooo_csr_probe_valid_w"]:
        fail("CsrFile probe-valid binding is not the dedicated probe net")
    require_vector_binding(core, "csr_probe_addr_i", "ooo_csr_probe_addr_w", 12)
    require_vector_binding(core, "csr_probe_funct3_i", "ooo_csr_probe_funct3_w", 3)
    require_vector_binding(core, "csr_probe_rs1_idx_i", "ooo_csr_probe_rs1_idx_w", 5)

    for width, probe_stem, legacy_stem in (
        (12, "csr_probe_addr_i", "csr_addr_i"),
        (3, "csr_probe_funct3_i", "csr_funct3_i"),
        (5, "csr_probe_rs1_idx_i", "csr_rs1_idx_i"),
    ):
        probe_nets = {net for _, net in vector_connections(core, probe_stem)}
        legacy_nets = {net for _, net in vector_connections(core, legacy_stem)}
        if len(probe_nets) != width or probe_nets & legacy_nets:
            fail(
                f"probe/main-access physical net alias at {probe_stem}: "
                f"probe={probe_nets} legacy={legacy_nets}"
            )
    if scalar_connection(core, "csr_probe_valid_i") == scalar_connection(
        core, "csr_valid_i"
    ):
        fail("probe valid physically aliases main-access valid")

    # The head-only producer contract is preserved as ports even if internal
    # cell names are technology-generated.
    head_decl_counts = {
        "head0_raw": scalar_decl_count(mux, "input", "head0_csr_raw_i"),
        "head1_raw": scalar_decl_count(mux, "input", "head1_csr_raw_i"),
        "head_inst0": vector_decl_count(mux, "input", "head_inst0_i"),
        "head_inst1": vector_decl_count(mux, "input", "head_inst1_i"),
    }
    if head_decl_counts != {
        "head0_raw": 1,
        "head1_raw": 1,
        "head_inst0": 32,
        "head_inst1": 32,
    }:
        fail(f"head-only probe producer inputs drifted: {head_decl_counts}")

    if csr_illegal_dependencies != probe_legality_ports:
        fail(
            "fresh CsrFile illegal cone is not exactly dedicated probe access: "
            f"{sorted(csr_illegal_dependencies)}"
        )
    probe_targets = (
        {"csr_probe_valid_o"}
        | scalar_ports("csr_probe_addr_o", 12)
        | scalar_ports("csr_probe_funct3_o", 3)
        | scalar_ports("csr_probe_rs1_idx_o", 5)
    )
    mux_probe_cone = combinational_input_cone(
        mux, probe_targets, directions, sequential
    )
    mux_input_ports = set(re.findall(r"^  input (\S+);$", mux, re.MULTILINE))
    mux_probe_dependencies = mux_probe_cone & mux_input_ports
    selected_inst_bits = set(range(12, 15)) | set(range(15, 20)) | set(range(20, 32))
    expected_head_dependencies = {
        "dispatch_valid_i",
        "dispatch0_system_i",
        "dispatch1_barrier_i",
        "head0_csr_raw_i",
        "head1_csr_raw_i",
    } | {
        f"head_inst{head}_i_{bit}_"
        for head in (0, 1)
        for bit in selected_inst_bits
    }
    if mux_probe_dependencies != expected_head_dependencies:
        fail(
            "fresh request-mux probe cone is not exactly current-head-only: "
            f"actual={sorted(mux_probe_dependencies)} "
            f"expected={sorted(expected_head_dependencies)}"
        )

    print(
        f"[{PREFIX}] PASS: expect=fresh probe=1/12/3/5 "
        "legacy=1/12/3/5 distinct_bindings=PASS "
        f"csr_illegal_cone=probe:19 mux_probe_cone=head:{len(mux_probe_dependencies)} "
        f"tokens={probe_tokens}"
    )


if __name__ == "__main__":
    main()
