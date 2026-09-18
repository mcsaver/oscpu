#!/usr/bin/env python3
"""Build the whole-CPU word network and original full-DiffTest harness."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
MODEL=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(MODEL))
from rtl_snapshot import ROOT, prepare_sources
from rtl_compile import Compiler
from parallel_compile import ParallelCompiler

def command(argv, log):
    started=time.perf_counter()
    with Path(log).open("w") as stream:
        child=subprocess.Popen(argv,stdout=stream,stderr=subprocess.STDOUT,start_new_session=True)
        try:
            code=child.wait()
        except BaseException:
            os.killpg(child.pid,signal.SIGTERM)
            try:child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid,signal.SIGKILL);child.wait()
            raise
    if code:
        raise RuntimeError(f"exit {code}: {argv[0]}; {log}\n"+Path(log).read_text(errors="replace")[-5000:])
    return time.perf_counter()-started

def harness(out):
    src=(ROOT/"npc/rv64/testbench/chengyue64/r64_core_test.cpp").read_text()
    src='#include "model.h"\n#include "timing.hpp"\nusing Dut=TimedDut<NetworkDut>;\n'+src[src.index('#include "r64_image.h"'):]
    src=src.replace('  Verilated::threadContextp()->threads(R64_HOST_THREADS);','')
    src=src.replace('  Verilated::commandArgs(argc,argv);Dut d;','  Dut d;')
    (out/"main.cpp").write_text(src)

def build(args):
    args.out.mkdir(parents=True,exist_ok=True)
    report={"status":"running","scope":"whole CPU and system RTL word network; execution must be validated"}
    receipt=args.out/"build-report.json"
    receipt.write_text(json.dumps(report,indent=2)+"\n")
    started=time.perf_counter()
    temp=None
    if args.work:
        work=args.work.resolve();work.mkdir(parents=True,exist_ok=True)
    else:
        temp=tempfile.TemporaryDirectory(prefix="r64-network-",dir=args.out.resolve())
        work=Path(temp.name)
    try:
        if args.netlist:
            design_path=args.netlist.resolve()
        else:
            snapshot=work/"snapshot";files,incs=prepare_sources(snapshot)
            script="read_slang --error-limit 0 --best-effort-hierarchy --top R64SystemTestTop --allow-use-before-declare --no-synthesis-define --no-default-translate-off-format -D R64_ASSERT "
            script+=" ".join("-I "+str(p) for p in incs)+" "+" ".join(files)+" "+str(snapshot/"R64SystemTestTop.sv")+"\n"
            script+="opt; memory_collect; write_json "+str(snapshot/"hierarchy.json")+"\n"
            script+="flatten; opt; memory_collect; write_json "+str(snapshot/"design.json")+"\n"
            (snapshot/"build.ys").write_text(script)
            report["rtl_import_seconds"]=command([str(args.yosys),"-Q","-T","-m","slang","-s",str(snapshot/"build.ys")],args.out/"rtl-import.log")
            design_path=snapshot/"design.json"
            # Preserve a compact inventory of module I/O boundaries for migration.
            hierarchy=json.loads((snapshot/"hierarchy.json").read_text())["modules"]
            manifest={name:{"ports":{p:{"direction":v["direction"],"width":len(v["bits"])} for p,v in m["ports"].items()},
                            "source":m["attributes"].get("src"),
                            "children":{n:c["type"] for n,c in m["cells"].items() if c["type"] in hierarchy}}
                      for name,m in hierarchy.items()}
            (args.out/"modules.json").write_text(json.dumps(manifest,indent=2)+"\n")
            shutil.copy2(snapshot/"assertions.json",args.out/"assertions.json")
        began=time.perf_counter()
        design=json.loads(design_path.read_text())
        module=design["modules"]["R64SystemTestTop"]
        compiler=ParallelCompiler(module,partition_style=args.parallel_partition) if args.backend=="parallel" else Compiler(module)
        size=args.group_size or (512 if args.backend=="parallel" else 256)
        report["network"]=compiler.emit(work,group_size=size)
        report["code_generation_seconds"]=time.perf_counter()-began
        del design
        harness(work)
        sources=report["network"]["sources"]+["main.cpp"]
        logs=args.out/"compile-logs";logs.mkdir(exist_ok=True)
        flags=[args.cxx,"-std=c++17","-O"+args.optimization,"-DR64_SYSTEM","-pthread",
               "-I"+str(work),"-I"+str(Path(__file__).resolve().parent),"-I"+str(ROOT/"npc/rv64/testbench/chengyue64")]
        def compile_one(name):
            path=work/name
            return command(["prlimit","--as="+str(6<<30),"--core=0","--"]+flags+["-c",str(path),"-o",str(path.with_suffix(".o"))],logs/(path.stem+".log"))
        began=time.perf_counter()
        try:
            with ThreadPoolExecutor(max_workers=args.jobs) as pool:
                list(pool.map(compile_one,sources))
            report["compile_seconds"]=time.perf_counter()-began
            report["link_seconds"]=command(flags+[str((work/p).with_suffix(".o")) for p in sources]+[
                "-ldl","-Wl,--no-as-needed","-lreadline","-o",str(args.out/"r64-network")],args.out/"link.log")
        finally:
            for name in sources:
                path=(work/name).with_suffix(".o").resolve()
                if not path.is_relative_to(work.resolve()):raise RuntimeError("cleanup path escaped build")
                path.unlink(missing_ok=True)
        for log in logs.glob("*.log"):
            if not log.stat().st_size:log.unlink()
        report["status"]="built_not_validated"
        report["total_seconds"]=time.perf_counter()-started
        report["binary"]=str((args.out/"r64-network").resolve())
        report["compiler"]=flags[:3]
        report["jobs"]=args.jobs
    except BaseException as exc:
        report["status"]="failed";report["error"]=str(exc)
        raise
    finally:
        if temp:temp.cleanup()
        receipt.write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k!="network"},indent=2))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out",type=Path)
    p.add_argument("--backend",choices=("serial","parallel"),default="serial")
    p.add_argument("--parallel-partition",choices=("cones","levels"),default="cones")
    p.add_argument("--group-size",type=int)
    p.add_argument("--yosys",type=Path,default=ROOT/"oss-cad-suite/bin/yosys")
    p.add_argument("--cxx",default="clang++")
    p.add_argument("--optimization",choices=("0","1","2","3"),default="2")
    p.add_argument("--jobs",type=int,default=2)
    p.add_argument("--netlist",type=Path,help="reuse an explicitly selected, already imported RTL snapshot")
    p.add_argument("--work",type=Path,help="retain generated code for backend debugging; objects are always removed")
    args=p.parse_args()
    if args.out is None:args.out=ROOT/"npc/rv64/build"/("network-parallel" if args.backend=="parallel" else "network-model")
    if args.jobs<1:p.error("--jobs must be positive")
    if args.group_size is not None and args.group_size<1:p.error("--group-size must be positive")
    build(args)
if __name__=="__main__":main()
