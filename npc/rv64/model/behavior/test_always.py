#!/usr/bin/env python3
"""Independent always semantics tests and real R64Counter/Icarus comparison."""
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
sys.dont_write_bytecode=True
from always_ir import *
from counter import counter
ROOT=Path(__file__).resolve().parents[4]

def command(argv):
    result=subprocess.run([str(x) for x in argv],text=True,capture_output=True,timeout=60)
    if result.returncode:raise RuntimeError(result.stderr or result.stdout)
    return result.stdout

class AlwaysTest(unittest.TestCase):
    def example(self):
        a=ref("a",8);b=ref("b",8);count=ref("count",8);en=ref("en");pop=ref("pop")
        return Model("NBA",{"en":1,"pop":1},{"a":8,"b":8,"c":8,"count":8,"local_result":8},{},[
            Block("ab","posedge",(If(en,(nba("a",add(a,const(1,8))),nba("b",a))),)),
            Block("c","posedge",(If(en,(nba("c",add(b,const(2,8))),)),)),
            Block("priority","posedge",(If(en,(nba("count",add(count,const(1,8))),)),
                                        If(pop,(nba("count",sub(count,const(1,8))),)))),
            Block("temporary","posedge",(blocking("tmp",add(a,b)),nba("local_result",ref("tmp",8)),
                                         blocking("tmp",const(0,8))),locals={"tmp":8})
        ],initial={"a":5,"b":10,"count":9})

    def test_old_state_and_local_order(self):
        m=self.example();old=dict(m.state)
        patches=m.prepare({"en":1,"pop":1})
        self.assertEqual(m.state,old)
        m.commit(patches)
        self.assertEqual(m.state,{"a":6,"b":5,"c":12,"count":8,"local_result":15})

    def test_block_order_and_commit_order(self):
        oracle=self.example().step({"en":1,"pop":1});rng=random.Random(337)
        for _ in range(100):
            m=self.example();order=[b.name for b in m.blocks];rng.shuffle(order)
            writes=m.prepare({"en":1,"pop":1},order=order);rng.shuffle(writes);m.commit(writes)
            self.assertEqual(m.state,oracle)

    def test_hold_and_partial_priority(self):
        m=Model("partial",{"en":1},{"q":8},{},[
            Block("one","posedge",(If(ref("en"),(nba("q",const(0xA5,8)),
                              nba("q",const(3,4),low=0,width=4))),))],initial={"q":0x55})
        self.assertEqual(m.step({"en":0})["q"],0x55)
        self.assertEqual(m.step({"en":1})["q"],0xA3)

    def test_disjoint_writers_and_overlap_rejected(self):
        blocks=[Block("lo","posedge",(nba("q",const(3,4),width=4),)),
                Block("hi","posedge",(nba("q",const(10,4),low=4,width=4),))]
        m=Model("slices",{},{"q":8},{},blocks)
        self.assertEqual(m.step({})["q"],0xA3)
        with self.assertRaisesRegex(ValueError,"overlapping state writers"):
            Model("conflict",{},{"q":8},{},[blocks[0],Block("other","posedge",(nba("q",const(7,8)),))])

    def test_combinational_order(self):
        m=Model("comb",{"x":8},{"q":8},{"w":8,"v":8},[
            Block("consumer","comb",(blocking("v",add(ref("w",8),const(1,8))),)),
            Block("reg","posedge",(nba("q",ref("v",8)),)),
            Block("producer","comb",(blocking("w",ref("x",8)),blocking("w",add(ref("w",8),const(2,8))))),
        ])
        self.assertEqual(m.step({"x":5})["q"],8)
        self.assertEqual([b.name for b in m.comb_order],["producer","consumer"])

    def test_unsupported_races_latches_and_uninitialized_locals(self):
        with self.assertRaisesRegex(ValueError,"blocking writes"):
            Model("blocking-state",{},{"q":8},{},[Block("a","posedge",(blocking("q",const(1,8)),))])
        with self.assertRaisesRegex(ValueError,"uninitialized local"):
            Model("local",{},{"q":8},{},[Block("a","posedge",(nba("q",ref("t",8)),),locals={"t":8})])
        with self.assertRaisesRegex(ValueError,"latch"):
            Model("latch",{"en":1},{"q":8},{"w":8},[
                Block("a","comb",(If(ref("en"),(blocking("w",const(1,8)),)),)),
                Block("b","posedge",(nba("q",ref("w",8)),))])
        with self.assertRaisesRegex(ValueError,"dependency cycle"):
            Model("cycle",{},{"q":8},{"u":8,"v":8},[
                Block("u","comb",(blocking("u",ref("v",8)),)),
                Block("v","comb",(blocking("v",ref("u",8)),)),
                Block("q","posedge",(nba("q",ref("u",8)),))])

    def test_negedge_is_distinct(self):
        m=Model("edges",{},{"a":8,"b":8},{},[
            Block("p","posedge",(nba("a",const(1,8)),)),
            Block("n","negedge",(nba("b",ref("a",8)),))])
        self.assertEqual(m.step({},"negedge"),{"a":0,"b":0})
        self.assertEqual(m.step({},"posedge"),{"a":1,"b":0})
        self.assertEqual(m.step({},"negedge"),{"a":1,"b":1})

    def test_checks_read_old_state(self):
        m=Model("check",{},{"q":1},{},[
            Block("a","posedge",(nba("q",const(1)),Check(eq(ref("q"),const(0)),"old state")))])
        m.step({})
        with self.assertRaises(AssertionError):m.step({})

class CounterTest(unittest.TestCase):
    def test_production_counter(self):
        m=counter();self.assertEqual(sum(b.kind=="posedge" for b in m.blocks),22)
        cases=[{"rst_i":1,"enable_i":1,"increment_i":3,"write_i":1,"write_value_i":(1<<64)-1}]
        # Writes followed by steps around every byte boundary, including full wrap.
        for bank in range(1,9):
            for distance in range(1,5):
                for step in range(4):
                    value=((1<<(bank*8))-distance)&mask(64)
                    cases += [
                        {"rst_i":0,"enable_i":1,"increment_i":3,"write_i":1,"write_value_i":value},
                        {"rst_i":0,"enable_i":1,"increment_i":step,"write_i":0,"write_value_i":0},
                        {"rst_i":0,"enable_i":0,"increment_i":3,"write_i":0,"write_value_i":0},
                    ]
        rng=random.Random(2049)
        while len(cases)<2000:
            cases.append({"rst_i":int(rng.randrange(37)==0),"enable_i":rng.randrange(2),
                          "increment_i":rng.randrange(4),"write_i":int(rng.randrange(7)==0),
                          "write_value_i":rng.getrandbits(64)})
        fields=list(m.inputs)
        with tempfile.TemporaryDirectory(prefix="r64-always-") as directory:
            out=Path(directory);input_file=out/"input.txt"
            input_file.write_text("\n".join(" ".join(f"{row[n]:x}" if n=="write_value_i" else str(row[n]) for n in fields) for row in cases)+"\n")
            # Explicit hierarchical observation checks the cached internal state,
            # not just the architectural counter's final value.
            near="{"+",".join(f"d.g_bank[{b}].near_wrap_q" for b in reversed(range(1,8)))+"}"
            tb=f"""module tb;
reg clk_i=0,rst_i,enable_i,write_i;
reg [1:0] increment_i;
reg [63:0] write_value_i;
wire [63:0] value_o;
wire [20:0] near_debug={near};
R64Counter d(.*);
integer f,r,cycle;
initial begin
 cycle=0;f=$fopen("{input_file}","r");
 while(!$feof(f))begin
  r=$fscanf(f,"%d %d %d %d %h",rst_i,enable_i,increment_i,write_i,write_value_i);
  if(r==5)begin
   clk_i=0;#1;
   if(cycle>0)$display("%h %h",value_o,near_debug);
   clk_i=1;#1;$display("%h %h",value_o,near_debug);
   cycle=cycle+1;
  end
 end
 $finish;
end
endmodule
"""
            (out/"tb.sv").write_text(tb)
            command(["iverilog","-g2012","-s","tb","-o",out/"sim",out/"tb.sv",
                     ROOT/"npc/rv64/vsrc/chengyue64/control/R64Counter.v",
                     ROOT/"npc/rv64/vsrc/chengyue64/control/R64CounterNear.v"])
            rtl=command(["vvp",out/"sim"])
            actual=[]
            order=[b.name for b in m.blocks if b.kind=="posedge"]
            def sample():
                return (m.state["value_o"],sum(m.state[f"near_q{b}"]<<((b-1)*3) for b in range(1,8)))
            for cycle,row in enumerate(cases):
                if cycle:actual.append(sample())
                rng.shuffle(order)
                patches=m.prepare(row,order=order);rng.shuffle(patches);m.commit(patches)
                actual.append(sample())
            reference=[tuple(int(v,16) for v in line.split()) for line in rtl.splitlines() if "$finish" not in line]
            self.assertEqual(len(reference),3999)
            self.assertEqual(reference,actual)
            self.assertEqual(m.state["value_o"],reference[-1][0])

if __name__=="__main__":unittest.main(verbosity=2)
