#!/usr/bin/env python3
"""Experimental exact-RTL CXXRTL backend. Generation is not accuracy acceptance."""
from pathlib import Path
import argparse
import json
import re
import subprocess
import shutil
import time
from concurrent.futures import ThreadPoolExecutor
from rtl_snapshot import prepare_sources
from cxxrtl_native import specialize_native_checks

ROOT=Path(__file__).resolve().parents[3]

def run_logged(command, log_path, memory_gib=None):
    start=time.perf_counter()
    limits=["prlimit","--core=0"]
    if memory_gib:
        limits.append(f"--as={int(memory_gib*(1<<30))}")
    with log_path.open("w") as log:
        result=subprocess.run(limits+["--"]+command,stdout=log,stderr=subprocess.STDOUT)
    if result.returncode:
        print("\n".join(log_path.read_text(errors="replace").splitlines()[-30:]))
        raise RuntimeError(f"Command failed ({result.returncode}); see {log_path}")
    return time.perf_counter()-start

def compile_split(out, base_command, jobs, memory_gib):
    """Compile complete generated module methods in bounded translation units."""
    code=specialize_native_checks((out/"model.cc").read_text())
    namespace="namespace cxxrtl_design {"
    suffix="} // namespace cxxrtl_design"
    start=code.index(namespace)+len(namespace)
    end=code.rindex(suffix)
    body=code[start:end]
    offsets=[m.start() for m in re.finditer(r"(?m)^void p_[a-zA-Z0-9_]+::reset[(][)] [{]",body)]
    if not offsets or body[:offsets[0]].strip():
        raise RuntimeError("unrecognized CXXRTL module layout; refusing unsafe split")
    pieces=[body[a:b] for a,b in zip(offsets,offsets[1:]+[len(body)])]
    groups=[];group=""
    for piece in pieces:
        if group and len(group)+len(piece)>750_000:
            groups.append(group);group=""
        group+=piece
    if group: groups.append(group)
    directory=out/"compile-parts"
    directory.mkdir(exist_ok=True)
    sources=[]
    for i,part in enumerate(groups):
        source=directory/f"part-{i:03d}.cc"
        source.write_text(code[:start]+"\n"+part+"\n"+suffix+"\n")
        sources.append(source)
    sources.append(out/"main.cpp")
    def compile_one(source):
        obj=directory/(source.stem+".o")
        command=base_command+["-c",str(source),"-o",str(obj)]
        run_logged(command,directory/(source.stem+".log"),memory_gib)
        return obj
    began=time.perf_counter()
    objects=[directory/(source.stem+".o") for source in sources]
    try:
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            list(pool.map(compile_one,sources))
        command=base_command+[str(x) for x in objects]+[
            "-ldl","-Wl,--no-as-needed","-lreadline","-o",str(out/"r64-cxxrtl")]
        run_logged(command,out/"link.log",memory_gib)
    finally:
        # The pool has joined, including on error. Preserve diagnostics; remove
        # only this invocation's generated source/object paths.
        for target in sources[:-1]+objects:
            resolved=target.resolve()
            if not resolved.is_relative_to(directory.resolve()):
                raise RuntimeError("compiler cleanup escaped build directory")
            resolved.unlink(missing_ok=True)
        for log in [directory/(x.stem+".log") for x in sources]:
            if log.exists() and log.stat().st_size==0:
                log.unlink()
    return {"compile_seconds":time.perf_counter()-began,
            "translation_units":len(sources),"compiler_jobs":jobs}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--build",type=Path,default=ROOT/"npc/rv64/build/cxxrtl")
    p.add_argument("--yosys",type=Path,default=ROOT/"oss-cad-suite/bin/yosys")
    p.add_argument("--cxx",default="clang++")
    p.add_argument("--optimization",choices=("0","1","2","3"),default="1")
    p.add_argument("--forced-inline",action="store_true",
                   help="keep CXXRTL forced inlining; can require very large compiler memory")
    p.add_argument("--compiler-memory-gib",type=float,default=10)
    p.add_argument("--jobs",type=int,default=2)
    p.add_argument("--reuse-generated",action="store_true",
                   help="compile the existing generated RTL snapshot without regeneration")
    args=p.parse_args()
    if args.compiler_memory_gib<=0 or args.jobs<=0:
        p.error("compiler memory limit must be positive")
    root=ROOT
    out=args.build.resolve()
    out.mkdir(parents=True,exist_ok=True)
    report={}
    if not args.reuse_generated:
        files, incs=prepare_sources(out, root)
        script="read_slang --error-limit 0 --best-effort-hierarchy --top R64SystemTestTop --allow-use-before-declare --no-synthesis-define --no-default-translate-off-format -D R64_ASSERT "+" ".join("-I "+str(p) for p in incs)+" "+" ".join(files)+" "+str(out/"R64SystemTestTop.sv")+"\n"
        script+="opt; memory_collect; write_json "+str(out/"design.json")+"\nwrite_cxxrtl -noflatten -header -O6 -g0 "+str(out/"model.cc")+"\n"
        (out/"build.ys").write_text(script)
        report["generation_seconds"]=run_logged([str(args.yosys),"-Q","-T","-m","slang","-s",str(out/"build.ys")],out/"generate.log")
    generated_header=out/"model.h"
    generated_header.write_text(generated_header.read_text().replace(
        "using namespace cxxrtl;\n\nnamespace cxxrtl_design {",
        "namespace cxxrtl_design {\nusing namespace cxxrtl;"))
    ports=json.loads((out/"design.json").read_text())["modules"]["R64SystemTestTop"]["ports"]
    header='''#pragma once
    #include "model.h"
    #include <array>
    #include <memory>
    #include <cstdint>
    struct CxxrtlDut {
     std::unique_ptr<cxxrtl_design::p_R64SystemTestTop> engine =
         std::make_unique<cxxrtl_design::p_R64SystemTestTop>();
     template<size_t B, size_t N>
     static void put(cxxrtl::value<B>& v, const std::array<uint32_t,N>& a) {
      static_assert(N==cxxrtl::value<B>::chunks); for(size_t i=0;i<N;i++) v.data[i]=a[i];
     }
     template<size_t B, size_t N>
     static void put(cxxrtl::wire<B>& v, const std::array<uint32_t,N>& a) {put(v.next,a);}
     template<size_t B, size_t N>
     static void get(const cxxrtl::value<B>& v, std::array<uint32_t,N>& a) {
      static_assert(N==cxxrtl::value<B>::chunks); for(size_t i=0;i<N;i++) a[i]=v.data[i];
     }
     template<size_t B, size_t N>
     static void get(const cxxrtl::wire<B>& v, std::array<uint32_t,N>& a) {get(v.curr,a);}
    '''
    header=header.replace('#pragma once\n','#pragma once\n#include "'+str(root/"npc/rv64/model/src/cxxrtl_settle.hpp")+'"\n',1)
    inputs=[];outputs=[]
    for name,port in ports.items():
     bits=len(port["bits"])
     member="engine->p_"+name.replace("_","__")
     if bits<=64:
      typ="uint"+str(next(w for w in (8,16,32,64) if w>=bits))+"_t"
      header+=f" {typ} {name}=0;\n"
      if port["direction"]=="input": inputs.append(f" {member}.set<{typ}>({name});")
      else: outputs.append(f" {name}={member}.get<{typ}>();")
     else:
      header+=f" std::array<uint32_t,{(bits+31)//32}> {name}{{}};\n"
      if port["direction"]=="input": inputs.append(f" put({member},{name});")
      else: outputs.append(f" get({member},{name});")
    header+=' void eval(){\n'+'\n'.join(inputs)+'\n r64model::settle(*engine);\n'+'\n'.join(outputs)+'\n }\n void final(){}\n};\n'
    (out/"adapter.h").write_text(header)
    src=(root/"npc/rv64/testbench/chengyue64/r64_core_test.cpp").read_text()
    src='#include "adapter.h"\nusing Dut=CxxrtlDut;\n'+src[src.index('#include "r64_image.h"'):]
    src=src.replace('  Verilated::threadContextp()->threads(R64_HOST_THREADS);','')
    src=src.replace('  Verilated::commandArgs(argc,argv);Dut d;','  Dut d;')
    (out/"main.cpp").write_text(src)
    print("adapter generated:",len(ports),"ports")
    runtime=root/"oss-cad-suite/share/yosys/include/backends/cxxrtl/runtime"
    if not args.forced_inline:
        local_runtime=out/"runtime"
        shutil.copytree(runtime,local_runtime,dirs_exist_ok=True)
        runtime_header=local_runtime/"cxxrtl/cxxrtl.h"
        runtime_code=runtime_header.read_text()
        old="#define CXXRTL_ALWAYS_INLINE inline __attribute__((__always_inline__))"
        if old not in runtime_code:
            raise RuntimeError("unsupported CXXRTL inline attribute definition")
        runtime_header.write_text(runtime_code.replace(old,"#define CXXRTL_ALWAYS_INLINE inline"))
        runtime=local_runtime
    report["forced_inline"]=args.forced_inline
    cmd=[args.cxx,"-O"+args.optimization,"-std=c++17","-DR64_SYSTEM",
         "-I"+str(out),"-I"+str(root/"npc/rv64/testbench/chengyue64"),
         "-I"+str(runtime)]
    if Path(args.cxx).name in ("clang++","clang"):
        cmd += ["-mllvm","-rotation-max-header-size=0"]
    report.update(compile_split(out,cmd,args.jobs,args.compiler_memory_gib))
    report["scope"]="Generated RTL backend; requires independent DiffTest and exact cycle comparison before acceptance."
    (out/"build-report.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report,indent=2))

if __name__=="__main__":
    main()
