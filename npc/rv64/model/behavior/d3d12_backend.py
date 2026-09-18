"""Build and execute the real Intel iGPU backend through WSL Direct3D 12."""
import json,struct,subprocess,time
from pathlib import Path
from hlsl_codegen import HlslEmitter
HERE=Path(__file__).resolve().parent
BUILD=HERE.parents[1]/"build"/"behavior-d3d12"

def command(args,timeout=90):
    r=subprocess.run([str(x) for x in args],capture_output=True,text=True,timeout=timeout)
    if r.returncode:raise RuntimeError(r.stdout+r.stderr)
    return r.stdout

def build_runner(build=BUILD):
    build=Path(build).resolve();include=build/"deps/headers/usr/include"
    runner=build/"d3d12-run"
    source=HERE/"d3d12_runner.cpp"
    if not runner.exists() or runner.stat().st_mtime<source.stat().st_mtime:
        command(["g++","-std=c++17","-O2","-Wall","-Wextra","-Werror",
                 "-I",include,"-I",include/"wsl/stubs",source,
                 "-L",build/"deps/headers/usr/lib/x86_64-linux-gnu","-lDirectX-Guids",
                 "-L/usr/lib/wsl/lib","-ldxcore","-ld3d12","-o",runner])
    return runner

def compile_model(model,directory,build=BUILD,lanes=None,backend="auto",trace_mode=None):
    directory=Path(directory);directory.mkdir(parents=True,exist_ok=True)
    candidate=None
    if backend=="auto" and getattr(model,"materialize",None):backend="dataflow"
    if backend=="auto":
        from simd_codegen import SimdEmitter
        candidate=SimdEmitter(model,lanes=lanes)
        backend="wave" if candidate.logical_task_count<=32 and len(candidate.families)<=4 else "simd"
    if backend=="dataflow":
        from dataflow_codegen import DataflowEmitter
        emitter=DataflowEmitter(model,lanes=lanes)
    elif backend=="wave":
        from wave_codegen import WaveEmitter
        emitter=WaveEmitter(model)
    elif backend=="simd":
        from simd_codegen import SimdEmitter
        emitter=candidate or SimdEmitter(model,lanes=lanes)
    elif backend=="baseline":emitter=HlslEmitter(model,lanes=lanes or 32)
    else:raise ValueError("unknown GPU backend")
    source=directory/"model.hlsl";binary=directory/"model.dxil"
    source_text=emitter.emit()
    emitter.trace_mode=trace_mode
    if trace_mode is not None:
        declaration="cbuffer Parameters:register(b0){uint cycles;uint trace_enabled;};"
        source_text=source_text.replace(declaration,"cbuffer Parameters:register(b0){uint cycles;uint trace_request;};\nstatic const uint trace_enabled="+str(int(trace_mode))+";")
    source.write_text(source_text)
    started=time.perf_counter()
    command([Path(build)/"deps/dxc/bin/dxc","-T",getattr(emitter,"shader_target","cs_6_0"),"-E","main","-O3",source,"-Fo",binary],timeout=180)
    return emitter,binary,time.perf_counter()-started

def pack_inputs(model,cases):
    values=[]
    for edge,row in cases:
        if edge not in ("posedge","negedge"):raise ValueError("invalid edge")
        if set(row)!=set(model.inputs):raise ValueError("input names do not match")
        values.append(int(edge=="negedge"))
        for n,w in model.inputs.items():
            value=row[n]
            if not isinstance(value,int) or not 0<=value<(1<<w):raise ValueError("input exceeds declared width")
            values.extend((value>>(32*j))&0xffffffff for j in range((w+31)//32))
    if not cases:raise ValueError("at least one edge is required")
    return struct.pack("<"+"I"*len(values),*values)

def unpack(values,widths,offset):
    row=[]
    for w in widths:
        n=(w+31)//32;row.append(sum(values[offset+j]<<(32*j) for j in range(n)));offset+=n
    return tuple(row),offset

def execute(model,cases,emitter,binary,directory,trace=True,build=BUILD,expect_failure=False):
    if getattr(emitter,"trace_mode",None) is not None and trace!=emitter.trace_mode:
        raise ValueError("trace request does not match compiled specialization")
    directory=Path(directory);inp=directory/"input.bin";out=directory/"output.bin"
    descriptors=getattr(emitter,"descriptors",[])
    inp.write_bytes(pack_inputs(model,cases)+struct.pack("<"+"I"*len(descriptors),*descriptors))
    words=4+emitter.state_words+(2*len(cases)*emitter.observation_words if trace else 0)
    started=time.perf_counter()
    r=subprocess.run([str(build_runner(build)),str(binary),str(inp),str(out),str(len(cases)),str(words),str(int(trace))],
                     capture_output=True,text=True,timeout=40)
    elapsed=time.perf_counter()-started
    if r.returncode not in (0,2):raise RuntimeError(r.stdout+r.stderr)
    report=json.loads(r.stdout);report["invocation_ms"]=elapsed*1000
    if report["vendor_id"]!=0x8086 or not report["hardware"] or not report["integrated"]:
        raise AssertionError("unexpected device; no CPU/software fallback accepted")
    if bool(r.returncode==2)!=expect_failure:raise AssertionError(report)
    data=out.read_bytes()
    if len(data)!=words*4:raise AssertionError("incorrect device result size")
    values=struct.unpack("<"+"I"*words,data)
    if tuple(values[:4])!=(report["status"],report["failure_cycle"],report["failure_block"],report["failure_phase"]):
        raise AssertionError("device status mismatch")
    state,offset=unpack(values,model.states.values(),4)
    rows=[]
    if trace and not expect_failure:
        widths=[e.width for e in model.outputs.values()]+list(model.states.values())
        for _ in range(len(cases)*2):
            row,offset=unpack(values,widths,offset);rows.append(row)
    return rows,state,report
