#!/usr/bin/env python3
"""Emit a bounded protocol network from one unsigned transition IR."""
import argparse
import json
from pathlib import Path
from semantics import build

OPS = {"and":"&", "or":"|", "add":"+", "sub":"-", "eq":"==", "lt":"<"}


def mask(width):
    return (1 << width) - 1


def cpp_expr(e, ir):
    if e.op == "const":
        return f"UINT64_C({e.value})"
    if e.op == "ref":
        return ("state." if e.value in ir.regs else "") + e.value
    a = [cpp_expr(x, ir) for x in e.args]
    if e.op == "mux":
        value = f"({a[0]} ? {a[1]} : {a[2]})"
    elif e.op == "not":
        value = f"(~{a[0]})"
    elif e.op == "resize":
        value = a[0]
    else:
        value = f"({a[0]} {OPS[e.op]} {a[1]})"
    return f"({value} & UINT64_C({mask(e.width)}))"


def verilog_expr(e):
    if e.op == "const":
        return f"{e.width}'d{e.value}"
    if e.op == "ref":
        return e.value
    a = [verilog_expr(x) for x in e.args]
    if e.op == "mux":
        return f"({a[0]} ? {a[1]} : {a[2]})"
    if e.op == "not":
        return f"(~{a[0]})"
    if e.op == "resize":
        old = e.args[0].width
        if e.width > old:
            return "{" + f"{e.width-old}'d0, {a[0]}" + "}"
        return f"{a[0]}[{e.width-1}:0]"
    return f"({a[0]} {OPS[e.op]} {a[1]})"


def vrange(width):
    return "" if width == 1 else f"[{width-1}:0] "


def emit(cfg, directory):
    ir, layout = build(cfg)
    order = ir.validate()
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    types = ["#pragma once", "#include <array>", "#include <cstdint>", "namespace net {",
             f"constexpr unsigned N={layout['n']}, M={layout['m']}, CANCEL_PORTS={layout['cancel_ports']};",
             f"constexpr uint64_t OWNER_MASK=UINT64_C({mask(layout['owner_bits'])}), DATA_MASK=UINT64_C({mask(layout['payload_bits'])});",
             f"using Inputs=std::array<uint64_t,{len(ir.inputs)}>;",
             f"using Outputs=std::array<uint64_t,{len(ir.outputs)}>;"]
    for prefix, fields in (("I", ir.inputs), ("O", ir.outputs)):
        for i, name in enumerate(fields):
            types.append(f"constexpr unsigned {prefix}_{name}={i};")
    for label, prefix, names in (
        ("SRC_OFFER", "I", [f"src{i}_offer" for i in range(layout["n"])]),
        ("SRC_OWNER", "I", [f"src{i}_owner" for i in range(layout["n"])]),
        ("SRC_DATA", "I", [f"src{i}_data" for i in range(layout["n"])]),
        ("SINK_READY", "I", [f"sink{i}_ready" for i in range(layout["m"])]),
        ("CANCEL_VALID", "I", [f"cancel{i}_valid" for i in range(layout["cancel_ports"])]),
        ("CANCEL_OWNER", "I", [f"cancel{i}_owner" for i in range(layout["cancel_ports"])]),
        ("IN_FIRE", "O", [f"in{i}_fire" for i in range(layout["n"])]),
    ):
        types.append(f"constexpr std::array<unsigned,{len(names)}> {label}={{{','.join(prefix+'_'+x for x in names)}}};")
    types += ["}", ""]
    (directory/"network_types.hpp").write_text("\n".join(types))
    cpp = ["#pragma once", '#include "network_types.hpp"', "namespace net {", "class Model {",
           "  struct State {"]
    cpp += [f"    uint64_t {name}=0;" for name in ir.regs]
    cpp += ["  } state;", "public:", "  Outputs step(const Inputs& input) {"]
    cpp += [f"    const uint64_t {name}=input[{i}] & UINT64_C({mask(width)});"
            for i,(name,width) in enumerate(ir.inputs.items())]
    # Assertions are evaluated in both engines, outside benchmark-only shortcuts.
    cpp += [f"    const uint64_t {name}={cpp_expr(ir.wires[name],ir)};" for name in order]
    cpp += [f'    if (!({cpp_expr(e,ir)})) throw std::runtime_error("network invariant {i}");'
            for i,e in enumerate(ir.assertions)]
    cpp += ["    Outputs output={" + ",".join(cpp_expr(e,ir) for e in ir.outputs.values()) + "};"]
    cpp += [f"    const uint64_t next_{name}={cpp_expr(ir.next[name],ir)};" for name in ir.regs]
    cpp += [f"    state.{name}=next_{name};" for name in ir.regs]
    cpp += ["    return output;", "  }", "};", "}", ""]
    cpp.insert(2, "#include <stdexcept>")
    (directory/"network_model.hpp").write_text("\n".join(cpp))
    ports = ["  input clk"] + [f"  input {vrange(w)}{name}" for name,w in ir.inputs.items()]
    ports += [f"  output {vrange(e.width)}o_{name}" for name,e in ir.outputs.items()]
    sv = ["// Generated from semantics.py; all next-state reads old registers.",
          "module Network(", ",\n".join(ports), ");"]
    sv += [f"  reg {vrange(width)}{name};" for name,width in ir.regs.items()]
    sv += [f"  wire {vrange(ir.wires[name].width)}{name} = {verilog_expr(ir.wires[name])};" for name in order]
    sv += [f"  assign o_{name} = {verilog_expr(e)};" for name,e in ir.outputs.items()]
    sv += ["  always @(posedge clk) begin"]
    sv += [f"    {name} <= {verilog_expr(ir.next[name])};" for name in ir.regs]
    sv += ["  end", chr(96)+"ifdef R64_ASSERT", "  always @(posedge clk) if (!reset) begin"]
    sv += [f'    if (!({verilog_expr(e)})) $fatal(1, "network invariant {i}");'
           for i,e in enumerate(ir.assertions)]
    sv += ["  end", chr(96)+"endif", "endmodule", ""]
    (directory/"Network.v").write_text("\n".join(sv))
    adapter = ['#pragma once', '#include "VNetwork.h"', '#include "network_types.hpp"',
               "namespace net {", "class Rtl {", "  VNetwork dut;", "public:",
               "  Outputs step(const Inputs& input) {"]
    adapter += [f"    dut.{name}=input[{i}];" for i,name in enumerate(ir.inputs)]
    adapter += ["    dut.clk=0; dut.eval();", "    Outputs output={"+
                ",".join("dut.o_"+name for name in ir.outputs)+"};",
                "    dut.clk=1; dut.eval();", "    return output;", "  }", "};", "}", ""]
    (directory/"network_rtl.hpp").write_text("\n".join(adapter))
    manifest = {"layout":layout,"inputs":list(ir.inputs),"input_widths":list(ir.inputs.values()),
                "outputs":list(ir.outputs),"output_widths":[e.width for e in ir.outputs.values()],
                "registers":len(ir.regs),"combinational_nodes":len(ir.wires)}
    (directory/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    return manifest


if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--config",type=Path,default=Path(__file__).with_name("completion.json"))
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    emit(json.loads(a.config.read_text()),a.out)
