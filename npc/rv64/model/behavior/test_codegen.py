#!/usr/bin/env python3
"""Check generated behavior semantics and CUDA compilation without claiming GPU execution."""
from pathlib import Path
import random
import shutil
import subprocess
import sys
import tempfile
import unittest
sys.dont_write_bytecode=True
from always_ir import *
from counter import counter
from lsu_queue import request_queue
from cuda_codegen import CudaEmitter
from runner_codegen import write_driver
from test_always import command
from test_queue import sequence,rtl_run

HERE=Path(__file__).resolve().parent

def stimulus_text(model,cases):
    rows=[]
    for edge,row in cases:
        words=[str(int(edge=="negedge"))]
        for n,w in model.inputs.items():
            words.extend(f"{(row[n]>>(32*i))&0xffffffff:x}" for i in range((w+31)//32))
        rows.append(" ".join(words))
    return "\n".join(rows)+"\n"

def expected_trace(model,cases):
    model.state=dict(model.initial);result=[]
    for edge,row in cases:
        result.append(tuple(model.observe(row).values())+tuple(model.state.values()))
        model.step(row,edge)
        result.append(tuple(model.observe(row).values())+tuple(model.state.values()))
    return result

def build_host(model,directory):
    write_driver(model,directory)
    exe=Path(directory)/"oracle"
    command(["g++","-x","c++","-std=c++17","-O1","-fsanitize=undefined","-fno-sanitize-recover=all",
             "-I",HERE,Path(directory)/"driver.cu","-o",exe])
    return exe

def run_host(model,exe,cases,negative=False):
    result=subprocess.run([str(exe),"--host-oracle"],input=stimulus_text(model,cases),
                          text=True,capture_output=True,timeout=60)
    if negative:
        if result.returncode!=2:raise AssertionError(result.stderr)
        return result.stderr
    if result.returncode:raise RuntimeError(result.stderr)
    if result.stderr:raise AssertionError(result.stderr)
    return [tuple(int(x,16) for x in row.split()) for row in result.stdout.splitlines()]

def semantics_model():
    # Cross-word part select, >64-bit carry/borrow, very wide indexes, both edges,
    # shared machine-word writers and ordered blocking/NBA self references.
    a=ref("a",130);b=ref("b",130);idx=ref("index",65)
    states={n:130 for n in ("add","sub","and","or","xor","inv","left","slice","mux","cat","local")}
    states.update(compare=2,shared=8,capture=130,negative=130)
    outputs={n:ref(n,w) for n,w in states.items()}
    outputs["comb"]=ref("comb",130)
    blocks=[
        Block("comb","comb",(blocking("comb",a),
            blocking("comb",ref("comb",130),low=idx,width=130))),
        Block("arith","posedge",(
            nba("add",add(a,b)),nba("sub",sub(a,b)),nba("and",band(a,b)),
            nba("or",bor(a,b)),nba("xor",op("xor",130,a,b)),nba("inv",inv(a)),
            nba("left",shl(a,idx)),nba("slice",resize(indexed(a,idx,63),130)),
            nba("mux",mux(eq(a,b),a,b)),
            nba("compare",concat(op("lt",1,a,b),eq(a,b))),
            nba("cat",concat(bit_slice(a,1,65),bit_slice(b,65,65))),
            blocking("tmp",a),blocking("address",resize(idx,65)),
            nba("capture",const(511,9),low=ref("address",65),width=9),
            blocking("address",const(0,65)),
            nba("capture",const(0,3),low=const(66,8),width=3),
            blocking("tmp",ref("tmp",130),low=idx,width=130),
            nba("local",ref("tmp",130)),
        ),locals={"tmp":130,"address":65}),
        Block("lo","posedge",(nba("shared",bit_slice(a,0,4),width=4),)),
        Block("hi","posedge",(nba("shared",bit_slice(b,0,4),low=4,width=4),)),
        Block("neg","negedge",(nba("negative",ref("add",130)),))
    ]
    return Model("semantics",{"a":130,"b":130,"index":65},states,{"comb":130},blocks,outputs)

class CodegenTest(unittest.TestCase):
    def test_generated_integer_and_edge_semantics(self):
        model=semantics_model();rng=random.Random(3209);cases=[]
        indexes=[0,1,31,32,63,64,125,129,130,1<<32,1<<64]
        for cycle in range(400):
            row={"a":rng.getrandbits(130),"b":rng.getrandbits(130),"index":indexes[cycle%len(indexes)]}
            if cycle<8:row.update(a=(1<<130)-1 if cycle%2 else 0,b=1)
            if cycle%13==0:row["b"]=row["a"]
            cases.append(("negedge" if cycle%3==2 else "posedge",row))
        expected=expected_trace(model,cases)
        with tempfile.TemporaryDirectory(prefix="r64-behavior-codegen-") as directory:
            self.assertEqual(run_host(model,build_host(model,directory),cases),expected)

    def test_generated_counter(self):
        model=counter();rng=random.Random(517);cases=[]
        for cycle in range(1000):
            row={n:rng.getrandbits(w) for n,w in model.inputs.items()}
            row.update(rst_i=int(cycle==0 or cycle%79==0),write_i=int(cycle%7==1))
            if cycle%7==1:row["write_value_i"]=((1<<((1+cycle%8)*8))-2)&mask(64)
            cases.append(("posedge",row))
        with tempfile.TemporaryDirectory(prefix="r64-counter-codegen-") as directory:
            self.assertEqual(run_host(model,build_host(model,directory),cases),expected_trace(model,cases))

    def test_generated_queue_against_original_rtl(self):
        # Independently check the compiled wide behavior against the actual RTL,
        # not just against the Python interpreter that supplied its description.
        model=request_queue(data_w=193,age_w=32,prepared_cancel=True)
        rows,expected,_=sequence(model,cycles=700,seed=992)
        with tempfile.TemporaryDirectory(prefix="r64-queue-codegen-") as directory:
            result=run_host(model,build_host(model,directory),[("posedge",r) for r in rows])
            self.assertEqual(result,expected)
            self.assertEqual(result,rtl_run(model,rows,directory))

    def test_generated_check_stops_before_commit(self):
        model=request_queue(prepared_cancel=True)
        row={n:0 for n in model.inputs};row["rst_i"]=1
        rows=[dict(row)];row.update(rst_i=0,in_fire_i=3)
        rows.extend([dict(row) for _ in range(3)])
        with tempfile.TemporaryDirectory(prefix="r64-check-codegen-") as directory:
            message=run_host(model,build_host(model,directory),[("posedge",r) for r in rows],True)
            self.assertIn("cycle 3",message);self.assertIn("phase 1",message)

    @unittest.skipUnless(shutil.which("nvcc"),"CUDA compiler unavailable; GPU compilation not verified")
    def test_cuda_device_compile(self):
        for name,model in (("counter",counter()),("queue",request_queue(data_w=193,age_w=32,prepared_cancel=True)),
                           ("semantics",semantics_model())):
            with self.subTest(model=name),tempfile.TemporaryDirectory(prefix="r64-behavior-cuda-") as directory:
                write_driver(model,directory)
                # Link an actual CUDA driver/kernel. No GPU is queried or execution claimed.
                compiler=["nvcc","-std=c++17","-arch=sm_70","-I",HERE]
                if shutil.which("g++-12"):compiler += ["-ccbin","g++-12"]
                command(compiler+[Path(directory)/"driver.cu","-o",Path(directory)/"cuda-driver"])

if __name__=="__main__":unittest.main(verbosity=2)
