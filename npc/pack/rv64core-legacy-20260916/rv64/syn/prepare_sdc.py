#!/usr/bin/env python3
"""Enumerate actual mapped top inputs for iEDA's literal-only get_ports."""
import argparse,pathlib,re
p=argparse.ArgumentParser()
for name in ('netlist','template','output'):p.add_argument('--'+name,type=pathlib.Path,required=True)
p.add_argument('--top',required=True)
p.add_argument('--clock',default='clk_i')
p.add_argument('--engine',choices=('ieda','opensta'),default='ieda')
a=p.parse_args()
ports=[];outputs=[];inside=False;found=False
with a.netlist.open() as src:
 for line in src:
  if re.match(r"\s*module\s+"+re.escape(a.top)+r"(?:\s|\()",line):
   inside=True;found=True
  elif inside and re.match(r"\s*endmodule\b",line):break
  elif inside and re.match(r"\s*(input|output)\b",line):
   direction,decl=line.strip().split(None,1)
   decl=decl.removesuffix(';').strip()
   if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_$]*',decl):
    raise SystemExit('expected scalar splitnet input, found '+decl)
   (ports if direction=="input" else outputs).append(decl)
if not found or ports.count(a.clock)!=1 or len(ports)!=len(set(ports)):
 raise SystemExit('missing top, ambiguous clock, or duplicate port')
data=[name for name in ports if name!=a.clock]
if not data:raise SystemExit('empty data input set')
a.output.parent.mkdir(parents=True,exist_ok=True)
template=a.template.read_text()
if a.engine=='opensta':
 # OpenSTA applies a single-clock uncertainty to both polarities and rejects
 # iEDA's required -rise/-fall workaround. Preserve all numeric constraints.
 template=re.sub(r'(?m)^set_clock_uncertainty -(setup|hold) -rise ([^\n]+)\nset_clock_uncertainty -\1 -fall \2$',r'set_clock_uncertainty -\1 \2',template)
a.output.write_text('# Every mapped data input/output; only clock excluded.\nset r64_clock_port {'+a.clock+'}\nset r64_data_input_names {\n  '+'\n  '.join(data)+'\n}\nset r64_data_output_names {\n  '+'\n  '.join(outputs)+'\n}\n'+template)
print('Prepared SDC:',len(data),'data inputs,',len(outputs),'outputs; only',a.clock,'excluded')
