#!/usr/bin/env python3
"""Collect an exact-path, instruction-checked RTL prefix without changing the DUT."""
import argparse
import json
from pathlib import Path
import subprocess
import time
import struct
ROOT=Path(__file__).resolve().parents[3]
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--image",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--max-cycles",type=int,default=100000)
    p.add_argument("--host-timeout",type=float,default=600)
    p.add_argument("--sim",type=Path,default=ROOT/"npc/rv64/build/chengyue64/system/obj/VR64SystemTestTop")
    p.add_argument("--ref",type=Path,default=ROOT/"nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    args=p.parse_args()
    if args.max_cycles <= 0 or args.host_timeout <= 0:
        p.error("cycle and host-time limits must be positive")
    args.out.mkdir(parents=True,exist_ok=True)
    cmd=[str(args.sim),str(args.image),str(args.ref),"--verbose",f"--maxcycles={args.max_cycles}"]
    start=time.perf_counter()
    with (args.out/"rtl.log").open("w") as log, (args.out/"rtl.stderr").open("w") as status:
        sim=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=status)
        collector=subprocess.Popen([str(ROOT/"npc/rv64/build/perf-model/import-rtl"),
            str(args.out/"functional.trace"),str(args.out/"rtl.cycles"),f"--cycle-limit-status={args.out/'rtl.stderr'}"],
            stdin=sim.stdout,stdout=log,stderr=subprocess.STDOUT)
        sim.stdout.close()
        try:
            collector_code=collector.wait(timeout=args.host_timeout)
            sim_code=sim.wait(timeout=10)
        except BaseException as error:
            sim.terminate();collector.terminate()
            sim.wait();collector.wait()
            receipt={"command":cmd,"rtl_exit_code":sim.returncode,
                     "collector_exit_code":collector.returncode,
                     "host_seconds":time.perf_counter()-start,
                     "collection_error":type(error).__name__,
                     "trace_natural_end":False,
                     "scope":"Collection interrupted; partial files are not an accepted RTL run."}
            (args.out/"collection.json").write_text(json.dumps(receipt,indent=2)+"\n")
            raise
    receipt={"command":cmd,"rtl_exit_code":sim_code,"collector_exit_code":collector_code,
             "host_seconds":time.perf_counter()-start,
             "scope":"Explicit bounded instruction-checked prefix; a cycle limit is not whole-program PASS."}
    if collector_code == 0:
        with (args.out/"functional.trace").open("rb") as trace:
            _, count, flags = struct.unpack("<8sQQ", trace.read(24))
        receipt["instructions"] = count
        receipt["trace_natural_end"] = bool(flags & 1)
        receipt["scope"] = "Complete instruction-checked RTL program." if flags & 1 else receipt["scope"]
    (args.out/"collection.json").write_text(json.dumps(receipt,indent=2)+"\n")
    if collector_code or sim_code not in (0,1):
        raise RuntimeError(f"collection failed; inspect {args.out/'rtl.log'}")
    print(json.dumps(receipt,indent=2))
if __name__=="__main__":
    main()
