#!/usr/bin/env python3
"""Prepare observation-equivalent RTL copies for word-level model backends.

Only testbench observations and simulator assertion syntax are adapted.
The production source tree is never edited.
"""
from pathlib import Path
import json
import re
import subprocess
from cxxrtl_observation import adapt_checks
ROOT=Path(__file__).resolve().parents[3]

def prepare_sources(out, root=ROOT):
    out=Path(out).resolve()
    out.mkdir(parents=True,exist_ok=True)
    top=root/"npc/rv64/testbench/chengyue64/R64SystemTestTop.sv"
    src=top.read_text()
    # Keep every DUT connection, registered retirement and exact CSR observation.
    # Optional textual debug and occupancy reporting are outside this adapter.
    src=src[:src.index(' always @(posedge clk_i)if(!rst_i&&$test$plusargs')]+ '\nendmodule\n'+chr(96)+'undef R64_SYSTEM_HIER\n'
    snapshot="\n".join(line for line in src.splitlines() if line.startswith(" assign csr_snapshot_o"))
    snapshot=snapshot.replace("csr_snapshot_o","model_snapshot_o")
    snapshot=snapshot.replace(chr(96)+"R64_SYSTEM_HIER.core.csr.","")
    snapshot=snapshot.replace(chr(96)+"R64_SYSTEM_HIER.core.","")
    snapshot=snapshot.replace("trigger_address;","trigger_address_o;")
    src="\n".join(line for line in src.splitlines() if not line.startswith(" assign csr_snapshot_o"))+"\n"
    src=src.replace("  .clk_i(clk_i),","  .model_snapshot_o(csr_snapshot_o),\n  .clk_i(clk_i),",1)
    (out/"R64SystemTestTop.sv").write_text(src)
    files=subprocess.check_output(["make","-s","-C",str(root/"npc/rv64"),"print-synth-rtl"],text=True).split()
    incs=[root/"npc/rv64/vsrc/include",root/"npc/rv64/vsrc/chengyue64/backend",root/"npc/rv64/vsrc/chengyue64/platform"]
    adapted=[]
    assertions=[]
    for name in files:
     f=Path(name)
     data=f.read_text()
     def adapt(m):
      assertions.append({"source":str(f.relative_to(root)),"line":data[:m.start()].count("\n")+1,"message":m.group(1)})
      return "assert (1'b0)"
     data,n=re.subn(r'\$fatal\(\s*1\s*,\s*("(?:[^"\\\\]|\\\\.)*")(?:\s*,[^;]*)?\s*\)',adapt,data)
     if "$fatal" in data:
      print([line for line in data.splitlines() if "$fatal" in line])
      raise RuntimeError("Unsupported fatal form in "+name)
     data=re.sub(r'\$onehot\((\w+)\)',lambda m:"(("+m[1]+"!=0) && (("+m[1]+" & ("+m[1]+"-1'b1))==0))",data)
     if f.name in ("R64Csr.v","R64CoreTop.v","R64SystemTop.v"):
      data=data.replace(" input clk_i,"," output [1727:0] model_snapshot_o,\n input clk_i,",1)
      if f.name=="R64Csr.v":
       data=data.replace("endmodule",snapshot+"\nendmodule")
      elif f.name=="R64CoreTop.v":
       data=data.replace("R64Csr csr(","R64Csr csr(.model_snapshot_o(model_snapshot_o),")
      else:
       data=data.replace("R64CoreTop core(","R64CoreTop core(.model_snapshot_o(model_snapshot_o),")
     if f.name in ("R64Rob.v","R64Rename.v","R64Issue.v","R64RegRead.v","R64Execute.v","R64NumericOwner.v","R64Alu.v"):
      data=re.sub(r'(?m)^module ', '(* keep_hierarchy = 0 *) module ', data)
     data=adapt_checks(data,f.name)
     target=out/"sources"/f.relative_to(root)
     target.parent.mkdir(parents=True,exist_ok=True)
     target.write_text(data)
     adapted.append(str(target))
    # Source-only adaptation, retaining each failure condition and clocking.
    (out/"assertions.json").write_text(json.dumps(assertions,indent=2))
    files=adapted
    return files, incs
