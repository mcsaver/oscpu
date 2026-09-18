#!/usr/bin/env python3
"""Independent timing invariants and rejection tests for the performance model."""
import argparse
import csv
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

HEADER=struct.Struct("<8sQQ")
RECORD=struct.Struct("<QQQQQII")
def addi(rd,rs=0,imm=1):
    return ((imm&4095)<<20)|(rs<<15)|(rd<<7)|0x13
def reg(f7,rs2,rs1,f3,rd):
    return f7<<25|rs2<<20|rs1<<15|f3<<12|rd<<7|0x33

class TimingTests(unittest.TestCase):
    def simulate(self,raws,config=(),addresses=None,operands=None):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory);trace=path/"trace"
            with trace.open("wb") as f:
                f.write(HEADER.pack(b"R64TRC1\0",len(raws),1))
                for n,raw in enumerate(raws):
                    a,b=operands[n] if operands else (0,0)
                    f.write(RECORD.pack(0x80000000+n*4,0x80000004+n*4,
                                        addresses[n] if addresses else 0,a,b,raw,0))
            cmd=[str(BUILD/"r64-model"),str(trace),"--stages",str(path/"stages")]
            for entry in config:cmd+=["--set",entry]
            run=subprocess.run(cmd,capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stderr)
            result=json.loads(run.stdout)
            with (path/"stages").open() as stream:
                stages=list(csv.DictReader(stream))
            self.assertEqual(result["instructions"],len(raws))
            events=result["events"]
            self.assertEqual(sum(events.get(f"retire_{i}",0) for i in range(3)),result["cycles"])
            capacity=result["config"]["commit_width"]*result["cycles"]
            self.assertEqual(sum(result["unused_retire_slots"].values())+len(raws),capacity)
            retires=[int(x["retire"]) for x in stages]
            self.assertEqual(retires,sorted(retires))
            for row in stages:
                values=[int(row[k]) for k in ("fetch","dispatch","issue","execute","result","wb","retire")]
                self.assertEqual(values,sorted(values))
            return result,stages

    def test_dependency_and_x0(self):
        independent,_=self.simulate([addi(5)]*256)
        chain,_=self.simulate([addi(5,5)]*256)
        zero,_=self.simulate([addi(0,0)]*256)
        self.assertGreater(chain["cycles"],independent["cycles"]*1.5)
        self.assertLessEqual(zero["cycles"],independent["cycles"])

    def test_writeback_width(self):
        raws=[addi(5)]*512
        two,_=self.simulate(raws)
        one,_=self.simulate(raws,["wb_width=1"])
        self.assertGreater(one["cycles"],two["cycles"])

    def test_early_wakeup_changes_dependency_chain(self):
        raws=[addi(5,5)]*256
        enabled,_=self.simulate(raws)
        disabled,_=self.simulate(raws,["early_alu_wake=0"])
        self.assertGreater(disabled["cycles"],enabled["cycles"])

    def test_same_bundle_raw_dependency(self):
        _,rows=self.simulate([addi(5),addi(6,5),addi(7,6)])
        self.assertGreater(int(rows[1]["issue"]),int(rows[0]["execute"]))
        self.assertGreater(int(rows[2]["issue"]),int(rows[1]["execute"]))

    def test_store_waits_for_head_but_load_can_forward(self):
        div=reg(1,2,1,4,3)
        store=(6<<20)|(5<<15)|(3<<12)|0x23
        load=(5<<15)|(3<<12)|(7<<7)|3
        result,rows=self.simulate([div,store,load],
             addresses=[0,0x80002000,0x80002000],operands=[(1<<60,3),(0,0),(0,0)])
        self.assertGreater(int(rows[1]["result"]),int(rows[0]["retire"]))
        self.assertLess(int(rows[2]["result"]),int(rows[1]["result"]))
        self.assertEqual(result["events"].get("forwarded_loads"),1)

    def test_wb_hint_reduces_load_completion_wait(self):
        load=(5<<15)|(3<<12)|(5<<7)|3
        args=([load]*64,)
        enabled,_=self.simulate(*args,addresses=[0x80002000]*64)
        disabled,_=self.simulate(*args,config=["wb_request_hints=0"],addresses=[0x80002000]*64)
        self.assertGreater(disabled["cycles"],enabled["cycles"])

    def test_changed_alu_latency_preserves_data_availability(self):
        _,rows=self.simulate([addi(5,5)]*16,["alu_latency=6"])
        for producer,consumer in zip(rows,rows[1:]):
            self.assertGreaterEqual(int(consumer["execute"]),int(producer["result"]))

    def test_invalid_inputs_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/"bad";path.write_bytes(b"bad")
            result=subprocess.run([str(BUILD/"r64-model"),str(path)],capture_output=True)
            self.assertNotEqual(result.returncode,0)

    def test_unsupported_opcode_rejected(self):
        with self.assertRaises(AssertionError):
            self.simulate([0x0000002f])

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--build",type=Path,required=True)
    args,remaining=p.parse_known_args();BUILD=args.build.resolve()
    unittest.main(argv=["test_model.py",*remaining])
