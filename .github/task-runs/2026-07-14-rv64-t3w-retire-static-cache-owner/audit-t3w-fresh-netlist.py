#!/usr/bin/env python3
"""T3W fresh mapped-netlist ownership audit.

This deliberately inspects the mapped netlist rather than the RTL.  It builds
an over-approximated combinational connectivity graph inside the preserved
FIFO, IFU and ROB modules.  Sequential D/Q arcs are boundaries: a Q is a
source and a D is an endpoint.  Over-approximation is intentional here; it can
only make a forbidden path harder to dismiss.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


class AuditError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AuditError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_identifier(value: str) -> str:
    value = value.strip()
    if value.startswith("\\"):
        # Whitespace terminates an escaped Verilog identifier and is not part
        # of the logical name.
        return value.rstrip()
    return value


@dataclass(frozen=True)
class Instance:
    cell_type: str
    name: str
    connections: dict[str, str]


@dataclass
class Module:
    name: str
    text: str
    inputs: set[str]
    outputs: set[str]
    instances: list[Instance]
    assignments: list[tuple[str, set[str]]]


MODULE_START_RE = re.compile(r"(?m)^module\s+([^\s(]+)\s*\(")
INSTANCE_RE = re.compile(
    r"(?ms)^  (\S+)\s+(\S+)\s*\(\s*\n(.*?)^  \);"
)
CONNECTION_RE = re.compile(r"(?ms)\.([^\s(]+)\s*\(\s*(.*?)\s*\)")
PORT_RE = re.compile(r"(?m)^\s{2}(input|output|inout)\s+(.+?)\s*;$")
ASSIGN_RE = re.compile(r"(?m)^\s{2}assign\s+(.+?)\s*=\s*(.+?)\s*;$")
TOKEN_RE = re.compile(r"\\[^\s,;{}()]+|[A-Za-z_$][A-Za-z0-9_$.:\[\]]*")


def expression_nets(expression: str) -> set[str]:
    expression = re.sub(
        r"\b(?:\d+)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?_]+",
        " ",
        expression,
    )
    nets: set[str] = set()
    for token in TOKEN_RE.findall(expression):
        token = normalize_identifier(token)
        if token in {"assign", "wire", "input", "output"}:
            continue
        # Numeric constants are not matched by TOKEN_RE.  Verilog keywords in
        # the mapped aliases are not expected; reject them if one appears as a
        # driver-less name later in the graph.
        nets.add(token)
    return nets


def parse_module(name: str, text: str) -> Module:
    inputs: set[str] = set()
    outputs: set[str] = set()
    for direction, declaration in PORT_RE.findall(text):
        identifier = normalize_identifier(declaration)
        # The mapped output contains one scalar declaration per bit.
        require(" " not in identifier, f"unsupported port declaration in {name}: {declaration}")
        if direction == "input":
            inputs.add(identifier)
        elif direction == "output":
            outputs.add(identifier)

    instances: list[Instance] = []
    for match in INSTANCE_RE.finditer(text):
        cell_type, instance_name, body = match.groups()
        connections: dict[str, str] = {}
        for port, expression in CONNECTION_RE.findall(body):
            nets = expression_nets(expression)
            require(
                len(nets) <= 1,
                f"unsupported multi-net instance expression {name}/{instance_name}.{port}: {expression}",
            )
            if nets:
                connections[port] = next(iter(nets))
        instances.append(Instance(cell_type, instance_name, connections))

    assignments: list[tuple[str, set[str]]] = []
    for lhs, rhs in ASSIGN_RE.findall(text):
        lhs_nets = expression_nets(lhs)
        require(len(lhs_nets) == 1, f"unsupported assignment lhs in {name}: {lhs}")
        assignments.append((next(iter(lhs_nets)), expression_nets(rhs)))

    require(inputs and outputs and instances, f"incomplete mapped module parse: {name}")
    return Module(name, text, inputs, outputs, instances, assignments)


def load_required_modules(netlist: Path) -> tuple[dict[str, Module], set[str]]:
    text = netlist.read_text(errors="strict")
    starts = list(MODULE_START_RE.finditer(text))
    require(starts, "mapped netlist contains no modules")
    all_module_names = {match.group(1) for match in starts}
    selected_texts: dict[str, tuple[str, str]] = {}
    for match in starts:
        raw_name = match.group(1)
        end = text.find("\nendmodule", match.end())
        require(end >= 0, f"unterminated module {raw_name}")
        body = text[match.start() : end]
        logical_name = ""
        if raw_name.endswith("\\OooFetchPacketFifo"):
            logical_name = "fifo"
        elif raw_name.endswith("\\OooRob"):
            logical_name = "rob"
        elif raw_name == "OooFetchAxiBridge":
            logical_name = "ifu"
        if logical_name:
            require(logical_name not in selected_texts, f"duplicate selected module: {logical_name}")
            selected_texts[logical_name] = (raw_name, body)
    require(set(selected_texts) == {"fifo", "rob", "ifu"},
            f"missing required mapped modules: {sorted({'fifo', 'rob', 'ifu'} - set(selected_texts))}")
    modules = {
        key: parse_module(raw_name, body)
        for key, (raw_name, body) in selected_texts.items()
    }
    return modules, all_module_names


def used_cell_types(modules: Iterable[Module], all_module_names: set[str]) -> set[str]:
    return {
        instance.cell_type
        for module in modules
        for instance in module.instances
        if instance.cell_type not in all_module_names
    }


def load_liberty_directions(liberty: Path, wanted: set[str]) -> dict[str, dict[str, str]]:
    """Stream one Liberty file and retain pin directions for wanted cells."""

    result: dict[str, dict[str, str]] = {}
    depth = 0
    cell_name: str | None = None
    cell_base = -1
    pin_name: str | None = None
    pin_base = -1
    cell_re = re.compile(r"^\s*cell\s*\(\s*([^\s)]+)\s*\)\s*\{")
    pin_re = re.compile(r"^\s*pin\s*\(\s*([^\s)]+)\s*\)\s*\{")
    direction_re = re.compile(r"\bdirection\s*:\s*(input|output|inout)\s*;")

    with liberty.open(errors="strict") as stream:
        for line in stream:
            if cell_name is None:
                match = cell_re.match(line)
                if match:
                    candidate = match.group(1).strip('"')
                    cell_name = candidate if candidate in wanted else ""
                    cell_base = depth
                    if cell_name:
                        result.setdefault(cell_name, {})
            elif cell_name and pin_name is None:
                match = pin_re.match(line)
                if match:
                    pin_name = match.group(1).strip('"')
                    pin_base = depth
            if cell_name and pin_name:
                match = direction_re.search(line)
                if match:
                    result[cell_name][pin_name] = match.group(1)

            depth += line.count("{") - line.count("}")
            if pin_name is not None and depth <= pin_base:
                pin_name = None
                pin_base = -1
            if cell_name is not None and depth <= cell_base:
                cell_name = None
                cell_base = -1

    missing = wanted - set(result)
    require(not missing, f"cell types absent from Liberty: {sorted(missing)}")
    incomplete = sorted(name for name, pins in result.items()
                        if not any(direction == "output" for direction in pins.values()))
    require(not incomplete, f"Liberty cells without output pins: {incomplete}")
    return result


class ConnectivityGraph:
    def __init__(
        self,
        module: Module,
        directions: dict[str, dict[str, str]],
        all_module_names: set[str],
        *,
        allow_hierarchy: bool,
    ) -> None:
        self.module = module
        self.comb_drivers: dict[str, set[str]] = defaultdict(set)
        self.comb_consumers: dict[str, set[str]] = defaultdict(set)
        self.seq_q_cells: dict[str, set[str]] = defaultdict(set)
        self.seq_d_cells: dict[str, set[str]] = defaultdict(set)
        self.cell_q_nets: dict[str, set[str]] = defaultdict(set)
        self.cell_d_nets: dict[str, set[str]] = defaultdict(set)
        self.constant_driven: set[str] = set()
        self.skipped_hierarchy: list[str] = []

        for instance in module.instances:
            if instance.cell_type in all_module_names:
                require(allow_hierarchy,
                        f"unexpected hierarchical instance in {module.name}: {instance.name}")
                self.skipped_hierarchy.append(instance.name)
                continue
            pin_dirs = directions.get(instance.cell_type)
            require(pin_dirs is not None,
                    f"unknown mapped cell type {instance.cell_type} in {module.name}")
            is_sequential = "DFF" in instance.cell_type.upper()
            inputs = {
                net for pin, net in instance.connections.items()
                if pin_dirs.get(pin) in {"input", "inout"}
            }
            outputs = {
                net for pin, net in instance.connections.items()
                if pin_dirs.get(pin) == "output"
            }
            require(outputs, f"mapped instance has no output connection: {module.name}/{instance.name}")
            if is_sequential:
                for pin, net in instance.connections.items():
                    if pin == "D":
                        self.seq_d_cells[net].add(instance.name)
                        self.cell_d_nets[instance.name].add(net)
                    if pin in {"Q", "QN"}:
                        self.seq_q_cells[net].add(instance.name)
                        self.cell_q_nets[instance.name].add(net)
                require(self.cell_q_nets[instance.name],
                        f"sequential cell lacks Q/QN: {module.name}/{instance.name}")
                require(self.cell_d_nets[instance.name],
                        f"sequential cell lacks D: {module.name}/{instance.name}")
            else:
                for output in outputs:
                    self.comb_drivers[output].update(inputs)
                for input_net in inputs:
                    self.comb_consumers[input_net].update(outputs)

        for lhs, rhs_nets in module.assignments:
            if rhs_nets:
                self.comb_drivers[lhs].update(rhs_nets)
                for rhs in rhs_nets:
                    self.comb_consumers[rhs].add(lhs)
            else:
                self.constant_driven.add(lhs)

        self._source_cache: dict[str, tuple[set[str], set[str], set[str]]] = {}

    def cell_state_kind(self, cell: str) -> str:
        names = " ".join(self.cell_q_nets[cell])
        patterns = {
            "head_packet": r"(?:^|[\\\s])head_packet_q(?:_|\[)",
            "head_ptr": r"(?:^|[\\\s])head_q(?:_|\[)",
            "lookup_exec_paddr": r"(?:^|[\\\s])lookup_exec_paddr_q(?:_|\[)",
            "pc": r"(?:^|[\\\s])pc_q(?:_|\[)",
            "done": r"(?:^|[\\\s])done_q(?:_|\[)",
            "data": r"(?:^|[\\\s])data_q(?:_|\[)",
            "exception": r"(?:^|[\\\s])exception_q(?:_|\[)",
            "cause": r"(?:^|[\\\s])cause_q(?:_|\[)",
            "tval": r"(?:^|[\\\s])tval_q(?:_|\[)",
            "fflags": r"(?:^|[\\\s])fflags_q(?:_|\[)",
        }
        matches = [kind for kind, pattern in patterns.items() if re.search(pattern, names)]
        require(len(matches) <= 1, f"ambiguous state name for {self.module.name}/{cell}: {names}")
        return matches[0] if matches else "other"

    def backward_sources(self, net: str, active: set[str] | None = None) -> tuple[set[str], set[str], set[str]]:
        """Return (sequential cells, input ports, unresolved nets)."""

        if net in self._source_cache:
            cells, inputs, unresolved = self._source_cache[net]
            return set(cells), set(inputs), set(unresolved)
        if active is None:
            active = set()
        require(net not in active, f"combinational cycle while tracing {self.module.name}/{net}")
        active.add(net)
        cells = set(self.seq_q_cells.get(net, set()))
        inputs = {net} if net in self.module.inputs else set()
        unresolved: set[str] = set()
        if not cells and not inputs:
            predecessors = self.comb_drivers.get(net, set())
            if predecessors:
                for predecessor in predecessors:
                    sub_cells, sub_inputs, sub_unresolved = self.backward_sources(predecessor, active)
                    cells.update(sub_cells)
                    inputs.update(sub_inputs)
                    unresolved.update(sub_unresolved)
            elif net not in self.constant_driven:
                unresolved.add(net)
        active.remove(net)
        self._source_cache[net] = (set(cells), set(inputs), set(unresolved))
        return cells, inputs, unresolved

    def forward_sinks(self, start_nets: Iterable[str]) -> tuple[set[str], set[str], set[str]]:
        """Return (sequential D cells, module outputs, dead-end nets)."""

        queue = deque(start_nets)
        visited: set[str] = set()
        d_cells: set[str] = set()
        outputs: set[str] = set()
        dead_ends: set[str] = set()
        while queue:
            net = queue.popleft()
            if net in visited:
                continue
            visited.add(net)
            d_cells.update(self.seq_d_cells.get(net, set()))
            if net in self.module.outputs:
                outputs.add(net)
            successors = self.comb_consumers.get(net, set())
            if not successors and not self.seq_d_cells.get(net) and net not in self.module.outputs:
                dead_ends.add(net)
            queue.extend(successors)
        return d_cells, outputs, dead_ends


def exact_bit_port(name: str, base: str) -> bool:
    return name == base or re.fullmatch(re.escape(base) + r"_\d+_", name) is not None


FIFO_HEAD_BASES = (
    "head_pc0_o", "head_pc1_o", "head_next_pc0_o", "head_next_pc1_o",
    "head_packet_next_pc_o", "head_inst0_o", "head_inst1_o",
    "head_ctrl0_o", "head_ctrl1_o", "head_static_facts0_o",
    "head_static_facts1_o", "head_rs1_0_o", "head_rs2_0_o",
    "head_rd0_o", "head_imm0_o", "head_rs1_1_o", "head_rs2_1_o",
    "head_rd1_o", "head_imm1_o", "head_resp0_o", "head_resp1_o",
    "head_pred_taken0_o", "head_pred_taken1_o", "head_bht_idx0_o",
    "head_bht_idx1_o", "head_bht_valid0_o", "head_bht_valid1_o",
    "head_slot1_valid_o",
)


def audit_fifo(graph: ConnectivityGraph) -> tuple[dict[str, object], list[str]]:
    outputs_by_base = {
        base: sorted(port for port in graph.module.outputs if exact_bit_port(port, base))
        for base in FIFO_HEAD_BASES
    }
    require(all(outputs_by_base.values()),
            f"FIFO production output group missing: {[base for base, ports in outputs_by_base.items() if not ports]}")
    production_outputs = {port for ports in outputs_by_base.values() for port in ports}
    require(len(production_outputs) == 709,
            f"FIFO packed head width drifted: expected 709, got {len(production_outputs)}")

    state_cells = set(graph.cell_q_nets)
    # Yosys legally coalesces head_packet_q bit names with the 709 output port
    # nets.  Therefore derive the shadow owner from the mapped backward cone,
    # rather than relying on an RTL wire name that may disappear.
    observed_owners: set[str] = set()
    for output in sorted(production_outputs):
        cells, input_ports, unresolved = graph.backward_sources(output)
        require(not input_ports,
                f"FIFO production output has combinational input owner: {output} <- {sorted(input_ports)}")
        require(not unresolved,
                f"FIFO production output has unresolved owner: {output} <- {sorted(unresolved)}")
        require(len(cells) == 1,
                f"FIFO production output is not one-Q-owned: {output} <- {sorted(cells)}")
        observed_owners.update(cells)
    head_packet_cells = observed_owners
    head_ptr_cells = {cell for cell in state_cells if graph.cell_state_kind(cell) == "head_ptr"}
    require(len(head_packet_cells) == 709,
            f"mapped production shadow flop count drifted: {len(head_packet_cells)}")
    require(len(head_ptr_cells) == 2,
            f"mapped head_q flop/clone count is not exactly two: {len(head_ptr_cells)}")

    head_ptr_q_nets = {
        net for cell in head_ptr_cells for net in graph.cell_q_nets[cell]
    }
    d_cells, output_sinks, dead_ends = graph.forward_sinks(head_ptr_q_nets)
    require(not (output_sinks & production_outputs),
            f"head_q still reaches production head outputs: {sorted(output_sinks & production_outputs)}")
    require(not dead_ends,
            f"head_q reaches unresolved/dead combinational sinks: {sorted(dead_ends)[:16]}")
    endpoint_kinds = {
        "head_ptr" if cell in head_ptr_cells else
        "head_packet" if cell in head_packet_cells else
        graph.cell_state_kind(cell)
        for cell in d_cells
    }
    require(endpoint_kinds <= {"head_ptr", "head_packet"},
            f"head_q reaches state outside pointer/shadow D: {sorted(endpoint_kinds)}")
    require("head_packet" in endpoint_kinds,
            "head_q no longer reaches the registered head shadow D (vacuous cut)")

    return {
        "production_output_bits": len(production_outputs),
        "head_packet_q_flops": len(head_packet_cells),
        "head_q_flops": len(head_ptr_cells),
        "head_q_endpoint_flops": len(d_cells),
        "head_q_endpoint_kinds": sorted(endpoint_kinds),
    }, sorted(head_packet_cells)


def find_instance(module: Module, name: str) -> Instance:
    matches = [instance for instance in module.instances if instance.name == name]
    require(len(matches) == 1, f"expected one {module.name}/{name}, got {len(matches)}")
    return matches[0]


def paddr_connections(instance: Instance) -> list[str]:
    connected = [net for port, net in instance.connections.items()
                 if re.fullmatch(r"paddr_i_\d+_", port)]
    require(len(connected) == 64,
            f"{instance.name} mapped paddr width drifted: {len(connected)}")
    return connected


def audit_ifu(graph: ConnectivityGraph) -> dict[str, object]:
    pmp0 = find_instance(graph.module, "u_req_exec_pmp_checker")
    pmp1 = find_instance(graph.module, "u_req_exec1_pmp_checker")
    lookup_cells = {cell for cell in graph.cell_q_nets
                    if graph.cell_state_kind(cell) == "lookup_exec_paddr"}
    pc_cells = {cell for cell in graph.cell_q_nets if graph.cell_state_kind(cell) == "pc"}
    require(len(lookup_cells) >= 60,
            f"lookup_exec_paddr_q was not preserved as a full-width boundary: {len(lookup_cells)} flops")
    require(len(pc_cells) >= 60, f"pc_q boundary unexpectedly absent: {len(pc_cells)} flops")

    source_counts: dict[str, int] = {}
    for label, instance in (("pmp0", pmp0), ("pmp1", pmp1)):
        owners: set[str] = set()
        input_owners: set[str] = set()
        unresolved: set[str] = set()
        for net in paddr_connections(instance):
            cells, inputs, missing = graph.backward_sources(net)
            owners.update(cells)
            input_owners.update(inputs)
            unresolved.update(missing)
        require(not input_owners,
                f"{label} fast paddr still has live module-input owner: {sorted(input_owners)}")
        require(not unresolved,
                f"{label} fast paddr has unresolved mapped owner: {sorted(unresolved)}")
        require(owners and owners <= lookup_cells,
                f"{label} fast paddr is not lookup_exec_paddr_q-only: "
                f"owner_kinds={sorted({graph.cell_state_kind(cell) for cell in owners})}")
        require(not (owners & pc_cells), f"{label} retained pc_q -> fast PMP same-cycle ownership")
        source_counts[label] = len(owners)

    return {
        "lookup_exec_paddr_q_flops": len(lookup_cells),
        "pc_q_flops": len(pc_cells),
        "pmp0_paddr_q_owners": source_counts["pmp0"],
        "pmp1_paddr_q_owners": source_counts["pmp1"],
    }


ROB_COMMIT_BASES = (
    "commit0_valid_o", "commit0_pc_o", "commit0_next_pc_o", "commit0_inst_o",
    "commit0_rd_en_o", "commit0_is_fp_rd_o", "commit0_fflags_o",
    "commit0_arch_rd_o", "commit0_old_pdest_o", "commit0_new_pdest_o",
    "commit0_data_o", "commit0_exception_o", "commit0_cause_o", "commit0_tval_o",
    "commit1_valid_o", "commit1_pc_o", "commit1_next_pc_o", "commit1_inst_o",
    "commit1_rd_en_o", "commit1_is_fp_rd_o", "commit1_fflags_o",
    "commit1_arch_rd_o", "commit1_old_pdest_o", "commit1_new_pdest_o",
    "commit1_data_o", "commit1_exception_o", "commit1_cause_o", "commit1_tval_o",
)


def input_group(module: Module, base: str) -> set[str]:
    return {port for port in module.inputs if exact_bit_port(port, base)}


def audit_rob(graph: ConnectivityGraph) -> dict[str, object]:
    commit_outputs = {
        port for port in graph.module.outputs
        if any(exact_bit_port(port, base) for base in ROB_COMMIT_BASES)
    }
    require(len(commit_outputs) >= 400,
            f"ROB commit payload/output set unexpectedly small: {len(commit_outputs)}")
    wb_input_owners: set[str] = set()
    sequential_owners: set[str] = set()
    unresolved_outputs: set[str] = set()
    for output in commit_outputs:
        cells, inputs, unresolved = graph.backward_sources(output)
        sequential_owners.update(cells)
        wb_input_owners.update(port for port in inputs if port.startswith(("wb0_", "wb1_")))
        unresolved_outputs.update(unresolved)
    require(not wb_input_owners,
            f"WB input still owns commit valid/payload combinationally: {sorted(wb_input_owners)}")
    require(not unresolved_outputs,
            f"ROB commit outputs have unresolved mapped owners: {sorted(unresolved_outputs)[:16]}")
    require(sequential_owners, "ROB commit output audit is vacuous: no Q owner found")

    payload_groups = {
        "data": (input_group(graph.module, "wb0_data_i") |
                 input_group(graph.module, "wb1_data_i")),
        "exception": (input_group(graph.module, "wb0_exception_i") |
                      input_group(graph.module, "wb1_exception_i")),
        "cause": (input_group(graph.module, "wb0_cause_i") |
                  input_group(graph.module, "wb1_cause_i")),
        "tval": (input_group(graph.module, "wb0_tval_i") |
                 input_group(graph.module, "wb1_tval_i")),
        "fflags": (input_group(graph.module, "wb0_fflags_i") |
                   input_group(graph.module, "wb1_fflags_i")),
    }
    endpoint_counts: dict[str, int] = {}
    for expected_kind, inputs in payload_groups.items():
        require(inputs, f"missing mapped WB {expected_kind} inputs")
        d_cells, outputs, _dead = graph.forward_sinks(inputs)
        require(not (outputs & commit_outputs),
                f"WB {expected_kind} reaches commit output: {sorted(outputs & commit_outputs)}")
        require(d_cells, f"WB {expected_kind} no longer reaches ROB state D (vacuous isolation)")
        kinds = {graph.cell_state_kind(cell) for cell in d_cells}
        require(kinds == {expected_kind},
                f"WB {expected_kind} reaches unexpected ROB state D kinds: {sorted(kinds)}")
        endpoint_counts[expected_kind] = len(d_cells)

    all_wb_inputs = {port for port in graph.module.inputs
                     if port.startswith(("wb0_", "wb1_"))}
    _d_cells, all_outputs, _dead = graph.forward_sinks(all_wb_inputs)
    require(not (all_outputs & commit_outputs),
            f"some WB input reaches commit output: {sorted(all_outputs & commit_outputs)}")

    return {
        "commit_output_bits": len(commit_outputs),
        "commit_sequential_owner_flops": len(sequential_owners),
        "wb_completion_d_endpoints": endpoint_counts,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--std-lib", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--object-manifest-out", type=Path, required=True)
    args = parser.parse_args()
    require(args.netlist.is_file() and args.netlist.stat().st_size > 1_000_000,
            f"invalid/incomplete fresh netlist: {args.netlist}")
    require(args.std_lib.is_file() and args.std_lib.stat().st_size > 1_000_000,
            f"invalid standard-cell Liberty: {args.std_lib}")

    modules, all_module_names = load_required_modules(args.netlist)
    wanted_types = used_cell_types(modules.values(), all_module_names)
    directions = load_liberty_directions(args.std_lib, wanted_types)
    fifo_graph = ConnectivityGraph(modules["fifo"], directions, all_module_names,
                                   allow_hierarchy=False)
    rob_graph = ConnectivityGraph(modules["rob"], directions, all_module_names,
                                  allow_hierarchy=False)
    ifu_graph = ConnectivityGraph(modules["ifu"], directions, all_module_names,
                                  allow_hierarchy=True)

    fifo_result, fifo_shadow_cells = audit_fifo(fifo_graph)
    args.object_manifest_out.parent.mkdir(parents=True, exist_ok=True)
    args.object_manifest_out.write_text(
        "".join(f"fifo_shadow_cell {cell}\n" for cell in fifo_shadow_cells)
    )
    result = {
        "status": "PASS",
        "netlist": str(args.netlist.resolve()),
        "netlist_sha256": sha256(args.netlist),
        "std_lib_sha256": sha256(args.std_lib),
        "mapped_cell_types": len(wanted_types),
        "fifo": fifo_result,
        "ifu": audit_ifu(ifu_graph),
        "rob": audit_rob(rob_graph),
        "ifu_skipped_hierarchical_instances": sorted(ifu_graph.skipped_hierarchy),
        "object_manifest": str(args.object_manifest_out.resolve()),
        "object_manifest_sha256": sha256(args.object_manifest_out),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("[T3W-FRESH-NETLIST-STRUCTURAL] PASS")


if __name__ == "__main__":
    try:
        main()
    except AuditError as error:
        raise SystemExit(f"[T3W-FRESH-NETLIST-STRUCTURAL] FAIL: {error}")
