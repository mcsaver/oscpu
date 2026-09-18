#!/usr/bin/env python3
"""Same-image complete-program comparison of RTL, serial and parallel backends."""
import argparse
import json
import os
from pathlib import Path
import statistics
import sys
import tempfile
sys.dont_write_bytecode=True
from build_cpu import ROOT
from benchmark_cpu import run
from validate_cpu import image

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--rtl",type=Path,required=True)
    p.add_argument("--serial",type=Path,default=ROOT/"npc/rv64/build/network-model/r64-network")
    p.add_argument("--parallel",type=Path,default=ROOT/"npc/rv64/build/network-parallel/r64-network")
    p.add_argument("--ref",type=Path,default=ROOT/"nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--threads",default="1,2,4")
    p.add_argument("--cases",default="program,throughput,lsu_contention")
    p.add_argument("--samples",type=int,default=3)
    p.add_argument("--timeout",type=float,default=120)
    args=p.parse_args()
    threads=[int(x) for x in args.threads.split(",")]
    if args.samples<1 or any(t<1 for t in threads):p.error("samples/threads must be positive")
    args.out.mkdir(parents=True,exist_ok=True)
    engines=[("rtl",args.rtl,None),("serial",args.serial,None)]
    engines += [(f"parallel_{n}",args.parallel,n) for n in threads]
    report={"status":"running","scope":"single simulated CPU latency, original complete DiffTest and RTL assertions",
            "gpu_execution":False,"samples_per_engine":args.samples,"cases":{}}
    receipt=args.out/"summary.json"
    receipt.write_text(json.dumps(report,indent=2)+"\n")
    try:
        with tempfile.TemporaryDirectory(prefix="images-",dir=args.out.resolve()) as name:
            work=Path(name)
            for case in args.cases.split(","):
                binary=work/(case+".bin")
                image(ROOT/f"npc/rv64/testbench/chengyue64/r64_core_{case}.S",binary)
                records={label:[] for label,_,_ in engines}
                for sample in range(args.samples):
                    shift=sample%len(engines)
                    order=engines[shift:]+engines[:shift]
                    if sample%2:order.reverse()
                    for label,engine,n in order:
                        env=dict(os.environ)
                        if n is not None:env["R64_MODEL_THREADS"]=str(n)
                        else:env.pop("R64_MODEL_THREADS",None)
                        result=run(engine,binary,args.ref,args.out/f"{case}-{sample}-{label}.log",args.timeout,env=env)
                        records[label].append(result)
                        print(f"{case} sample={sample} {label}: eval={result['eval_seconds']:.6f}s wall={result['wall_seconds']:.6f}s",flush=True)
                samples=[r for group in records.values() for r in group]
                if len({r["terminal"] for r in samples})!=1 or len({r["eval_calls"] for r in samples})!=1:
                    raise ValueError("terminal or timing-call mismatch")
                medians={label:{"eval_seconds":statistics.median(r["eval_seconds"] for r in values),
                                "wall_seconds":statistics.median(r["wall_seconds"] for r in values)}
                         for label,values in records.items()}
                for label,value in medians.items():
                    value["speedup_vs_rtl"]=medians["rtl"]["eval_seconds"]/value["eval_seconds"]
                    value["speedup_vs_serial"]=medians["serial"]["eval_seconds"]/value["eval_seconds"]
                report["cases"][case]={"samples":records,"medians":medians}
                receipt.write_text(json.dumps(report,indent=2)+"\n")
        report["status"]="pass"
    except BaseException as exc:
        report["status"]="failed";report["error"]=str(exc);raise
    finally:receipt.write_text(json.dumps(report,indent=2)+"\n")

if __name__=="__main__":main()
