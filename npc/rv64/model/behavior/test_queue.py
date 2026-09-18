#!/usr/bin/env python3
"""Compare all queue ports and retained state with unmodified production RTL."""
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
sys.dont_write_bytecode=True
from always_ir import *
from lsu_queue import request_queue
from test_always import ROOT, command

def rtl_run(model,cases,directory,expect_failure=False):
    out=Path(directory)
    ins=list(model.inputs);outs=list(model.outputs);states=list(model.states)
    lines=["module tb;","reg clk_i=0;"]
    lines += [f"reg [{w-1}:0] {n};" for n,w in model.inputs.items()]
    lines += [f"wire [{model.outputs[n].width-1}:0] {n};" for n in outs]
    params=",".join(f".{k}({v})" for k,v in model.parameters.items())
    lines += [f"R64LsuRequestQueue #({params}) d(.*);","integer f,r,cycle;","initial begin"]
    # Explicit two-state starting point, including storage not reset by RTL.
    lines += [f"d.{model.rtl_state_paths[n]}='0;" for n in states]
    input_file=out/"input.txt"
    input_file.write_text("\n".join(" ".join(f"{c[n]:x}" for n in ins) for c in cases)+"\n")
    lines += [f'cycle=0;f=$fopen("{input_file}","r");','while(!$feof(f))begin',
              'r=$fscanf(f,"'+" ".join("%h" for _ in ins)+'",'+",".join(ins)+");",
              f"if(r=={len(ins)})begin","clk_i=0;#1;"]
    observations=outs+["d."+model.rtl_state_paths[n] for n in states]
    display='$display("'+" ".join("%h" for _ in observations)+'",'+",".join(observations)+");"
    lines += [display,"clk_i=1;#1;",display,"cycle=cycle+1;end end","$finish;end endmodule"]
    (out/"tb.sv").write_text("\n".join(lines)+"\n")
    command(["iverilog","-g2012","-DR64_ASSERT","-s","tb","-o",out/"sim",out/"tb.sv",
             ROOT/"npc/rv64/vsrc/chengyue64/lsu/R64LsuRequestQueue.v"])
    result=subprocess.run(["vvp",str(out/"sim")],capture_output=True,text=True,timeout=60)
    if expect_failure:
        if result.returncode==0 or "FATAL:" not in result.stdout:
            raise AssertionError("original RTL did not reject invalid input")
        return result.stdout
    if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    return [tuple(int(x,16) for x in line.split()) for line in result.stdout.splitlines() if "$finish" not in line]

def sequence(model,cycles=1500,seed=831):
    rng=random.Random(seed);cases=[];expected=[]
    p=model.parameters;dw=p["DATA_W"];tw=p["TAG_W"];aw=p["AGE_W"]
    order=[b.name for b in model.blocks if b.kind=="posedge"]
    coverage={k:0 for k in ("push","pop","push_pop","full","stall","cancel","flush","age_clear","unpublished_capture")}
    for cycle in range(cycles):
        row={n:rng.getrandbits(w) for n,w in model.inputs.items()}
        row.update(rst_i=int(cycle==0 or cycle%149==0),flush_i=int(cycle>0 and rng.randrange(31)==0),
                   cancel_active_i=int(rng.randrange(5)==0),in_fire_i=0)
        candidates=row["cancel_candidates_i"] if row["cancel_active_i"] else 0
        row["kill_mask_i"]=candidates
        # First fill, stall, then exercise a pop and simultaneous pop/push.
        if 1<=cycle<=6:
            row.update(rst_i=0,flush_i=0,cancel_active_i=0,kill_mask_i=0,cancel_candidates_i=0,
                       out_ready_i=3 if cycle>=4 else 0,age_clear_i=0)
        if cycle==7:row.update(rst_i=0,flush_i=1,in_fire_i=0)
        if cycle==8:row.update(rst_i=0,flush_i=0,kill_mask_i=0,cancel_active_i=0,out_ready_i=0)
        before=model.observe(row)
        want=3 if 1<=cycle<=6 else (0 if cycle==8 else rng.randrange(4))
        row["in_fire_i"]=want&before["in_ready_o"]
        pre=model.observe(row)
        fire=row["in_fire_i"];pop=pre["out_valid_o"]&row["out_ready_i"]
        coverage["push"]+=fire.bit_count();coverage["pop"]+=pop.bit_count()
        coverage["push_pop"]+=(fire&pop).bit_count()
        coverage["full"]+=sum(model.state[f"valid_q{lane}"]==3 for lane in range(2))
        coverage["stall"]+=(pre["out_valid_o"]&~row["out_ready_i"]&3).bit_count()
        coverage["cancel"]+=int(bool(row["kill_mask_i"]&pre["reuse_block_o"]))
        coverage["flush"]+=int(bool(row["flush_i"] and pre["out_occupied_o"]))
        coverage["age_clear"]+=int(bool(row["age_clear_i"]&pre["held_age_o"]))
        coverage["unpublished_capture"]+=sum(not (fire>>lane&1) and model.state[f"valid_q{lane}"]!=3 and not row["rst_i"] for lane in range(2))
        def sample(outputs):return tuple(outputs.values())+tuple(model.state.values())
        expected.append(sample(pre));rng.shuffle(order)
        patches=model.prepare(row,order=order);rng.shuffle(patches);model.commit(patches)
        expected.append(sample(model.observe(row)));cases.append(row)
    if not all(coverage.values()):raise AssertionError("missing directed/random coverage: "+str(coverage))
    return cases,expected,coverage

class QueueTest(unittest.TestCase):
    def test_real_queue_all_ports_and_state(self):
        configs=[{},{"prepared_cancel":True,"age_w":32},
                 {"data_w":193,"tag_w":12,"rob_w":6,"age_w":7},
                 {"data_w":1,"tag_w":9,"rob_w":3,"age_w":1,"prepared_cancel":True}]
        for index,config in enumerate(configs):
            with self.subTest(config=config),tempfile.TemporaryDirectory(prefix="r64-queue-behavior-") as directory:
                m=request_queue(**config)
                cases,expected,coverage=sequence(m,seed=831+index)
                reference=rtl_run(m,cases,directory)
                self.assertEqual(len(reference),3000)
                for cycle,(a,b) in enumerate(zip(reference,expected)):
                    self.assertEqual(a,b,(config,cycle//2,"post" if cycle%2 else "pre"))
                print("QUEUE_COVERAGE "+json.dumps({"parameters":m.parameters,"cycles":len(cases),"coverage":coverage}),flush=True)

    def test_credit_failure_is_preserved(self):
        for prepared in (False,True):
            m=request_queue(prepared_cancel=prepared)
            row={n:0 for n in m.inputs};row["rst_i"]=1
            rows=[dict(row)];m.step(row);row.update(rst_i=0,in_fire_i=3)
            for _ in range(2):rows.append(dict(row));m.step(row)
            rows.append(dict(row))
            with self.assertRaisesRegex(AssertionError,"credit violation"):m.prepare(row)
            with tempfile.TemporaryDirectory(prefix="r64-queue-negative-") as directory:
                self.assertIn("credit violation",rtl_run(m,rows,directory,True))

    def test_prepared_cancel_failure_is_preserved(self):
        m=request_queue(prepared_cancel=True)
        row={n:0 for n in m.inputs};row["rst_i"]=1;rows=[dict(row)];m.step(row)
        row.update(rst_i=0,kill_mask_i=1,cancel_active_i=0);rows.append(dict(row))
        with self.assertRaisesRegex(AssertionError,"prepared cancel"):m.prepare(row)
        with tempfile.TemporaryDirectory(prefix="r64-cancel-negative-") as directory:
            self.assertIn("prepared cancel differs",rtl_run(m,rows,directory,True))

class ExtendedBehaviorTest(unittest.TestCase):
    def test_dynamic_nba_address_is_sampled_before_local_changes(self):
        m=Model("index",{},{"q":130},{"comb":130},[
            Block("view","comb",(blocking("comb",ref("q",130)),
                blocking("comb",const(0x1ff,9),low=const(125,8),width=9))),
            Block("edge","posedge",(blocking("index",const(63,8)),
                nba("q",const(0x1ff,9),low=ref("index",8),width=9),
                blocking("index",const(2,8)),
                nba("q",const(0,3),low=const(66,8),width=3)),locals={"index":8})])
        expected=(0x1ff<<63)&~(7<<66)
        self.assertEqual(m.step({})["q"],expected)
        self.assertEqual(m.snapshot({})["comb"],expected|(31<<125))

    def test_dynamic_write_and_shift_out_of_range(self):
        m=Model("oor",{"index":16},{"q":9},{},[
            Block("edge","posedge",(nba("q",const(7,3),low=ref("index",16),width=3),))],initial={"q":1})
        self.assertEqual(m.step({"index":65535})["q"],1)
        self.assertEqual(m.evaluate(shl(const(1,9),const(65535,16)),{}),0)
        self.assertEqual(m.evaluate(indexed(const(511,9),const(65535,16)),{}),0)
        with self.assertRaisesRegex(ValueError,"whole-value initialization"):
            Model("partial",{},{"q":1},{"w":9},[
                Block("comb","comb",(blocking("w",const(1),low=const(1,3),width=1),)),
                Block("edge","posedge",(nba("q",const(0)),))])

if __name__=="__main__":unittest.main(verbosity=2)
