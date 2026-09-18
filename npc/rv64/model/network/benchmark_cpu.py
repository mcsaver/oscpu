#!/usr/bin/env python3
"""Matched complete-program benchmark with the same eval() timer on both engines."""
import argparse
import json
from pathlib import Path
import re
import statistics
import subprocess
import sys
import tempfile
import time
sys.dont_write_bytecode=True
from build_cpu import ROOT
from validate_cpu import image, TERMINAL

def run(binary,program,reference,log,timeout,env=None):
    cmd=[str(binary.resolve()),str(program),str(reference.resolve()),"--maxcycles=2000000"]
    start=time.perf_counter()
    # communicate uses pipe readiness while waiting; unlike wait(timeout), it
    # does not quantize these short processes into polling intervals.
    result=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout,text=True,env=env)
    seconds=time.perf_counter()-start;log.write_text(result.stdout)
    if result.returncode:raise RuntimeError(f"benchmark failed ({result.returncode}): {log}")
    terminal=TERMINAL.findall(result.stdout)
    timing=re.findall(r"R64_ENGINE_TIMING eval_calls=(\d+) eval_nanoseconds=(\d+)",result.stdout)
    if len(terminal)!=1 or len(timing)!=1:raise ValueError(f"missing natural terminal or timing: {log}")
    return {"wall_seconds":seconds,"eval_calls":int(timing[0][0]),
            "eval_seconds":int(timing[0][1])/1e9,"terminal":terminal[0]}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--model",type=Path,required=True);p.add_argument("--rtl",type=Path,required=True)
    p.add_argument("--ref",type=Path,default=ROOT/"nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--cases",default="program,throughput,lsu_contention,backend_network")
    p.add_argument("--samples",type=int,default=3);p.add_argument("--timeout",type=float,default=120)
    args=p.parse_args()
    if args.samples<1:p.error("samples must be positive")
    args.out.mkdir(parents=True,exist_ok=True)
    report={"status":"running","cases":{},"scope":"full original DiffTest; equal steady_clock eval timing adapters; no verbose trace"}
    receipt=args.out/"summary.json"
    receipt.write_text(json.dumps(report,indent=2)+"\n")
    try:
        with tempfile.TemporaryDirectory(prefix="images-",dir=args.out.resolve()) as name:
            directory=Path(name)
            for case in args.cases.split(","):
                program=directory/(case+".bin")
                image(ROOT/f"npc/rv64/testbench/chengyue64/programs/r64_core_{case}.S",program)
                records={"rtl":[],"model":[]}
                for sample in range(args.samples):
                    engines=[("rtl",args.rtl),("model",args.model)]
                    if sample%2:engines.reverse()
                    for engine,binary in engines:
                        value=run(binary,program,args.ref,args.out/f"{case}-{sample}-{engine}.log",args.timeout)
                        records[engine].append(value)
                        print(f"{case} sample={sample} {engine}: eval={value['eval_seconds']:.6f}s wall={value['wall_seconds']:.6f}s",flush=True)
                values=records["rtl"]+records["model"]
                if len({x["terminal"] for x in values})!=1 or len({x["eval_calls"] for x in values})!=1:
                    raise ValueError("workload/timing-call mismatch")
                rt=statistics.median(x["eval_seconds"] for x in records["rtl"])
                mt=statistics.median(x["eval_seconds"] for x in records["model"])
                rw=statistics.median(x["wall_seconds"] for x in records["rtl"])
                mw=statistics.median(x["wall_seconds"] for x in records["model"])
                report["cases"][case]={"samples":records,"rtl_eval_median":rt,"model_eval_median":mt,
                                      "eval_speedup":rt/mt,"rtl_wall_median":rw,"model_wall_median":mw,
                                      "wall_speedup":rw/mw}
                receipt.write_text(json.dumps(report,indent=2)+"\n")
        report["status"]="pass"
    except BaseException as exc:
        report["status"]="failed";report["error"]=str(exc);raise
    finally:receipt.write_text(json.dumps(report,indent=2)+"\n")

if __name__=="__main__":main()
