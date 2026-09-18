#!/usr/bin/env python3
"""Build short programs, compare instruction-aligned retirement timing with real RTL."""
import argparse
import csv
import json
from pathlib import Path
import re
import subprocess
import time
from compare import timing_metrics

ROOT = Path(__file__).resolve().parents[3]
MODEL = Path(__file__).resolve().parent
CASES = {
    "pointer_barrier": ("structural", "la t0, data", "ld t0,0(t0)\nld t1,8(t0)\nlh t1,0(t1)", 64),
    "independent": ("calibration", "li t0, 1\nli t1, 3", "\n".join(f"addi x{i}, x0, {i}" for i in range(12,28)), 64),
    "dependency": ("calibration", "li t0, 1", "addi t0,t0,1\naddi t0,t0,1\naddi t0,t0,1\naddi t0,t0,1", 128),
    "multiply": ("calibration", "li t0, 1\nli t1, 3", "mul t0,t0,t1", 128),
    "load_chain": ("calibration", "la t0, data", "ld t0,0(t0)", 128),
    "stores": ("calibration", "la t0, data\nli t1,1", "sd t1,16(t0)\nsd t1,24(t0)", 64),
    "branch": ("calibration", "li t0,0", "xori t0,t0,1\nbeqz t0,1f\naddi t1,t1,1\n1:", 128),
    "mixed": ("crosscheck", "la t0,data\nli t1,3\nli t2,5",
              "ld a1,0(t0)\nadd a2,a1,t1\nmul a3,t1,t2\nadd a4,a2,a3\nsd a4,16(t0)\naddi t2,t2,1", 64),
    "forward": ("crosscheck", "la t0,data\nli t1,3", "sd t1,16(t0)\nld t2,16(t0)\nadd t1,t2,t1", 64),
    "load_banks": ("crosscheck", "la t0,data", "ld a1,0(t0)\nld a2,8(t0)\nld a3,16(t0)\nld a4,24(t0)", 64),
    "divide": ("crosscheck", "li t0,123456789\nli t1,7", "div t2,t0,t1\nadd t0,t2,t1", 32),
    "compressed": ("crosscheck", "li t0,1\nli t1,3", "c.addi t0,1\nc.add t1,t0\nc.mv a1,t1", 64),
}
def run(command, log=None, timeout=180):
    start=time.perf_counter()
    if log:
        with Path(log).open("w") as out:
            result=subprocess.run([str(x) for x in command], stdout=out, stderr=subprocess.STDOUT, timeout=timeout)
        if result.returncode:
            raise RuntimeError(f"exit {result.returncode}: {' '.join(map(str,command))}; see {log}")
    else:
        subprocess.run([str(x) for x in command], check=True, capture_output=True, text=True, timeout=timeout)
    return time.perf_counter()-start

def compare(rtl_log, stages):
    text=Path(rtl_log).read_text()
    if "[PASS] r64_core_program" not in text:
        raise ValueError("RTL did not reach successful DiffTest terminal")
    rtl=[(int(m[1]),int(m[2],16)) for m in re.finditer(r"^C (\d+) pc=([0-9a-f]+)",text,re.M)]
    with Path(stages).open() as stream:
        model=list(csv.DictReader(stream))
    if len(rtl)!=len(model) or any(pc!=int(row["pc"],16) for (_,pc),row in zip(rtl,model)):
        raise ValueError("different architectural instruction stream: timing comparison rejected")
    rc=[x[0] for x in rtl];mc=[int(x["retire"]) for x in model]
    return timing_metrics(rc, mc)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--sim",type=Path,default=ROOT/"npc/rv64/build/chengyue64/system/obj/VR64SystemTestTop")
    p.add_argument("--ref",type=Path,default=ROOT/"nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so")
    p.add_argument("--build",type=Path,default=ROOT/"npc/rv64/build/perf-model")
    p.add_argument("--config",type=Path,default=MODEL/"configs/chengyue64-v1.cfg")
    p.add_argument("--cases",default=",".join(CASES))
    p.add_argument("--reuse-rtl",action="store_true",help="Reuse this output's existing RTL traces and functional traces.")
    args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True);results={}
    for case in args.cases.split(","):
        cohort,setup,body,count=CASES[case];directory=args.out/case;directory.mkdir(exist_ok=True)
        source=directory/"program.S"
        if not args.reuse_rtl:
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
.dword data, data, 0, 0, 0, 0, 0, 0
""")
            run(["riscv64-linux-gnu-gcc","-nostdlib","-static","-march=rv64gc","-mabi=lp64d",
                 "-Wl,-Ttext=0x80000000","-Wl,--build-id=none",source,"-o",directory/"program.elf"])
            run(["riscv64-linux-gnu-objcopy","-O","binary",directory/"program.elf",directory/"program.bin"])
            rtl_seconds=run([args.sim,directory/"program.bin",args.ref,"--verbose","--maxcycles=200000"],directory/"rtl.log")
            trace_seconds=run([args.build/"trace-nemu",directory/"program.bin",args.ref,directory/"functional.trace"],directory/"trace.log")
            (directory/"wall.json").write_text(json.dumps({"rtl_seconds":rtl_seconds,"trace_seconds":trace_seconds}))
        model_seconds=run([args.build/"r64-model",directory/"functional.trace","--config",args.config,
                           "--output",directory/"model.json","--stages",directory/"stages.csv"],directory/"model.log")
        report=compare(directory/"rtl.log",directory/"stages.csv")
        report.update(json.loads((directory/"wall.json").read_text()))
        report.update(cohort=cohort,model_process_seconds=model_seconds)
        report["model_core_seconds"]=json.loads((directory/"model.json").read_text())["host_seconds"]
        results[case]=report
        print(f"{case:14s} RTL={report['rtl_retirement_span']:6d} model={report['model_retirement_span']:6d}"
              f" error={report['span_error_percent']:+7.2f}% interval_exact={report['interval_exact_percent']:5.1f}%",flush=True)
    (args.out/"validation.json").write_text(json.dumps({
        "scope":"Instruction-aligned bare-mode calibration and inspected crosschecks; no full-core equivalence claim.",
        "config":str(args.config.resolve()),"cases":results},indent=2)+"\n")

if __name__=="__main__":
    main()
