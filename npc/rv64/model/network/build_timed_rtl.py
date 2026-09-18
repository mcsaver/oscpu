#!/usr/bin/env python3
"""Relink the existing assertion-enabled Verilator library with equal eval timing."""
import argparse
from pathlib import Path
import sys
import tempfile
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_cpu import ROOT, command

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--obj",type=Path,default=ROOT/"npc/rv64/build/chengyue64/system/obj")
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--include",type=Path,default=Path("/usr/share/verilator/include"))
    args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    network=Path(__file__).resolve().parent
    with tempfile.TemporaryDirectory(prefix="timed-rtl-",dir=args.out.resolve()) as name:
        work=Path(name)
        src=(ROOT/"npc/rv64/testbench/chengyue64/r64_core_test.cpp").read_text()
        src=src.replace('using Dut=VR64SystemTestTop;','#include "timing.hpp"\nusing Dut=TimedDut<VR64SystemTestTop>;')
        (work/"main.cpp").write_text(src)
        flags=["g++","-O2","-std=c++17","-DR64_SYSTEM","-DR64_HOST_THREADS=1",
               "-I"+str(args.obj.resolve()),"-I"+str(args.include),"-I"+str(args.include/"vltstd"),
               "-I"+str(network),"-I"+str(ROOT/"npc/rv64/testbench/chengyue64")]
        sources=[work/"main.cpp",args.include/"verilated.cpp",args.include/"verilated_threads.cpp"]
        objects=[]
        for source in sources:
            target=work/(source.stem+".o");objects.append(target)
            command(flags+["-c",str(source),"-o",str(target)],args.out/(source.stem+".log"))
        command(flags+[str(x) for x in objects]+[str(args.obj.resolve()/"VR64SystemTestTop__ALL.a"),
                "-ldl","-pthread","-Wl,--no-as-needed","-lreadline","-o",str(args.out/"r64-verilator-timed")],args.out/"link.log")
    print(args.out/"r64-verilator-timed")
if __name__=="__main__":main()
