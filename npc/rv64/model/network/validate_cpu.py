#!/usr/bin/env python3
"""Execute complete programs independently and require exact retirement/trap cycles."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
sys.dont_write_bytecode=True
MODEL=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(MODEL))
from validate import CASES, ROOT
CORE=("program","sv39","sdtrig","lsu_contention","backend_network","throughput")
EVENT=re.compile(r"(?:C \d+ pc=[^\n]*|T \d+ pc=[^\n]*)")
TERMINAL=re.compile(r"\[PASS\] r64_(?:core_program|system_poweroff) ([^\n]*)")

def execute(command,log,timeout):
    start=time.perf_counter()
    error_log=log.with_suffix(".stderr")
    with log.open("w") as stream, error_log.open("w") as error:
        try:
            result=subprocess.run([str(x) for x in command],stdout=stream,stderr=error,timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f"host timeout, incomplete run: {log}") from exc
    if result.returncode:
        raise RuntimeError(f"exit {result.returncode}: {log}\n"+log.read_text(errors="replace")[-2000:]+error_log.read_text(errors="replace")[-2000:])
    if not error_log.stat().st_size:error_log.unlink()
    return time.perf_counter()-start

def image(source,out):
    elf=out.with_suffix(".elf")
    log=out.with_suffix(".build.log")
    execute(["riscv64-linux-gnu-gcc","-nostdlib","-static","-march=rv64gc","-mabi=lp64d",
             "-Wl,-Ttext=0x80000000","-Wl,--build-id=none",source,"-o",elf],log,60)
    try:
        execute(["riscv64-linux-gnu-objcopy","-O","binary",elf,out],log,30)
    finally:
        elf.unlink(missing_ok=True)
    if not log.stat().st_size:log.unlink()

def compare(reference,candidate):
    texts=[p.read_text(errors="replace") for p in (reference,candidate)]
    events=[EVENT.findall(t) for t in texts]
    terminal=[TERMINAL.findall(t) for t in texts]
    if any(len(t)!=1 for t in terminal):raise ValueError("missing or ambiguous natural termination")
    values=[dict((k,int(v)) for k,v in re.findall(r"(\w+)=(\d+)",t[0])) for t in terminal]
    for e,v in zip(events,values):
        if sum(line.startswith("C ") for line in e)!=v["commits"]:
            raise ValueError("incomplete retirement observation")
    first=next(({"index":i,"rtl":a,"model":b} for i,(a,b) in enumerate(zip(*events)) if a!=b),None)
    accepted=events[0]==events[1] and values[0]==values[1]
    return {"accepted":accepted,"instructions":values[0]["commits"],"terminal_cycle":values[0]["cycles"],
            "events":len(events[0]),"first_mismatch":first,"same_terminal":values[0]==values[1],
            "retirement_and_trap_events_equal":events[0]==events[1],"reference_terminal":values[0],
            "scope":"complete program, original GPR/FPR/CSR/device DiffTest and RTL assertions"}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--model",type=Path,required=True)
    p.add_argument("--rtl",type=Path,default=ROOT/"npc/rv64/build/chengyue64/system/obj/VR64SystemTestTop")
    p.add_argument("--ref",type=Path,default=ROOT/"nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--micro",default=",".join(CASES))
    p.add_argument("--core",default=",".join(CORE))
    p.add_argument("--modes",default="plain,stalls")
    p.add_argument("--skip-system-io",action="store_true")
    p.add_argument("--timeout",type=float,default=120)
    p.add_argument("--max-cycles",type=int,default=2000000)
    args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    report={"status":"running","cases":{},"criterion":"all absolute retirement/trap events and natural terminal identical"}
    receipt=args.out/"summary.json";receipt.write_text(json.dumps(report,indent=2)+"\n")
    try:
        with tempfile.TemporaryDirectory(prefix="images-",dir=args.out.resolve()) as name:
            directory=Path(name);workloads=[]
            for case in filter(None,args.micro.split(",")):
                _,setup,body,count=CASES[case]
                source=directory/(case+".S");binary=directory/(case+".bin")
                source.write_text(f""".section .text
.globl _start
.option norelax
.option {'rvc' if case=='compressed' else 'norvc'}
_start:
{setup}
.rept {count}
{body}
.endr
li a0,0
ebreak
.section .data
.balign 64
data:
.dword data,data,0,0,0,0,0,0
""")
                image(source,binary);workloads.append((case,binary,[]))
            for case in filter(None,args.core.split(",")):
                binary=directory/(case+".bin")
                image(ROOT/f"npc/rv64/testbench/chengyue64/programs/r64_core_{case}.S",binary)
                workloads.append(("core_"+case,binary,[]))
            if not args.skip_system_io:
                binary=directory/"system_io.bin"
                image(ROOT/"npc/rv64/testbench/chengyue64/programs/r64_core_system_io.S",binary)
                sentinel=directory/"sentinel.bin"
                sentinel.write_bytes(bytes.fromhex("8877665544332211"))
                workloads.append(("system_io",binary,["--system",f"--load=0x81000000:{sentinel}","--uart-input=?:Z"]))
            for case,binary,extra in workloads:
                for mode in args.modes.split(","):
                    if mode not in ("plain","stalls"):raise ValueError("unknown mode")
                    stem=case+"-"+mode
                    options=extra+["--verbose",f"--maxcycles={args.max_cycles}"]+(["--stalls"] if mode=="stalls" else [])
                    times=[]
                    for engine,sim in (("rtl",args.rtl),("model",args.model)):
                        times.append(execute([sim.resolve(),binary,args.ref.resolve(),*options],args.out/(stem+"-"+engine+".log"),args.timeout))
                    result=compare(args.out/(stem+"-rtl.log"),args.out/(stem+"-model.log"))
                    result.update(rtl_wall_seconds=times[0],model_wall_seconds=times[1])
                    report["cases"][stem]=result
                    receipt.write_text(json.dumps(report,indent=2)+"\n")
                    print(f"{stem}: {'PASS' if result['accepted'] else 'FAIL'} instructions={result['instructions']} terminal={result['terminal_cycle']} rtl={times[0]:.3f}s model={times[1]:.3f}s",flush=True)
                    if not result["accepted"]:raise RuntimeError(f"exact comparison failed: {stem}")
        report["status"]="pass"
        report["instructions"]=sum(c["instructions"] for c in report["cases"].values())
        report["target_cycles"]=sum(c["terminal_cycle"]+1 for c in report["cases"].values())
    except BaseException as exc:
        report["status"]="failed";report["error"]=str(exc)
        raise
    finally:
        receipt.write_text(json.dumps(report,indent=2)+"\n")

if __name__=="__main__":main()
