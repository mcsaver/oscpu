#!/usr/bin/env python3
"""Check post-edge observations using the actual CXXRTL runtime, without a full core build."""
from pathlib import Path
import subprocess
import tempfile
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cxxrtl_native import specialize_native_checks
from build_cxxrtl import compile_split

ROOT=Path(__file__).resolve().parents[4]
YOSYS=ROOT/"oss-cad-suite/bin/yosys"
RUNTIME=ROOT/"oss-cad-suite/share/yosys/include/backends/cxxrtl/runtime"
SOURCE=ROOT/"npc/rv64/model/src"
RTL="""module probe(input clk, input rst, input [63:0] data, input bad,
 output reg [63:0] q, output [63:0] twice);
 always @(posedge clk) if(rst) q<=0; else q<=q+data;
 assign twice=q<<1;
 always @(posedge clk) if(!rst) assert(!bad);
endmodule
"""
CPP=r'''#include "probe.h"
#include "cxxrtl_settle.hpp"
#include <cassert>
int main(int argc, char **) {
 cxxrtl_design::p_probe d;
 d.p_rst.set<bool>(true); d.p_clk.set<bool>(false); r64model::settle(d);
 d.p_clk.set<bool>(true); r64model::settle(d);
 assert(d.p_q.get<uint64_t>()==0 && d.p_twice.get<uint64_t>()==0);
 d.p_rst.set<bool>(false); d.p_data.set<uint64_t>(1);
 d.p_bad.set<bool>(argc > 1);
 for(uint64_t i=1;i<5;i++) {
  d.p_clk.set<bool>(false); r64model::settle(d);
  d.p_clk.set<bool>(true); r64model::settle(d);
  assert(d.p_q.get<uint64_t>()==i && d.p_twice.get<uint64_t>()==2*i);
  r64model::settle(d);
  assert(d.p_q.get<uint64_t>()==i && d.p_twice.get<uint64_t>()==2*i);
 }
}
'''

def main():
    with tempfile.TemporaryDirectory(prefix="r64-cxxrtl-test-") as name:
        out=Path(name)
        (out/"probe.v").write_text(RTL)
        (out/"test.cpp").write_text(CPP)
        script=f"read_verilog -formal {out/'probe.v'}; hierarchy -top probe; write_cxxrtl -header -O6 -g0 {out/'probe.cc'}"
        subprocess.run([str(YOSYS),"-Q","-T","-p",script],check=True,capture_output=True)
        generated=(out/"probe.cc").read_text()
        for native in (False,True):
            (out/"probe.cc").write_text(specialize_native_checks(generated) if native else generated)
            command=["g++","-O1","-std=c++17","-I"+str(RUNTIME),"-I"+str(SOURCE),"-I"+str(out)]
            if native:
                (out/"model.cc").write_text(generated)
                (out/"main.cpp").write_text(CPP)
                compile_split(out,command,2,1)
                binary=out/"r64-cxxrtl"
                assert not list((out/"compile-parts").glob("*.cc"))
                assert not list((out/"compile-parts").glob("*.o"))
            else:
                binary=out/"test"
                subprocess.run(command+[str(out/"test.cpp"),str(out/"probe.cc"),
                                        "-o",str(binary)],check=True)
            subprocess.run([str(binary)],check=True)
            negative=subprocess.run(["prlimit","--core=0","--",str(binary),"--bad"],
                                    capture_output=True)
            assert negative.returncode != 0, "RTL assertion was lost"
            assert b"Check failed" in negative.stderr, negative.stderr
        try:
            compile_split(out,["false"],2,1)
        except RuntimeError:
            assert not list((out/"compile-parts").glob("*.cc"))
            assert not list((out/"compile-parts").glob("*.o"))
        else:
            raise AssertionError("failing compiler was not rejected")
    print("CXXRTL post-edge observations, single-edge updates retained RTL assertions and compiler cleanup: PASS")

if __name__=="__main__":
    main()
