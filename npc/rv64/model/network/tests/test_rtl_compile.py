#!/usr/bin/env python3
"""Independent RTL checks for state, memory, wide arithmetic and edge sampling."""
import json
import os
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
sys.dont_write_bytecode=True
NETWORK=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(NETWORK))
from rtl_compile import Compiler
from parallel_compile import ParallelCompiler
ROOT=NETWORK.parents[3]
RTL=r"""
module R64SystemTestTop(
 input clk_i, input rst_i, input bad, input [63:0] a,b,
 input signed [7:0] amount, input [1:0] address, other, input [7:0] mask_i,
 output reg [63:0] q, old_a, old_b, old_c, priority_o, temporary_o, output [64:0] sum_o, output [63:0] left_o,right_o,
 output [63:0] slice_o, output signed [63:0] arithmetic_o,
 output [63:0] read_o, output [63:0] next_o, output [3:0] compare_o);
 reg [63:0] mem[0:3];
 integer i;
 reg [63:0] temporary;
 always @(posedge clk_i) begin
  if(rst_i) begin old_a<=5;old_b<=10;priority_o<=0;temporary_o<=0;end
  else begin
   if(mask_i[0]) begin old_a<=old_a+1;old_b<=old_a;end
   if(mask_i[0]) priority_o<=priority_o+1;
   if(mask_i[1]) priority_o<=priority_o-1;
   temporary=a+b;temporary_o<=temporary^q;
  end
 end
 always @(posedge clk_i) begin
  if(rst_i)old_c<=0;
  else if(mask_i[0])old_c<=old_b+2;
 end
 always @(posedge clk_i) begin
  if(rst_i) begin q<=0;for(i=0;i<4;i=i+1)mem[i]<=0;end
  else begin
   q<=q+a;
   mem[address]<=a;
   for(i=0;i<8;i=i+1) if(mask_i[i])mem[other][i*8+:8]<=b[i*8+:8];
  end
  if(!rst_i) assert(!bad);
 end
 always @(negedge clk_i) if(!rst_i) assert(!bad);
 assign sum_o={1'b0,a}+{1'b0,b};
 assign left_o=a<<amount;
 assign right_o=a>>amount;
 assign arithmetic_o=$signed(a)>>>amount;
 wire [191:0] packet={a,q,b};
 assign slice_o=packet[amount+:64];
 assign read_o=mem[address];
 assign next_o=q+b;
 assign compare_o={a<b,$signed(a)<$signed(b),a==b,a!=b};
endmodule
"""

def execute(argv, **kwargs):
    result=subprocess.run([str(x) for x in argv],capture_output=True,text=True,**kwargs)
    if result.returncode:raise RuntimeError(result.stderr or result.stdout)
    return result

class LoweringTest(unittest.TestCase):
    thread_counts=(1,)
    def compiler(self,module):return Compiler(module)

    def test_against_icarus(self):
        with tempfile.TemporaryDirectory(prefix="r64-word-network-") as directory:
            out=Path(directory);(out/"probe.sv").write_text(RTL)
            script=f"read_slang --top R64SystemTestTop --no-synthesis-define --no-default-translate-off-format {out/'probe.sv'}; opt; memory_collect; write_json {out/'design.json'}"
            execute([ROOT/"oss-cad-suite/bin/yosys","-Q","-T","-m","slang","-p",script])
            module=json.loads((out/"design.json").read_text())["modules"]["R64SystemTestTop"]
            report=self.compiler(module).emit(out,group_size=3)
            inputs=[n for n,p in module["ports"].items() if p["direction"]=="input" and n!="clk_i"]
            outputs=[n for n,p in module["ports"].items() if p["direction"]=="output"]
            ports=module["ports"]
            rng=random.Random(9017)
            cases=[]
            for cycle in range(500):
                values={"rst_i":int(cycle<2 or cycle%73==0),"bad":0,"a":rng.getrandbits(64),"b":rng.getrandbits(64),
                        "amount":rng.choice([0,1,31,32,63,64,65,127,128,193,255]),
                        "address":rng.randrange(4),"other":rng.randrange(4),"mask_i":rng.getrandbits(8)}
                cases.append(" ".join(str(values[n]) for n in inputs))
            (out/"input.txt").write_text("\n".join(cases)+"\n")
            setup="\n".join(f"d.{n}=uint64_t(x[{k}]);" for k,n in enumerate(inputs))
            writes=[]
            for n in outputs:
                w=len(ports[n]["bits"])
                if w<=64:writes.append(f' std::cout << " " << uint64_t(d.{n});')
                else:
                    for k in range(0,w,32):writes.append(f' std::cout << " " << uint64_t(d.{n}[{k//32}]);')
            cpp='#include "model.h"\n#include <iostream>\n#include <fstream>\nint main(int argc,char**argv){NetworkDut d;std::ifstream in(argv[1]);uint64_t x['+str(len(inputs))+'];unsigned cycle=0;'
            cpp+='while(in>>x[0]){for(unsigned i=1;i<'+str(len(inputs))+';i++)in>>x[i];'+setup
            cpp+='for(int clk=0;clk<2;clk++){d.clk_i=clk;d.eval();if(cycle || clk){'
            cpp+=''.join(writes)+'std::cout<<"\\n";}}cycle++;}'
            cpp+='if(argc>2){d.rst_i=0;if(argv[2][0]==114){d.clk_i=0;d.eval();d.clk_i=1;}else d.clk_i=0;d.bad=1;try{d.eval();}catch(const std::exception&){return 7;}return 0;}return 0;}\n'
            (out/"test.cpp").write_text(cpp)
            execute(["g++","-std=c++17","-O1","-fsanitize=undefined","-fno-sanitize-recover=all","-pthread","-I"+str(NETWORK),"-I"+str(out),
                     *[out/x for x in report["sources"]],out/"test.cpp","-o",out/"probe"])
            decl=[]
            for n,p in ports.items():
                kind="reg" if p["direction"]=="input" else "wire"
                decl.append(f"{kind} [{len(p['bits'])-1}:0] {n};")
            reads='r=$fscanf(f,"'+" ".join("%d" for _ in inputs)+'",'+",".join(inputs)+");"
            displays=[]
            for n in outputs:
                w=len(ports[n]["bits"])
                if w<=64:displays.append(f'$write(" %0d",{{1\\\'b0,{n}}});')
                else:
                    for k in range(0,w,32):
                        hi=min(w-1,k+31)
                        displays.append(f'$write(" %0d",{{1\\\'b0,{n}[{hi}:{k}]}});')
            display="".join(displays)+'$write("\\n");'
            tb="module tb;\n"+"\n".join(decl)+"\nR64SystemTestTop d("+",".join(f".{n}({n})" for n in ports)+");\n"
            tb+='integer f,r,cycle;initial begin clk_i=0;cycle=0;f=$fopen("'+str(out/"input.txt")+'","r");'
            tb+='while(!$feof(f))begin '+reads+f"if(r=={len(inputs)})begin clk_i=0;#1;if(cycle>0)begin {display} end clk_i=1;#1;{display} cycle=cycle+1;end end $finish;end endmodule\n"
            tb=tb.replace("\\'","'")
            (out/"tb.sv").write_text(tb)
            execute(["iverilog","-g2012","-s","tb","-o",out/"rtl",out/"probe.sv",out/"tb.sv"])
            rtl=execute(["vvp",out/"rtl"]).stdout
            self.assertNotIn("ERROR:",rtl)
            expected=[line.split() for line in rtl.splitlines() if "$finish called" not in line]
            for threads in self.thread_counts:
                env=dict(os.environ,R64_MODEL_THREADS=str(threads))
                native=execute([out/"probe",out/"input.txt"],env=env).stdout
                # Defined four-state outputs must agree; two-state X values
                # cannot establish four-state equivalence.
                actual=[line.split() for line in native.splitlines()]
                self.assertEqual(len(expected),len(actual))
                compared=0
                for index,(ra,rb) in enumerate(zip(expected,actual)):
                    self.assertEqual(len(ra),len(rb))
                    for col,(x,y) in enumerate(zip(ra,rb)):
                        if "x" not in x.lower():
                            self.assertEqual(int(x),int(y),(threads,index,col,x,y))
                            compared+=1
                for edge in ("falling","rising"):
                    negative=subprocess.run([out/"probe",out/"input.txt",edge],capture_output=True,env=env)
                    self.assertEqual(negative.returncode,7,edge+"-edge RTL assertion was lost")
                self.assertGreater(compared,9000)

class ParallelLoweringTest(LoweringTest):
    thread_counts=(1,2,4)
    def compiler(self,module):return ParallelCompiler(module,parallel_min_nodes=1)

class LevelParallelLoweringTest(ParallelLoweringTest):
    thread_counts=(1,4)
    def compiler(self,module):return ParallelCompiler(module,parallel_min_nodes=1,partition_style="levels")

if __name__=="__main__":unittest.main()
